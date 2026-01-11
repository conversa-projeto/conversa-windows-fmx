unit Conversa.Notificacao.Item.Chamada;

interface

uses
  System.Classes,
  System.SysUtils,
  System.UITypes,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  Conversa.Notificacao.Item.Base;

type
  TNotificacaoItemChamada = class(TNotificacaoItemBase)
    rctFundo: TRectangle;
    lytTopo: TLayout;
    txtTitulo: TText;
    lytCloseButton: TLayout;
    rctClose: TRectangle;
    lytClose: TLayout;
    pthClose: TPath;
    lytCentro: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtUserLetra: TText;
    lytConteudo: TLayout;
    txtNome: TText;
    txtTipoChamada: TText;
    txtDescricao: TText;
    lytBotoes: TLayout;
    rctAtender: TRectangle;
    txtAtender: TText;
    rctRecusar: TRectangle;
    txtRecusar: TText;
    procedure lytCloseButtonClick(Sender: TObject);
    procedure rctAtenderClick(Sender: TObject);
    procedure rctRecusarClick(Sender: TObject);
  private
    FChamadaId: Integer;
    FOnAtender: TProc<Integer>;
    FOnRecusar: TProc<Integer>;
  public
    class function New(AOwner: TFmxObject): TNotificacaoItemChamada;
    procedure Fechar; override;
    procedure Configurar(AChamadaId: Integer; const ANome, ATipoChamada, ADescricao: String;
      AOnAtender, AOnRecusar: TProc<Integer>);
    property ChamadaId: Integer read FChamadaId;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Notificacao,
  Conversa.Notificacao.Tipos;

class function TNotificacaoItemChamada.New(AOwner: TFmxObject): TNotificacaoItemChamada;
begin
  Sleep(1);
  Result := TNotificacaoItemChamada.Create(AOwner);
  Result.Name := 'TNotificacaoItemChamada_'+ FormatDateTime('yyyymmddHHnnsszzzz', Now);
  Result.Parent := AOwner;
  Result.Align := TAlignLayout.Top;
  Result.Show;
end;

procedure TNotificacaoItemChamada.Configurar(AChamadaId: Integer;
  const ANome, ATipoChamada, ADescricao: String;
  AOnAtender, AOnRecusar: TProc<Integer>);
begin
  FChamadaId := AChamadaId;
  FId := AChamadaId;
  FOnAtender := AOnAtender;
  FOnRecusar := AOnRecusar;
  txtNome.Text := ANome;
  txtTipoChamada.Text := ATipoChamada;
  txtDescricao.Text := ADescricao;
  if ANome.Length > 0 then
    txtUserLetra.Text := ANome.Substring(1, 1).ToUpper
  else
    txtUserLetra.Text := '?';
end;

procedure TNotificacaoItemChamada.Fechar;
begin
  TNotificacaoManager.Fechar(TTipoNotificacao.Chamada, FChamadaId);
end;

procedure TNotificacaoItemChamada.lytCloseButtonClick(Sender: TObject);
begin
  if Assigned(FOnRecusar) then
    FOnRecusar(FChamadaId);
  Fechar;
end;

procedure TNotificacaoItemChamada.rctAtenderClick(Sender: TObject);
begin
  if Assigned(FOnAtender) then
    FOnAtender(FChamadaId);
  Fechar;
end;

procedure TNotificacaoItemChamada.rctRecusarClick(Sender: TObject);
begin
  if Assigned(FOnRecusar) then
    FOnRecusar(FChamadaId);
  Fechar;
end;

end.
