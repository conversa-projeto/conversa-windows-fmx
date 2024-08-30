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
//  Mensagem.Visualizador,
//  Mensagem.Editor,
//  Mensagem.Anexo,
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
    //Anexo: TAnexo;
    procedure AoVisualizar(Frame: TFrame);
    procedure AoEnviar(Conteudos: TArray<chat.tipos.TConteudo>);
    procedure AoAtualizarMensagem(const Sender: TObject; const M: TMessage);
    procedure AoClicar(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AoChegarLimite(Limite: TLimite);
    procedure CriarControles;
    procedure AoClicarDownloadAnexo(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,
      Y: Single);
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
  end;

implementation

{$R *.fmx}

uses
  chat.conteudo.imagem,
  chat.conteudo.anexo,
  Conversa.Visualizador.Midia;

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

//  Editor.AdicionaMensagem(
//    procedure(Mensagem: TMensagem)
//    begin
//    end
//  );
end;

destructor TChat.Destroy;
begin
  Visualizador.Free;
  Editor.Free;
//  Anexo.Free;
  inherited;
end;

procedure TChat.CriarControles;
begin
  FVisualizador := TChatVisualizador.Create(lytClient);
  lytClient.AddObject(Visualizador);
  Visualizador.Align := TAlignLayout.Client;
  Visualizador.AoVisualizar := AoVisualizar;
  Visualizador.LarguraMaximaConteudo := 500;
  Visualizador.AoClicar := AoClicar;
  Visualizador.AoChegarLimite := AoChegarLimite;
  Visualizador.AoClicarDownloadAnexo := AoClicarDownloadAnexo;

  Editor := TChatEditor.Create(lytClient);
  lytClient.AddObject(Editor);
  Editor.Align := TAlignLayout.Bottom;
  Editor.AoEnviar := AoEnviar;
  Editor.LarguraMaximaConteudo := 500;
end;

procedure TChat.Limpar;
begin
  FConversa := nil;
  FreeAndNil(Editor);
  FreeAndNil(FVisualizador);
  CriarControles;
//  Visualizador.Limpar;
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
  Visualizador.Posicionar();
end;

procedure TChat.AdicionarMensagem(Mensagem: TMensagem);
var
  DataConteudo: TConteudo;
  MsgConteduos: TArray<chat.tipos.TConteudo>;
  Msg: TChatMensagem;
begin
  if not Assigned(Conversa) then
    Exit;

  for DataConteudo in Mensagem.Conteudos do
    MsgConteduos := MsgConteduos + [chat.tipos.TConteudo.Create(TTipo(Pred(Integer(DataConteudo.Tipo))), DataConteudo.Conteudo)];

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
begin
  if Length(aMensagem) = 0 then
    Exit;
  for Mensagem in aMensagem do
  begin
    UltimaMensagem := Max(UltimaMensagem, Mensagem.id);
    AdicionarMensagem(Mensagem);
  end;
  if IrParaUltima then
    PosicionarUltima;
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
    Mensagem.Conteudos.Add(TConteudo.New(0).Tipo(TTipoConteudo(Succ(Integer(Cont.Tipo)))).Conteudo(Cont.Conteudo));

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
    if Assigned(Sender) and (Sender.InheritsFrom(TImage) and TImage(Sender).Parent.InheritsFrom(TChatConteudoImagem)) then
      TVisualizadorMidia.Exibir(TImage(Sender).Bitmap);
end;

procedure TChat.AoChegarLimite(Limite: TLimite);
begin
  Exit;
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
      ShowMessage('Ainda não ta pronto!');
end;

end.
