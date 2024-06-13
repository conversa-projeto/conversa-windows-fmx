unit Conversa.Chat.Listagem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Objects,

  Conversa.FrameBase,
  Conversa.Chat.Listagem.Item,
//  Conversa.Conteudo,
  Conversa.Dados,
  Conversa.Chat,
  FMX.Controls.Presentation,
  Mensagem.Tipos;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    ContatoItem: TConversasItemFrame;
  end;
  TChatListagem = class(TFrameBase)
    lytClient: TLayout;
    rctListaConversas: TRectangle;
    lstConversas: TListBox;
    lytViewClient: TLayout;
    rctFundo: TRectangle;
    Timer1: TTimer;
    lblAvisoConversa: TLabel;
    lnSeparador: TLine;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FChats: TArray<TChat>;
    procedure btnAbrirChat(Item: TConversasItemFrame);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
  public
    { Public declarations }
    class function New(AOwner: TFmxObject): TChatListagem; static;
    destructor Destroy; override;

    procedure AbrirChat(DestinatarioId: Integer; NomeDestinatario: String);
  end;

var
  Chats: TChatListagem;

implementation

{$R *.fmx}

destructor TChatListagem.Destroy;
var
  Chat: TChat;
begin
  for Chat in FChats do
    Chat.Free;
  inherited;
end;

class function TChatListagem.New(AOwner: TFmxObject): TChatListagem;
begin
  Chats := TChatListagem.Create(AOwner);
  Chats.Align := TAlignLayout.Client;
  Chats.Parent := AOwner;
  Chats.lytClient.Visible := True;
  Chats.Visible := True;
  Chats.lytClient.Align := TAlignLayout.Client;
  Result := Chats;
end;

procedure TChatListagem.Timer1Timer(Sender: TObject);
var
  Item: TListBoxItem;
begin
  Timer1.Enabled := False;
  Dados.Conversas;
  Dados.cdsConversas.First;
  while not Dados.cdsConversas.Eof do
  try
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    //Item.Tag := Dados.cdsConversas.IGGetInt('id');

    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Dados.cdsConversas.FieldByName('id').AsInteger, Dados.cdsConversas.FieldByName('destinatario_id').AsInteger)
        .Descricao(Dados.cdsConversas.FieldByName('descricao').AsString)
        .Mensagem(Dados.cdsConversas.FieldByName('ultima_mensagem_texto').AsString)
        .UltimaMensagem(Dados.cdsConversas.FieldByName('ultima_mensagem').AsDateTime)
        .OnClick(btnAbrirChat);

    lstConversas.AddObject(Item);
  finally
    Dados.cdsConversas.Next;
  end;
end;

procedure TChatListagem.EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
begin
  Dados.EnviarMensagem(Mensagem);
end;

procedure TChatListagem.btnAbrirChat(Item: TConversasItemFrame);
var
  Chat: TChat;
  bJaCriado: Boolean;
begin
  bJaCriado := False;
  for Chat in FChats do
  begin
    if Chat.ID <> Item.ID then
      Chat.Visible := False
    else
    begin
      bJaCriado := True;
      Chat.Visible := True;
    end;
  end;

  if bJaCriado then
    Exit;

  Chat := TChat.Create(lytViewClient);
  Chat.DestinatarioID := Item.DestinatarioId;
  Chat.lblNome.Text := Item.lblNome.Text;
  Chat.ID := Item.ID;
  Chat.Usuario := Dados.Nome;
  Chat.UsuarioID := Dados.ID;
  Chat.AoEnviarMensagem := EnviarMensagem;
  Chat.AdicionarMensagens(Dados.Mensagens(Item.ID));
  Chat.ListagemItem := Item;
  FChats := FChats + [Chat];
end;

procedure TChatListagem.AbrirChat(DestinatarioId: Integer; NomeDestinatario: String);
var
  Chat: TChat;
  ChatItem: Integer;
  bLocalizou: Boolean;
  ChatId: Integer;
  Item: TListBoxItem;
begin
  bLocalizou := False;
  Chat := nil;
  for Chat in FChats do
  begin
    if Chat.DestinatarioID = DestinatarioId then
    begin
      bLocalizou :=  True;
      Break;
    end;
  end;

  if bLocalizou then
  begin
    Chat.Visible := True;
    Chat.BringToFront;
    Exit;
  end;

  ChatId := 0;
  Item := nil;
  for ChatItem := 0 to Pred(lstConversas.Items.Count) do
  begin
    if TListBoxItem(lstConversas.ListItems[ChatItem]).ContatoItem.DestinatarioID = DestinatarioId then
    begin
      Item := TListBoxItem(lstConversas.ListItems[ChatItem]);
      ChatId := TListBoxItem(lstConversas.ListItems[ChatItem]).ContatoItem.ID;
      Break;
    end;
  end;

  if ChatId = 0 then
  begin
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.ContatoItem :=
      TConversasItemFrame.New(Item, ChatId, DestinatarioId)
        .Descricao(NomeDestinatario)
        .Mensagem('Novo Chat')
        .UltimaMensagem(0)
        .OnClick(btnAbrirChat);

    lstConversas.InsertObject(0, Item);
  end;

  Chat := TChat.Create(lytViewClient);
  Chat.DestinatarioID := DestinatarioId;
  Chat.lblNome.Text := NomeDestinatario;
  Chat.ID := ChatId;
  Chat.Usuario := Dados.Nome;
  Chat.UsuarioID := Dados.ID;
  Chat.AoEnviarMensagem := EnviarMensagem;
  Chat.AdicionarMensagens(Dados.Mensagens(ChatId));
  Chat.ListagemItem := Item.ContatoItem;
  FChats := FChats + [Chat];
end;

end.
