// Eduardo - 04/08/2024
unit chat.editor;

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
  FMX.Memo.Types,
  FMX.Objects,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo,
  chat.base,
  chat.tipos;

type
  TChatEditor = class(TChatBase)
    rtgMensagem: TRectangle;
    mmMensagem: TMemo;
    txtMensagem: TText;
    lytCarinha: TLayout;
    pthCarinha: TPath;
    lytAnexo: TLayout;
    pthAnexo: TPath;
    lytEnviar: TLayout;
    pthEnviar: TPath;
    rtgFundoMensagem: TRectangle;
    rtgFundoAnexo: TRectangle;
    rtgEditor: TRectangle;
    lytBotoes: TLayout;
    sbtCancelar: TSpeedButton;
    sbtAdicionar: TSpeedButton;
    lbTitulo: TLabel;
    vsbxConteudo: TVertScrollBox;
    odlgArquivo: TOpenDialog;
    procedure FrameResized(Sender: TObject);
    procedure mmMensagemChangeTracking(Sender: TObject);
    procedure mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lytAnexoClick(Sender: TObject);
    procedure lytEnviarClick(Sender: TObject);
    procedure lytCarinhaClick(Sender: TObject);
    procedure sbtAdicionarClick(Sender: TObject);
    procedure sbtCancelarClick(Sender: TObject);
  private
    FLarguraMaximaConteudo: Integer;
    FAoEnviar: TEventoEnvio;
    FAnexoExibindo: Boolean;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    procedure AdicionarItem(sArquivo: String);
    procedure AnexoRemoverClick(Sender: TObject);
    procedure RemoverItens;
    function Selecionados: TArray<String>;
  public
    procedure AfterConstruction; override;
    property LarguraMaximaConteudo: Integer read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property AoEnviar: TEventoEnvio read FAoEnviar write FAoEnviar;
  end;

implementation

uses
  System.StrUtils,
  System.Math,
  chat.so,
  chat.anexo.item;

const
  QUANTIDADE_VISIVEL = 5;

{$R *.fmx}

{ TEditor }

procedure TChatEditor.AfterConstruction;
begin
  inherited;
  mmMensagem.NeedStyleLookup;
  mmMensagem.ApplyStyleLookup;
  mmMensagem.StylesData['background.Source'] := nil;

  Self.Height := 40;
end;

procedure TChatEditor.FrameResized(Sender: TObject);
var
  TamanhoTexto: TRectF;
  cHeight: Single;
begin
  rtgMensagem.Width := Min(LarguraMaximaConteudo, Self.Width);

  if Self.Width > LarguraMaximaConteudo then
    rtgMensagem.Corners := [TCorner.TopLeft, TCorner.TopRight]
  else
    rtgMensagem.Corners := [];

  if not Assigned(mmMensagem.Canvas) then
    Exit;

  if mmMensagem.Width < 50 then
    Exit;

  TamanhoTexto := RectF(0, 0, mmMensagem.ContentSize.Width, 10000);
  mmMensagem.Canvas.MeasureText(TamanhoTexto, mmMensagem.Lines.Text, True, [], TTextAlign.Center, TTextAlign.Leading);
  cHeight := TamanhoTexto.Bottom + mmMensagem.Margins.Top + mmMensagem.Margins.Bottom;

  if cHeight > 40 then
    cHeight := cHeight + 5;
  rtgFundoMensagem.Height := Min(212, Max(40, cHeight));
  mmMensagem.ShowScrollBars := rtgFundoMensagem.Height > 200;

  if FAnexoExibindo then
    Self.Height := rtgFundoMensagem.Height + rtgFundoAnexo.Height
  else
    Self.Height := rtgFundoMensagem.Height;
end;

procedure TChatEditor.mmMensagemChangeTracking(Sender: TObject);
begin
  txtMensagem.Visible := mmMensagem.Lines.Text.IsEmpty;
  FrameResized(Self);
end;

procedure TChatEditor.mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkReturn) and (Shift = []) then
  begin
    Key := 0;
    KeyChar := #0;
    if Assigned(lytEnviar.OnClick) then
      lytEnviar.OnClick(lytEnviar);
  end;
end;

procedure TChatEditor.SetLarguraMaximaConteudo(const Value: Integer);
begin
  FLarguraMaximaConteudo := Value;
  FrameResized(Self);
end;

procedure TChatEditor.lytAnexoClick(Sender: TObject);
begin
  if FAnexoExibindo then
    Exit;

  FAnexoExibindo := True;

  Self.Height := rtgFundoMensagem.Height + 70;
end;

procedure TChatEditor.lytCarinhaClick(Sender: TObject);
begin
  ShowEmoji(mmMensagem);
end;

procedure TChatEditor.lytEnviarClick(Sender: TObject);
var
  Conteudo: TConteudo;
  Conteudos: TArray<TConteudo>;
begin
  if not Assigned(FAoEnviar) then
    Exit;

  Conteudos := [];

  if FAnexoExibindo then
  begin
    for var Item in Selecionados do
    begin
      Conteudo := Default(TConteudo);
      if IndexStr(ExtractFileExt(Item).Replace('.', EmptyStr), ['bmp', 'jpg', 'png']) >= 0 then
        Conteudo.Tipo := TTipo.Imagem
      else
        Conteudo.Tipo := TTipo.Arquivo;
      Conteudo.Conteudo := Item;
      Conteudos := Conteudos + [Conteudo];
    end;
    sbtCancelarClick(sbtCancelar);
  end;

  if not mmMensagem.Lines.Text.Trim.IsEmpty then
  begin
    Conteudo := Default(TConteudo);
    Conteudo.Tipo := TTipo.Texto;
    Conteudo.Conteudo := mmMensagem.Lines.Text.Trim;
    mmMensagem.Lines.Clear;
    Conteudos := Conteudos + [Conteudo];
  end;

  if Length(Conteudos) > 0 then
    FAoEnviar(Conteudos);
end;

procedure TChatEditor.sbtCancelarClick(Sender: TObject);
begin
  RemoverItens;
  FAnexoExibindo := False;
  FrameResized(Self);
end;

procedure TChatEditor.AdicionarItem(sArquivo: String);
var
  Anexo: TChatAnexoItem;
begin
  Anexo := TChatAnexoItem.Create(vsbxConteudo, sArquivo);
  vsbxConteudo.Position.Y := Pred(vsbxConteudo.ComponentCount) * Anexo.Height;
  Anexo.OnRemoverClick := AnexoRemoverClick;

  if Pred(vsbxConteudo.ComponentCount) <= QUANTIDADE_VISIVEL then
    Self.Height := rtgFundoMensagem.Height + rtgFundoAnexo.Height + 55;

  if Pred(vsbxConteudo.ComponentCount) <= QUANTIDADE_VISIVEL then
    rtgEditor.Width := 296
  else
    rtgEditor.Width := 310;
end;

procedure TChatEditor.AnexoRemoverClick(Sender: TObject);
begin
  vsbxConteudo.RemoveObject(TChatAnexoItem(Sender));
  TChatAnexoItem(Sender).Free;

  if Pred(vsbxConteudo.ComponentCount) < QUANTIDADE_VISIVEL then
    Self.Height := rtgFundoMensagem.Height + rtgFundoAnexo.Height - 55;

  if Pred(vsbxConteudo.ComponentCount) <= QUANTIDADE_VISIVEL then
    rtgEditor.Width := 296
  else
    rtgEditor.Width := 310;
end;

procedure TChatEditor.RemoverItens;
var
  I: Integer;
  Item: TChatAnexoItem;
begin
  for I := Pred(vsbxConteudo.ComponentCount) downto 0 do
  begin
    if vsbxConteudo.Components[I] is TChatAnexoItem then
    begin
      Item := vsbxConteudo.Components[I] as TChatAnexoItem;
      vsbxConteudo.RemoveObject(Item);
      Item.Free;
    end;
  end;
end;

procedure TChatEditor.sbtAdicionarClick(Sender: TObject);
begin
  if odlgArquivo.Execute then
    for var sArquivo in odlgArquivo.Files do
      AdicionarItem(sArquivo);
end;

function TChatEditor.Selecionados: TArray<String>;
var
  I: Integer;
  Item: TChatAnexoItem;
begin
  Result := [];
  for I := 0 to Pred(vsbxConteudo.ComponentCount) do
  begin
    if vsbxConteudo.Components[I] is TChatAnexoItem then
    begin
      Item := vsbxConteudo.Components[I] as TChatAnexoItem;
      Result := Result + [Item.Arquivo];
    end;
  end;
end;

end.
