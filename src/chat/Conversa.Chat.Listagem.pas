unit Conversa.Chat.Listagem;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.DateUtils,
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
  Conversa.Notificacao,
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
    procedure AoReceberMensagem(Conversa: Integer);
    procedure btnAbrirChat(Item: TConversasItemFrame);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
    procedure AtualizarChat(Mensagem: TMensagem);
  public
    Chat: TChat;
    class function New(AOwner: TFmxObject): TChatListagem; static;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AbrirChat(iChat: Integer); overload;
    procedure AbrirChat(DestinatarioId: Integer; NomeDestinatario: String); overload;
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
  //
end;

destructor TChatListagem.Destroy;
begin
  if Assigned(Chat) then
    FreeAndNil(Chat);

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
  Chat.AdicionarMensagens(Dados.ExibirMensagem(Conteudo.ID, True));
  AtualizarChat(Mensagem);
end;

procedure TChatListagem.AbrirChat(iChat: Integer);
var
  I: Integer;
begin
  for I := 0 to Pred(lstConversas.Count) do
  begin
    if TListBoxItem(lstConversas.ListItems[I]).ContatoItem.ID = iChat then
    begin
      btnAbrirChat(TListBoxItem(lstConversas.ListItems[I]).ContatoItem);
      Break;
    end;
  end;
end;

procedure TChatListagem.AoReceberMensagem(Conversa: Integer);
var
  bNovo: Boolean;
  Item: TListBoxItem;
  Mensagens: TArray<TMensagem>;
  I: Integer;
begin
  Mensagens := Dados.Mensagens(Conversa, 0);
  bNovo := True;
  for I := 0 to Pred(lstConversas.Count) do
  begin
    if TListBoxItem(lstConversas.ListItems[I]).ContatoItem.ID = Conversa then
    begin
      bNovo := False;
      Break;
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

  if not Assigned(Chat) or (Chat.ID <> Conversa) or not Self.IsFormActive then
  begin
    with Mensagens[Pred(Length(Mensagens))] do
      TNotificacaoManager.Apresentar(
        TNotificacao.New
          .ChatId(Conversa)
          .Nome(remetente)
          .Hora(Now)
          .Conteudo([TMensagemNotificacao.New.Mensagem(conteudos[Pred(Length(conteudos))].conteudo)])
      );
  end;

  if Assigned(Chat) and (Chat.ID = Conversa) then
    Chat.AdicionarMensagens(Dados.ExibirMensagem(Conversa, True));

  PlayResource('nova_mensagem');

  AtualizarChat(Mensagens[Pred(Length(Mensagens))]);
end;

procedure TChatListagem.AtualizarChat(Mensagem: TMensagem);
var
  I: Integer;
  Item: TListBoxItem;
begin
  for I := 0 to Pred(lstConversas.Count) do
  begin
    Item := TListBoxItem(lstConversas.ListItems[I]);
    if Item.ContatoItem.ID = Mensagem.ConversaId then
    begin
      Item.ContatoItem.Mensagem(Mensagem.conteudos[Pred(Length(Mensagem.conteudos))].conteudo);
      Item.ContatoItem.UltimaMensagem(Mensagem.inserida);
      Break;
    end;
  end;
end;

procedure TChatListagem.btnAbrirChat(Item: TConversasItemFrame);
begin
  try
    if not Assigned(Chat) then
      Chat := TChat.Create(lytViewClient);

    if Chat.ID = Item.ID then
      Exit;

    Chat.Limpar;
    Chat.DestinatarioID := Item.DestinatarioId;
    Chat.lblNome.Text := Item.lblNome.Text;
    Chat.ID := Item.ID;
    Chat.Usuario := Dados.Nome;
    Chat.UsuarioID := Dados.ID;
    Chat.AoEnviarMensagem := EnviarMensagem;
    Chat.UltimaMensagem := 0;
    Chat.AdicionarMensagens(Dados.ExibirMensagem(Item.ID, False));
    Chat.ListagemItem := Item;
    Chat.VisualizarTudo;
    TNotificacaoManager.Fechar(Item.ID);
  finally
    // Posicionar na ultima mensagem
    tmrUltima.Enabled := True;
  end;
end;

procedure TChatListagem.tmrUltimaTimer(Sender: TObject);
begin
  tmrUltima.Enabled := False;
  if Assigned(Chat) and Chat.Visible then
    Chat.PosicionarUltima;
end;

procedure TChatListagem.AbrirChat(DestinatarioId: Integer; NomeDestinatario: String);
var
  ChatItem: Integer;
//  bLocalizou: Boolean;
  ChatId: Integer;
  Item: TListBoxItem;
begin
//  bLocalizou := False;

  if not Assigned(Chat) then
    Chat := TChat.Create(lytViewClient);


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

  Chat.Limpar;
  Chat.DestinatarioID := DestinatarioId;
  Chat.lblNome.Text := NomeDestinatario;
  Chat.ID := ChatId;
  Chat.Usuario := Dados.Nome;
  Chat.UsuarioID := Dados.ID;
  Chat.AoEnviarMensagem := EnviarMensagem;
  Chat.UltimaMensagem := 0;
  Chat.AdicionarMensagens(Dados.ExibirMensagem(ChatId, False));
  Chat.ListagemItem := Item.ContatoItem;
end;

end.
