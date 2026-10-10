unit Conversa.Contatos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Objects, FMX.Layouts, FMX.ListBox, Conversa.Dados,
  System.JSON,
  Conversa.Contatos.Listagem.Item;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    ContatoItem: TConversaContatoItem;
  end;
  TConversaContatos = class(TFrameBase)
    rctFundo: TRectangle;
    txtTitle: TText;
    lstContatos: TListBox;
    tmrCarregar: TTimer;
    procedure tmrCarregarTimer(Sender: TObject);
  public
    class procedure ExibirContatos;
  end;

var
  ConversaContatos: TConversaContatos;

implementation

{$R *.fmx}

uses
  Conversa.Tela.Inicial.view,
  Conversa.Tipos,
  Conversa.Chat.Listagem,
  Conversa.Proxy,
  Conversa.Proxy.Tipos;

{ TConversaContatos }

class procedure TConversaContatos.ExibirContatos;
begin
  TelaInicial.ModalView.Exibir(TConversaContatos.Create(TelaInicial.lytClientForm));
end;

procedure TConversaContatos.tmrCarregarTimer(Sender: TObject);
var
  Contato: Conversa.Proxy.Tipos.TContato;
  Item: TListBoxItem;
begin
  TTimer(Sender).Enabled := False;
  for Contato in Conversa.Proxy.TAPIConversa.Usuario.Contatos do
  begin
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.ContatoItem := TConversaContatoItem.Create(Item, Contato.id);
    Item.ContatoItem.lblNome.Text := Contato.nome;
    Item.ContatoItem.Text1.Text := Contato.nome[1];
    lstContatos.AddObject(Item);

    Item.ContatoItem.OnAbrirChat(
      procedure(DestinatarioId: Integer; NomeDestinaratio: String)
      var
        objConversa: Conversa.Tipos.TConversa;
      begin
        objConversa := Dados.FDadosApp.Conversas.FromDestinatario(DestinatarioId);

        if not Assigned(objConversa) then
          objConversa := Conversa.Tipos.TConversa.New(0)
            .Tipo(TTipoConversa.Chat)
            .Descricao(NomeDestinaratio)
            .AddUsuario(Dados.FDadosApp.Usuario)
            .AddUsuario(Dados.FDadosApp.Usuarios.GetOrAdd(DestinatarioId).Nome(NomeDestinaratio));

        try
          Dados.FDadosApp.Conversas.Add(objConversa);
          Chats.AbrirChat(objConversa);
        finally
        end;
        TelaInicial.ModalView.Ocultar;
      end
    );
  end
end;

end.
