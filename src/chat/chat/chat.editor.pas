// Eduardo - 21/08/2024
unit chat.editor;

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  chat.tipos,
  chat.editor.entrada,
  chat.anexo;

type
  TChatEditor = class(TControl, IControl)
  private
    Editor: TChatEditorEntrada;
    Anexo: TChatAnexo;
    FAoEnviar: TEventoEnvio;
    procedure AnexoEnviarClick(Sender: TObject);
    procedure EditorAnexoClick(Sender: TObject);
    procedure EditorEmojiClick(Sender: TObject);
    procedure EditorEnviarClick(Sender: TObject);
    function GetLarguraMaximaConteudo: Integer;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    property LarguraMaximaConteudo: Integer read GetLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property AoEnviar: TEventoEnvio read FAoEnviar write FAoEnviar;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  FMX.Dialogs,
  FMX.Forms,
  chat.so;

{ TChatEditor }

constructor TChatEditor.Create(AOwner: TComponent);
begin
  inherited;
  Editor := TChatEditorEntrada.Create(Self);
  Self.AddObject(Editor);

  Anexo := TChatAnexo.Create(Self);
  Self.AddObject(Anexo);

  Anexo.AoEnviarClick := AnexoEnviarClick;
  Editor.AoAnexoClick := EditorAnexoClick;
  Editor.AoEmojiClick := EditorEmojiClick;
  Editor.AoEnviarClick :=  EditorEnviarClick;
end;

procedure TChatEditor.AnexoEnviarClick(Sender: TObject);
var
  Conteudo: TConteudo;
  Conteudos: TArray<TConteudo>;
begin
  if not Assigned(FAoEnviar) then
    Exit;

  for var Item in Anexo.Selecionados do
  begin
    Conteudo := Default(TConteudo);
    if IndexStr(ExtractFileExt(Item).Replace('.', EmptyStr), ['bmp', 'jpg', 'png']) >= 0 then
      Conteudo.Tipo := TTipo.Imagem
    else
      Conteudo.Tipo := TTipo.Arquivo;
    Conteudo.Conteudo := Item;
    Conteudos := Conteudos + [Conteudo];
  end;

  if Length(Conteudos) > 0 then
    FAoEnviar(Conteudos);
end;

procedure TChatEditor.EditorAnexoClick(Sender: TObject);
begin
  Anexo.Exibir;
end;

procedure TChatEditor.EditorEmojiClick(Sender: TObject);
begin
  ShowEmoji(Editor.mmMensagem);
end;

procedure TChatEditor.EditorEnviarClick(Sender: TObject);
var
  Conteudo: TConteudo;
begin
  if not Assigned(FAoEnviar) then
    Exit;

  if Editor.mmMensagem.Lines.Text.Trim.IsEmpty then
    Exit;

  Conteudo := Default(TConteudo);
  Conteudo.Tipo := TTipo.Texto;
  Conteudo.Conteudo := Editor.mmMensagem.Lines.Text.Trim;
  Editor.mmMensagem.Lines.Clear;

  FAoEnviar([Conteudo]);
end;

function TChatEditor.GetLarguraMaximaConteudo: Integer;
begin
  Result := Editor.LarguraMaximaConteudo;
end;

procedure TChatEditor.SetLarguraMaximaConteudo(const Value: Integer);
begin
  Editor.LarguraMaximaConteudo := Value;
end;

end.
