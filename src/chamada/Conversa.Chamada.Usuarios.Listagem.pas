unit Conversa.Chamada.Usuarios.Listagem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Objects, FMX.Layouts, FMX.ListBox, Conversa.Dados,
  System.JSON,
  Conversa.Chamada.Usuarios.Listagem.Item;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    Usuario: TConversaChamadaUsuariosListItem;
  end;
  TConversaChamadaUsuariosListagem = class(TFrameBase)
    rctFundo: TRectangle;
    lstContatos: TListBox;
    Text1: TText;
  private
    FChamada: TObject;
  public
    constructor Create(AOwner: TComponent; AChamada: TObject); reintroduce; overload;
    procedure AtualizarListaUsuarios;
  end;

var
  ConversaChamadaUsuariosListagem: TConversaChamadaUsuariosListagem;

implementation

{$R *.fmx}

uses
  Conversa.Proxy.Tipos,
  Conversa.Chamada;

type
  TConversaChamadaUsuariosListagemH = class Helper for TConversaChamadaUsuariosListagem
    function Chamada: TConversaChamada;
  end;

{ TConversaChamadaUsuariosListagem }

constructor TConversaChamadaUsuariosListagem.Create(AOwner: TComponent; AChamada: TObject);
begin
  inherited Create(AOwner);
  FChamada := AChamada;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Visible := True;
end;

procedure TConversaChamadaUsuariosListagem.AtualizarListaUsuarios;
var
  Usuario: Conversa.Proxy.Tipos.TChamadaDadosUsuario;
  Item: TListBoxItem;
  I: Integer;
begin
  for Usuario in Chamada.GetUsuarios do
  begin
    Item := nil;

    for I := 0 to Pred(lstContatos.Count) do
    begin
      if not Assigned(TListBoxItem(lstContatos.ListItems[I]).Usuario) then
        Continue;

      if not TListBoxItem(lstContatos.ListItems[I]).Usuario.InheritsFrom(TConversaChamadaUsuariosListItem) then
        Continue;

      if TConversaChamadaUsuariosListItem(TListBoxItem(lstContatos.ListItems[I]).Usuario).Usuario.usuario_id <> Usuario.usuario_id then
        Continue;

      Item := TListBoxItem(lstContatos.ListItems[I]);
      Break;
    end;

    if Assigned(Item) then
      Continue;

    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.Usuario := TConversaChamadaUsuariosListItem.Create(Item, Usuario);
    Item.Usuario.txtNome.Text := Usuario.usuario_nome;
    Item.Usuario.txtAbreviatura.Text := Usuario.usuario_nome[1];
    lstContatos.AddObject(Item);
  end;
  Self.Visible := True;
  Self.Show;
end;

{ TConversaChamadaUsuariosListagemH }

function TConversaChamadaUsuariosListagemH.Chamada: TConversaChamada;
begin
  Result := TConversaChamada(FChamada);
end;

end.
