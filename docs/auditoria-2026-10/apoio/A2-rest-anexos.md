> **Relatório de apoio da auditoria de 2026-10-08** — frente: REST e anexos: o contrato que o FMX usa × o servidor atual.
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A2 — REST e anexos: o contrato que o FMX usa × o servidor atual

Auditoria feita em 2026-10-08, **somente leitura** (nenhum arquivo dos 4 repositórios foi alterado). Esta é a versão FMX do doc `02-mudancas-servidor-desde-abril.md` do Android, restrita a **REST e anexos** (WebSocket e sinalização de chamada ficam com os colegas; as rotas REST de chamada estão aqui).

## 0. Referências e método

| Item | Valor |
|---|---|
| Cliente | `conversa-windows-fmx` (Delphi 12 / FireMonkey), branch `chamada`, HEAD **`4759ba5`** (2026-04-26). Auditada a **árvore de trabalho** = HEAD + *staged* (`Conversa.Dados.pas`, `src/chamada/Conversa.Chamada.WebRTC.pas`). As alterações staged tocam só o WebSocket/WebRTC (fora do escopo desta parte). |
| Servidor atual | `conversa` (Bun + Elysia), HEAD **`779c8ed`** (= `5cad911` para efeito de contrato; `779c8ed` só mexe no `.bat`). 54 rotas publicadas confirmadas no OpenAPI vivo (`https://localhost/api/docs/json`). |
| Servidor de abril | `56e7cc0` (2026-04-19, Delphi/Horse): `conversa.rest.dpr`, `src/conversa/conversa.api.pas` e `src/jhonson/Horse.Jhonson.pas`. |
| Web (referência) | `conversa-web` HEAD `e8d82cb`, `src/services/conversaApi.ts`. |
| Contrato validado | `conversa-android-kotlin/docs/auditoria-2026-10/01-contrato-servidor-atual.md` (69 rotas, §4/§8/§10/§11/§19). |

Convenções: sem prefixo de commit = HEAD atual (servidor `779c8ed`/`5cad911` ou árvore FMX). `api.pas@56e7cc0:N` = servidor de abril. **[NOVA]** = quebra introduzida entre `56e7cc0` e hoje (funcionava em abril). **[ABRIL]** = o FMX já era incompatível com o servidor de abril e continua.

**Achado transversal, igual ao do Android:** quase toda a “segunda camada” de endpoints do FMX é **código morto**. `src/Conversa.Proxy.Extras.pas` (533 linhas: `alterar-senha`, `mensagem/reacao`, `mensagem/reproduzir`, `pesquisar`, `mensagem` com referência, `conversa/digitando`, `conversa/gravando`, `chamada/video`, `chamada/usuario`, `chamadas/pendentes`, `sip`, `anexos`, `anexo/confirmar`, cadastro público, `contatos/online`) **não tem nenhum chamador** fora do próprio arquivo (busca por `TAPIExtras`, `TMensagemExtras`, `TChamadaExtras`, `TSipProxy`, `TAnexoExtras`, `TConversaIndicadores`, `TUsuarioRegistro`, `TContatoOnline`, `TChamadaPendentes`). Vários métodos de `Conversa.Proxy.pas` também não são chamados (`Usuario.Incluir/Alterar/Excluir`, `Contato.*`, `Conversa.Alterar/Excluir`, `ConversaUsuario.Excluir`, `Mensagem.Excluir`, `Dispositivo.Incluir/Usuario`). Por isso há a coluna **“Roda?”** na tabela: a maioria das quebras é **latente** (só apareceria se o código morto fosse ligado).

---

## 1. Camada HTTP (`REST.API.pas`, `src/Conversa.Proxy.pas`)

- **Biblioteca:** `TNetHTTPClient` (`System.Net.HttpClientComponent`), um por requisição, criado em `TRESTAPI.Create` (`REST.API.pas:145,197`). Em Windows isso usa o **WinHTTP/SChannel** do SO.
- **URL base:** vem inteira de `Configuracoes.Host` (`Conversa.Configuracoes.pas:14`), ex.: `https://localhost:4430/api/`. É aplicada em `TAPIInternal.Create` (`Conversa.Proxy.pas:114`) e `TAPIExtras.Create` (`Conversa.Proxy.Extras.pas:162`). `Route('login')` é concatenado em `GetURI` (`REST.API.pas:313-338`, trim de `/`, `TURI.Encode`). **O `/api` já faz parte do Host** — não há campos separados de host/porta/path. Configurado só pela tela `ConfigurarConexao` (`src/configuracoes/Conversa.Configurar.Conexao.pas:77`, um único `edtHost`), salvo em `conversa.json` (`Conversa.Configuracoes.pas:70-77`). O arquivo local de dev tem `"Host":"https://localhost:4430/api/"` e `"MediaMtxBase":"http://localhost:8889"`.
- **Cabeçalhos / Authorization:** `Content-Type: application/json` default em todo request (`REST.API.pas:614`). `TAuthBearer` injeta `Authorization: Bearer <token>` (`REST.API.pas:398-414,712-726`). O token é `class var TAPIInternal.FToken` (`Conversa.Proxy.pas:98`), setado no login (`:205`) e reusado por todas as chamadas de `TAPIInternal`.
- **Timeouts:** `TRESTAPI.Timeout` existe (`REST.API.pas:227-244`) mas **nunca é chamado** pelo proxy → ficam os defaults do `TNetHTTPClient` (ConnectionTimeout/ResponseTimeout ≈ 60 s). Como várias chamadas são **síncronas na thread de UI** (ver §1-threads), a janela pode congelar até ~60 s se o servidor não responder.
- **Novas tentativas (`Tentativa`):** `TAPIInternal.Tentativa(n)` (`Conversa.Proxy.pas:137-152`) repete só em erro de rede (status `Unknown`), com backoff `Sleep(I*I*1000)`; erro do servidor (4xx/5xx) não repete. Usada só em `Conversa.Dados` (`Tentativa(3)`, `Conversa.Proxy.pas:584`) e `Mensagem.Visualizar` (`Tentativa(5)`, `:737`).
- **TLS:** **não há callback que aceita qualquer certificado** (não existe `OnValidateServerCertificate`/trust-all no REST). O `TNetHTTPClient` valida contra o **repositório de certificados do Windows**. Com o servidor de dev (mkcert), funciona **se e somente se** a CA raiz do mkcert estiver instalada na máquina (`mkcert -install`, feito por `conversa/bin/setup-cert.bat:41`). O certificado cobre `localhost 127.0.0.1 <IP>` (`setup-cert.bat:45`). O WebSocket (Indy, fora do escopo) usa `sslvTLSv1/1.1/1.2` e `PassThrough:=False` sem override de validação (`lib/bird-socket-client/Bird.Socket.Client.pas:267-271`).
- **Tratamento de erro:** `TAPIInternal.InternalExecute` (`Conversa.Proxy.pas:121-135`) lê o campo `error` do JSON em resposta não-2xx; se não houver `error`, usa o corpo cru. `TResponse.Value` classifica `1..3xx = Sucess`, `4..5xx = Error`, resto `Unknown` (`REST.API.pas:477-482`). **3xx é tratado como sucesso** (benigno hoje, mas frágil). Exceção de rede → `Unknown`, `StatusCode = 0`, mensagem = texto da exceção (`REST.API.pas:389-394`). O formato de erro do servidor atual é `{ "error": ... }` (`conversa/src/app.ts:57-77`) — **igual** ao do FMX esperado; em abril o Horse também mandava `{error}` (`Horse.HandleException.pas`).
- **401 / sessão expirada:** **não há tratamento global de 401**. Só o `Login` trata 4xx (limpa a senha salva e zera `DispositivoId` se a mensagem contém `"Seção Encerrada!"`, `Conversa.Proxy.pas:186-196`). O token tem validade de **12 h** (`autenticacao.ts:6`); depois disso toda rota responde 401 e o FMX não reage (sem refresh/relogin). `TAuthBearer.Expired` chega a conferir `exp` localmente, mas só no caminho `New(Token)` (`REST.API.pas:728-753`).
- **Respostas HTML do nginx (413/502/503):** 5xx → `Error`; sem campo `error` no HTML, `MensagemErro` vira o HTML cru. O limite de login (10/min, `conversa/bin/nginx/nginx.conf:74,97-100`) devolve 503 HTML; o upload >1 MiB devolve 413 HTML (`:24`).
- **Logs:** `AddLog` (`Conversa.Log.Pas:26-37`) grava em `PastaDados\log.txt`. **A camada REST não registra corpo, token nem senha** (só a unidade de WebRTC usa `AddLog`). ✅ Sem vazamento de segredos em log.
- **Erros silenciosos:** `ValidarErro` (`Conversa.Proxy.pas:154-167`) dispara o evento `TErroServidor` e `Abort`. **No app real ninguém assina `TErroServidor`** (só `teste/Exemplo.Principal.pas`). Logo, erros de servidor nas rotas que usam `ValidarErro` são **engolidos em silêncio** (ver §7).

**Threads:** rodam em `TThread.CreateAnonymousThread`: `Conversas`, `Mensagens`, `MensagensNovas` (parcial), `Chamadas`, `Mensagem.Status`, `Mensagem.Visualizar`, `Conversa.Dados`, `Anexo.Incluir`. Rodam **síncronas (UI/caller)**: `Login`, `CarregarContatos`/`Usuario.Contatos`, `NovoChat` (`Conversa.Incluir` + `Conversa/usuario`), `Anexo.Existe`, `Anexo.Download`, e todas as de chamada (`Iniciar/Entrar/Sair/...`, `Dados`). Os eventos de resultado voltam à thread principal via `TThread.ForceQueue` (`Conversa.Evento.Base.pas:61-75`).

---

## 2. Tabela de TODAS as chamadas REST do FMX

**Segurança/token:** `Conversa.Proxy.pas` usa `TAPIInternal` (token OK). `Conversa.Proxy.Extras.pas` usa `TAPIExtras`, que tem **um segundo `FToken` de classe nunca inicializado** (`Conversa.Proxy.Extras.pas:153,167`; só `TConversaExtrasAuth.SetToken` o preencheria, e isso **nunca é chamado**) → toda chamada de Extras iria **sem Authorization → 401**. Como nada em Extras roda, é dupla morte.

Legenda do veredito: ✅ compatível · 🔴 quebra confirmada · 🟠 quebra provável · ⚪ morta (não roda).

| # | Verbo + caminho FMX | Query/corpo que o FMX envia | Onde (arquivo:linha) | Roda? | Servidor atual (arquivo:linha) | Veredito |
|---|---|---|---|---|---|---|
| 1 | POST `login` | body `{login, senha, dispositivo_id}` | `Conversa.Proxy.pas:171-209` ← `Conversa.Dados.pas:117`, `Conversa.Login.pas:80` | sim | `rotas.ts:34`, `esquemas.ts:29`, `usuarios.ts:19-66` | ✅ lê `{id,nome,email,telefone,dispositivo{id},token}` (`TRespostaLogin`, `avatar_identificador` ignorado) |
| 2 | PATCH `dispositivo` | body `{id,nome,modelo,versao_so,plataforma}` | `Conversa.Proxy.pas:452-470` ← `Conversa.Dados.pas:141` | sim | `rotas.ts:52`, `esquemas.ts:31-33`, `usuarios.ts:76-90` | ✅ **manda `id`** (ao contrário do Android) → 200 (403 só se dispositivo alheio) |
| 3 | GET `usuario/contatos` | – | `Conversa.Proxy.pas:398-418` ← `Conversa.Dados.pas:168`, `Contatos.pas:54`, `Novo.Grupo.pas:80` | sim | `rotas.ts:66`, `usuarios.ts:142-144` | ✅ `[{id,nome,login,email,telefone}]` (todos os usuários) |
| 4 | PUT `conversa` | body `{descricao, tipo, inserida}` | `Conversa.Proxy.pas:515-539` ← `Conversa.Dados.pas:315-317` | sim | `rotas.ts:72`, `esquemas.ts:43`, `conversas.ts:39-44` | ✅ `inserida` é ignorado (abril gravava); lê `{id,...}` |
| 5 | PUT `conversa/usuario` | body `{conversa_id, usuario_id}` | `Conversa.Proxy.pas:609-624` ← `Conversa.Dados.pas:321` | sim | `rotas.ts:89`, `conversas.ts:223-235` | ✅ idempotente hoje (abril: 409 ao reincluir a si; melhorou) |
| 6 | GET `conversas` | – | `Conversa.Proxy.pas:211-241` ← `Conversa.Dados.pas:182` | sim | `rotas.ts:78`, `conversas.ts:56-179` | ✅ parse OK (`fixada_ordem`/`arquivada_em`/figurinha/"Mensagem oculta" ignorados; mostra arquivadas) |
| 7 | GET `conversa/dados?id=` | query `{id}` | `Conversa.Proxy.pas:572-605` ← `Conversa.Chat.pas:177` (abre cada chat) | sim | **não existe** (`rotas.ts`; nem em `dpr@56e7cc0`) | 🔴 **[ABRIL]** 404 confirmado no servidor vivo |
| 8 | GET `mensagens?conversa&mensagemreferencia&mensagensprevias&mensagensseguintes` | query | `Conversa.Proxy.pas:243-282` ← `Conversa.Dados.pas:542-548` | sim | `rotas.ts:109`, `esquemas.ts:58-65`, `mensagens.ts:328-376,506-621` | 🟠 parse OK, **mas** `excluida_em` e tipos 5/6/7/8 quebram a exibição (Q6/Q7) |
| 9 | PUT `mensagem` | body `{conversa_id, conteudos:[{ordem,tipo,conteudo}]}` | `Conversa.Proxy.pas:641-664` ← `Conversa.Dados.pas:286` | sim | `rotas.ts:105`, `esquemas.ts:50-57`, `mensagens.ts:148-232` | ✅ texto; 🔴 anexo (tipo 2/3/4) referencia identificador nunca enviado (Q1/Q2); grava sem `visivel_em`/`mensagem_referencia` |
| 10 | GET `mensagens/novas?ultima=` | query `{ultima=<int>}` | `Conversa.Proxy.pas:284-311` ← `Conversa.Dados.pas:477` | sim | `rotas.ts:124`, `esquemas.ts:68` espera **`desde`** (ISO), `mensagens.ts:694-725` | 🟠 **[ABRIL]** `ultima` ignorado → `desde=''` → recarrega tudo; lê `{conversa_id,mensagem_id}` (Q8) |
| 11 | GET `mensagem/status?conversa&mensagem=<csv>` | query | `Conversa.Proxy.pas:666-708` ← `Conversa.Dados.pas:484` (WS 3) | sim | `rotas.ts:118`, `mensagens.ts:636-668` | ✅ **compatível** — lê `recebida/visualizada/reproduzida` **boolean** (o servidor devolve boolean agregado; `excluida_em` ignorado) |
| 12 | **GET** `mensagem/visualizar?conversa&mensagem` | query | `Conversa.Proxy.pas:723-744` ← `Conversa.Dados.pas:349` (`VisualizarMensagem`) | sim | só **POST** `{conversa,mensagem}` (`rotas.ts:112`, `esquemas.ts:66`) | 🔴 **[ABRIL]** 404 confirmado no servidor vivo (Q3) |
| 13 | GET `anexo/existe?identificador=` | query | `Conversa.Proxy.pas:748-760` ← `Conversa.Dados.pas:279` | sim | `rotas.ts:135`, `anexos.ts:33-39` | ✅ lê `existe` |
| 14 | GET `anexo?identificador=` → **bytes** | query | `Conversa.Proxy.pas:762-786` ← `Conversa.Dados.pas:234` (`DownloadAnexo`) | sim | `rotas.ts:137`, `anexos.ts:41-56` devolve **JSON `{url}`** | 🔴 **[ABRIL]** (Q1) |
| 15 | PUT `anexo?tipo&nome&extensao` + corpo `application/octet-stream` | query + bytes | `Conversa.Proxy.pas:788-814` ← `Conversa.Dados.pas:280` (tipo **0**!) | sim | `rotas.ts:139`, `esquemas.ts:74`, `anexos.ts:58-81` espera **JSON** `{identificador,tipo,nome,extensao,tamanho}` | 🔴 **[ABRIL], piorada** (Q2); nginx 1 MiB → 413 |
| 16 | PUT `chamada/iniciar` | body `{usuarios:[{id}]}` | `Conversa.Proxy.pas:818-841` ← `Conversa.Chamada.pas:462` | sim | `rotas.ts:155`, `esquemas.ts:86`, `chamadas.ts:88-110` | ✅ lê `{id,iniciada,finalizada,conversa_id,status,tipo}` (campos extras ignorados); não manda `conversa_id` (sem chat/resumo) |
| 17 | POST `chamada/cancelar` | body `{id}` | `Conversa.Proxy.pas:843-855` ← `Conversa.Chamada.pas:312` | sim | `rotas.ts:157`, `chamadas.ts:153-162` | ✅ (404 se não participa) |
| 18 | POST `chamada/recusar` | body `{id}` | `Conversa.Proxy.pas:857-869` ← `Conversa.Chamada.pas:313` | sim | `rotas.ts:161`, `esquemas.ts:88` (`nao_atendeu?`), `chamadas.ts:164-197` | ✅ (WS 53 também para si; `nao_atendeu` opcional não enviado) |
| 19 | POST `chamada/entrar` | body `{id}` | `Conversa.Proxy.pas:871-894` ← `Conversa.Chamada.pas:296` | sim | `rotas.ts:159`, `chamadas.ts:199-212` | ✅ (deserialização do corpo está comentada; só usa status) |
| 20 | POST `chamada/sair` | body `{id}` | `Conversa.Proxy.pas:896-908` ← `Conversa.Chamada.pas:319` | sim | `rotas.ts:164`, `chamadas.ts:214-225` | ✅ |
| 21 | POST `chamada/finalizar` | body `{id}` | `Conversa.Proxy.pas:910-922` ← `Conversa.Chamada.pas:317` | sim | `rotas.ts:169`, `chamadas.ts:293-300` | ✅ |
| 22 | GET `chamada/dados?id=` | query | `Conversa.Proxy.pas:924-937` ← `Conversa.Chamada.pas:410` | sim | `rotas.ts:201`, `chamadas.ts:307-389` | 🟠 lê `{...,usuarios[]}`; campo FMX `adicinoado_em` (typo) e `conversa_id` não existem na resposta → ficam 0 (benigno) |
| 23 | GET `chamadas` → histórico | – | `Conversa.Proxy.pas:313-337` ← `Conversa.Chamada.Listagem.pas:68` | sim | `rotas.ts:205`, `chamadas.ts:429-450` | 🔴 **[ABRIL]** forma incompatível (Q5) |
| M1 | PUT `dispositivo` | body `{nome,modelo,versao_so,plataforma}` | `Conversa.Proxy.pas:422-450` | **não** | rota não existe (só PATCH) | ⚪ morta |
| M2 | PUT `dispositivo/usuario?dispositivo_id=` | query | `Conversa.Proxy.pas:472-483` | **não** | `rotas.ts:54` | ⚪ morta |
| M3 | PUT `usuario` / PATCH `usuario` / DELETE `usuario?id=` | – | `Conversa.Proxy.pas:341-396` | **não** | `rotas.ts:39,57,59` | ⚪ morta |
| M4 | PUT/DELETE `usuario/contato` | query | `Conversa.Proxy.pas:487-511` | **não** | `rotas.ts:61,64` | ⚪ morta |
| M5 | PATCH `conversa` / DELETE `conversa?id=` | body/query | `Conversa.Proxy.pas:541-570` | **não** | `rotas.ts:74,76` | ⚪ morta |
| M6 | DELETE `conversa/usuario?id=` | query | `Conversa.Proxy.pas:626-637` | **não** | `rotas.ts:91` | ⚪ morta |
| M7 | DELETE `mensagem?id=` | query | `Conversa.Proxy.pas:710-721` | **não** | `rotas.ts:107` | ⚪ morta |
| X1 | POST `alterar-senha` `{senha_atual, senha_nova}` | body | `Conversa.Proxy.Extras.pas:241-257` | **não** (e sem token → 401) | `esquemas.ts:30` espera `{senha_atual, senha}` | ⚪ morta; seria 400 (`senha` ausente) — **[ABRIL]** latente |
| X2 | PUT `mensagem/reacao` `{mensagem_id, emoji}` | body | `Conversa.Proxy.Extras.pas:261-280` | **não** | `rotas.ts:131`, `mensagens.ts:730-760` | ⚪ morta (contrato ok) |
| X3 | POST `mensagem/reproduzir` `{mensagem_id, conversa_id}` | body | `Conversa.Proxy.Extras.pas:282-298` | **não** | espera `{conversa, mensagem}` (`esquemas.ts:66`) | ⚪ morta; seria 400 — **[ABRIL]** latente |
| X4 | GET `pesquisar?texto&conversa` | query | `Conversa.Proxy.Extras.pas:300-320` | **não** | `rotas.ts:128`, `mensagens.ts:378-404` | ⚪ morta (resposta é array de mensagens) |
| X5 | PUT `mensagem` com `referencia:{tipo,destino_mensagem_id}` | body | `Conversa.Proxy.Extras.pas:322-354` | **não** | espera `mensagem_referencia:{tipo, origem_mensagem_id}` (`esquemas.ts:55`) | ⚪ morta; referência **descartada em silêncio** — **[ABRIL]** latente |
| X6 | POST `conversa/digitando` / `gravando` `{conversa_id}` | body | `Conversa.Proxy.Extras.pas:358-390` | **não** | espera `{id}` (`esquemas.ts:41`) | ⚪ morta; seria 400 (`id` ausente) — **[ABRIL]** latente |
| X7 | POST `chamada/video` `{id}` | body | `Conversa.Proxy.Extras.pas:394-409` | **não** | `rotas.ts:207` | ⚪ morta |
| X8 | PUT `chamada/usuario` `{chamada_id, usuario_id}` | body | `Conversa.Proxy.Extras.pas:411-427` | **não** | `rotas.ts:166` | ⚪ morta |
| X9 | GET `chamadas/pendentes` | – | `Conversa.Proxy.Extras.pas:225-237,429-441` | **não** | `rotas.ts:203`, `chamadas.ts:312-330` | ⚪ morta |
| X10 | GET `sip` / PUT `sip` / PATCH `sip` | body | `Conversa.Proxy.Extras.pas:445-484` | **não** | `rotas.ts:216,218,220` | ⚪ morta (PATCH sem `id` seria 400) |
| X11 | GET `anexos?...` | query | `Conversa.Proxy.Extras.pas:488-514` | **não** | `rotas.ts:143`, `anexos.ts:97-169` | ⚪ morta (forma diferente) |
| X12 | POST `anexo/confirmar?identificador=` | query | `Conversa.Proxy.Extras.pas:516-531` | **não** | `rotas.ts:141`, `anexos.ts:83-95` | ⚪ morta (contrato ok, mas ninguém chama) |
| X13 | PUT `usuario` (cadastro) / GET `contatos/online` | body/– | `Conversa.Proxy.Extras.pas:181-221` | **não** | `rotas.ts:39,68` | ⚪ morta |

---

## 3. Anexos — upload, download, cache

**Fluxo correto do servidor (abril e hoje, mesmo contrato — `01-contrato-servidor-atual.md` §8.2):** SHA-256 → `GET /anexo/existe` → `PUT /anexo` **JSON** `{identificador,tipo,nome,extensao,tamanho}` → `{upload_url}` (PUT pré-assinado MinIO, 300 s) → `PUT <upload_url>` com os bytes direto no MinIO (`/storage/`, até 1024 MiB) → `POST /anexo/confirmar?identificador=` → `PUT /mensagem` com `{tipo, ordem, conteudo:<identificador>}`. Download: `GET /anexo?identificador=` → `{url}` (GET pré-assinado 600 s) → baixar da URL **sem Authorization**. É assim que o web faz (`conversa-web/src/services/conversaApi.ts:102-161`).

**O que o FMX faz (`Conversa.Dados.pas:243-290`, `Conversa.Proxy.pas:746-814`):**
- **Hash:** `THashSHA2.GetHashString(ss)` (`Conversa.Dados.pas:272`) — SHA-256, **sobre o arquivo inteiro já carregado em memória** num `TStringStream` (`ss.LoadFromFile`, `:271`). Sem streaming/chunking.
- **`anexo/existe`:** OK (`:279`).
- **Upload (`PUT /anexo`):** manda os **bytes** no corpo (`application/octet-stream`) com `tipo/nome/extensao` em **query** (`Conversa.Proxy.pas:796-807`). Isso é o contrato **pré-MinIO** (`dpr@5f1e9f59`, até 2026-03-07, commit `f28ff10`). O servidor hoje valida corpo JSON → **400** (faltam `identificador`/`tipo`/`tamanho`) para ≤ 1 MiB e **413 HTML** do nginx para > 1 MiB (`bin/nginx/nginx.conf:24`). **Não há `PUT` no MinIO nem `POST /anexo/confirmar`.** Além disso o FMX chama `Anexo.Incluir(0, ...)` com **`tipo` fixo 0** (`Conversa.Dados.pas:280`), que nem é um tipo de anexo válido (`TIPOS_ANEXO=[2,3,4,5]`, `anexos.ts:31`).
- **`PUT /anexo` é JSON ou bytes?** O servidor quer **JSON** (`esquemas.ts:74`); o FMX manda **bytes**. (Q2)
- **Download (`GET /anexo`):** `TAnexo.Download` lê `Response.ToStream.Bytes` como se fosse o arquivo (`Conversa.Proxy.pas:779`) e `DownloadAnexo` grava esses bytes em `PastaDados\anexos\<identificador>` (`Conversa.Dados.pas:229-241`). Mas o servidor devolve **JSON `{url}`** → o arquivo salvo é o texto `{"url":"https://.../storage/..."}`. **O FMX não usa a URL assinada e não baixa do MinIO.** (Q1)
- **Authorization ao MinIO:** N/A — o FMX nunca chega ao MinIO; se chegasse, usaria o `Host` da API (não há montagem da URL assinada).
- **URL expirada (300 s/600 s):** irrelevante, porque o fluxo assinado não é usado.
- **Cache local:** pasta `PastaDados + 'anexos'` (`Conversa.Dados.pas:82,231`); **nome do arquivo = o `identificador` (SHA-256)** → nome seguro, imutável, cache por conteúdo. Observado em disco: `bin/Conversa/anexos/<sha256>` e `%HOME%/Conversa/anexos/<sha256>`.
- **Sanitização do nome vindo do servidor:** o `identificador` não vem do nome, então o cache está protegido. Porém, ao **salvar** um anexo, `SalvarAnexo` monta o nome padrão do `TSaveDialog` com `Cont.Nome`/`Cont.Extensao` **vindos do servidor, sem sanitização** (`Conversa.Dados.pas:376-388`). O diálogo mitiga (o usuário confirma o caminho), mas é um ponto a observar. (Ver §7.)
- **Abrir arquivo:** links em texto são abertos com `ShellExecute(0,'OPEN',...)` (`src/chat/chat/frames/chat.conteudo.texto.pas:121`) sobre o regex `(http|ftp|https)://...` (`:169`). Anexos não têm “abrir”, só “salvar” (move do cache para o destino, `Conversa.Dados.pas:388`).
- **Tipos de conteúdo (1 texto … 8 enquete):** o FMX só conhece **0..4** (`TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo, MensagemAudio)`, `src/Conversa.Tipos.pas:220`). Envio: `Integer(tipo)` (`Conversa.Dados.pas:258`) → texto=1, imagem=2, arquivo=3, áudio=4. **Não há tipo 5 (gravação).**
- **Gravação do microfone vai como 4 ou 5? extensão?** Vai como **tipo 4 (MensagemAudio)**, não 5. O arquivo é salvo como **`.mp3`** (`src/chat/chat/frames/chat.editor.audio.pas:169`), mas o `TAudioCaptureDevice`/`TCaptureDeviceManager` (`:58,105`) grava **WAV/AVI RIFF** — confirmado pelo cabeçalho de um arquivo em cache (`RIFF....AVI LIST`). Ou seja, extensão errada + content-type errado. (Combina com Q2: nunca chega a subir de qualquer forma.)

---

## 4. Modelos e serialização (`src/Conversa.Serializer.pas`, `src/Conversa.Proxy.Tipos.pas`)

- **Datas:** `TJsonSerializer` com `DateTimeZoneHandling = Utc` + `TDateTimeConverter` (`Conversa.Serializer.pas:114-116`). Na leitura, `Null → 0.0`; senão `TTimeZone.Local.ToLocalTime(ISO8601ToDate(valor))` → `TDateTime` **no fuso local** (`:69-87`). O servidor manda ISO-8601 UTC com `Z`; **o FMX converte corretamente para o fuso local.** ✅ (confirmei no RTL `System.DateUtils.pas:3371-3422`: com `ioReturnUTC`, `ISO8601ToDate` respeita o `Z`/offset.) `TDateTime = 0` representa “nulo/ausente”; o código testa `<> 0` antes de usar (`Conversa.Dados.pas:213,582-585`).
- **Campos ausentes/extras:** o `TJsonReader` do RTL ignora propriedades desconhecidas (`System.JSON.Serializers.pas:1897-1903` → `GetClosestMatchProperty=nil` → `Skip`). Logo campos novos do servidor (`fixada_ordem`, `arquivada_em`, `excluida_em`, `transcricao_*`, `reacoes`, `conversa_chat_id`, …) **não quebram o parse** — mas também **não são lidos**.
- **`excluida_em` (mensagem oculta):** `TMensagem` (`Conversa.Proxy.Tipos.pas:99-111`) **não tem o campo** → a mensagem oculta chega com `conteudos` completos (texto original) e é renderizada normalmente (Q6). Não há consumidor de exclusão por WS 3 (o `ObterMensagensStatus` só atualiza `recebida/visualizada`).
- **`visivel_em` (agendada):** o FMX nem envia nem lê `visivel_em`; mensagens agendadas de terceiros simplesmente não aparecem (filtro é do servidor). Benigno.
- **`remetente` (só primeiro nome):** `TMensagem.remetente` recebe o primeiro nome do servidor (`mensagens.ts:511`), mas o FMX **ignora** esse campo e usa `remetente_id` cruzado com o cadastro local (`Conversa.Dados.pas:567-574`), onde o nome completo veio de `/usuario/contatos`. ✅
- **ids como string:** o servidor devolve `id` **string** só em `PUT /anexo` com `existe:true` (`anexos.ts:65`) — irrelevante porque o upload do FMX não usa esse retorno. Demais ids são números. JWT `sub` string é tratado pela lib.
- **status em `/mensagens` × `/mensagem/status`:** `/mensagens` traz `recebida/visualizada/reproduzida` **boolean** (`mensagens.ts:613-615`) e o FMX lê boolean (`TMensagem`, `Conversa.Dados.pas:587-588`). `/mensagem/status` também é **boolean** e o FMX casa (`TMensagemStatus`, item 11) — **diferente do Android**, que esperava datas/por-usuário. ✅
- **Conteúdo tipo 6 (JSON de chamada, datas sem fuso), tipo 7 (figurinha), tipo 8 (enquete):** o FMX **não trata nenhum** (enum 0..4). Ver Q7 — além de aparecer vazio, há risco de **range check** em build Debug.

---

## 5. Rotas do servidor atual que o FMX **não usa**

Das 69 rotas do doc 01 §4, o FMX efetivamente usa ~20 (tabela §2, não-mortas). Agrupadas, o que **não** é usado:

- **Usuário/dispositivo:** `PUT /usuario` (cadastro), `PATCH /usuario`, `DELETE /usuario`, `PUT /dispositivo/usuario`, `POST /alterar-senha`, `GET /usuario/permissoes`.
- **Contatos:** `PUT /usuario/contato`, `DELETE /usuario/contato`, `GET /contatos/online`.
- **Conversas:** `PATCH /conversa`, `DELETE /conversa`, `PATCH /conversa/fixadas`, `PATCH /conversa/arquivada`, `GET /conversa/usuarios`, `DELETE /conversa/usuario`, `POST /conversa/digitando`, `POST /conversa/gravando`.
- **Mensagens:** `DELETE /mensagem`, `POST /mensagem/visualizar` (usa o GET errado), `POST /mensagem/reproduzir`, `GET /mensagem/status/detalhe`, `GET /pesquisar`, `PUT /mensagem/reacao`.
- **Anexos/transcrição:** `POST /anexo/confirmar`, `GET /anexos`, `GET /anexo/transcricao`, `PUT /anexo/transcricao`.
- **Chamadas:** `POST /chamada/cancelar` (usa, ok), `PUT /chamada/usuario`, `POST /chamada/video`, `PUT /chamada/chat`, `GET /chamadas/pendentes`, `GET /ice`. **`GET /ice` não ser usado é crítico para chamadas** (mesma quebra do Android; está na área dos colegas de WebRTC, mas registro aqui porque é uma rota REST).
- **Permissões/parâmetros/atividades:** `GET /permissoes`, `PUT/DELETE /permissao/usuario`, `GET/PATCH /parametros`, `GET /atividades`, `GET /atividades/novas`, `POST /atividades/vistas`.
- **Enquetes:** `PUT/GET/PATCH /enquete`, `POST /enquete/votar`, `POST /enquete/encerrar`.
- **SIP:** `GET/PUT/PATCH /sip`.

Chama o endpoint inexistente `GET /conversa/dados` e usa `GET /mensagem/visualizar` (só existe POST).

---

## 6. Quebras (confirmadas e prováveis)

### 6.1 QUEBRAS CONFIRMADAS

**Q1 — [ABRIL] Download/exibição de anexos: `GET /anexo` devolve JSON `{url}`, o FMX espera bytes.**
- FMX: `Conversa.Proxy.pas:779` (`Result.Dados := Response.ToStream.Bytes`), `Conversa.Dados.pas:229-241` (grava os “bytes” em `anexos/<id>`), `Conversa.Dados.pas:601-603` (`DownloadAnexo` para imagem e áudio), `Conversa.Dados.pas:388` (salvar arquivo).
- Servidor: `anexos.ts:41-56` (JSON `{url}`); desde `f28ff10` (2026-03-07), antes de `56e7cc0`.
- **Efeito:** o arquivo salvo é o texto `{"url":...}`. Imagem → `TImage.LoadFromFile` falha; áudio não toca; “Salvar arquivo” grava um stub JSON com o nome original.

**Q2 — [ABRIL, piorada] Upload de anexos com contrato errado + sem MinIO + sem confirmar.**
- FMX: `Conversa.Proxy.pas:788-814` (bytes em `PUT /anexo?tipo&nome&extensao`), `Conversa.Dados.pas:279-280` (chama `Anexo.Incluir(0, ...)`, `tipo=0`).
- Servidor: `esquemas.ts:74` + `anexos.ts:58-81` (JSON `{identificador,tipo,nome,extensao,tamanho}` → `{upload_url}`); nginx `client_max_body_size 1m` (`bin/nginx/nginx.conf:24`).
- **Efeito:** ≤ 1 MiB → **400** de validação; > 1 MiB → **413 HTML** do nginx. Nunca sobe o arquivo; o `PUT /mensagem` ainda referencia um identificador que não existe no MinIO → o destinatário (web) não baixa. Já quebrava em abril (500); hoje 400/413.

**Q3 — [ABRIL] `GET /mensagem/visualizar` não existe (servidor só tem POST).**
- FMX: `Conversa.Proxy.pas:723-744` (GET), `Conversa.Dados.pas:346-350`, disparado por `Conversa.Chat.pas:164-165,287-289` e `chat.mensagem.pas:268-269` (ao exibir cada bolha).
- Servidor: `rotas.ts:112` + `esquemas.ts:66` (POST `{conversa,mensagem}`); virou POST em `9b9a32f` (2026-03-10). **404 confirmado no servidor vivo.**
- **Efeito:** nenhuma mensagem é marcada como visualizada no servidor → o remetente nunca vê “visualizada” (azul); contadores de não-lidas do outro lado não baixam. `Tentativa(5)` só repete à toa (404 não é `Unknown`).

**Q4 — [ABRIL] `GET /conversa/dados` não existe → 404 ao abrir cada conversa.**
- FMX: `Conversa.Proxy.pas:572-605`, `Conversa.Chat.pas:173-178` (`SetConversa` chama para toda conversa com `ID<>0`).
- Servidor: ausente em `rotas.ts` e em `dpr@56e7cc0`. **404 confirmado no servidor vivo.**
- **Efeito:** a montagem de participantes por essa via falha (os nomes ainda vêm de `/conversas` + `/usuario/contatos`, então o chat não fica vazio). Como `ValidarErro` só dispara `TErroServidor` e **ninguém assina** no app, o erro é **silencioso** (nem popup). Substituto correto: `GET /conversa/usuarios?conversa=` (`conversas.ts:204-221`).

**Q5 — [ABRIL] Histórico de chamadas (`GET /chamadas`) com campos que não existem.**
- FMX: `Conversa.Proxy.Tipos.pas:194-216` (`TChamadaHistorico` espera `chamada_id`, `tipo_chamada`, `status_chamada`, `criado_por_id`, `usuario_exibido_id/nome`, `tipo_acao`, `quantidade_outros_usuarios`, `adicionado_em`), consumidos em `Conversa.Chamada.Listagem.Item.pas:78-131` e `Conversa.Chamada.Detalhe.pas:76-126`.
- Servidor: `chamadas.ts:416-450` devolve `{id,tipo,status,criado_em,criado_por,conversa_id,iniciada,finalizada,duracao,participantes:[{usuario_id,nome,status,duracao,avatar_url}]}`. Nenhum dos campos esperados existe (nem em `api.pas@56e7cc0:2445-2591`).
- **Efeito:** a lista de chamadas (botão “Chamadas”, `Conversa.Principal.pas:77`) mostra itens com nome/ícone/duração zerados; datas desde `95430ba` vêm com `Z` (o conversor aceita).

**Q6 — [NOVA] Mensagens ocultadas aparecem com o texto original.**
- FMX: `src/Conversa.Tipos.pas:220` + `Conversa.Proxy.Tipos.pas:99-111` (sem `excluida_em`); `Conversa.Dados.pas:591-606` monta os conteúdos; render em `chat.visualizador.pas:150-222`.
- Servidor: exclusão lógica (`mensagens.ts:303-314`), `excluida_em` na resposta (`:518,611`), conteúdo **não filtrado** (`:406-456`); migração `031.sql`. [NOVA] desde `b94b504`.
- **Efeito:** o FMX exibe o texto/arquivo da mensagem que deveria estar oculta; não há consumo do WS 3 para esconder.

**Q7 — [NOVA p/ 7 e 8; ABRIL p/ 5 e 6] Conteúdos tipo 5/6/7/8 desconhecidos quebram a exibição.**
- FMX: enum `TTipoConteudo` só 0..4 (`src/Conversa.Tipos.pas:220`); `EventoObterMensagens` faz `TTipoConteudo(Ctd.tipo)` (`Conversa.Dados.pas:596`) e `chat.visualizador.pas:150` trata só 4 ramos; `Conversa.Chat.pas:196` faz `TTipo(Pred(Integer(tipo)))`.
- Servidor: tipo 5 gravação (abril), 6 chamada/JSON (abril), 7 figurinha (`315464b`), 8 enquete (`8031fa5`), devolvidos junto com 1 (`mensagens.ts:409-446`).
- **Efeito:** no mínimo bolha vazia. **Em build Debug** (`Conversa.dproj:194-195`, `DCC_IntegerOverflowCheck`/`DCC_RangeChecking = true`) o cast `TTipoConteudo(5..8)` dispara `ERangeError` e **aborta o carregamento da thread de mensagens** — basta um resumo de chamada (tipo 6) ou uma figurinha/enquete do web na conversa.

### 6.2 QUEBRAS PROVÁVEIS

**Q8 — [ABRIL] `GET /mensagens/novas` manda `ultima` (int), o servidor espera `desde` (ISO).**
- FMX: `Conversa.Proxy.pas:290` (`AddPair('ultima', ...)`); servidor `esquemas.ts:68` + `mensagens.ts:694-725` só olham `desde`. `ultima` já não era lido em `56e7cc0` (`dpr@56e7cc0:408` usa `desde`).
- **Efeito:** `desde=''` → “desde sempre”; a cada evento WS de nova mensagem o FMX recarrega as novas do zero. **Funciona** (lê `conversa_id`/`mensagem_id`), mas é ineficiente e ignora o cursor.

**Q9 — [NOVA] Porta/URL padrão (`:4430` → `:443`) e MediaMTX direto.**
- O nginx de dev passou a escutar **443** (`conversa/bin/nginx/desenvolvimento/servidor.conf:2`; antes 4430). O `conversa.json` local tem `"Host":"https://localhost:4430/api/"` e `"MediaMtxBase":"http://localhost:8889"` (direto, não via `/webrtc`).
- **Efeito:** com a config padrão de dev, as chamadas REST vão para `:4430` (recusa de conexão) até o usuário corrigir o Host em `ConfigurarConexao`. Em produção o Host aponta para a borda (80/443). É configuração, não código — por isso 🟠.

**Q10 — [NOVA] Gravação do microfone vai como tipo 4 e extensão `.mp3` sobre arquivo WAV.** Ver §3. Semântico; só importaria depois de Q2 ser resolvido.

---

## 7. Outros problemas (segurança, bugs, threads)

- **ALTO — Token duplicado e nunca inicializado em `TAPIExtras`.** `Conversa.Proxy.Extras.pas:153,163-170`: um segundo `FToken` de classe que só seria preenchido por `TConversaExtrasAuth.SetToken`, **nunca chamado**. Se qualquer endpoint de `Proxy.Extras` for ligado, todas as chamadas vão **sem `Authorization` → 401**. Hoje é latente porque a unit inteira é código morto.
- **ALTO — `Conversa.Proxy.Extras.pas` é código morto (533 linhas).** Além do token, embute contratos já errados (`alterar-senha` com `senha_nova`, `digitando/gravando` com `conversa_id`, `reproduzir` com `mensagem_id/conversa_id`, `mensagem` com `referencia/destino_mensagem_id`, `sip` PATCH sem `id`). Se migrarem para cá achando que “está pronto”, herdam as quebras latentes do Android (doc 02 §9.1-12 e §9.1-4).
- **MÉDIO — Erros de servidor silenciosos.** `ValidarErro` dispara `TErroServidor` + `Abort` (`Conversa.Proxy.pas:154-167`), mas **nenhum componente do app assina `TErroServidor`** (só `teste/Exemplo.Principal.pas`). 404 de `/conversa/dados`, 400 de anexo etc. não chegam ao usuário nem ao log.
- **MÉDIO — Chamadas REST síncronas na thread de UI.** `Login`, `CarregarContatos`, `NovoChat`, `Anexo.Existe`/`Download` rodam sem thread e sem timeout explícito (defaults ~60 s do `TNetHTTPClient`). Servidor lento/indisponível **congela a janela**.
- **MÉDIO — Senha do usuário guardada no disco.** `conversa.json` guarda `Senha` cifrada (`Conversa.Login.pas:82`, `Conversa.Configuracoes.pas:16`), com AES-256-CBC cuja chave deriva do **serial da placa-mãe (WMI)** + salt, IV fixo `'1234567890123456'` (`lib/AES/Conversa.AES.pas:30,34-37`). Não é enviada a serviço nenhum, mas contraria a regra “nunca guardar a senha” e a chave é recuperável localmente. (Observação, não vazamento de rede.)
- **BAIXO — Nome/extensão do servidor sem sanitização ao salvar.** `SalvarAnexo` usa `Cont.Nome`/`Cont.Extensao` do servidor no `TSaveDialog.FileName` (`Conversa.Dados.pas:376-388`) sem filtrar separadores/`..`. O diálogo com confirmação do usuário mitiga; o cache em si é seguro (nome = SHA-256).
- **BAIXO — 3xx tratado como sucesso.** `TResponse.Value` (`REST.API.pas:477-478`) classifica 1..3xx como `Sucess`. Hoje o `/api` não redireciona, mas um 301/302 (ex.: http→https do nginx) seria lido como corpo vazio “ok”.
- **BAIXO — `GetURI` usa `Length(Result)` onde deveria ser `Length(sURL)`** (`REST.API.pas:329`). Acidentalmente inócuo porque `sURL` é passado por `var` sobre o próprio `Result` nas chamadas atuais, mas é um bug latente de montagem de URL.
- **BAIXO — Sem keep-alive / pool.** Um `TNetHTTPClient` por requisição (`REST.API.pas:197`); custo de handshake TLS a cada chamada.

---

## 8. Resumo do estado

O FMX **funciona** para: login, registro de dispositivo (manda `id`, ao contrário do Android), lista de conversas, lista de contatos, criação de conversa/grupo, envio e recebimento de **mensagens de texto**, status de mensagem (boolean), e o ciclo básico de chamada (`iniciar/entrar/sair/recusar/cancelar/finalizar/dados`). **Está quebrado** para: todo anexo (upload Q2 e download Q1), marcação de visualizado (Q3), `conversa/dados` (Q4), histórico de chamadas (Q5), mensagens ocultas (Q6) e conteúdos tipo 5/6/7/8 (Q7, com risco de crash em Debug). A maioria dos demais contratos divergentes está em **código morto** (`Conversa.Proxy.Extras.pas` e vários métodos de `Conversa.Proxy.pas`), que são quebras **latentes**. A camada HTTP em si é sólida e segura (TLS do SO, Bearer, sem log de segredos), mas sem timeout/relogin e com erros silenciosos.
