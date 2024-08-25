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
    procedure AoAtualizarMensagem(ID: Integer);
  public
    UltimaMensagem: Integer;
    AoEnviarMensagem: TProc<TChat, TMensagem>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Conversa: TConversa read FConversa write FConversa;


    property Visualizador: TChatVisualizador read FVisualizador;
    procedure AdicionarMensagem(Mensagem: TMensagem);
    procedure AdicionarMensagens(aMensagem: TArrayMensagens);
    procedure PosicionarUltima;
    procedure Limpar;
    procedure ValidarVisualizacao;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Eventos;

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

  FVisualizador := TChatVisualizador.Create(lytClient);
  lytClient.AddObject(Visualizador);
  Visualizador.Align := TAlignLayout.Client;
  Visualizador.AoVisualizar := AoVisualizar;
  Visualizador.LarguraMaximaConteudo := 500;

  Editor := TChatEditor.Create(lytClient);
  lytClient.AddObject(Editor);
  Editor.Align := TAlignLayout.Bottom;
  Editor.AoEnviar := AoEnviar;
  Editor.LarguraMaximaConteudo := 500;

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

procedure TChat.Limpar;
begin
//  Visualizador.Limpar;
end;

procedure TChat.ValidarVisualizacao;
var
  ID: Integer;
begin
  for ID in Visualizador.Visiveis do
    Conversa.Mensagens.Get(ID).Visualizada(True);
//  Visualizador.ValidarVisualizacao;
end;

procedure TChat.PosicionarUltima;
begin
  Visualizador.Posicionar();
end;

procedure TChat.AdicionarMensagem(Mensagem: TMensagem);
var
  DataConteudo: TConteudo;
  MsgConteduos: TArray<chat.tipos.TConteudo>;
begin
  for DataConteudo in Mensagem.Conteudos do
    MsgConteduos := MsgConteduos + [chat.tipos.TConteudo.Create(TTipo(Pred(Integer(DataConteudo.Tipo))), DataConteudo.Conteudo)];

  Visualizador.AdicionarMensagem(Mensagem.ID, Mensagem.Remetente.Nome, Mensagem.Inserida, MsgConteduos);

  case Mensagem.Lado of
    TLadoMensagem.Esquerdo : Visualizador.Mensagem[Mensagem.ID].Lado := TLado.Esquerdo;
    TLadoMensagem.Direito  : Visualizador.Mensagem[Mensagem.ID].Lado := TLado.Direito;
  end;

  if Mensagem.Visualizada then
    Visualizador.Mensagem[Mensagem.ID].Status := TStatus.Visualizada
  else
  if Mensagem.Recebida then
    Visualizador.Mensagem[Mensagem.ID].Status := TStatus.Recebida
  else
    Visualizador.Mensagem[Mensagem.ID].Status := TStatus.Pendente;

  TEvento.Adicionar(TTipoEvento.AtualizacaoMensagem, AoAtualizarMensagem, Mensagem.ID);
  Visualizador.AdicionarSeparadorData(TDate(Trunc(Mensagem.Inserida)), Visualizador.Mensagem[Mensagem.ID].Position.Y - 10);
end;

procedure TChat.AdicionarMensagens(aMensagem: TArrayMensagens);
var
  Mensagem: TMensagem;
begin
  for Mensagem in aMensagem do
  begin
    UltimaMensagem := Max(UltimaMensagem, Mensagem.id);
    AdicionarMensagem(Mensagem);
  end;
  PosicionarUltima;
end;

procedure TChat.AoEnviar(Conteudos: TArray<chat.tipos.TConteudo>);
var
  Mensagem: TMensagem;
  Cont: chat.tipos.TConteudo;
begin
  if Conversa.ID = 0 then
  begin
    Dados.NovoChat(FConversa);
  end;

  Mensagem := TMensagem.New(0)
    .Lado(TLadoMensagem.Direito)
    .Inserida(Now)
    .Remetente(Dados.FDadosApp.Usuario)
    .Conversa(Conversa);

  for Cont in Conteudos do
    Mensagem.Conteudos.Add(TConteudo.New(0).Tipo(TTipoConteudo(Succ(Integer(Cont.Tipo)))).Conteudo(Cont.Conteudo));

  if Assigned(AoEnviarMensagem) then
    AoEnviarMensagem(Self, Mensagem);

//  Visualizador.PosicionarUltima;
end;

procedure TChat.AoVisualizar(Frame: TFrame);
var
  Msg: TMensagem;
begin
  if Assigned(Frame) and Frame.InheritsFrom(TChatMensagem) then
  begin
    Msg := Conversa.Mensagens.Get(TChatMensagem(Frame).ID);
    if not Msg.Visualizada and (Msg.Lado = TLadoMensagem.Esquerdo) then
      Msg.Visualizada(True, True);
  end;
end;

procedure TChat.AoAtualizarMensagem(ID: Integer);
var
  Msg: TMensagem;
  MsgChat: TChatMensagem;
begin
  Msg := Conversa.Mensagens.Get(ID);
  MsgChat := Visualizador.Mensagem[ID];

  if Msg.Visualizada then
    MsgChat.Status := TStatus.Visualizada
  else
  if Msg.Recebida then
    MsgChat.Status := TStatus.Recebida
  else
    MsgChat.Status := TStatus.Pendente;
end;

end.
