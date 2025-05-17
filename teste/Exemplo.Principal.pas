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
  Conversa.Tipos;

type
  TPrincipal = class(TForm)
    btnLogin: TButton;
    edtLogin: TEdit;
    btnConversas: TButton;
    btnContatos: TButton;
    edtConversas: TEdit;
    edtContatos: TEdit;
    btnVisualizada: TButton;
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConversasClick(Sender: TObject);
    procedure btnContatosClick(Sender: TObject);
    procedure btnVisualizadaClick(Sender: TObject);
  private
    procedure ObterConversas(const Sender: TObject; const M: TObterConversas);
    procedure ErroServidor(const Sender: TObject; const M: TErroServidor);
  end;

var
  Principal: TPrincipal;

implementation

{$R *.dfm}

procedure TPrincipal.FormCreate(Sender: TObject);
begin
  TObterConversas.Subscribe(ObterConversas);
  TErroServidor.Subscribe(ErroServidor);
end;

procedure TPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TObterConversas.Unsubscribe(ObterConversas);
  TErroServidor.Unsubscribe(ErroServidor);
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

procedure TPrincipal.btnLoginClick(Sender: TObject);
var
  RespostaLogin: TRespostaLogin;
begin
  RespostaLogin := TAPIConversa.Login('37409-eduardo', '123');
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

end.
