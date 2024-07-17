unit Notificacao.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects,
  FMX.Effects,
  FMX.Layouts,
  System.StrUtils,
  Notificacao;

type
  TNotificacaoItem = class(TFrame)
    rctFundo: TRectangle;
    txtHora: TText;
    lytTopo: TLayout;
    lytResposta: TLayout;
    lytCentro: TLayout;
    lytFoto: TLayout;
    Circle1: TCircle;
    rctResposta: TRectangle;
    txtTitulo: TText;
    lytCloseButton: TLayout;
    rctClose: TRectangle;
    lytClose: TLayout;
    PaintBox1: TPaintBox;
    Path1: TPath;
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
  private
    FConteudos: TArray<TMensagemNotificacao>;
  public
    class function New(AOwner: TFmxObject): TNotificacaoItem;
    procedure AtualizarConteudo(AConteudos: TArray<TMensagemNotificacao>);
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

procedure TNotificacaoItem.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
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
begin
  Text := EmptyStr;
  bNome := False;
  for I := 0 to Pred(Length(FConteudos)) do
    bNome := bNome or not FConteudos[I].Usuario.Trim.IsEmpty;

  iLas := 0;
  SetLength(ANConteudos, Length(FConteudos));
  for I := 0 to Pred(Length(FConteudos)) do
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

  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.MaxSize := TPointF.Create(PaintBox1.Width, PaintBox1.Height);
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
    PaintBox1.Canvas.BeginScene;
    try
      Layout.RenderLayout(PaintBox1.Canvas);
    finally
      PaintBox1.Canvas.EndScene;
    end;
  finally
    Layout.Free;
  end;
end;

procedure TNotificacaoItem.AtualizarConteudo(AConteudos: TArray<TMensagemNotificacao>);
begin
  FConteudos := AConteudos;
  PaintBox1.Repaint;
//  PaintBox1.Visible := False;
//  PaintBox1.Visible := True;
//  PaintBox1.Repaint;
end;

end.
