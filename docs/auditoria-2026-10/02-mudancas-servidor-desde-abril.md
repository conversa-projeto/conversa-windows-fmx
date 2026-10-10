# 02 — Mudanças no servidor desde abril/2026 e o contrato que o FMX usa

**Data:** 2026-10-08 · **Cliente:** `conversa-windows-fmx`, branch `chamada`, HEAD **`4759ba5`** (2026-04-26) + alterações *staged* em `Conversa.Dados.pas` (URL do WebSocket) e `src/chamada/Conversa.Chamada.WebRTC.pas` (só o comentário do cabeçalho) · **Servidor:** abril **`56e7cc0`** (2026-04-19, Delphi/Horse) → atual **`779c8ed`** (2026-10-08, Bun/Elysia) · **Web (referência):** `conversa-web` **`e8d82cb`**.
**Modo:** somente leitura nos quatro repositórios. O build por linha de comando **não foi possível** (Delphi 12.1 Community bloqueia `msbuild`/`dcc32`/`dcc64`, doc 04 §2.3): tudo aqui vem da leitura do código, e o que depende de execução está marcado como **"não confirmado"**.

Este documento é a versão FMX do doc 02 da auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/02-mudancas-servidor-desde-abril.md`). Ele consolida os relatórios `apoio/A2` (REST e anexos, a base), `apoio/A3` (WebSocket, sessão, push), `apoio/A4` (chamadas e mídia) e `apoio/A7` (servidor × desktop sempre conectado), com as evidências conferidas de novo nos repositórios.

---

## 0. Referências e método

| Item | Valor |
|---|---|
| Cliente auditado | `conversa-windows-fmx` (Delphi 12 / FireMonkey, alvo Windows). Árvore de trabalho = HEAD `4759ba5` + *staged*. As citações `arquivo:linha` sem commit referem-se à árvore de trabalho. O HEAD sem o *staged* é citado como `@4759ba5`. |
| Servidor de abril | `conversa` em **`56e7cc0`** (2026-04-19, "Adiciona agendamento de mensagens"). Lidos com `git show 56e7cc0:<caminho>`: `conversa.rest.dpr` (rotas, portas), `src/conversa/conversa.api.pas` (handlers), `src/conversa/WebSocket.pas`, `src/conversa/conversa.migracoes.pas`, `bin/nginx/conf/nginx.conf`, `bin/mediamtx/mediamtx.yml` e o build do web de abril em `bin/web/assets/`. Nenhum commit em nenhum branch entre 2026-04-19 e 2026-09-12. |
| Servidor atual | `conversa` em **`779c8ed`** (2026-10-08). Para efeito de contrato é igual a `5cad911`: `779c8ed` só altera `bin/iniciar-desenvolvimento.bat`. Árvore de trabalho limpa. Fontes: `src/rotas.ts`, `src/esquemas.ts`, `src/app.ts`, `src/autenticacao.ts`, `src/websocket.ts`, `src/notificacoes.ts`, `src/mensagens.ts`, `src/conversas.ts`, `src/chamadas.ts`, `src/anexos.ts`, `src/usuarios.ts`, `bin/nginx/nginx.conf`, `bin/nginx/desenvolvimento/servidor.conf`, `bin/mediamtx/mediamtx.docker.yml`, `bin/coturn/turnserver.conf`, `docker-compose.yml`. |
| Commits entre os dois | **26** (`aa61b78` … `779c8ed`), §1. |
| Web | `conversa-web` em `e8d82cb` (2026-10-08), referência de comportamento (`src/services/conversaApi.ts`, `src/stores/call.ts`, `src/stores/chat.ts`). |
| Contrato | Doc 01 desta pasta (`01-contrato-servidor-atual.md`, revalidado em `779c8ed`). Problemas do FMX: doc 04 (`#1`–`#103`). Pendências do servidor: doc 08 (`S1`–`S24`). |
| Configuração local | `bin/Conversa/conversa.json` (não versionado, `.gitignore:43`). Para não expor credenciais, **só** as chaves `Host` e `MediaMtxBase` foram lidas: `"Host":"https://localhost:4430/api/"`, `"MediaMtxBase":"http://localhost:8889"`. |

**Convenções**

- `dpr@56e7cc0:N` = `conversa.rest.dpr` no commit de abril; `api.pas@56e7cc0:N` = `src/conversa/conversa.api.pas`; `ws.pas@56e7cc0:N` = `src/conversa/WebSocket.pas`; `nginx@56e7cc0:N` = `bin/nginx/conf/nginx.conf`; `migracoes.pas@56e7cc0:N` = `src/conversa/conversa.migracoes.pas`.
- Arquivos `.ts` sem prefixo = `conversa/src/` no HEAD atual. Demais arquivos do servidor levam o prefixo `conversa/` (ex.: `conversa/bin/nginx/nginx.conf:24`).
- Arquivos `.pas`, `.dpr`, `.dproj`, `lib/…`, `src/…` sem `@commit` = FMX (árvore de trabalho), relativos à raiz de `conversa-windows-fmx/`. Web = prefixo `conversa-web/`.
- **[NOVA]** = quebra introduzida entre `56e7cc0` e hoje (funcionava com o servidor de abril). **[ABRIL]** = o FMX já era incompatível com o servidor de abril e continua.
- Vereditos: ✅ compatível · 🔴 quebra confirmada · 🟠 quebra provável/parcial · ⚪ código morto (não roda) · ⬜ não tratado/não implementado.

**Achado transversal — boa parte do contrato do FMX é código morto.** A coluna **"Roda?"** da §3 separa o que executa do que não executa:

- `src/Conversa.Proxy.Extras.pas` (533 linhas: `alterar-senha`, `mensagem/reacao`, `mensagem/reproduzir`, `pesquisar`, `mensagem` com referência, `conversa/digitando`, `conversa/gravando`, `chamada/video`, `chamada/usuario`, `chamadas/pendentes`, `sip`, `anexos`, `anexo/confirmar`, cadastro, `contatos/online`) **não está no `Conversa.dpr` nem no `Conversa.dproj`, e nenhuma unit faz `uses` dela** (grep). Além disso, ela tem um segundo token de classe (`Conversa.Proxy.Extras.pas:153`) que só `TConversaExtrasAuth.SetToken` preencheria (`:174-177`), e isso nunca é chamado; sem token, `TAPIExtras.Create` não põe `Authorization` (`:163-164`) → toda chamada daria **401**.
- Em `src/Conversa.Proxy.pas`, não têm chamador: `TUsuario.Incluir/Alterar/Excluir` (`:341-396`), `TDispositivoProxy.Incluir` (`:422-450`) e `.Usuario` (`:472-483`), `TContato.*` (`:487-511`), `TConversa.Alterar/Excluir` (`:541-570`), `TConversaUsuario.Excluir` (`:626-637`), `TMensagem.Excluir` (`:710-721`). (`teste/Conversa.Proxy.pas` é uma cópia antiga usada só pelo projeto de teste.)

Consequência: a maior parte das divergências de contrato do FMX é **latente** (§10.3). As quebras que o usuário sente estão nas ~23 chamadas vivas.

---

## 1. Linha do tempo dos commits do servidor desde 2026-04-19

**Base `56e7cc0` (abril):** Delphi + Horse na porta **8080** (`dpr@56e7cc0:588-589`); WebSocket próprio (Bird Socket) na porta **9090** (`dpr@56e7cc0:571`); nginx nativo no Windows escutando **4430 com TLS** e **80 sem TLS** (`nginx@56e7cc0:28`, `:94`), repassando `/api/` → 8080, `/ws/` → 9090, `/webrtc/` → MediaMTX nativo em `127.0.0.1:8889`, `/storage/` → MinIO (`nginx@56e7cc0:21-24`); corpo de até 1024 MiB (`nginx@56e7cc0:12`); JWT de 12 h (`dpr@56e7cc0:120`, `IncHour(Now, 12)`); push FCM com bloco `notification`.

Tabela copiada do doc 02 do Android (linhas 1–25), com as menções ao Android trocadas pelo FMX e uma coluna com o efeito no FMX; a linha 26 é nova.

| # | Commit | Data | Título | O que mudou para clientes | No FMX |
|---|---|---|---|---|---|
| 1 | `aa61b78` | 2026-09-12 | Ambiente | Ainda Delphi. **Novo `GET /api/ice`** (`TConversa.IceServers`) devolvendo `{iceServers:[{urls,username,credential}], iceTransportPolicy:'relay'\|'all'}` com credencial TURN HMAC-SHA1 (formato `use-auth-secret` do coturn); parâmetros `turn_url`, `turn_secret`, `turn_forcar_relay` (padrão `'1'`, migração 23). Entram coturn (`bin/coturn/turnserver.conf`) e MediaMTX em Docker (`bin/mediamtx/mediamtx.docker.yml`), `docker-compose.yml`, nginx para Docker. Cria o bucket do MinIO na partida. | Não chama `/ice` → Q11 |
| 2 | `97f9341` | 2026-09-13 | Converte a API para Node e padroniza o ambiente em Docker | **Reescrita total** em TypeScript (Fastify + postgres.js). Mesmo conjunto de rotas (`/api/...`) e mesmos números de evento WS. **WebSocket passa a ser servido pela própria API em `/ws/` (porta 8080)**, não mais 9090; nginx em Docker repassa `/ws/` para a API. **nginx de DEV passa a escutar 443** (antes 4430). Validação de esquema Fastify (400 antes do handler). `mensagemreferencia` limitado a 0..1000 (corrigido em `cb7ef68`). `PUT /conversa/usuario` de membro existente devolve o registro em vez de erro de chave duplicada. Segredos (pepper, MinIO, TURN) gerados no volume `conversa-dados`; `turn_url`/`turn_secret`/`s3_endpoint` saem dos parâmetros (migrações 024–026): URLs de anexos e TURN passam a ser montadas a partir do `Host`/`X-Forwarded-Proto` da requisição. MediaMTX/nginx nativos de Windows removidos. FMX ainda com `notification:{title,body}`. | Porta 4430 → 443 (Q12); dev só com TLS → `wss` obrigatório (Q9); corpo de 1 MiB em `/api/` (Q2 piora); MediaMTX só por TURN (Q11); `conversa/usuario` idempotente (melhora, §3.1) |
| 3 | `6c1ee03` | 2026-09-15 | Altera porta padrão do postgres | Só infraestrutura (Postgres publicado em 5433). Sem efeito no contrato. | — |
| 4 | `2299a5c` | 2026-09-17 | Corrige notificações e mensagem de chamada; adiciona transcrição de áudio | `GET /mensagens` ganha `conteudos[].transcricao_status` e `conteudos[].transcricao`. Novos `GET` e `PUT /api/anexo/transcricao`. `GET /mensagens/novas` ignora mensagens já visualizadas e trunca `ate` em milissegundos. Mensagem-resumo de chamada (conteúdo tipo 6) já nasce lida para quem participou, e o evento WS 3 dela vai para **todos** os membros (inclusive quem ligou). Migração 027. | Campos novos ignorados; `/mensagens/novas` filtra visualizadas (com Q3, devolve sempre as mesmas conversas) |
| 5 | `6fd4733` | 2026-09-22 | Ajusta notificações push | **Push FCM passa a ser só `data`** = `{titulo, mensagem, conversa}` + `webpush.headers.Urgency=high`; o bloco `notification` some. Texto do push/WS com menção `@[Nome](id)`→`@Nome` e blocos de código resumidos; espaços deixam de virar `" \| "`. | Não usa FCM (§6) |
| 6 | `5159c5b` | 2026-09-23 | Adiciona script para subir o desenvolvimento | Só script. | — |
| 7 | `cb7ef68` | 2026-09-25 | Corrige pesquisa e contexto de mensagens | `mensagemreferencia` aceita ids > 1000 (no Node entre `97f9341` e aqui, id > 1000 dava 400). Pesquisa com `unaccent` + `ilike`. **Novo `GET /api/mensagem/status/detalhe?id=`**. Migração 028. | Pesquisa só em código morto |
| 8 | `95430ba` | 2026-09-26 | Migra a API para Bun e Elysia | Fastify→**Elysia** (validação TypeBox; erro `{error}`; mensagens de validação em PT). OpenAPI em `/api/docs` (JSON em `/api/docs/json`). Datas do histórico de chamadas (`GET /chamadas`) passam de texto sem fuso (`to_char`) para ISO com `Z`; `reagido_em` das reações com fuso. **Senha atual errada em `/alterar-senha` → 400** (antes 401). **Novos `PATCH /conversa/fixadas` e `PATCH /conversa/arquivada`** (migração 029); `GET /conversas` ganha `fixada_ordem` e `arquivada_em`; conversa arquivada não gera push. **`POST /chamada/entrar` e `/chamada/recusar` passam a notificar também o próprio usuário** (eventos 54/53 com `usuario_id` = ele mesmo). | WebSocket do Bun com *ping* automático (Q10); arquivadas aparecem e notificam (#42); 53/54 próprios ignorados (#30) |
| 9 | `abfd3d5` | 2026-09-27 | Sobe a API de novo quando ela cai no desenvolvimento | Só script de desenvolvimento. | — |
| 10 | `f1ffb14` | 2026-09-28 | Isola anexos abertos direto pelo endereço de /storage/ | nginx manda `Content-Security-Policy: sandbox` em `/storage/` (exceto PDF). Não afeta download por app nativo. | O FMX nunca chega ao `/storage/` (Q1) |
| 11 | `09c2c8d` | 2026-09-28 | Ajusta a transcrição para a versão Windows do transcritor-api | Interno (não manda `num_speakers`). | — |
| 12 | `0b67aca` | 2026-09-29 | Adiciona testes unitários | `GET /chamada/dados` e `POST /chamada/video` validam participação: chamada inexistente/alheia → **404** (antes 500). `digitando`/`gravando` passam a exigir participação na conversa (**403**). | Sem efeito prático (o FMX só consulta chamadas de que participa; não envia digitando) |
| 13 | `8e81360` | 2026-09-30 | Corrige acesso a dispositivos, exclusão de conta e erros 500 da API | `PATCH /dispositivo` só altera dispositivo do próprio usuário (**403**). Login só reaproveita `dispositivo_id` que pertence à pessoa (senão cria outro). `DELETE /usuario` remove dispositivos; conta com histórico → **409**. Anexo inexistente → **404**; arquivo > 1 GiB → **400**; pesquisa vazia → **400** (antes 500). | `DispositivoId` é por máquina: alternar contas no mesmo PC cria um dispositivo a cada troca (#86) |
| 14 | `5272c9f` | 2026-09-30 | Confere o dono ao vincular dispositivo; acelera os testes | `PUT /dispositivo/usuario` só vincula dispositivo do próprio usuário (**403**). | Rota só em código morto (M2) |
| 15 | `4bbfb0a` | 2026-10-02 | Grava o áudio e o vídeo das chamadas para auditoria | MediaMTX grava os caminhos `call-*` em fMP4 (`mediamtx.docker.yml:32-37`). **Vídeo só é gravado em H264 ou VP9; VP8 não é gravado** (`mediamtx.docker.yml:31`). Parâmetro `gravacao_dias` (migração 030). | O FMX publica H264 **da tela inteira** (#1): seria gravado (§7.3) |
| 16 | `b94b504` | 2026-10-02 | Excluir marca a mensagem em vez de apagar | **`DELETE /mensagem` vira exclusão lógica**: grava `excluida_em`/`excluida_por` (migração 031); a mensagem continua em `GET /mensagens` com `excluida_em` preenchido e conteúdo completo; só o autor exclui, sem prazo; agendada não enviada é apagada de vez. Aviso pelo WS 3 e em `GET /mensagem/status` (`excluida_em`). Pesquisa ignora excluídas; prévia e citações não mostram o texto. | **Q6** |
| 17 | `315464b` | 2026-10-03 | Sinal da chamada, chat da chamada e figurinhas | **Novo evento WS 57 (`SinalChamada`)**, bidirecional, só entre participantes. **Novo `PUT /api/chamada/chat`** (migração 032; `GET /chamada/dados` ganha `conversa_chat_id`). **Conteúdo tipo 7 = figurinha** (`conteudo` = `pacote/nome`, regex `^[a-z0-9-]{1,40}\/[a-z0-9-]{1,40}$`, `mensagens.ts:134`). | WS 57 ignorado; tipo 7 → **Q7** |
| 18 | `a82d373` | 2026-10-03 | Pasta das gravações nasce com o dono certo, sem container auxiliar | Só infraestrutura. | — |
| 19 | `184904b` | 2026-10-05 | Dev Container instala as dependências ao conectar | Só ambiente. | — |
| 20 | `f095bf1` | 2026-10-05 | Prévia da conversa diz "Mensagem oculta" | `GET /conversas`: `ultima_mensagem_texto` = `"Mensagem oculta"` quando a última mensagem foi excluída (`conversas.ts:127`). | A lista do FMX mostra "Mensagem oculta", mas o chat mostra o conteúdo (Q6) |
| 21 | `8283616` | 2026-10-05 | Atividades: reações, respostas, menções e chamadas perdidas | **Novos `GET /atividades`, `GET /atividades/novas`, `POST /atividades/vistas`**; **novo evento WS 61**; `POST /chamada/recusar` aceita `nao_atendeu: boolean` (evento de chamada 8). Migração 033. | WS 61 ignorado; sem `nao_atendeu` (#61) |
| 22 | `7f670c3` | 2026-10-06 | Permissões do sistema e parâmetros alterados pela API | **Novos `GET /usuario/permissoes`, `GET /permissoes`, `PUT`/`DELETE /permissao/usuario`, `GET`/`PATCH /parametros`** (403 sem permissão). Migração 034. Só `parametros.ts:12,58` e `permissoes.ts:57,82,98` chamam `validarPermissao`. | Nenhuma rota usada pelo FMX passou a exigir permissão |
| 23 | `8031fa5` | 2026-10-06 | Votação em grupo: enquete com escolha única ou múltipla | **Novos `PUT /enquete`, `GET /enquete?id=`, `POST /enquete/votar`**; **novo evento WS 62** `{enquete_id, conversa_id}`; **conteúdo tipo 8** = id da enquete (só o servidor grava). Migração 035. Detalhes: doc 01 §10.13. | Tipo 8 → **Q7**; WS 62 ignorado |
| 24 | `d4435db` | 2026-10-07 | Reações: no máximo 5 emojis diferentes por pessoa na mesma mensagem | `PUT /mensagem/reacao` recusa o 6º emoji diferente: 400. Detalhes: doc 01 §10.12. | O FMX não reage |
| 25 | `5cad911` | 2026-10-07 | Votação com data final e encerramento antes do prazo | **Novos `POST /enquete/encerrar` e `PATCH /enquete`**; `encerra_em` na criação; campos novos no `Enquete`; votar encerrada → 400; WS 62 também ao encerrar e ao mudar a data. Migração 036. | O FMX não tem votação |
| 26 | `779c8ed` | 2026-10-08 | iniciar-desenvolvimento.bat atualiza também as dependências da API | Só `bin/iniciar-desenvolvimento.bat`. **Sem mudança de contrato.** | — |

### 1.1 O FMX já estava atrás **antes** de abril

Conferido no `git log` dos dois repositórios: o contrato que o FMX usa é o da **árvore antiga do servidor** (`rest/conversa.rest.dpr`, Delphi), que foi substituída por uma árvore nova na raiz em `61b7dbe` (2026-03-01, "Adiciona HTTPS e cliente web") e apagada em `eb59c61` (2026-03-13). Entre março e abril o servidor mudou vários contratos e o FMX não acompanhou — nem no commit `4759ba5` (2026-04-26), sete dias **depois** do servidor de abril.

| Data | Commit | O que mudou no servidor | Efeito no FMX |
|---|---|---|---|
| 2025-08-03 | FMX `e970c92` | O FMX passa a abrir o WS em `ws://host:(8000 + porta do Host)`, igual ao servidor da época (`rest/conversa.rest.dpr@786a7a8:398`, `TWebSocket.Iniciar(8000 + Configuracao.Porta, …)`) | Regra certa naquela data |
| 2026-03-01 | `61b7dbe` | Nova árvore do servidor na raiz. A `rest/conversa.rest.dpr` antiga tinha `GET /conversa/dados`, `GET /mensagem/visualizar`, `?ultima=` e o `/anexo` por bytes (`rest/conversa.rest.dpr@61b7dbe~1:308`, `:359-374`, `:397-398`, `:434`); a nova raiz **não tem `/conversa/dados`** (`git show 61b7dbe:conversa.rest.dpr`) | Q4 |
| 2026-03-07 | `f28ff10` | "Adiciona upload para MinIO": `GET /anexo` passa a devolver JSON `{url}` (`Res.Send<TJSONObject>`) e `PUT /anexo` passa a ler JSON `{identificador, tipo, nome, extensao, tamanho}` em vez de bytes + query (diff de `conversa.rest.dpr`) | Q1, Q2 |
| 2026-03-08 | `2b9a06d` | "Migra https para o nginx": API em 18080 e WS em 19090, atrás do nginx; o WS deixa de estar em `8000 + porta` | A URL do WS do HEAD do FMX deixa de acertar (Q9) |
| 2026-03-10 | `9b9a32f` | `mensagem/visualizar` passa de `THorse.Get` com query para `THorse.Post` com corpo (diff de `conversa.rest.dpr`) | Q3 |
| 2026-03-13 | `eb59c61` | Apaga a árvore `rest/`, levando junto o modelo de histórico com `usuario_exibido_*` (criado em `927bf19`, 2026-01-30) | Q5 (o FMX copiou esse modelo em `3d57153`, 2026-02-02) |
| 2026-03-21 | `e8f60fd` | API em 8080 e WS em 9090 (situação de abril) | — |
| 2026-04-19 | `56e7cc0` | **No próprio commit de abril**, `/mensagens/novas` troca `Field('ultima').AsInteger` por `Field('desde').AsString` (diff de `conversa.rest.dpr`; `dpr@56e7cc0:404-410`) | Q8 |

Por isso a maioria das quebras da §10 é **[ABRIL]** (placar na §10.4): o FMX já não conversava direito com o servidor que existia quando o HEAD foi feito.

---

## 2. Regras gerais (valem para todas as rotas)

| Aspecto | Abril (`56e7cc0`, Delphi/Horse) | Hoje (`779c8ed`, Bun/Elysia) | **FMX hoje** |
|---|---|---|---|
| Prefixo | `/api/...` (`dpr@56e7cc0:105` etc.) | `/api/...` (`rotas.ts:29`, `prefix: '/api'`) | ✅ O `/api/` faz parte do `Configuracoes.Host` (`src/configuracoes/Conversa.Configuracoes.pas:14`), aplicado em `src/Conversa.Proxy.pas:114`. Não há campos separados de host/porta/caminho; o endereço só é pedido na primeira execução (#70). |
| Autenticação | Horse.JWT; livres `/api/login` e `/api/cadastro` (`dpr@56e7cc0:81-84`; `PUT /api/usuario` exigia token) | `Authorization: Bearer <jwt>` (`autenticacao.ts:26-30`); livres `POST /login` e `PUT /usuario` (`rotas.ts:34-39`); o resto passa pelo `resolve` (`rotas.ts:43`) | ✅ `TAuthBearer` injeta `Bearer <token>` (`REST.API.pas:398-414`, `:712-726`); token em `class var` (`src/Conversa.Proxy.pas:98`), preenchido no login (`:205`). |
| Validade do JWT | **12 h** (`dpr@56e7cc0:120`, `IncHour(Now, 12)`) | **12 h** (`autenticacao.ts:6`, `exp: '12h'`), sem *refresh* | 🔴 Igual a abril, mas o FMX **não trata 401** em lugar nenhum (só o login trata 4xx, `src/Conversa.Proxy.pas:184-196`). Um app de bandeja passa de 12 h todo dia e para de carregar em silêncio (#4). Não é quebra de contrato: já era assim em abril. |
| Formato de erro | `{"error": "..."}` (Horse.HandleException) | `{"error": "..."}` (`app.ts:56-77`) | ✅ `TAPIInternal.InternalExecute` lê `error`; sem ele, usa o corpo cru (`src/Conversa.Proxy.pas:121-135`). Erros do nginx (413, 502, 503) vêm em **HTML** e aparecem crus. |
| Validação | Manual (`CamposObrigatorios` → 400); erros não previstos → 500 | Esquema TypeBox antes do handler → **400** (`app.ts:62-65`); corpo ilegível → 400 `Corpo da requisição inválido!` (`app.ts:70-72`); campos extras ignorados | ✅ O FMX manda campos a mais (`inserida` em `PUT /conversa`) e eles são ignorados. Erros de servidor passam por `ValidarErro` → `TErroServidor` **sem assinante** + `Abort` (`src/Conversa.Proxy.pas:154-167`): **silenciosos** (#25). |
| Rota inexistente | Resposta padrão do Horse | **404** `{"error":"Rota GET:/api/xxx não encontrada"}` (`app.ts:66-69`) | 🔴 O FMX chama duas rotas que não existem (`GET /conversa/dados`, `GET /mensagem/visualizar`): Q3, Q4. |
| Datas | `DateToISO8601` → `…Z`; exceção: `GET /chamadas` com `to_char` sem fuso | `JSON.stringify(Date)` → `…Z`; `GET /chamadas` também com `Z` (`95430ba`) | ✅ `TJsonSerializer` com `TDateTimeConverter`: `null` → `0`; senão `TTimeZone.Local.ToLocalTime(ISO8601ToDate(valor))` (`src/Conversa.Serializer.pas:69-88`, registrado em `:114-116`). Converte UTC → fuso local corretamente. Só o JSON do conteúdo tipo 6 tem datas sem fuso, e o FMX não o lê (Q7). |
| Tamanho do corpo em `/api/` | `client_max_body_size 1024m` (`nginx@56e7cc0:12`) | **`client_max_body_size 1m`** (`conversa/bin/nginx/nginx.conf:24`); só `/storage/` aceita 1024m (`:128`) | 🔴 O upload do FMX manda o arquivo inteiro no `PUT /api/anexo` → **413 em HTML** acima de 1 MiB (Q2). Um texto acima de 1 MiB também daria 413. |
| Limite de login | Não havia | `limit_req` 10/min, rajada 5, só em `location = /api/login` (`conversa/bin/nginx/nginx.conf:74`, `:97-100`) → **503 em HTML** | 🟠 5xx mantém a senha salva e mostra o HTML do nginx no diálogo (`src/Conversa.Proxy.pas:130-133`, `:195`). O FMX não reloga em laço (o login automático é uma vez por abertura, `Conversa.Login.pas:68-73`), então o risco é baixo. Em desenvolvimento todos os clientes chegam com o IP do gateway do Docker (S14). |
| Porta de desenvolvimento | **4430** com TLS e **80** sem TLS (`nginx@56e7cc0:28`, `:94`) | **443** só com TLS (`conversa/bin/nginx/desenvolvimento/servidor.conf:2-7`, HTTP na 443 → 301); produção na 80 atrás da borda TLS (`conversa/bin/nginx/producao/servidor.conf`) | 🔴 O `conversa.json` local aponta para `https://localhost:4430/api/` → conexão recusada (Q12). |
| TLS | Certificado do nginx de Windows | Dev: mkcert (`conversa/bin/setup-cert.bat:41`, nomes `localhost`, `127.0.0.1` e o IP); prod: na borda | REST (✅): `TNetHTTPClient` = WinHTTP/SChannel (`REST.API.pas:197`), valida pelo **repositório de certificados do Windows**; em dev funciona se a CA do mkcert estiver instalada. Não há *callback* que aceite tudo. WS (🔴): Indy + OpenSSL **sem verificação** de certificado nem de host (`lib/bird-socket-client/Bird.Socket.Client.pas:263-272`), e as DLLs `ssleay32.dll`/`libeay32.dll` (OpenSSL 1.0.2) **não estão** em `bin/` nem no `PATH` (Q9, #5). |
| Timeouts | — | — | 🟠 `TRESTAPI.Timeout` existe (`REST.API.pas:227-244`) mas nunca é chamado: valem os padrões do `TNetHTTPClient` (~60 s). Várias chamadas são síncronas na thread da interface (login, contatos, criar conversa, `anexo/existe`, download de anexo, `mensagens/novas` a cada WS 2, todas as de chamada): servidor lento congela a janela (#24). |

---

## 3. Tabela de TODAS as chamadas REST do FMX

23 chamadas vivas (1–23), 7 grupos de métodos sem chamador em `Conversa.Proxy.pas` (M1–M7) e 13 grupos na unit órfã `Conversa.Proxy.Extras.pas` (X1–X13). "Onde" = método no FMX ← quem chama. "Servidor atual" = rota (`rotas.ts`), esquema (`esquemas.ts`) e handler. "Abril" = `dpr@56e7cc0` (e `api.pas@56e7cc0` quando relevante).

| # | Verbo + caminho FMX | O que o FMX envia | Onde | Roda? | Servidor atual | Abril | Veredito |
|---|---|---|---|---|---|---|---|
| 1 | POST `login` | corpo `{login, senha, dispositivo_id}` | `src/Conversa.Proxy.pas:171-209` ← `Conversa.Dados.pas:117` ← `Conversa.Login.pas:80` | sim (síncrono, UI) | `rotas.ts:34-37`, `esquemas.ts:29`, `usuarios.ts:19-66` | `dpr:104-128` | ✅ Lê `{id, nome, email, telefone, dispositivo{id}, token}`. Só reaproveita `dispositivo_id` do mesmo dono (`8e81360`). |
| 2 | PATCH `dispositivo` | `{id, nome, modelo, versao_so, plataforma}`, só quando o id devolvido muda | `src/Conversa.Proxy.pas:452-470` ← `Conversa.Dados.pas:131-144` | sim | `rotas.ts:52`, `esquemas.ts:31-33`, `usuarios.ts:76-90` (403 se alheio) | `dpr:139` (exige `id`) | ✅ Manda `id` (ao contrário do Android). Sem `token_fcm` (o desktop não usa push). |
| 3 | GET `usuario/contatos` | – | `src/Conversa.Proxy.pas:398-418` ← `Conversa.Dados.pas:168`, `src/contatos/Conversa.Contatos.pas:54`, `src/novo/grupo/Novo.Grupo.pas:80` | sim (síncrono) | `rotas.ts:66`, `usuarios.ts:142-144` | `dpr:199` | ✅ |
| 4 | PUT `conversa` | `{descricao, tipo, inserida}` | `src/Conversa.Proxy.pas:515-539` ← `Conversa.Dados.pas:315-317` | sim (síncrono) | `rotas.ts:72`, `esquemas.ts:43`, `conversas.ts:39-44` | `dpr:215` (gravava `inserida`) | ✅ `inserida` é ignorado (o servidor usa a própria hora). |
| 5 | PUT `conversa/usuario` | `{conversa_id, usuario_id}` para cada membro, **começando pelo próprio usuário** | `src/Conversa.Proxy.pas:609-624` ← `Conversa.Dados.pas:320-321` | sim (síncrono) | `rotas.ts:89`, `esquemas.ts:48`, `conversas.ts:223-235` (membro existente volta sem erro) | `dpr:257`; índice único `ux_conversa_usuario_conv_user` (`migracoes.pas@56e7cc0:412`) | ✅ hoje; **em abril quebrava** (§3.1-5) |
| 6 | GET `conversas` | – | `src/Conversa.Proxy.pas:211-241` ← `Conversa.Dados.pas:182` | sim (thread) | `rotas.ts:78`, `conversas.ts:56-179` | `dpr:240` | ✅ *Parse* OK; `fixada_ordem`/`arquivada_em` ignorados (arquivadas aparecem e notificam, #42). |
| 7 | GET `conversa/dados?id=` | query `{id}`, `Tentativa(3)` | `src/Conversa.Proxy.pas:572-605` ← `src/chat/Conversa.Chat.pas:173-178` (ao abrir cada conversa) | sim (thread) | **não existe** → 404 | **não existia** (só na árvore antiga `rest/`, substituída em `61b7dbe`) | 🔴 **Q4 [ABRIL]** |
| 8 | GET `mensagens?conversa&mensagemreferencia&mensagensprevias&mensagensseguintes` | query | `src/Conversa.Proxy.pas:243-282` ← `Conversa.Dados.pas:532-548` | sim (thread) | `rotas.ts:109`, `esquemas.ts:58-65`, `mensagens.ts:328-376`, `:506-621` | `dpr:356`, `api.pas:1330`, `:1456` | 🟠 *Parse* OK, mas mensagem oculta (**Q6**) e tipos 5–8 (**Q7**) |
| 9 | PUT `mensagem` | `{conversa_id, conteudos:[{ordem, tipo, conteudo}]}` | `src/Conversa.Proxy.pas:641-664` ← `Conversa.Dados.pas:243-290` (síncrono, UI) | sim | `rotas.ts:105`, `esquemas.ts:50-57`, `mensagens.ts:148-232` | `dpr:296`, `api.pas:735` | ✅ texto · 🔴 anexo aponta para um identificador que não subiu (**Q2**) |
| 10 | GET `mensagens/novas?ultima=<id>` | query `{ultima}` | `src/Conversa.Proxy.pas:284-311` ← `Conversa.Dados.pas:474-478` (síncrono, UI, a cada WS 2) | sim | `rotas.ts:124`, `esquemas.ts:68` (**`desde`**, ISO), `mensagens.ts:694-725` | `dpr:404-410` já com `desde` | 🟠 **Q8 [ABRIL]** |
| 11 | GET `mensagem/status?conversa&mensagem=<csv>` | query | `src/Conversa.Proxy.pas:666-708` ← `Conversa.Dados.pas:479-485` (WS 3) | sim (thread) | `rotas.ts:118`, `esquemas.ts:67`, `mensagens.ts:636-668` | `dpr:388`, `api.pas:1848` | ✅ Booleanos agregados, como o FMX espera; `excluida_em` ignorado (Q6). |
| 12 | **GET** `mensagem/visualizar?conversa&mensagem` | query, `Tentativa(5)` | `src/Conversa.Proxy.pas:723-744` ← `Conversa.Dados.pas:346-350` ← `src/chat/Conversa.Chat.pas:157-166`, `:280-290`, `src/chat/chat/frames/chat.mensagem.pas:265-270` | sim (thread) | só **POST** `{conversa, mensagem}` (`rotas.ts:112`, `esquemas.ts:66`) → 404 | só **POST** (`dpr:372`), desde `9b9a32f` | 🔴 **Q3 [ABRIL]** |
| 13 | GET `anexo/existe?identificador=` | query | `src/Conversa.Proxy.pas:748-760` ← `Conversa.Dados.pas:279` | sim (síncrono) | `rotas.ts:135`, `anexos.ts:33-39` | `dpr:313` | ✅ |
| 14 | GET `anexo?identificador=` → lê **bytes** | query | `src/Conversa.Proxy.pas:762-786` (`:779`) ← `Conversa.Dados.pas:229-241` ← `:599-604` | sim (síncrono, UI) | `rotas.ts:137`, `anexos.ts:41-56` → JSON **`{url}`** | `dpr:322` → `{url}` (`api.pas:1040-1042`), desde `f28ff10` | 🔴 **Q1 [ABRIL]** |
| 15 | PUT `anexo?tipo&nome&extensao` + corpo `application/octet-stream` | bytes do arquivo; **`tipo` = 0** | `src/Conversa.Proxy.pas:788-814` ← `Conversa.Dados.pas:279-280` (thread solta) | sim | `rotas.ts:139`, `esquemas.ts:74` (JSON `{identificador, tipo, nome, extensao, tamanho}`), `anexos.ts:58-81`; nginx 1 MiB | `dpr:331-345`, `api.pas:1048-1114` (JSON, desde `f28ff10`); nginx 1024 MiB | 🔴 **Q2 [ABRIL], piorada** |
| 16 | PUT `chamada/iniciar` | `{usuarios:[{id}]}` (com o próprio; **sem `tipo` e sem `conversa_id`**) | `src/Conversa.Proxy.pas:818-841` ← `src/chamada/Conversa.Chamada.pas:433-470` | sim (síncrono) | `rotas.ts:155`, `esquemas.ts:86`, `chamadas.ts:88-110` | `dpr:430`, `api.pas:1989-2071` (mesmas regras) | 🟠 **Q14 [ABRIL]** |
| 17 | POST `chamada/cancelar` | `{id}` | `src/Conversa.Proxy.pas:843-855` ← `src/chamada/Conversa.Chamada.pas:312` | sim | `rotas.ts:157`, `chamadas.ts:153-162` | `dpr:438` | ✅ (404 se não participa; antes 500) |
| 18 | POST `chamada/recusar` | `{id}` | `src/Conversa.Proxy.pas:857-869` ← `Conversa.Chamada.pas:313` | sim | `rotas.ts:161`, `esquemas.ts:88` (`nao_atendeu?`), `chamadas.ts:164-197` | `dpr:454` | ✅ Não manda `nao_atendeu` (sem tempo limite de toque, #61). O 53 agora volta também para si mesmo (#30). |
| 19 | POST `chamada/entrar` | `{id}` | `src/Conversa.Proxy.pas:871-894` ← `Conversa.Chamada.pas:296` | sim (síncrono) | `rotas.ts:159`, `chamadas.ts:199-212` | `dpr:446` | ✅ O 54 agora volta também para si mesmo. |
| 20 | POST `chamada/sair` | `{id}` | `src/Conversa.Proxy.pas:896-908` ← `Conversa.Chamada.pas:319` | sim | `rotas.ts:164`, `chamadas.ts:214-225` | `dpr:462` | ✅ |
| 21 | POST `chamada/finalizar` | `{id}` | `src/Conversa.Proxy.pas:910-922` ← `Conversa.Chamada.pas:317` | sim | `rotas.ts:169`, `chamadas.ts:293-300` | `dpr:478` | ✅ |
| 22 | GET `chamada/dados?id=` | query | `src/Conversa.Proxy.pas:924-937` ← `Conversa.Chamada.pas:408-421` (síncrono, a cada evento 51–55) | sim | `rotas.ts:201`, `chamadas.ts:307-389` | `dpr:486` | ✅ Detalhes benignos: o campo do FMX `adicinoado_em` (erro de digitação, `src/Conversa.Proxy.Tipos.pas:170`) e `conversa_id` não vêm na resposta e ficam 0; `conversa_chat_id` é ignorado. |
| 23 | GET `chamadas` → `TChamadasHistorico` | – | `src/Conversa.Proxy.pas:313-337` ← `src/chamada/Conversa.Chamada.Listagem.pas:68` | sim (thread) | `rotas.ts:205`, `esquemas.ts:118`, `chamadas.ts:429-450` | `dpr:502`, `api.pas:2445-2591` (mesma forma de hoje; datas sem fuso) | 🔴 **Q5 [ABRIL]** |
| M1 | PUT `dispositivo` | `{nome, modelo, versao_so, plataforma}` | `src/Conversa.Proxy.pas:422-450` | **não** | rota não existe (só PATCH) → 404 | também não existia | ⚪ latente [ABRIL] |
| M2 | PUT `dispositivo/usuario?dispositivo_id=` | query | `:472-483` | **não** | `rotas.ts:54`, `usuarios.ts:92-95` (403 se alheio) | `dpr:147` | ⚪ contrato OK |
| M3 | PUT / PATCH / DELETE `usuario` | `TReqUsuario {nome, login, email, telefone, senha}` (sem `id`); `?id=` | `:341-396` | **não** | `rotas.ts:39`, `:57`, `:59`; `esquemas.ts:37` exige `id` no PATCH | `dpr:156` (PUT exigia token), `:164`, `:172` | ⚪ PATCH sem `id` daria 400 — latente [ABRIL] |
| M4 | PUT / DELETE `usuario/contato` | query | `:487-511` | **não** | `rotas.ts:61`, `:64` | `dpr:181`, `:190` | ⚪ contrato OK |
| M5 | PATCH / DELETE `conversa` | `{id, descricao, tipo}`; `?id=` | `:541-570` | **não** | `rotas.ts:74`, `:76` | `dpr:223`, `:231` | ⚪ contrato OK (`DELETE /conversa` dá 500 no servidor, S6) |
| M6 | DELETE `conversa/usuario?id=` | query | `:626-637` | **não** | `rotas.ts:91` | `dpr:265` | ⚪ contrato OK |
| M7 | DELETE `mensagem?id=` | query | `:710-721` | **não** | `rotas.ts:107`, `mensagens.ts:293-326` (exclusão lógica) | `dpr:304` (apagava de fato; 409 se já recebida) | ⚪ semântica mudou ("ocultar") |
| X1 | POST `alterar-senha` | `{senha_atual, senha_nova}` | `src/Conversa.Proxy.Extras.pas:241-257` | **não** (e sem token → 401) | `esquemas.ts:30` espera `{senha_atual, senha}` | `dpr:130` também exigia `senha` | ⚪ seria 400 — latente [ABRIL] |
| X2 | PUT `mensagem/reacao` | `{mensagem_id, emoji}` | `:261-280` | **não** | `rotas.ts:131`, `mensagens.ts:730-760` | `dpr:563` | ⚪ contrato OK |
| X3 | POST `mensagem/reproduzir` | `{mensagem_id, conversa_id}` | `:282-298` | **não** | espera `{conversa, mensagem}` (`esquemas.ts:66`) | `dpr:380` (mesmo corpo de hoje) | ⚪ seria 400 — latente [ABRIL] |
| X4 | GET `pesquisar?texto&conversa` | query | `:300-320` | **não** | `rotas.ts:128`, `mensagens.ts:378-404` (devolve mensagens) | `dpr:525-537` (exigia `usuario`, `:529`) | ⚪ hoje funcionaria; em abril dava 400 |
| X5 | PUT `mensagem` com `referencia:{tipo, destino_mensagem_id}` | corpo | `:322-354` (`:336-339`) | **não** | espera `mensagem_referencia:{tipo, origem_mensagem_id}` (`esquemas.ts:55`); `referencia` é **descartada em silêncio** | `mensagem_referencia` (`api.pas:797`); a chave desconhecida dava 500 | ⚪ latente [ABRIL] |
| X6 | POST `conversa/digitando` / `gravando` | `{conversa_id}` | `:358-390` (`:363`, `:380`) | **não** | espera `{id}` (`esquemas.ts:41`; `rotas.ts:93`, `:98`) | `dpr:274-295` também lia `id` | ⚪ seria 400 — latente [ABRIL] |
| X7 | POST `chamada/video` | `{id}` | `:394-409` | **não** | `rotas.ts:207` | `dpr:515` | ⚪ contrato OK |
| X8 | PUT `chamada/usuario` | `{chamada_id, usuario_id}` | `:411-427` | **não** | `rotas.ts:166`, `esquemas.ts:87` | `dpr:470` | ⚪ contrato OK |
| X9 | GET `chamadas/pendentes` | – | `:225-237`, `:429-441` | **não** | `rotas.ts:203`, `chamadas.ts:312-330` | `dpr:494` | ⚪ contrato OK (devolve JSON cru) |
| X10 | GET / PUT / PATCH `sip` | corpo | `:445-484` | **não** | `rotas.ts:216`, `:218`, `:220`; PATCH exige `id` (`esquemas.ts:121-124`) | `dpr:539`, `:547`, `:555` | ⚪ depende do JSON montado por quem chamar |
| X11 | GET `anexos?conversa&autor&direcao&tipos&antes&limite` | query | `:488-514` | **não** | `rotas.ts:143`, `esquemas.ts:75-84`, `anexos.ts:97-169` | `dpr:412` | ⚪ contrato OK (devolve JSON cru) |
| X12 | POST `anexo/confirmar?identificador=` | query | `:516-531` | **não** | `rotas.ts:141`, `anexos.ts:83-95` | `dpr:347` | ⚪ contrato OK, mas ninguém chama (parte de Q2) |
| X13 | PUT `usuario` (cadastro) / GET `contatos/online` | corpo / – | `:181-221` | **não** | `rotas.ts:39` (pública), `:68` | `dpr:156` (exigia token), `:207` | ⚪ contrato OK |

### 3.1 Notas por endpoint

**5. `PUT /conversa/usuario` — quebrava em abril, funciona hoje.** O FMX cria a conversa e depois inclui cada membro, começando pelo próprio usuário (`src/contatos/Conversa.Contatos.pas:75-76` monta `[eu, destinatário]`; `Conversa.Dados.pas:320-321` percorre a lista). Em abril o criador já entrava ao criar (`api.pas@56e7cc0:432-433`) e havia índice único em `(conversa_id, usuario_id)` (`migracoes.pas@56e7cc0:412`): a reinclusão falhava, `ValidarErro` fazia `Abort` (`src/Conversa.Proxy.pas:620`) e o destinatário **nunca era incluído** (dedução do código; não confirmado em execução). Hoje o servidor devolve o membro existente sem erro (`conversas.ts:225-231`, desde `97f9341`).

**7. `GET /conversa/dados?id=` — não existe (Q4).** Chamado em `TChat.SetConversa` para toda conversa com `ID <> 0` (`src/chat/Conversa.Chat.pas:173-178`). Resposta: 404 `{"error":"Rota GET:/api/conversa/dados não encontrada"}` (`app.ts:66-69`). O erro some em `ValidarErro` (sem assinante). Substituto: `GET /conversa/usuarios?conversa=` → `[{id (conversa_usuario.id), usuario_id, nome, avatar_url}]` (`rotas.ts:86`, `conversas.ts:204-221`; doc 01 §11.4).

**8. `GET /mensagens`.** Formato de hoje: `{id, remetente_id, remetente, conversa_id, inserida, alterada, visivel_em, excluida_em, mensagem_referencia?, recebida, visualizada, reproduzida, conteudos:[{id, ordem, tipo, conteudo, nome, extensao, transcricao_status, transcricao}], reacoes?}` (`mensagens.ts:506-621`; doc 01 §10.2). O `TMensagem` do FMX (`src/Conversa.Proxy.Tipos.pas:99-111`) lê `id, remetente_id, remetente, conversa_id, inserida, alterada, recebida, visualizada, reproduzida, conteudos`: o *parse* funciona porque o `TJsonSerializer` pula propriedades desconhecidas (§9). Falta ler `excluida_em` (Q6) e tratar os tipos 5–8 (Q7). Efeito colateral igual a abril: listar marca como recebidas e dispara WS 3 aos outros. A paginação usa `mensagemreferencia = menor id − 1` / `maior id + 1` (`Conversa.Dados.pas:532-548`); se esse id não existir, o servidor não devolve nada (`mensagens.ts:334`; #20).

**9. `PUT /mensagem` com anexo.** O conteúdo leva `conteudo = <SHA-256>` (`Conversa.Dados.pas:277`), mas o arquivo nunca sobe (Q2). O servidor grava a mensagem (`mensagens.ts:148-232`) e, na leitura, só devolve conteúdos de anexo que tenham registro em `anexo` (`inner join anexo`, `mensagens.ts:441-442`): **os outros recebem a mensagem sem o conteúdo**. Exceção: se o mesmo arquivo (mesmo SHA-256) já existir no servidor, `anexo/existe` devolve `true`, o FMX pula o upload e a mensagem funciona. O remetente vê a cópia local (`Conversa.Dados.pas:274-276`) e acha que deu certo.

**10. `GET /mensagens/novas?ultima=` (Q8).** O FMX manda `ultima = <maior mensagem_id já visto>` (`src/Conversa.Proxy.pas:290`; `FDadosApp.UltimaMensagemNotificada`, `Conversa.Dados.pas:505`). O servidor só lê `desde` (`esquemas.ts:68`); sem ele, conta "desde sempre" (`mensagens.ts:695-702`). Hoje devolve as conversas com mensagens de outros **ainda não visualizadas** (filtro de `2299a5c`, `mensagens.ts:719-723`) — e, como o FMX nunca marca nada como visualizado (Q3), a lista não esvazia. A resposta `[{conversa_id, mensagem_id, ate}]` é lida por `TMensagemNova` (`src/Conversa.Proxy.Tipos.pas:126-129`), e cada item vira um `GET /mensagens` (`Conversa.Dados.pas:496-508`).

**12. `GET /mensagem/visualizar` (Q3).** Disparado ao pintar cada bolha recebida com a janela ativa (`src/chat/chat/frames/chat.mensagem.pas:265-270`) e ao abrir a conversa (`src/chat/Conversa.Chat.pas:157-166`, `:280-290`). `Tentativa(5)` só repete erro de rede (`src/Conversa.Proxy.pas:137-152`); o 404 cai em `ValidarErro` → `Abort` silencioso. O certo: `POST /mensagem/visualizar` com corpo `{conversa, mensagem}` → `{sucesso: true}` + WS 3 aos outros membros (`mensagens.ts:623-634`).

**14. `GET /anexo` (Q1).** `TAnexo.Download` devolve `Response.ToStream.Bytes` (`src/Conversa.Proxy.pas:779`) e `DownloadAnexo` grava em `PastaDados\anexos\<identificador>` (`Conversa.Dados.pas:229-241`) — inclusive quando a resposta é erro (bytes vazios) — e nunca revalida (`TFile.Exists`, `:232-233`). Como o servidor devolve `{"url": "<GET pré-assinado, 600 s>"}` (`anexos.ts:55`), o "arquivo" salvo é esse JSON. Detalhe em §8.

**15. `PUT /anexo` (Q2).** Bytes no corpo + `tipo/nome/extensao` na *query* (`src/Conversa.Proxy.pas:794-807`). O servidor quer JSON (`esquemas.ts:74`): ≤ 1 MiB → **400** (validação ou corpo inválido, conforme o `Content-Type` que efetivamente sai — não confirmado); > 1 MiB → **413 HTML** do nginx. O FMX chama com `tipo` fixo **0** (`Conversa.Dados.pas:280`), que nem é tipo de anexo (`anexos.ts:31`, `[2, 3, 4, 5]`). O erro morre na thread anônima (`ValidarErro` → `Abort`). Em abril: `Req.Body<TJSONObject>` sobre bytes → erro (500).

**16. `PUT /chamada/iniciar` (Q14).** O FMX manda só `usuarios` (`src/chamada/Conversa.Chamada.pas:455-462`). O servidor, sem `tipo`, usa `convidados.length === 2 ? 1 : 2` (`chamadas.ts:90`), ou seja, **1 = simples, 2 = grupo** — a mesma regra de abril (`api.pas@56e7cc0:2003`) e a mesma leitura do FMX (`TChamadaTipo = (Desconhecido, Simples, Grupo)`, `src/Conversa.Proxy.Tipos.pas:142-146`). Mas o web manda `tipo` = **1 áudio / 2 vídeo** (`conversa-web/src/stores/call.ts:852-890`, `api.chamadaIniciar(tipo, usuarios, conversaAtivaId)`) — e já mandava em abril (`bin/web/assets/style-DuUMYjIa.js@56e7cc0`: `body:{tipo:e,usuarios:t,conversa_id:n||void 0}`). Sem `conversa_id`, não há mensagem-resumo tipo 6 nem chat da chamada vinculado (`chamadas.ts:510`; abril `api.pas@56e7cc0:2693-2694`). Ambiguidade registrada como S11 no doc 08.

**23. `GET /chamadas` (Q5).** O FMX desserializa em `TChamadaHistorico` (`src/Conversa.Proxy.Tipos.pas:194-215`: `chamada_id`, `tipo_chamada`, `status_chamada`, `criado_por_id`, `criado_por: String`, `usuario_exibido_id/nome`, `status_usuario`, `adicionado_por_id/por`, `tipo_acao`, `quantidade_outros_usuarios`, …). O servidor devolve `{id, tipo, status, criado_em, criado_por (número), conversa_id, iniciada, finalizada, duracao, participantes:[{usuario_id, nome, status, duracao, avatar_url}]}` (`chamadas.ts:416-450`) — a mesma forma de abril (`api.pas@56e7cc0:2445-2591`). Só `iniciada`, `finalizada`, `conversa_id` e `criado_em` coincidem; `criado_por` chega como número num campo `String` (comportamento do `TJsonSerializer` nesse caso não confirmado). O modelo do FMX é o da árvore antiga `rest/` (§1.1).

---

## 4. Rotas do servidor que o FMX não usa

Das **69 rotas** de `rotas.ts` (doc 01 §4), o código vivo do FMX chama **21** (as 23 linhas vivas da §3 menos as duas inexistentes). As **48** restantes, agrupadas; em **negrito** as que são **P0 para o desktop** (sem elas não há paridade mínima nem tempo real confiável):

| Área | Rotas não usadas | Comentário |
|---|---|---|
| Chamadas | **`GET /ice`** (`rotas.ts:212`), **`GET /chamadas/pendentes`** (`:203`), `POST /chamada/video` (`:207`), `PUT /chamada/usuario` (`:166`), `PUT /chamada/chat` (`:199`) | Sem `/ice` não há mídia (Q11). Sem `pendentes`, chamada que já tocava ao abrir ou reconectar não aparece (#44). |
| Conversas | **`GET /conversa/usuarios`** (`:86`), **`POST /conversa/digitando`** (`:93`), **`POST /conversa/gravando`** (`:98`), `PATCH /conversa` (`:74`), `DELETE /conversa` (`:76`), `PATCH /conversa/fixadas` (`:80`), `PATCH /conversa/arquivada` (`:83`), `DELETE /conversa/usuario` (`:91`) | `/conversa/usuarios` é o substituto do inexistente `/conversa/dados` (Q4). Digitando/gravando só existem na unit órfã, com corpo errado (§10.3). |
| Contatos e presença | **`GET /contatos/online`** (`:68`), `PUT /usuario/contato` (`:61`), `DELETE /usuario/contato` (`:64`) | Sem presença no desktop (#45). |
| Mensagens | **`POST /mensagem/visualizar`** (`:112`; o FMX usa `GET`), **`POST /mensagem/reproduzir`** (`:115`), `DELETE /mensagem` (`:107`), `GET /mensagem/status/detalhe` (`:121`), `GET /pesquisar` (`:128`), `PUT /mensagem/reacao` (`:131`) | `visualizar` = Q3. `reproduzir` marca áudio ouvido (verde até ouvir, #57). |
| Anexos | **`POST /anexo/confirmar`** (`:141`), `GET /anexos` (`:143`), `GET /anexo/transcricao` (`:147`), `PUT /anexo/transcricao` (`:150`) | `confirmar` faz parte do upload correto (Q2). O `PUT` direto no MinIO (`/storage/`, URL assinada) também não é feito. |
| Usuário e dispositivo | `PUT /usuario` (`:39`), `PATCH /usuario` (`:57`), `DELETE /usuario` (`:59`), `PUT /dispositivo/usuario` (`:54`), `POST /alterar-senha` (`:47`), `GET /usuario/permissoes` (`:179`) | Cadastro, perfil e troca de senha não existem no app vivo. |
| Atividades | `GET /atividades` (`:193`), `GET /atividades/novas` (`:195`), `POST /atividades/vistas` (`:197`) | O FMX não tem a aba Atividades. |
| Enquetes | `PUT /enquete` (`:171`), `GET /enquete` (`:173`), `POST /enquete/votar` (`:175`), `POST /enquete/encerrar` (`:176`), `PATCH /enquete` (`:177`) | Tipo 8 aparece vazio (Q7). |
| Permissões e parâmetros | `GET /permissoes` (`:181`), `PUT /permissao/usuario` (`:183`), `DELETE /permissao/usuario` (`:186`), `GET /parametros` (`:189`), `PATCH /parametros` (`:191`) | Administração. |
| SIP | `GET /sip` (`:216`), `PUT /sip` (`:218`), `PATCH /sip` (`:220`) | Só na unit órfã. |

E o contrário: o FMX chama duas rotas que **não existem** — `GET /conversa/dados` (Q4) e `GET /mensagem/visualizar` (Q3).

---

## 5. WebSocket

### 5.1 Transporte, URL e TLS

| | Abril (`56e7cc0`) | Hoje (`779c8ed`) | FMX |
|---|---|---|---|
| Servidor | Bird Socket próprio na porta **9090** (`dpr@56e7cc0:571`) | Elysia `.ws('/ws/')` na **mesma porta da API** (`websocket.ts:56`); o compose publica a API só em `127.0.0.1:8080` (`conversa/docker-compose.yml:149-150`) | — |
| URL pública | `wss://host:4430/ws/` **e** `ws://host/ws/` (nginx 4430 com TLS e 80 sem TLS repassando `/ws/` → 9090, `nginx@56e7cc0:28`, `:48-57`, `:94`, `:113-114`) | `wss://host[:443]/ws/` (`conversa/bin/nginx/nginx.conf:109-114`, `proxy_read_timeout 3600s`). Em dev **só TLS** (`desenvolvimento/servidor.conf:2-7`); em produção o TLS fica na borda. `/ws` sem barra → 301 | **HEAD `@4759ba5`:** `ws://host:(8000 + porta do Host)` mantendo o caminho do Host (`Conversa.Dados.pas@4759ba5:429-431`) — com `https://localhost:4430/api/` vira `ws://localhost:12430/api/`. **Staged:** `wss://host[:porta]/ws/` se o Host for `https` (`ws://` se `http`), caminho `/ws/` (`Conversa.Dados.pas:432-437`) |
| Biblioteca | — | — | `TBirdSocketClient` (cópia local do *bird-socket-client*, sobre `TIdTCPClient` do **Indy 10**); quadros montados e lidos à mão (`lib/bird-socket-client/Bird.Socket.Client.pas:348-408`, `:533-636`) |
| TLS | — | — | `TIdSSLIOHandlerSocketOpenSSL` criado quando a URL é `wss`; o `Method := sslvTLSv1_2` atribuído depois de `SSLVersions` deixa só TLS 1.2 na prática (`Bird.Socket.Client.pas:263-272`, leitura do A3 §2.1); **sem `VerifyMode`/`OnVerifyPeer`/`RootCertFile`**: qualquer certificado é aceito, e o JWT vai no primeiro quadro (#5). O Indy do Delphi 12 carrega `ssleay32.dll` + `libeay32.dll` (OpenSSL 1.0.x), que **não estão** em `bin/` nem no `PATH` desta máquina (conferido): com Host `https`, o `Connect` falha com "Could not load SSL library" e o app segue **sem tempo real** (o REST funciona, por WinHTTP) |
| Login | 1ª mensagem `{tipo:1, token}`; JWT exige `exp`, `iat`, `sub` (`ws.pas@56e7cc0:136-150`) | Igual: `{tipo:1, token}`; segunda tentativa na mesma conexão é ignorada (`websocket.ts:76-100`) | ✅ `{"tipo":1,"token":"<jwt>"}` uma vez, logo após o `Connect`, na thread da interface (`Conversa.Dados.pas:442-450`). O servidor não confirma, e o FMX não espera confirmação |
| Erro de token | `{tipo:0, message}` | `{tipo:0, message:"Token inválido ou expirado"}`, conexão **não** é fechada (`websocket.ts:83-88`) | 🔴 `raise Exception.Create(message)` dentro do *callback* (`Conversa.Dados.pas:486-489`): diálogo genérico; o socket fica aberto e mudo; não reloga (#46) |
| Keepalive | Bird servidor sem *ping* (nada em `ws.pas@56e7cc0`) | Sem `idleTimeout`/`sendPings` no código (`websocket.ts:56`) → valem os padrões do Bun: pela documentação, 120 s ocioso e *ping* automático **sem carga**. **Não confirmado** no código (S21). O Node de `97f9341` (`@fastify/websocket`) também não mandava *ping* | 🔴 provável: o leitor do Bird não fecha quadro de tamanho 0 (`Bird.Socket.Client.pas:573-579`: `LPosition := 0` e depois `Inc(LPosition)`), não responde PONG e lê o byte seguinte como tamanho (Q10, #3) |
| Reconexão | — | — | 🔴 Não existe: só o ouvinte `MESSAGE` (`Conversa.Dados.pas:439`), `AutoReconnect` desligado (`Bird.Socket.Client.pas:306`) e `IniciarMonitoramento` sai se o socket já foi criado (`Conversa.Dados.pas:425-426`). Qualquer queda deixa o app sem tempo real até reiniciar (#2) |

Atalho de desenvolvimento (não serve para a rede local): no próprio PC do servidor, Host `http://localhost:8080/api/` dá `ws://localhost:8080/ws/` sem TLS e sem OpenSSL. As URLs de anexo e de TURN sairiam com o `Host` interno (`contexto.ts`, `minio.ts`), mas o FMX não as usa hoje.

### 5.2 Eventos servidor → FMX (tabela completa)

Enum do servidor: `websocket.ts:4-23`. Enum do FMX: `src/Conversa.Tipos.pas:17-38` (não tem 9, 57, 61 nem 62; o comentário ainda cita o servidor Delphi). Abril: `ws.pas@56e7cc0:20-36` (0–7, 40, 51–56, 60). Despacho no FMX: `Conversa.Dados.pas:453-494`; antes do `case`, `TConversaChamadas.ProcessarSocket` consome 51–55 (`src/chamada/Conversa.Chamada.pas:132-141`, `:170-190`). Vereditos: ✅ · 🟠 parcial · 🔴 quebrado · ⬜ não tratado.

| tipo | Nome | Payload (hoje) | Mudou desde abril? | FMX trata em | O que o FMX faz | Veredito |
|---|---|---|---|---|---|---|
| 0 | Erro | `{tipo, message}` | Não | `Conversa.Dados.pas:486-489` | `raise` na interface → diálogo genérico; não fecha nem reloga | 🔴 |
| 2 | NovaMensagem | `{tipo, titulo, mensagem}`, **sem** `conversa_id` | Texto resumido (`6fd4733`). Sai **uma vez por par usuário × aparelho com `token_fcm`** (`notificacoes.ts:56-69`): quem tem 2+ aparelhos com token recebe o 2 duplicado (S22) | `Conversa.Dados.pas:474-478` → `src/Conversa.Proxy.pas:284-311` → `Conversa.Dados.pas:496-508` | Ignora `titulo`/`mensagem`; `GET /mensagens/novas?ultima=` **síncrono na interface** (Q8) e um `GET /mensagens` por conversa; duplicatas geram "Mensagem já adicionada!" (#11) | 🟠 |
| 3 | AtualizacaoStatusMensagem | `{tipo, grupo, mensagens:"1,2,3"}` | Também emitido na exclusão (`b94b504`), no resumo de chamada a todos (`2299a5c`) e quando a agendada sai | `Conversa.Dados.pas:479-485` → `src/Conversa.Proxy.pas:666-708` | `GET /mensagem/status`; atualiza recebida/visualizada; ignora `reproduzida` e **`excluida_em`** (Q6) | ✅ (🟠 sem `excluida_em`) |
| 4 | Digitando | `{tipo, conversa_id, usuario_id}` | 403 para não membros (`0b67aca`) | — (sem `case`) | Nada; a área "digitando…" existe e fica oculta (`src/chat/Conversa.Chat.pas:45-48`, `:110`) | ⬜ |
| 5 | GravandoAudio | idem | idem | — | Nada | ⬜ |
| 7 | ReacaoMensagem | `{tipo, conversa_id, mensagem_id, usuario_id, emoji, acao}` | Não | — | Nada (o FMX não mostra reações) | ⬜ |
| 9 | (erro de leitura) | `{tipo:9, message}` | Não | — | Ignorado (o FMX só envia JSON válido) | ✅ |
| 40 | ConversaNova | `{tipo, conversa_id, usuario_id}` | Também ao criar o chat da chamada e ao entrar numa chamada com chat (`315464b`) | `Conversa.Dados.pas:470-473` | `GET /conversas` (thread); corrida com o 2 seguinte (#40) | ✅ |
| 51 | ChamadaRecebida | `{tipo, chamada_id, usuario_id}` | Não | `Conversa.Chamada.pas:170-190` → `:334-340` | Cria a chamada, `GET /chamada/dados` **síncrono**, *card* + janela. Sem som de toque nem tempo limite; 51 da chamada atual a faz voltar a "Recebendo" (#32) | 🟠 |
| 52 | ChamadaFinalizada | idem | Não | `Conversa.Chamada.pas:326-332` | Encerra, mas lê `FID` depois de liberar o objeto (#7) | 🟠 |
| 53 | UsuarioRecusou | idem | **Também ao próprio usuário** (`95430ba`) | `Conversa.Chamada.pas:342-356` | Com meu id e eu "recebendo" → ignora: não para o toque quando recusei em outro aparelho (#30) | 🟠 |
| 54 | UsuarioEntrou | idem | **Também ao próprio usuário** (`95430ba`) | `Conversa.Chamada.pas:358-387` | Idem para "atendi no celular"; senão assina o *peer* uma vez, sem retentativa (#31) | 🟠 |
| 55 | UsuarioSaiu | idem | Não (continua sem 52 quando a chamada termina por saída) | `Conversa.Chamada.pas:389-406` | Desconecta o *peer*; 1:1 em andamento encerra; grupo, nada | 🟠 |
| 56 | VideoAtivado | idem | Não | — (fora de `SocketType`) | Nada | ⬜ |
| 57 | SinalChamada | `{tipo, chamada_id, usuario_id, dados}` | **Novo** (`315464b`) | — (fora do enum) | Nada (sem tela anunciada, ponteiro nem chat da chamada) | ⬜ |
| 60 | StatusUsuario | `{tipo, usuario_id, online}` | Não | — | Nada (sem presença) | ⬜ |
| 61 | NovaAtividade | `{tipo:61}` | **Novo** (`8283616`) | — | Nada | ⬜ |
| 62 | EnqueteAtualizada | `{tipo, enquete_id, conversa_id}` | **Novo** (`8031fa5`) | — | Nada | ⬜ |

Os tipos fora do enum (57, 61, 62) passam por `TSocketMessageType(...)` (`Conversa.Dados.pas:464`) sem erro e não casam com nenhum ramo: são ignorados sem quebrar. Nenhum número de evento mudou de valor desde abril.

### 5.3 O que o FMX envia pelo WebSocket

| tipo | Formato | Aceito? | Veredito |
|---|---|---|---|
| 1 | `{"tipo":1,"token":"<jwt>"}` uma vez (`Conversa.Dados.pas:442-450`) | Sim (`websocket.ts:79-100`) | ✅ |
| 57 | Nunca enviado | — | ⬜ |
| PONG de protocolo | Só em resposta a PING **com carga**; PING vazio fica sem resposta (Q10) | — | 🔴 |

### 5.4 Ações REST ligadas ao tempo real

| Ação | FMX hoje | Servidor | Veredito |
|---|---|---|---|
| Digitando / gravando | Nada no app; só na unit órfã, com `{conversa_id}` e sem token (`src/Conversa.Proxy.Extras.pas:358-390`) | `POST /conversa/digitando` e `/gravando` com `{id}` (`rotas.ts:93`, `:98`; `esquemas.ts:41`) | ⬜ (🔴 se ligado como está) |
| Novas mensagens | `GET /mensagens/novas?ultima=<id>`, síncrono | `?desde=<ISO>` (`esquemas.ts:68`) | 🟠 Q8 |
| Status | `GET /mensagem/status?conversa=&mensagem=<csv>` | Igual (`mensagens.ts:636-668`) | ✅ |
| Visualizar | `GET` com query | Só `POST` com corpo | 🔴 Q3 |
| Contatos online | Nada (só na unit órfã) | `GET /contatos/online` → `number[]` (`usuarios.ts:147-155`) | ⬜ |
| Chamadas pendentes | Nada (só na unit órfã) | `GET /chamadas/pendentes` (`chamadas.ts:312-330`) | ⬜ |
| Atividades novas | Nada | `GET /atividades/novas` | ⬜ |
| Dispositivo | `PATCH /dispositivo` só quando o id muda | `usuarios.ts:76-90` | ✅ |

Não há ressincronização em nenhum momento (abertura, reconexão): nem `mensagens/novas`, nem `contatos/online`, nem `chamadas/pendentes`, nem `atividades/novas` (#44). O web faz essa sequência a cada `onopen` (doc 03 §1.4–1.6).

---

## 6. Push

- **O desktop não usa FCM.** O `PATCH /dispositivo` do FMX não manda `token_fcm` (`src/Conversa.Proxy.pas:456-463`); o servidor nunca envia push para ele. Notificações do PC só existem com o app aberto e o WebSocket vivo (janelas FMX próprias, `src/notificacao/*`; A3 §7).
- **A regra do servidor que importa para o desktop** (A3 §8, A7 §4.1): ao gravar uma mensagem, para cada destinatário e cada aparelho ativo com `token_fcm`, o servidor manda o WS 2 e, **só se** `token_fcm && !arquivada && !usuarioConectado(usuario_id)`, o push (`notificacoes.ts:68-75`, o `if` em `:71`). `usuarioConectado` = **qualquer** conexão WebSocket autenticada do usuário, de qualquer aparelho ou aba (`websocket.ts:131-133`); o login do WS não informa o aparelho, e o token vencido não remove a conexão.
- **Não é regra nova:** abril fazia o mesmo (`api.pas@56e7cc0:671-674`, `TWebSocket.UsuarioConectado`, `ws.pas@56e7cc0:259`). Mudaram só o formato do push (`6fd4733`, só `data`) e a exceção das arquivadas (`95430ba`).
- **Efeito de um desktop sempre conectado** (A7 §4.2): enquanto o FMX estiver com o socket aberto — minimizado na bandeja, com a tela bloqueada, de noite no escritório, mesmo com o JWT vencido — **o celular e o web em segundo plano do mesmo usuário não recebem push de mensagem nenhuma**; o usuário aparece online 24 h (WS 60, `contatos/online`); e um temporizador de 30 s de toque no desktop (quando existir) recusaria a chamada por todos os aparelhos (S19).
- **Hoje o efeito está mascarado** pelos defeitos do FMX: o socket provavelmente cai ~2 min depois de abrir (Q10) e nunca volta (#2), ou nem abre sem o OpenSSL (Q9). **Consertar o tempo real do FMX sem tratar isso deixa o celular sem push sempre que o PC estiver ligado** (#15).
- **Pendências no servidor:** **S2** (suprimir o push por aparelho, não por usuário: `{tipo:1, token, dispositivo_id}` ou *claim* no JWT) e **S18** (presença ativa por conexão, "ausente") — doc 08 §1 e §2, prioridade 1 no doc 08 §4. Enquanto não existirem, o cliente desktop deve fechar o socket ao bloquear a sessão, ao suspender e depois de N minutos ocioso, mantendo *polling* REST nesse período (doc 04 #15).

---

## 7. Chamadas / WebRTC

### 7.1 Endereços e caminhos (A4 §1.10, §1.13)

| | Abril | Hoje | FMX |
|---|---|---|---|
| Base WHIP/WHEP | `https://host:4430/webrtc/` → MediaMTX nativo em `127.0.0.1:8889` (`nginx@56e7cc0:72-80`; `mediamtx.yml@56e7cc0:13-15`); no próprio PC do servidor, `http://localhost:8889` também respondia | `https://host/webrtc/` → `mediamtx:8889` (`conversa/bin/nginx/nginx.conf:135-140`); o compose publica `8889/tcp` só em `127.0.0.1` (`conversa/docker-compose.yml:123-124`) | `Configuracoes.MediaMtxBase`, padrão **`http://localhost:8889`** (`src/configuracoes/Conversa.Configuracoes.pas:17`, `:51-52`, `:66-67`); **não deriva do Host** e não tem tela para editar (#70). O certo é `<origem do servidor>/webrtc`, como o web (`conversa-web/src/stores/call.ts:210-213`) |
| Caminho | `call-<chamada>-u-<usuario>` + `/whip` ou `/whep` | igual (gravado pelo padrão `"~^call-"`, `mediamtx.docker.yml:32`) | ✅ igual (`src/chamada/Conversa.Chamada.WebRTC.pas:180`, `:262`) |
| `Location`/`DELETE` | — | — | Não usa (o web também não; o MediaMTX encerra quando o DTLS fecha) |

### 7.2 ICE / TURN (A4 §1.11)

- **Abril:** MediaMTX no próprio Windows do servidor, com o UDP 8189 padrão nas interfaces do host: candidatos *host* alcançáveis na rede local, sem TURN. Não existia `GET /api/ice`.
- **Hoje:** MediaMTX em Docker anuncia **só o IP do container** (`172.30.0.20`), "que só o coturn alcança. Por isso o cliente usa relay-only" (`conversa/bin/mediamtx/mediamtx.docker.yml:20-24`). O coturn escuta **só TCP 3478** (`conversa/bin/coturn/turnserver.conf:15-17`), só retransmite para o MediaMTX (`:36-37`) e sem *relay* TCP (`:41`). As credenciais vêm de **`GET /api/ice`** (`rotas.ts:212`, `chamadas.ts:576-594`): `{iceServers:[{urls: "turn:<host>:3478?transport=tcp"` (ou `turns:` em produção)`, username, credential}], iceTransportPolicy: "relay"}` com `turn_forcar_relay = '1'`.
- **FMX:** a `pion_whep.dll` cria as `PeerConnection` com **`ICEServers: []`**, sem política nem `SettingEngine` (`conversa-webrtc/pion/main.go:169`, `:353`): só sobem candidatos *host* do cliente. O FMX **não chama `GET /api/ice`**, e a API da DLL não tem parâmetro para isso (precisaria de uma função nova, ex.: `WhipConnectEx`). O *gathering* espera sem limite (`main.go:245`, `:440`; o web limita a 5 s). Resultado: o WHIP/WHEP responde por HTTP, mas o ICE **falha** e o estado 3 só vai para o log (`Conversa.Chamada.WebRTC.pas:449-466`) — **Q11**.

### 7.3 Codec e gravação (A4 §2)

- Desde `4bbfb0a` o MediaMTX grava todo `call-*` em fMP4, segmentos de 1 h, retenção pelo parâmetro `gravacao_dias` (padrão 90); **VP8 não é gravado**, H264 e VP9 sim (`mediamtx.docker.yml:27-37`).
- O FMX publica **H264 (libx264) + Opus**, ambos graváveis — o codec está certo. Mas:
  1. **o vídeo é a tela inteira do usuário**, ligado sozinho em toda chamada, inclusive de voz e antes de atenderem (`src/chamada/Conversa.Chamada.pas:502` → `Conversa.Chamada.WebRTC.pas:203-221`; #1). Assim que o ICE for corrigido, **a tela passa a ser gravada no servidor**;
  2. o áudio enviado provavelmente nem sai (#14) e o recebido é inutilizável (#13);
  3. na recepção, só H264: um navegador que publique VP9 (válido pelo contrato) vira lixo no FMX (`main.go:190-197`, #35).

### 7.4 Eventos 51–57 (resumo; detalhe em A4 §3.1)

| Evento | Servidor (hoje) | FMX | Situação |
|---|---|---|---|
| 51 | `iniciar`: a todos menos o criador; `PUT /chamada/usuario`: a todos menos quem adicionou, **inclusive quem já está na chamada** | Cria a chamada; 51 da chamada atual volta a "Recebendo"; outra chamada abre segunda janela no mesmo *singleton* de mídia (#32) | 🔴 |
| 52 | `cancelar`/`finalizar` | Encerra, com uso de objeto liberado (#7) | 🟠 |
| 53 | `recusar`: aos outros **e a mim** | Meu id em "recebendo" → ignorado (#30) | 🟠 |
| 54 | `entrar`: aos outros **e a mim**, emitido antes de quem atende publicar | Assina o *peer* na hora, recebe 404 e desiste: áudio de mão única (#31) | 🔴 |
| 55 | `sair`: aos outros; sem 52 quando termina por saída | 1:1 encerra; grupo nada | 🟠 |
| 56 | `POST /chamada/video` | Não tratado | ⬜ |
| 57 | Sinal entre participantes (`tela`, `ponteiro`, `chat`) | Fora do enum; nem envia nem recebe | ⬜ |

Na sinalização REST, `PUT /chamada/iniciar` sem `tipo` nem `conversa_id` é a **Q14**; o resto das rotas de chamada usadas está compatível (§3, linhas 16–22).

---

## 8. Anexos (A2 §3)

**Fluxo correto (abril e hoje, mesmo contrato — doc 01 §8.2):**

1. SHA-256 do arquivo → `identificador`.
2. `GET /api/anexo/existe?identificador=` → `{existe, ...}`.
3. `PUT /api/anexo` com **JSON** `{identificador, tipo (2 imagem, 3 arquivo, 4 áudio, 5 gravação), nome, extensao, tamanho}` → `{existe:false, id, upload_url, upload_status:0}`; `upload_url` = **PUT pré-assinado no MinIO, 300 s** (`anexos.ts:58-81`; abril `api.pas@56e7cc0:1048-1114`).
4. `PUT <upload_url>` com os bytes, **sem `Authorization`**, direto no `/storage/` (até 1024 MiB, `conversa/bin/nginx/nginx.conf:121-133`).
5. `POST /api/anexo/confirmar?identificador=` → `{confirmado:true, upload_status:1}` (`anexos.ts:83-95`).
6. `PUT /api/mensagem` com `{tipo, ordem, conteudo:<identificador>}`.
7. Download: `GET /api/anexo?identificador=` → `{url}` (GET pré-assinado, 600 s) → baixar da URL **sem `Authorization`**.

É o que o web faz (`conversa-web/src/services/conversaApi.ts:102-161`). Mudanças desde abril: URL assinada montada com o `Host` + `X-Forwarded-Proto` da requisição + `/storage` (antes, parâmetro `s3_endpoint`); 404/400 em vez de 500 (`8e81360`); `client_max_body_size 1m` em `/api/`; `Content-Security-Policy: sandbox` em `/storage/` (`f1ffb14`). Para `existe:true`, `id` vem como **string** e `upload_url` é um **GET** (`anexos.ts:65`) — igual a abril.

**O que o FMX faz (`Conversa.Dados.pas:229-290`, `src/Conversa.Proxy.pas:746-814`):**

| Passo | FMX | Veredito |
|---|---|---|
| 1. Hash | `THashSHA2.GetHashString` (SHA-256) sobre o arquivo **inteiro carregado em memória** num `TStringStream` (`Conversa.Dados.pas:270-272`); compatível com o web | ✅ (memória: #54) |
| 2. `anexo/existe` | `Conversa.Dados.pas:279`, síncrono | ✅ |
| 3. `PUT /anexo` | **Bytes** no corpo (`application/octet-stream`) + `tipo/nome/extensao` na *query* (`src/Conversa.Proxy.pas:794-807`), numa thread solta; **`tipo = 0`** (`Conversa.Dados.pas:280`) | 🔴 Q2 |
| 4. PUT no MinIO | Não existe | 🔴 Q2 |
| 5. `confirmar` | Não chamado (só na unit órfã, X12) | 🔴 Q2 |
| 6. `PUT /mensagem` | Sai logo depois, sem esperar o upload (`Conversa.Dados.pas:286`) | 🔴 a mensagem chega sem o conteúdo (§3.1-9) |
| 7. Download | Trata a resposta de `GET /anexo` como o arquivo (`src/Conversa.Proxy.pas:779`) e grava em `PastaDados\anexos\<identificador>` (`Conversa.Dados.pas:229-241`); nunca usa a URL assinada | 🔴 Q1 |

- **Cache:** pasta `PastaDados\anexos`, nome = identificador (`Conversa.Dados.pas:231`). Como o arquivo nunca é revalidado (`TFile.Exists`, `:232-233`), cada JSON `{url}` gravado fica no cache para sempre (**cache envenenado**, #9): mesmo depois de corrigir o contrato, é preciso limpar a pasta. O identificador vem de outro usuário e vira caminho sem validação (*path traversal*, #26; servidor S20).
- **Quando baixa:** imagem e áudio são baixados **na hora de montar a mensagem**, síncrono, na thread da interface (`Conversa.Dados.pas:599-604`); arquivo só ao salvar (`:352-393`, que **move** o arquivo do cache e usa `nome`/`extensao` do servidor sem sanitizar, #55).
- **Tipos:** o FMX só conhece 0..4 (`TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo, MensagemAudio)`, `src/Conversa.Tipos.pas:220`): envia texto 1, imagem 2, arquivo 3, áudio 4 (`Conversa.Dados.pas:258`). Não há tipo 5.
- **Gravação do microfone:** vai como **tipo 4** com nome `Conversa_Mensagem_Audio<data>.mp3` (`src/chat/chat/frames/chat.editor.audio.pas:169`, `:306-309`), mas o `TAudioCaptureDevice` grava **WAV/AVI RIFF** (conferido pelo cabeçalho de um arquivo em cache, A2 §3): extensão e tipo errados (**Q13**, #57). Na prática nunca sobe (Q2).

---

## 9. Modelos e serialização (A2 §4)

- **Datas:** `TJsonSerializer` com `DateTimeZoneHandling = Utc` + `TDateTimeConverter` (`src/Conversa.Serializer.pas:114-116`). Leitura: `null` → `0`; senão `TTimeZone.Local.ToLocalTime(ISO8601ToDate(valor))` (`:69-88`). O servidor manda ISO-8601 UTC com `Z`, e o FMX converte para o fuso local corretamente ✅. `TDateTime = 0` = "nulo"; o código testa `<> 0` antes de usar (`Conversa.Dados.pas:582-585`).
- **Campos novos e ausentes:** o leitor do RTL pula propriedades desconhecidas (A2 §4, `System.JSON.Serializers.pas:1897-1903` do Delphi). `fixada_ordem`, `arquivada_em`, `excluida_em`, `visivel_em`, `transcricao_*`, `reacoes`, `mensagem_referencia`, `conversa_chat_id` **não quebram o *parse*, mas também não são lidos**. Campos que o FMX espera e não vêm ficam com o valor padrão (0, '' ou `False`).
- **`excluida_em`:** ausente de `TMensagem` (`src/Conversa.Proxy.Tipos.pas:99-111`) e de `TMensagemStatus` (`:116-122`) → Q6.
- **`visivel_em` (agendadas):** o FMX nem envia nem lê. Agendadas de terceiros só aparecem quando o servidor as libera. Benigno.
- **`remetente`:** o servidor manda só o primeiro nome; o FMX ignora e cruza `remetente_id` com o cadastro de `/usuario/contatos` (`Conversa.Dados.pas:567-574`) ✅.
- **Status:** `/mensagens` e `/mensagem/status` devolvem `recebida/visualizada/reproduzida` **booleanos**, e o FMX lê booleanos (`TMensagem`, `TMensagemStatus`) ✅ — diferente do Android, que esperava datas por usuário.
- **Ids:** todos numéricos, exceto `id` **string** em `PUT /anexo` com `existe:true` (`anexos.ts:65`), que o FMX não lê.
- **Tipos de conteúdo 5–8:** o FMX converte com `TTipoConteudo(Ctd.tipo)` (`Conversa.Dados.pas:596`) e, no chat, `TTipo(Pred(Integer(tipo)))` (`src/chat/Conversa.Chat.pas:196`; `TTipo = (Texto, Imagem, Arquivo, MensagemAudio)`, `src/chat/chat/chat.tipos.pas:19`). Nenhum ramo do `case` do visualizador casa (`src/chat/chat/chat.visualizador.pas:150-222`) → bolha vazia (Q7).
- **Histórico de chamadas:** modelo da árvore antiga do servidor (§3.1-23, Q5).

---

## 10. Conclusões

Cada item traz o rótulo (**[NOVA]** ou **[ABRIL]**), a evidência dos dois lados, o efeito para o usuário e o problema correspondente no doc 04. Os rótulos foram conferidos no código e no `git log`; onde o rótulo sugerido não se sustentou, a correção está explicada no próprio item.

### 10.1 QUEBRAS CONFIRMADAS

**Q1 — [ABRIL] Download de anexos: `GET /anexo` devolve `{url}` e o FMX grava esse JSON como se fosse o arquivo.** (doc 04 **#9**)
- FMX: `src/Conversa.Proxy.pas:762-786` (`Result.Dados := Response.ToStream.Bytes`, `:779`); `Conversa.Dados.pas:229-241` (grava em `anexos\<identificador>`, também em erro, e nunca revalida), `:599-604` (baixa imagem e áudio ao montar a mensagem); `src/chat/chat/frames/chat.conteudo.imagem.pas:74` (`Bitmap.LoadFromFile` lança com o JSON); `src/chat/Conversa.Chat.pas:229-238` (o laço do lote não protege cada mensagem).
- Servidor hoje: `anexos.ts:41-56` (`{url}` pré-assinada de 600 s). Abril: `dpr@56e7cc0:322`, `api.pas@56e7cc0:1040-1042` — devolve `{url}` desde `f28ff10` (2026-03-07); antes devolvia os bytes (`rest/conversa.rest.dpr@61b7dbe~1:359-363`).
- **Efeito:** imagens recebidas nunca aparecem e uma imagem **interrompe a exibição do resto do lote**; áudios não tocam; "Salvar" entrega um arquivo com o nome certo e conteúdo `{"url":…}`. O cache fica envenenado: mesmo corrigindo o código, os arquivos antigos continuam errados até limpar a pasta.

**Q2 — [ABRIL, piorada] Upload de anexos: bytes em `PUT /anexo`, `tipo` 0, sem MinIO nem `confirmar`; a mensagem chega vazia.** (doc 04 **#10**)
- FMX: `src/Conversa.Proxy.pas:788-814` (bytes + *query*); `Conversa.Dados.pas:279-280` (`Anexo.Incluir(0, …)`), `:286` (o `PUT /mensagem` sai sem esperar o upload).
- Servidor hoje: `esquemas.ts:74` + `anexos.ts:58-81` (JSON → `{upload_url}`), `anexos.ts:83-95` (`confirmar`); nginx `client_max_body_size 1m` (`conversa/bin/nginx/nginx.conf:24`); conteúdo sem registro em `anexo` é omitido na leitura (`mensagens.ts:441-442`). Abril: `dpr@56e7cc0:331-345` e `api.pas@56e7cc0:1048-1114` (mesmo contrato JSON, desde `f28ff10`); nginx 1024 MiB (`nginx@56e7cc0:12`).
- **Piorada:** em abril, erro do servidor (500) para qualquer tamanho; hoje 400 até 1 MiB e **413 HTML** do nginx acima disso (`97f9341`).
- **Efeito:** nenhum anexo sai do PC. O erro é engolido; o remetente vê a cópia local e acha que enviou; os outros recebem a mensagem **sem o conteúdo** (exceto quando o mesmo arquivo já estava no servidor).

**Q3 — [ABRIL] `GET /mensagem/visualizar` não existe (o servidor só tem `POST`).** (doc 04 **#18**)
- FMX: `src/Conversa.Proxy.pas:723-744` (GET + `Tentativa(5)`); `Conversa.Dados.pas:346-350`; disparado por `src/chat/chat/frames/chat.mensagem.pas:265-270` e `src/chat/Conversa.Chat.pas:157-166`, `:280-290`.
- Servidor hoje: `rotas.ts:112` + `esquemas.ts:66` (POST `{conversa, mensagem}`) → 404 para o GET (`app.ts:66-69`; confirmado no servidor vivo pelo A2). Abril: `dpr@56e7cc0:372` (POST), desde `9b9a32f` (2026-03-10).
- **Efeito:** nada lido no PC é marcado como visualizado: o remetente nunca vê o ✓✓ azul; os contadores do celular e do web não baixam; `/mensagens/novas` devolve as mesmas conversas para sempre; depois de reiniciar o app, contador, *badge* e notificações voltam para mensagens já lidas no PC.

**Q4 — [ABRIL] `GET /conversa/dados` não existe → 404 ao abrir cada conversa; membros de grupo não carregam; chamada em grupo vira `[eu]` → 500.** (doc 04 **#23**)
- FMX: `src/Conversa.Proxy.pas:572-605` (rota em `:582`); `src/chat/Conversa.Chat.pas:173-178` (`SetConversa`); membros só de `/conversas` = `[eu, destinatário]` (`Conversa.Dados.pas:207-209`) e de quem já mandou mensagem (`:567-568`); o botão de chamada usa essa lista (`src/chat/Conversa.Chat.pas:151-155`).
- Servidor hoje: ausente em `rotas.ts`; uma chamada só consigo mesmo faz `notificarMembrosChamada` lançar erro → 500 (`notificacoes.ts:33-35`), depois de a chamada já estar gravada. Abril: ausente em `dpr@56e7cc0` (a rota existia só na árvore antiga `rest/`, `rest/conversa.rest.dpr@61b7dbe~1:308`).
- **Efeito:** o cabeçalho do grupo fica sem membros; chamada em grupo só inclui quem já falou na conversa ou falha com 500 (e o FMX segue com `FID = 0`, publicando em `call-0-u-<eu>`); tudo em silêncio. Substituto: `GET /conversa/usuarios?conversa=` (`conversas.ts:204-221`).

**Q5 — [ABRIL] Histórico de chamadas com um modelo que o servidor não devolve.** (doc 04 **#33**)
- FMX: `src/Conversa.Proxy.Tipos.pas:194-215` (`TChamadaHistorico`); `src/Conversa.Proxy.pas:313-337` (sem filtros); telas `src/chamada/Conversa.Chamada.Listagem.Item.pas:78-131` e `Conversa.Chamada.Detalhe.pas:76-126`.
- Servidor hoje: `chamadas.ts:416-450` (`{id, tipo, status, criado_em, criado_por, conversa_id, iniciada, finalizada, duracao, participantes[]}`); a única mudança desde abril são as datas com `Z` (`95430ba`). Abril: `api.pas@56e7cc0:2445-2591`, mesma forma. O modelo do FMX veio da árvore antiga `rest/` (servidor `927bf19` → apagado em `eb59c61`, 2026-03-13).
- **Efeito:** a lista "Chamadas" mostra itens sem nome, ícone, status nem duração.

**Q6 — [NOVA] Mensagem oculta aparece com o conteúdo original.** (doc 04 **#17**)
- FMX: `src/Conversa.Proxy.Tipos.pas:99-111` e `:116-122` (sem `excluida_em`); `Conversa.Dados.pas:591-606` monta os conteúdos; render em `src/chat/chat/chat.visualizador.pas:150-222`.
- Servidor hoje: exclusão lógica (`mensagens.ts:293-326`), `excluida_em` na resposta (`:611`) e no status (`:645-652`), conteúdo **não filtrado** (`:406-456`); `migracoes/031.sql`; desde `b94b504` (2026-10-02). Abril: `DELETE` apagava de fato (`api.pas@56e7cc0:941-969`).
- **Efeito:** quem ocultou uma mensagem no web ou no celular continua com ela **visível, com o texto/arquivo original**, no FMX dos outros membros (problema de privacidade). A prévia da lista diz "Mensagem oculta" (`conversas.ts:127`), mas o chat mostra tudo.

**Q7 — [ABRIL para 5–6; NOVA para 7–8] Conteúdos tipo 5–8 aparecem como bolha vazia.** (doc 04 **#22**)
- FMX: `TTipoConteudo` só 0..4 (`src/Conversa.Tipos.pas:220`); `Conversa.Dados.pas:596`; `src/chat/Conversa.Chat.pas:196`; o `case` do visualizador tem 4 ramos (`src/chat/chat/chat.visualizador.pas:150-222`); a notificação herda o texto da conversa anterior do lote (`src/chat/Conversa.Chat.Listagem.pas:284-288`, #42).
- Servidor hoje: tipos 1, 6, 7, 8 devolvidos como texto (`mensagens.ts:406-420`) e 2–5 como anexo (`:424-442`); 7 = figurinha (`315464b`, 2026-10-03), 8 = enquete (`8031fa5`, 2026-10-06). Abril: tipo 5 (gravação) e 6 (resumo de chamada) já existiam (`api.pas@56e7cc0:1492`, `:1511`, `:2656-2786`).
- **Efeito:** toda gravação de áudio feita no web (5), todo resumo de chamada (6), figurinha (7) e votação (8) aparece como bolha vazia; a notificação mostra o texto errado.
- **Sobre o `ERangeError` em Debug** (citado em A2 Q7 e no doc 04 #22): **não confirmado, e improvável pela leitura.** O build Debug liga a verificação de faixa (`Conversa.dproj:194-195`), mas o Delphi não aplica `{$R+}` a conversões explícitas como `TTipoConteudo(Ctd.tipo)` e `TTipo(Pred(…))`, e não há vetor indexado por esses tipos (grep). O efeito certo é a bolha vazia; só um teste em Debug fecha a dúvida.

**Q8 — [ABRIL] `/mensagens/novas` com `ultima` (o servidor usa `desde`).** (doc 04 **#19**)
- FMX: `src/Conversa.Proxy.pas:290` (`AddPair('ultima', …)`), chamado síncrono na interface a cada WS 2 (`Conversa.Dados.pas:474-478`).
- Servidor hoje: `esquemas.ts:68` + `mensagens.ts:694-725` (só `desde`; vazio = "desde sempre"; exclui visualizadas desde `2299a5c`). Abril: `dpr@56e7cc0:404-410` já com `desde` — a troca foi feita **no próprio `56e7cc0`** (antes era `Field('ultima').AsInteger`).
- **Efeito:** funciona por acaso (devolve "tudo que não foi visualizado"), mas cada WS 2 vira N `GET /mensagens` com a janela congelada durante o primeiro; com Q3, a lista nunca esvazia; alimenta a corrida "Mensagem já adicionada!" (#11).

### 10.2 QUEBRAS PROVÁVEIS / DE AMBIENTE

**Q9 — [ABRIL] URL do WebSocket no HEAD · [NOVA] `wss` obrigatório, que depende do OpenSSL 1.0.2 ausente.** (doc 04 **#5**; a URL também em #81)
- **Rótulo corrigido** (sugerido: só [NOVA]). Conferido: a regra do HEAD, `ws://host:(8000 + porta)` (`Conversa.Dados.pas@4759ba5:429-431`, de `e970c92`, 2025-08-03), deixou de valer em `2b9a06d` (2026-03-08) — em abril o WS estava em 9090 e atrás do nginx em `/ws/` (`dpr@56e7cc0:571`; `nginx@56e7cc0:48-57`, `:113-114`), e nenhum Host natural dá 9090. Logo, o HEAD **já não conectava em abril** → [ABRIL]. A versão *staged* (`wss://host[:porta]/ws/`, `Conversa.Dados.pas:432-437`) acerta o servidor de abril e o de hoje. O que é **[NOVA]**: em abril o nginx também escutava na **80 sem TLS** com `/ws/` (`nginx@56e7cc0:94`, `:113-114`), então o *staged* com Host `http://…` funcionava sem OpenSSL; desde `97f9341` o nginx de desenvolvimento só aceita TLS (`conversa/bin/nginx/desenvolvimento/servidor.conf:2-7`) e a produção tem TLS na borda — o `wss` passou a ser obrigatório.
- FMX: `lib/bird-socket-client/Bird.Socket.Client.pas:263-272` (Indy/OpenSSL, sem verificação de certificado); `ssleay32.dll`/`libeay32.dll` ausentes de `bin/` e do `PATH` (conferido).
- **Efeito:** com o HEAD, não há tempo real. Com o *staged* e Host `https`, o `Connect` falha com "Could not load SSL library", a exceção interrompe o login no meio e o app segue sem tempo real (o REST funciona, o que confunde o diagnóstico). Com as DLLs copiadas à mão, qualquer certificado é aceito e o JWT pode ser capturado na rede. Contorno só para desenvolvimento no próprio PC do servidor: Host `http://localhost:8080/api/` (§5.1).

**Q10 — [NOVA] Quadros de controle vazios (*ping* do Bun após ~120 s ocioso) derrubam o socket — não confirmado.** (doc 04 **#3**)
- FMX: `Bird.Socket.Client.pas:573-579` (tamanho 0 deixa o quadro "aberto"), `:583-599` (PONG só com carga); o FMX não envia nada depois do login.
- Servidor hoje: `websocket.ts:56` sem `idleTimeout`/`sendPings` → padrões do Bun (pela documentação: 120 s e *ping* automático sem carga), desde `95430ba` (2026-09-26). **Não confirmado** no código do servidor (S21). Abril: o servidor Bird não mandava *ping* (`ws.pas@56e7cc0`); o Node de `97f9341` (`@fastify/websocket`) também não.
- **Efeito provável:** o tempo real morre ~2 min depois de abrir o app, e um evento que chegue nesse intervalo vem corrompido. **Teste:** abrir o app, não mexer por 3 min e mandar uma mensagem pelo web; ou observar a bolinha "online" do usuário do PC apagar no web.

**Q11 — [NOVA] Chamadas sem mídia: sem TURN, base errada, ICE só *host*.** (doc 04 **#12**)
- FMX: `conversa-webrtc/pion/main.go:169`, `:353` (`ICEServers: []`); `src/configuracoes/Conversa.Configuracoes.pas:51-52`, `:66-67` (`MediaMtxBase` = `http://localhost:8889`); nenhuma chamada a `GET /api/ice`.
- Servidor hoje: MediaMTX em Docker anunciando só `172.30.0.20` (`conversa/bin/mediamtx/mediamtx.docker.yml:20-24`), 8889 publicado só em `127.0.0.1` (`conversa/docker-compose.yml:123-124`), coturn só TCP (`conversa/bin/coturn/turnserver.conf:15-17`), credenciais em `GET /api/ice` (`rotas.ts:212`, `chamadas.ts:576-594`) — desde `aa61b78`/`97f9341` (2026-09-12/13). Abril: MediaMTX nativo no Windows com UDP nas interfaces do host (`mediamtx.yml@56e7cc0:13-15`), alcançável por candidatos *host*.
- **Efeito:** o WHIP/WHEP responde, mas o ICE falha: chamadas **mudas**, sem aviso (o estado 3 só vai para o log). Somam-se os defeitos próprios da mídia do FMX (#13, #14, #31), que continuariam depois de corrigir o ICE.

**Q12 — [NOVA] Porta de desenvolvimento 4430 → 443 no `conversa.json`.** (doc 04 **#70**, configuração do servidor só na primeira vez; não há número próprio para a porta)
- FMX: `bin/Conversa/conversa.json` local com `"Host":"https://localhost:4430/api/"`; o comentário do *staged* ainda cita `https://host:4430/api` (`Conversa.Dados.pas:428-431`); o endereço só pode ser trocado na tela da primeira execução ou editando o arquivo (`src/configuracoes/Conversa.Configurar.Conexao.pas:48-81`).
- Servidor hoje: `conversa/bin/nginx/desenvolvimento/servidor.conf:2` (443), desde `97f9341`; compose `"${CONVERSA_PORTA:-443}"` (`conversa/docker-compose.yml:170-171`). Abril: `listen 4430 ssl` (`nginx@56e7cc0:28`).
- **Efeito:** com a configuração de desenvolvimento existente, todo REST dá "conexão recusada" até o usuário corrigir o endereço. É configuração, não código. Atenção: **não** escrever `https://host:443` explicitamente — a URL assinada do MinIO é montada sem `:443` e a assinatura pode não bater (dedução de `minio.ts`, não confirmado; A7 §4.4).

**Q13 — [ABRIL] Gravação de áudio enviada como tipo 4, com extensão `.mp3` sobre um arquivo WAV.** (doc 04 **#57**)
- FMX: `src/chat/chat/frames/chat.editor.audio.pas:169` (nome `.mp3`), `:306-309` (`TTipo.MensagemAudio` → tipo 4); o `TAudioCaptureDevice` grava RIFF (A2 §3). Código de 2024 (último commit da unit: `da02b29`, 2024-10-26).
- Servidor: o tipo 5 "gravação de áudio" já existia em abril (`api.pas@56e7cc0:1511`) e existe hoje (`anexos.ts:31`); o web trata 5 como gravação (doc 03).
- **Efeito:** semântico e de formato — o destinatário veria um "áudio" com extensão errada, que pode não tocar; sem `POST /conversa/gravando`. Na prática nunca chega, por causa da Q2.

**Q14 — [ABRIL] `PUT /chamada/iniciar` sem `tipo` e sem `conversa_id`.** (doc 04 **#62**)
- **Rótulo confirmado como [ABRIL]** (estava "a confirmar"). FMX: `src/chamada/Conversa.Chamada.pas:455-462` (só `usuarios`); o FMX lê `tipo` como simples/grupo (`src/Conversa.Proxy.Tipos.pas:142-146`) e decide o fim por ele (`Conversa.Chamada.pas:349`, `:399-405`).
- Servidor hoje: `esquemas.ts:86` (`tipo?`, `conversa_id?`), `chamadas.ts:90` (sem `tipo`: 2 participantes → 1, senão 2), `:473-478` (regras de status por simples/grupo), `:510` (sem `conversa_id`, sem resumo). Abril: as **mesmas** regras (`api.pas@56e7cc0:2003-2006`, `:2693-2694`), e o web de abril já mandava `{tipo, usuarios, conversa_id}` com `tipo` = áudio/vídeo (`bin/web/assets/style-DuUMYjIa.js@56e7cc0`). Nada disso mudou entre `56e7cc0` e hoje.
- **Efeito:** chamada iniciada no FMX não gera a mensagem-resumo (tipo 6) na conversa nem chat da chamada; como o web usa `tipo` para áudio/vídeo e o FMX para "número de pessoas", uma 1:1 **de vídeo** iniciada no web (tipo 2) nunca termina no FMX pela saída do outro (55), e uma **de áudio em grupo** (tipo 1) termina na primeira saída. Ambiguidade do servidor: S11 (doc 08).

### 10.3 Latentes (código morto com contrato errado)

Só apareceriam se o código fosse ligado; todos já eram incompatíveis em abril (**[ABRIL]**). Consolidados no doc 04 **#73** (e #80, código morto em geral).

| Onde (FMX) | Contrato errado | Servidor hoje | Resultado se ligado |
|---|---|---|---|
| `src/Conversa.Proxy.Extras.pas:151-177` | Token próprio (`TAPIExtras.FToken`) que ninguém preenche; sem ele não vai `Authorization` (`:163-164`) | Todas as rotas, exceto login e cadastro, exigem token (`rotas.ts:43`) | **401** em tudo da unit |
| `src/Conversa.Proxy.Extras.pas:241-257` (`:247`) | `alterar-senha` com `{senha_atual, senha_nova}` | `{senha_atual, senha}` (`esquemas.ts:30`); abril igual (`dpr@56e7cc0:130`) | 400 `Campo "senha" é obrigatório…` |
| `:358-390` (`:363`, `:380`) | `digitando`/`gravando` com `{conversa_id}` | `{id}` (`esquemas.ts:41`); abril igual (`dpr@56e7cc0:274-295`) | 400 |
| `:282-298` (`:287-288`) | `reproduzir` com `{mensagem_id, conversa_id}` | `{conversa, mensagem}` (`esquemas.ts:66`) | 400 |
| `:322-354` (`:336-339`) | `PUT /mensagem` com `referencia:{tipo, destino_mensagem_id}` | `mensagem_referencia:{tipo, origem_mensagem_id}` (`esquemas.ts:55`, `mensagens.ts:185-203`) | **200 silencioso, sem a referência** (abril: 500) |
| `src/Conversa.Proxy.pas:422-450` | `PUT /dispositivo` | Só existe `PATCH /dispositivo` (`rotas.ts:52`); abril idem | 404 |
| `src/Conversa.Proxy.pas:363-384` | `PATCH /usuario` com `TReqUsuario` sem `id` (`src/Conversa.Proxy.Tipos.pas:67-73`) | `id` obrigatório (`esquemas.ts:37`) | 400 |
| `src/Conversa.Proxy.Extras.pas:445-484` | `PATCH /sip` sem garantia de `id` | `id` obrigatório (`esquemas.ts:121-124`) | 400 se faltar |

### 10.4 Resumo

| Q | Rótulo | Área | doc 04 |
|---|---|---|---|
| Q1 | [ABRIL] | Download de anexos | #9 |
| Q2 | [ABRIL, piorada] | Upload de anexos | #10 |
| Q3 | [ABRIL] | Visualizar (GET × POST) | #18 |
| Q4 | [ABRIL] | `/conversa/dados` | #23 |
| Q5 | [ABRIL] | Histórico de chamadas | #33 |
| Q6 | [NOVA] | Mensagem oculta | #17 |
| Q7 | [ABRIL] 5–6 · [NOVA] 7–8 | Conteúdos 5–8 | #22 |
| Q8 | [ABRIL] | `/mensagens/novas` | #19 |
| Q9 | [ABRIL] URL do HEAD · [NOVA] `wss` obrigatório | WebSocket / TLS | #5 (#81) |
| Q10 | [NOVA] (não confirmado) | *Ping* vazio | #3 |
| Q11 | [NOVA] | Mídia de chamada | #12 |
| Q12 | [NOVA] | Porta 4430 → 443 | #70 |
| Q13 | [ABRIL] | Gravação como tipo 4 / `.mp3` | #57 |
| Q14 | [ABRIL] | `iniciar` sem `tipo`/`conversa_id` | #62 |

Placar: **9 [ABRIL]** (Q1–Q5, Q8, Q13, Q14 e a parte 5–6 da Q7), **5 [NOVA]** (Q6, Q10, Q11, Q12 e a parte 7–8 da Q7), e a Q9 com as duas partes. O servidor novo também **consertou** uma quebra de abril (`PUT /conversa/usuario` idempotente, §3.1-5) e trocou vários 500 por 404/400. A regra de push que afeta o desktop (§6) não mudou desde abril.

---

Documento gerado por auditoria somente leitura; nenhum arquivo do servidor, do web ou do FMX foi modificado.
