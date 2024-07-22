unit Conversa.Notificacao.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects,
  FMX.Effects,
  FMX.Layouts,
  System.StrUtils,
  System.Math,
  Conversa.Notificacao;

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
    Path1: TPath;
    lytConteudo: TLayout;
    pbTexto: TPaintBox;
    txtNome: TText;
    txtUserLetra: TText;
    procedure pbTextoPaint(Sender: TObject; Canvas: TCanvas);
    procedure lytCloseButtonClick(Sender: TObject);
  private
    FChatId: Integer;
    FConteudos: TArray<TMensagemNotificacao>;
  public
    class function New(AOwner: TFmxObject): TNotificacaoItem;
    procedure AtualizarConteudo(AChatId: Integer; AConteudos: TArray<TMensagemNotificacao>);
  end;

implementation

uses
  FMX.TextLayout;

{$R *.fmx}

{ TNotificacao }

class function TNotificacaoItem.New(AOwner: TFmxObject): TNotificacaoItem;
begin
  Sleep(1);
  Result := TNotificacaoItem.Create(AOwner);
  Result.Name := 'TNotificacaoItem_'+ FormatDateTime('yyyyymmddHHnnsszzzz', Now);
  Result.Parent := AOwner;
  Result.Align := TAlignLayout.Top;
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
    Layout.MaxSize := TPointF.Create(pbTexto.Width, pbTexto.Height);
    Layout.BeginUpdate;
    try
      Layout.Text := Text;
      Layout.Color := TAlphaColors.White;
      Layout.WordWrap := False;
      BoldFont := TFont.Create;
      BoldFont.Assign(Layout.Font);
      BoldFont.Style := [TFontStyle.fsBold];
      for I := 0 to Pred(Length(ANConteudos)) do
        Layout.AddAttribute(
          TTextAttributedRange.Create(
            TTextRange.Create(ANConteudos[I].InicioNome, ANConteudos[I].Nome.Length),
            TTextAttribute.Create(BoldFont, TAlphaColors.Black)
          )
        );
      Layout.WordWrap := True;
      Layout.HorizontalAlign := TTextAlign.Leading;
      Layout.VerticalAlign := TTextAlign.Leading;
    finally
      Layout.EndUpdate;
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
  FChatId := AChatId;
  FConteudos := AConteudos;
  pbTexto.Repaint;
end;

procedure TNotificacaoItem.lytCloseButtonClick(Sender: TObject);
begin
  TNotificacaoManager.Fechar(FChatId);
end;

end.
