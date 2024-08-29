unit Conversa.Chat.Listagem.Item;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.Objects,
  FMX.Layouts,
  FMX.Ani,
  FMX.ListBox,
  System.StrUtils,
  System.DateUtils,
  Conversa.Eventos,
  Conversa.FrameBase,
  Conversa.Tipos;

type
  TConversasItemFrame = class(TFrameBase)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtAbreviatura: TText;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    lytInformacoesBottom: TLayout;
    ColorAnimation1: TColorAnimation;
    txtMensagem: TText;
    txtDataHora: TText;
    rctCount: TRectangle;
    txtCount: TText;
    Timer1: TTimer;
    procedure lblUltimaMensagemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure rctFundoClick(Sender: TObject);
    procedure txtCountResized(Sender: TObject);
    procedure rctFundoMouseEnter(Sender: TObject);
    procedure rctFundoMouseLeave(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FConversa: TConversa;
    FUltimaMensagem: TDateTime;
    FOnClick: TProc<TConversasItemFrame>;
    FSelecionado: Boolean;
    function ConversaFormatDateTime(Value: TDateTime): String;
    procedure Configurar;
    procedure Atualizar(const Sender: TObject; const M: TMessage);
    procedure AtualizarContador(const Quantidade: Integer);
  public
    class function New(AOwner: TComponent; Conversa: TConversa): TConversasItemFrame; static;
    property Conversa: TConversa read FConversa;
    function Descricao(Value: string): TConversasItemFrame;
    function Mensagem(Value: string): TConversasItemFrame;
    function UltimaMensagem(Value: TDateTime): TConversasItemFrame;
    function OnClick(Value: TProc<TConversasItemFrame>): TConversasItemFrame;
    function Selecionado(const Value: Boolean): TConversasItemFrame;
  end;
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    Conversa: TConversa;
    ContatoItem: TConversasItemFrame;
  end;

implementation

{$R *.fmx}

class function TConversasItemFrame.New(AOwner: TComponent; Conversa: TConversa): TConversasItemFrame;
begin
  Result := TConversasItemFrame.Create(AOwner);
  Result.Parent := TFmxObject(AOwner);
  Result.Align := TAlignLayout.Client;
  Result.FConversa := Conversa;
  Result.AtualizarContador(0);
  Result.Configurar;
  Result.Selecionado(False);
end;

function TConversasItemFrame.OnClick(Value: TProc<TConversasItemFrame>): TConversasItemFrame;
begin
  Result := Self;
  FOnClick := Value;
end;

procedure TConversasItemFrame.rctFundoClick(Sender: TObject);
begin
  FOnClick(Self);
end;

procedure TConversasItemFrame.rctFundoMouseEnter(Sender: TObject);
begin
  inherited;
  if FSelecionado then
    Exit;

  ColorAnimation1.Inverse := False;
  ColorAnimation1.Start;
end;

procedure TConversasItemFrame.rctFundoMouseLeave(Sender: TObject);
begin
  inherited;
  if FSelecionado then
    Exit;

  ColorAnimation1.Inverse := True;
  ColorAnimation1.Start;
end;

function TConversasItemFrame.Selecionado(const Value: Boolean): TConversasItemFrame;
begin
  Result := Self;
  FSelecionado := Value;
  if Value then
    rctFundo.Fill.Color := $FFE3F1FF
  else
    rctFundo.Fill.Color := TAlphaColors.White;
end;

procedure TConversasItemFrame.txtCountResized(Sender: TObject);
begin
  inherited;
  rctCount.Width := txtCount.Width + 8;
end;

function TConversasItemFrame.Descricao(Value: string): TConversasItemFrame;
begin
  Result := Self;
  lblNome.Text := Value;
  if Value.Trim.IsEmpty then
    txtAbreviatura.Text := '?'
  else
    txtAbreviatura.Text := Value[1];
end;

procedure TConversasItemFrame.lblUltimaMensagemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
//  if FNextUpdateDateTime > Now then
//  lblUltimaMensagem.OnPaint := nil;
//  try
//    if DaysBetween(FUltimaMensagem, Now) > 0 then
//    begin
//      lblUltimaMensagem.Text := ConversaFormatDateTime(FUltimaMensagem);
//    end;
//  finally
//    lblUltimaMensagem.OnPaint := lblUltimaMensagemPaint;
//  end;
end;

function TConversasItemFrame.Mensagem(Value: string): TConversasItemFrame;
begin
  Result := Self;
  txtMensagem.Text := Value.Replace('&', '&&');
end;

function TConversasItemFrame.UltimaMensagem(Value: TDateTime): TConversasItemFrame;
begin
  Result := Self;
  FUltimaMensagem := Value;
  txtDataHora.Text := ConversaFormatDateTime(FUltimaMensagem);
end;

procedure TConversasItemFrame.Atualizar(const Sender: TObject; const M: TMessage);
begin
  AtualizarContador(FConversa.MensagemSemVisualizar);
end;

procedure TConversasItemFrame.Configurar;
begin
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoAtualizarContadorConversa, Atualizar);
end;

procedure TConversasItemFrame.AtualizarContador(const Quantidade: Integer);
begin
  Timer1.Enabled := True;
end;

procedure TConversasItemFrame.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  Self.BeginUpdate;
  try
    if FConversa.MensagemSemVisualizar <= 0 then
    begin
      lblNome.TextSettings.Font.Style := lblNome.TextSettings.Font.Style - [TFontStyle.fsBold];
      txtMensagem.TextSettings.Font.Style := txtMensagem.TextSettings.Font.Style - [TFontStyle.fsBold];
      txtDataHora.TextSettings.Font.Style := txtDataHora.TextSettings.Font.Style - [TFontStyle.fsBold];
      rctCount.Visible := False;
      Exit;
    end;

    lblNome.TextSettings.Font.Style := lblNome.TextSettings.Font.Style + [TFontStyle.fsBold];
    txtMensagem.TextSettings.Font.Style := txtMensagem.TextSettings.Font.Style + [TFontStyle.fsBold];
    txtDataHora.TextSettings.Font.Style := txtDataHora.TextSettings.Font.Style + [TFontStyle.fsBold];

    rctCount.Visible := True;
    txtCount.Text := FConversa.MensagemSemVisualizar.ToString;
  finally
    Self.EndUpdate;
    Self.Repaint;
  end;
end;

function TConversasItemFrame.ConversaFormatDateTime(Value: TDateTime): String;
begin
  if Value = 0 then
    Exit(EmptyStr)
  else
  if DaysBetween(Value, Now) = 0 then
    Result := TimeToStr(Value)
  else
    Exit(DateToStr(Value));
end;

end.
