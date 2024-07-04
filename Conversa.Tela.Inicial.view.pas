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
    Button1: TButton;
    tmrShow: TTimer;
    lytProfileView: TLayout;
    Circle1: TCircle;
    txtUserLetra: TText;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
  private
    procedure Iniciar;
  public
    ModalView: TModalView;
  end;

var
  TelaInicial: TTelaInicial;

implementation

uses
  Conversa.Configurar.Conexao;

{$R *.fmx}

procedure TTelaInicial.Button1Click(Sender: TObject);
begin
  inherited;
  TPascalStyleScript.Instance.LoadFromFile('tema/escuro.pss');
end;

procedure TTelaInicial.FormShow(Sender: TObject);
begin
  inherited;
  ModalView := TModalView.Create(lytClientForm);


//  Button1.Visible := False;
  tmrShow.Enabled := True;
end;

procedure TTelaInicial.Iniciar;
begin
  TPrincipalView.New(lytClientForm);
  Dados.Conversas;
  Dados.tmrAtualizarMensagens.Enabled := True;
end;

procedure TTelaInicial.tmrShowTimer(Sender: TObject);
begin
  inherited;
  tmrShow.Enabled := False;
  if Configuracoes.Host.Trim.IsEmpty then
  begin
    TConfigurarConexao.ConfiguracaoInicial(
      lytClientForm,
      procedure
      begin
        TLogin.New(lytClientForm, Iniciar);
      end
    );
  end
  else
    TLogin.New(lytClientForm, Iniciar);
end;

end.
