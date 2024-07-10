unit Conversa.Tela.Inicial.view;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  Conversa.FormularioBase,
  Conversa.Login,
  Conversa.Dados,
  Conversa.Conversas.Listagem,
  FMX.Objects,
  FMX.Layouts,
  FMX.Ani,
  FMX.Controls.Presentation,
  FMX.StdCtrls,

  Conversa.Configuracoes,
  Conversa.Principal,
  Conversa.ModalView,

  PascalStyleScript;

type
  TTelaInicial = class(TFormularioBase)
    tmrShow: TTimer;
    procedure FormShow(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
  private
    procedure Iniciar;
    procedure ExibirTelaPrincipal;
  public
    ModalView: TModalView;
  end;

var
  TelaInicial: TTelaInicial;

implementation

uses
  Conversa.Conexao.AvisoInicioSistema,
  Conversa.Configurar.Conexao;

{$R *.fmx}

procedure TTelaInicial.FormShow(Sender: TObject);
begin
  inherited;
  ModalView := TModalView.Create(lytClientForm);


//  Button1.Visible := False;
  tmrShow.Enabled := True;
end;

procedure TTelaInicial.tmrShowTimer(Sender: TObject);
begin
  inherited;
  tmrShow.Enabled := False;
  Iniciar;
end;

procedure TTelaInicial.Iniciar;
begin
  if TConfigurarConexao.PrecisaConfigurar(Iniciar) then
    Exit;

  if TConexaoFalhaInicio.FalhaConexao(Iniciar) then
    Exit;

  TLogin.New(lytClientForm, ExibirTelaPrincipal);
end;

procedure TTelaInicial.ExibirTelaPrincipal;
begin
  with TPrincipalView.New(lytClientForm) do
  begin
    lytTitleBarClient.Parent := Self.lytTitleBarClient;
    lytTitleBarClient.Align := TAlignLayout.Client;
    txtUserLetra.Text := Dados.Nome[1];
  end;
  Dados.Conversas;
  Dados.tmrAtualizarMensagens.Enabled := True;
end;

end.
