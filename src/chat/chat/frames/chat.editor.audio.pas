unit chat.editor.audio;

interface

uses
  System.Classes,
  System.DateUtils,
  System.IOUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  FMX.Ani,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Media,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  FMX.Text,
  chat.tipos,
  Chat.Editor.Base;

type
  TChatEditorAudio = class(TChatEditorBase)
    lytEditorAudio: TLayout;
    lytBotoesAudio: TLayout;
    lytBloquearCapturaAudio: TLayout;
    crclBloquearCapturaAudio: TCircle;
    pthBloquearCapturaAudio: TPath;
    lytCapturaAudio: TLayout;
    crclBotaoEnviaAudio: TCircle;
    pthMicrofoneAudio: TPath;
    pthEnviarAudio: TPath;
    lytAudio: TLayout;
    crclStatusGravacao: TCircle;
    txtDuracaoAudio: TText;
    txtAvisoAudio: TText;
    aniGravacao: TFloatAnimation;
    aniCorCancelamentoBotao: TColorAnimation;
    aniCorCancelamentoMicrofone: TColorAnimation;
    tmrCaptura: TTimer;
    procedure MouseEvent_EnviaAudio(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure crclBloquearCapturaAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure lytBotoesAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure lytEditorAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure lytEditorAudioMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure txtAvisoAudioClick(Sender: TObject);
    procedure tmrCapturaTimer(Sender: TObject);
  private
    FAudioPath: String;
    FBloqueado: Boolean;
    FCapturando: Boolean;
    FStatusCancelamento: Boolean;
    FAudioCapture: TAudioCaptureDevice;
    FStartCapture: TDateTime;
    procedure CorCancelamentoAudio;
    procedure RevertCorCancelamentoAudio;
    procedure LimparArquivo;
  public
    procedure AfterConstruction; override;
    function TemConteudo: Boolean; override;
    procedure Iniciar;
    procedure Bloquear;
    procedure Parar;
    procedure Cancelar;
    procedure Enviar;
    procedure Limpar; override;
    property AudioPath: String read FAudioPath;
    function Conteudo: TConteudo;
  end;

implementation

{$R *.fmx}

uses
  Chat.Editor;

type
  TChatEditorTextoHelper = class Helper for TChatEditorAudio
    function Editor: TChatEditor;
  end;

  TFormHack = class(TForm);

{ TChatEditorTextoHelper }

function TChatEditorTextoHelper.Editor: TChatEditor;
begin
  Result := TChatEditor(FEditor);
end;

{ TChatEditorAudio }

procedure TChatEditorAudio.AfterConstruction;
begin
  inherited;
  FAudioPath := EmptyStr;
  pthEnviarAudio.Visible := False;
  Self.Height := 50;
  FAudioCapture := TCaptureDeviceManager.Current.DefaultAudioCaptureDevice;
end;

procedure TChatEditorAudio.MouseEvent_EnviaAudio(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FCapturando then
    Enviar;
end;

procedure TChatEditorAudio.crclBloquearCapturaAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Bloquear;
end;

procedure TChatEditorAudio.lytBotoesAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // Se soltou na parte inferior, envia o áudio
  if Y > (TLayout(Sender).Height / 2) then
    Enviar;
end;

procedure TChatEditorAudio.lytEditorAudioMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FBloqueado then
    Exit;

  // Se chegou ao limite de bloqueio
  if Y <= lytBloquearCapturaAudio.Height then
    Bloquear
  else
  // Se mouse está sobre botão de ação
  if lytCapturaAudio.LocalRect.Contains(lytCapturaAudio.ScreenToLocal(Screen.MousePos)) then
    RevertCorCancelamentoAudio
  else
    CorCancelamentoAudio;
end;

procedure TChatEditorAudio.lytEditorAudioMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if crclBotaoEnviaAudio.LocalRect.Contains(crclBotaoEnviaAudio.ScreenToLocal(Screen.MousePos)) then
    Enviar
  else
  if (Y > (TLayout(Sender).Height / 2)) and lytBotoesAudio.LocalRect.Contains(lytBotoesAudio.ScreenToLocal(Screen.MousePos)) then
    Enviar
  else
  if not FBloqueado or lytAudio.LocalRect.Contains(lytAudio.ScreenToLocal(Screen.MousePos)) then
    Cancelar
end;

procedure TChatEditorAudio.Iniciar;
var
  Last: TFmxObject;
begin
  RevertCorCancelamentoAudio;
  aniGravacao.Enabled := False;

  LimparArquivo;

  FBloqueado := False;
  FCapturando := True;
  lytBloquearCapturaAudio.Visible := True;
  txtAvisoAudio.Text := 'Solte para enviar, ou deslize para cancelar';
  txtAvisoAudio.HitTest := False;

  FAudioPath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetCachePath, 'Conversa_Mensagem_Audio'+ FormatDateTime('yyyy-mm-dd-HH-nn-ss', Now) +'.mp3');
  FAudioCapture.FileName := FAudioPath;
  FAudioCapture.StartCapture;
  FStartCapture := Now;
  pthMicrofoneAudio.Fill.Color := TAlphaColors.Red;
  tmrCaptura.Enabled := True;
  aniGravacao.Start;

  // Captura de Mouse para segurar eventos
  Last := Parent;
  while Assigned(Last) and Last.HasParent do
    Last := Last.Parent;

  if Assigned(Last) and Last.InheritsFrom(TForm) then
    TFormHack(Last).SetCaptured(TControl(lytEditorAudio));
end;

procedure TChatEditorAudio.Bloquear;
begin
  if FBloqueado then
    Exit;

  FBloqueado := True;
  txtAvisoAudio.Text := 'Cancelar';
  txtAvisoAudio.HitTest := True;
  lytBloquearCapturaAudio.Visible := False;
  pthMicrofoneAudio.Visible := False;
  pthEnviarAudio.Visible := True;
  RevertCorCancelamentoAudio;
end;

procedure TChatEditorAudio.Parar;
begin
  if not FCapturando then
    Exit;

  FCapturando := False;
  pthMicrofoneAudio.Fill.Color := $FF007DFF;
  FAudioCapture.StopCapture;
  RevertCorCancelamentoAudio;
  tmrCaptura.Enabled := False;
  tmrCapturaTimer(tmrCaptura);
  aniGravacao.Stop;
end;

procedure TChatEditorAudio.Cancelar;
begin
  Parar;
  LimparArquivo;
  RevertCorCancelamentoAudio;
  Editor.AtualizarAction;
  Editor.SetEditor(TTipoEditor.Texto);
  Editor.AtualizarRedimensionamento;
end;

procedure TChatEditorAudio.Enviar;
begin
  Parar;
  Editor.Enviar;
  Editor.SetEditor(TTipoEditor.Texto);
  Editor.AtualizarAction;
end;

procedure TChatEditorAudio.LimparArquivo;
begin
  if not FAudioPath.Trim.IsEmpty and TFile.Exists(FAudioPath) then
    TFile.Delete(FAudioPath);

  FAudioPath := EmptyStr;
end;

procedure TChatEditorAudio.CorCancelamentoAudio;
begin
  if FBloqueado then
    Exit;

  if FStatusCancelamento then
    Exit;

  aniCorCancelamentoBotao.Inverse := False;
  aniCorCancelamentoBotao.StartFromCurrent := True;
  aniCorCancelamentoBotao.Start;
  aniCorCancelamentoMicrofone.Inverse := False;
  aniCorCancelamentoMicrofone.StartFromCurrent := True;
  aniCorCancelamentoMicrofone.Start;
  FStatusCancelamento := True;
end;

procedure TChatEditorAudio.RevertCorCancelamentoAudio;
begin
  if not FStatusCancelamento then
    Exit;

  if not FCapturando then
    Exit;

  aniCorCancelamentoBotao.Inverse := True;
  aniCorCancelamentoBotao.StartFromCurrent := False;
  aniCorCancelamentoBotao.Start;
  aniCorCancelamentoMicrofone.Inverse := True;
  aniCorCancelamentoMicrofone.StartFromCurrent := False;
  aniCorCancelamentoMicrofone.Start;
  FStatusCancelamento := False;
end;

procedure TChatEditorAudio.txtAvisoAudioClick(Sender: TObject);
begin
  Cancelar;
end;

function TChatEditorAudio.TemConteudo: Boolean;
begin
  Result := TFile.Exists(FAudioPath);
end;

procedure TChatEditorAudio.Limpar;
begin
  LimparArquivo;
end;

procedure TChatEditorAudio.tmrCapturaTimer(Sender: TObject);
var
  NowCurrent: TDateTime;
  Minutes: Int64;
  Seconds: Int64;
  MSeconds: Int64;
begin
  if Assigned(FAudioCapture) and (FAudioCapture.State = TCaptureDeviceState.Capturing) and (FStartCapture <> 0) then
  begin
    NowCurrent := Now;
    Minutes := MinutesBetween(FStartCapture, NowCurrent);
    Seconds := SecondsBetween(FStartCapture, NowCurrent);
    MSeconds := MilliSecondsBetween(FStartCapture, NowCurrent);
    txtDuracaoAudio.Text := Minutes.ToString.PadLeft(2, '0') +':'+ (Seconds - (SecsPerMin * Minutes)).ToString.PadLeft(2, '0') +','+ (MSeconds - (MSecsPerSec * Seconds)).ToString.PadRight(3, '0');
  end;
end;

function TChatEditorAudio.Conteudo: TConteudo;
begin
  Result := TConteudo.Create(TTipo.MensagemAudio, FAudioPath);
end;

end.
