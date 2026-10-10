unit Inicio.view;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.SyncObjs, System.Generics.Collections, System.StrUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls,
  FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  Pion.Whep.Binding, Video.Decoder, Audio.Player;

type
  TForm1 = class(TForm)
    PnlLeft: TPanel;
    PnlLeftTop: TPanel;
    LblHost1: TLabel;
    EdtHost1: TEdit;
    LblPort1: TLabel;
    EdtPort1: TEdit;
    LblPath1: TLabel;
    EdtPath1: TEdit;
    LblUser1: TLabel;
    EdtUser1: TEdit;
    LblPass1: TLabel;
    EdtPass1: TEdit;
    BtnConnect1: TButton;
    BtnStop1: TButton;
    LblStatus1: TLabel;
    ImgVideo1: TImage;
    PnlSplitter: TPanel;
    PnlRight: TPanel;
    PnlRightTop: TPanel;
    LblHost2: TLabel;
    EdtHost2: TEdit;
    LblPort2: TLabel;
    EdtPort2: TEdit;
    LblPath2: TLabel;
    EdtPath2: TEdit;
    LblUser2: TLabel;
    EdtUser2: TEdit;
    LblPass2: TLabel;
    EdtPass2: TEdit;
    BtnConnect2: TButton;
    BtnStop2: TButton;
    LblStatus2: TLabel;
    ImgVideo2: TImage;
    btnTransmitir: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnConnect1Click(Sender: TObject);
    procedure BtnStop1Click(Sender: TObject);
    procedure BtnConnect2Click(Sender: TObject);
    procedure BtnStop2Click(Sender: TObject);
    procedure btnTransmitirClick(Sender: TObject);
  private
    FDecoders:     TDictionary<Int32, TVideoDecoder>;
    FAudioPlayers: TDictionary<Int32, TAudioPlayer>;
    FImages:       TDictionary<Int32, TImage>;
    FStatusLabels: TDictionary<Int32, TLabel>;
    FBtnConnect:   TDictionary<Int32, TButton>;
    FBtnStop:      TDictionary<Int32, TButton>;

    FHandle1: Int32;
    FHandle2: Int32;

    procedure DoConnect(const Host, Port, Path, User, Pass: string;
      ImgTarget: TImage; LblTarget: TLabel;
      BtnConn, BtnStp: TButton; var HandleOut: Int32);
    procedure DoDisconnect(var HandleOut: Int32;
      BtnConn, BtnStp: TButton; LblTarget: TLabel);
  end;

var
  Form1: TForm1;

  // Globals acessados de callbacks em threads Go — proteção via GCallbackLock
  GCallbackLock: TCriticalSection;
  GDecoders:     TDictionary<Int32, TVideoDecoder>;
  GAudioPlayers: TDictionary<Int32, TAudioPlayer>;
  GImages:       TDictionary<Int32, TImage>;
  GShutdown:     Boolean;  // sinaliza que o form está sendo destruído

procedure VideoCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure AudioCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure StateCallback(Handle: Int32; State: Int32); cdecl;

implementation

{$R *.fmx}

uses
  System.IOUtils,
  Whip.view;

var
  GLogFile:         string;
  GLogLock:         TCriticalSection;
  GVideoFrameCount: Integer;
  GForm:            TForm1;

procedure AppLog(const Msg: string);
var
  Line: string;
begin
  GLogLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + Msg + sLineBreak;
    TFile.AppendAllText(GLogFile, Line, TEncoding.UTF8);
  finally
    GLogLock.Leave;
  end;
end;

// VideoCallback é chamado de goroutines Go — NÃO na main thread
procedure VideoCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
var
  Dec: TVideoDecoder;
begin
  // GCallbackLock serializa acesso ao dicionário e garante que Dec
  // não seja liberado pelo DoDisconnect enquanto FeedData estiver rodando
  GCallbackLock.Enter;
  try
    if GShutdown then Exit;

    Inc(GVideoFrameCount);
    if GVideoFrameCount <= 5 then
      AppLog(Format('VideoCallback handle=%d #%d: %d bytes', [Handle, GVideoFrameCount, Size]));

    if not GDecoders.TryGetValue(Handle, Dec) then Exit;
  finally
    GCallbackLock.Leave;
  end;

  // FeedData fora do lock global — tem seu próprio lock interno
  // Neste ponto, DoDisconnect pode ter removido Dec do dict mas não pode
  // ainda ter chamado Dec.Free (pois DoDisconnect aguarda GCallbackLock)
  Dec.FeedData(Data, Size);
end;

// AudioCallback é chamado de goroutines Go — NÃO na main thread
procedure AudioCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
var
  Player: TAudioPlayer;
begin
  GCallbackLock.Enter;
  try
    if GShutdown then Exit;
    if not GAudioPlayers.TryGetValue(Handle, Player) then Exit;
  finally
    GCallbackLock.Leave;
  end;

  Player.FeedData(Data, Size);
end;

// StateCallback é chamado de goroutines Go — NÃO na main thread
procedure StateCallback(Handle: Int32; State: Int32); cdecl;
var
  Msg: string;
begin
  case State of
    0: Msg := 'Desconectado';
    1: Msg := 'Conectando...';
    2: Msg := 'Conectado';
    3: Msg := 'Falha na conexão';
  else
    Msg := 'Desconhecido';
  end;

  AppLog(Format('StateCallback handle=%d: %d (%s)', [Handle, State, Msg]));

  if GShutdown then Exit;

  // Faz o lookup do label na main thread (dentro do Queue),
  // não aqui — evita capturar ponteiro que pode ser liberado antes do Queue executar
  TThread.Queue(nil, procedure
  var
    Lbl: TLabel;
  begin
    if GShutdown or (GForm = nil) then Exit;
    if GForm.FStatusLabels.TryGetValue(Handle, Lbl) then
      Lbl.Text := Msg;
  end);
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  Ret: Int32;
begin
  GLogLock     := TCriticalSection.Create;
  GCallbackLock := TCriticalSection.Create;
  GLogFile     := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'delphi_whep.log');
  GVideoFrameCount := 0;
  GShutdown    := False;

  AppLog('=== App iniciado ===');
  AppLog('Exe: ' + ParamStr(0));

  FHandle1 := 0;
  FHandle2 := 0;

  FDecoders     := TDictionary<Int32, TVideoDecoder>.Create;
  FAudioPlayers := TDictionary<Int32, TAudioPlayer>.Create;
  FImages       := TDictionary<Int32, TImage>.Create;
  FStatusLabels := TDictionary<Int32, TLabel>.Create;
  FBtnConnect   := TDictionary<Int32, TButton>.Create;
  FBtnStop      := TDictionary<Int32, TButton>.Create;

  GDecoders     := FDecoders;
  GAudioPlayers := FAudioPlayers;
  GImages       := FImages;
  GForm         := Self;

  AppLog('Chamando WhepInit...');
  Ret := WhepInit(@VideoCallback, @AudioCallback, @StateCallback);
  AppLog(Format('WhepInit retornou: %d', [Ret]));
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  Dec:    TVideoDecoder;
  Player: TAudioPlayer;
begin
  AppLog('FormDestroy');

  // 1. Sinaliza shutdown para que novos callbacks retornem imediatamente
  GShutdown := True;
  GForm     := nil;

  // 2. Desconecta streams — Go vai encerrar as goroutines
  if FHandle1 > 0 then WhepDisconnect(FHandle1);
  if FHandle2 > 0 then WhepDisconnect(FHandle2);

  // 3. Aguarda callbacks em andamento terminarem via lock
  GCallbackLock.Enter;
  GCallbackLock.Leave;

  // 4. Limpa globals (neste ponto nenhum callback está rodando)
  GDecoders     := nil;
  GAudioPlayers := nil;
  GImages       := nil;

  // 5. Libera objetos
  for Dec in FDecoders.Values do
    Dec.Free;
  for Player in FAudioPlayers.Values do
    Player.Free;

  FDecoders.Free;
  FAudioPlayers.Free;
  FImages.Free;
  FStatusLabels.Free;
  FBtnConnect.Free;
  FBtnStop.Free;

  GCallbackLock.Free;
  GLogLock.Free;
end;

procedure TForm1.DoConnect(const Host, Port, Path, User, Pass: string;
  ImgTarget: TImage; LblTarget: TLabel;
  BtnConn, BtnStp: TButton; var HandleOut: Int32);
var
  URL:        string;
  Dec:        TVideoDecoder;
  Player:     TAudioPlayer;
  PHandleOut: ^Int32;  // aponta para FHandle1 ou FHandle2 via var param
begin
  // @HandleOut é válido: var param é passado por referência, ou seja,
  // aponta para FHandle1 ou FHandle2 no form — não para TForm.Handle
  PHandleOut := @HandleOut;

  URL := Format('http://%s:%s/%s/whep', [Host, Port, Path]);
  AppLog('DoConnect: URL=' + URL);

  BtnConn.Enabled := False;
  LblTarget.Text  := 'Conectando...';

  Dec    := TVideoDecoder.Create;
  Player := TAudioPlayer.Create;

  TThread.CreateAnonymousThread(procedure
  var
    H:        Int32;  // "H" para não colidir com TForm.Handle
    URLAnsi:  AnsiString;
    AuthAnsi: AnsiString;
    UserAnsi: AnsiString;
    PassAnsi: AnsiString;
  begin
    URLAnsi  := AnsiString(URL);
    AuthAnsi := AnsiString(IfThen(User <> '', 'Basic', ''));
    UserAnsi := AnsiString(User);
    PassAnsi := AnsiString(Pass);

    H := WhepConnect(PAnsiChar(URLAnsi), PAnsiChar(AuthAnsi),
                     PAnsiChar(UserAnsi), PAnsiChar(PassAnsi));
    AppLog(Format('WhepConnect retornou handle=%d', [H]));

    // TThread.Synchronize garante execução na main thread antes de continuar
    TThread.Synchronize(nil, procedure
    begin
      if GShutdown then
      begin
        Dec.Free;
        Player.Free;
        Exit;
      end;

      if H > 0 then
      begin
        // Registra o OnFrame AQUI: agora temos H e podemos capturá-lo no closure.
        // O lookup de ImgTarget é feito via GImages[H] em tempo de execução
        // do Queue — se a conexão já foi encerrada, TryGetValue retorna false
        // e o lambda sai sem acessar nada inválido.
        Dec.OnFrame := procedure(BGRA: PByte; W, FH, Stride: Integer)
        var
          Copy: TBytes;
          ConnHandle: Int32;
        begin
          if GShutdown then Exit;
          ConnHandle := H;
          SetLength(Copy, FH * Stride);
          Move(BGRA^, Copy[0], FH * Stride);
          TThread.Queue(nil, procedure
          var
            Img:     TImage;
            BmpData: TBitmapData;
            Bmp:     TBitmap;
            Y:       Integer;
          begin
            if GShutdown or (GImages = nil) then Exit;
            // Lookup em tempo de execução — seguro mesmo após DoDisconnect
            if not GImages.TryGetValue(ConnHandle, Img) then Exit;
            Bmp := Img.Bitmap;
            if (Bmp.Width <> W) or (Bmp.Height <> FH) then
              Bmp.SetSize(W, FH);
            if Bmp.Map(TMapAccess.Write, BmpData) then
            try
              for Y := 0 to FH - 1 do
                Move(Copy[Y * Stride],
                     (PByte(BmpData.Data) + Y * BmpData.Pitch)^,
                     W * 4);
            finally
              Bmp.Unmap(BmpData);
            end;
            Img.Repaint;
          end);
        end;

        PHandleOut^ := H;
        FDecoders.AddOrSetValue(H, Dec);
        FAudioPlayers.AddOrSetValue(H, Player);
        FImages.AddOrSetValue(H, ImgTarget);
        FStatusLabels.AddOrSetValue(H, LblTarget);
        FBtnConnect.AddOrSetValue(H, BtnConn);
        FBtnStop.AddOrSetValue(H, BtnStp);

        // Atualiza globals protegidos por lock
        GCallbackLock.Enter;
        try
          GDecoders.AddOrSetValue(H, Dec);
          GAudioPlayers.AddOrSetValue(H, Player);
          GImages.AddOrSetValue(H, ImgTarget);
        finally
          GCallbackLock.Leave;
        end;

        BtnStp.Enabled := True;
      end
      else
      begin
        Dec.Free;
        Player.Free;
        BtnConn.Enabled := True;
        LblTarget.Text  := Format('Erro: %d', [H]);
      end;
    end);
  end).Start;
end;

procedure TForm1.DoDisconnect(var HandleOut: Int32;
  BtnConn, BtnStp: TButton; LblTarget: TLabel);
var
  H:      Int32;
  Dec:    TVideoDecoder;
  Player: TAudioPlayer;
begin
  H := HandleOut;
  if H <= 0 then Exit;
  AppLog(Format('DoDisconnect handle=%d', [H]));

  // Remove dos globals primeiro — callbacks param de usar Dec/Player
  GCallbackLock.Enter;
  try
    GDecoders.Remove(H);
    GAudioPlayers.Remove(H);
    GImages.Remove(H);
  finally
    GCallbackLock.Leave;
  end;

  // Agora é seguro chamar WhepDisconnect — callbacks já não chegam mais
  WhepDisconnect(H);

  // Recupera e libera os objetos locais
  if FDecoders.TryGetValue(H, Dec) then
  begin
    FDecoders.Remove(H);
    Dec.Free;
  end;

  if FAudioPlayers.TryGetValue(H, Player) then
  begin
    FAudioPlayers.Remove(H);
    Player.Free;
  end;

  FImages.Remove(H);
  FStatusLabels.Remove(H);
  FBtnConnect.Remove(H);
  FBtnStop.Remove(H);

  HandleOut       := 0;
  BtnConn.Enabled := True;
  BtnStp.Enabled  := False;
  LblTarget.Text  := 'Desconectado';
end;

procedure TForm1.BtnConnect1Click(Sender: TObject);
begin
  DoConnect(EdtHost1.Text, EdtPort1.Text, EdtPath1.Text,
    EdtUser1.Text, EdtPass1.Text,
    ImgVideo1, LblStatus1, BtnConnect1, BtnStop1, FHandle1);
end;

procedure TForm1.BtnStop1Click(Sender: TObject);
begin
  DoDisconnect(FHandle1, BtnConnect1, BtnStop1, LblStatus1);
end;

procedure TForm1.BtnConnect2Click(Sender: TObject);
begin
  DoConnect(EdtHost2.Text, EdtPort2.Text, EdtPath2.Text,
    EdtUser2.Text, EdtPass2.Text,
    ImgVideo2, LblStatus2, BtnConnect2, BtnStop2, FHandle2);
end;

procedure TForm1.BtnStop2Click(Sender: TObject);
begin
  DoDisconnect(FHandle2, BtnConnect2, BtnStop2, LblStatus2);
end;

procedure TForm1.btnTransmitirClick(Sender: TObject);
begin
  FormWhip.Show;
end;

end.
