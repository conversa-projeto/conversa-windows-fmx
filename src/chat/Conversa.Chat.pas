unit Conversa.Chat;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  System.Math,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  System.StrUtils,
  chat.visualizador,
  chat.editor,
  chat.tipos,
  chat.mensagem,
  Conversa.Dados,
  Conversa.FrameBase,
  Conversa.Tipos,
  Conversa.Eventos,
  Conversa.Chat.Listagem.Item;

type
  TChat = class(TFrameBase)
    rctFundo: TRectangle;
    rctTitulo: TRectangle;
    lytTituloClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    imgFoto: TImage;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    lytClient: TLayout;
    pthFotoDefault: TPath;
  private
    FConversa: TConversa;
    FVisualizador: TChatVisualizador;
    Editor: TChatEditor;
    FMsgClicada: TFrame;
    FObjetoClicado: TObject;
    procedure AoVisualizar(Frame: TFrame);
    procedure AoEnviar(Conteudos: TArray<chat.tipos.TConteudo>);
    procedure AoAtualizarMensagem(const Sender: TObject; const M: TMessage);
    procedure AoClicar(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AoChegarLimite(Limite: TLimite);
    procedure CriarControles;
    procedure AoClicarDownloadAnexo(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Copiar;
  public
    UltimaMensagem: Integer;
    AoEnviarMensagem: TProc<TChat, TMensagem>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Conversa: TConversa read FConversa write FConversa;
    property Visualizador: TChatVisualizador read FVisualizador;
    procedure AdicionarMensagem(Mensagem: TMensagem);
    procedure AdicionarMensagens(aMensagem: TArrayMensagens; IrParaUltima: Boolean = True);
    procedure PosicionarUltima;
    procedure Limpar;
    procedure ValidarVisualizacao;
    procedure FocoEditor;
  end;

implementation

{$R *.fmx}

uses
  FMX.Platform,
  FMX.Clipboard,
  chat.conteudo.imagem,
  chat.conteudo.anexo,
  Conversa.Visualizador.Midia,
  PopupMenu;

{ TChat }

constructor TChat.Create(AOwner: TComponent);
begin
  inherited;
  Sleep(1);
  Name := 'chat_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Visible := True;
  lytFoto.Visible := False;
  lblNome.Visible := True;

  CriarControles;
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoAtualizacaoMensagem, AoAtualizarMensagem);
end;

destructor TChat.Destroy;
begin
  Visualizador.Free;
  Editor.Free;
  inherited;
end;

procedure TChat.CriarControles;
begin
  FVisualizador := TChatVisualizador.Create(lytClient);
  lytClient.AddObject(Visualizador);
  Visualizador.Align := TAlignLayout.Client;
  Visualizador.AoVisualizar := AoVisualizar;
  Visualizador.LarguraMaximaConteudo := 800;
  Visualizador.AoClicar := AoClicar;
  Visualizador.AoChegarLimite := AoChegarLimite;
  Visualizador.AoClicarDownloadAnexo := AoClicarDownloadAnexo;

  Editor := TChatEditor.Create(lytClient);
  lytClient.AddObject(Editor);
  Editor.Align := TAlignLayout.Bottom;
  Editor.AoEnviar := AoEnviar;
  Editor.LarguraMaximaConteudo := 800;
end;

procedure TChat.Limpar;
begin
  FConversa := nil;
  FreeAndNil(Editor);
  FreeAndNil(FVisualizador);
  CriarControles;
end;

procedure TChat.ValidarVisualizacao;
var
  ID: Integer;
begin
  if Assigned(Conversa) then
    for ID in Visualizador.Visiveis do
      with Conversa.Mensagens.Get(ID) do
        if not Visualizada and (Lado = TLadoMensagem.Esquerdo) then
          Visualizada(True, True);
end;

procedure TChat.PosicionarUltima;
begin
  Visualizador.Posicionar;
end;

procedure TChat.AdicionarMensagem(Mensagem: TMensagem);
var
  DataConteudo: TConteudo;
  MsgCont: chat.tipos.TConteudo;
  MsgConteduos: TArray<chat.tipos.TConteudo>;
  Msg: TChatMensagem;
begin
  if not Assigned(Conversa) then
    Exit;

  for DataConteudo in Mensagem.Conteudos do
  begin
    MsgCont := chat.tipos.TConteudo.Create(TTipo(Pred(Integer(DataConteudo.Tipo))), DataConteudo.Conteudo);
    MsgCont.Nome := DataConteudo.Nome;
    MsgCont.Extensao := DataConteudo.Extensao;
    MsgConteduos := MsgConteduos + [MsgCont];
  end;

  Visualizador.AdicionarMensagem(Mensagem.ID, Mensagem.Remetente.Nome, Mensagem.Inserida, MsgConteduos);
  Msg := Visualizador.Mensagem[Mensagem.ID];
  Msg.NomeVisivel := Conversa.Tipo = TTipoConversa.Grupo;

  case Mensagem.Lado of
    TLadoMensagem.Esquerdo : Msg.Lado := TLado.Esquerdo;
    TLadoMensagem.Direito  : Msg.Lado := TLado.Direito;
  end;

  if Mensagem.Visualizada then
    Msg.Status := TStatus.Visualizada
  else
  if Mensagem.Recebida then
    Msg.Status := TStatus.Recebida
  else
    Msg.Status := TStatus.Pendente;
end;

procedure TChat.AdicionarMensagens(aMensagem: TArrayMensagens; IrParaUltima: Boolean = True);
var
  Mensagem: TMensagem;
  Anterior: Single;
begin
  if Length(aMensagem) = 0 then
    Exit;

  Anterior := Visualizador.Bottom;
  Visualizador.OcultarSeparadoresData;
  try
    for Mensagem in aMensagem do
    begin
      UltimaMensagem := Max(UltimaMensagem, Mensagem.id);
      AdicionarMensagem(Mensagem);
    end;
  finally
    Visualizador.ExibirSeparadoresData;
  end;

  if IrParaUltima then
    PosicionarUltima
  else
    Visualizador.Bottom := Anterior;
end;

procedure TChat.AoEnviar(Conteudos: TArray<chat.tipos.TConteudo>);
var
  Mensagem: TMensagem;
  Cont: chat.tipos.TConteudo;
begin
  if not Assigned(Conversa) then
    Exit;

  if Conversa.ID = 0 then
    Dados.NovoChat(FConversa);

  Mensagem := TMensagem.New(0)
    .Lado(TLadoMensagem.Direito)
    .Inserida(Now)
    .Remetente(Dados.FDadosApp.Usuario)
    .Conversa(Conversa);

  for Cont in Conteudos do
    Mensagem.Conteudos.Add(
      TConteudo.New(0)
        .Tipo(TTipoConteudo(Succ(Integer(Cont.Tipo))))
        .Conteudo(Cont.Conteudo)
        .Nome(Cont.Nome)
        .Extensao(Cont.Extensao)
    );

  if Assigned(AoEnviarMensagem) then
    AoEnviarMensagem(Self, Mensagem);
end;

procedure TChat.AoVisualizar(Frame: TFrame);
var
  Msg: TMensagem;
begin
  if Assigned(Conversa) and Assigned(Frame) and Frame.InheritsFrom(TChatMensagem) then
  begin
    Msg := Conversa.Mensagens.Get(TChatMensagem(Frame).ID);
    if not Msg.Visualizada and (Msg.Lado = TLadoMensagem.Esquerdo) then
      Msg.Visualizada(True, True);
  end;
end;

procedure TChat.AoAtualizarMensagem(const Sender: TObject; const M: TMessage);
var
  Msg: TMensagem;
  MsgChat: TChatMensagem;
begin
  if not Assigned(Conversa) then
    Exit;

  Msg := Conversa.Mensagens.Get(TEventoAtualizacaoMensagem(M).Value);
  if not Assigned(Msg) then
    Exit;

  MsgChat := Visualizador.Mensagem[TEventoAtualizacaoMensagem(M).Value];
  if not Assigned(MsgChat) then
    Exit;

  if Msg.Visualizada then
    MsgChat.Status := TStatus.Visualizada
  else
  if Msg.Recebida then
    MsgChat.Status := TStatus.Recebida
  else
    MsgChat.Status := TStatus.Pendente;
end;

procedure TChat.AoClicar(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Assigned(Frame) and Frame.InheritsFrom(TChatMensagem) then
  begin
    FMsgClicada := Frame;
    FObjetoClicado := Sender;
    if (Button = TMouseButton.mbLeft) and Assigned(Sender) and Sender.InheritsFrom(TChatConteudoImagem) then
      TVisualizadorMidia.Exibir(TChatConteudoImagem(Sender).Bitmap)
    else
    if Button = TMouseButton.mbRight then
      TPopupMenu.New(Frame)
        .Add('Copiar',
          procedure(Sender: TObject)
          begin
            Copiar;
          end
        ).Exibir(Screen.MousePos);
  end;
end;

procedure TChat.Copiar;
var
  Conteudos: TArray<TConteudo>;
  Conteudo: TConteudo;
  Texto: String;
  svc: IFMXExtendedClipboardService;
begin
  if not Assigned(FMsgClicada) or not FMsgClicada.InheritsFrom(TChatMensagem) then
    Exit;

  if not Assigned(FObjetoClicado) then
    Exit;

  if (FObjetoClicado.InheritsFrom(TImage) and TImage(FObjetoClicado).Parent.InheritsFrom(TChatConteudoImagem)) then
  begin
    if TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, svc) then
      svc.SetClipboard(TImage(FObjetoClicado).Bitmap);

    Exit;
  end;

  Conteudos := FConversa.Mensagens.Get(TChatMensagem(FMsgClicada).ID).Conteudos;
  Texto := EmptyStr;
  for Conteudo in Conteudos do
    if Conteudo.Tipo = TTipoConteudo.Texto then
      Texto := Texto + IfThen(not Texto.Trim.IsEmpty, sLineBreak) + Conteudo.Conteudo;

  if Texto.Trim.IsEmpty then
    Exit;

  if TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, svc) then
    svc.SetText(Texto.Replace('&', '&&'));
end;

procedure TChat.AoChegarLimite(Limite: TLimite);
begin
  if Limite = TLimite.Superior then
  begin
    Dados.ObterMensagens(Conversa.ID, True);
    AdicionarMensagens(Conversa.Mensagens.ParaExibir(True).OrdemTempo, False);
  end;
end;

procedure TChat.AoClicarDownloadAnexo(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Assigned(Frame) and Frame.InheritsFrom(TChatMensagem) then
    if Assigned(Sender) and (Sender.InheritsFrom(TLayout) and TLayout(Sender).Parent.InheritsFrom(TChatConteudoAnexo)) then
      Dados.SalvarAnexo(Conversa.Mensagens.Get(TChatMensagem(Frame).ID), TChatConteudoAnexo(TLayout(Sender).Parent).Identificador);
end;

procedure TChat.FocoEditor;
begin
  Editor.FocoEditorTexto;
end;

end.
