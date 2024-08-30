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
    lytAnexo: TLayout;
    lytEnviar: TLayout;
    rtgFundoMensagem: TRectangle;
    rtgFundoAnexo: TRectangle;
    rtgEditor: TRectangle;
    lbTitulo: TLabel;
    vsbxConteudo: TVertScrollBox;
    odlgArquivo: TOpenDialog;
    lytCancelar: TLayout;
    pthCancelar: TPath;
    lytBAnexo: TLayout;
    pthAnexo: TPath;
    lytBCarinha: TLayout;
    pthCarinha: TPath;
    lytBEnviar: TLayout;
    pthEnviar: TPath;
    procedure FrameResized(Sender: TObject);
    procedure mmMensagemChangeTracking(Sender: TObject);
    procedure mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lytAnexoClick(Sender: TObject);
    procedure lytEnviarClick(Sender: TObject);
    procedure lytCarinhaClick(Sender: TObject);
    procedure lytCancelarClick(Sender: TObject);
  private
    FLarguraMaximaConteudo: Integer;
    FAoEnviar: TEventoEnvio;
    FAnexoExibindo: Boolean;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    procedure AnexoRemoverClick(Sender: TObject);
    procedure RemoverItens;
    function Selecionados: TArray<String>;
    function AlturaAnexos: Single;
  public
    procedure AfterConstruction; override;
    procedure AdicionarAnexo(sArquivo: String);
    property LarguraMaximaConteudo: Integer read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property AoEnviar: TEventoEnvio read FAoEnviar write FAoEnviar;
  end;

implementation

uses
  System.StrUtils,
  System.Math,
  System.IOUtils,
  FMX.Clipboard,
  FMX.Platform,
  FMX.Surfaces,
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
  FAnexoExibindo := False;
  rtgEditor.Corners := [TCorner.TopLeft, TCorner.TopRight];
end;

procedure TChatEditor.FrameResized(Sender: TObject);
var
  TamanhoTexto: TRectF;
  cHeight: Single;
begin
  rtgMensagem.Width := Min(LarguraMaximaConteudo, Self.Width);
  rtgEditor.Width := rtgMensagem.Width;

  if FAnexoExibindo or (Self.Width <= LarguraMaximaConteudo) then
    rtgMensagem.Corners := []
  else
    rtgMensagem.Corners := [TCorner.TopLeft, TCorner.TopRight];

  if Self.Width <= LarguraMaximaConteudo then
    rtgEditor.Corners := []
  else
    rtgEditor.Corners := [TCorner.TopLeft, TCorner.TopRight];

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
    Self.Height := rtgFundoMensagem.Height + AlturaAnexos
  else
    Self.Height := rtgFundoMensagem.Height;
end;

procedure TChatEditor.mmMensagemChangeTracking(Sender: TObject);
begin
  txtMensagem.Visible := mmMensagem.Lines.Text.IsEmpty;
  FrameResized(Self);
end;

procedure TChatEditor.mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
var
  svc: IFMXExtendedClipboardService;
  Bmp: TBitmapSurface;
  sTemp: String;
begin
  if (Key = vkReturn) and (Shift = []) then
  begin
    Key := 0;
    KeyChar := #0;
    if Assigned(lytBEnviar.OnClick) then
      lytBEnviar.OnClick(lytBEnviar);
  end
  else
  if (Shift = [ssCtrl]) and (Key = vkV) then
  begin
    if not TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, svc) then
      Exit;

    if not svc.HasImage then
      Exit;

    sTemp := ExtractFilePath(ParamStr(0)) +'clipboard';

    if not TDirectory.Exists(sTemp) then
      TDirectory.CreateDirectory(sTemp);

    sTemp := sTemp + PathDelim +'clipboard'+ Length(TDirectory.GetFiles(sTemp)).ToString +'.png';

    Bmp := svc.GetImage;
    try
      if not TBitmapCodecManager.SaveToFile(sTemp, Bmp, nil) then
        raise EBitmapSavingFailed.Create('Erro ao converter a imagem do clipboard para png!');
    finally
      FreeAndNil(Bmp);
    end;

    AdicionarAnexo(sTemp);
  end;
end;

procedure TChatEditor.SetLarguraMaximaConteudo(const Value: Integer);
begin
  FLarguraMaximaConteudo := Value;
  FrameResized(Self);
end;

procedure TChatEditor.lytAnexoClick(Sender: TObject);
begin
  if odlgArquivo.Execute then
    for var sArquivo in odlgArquivo.Files do
      AdicionarAnexo(sArquivo);
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
      if IndexStr(ExtractFileExt(Item).Replace('.', EmptyStr).ToLower, TipoArquivoImagem) >= 0 then
        Conteudo.Tipo := TTipo.Imagem
      else
        Conteudo.Tipo := TTipo.Arquivo;
      Conteudo.Conteudo := Item;
      Conteudos := Conteudos + [Conteudo];
    end;
    lytCancelarClick(lytCancelar);
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

procedure TChatEditor.AdicionarAnexo(sArquivo: String);
var
  Anexo: TChatAnexoItem;
begin
  if not FAnexoExibindo then
    FAnexoExibindo := True;

  Anexo := TChatAnexoItem.Create(vsbxConteudo, sArquivo);
  Anexo.Position.Y := -1;
  Anexo.OnRemoverClick := AnexoRemoverClick;

  vsbxConteudo.ShowScrollBars := Pred(vsbxConteudo.ComponentCount) > QUANTIDADE_VISIVEL;
  if not vsbxConteudo.ShowScrollBars then
    Self.Height := rtgFundoMensagem.Height + AlturaAnexos;
end;

procedure TChatEditor.AnexoRemoverClick(Sender: TObject);
begin
  vsbxConteudo.RemoveObject(TChatAnexoItem(Sender));
  TChatAnexoItem(Sender).Free;

  vsbxConteudo.ShowScrollBars := Pred(vsbxConteudo.ComponentCount) > QUANTIDADE_VISIVEL;
  if not vsbxConteudo.ShowScrollBars then
    Self.Height := rtgFundoMensagem.Height + AlturaAnexos;

  if Pred(vsbxConteudo.ComponentCount) = 0 then
    lytCancelarClick(lytCancelar);
end;

function TChatEditor.AlturaAnexos: Single;
begin
  Result := (Pred(vsbxConteudo.ComponentCount) * 50) + lbTitulo.Margins.Top + lbTitulo.Margins.Bottom + rtgEditor.Padding.Top + rtgEditor.Padding.Bottom + 20;
end;

procedure TChatEditor.lytCancelarClick(Sender: TObject);
begin
  RemoverItens;
  FAnexoExibindo := False;
  FrameResized(Self);
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
