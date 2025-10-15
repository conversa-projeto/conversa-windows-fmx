unit Conversa.Chamada;

{

- Notificação correta
- Status de participante
- Mensagem correta

}

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  IdGlobal,
  Conversa.Tipos,
  Conversa.Proxy.Tipos,
  Conversa.Chamada.BarraTitulo,
  Conversa.Chamada.view;

type
  TConversaChamada = class;

  TConversaChamadas = class
  private
    class var FInstance: TConversaChamadas;
    FChamadas: TDictionary<Integer, TConversaChamada>;
  public
    class constructor Create;
    class destructor Destroy;
    class function Instance: TConversaChamadas;
    class function SocketType(Tipo: TSocketMessageType): Boolean;
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;

    constructor Create;
    destructor Destroy; override;

    function Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;
    function GetChamada(const AID: Integer): TConversaChamada;

    procedure FinalizarTodas;
  end;

  TConversaChamada = class
  private
    FID: Integer;
    FStatus: TChamadaStatusLocal;
    FChamadaView: TConversaChamadaView;
    FBarraTitulo: TConversaChamadaBarraTitulo;
    FUsuarios: TArray<TChamadaDadosUsuario>;
    procedure SetStatus(const Value: TChamadaStatusLocal);
    procedure AtualizarStatusUsuario(const Usuario: Integer; Status: TChamadaStatusUsuario);

    procedure OnChamadaFinalizada;
    procedure ChamadaFinalizada;
  protected
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;


    procedure IniciarCapturaAudio;
    procedure IniciarReproducaoAudio;

    procedure NotificarChamada;
    procedure ExibirChamada;

    procedure IniciarChamada(AParticipantes: TArrayUsuarios);

    property Status: TChamadaStatusLocal read FStatus write SetStatus;
  public
    constructor Create(const AID: Integer);
    destructor Destroy; override;
    procedure Cancelar;
    procedure Recusar;
    procedure Entrar;
    procedure Sair(const AFinalizar: Boolean = False);
    procedure Finalizar;
    procedure AtualizarDados;
    procedure OnChamadaRecebida;
    function GetUsuarios: TArray<TChamadaDadosUsuario>;
  end;

implementation

uses
  Conversa.Dados,
  Conversa.Proxy,
  Conversa.Tela.Inicial.view;

{ TConversaChamadas }

class function TConversaChamadas.SocketType(Tipo: TSocketMessageType): Boolean;
begin
  Result := Tipo in [
    TSocketMessageType.ChamadaRecebida,
    TSocketMessageType.ChamadaFinalizada,
    TSocketMessageType.UsuarioRecusou,
    TSocketMessageType.UsuarioEntrou,
    TSocketMessageType.UsuarioSaiu
  ];
end;

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

constructor TConversaChamadas.Create;
begin
  FChamadas := TDictionary<Integer, TConversaChamada>.Create;
end;

destructor TConversaChamadas.Destroy;
begin
  FinalizarTodas;
  FreeAndNil(FChamadas);
  inherited;
end;

function TConversaChamadas.ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;
var
  Chamada: TConversaChamada;
begin
  if not SocketType(Tipo) then
    Exit(False);

  if jo.GetValue<Integer>('chamada_id', 0) = 0 then
    Exit(False);

  Result := True;
  Chamada := GetChamada(jo.GetValue<Integer>('chamada_id'));

  if not Assigned(Chamada) then
  begin
    Chamada := TConversaChamada.Create(jo.GetValue<Integer>('chamada_id'));
    FChamadas.Add(Chamada.FID, Chamada);
  end;

  Chamada.ProcessarSocket(Tipo, jo);
end;

function TConversaChamadas.Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;
begin
  Result := TConversaChamada.Create(0);
  Result.IniciarChamada(AParticipantes);
  FChamadas.Add(Result.FID, Result);
end;

procedure TConversaChamadas.FinalizarTodas;
var
  Chamada: TConversaChamada;
begin
  for Chamada in FChamadas.Values do
  begin
    if not Assigned(Chamada) then
      Continue;

    try
      Chamada.Sair;
      Chamada.Free;
    except
    end;
  end;

  FChamadas.Clear;
end;

function TConversaChamadas.GetChamada(const AID: Integer): TConversaChamada;
begin
  if not FChamadas.TryGetValue(AID, Result) then
    Exit(nil);
end;

{ TConversaChamada }

constructor TConversaChamada.Create(const AID: Integer);
begin
  FID := AID;
  FStatus := TChamadaStatusLocal.Desconhecido;
end;

destructor TConversaChamada.Destroy;
begin
  if FStatus.Ativa then
    Sair;

  if Assigned(FBarraTitulo) then
    FreeAndNil(FBarraTitulo);
  if Assigned(FChamadaView) then
    FreeAndNil(FChamadaView);
  inherited;
end;

function TConversaChamada.ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;
begin
  Result := True;
  case Tipo of
    TSocketMessageType.ChamadaRecebida: OnChamadaRecebida;
    TSocketMessageType.ChamadaFinalizada: OnChamadaFinalizada;
    TSocketMessageType.UsuarioRecusou: AtualizarStatusUsuario(jo.GetValue<Integer>('usuario_id', 0), TChamadaStatusUsuario.Recusou);
    TSocketMessageType.UsuarioEntrou: AtualizarStatusUsuario(jo.GetValue<Integer>('usuario_id', 0), TChamadaStatusUsuario.Entrou);
    TSocketMessageType.UsuarioSaiu: AtualizarStatusUsuario(jo.GetValue<Integer>('usuario_id', 0), TChamadaStatusUsuario.Saiu);
  end;
end;

procedure TConversaChamada.Cancelar;
begin
  Sair;
end;

procedure TConversaChamada.Recusar;
begin
  Sair;
end;

procedure TConversaChamada.Entrar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Entrar(FID);
  AtualizarDados;
  Status := TChamadaStatusLocal.ChamadaEmAndamento;
end;

procedure TConversaChamada.Finalizar;
begin
  Sair(True);
end;

procedure TConversaChamada.Sair(const AFinalizar: Boolean = False);
begin
  case FStatus of
    TChamadaStatusLocal.IniciandoChamada: Conversa.Proxy.TAPIConversa.Chamada.Cancelar(FID);
    TChamadaStatusLocal.RecebentoChamada: Conversa.Proxy.TAPIConversa.Chamada.Recusar(FID);
    TChamadaStatusLocal.ChamadaEmAndamento:
    begin
      if AFinalizar then
        Conversa.Proxy.TAPIConversa.Chamada.Finalizar(FID)
      else
        Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
    end
  else
    Exit;
  end;
  ChamadaFinalizada;
end;

procedure TConversaChamada.OnChamadaFinalizada;
begin
  // Não fecha a tela, para exibir quem finalizou
  AtualizarDados;
  ExibirChamada;
  Status := TChamadaStatusLocal.ChamadaFinalizada;
end;

procedure TConversaChamada.OnChamadaRecebida;
begin
  Status := TChamadaStatusLocal.RecebentoChamada;
  AtualizarDados;
  ExibirChamada;
end;

procedure TConversaChamada.AtualizarDados;
begin
  FUsuarios := Conversa.Proxy.TAPIConversa.Chamada.Dados(FID).Dados.usuarios;
end;

function TConversaChamada.GetUsuarios: TArray<TChamadaDadosUsuario>;
begin
  Result := FUsuarios;
end;

procedure TConversaChamada.IniciarChamada(AParticipantes: TArrayUsuarios);
var
  jo: TJSONObject;
  ja: TJSONArray;
  P: Conversa.Tipos.TUsuario;
  U: Conversa.Tipos.TUsuario;
  Usu: TChamadaDadosUsuario;
begin
  for U in AParticipantes do
  begin
    Usu := Default(TChamadaDadosUsuario);
    Usu.usuario_id := U.ID;
    Usu.usuario_nome := U.Nome;
    if Usu.usuario_id = Dados.FDadosApp.Usuario.ID then
      Usu.status := TChamadaStatusUsuario.Entrou
    else
      Usu.status := TChamadaStatusUsuario.Pendente;
    FUsuarios := FUsuarios + [Usu];
  end;
  FStatus := TChamadaStatusLocal.IniciandoChamada;
  ExibirChamada;

  ja := TJSONArray.Create;
  jo := TJSONObject.Create;
  jo.AddPair('usuarios', ja);

  for P in AParticipantes do
    ja.Add(TJSONObject.Create.AddPair('id', P.ID));

  FID := Conversa.Proxy.TAPIConversa.Chamada.Iniciar(jo).Dados.id;
end;

procedure TConversaChamada.ChamadaFinalizada;
begin
  Status := TChamadaStatusLocal.ChamadaFinalizada;
  TConversaChamadas.Instance.FChamadas.Remove(FID);
  FreeAndNil(Self);
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
  if not Assigned(FChamadaView) then
  begin
    FChamadaView := TConversaChamadaView.Create(nil, Self);
    FChamadaView.AtualizarListaParticipante;
    FChamadaView.Show;
  end;

  FChamadaView.Status := Status;

  if not Assigned(FBarraTitulo) then
  begin
    FBarraTitulo := TConversaChamadaBarraTitulo.Create(TelaInicial.lytTitleBarClient, Self);
    FBarraTitulo.Exibir;
    FBarraTitulo.txtTempoLigacao.AutoSize := True;
    FBarraTitulo.txtTempoLigacao.AutoSize := False;
  end;

  FBarraTitulo.Status := FStatus;
end;

procedure TConversaChamada.NotificarChamada;
begin
  //
end;

procedure TConversaChamada.SetStatus(const Value: TChamadaStatusLocal);
begin
  FStatus := Value;

  if Assigned(FChamadaView) then
    FChamadaView.Status := FStatus;

  if Assigned(FBarraTitulo) then
    FBarraTitulo.Status := FStatus;
end;

procedure TConversaChamada.AtualizarStatusUsuario(const Usuario: Integer; Status: TChamadaStatusUsuario);
var
  I: Integer;
  Usr: TChamadaDadosUsuario;
  QtdAtivos: Integer;
begin
  for I := 0 to Pred(Length(FUsuarios)) do
  begin
    Usr := FUsuarios[I];
    if Usr.usuario_id <> Usuario then
      Continue;

    Usr.status := Status;
    FUsuarios[I] := Usr;
  end;

  QtdAtivos := -1;
  for I := 0 to Pred(Length(FUsuarios)) do
    if FUsuarios[I].status = TChamadaStatusUsuario.Entrou then
      Inc(QtdAtivos);

  if QtdAtivos = 0 then
    Sair
  else
  if FStatus = TChamadaStatusLocal.IniciandoChamada then
    Self.Status := TChamadaStatusLocal.ChamadaEmAndamento;
end;

end.
