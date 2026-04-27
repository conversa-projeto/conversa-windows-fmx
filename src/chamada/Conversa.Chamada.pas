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
  Conversa.Chamada.Waveform,
  Conversa.Chamada.WebRTC,
  AudioTypes,
  AudioMixer,
  System.Classes,
  FMX.Objects,
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
    FClientStreams: TList<TClientAudioStream>;
    FWaveformDataGeral: TWaveformData;
    FMuted: Boolean;
    FWebRTCAtivo: Boolean;

    procedure SetStatusLocal(const Value: TChamadaStatusLocal);
    procedure AtualizarStatusUsuario(const Usuario: Integer; Status: TChamadaStatusUsuario);
    procedure OnChamadaFinalizada;
    procedure OnUsuarioRecusou(const Usuario: Integer);
    procedure OnUsuarioEntrou(const Usuario: Integer);
    procedure OnUsuarioSaiu(const Usuario: Integer);
    procedure FinalizarLocalmente;
    procedure IniciarWebRTC;
    procedure AssinarPeersExistentes;
  protected
    function ProcessarSocket(Tipo: TSocketMessageType; jo: TJSONObject): Boolean;

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
    function GetClientStreams: TList<TClientAudioStream>;
    property Iniciada: TDateTime read FIniciada;
    property Muted: Boolean read FMuted;
    property WaveformDataGeral: TWaveformData read FWaveformDataGeral;
    procedure ToggleMute;
    function TempoDecorrido: string;
  end;

implementation

uses
  Conversa.Dados,
  Conversa.Proxy,
  Conversa.Tela.Inicial.view,
  Conversa.Configuracoes,
  Conversa.Notificacao;

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
  FMuted := False;
  FWebRTCAtivo := False;
end;

destructor TConversaChamada.Destroy;
begin
  try
    if FWebRTCAtivo then
    begin
      TConversaWebRTC.Instance.Desligar;
      FWebRTCAtivo := False;
    end;

    if Assigned(FWaveformDataGeral) then
      FreeAndNil(FWaveformDataGeral);

    if Assigned(FClientStreams) then
    begin
      for var Stream in FClientStreams do
      begin
        if Assigned(Stream.Buffer) then
          Stream.Buffer.Free;
        if Assigned(Stream.WaveformData) then
          Stream.WaveformData.Free;
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
  IniciarWebRTC;
  AssinarPeersExistentes;
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
  NotificarChamada;
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
var
  Img: FMX.Objects.TImage;
  PeerId: Integer;
begin
  AtualizarStatusUsuario(Usuario, TChamadaStatusUsuario.Entrou);
  if StatusLocal = TChamadaStatusLocal.RecebentoChamada then
    Exit;

  StatusLocal := TChamadaStatusLocal.ChamadaEmAndamento;
  AtualizarDados;

  if not FWebRTCAtivo then
    Exit;

  if Usuario = Dados.FDadosApp.Usuario.ID then
    Exit;

  PeerId := Usuario;
  Img := nil;
  if Assigned(FChamadaView) then
    Img := FChamadaView.GetVideoTarget(PeerId);

  TThread.CreateAnonymousThread(
    procedure
    begin
      TConversaWebRTC.Instance.AssinarDePeer(PeerId, Img);
    end
  ).Start;
end;

procedure TConversaChamada.OnUsuarioSaiu(const Usuario: Integer);
begin
  AtualizarStatusUsuario(Usuario, TChamadaStatusUsuario.Saiu);

  if FWebRTCAtivo and (Usuario <> Dados.FDadosApp.Usuario.ID) then
    TConversaWebRTC.Instance.DesconectarPeer(Usuario);

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

function TConversaChamada.GetClientStreams: TList<TClientAudioStream>;
begin
  Result := FClientStreams;
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

  IniciarWebRTC;
end;

procedure TConversaChamada.FinalizarLocalmente;
begin
  TNotificacaoManager.Fechar(TTipoNotificacao.Chamada, FID);
  if FWebRTCAtivo then
  begin
    TConversaWebRTC.Instance.Desligar;
    FWebRTCAtivo := False;
  end;
  StatusLocal := TChamadaStatusLocal.ChamadaFinalizada;
  TConversaChamadas.Instance.FChamadas.Remove(FID);
  FreeAndNil(Self);
end;

procedure TConversaChamada.IniciarWebRTC;
var
  ChamadaId, MeuId: Integer;
begin
  if FWebRTCAtivo then
    Exit;

  TConversaWebRTC.Instance.MediaMtxBase := Configuracoes.MediaMtxBase;
  FWebRTCAtivo := True;

  ChamadaId := FID;
  MeuId := Dados.FDadosApp.Usuario.ID;

  // WhipConnect bloqueia durante negociacao ICE/DTLS — rodar em thread.
  TThread.CreateAnonymousThread(
    procedure
    begin
      TConversaWebRTC.Instance.PublicarLocalNaSala(ChamadaId, MeuId, True, True);
    end
  ).Start;
end;

procedure TConversaChamada.AssinarPeersExistentes;
var
  Usuario: TChamadaDadosUsuario;
  MeuId, PeerId: Integer;
  Img: FMX.Objects.TImage;
begin
  if not FWebRTCAtivo then
    Exit;

  MeuId := Dados.FDadosApp.Usuario.ID;
  for Usuario in FUsuarios do
  begin
    if Usuario.usuario_id = MeuId then
      Continue;
    if Usuario.status <> TChamadaStatusUsuario.Entrou then
      Continue;

    PeerId := Usuario.usuario_id;
    Img := nil;
    if Assigned(FChamadaView) then
      Img := FChamadaView.GetVideoTarget(PeerId);

    TThread.CreateAnonymousThread(
      procedure
      begin
        TConversaWebRTC.Instance.AssinarDePeer(PeerId, Img);
      end
    ).Start;
  end;
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
var
  DadosChamada: TNotificacaoChamadaDados;
  Usuario: TChamadaDadosUsuario;
begin

  for Usuario in FUsuarios do
  begin
    if Usuario.usuario_id = Dados.FDadosApp.Usuario.ID then
      Continue;

    DadosChamada.Nome := Usuario.usuario_nome;
    Break;
  end;

  if Length(FUsuarios) = 2 then
    DadosChamada.TipoChamada := 'Chamada de Voz'
  else
    DadosChamada.TipoChamada := 'Chamada de Voz em Grupo';

//  DadosChamada.Descricao := 'Teste - 2';
  DadosChamada.OnAtender :=
    procedure(AID: Integer)
    begin
      TConversaChamadas.FChamadas.Items[AID].Entrar;
    end;
  DadosChamada.OnRecusar :=
    procedure(AID: Integer)
    begin
      TConversaChamadas.FChamadas.Items[AID].Recusar;
    end;

  TNotificacaoManager.Apresentar(
    TNotificacao.New
      .ChamadaId(FID)
      .Tipo(TTipoNotificacao.Chamada)
      .ChamadaDados(DadosChamada)
  );
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
      TNotificacaoManager.Fechar(TTipoNotificacao.Chamada, FID);
      FIniciada := Now;
    end;
    TChamadaStatusLocal.ChamadaFinalizada:
    begin
      if FWebRTCAtivo then
      begin
        TConversaWebRTC.Instance.Desligar;
        FWebRTCAtivo := False;
      end;
    end;
    TChamadaStatusLocal.ChamadaPerdida: ;
    TChamadaStatusLocal.Recusada:
    begin
      TNotificacaoManager.Fechar(TTipoNotificacao.Chamada, FID);
    end;
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

procedure TConversaChamada.ToggleMute;
begin
  FMuted := not FMuted;
  if FWebRTCAtivo then
    TConversaWebRTC.Instance.AlternarMicrofone(FMuted);
end;

end.
