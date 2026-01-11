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
  Conversa.Chamada.view,
  tcp,
  AudioTypes,
  AudioPlayer,
  AudioCapture,
  AudioMixer,
  System.Classes,
  Winapi.MMSystem,
  Winapi.Windows;

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
    FTipo: TChamadaTipo;
    FStatus: TChamadaStatus;
    FStatusLocal: TChamadaStatusLocal;
    FChamadaView: TConversaChamadaView;
    FBarraTitulo: TConversaChamadaBarraTitulo;
    FUsuarios: TArray<TChamadaDadosUsuario>;
    FIniciada: TDateTime;
    FFinalizada: TDateTime;
    FTCPAudio: TTCPClient;
    FClientStreams: TList<TClientAudioStream>;

    FCaptureThread: TAudioCaptureThread;
    FPlayerThread: TAudioPlayerThread;
    FMixerThread: TAudioMixerThread;
    FCaptureAudioBuffer: TAudioBuffer;
    FPlayerAudioBuffer: TAudioBuffer;
    FAudioThreadsStarted: Boolean;

    procedure SetStatusLocal(const Value: TChamadaStatusLocal);
    procedure AtualizarStatusUsuario(const Usuario: Integer; Status: TChamadaStatusUsuario);
    procedure OnChamadaFinalizada;
    procedure OnUsuarioRecusou(const Usuario: Integer);
    procedure OnUsuarioEntrou(const Usuario: Integer);
    procedure OnUsuarioSaiu(const Usuario: Integer);
    procedure FinalizarLocalmente;
    procedure ConectarTCPAudio;
    procedure TCPAudioError(const sError: String);
    procedure TCPAudioReceive(const Data: TBytes);
    procedure TCPAudioConnected;
    procedure TCPAudioDisconnected;
  protected
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;

    procedure IniciarCapturaAudio;
    procedure IniciarReproducaoAudio;

    procedure NotificarChamada;
    procedure ExibirChamada;

    procedure IniciarChamada(AParticipantes: TArrayUsuarios);

    property StatusLocal: TChamadaStatusLocal read FStatusLocal write SetStatusLocal;
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
    property Iniciada: TDateTime read FIniciada;
    function TempoDecorrido: string;
  end;

implementation

uses
  Conversa.Dados,
  Conversa.Proxy,
  Conversa.Tela.Inicial.view;

function IntToBytes(const Value: Integer): TBytes;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[0], SizeOf(Value));
end;

function BytesToInt(const Bytes: TBytes): Integer;
begin
  if Length(Bytes) <> 4 then
    raise Exception.Create('Invalid byte array size. Expected 4 bytes.');
  Move(Bytes[0], Result, SizeOf(Result));
end;


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
  FStatusLocal := TChamadaStatusLocal.Desconhecido;
  FTipo := TChamadaTipo.Simples;
  FIniciada := 0;
  FAudioThreadsStarted := False;
end;

destructor TConversaChamada.Destroy;
begin
  try
    if Assigned(FMixerThread) then
    begin
      FMixerThread.Finalizar;
      FMixerThread.WaitFor;
      FreeAndNil(FMixerThread);
    end;

    if Assigned(FCaptureThread) then
    begin
      FCaptureThread.Finalizar;
      FCaptureThread.WaitFor;
      FreeAndNil(FCaptureThread);
    end;

    if Assigned(FPlayerThread) then
    begin
      FPlayerThread.Finalizar;
      FPlayerThread.WaitFor;
      FreeAndNil(FPlayerThread);
    end;

    if Assigned(FCaptureAudioBuffer) then
      FreeAndNil(FCaptureAudioBuffer);

    if Assigned(FPlayerAudioBuffer) then
      FreeAndNil(FPlayerAudioBuffer);

    if Assigned(FTCPAudio) then
      FreeAndNil(FTCPAudio);

    if Assigned(FClientStreams) then
    begin
      for var Stream in FClientStreams do
      begin
        if Assigned(Stream.Buffer) then
          Stream.Buffer.Free;
        Stream.Free;
      end;
      FreeAndNil(FClientStreams);
    end;

    if Assigned(FBarraTitulo) then
      FreeAndNil(FBarraTitulo);

    if Assigned(FChamadaView) then
      FreeAndNil(FChamadaView);
  except
  end;

  inherited;
end;

function TConversaChamada.ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;
begin
  Result := True;
  case Tipo of
    TSocketMessageType.ChamadaRecebida: OnChamadaRecebida;
    TSocketMessageType.ChamadaFinalizada: OnChamadaFinalizada;
    TSocketMessageType.UsuarioRecusou: OnUsuarioRecusou(jo.GetValue<Integer>('usuario_id', 0));
    TSocketMessageType.UsuarioEntrou: OnUsuarioEntrou(jo.GetValue<Integer>('usuario_id', 0));
    TSocketMessageType.UsuarioSaiu: OnUsuarioSaiu(jo.GetValue<Integer>('usuario_id', 0));
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
  FIniciada := Now;
  AtualizarDados;
  StatusLocal := TChamadaStatusLocal.ChamadaEmAndamento;
  ConectarTCPAudio;
end;

procedure TConversaChamada.Finalizar;
begin
  Sair(True);
end;

procedure TConversaChamada.Sair(const AFinalizar: Boolean = False);
begin
  case FStatusLocal of
    TChamadaStatusLocal.IniciandoChamada: Conversa.Proxy.TAPIConversa.Chamada.Cancelar(FID);
    TChamadaStatusLocal.RecebentoChamada: Conversa.Proxy.TAPIConversa.Chamada.Recusar(FID);
    TChamadaStatusLocal.ChamadaEmAndamento:
    begin
      if AFinalizar then
        Conversa.Proxy.TAPIConversa.Chamada.Finalizar(FID)
      else
        Conversa.Proxy.TAPIConversa.Chamada.Sair(FID);
    end;
    TChamadaStatusLocal.ChamadaFinalizada: Exit;
  end;
  FinalizarLocalmente;
end;

procedure TConversaChamada.OnChamadaFinalizada;
begin
  AtualizarDados;
  StatusLocal := TChamadaStatusLocal.ChamadaFinalizada;
  FinalizarLocalmente;
  TConversaChamadas.Instance.FChamadas.Remove(FID);
end;

procedure TConversaChamada.OnChamadaRecebida;
begin
  StatusLocal := TChamadaStatusLocal.RecebentoChamada;
  AtualizarDados;
  ExibirChamada;
end;

procedure TConversaChamada.OnUsuarioRecusou(const Usuario: Integer);
begin
  AtualizarStatusUsuario(Usuario, TChamadaStatusUsuario.Recusou);

  if StatusLocal = TChamadaStatusLocal.RecebentoChamada then
    Exit;

  if (StatusLocal = TChamadaStatusLocal.IniciandoChamada) and (FTipo = TChamadaTipo.Simples) then
  begin
    StatusLocal := TChamadaStatusLocal.Recusada;
    FinalizarLocalmente;
    TConversaChamadas.Instance.FChamadas.Remove(FID);
    Exit;
  end;
end;

procedure TConversaChamada.OnUsuarioEntrou(const Usuario: Integer);
begin
  AtualizarStatusUsuario(Usuario, TChamadaStatusUsuario.Entrou);
  if StatusLocal = TChamadaStatusLocal.RecebentoChamada then
    Exit;

  StatusLocal := TChamadaStatusLocal.ChamadaEmAndamento;
  AtualizarDados;
end;

procedure TConversaChamada.OnUsuarioSaiu(const Usuario: Integer);
begin
  AtualizarStatusUsuario(Usuario, TChamadaStatusUsuario.Saiu);

  if StatusLocal = TChamadaStatusLocal.RecebentoChamada then
    Exit;

  if (StatusLocal = TChamadaStatusLocal.ChamadaEmAndamento) and (FTipo = TChamadaTipo.Simples) then
  begin
    StatusLocal := TChamadaStatusLocal.ChamadaFinalizada;
    FinalizarLocalmente;
    TConversaChamadas.Instance.FChamadas.Remove(FID);
    Exit;
  end;
end;

procedure TConversaChamada.AtualizarDados;
begin
  with Conversa.Proxy.TAPIConversa.Chamada.Dados(FID) do
  begin
    FTipo := Dados.tipo;
    FStatus := Dados.status;
    FIniciada := Dados.iniciada;
    FFinalizada := Dados.finalizada;
    FUsuarios := Dados.usuarios;
  end;

  if Assigned(FChamadaView) then
    FChamadaView.AtualizarListaParticipante;
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
  FStatusLocal := TChamadaStatusLocal.IniciandoChamada;
  ExibirChamada;

  ja := TJSONArray.Create;
  jo := TJSONObject.Create;
  jo.AddPair('usuarios', ja);

  for P in AParticipantes do
    ja.Add(TJSONObject.Create.AddPair('id', P.ID));

  with Conversa.Proxy.TAPIConversa.Chamada.Iniciar(jo).Dados do
  begin
    FID := id;
    FTipo := tipo;
    FStatus := status;
  end;

  ConectarTCPAudio;
end;

procedure TConversaChamada.FinalizarLocalmente;
begin
  StatusLocal := TChamadaStatusLocal.ChamadaFinalizada;
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
    FChamadaView.CentralizarNoDisplayDoMainForm;
  end;

  FChamadaView.Status := StatusLocal;

  if not Assigned(FBarraTitulo) then
  begin
    FBarraTitulo := TConversaChamadaBarraTitulo.Create(TelaInicial.lytTitleBarClient, Self);
    FBarraTitulo.Exibir;
    FBarraTitulo.txtTempoLigacao.AutoSize := True;
    FBarraTitulo.txtTempoLigacao.AutoSize := False;
  end;

  FBarraTitulo.Status := FStatusLocal;
end;

procedure TConversaChamada.NotificarChamada;
begin
  //
end;

procedure TConversaChamada.SetStatusLocal(const Value: TChamadaStatusLocal);
begin
  if FStatusLocal = Value then
    Exit;

  FStatusLocal := Value;
  case FStatusLocal of
    TChamadaStatusLocal.Desconhecido: ;
    TChamadaStatusLocal.IniciandoChamada: ;
    TChamadaStatusLocal.RecebentoChamada: ;
    TChamadaStatusLocal.ChamadaEmAndamento:
    begin
      FIniciada := Now;
    end;
    TChamadaStatusLocal.ChamadaFinalizada:
    begin
      if Assigned(FCaptureThread) then
        FCaptureThread.Finalizar;
      if Assigned(FPlayerThread) then
        FPlayerThread.Finalizar;
      if Assigned(FMixerThread) then
        FMixerThread.Finalizar;
    end;
    TChamadaStatusLocal.ChamadaPerdida: ;
    TChamadaStatusLocal.Recusada: ;
  end;

  if Assigned(FChamadaView) then
    FChamadaView.Status := FStatusLocal;

  if Assigned(FBarraTitulo) then
    FBarraTitulo.Status := FStatusLocal;
end;

procedure TConversaChamada.AtualizarStatusUsuario(const Usuario: Integer; Status: TChamadaStatusUsuario);
var
  I: Integer;
  Usr: TChamadaDadosUsuario;
begin
  for I := 0 to Pred(Length(FUsuarios)) do
  begin
    Usr := FUsuarios[I];
    if Usr.usuario_id <> Usuario then
      Continue;

    Usr.status := Status;
    FUsuarios[I] := Usr;
  end;

  if Assigned(FChamadaView) then
    FChamadaView.AtualizarListaParticipante;
end;

function TConversaChamada.TempoDecorrido: string;
var
  Diferenca: TDateTime;
  Horas, Minutos, Segundos, Milisegundos: Word;
begin
  // Claude Sonnet 4.5
  // Calcula a diferença entre as datas
  Diferenca := Now - FIniciada;

  // Extrai horas, minutos, segundos e milisegundos
  DecodeTime(Diferenca, Horas, Minutos, Segundos, Milisegundos);

  // Formata a string de acordo com a regra
  if Horas > 0 then
    Result := Format('%2.2d:%2.2d:%2.2d.%3.3d', [Horas, Minutos, Segundos, Milisegundos])
  else
    Result := Format('%2.2d:%2.2d.%3.3d', [Minutos, Segundos, Milisegundos]);
end;

procedure TConversaChamada.ConectarTCPAudio;
var
  RegistrationData: TBytes;
begin
  FClientStreams := TList<TClientAudioStream>.Create;
  FCaptureAudioBuffer := TAudioBuffer.Create(1024 * 1024);
  FPlayerAudioBuffer := TAudioBuffer.Create(1024 * 1024);

  FMixerThread := TAudioMixerThread.Create(
    FClientStreams,
    FPlayerAudioBuffer,
    function: Boolean
    begin
      Result := FStatusLocal = TChamadaStatusLocal.ChamadaEmAndamento;
    end
  );
  FMixerThread.Start;

  FCaptureThread := TAudioCaptureThread.Create(FCaptureAudioBuffer);
  FPlayerThread := TAudioPlayerThread.Create(FPlayerAudioBuffer);

  FCaptureThread.OnNewAudioData :=
    procedure(Data: TBytes)
    begin
      if (FStatusLocal = TChamadaStatusLocal.ChamadaEmAndamento) then
        if Assigned(FTCPAudio) and (FTCPAudio.State = TTCPClientState.Connected) then
          FTCPAudio.Send([1] + IntToBytes(FID) + Data);
    end;

  RegistrationData := [0] + IntToBytes(Dados.FDadosApp.Usuario.ID);

  FTCPAudio := TTCPClient.Create('localhost', 9090);
  FTCPAudio.SetRegistrationData(RegistrationData);
  FTCPAudio.OnClientReceive := TCPAudioReceive;
  FTCPAudio.OnError := TCPAudioError;
  FTCPAudio.OnConnected := TCPAudioConnected;
  FTCPAudio.OnDisconnected := TCPAudioDisconnected;
end;

procedure TConversaChamada.TCPAudioConnected;
begin
  if FAudioThreadsStarted then
    Exit;

  FAudioThreadsStarted := True;
  if Assigned(FCaptureThread) then
    FCaptureThread.Start;
  if Assigned(FPlayerThread) then
    FPlayerThread.Start;
end;

procedure TConversaChamada.TCPAudioDisconnected;
begin
  // Reconexão é automática pelo TTCPClient
end;

procedure TConversaChamada.TCPAudioError(const sError: String);
begin
  {TODO -oDaniel -cChamada: Melhorar exibição de erros}
  raise Exception.Create(sError);
end;

procedure TConversaChamada.TCPAudioReceive(const Data: TBytes);
var
  iRemetente: Integer;
  ClientStream: TClientAudioStream;
  AudioData: TBytes;
begin
  try
    if FStatusLocal <> TChamadaStatusLocal.ChamadaEmAndamento then
      Exit;

    // Valida tamanho mínimo: 4 (remetente) + 4 (chamada) + 1 (áudio)
    if Length(Data) < 9 then
      Exit;

    iRemetente := BytesToInt(Copy(Data, 0, 4));
    AudioData := Copy(Data, 8);

    // Procura ou cria buffer para este cliente
    ClientStream := nil;
    for var Stream in FClientStreams do
    begin
      if Stream.ClientID = iRemetente then
      begin
        ClientStream := Stream;
        Break;
      end;
    end;

    if ClientStream = nil then
    begin
      ClientStream := TClientAudioStream.Create;
      ClientStream.ClientID := iRemetente;
      ClientStream.Buffer := TAudioBuffer.Create(512 * 1024);
      FClientStreams.Add(ClientStream);
    end;

    ClientStream.Buffer.Write(AudioData);
  except
  end;
end;

end.
