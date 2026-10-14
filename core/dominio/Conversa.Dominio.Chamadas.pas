unit Conversa.Dominio.Chamadas;

{ Modelos de chamada (doc 01 §9).

  - "tipo" da chamada é ambíguo no servidor (1/2 = áudio/vídeo para o cliente, simples/grupo para a regra de
    status): fica o número cru, e EhVideo é a leitura do cliente (como o web).
  - Status 5 (desconectada/desconectou) nunca é gravado pelo servidor atual, mas é aceito.
  - Duração nula = -1. }

interface

type
  {$SCOPEDENUMS ON}
  TStatusChamada = (Desconhecido, Pendente, Recusada, EmAndamento, Encerrada, Desconectada, Cancelada);
  TStatusParticipante = (Desconhecido, Pendente, Recusou, Entrou, Saiu, Desconectou);
  {$SCOPEDENUMS OFF}

  TCodigosChamada = record
    class function Status(ACodigo: Int64): TStatusChamada; static;
    class function StatusParticipante(ACodigo: Int64): TStatusParticipante; static;
  end;

  /// <summary>Participante em "dados da chamada" (§9.3): datas vindas dos eventos.</summary>
  TParticipanteChamada = record
    UsuarioId: Int64;
    Nome: string;
    Status: TStatusParticipante;
    AdicionadoPor: Int64;
    AdicionadoPorNome: string;
    AdicionadoEm: TDateTime;
    EntrouEm: TDateTime;
    SaiuEm: TDateTime;
    RecusouEm: TDateTime;
  end;

  /// <summary>PUT /chamada/iniciar e GET /chamada/dados (§9.3). Não traz conversa_id (só o do chat).</summary>
  TDadosChamada = record
    Id: Int64;
    Tipo: Integer;
    Status: TStatusChamada;
    Iniciada: TDateTime;
    Finalizada: TDateTime;
    CriadoEm: TDateTime;
    CriadoPor: Int64;
    ConversaChatId: Int64;
    Participantes: TArray<TParticipanteChamada>;
    function EhVideo: Boolean;
    function Participante(AUsuarioId: Int64; out AParticipante: TParticipanteChamada): Boolean;
    /// <summary>Quantos estão com status "Entrou" (3), opcionalmente sem contar um usuário.</summary>
    function QuantosEntraram(AExcetoUsuarioId: Int64 = 0): Integer;
  end;

  /// <summary>Item de GET /chamadas/pendentes (§9.6): sem a lista de usuários; conversa_id nulo vira 0.</summary>
  TChamadaPendente = record
    Id: Int64;
    Tipo: Integer;
    Status: TStatusChamada;
    Iniciada: TDateTime;
    Finalizada: TDateTime;
    ConversaId: Int64;
    CriadoEm: TDateTime;
    CriadoPor: Int64;
    function EhVideo: Boolean;
  end;

  /// <summary>Participante no histórico (§9.7) e no resumo da chamada (tipo 6, §9.8).</summary>
  TParticipanteResumo = record
    UsuarioId: Int64;
    Nome: string;
    Status: TStatusParticipante;
    /// <summary>Segundos; -1 = sem duração (o criador nunca tem).</summary>
    Duracao: Integer;
    AvatarUrl: string;
  end;

  /// <summary>Item de GET /chamadas (só finalizadas).</summary>
  TChamadaHistorico = record
    Id: Int64;
    Tipo: Integer;
    Status: TStatusChamada;
    CriadoEm: TDateTime;
    CriadoPor: Int64;
    ConversaId: Int64;
    Iniciada: TDateTime;
    Finalizada: TDateTime;
    /// <summary>Segundos; -1 = sem duração.</summary>
    Duracao: Integer;
    Participantes: TArray<TParticipanteResumo>;
    function EhVideo: Boolean;
  end;

  /// <summary>Conteúdo tipo 6: JSON do resumo, com datas sem fuso (UTC). Valido = False se o JSON não abriu.</summary>
  TResumoChamada = record
    Valido: Boolean;
    ChamadaId: Int64;
    Tipo: Integer;
    Status: TStatusChamada;
    Iniciada: TDateTime;
    Finalizada: TDateTime;
    Duracao: Integer;
    Participantes: TArray<TParticipanteResumo>;
    function EhVideo: Boolean;
    function EmGrupo: Boolean;
  end;

  /// <summary>Um servidor de GET /ice (camelCase: urls, username, credential). "urls" é texto único hoje.</summary>
  TServidorIce = record
    Urls: TArray<string>;
    Usuario: string;
    Credencial: string;
  end;

  TConfiguracaoIce = record
    Servidores: TArray<TServidorIce>;
    /// <summary>iceTransportPolicy = "relay" (na prática a mídia só passa pelo TURN).</summary>
    SoRelay: Boolean;
  end;

implementation

{ TCodigosChamada }

class function TCodigosChamada.Status(ACodigo: Int64): TStatusChamada;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TStatusChamada))) then
    Result := TStatusChamada(ACodigo)
  else
    Result := TStatusChamada.Desconhecido;
end;

class function TCodigosChamada.StatusParticipante(ACodigo: Int64): TStatusParticipante;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TStatusParticipante))) then
    Result := TStatusParticipante(ACodigo)
  else
    Result := TStatusParticipante.Desconhecido;
end;

{ TDadosChamada }

function TDadosChamada.EhVideo: Boolean;
begin
  Result := Tipo = 2;
end;

function TDadosChamada.Participante(AUsuarioId: Int64; out AParticipante: TParticipanteChamada): Boolean;
var
  P: TParticipanteChamada;
begin
  for P in Participantes do
    if P.UsuarioId = AUsuarioId then
    begin
      AParticipante := P;
      Exit(True);
    end;
  AParticipante := Default(TParticipanteChamada);
  Result := False;
end;

function TDadosChamada.QuantosEntraram(AExcetoUsuarioId: Int64): Integer;
var
  P: TParticipanteChamada;
begin
  Result := 0;
  for P in Participantes do
    if (P.Status = TStatusParticipante.Entrou) and (P.UsuarioId <> AExcetoUsuarioId) then
      Inc(Result);
end;

{ TChamadaPendente }

function TChamadaPendente.EhVideo: Boolean;
begin
  Result := Tipo = 2;
end;

{ TChamadaHistorico }

function TChamadaHistorico.EhVideo: Boolean;
begin
  Result := Tipo = 2;
end;

{ TResumoChamada }

function TResumoChamada.EhVideo: Boolean;
begin
  Result := Tipo = 2;
end;

function TResumoChamada.EmGrupo: Boolean;
begin
  Result := Length(Participantes) > 2;
end;

end.
