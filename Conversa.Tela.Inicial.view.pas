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

  Conversa.Principal,

  PascalStyleScript;

type
  TTelaInicial = class(TFormularioBase)
    Button1: TButton;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Iniciar;
  end;

var
  TelaInicial: TTelaInicial;

implementation

{$R *.fmx}

procedure TTelaInicial.Button1Click(Sender: TObject);
begin
  inherited;
  Exit;
  TPascalStyleScript.Instance.LoadFromFile('tema/escuro.pss');
end;

procedure TTelaInicial.FormShow(Sender: TObject);
begin
  inherited;
  Width := 1000;
  Button1.Visible := False;
  TLogin.New(lytClientForm, Iniciar);
//  rctFundo.Stroke.Kind := TBrushKind.Solid;
end;

procedure TTelaInicial.Iniciar;
begin
  TPrincipalView.New(lytClientForm);
  Dados.Conversas;
  Dados.tmrAtualizarMensagens.Enabled := True;
end;

end.
