﻿unit Conversa.Chat.Listagem;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.DateUtils,
  System.StrUtils,
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
  Conversa.Tipos,
  Conversa.Memoria,
  Conversa.Audio;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    Conversa: TConversa;
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
    procedure AoReceberMensagem(ConversaId: Integer);
    procedure btnAbrirChat(Item: TConversasItemFrame);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
    procedure AtualizarChat(Mensagem: TMensagem);
    procedure AtualizarListagem;
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

uses
  Conversa.Eventos;

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
  TEvento.Adicionar(TTipoEvento.AtualizacaoListaConversa, AtualizarListagem);
end;

destructor TChatListagem.Destroy;
begin
  TEvento.Remover(TTipoEvento.AtualizacaoListaConversa, AtualizarListagem);
  if Assigned(Chat) then
    FreeAndNil(Chat);
  inherited;
end;

procedure TChatListagem.tmrExibirTimer(Sender: TObject);
begin
  tmrExibir.Enabled := False;
  Dados.CarregarConversas;
end;

procedure TChatListagem.EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
begin
  Dados.EnviarMensagem(Mensagem);
  Chat.AdicionarMensagens(Dados.ExibirMensagem(Conteudo.Conversa.ID, True));
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

procedure TChatListagem.AoReceberMensagem(ConversaId: Integer);
var
  bNovo: Boolean;
  Item: TListBoxItem;
  Mensagens: TArrayMensagens;
  Msg: TMensagem;
  I: Integer;
  AConteudos: TArray<TMensagemNotificacao>;
  Conversa: TConversa;
begin
  Mensagens := Dados.MensagensParaNotificar(ConversaId);
  if Length(Mensagens) = 0 then
    Exit;
  bNovo := True;
  for I := 0 to Pred(lstConversas.Count) do
  begin
    if TListBoxItem(lstConversas.ListItems[I]).ContatoItem.ID = ConversaId then
    begin
      bNovo := False;
      Break;
    end;
  end;
  if bNovo then
  begin
    Dados.CarregarConversas;
    Conversa := Dados.FDadosApp.Conversas.Get(ConversaId);
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Conversa.ID, Conversa.Destinatario.ID)
        .Descricao(Conversa.Descricao)
        .Mensagem(Conversa.UltimaMensagem)
        .UltimaMensagem(Conversa.UltimaMensagemData)
        .OnClick(btnAbrirChat);

    lstConversas.AddObject(Item);
  end;
  Msg := Mensagens[Pred(Length(Mensagens))];
  if not Assigned(Chat) or (Chat.Conversa.ID <> ConversaId) or not Self.IsFormActive then
  begin
    AConteudos := [];
    if Msg.Conteudos.Count > 0 then
      AConteudos := [
        TMensagemNotificacao.New
          .ID(Msg.Conteudos[0].id)
          .Mensagem(IfThen(Msg.Conteudos[0].tipo = TTipoConteudo.Texto, Msg.Conteudos[0].conteudo, 'Imagem'))
      ];
    TNotificacaoManager.Apresentar(
      TNotificacao.New
        .ChatId(ConversaId)
        .Nome(Msg.Remetente.Nome)
        .Hora(Now)
        .Conteudo(AConteudos)
    );
  end;
  if Assigned(Chat) and (Chat.Conversa.ID = ConversaId) then
    Chat.AdicionarMensagens(Dados.ExibirMensagem(ConversaId, True));
  PlayResource('nova_mensagem');
  AtualizarChat(Msg);
end;

procedure TChatListagem.AtualizarChat(Mensagem: TMensagem);
var
  I: Integer;
  Item: TListBoxItem;
begin
  for I := 0 to Pred(lstConversas.Count) do
  begin
    Item := TListBoxItem(lstConversas.ListItems[I]);
    if Item.ContatoItem.ID = Mensagem.Conversa.ID then
    begin
      if Mensagem.Lado = TLadoMensagem.Direito then
        Item.ContatoItem.Mensagem('Você: '+ Mensagem.conteudos[Pred(Mensagem.Conteudos.Count)].conteudo)
      else
        Item.ContatoItem.Mensagem(Mensagem.conteudos[Pred(Mensagem.conteudos.Count)].conteudo);
      Item.ContatoItem.UltimaMensagem(Mensagem.inserida);
      Break;
    end;
  end;
end;

procedure TChatListagem.btnAbrirChat(Item: TConversasItemFrame);
begin
  try
    if not Assigned(Chat) then
      Chat := TChat.Create(lytViewClient)
    else
    if Assigned(Chat.Conversa) and (Chat.Conversa.ID = Item.ID) then
      Exit;

    Chat.Conversa := Dados.FDadosApp.Conversas.GetOrAdd(Item.ID);
    Chat.Limpar;
    Chat.lblNome.Text := Item.lblNome.Text;
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
  Chat.Conversa := Dados.FDadosApp.Conversas.GetOrAdd(ChatId);
//  Chat.DestinatarioID := DestinatarioId;
  Chat.lblNome.Text := NomeDestinatario;
//  Chat.ID := ChatId;
//  Chat.Usuario := Dados.Nome;
//  Chat.UsuarioID := Dados.ID;
  Chat.AoEnviarMensagem := EnviarMensagem;
  Chat.UltimaMensagem := 0;
  Chat.AdicionarMensagens(Dados.ExibirMensagem(ChatId, False));
  Chat.ListagemItem := Item.ContatoItem;
end;

procedure TChatListagem.AtualizarListagem;
var
  Item: TListBoxItem;
  Conversas: TArrayConversas;
  Conversa: TConversa;
  I: Integer;
  bContinue: Boolean;
  DestinatarioId: Integer;

  iConversa: Integer;
begin
  Conversas := Dados.FDadosApp.Conversas.Items.OrdemAtualizacao;
  for iConversa := 0 to Pred(Length(Conversas)) do
  begin
    Conversa := Conversas[iConversa];
    bContinue := False;
    for I := 0 to Pred(lstConversas.Count) do
    begin
      Item := TListBoxItem(lstConversas.ListItems[I]);
      if Item.Conversa = Conversa then
      begin
        Item.Index := iConversa;
        Item.ContatoItem
          .Descricao(Conversa.Descricao)
          .Mensagem(Conversa.UltimaMensagem)
          .UltimaMensagem(Conversa.UltimaMensagemData);

        bContinue := True;
        Break;
      end;
    end;

    if bContinue then
      Continue;

    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.Index := iConversa;

    if Conversa.Tipo = TTipoConversa.Chat then
      DestinatarioId := Conversa.Destinatario.ID
    else
      DestinatarioId := 0;

    Item.Conversa := Conversa;
    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Conversa.ID, DestinatarioId)
        .Descricao(Conversa.Descricao)
        .Mensagem(Conversa.UltimaMensagem)
        .UltimaMensagem(Conversa.UltimaMensagemData)
        .OnClick(btnAbrirChat);
    lstConversas.AddObject(Item);
  end;
end;

end.
