unit Conversa.Chat.Listagem;

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
  FMX.Layouts,
  FMX.ListBox,
  FMX.Objects,
  FMX.Controls.Presentation,
  Conversa.FrameBase,
  Conversa.Chat.Listagem.Item,
  Conversa.Dados,
  Conversa.Chat,
  Mensagem.Tipos,
  Conversa.Audio;

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
    tmrExibir: TTimer;
    lblAvisoConversa: TLabel;
    lnSeparador: TLine;
    tmrUltima: TTimer;
    procedure tmrExibirTimer(Sender: TObject);
    procedure tmrUltimaTimer(Sender: TObject);
  private
    FChats: TArray<TChat>;
    FChatAtivo: Integer;
    procedure AoReceberMensagem(Conversa: Integer);
    procedure btnAbrirChat(Item: TConversasItemFrame);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
  public
    class function New(AOwner: TFmxObject): TChatListagem; static;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AbrirChat(DestinatarioId: Integer; NomeDestinatario: String);
  end;

var
  Chats: TChatListagem;

implementation

{$R *.fmx}

class function TChatListagem.New(AOwner: TFmxObject): TChatListagem;
begin
  Chats := TChatListagem.Create(AOwner);
  Chats.Align := TAlignLayout.Client;
  Chats.Parent := AOwner;
  Chats.lytClient.Visible := True;
  Chats.Visible := True;
  Chats.lytClient.Align := TAlignLayout.Client;
  Dados.ReceberNovasMensagens(Chats.AoReceberMensagem);
  Result := Chats;
end;

constructor TChatListagem.Create(AOwner: TComponent);
begin
  inherited;
  FChatAtivo := -1;
end;

destructor TChatListagem.Destroy;
var
  Chat: TChat;
begin
  for Chat in FChats do
    Chat.Free;
  inherited;
end;

procedure TChatListagem.tmrExibirTimer(Sender: TObject);
var
  Item: TListBoxItem;
begin
  tmrExibir.Enabled := False;
  Dados.Conversas;
  Dados.cdsConversas.First;
  while not Dados.cdsConversas.Eof do
  try
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;

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

procedure TChatListagem.AoReceberMensagem(Conversa: Integer);
var
  Chat: TChat;
  bNovo: Boolean;
  Item: TListBoxItem;
begin
  bNovo := True;
  for Chat in FChats do
  begin
    if Chat.ID = Conversa then
    begin
      bNovo := False;
      Chat.AdicionarMensagens(Dados.Mensagens(Conversa));
      Chat.Visualizador.PosicionarUltima;
    end;
  end;

  if bNovo then
  begin
    Dados.Conversas;
    if not Dados.cdsConversas.Locate('id', Conversa, []) then
      Exit;

    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;

    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Dados.cdsConversas.FieldByName('id').AsInteger, Dados.cdsConversas.FieldByName('destinatario_id').AsInteger)
        .Descricao(Dados.cdsConversas.FieldByName('descricao').AsString)
        .Mensagem(Dados.cdsConversas.FieldByName('ultima_mensagem_texto').AsString)
        .UltimaMensagem(Dados.cdsConversas.FieldByName('ultima_mensagem').AsDateTime)
        .OnClick(btnAbrirChat);

    lstConversas.AddObject(Item);
  end;

  PlayResource('nova_mensagem');
end;

procedure TChatListagem.btnAbrirChat(Item: TConversasItemFrame);
var
  Chat: TChat;
  bJaCriado: Boolean;
  I: Integer;
begin
  try
    bJaCriado := False;
    for I := Low(FChats) to High(FChats) do
    begin
      if FChats[I].ID <> Item.ID then
        FChats[I].Visible := False
      else
      begin
        bJaCriado := True;
        FChats[I].Visible := True;
        FChatAtivo := I;
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

    FChatAtivo := Pred(Length(FChats));
  finally
    // Posicionar na ultima mensagem
    tmrUltima.Enabled := True;
  end;
end;

procedure TChatListagem.tmrUltimaTimer(Sender: TObject);
begin
  tmrUltima.Enabled := False;
  if FChatAtivo <> -1 then
    FChats[FChatAtivo].PosicionarUltima;
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
      bLocalizou := True;
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
