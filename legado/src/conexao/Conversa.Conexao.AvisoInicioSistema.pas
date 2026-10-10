unit Conversa.Conexao.AvisoInicioSistema;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Objects, FMX.Layouts;

type
  TConexaoFalhaInicio = class(TFrameBase)
    rctFundo: TRectangle;
    rctCenter: TRectangle;
    txtTitulo: TText;
    lytgBotoes: TGridPanelLayout;
    rctBotaoTentarNovamente: TRectangle;
    txtBotaoTentarNovamente: TText;
    rctBotaoConfiguracoes: TRectangle;
    txtBotaoConfiguracoes: TText;
    pthIcone: TPath;
    Text1: TText;
    procedure rctBotaoTentarNovamenteClick(Sender: TObject);
    procedure rctBotaoConfiguracoesClick(Sender: TObject);
  private
    FOnClose: TProc;
    { Private declarations }
  public
    { Public declarations }
    class function FalhaConexao(Proc: TProc): Boolean;
  end;

var
  ConexaoFalhaInicio: TConexaoFalhaInicio;

implementation

{$R *.fmx}

uses
  Conversa.Tela.Inicial.view,
  Conversa.Configurar.Conexao,
  Conversa.Dados;

{ TConexaoFalhaInicio }

class function TConexaoFalhaInicio.FalhaConexao(Proc: TProc): Boolean;
begin
  if Dados.ServerOnline then
    Exit(False);

  Result := True;
  with TConexaoFalhaInicio.Create(TelaInicial.lytClientForm) do
  begin
    Parent := TFmxObject(TelaInicial.lytClientForm);
    Align := TAlignLayout.Center;
    FOnClose := Proc;
//    lytgBotoes.ColumnCollection[0].Value := 0;
//    rctBotaoSalvar.Margins.Left := 0;
  end;
end;

procedure TConexaoFalhaInicio.rctBotaoConfiguracoesClick(Sender: TObject);
begin
  inherited;
  TConfigurarConexao.ConfiguracaoInicial(
    TelaInicial.lytClientForm,
    procedure
    begin
      if not Dados.ServerOnline then Exit;
      FOnClose;
      FreeAndNil(Self);
    end
  );
end;

procedure TConexaoFalhaInicio.rctBotaoTentarNovamenteClick(Sender: TObject);
begin
  inherited;
  if not Dados.ServerOnline then
    Exit;

  FOnClose;
  FreeAndNil(Self);
end;

end.
