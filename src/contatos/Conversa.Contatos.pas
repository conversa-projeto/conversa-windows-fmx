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
  Conversa.Chat.Listagem;

{ TConversaContatos }

class procedure TConversaContatos.ExibirContatos;
begin
  TelaInicial.ModalView.Exibir(TConversaContatos.Create(TelaInicial.lytClientForm));
end;

procedure TConversaContatos.tmrCarregarTimer(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  Dados.Contatos(
    procedure(jaContatos: TJSONArray)
    var
      Item: TListBoxItem;
    begin
      if Assigned(jaContatos) then
      begin
        for var joContato in  jaContatos do
        begin
          Item := TListBoxItem.Create(nil);
          Item.Text := '';
          Item.Height := 60;
          Item.Selectable := False;
          Item.ContatoItem := TConversaContatoItem.Create(Item, joContato.GetValue<Integer>('id'));
          Item.ContatoItem.lblNome.Text := joContato.GetValue<String>('nome');
          Item.ContatoItem.Text1.Text := joContato.GetValue<String>('nome')[1];
          lstContatos.AddObject(Item);

          Item.ContatoItem.OnAbrirChat(
            procedure(DestinatarioId: Integer; NomeDestinaratio: String)
            begin
              Chats.AbrirChat(DestinatarioId, NomeDestinaratio);
              TelaInicial.ModalView.Ocultar;
            end
          );
        end;
      end;
    end
  );
end;

end.
