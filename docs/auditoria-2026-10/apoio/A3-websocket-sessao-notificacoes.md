> **Relatório de apoio da auditoria de 2026-10-08** — frente: WebSocket, sessão, eventos, presença, notificações e ciclo de vida.
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A3 — WebSocket, sessão, eventos em tempo real, presença, notificações e ciclo de vida (cliente Windows FMX)

> Auditoria de 2026-10-08, **somente leitura** e **estática** (nada foi compilado nem executado).
>
> | Repositório | Estado lido |
> |---|---|
> | `conversa-windows-fmx` (alvo) | branch `chamada`, HEAD `4759ba5` (2026-04-26) **+ alterações staged** em `Conversa.Dados.pas` (URL do WebSocket) e `src/chamada/Conversa.Chamada.WebRTC.pas` |
> | `conversa` (servidor Bun + Elysia) | HEAD `779c8ed` (o contrato do doc 01 foi validado em `5cad911`; `779c8ed` só mexe no `.bat` de desenvolvimento) |
> | `conversa` de abril (Delphi) | `56e7cc0` (só para comparação) |
> | `conversa-web` (referência) | HEAD `e8d82cb` |
>
> Referências cruzadas: `conversa-android-kotlin/docs/auditoria-2026-10/01-contrato-servidor-atual.md` (§2, §6, §7, §15, §19), `03-inventario-web.md` (§1.4–1.6, AUT-03/04/05, ENV-15/16, NOT-01..06, PRE-01, GER-02), `08-pendencias-servidor.md` (S2, S3, S13).
>
> Convenções:
> - Sem prefixo, os caminhos são relativos à raiz do `conversa-windows-fmx`.
> - `srv:` = repositório `conversa`; `web:` = `conversa-web`.
> - `delphi:` = fontes do Delphi 12 instaladas na máquina (`C:\Program Files (x86)\Embarcadero\Studio\23.0\source\...`). Uso essas fontes só para confirmar o comportamento das bibliotecas (Indy, RTL, FMX).
>
> Vereditos: ✅ compatível · 🟠 funciona parcialmente ou por acaso · 🔴 quebrado/incompatível · ⬜ não tratado.
> Quando algo não foi confirmado no código, está escrito **"não confirmado"**. Senhas e tokens não aparecem neste documento; o `conversa.json` local **não foi lido**.

---

## Sumário executivo

1. **O tempo real do desktop não se mantém.** O WebSocket abre uma única vez, logo depois do login (`Conversa.Dados.pas:420-451`). Faltam várias peças:
   - **não há reconexão** nem detecção de queda: nenhum ouvinte de `OnClose`/`OnError`, e o `AutoReconnect` do Bird fica desligado;
   - não há polling de reserva nem faixa de aviso: o `TEventoStatusConexao` nunca é enviado.

   Qualquer queda (rede, servidor reiniciado, PC suspenso, 502 do nginx) deixa o app sem eventos **até ser reiniciado**. Em RELEASE, o "X" só esconde a janela e não existe "Sair" (**A3-01**).
2. **O leitor de frames do Bird quebra com frame de controle sem carga** (`Bird.Socket.Client.pas:567-580`):
   - não responde o PONG e desalinha o fluxo;
   - pelos padrões do Bun (idle 120 s, pings automáticos; **não confirmado no código do servidor**), o servidor manda exatamente esse ping vazio quando o cliente fica 2 min sem enviar nada. O FMX não envia nada depois do login.

   Desfecho provável: **a conexão cai ~2 min depois de abrir o app** (**A3-02**, precisa de teste).
3. **Desktop conectado = celular sem push.** O servidor suprime o push FCM se o usuário tem **qualquer** WebSocket autenticado (`srv:src/notificacoes.ts:71`, `srv:src/websocket.ts:131-133`). Um cliente de bandeja, sempre ligado, faria o celular parar de receber push sempre que o PC estiver ligado: com o usuário fora, com a tela bloqueada e até com o token vencido (**A3-03**).

   Hoje os defeitos A3-01/A3-02 "mascaram" o problema. **Corrigir a reconexão sem tratar isso piora a experiência no celular.**
4. **Sessão sem renovação e 401 ignorado.** O JWT vale 12 h e nenhuma rota trata 401: as falhas são silenciosas (`TErroServidor` não tem assinante). Depois de 12 h o desktop não carrega mais nada, mas, se o socket ainda estiver vivo, continua "online" e suprimindo push (**A3-04**).
5. **"Marcar como visualizada" nunca chega ao servidor.** O FMX usa `GET /mensagem/visualizar?...`, e o servidor só tem `POST` com corpo (→ 404). Efeitos:
   - leituras feitas no PC não aparecem para o remetente nem nos outros aparelhos;
   - depois de reiniciar o app, as mesmas mensagens voltam como não lidas e notificam de novo (**A3-05**).
6. **Transporte inseguro e frágil:**
   - **TLS do WebSocket sem validar certificado** (Indy com `VerifyMode` vazio): o JWT vai na primeira mensagem (**A3-06**);
   - as DLLs do OpenSSL 1.0.2 exigidas pelo Indy (`ssleay32.dll`/`libeay32.dll`) **não estão** no repositório, nem em `bin/`, nem no PATH, e o 1.0.2 está sem suporte desde 2019 (**A3-07**);
   - `Connected` do Indy **lê do socket** e é chamado em 3 threads ao mesmo tempo (**A3-08**).
7. **Evento 2 (nova mensagem):**
   - chama `GET /mensagens/novas?ultima=<id>`, mas o servidor só conhece `desde`, então devolve todas as conversas com não lidas "desde sempre";
   - abre um `GET /mensagens` por conversa;
   - duas notificações seguidas, ou o WS 2 **duplicado** quando o usuário tem mais de um aparelho com token, disparam buscas paralelas, e a segunda levanta **"Mensagem já adicionada!"** em diálogo (**A3-09**).
8. **Eventos não tratados:** 4, 5, 7, 56, 57, 60, 61 e 62. O FMX **não tem presença, digitando/gravando, reações em tempo real, atividades nem enquetes**. Os 51–55 são tratados, mas 53/54 "ao próprio" não param o toque quando a chamada foi atendida ou recusada em outro aparelho (**A3-12**).
9. **Notificações** usam janelas FMX próprias (canto inferior direito, TOPMOST, sem roubar foco), sem toast nativo. Problemas:
   - use-after-free no clique e no fechamento automático (**A3-10**);
   - `Exit` no lugar de `Continue`, que descarta as outras conversas do lote, e texto herdado em mensagens de áudio (**A3-17**);
   - notificam conversas arquivadas;
   - chamada recebida **sem toque**;
   - vazamento de GDI no contador da barra de tarefas (**A3-20**).
10. **Senha salva sempre**, com AES-CBC de IV fixo e chave = serial da placa-mãe (legível por WMI) + "sal" gravado junto. No modo portátil, o `conversa.json` é compartilhado por todos os usuários do Windows (**A3-11**). Não há logout (**A3-23**).

---

## 1. Arquitetura do tempo real no FMX (estado real)

```
Conversa.dpr:69-86
 └─ Inicializacoes.Iniciar (Conversa.Inicializacoes.pas:22-41)
      ├─ instância única (só RELEASE)  ── IsApplicationAlreadyRunning → traz a outra para frente e sai
      ├─ TConfiguracoes.Load (conversa.json)
      └─ UserActivity.IniciarMonitoramento (TTask: GetLastInputInfo a cada 100 ms; ocioso ≥ 1 s)
 └─ TTelaInicial.Create (Conversa.Tela.Inicial.view.pas:88-102): Dados := TDados.Create; ícone de bandeja (Shell_NotifyIcon)
      └─ FormShow → tmrShow (30 ms) → Iniciar (:186-195)
           ├─ Host vazio? → tela "Configurar conexão"
           ├─ TConexaoFalhaInicio.FalhaConexao → Dados.ServerOnline = True SEMPRE (Conversa.Dados.pas:324-339)
           └─ TLogin.New (Conversa.Login.pas:58-76): auto-clique se usuário+senha salvos
                └─ Dados.Login → POST /api/login (síncrono, thread da UI) → [PATCH /api/dispositivo se o id mudou]
                └─ ExibirTelaPrincipal (:223-234):
                     GET /usuario/contatos (síncrono) → TPrincipalView → GET /conversas (thread) → IniciarMonitoramento
                         └─ TBirdSocketClient.New(wss://host[:porta]/ws/)   (Conversa.Dados.pas:432-439)
                            Connect ─ thread da UI: TCP + TLS (Indy/OpenSSL) + upgrade HTTP (sem timeout de leitura)
                            Send {"tipo":1,"token":...}  (uma vez; nunca mais)
                              ├─ TTask LEITOR (Bird :533-636): ReadByte… → TThread.Queue → TDados.NotificacaoSocket (UI)
                              │     ├─ 51..55 → TConversaChamadas.ProcessarSocket → GET /chamada/dados SÍNCRONO → card + janela
                              │     ├─ 2  → GET /mensagens/novas?ultima= SÍNCRONO → (ForceQueue) → GET /mensagens por conversa (threads)
                              │     │        → TExibirMensagem (ForceQueue) → notificação + som
                              │     ├─ 3  → GET /mensagem/status (thread)
                              │     ├─ 40 → GET /conversas (thread)
                              │     ├─ 0  → raise (diálogo de erro)
                              │     └─ 4,5,7,9,56,57,60,61,62 → ignorados
                              └─ TTask HEARTBEAT (Bird :716-740): a cada 500 ms chama Connected (que LÊ do socket) e não envia nada
   Sem: reconexão · ping do cliente · polling · faixa de "sem conexão" · /contatos/online · /chamadas/pendentes · /atividades/novas · 401
```

Eventos internos: `TEventBase<T,T2>.Send` usa `TThread.ForceQueue` (`src/Conversa.Evento.Base.pas:117-131`), e o resultado das chamadas REST assíncronas volta na thread da UI. Os `TEvento*` "simples" usam `TMessageManager.DefaultManager.SendMessage` síncrono na thread que chama.

---

## 2. WebSocket

### 2.1 Biblioteca e transporte

| Item | FMX | Evidência |
|---|---|---|
| Biblioteca | `TBirdSocketClient` (cópia local do *bird-socket-client*, sem versão declarada), subclasse de `TIdTCPClient` do **Indy 10**. O frame WebSocket é montado e lido à mão, byte a byte | `lib/bird-socket-client/Bird.Socket.Client.pas:29`, `:348-408`, `:523-641` |
| TLS | `TIdSSLIOHandlerSocketOpenSSL` criado sozinho quando a URL é `wss`; `Method := sslvTLSv1_2` (na prática, só TLS 1.2) | `Bird.Socket.Client.pas:263-272` |
| DLLs do TLS | O Indy do Delphi 12 carrega **`ssleay32.dll` + `libeay32.dll` (OpenSSL 1.0.x)** no Windows (`delphi:Indy10/Protocols/IdSSLOpenSSLHeaders.pas:19590-19598`; cabeçalhos `OPENSSL_VERSION_NUMBER = $1000105f`, `:5052`). **Nenhuma** das duas está no repositório nem em `bin/`, e `where` não as encontra no PATH desta máquina. O REST usa `TNetHTTPClient` (WinHTTP/SChannel, `REST.API.pas:197`), que não depende do OpenSSL. Resultado: o login funciona e o `wss://` falha | — |
| Validação do certificado | **Nenhuma.** `TIdSSLOptions.Create` não define `VerifyMode` (`delphi:IdSSLOpenSSL.pas:2452-2457`), e o Bird não define `VerifyMode`, `VerifyDepth`, `OnVerifyPeer` nem `RootCertFile`. SNI é enviado (`delphi:IdSSLOpenSSL.pas:3792`) | `Bird.Socket.Client.pas:263-272` |
| Assimetria com o REST | O REST (WinHTTP) valida pela loja do Windows; em desenvolvimento, a CA do mkcert precisa estar instalada. O WS aceita qualquer certificado | — |

### 2.2 URL

- **HEAD `4759ba5`**: `ws://` com porta `8000 + porta do Host` (servidor de abril, porta 9090). **Não funciona com o servidor atual.**
- **Staged:** `TURI.Create(Configuracoes.Host)`. O esquema vira `wss` se o Host for `https` (senão `ws`), e o caminho vira **`/ws/` com barra final** (`Conversa.Dados.pas:432-438`).
  - Com o Host no formato documentado (`https://<host>[:porta]/api`), a URL fica `wss://<host>[:porta]/ws/`, que bate com o nginx (`srv:bin/nginx/nginx.conf:109-114`) e com o Elysia (`srv:src/websocket.ts:56`). ✅
- Limitações:
  - prefixo de caminho do Host (ex.: proxy em `https://empresa/conversa/api`) é descartado. O web resolve isso com `VITE_WS_PATH`;
  - Host sem esquema faz o `TURI.Create` levantar exceção no meio do `ExibirTelaPrincipal`.

### 2.3 Handshake HTTP

- Cabeçalhos enviados (`Bird.Socket.Client.pas:138-173`):
  - `GET /ws/ HTTP/1.1`;
  - `Host: <host>:<porta>`;
  - `Connection: keep-alive, Upgrade`;
  - `Upgrade: WebSocket` (com maiúsculas);
  - `Sec-WebSocket-Version: 13`;
  - `Sec-WebSocket-Key`.
- O nginx reescreve `Connection` para `upgrade` e repassa `Upgrade: $http_upgrade` (`srv:bin/nginx/nginx.conf:39-42`, `:94-95`).
  - O RFC 6455 manda comparar o valor sem diferenciar maiúsculas. Que o Bun/Elysia aceite `WebSocket` é **não confirmado** (o código do servidor não trata disso).
  - Recomenda-se mandar `websocket`.
- A resposta é validada (101, `Upgrade: websocket`, `Sec-WebSocket-Accept`) em `:454-470`.
- O handshake roda **na thread da UI** (`Connect` → `ReadFromWebSocket` → `IsValidWebSocket`, `:276-279`, `:472-516`):
  - conexão TCP: tempo limite padrão do Windows (~20 s);
  - leitura: **sem tempo limite** (`ReadTimeout` padrão = `IdTimeoutDefault = -1`, `delphi:Indy10/System/IdGlobal.pas:799`).
  - Um servidor que aceita o TCP e não responde **congela a interface indefinidamente**.
- Falha no upgrade (404, 502 do nginx com a API reiniciando, cabeçalho inválido): é capturada em `IsValidWebSocket` → `HandleException` → `Close`, e `Connect` **retorna normalmente** (`:529-530` sai antes do `raise` de `:637-638`). O login no socket vira no-op (`Send` checa `Connected`, `:651-652`). **Nada é mostrado ao usuário.**

### 2.4 Login no socket

- Envio: `{"tipo":1,"token":"<jwt>"}` uma única vez, logo depois do `Connect`, na thread da UI (`Conversa.Dados.pas:442-450`). O formato confere com `srv:src/websocket.ts:79-90`. ✅
- O servidor **não confirma** o sucesso. O FMX também não espera confirmação (correto).
- Erro: o servidor manda `{"tipo":0,"message":"Token inválido ou expirado"}` e **não fecha** (`srv:src/websocket.ts:83-88`). O FMX faz `raise Exception.Create(message)` dentro do callback (`Conversa.Dados.pas:486-489`):
  - a exceção sobe da fila (`TThread.Queue`) e vai para `ApplicationHandleException` (`delphi:rtl/common/System.Classes.pas:16337-16341`), que abre um diálogo genérico;
  - o socket continua aberto e **mudo**;
  - não há novo login.
- Tipo 9 (JSON ilegível): não está no enum do FMX e é ignorado. Inofensivo, porque o FMX só envia JSON válido.
- O token **nunca é reenviado**. Não existe "segunda conexão".

### 2.5 Leitura de frames (parser próprio)

`Bird.Socket.Client.pas:533-636`, executado num `TTask`:

| Caso | Comportamento | Veredito |
|---|---|---|
| Texto (op 1) com tamanho 1..125, 126 (16 bits) ou 127 (64 bits) | Lê byte a byte e dispara `TriggerOnMessage` (`:619-622`, `:742-750` → `TThread.Queue`) | ✅ |
| **Frame de tamanho 0** (ex.: PING vazio, PONG vazio) | Em `:573-579`, `LSize = 0` faz `LPosition := 0`, mas o `Inc(LPosition)` incondicional deixa `LPosition = 1`, com `LLinFrame` ainda `True`. O frame nunca "completa" (a conclusão só é testada depois de anexar um byte, `:583-584`): **sem PONG**. O **primeiro byte do frame seguinte é lido como byte de tamanho**, o que desalinha todo o fluxo | 🔴 |
| PING com carga | Responde PONG com a mesma carga (`:590-599`). PONG recebido também é "respondido" com PONG (inútil, inofensivo) | ✅ |
| CLOSE (op 8) | Responde o close (`Self.Close`, que espera 200 ms) e sai do laço | ✅ |
| Fragmentação (FIN=0 / op 0) | O primeiro byte com o bit 7 zerado é descartado (`:550`) e o fluxo desalinha | 🔴 (o Bun não fragmenta mensagens pequenas; risco baixo) |
| Op reservado | `HandleException` + `Close` | ✅ |

Envio (`EncodeFrame`, `:348-408`):
- o comprimento de 64 bits é escrito com **4** bytes em vez de 8 (`:380-388`), o que corrompe frames ≥ 64 KiB. Hoje o FMX só envia o login (curto);
- a máscara usa `Random(255)` (não criptográfico).

### 2.6 Keepalive / ping

- **O cliente não envia nada** depois do login: não há ping de aplicação nem de protocolo.
- O "heartbeat" do Bird (`:716-740`) só chama `OnHeartBeatTimer`, e **ninguém o assina** (grep: só a biblioteca). Mesmo assim, ele chama `Connected` a cada 500 ms (ver 2.8).
- Servidor: `Elysia().ws('/ws/', { message, close })` sem `idleTimeout`/`sendPings` (`srv:src/websocket.ts:56-117`; nenhuma opção em `srv:src/servidor.ts:31`). Valem os padrões do Bun: pela documentação do Bun, `idleTimeout` 120 s e `sendPings: true`. **Não confirmado no código.**
  - No uWebSockets (base do Bun), quando passa o tempo ocioso sem **receber** dados, o servidor manda um PING de controle **sem carga** e fecha a conexão se não houver resposta. O frame exato (`89 00`) também é **não confirmado** neste repositório.
- nginx: `proxy_read_timeout`/`proxy_send_timeout` de 3600 s em `/ws/` (`srv:bin/nginx/nginx.conf:109-114`).
- **Consequência provável** (A3-02): o FMX não envia nada, então ~120 s depois do login o Bun manda o ping vazio. O parser do Bird não responde e o Bun fecha por tempo esgotado. Sem reconexão (2.7), o desktop fica sem tempo real cerca de 2 min depois de abrir.
  - **Teste para confirmar:** abrir o app, não mexer por 3 min e mandar uma mensagem pelo web. Alternativa: observar no web a bolinha de "online" do usuário do desktop apagar ~2 min depois do login.
- Também não há `SO_KEEPALIVE` no TCP. Depois de suspender o PC, o socket pode ficar "meio aberto": `Connected = True`, mas nada chega.

### 2.7 Reconexão, backoff e "geração"

- **Inexistente.**
  - `FAutoReconnect := False` no construtor (`Bird.Socket.Client.pas:306`), e o FMX nunca chama `.AutoReconnect.Active(True)`.
  - `TDados` só registra o ouvinte `MESSAGE` (`Conversa.Dados.pas:439`): nada para `CLOSE`/`ERROR`.
  - `IniciarMonitoramento` sai se `FBirdSocket` já foi criado (`:425-426`), então nem uma segunda chamada recriaria o socket.
- Não existe risco de **dois sockets** hoje (há um só e ele nunca é recriado). Também não existe "geração" para descartar eventos de um socket antigo.
- **Armadilha** para quem for "só ligar" o `AutoReconnect` do Bird:
  1. o monitor chama `TThread.Synchronize(... FOnReconnect)` (`Bird.Socket.Client.ConnectionMonitor.pas:92-96`), e o `Reconnect` faz `Connect` **na thread da UI**;
  2. se esse `Connect` falhar no handshake: `HandleException` → `Close` → `Disconnect` → `FreeConnectionMonitorThread` → `FConnectionMonitor.WaitFor` (`Bird.Socket.Client.pas:342-346`, `:410-418`). A thread da UI passa a esperar o monitor, que está parado dentro do `Synchronize` esperando a UI: **deadlock**;
  3. o `Reconnect` também **não reenvia** `{tipo:1}`, então a conexão nova ficaria aberta e não autenticada.

### 2.8 Threading

| O quê | Thread | Evidência |
|---|---|---|
| `Connect` + handshake + envio do login | UI | `Conversa.Dados.pas:438-450` |
| Leitura dos frames | `TTask` (pool) | `Bird.Socket.Client.pas:533` |
| Entrega à UI | `TThread.Queue(nil, ...)` assíncrono; a closure captura o `TBirdSocketClient` | `:742-750` |
| `NotificacaoSocket` | UI, e faz **REST síncrono**: `GET /mensagens/novas` (`src/Conversa.Proxy.pas:284-311`) no WS 2; `GET /chamada/dados` (`src/chamada/Conversa.Chamada.pas:408-421` → `Proxy.pas:924-937`) em 51–55. `TNetHTTPClient` com timeouts padrão (60 s) | `Conversa.Dados.pas:453-494` |
| Respostas REST assíncronas | `TThread.CreateAnonymousThread` → `TEventBase.Send` → `TThread.ForceQueue` → UI | `src/Conversa.Evento.Base.pas:117-131` |
| `Connected` | Chamado no **leitor** (`:547`), no **heartbeat** a cada 500 ms (`:725`) e na **UI** (`Send`, `:651`; `Close`, `:224`). No Indy, `TIdIOHandlerStack.Connected` executa **`ReadFromSource(False, 0, False)`**, ou seja, **lê do socket** (`delphi:Indy10/Core/IdIOHandlerStack.pas:241-245`). São três threads lendo o mesmo `InputBuffer` (e, com TLS, o mesmo `SSL*` do OpenSSL) sem trava: **corrida** (A3-08) | — |
| `PONG` | Thread do leitor, sob `FInternalLock` (o mesmo do `Send`) | `:592-598` |
| `OnClose`/`OnError` (se fossem usados) | Thread do leitor, não da UI | `:437-446`, `:222-240` |
| Saída do app | `TDados.Destroy` chama `FBirdSocket.Disconnect` **sem checar `nil`** (`Conversa.Dados.pas:99-102`): fechar antes de logar dá AV. Closures já enfileiradas podem rodar depois do `Free` do socket | — |

### 2.9 Token expirado

- O servidor **não derruba** a conexão quando o JWT vence depois do login (`srv:src/websocket.ts:79-100`; não há checagem posterior). Continua mandando eventos e mantém o usuário "conectado" para fins de push (§8).
- O FMX não sabe a validade do token: não lê `exp` e não guarda a hora do login. Os eventos continuam chegando, mas as buscas REST que eles disparam falham com 401, **em silêncio** (§4.5).

---

## 3. Eventos em tempo real: tabela completa

### 3.1 Servidor → FMX (enum `srv:src/websocket.ts:4-23`; enum do FMX `src/Conversa.Tipos.pas:17-38`, que **não tem 9, 57, 61 nem 62**)

Despacho no FMX: `Conversa.Dados.pas:453-494`. Antes do `case`, `TConversaChamadas.ProcessarSocket` consome 51–55 (`src/chamada/Conversa.Chamada.pas:132-141`, `:170-190`).

| tipo | Nome | Payload do servidor | Onde e para quem é emitido (servidor atual) | FMX trata em | O que o FMX faz / espera | Veredito |
|---|---|---|---|---|---|---|
| 0 | Erro | `{tipo:0, message}` | Login do socket com token ausente/inválido/expirado; a conexão segue aberta (`srv:websocket.ts:83-88`) | `Conversa.Dados.pas:486-489` | `raise` dentro do callback na UI → diálogo genérico; não fecha nem reloga | 🔴 |
| 2 | NovaMensagem | `{tipo:2, titulo, mensagem}`, **sem** `conversa_id` (`srv:websocket.ts:135-137`) | `PUT /mensagem` não agendada (`srv:mensagens.ts:229`) e agendada que amadurece (`:285`), via `srv:notificacoes.ts:52-76`, a cada outro membro. Sai **uma vez por par usuário×dispositivo com `token_fcm`** (`:56-69`), portanto **duplica** se o destinatário tem 2+ aparelhos com token | `Dados.pas:474-478` → `Proxy.pas:284-311` → `Dados.pas:496-508` → `ObterMensagens` `:510-549` | Ignora `titulo`/`mensagem`. Chama **síncrono na UI** `GET /mensagens/novas?ultima=<maior id visto>`, mas o servidor espera `desde=<ISO>` (`srv:esquemas.ts:68`, `srv:mensagens.ts:693-722`); `ultima` é ignorado e `desde=''` vale "desde sempre". Para cada `{conversa_id, mensagem_id}` devolvido: `GET /mensagens` em thread com `mensagemreferencia = última sincronizada + 1` | 🟠 (funciona por acaso; caro; corrida, A3-09) |
| 3 | AtualizacaoStatusMensagem | `{tipo:3, grupo, mensagens:"1,2,3"}` | Ao listar `/mensagens` (recebidas), `visualizar`/`reproduzir`, exclusão, agendada, resumo de chamada; aos outros membros (resumo: a todos) (`srv:mensagens.ts:286,313,549,632`, `srv:chamadas.ts:559`) | `Dados.pas:479-485` → `Proxy.pas:666-708` → `Dados.pas:395-418` | Lê `grupo` e o CSV; `GET /mensagem/status?conversa=&mensagem=` (thread); atualiza `recebida`/`visualizada`. Ignora `reproduzida` e **`excluida_em`** (o registro `TMensagemStatus` não tem o campo, `src/Conversa.Proxy.Tipos.pas:116-122`), então mensagem ocultada pelo autor não some | ✅ (🟠 sem `excluida_em`) |
| 4 | Digitando | `{tipo:4, conversa_id, usuario_id}` | `POST /conversa/digitando` aos outros membros (`srv:rotas.ts:93-96`, `srv:conversas.ts:238-241`) | — (enum tem `Digitando=4`, sem `case`) | Nada. A UI de "digitando" existe e fica sempre oculta (`src/chat/Conversa.Chat.pas:45-48`, `:110`) | ⬜ |
| 5 | GravandoAudio | idem | `POST /conversa/gravando` (`srv:rotas.ts:98-101`) | — | Nada | ⬜ |
| 7 | ReacaoMensagem | `{tipo:7, conversa_id, mensagem_id, usuario_id, emoji, acao}` | `PUT /mensagem/reacao` aos outros membros (`srv:mensagens.ts:764`) | — (enum 7 sem `case`) | Nada (o FMX não exibe reações) | ⬜ |
| 9 | (erro de leitura; fora do enum do servidor) | `{tipo:9, message}` | Cliente mandou texto não-JSON ou sem `tipo` (`srv:websocket.ts:61-68`) | — | Ignorado | ✅ (inofensivo) |
| 40 | ConversaNova | `{tipo:40, conversa_id, usuario_id}` | Membro adicionado (`srv:conversas.ts:233`); chat da chamada criado (`srv:chamadas.ts:258`); entrar em chamada com chat (`:279`, ao próprio) | `Dados.pas:470-473` | `GET /conversas` (thread) | ✅ (corrida com o 2, A3-18) |
| 51 | ChamadaRecebida | `{tipo:51, chamada_id, usuario_id}` | `iniciar` (`srv:chamadas.ts:108`) e `PUT /chamada/usuario` (`:289`), a todos menos quem ligou/adicionou | `Chamada.pas:170-190` → `:334-340` | Cria `TConversaChamada`; `GET /chamada/dados` **síncrono na UI**; card de notificação + janela da chamada. **Sem som de toque**, sem tempo limite de toque | ✅ (🟠 sem toque) |
| 52 | ChamadaFinalizada | idem | `cancelar`/`finalizar`, aos outros participantes (`srv:chamadas.ts:158,298`) | `Chamada.pas:326-332` | `GET /chamada/dados` síncrono; `FinalizarLocalmente` libera o objeto (`:472-483`, `FreeAndNil(Self)`) e depois **lê `FID` do objeto liberado** (`:331`) | 🟠 |
| 53 | UsuarioRecusou | idem | `recusar`: aos outros **e ao próprio** (outras abas/aparelhos param de tocar; `srv:chamadas.ts:193-195`) | `Chamada.pas:342-356` | Marca o participante. Se estou "recebendo", **só sai**: não para o toque quando **eu** recusei em outro aparelho. O chamador 1:1 encerra | 🟠 |
| 54 | UsuarioEntrou | idem | `entrar`: aos outros **e ao próprio** (`srv:chamadas.ts:208-210`) | `Chamada.pas:358-387` | Marca. Se estou "recebendo", sai **sem fechar o card** (atendi no celular, o PC segue "tocando"). Senão, assina a mídia do peer | 🟠 |
| 55 | UsuarioSaiu | idem | `sair`: aos outros (`srv:chamadas.ts:223`); a chamada que termina por saída **não** gera 52 | `Chamada.pas:389-406` | Marca; desconecta o peer; 1:1 em andamento é encerrada. Se estou "recebendo", **não fecha o card** | 🟠 |
| 56 | VideoAtivado | idem | `POST /chamada/video` (`srv:chamadas.ts:304`) | — (`SocketType` não inclui 56, `Chamada.pas:132-141`; `Dados.pas` sem `case`) | Nada | ⬜ |
| 57 | SinalChamada | `{tipo:57, chamada_id, usuario_id, dados}` | Repasse de sinal entre participantes (`srv:websocket.ts:206-227`) e `{acao:'chat', conversa_id}` (`srv:chamadas.ts:262`) | — (fora do enum) | Nada: sem tela compartilhada/ponteiro, sem abrir o chat da chamada | ⬜ |
| 60 | StatusUsuario | `{tipo:60, usuario_id, online}` | Primeira conexão / fechamento da última, a quem tem conversa direta (`srv:websocket.ts:97-100`, `:111-115`, `:230-243`) | — (enum 60 sem `case`) | Nada; o FMX não mostra presença | ⬜ |
| 61 | NovaAtividade | `{tipo:61}` | Atividade nova ou removida (`srv:atividades.ts:43,53,62,75`) | — | Nada (o FMX não tem atividades) | ⬜ |
| 62 | EnqueteAtualizada | `{tipo:62, enquete_id, conversa_id}` | Voto, encerramento ou mudança de prazo (`srv:enquetes.ts:103`) | — | Nada (o FMX não renderiza enquete) | ⬜ |

Observações:
- **Mensagens enviadas pelo próprio usuário em outro aparelho** não geram WS 2 para nenhuma conexão dele (`srv:notificacoes.ts:65`, `cu.usuario_id <> remetente`). Também não há evento para "**eu** li no celular" (o WS 3 vai só "aos outros", `srv:notificacoes.ts:43-48`). Isso é limitação do servidor e vale para todos os clientes; no FMX ela agrava A3-19.
- O FMX cria um `TConversaChamada` novo para **qualquer** 51–55 de `chamada_id` desconhecido (`Chamada.pas:183-187`), inclusive 53/54/55 de chamadas que ele nunca viu tocar. Ver A3-12.

### 3.2 FMX → servidor pelo WebSocket

| tipo | Formato enviado | Aceito pelo servidor? | Veredito |
|---|---|---|---|
| 1 | `{"tipo":1,"token":"<jwt>"}` uma vez, logo depois de abrir (`Conversa.Dados.pas:442-450`) | Sim (`srv:websocket.ts:79-100`) | ✅ |
| 57 | **Nunca enviado** (o FMX não tem tela compartilhada nem ponteiro) | — | ⬜ |
| PONG (protocolo) | Resposta a PING **com carga**; PING sem carga não é respondido (A3-02) | — | 🔴 |
| outros | Nenhum. O servidor ignora qualquer outro tipo | — | — |

### 3.3 FMX → servidor por REST (ações ligadas ao tempo real)

| Ação | FMX hoje | Servidor | Veredito |
|---|---|---|---|
| Digitando | **Nada no build.** `TConversaIndicadores.Digitando` existe só em `src/Conversa.Proxy.Extras.pas:358-373`, **fora do `.dpr`** (unit órfã), com corpo `{"conversa_id":X}` e token nunca preenchido (`TConversaExtrasAuth.SetToken` não é chamado; `:134-141`, `:151-177`) | `POST /conversa/digitando {"id":X}` (`srv:rotas.ts:93-96`, `srv:esquemas.ts:16,41`). Com o corpo do Extras daria 400; sem token, 401 | ⬜ (e 🔴 se for ligado como está) |
| Gravando | Idem (`Proxy.Extras.pas:375-390`) | `POST /conversa/gravando {"id":X}` | ⬜ |
| Novas mensagens | `GET /mensagens/novas?ultima=<id>` (`Proxy.pas:284-311`), síncrono | `?desde=<ISO-8601>` (`srv:esquemas.ts:68`). `ultima` ignorado → "desde sempre". Mesmo no servidor de abril o parâmetro já era `desde` (`git show 56e7cc0:src/conversa/conversa.api.pas`, l. 1891-1904) | 🟠 |
| Status das mensagens | `GET /mensagem/status?conversa=&mensagem=<csv>` (`Proxy.pas:666-708`) | Igual (`srv:esquemas.ts:67`, `srv:mensagens.ts:636-667`) | ✅ |
| Visualizar | `GET /mensagem/visualizar?conversa=&mensagem=` com `Tentativa(5)` (`Proxy.pas:723-744`) | Só `POST` com corpo `{conversa, mensagem}` (`srv:rotas.ts:112-113`, `srv:esquemas.ts:66`). Dá **404** (`Rota GET:/api/mensagem/visualizar não encontrada`); o 404 não é reenviado (`Tentativa` só repete `Unknown`); `ValidarErro` → `Abort` silencioso | 🔴 |
| Contatos online | Nada no build (`Proxy.Extras.pas:209-221` órfão) | `GET /contatos/online` → `number[]` (`srv:usuarios.ts:147-155`) | ⬜ |
| Chamadas pendentes | Nada no build (`Proxy.Extras.pas:225-237`, `:429-441` órfãos) | `GET /chamadas/pendentes` (`srv:rotas.ts:203`) | ⬜ |
| Atividades novas | Nada | `GET /atividades/novas` (`srv:rotas.ts:195`) | ⬜ |
| Dispositivo | `PATCH /dispositivo {id, nome, modelo, versao_so, plataforma}` só quando o id muda (§4.3) | `srv:esquemas.ts:31-33`, `srv:usuarios.ts:76-82` | ✅ |

---

## 4. Sessão

### 4.1 Login e o que é guardado

Fluxo: `TLogin.rctBotaoEntrarClick` (`Conversa.Login.pas:78-86`) → `TDados.Login` (`Conversa.Dados.pas:112-145`) → `TAPIConversa.Login` (`src/Conversa.Proxy.pas:171-209`), síncrono na UI. O corpo é `{login, senha, dispositivo_id}`: confere com `srv:esquemas.ts:29`. ✅

| Dado | Onde | Forma | Evidência |
|---|---|---|---|
| Host (URL base da API) | `conversa.json` | texto | `src/configuracoes/Conversa.Configuracoes.pas:13-24` |
| Login | `conversa.json` | texto | `Conversa.Login.pas:81` |
| **Senha** | `conversa.json` | **AES-256-CBC**, IV **fixo** `'1234567890123456'`. Chave = UTF-8(**serial da placa-mãe via WMI** + "sal" GUID). O sal é gravado **junto**: `base64(sal + ':' + base64(cifra))`. O DCPcrypt usa os primeiros 32 bytes da chave (`lib/AES/Prism.Crypto.AES.pas:36`): se o serial tiver ≥ 32 caracteres, a chave é só o serial; se for vazio ou genérico ("Default string" etc.), a chave é formada quase toda pelo sal gravado no próprio arquivo | `lib/AES/Conversa.AES.pas:100-140`, `Conversa.WMI.pas:79-105` |
| `DispositivoId` | `conversa.json` | inteiro | `Conversa.Dados.pas:142-143` |
| Escala, posição da janela, `MediaMtxBase`, `Notificacoes.Timeout` | `conversa.json` | — | `Conversa.Configuracoes.pas:13-24` |
| **Token JWT** | **só memória**, em duas cópias: `TAPIInternal.FToken` (class var, `Proxy.pas:98`, `:205`) e `TDados.FToken` (`Conversa.Dados.pas:41`, `:128`). Uma terceira, `TAPIExtras.FToken` (`Proxy.Extras.pas:153`), nunca é preenchida | — | — |
| Registro do Windows, `.ini`, DPAPI | **não usados** | — | — |

Onde fica o `conversa.json` (`Conversa.Configuracoes.pas:39-47`):
- **modo portátil:** `<pasta do exe>\Conversa\conversa.json`, quando esse arquivo já existe. É o caso deste ambiente: existe `bin/Conversa/conversa.json` (o conteúdo não foi lido);
- senão, `TPath.GetHomePath\Conversa\` = `%APPDATA%\Conversa\` (perfil **móvel**).

Não há opção "lembrar senha": a senha é salva **sempre** (`Login.pas:82-83`).

### 4.2 Auto-login

- Ao abrir, se há usuário e senha salvos, o `TLogin.New` decifra a senha e clica sozinho em "Entrar" (`Login.pas:68-73`).
- Erro 4xx no login apaga a senha salva. "Seção Encerrada!" (dispositivo inativo) zera também o `DispositivoId` (`Proxy.pas:184-195`).
- O 503 do nginx (limite de 10 logins/min) cai no ramo 5xx: a senha é mantida, e o diálogo mostra o **HTML** do nginx (`MensagemErro = Response.ToString`, `:130-133`).
- Se o `Decrypt` falhar (arquivo copiado de outro PC, placa trocada), a exceção sobe do `tmrShowTimer` e o campo de senha fica vazio.

### 4.3 `dispositivo_id` e `PATCH /dispositivo`

- O `dispositivo_id` salvo vai em todo login (`Proxy.pas:176-181`). ✅
- Se o servidor devolver o **mesmo** id, não há PATCH (`Dados.pas:131-132`). Se devolver outro (primeiro login na máquina, outro usuário, dispositivo de outro dono), o FMX manda `PATCH /dispositivo` (`Proxy.pas:452-470`) com:

  | Campo | Valor no Windows | Limite da coluna (`srv:migracoes/002.sql:2-9`) |
  |---|---|---|
  | `id` | `dispositivo.id` da resposta | — |
  | `nome` | `GetComputerName` (nome NetBIOS, ≤ 15 caracteres) | 50 ✅ |
  | `modelo` | **`""`** (não preenchido no Windows; `lib/Conversa.DeviceInfo.Utils.pas:151-169`). O servidor aceita string vazia (`t.String()`, `srv:esquemas.ts:9`) | 50 ✅ |
  | `versao_so` | `GetVersionEx` → `"10.0.22621"` (o manifesto padrão do Delphi declara Windows 10; sem ele seria `"6.2.9200"`) | 15 ✅ |
  | `plataforma` | `"Windows"` | 15 ✅ |
  | `token_fcm` | não enviado (o desktop não recebe push) | — |

  O WMI **não** é usado para o dispositivo (só para a chave da senha), então não há risco de textos longos → 500. ✅
- Depois do primeiro registro, o dispositivo nunca é atualizado: se o computador for renomeado, o nome antigo fica no servidor.
- O `DispositivoId` é **por máquina** (arquivo de configuração), não por usuário. Alternar entre duas contas no mesmo PC cria um dispositivo novo a cada troca (o servidor só reaproveita o id se for do mesmo dono, `srv:usuarios.ts:47-60`).
- Falha no PATCH: `ValidarErro` → `Abort` silencioso (`Proxy.pas:154-167`). O login é interrompido **sem mensagem**, com o token já em memória.

### 4.4 Logout e troca de usuário

- **Não existe "Sair"** em lugar nenhum (grep sem `Logout`/`Deslogar`/`Terminate`). Para trocar de conta é preciso apagar o `conversa.json` ou errar a senha.
- Em RELEASE o "X" só esconde a janela (`Conversa.Tela.Inicial.view.pas:197-204`). A bandeja não tem menu (§7.8), então **não há como fechar o app** a não ser pelo Gerenciador de Tarefas ou encerrando a sessão do Windows.
- Referência no web: AUT-05 (logout local, mantém `deviceId`).

### 4.5 401 no meio do uso e JWT de 12 h

- JWT de 12 h sem refresh (`srv:src/autenticacao.ts:6`; doc 01 §2.2).
- O FMX não trata 401 em lugar nenhum:
  - `TAPIInternal.InternalExecute` só guarda a mensagem (`Proxy.pas:121-135`);
  - os chamadores por evento fazem `if Status <> Sucess then Exit` (ex.: `Dados.pas:191-192`, `:500-501`, `:561-562`);
  - os síncronos usam `ValidarErro` → `TErroServidor.Send` (**sem assinante** no app; só em `teste/Exemplo.Principal.pas:63`) + `Abort` (silencioso).
- Como o app é feito para ficar aberto na bandeja e não tem "Sair", **o limite de 12 h é atingido todo dia**.
- Daí em diante: novas mensagens, status, conversas e chamadas (`/chamada/dados`) falham sem aviso. Se o socket ainda estiver vivo, o usuário continua "online" e o push continua suprimido (§8).

### 4.6 Várias instâncias, vários usuários do Windows, vários aparelhos

| Cenário | Comportamento | Evidência |
|---|---|---|
| Duas instâncias do app | Bloqueado **só em RELEASE** (`{$IFDEF RELEASE}`), pelo nome do exe + mesma pasta. Traz a outra para frente com `SW_RESTORE` e `WM_RESTAURAR_CONVERSA` (`WM_USER+1`). Em DEBUG, cada instância abre seu socket, notifica e grava o mesmo `conversa.json` | `Conversa.Inicializacoes.pas:26-29`; `lib/windows/Conversa.Windows.Utils.pas:89-158`; `src/base/Conversa.FormularioBase.pas:174-177` |
| Vários usuários do Windows no mesmo PC | Com instalação "portátil" (pasta `Conversa` ao lado do exe), **todos** compartilham o mesmo `conversa.json`, inclusive login e senha cifrados com a placa-mãe do **mesmo** PC: qualquer usuário local entra na conta do outro. A verificação de instância única percorre processos de todas as sessões; o `OpenProcess` de processo alheio costuma falhar e ele é pulado | `Conversa.Configuracoes.pas:41-47`; `Windows.Utils.pas:111-131` |
| Mesmo usuário em PC + celular/web | Leituras feitas no PC **não chegam** ao servidor (A3-05). Leituras feitas no celular não atualizam o contador do PC (A3-19). Mensagens enviadas no celular só aparecem no PC quando outro evento força a busca daquela conversa. Atender/recusar no celular não para o toque do PC (A3-12). WS 2 duplicado (A3-09) | §3.1, §10 |

---

## 5. Ressincronização e modo degradado

O servidor não guarda fila: o que acontece com o socket fora **se perde** (doc 01 §6.7). Comparação:

| Momento | Web (`web:src/stores/chat.ts`) | FMX |
|---|---|---|
| Abertura/login | Contatos + conversas, WS, `contatos/online`, `atividades/novas`, `chamadas/pendentes`, polling | `GET /usuario/contatos` (síncrono); `GET /conversas` **duas vezes** (`Tela.Inicial.view.pas:232` e `tmrExibir` 500 ms em `src/chat/Conversa.Chat.Listagem.pas:99-103`); WS. **Sem** `mensagens/novas`, `contatos/online`, `atividades/novas`, `chamadas/pendentes` |
| `onopen` do WS | `{tipo:1}` → `contatos/online` → `atividades/novas` → `chamadas/pendentes` (`:753-770`) | Só `{tipo:1}` |
| Socket caiu | Reconecta com espera `min(30 s, 1 s × 2^n)` (`:807-819`) | **Nada** (A3-01) |
| Socket fora | Polling a cada 8 s de `mensagens/novas` + `chamadas/pendentes` (`:1038-1052`) | **Nada** |
| Aviso visual (GER-02) | Faixa depois de 5 s: "Conexao em tempo real indisponivel — usando atualizacao periodica" (`web:src/App.vue:21`, `:387-396`) | Existe `rctAvisoConexao` com "Falha na conexão com o servidor!" (`Conversa.Tela.Inicial.view.fmx:2469-2484`) e o assinante `StatusConexao` (`Tela.Inicial.view.pas:274-277`), mas **ninguém envia `TEventoStatusConexao`** (grep). Nunca aparece |
| Falha na abertura | AUT-03: 401 → login; outro erro → toast e nova tentativa a cada 5 s | `ServerOnline` devolve `True` fixo (`Dados.pas:324-339`), então a tela "falha de conexão" (`src/conexao/Conversa.Conexao.AvisoInicioSistema.pas:46-60`) **nunca aparece**. Erro de rede vira exceção/diálogo |
| Cursor de novas mensagens | `desde = <ISO>`, avançado pelo maior `ate` e nunca para o futuro (doc 03 §1.4) | `UltimaMensagemNotificada` (maior `mensagem_id`), que o servidor não usa |
| Chamada que já tocava ao abrir | `chamadas/pendentes` | Não toca |

---

## 6. Presença e atividade

| Item | Web / contrato | FMX |
|---|---|---|
| Online/offline (PRE-01) | `GET /contatos/online` a cada conexão + WS 60 | **Nada**: não há indicador na lista nem no cabeçalho, WS 60 é ignorado, e a rota só existe na unit órfã |
| Digitando (ENV-15) | Envia `POST /conversa/digitando {id}` ao digitar, no máximo 1 a cada 2,5 s (o último é adiado, não perdido; `web:src/stores/chat.ts:49`, `:1062-1077`). Recebe WS 4, ignora o próprio, expira em 4 s (`:50`), limpa ao chegar mensagem. Textos: "Digitando..." (direta); "Ana está digitando...", "Ana e Beto estão digitando...", "Ana, Beto e Caio estão digitando...", "Ana, Beto, Caio e outras N pessoas estão digitando..." | **Nada.** A UI (`lytActionDigitandoClient`, `txtNomeDigitando`, `LoadingAction`) existe e é escondida no construtor (`Conversa.Chat.pas:45-48`, `:110`). Eventos `TEventoUsuarioDigitando`/`TEventoUsuarioGravandoAudio` declarados em 2026-04-21 e **nunca usados** (`src/Conversa.Eventos.pas:24-29`) |
| Gravando (ENV-16) | `POST /conversa/gravando {id}` ao começar e a cada 2,5 s; WS 5 expira em 4 s; textos "Gravando áudio..." / "Ana está gravando áudio..."; prioridade sobre "digitando" | **Nada** |
| `Conversa.Windows.UserActivity` | (não existe no servidor: sem "ausente"/"visto por último", doc 01 §15.1) | Monitor **local**: `GetLastInputInfo` a cada 100 ms; "Inativo" com ≥ **1 s** sem entrada, "Ativo" com ≤ 1 s (`lib/windows/Conversa.Windows.UserActivity.pas:31-34`, `:36-82`). Publica `TEventoMudancaStatusUsuarioSO` via `TThread.Synchronize`. **Único uso:** começar a contagem para fechar a notificação de mensagem só quando o usuário mexe no PC (`Conversa.Notificacao.Item.Mensagem.pas:83`, `:181`, `:224-234`). Nada é enviado ao servidor |

Ressalvas do `UserActivity`:
- o laço só roda se `ApplicationState = Running` **1 s depois** de `Iniciar`, que é chamado **antes** de `Application.Initialize` (`UserActivity.pas:91-101`; `Conversa.dpr:72-79`). `ApplicationState` só vira `Running` com o laço de mensagens rodando (`delphi:fmx/FMX.Forms.pas:1500-1520`). Numa partida a frio mais lenta que 1 s, o monitor **termina antes de começar**: `StatusUsuarioSO` fica `Desconhecido` e as notificações de mensagem **nunca fecham sozinhas** (não confirmado em campo);
- `FinalizarMonitoramento` faz `MonitorTask.Wait` na thread da UI (`:104-109`). Se a tarefa estiver dentro de `Synchronize` nesse instante, há um **deadlock** possível na saída (janela pequena).

---

## 7. Notificações no Windows

### 7.1 Mecanismo

- **Janelas FMX próprias**, sem toast nativo nem `TNotificationCenter`:
  - `TNotificacaoManager` (singleton, `src/notificacao/Conversa.Notificacao.pas:46-200`) mantém um `TDictionary` por chave `MSG_<conversa>`/`CALL_<chamada>` (`Conversa.Notificacao.Tipos.pas:40-45`);
  - cada notificação é um `TFrame` (`Item.Mensagem` ou `Item.Chamada`) empilhado (`Align := Top`) dentro de um único formulário `TNotificacaoVisualizador`;
  - esse formulário é sem borda (`WS_EX_LAYERED`, sem `WS_CAPTION`), `HWND_TOPMOST`, exibido com `SW_SHOWNOACTIVATE` (não rouba foco) no **canto inferior direito da área útil do monitor principal**, com largura 250 e altura = soma dos itens até 75% da tela (`Conversa.Notificacao.Visualizador.pas:117-175`).
- `Conversa.Windows.Overlay` **não** é notificação: é o contador na barra de tarefas (§7.8).
- O `refatoracao_notificacao.md` está correto quanto à estrutura (Tipos, Base, Mensagem, Chamada, Manager). A "Limpeza (PENDENTE)" continua pendente: `Conversa.Notificacao.Item.pas`/`.fmx` está fora do `.dpr` e chama uma assinatura que não existe mais (`TNotificacaoManager.Fechar(FChatId)`, `:197-207`).

### 7.2 Quando notifica uma mensagem (`Conversa.Chat.Listagem.pas:244-310`, disparado por `TExibirMensagem` a cada resposta de `GET /mensagens`)

| Situação | FMX | Web (NOT-01/02) |
|---|---|---|
| Conversa aberta e janela ativa | Não notifica nem toca (`:269-270`) | Igual |
| Conversa aberta, janela sem foco/minimizada/na bandeja | Notifica e toca | Igual |
| Outra conversa aberta, janela ativa | Notifica e toca | Toca; notificação do sistema |
| **Conversa arquivada** | **Notifica e toca**: o FMX não conhece `arquivada` (não está em `TConversa`, `src/Conversa.Proxy.Tipos.pas:50-62`) | Não toca |
| Mensagem própria (inclusive de outro aparelho) | Não (`TMensagens.ParaNotificar` filtra `Lado = Esquerdo`, `src/Conversa.Tipos.pas:681-689`) | Igual |
| Mensagens não lidas antigas, depois de reiniciar | **Notifica em rajada** no primeiro WS 2, para cada conversa com não lidas. Como o PC nunca marca "visualizada" no servidor (A3-05), isso inclui mensagens **já lidas no PC** em sessões anteriores (consequência direta do código; confirmar em teste) | Cursor começa em "agora" |
| Lote com várias conversas | `if Length(Mensagens) = 0 then Exit` (`:275-276`): a primeira conversa sem pendências **descarta as seguintes** | — |

### 7.3 Conteúdo

- Título: `Conversa.Descricao`; hora: `Now`.
- Corpo:
  - texto (com "Você: " se for do próprio lado), `"Imagem"` ou `"Arquivo"` (`:284-288`);
  - **áudio (4/5), chamada (6), figurinha (7), enquete (8):** `sConteudo` não é atribuído e **herda o texto da conversa anterior do lote** (ou fica vazio);
  - em grupo, prefixo "Nome: ".
- Agrupamento: até 5 linhas; a partir da 6ª, mostra 4 linhas + "+N" (`Item.Mensagem.pas:88-174`).
- Menções `@[Nome](id)` e cercas de código **não** são resumidas (o web resume).

### 7.4 Som

- `res/nova_mensagem.wav`, embutido como `RCDATA` `nova_mensagem` (`ConversaResource.rc:1`, `Conversa.dproj:371-375`).
- Tocado com `PlaySound(SND_MEMORY or SND_SYNC)` numa **thread nova por chamada** (`Conversa.Audio.pas:167-182`), uma vez **por conversa** do lote (`Listagem.pas:307`).
- Sem opção de silenciar e sem respeitar "não perturbe". **Chamada recebida não tem toque nenhum** (grep: só `nova_mensagem`).

### 7.5 Tempo de exibição

- `FloatAnimation` (opacidade 1→0, 0,3 s) com `Delay = Configuracoes.Notificacoes.Timeout`:
  - 5 s por padrão, aplicado só quando o arquivo já existe (`Configuracoes.pas:63-64`);
  - **na primeira execução fica 0**, e a notificação some quase na hora.
- A contagem só começa quando o usuário está "Ativo" (§6). Com o usuário fora, a notificação fica na tela.
- Notificação de chamada não fecha sozinha.

### 7.6 Clique, fechar, empilhamento

| Ação | Comportamento | Evidência |
|---|---|---|
| Clique na notificação de mensagem | `Fechar` (libera o frame) → `Chats.AbrirChat(...GetOrAdd(FChatId))` → `TelaInicial.DoConversaRestore`. **Lê `FChatId` depois de liberar o próprio frame**, dentro do próprio evento de clique (A3-10) | `Item.Mensagem.pas:212-217` |
| Fechamento automático | `FloatAnimationFinish` → `Fechar` → `Notif.FView.Free`: o frame é liberado **dentro do `OnFinish` da animação que é filha dele** | `:202-205`; `Conversa.Notificacao.pas:175-187` |
| Abrir a conversa | Fecha a notificação daquela conversa | `Listagem.pas:237` |
| Ler no celular | **Não** fecha (o web fecha quando o contador zera, NOT-03) | — |
| Empilhamento | Uma por conversa (chave `MSG_<id>`); mensagens novas da mesma conversa entram no item existente. Sem limite de itens; altura limitada a 75% da tela | `Conversa.Notificacao.pas:133-144` |

### 7.7 Notificação de chamada recebida

- Card `TNotificacaoItemChamada` (`Conversa.Notificacao.Item.Chamada.pas`) com "Atender"/"Recusar"/"×". O texto é **sempre** "Chamada de Voz" ou "Chamada de Voz em Grupo", mesmo em vídeo (`Chamada.pas:576-579`). O nome mostrado é o do primeiro participante que não sou eu, não necessariamente quem ligou (`:567-574`).
- Junto com o card abrem a janela da chamada (`ExibirChamada`, `:538-559`) e a barra de título.
- Fecha:
  - ao atender ou recusar localmente (`SetStatusLocal`, `:611-628`);
  - com 52 (`FinalizarLocalmente`, `:472-483`).
- **Não fecha:**
  - com 53/54 do próprio usuário (recusou/atendeu em outro aparelho);
  - com 55 (a chamada acabou por saída);
  - por tempo (o web/contrato: 30 s com `nao_atendeu:true`).
- Atender/Recusar/× liberam o próprio frame durante o clique (via `SetStatusLocal`/`FinalizarLocalmente` → `TNotificacaoManager.Fechar`) e depois chamam `Fechar`, que lê `FChamadaId` (`Item.Chamada.pas:95-114`) (A3-10).

### 7.8 Bandeja, barra de tarefas e ciclo de vida da janela

| Item | Estado | Evidência |
|---|---|---|
| Ícone de bandeja | `Shell_NotifyIcon` manual (não há `TTrayIcon` no `.fmx`); tooltip "Conversa"; clique esquerdo/direito → restaurar. **Sem menu** (sem "Abrir"/"Sair"), **sem contador**, sem balão. `TrayIconAdded` **nunca vira `True`**, então `NIM_DELETE` nunca roda (ícone "fantasma" depois de sair). Sem tratamento de `TaskbarCreated` (o ícone some se o Explorer reiniciar) | `Tela.Inicial.view.pas:236-272` |
| Fechar (X) | RELEASE: `ShowWindow(SW_HIDE)`, sem botão na barra de tarefas. DEBUG: fecha o app | `:197-204` |
| Minimizar | `MinimizeApp` minimiza todas as janelas menos o visualizador de notificações e **desliga temporariamente a animação de minimizar do sistema** (`SPI_SETANIMATION`, global da sessão) | `FormularioBase.pas:91-141` |
| Restaurar | Bandeja, clique na notificação ou segunda instância → `DoConversaRestore` (`SetWindowPos` TOPMOST/NOTOPMOST + `Activate`, que dá `SW_RESTORE` se a janela estiver oculta, `delphi:fmx/FMX.Platform.Win.pas:3484-3499`) | `Tela.Inicial.view.pas:206-221` |
| Contador / *badge* | Ícone sobreposto (`ITaskbarList3.SetOverlayIcon`) na janela principal: círculo vermelho com o número ou "9+". Some quando a janela está oculta (sem botão na barra). **Vaza 2 `HBITMAP` a cada atualização** (`CreateIconIndirect` não assume os bitmaps, e não há `DeleteObject`) | `lib/windows/Conversa.Windows.Overlay.pas:67-97`, `:128-134`, `:148-172` |
| Piscar na barra de tarefas | Não existe (`FlashWindowEx` ausente) | grep |
| Iniciar com o Windows | Não existe (sem chave `Run` nem atalho em Inicializar) | grep |
| Instância única | Só RELEASE, por pasta (§4.6) | — |
| Vários monitores / DPI | `PerMonitorV2` (`Conversa.dproj:209-227`). Notificações sempre no monitor **principal**, posicionadas por `Screen.WorkAreaRect` × escala do próprio formulário. A janela de chamada é centralizada no monitor da janela principal (`Chamada.pas:545`) | `Visualizador.pas:146-175` |
| Win64 | O projeto habilita Win64 (`Conversa.dproj:1401-1402`), mas `SetWindowLong(..., LongInt(@WndProc))` trunca o ponteiro em 64 bits (`FormularioBase.pas:324`, `:329`). Provável quebra no Win64 com ASLR alto (não confirmado; fora do escopo) | — |

---

## 8. Ponto crítico: desktop × push

**Confirmado no servidor:**
- `srv:src/notificacoes.ts:56-75`: para cada membro da conversa (exceto o remetente) e para cada dispositivo `ativo` com `token_fcm`, o servidor manda o WS 2 e, **só se** `token_fcm && !arquivada && !usuarioConectado(usuario_id)`, o push (`:71`).
- `srv:src/websocket.ts:131-133`: `usuarioConectado` = `conexoes.get(usuarioId)?.size > 0`, isto é, **qualquer** conexão WebSocket autenticada do usuário, em qualquer aparelho ou aba.
  - A conexão entra no mapa ao validar o `{tipo:1}` (`:90-96`) e sai só no `close` (`:103-116`).
  - O login do socket não informa o dispositivo (`:83-90`): o servidor **não sabe** qual aparelho está conectado.
  - O token vencido **não** remove a conexão (§2.9).
- Chamadas não geram push nenhum (só WS 51; doc 01 §7.1 e §19.31).

**Efeito de um desktop "sempre conectado":**
1. Enquanto o app do PC estiver com o socket aberto, **o celular (e o web em segundo plano) não recebem push de mensagem**: com o usuário longe do PC, com a tela bloqueada, de noite (PC ligado no escritório) e mesmo depois de vencer o JWT de 12 h.
2. As notificações do PC só servem a quem está na frente dele. Com o usuário fora, ninguém é avisado.
3. Para os contatos, o usuário aparece **online 24 h** (WS 60 / `contatos/online`).
4. Hoje o efeito é **mascarado** pelos defeitos do FMX: o socket provavelmente cai ~2 min depois de abrir (A3-02) e nunca volta (A3-01). Daí em diante o servidor vê o usuário offline e o push volta a funcionar. **Corrigir A3-01/A3-02 sem tratar este ponto faz o celular parar de receber push sempre que o PC estiver ligado.**

**Correções sugeridas:**
- **Servidor** (já é a pendência S2.2 do doc 08; reforço):
  1. associar a conexão WS ao dispositivo (`{tipo:1, token, dispositivo_id}`) e suprimir o push **só** no dispositivo que está conectado;
  2. de preferência, um sinal de **presença ativa** por conexão (novo tipo cliente→servidor, ex. `{tipo:58, ativo:bool}`) e só suprimir o push dos outros aparelhos se alguma conexão estiver **ativa** nos últimos N minutos;
  3. ou sempre mandar o push e deixar o celular descartar (exige um evento "lida em outro aparelho" para limpar a notificação).
- **Cliente desktop**, enquanto o servidor não mudar:
  - fechar o socket ao **bloquear a sessão** (`WTSRegisterSessionNotification` → `WM_WTSSESSION_CHANGE`, `WTS_SESSION_LOCK`/`UNLOCK`);
  - fechar o socket ao **suspender** (`WM_POWERBROADCAST`: `PBT_APMSUSPEND` / `PBT_APMRESUMEAUTOMATIC`);
  - fechar o socket depois de **N minutos ocioso** (`GetLastInputInfo`, configurável; o `UserActivity` já mede isso);
  - nesse período, fazer **polling REST** (ex.: 30–60 s) para continuar notificando no PC, aceitando notificação dupla;
  - reabrir e ressincronizar quando o usuário voltar.

  Com isso, o usuário também aparece offline quando está fora (mais fiel à realidade).

---

## 9. Arquivos lidos e o que é código vivo

| Arquivo | Situação |
|---|---|
| `lib/bird-socket-client/*.pas` | Vivo (o WS). Partes **não usadas**: `AutoReconnect`/`ConnectionMonitor`, `OnOpen`/`OnClose`/`OnError`/`OnUpgrade`/`OnHeartBeatTimer`, `SetHeader`, `Send(TBytes)`. Ver §2 |
| `Conversa.Dados.pas` | Vivo; núcleo de sessão + WS + sincronização |
| `src/Conversa.Eventos.pas` | Vivo, mas `TEventoUsuarioDigitando`, `TEventoUsuarioGravandoAudio`, `TEventoStatusUsuario`, `TEventoConversaAtualizada`, `TEventoChamadaVideoAtivado`, `TEventoReacaoMensagem` (`:24-39`) **nunca são enviados nem assinados**. `TEventoStatusConexao` é assinado e nunca enviado. `TErroServidor` é enviado e nunca assinado |
| `src/Conversa.Evento.Base.pas` | Vivo (`ForceQueue` + `TMonitor`) |
| `src/Conversa.Proxy.pas` | Vivo |
| `src/Conversa.Proxy.Extras.pas` | **Órfão** (não está no `.dpr`, ninguém faz `uses`; criado em 2026-04-21). Corpo de digitando/gravando errado; token nunca preenchido |
| `src/Conversa.Proxy.Tipos.pas` | Vivo |
| `Conversa.Tela.Inicial.view.pas/.fmx` | Vivo (bandeja manual, faixa de conexão morta, `tmrShow` 30 ms) |
| `Conversa.Login.pas` | Vivo (auto-login) |
| `Conversa.Memoria.pas` | Vivo, só o `TDadosApp` (o resto está comentado). `Destroy` sem `inherited` (`:60-64`) |
| `Conversa.Inicializacoes.pas` | Vivo |
| `Conversa.Log.Pas` | Vivo, mas só usado pelo WebRTC (`src/chamada/Conversa.Chamada.WebRTC.pas:456-458`). `log.txt` em `PastaDados`, **sobrescrito** a cada partida (`Rewrite`), sem trava entre threads. Não registra token |
| `src/conexao/Conversa.Conexao.AvisoInicioSistema.pas` | Vivo, mas inalcançável (`ServerOnline = True`) |
| `src/notificacao/*` | Vivo (exceto `Conversa.Notificacao.Item.pas/.fmx`, órfão) |
| `lib/windows/Conversa.Windows.Overlay.pas` | Vivo (contador na barra de tarefas) |
| `lib/windows/Conversa.Windows.UserActivity.pas` | Vivo (§6) |
| `lib/windows/Conversa.Windows.Utils.pas` | Vivo (instância única, posição da janela) |
| `Conversa.WMI.pas` | Vivo; só o serial da placa-mãe para a chave da senha |
| `lib/Conversa.DeviceInfo.Utils.pas` | Vivo (§4.3) |
| `Conversa.Audio.pas` | Vivo (som de mensagem) |
| `lib/tcp.pas` | **Não usado.** Nenhuma unit o inclui; era do áudio de chamada por TCP, substituído por WebRTC em `4759ba5` (ver também `docs/todo.md` §1, não versionado) |
| `src/principal/*` | Vivo; nada de tempo real além de criar a listagem |
| `src/chat/Conversa.Chat.Listagem*.pas`, `Conversa.Chat.pas` | Vivos; reagem a `TExibirMensagem`, `TEventoAtualizacaoListaConversa`, `TEventoAtualizarContadorConversa`, `TEventoAtualizacaoMensagem` |
| `lib/AES/Conversa.AES.pas` | Vivo (§4.1) |

---

## 10. Problemas encontrados

Formato: **A3-nn [SEVERIDADE] Título.** Local · o que acontece · efeito · correção. A numeração é provisória e serve para a consolidação com as outras partes da auditoria.

### CRÍTICO

**A3-01 [CRÍTICO] WebSocket sem reconexão, sem detecção de queda e sem modo degradado.**
- **Local:**
  - `Conversa.Dados.pas:420-451` (só o ouvinte `MESSAGE`; `if Assigned(FBirdSocket) then Exit`);
  - `lib/bird-socket-client/Bird.Socket.Client.pas:306` (`FAutoReconnect := False`), `:437-446`, `:222-240`;
  - `Conversa.Tela.Inicial.view.pas:94`, `:274-277` (faixa nunca acionada);
  - `Conversa.Dados.pas:324-339` (`ServerOnline` fixo).
- **O que acontece:** qualquer queda (Wi-Fi, troca de rede, suspensão, API reiniciada, 502 do nginx, A3-02) fecha o socket. Ninguém percebe e nada reabre. Não há polling nem aviso.
- **Efeito:** o app continua aberto (na bandeja, sem "Sair") **sem receber mensagens, chamadas nem status** até ser reiniciado pelo usuário. Ele não sabe que precisa.
- **Correção:**
  - um "gerente de conexão" de escopo de aplicação, com estado (`desconectado` / `conectando` / `autenticando` / `conectado`), **número de geração** (descartar eventos de socket antigo) e reconexão com espera `min(30 s, 1 s×2^n)` + jitter;
  - `{tipo:1}` a cada abertura, ressincronização (§5) e polling de 8 s enquanto estiver fora;
  - faixa depois de 5 s (texto do web) e reconexão imediata ao voltar de suspensão ou bloqueio;
  - **não** usar o `AutoReconnect` do Bird (deadlock, §2.7). Tudo isso precisa vir **junto** com o tratamento de A3-03.

**A3-02 [CRÍTICO, provável] O leitor do Bird não trata frame de controle sem carga: o ping do Bun derruba a conexão em ~2 min.**
- **Local:** `Bird.Socket.Client.pas:567-580` (`LSize = 0` deixa `LPosition = 1`), `:583-599`; servidor sem opções de WS (`srv:src/websocket.ts:56`, `srv:src/servidor.ts:31`).
- **O que acontece:** o frame de tamanho 0 nunca é concluído, nenhum PONG é enviado, e o próximo byte é lido como tamanho, o que desalinha o fluxo. Pelos padrões do Bun (idle 120 s, `sendPings`; **não confirmado no código**), o servidor manda um PING vazio depois de 120 s sem receber nada e fecha se não houver resposta. O FMX não envia nada depois do login.
- **Efeito:** o desktop provavelmente perde o tempo real ~2 min depois de abrir. Se algum evento chegar entre o ping e o fechamento, ele vem corrompido.
- **Correção:** trocar o cliente WS (ver o item de transporte em A3-07). Se o Bird for mantido:
  - corrigir o caso `LSize = 0` (concluir o frame na hora e responder PONG);
  - suportar continuação/fragmentação;
  - enviar PING de protocolo a cada 30 s e considerar a conexão morta sem PONG em 10 s.
- **Teste:** abrir o app e ficar 3 min sem mexer; mandar mensagem pelo web e ver se chega. Alternativa: olhar a bolinha "online" no web.

**A3-03 [CRÍTICO] Desktop conectado suprime o push de todos os aparelhos do usuário.**
- **Local:** `srv:src/notificacoes.ts:71`, `srv:src/websocket.ts:131-133`, `:83-100`; cliente sem "ausente" nem fechamento por inatividade (`Tela.Inicial.view.pas:197-204`, `Conversa.Windows.UserActivity.pas`).
- **O que acontece e efeito:** ver §8.
- **Correção:** §8 (servidor S2.2 + medidas no cliente). Tratar **antes** ou **junto** com A3-01/A3-02.

**A3-04 [CRÍTICO] Sessão de 12 h sem renovação; 401 ignorado em todo o app.**
- **Local:** `src/Conversa.Proxy.pas:121-135`, `:154-167`; `Conversa.Dados.pas:191-192`, `:500-501`, `:561-562`; `TErroServidor` sem assinante (`src/Conversa.Eventos.pas:43`); `srv:src/autenticacao.ts:6`.
- **O que acontece:** depois de 12 h, todas as rotas respondem 401 e o app trata como "sem dados". O socket (se vivo) continua autenticado (§2.9).
- **Efeito:** num app de bandeja sem "Sair", isso acontece **todo dia**. Mensagens e chamadas param de carregar sem aviso, e o usuário segue "online" e com o push suprimido (A3-03).
- **Correção:**
  - tratamento global de 401: refazer o login em silêncio, com a credencial guardada de forma segura (ver A3-11), ou voltar à tela de login;
  - fechar e reabrir o socket com o token novo;
  - guardar o `exp` e renovar antes de vencer;
  - no servidor, refresh token (S13).

### ALTO

**A3-05 [ALTO] "Visualizar" usa GET com query; o servidor só aceita POST com corpo (404).**
- **Local:** `src/Conversa.Proxy.pas:723-744`; `src/Conversa.Tipos.pas:845-864`; `src/chat/Conversa.Chat.pas:157-166`, `:280-290`; `srv:src/rotas.ts:112-113`, `srv:src/esquemas.ts:66`.
- **O que acontece:** todo "visto" no PC dá 404 e é descartado em silêncio (`Abort`).
- **Efeito:**
  - o remetente nunca vê "visualizada" do que foi lido no PC;
  - os contadores do celular/web não zeram;
  - `/mensagens/novas` devolve essas conversas para sempre (amplifica A3-09);
  - depois de reiniciar, o contador e as notificações voltam para mensagens já lidas no PC.
- **Correção:** `POST /mensagem/visualizar` com corpo `{conversa, mensagem}`. Provavelmente também está na parte de mensagens da auditoria; incluído aqui pelo efeito nos eventos e na sincronização.

**A3-06 [ALTO] TLS do WebSocket sem validação de certificado.**
- **Local:** `Bird.Socket.Client.pas:263-272`; `delphi:Indy10/Protocols/IdSSLOpenSSL.pas:2452-2457`.
- **O que acontece:** o Indy negocia o TLS com `VerifyMode = []`: qualquer certificado é aceito e o nome do host não é conferido.
- **Efeito:** quem estiver no meio da rede (Wi-Fi público, proxy) captura o **JWT** na primeira mensagem `{tipo:1}` e recebe todos os eventos. O REST, por usar WinHTTP, valida normalmente, o que dá falsa sensação de segurança.
- **Correção:** cliente WS com TLS do sistema (SChannel), por exemplo:
  - `THTTPClient`/WinHTTP com WebSocket nativo do Windows;
  - `sgcWebSockets` com SChannel;
  - ou ICS.

  Mantendo o Indy, exigir `sslvrfPeer` + `OnVerifyPeer` com a cadeia e o nome do host, e um repositório de CAs.

**A3-07 [ALTO] `wss://` depende de OpenSSL 1.0.2 (`ssleay32.dll`/`libeay32.dll`) que não é distribuído.**
- **Local:** `Bird.Socket.Client.pas:263-276`; `delphi:Indy10/Protocols/IdSSLOpenSSLHeaders.pas:19590-19598`; `bin/` sem as DLLs; `.gitignore` sem regra para elas.
- **O que acontece:** com o Host `https://`, o `Connect` levanta "Could not load SSL library". A exceção sobe de `IniciarMonitoramento` → `ExibirTelaPrincipal` → clique de login (`Conversa.Login.pas:84`). Aparece um diálogo, e o app segue **sem tempo real**: o `FBirdSocket` já foi atribuído, então nunca mais tenta. O REST funciona, o que confunde o diagnóstico.
- **Efeito:** em produção (TLS obrigatório) o WS não funciona sem copiar DLLs à mão. E o OpenSSL 1.0.2 está fora de suporte desde 2019.
- **Correção:** a mesma de A3-06 (TLS do sistema). Se ficar no Indy, empacotar a versão suportada e registrar no instalador.

**A3-08 [ALTO] Corrida no Indy: `Connected` lê do socket e é chamado em três threads.**
- **Local:** `Bird.Socket.Client.pas:288-295`, `:547`, `:651`, `:725`; `delphi:Indy10/Core/IdIOHandlerStack.pas:241-245`.
- **O que acontece:** o heartbeat (a cada 500 ms), a UI (`Send`) e o leitor chamam `Connected`, que executa `ReadFromSource`. Leituras concorrentes no mesmo `InputBuffer` (e, com TLS, `SSL_read` concorrente no mesmo `SSL*`).
- **Efeito:** bytes perdidos ou fora de ordem (frames corrompidos, eventos sumindo), exceções esporádicas e possível violação de acesso dentro do OpenSSL.
- **Correção:** um único dono do socket (a thread leitora); nada de `Connected` fora dela; estado de conexão num campo próprio, protegido. Ou trocar a biblioteca.

**A3-09 [ALTO] WS 2: busca sem cursor, uma busca por conversa e corrida que levanta "Mensagem já adicionada!".**
- **Local:**
  - `Conversa.Dados.pas:474-478` (`MensagensNovas` síncrono), `:496-508`, `:510-549`, `:564-614`;
  - `src/Conversa.Proxy.pas:284-311` (`ultima`);
  - `src/Conversa.Tipos.pas:618-627` (`raise`);
  - `srv:src/mensagens.ts:693-722`, `srv:src/notificacoes.ts:56-69`.
- **O que acontece:**
  1. `ultima` é ignorado e o servidor devolve todas as conversas com não lidas "desde sempre", com um `GET /mensagens` em thread para cada uma;
  2. duas notificações em sequência (mensagens seguidas, ou o **mesmo** WS 2 duplicado porque o destinatário tem 2+ aparelhos com `token_fcm`, por exemplo celular + web) disparam duas buscas da mesma conversa com a **mesma** referência;
  3. a segunda resposta reaproveita o objeto existente, **duplica os conteúdos** (`Mensagem.conteudos.Add`) e chama `Mensagens.Add`, que levanta exceção;
  4. a exceção sai da fila e vira **diálogo de erro** (`delphi:rtl/common/System.Classes.pas:16337-16341`).
- **Efeito:** diálogos "Mensagem já adicionada!", mensagens com conteúdo repetido, carga desnecessária no servidor e congelamento da UI a cada WS 2 (o `GET` de `novas` é síncrono).
- **Correção:**
  - cursor `desde` (ISO) como no web;
  - deduplicação por `mensagem_id`;
  - uma busca em andamento por conversa (com "busca pendente" coalescida);
  - `Add` idempotente;
  - nada de REST síncrono na UI.

**A3-10 [ALTO] Use-after-free nas notificações.**
- **Local:**
  - `src/notificacao/Conversa.Notificacao.Item.Mensagem.pas:202-205`, `:212-217`;
  - `src/notificacao/Conversa.Notificacao.Item.Chamada.pas:95-114`;
  - `src/notificacao/Conversa.Notificacao.pas:175-187`;
  - `src/chamada/Conversa.Chamada.pas:472-483`, `:611-628`.
- **O que acontece:**
  - clique em notificação de mensagem: libera o frame e depois lê `FChatId`;
  - Atender/Recusar/×: o callback fecha (libera) o card e depois `Fechar` lê `FChamadaId`;
  - fechamento automático: libera o frame dentro do `OnFinish` da animação filha. Em todos os casos, o FMX continua processando o evento (mouse/animação) sobre o objeto liberado.
- **Efeito:** violações de acesso intermitentes (piores com FastMM em modo debug, que sobrescreve memória liberada); fechamento abrupto do app.
- **Correção:**
  - copiar os dados para variáveis locais antes de fechar;
  - adiar a liberação com `TThread.ForceQueue(nil, ...)` ou `Release`/`DisposeOf` adiado;
  - nunca liberar o próprio frame dentro do próprio evento.

**A3-11 [ALTO] Senha guardada sempre, com cifra de chave derivável; compartilhada no modo portátil.**
- **Local:** `Conversa.Login.pas:68-73`, `:80-83`; `lib/AES/Conversa.AES.pas:100-140`; `Conversa.WMI.pas:79-105`; `src/configuracoes/Conversa.Configuracoes.pas:39-78`.
- **O que acontece:** AES-CBC com IV fixo. A chave é o serial da placa-mãe (qualquer processo do usuário lê pelo WMI, sem privilégio) + um "sal" gravado no mesmo arquivo. Com serial vazio ou genérico, a chave é praticamente o próprio sal.
- **Efeito:** quem tiver acesso ao `conversa.json` no mesmo PC (ou souber o serial) recupera a senha. No modo portátil, todos os usuários do Windows compartilham o arquivo e entram na conta uns dos outros. Com o perfil móvel (`%APPDATA%`), o arquivo viaja para outras máquinas, onde não decifra.
- **Correção:**
  - não guardar a senha: refresh token no servidor (S13);
  - enquanto isso, DPAPI (`CryptProtectData`, escopo do usuário) ou o Gerenciador de Credenciais do Windows;
  - `conversa.json` sempre em `%LOCALAPPDATA%` (por usuário, não móvel);
  - opção "lembrar".

**A3-12 [ALTO] Chamadas com o mesmo usuário em vários aparelhos.**
- **Local:**
  - `src/chamada/Conversa.Chamada.pas:170-190` (cria objeto para qualquer `chamada_id`), `:342-406`, `:199-216` (`FinalizarTodas` na saída), `:309-324`;
  - `srv:src/chamadas.ts:164-226`.
- **O que acontece:**
  1. 53/54 "ao próprio" (recusei/atendi no celular) caem nos ramos `if StatusLocal = RecebentoChamada then Exit`: o card e a janela de chamada **continuam** no PC, sem tempo limite;
  2. se o usuário depois clicar em "Recusar" ou fechar o app, o FMX manda `POST /chamada/recusar` de uma chamada que ele mesmo atendeu no celular. O servidor não muda o status (guarda `entrou_em is null`, `srv:chamadas.ts:167`), mas grava o evento e **envia 53 a todos**, e os outros clientes podem tratar como recusa (o próprio FMX chamador encerra a chamada 1:1 em `:349-355`);
  3. caminho mais raro: 54 do próprio sem ter recebido o 51 (app aberto durante o toque) cria uma chamada "fantasma" em andamento. Na saída, `FinalizarTodas` → `POST /chamada/sair`, que **tira o usuário da chamada que ele está fazendo no celular** (`srv:chamadas.ts:213-226`, sem guarda).

  Também não há toque sonoro nem consulta a `chamadas/pendentes`.
- **Efeito:** PC "tocando" à toa, eventos espúrios e, no pior caso, a chamada do celular derrubada.
- **Correção:**
  - 53/54 com `usuario_id = eu` e estado "recebendo" → parar de tocar e descartar localmente, sem nenhuma chamada REST;
  - não criar objeto para eventos de chamadas desconhecidas (exceto 51);
  - tempo limite de 30 s;
  - toque com som;
  - `chamadas/pendentes` ao conectar.

  O ciclo de vida da chamada deve estar detalhado na parte de chamadas da auditoria.

### MÉDIO

**A3-13 [MÉDIO] Rede na thread da interface.**
- **Local:**
  - `Conversa.Dados.pas:438-450` (`Connect` + handshake);
  - `Bird.Socket.Client.pas:472-516` (leitura sem tempo limite; `delphi:IdGlobal.pas:799`);
  - `Conversa.Dados.pas:474-478`;
  - `Chamada.pas:408-421`, `:294-302` (REST síncrono nos eventos 51–55 e em Atender).
- **Efeito:** congelamentos de até ~60 s (tempo limite do `TNetHTTPClient`) em rede lenta; congelamento **indefinido** se o servidor aceitar a conexão TCP e não responder ao upgrade.
- **Correção:** toda E/S fora da UI (tarefas/threads com cancelamento), tempos limite explícitos e entrega do resultado por fila.

**A3-14 [MÉDIO] Erros do socket viram exceção ou somem.**
- **Local:**
  - `Conversa.Dados.pas:486-489` (`raise` no tipo 0);
  - `Bird.Socket.Client.pas:529-530`, `:637-638` (falha de upgrade engolida);
  - `Conversa.Dados.pas:425-426`;
  - `Conversa.Login.pas:84-85` (exceção do `IniciarMonitoramento` interrompe o fluxo de login no meio).
- **Efeito:** diálogo genérico para token inválido; nenhum aviso quando o upgrade falha (404/502); estado inconsistente (socket criado e morto).
- **Correção:** tratar 0/9 como estado (`não autenticado` → relogar → reconectar); falha de conexão alimenta o gerente de conexão (A3-01), nunca uma exceção na UI.

**A3-15 [MÉDIO] Nenhuma ressincronização.**
- **Local:** `Conversa.Tela.Inicial.view.pas:223-234`; `Conversa.Dados.pas:420-451`; rotas só na unit órfã.
- **O que acontece:** nem na abertura nem em (futuras) reconexões há `chamadas/pendentes`, `contatos/online`, `atividades/novas` ou `mensagens/novas`; `GET /conversas` roda duas vezes na abertura.
- **Efeito:** chamada que já tocava não aparece; eventos perdidos nunca são recuperados.
- **Correção:** a sequência do web (§5) a cada `onopen` e na abertura.

**A3-16 [MÉDIO] Presença, digitando e gravando ausentes.**
- **Local:** `Conversa.Dados.pas:469-490` (sem `case` para 4/5/60); `src/chat/Conversa.Chat.pas:45-48`, `:110`; `src/Conversa.Proxy.Extras.pas:356-390` (corpo `{conversa_id}` em vez de `{id}`), `:134-177` (token nunca preenchido); `srv:src/esquemas.ts:16`, `:41`.
- **Efeito:** sem paridade com PRE-01, ENV-15 e ENV-16. Se alguém ligar o `Proxy.Extras` como está, recebe 400/401.
- **Correção:**
  - envio com intervalo mínimo de 2,5 s (o último adiado) e corpo `{id}`;
  - recepção com expiração de 4 s, ignorando o próprio usuário e limpando ao chegar mensagem;
  - textos do web;
  - bolinha de online com `contatos/online` + WS 60;
  - remover o `Proxy.Extras` ou integrá-lo ao `TAPIInternal` (um só token).

**A3-17 [MÉDIO] Lógica das notificações de mensagem.**
- **Local:** `src/chat/Conversa.Chat.Listagem.pas:244-310`.
- **O que acontece e efeito:**
  - `Exit` em vez de `Continue` (`:275-276`) descarta as outras conversas do lote;
  - `sConteudo` não reiniciado: áudio, figurinha, enquete e chamada mostram o **texto da conversa anterior** (`:284-288`);
  - conversas arquivadas notificam e tocam (o FMX não lê `arquivada`);
  - som tocado uma vez por conversa;
  - menções e código crus;
  - rajada de mensagens antigas depois de reiniciar (com A3-05);
  - possível AV em `Chat.Conversa.ID` com `Chat.Conversa = nil` (`:279`, `:305`).
- **Correção:**
  - `Continue`;
  - texto por tipo, como o web (NOT-02: "Imagem", "Gravacao de audio", "Audio", "Figurinha", "Arquivo"; e "Votação"/"Chamada");
  - respeitar `arquivada`;
  - um som por lote;
  - notificar só mensagens novas desde o cursor;
  - fechar a notificação quando o contador da conversa zerar (NOT-03).

**A3-18 [MÉDIO] Primeira mensagem de conversa nova pode não aparecer nem notificar.**
- **Local:** `Conversa.Dados.pas:470-473` (40 → `GET /conversas` assíncrono), `:517-527` (`ObterMensagens`: se a conversa não está em memória, chama `CarregarConversas`, **também assíncrono**, e sai).
- **O que acontece:** a criação da conversa gera 40 e logo depois 2; o 2 é processado antes da lista chegar.
- **Efeito:** a primeira mensagem não é baixada nem notificada; só a prévia na lista aparece depois.
- **Correção:** no 2, ao achar conversa desconhecida, aguardar `/conversas` e repetir a busca, ou buscar `GET /mensagens` direto pelo `conversa_id`.

**A3-19 [MÉDIO] Contadores e mensagens próprias não sincronizam entre aparelhos.**
- **Local:**
  - `Conversa.Dados.pas:216-217` (só aceita `mensagens_sem_visualizar` do servidor se o local for 0);
  - `srv:src/notificacoes.ts:43-48`, `:65` (sem evento para o próprio usuário).
- **Efeito:** ler no celular não zera o contador nem o ícone do PC; mensagem enviada pelo celular não aparece no PC até outro evento forçar a busca daquela conversa.
- **Correção:**
  - recarregar `/conversas` em foco, reconexão e WS 3, adotando sempre o valor do servidor;
  - no servidor, um evento "lida pelo próprio" e WS 2 também para as outras conexões do remetente (S3).

**A3-20 [MÉDIO] Vazamento de GDI no contador da barra de tarefas.**
- **Local:** `lib/windows/Conversa.Windows.Overlay.pas:67-97`, `:128-134`.
- **O que acontece:** cada mudança de contagem cria dois `HBITMAP` e nunca os apaga (`CreateIconIndirect` copia; quem chama deve dar `DeleteObject`).
- **Efeito:** um app que fica dias aberto esgota os objetos GDI do processo (limite de 10.000), o que causa falhas de desenho e de criação de janelas.
- **Correção:** `DeleteObject(IconInfo.hbmMask)` e `DeleteObject(IconInfo.hbmColor)` depois do `CreateIconIndirect`. A máscara deve ser monocromática.

**A3-21 [MÉDIO] Bandeja incompleta e sem forma de sair.**
- **Local:** `Conversa.Tela.Inicial.view.pas:197-204`, `:236-272`.
- **O que acontece:** sem menu ("Abrir", "Sair", "Não perturbe"), sem contador; `TrayIconAdded` nunca `True` (ícone fantasma); sem `TaskbarCreated` (o ícone some se o Explorer reiniciar; a janela oculta só volta abrindo o exe de novo).
- **Correção:**
  - menu de contexto com "Sair" real (fecha o socket e salva a configuração);
  - `NIM_DELETE` correto;
  - recriar o ícone em `RegisterWindowMessage('TaskbarCreated')`;
  - tooltip com o número de não lidas.

**A3-22 [MÉDIO, provável] Busca incremental por `mensagemreferencia = última + 1`.**
- **Local:** `Conversa.Dados.pas:548`; `srv:src/mensagens.ts:334`, `:366`.
- **O que acontece:** o servidor resolve a posição pela linha `mensagem where id = referencia`. Se esse id não existir (lacuna na sequência: inserção que falhou, reinício do Postgres), a comparação de linha com `NULL` não devolve nada. `UltimaMensagemSincronizada` nunca avança e a conversa **para de receber mensagens novas** até reiniciar o app.
- **Correção:** usar `mensagemreferencia = última sincronizada` (que existe) com `mensagensseguintes` e descartar a própria, ou usar o cursor por data. A confirmar na parte de mensagens da auditoria.

**A3-23 [MÉDIO] Sem logout nem troca de conta; dispositivo por máquina.**
- **Local:** `Conversa.Login.pas`; `Conversa.Dados.pas:112-145`; `Conversa.Configuracoes.pas:20`.
- **Efeito:** não há como sair. Trocar de usuário exige apagar o arquivo. Alternar contas cria um dispositivo novo a cada troca.
- **Correção:**
  - "Sair": fecha o socket, apaga as credenciais, encerra chamadas e notificações, mantém o `dispositivo_id` **por usuário** (mapa `login → id`), como faz o web (AUT-05).

### BAIXO

**A3-24 [BAIXO] `UserActivity`: limiar de 1 s, corrida na partida e espera na saída.**
- **Local:** `lib/windows/Conversa.Windows.UserActivity.pas:31-34`, `:91-101`, `:104-109`.
- **Efeito:** possível notificação que nunca fecha sozinha (partida lenta) e possível travamento ao sair.
- **Correção:** iniciar o monitor depois do `Application.Run` (ex.: no `FormShow`); usar `TThread.Queue` em vez de `Synchronize`; considerar limiar maior (ex.: 30 s) para "ausente".

**A3-25 [BAIXO] Notificações próprias ignoram as configurações do Windows.**
- **Local:** `src/notificacao/Conversa.Notificacao.Visualizador.pas:117-175`; `Conversa.Configuracoes.pas:49-54`, `:63-64`.
- **O que acontece:**
  - janela TOPMOST ignora o Assistente de Foco / "não perturbe" e aparece por cima de apresentações em tela cheia;
  - não vai para a Central de Notificações;
  - sempre no monitor principal;
  - sem `FlashWindowEx`;
  - sem "iniciar com o Windows";
  - na primeira execução, `Timeout = 0` (a notificação some na hora).
- **Correção:**
  - toast nativo (`TNotificationCenter` do FMX ou WinRT, com AppUserModelID e atalho no Menu Iniciar);
  - piscar a barra de tarefas quando a janela estiver sem foco;
  - opção de iniciar com o Windows (`HKCU\...\Run`);
  - padrão `Timeout = 5` também sem arquivo.

**A3-26 [BAIXO] Defeitos menores do Bird.**
- **Local:**
  - `Bird.Socket.Client.pas:380-388` (comprimento de 64 bits com 4 bytes);
  - `:389-392` (`Random`);
  - `:556`, `:561` (exceções criadas e nunca liberadas);
  - `:161-163` (`Upgrade: WebSocket`, `Connection: keep-alive, Upgrade`);
  - `:498-499` (`OnOpen` disparado a cada linha de cabeçalho).
- **Correção:** só faz sentido se a biblioteca for mantida (ver A3-06/A3-07).

**A3-27 [BAIXO] Saída do app.**
- **Local:** `Conversa.Dados.pas:99-102` (`FBirdSocket.Disconnect` sem checar `nil`: fechar antes de logar dá AV); `Bird.Socket.Client.pas:742-750` (closures na fila referenciam o socket liberado); `:311-340` (`WaitForAll` pode relançar exceções das tarefas).
- **Correção:** `if Assigned(FBirdSocket)`; gerente de conexão com geração (ignorar eventos depois de `Destroy`).

**A3-28 [BAIXO] Instância única só em RELEASE e por pasta.**
- **Local:** `Conversa.Inicializacoes.pas:26-29`; `Windows.Utils.pas:89-158`.
- **Efeito:** em DEBUG, várias instâncias com sockets e notificações duplicados. `WM_RESTAURAR_CONVERSA` e `WM_ICONTRAY` têm o mesmo valor (`WM_USER+1`), mas em janelas diferentes.
- **Correção:** mutex nomeado por sessão (`Local\Conversa-<usuário>`) e `RegisterWindowMessage` para a mensagem de restaurar.

**A3-29 [BAIXO] Código órfão e enganoso.**
- **Local:**
  - `lib/tcp.pas` (sem uso desde `4759ba5`);
  - `src/Conversa.Proxy.Extras.pas` (fora do `.dpr`);
  - `src/notificacao/Conversa.Notificacao.Item.pas/.fmx` (não compila);
  - eventos declarados e nunca usados (`src/Conversa.Eventos.pas:24-39`);
  - `TErroServidor` sem assinante;
  - heartbeat sem ouvinte;
  - `AutoReconnect` com deadlock;
  - comentário "alinhado com backend `src/conversa/WebSocket.pas`" (servidor Delphi, que não existe mais; `src/Conversa.Tipos.pas:20-21`).
- **Efeito:** dá a impressão de funcionalidades (digitando, online, pendentes, reconexão) que **não existem** no build.
- **Correção:** remover ou integrar; atualizar o comentário do enum para `srv:src/websocket.ts`.

**A3-30 [BAIXO] Detalhes de sessão e janela.**
- **Local e detalhe:**
  - 503 do nginx mostrado como HTML (`Proxy.pas:130-133`, `:195`);
  - "Seção Encerrada!" detectada pelo texto (`:188`);
  - URL do WS descarta o subcaminho do Host (`Dados.pas:432-438`);
  - `MinimizeApp` altera `SPI_SETANIMATION` da sessão (`FormularioBase.pas:106-139`);
  - `SetWindowLong(..., LongInt(@WndProc))` incompatível com Win64 (`FormularioBase.pas:324`, `:329`);
  - nenhuma atualização do dispositivo depois do primeiro registro (`Dados.pas:131-132`).
- **Correção:** mensagens amigáveis para 429/503; `SetWindowLongPtr`/`GWLP_WNDPROC`; caminho do WS configurável.

---

## 11. Ordem sugerida e testes manuais

**Se o FMX continuar sendo mantido**, a ordem mínima é:
1. A3-03 (decisão de produto + S2.2 no servidor; medidas no cliente);
2. trocar o transporte WS (A3-06/07/08/02);
3. gerente de conexão com reconexão, ressincronização, polling e faixa (A3-01/14/15);
4. 401 e renovação (A3-04);
5. A3-05 (POST visualizar) e A3-09 (cursor `desde` + deduplicação);
6. A3-10 (use-after-free);
7. A3-11/A3-23 (credenciais e logout);
8. o resto.

**Para uma nova base**, os itens acima viram requisitos do componente de tempo real: um dono do socket, estado + geração, ping de protocolo, backoff, ressincronização, polling, 401 global, presença ativa.

**Testes manuais sugeridos** (nenhum foi executado nesta auditoria):

| # | Cenário | Verifica |
|---|---|---|
| T1 | Abrir o app, ficar 3 min sem mexer, mandar mensagem pelo web | A3-02 |
| T2 | `docker compose restart api` com o app aberto; mandar mensagem depois | A3-01 |
| T3 | Suspender o PC por 5 min, acordar, mandar mensagem | A3-01, 2.6 |
| T4 | Trocar o parâmetro `jwt_token` no servidor (invalida todos os tokens) com o app aberto; abrir uma conversa e receber mensagem | A3-04 |
| T5 | PC com o app conectado + celular com push; outro usuário manda mensagem | A3-03 |
| T6 | Ler mensagens no PC; olhar o status no remetente; reiniciar o app do PC | A3-05, A3-17 |
| T7 | Usuário com celular + web (ambos com `token_fcm`) e o PC aberto; receber mensagem | A3-09 (diálogo "Mensagem já adicionada!") |
| T8 | Chamada recebida; atender no celular | A3-12 |
| T9 | Clicar em notificações e em Atender/Recusar repetidas vezes com FastMM em `FullDebugMode` | A3-10 |
| T10 | Host `https` sem as DLLs do OpenSSL; depois, com um proxy que apresente certificado falso | A3-07, A3-06 |
| T11 | Deixar o app aberto alguns dias, com mensagens entrando; acompanhar "Objetos GDI" no Gerenciador de Tarefas | A3-20 |
