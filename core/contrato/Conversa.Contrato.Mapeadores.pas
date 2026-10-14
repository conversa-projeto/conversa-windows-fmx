unit Conversa.Contrato.Mapeadores;

{ JSON do servidor -> modelos de domínio (FC-108; doc 01). Toda leitura é tolerante (TLeitorJson): campo
  ausente ou null vira o padrão. As funções que recebem texto abrem e liberam o próprio JSON e lançam
  EContratoInvalido se o texto não for do formato esperado (objeto ou lista). ResumoChamada nunca lança. }

interface

uses
  System.SysUtils,
  System.JSON,
  Conversa.Contrato.Json,
  Conversa.Dominio.Modelos,
  Conversa.Dominio.Chamadas,
  Conversa.Dominio.Anexos,
  Conversa.Dominio.Enquetes,
  Conversa.Dominio.Sistema;

type
  TMapeador = record
  private
    class function ListaDeConteudos(ALista: TJSONArray): TArray<TConteudo>; static;
    class function Reacao(AObj: TJSONObject): TReacao; static;
    class function Referencias(AObj: TJSONObject): TArray<TMensagemResumida>; static;
    class function ParticipanteChamada(AObj: TJSONObject): TParticipanteChamada; static;
    class function ParticipanteResumo(AObj: TJSONObject): TParticipanteResumo; static;
    class function ListaDeParticipantesResumo(ALista: TJSONArray): TArray<TParticipanteResumo>; static;
    class function DadosChamadaDe(AObj: TJSONObject): TDadosChamada; static;
    class function EnqueteDe(AObj: TJSONObject): TEnquete; static;
  public
    // sessão e usuários
    class function UsuarioLogado(const AJson: string): TUsuarioLogado; static;
    class function Dispositivo(AObj: TJSONObject): TDispositivo; static;
    class function Contatos(const AJson: string): TArray<TContato>; static;
    class function Membros(const AJson: string): TArray<TMembro>; static;
    class function IdsOnline(const AJson: string): TArray<Int64>; static;
    // conversas
    class function ConversaDe(AObj: TJSONObject): TConversa; static;
    class function Conversas(const AJson: string): TArray<TConversa>; static;
    // mensagens
    class function Conteudo(AObj: TJSONObject): TConteudo; static;
    class function Mensagem(AObj: TJSONObject): TMensagem; static;
    class function Mensagens(const AJson: string): TArray<TMensagem>; static;
    class function StatusMensagens(const AJson: string): TArray<TStatusMensagem>; static;
    class function StatusDetalhe(const AJson: string): TArray<TStatusDestinatario>; static;
    class function NovasMensagens(const AJson: string): TArray<TNovaMensagem>; static;
    // atividades
    class function Atividades(const AJson: string): TArray<TAtividade>; static;
    class function QuantidadeDeAtividades(const AJson: string): Integer; static;
    // anexos
    class function AnexoRegistrado(const AJson: string): TAnexoRegistrado; static;
    class function AnexoExistente(const AJson: string): TAnexoExistente; static;
    class function UrlDoAnexo(const AJson: string): string; static;
    class function Galeria(const AJson: string): TArray<TAnexoGaleria>; static;
    class function Transcricao(const AJson: string): TTranscricao; static;
    // chamadas
    class function DadosChamada(const AJson: string): TDadosChamada; static;
    class function ChamadasPendentes(const AJson: string): TArray<TChamadaPendente>; static;
    class function HistoricoDeChamadas(const AJson: string): TArray<TChamadaHistorico>; static;
    /// <summary>Conteúdo tipo 6. Nunca lança: JSON inválido -> Valido = False.</summary>
    class function ResumoChamada(const AConteudo: string): TResumoChamada; static;
    class function ConfiguracaoIce(const AJson: string): TConfiguracaoIce; static;
    // enquetes
    class function Enquete(const AJson: string): TEnquete; static;
    // sistema
    class function MinhasPermissoes(const AJson: string): TArray<string>; static;
    class function PainelPermissoes(const AJson: string): TPainelPermissoes; static;
    class function Parametros(const AJson: string): TParametros; static;
    class function RamalSip(const AJson: string): TRamalSip; static;
  end;

const
  /// <summary>Limite de níveis lidos em mensagem_referencia (o servidor manda até 5).</summary>
  MAXIMO_NIVEIS_REFERENCIA = 10;

implementation

{ sessão e usuários }

class function TMapeador.UsuarioLogado(const AJson: string): TUsuarioLogado;
var
  O: TJSONObject;
  L: TLeitorJson;
  D: TJSONObject;
begin
  Result := Default(TUsuarioLogado);
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.Id := L.Inteiro('id');
    Result.Nome := L.Texto('nome');
    Result.Email := L.Texto('email');
    Result.Telefone := L.Texto('telefone');
    Result.AvatarIdentificador := L.Texto('avatar_identificador');
    Result.Token := L.Texto('token');
    D := L.Objeto('dispositivo');
    if Assigned(D) then
      Result.DispositivoId := TLeitorJson.Create(D).Inteiro('id');
  finally
    O.Free;
  end;
end;

class function TMapeador.Dispositivo(AObj: TJSONObject): TDispositivo;
var
  L: TLeitorJson;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  Result.Nome := L.Texto('nome');
  Result.Modelo := L.Texto('modelo');
  Result.VersaoSo := L.Texto('versao_so');
  Result.Plataforma := L.Texto('plataforma');
  Result.Ativo := L.Booleano('ativo', True);
end;

class function TMapeador.Contatos(const AJson: string): TArray<TContato>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)].Id := L.Inteiro('id');
        Result[High(Result)].Nome := L.Texto('nome');
        Result[High(Result)].Login := L.Texto('login');
        Result[High(Result)].Email := L.Texto('email');
        Result[High(Result)].Telefone := L.Texto('telefone');
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.Membros(const AJson: string): TArray<TMembro>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)].VinculoId := L.Inteiro('id');
        Result[High(Result)].UsuarioId := L.Inteiro('usuario_id');
        Result[High(Result)].Nome := L.Texto('nome');
        Result[High(Result)].AvatarUrl := L.Texto('avatar_url');
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.IdsOnline(const AJson: string): TArray<Int64>;
var
  A: TJSONArray;
  I: Integer;
  X: Int64;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if TJson.ComoInteiro(A.Items[I], X) then
        Result := Result + [X];
  finally
    A.Free;
  end;
end;

{ conversas }

class function TMapeador.ConversaDe(AObj: TJSONObject): TConversa;
var
  L: TLeitorJson;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  Result.Descricao := L.Texto('descricao');
  Result.TipoBruto := Integer(L.Inteiro('tipo'));
  Result.Tipo := TCodigos.TipoConversa(Result.TipoBruto);
  Result.Inserida := L.DataUtc('inserida');
  Result.Nome := L.Texto('nome');
  Result.DestinatarioId := L.Inteiro('destinatario_id');
  Result.AvatarUrl := L.Texto('avatar_url');
  Result.UltimaMensagemId := L.Inteiro('mensagem_id');
  Result.UltimaMensagemEm := L.DataUtc('ultima_mensagem');
  Result.UltimaMensagemTexto := L.Texto('ultima_mensagem_texto');
  Result.MensagensSemVisualizar := Integer(L.Inteiro('mensagens_sem_visualizar'));
  Result.FixadaOrdem := Integer(L.Inteiro('fixada_ordem'));
  Result.ArquivadaEm := L.DataUtc('arquivada_em');
end;

class function TMapeador.Conversas(const AJson: string): TArray<TConversa>;
var
  A: TJSONArray;
  I: Integer;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
        Result := Result + [ConversaDe(TJSONObject(A.Items[I]))];
  finally
    A.Free;
  end;
end;

{ mensagens }

class function TMapeador.Conteudo(AObj: TJSONObject): TConteudo;
var
  L: TLeitorJson;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  Result.Ordem := Integer(L.Inteiro('ordem'));
  Result.TipoBruto := Integer(L.Inteiro('tipo'));
  Result.Tipo := TCodigos.TipoConteudo(Result.TipoBruto);
  Result.Conteudo := L.Texto('conteudo');
  Result.Nome := L.Texto('nome');
  Result.Extensao := L.Texto('extensao');
  Result.TranscricaoStatus := TCodigos.StatusTranscricao(L.Inteiro('transcricao_status'));
  Result.Transcricao := L.Texto('transcricao');
end;

class function TMapeador.ListaDeConteudos(ALista: TJSONArray): TArray<TConteudo>;
var
  I: Integer;
begin
  SetLength(Result, 0);
  if not Assigned(ALista) then
    Exit;
  for I := 0 to ALista.Count - 1 do
    if ALista.Items[I] is TJSONObject then
      Result := Result + [Conteudo(TJSONObject(ALista.Items[I]))];
end;

class function TMapeador.Reacao(AObj: TJSONObject): TReacao;
var
  L, LU: TLeitorJson;
  LUsuarios: TJSONArray;
  I: Integer;
  U: TUsuarioReacao;
begin
  L := TLeitorJson.Create(AObj);
  Result.Emoji := L.Texto('emoji');
  Result.Quantidade := Integer(L.Inteiro('quantidade'));
  Result.Reagiu := L.Booleano('reagiu');
  SetLength(Result.Usuarios, 0);
  LUsuarios := L.Lista('usuarios');
  if Assigned(LUsuarios) then
    for I := 0 to LUsuarios.Count - 1 do
      if LUsuarios.Items[I] is TJSONObject then
      begin
        LU := TLeitorJson.Create(TJSONObject(LUsuarios.Items[I]));
        U.UsuarioId := LU.Inteiro('usuario_id');
        U.Nome := LU.Texto('nome');
        U.ReagidoEm := LU.DataUtc('reagido_em');
        U.AvatarUrl := LU.Texto('avatar_url');
        Result.Usuarios := Result.Usuarios + [U];
      end;
end;

class function TMapeador.Referencias(AObj: TJSONObject): TArray<TMensagemResumida>;
var
  LRef: TJSONObject;
  LMsg: TJSONObject;
  LR, LM: TLeitorJson;
  N: TMensagemResumida;
  LNivel: Integer;
begin
  SetLength(Result, 0);
  LRef := TLeitorJson.Create(AObj).Objeto('mensagem_referencia');
  LNivel := 0;
  while Assigned(LRef) and (LNivel < MAXIMO_NIVEIS_REFERENCIA) do
  begin
    LR := TLeitorJson.Create(LRef);
    N := Default(TMensagemResumida);
    N.TipoReferencia := TCodigos.TipoReferencia(LR.Inteiro('tipo'));
    LMsg := LR.Objeto('mensagem');
    if Assigned(LMsg) then
    begin
      LM := TLeitorJson.Create(LMsg);
      N.Existe := True;
      N.Id := LM.Inteiro('id');
      N.ConversaId := LM.Inteiro('conversa_id');
      N.Remetente := LM.Texto('remetente');
      N.Inserida := LM.DataUtc('inserida');
      N.ExcluidaEm := LM.DataUtc('excluida_em');
      N.Conteudos := ListaDeConteudos(LM.Lista('conteudos'));
      LRef := LM.Objeto('mensagem_referencia');
    end
    else
      LRef := nil;
    Result := Result + [N];
    Inc(LNivel);
  end;
end;

class function TMapeador.Mensagem(AObj: TJSONObject): TMensagem;
var
  L: TLeitorJson;
  LReacoes: TJSONArray;
  I: Integer;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  // GET /mensagens usa remetente_id; a resposta de PUT /mensagem usa usuario_id (pegadinha 4)
  if L.Tem('remetente_id') then
    Result.RemetenteId := L.Inteiro('remetente_id')
  else
    Result.RemetenteId := L.Inteiro('usuario_id');
  Result.Remetente := L.Texto('remetente');
  Result.ConversaId := L.Inteiro('conversa_id');
  Result.Inserida := L.DataUtc('inserida');
  Result.VisivelEm := L.DataUtc('visivel_em');
  Result.ExcluidaEm := L.DataUtc('excluida_em');
  Result.Recebida := L.Booleano('recebida');
  Result.Visualizada := L.Booleano('visualizada');
  Result.Reproduzida := L.Booleano('reproduzida');
  Result.Conteudos := ListaDeConteudos(L.Lista('conteudos'));
  Result.Referencias := Referencias(AObj);
  SetLength(Result.Reacoes, 0);
  LReacoes := L.Lista('reacoes');
  if Assigned(LReacoes) then
    for I := 0 to LReacoes.Count - 1 do
      if LReacoes.Items[I] is TJSONObject then
        Result.Reacoes := Result.Reacoes + [Reacao(TJSONObject(LReacoes.Items[I]))];
end;

class function TMapeador.Mensagens(const AJson: string): TArray<TMensagem>;
var
  A: TJSONArray;
  I: Integer;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
        Result := Result + [Mensagem(TJSONObject(A.Items[I]))];
  finally
    A.Free;
  end;
end;

class function TMapeador.StatusMensagens(const AJson: string): TArray<TStatusMensagem>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  S: TStatusMensagem;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        S.ConversaId := L.Inteiro('conversa_id');
        S.MensagemId := L.Inteiro('mensagem_id');
        S.Recebida := L.Booleano('recebida');
        S.Visualizada := L.Booleano('visualizada');
        S.Reproduzida := L.Booleano('reproduzida');
        S.ExcluidaEm := L.DataUtc('excluida_em');
        Result := Result + [S];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.StatusDetalhe(const AJson: string): TArray<TStatusDestinatario>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  S: TStatusDestinatario;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        S.UsuarioId := L.Inteiro('usuario_id');
        S.Nome := L.Texto('nome');
        S.Recebida := L.DataUtc('recebida');
        S.Visualizada := L.DataUtc('visualizada');
        S.Reproduzida := L.DataUtc('reproduzida');
        Result := Result + [S];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.NovasMensagens(const AJson: string): TArray<TNovaMensagem>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  N: TNovaMensagem;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        N.ConversaId := L.Inteiro('conversa_id');
        N.MensagemId := L.Inteiro('mensagem_id');
        N.Ate := L.DataUtc('ate');
        Result := Result + [N];
      end;
  finally
    A.Free;
  end;
end;

{ atividades }

class function TMapeador.Atividades(const AJson: string): TArray<TAtividade>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  X: TAtividade;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        X.Id := L.Inteiro('id');
        X.TipoBruto := Integer(L.Inteiro('tipo'));
        X.Tipo := TCodigos.TipoAtividade(X.TipoBruto);
        X.CriadoEm := L.DataUtc('criado_em');
        X.Nova := L.Booleano('nova');
        X.AutorId := L.Inteiro('autor_id');
        X.AutorNome := L.Texto('autor_nome');
        X.AutorAvatarUrl := L.Texto('autor_avatar_url');
        X.ConversaId := L.Inteiro('conversa_id');
        X.ConversaTipo := TCodigos.TipoConversa(L.Inteiro('conversa_tipo'));
        X.ConversaDescricao := L.Texto('conversa_descricao');
        X.MensagemId := L.Inteiro('mensagem_id');
        X.ConteudoTipo := TCodigos.TipoConteudo(L.Inteiro('conteudo_tipo'));
        X.Texto := L.Texto('texto');
        X.ChamadaId := L.Inteiro('chamada_id');
        X.ChamadaTipo := Integer(L.Inteiro('chamada_tipo'));
        X.Emoji := L.Texto('emoji');
        Result := Result + [X];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.QuantidadeDeAtividades(const AJson: string): Integer;
var
  O: TJSONObject;
begin
  O := TJson.LerObjeto(AJson);
  try
    Result := Integer(TLeitorJson.Create(O).Inteiro('quantidade'));
  finally
    O.Free;
  end;
end;

{ anexos }

class function TMapeador.AnexoRegistrado(const AJson: string): TAnexoRegistrado;
var
  O: TJSONObject;
  L: TLeitorJson;
begin
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.Existe := L.Booleano('existe');
    Result.Id := L.Inteiro('id'); // número no anexo novo, texto no existente (pegadinha 6)
    Result.Url := L.Texto('upload_url');
    Result.UploadStatus := Integer(L.Inteiro('upload_status', -1));
  finally
    O.Free;
  end;
end;

class function TMapeador.AnexoExistente(const AJson: string): TAnexoExistente;
var
  O: TJSONObject;
  L: TLeitorJson;
begin
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.Existe := L.Booleano('existe');
    Result.Id := L.Inteiro('id');
    Result.Identificador := L.Texto('identificador');
    Result.Tipo := TCodigos.TipoConteudo(L.Inteiro('tipo'));
    Result.Tamanho := L.Inteiro('tamanho');
    Result.UploadStatus := Integer(L.Inteiro('upload_status', -1));
  finally
    O.Free;
  end;
end;

class function TMapeador.UrlDoAnexo(const AJson: string): string;
var
  O: TJSONObject;
begin
  O := TJson.LerObjeto(AJson);
  try
    Result := TLeitorJson.Create(O).Texto('url');
  finally
    O.Free;
  end;
end;

class function TMapeador.Galeria(const AJson: string): TArray<TAnexoGaleria>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  G: TAnexoGaleria;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        G.AnexoId := L.Inteiro('anexo_id');
        G.Identificador := L.Texto('identificador');
        G.Nome := L.Texto('nome');
        G.Extensao := L.Texto('extensao');
        G.Tamanho := L.Inteiro('tamanho');
        G.CriadoEm := L.DataUtc('criado_em');
        G.Tipo := TCodigos.TipoConteudo(L.Inteiro('tipo'));
        G.MensagemId := L.Inteiro('mensagem_id');
        G.ConversaId := L.Inteiro('conversa_id');
        G.ConversaDescricao := L.Texto('conversa_descricao');
        G.AutorId := L.Inteiro('autor_id');
        G.AutorNome := L.Texto('autor_nome');
        G.Url := L.Texto('url');
        Result := Result + [G];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.Transcricao(const AJson: string): TTranscricao;
var
  O: TJSONObject;
  L: TLeitorJson;
begin
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.Status := TCodigos.StatusTranscricao(L.Inteiro('status'));
    Result.Texto := L.Texto('texto');
    Result.Erro := L.Texto('erro');
  finally
    O.Free;
  end;
end;

{ chamadas }

class function TMapeador.ParticipanteChamada(AObj: TJSONObject): TParticipanteChamada;
var
  L: TLeitorJson;
begin
  L := TLeitorJson.Create(AObj);
  Result.UsuarioId := L.Inteiro('usuario_id');
  Result.Nome := L.Texto('usuario_nome');
  Result.Status := TCodigosChamada.StatusParticipante(L.Inteiro('status'));
  Result.AdicionadoPor := L.Inteiro('adicionado_por');
  Result.AdicionadoPorNome := L.Texto('adicionado_por_nome');
  Result.AdicionadoEm := L.DataUtc('adicionado_em');
  Result.EntrouEm := L.DataUtc('entrou_em');
  Result.SaiuEm := L.DataUtc('saiu_em');
  Result.RecusouEm := L.DataUtc('recusou_em');
end;

class function TMapeador.ParticipanteResumo(AObj: TJSONObject): TParticipanteResumo;
var
  L: TLeitorJson;
begin
  L := TLeitorJson.Create(AObj);
  Result.UsuarioId := L.Inteiro('usuario_id');
  Result.Nome := L.Texto('nome');
  Result.Status := TCodigosChamada.StatusParticipante(L.Inteiro('status'));
  Result.Duracao := Integer(L.Inteiro('duracao', -1));
  Result.AvatarUrl := L.Texto('avatar_url');
end;

class function TMapeador.ListaDeParticipantesResumo(ALista: TJSONArray): TArray<TParticipanteResumo>;
var
  I: Integer;
begin
  SetLength(Result, 0);
  if not Assigned(ALista) then
    Exit;
  for I := 0 to ALista.Count - 1 do
    if ALista.Items[I] is TJSONObject then
      Result := Result + [ParticipanteResumo(TJSONObject(ALista.Items[I]))];
end;

class function TMapeador.DadosChamadaDe(AObj: TJSONObject): TDadosChamada;
var
  L: TLeitorJson;
  LUsuarios: TJSONArray;
  I: Integer;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  Result.Tipo := Integer(L.Inteiro('tipo'));
  Result.Status := TCodigosChamada.Status(L.Inteiro('status'));
  Result.Iniciada := L.DataUtc('iniciada');
  Result.Finalizada := L.DataUtc('finalizada');
  Result.CriadoEm := L.DataUtc('criado_em');
  Result.CriadoPor := L.Inteiro('criado_por');
  Result.ConversaChatId := L.Inteiro('conversa_chat_id');
  SetLength(Result.Participantes, 0);
  LUsuarios := L.Lista('usuarios');
  if Assigned(LUsuarios) then
    for I := 0 to LUsuarios.Count - 1 do
      if LUsuarios.Items[I] is TJSONObject then
        Result.Participantes := Result.Participantes + [ParticipanteChamada(TJSONObject(LUsuarios.Items[I]))];
end;

class function TMapeador.DadosChamada(const AJson: string): TDadosChamada;
var
  O: TJSONObject;
begin
  O := TJson.LerObjeto(AJson);
  try
    Result := DadosChamadaDe(O);
  finally
    O.Free;
  end;
end;

class function TMapeador.ChamadasPendentes(const AJson: string): TArray<TChamadaPendente>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  P: TChamadaPendente;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        P.Id := L.Inteiro('id');
        P.Tipo := Integer(L.Inteiro('tipo'));
        P.Status := TCodigosChamada.Status(L.Inteiro('status'));
        P.Iniciada := L.DataUtc('iniciada');
        P.Finalizada := L.DataUtc('finalizada');
        P.ConversaId := L.Inteiro('conversa_id');
        P.CriadoEm := L.DataUtc('criado_em');
        P.CriadoPor := L.Inteiro('criado_por');
        Result := Result + [P];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.HistoricoDeChamadas(const AJson: string): TArray<TChamadaHistorico>;
var
  A: TJSONArray;
  I: Integer;
  L: TLeitorJson;
  H: TChamadaHistorico;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if A.Items[I] is TJSONObject then
      begin
        L := TLeitorJson.Create(TJSONObject(A.Items[I]));
        H.Id := L.Inteiro('id');
        H.Tipo := Integer(L.Inteiro('tipo'));
        H.Status := TCodigosChamada.Status(L.Inteiro('status'));
        H.CriadoEm := L.DataUtc('criado_em');
        H.CriadoPor := L.Inteiro('criado_por');
        H.ConversaId := L.Inteiro('conversa_id');
        H.Iniciada := L.DataUtc('iniciada');
        H.Finalizada := L.DataUtc('finalizada');
        H.Duracao := Integer(L.Inteiro('duracao', -1));
        H.Participantes := ListaDeParticipantesResumo(L.Lista('participantes'));
        Result := Result + [H];
      end;
  finally
    A.Free;
  end;
end;

class function TMapeador.ResumoChamada(const AConteudo: string): TResumoChamada;
var
  V: TJSONValue;
  L: TLeitorJson;
begin
  Result := Default(TResumoChamada);
  Result.Duracao := -1;
  V := TJSONObject.ParseJSONValue(AConteudo);
  try
    if not (V is TJSONObject) then
      Exit;
    L := TLeitorJson.Create(TJSONObject(V));
    Result.Valido := True;
    Result.ChamadaId := L.Inteiro('chamada_id');
    Result.Tipo := Integer(L.Inteiro('tipo'));
    Result.Status := TCodigosChamada.Status(L.Inteiro('status'));
    Result.Iniciada := L.DataUtc('iniciada');
    Result.Finalizada := L.DataUtc('finalizada');
    Result.Duracao := Integer(L.Inteiro('duracao', -1));
    Result.Participantes := ListaDeParticipantesResumo(L.Lista('participantes'));
  finally
    V.Free;
  end;
end;

class function TMapeador.ConfiguracaoIce(const AJson: string): TConfiguracaoIce;
var
  O: TJSONObject;
  L, LS: TLeitorJson;
  LServidores: TJSONArray;
  LUrls: TJSONValue;
  I, J: Integer;
  S: TServidorIce;
begin
  Result := Default(TConfiguracaoIce);
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.SoRelay := SameText(L.Texto('iceTransportPolicy'), 'relay');
    LServidores := L.Lista('iceServers');
    if Assigned(LServidores) then
      for I := 0 to LServidores.Count - 1 do
        if LServidores.Items[I] is TJSONObject then
        begin
          LS := TLeitorJson.Create(TJSONObject(LServidores.Items[I]));
          S := Default(TServidorIce);
          // "urls" hoje é texto único; o padrão do WebRTC também aceita lista
          LUrls := TJSONObject(LServidores.Items[I]).GetValue('urls');
          if LUrls is TJSONArray then
          begin
            for J := 0 to TJSONArray(LUrls).Count - 1 do
              if TJSONArray(LUrls).Items[J] is TJSONString then
                S.Urls := S.Urls + [TJSONArray(LUrls).Items[J].Value];
          end
          else if LS.Texto('urls') <> '' then
            S.Urls := [LS.Texto('urls')];
          S.Usuario := LS.Texto('username');
          S.Credencial := LS.Texto('credential');
          Result.Servidores := Result.Servidores + [S];
        end;
  finally
    O.Free;
  end;
end;

{ enquetes }

class function TMapeador.EnqueteDe(AObj: TJSONObject): TEnquete;
var
  L, LO, LV: TLeitorJson;
  LOpcoes, LVotantes: TJSONArray;
  I, J: Integer;
  Op: TOpcaoEnquete;
  Vt: TVotante;
begin
  L := TLeitorJson.Create(AObj);
  Result.Id := L.Inteiro('id');
  Result.ConversaId := L.Inteiro('conversa_id');
  Result.MensagemId := L.Inteiro('mensagem_id');
  Result.Pergunta := L.Texto('pergunta');
  Result.Multipla := L.Booleano('multipla');
  Result.CriadoPor := L.Inteiro('criado_por');
  Result.EncerraEm := L.DataUtc('encerra_em');
  Result.EncerradaEm := L.DataUtc('encerrada_em');
  Result.Encerrada := L.Booleano('encerrada');
  Result.PodeEncerrar := L.Booleano('pode_encerrar');
  Result.PodeAlterarPrazo := L.Booleano('pode_alterar_prazo');
  Result.TotalVotantes := Integer(L.Inteiro('total_votantes'));
  Result.MeusVotos := L.Inteiros('meus_votos');
  SetLength(Result.Opcoes, 0);
  LOpcoes := L.Lista('opcoes');
  if Assigned(LOpcoes) then
    for I := 0 to LOpcoes.Count - 1 do
      if LOpcoes.Items[I] is TJSONObject then
      begin
        LO := TLeitorJson.Create(TJSONObject(LOpcoes.Items[I]));
        Op := Default(TOpcaoEnquete);
        Op.Id := LO.Inteiro('id');
        Op.Texto := LO.Texto('texto');
        LVotantes := LO.Lista('votantes');
        if Assigned(LVotantes) then
          for J := 0 to LVotantes.Count - 1 do
            if LVotantes.Items[J] is TJSONObject then
            begin
              LV := TLeitorJson.Create(TJSONObject(LVotantes.Items[J]));
              Vt.Id := LV.Inteiro('id');
              Vt.Nome := LV.Texto('nome');
              Op.Votantes := Op.Votantes + [Vt];
            end;
        Result.Opcoes := Result.Opcoes + [Op];
      end;
end;

class function TMapeador.Enquete(const AJson: string): TEnquete;
var
  O: TJSONObject;
begin
  O := TJson.LerObjeto(AJson);
  try
    Result := EnqueteDe(O);
  finally
    O.Free;
  end;
end;

{ sistema }

class function TMapeador.MinhasPermissoes(const AJson: string): TArray<string>;
var
  A: TJSONArray;
  I: Integer;
begin
  A := TJson.LerLista(AJson);
  try
    SetLength(Result, 0);
    for I := 0 to A.Count - 1 do
      if (A.Items[I] is TJSONString) and not (A.Items[I] is TJSONNumber) then
        Result := Result + [A.Items[I].Value];
  finally
    A.Free;
  end;
end;

class function TMapeador.PainelPermissoes(const AJson: string): TPainelPermissoes;
var
  O: TJSONObject;
  L, LI: TLeitorJson;
  LLista: TJSONArray;
  I: Integer;
  P: TPermissao;
  U: TUsuarioPermissoes;
begin
  Result := Default(TPainelPermissoes);
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.ModoAberto := L.Booleano('modo_aberto');
    LLista := L.Lista('permissoes');
    if Assigned(LLista) then
      for I := 0 to LLista.Count - 1 do
        if LLista.Items[I] is TJSONObject then
        begin
          LI := TLeitorJson.Create(TJSONObject(LLista.Items[I]));
          P.Codigo := LI.Texto('codigo');
          P.Descricao := LI.Texto('descricao');
          Result.Permissoes := Result.Permissoes + [P];
        end;
    LLista := L.Lista('usuarios');
    if Assigned(LLista) then
      for I := 0 to LLista.Count - 1 do
        if LLista.Items[I] is TJSONObject then
        begin
          LI := TLeitorJson.Create(TJSONObject(LLista.Items[I]));
          U.Id := LI.Inteiro('id');
          U.Nome := LI.Texto('nome');
          U.Login := LI.Texto('login');
          U.Permissoes := LI.Textos('permissoes');
          Result.Usuarios := Result.Usuarios + [U];
        end;
  finally
    O.Free;
  end;
end;

class function TMapeador.Parametros(const AJson: string): TParametros;
var
  O: TJSONObject;
  L: TLeitorJson;
begin
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.FcmProjectId := L.Texto('fcm_project_id');
    Result.FcmClientEmail := L.Texto('fcm_client_email');
    Result.FcmPrivateKeyConfigurada := L.Booleano('fcm_private_key_configurada');
    Result.TurnForcarRelay := L.Booleano('turn_forcar_relay');
    Result.TranscritorUrl := L.Texto('transcritor_url');
    Result.TranscritorIdioma := L.Texto('transcritor_idioma');
    Result.GravacaoDias := Integer(L.Inteiro('gravacao_dias'));
    Result.S3Bucket := L.Texto('s3_bucket');
  finally
    O.Free;
  end;
end;

class function TMapeador.RamalSip(const AJson: string): TRamalSip;
var
  O: TJSONObject;
  L: TLeitorJson;
begin
  Result := Default(TRamalSip);
  O := TJson.LerObjeto(AJson);
  try
    L := TLeitorJson.Create(O);
    Result.Existe := L.Tem('id');
    if not Result.Existe then
      Exit;
    Result.Id := L.Inteiro('id');
    Result.UsuarioId := L.Inteiro('usuario_id');
    Result.SipUser := L.Texto('sip_user');
    Result.AuthUser := L.Texto('auth_user');
    Result.SipPassword := L.Texto('sip_password');
    Result.DisplayName := L.Texto('display_name');
    Result.Domain := L.Texto('domain');
    Result.WsServer := L.Texto('ws_server');
    Result.Ativo := L.Booleano('ativo', True);
  finally
    O.Free;
  end;
end;

end.
