// Eduardo/Daniel - 17/05/2025
unit Exemplo.Principal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Conversa.Eventos,
  Conversa.Proxy,
  Conversa.Proxy.Tipos,
  GenericSocket.Interfaces,
  GenericSocket.Client;

type
  TPrincipal = class(TForm)
    btnLogin: TButton;
    edtLogin: TEdit;
    btnConversas: TButton;
    btnContatos: TButton;
    edtConversas: TEdit;
    edtContatos: TEdit;
    btnVisualizada: TButton;
    btnMensagens: TButton;
    edtMensagem: TEdit;
    btnEnviar: TButton;
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConversasClick(Sender: TObject);
    procedure btnContatosClick(Sender: TObject);
    procedure btnVisualizadaClick(Sender: TObject);
    procedure btnMensagensClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
  private
    Client: ISocketClient;
    procedure ObterConversas(const Sender: TObject; const M: TObterConversas);
    procedure ErroServidor(const Sender: TObject; const M: TErroServidor);
    procedure DownloadAnexo(const Sender: TObject; const M: TDownloadAnexo);
    procedure ObterMensagens(const Sender: TObject; const M: TObterMensagens);
    procedure ObterMensagemStatus(const Sender: TObject; const M: TObterMensagensStatus);
    procedure ObterMensagensNovas(const Sender: TObject; const M: TObterMensagensNovas);
  end;

var
  Principal: TPrincipal;

implementation

{$R *.dfm}

procedure TPrincipal.FormCreate(Sender: TObject);
begin
  TObterConversas.Subscribe(ObterConversas);
  TErroServidor.Subscribe(ErroServidor);
  TDownloadAnexo.Subscribe(DownloadAnexo);
  TObterMensagens.Subscribe(ObterMensagens);
  TObterMensagensStatus.Subscribe(ObterMensagemStatus);
  TObterMensagensNovas.Subscribe(ObterMensagensNovas);

  Client := TSocketClient.New;
  Client.Connect('localhost', 55888, '2');
  Client.RegisterCallback(
    'mensagem',
    function(Conteudo: String): String
    begin
      Result := '';
      ShowMessage(Conteudo);
    end
  );
end;

procedure TPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TObterConversas.Unsubscribe(ObterConversas);
  TErroServidor.Unsubscribe(ErroServidor);
  TDownloadAnexo.Unsubscribe(DownloadAnexo);
  TObterMensagens.Unsubscribe(ObterMensagens);
  TObterMensagensStatus.Unsubscribe(ObterMensagemStatus);
  TObterMensagensNovas.Unsubscribe(ObterMensagensNovas);

  Client.Disconnet;
end;

procedure TPrincipal.ObterConversas(const Sender: TObject; const M: TObterConversas);
begin
  for var Item in M.Value.Dados do
    edtConversas.Text := Item.descricao;
end;

procedure TPrincipal.ErroServidor(const Sender: TObject; const M: TErroServidor);
begin
  raise Exception.Create(M.Value.Erro);
end;

procedure TPrincipal.DownloadAnexo(const Sender: TObject; const M: TDownloadAnexo);
begin
  //
end;

procedure TPrincipal.ObterMensagens(const Sender: TObject; const M: TObterMensagens);
begin
  for var Item in M.Value.Dados do
    if Item.alterada <> 0 then
      edtMensagem.Text := Item.id.ToString;
end;

procedure TPrincipal.ObterMensagemStatus(const Sender: TObject; const M: TObterMensagensStatus);
begin
  //
end;

procedure TPrincipal.ObterMensagensNovas(const Sender: TObject; const M: TObterMensagensNovas);
begin
  //
end;

procedure TPrincipal.btnLoginClick(Sender: TObject);
var
  RespostaLogin: TRespostaLogin;
begin
  RespostaLogin := TAPIConversa.Login('daniel', '123');
  edtLogin.Text := RespostaLogin.nome;
end;

procedure TPrincipal.btnConversasClick(Sender: TObject);
begin
  TAPIConversa.Conversas;
end;

procedure TPrincipal.btnContatosClick(Sender: TObject);
begin
  for var Item in TAPIConversa.Usuario.Contatos do
    edtContatos.Text := Item.nome;
end;

procedure TPrincipal.btnVisualizadaClick(Sender: TObject);
begin
  TAPIConversa.Mensagem.Visualizar(1, 1);
end;

procedure TPrincipal.btnMensagensClick(Sender: TObject);
begin
  TAPIConversa.Mensagens(1, 0, 10, 10);
end;

procedure TPrincipal.btnEnviarClick(Sender: TObject);
var
  req: TReqMensagem;
begin
  req := Default(TReqMensagem);
  req.conversa_id := 1;
  req.conteudos := [];
  TAPIConversa.Mensagem.Incluir(req);
end;

end.
