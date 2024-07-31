// Eduardo - 03/03/2024
unit Mensagem.Anexo;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.IOUtils,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Layouts,
  FMX.Objects,
  FMX.Memo.Types,
  FMX.StdCtrls,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Controls.Presentation,
  FMX.ListBox,
  FMX.Styles,
  System.Messaging,
  Mensagem.Tipos;

type
  TAnexo = class
  private
    odlgArquivo: TOpenDialog;
    StyleBook: TStyleBook;
    lytEditorAnexo: TLayout;
    rtgEditor: TRectangle;
    lytBotoes: TLayout;
    sbtCancelar: TSpeedButton;
    sbtEnviar: TSpeedButton;
    sbtAdicionar: TSpeedButton;
    lbTitulo: TLabel;
    lbxAnexos: TListBox;
    procedure sbtAdicionarClick(Sender: TObject);
    procedure sbtCancelarClick(Sender: TObject);
    procedure sbtRemoverClick(Sender: TObject);
    procedure sbtEnviarClick(Sender: TObject);
  private const
    QUANTIDADE_VISIVEL = 5;
  private
    FImagens: TArray<TBitmap>;
    FAoSelecionar: TProc<TArray<TMensagemConteudo>>;
    FAoCancelar: TProc;
    procedure CriarEstilo;
    procedure ItemOnApplyStyleLookup(Sender: TObject);
    procedure RemoverItens;
  public
    constructor Create(AOwner: TFmxObject);
    destructor Destroy; override;
    procedure AdicionarItem(sArquivo: String);
    procedure SelecionarAnexo(AoSelecionar: TProc<TArray<TMensagemConteudo>>);
    procedure CancelarAnexo(AoCancelar: TProc);
    property Layout: TLayout read lytEditorAnexo;
  end;

implementation

{ TAnexo }

constructor TAnexo.Create(AOwner: TFmxObject);
begin
  odlgArquivo := TOpenDialog.Create(AOwner);
  odlgArquivo.Options := [TOpenOption.ofHideReadOnly, TOpenOption.ofAllowMultiSelect, TOpenOption.ofEnableSizing];

  lytEditorAnexo := TLayout.Create(AOwner);
  lytEditorAnexo.Align := TAlignLayout.Contents;
  lytEditorAnexo.Size.Width := 452;
  lytEditorAnexo.Size.Height := 346;
  lytEditorAnexo.Size.PlatformDefault := False;
  lytEditorAnexo.Visible := False;

  rtgEditor := TRectangle.Create(lytEditorAnexo);
  rtgEditor.Align := TAlignLayout.Center;
  rtgEditor.Padding.Left := 15;
  rtgEditor.Padding.Top := 10;
  rtgEditor.Padding.Right := 15;
  rtgEditor.Padding.Bottom := 10;
  rtgEditor.Size.Width := 296;
  rtgEditor.Size.Height := 115;
  rtgEditor.Size.PlatformDefault := False;
  rtgEditor.XRadius := 10;
  rtgEditor.YRadius := 10;

  lytBotoes := TLayout.Create(rtgEditor);
  lytBotoes.Align := TAlignLayout.Bottom;
  lytBotoes.Position.X := 15;
  lytBotoes.Position.Y := 196;
  lytBotoes.Size.Width := 266;
  lytBotoes.Size.Height := 25;
  lytBotoes.Size.PlatformDefault := False;

  sbtCancelar := TSpeedButton.Create(lytBotoes);
  sbtCancelar.Align := TAlignLayout.Right;
  sbtCancelar.Position.X := 146;
  sbtCancelar.Size.Width := 60;
  sbtCancelar.Size.Height := 25;
  sbtCancelar.Size.PlatformDefault := False;
  sbtCancelar.Text := 'Cancelar';
  sbtCancelar.OnClick := sbtCancelarClick;

  sbtEnviar := TSpeedButton.Create(lytBotoes);
  sbtEnviar.Align := TAlignLayout.Right;
  sbtEnviar.Position.X := 206;
  sbtEnviar.Size.Width := 60;
  sbtEnviar.Size.Height := 25;
  sbtEnviar.Size.PlatformDefault := False;
  sbtEnviar.Text := 'Enviar';
  sbtEnviar.OnClick := sbtEnviarClick;

  sbtAdicionar := TSpeedButton.Create(lytBotoes);
  sbtAdicionar.Align := TAlignLayout.Left;
  sbtAdicionar.Size.Width := 60;
  sbtAdicionar.Size.Height := 25;
  sbtAdicionar.Size.PlatformDefault := False;
  sbtAdicionar.Text := 'Adicionar';
  sbtAdicionar.OnClick := sbtAdicionarClick;

  lbTitulo := TLabel.Create(rtgEditor);
  lbTitulo.Align := TAlignLayout.Top;
  lbTitulo.StyledSettings := [TStyledSetting.Family, TStyledSetting.Size, TStyledSetting.FontColor];
  lbTitulo.Margins.Bottom := 8;
  lbTitulo.Position.X := 15;
  lbTitulo.Position.Y := 10;
  lbTitulo.Size.Width := 266;
  lbTitulo.Size.Height := 17;
  lbTitulo.Size.PlatformDefault := False;
  lbTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lbTitulo.Text := 'Enviar';

  lbxAnexos := TListBox.Create(rtgEditor);
  lbxAnexos.Align := TAlignLayout.Client;
  lbxAnexos.Size.Width := 266;
  lbxAnexos.Size.Height := 116;
  lbxAnexos.Size.PlatformDefault := False;
  lbxAnexos.TabOrder := 5;
  lbxAnexos.ItemHeight := 50;
  lbxAnexos.DisableFocusEffect := True;
  lbxAnexos.DefaultItemStyles.ItemStyle := '';
  lbxAnexos.DefaultItemStyles.GroupHeaderStyle := '';
  lbxAnexos.DefaultItemStyles.GroupFooterStyle := '';

  lytEditorAnexo.AddObject(rtgEditor);
  rtgEditor.AddObject(lbTitulo);
  rtgEditor.AddObject(lbxAnexos);
  rtgEditor.AddObject(lytBotoes);
  lytBotoes.AddObject(sbtAdicionar);
  lytBotoes.AddObject(sbtCancelar);
  lytBotoes.AddObject(sbtEnviar);
  AOwner.AddObject(lytEditorAnexo);

  lbxAnexos.NeedStyleLookup;
  lbxAnexos.ApplyStyleLookup;
  lbxAnexos.StylesData['background.Source'] := nil;

  CriarEstilo;
end;

destructor TAnexo.Destroy;
var
  bmp: TBitmap;
begin
  lbxAnexos.Clear;
  for bmp in FImagens do
    bmp.Free;

  lytEditorAnexo.Free;
  StyleBook.Free;
  inherited;
end;

procedure TAnexo.SelecionarAnexo(AoSelecionar: TProc<TArray<TMensagemConteudo>>);
begin
  FAoSelecionar := AoSelecionar;
  lytEditorAnexo.Visible := True;
  rtgEditor.Height := 70;
end;

procedure TAnexo.CancelarAnexo(AoCancelar: TProc);
begin
  FAoCancelar := AoCancelar;
end;

procedure TAnexo.AdicionarItem(sArquivo: String);
var
  Item: TListBoxItem;
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  FImagens := FImagens + [bmp];

  bmp.LoadFromFile(sArquivo);

  Item := TListBoxItem.Create(lbxAnexos);
  Item.Selectable := False;
  Item.StylesData['Imagem.Bitmap'] := bmp;
  Item.StylesData['Nome'] := ExtractFileName(sArquivo);
  Item.StylesData['Tamanho'] := FormatFloat('#,##0.00', TFile.GetSize(sArquivo) / 1024 / 1024) +' MB';
  Item.StylesData['Arquivo'] := sArquivo;

  lbxAnexos.AddObject(Item);

  Item.OnApplyStyleLookup := ItemOnApplyStyleLookup;

  Item.NeedStyleLookup;
  Item.ApplyStyleLookup;

  if lbxAnexos.Items.Count <= QUANTIDADE_VISIVEL then
    rtgEditor.Height := rtgEditor.Height + 55;

  if lbxAnexos.Items.Count <= QUANTIDADE_VISIVEL then
    rtgEditor.Width := 296
  else
    rtgEditor.Width := 310;
end;

procedure TAnexo.CriarEstilo;
var
  ms: TStringStream;
  sc: TStyleContainer;
  Layout1: TLayout;
  Rectangle: TRectangle;
  Image: TImage;
  SpeedButton: TSpeedButton;
  Layout2: TLayout;
  Text1: TText;
  Text2: TText;
  Text3: TText;
begin
  sc := TStyleContainer.Create(nil);
  try
    Layout1 := TLayout.Create(sc);
    with Layout1 do
    begin
      StyleName := 'ListBoxItemAnexo';
      Align := TAlignLayout.Center;
      Size.Width := 262;
      Size.Height := 50;
      Size.PlatformDefault := False;
      TabOrder := 36;
    end;

    Rectangle := TRectangle.Create(sc);
    with Rectangle do
    begin
      StyleName := 'Fundo';
      Align := TAlignLayout.Client;
      Size.Width := 262;
      Size.Height := 50;
      Size.PlatformDefault := False;
      Margins.Top := 3;
      Margins.Bottom := 3;
      Margins.Left := 3;
      Margins.Right := 3;
      XRadius := 5;
      YRadius := 5;
    end;

    Image := TImage.Create(sc);
    with Image do
    begin
      StyleName := 'Imagem';
      Align := TAlignLayout.Left;
      Margins.Left := 3;
      Margins.Top := 3;
      Margins.Right := 3;
      Margins.Bottom := 3;
      Position.X := 3;
      Position.Y := 3;
      Size.Width := 70;
      Size.Height := 44;
      Size.PlatformDefault := False;
    end;

    SpeedButton := TSpeedButton.Create(sc);
    with SpeedButton do
    begin
      StyleName := 'SpeedButton';
      Align := TAlignLayout.Right;
      Position.X := 232;
      Size.Width := 30;
      Size.Height := 50;
      Size.PlatformDefault := False;
      Text := '🗑';
    end;

    Layout2 := TLayout.Create(sc);
    with Layout2 do
    begin
      StyleName := 'Layout';
      Align := TAlignLayout.Client;
      Size.Width := 156;
      Size.Height := 50;
      Size.PlatformDefault := False;
      TabOrder := 2;
    end;

    Text1 := TText.Create(sc);
    with Text1 do
    begin
      StyleName := 'Nome';
      Align := TAlignLayout.Top;
      WordWrap := False;
      Size.Width := 156;
      Size.Height := 25;
      Size.PlatformDefault := False;
      TextSettings.HorzAlign := TTextAlign.Leading;
    end;

    Text2 := TText.Create(sc);
    with Text2 do
    begin
      StyleName := 'Tamanho';
      Align := TAlignLayout.Client;
      Size.Width := 156;
      Size.Height := 25;
      Size.PlatformDefault := False;
      TextSettings.Font.Size := 10;
      TextSettings.HorzAlign := TTextAlign.Leading;
      TextSettings.VertAlign := TTextAlign.Leading;
    end;

    Text3 := TText.Create(sc);
    with Text3 do
    begin
      StyleName := 'Arquivo';
      Visible := False;
    end;

    Layout1.AddObject(Rectangle);
    Rectangle.AddObject(Image);
    Rectangle.AddObject(SpeedButton);
    Rectangle.AddObject(Layout2);
    Layout2.AddObject(Text1);
    Layout2.AddObject(Text2);
    Layout2.AddObject(Text3);

    sc.AddObject(Layout1);

    ms := TStringStream.Create;
    try
      // \o/ - Eduardo - 07/03/2024 - Criar o estilo em tempo de execução
      TStyleStreaming.SaveToStream(sc, ms, TStyleFormat.Indexed);

      StyleBook := TStyleBook.Create(nil);
      ms.Position := 0;
      StyleBook.LoadFromStream(ms);

      // \o/ - Eduardo - 08/03/2024 - Definir o estilo somente no componente
      lbxAnexos.Scene.StyleBook := StyleBook;

      lbxAnexos.DefaultItemStyles.ItemStyle := 'ListBoxItemAnexo';
    finally
      FreeAndNil(ms);
    end;
  finally
    FreeAndNil(sc);
  end;
end;

procedure TAnexo.sbtAdicionarClick(Sender: TObject);
begin
  if odlgArquivo.Execute then
    for var sArquivo in odlgArquivo.Files do
      AdicionarItem(sArquivo);
end;

procedure TAnexo.ItemOnApplyStyleLookup(Sender: TObject);
var
  btn: TFMXObject;
begin
  btn := TListBoxItem(Sender).FindStyleResource('SpeedButton');
  if Assigned(btn) and (btn is TSpeedButton) then
    TSpeedButton(btn).OnClick := sbtRemoverClick;
end;

procedure TAnexo.sbtRemoverClick(Sender: TObject);
begin
  with TListBoxItem(TLayout(TRectangle(TSpeedButton(Sender).Parent).Parent).Parent) do
    TListBox(Parent).RemoveObject(Index);

  if lbxAnexos.Items.Count < QUANTIDADE_VISIVEL then
    rtgEditor.Height := rtgEditor.Height - 55;

  if lbxAnexos.Items.Count <= QUANTIDADE_VISIVEL then
    rtgEditor.Width := 296
  else
    rtgEditor.Width := 310;
end;

procedure TAnexo.sbtCancelarClick(Sender: TObject);
begin
  RemoverItens;
  lytEditorAnexo.Visible := False;
  if Assigned(FAoCancelar) then
    FAoCancelar;
end;

procedure TAnexo.sbtEnviarClick(Sender: TObject);
var
  Item: TMensagemConteudo;
  Selecionados: TArray<TMensagemConteudo>;
  I: Integer;
begin
  Selecionados := [];
  for I := 0 to Pred(lbxAnexos.Items.Count) do
  begin
    Item := TMensagemConteudo.New;
    Item.tipo := 2; // 2-Imagem
    Item.conteudo := TText(lbxAnexos.ListItems[I].FindStyleResource('Arquivo')).Text;
    Selecionados := Selecionados + [Item];
  end;

  RemoverItens;

  FAoSelecionar(Selecionados);

  lytEditorAnexo.Visible := False;
end;

procedure TAnexo.RemoverItens;
var
  bmp: TBitmap;
begin
  lbxAnexos.Clear;
  for bmp in FImagens do
    bmp.Free;
  FImagens := [];
end;

end.
