unit Conversa.Chat.Listagem;

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
  Conversa.Audio,
  Conversa.Eventos;

type
  TChatListagem = class(TFrameBase)
    lytClient: TLayout;
    rctListaConversas: TRectangle;
    lstConversas: TListBox;
    lytViewClient: TLayout;
    rctFundo: TRectangle;
    tmrExibir: TTimer;
    lnSeparador: TLine;
    tmrUltima: TTimer;
    Layout1: TLayout;
    lblAvisoConversa: TLabel;
    imgLogo: TImage;
    procedure tmrExibirTimer(Sender: TObject);
    procedure tmrUltimaTimer(Sender: TObject);
  private
    procedure AoReceberMensagem(ConversaId: Integer);
    procedure btnAbrirChat(Item: TConversasItemFrame);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
    procedure AtualizarChat(Mensagem: TMensagem);
    procedure AtualizarListagem(const Sender: TObject; const M: TMessage);

    procedure AdicionarItemListagem(Conversa: TConversa; iPosicao: Integer = -1);
    procedure SelecionarItemListagem(AConversa: TConversa);
  public
    Chat: TChat;
    class function New(AOwner: TFmxObject): TChatListagem; static;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AbrirChat(Conversa: TConversa);
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
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoAtualizacaoListaConversa, AtualizarListagem);
end;

destructor TChatListagem.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TEventoAtualizacaoListaConversa, AtualizarListagem);
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

procedure TChatListagem.AoReceberMensagem(ConversaId: Integer);
var
  Mensagens: TArrayMensagens;
  Msg: TMensagem;
  AConteudos: TArray<TMensagemNotificacao>;
  Conversa: TConversa;
  sConteudo: String;
begin
  Conversa  := Dados.FDadosApp.Conversas.Get(ConversaId);
  Mensagens := Dados.MensagensParaNotificar(ConversaId);
  AdicionarItemListagem(Conversa);

  if Length(Mensagens) = 0 then
    Exit;

  Msg := Mensagens[Pred(Length(Mensagens))];
  if not Assigned(Chat) or (Chat.Conversa.ID <> ConversaId) or not Self.IsFormActive then
  begin
    AConteudos := [];
    if Msg.Conteudos.Count > 0 then
    begin
      case Msg.Conteudos[0].tipo of
        TTipoConteudo.Texto:   sConteudo := Msg.Conteudos[0].conteudo;
        TTipoConteudo.Imagem:  sConteudo := 'Imagem';
        TTipoConteudo.Arquivo: sConteudo := 'Arquivo';
      end;
      AConteudos := [
        TMensagemNotificacao.New
          .ID(Msg.Conteudos[0].id)
          .Usuario(IfThen(Conversa.Tipo = TTipoConversa.Chat, '', Msg.Remetente.Nome))
          .Mensagem(sConteudo)
      ];
    end;
    TNotificacaoManager.Apresentar(
      TNotificacao.New
        .ChatId(ConversaId)
        .Nome(Conversa.Descricao)
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
    if Item.Conversa = Mensagem.Conversa then
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
  AbrirChat(Item.Conversa);
end;

procedure TChatListagem.tmrUltimaTimer(Sender: TObject);
begin
  tmrUltima.Enabled := False;
  if Assigned(Chat) and Chat.Visible then
    Chat.PosicionarUltima;
end;

procedure TChatListagem.AtualizarListagem(const Sender: TObject; const M: TMessage);
var
  Conversas: TArrayConversas;
  iConversa: Integer;
begin
  Conversas := Dados.FDadosApp.Conversas.Items.OrdemAtualizacao;
  for iConversa := 0 to Pred(Length(Conversas)) do
    AdicionarItemListagem(Conversas[iConversa], iConversa);
end;

procedure TChatListagem.AdicionarItemListagem(Conversa: TConversa; iPosicao: Integer = -1);
var
  I: Integer;
  Item: TListBoxItem;
begin
  Item := nil;
  for I := 0 to Pred(lstConversas.Count) do
  begin
    if TListBoxItem(lstConversas.ListItems[I]).Conversa.ID = Conversa.ID then
    begin
      Item := TListBoxItem(lstConversas.ListItems[I]);
      Break;
    end;
  end;

  if not Assigned(Item) then
  begin
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    Item.Conversa := Conversa;
    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Conversa)
        .OnClick(btnAbrirChat);

    if iPosicao = -1 then
      iPosicao := 0;

    lstConversas.InsertObject(iPosicao, Item);
  end;

  if iPosicao > -1 then
    Item.Index := iPosicao;

  if Item.Conversa.ID = 0 then
  begin
    Item.ContatoItem
      .Descricao(Conversa.Destinatario.Nome)
      .Mensagem('Novo Chat')
      .UltimaMensagem(Now);
  end
  else
  begin
    Item.ContatoItem
      .Descricao(Conversa.Descricao)
      .Mensagem(Conversa.UltimaMensagem)
      .UltimaMensagem(Conversa.UltimaMensagemData)
  end;
end;

procedure TChatListagem.SelecionarItemListagem(AConversa: TConversa);
var
  I: Integer;
begin
  for I := 0 to Pred(lstConversas.Count) do
    with TListBoxItem(lstConversas.ListItems[I]) do
      ContatoItem.Selecionado(Conversa = AConversa);
end;

procedure TChatListagem.AbrirChat(Conversa: TConversa);
begin
  if not Assigned(Chat) then
    Chat := TChat.Create(lytViewClient)
  else
  if Assigned(Chat.Conversa) and (Chat.Conversa.ID = Conversa.ID) then
    Exit;

  try
    Chat.Limpar;
    AdicionarItemListagem(Conversa);
    SelecionarItemListagem(Conversa);
    Chat.Conversa := Conversa;
    Chat.lblNome.Text := Conversa.Descricao;
    Chat.AoEnviarMensagem := EnviarMensagem;
    Chat.UltimaMensagem := 0;

    // Resolve posicionamento do Separador de data
    Application.ProcessMessages;
    Chat.AdicionarMensagens(Dados.ExibirMensagem(Conversa.ID, False));

    Chat.FocoEditor;

    TNotificacaoManager.Fechar(Conversa.ID);
  finally
    // Posicionar na ultima mensagem
    tmrUltima.Enabled := True;
  end;
end;

end.
