unit chat.editor.texto;

interface

uses
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.IOUtils,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Memo.Types,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Layouts,
  FMX.Clipboard,
  FMX.Platform,
  FMX.Surfaces,
  FMX.VirtualKeyboard,
  chat.tipos,
  Chat.Editor.Base;

const
  AlturaMaximaEditorTexto = 212;

type
  TChatEditorTexto = class(TChatEditorBase)
    lytMensagemTexto: TLayout;
    lytEmoji: TLayout;
    lytBEmoji: TLayout;
    pthEmoji: TPath;
    lytAnexo: TLayout;
    lytBAnexo: TLayout;
    pthAnexo: TPath;
    lytInput: TLayout;
    mmMensagem: TMemo;
    txtMensagem: TText;
    lytInputClient: TLayout;
    procedure lytInputClick(Sender: TObject);
    procedure mmMensagemChangeTracking(Sender: TObject);
    procedure mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure FrameResize(Sender: TObject);
    procedure lytBAnexoClick(Sender: TObject);
    procedure lytBEmojiClick(Sender: TObject);
  public
    procedure AfterConstruction; override;
    function TemConteudo: Boolean; override;
    procedure Limpar; override;
    procedure AtualizarRedimensionamento(const AtualizarEditor: Boolean);
    function Conteudo: TConteudo;
  end;

implementation

{$R *.fmx}

uses
  chat.editor,
  chat.so,
  chat.selectfile;

type
  TChatEditorTextoHelper = class Helper for TChatEditorTexto
    function Editor: TChatEditor;
  end;

{ TChatEditorTexto }

procedure TChatEditorTexto.AfterConstruction;
begin
  inherited;
  mmMensagem.NeedStyleLookup;
  mmMensagem.ApplyStyleLookup;
  mmMensagem.StylesData['background.Source'] := nil;
end;

procedure TChatEditorTexto.lytBAnexoClick(Sender: TObject);
begin
  SelectFile(
    procedure(FileSelected: TFileSelected)
    begin
      Editor.AdicionarAnexo(FileSelected);
    end
  );
end;

procedure TChatEditorTexto.lytBEmojiClick(Sender: TObject);
begin
  ShowEmoji(mmMensagem);
end;

procedure TChatEditorTexto.lytInputClick(Sender: TObject);
begin
  inherited;
  mmMensagem.SetFocus;
end;

procedure TChatEditorTexto.mmMensagemChangeTracking(Sender: TObject);
begin
  inherited;
  txtMensagem.Visible := mmMensagem.Lines.Text.IsEmpty;
  Editor.AtualizarAction;
  AtualizarRedimensionamento(True);
  mmMensagem.ShowScrollBars := Self.Height >= AlturaMaximaEditorTexto;
end;

procedure TChatEditorTexto.mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  svc: IFMXExtendedClipboardService;
  Bmp: TBitmapSurface;
  sTemp: String;
begin
  {$IFDEF MSWINDOWS}
  if (Key = vkReturn) and (Shift = []) then
  begin
    Key := 0;
    KeyChar := #0;
    Editor.Enviar;
  end
  else
  {$ENDIF}
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

    Editor.AdicionarAnexo(TFileSelected.Create(sTemp));
  end;
end;

function TChatEditorTexto.TemConteudo: Boolean;
begin
  Result := not mmMensagem.text.trim.IsEmpty;
end;

procedure TChatEditorTexto.AtualizarRedimensionamento(const AtualizarEditor: Boolean);
var
  TamanhoTexto: TRectF;
  iMax: Single;
begin
  TamanhoTexto := RectF(0, 0, mmMensagem.ContentSize.Width, 10000);

  if Assigned(mmMensagem.Canvas) and (mmMensagem.Lines.Count > 0) and (not mmMensagem.text.trim.IsEmpty) then
    mmMensagem.Canvas.MeasureText(TamanhoTexto, mmMensagem.Lines.Text + IfThen(mmMensagem.Lines[Pred(mmMensagem.Lines.Count)].trim.IsEmpty, 'A'), True, [], TTextAlign.Center, TTextAlign.Leading)
  else
    TamanhoTexto := TRectF.Create(0, 0, 0, 16);

  if (mmMensagem.ContentSize.Height + 5) > (TamanhoTexto.Bottom + 5) then
    iMax  := mmMensagem.ContentSize.Height + 5
  else
    iMax  := Ceil(TamanhoTexto.Bottom + 5);

  iMax := Min(iMax, AlturaMaximaEditorTexto);
  if lytInput.Height <> iMax then
    lytInput.Height := iMax;

  if lytBAnexo.Height <> Editor.AlturaMinimaEditor then
    lytBAnexo.Height := Editor.AlturaMinimaEditor;

  if lytBEmoji.Height <> Editor.AlturaMinimaEditor then
    lytBEmoji.Height := Editor.AlturaMinimaEditor;

  Self.Height := Min(
    AlturaMaximaEditorTexto,
      Max(
        Editor.AlturaMinimaEditor,
        iMax + lytInput.Margins.Top + lytInput.Margins.Bottom + lytInput.Padding.Top + lytInput.Padding.Bottom
      )
  );

  if AtualizarEditor then
    Editor.AtualizarRedimensionamento;
end;

procedure TChatEditorTexto.FrameResize(Sender: TObject);
begin
  inherited;
  AtualizarRedimensionamento(True);
end;

procedure TChatEditorTexto.Limpar;
begin
  mmMensagem.Text := EmptyStr;
end;

function TChatEditorTexto.Conteudo: TConteudo;
begin
  Result := TConteudo.Create(TTipo.Texto, mmMensagem.Text);
end;

{ TChatEditorTextoHelper }

function TChatEditorTextoHelper.Editor: TChatEditor;
begin
  Result := TChatEditor(FEditor);
end;

end.
