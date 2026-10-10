unit Conversa.Chamada.Detalhe;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts,
  Conversa.FrameBase,
  Conversa.Proxy.Tipos;

type
  TConversaChamadaDetalhe = class(TFrameBase)
    rctFundo: TRectangle;
    lytHeader: TLayout;
    lytIcone: TLayout;
    crclIcone: TCircle;
    pthIcone: TPath;
    txtNome: TText;
    txtTipo: TText;
    lytDados: TLayout;
    txtLabelIniciada: TText;
    txtIniciada: TText;
    txtLabelFinalizada: TText;
    txtFinalizada: TText;
    txtLabelDuracao: TText;
    txtDuracao: TText;
    txtLabelStatus: TText;
    txtStatus: TText;
    lytBotoes: TLayout;
    rctBtnVoltar: TRectangle;
    txtBtnVoltar: TText;
    rctBtnChamar: TRectangle;
    txtBtnChamar: TText;
    procedure rctBtnVoltarClick(Sender: TObject);
    procedure rctBtnChamarClick(Sender: TObject);
  private
    FChamada: TChamadaHistorico;
    procedure ConfigurarTela;
    procedure ConfigurarIcone;
  public
    constructor Create(AOwner: TComponent; AChamada: TChamadaHistorico); reintroduce; overload;
    class procedure Exibir(AChamada: TChamadaHistorico);
  end;

var
  ConversaChamadaDetalhe: TConversaChamadaDetalhe;

implementation

{$R *.fmx}

uses
  System.DateUtils,
  Conversa.Tela.Inicial.view;

constructor TConversaChamadaDetalhe.Create(AOwner: TComponent; AChamada: TChamadaHistorico);
begin
  inherited Create(AOwner);
  FChamada := AChamada;
  ConfigurarTela;
end;

class procedure TConversaChamadaDetalhe.Exibir(AChamada: TChamadaHistorico);
begin
  TelaInicial.ModalView.Exibir(TConversaChamadaDetalhe.Create(TelaInicial.lytClientForm, AChamada));
end;

procedure TConversaChamadaDetalhe.ConfigurarTela;
var
  Seg, Min, Hr: Integer;
begin
  ConfigurarIcone;

  // Nome
  txtNome.Text := FChamada.usuario_exibido_nome;
  if FChamada.quantidade_outros_usuarios > 0 then
    txtNome.Text := txtNome.Text + ' (+' + FChamada.quantidade_outros_usuarios.ToString + ')';

  // Tipo
  case FChamada.tipo_chamada of
    TChamadaTipo.Simples: txtTipo.Text := 'Chamada Individual';
    TChamadaTipo.Grupo: txtTipo.Text := 'Chamada em Grupo';
  else
    txtTipo.Text := 'Chamada';
  end;

  // Datas
  if FChamada.iniciada > 0 then
    txtIniciada.Text := FormatDateTime('dd/mm/yyyy hh:nn:ss', FChamada.iniciada)
  else
    txtIniciada.Text := '-';

  if FChamada.finalizada > 0 then
    txtFinalizada.Text := FormatDateTime('dd/mm/yyyy hh:nn:ss', FChamada.finalizada)
  else
    txtFinalizada.Text := '-';

  // Duracao
  if (FChamada.finalizada > 0) and (FChamada.iniciada > 0) then
  begin
    Seg := SecondsBetween(FChamada.iniciada, FChamada.finalizada);
    Hr := Seg div 3600;
    Min := (Seg mod 3600) div 60;
    Seg := Seg mod 60;
    txtDuracao.Text := Format('%02d:%02d:%02d', [Hr, Min, Seg]);
  end
  else
    txtDuracao.Text := '-';

  // Status
  case FChamada.status_chamada of
    TChamadaStatus.Iniciada: txtStatus.Text := 'Chamando...';
    TChamadaStatus.Recusada: txtStatus.Text := 'Recusada';
    TChamadaStatus.EmAndamento: txtStatus.Text := 'Em andamento';
    TChamadaStatus.Finalizada: txtStatus.Text := 'Finalizada';
    TChamadaStatus.Perdida: txtStatus.Text := 'Perdida';
    TChamadaStatus.Cancelada: txtStatus.Text := 'Cancelada';
  else
    txtStatus.Text := '-';
  end;
end;

procedure TConversaChamadaDetalhe.ConfigurarIcone;
begin
  case FChamada.tipo_acao of
    TChamadaHistoricoTipoAcao.Realizada:
    begin
      pthIcone.Data.Data := 'M7 17L17 7M17 7H7M17 7V17';
      crclIcone.Fill.Color := $FF007DFF;
    end;
    TChamadaHistoricoTipoAcao.Recebida:
    begin
      pthIcone.Data.Data := 'M17 7L7 17M7 17H17M7 17V7';
      crclIcone.Fill.Color := $FF00C853;
    end;
  else
    pthIcone.Data.Data := 'M17 7L7 17M7 17H17M7 17V7';
    crclIcone.Fill.Color := $FFFF5252;
  end;
end;

procedure TConversaChamadaDetalhe.rctBtnVoltarClick(Sender: TObject);
begin
  TelaInicial.ModalView.Ocultar;
end;

procedure TConversaChamadaDetalhe.rctBtnChamarClick(Sender: TObject);
begin
  // TODO: Iniciar nova chamada para FChamada.usuario_exibido_id
  TelaInicial.ModalView.Ocultar;
end;

end.
