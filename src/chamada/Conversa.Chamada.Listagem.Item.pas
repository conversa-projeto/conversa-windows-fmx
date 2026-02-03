unit Conversa.Chamada.Listagem.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Objects, FMX.Layouts,
  Conversa.FrameBase,
  Conversa.Proxy.Tipos;

type
  TConversaChamadaListagemItem = class(TFrameBase)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytColuna1: TLayout;
    crclAvatar: TCircle;
    txtAbreviatura: TText;
    pthGrupo: TPath;
    lytColuna2: TLayout;
    txtNome: TText;
    lytLinha2: TLayout;
    txtStatus: TText;
    txtDuracao: TText;
    txtDataHora: TText;
    ColorAnimation1: TColorAnimation;
    lytTipoChamada: TLayout;
    pthIconeChamada_Realizada: TPath;
    pthIconeChamada_Recebida: TPath;
    pthIconeChamada_Recusada: TPath;
    procedure rctFundoClick(Sender: TObject);
  private
    FChamada: TChamadaHistorico;
    FOnClick: TProc<TChamadaHistorico>;
    procedure ConfigurarTipoChamada;
    procedure ConfigurarAvatar;
    procedure ConfigurarInformacoes;
    function FormatarDuracao(AInicio, AFim: TDateTime): String;
    function FormatarDataHora(AData: TDateTime): String;
  public
    constructor Create(AOwner: TComponent; AChamada: TChamadaHistorico); reintroduce; overload;
    function OnClick(Value: TProc<TChamadaHistorico>): TConversaChamadaListagemItem;
    property Chamada: TChamadaHistorico read FChamada;
  end;

implementation

{$R *.fmx}

uses
  System.DateUtils;

constructor TConversaChamadaListagemItem.Create(AOwner: TComponent; AChamada: TChamadaHistorico);
begin
  inherited Create(AOwner);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  FChamada := AChamada;
  ConfigurarTipoChamada;
  ConfigurarAvatar;
  ConfigurarInformacoes;
end;

function TConversaChamadaListagemItem.OnClick(Value: TProc<TChamadaHistorico>): TConversaChamadaListagemItem;
begin
  Result := Self;
  FOnClick := Value;
end;

procedure TConversaChamadaListagemItem.rctFundoClick(Sender: TObject);
begin
  if Assigned(FOnClick) then
    FOnClick(FChamada);
end;

procedure TConversaChamadaListagemItem.ConfigurarTipoChamada;
begin
  pthIconeChamada_Realizada.Visible := FChamada.tipo_acao = TChamadaHistoricoTipoAcao.Realizada;
  pthIconeChamada_Recebida.Visible := FChamada.tipo_acao = TChamadaHistoricoTipoAcao.Recebida;
  pthIconeChamada_Recusada.Visible := FChamada.tipo_acao = TChamadaHistoricoTipoAcao.Perdida;
end;

procedure TConversaChamadaListagemItem.ConfigurarAvatar;
begin

  if FChamada.tipo_chamada = TChamadaTipo.Grupo then
  begin
    txtAbreviatura.Visible := False;
    pthGrupo.Visible := True;
  end
  else
  begin
    pthGrupo.Visible := False;
    if FChamada.usuario_exibido_nome.Length > 0 then
      txtAbreviatura.Text := FChamada.usuario_exibido_nome.ToUpper[1]
    else
      txtAbreviatura.Text := '?';
    txtAbreviatura.Visible := True;
  end;
end;

procedure TConversaChamadaListagemItem.ConfigurarInformacoes;
var
  sStatus: String;
begin
  // Nome + quantidade de outros usuarios
  txtNome.Text := FChamada.usuario_exibido_nome;
  if FChamada.quantidade_outros_usuarios > 0 then
    txtNome.Text := txtNome.Text + ' (+' + FChamada.quantidade_outros_usuarios.ToString + ')';

  // Status
  case FChamada.status_chamada of
    TChamadaStatus.Iniciada: sStatus := 'Chamando...';
    TChamadaStatus.Recusada: sStatus := 'Recusada';
    TChamadaStatus.EmAndamento: sStatus := 'Em andamento';
    TChamadaStatus.Finalizada: sStatus := 'Finalizada';
    TChamadaStatus.Perdida: sStatus := 'Perdida';
    TChamadaStatus.Cancelada: sStatus := 'Cancelada';
  else
    sStatus := '';
  end;
  txtStatus.Text := sStatus;

  // Duracao
  if (FChamada.finalizada > 0) and (FChamada.iniciada > 0) then
    txtDuracao.Text := FormatarDuracao(FChamada.iniciada, FChamada.finalizada)
  else
    txtDuracao.Text := '';

  // Data/Hora
  txtDataHora.Text := FormatarDataHora(FChamada.adicionado_em);
end;

function TConversaChamadaListagemItem.FormatarDataHora(AData: TDateTime): String;
begin
  if AData = 0 then
    Exit('');
  if DaysBetween(AData, Now) = 0 then
    Result := FormatDateTime('hh:nn', AData)
  else if DaysBetween(AData, Now) < 7 then
    Result := FormatDateTime('ddd hh:nn', AData)
  else
    Result := FormatDateTime('dd/mm/yy', AData);
end;

function TConversaChamadaListagemItem.FormatarDuracao(AInicio, AFim: TDateTime): String;
var
  Seg, Min, Hr: Integer;
begin
  Seg := SecondsBetween(AInicio, AFim);
  if Seg < 60 then
    Exit(Seg.ToString + 's');
  Min := Seg div 60;
  Seg := Seg mod 60;
  if Min < 60 then
    Exit(Format('%d:%02d', [Min, Seg]));
  Hr := Min div 60;
  Min := Min mod 60;
  Result := Format('%d:%02d:%02d', [Hr, Min, Seg]);
end;

end.
