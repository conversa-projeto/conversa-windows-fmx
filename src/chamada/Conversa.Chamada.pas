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
    FChamadas: TArray<TConversaChamada>;
  public
    class constructor Create;
    class destructor Destroy;
    class function Instance: TConversaChamadas;
    class function SocketType(Tipo: TSocketMessageType): Boolean;
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;

    destructor Destroy; override;

    function Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;
    function GetChamada(const AID: Integer): TConversaChamada;

    procedure FinalizarTodas;
  end;

  TConversaChamada = class
  private
    FID: Integer;
    FStatus: TStatusChamada;
    FChamadaView: TConversaChamadaView;
    FBarraTitulo: TConversaChamadaBarraTitulo;
    FUsuarios: TArray<TChamadaDadosUsuario>;
    procedure SetStatus(const Value: TStatusChamada);
  protected
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;

    procedure OnChamadaFinalizada;
    procedure OnUsuarioRecusou;
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
    constructor Create(const AID: Integer);
    destructor Destroy; override;
    procedure Cancelar;
    procedure Recusar;
    procedure Entrar;
    procedure Sair;
    procedure Finalizar;
    procedure AtualizarDados;
    procedure OnChamadaRecebida;
    function GetUsuarios: TArray<TChamadaDadosUsuario>;
  end;

implementation

uses
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

destructor TConversaChamadas.Destroy;
begin
  FinalizarTodas;
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
    FChamadas := FChamadas + [Chamada];
  end;

  Chamada.ProcessarSocket(Tipo, jo);
end;

function TConversaChamadas.Iniciar(AParticipantes: TArrayUsuarios): TConversaChamada;
begin
  Result := TConversaChamada.Create(0);
  FChamadas := FChamadas + [Result];
  Result.IniciarChamada(AParticipantes);
end;

procedure TConversaChamadas.FinalizarTodas;
begin
  //
end;

function TConversaChamadas.GetChamada(const AID: Integer): TConversaChamada;
var
  Chamada: TConversaChamada;
begin
  Result := nil;
  for Chamada in FChamadas do
    if Chamada.FID = AID then
      Exit(Chamada);
end;

{ TConversaChamada }

constructor TConversaChamada.Create(const AID: Integer);
begin
  FID := AID;
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

function TConversaChamada.ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;
begin
  Result := True;
  case Tipo of
    TSocketMessageType.ChamadaRecebida: OnChamadaRecebida;
    TSocketMessageType.ChamadaFinalizada: OnChamadaFinalizada;
    TSocketMessageType.UsuarioRecusou: OnUsuarioRecusou;
    TSocketMessageType.UsuarioEntrou: OnUsuarioEntrou;
    TSocketMessageType.UsuarioSaiu: OnUsuarioSaiu;
  end;
end;

procedure TConversaChamada.Cancelar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Cancelar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.Recusar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Recusar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.Entrar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Entrar(FID);
  Status := TStatusChamada.ChamadaEmAndamento;
end;

procedure TConversaChamada.Sair;
begin
  case FStatus of
    TStatusChamada.IniciandoChamada: Cancelar;
    TStatusChamada.RecebentoChamada: Recusar;
    TStatusChamada.ChamadaEmAndamento:
    begin
      Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
      Status := TStatusChamada.ChamadaFinalizada;
    end;
  end;
end;

procedure TConversaChamada.Finalizar;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Finalizar(FID);
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.OnChamadaFinalizada;
begin
  Status := TStatusChamada.ChamadaFinalizada;
end;

procedure TConversaChamada.OnChamadaRecebida;
begin
  Status := TStatusChamada.RecebentoChamada;
  AtualizarDados;
  ExibirChamada;
  FChamadaView.Status := TStatusChamada.RecebentoChamada;
  FBarraTitulo.Status(TStatusChamada.RecebentoChamada);
end;

procedure TConversaChamada.OnUsuarioRecusou;
begin
  if Length(FUsuarios) = 2 then
  begin
    Finalizar;
    Exit;
  end;
  Status := TStatusChamada.Recusada;
end;

procedure TConversaChamada.OnUsuarioEntrou;
begin
  ChamadaAtendida;
end;

procedure TConversaChamada.OnUsuarioSaiu;
begin
  //ChamadaFinalizada;
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
    FUsuarios := FUsuarios + [Usu];
  end;
  FStatus := TStatusChamada.IniciandoChamada;
  ExibirChamada;

  ja := TJSONArray.Create;
  jo := TJSONObject.Create;
  jo.AddPair('usuarios', ja);

  for P in AParticipantes do
    ja.Add(TJSONObject.Create.AddPair('id', P.ID));

  FID := Conversa.Proxy.TAPIConversa.Chamada.Iniciar(jo).Dados.id;
end;

procedure TConversaChamada.ChamadaAtendida;
begin
  Status := TStatusChamada.ChamadaEmAndamento;
end;

procedure TConversaChamada.ChamadaFinalizada;
begin
  Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
  Status := TStatusChamada.ChamadaFinalizada;
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
