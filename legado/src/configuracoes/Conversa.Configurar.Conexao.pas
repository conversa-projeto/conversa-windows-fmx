unit Conversa.Configurar.Conexao;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Edit;

type
  TConfigurarConexao = class(TFrameBase)
    rctFundo: TRectangle;
    rctCenter: TRectangle;
    txtTitulo: TText;
    rctHost: TRectangle;
    Text1: TText;
    edtHost: TEdit;
    lytgBotoes: TGridPanelLayout;
    rctBotaoCancelar: TRectangle;
    txtBotaoCancelar: TText;
    rctBotaoSalvar: TRectangle;
    txtBotaoSalvar: TText;
    procedure rctBotaoSalvarClick(Sender: TObject);
    procedure rctBotaoSalvarMouseEnter(Sender: TObject);
    procedure rctBotaoSalvarMouseLeave(Sender: TObject);
  private
    { Private declarations }
    FOnClose: TProc;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    class procedure ConfiguracaoInicial(AOwner: TFmxObject; AOnClose: TProc);
    class function PrecisaConfigurar(Proc: TProc): Boolean;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Configuracoes,
  Conversa.Tela.Inicial.view,
  System.UIConsts;

{ TConfigurarConexao }

class function TConfigurarConexao.PrecisaConfigurar(Proc: TProc): Boolean;
begin
  if not Configuracoes.Host.Trim.IsEmpty then
    Exit(False);

  Result := True;
  ConfiguracaoInicial(TelaInicial.lytClientForm, Proc);
end;

class procedure TConfigurarConexao.ConfiguracaoInicial(AOwner: TFmxObject; AOnClose: TProc);
begin
  with TConfigurarConexao.Create(AOwner) do
  begin
    Align := TAlignLayout.Center;
    FOnClose := AOnClose;
    lytgBotoes.ColumnCollection[0].Value := 0;
    rctBotaoSalvar.Margins.Left := 0;
  end;
end;

constructor TConfigurarConexao.Create(AOwner: TComponent);
begin
  inherited;
  Parent := TFmxObject(AOwner);
  edtHost.Text := Configuracoes.Host;
end;

procedure TConfigurarConexao.rctBotaoSalvarClick(Sender: TObject);
begin
  Configuracoes.Host := edtHost.Text;
  Configuracoes.Save;
  FOnClose;
  FreeAndNil(Self);
end;

procedure TConfigurarConexao.rctBotaoSalvarMouseEnter(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := MakeColor(230, 242, 255);
end;

procedure TConfigurarConexao.rctBotaoSalvarMouseLeave(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := TAlphaColors.Whitesmoke;
end;

end.
