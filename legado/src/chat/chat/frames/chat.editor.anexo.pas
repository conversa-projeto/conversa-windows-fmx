unit chat.editor.anexo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation,

  System.StrUtils,

  chat.tipos,
  Chat.Editor.Base,
  Chat.Editor.Anexo.Item;

type
  TChatEditorAnexo = class(TChatEditorBase)
    odlgArquivo: TOpenDialog;
    lbTitulo: TLabel;
    lytCancelar: TLayout;
    pthCancelar: TPath;
    vsbxConteudo: TVertScrollBox;
    procedure lytCancelarClick(Sender: TObject);
  private
    FCount: Integer;
    procedure AnexoRemoverClick(Sender: TObject);
    procedure RemoverItens;
    function AlturaAnexos: Single;
  public
    procedure AfterConstruction; override;
    procedure AdicionarItem(const Arquivo: TFileSelected);
    function TemConteudo: Boolean; override;
    procedure Limpar; override;
    function Conteudos: TArray<TConteudo>;
  end;

implementation

{$R *.fmx}

uses
  Chat.Editor;

type
  TChatEditorTextoHelper = class Helper for TChatEditorAnexo
    function Editor: TChatEditor;
  end;

const
  QUANTIDADE_VISIVEL = 5;

{ TChatEditorAnexo }

procedure TChatEditorAnexo.AfterConstruction;
begin
  inherited;
  FCount := 0;
end;

procedure TChatEditorAnexo.AdicionarItem(const Arquivo: TFileSelected);
var
  Anexo: TChatAnexoItem;
begin
  Self.Visible := True;

  Anexo := TChatAnexoItem.Create(vsbxConteudo, Arquivo);
  Anexo.Position.Y := -1;
  Anexo.OnRemoverClick := AnexoRemoverClick;

  vsbxConteudo.ShowScrollBars := Pred(vsbxConteudo.ComponentCount) > QUANTIDADE_VISIVEL;
  if not vsbxConteudo.ShowScrollBars then
    Self.Height := AlturaAnexos;

  Inc(FCount);
  Editor.AtualizarAction;
  Editor.AtualizarRedimensionamento;
end;

procedure TChatEditorAnexo.AnexoRemoverClick(Sender: TObject);
begin
  vsbxConteudo.RemoveObject(TChatAnexoItem(Sender));
  TChatAnexoItem(Sender).Free;

  vsbxConteudo.ShowScrollBars := Pred(vsbxConteudo.ComponentCount) > QUANTIDADE_VISIVEL;
  if not vsbxConteudo.ShowScrollBars then
    Self.Height := AlturaAnexos;

  Dec(FCount);
  Editor.AtualizarAction;
  Editor.AtualizarRedimensionamento;

  if FCount = 0 then
    lytCancelarClick(lytCancelar);
end;

procedure TChatEditorAnexo.lytCancelarClick(Sender: TObject);
begin
  inherited;
  RemoverItens;
  Self.Visible := False;
  Editor.AtualizarAction;
  Editor.AtualizarRedimensionamento;
end;

function TChatEditorAnexo.AlturaAnexos: Single;
begin
  if Self.Visible then
    Result := (Pred(vsbxConteudo.ComponentCount) * 50) + lbTitulo.Margins.Top + lbTitulo.Margins.Bottom + 20
  else
    Result := 0;
end;

procedure TChatEditorAnexo.RemoverItens;
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
  FCount := 0;
  Self.Height := 0;
end;

function TChatEditorAnexo.TemConteudo: Boolean;
begin
  Result := FCount > 0;
end;

procedure TChatEditorAnexo.Limpar;
begin
  inherited;
  RemoverItens;
end;

function TChatEditorAnexo.Conteudos: TArray<TConteudo>;
var
  I: Integer;
  Conteudo: TConteudo;
begin
  Result := [];
  for I := Pred(vsbxConteudo.ComponentCount) downto 0 do
  begin
    if not (vsbxConteudo.Components[I] is TChatAnexoItem) then
      Continue;

    if IndexStr(ExtractFileExt(TChatAnexoItem(vsbxConteudo.Components[I]).Arquivo).Replace('.', EmptyStr).ToLower, TipoArquivoImagem) >= 0 then
      Conteudo := TConteudo.Create(TTipo.Imagem, TChatAnexoItem(vsbxConteudo.Components[I]).Arquivo)
    else
      Conteudo := TConteudo.Create(TTipo.Arquivo, TChatAnexoItem(vsbxConteudo.Components[I]).Arquivo);

    Conteudo.Extensao := ExtractFileExt(Conteudo.Conteudo).Trim([' ', '.']).ToLower;
    Conteudo.Nome := ExtractFileName(TChatAnexoItem(vsbxConteudo.Components[I]).Arquivo).Replace(ExtractFileExt(Conteudo.Conteudo).Trim([' ', '.']),  '');
    Result := Result + [Conteudo];
  end;
end;

{ TChatEditorTextoHelper }

function TChatEditorTextoHelper.Editor: TChatEditor;
begin
  Result := TChatEditor(FEditor);
end;

end.
