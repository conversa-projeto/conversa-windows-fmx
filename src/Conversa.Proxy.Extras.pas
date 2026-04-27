(*----------------------------------------------------------------------------------------------------------------------
Conversa.Proxy.Extras — endpoints REST adicionais (em paridade com conversa-web/src/services/conversaApi.ts)

Adiciona a capacidade de acesso aos seguintes endpoints que NAO existem em Conversa.Proxy.pas:

  - POST   /alterar-senha                 (altera senha)
  - PUT    /mensagem/reacao               (toggle emoji reaction)
  - POST   /mensagem/reproduzir           (marca audio reproduzido)
  - GET    /pesquisar                     (busca de mensagens)
  - POST   /conversa/digitando            (broadcast digitando)
  - POST   /conversa/gravando             (broadcast gravando audio)
  - POST   /chamada/video                 (upgrade audio->video)
  - PUT    /chamada/usuario               (adicionar participante mid-call)
  - GET    /chamadas/pendentes            (chamadas pendentes)
  - GET    /sip                           (config SIP)
  - PUT    /sip                           (criar SIP)
  - PATCH  /sip                           (atualizar SIP)
  - GET    /anexos                        (listar anexos)
  - POST   /anexo/confirmar               (confirmar upload MinIO)

Estrutura de estilo igual a Conversa.Proxy.pas — classes estaticas com metodos procedurais.
Todos usam TAPIInternal (definido em Conversa.Proxy.pas) para consistencia de auth.

Autor: Migracao automatica 2026-04-21 com base em ConversaApi.kt e services/conversaApi.ts
----------------------------------------------------------------------------------------------------------------------*)
unit Conversa.Proxy.Extras;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  Conversa.Proxy,
  Conversa.Proxy.Tipos,
  Conversa.Configuracoes,
  REST.API;

type
  // ======================= USUARIO / DISPOSITIVO EXTRAS =======================
  TUsuarioExtras = class
  public
    class procedure AlterarSenha(const SenhaAtual, SenhaNova: String);
  end;

  // ======================= MENSAGEM EXTRAS =======================
  TMensagemExtras = class
  public
    // Toggle de emoji reaction. acao retornada sera 'add' ou 'remove'.
    class function Reagir(MensagemId: Integer; const Emoji: String): TJSONObject;

    // Marca audio como reproduzido
    class procedure Reproduzir(MensagemId, ConversaId: Integer);

    // Busca global ou por conversa
    class function Pesquisar(const Texto: String; ConversaId: Integer = 0): TJSONArray;

    // Envia mensagem com referencia (responder ou encaminhar)
    // Tipo: 1=Responder, 2=Encaminhar
    class function EnviarComReferencia(
      ConversaId: Integer;
      Conteudos: TJSONArray;
      TipoReferencia: Integer;
      DestinoMensagemId: Integer;
      const VisivelEmISO: String = ''
    ): TJSONObject;
  end;

  // ======================= DIGITANDO / GRAVANDO =======================
  TConversaIndicadores = class
  public
    class procedure Digitando(ConversaId: Integer);
    class procedure GravandoAudio(ConversaId: Integer);
  end;

  // ======================= CHAMADA EXTRAS =======================
  TChamadaExtras = class
  public
    // Upgrade audio -> video. Dispara evento WS tipo 56 aos peers.
    class procedure AtivarVideo(ChamadaId: Integer);

    // Adicionar novo participante a chamada ativa
    class procedure AdicionarUsuario(ChamadaId, UsuarioId: Integer);

    // Chamadas pendentes (onde sou Pendente)
    class function Pendentes: TJSONArray;
  end;

  // ======================= SIP (PSTN) =======================
  TSipProxy = class
  public
    class function Obter: TJSONObject; // retorna nil se 404
    class function Criar(Config: TJSONObject): TJSONObject;
    class procedure Atualizar(Config: TJSONObject);
  end;

  // ======================= ANEXO EXTRAS =======================
  TAnexoExtras = class
  public
    class function Listar(
      ConversaId: Integer = 0;
      AutorId: Integer = 0;
      const Direcao: String = '';
      const Tipos: String = '';
      Antes: Integer = 0;
      Limite: Integer = 0
    ): TJSONArray;

    class procedure Confirmar(const Identificador: String);
  end;

  // ======================= USUARIO EXTRAS =======================
  TUsuarioRegistro = class
  public
    // Cadastro publico de novo usuario (nao requer auth)
    class function Cadastrar(const Nome, Login, Email, Senha: String;
      const Telefone: String = ''): TJSONObject;
  end;

  // ======================= CONTATOS EXTRAS =======================
  TContatoOnline = class
  public
    // Lista IDs de usuarios online no momento
    class function ListarOnline: TJSONArray;
  end;

  // ======================= CHAMADA PENDENTES =======================
  TChamadaPendentes = class
  public
    // Chamadas pendentes (recebendo, nao atendidas) do usuario autenticado
    class function Listar: TJSONArray;
  end;

  // Helper para injetar o token JWT (o token "canonico" esta em
  // Conversa.Proxy.TAPIInternal.FToken, mas ela esta na implementation e nao e acessivel).
  // Apos login bem-sucedido, chame tambem: TConversaExtrasAuth.SetToken(token).
  // Ver docs/problemas.md para unificacao futura.
  TConversaExtrasAuth = class
  public
    class procedure SetToken(const Token: String); static;
  end;

implementation

type
  // Wrapper local — replica TAPIInternal de Conversa.Proxy (que esta declarada na
  // implementation daquela unit e portanto nao e acessivel de fora). Esta versao
  // replica o comportamento de Create (Host + Authorization Bearer).
  // Se mais adiante o token puder ser compartilhado via Conversa.Configuracoes,
  // esta classe pode ler de la.
  TAPIExtras = class(TRESTAPI)
  private
    class var FToken: String;
  public
    constructor Create;
    class procedure SetToken(const Token: String); static;
  end;

constructor TAPIExtras.Create;
begin
  inherited;
  Host(Configuracoes.Host);
  if not FToken.IsEmpty then
    Authorization(TAuthBearer.New(FToken));
end;

class procedure TAPIExtras.SetToken(const Token: String);
begin
  FToken := Token;
end;

{ TConversaExtrasAuth }

class procedure TConversaExtrasAuth.SetToken(const Token: String);
begin
  TAPIExtras.SetToken(Token);
end;

{ TUsuarioRegistro }

class function TUsuarioRegistro.Cadastrar(const Nome, Login, Email, Senha,
  Telefone: String): TJSONObject;
var
  joBody: TJSONObject;
begin
  Result := nil;
  joBody := TJSONObject.Create;
  joBody.AddPair('nome', Nome);
  joBody.AddPair('login', Login);
  joBody.AddPair('email', Email);
  joBody.AddPair('senha', Senha);
  if Telefone <> '' then
    joBody.AddPair('telefone', Telefone);

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('usuario');
    PUT;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONObject;
  finally
    Free;
  end;
end;

{ TContatoOnline }

class function TContatoOnline.ListarOnline: TJSONArray;
begin
  Result := nil;
  with TAPIExtras.Create do
  try
    Route('contatos/online');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONArray;
  finally
    Free;
  end;
end;

{ TChamadaPendentes }

class function TChamadaPendentes.Listar: TJSONArray;
begin
  Result := nil;
  with TAPIExtras.Create do
  try
    Route('chamadas/pendentes');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONArray;
  finally
    Free;
  end;
end;

{ TUsuarioExtras }

class procedure TUsuarioExtras.AlterarSenha(const SenhaAtual, SenhaNova: String);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('senha_atual', SenhaAtual);
  joBody.AddPair('senha_nova', SenhaNova);

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('alterar-senha');
    POST;
  finally
    Free;
  end;
end;

{ TMensagemExtras }

class function TMensagemExtras.Reagir(MensagemId: Integer; const Emoji: String): TJSONObject;
var
  joBody: TJSONObject;
begin
  Result := nil;
  joBody := TJSONObject.Create;
  joBody.AddPair('mensagem_id', TJSONNumber.Create(MensagemId));
  joBody.AddPair('emoji', Emoji);

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('mensagem/reacao');
    PUT;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONObject;
  finally
    Free;
  end;
end;

class procedure TMensagemExtras.Reproduzir(MensagemId, ConversaId: Integer);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('mensagem_id', TJSONNumber.Create(MensagemId));
  joBody.AddPair('conversa_id', TJSONNumber.Create(ConversaId));

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('mensagem/reproduzir');
    POST;
  finally
    Free;
  end;
end;

class function TMensagemExtras.Pesquisar(const Texto: String; ConversaId: Integer): TJSONArray;
var
  joQuery: TJSONObject;
begin
  Result := nil;
  joQuery := TJSONObject.Create;
  joQuery.AddPair('texto', Texto);
  if ConversaId > 0 then
    joQuery.AddPair('conversa', TJSONNumber.Create(ConversaId));

  with TAPIExtras.Create do
  try
    Query(joQuery);
    Route('pesquisar');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONArray;
  finally
    Free;
  end;
end;

class function TMensagemExtras.EnviarComReferencia(
  ConversaId: Integer;
  Conteudos: TJSONArray;
  TipoReferencia: Integer;
  DestinoMensagemId: Integer;
  const VisivelEmISO: String): TJSONObject;
var
  joBody, joRef: TJSONObject;
begin
  Result := nil;
  joBody := TJSONObject.Create;
  joBody.AddPair('conversa_id', TJSONNumber.Create(ConversaId));
  joBody.AddPair('conteudos', Conteudos);

  joRef := TJSONObject.Create;
  joRef.AddPair('tipo', TJSONNumber.Create(TipoReferencia));
  joRef.AddPair('destino_mensagem_id', TJSONNumber.Create(DestinoMensagemId));
  joBody.AddPair('referencia', joRef);

  if VisivelEmISO <> '' then
    joBody.AddPair('visivel_em', VisivelEmISO);

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('mensagem');
    PUT;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONObject;
  finally
    Free;
  end;
end;

{ TConversaIndicadores }

class procedure TConversaIndicadores.Digitando(ConversaId: Integer);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('conversa_id', TJSONNumber.Create(ConversaId));

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('conversa/digitando');
    POST;
  finally
    Free;
  end;
end;

class procedure TConversaIndicadores.GravandoAudio(ConversaId: Integer);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('conversa_id', TJSONNumber.Create(ConversaId));

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('conversa/gravando');
    POST;
  finally
    Free;
  end;
end;

{ TChamadaExtras }

class procedure TChamadaExtras.AtivarVideo(ChamadaId: Integer);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('id', TJSONNumber.Create(ChamadaId));

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('chamada/video');
    POST;
  finally
    Free;
  end;
end;

class procedure TChamadaExtras.AdicionarUsuario(ChamadaId, UsuarioId: Integer);
var
  joBody: TJSONObject;
begin
  joBody := TJSONObject.Create;
  joBody.AddPair('chamada_id', TJSONNumber.Create(ChamadaId));
  joBody.AddPair('usuario_id', TJSONNumber.Create(UsuarioId));

  with TAPIExtras.Create do
  try
    Body(joBody);
    Route('chamada/usuario');
    PUT;
  finally
    Free;
  end;
end;

class function TChamadaExtras.Pendentes: TJSONArray;
begin
  Result := nil;
  with TAPIExtras.Create do
  try
    Route('chamadas/pendentes');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONArray;
  finally
    Free;
  end;
end;

{ TSipProxy }

class function TSipProxy.Obter: TJSONObject;
begin
  Result := nil;
  with TAPIExtras.Create do
  try
    Route('sip');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONObject;
  finally
    Free;
  end;
end;

class function TSipProxy.Criar(Config: TJSONObject): TJSONObject;
begin
  Result := nil;
  with TAPIExtras.Create do
  try
    Body(Config);
    Route('sip');
    PUT;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONObject;
  finally
    Free;
  end;
end;

class procedure TSipProxy.Atualizar(Config: TJSONObject);
begin
  with TAPIExtras.Create do
  try
    Body(Config);
    Route('sip');
    PATCH;
  finally
    Free;
  end;
end;

{ TAnexoExtras }

class function TAnexoExtras.Listar(
  ConversaId, AutorId: Integer;
  const Direcao, Tipos: String;
  Antes, Limite: Integer): TJSONArray;
var
  joQuery: TJSONObject;
begin
  Result := nil;
  joQuery := TJSONObject.Create;
  if ConversaId > 0 then joQuery.AddPair('conversa', TJSONNumber.Create(ConversaId));
  if AutorId > 0    then joQuery.AddPair('autor', TJSONNumber.Create(AutorId));
  if Direcao <> ''  then joQuery.AddPair('direcao', Direcao);
  if Tipos <> ''    then joQuery.AddPair('tipos', Tipos);
  if Antes > 0      then joQuery.AddPair('antes', TJSONNumber.Create(Antes));
  if Limite > 0     then joQuery.AddPair('limite', TJSONNumber.Create(Limite));

  with TAPIExtras.Create do
  try
    Query(joQuery);
    Route('anexos');
    GET;
    if Response.Status = TResponseStatus.Sucess then
      Result := Response.ToJSONArray;
  finally
    Free;
  end;
end;

class procedure TAnexoExtras.Confirmar(const Identificador: String);
var
  joQuery: TJSONObject;
begin
  joQuery := TJSONObject.Create;
  joQuery.AddPair('identificador', Identificador);

  with TAPIExtras.Create do
  try
    Query(joQuery);
    Route('anexo/confirmar');
    POST;
  finally
    Free;
  end;
end;

end.
