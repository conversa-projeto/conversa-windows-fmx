unit Conversa.Notificacao.Item;

interface

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Effects,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.TextLayout,
  FMX.Types,
  Conversa.Eventos,
  Conversa.Notificacao, FMX.Ani;

type
  TNotificacaoItem = class(TFrame)
    rctFundo: TRectangle;
    txtHora: TText;
    lytTopo: TLayout;
    lytCentro: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtTitulo: TText;
    lytCloseButton: TLayout;
    rctClose: TRectangle;
    lytClose: TLayout;
    pthClose: TPath;
    lytConteudo: TLayout;
    pbTexto: TPaintBox;
    txtNome: TText;
    txtUserLetra: TText;
    FloatAnimation: TFloatAnimation;
    procedure pbTextoPaint(Sender: TObject; Canvas: TCanvas);
    procedure lytCloseButtonClick(Sender: TObject);
    procedure FloatAnimationFinish(Sender: TObject);
    procedure rctFundoClick(Sender: TObject);
  private
    FChatId: Integer;
    FConteudos: TArray<TMensagemNotificacao>;
    procedure RegistrarEvento;
    procedure StatusIniciarAnimacao(const Sender: TObject; const M: TMessage);
  public
    class function New(AOwner: TFmxObject): TNotificacaoItem;
    destructor Destroy; override;
    procedure AtualizarConteudo(AChatId: Integer; AConteudos: TArray<TMensagemNotificacao>);
    procedure AtualizarAltura(iTexto: Single);
  end;

implementation

{$R *.fmx}

uses
  Conversa.Dados,
  Conversa.Configuracoes,
  Conversa.Chat.Listagem,
  Conversa.Tela.Inicial.view,
  Conversa.Windows.UserActivity;

{ TNotificacao }

class function TNotificacaoItem.New(AOwner: TFmxObject): TNotificacaoItem;
begin
  Sleep(1);
  Result := TNotificacaoItem.Create(AOwner);
  Result.Name := 'TNotificacaoItem_'+ FormatDateTime('yyyyymmddHHnnsszzzz', Now);
  Result.Parent := AOwner;
  Result.Align := TAlignLayout.Top;
  Result.FloatAnimation.Delay := Configuracoes.Notificacoes.Timeout;
  Result.FloatAnimation.Enabled := StatusUsuarioSO = TStatusUsuarioSO.Ativo;
  Result.RegistrarEvento;
  Result.Show;
end;

procedure TNotificacaoItem.pbTextoPaint(Sender: TObject; Canvas: TCanvas);
const
  QuantidadeMaximaExibida = 5;
  QuantidadeMaximaObterArray = 4;
  IndexArrayMaximo = 3;
type
  TConteudoNotify = record
    Nome: String;
    Mensagem: string;
    InicioNome: Integer;
  end;
var
  ANConteudos: TArray<TConteudoNotify>;
  Layout: TTextLayout;
  Text: string;
  Attributes: TArray<TTextAttributedRange>;
  BoldFont: TFont;
  bNome: Boolean;
  I: Integer;
  iLas: Integer;
  iMax: Integer;
begin
  Text := EmptyStr;
  bNome := False;
  iMax := IfThen(Length(FConteudos) > QuantidadeMaximaExibida, IndexArrayMaximo, Pred(Length(FConteudos)));

  for I := 0 to iMax do
    bNome := bNome or not FConteudos[I].Usuario.Trim.IsEmpty;

  iLas := 0;
  SetLength(ANConteudos, Succ(iMax));
  for I := 0 to iMax do
  begin
    if bNome then
      ANConteudos[I].Nome := IfThen(FConteudos[I].Usuario.Trim.IsEmpty, 'desconhecido', FConteudos[I].Usuario) +': '
    else
      ANConteudos[I].Nome := EmptyStr;

    ANConteudos[I].Mensagem := FConteudos[I].Mensagem;
    ANConteudos[I].InicioNome := iLas;
    iLas := iLas + ANConteudos[I].Nome.Length + String(sLineBreak).Length + ANConteudos[I].Mensagem.Length;
  end;

  for I := 0 to Pred(Length(ANConteudos)) do
    Text := Text + IfThen(I > 0, sLineBreak) + ANConteudos[I].Nome + ANConteudos[I].Mensagem;

  if Length(FConteudos) > QuantidadeMaximaExibida then
    Text := Text + sLineBreak +'+'+ ((Length(FConteudos) - QuantidadeMaximaObterArray)).ToString;

  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.MaxSize := TPointF.Create(pbTexto.Width, 500);
    Layout.BeginUpdate;
    try
      Layout.Text := Text;
      Layout.Color := TAlphaColors.White;
      Layout.Opacity := Self.Opacity;
      Layout.WordWrap := False;
      BoldFont := TFont.Create;
      try
        BoldFont.Assign(Layout.Font);
        BoldFont.Style := [TFontStyle.fsBold];
        for I := 0 to Pred(Length(ANConteudos)) do
          Layout.AddAttribute(
            TTextAttributedRange.Create(
              TTextRange.Create(ANConteudos[I].InicioNome, ANConteudos[I].Nome.Length),
              TTextAttribute.Create(BoldFont, TAlphaColors.White)
            )
          );
      finally
        FreeAndNil(BoldFont);
      end;
      Layout.HorizontalAlign := TTextAlign.Leading;
      Layout.VerticalAlign := TTextAlign.Leading;
    finally
      Layout.EndUpdate;
      Layout.TextHeight
    end;
    pbTexto.Canvas.BeginScene;
    try
      Layout.RenderLayout(pbTexto.Canvas);
    finally
      pbTexto.Canvas.EndScene;
    end;
  finally
    Layout.Free;
  end;
end;

procedure TNotificacaoItem.AtualizarConteudo(AChatId: Integer; AConteudos: TArray<TMensagemNotificacao>);
begin
  FloatAnimation.OnFinish := nil;
  try
    FloatAnimation.Enabled := False;
    FloatAnimation.Enabled := StatusUsuarioSO = TStatusUsuarioSO.Ativo;
  finally
    FloatAnimation.OnFinish := FloatAnimationFinish;
  end;
  FChatId := AChatId;
  FConteudos := AConteudos;
  pbTexto.Repaint;
end;

destructor TNotificacaoItem.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TEventoMudancaStatusUsuarioSO, StatusIniciarAnimacao);
  inherited;
end;

procedure TNotificacaoItem.FloatAnimationFinish(Sender: TObject);
begin
  TNotificacaoManager.Fechar(FChatId);
end;

procedure TNotificacaoItem.lytCloseButtonClick(Sender: TObject);
begin
  TNotificacaoManager.Fechar(FChatId);
end;

procedure TNotificacaoItem.rctFundoClick(Sender: TObject);
begin
  TNotificacaoManager.Fechar(FChatId);
  Chats.AbrirChat(Dados.FDadosApp.Conversas.GetOrAdd(FChatId));
  TelaInicial.DoConversaRestore;
end;

procedure TNotificacaoItem.RegistrarEvento;
begin
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoMudancaStatusUsuarioSO, StatusIniciarAnimacao);
end;

procedure TNotificacaoItem.StatusIniciarAnimacao(const Sender: TObject; const M: TMessage);
begin
  if not Assigned(Self) or (csDestroying in Self.ComponentState) then
  begin
    TMessageManager.DefaultManager.Unsubscribe(TEventoMudancaStatusUsuarioSO, StatusIniciarAnimacao);
    Exit;
  end;

  if not FloatAnimation.Enabled then
    FloatAnimation.Enabled := StatusUsuarioSO = TStatusUsuarioSO.Ativo;
end;

procedure TNotificacaoItem.AtualizarAltura(iTexto: Single);
var
  iNova: Single;
begin
  iNova := Min(lytTopo.Height + txtNome.Height + txtHora.Height + iTexto, 200);
  if Self.Height <> iNova then
    Self.Height := iNova;
end;

end.
