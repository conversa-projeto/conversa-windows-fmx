// Eduardo - 04/08/2024
unit chat.conteudo.mensagem.audio;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Media,
  chat.mensagem.conteudo, System.UITypes;

type
  TChatConteudoMensagemAudio = class(TChatConteudo)
    pthPlay: TPath;
    lytDados: TLayout;
    lytCircle: TLayout;
    crclAction: TCircle;
    pthPause: TPath;
    txtInformacoes: TText;
    lytProgress: TLayout;
    lnProgress: TLine;
    crcPosition: TCircle;
    tmrExecucao: TTimer;
    procedure FrameClick(Sender: TObject);
    procedure tmrExecucaoTimer(Sender: TObject);
    procedure lytProgressMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure lytProgressMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure lytProgressMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure lytProgressMouseLeave(Sender: TObject);
  private
    FPlayer: TMediaPlayer;
    FClickMove: Boolean;
    FSize: String;
    procedure Play;
    procedure Pausar;
    procedure Parar;
  public
    procedure AfterConstruction; override;
    function Target(Largura: Single): TTarget; override;
    procedure SetFile(const Path: String);
  end;

implementation

{$R *.fmx}

procedure TChatConteudoMensagemAudio.AfterConstruction;
begin
  inherited;
  pthPause.Visible := False;
  FPlayer := TMediaPlayer.Create(Self);
end;

{ TAnexo }

procedure TChatConteudoMensagemAudio.FrameClick(Sender: TObject);
begin
  if pthPlay.Visible then
    Play
  else
    Pausar;
end;

procedure TChatConteudoMensagemAudio.SetFile(const Path: String);
begin
  FPlayer.FileName := Path;
  FSize := IntToStr(Trunc(TFile.GetSize(Path) / 1024)) +' kb';
  txtInformacoes.Text := FPlayer.Duration.ToString +', '+ FSize;
end;

function TChatConteudoMensagemAudio.Target(Largura: Single): TTarget;
begin
  Result.Width := 250;
  Result.Height := 40;
end;

procedure TChatConteudoMensagemAudio.tmrExecucaoTimer(Sender: TObject);
begin
  if (FPlayer.CurrentTime = FPlayer.Duration) then
  begin
    Parar;
    Exit;
  end
  else
  if (FPlayer.CurrentTime = 0) then
    crcPosition.Position.X := 0
  else
    crcPosition.Position.X := (lytProgress.Width * (FPlayer.CurrentTime / FPlayer.Duration)) - (crcPosition.Width / 2);

  txtInformacoes.Text := FPlayer.CurrentTime.ToString +' / '+ FPlayer.Duration.ToString;
end;

procedure TChatConteudoMensagemAudio.lytProgressMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FClickMove := Button = TMouseButton.mbLeft;
  FPlayer.CurrentTime := Ceil(FPlayer.Duration * (X / lytProgress.Width));
  tmrExecucaoTimer(tmrExecucao);
end;

procedure TChatConteudoMensagemAudio.lytProgressMouseLeave(Sender: TObject);
begin
  FClickMove := False;
end;

procedure TChatConteudoMensagemAudio.lytProgressMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FClickMove then
  begin
    FPlayer.CurrentTime := Ceil(FPlayer.Duration * (X / lytProgress.Width));
    tmrExecucaoTimer(tmrExecucao);
  end;
end;

procedure TChatConteudoMensagemAudio.lytProgressMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FClickMove := False;
end;

procedure TChatConteudoMensagemAudio.Play;
begin
  pthPlay.Visible := False;
  pthPause.Visible := True;
  tmrExecucaoTimer(tmrExecucao);
  tmrExecucao.Enabled := True;
  FPlayer.Play;
end;

procedure TChatConteudoMensagemAudio.Parar;
begin
  tmrExecucao.Enabled := False;
  FPlayer.Stop;
  FPlayer.CurrentTime := 0;
  crcPosition.Position.X := 0;
  pthPlay.Visible := True;
  pthPause.Visible := False;
  txtInformacoes.Text := FPlayer.Duration.ToString +', '+ FSize;
end;

procedure TChatConteudoMensagemAudio.Pausar;
begin
  FPlayer.Stop;
  pthPlay.Visible := True;
  pthPause.Visible := False;
  tmrExecucao.Enabled := False;
  tmrExecucaoTimer(tmrExecucao);
end;

end.
