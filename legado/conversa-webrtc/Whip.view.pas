unit Whip.view;

// Form de transmissão WHIP.
// Captura tela (GDI/BitBlt) e microfone (waveIn), encoda H264+Opus via FFmpeg
// e envia via WHIP para um servidor compatível (MediaMTX, etc.).

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.SyncObjs,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation,
  Pion.Whep.Binding,
  Screen.Capture, Mic.Capture, Video.Encoder, Audio.Encoder, Winapi.Windows;

type
  TFormWhip = class(TForm)
    PnlTop:        TPanel;
    LblHost:       TLabel;
    EdtHost:       TEdit;
    LblPort:       TLabel;
    EdtPort:       TEdit;
    LblPath:       TLabel;
    EdtPath:       TEdit;
    LblUser:       TLabel;
    EdtUser:       TEdit;
    LblPass:       TLabel;
    EdtPass:       TEdit;
    ChkVideo:      TCheckBox;
    ChkAudio:      TCheckBox;
    LblFps:        TLabel;
    PnlBottom:     TPanel;
    BtnTransmitir: TButton;
    BtnParar:      TButton;
    LblStatus:     TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnTransmitirClick(Sender: TObject);
    procedure BtnPararClick(Sender: TObject);
  private
    FHandle:        Int32;
    FScreenCapture: TScreenCapture;
    FMicCapture:    TMicCapture;
    FVideoEncoder:  TVideoEncoder;
    FAudioEncoder:  TAudioEncoder;

    // FPS counter
    FFrameCount:    Integer;
    FLastFpsTick:   Cardinal;
    FLock:          TCriticalSection;

    procedure SetStatus(const Msg: string);
    procedure StopCapture;
    procedure UpdateFpsLabel(Fps: Integer);
  end;

var
  FormWhip: TFormWhip;

implementation

{$R *.fmx}

{ TFormWhip }

procedure TFormWhip.FormCreate(Sender: TObject);
begin
  FHandle := 0;
  FLock   := TCriticalSection.Create;
  FFrameCount  := 0;
  FLastFpsTick := GetTickCount;
end;

procedure TFormWhip.FormDestroy(Sender: TObject);
begin
  StopCapture;
  FLock.Free;
end;

procedure TFormWhip.SetStatus(const Msg: string);
begin
  TThread.Queue(nil, procedure
  begin
    if not (csDestroying in ComponentState) then
      LblStatus.Text := 'Status: ' + Msg;
  end);
end;

procedure TFormWhip.UpdateFpsLabel(Fps: Integer);
begin
  TThread.Queue(nil, procedure
  begin
    if not (csDestroying in ComponentState) then
      LblFps.Text := 'FPS: ' + IntToStr(Fps);
  end);
end;

procedure TFormWhip.BtnTransmitirClick(Sender: TObject);
var
  Host, Port, Path, User, Pass: string;
  WhipURL: string;
  SendVid, SendAud: Int32;
  W, H, Fps: Integer;
begin
  if FHandle <> 0 then Exit;

  Host := EdtHost.Text.Trim;
  Port := EdtPort.Text.Trim;
  Path := EdtPath.Text.Trim;
  User := EdtUser.Text.Trim;
  Pass := EdtPass.Text;

  if Host = '' then
  begin
    SetStatus('Host obrigatório');
    Exit;
  end;

  // Monta URL WHIP: http://host:port/path/whip
  if Port = '' then
    WhipURL := 'http://' + Host + Path + '/whip'
  else
    WhipURL := 'http://' + Host + ':' + Port + Path + '/whip';

  SendVid := Ord(ChkVideo.IsChecked);
  SendAud := Ord(ChkAudio.IsChecked);

  if (SendVid = 0) and (SendAud = 0) then
  begin
    SetStatus('Selecione ao menos vídeo ou áudio');
    Exit;
  end;

  BtnTransmitir.Enabled := False;
  SetStatus('Conectando...');

  // Parâmetros de vídeo
  W   := 1280;
  H   := 720;
  Fps := 30;

  // Cria encoders e capturas antes de conectar
  if SendVid = 1 then
  begin
    FVideoEncoder  := TVideoEncoder.Create(W, H, Fps, 2000);
    FScreenCapture := TScreenCapture.Create;
  end;

  if SendAud = 1 then
  begin
    FAudioEncoder := TAudioEncoder.Create;
    FMicCapture   := TMicCapture.Create(48000, 2);
  end;

  // Conecta WHIP em thread anônima
  TThread.CreateAnonymousThread(procedure
  var
    H_Local: Int32;
    Ret:     Int32;
    AuthType: AnsiString;
    UserA, PassA: AnsiString;
  begin
    AuthType := 'Basic';
    UserA    := AnsiString(User);
    PassA    := AnsiString(Pass);

    Ret := WhipConnect(
      PAnsiChar(AnsiString(WhipURL)),
      PAnsiChar(AuthType),
      PAnsiChar(UserA),
      PAnsiChar(PassA),
      SendVid,
      SendAud);

    if Ret < 0 then
    begin
      SetStatus('Erro ao conectar: ' + IntToStr(Ret));
      TThread.Queue(nil, procedure
      begin
        if not (csDestroying in ComponentState) then
        begin
          BtnTransmitir.Enabled := True;
          StopCapture;
        end;
      end);
      Exit;
    end;

    H_Local := Ret;

    TThread.Synchronize(nil, procedure
    begin
      if csDestroying in ComponentState then Exit;

      FHandle := H_Local;
      BtnParar.Enabled      := True;
      BtnTransmitir.Enabled := False;
      SetStatus('Transmitindo');

      // Conecta encoder de vídeo → WHIP
      if Assigned(FVideoEncoder) then
      begin
        FVideoEncoder.OnPacket := procedure(Data: PByte; Size, DurationMs: Integer)
        var
          H: Int32;
          Tick: Cardinal;
          Fps: Integer;
        begin
          H := FHandle;
          if H = 0 then Exit;
          WhipSendVideo(H, Data, Size, DurationMs);

          // Conta FPS
          FLock.Enter;
          try
            Inc(FFrameCount);
            Tick := GetTickCount;
            if Tick - FLastFpsTick >= 1000 then
            begin
              Fps := FFrameCount;
              FFrameCount  := 0;
              FLastFpsTick := Tick;
              UpdateFpsLabel(Fps);
            end;
          finally
            FLock.Leave;
          end;
        end;

        FScreenCapture.OnFrame := procedure(Data: PByte; W, H: Integer)
        begin
          if FHandle = 0 then Exit;
          if Assigned(FVideoEncoder) then
            FVideoEncoder.FeedFrame(Data, W, H);
        end;

        FScreenCapture.Start(30);
      end;

      // Conecta encoder de áudio → WHIP
      if Assigned(FAudioEncoder) then
      begin
        FAudioEncoder.OnPacket := procedure(Data: PByte; Size: Integer)
        var
          H: Int32;
        begin
          H := FHandle;
          if H = 0 then Exit;
          WhipSendAudio(H, Data, Size, 20);
        end;

        FMicCapture.OnData := procedure(PCM: PByte; Samples: Integer)
        begin
          if FHandle = 0 then Exit;
          if Assigned(FAudioEncoder) then
            FAudioEncoder.FeedPCM(PCM, Samples);
        end;

        FMicCapture.Start;
      end;
    end);
  end).Start;
end;

procedure TFormWhip.BtnPararClick(Sender: TObject);
begin
  StopCapture;
  BtnParar.Enabled      := False;
  BtnTransmitir.Enabled := True;
  LblFps.Text := 'FPS: --';
  SetStatus('Desconectado');
end;

procedure TFormWhip.StopCapture;
var
  H: Int32;
begin
  // Zera handle antes de parar capturas para que callbacks saiam imediatamente
  H       := FHandle;
  FHandle := 0;

  // Para capturas (bloqueante — espera threads terminarem)
  if Assigned(FScreenCapture) then
  begin
    FScreenCapture.OnFrame := nil;
    FScreenCapture.Stop;
    FreeAndNil(FScreenCapture);
  end;

  if Assigned(FMicCapture) then
  begin
    FMicCapture.OnData := nil;
    FMicCapture.Stop;
    FreeAndNil(FMicCapture);
  end;

  // Libera encoders
  FreeAndNil(FVideoEncoder);
  FreeAndNil(FAudioEncoder);

  // Desconecta WHIP
  if H <> 0 then
    WhipDisconnect(H);
end;

end.
