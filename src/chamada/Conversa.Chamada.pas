unit Conversa.Chamada;

interface

uses
  System.JSON,
  System.SysUtils,
  IdGlobal,
  Conversa.Tipos,
  Conversa.Chamada.BarraTitulo,
  Conversa.Chamada.view;

type
  TConversaChamada = class;

  TConversaChamadas = class
  private
    class var FInstance: TConversaChamadas;
    FChamadas: TArray<TConversaChamada>;
  public
    class constructor Create;
    class destructor Destroy;
    class function Instance: TConversaChamadas;

    destructor Destroy; override;

    function Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;

    procedure FinalizarTodas;
  end;

  TConversaChamada = class
  private
    FID: Integer;
    FStatus: TStatusChamada;
    FChamadaView: TConversaChamadaView;
    FBarraTitulo: TConversaChamadaBarraTitulo;
    FParticipantes: TArrayUsuarios;
    procedure SetStatus(const Value: TStatusChamada);
  protected
    class function EventoChamada(Method: TMethod): Boolean;
    procedure ProcessarEvento(Method: TMethod; Tamanho: Integer; Bytes: TIdBytes);

    procedure OnChamadaFinalizada;
    procedure OnUsuarioRejeitou;
    procedure OnUsuarioEntrou;
    procedure OnUsuarioSaiu;

    procedure ChamadaAtendida;
    procedure ChamadaFinalizada;

    procedure IniciarCapturaAudio;
    procedure IniciarReproducaoAudio;

    procedure NotificarChamada;
    procedure ExibirChamada;

    procedure IniciarChamada(AParticipantes: TArrayUsuarios);

    property Status: TStatusChamada read FStatus write SetStatus;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancelar;
    procedure Rejeitar;
    procedure Entrar;
    procedure Sair;
    procedure Finalizar;
    procedure OnChamadaRecebida;
    function GetParticipantes: TArrayUsuarios;
  end;

implementation

uses
  Conversa.Proxy,
  Conversa.Tela.Inicial.view;

{ TConversaChamadas }

class constructor TConversaChamadas.Create;
begin
  FInstance := TConversaChamadas.Create;
end;

class destructor TConversaChamadas.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TConversaChamadas.Instance: TConversaChamadas;
begin
  Result := FInstance;
end;

destructor TConversaChamadas.Destroy;
begin
  FinalizarTodas;
  inherited;
end;

function TConversaChamadas.Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;
begin
  Result := TConversaChamada.Create;
  FChamadas := FChamadas + [Result];
  Result.IniciarChamada(AParticipantes);
end;

procedure TConversaChamadas.FinalizarTodas;
begin
  //
end;

{ TConversaChamada }

constructor TConversaChamada.Create;
begin
  FStatus := TStatusChamada.Desconhecido;
end;

destructor TConversaChamada.Destroy;
begin
  Sair;

  if Assigned(FBarraTitulo) then
    FreeAndNil(FBarraTitulo);
  if Assigned(FChamadaView) then
    FreeAndNil(FChamadaView);
  inherited;
end;

procedure TConversaChamada.Cancelar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Cancelar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
//  TConversaConexao.Instance.TCPSendCommand(TMethod.CancelarChamada, TSerializer<Integer>.ParaBytes(FRemetente.ID));
//  ChamadaFinalizada;
end;

procedure TConversaChamada.Rejeitar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Rejeitar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
//  TConversaConexao.Instance.TCPSendCommand(TMethod.RecusarChamada, TSerializer<Integer>.ParaBytes(FRemetente.ID));
//  ChamadaFinalizada;
end;

procedure TConversaChamada.Entrar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Entrar(FID);
  Status := TStatusChamada.ChamadaEmAndamento;
//  TConversaConexao.Instance.TCPSendCommand(TMethod.AtenderChamada, TSerializer<Integer>.ParaBytes(FRemetente.ID));
//  ChamadaAtendida;
end;

procedure TConversaChamada.Sair;
begin
  if not FStatus.Ativa then
    Exit;

  Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.Finalizar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Finalizar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.OnChamadaFinalizada;
begin
  //
end;

procedure TConversaChamada.OnChamadaRecebida;
begin
  ExibirChamada;
  FChamadaView.Status := TStatusChamada.RecebentoChamada;
  FBarraTitulo.Status(TStatusChamada.RecebentoChamada);
//  with TChamadaBarraTitulo.Instance do
//  begin
//    Exibir;
//    Status(TMethod.ReceberChamada);
//    with TJSONValue.ParseJSONValue(FRemetente.Identificador) as TJSONObject do
//    try
//      txtTempoLigacao.Text := GetValue<String>('nome');
//    finally
//      Free;
//    end;
//  end;
end;

procedure TConversaChamada.OnUsuarioRejeitou;
begin
  Status := TStatusChamada.Recusada;
//  TChamadaBarraTitulo.Instance.Status(TMethod.RecusarChamada);
end;

procedure TConversaChamada.OnUsuarioEntrou;
begin
  ChamadaAtendida;
end;

procedure TConversaChamada.OnUsuarioSaiu;
begin
  ChamadaFinalizada;
end;

class function TConversaChamada.EventoChamada(Method: TMethod): Boolean;
begin
  Result := True;
//  case Method of
//    TMethod.ReceberChamada: Exit(True);
//    TMethod.AtenderChamada,
//    TMethod.RetomarChamada: Exit(True);
//    TMethod.RecusarChamada: Exit(True);
//    TMethod.FinalizarChamada,
//    TMethod.UsuarioDesconectado: Exit(True);
//    TMethod.CancelarChamada: Exit(True);
//    TMethod.DestinatarioOcupado: Exit(True);
//  end;
//  Result := False;
end;

function TConversaChamada.GetParticipantes: TArrayUsuarios;
begin
  Result := FParticipantes;
end;

procedure TConversaChamada.ProcessarEvento(Method: TMethod; Tamanho: Integer; Bytes: TIdBytes);
begin
//  if Method in [TMethod.AtenderChamada] then
//    FRemetente.ID := TSerializer<Integer>.DeBytes(Bytes)
//  else
//  if Method in [TMethod.ReceberChamada, TMethod.RetomarChamada] then
//  begin
//    if FRemetente.ID = 0 then
//      FRemetente := TSerializer<TPonta>.DeBytes(Bytes)
////    else
////      with TSerializer<TPonta>.DeBytes(Bytes) do
////        TCPSendCommand(TMethod.DestinatarioOcupado, TSerializer<Integer>.ParaBytes(ID))
//  end;
//  case Method of
//    TMethod.ReceberChamada: OnReceberChamada;
//    TMethod.AtenderChamada: OnChamadaAtendida;
////    TMethod.RetomarChamada:
//    TMethod.RecusarChamada: OnChamadaRecusada;
////    TMethod.FinalizarChamada,
////    TMethod.UsuarioDesconectado: FinalizarChamada(TOrigemComando.Remoto);
//    TMethod.CancelarChamada: OnChamadaCancelada;
////    TMethod.DestinatarioOcupado: DestinatarioOcupado;
//  end;
end;

procedure TConversaChamada.IniciarChamada(AParticipantes: TArrayUsuarios);
var
  jo: TJSONObject;
  ja: TJSONArray;
  P: Conversa.Tipos.TUsuario;
begin
  FParticipantes := AParticipantes;
  FStatus := TStatusChamada.IniciandoChamada;
  ExibirChamada;

  ja := TJSONArray.Create;
  jo := TJSONObject.Create;
  jo.AddPair('usuarios', ja);

  for P in AParticipantes do
    ja.Add(TJSONObject.Create.AddPair('id', P.ID));

  FID := Conversa.Proxy.TAPIConversa.Chamada.Iniciar(jo).Dados.id;

  Entrar;
  ChamadaFinalizada;

//  TConversaConexao.Instance.TCPSendCommand(TMethod.IniciarChamada, TSerializer<Integer>.ParaBytes(ID));
end;

procedure TConversaChamada.ChamadaAtendida;
begin
  Status := TStatusChamada.ChamadaEmAndamento;
//  TChamadaBarraTitulo.Instance.Status(TMethod.AtenderChamada);
end;

procedure TConversaChamada.ChamadaFinalizada;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
  Status := TStatusChamada.ChamadaFinalizada;
//  TChamadaBarraTitulo.Instance.Ocultar;
end;

procedure TConversaChamada.IniciarCapturaAudio;
begin
  //
end;

procedure TConversaChamada.IniciarReproducaoAudio;
begin
  //
end;

procedure TConversaChamada.ExibirChamada;
begin
  FChamadaView := TConversaChamadaView.Create(nil, Self);
  FChamadaView.AtualizarListaParticipante;
  FChamadaView.Show;
  FChamadaView.Status := Status;

  FBarraTitulo := TConversaChamadaBarraTitulo.Create(TelaInicial.lytTitleBarClient, Self);

  with FBarraTitulo do
  begin
    Exibir;
    txtTempoLigacao.AutoSize := True;
//    txtTempoLigacao.Text := sNome;
    Status(Self.Status);
    txtTempoLigacao.AutoSize := False;
  end;
end;

procedure TConversaChamada.NotificarChamada;
begin
  //
end;

procedure TConversaChamada.SetStatus(const Value: TStatusChamada);
begin
  FStatus := Value;

  if Assigned(FChamadaView) then
    FChamadaView.Status := FStatus;

  if Assigned(FBarraTitulo) then
    FBarraTitulo.Status(FStatus);
end;

end.
