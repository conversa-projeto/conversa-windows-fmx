> **Relatório de apoio da auditoria de 2026-10-08** — frente: arquitetura, qualidade, segurança e "evoluir ou recomeçar".
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A6 — Arquitetura, qualidade do código, segurança e "evoluir ou recomeçar" (`conversa-windows-fmx`)

> **Auditoria do cliente desktop `conversa-windows-fmx` (Delphi 12 / FireMonkey) — 2026-10-08.**
> **Escopo desta parte:** transversal ao app inteiro: arquitetura, qualidade, segurança, código morto, métricas e a avaliação "evoluir ou recomeçar" (premissas: o cliente **continua em Delphi FMX** e o alvo é **só Windows**).
> **Base auditada:** branch `chamada`, HEAD `4759ba5` (2026-04-26, **não publicado**: `origin/chamada` está em `ebe5cb9`) + as alterações *staged* em `Conversa.Dados.pas` e `src/chamada/Conversa.Chamada.WebRTC.pas`.
> **Método:** leitura integral do código próprio (`*.pas` e o necessário dos `*.fmx`), exceto o vendorizado (Skia, DCPcrypt, dados de emoji e de imagem). Comparações pontuais com o servidor `conversa` (`779c8ed`). Nada foi alterado nos repositórios; só `git log/show/diff/ls-files`. O app **não** foi compilado nem executado por mim (a tentativa de outra parte da auditoria falhou: *"This version of the product does not support command line compiling"*, `scratchpad/auditoria-fmx/build/build-win64-debug.log`).
> **Convenções:** caminhos relativos a `conversa-windows-fmx/`. "Não confirmado" = dedução do código sem execução. Segredos mascarados.
> **Formato** igual ao `04-auditoria-android.md` (§3, §6, §7, §8) do Android.

---

## Sumário executivo

- **Arquitetura:** é um app "UI inteligente" com um **objeto-deus global** (`Dados: TDados`), um modelo de domínio mutável que **chama o próprio serviço global** (`Conversa.Tipos` usa `Dados`), um proxy REST de *records* estáticos e dois barramentos de eventos sobrepostos. Quase **toda a E/S de rede roda na thread principal** (login, envio, upload, download de imagens, cada aviso de mensagem nova do WebSocket, cada evento de chamada), então a UI congela; as poucas partes realmente concorrentes (WebRTC) têm corridas e *use-after-free*.
- **Segurança (6 críticos):** (P1) **toda chamada transmite a tela inteira do usuário, sem aviso**; (P2) o **WebSocket usa TLS sem validar certificado** (Indy/OpenSSL 1.0, com TLS 1.0/1.1) e manda o JWT no primeiro quadro; as DLLs do OpenSSL nem vêm com o app, então são carregadas do `PATH`; (P6) a **senha fica salva** com uma cifra reversível cuja chave é o número de série da placa-mãe (legível por qualquer processo) e o app faz login automático; (P7, alto) o identificador de anexo vindo de outro usuário vira **caminho de arquivo sem sanitização** (*path traversal*).
- **Confiabilidade (críticos):** (P3) o **tempo real morre na primeira queda de rede** e nunca volta (não há reconexão, relogin nem polling; o aviso de conexão nunca é disparado); (P4) o ciclo de vida da chamada usa `FreeAndNil(Self)` e **continua usando o objeto liberado** (inclusive *double free* no fechamento e notificações que se liberam dentro do próprio clique); (P5) **microfone e tela podem continuar transmitindo depois de desligar**, por uma corrida entre a thread de publicação e o `Desligar`.
- **Qualidade:** ~23,2 mil linhas próprias (sem a tabela de emoji), **0 testes**, ~11% de código morto, 96 `with`, 0 `resourcestring`, erros do servidor **silenciados** por desenho (`TErroServidor` não tem assinante), `ReportMemoryLeaksOnShutdown` ligado em release com vários vazamentos. Mais 46,6 mil linhas vendorizadas (Skia 6.2.0 praticamente sem uso e DCPcrypt só para a senha).
- **Build:** não é reprodutível. O exe em `bin/` é **Win32**, mas as DLLs de mídia (FFmpeg 8 e `pion_whep.dll`) são **x64**, importadas estaticamente e **fora do Git**; o `sk4d.dll` é 32 bits; a subclasse de janela usa `SetWindowLong` com `LongInt` (frágil em Win64); os offsets de structs do FFmpeg estão fixados para "7.x" sem checar versão.
- **38 problemas** numerados (P1–P38): **6 CRÍTICOS, 9 ALTOS, 11 MÉDIOS, 12 BAIXOS** (§5). As quebras de **contrato** com o servidor Bun (upload/download por MinIO, rotas que mudaram, TURN etc.) estão nos relatórios A5/A7 e só aparecem aqui quando agravam um problema de arquitetura.
- **Recomendação (§6): recomeçar o núcleo numa nova base Delphi FMX (Win64), transplantando a UI frame a frame.** Em FMX, "recomeçar" **não** significa jogar fora o visual: os 59 frames/forms, o renderizador de mensagens, o editor, as notificações e as integrações com o Windows são aproveitáveis. O que precisa nascer de novo é tudo o que tem estado ou faz E/S: sessão, cliente REST, WebSocket, cache, envio/anexos, gerenciador de chamadas e orquestração de mídia. Corrigir o atual exigiria reescrever essas mesmas peças **mantendo o estado global vivo durante a transição e sem nenhum teste**.

---

## 1. Arquitetura atual

### 1.1 Mapa de módulos (linhas de `.pas` próprias)

```
conversa-windows-fmx/                               linhas
├── Conversa.dpr + raiz (Dados, Memoria, Login,      2.386   TDados (global), TDadosApp, login, tela inicial, WMI,
│   Tela.Inicial, WMI, Log, Audio, Inicializacoes,           log, som de mensagem, REST.API (cliente HTTP genérico, 2021)
│   REST.API, Teste.Proxy)
├── src/                                            14.505   (+5.128 da tabela de emoji)
│   ├── Conversa.Tipos / Proxy / Proxy.Tipos /       ~3.100   domínio (classes mutáveis), proxy REST (records estáticos),
│   │   Proxy.Extras / Eventos / Evento.Base /               DTOs, Proxy.Extras (533, MORTO), eventos, serializer
│   │   Serializer / Loading
│   ├── base/          FormularioBase, FrameBase       574   form com barra de título própria (WndProc), frame base
│   ├── chat/          lista, chat, chat/* (frames)  ~4.900   lista de conversas, chat, renderizador, editor, emoji
│   ├── chamada/       16 units                      ~2.700   chamada (estado+REST+UI), WebRTC, histórico, waveform;
│   │                                                        Conversa.Audio + Audio.Windows (MORTOS, 449)
│   ├── notificacao/   gerenciador + itens             ~1.200  toasts próprios (Item.pas antigo MORTO, 238)
│   ├── pss/           PascalStyleScript               789   motor de temas DESLIGADO (§3.1)
│   └── configuracoes, conexao, contatos, novo/grupo,  ~1.100
│       principal, sobre, visualizadormidia
├── lib/                                             3.999
│   ├── bird-socket-client  (WebSocket sobre Indy)     ~1.000
│   ├── popupmenu                                      ~1.000
│   ├── audio  (pipeline TCP legado)                     823   AudioCapture/AudioPlayer MORTOS; AudioMixer/AudioTypes
│   │                                                        só alimentam tipos de waveform que nunca recebem dados
│   ├── tcp.pas                                          441   MORTO (áudio por TCP substituído por WebRTC)
│   ├── windows (Overlay, UserActivity, Utils)           491
│   └── AES (Conversa.AES + Prism) / DeviceInfo / Utils  ~430  (+14.760 de DCPcrypt vendorizado)
├── conversa-webrtc/                                 2.300   bindings Pion/FFmpeg, encoders/decoders, captura;
│                                                            Inicio.view/Whip.view = harness de teste (768)
├── teste/                                           2.572   protótipo VCL (mai/2025) da refatoração Proxy+Eventos
└── src/chat/chat/skia/                             31.829   Skia4Delphi 6.2.0 vendorizado
```

### 1.2 Como os módulos se ligam (estado real)

```
 ┌──────────────────────────────── processo Conversa.exe (bin/ atual = Win32) ───────────────────────────────────────┐
 Conversa.dpr ─► Iniciar ─► DefinirDiretorio (CWD = pasta do exe) ─► TConfiguracoes.Load (conversa.json: Host, Usuario,
 │                          Senha cifrada, MediaMtxBase, DispositivoId) ─► TPascalStyleScript.Start (inerte)
 │                          ─► AtualizarContadorNotificacao ─► IniciarMonitoramento (UserActivity: poll 100 ms)
 └─► TTelaInicial (form principal, bandeja, WndProc próprio) ── cria ──► Dados := TDados   (GLOBAL)
        │                                                                 ├─ FDadosApp: TDadosApp (Conversa.Memoria)
        │                                                                 │     Usuarios/Conversas/Mensagens (Conversa.Tipos)
        ├─ TConfigurarConexao / TConexaoFalhaInicio (ServerOnline = sempre True)        ▲ Conversa.Tipos chama Dados
        ├─ TLogin ── Decrypt(Senha) [WMI] ─► Dados.Login ─► TAPIConversa.Login  (REST SÍNCRONO na UI)
        └─ TPrincipalView ─► TChatListagem (GLOBAL Chats) ─► TChat ─► chat.visualizador / chat.editor
                │                                              │
                │   UI chama direto ───────────────────────────┴─► Dados.*  ─► Conversa.Proxy.TAPIConversa (records estáticos)
                │                                                       │   a) síncrono na thread da UI (login, contatos,
                │                                                       │      envio, Existe, download, MensagensNovas,
                │                                                       │      chamada: iniciar/entrar/sair/dados)
                │                                                       │   b) TThread.CreateAnonymousThread ─► TEventBase.Send
                │                                                       │      ─► ForceQueue ─► handler na main (TDados, TChat…)
                │   TMessageManager.DefaultManager ◄── setters do domínio (TMensagem.Visualizada/Recebida, TMensagens.Add)
                │        (TEventoAtualizacao*, contadores) ─► UI
                │
        TBirdSocketClient (Indy + OpenSSL 1.0, wss SEM verificação, sem reconexão)
             leitor TTask ─► TThread.Queue ─► Dados.NotificacaoSocket (main)
                   ├─ 51–55 ─► TConversaChamadas (class var) ─► TConversaChamada ── REST síncrono
                   │                ├─ TConversaChamadaView (form) + BarraTitulo + TNotificacaoManager (toast)
                   │                └─ TConversaWebRTC (singleton) ─► pion_whep.dll (Go/cgo) + avcodec-62/… (FFmpeg)
                   │                       WHIP/WHEP em  <MediaMtxBase>/call-{chamada}-u-{usuario}/whip|whep  (http://localhost:8889 por padrão)
                   │                       TScreenCapture (TELA INTEIRA, sempre) + TMicCapture (waveIn) → encoders → WhipSend*
                   │                       callbacks Go ─► decoder ─► TThread.Queue (vídeo) / waveOut (áudio)
                   ├─ 2  ─► TAPIConversa.MensagensNovas  (SÍNCRONO na main) ─► ObterMensagens ─► thread ─► evento
                   ├─ 3  ─► TAPIConversa.Mensagem.Status (thread) ─► evento
                   ├─ 40 ─► TAPIConversa.Conversas (thread) ─► evento
                   └─ 0  ─► raise Exception (diálogo de erro)
 └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 Externo:  REST <Host> (ex.: https://host:porta/api)   WS wss://host:porta/ws/   WHIP/WHEP <MediaMtxBase>
```

### 1.3 Camadas e acoplamento

Não há camadas. Há quatro "blocos" que se chamam em todas as direções:

| Bloco | Units | Problema de acoplamento (evidência) |
|---|---|---|
| UI (frames/forms) | `src/**`, `Conversa.Login`, `Conversa.Tela.Inicial.view` | Chama `Dados.*` e `TAPIConversa.*` direto: `Novo.Grupo.pas:76` e `Conversa.Contatos.pas:55` fazem REST síncrono num `TTimer`; `TChat.AoEnviar` chama `Dados.NovoChat` (`Conversa.Chat.pas:257-258`); `TConversaChamadaView.crclAtenderChamadaClick` → `Chamada.Entrar` (REST) (`Conversa.Chamada.view.pas:96-99`). |
| "Serviço" | `Conversa.Dados` (`TDados`, global) | Mistura cache, regras, E/S e **UI**: abre `TSaveDialog` (`Conversa.Dados.pas:376-392`), dispara REST e WebSocket, atualiza o contador da barra de tarefas (`:341-344`). |
| Domínio | `Conversa.Tipos`, `Conversa.Memoria` | Classes mutáveis com *fluent setters* que **disparam eventos de UI** (`Conversa.Tipos.pas:912-917`) e **usam o global `Dados`** (`:269-271` no `uses`, `:579`, `:861`, `:894`). Dependência circular domínio ↔ serviço. |
| Acesso a dados | `Conversa.Proxy`, `REST.API`, `Bird.Socket.Client` | `TAPIConversa` é um *record* com `class var`s (não injetável); lê `Configuracoes.Host` global (`Conversa.Proxy.pas:114`) e **grava** `Configuracoes` (efeito colateral no login: `:186-193`). O token fica numa `class var` privada (`:98`) — o próprio `Proxy.Extras` teve de duplicar o cliente por isso (`Conversa.Proxy.Extras.pas:134-170`). |

O módulo de chamada é o caso extremo: `TConversaChamada` faz REST, cria e posiciona forms (`Conversa.Chamada.pas:538-559`), lê `TelaInicial.lytTitleBarClient` (`:552`), decide notificação e liga a mídia — tudo na mesma classe.

### 1.4 Singletons e globais

| Global / singleton | Onde | Observação |
|---|---|---|
| `Dados: TDados` | `Conversa.Dados.pas:64-65` | Criado em `TTelaInicial.Create` (`Conversa.Tela.Inicial.view.pas:91`), liberado no `Destroy` e de novo no `.dpr` (`Conversa.dpr:81`). Usado por domínio e UI. |
| `Configuracoes`, `PastaDados` | `Conversa.Configuracoes.pas:26-28` | *Record* global gravado de várias telas e do proxy. |
| `Chats: TChatListagem` | `Conversa.Chat.Listagem.pas:65-66` | Usado pelas notificações (`Conversa.Notificacao.Item.Mensagem.pas:215`) e pela tela inicial. |
| `TelaInicial` | `Conversa.Tela.Inicial.view.pas:68-69` | Usado como "pai" por diálogos e pela chamada. |
| `TConversaChamadas.FInstance` **e** `FChamadas` | `Conversa.Chamada.pas:36-37` | `FChamadas` também é `class var` (o bloco `class var` continua na linha seguinte) — correto, mas engana quem lê. Criado num `class constructor`. |
| `TConversaWebRTC.FInstance` | `Conversa.Chamada.WebRTC.pas:63`, `:156-161`, `:470-471` | Uma única instância para **todas** as chamadas (`FChamadaId`, `FTxHandle` únicos). Liberada no `finalization` enquanto *goroutines* ainda podem chamar os callbacks. |
| `TNotificacaoManager` (var `FInstance`) | `Conversa.Notificacao.pas:72-73`, `:109-116` | |
| `TPascalStyleScript` (var `FInstance`) | `src/pss/PascalStyleScript.pas:150-151` | Carregado no início, sem efeito (§3.1). |
| Token JWT | `TAPIInternal.FToken` (`Conversa.Proxy.pas:98`), `TAPIExtras.FToken` (`Conversa.Proxy.Extras.pas:153`, nunca preenchido), `TDados.FToken` (`Conversa.Dados.pas:41`) | Três cópias. |
| `TEventBase<T,T2>.FManager` | `src/Conversa.Evento.Base.pas:17-18` | Um `TMessageManager` por tipo de evento. |
| `StatusUsuarioSO`, `UltimaContagem`, `IV`/`MotherBoardSerial`, `LogFile`/`I` | `lib/windows/Conversa.Windows.UserActivity.pas:21-28`, `lib/windows/Conversa.Windows.Overlay.pas`, `lib/AES/Conversa.AES.pas:16-18`, `Conversa.Log.Pas:16-18` | Estado de unit. |
| Vars de form geradas pela IDE e nunca usadas | `ConexaoFalhaInicio`, `NovoGrupo`, `ConversaChamadaView`, `ConversaChamadaListagem`, `Login` (`Conversa.Login.pas:51-52`, nunca atribuída — o "singleton" de `TLogin.New` não funciona) | Ruído. |

### 1.5 Padrão de eventos (`Conversa.Evento.Base` / `Conversa.Eventos`)

Há **dois barramentos** convivendo:

1. **`TEventBase<T, T2>`** (`src/Conversa.Evento.Base.pas:16-75`): cada classe de evento tem seu `TMessageManager`; `Send` faz `TThread.ForceQueue` e despacha **na thread principal**, dentro de `TMonitor.Enter(FManager)` (`:61-75`). Carrega as respostas REST (`TResposta<T>`): `TObterConversas`, `TObterMensagens`, `TObterMensagensNovas`, `TObterMensagensStatus`, `TObterDadosConversa`, `TObterChamadasHistorico`, `TExibirMensagem`, `TErroServidor` (`src/Conversa.Eventos.pas:41-52`).
   - **Ponto bom:** garante entrega na thread principal; é a melhor ideia de concorrência do código.
   - **Limites:** cancelamento por igualdade de *method pointer*; handler lento segura o `TMonitor` (quem tenta `Subscribe` de outra thread espera); exceção num handler aborta os outros e vira diálogo; não há "último valor" (tela aberta depois perde o estado); os nomes são verbos de requisição (`TObterConversas`) usados como evento de resposta.
2. **`TMessageManager.DefaultManager`** com `TEventoBase = TMessage<Integer>` (`src/Conversa.Eventos.pas:16-22`): invalidações de UI (contadores, lista, mensagem atualizada), enviadas **de forma síncrona por quem estiver mexendo no domínio** (`Conversa.Tipos.pas:636`, `:912-917`).

**Eventos declarados e nunca usados:** `TEventoUsuarioDigitando`, `TEventoUsuarioGravandoAudio`, `TEventoStatusUsuario`, `TEventoConversaAtualizada`, `TEventoChamadaVideoAtivado`, `TEventoReacaoMensagem` (`src/Conversa.Eventos.pas:24-39`, adicionados na "migração automática" de 2026-04-21), `TDownloadAnexo`, `TEnvioMensagem`. **`TErroServidor` é enviado e ninguém assina** (P9). **`TEventoStatusConexao` é assinado e ninguém envia** (`Conversa.Tela.Inicial.view.pas:94`, `:274-277`), então a faixa "sem conexão" nunca aparece (P3).

O WebSocket tem **um único ouvinte por tipo** (`lib/bird-socket-client/Bird.Socket.Client.pas:197-215` lança exceção se já houver), e todo o roteamento fica no `case` de `TDados.NotificacaoSocket` (`Conversa.Dados.pas:453-494`).

### 1.6 Modelo de threads

| Onde roda | O quê | Evidência |
|---|---|---|
| **Thread principal** | Login; contatos; criar conversa/grupo; **envio de mensagem** (inclusive leitura do arquivo inteiro, SHA-256, `anexo/existe`, `PUT mensagem`); **download de cada imagem/áudio** ao processar mensagens; **`GET mensagens/novas` a cada evento WS 2**; `GET chamada/dados` a cada evento 51–55; iniciar/entrar/sair/cancelar chamada; **conexão do WebSocket** (TCP+TLS+handshake); WMI no login | `Conversa.Login.pas:80`; `Conversa.Tela.Inicial.view.pas:223-234`; `Conversa.Dados.pas:243-290`, `:599-604`, `:477`; `Conversa.Proxy.pas:284-311`; `Conversa.Chamada.pas:296`, `:408-421`, `:462`; `Conversa.Dados.pas:438-440` |
| `TThread.CreateAnonymousThread` (16) | `GET conversas`, `mensagens`, `mensagem/status`, `chamadas`, `conversa/dados`, `mensagem/visualizar`; `PUT anexo`; publicação WHIP e assinatura WHEP; som de mensagem; *workaround* do botão desligar | `Conversa.Proxy.pas:213`, `:245`, `:315`, `:574`, `:668`, `:725`, `:790`; `Conversa.Chamada.pas:381`, `:499`, `:529`; `Conversa.Audio.pas:18`; `Conversa.Chamada.view.pas:125` |
| `TTask.Run` (5) | Leitor do WebSocket; *heartbeat* (sem ouvinte); monitor de atividade | `Bird.Socket.Client.pas:533`, `:720`; `Conversa.Windows.UserActivity.pas:91` |
| Threads da DLL Go | Callbacks de vídeo/áudio/estado → decoder FFmpeg, `waveOut`, `AddLog` | `Conversa.Chamada.WebRTC.pas:413-466` |
| Callback do `waveIn` (thread do sistema) | Encoder Opus + `WhipSendAudio` | `conversa-webrtc/Mic.Capture.pas:47-67` |
| Thread de captura de tela | `BitBlt` + encoder H.264 + `WhipSendVideo` | `conversa-webrtc/Screen.Capture.pas:59-129` |

**Acesso a componentes visuais fora da thread principal:** no código vivo **não encontrei escrita direta em componente visual fora da thread principal**. Respostas REST voltam por `ForceQueue`, o WebSocket por `TThread.Queue` (`Bird.Socket.Client.pas:742-750`), os quadros de vídeo por `TThread.Queue` (`Conversa.Chamada.WebRTC.pas:295-323`) e o monitor de atividade por `Synchronize`. Os riscos são: (a) os callbacks públicos `OnPeerAdicionado`/`OnErro` do `TConversaWebRTC` disparam em threads de trabalho ou da DLL Go (`:195-196`, `:272-273`, `:333`, `:463-464`); hoje ninguém os atribui, mas quem ligar UI ali quebra o app; (b) `AddLog` é chamado de threads Go sem trava (P27). **O problema real é o inverso:** E/S bloqueante na thread principal (P8).

### 1.7 Gestão de memória

- **Tudo é classe com `Free` manual**; só 4 `TInterfacedObject`. Não há interfaces de serviço. 78 `FreeAndNil` e 56 `.Free`.
- **`FreeAndNil(Self)` em 6 lugares**, sempre dentro de um tratador de evento do próprio objeto ou chamado por ele: `Conversa.Chamada.pas:482`; `Conversa.Configurar.Conexao.pas:80`; `Conversa.Conexao.AvisoInicioSistema.pas:71`, `:83`; `Conversa.Visualizador.Midia.pas:97`; `Conversa.Visualizador.Midia.Windows.pas:82`. Mais os toasts, que se liberam pelo gerenciador durante o próprio clique (`Conversa.Notificacao.pas:182-183`). Detalhes em P4.
- **Dono implícito:** `TBody.Value(TStream)` **libera o stream do chamador** (`REST.API.pas:543-554`), e `TAnexo.Incluir` entrega o stream a uma thread que o libera depois (`Conversa.Proxy.pas:788-814`). O chamador (`Conversa.Dados.pas:270-280`) não sabe disso, e quando o anexo já existe o stream **vaza**.
- **Dicionários sem dono:** `FChamadas` remove sem `Free` e deixa a liberação para `FinalizarLocalmente` (P4). `TConversas.Add` ignora a conversa repetida sem liberá-la (`Conversa.Tipos.pas:398-410`). `TUsuarios.Add` não deduplica (`:286-289`), então um mesmo id pode ter dois objetos (`Conversa.Dados.pas:170-177`).
- **Assinaturas sem cancelamento:** `TChat` (`Conversa.Chat.pas:113` × `:116-123`), `TConversasItemFrame` (`Conversa.Chat.Listagem.Item.pas:181`), `TDados` (`Conversa.Dados.pas:91` × `:99-110`).
- `TDadosApp.Destroy` não chama `inherited` (`Conversa.Memoria.pas:60-64`).
- `ReportMemoryLeaksOnShutdown := True` **sem `{$IFDEF DEBUG}`** (`Conversa.Inicializacoes.pas:33`): com os vazamentos acima, o usuário final pode ver a caixa *"Unexpected Memory Leak"* ao sair (P22).

### 1.8 Tratamento de erros

- **Erros do servidor são silenciados por desenho:** `ValidarErro` envia `TErroServidor` (que ninguém assina) e chama `Abort` (`Conversa.Proxy.pas:154-167`). Em thread anônima, a exceção mata a thread em silêncio; na thread principal, `EAbort` não mostra nada.
- `try … except end;` vazios: `Conversa.Chamada.pas:208-212`, `:238-267`; `Conversa.Chamada.view.pas:133-136`; `Conversa.Windows.Utils.pas:170-184`; `Conversa.Windows.UserActivity.pas:51-62`, `:68-79`; `Novo.Grupo.pas:117-124` (engole e libera).
- **Exceção usada como mensagem de UI:** validações do novo grupo (`Novo.Grupo.pas:103`, `:110`); erro de login (`Conversa.Proxy.pas:195`); evento WS tipo 0 vira `raise` na thread principal (`Conversa.Dados.pas:486-489`). O usuário vê o diálogo padrão do FMX com textos técnicos, como `'Websocket not connected or timeout …'` (`Bird.Socket.Client.pas:637-638`), `'Token vencido!'` (`REST.API.pas:716`) e `'Mensagem já adicionada! [TMensagens].FMensagens: 123'` (`Conversa.Tipos.pas:624`).
- `ShowMessage` só aparece no ramo Android do seletor de arquivos (`src/chat/chat/chat.selectfile.pas:144`). Não há um ponto central de exibição de erro.

### 1.9 Logs (`Conversa.Log.Pas`)

- Grava em `PastaDados + 'log.txt'` com `Rewrite`, então **o log é apagado a cada execução** (`Conversa.Log.Pas:26-37`). O formato é contador | data/hora | thread | mensagem. Usa `TextFile` com *buffer*, então o conteúdo se perde num travamento.
- **Só 2 chamadas no app inteiro**, ambas da mudança de estado WebRTC (`Conversa.Chamada.WebRTC.pas:456`, `:458`), feitas **de threads Go sem trava** (contador global `I` e `Writeln` concorrentes).
- **Não registra dado sensível** (nem token, nem senha, nem conteúdo). Em compensação, **não registra nada útil**: falhas REST, quedas do WebSocket, erros de mídia.
- A DLL Pion tem log próprio, desligado por padrão, que grava URL e usuário na pasta do exe ou, se falhar, em `C:\pion_whep.log` (`conversa-webrtc/pion/main.go:54-62`).

### 1.10 Build, distribuição e plataforma

- `Conversa.dproj` mira **Win32, Win64, Android e Android64** (`TargetedPlatforms=32787`, `:9`), e há código `{$IFDEF Android}` e uma pasta `Android64/` com `.dcu`/`.o`. O alvo real é só Windows.
- **Arquiteturas misturadas em `bin/`:** `Conversa.exe` é **PE32 (x86)**; `sk4d.dll` é **PE32**; `avcodec-62.dll` e `pion_whep.dll` (com `avutil`, `swscale`, `swresample`) são **PE32+ (x64)**. As DLLs de mídia são **importadas estaticamente** (`conversa-webrtc/Pion.Whep.Binding.pas:26-71`, `conversa-webrtc/FFmpeg.Binding.pas:9-12`, `:118…`): um exe Win32 com elas **não carrega**, e um exe Win64 não usa o `sk4d.dll` de 32 bits (P14).
- **DLLs de mídia fora do Git** (`?? bin/*.dll`, ~133 MB). Um clone limpo gera um exe que **não abre**.
- **Sem instalador, sem assinatura de código, sem atualização automática, sem número de versão** (`FileVersion=1.0.0.0` fixo, `Conversa.dproj:166`; "Build" do *Sobre* é a data do arquivo, `src/sobre/Conversa.Sobre.pas:54-57`).
- *Pre-build* com `taskkill /f /t /im Conversa.exe` (`Conversa.dproj:104`, `:1411…`).
- **A edição do Delphi instalada não compila por linha de comando** (log citado no cabeçalho). Isso inviabiliza CI com `msbuild` sem trocar de licença (§6.7).

---

## 2. Segurança

### 2.1 Quadro-resumo

| Tema | Situação | Problema |
|---|---|---|
| TLS do REST | `System.Net` (`TNetHTTPClient`, WinHTTP) **com validação padrão** do Windows. Nenhum `OnValidateServerCertificate` no código. ✅ | — |
| TLS do WebSocket | Indy + OpenSSL **sem verificação de certificado nem de host**, aceita TLS 1.0/1.1; OpenSSL 1.0.x **não distribuído** | **P2** |
| TLS do WHIP/WHEP | Base padrão `http://localhost:8889` (`Conversa.Configuracoes.pas:52`, `:67`); sem UI para mudar; HTTP sem TLS, sem auth | **P13** |
| Senha | Salva no `conversa.json` com AES-CBC, **IV fixo** (constante ASCII trivial, `lib/AES/Conversa.AES.pas:30`, `:51`) e **chave = serial da placa-mãe (WMI) + salt guardado junto** (`:31-37`, `:52-58`); login automático | **P6** |
| Token | Só em memória (bom), mas em 3 cópias; expira em 12 h (`conversa/src/autenticacao.ts:6`) e o cliente não se recupera | **P10** |
| Onde a sessão fica | `conversa.json` em `<pasta do exe>\Conversa\` se existir; senão em `TPath.GetHomePath\Conversa` = **`%APPDATA%` (Roaming)** (`Conversa.Configuracoes.pas:41-47`). Em `bin/Conversa/conversa.json` há `Senha` preenchida (valor mascarado nesta auditoria) | P6, P23 |
| Caminhos vindos do servidor | Identificador de anexo concatenado ao caminho sem validação; o servidor não valida o `conteudo` dos tipos 2/3/4 | **P7** |
| Execução de anexos | **Nenhum** anexo é aberto ou executado automaticamente; o cache usa o hash sem extensão; "salvar" passa por `TSaveDialog`. ✅ Mas o arquivo salvo fica **sem Mark-of-the-Web** e sem aviso para `.exe/.bat/.lnk` | P20 |
| Links | `ShellExecute(…'OPEN', link…)` com o texto do link **desalinhado** em relação ao que o regex validou (`src/chat/chat/frames/chat.conteudo.texto.pas:101`, `:121`, `:166-169`) | P20 |
| DLL hijacking | OpenSSL por nome (procura no `PATH`); `sk4d.dll` por `SafeLoadLibrary('sk4d.dll')` (`src/chat/chat/skia/System.Skia.API.pas:4566`); imports estáticos da pasta do app; nenhum `SetDefaultDllDirectories`/`SetDllDirectory` | P2, P14 |
| WMI | Só para obter o serial da placa-mãe para a chave AES; roda na thread principal; se o WMI falhar, `OleCheck` lança e **o login fica impossível** (`Conversa.WMI.pas:79-105`) | P6, P36 |
| Privacidade em chamada | **Tela inteira transmitida em toda chamada**; mic/tela podem continuar depois de desligar | **P1**, **P5** |
| Dados locais | Cache de anexos sem cifra e sem limite, em Roaming ou na pasta do exe; imagens coladas gravadas em `<exe>\clipboard\` e nunca apagadas | P23 |
| Permissões | Manifesto padrão (`asInvoker`, `Conversa.dproj:168`, `:181`): sem elevação ✅. Microfone negado nas configurações de privacidade do Windows faz `waveInOpen` falhar numa thread anônima, em silêncio | P9 |
| Logs | Sem dado sensível ✅ (e quase sem conteúdo) | P27 |
| Instância única | Só em release; compara processos pelo nome e pela pasta (`lib/windows/Conversa.Windows.Utils.pas:89-158`). Aceitável | — |

### 2.2 Notas adicionais

- **"Cifra" da senha:** `Key := UTF8(serial + salt)` é passada ao Rijndael com 256 bits, então só os 32 primeiros bytes contam. O salt é um GUID com hífens (o `Trim` só tira as pontas) e fica **gravado junto do texto cifrado** (`Conversa.AES.pas:34-37`). Em VMs e placas genéricas o serial costuma ser vazio ou "Default string". Qualquer processo do usuário lê o serial (WMI sem privilégio) e o `conversa.json`. Não há autenticação da cifra (CBC sem MAC). O `Decrypt` com chave errada (troca de placa ou VM migrada) aplica um *unpadding* PKCS7 sem validar (`lib/AES/Prism.Crypto.AES.pas:92-95`): gera lixo ou erro de faixa e dispara um login automático com senha errada; o 4xx então **apaga** a senha salva (`Conversa.Proxy.pas:186-193`).
- **Arquivos de anexo e MOTW:** o `TFile.Move` do cache para o destino escolhido não grava `Zone.Identifier`. Um `.exe`, `.js` ou `.lnk` recebido e salvo pelo chat abre **sem o aviso do SmartScreen nem a exibição protegida do Office**.

---

## 3. Outros achados

### 3.1 PascalStyleScript (tema)

- **Está desligado:** `RegisterObject` faz `Result := Self; Exit;` nas duas primeiras linhas (`src/pss/PascalStyleScript.pas:520-522`), e nenhum objeto entra no tema. Mesmo assim:
  - o motor é criado no início e **lê `.\tema\default.pss`** (caminho relativo ao CWD; `:148`, `:199-202`, `:599-602`). Se o arquivo faltar, sobe uma exceção **antes de `Application.Initialize`** (`Conversa.Inicializacoes.pas:37`; quem salva é o `SetCurrentDir` de `DefinirDiretorio`);
  - `InternalLoad` se chama recursivamente no `except` (`:435-447`, chamada em `:444`): se o tema antigo também falhar, a pilha estoura;
  - `claro.pss` e `escuro.pss` (`bin/tema/`) não são usados por nada.
- Na prática, as cores vêm dos `.fmx` (o Android novo usa essas cores como referência). **Recomendação:** remover o PSS e centralizar as cores num *record* de tokens (ou num estilo FMX), alimentado por `docs/design/cores.md`.

### 3.2 Skia vendorizado

- **Skia4Delphi 6.2.0** (`src/chat/chat/skia/System.Skia.pas:60`), 6 units, 31.829 linhas, mais `bin/sk4d.dll` de 19 MB (32 bits, mai/2025). O Delphi 12 já traz o Skia4Delphi integrado com **os mesmos nomes de unit** (`System.Skia`, `FMX.Skia`). A cópia no *search path* (`Conversa.dproj:103`) faz sombra à do produto e prende o projeto a uma DLL própria. Provável motivo: o projeto nasceu antes do Delphi 12 (primeiro commit 2023-06-28) (não confirmado).
- **Uso efetivo ≈ zero:** o único consumidor é `chat.conteudo.imagem.pas`, que só usa Skia quando o arquivo termina em `.svg/.gif/.webp/.lottie/.tgs` (`:53-67`). Imagens recebidas e enviadas são sempre exibidas a partir do cache `anexos\<sha256>` **sem extensão** (`Conversa.Dados.pas:231`, `:276`), então caem no `TImage.Bitmap.LoadFromFile` (WIC): GIF fica estático, e SVG falha.
- **Recomendação:** apagar a cópia, usar o Skia do Delphi 12 (*Enable Skia* no projeto) e decidir o formato pelo `extensao` do conteúdo, não pelo nome do arquivo em cache.

### 3.3 Código morto (fora do `.dpr` ou nunca alcançado)

| Item | Linhas | Evidência |
|---|---|---|
| `lib/tcp.pas` (cliente TCP do áudio legado) | 441 | Nenhuma unit usa; `docs/todo.md:57-58` já registra |
| `lib/audio/AudioCapture.pas`, `AudioPlayer.pas` | 392 | Sem uso |
| `lib/audio/AudioMixer.pas` + `AudioTypes.pas` | 431 | Só alimentam `TClientAudioStream`/`TWaveformData`, que **nunca são instanciados** (`Conversa.Chamada.pas:65-66`; `docs/todo.md:135-152`); o waveform desenha vazio |
| `src/Conversa.Proxy.Extras.pas` | 533 | Ninguém usa. **Armadilha:** devolve `Response.ToJSONObject/Array`, que é liberado no `Free` logo abaixo (*use-after-free*, ex.: `:200-204`), e o token (`TConversaExtrasAuth.SetToken`) nunca é preenchido |
| `src/chamada/Conversa.Audio.pas` + `Conversa.Audio.Windows.pas` | 449 | **Mesmo nome de unit** que o `Conversa.Audio.pas` da raiz (o `.dpr` aponta para a raiz; `src\chamada` está no *search path*) |
| `src/notificacao/Conversa.Notificacao.Item.pas` | 238 | Versão antiga; chama `TNotificacaoManager.Fechar(FChatId)` com assinatura que não existe mais (não compila) |
| `src/chat/Conversa.Conteudo.pas` | 84 | Usa units inexistentes (`Mensagem.Visualizador`…) |
| `src/chamada/Conversa.Chamada.Participante.Item.pas`, `src/chat/chat/frames/chat.anexo.item.pas`, `chat.editor.anexo.item.pas`, `lib/popupmenu/PopupMenu.Item.Action.Container.pas`, `lib/bird-socket-client/Bird.Socket.Client.Consts.pas`, `Teste.Proxy.pas` | ~360 | Sem referência |
| Código comentado em `Conversa.Memoria.pas` | ~180 | `:26-33`, `:66-245` |
| `TDados.ServerOnline` sempre `True` → `TConexaoFalhaInicio` nunca aparece | — | `Conversa.Dados.pas:324-339` |
| Handler da barra de título "Encerrar chamada" com corpo todo comentado | — | `src/chamada/Conversa.Chamada.BarraTitulo.pas:80-98` (P21) |
| Ramo Android (`chat.selectfile.pas:18-…`, `Conversa.DeviceInfo.Utils.pas:65-…`), pasta `Android64/`, `Serializer/`, `api/` (só `__history`) | — | Alvo é só Windows (P37) |
| **`teste/`** | 2.572 | Protótipo **VCL** de mai/2025 (`teste/Exemplo.dpr`) da refatoração "Proxy + Eventos" e de um `GenericSocket` cliente/servidor. Duplica `REST.API`, `Conversa.Proxy`, `Conversa.Eventos`, `Conversa.Evento.Base` (este idêntico). **Não são testes automatizados** |
| `conversa-webrtc/Inicio.view.pas`, `Whip.view.pas`, `TesteWebRTC.dpr` | 768 | *Harness* de teste do WebRTC (útil como ferramenta, fora do app) |

**Total estimado:** ~2,6 mil linhas mortas dentro do app (~11% das 23,2 mil), mais 2,6 mil de `teste/`, 0,8 mil do *harness* e 0,8 mil do PSS inerte.

### 3.4 TODO, "temporário" e marcas de geração automática

- TODOs: `Conversa.Dados.pas:518` ("Melhorar aqui"), `:525`; `src/Conversa.Proxy.pas:400`; `src/Conversa.Serializer.pas:17` (NULL); `src/chamada/Conversa.Chamada.Detalhe.pas:150` ("Ligar de volta" não implementado); `src/chat/chat/chat.visualizador.pas:130` (inclusão repetida "resolvida" com `Sleep(0); Exit`); `src/pss/PascalStyleScript.pas:1-6` ("Pendencia").
- Marcas de geração por IA: cabeçalhos "Migracao automatica 2026-04-21" (`src/Conversa.Proxy.Extras.pas:24`, `src/chamada/Conversa.Chamada.WebRTC.pas:31`); comentário "Claude Sonnet 4.5" em `Conversa.Chamada.pas:662`; commit `4759ba5` *Co-Authored-By: Claude Opus 4.7*. Isso explica parte das camadas "declaradas e não ligadas" (eventos novos, `Proxy.Extras`, waveform).
- `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md` descrevem uma arquitetura que não existe mais; `docs/todo.md` (não versionado, 2026-06-27) já registra isso com honestidade.

### 3.5 Duplicações e nomes inconsistentes

- **Três `TConversa`** (`Conversa.Tipos`, `Conversa.Proxy.Tipos`, `Conversa.Proxy` — este último é a API!), **três `TMensagem`**, **dois `TUsuario`** (`Conversa.Tipos`, `Conversa.Proxy`), **dois `TContato`**, **três `TConteudo`** (`Conversa.Tipos`, `chat.tipos`, `Conversa.Conteudo`). O código vive cheio de nomes totalmente qualificados (`Conversa.Proxy.Tipos.TConversa`).
- `TListBoxItem = class(FMX.ListBox.TListBoxItem)` redeclarado em **5 units** (`Conversa.Chat.Listagem.Item.pas:68`, `Conversa.Chamada.Listagem.pas:16`, `Conversa.Chamada.Usuarios.Listagem.pas:14`, `Conversa.Contatos.pas:13`, `Novo.Grupo.Usuario.Item.pas:39`), com *hard casts* que dependem da ordem do `uses`.
- Dois clientes REST com token próprio (`TAPIInternal` e `TAPIExtras`); dois pipelines de áudio (`lib/audio` e `conversa-webrtc`); dois toasts de mensagem (`Notificacao.Item` e `Item.Mensagem`, ~90 linhas de `pbTextoPaint` iguais).
- **Erros de digitação** que viraram API: `RecebentoChamada` (`Conversa.Tipos.pas:43`), `Indisposivel` (`Conversa.Chamada.view.pas:31-32`), `TResponseStatus.Sucess` (`REST.API.pas:44`), **`adicinoado_em`** (`src/Conversa.Proxy.Tipos.pas:170` — o campo nunca é desserializado), "Seção Encerrada!" (`Conversa.Proxy.pas:188`), `NomeDestinaratio`, `MsgConteduos`, `Convera`.
- Mistura de inglês e português (`TResponseStatus` × `TResposta`; Bird em inglês), units `chat.*` em minúsculas e `Conversa.*` em PascalCase, `Conversa.Log.Pas` com extensão maiúscula.

### 3.6 `with`, números mágicos, hacks e strings de UI

- **96 `with … do`**, inclusive aninhados sobre resultados de função (`Conversa.Dados.pas:117-129`, `:134-144`, `:636-656`) e sobre objetos de vida curta (`with TAPIInternal.Create do` em todo o proxy).
- **Números mágicos:** 800 (largura máxima, `Conversa.Chat.pas:131`, `:140`), 60 (altura de item, 5 lugares), 1280×720@30 a 2000 kbps fixos (`Conversa.Chamada.WebRTC.pas:205`), offsets de structs do FFmpeg (`conversa-webrtc/Audio.Player.pas:170-171`: `PInteger(PByte(FFrame)+112)`), limiares de atividade de 1000 ms (`Conversa.Windows.UserActivity.pas:31-33`), `WM_USER + 1` para duas mensagens diferentes (`Conversa.Tela.Inicial.view.pas:85-86`, `Conversa.Windows.Utils.pas:12`).
- **Hacks:** nomes de componente por *timestamp* com `Sleep(1)` "para mudar o milissegundo" (`lib/popupmenu/Popup.pas:146-148`, `:279-285`; `PopupMenu.pas:73-76`, `:177-178`; `Conversa.Notificacao.Item.Chamada.pas:65-67`; `Item.Mensagem.pas:77-79`; `Conversa.Chat.pas:103-104`; `Conversa.Chamada.view.pas:146`; `Conversa.Chamada.BarraTitulo.pas:56`); `Sleep(0)` usado como "ponto de parada" (`Conversa.Chat.pas:192-193`, `chat.visualizador.pas:133`, `Conversa.Chamada.BarraTitulo.pas:63`); `Application.ProcessMessages` (`Conversa.Chat.Listagem.pas:232`, `Conversa.Tela.Inicial.view.pas:168`, `chat.so.pas:114`); seletor de emoji por `SendInput(Win + .)` com janela nativa escondida e espera ativa (`src/chat/chat/chat.so.pas:74-121`); comentário diz `WS_EX_TOOLWINDOW` e o código põe `WS_EX_APPWINDOW` (`Conversa.Visualizador.Midia.Windows.pas:76-77`).
- **Strings de UI espalhadas:** 136 atribuições literais em `.pas` e 136 `Text = '…'` em `.fmx`; **0 `resourcestring`**; o mesmo texto repetido com variações ("Você: " em `Conversa.Tipos.pas:895`, `Conversa.Chat.Listagem.pas:123`, `:285`; "📷 Imagem" × "Imagem"). Não há i18n nem catálogo de textos alinhado ao web (doc 03 §6 do Android).

---

## 4. Métricas e avaliação franca

### 4.1 Métricas

| Métrica | Valor |
|---|---|
| Arquivos próprios `.pas`/`.dpr` (sem vendor e sem `teste/`) | 116 `.pas` + 2 `.dpr` |
| Linhas próprias | **28.318**, das quais 5.128 são a tabela de emoji, ou seja, **~23,2 mil de código**: raiz 2.386 · `src` 14.505 · `lib` 3.999 · `conversa-webrtc` 2.300 |
| `.fmx` (forms/frames do app) | 59 (78 mil linhas, incluindo dados de imagem) |
| Vendorizado | Skia 31.829 · DCPcrypt 14.760 |
| Testes automatizados | **0** (`teste/` é um protótipo VCL) |
| Maiores units | `Conversa.Tipos` 1.093 · `Conversa.Proxy` 939 · `PascalStyleScript` 789 (inerte) · `REST.API` 768 · `Bird.Socket.Client` 758 · `Conversa.Chamada` 683 · `Conversa.Dados` 659 · `Proxy.Extras` 533 (morto) · `FormularioBase` 495 · `Chamada.WebRTC` 473 · `chat.visualizador` 452 · `tcp` 441 (morto) |
| Maiores rotinas | `WndProc` (FormularioBase) ~159 · `TPascalStyleScript.Apply` ~145 · `TBirdSocketClient.ReadFromWebSocket` ~119 · `TChatVisualizador.AdicionarMensagem` ~110 · `TConversaWebRTC.AssinarDePeer` ~90 |
| Código morto estimado | ~2,6 mil linhas (~11%) + `teste/` 2,6 mil + *harness* 0,8 mil |
| Concorrência à mão | 16 `CreateAnonymousThread` · 5 `TTask.Run` · 12 `TThread.Queue` · 7 `Synchronize` · 13 `TCriticalSection` · 0 cancelamento |
| E/S síncrona na thread principal | ≥ 15 rotas (P8) |
| `FreeAndNil(Self)` | 6 |
| `with … do` / `Sleep(` / `ProcessMessages` / `except` vazio | 96 / 32 / 3 / 7 |
| Globais e singletons | ~15 (§1.4) |
| Strings de UI literais / `resourcestring` | ~272 / 0 |
| Histórico | 183 commits (2023-06-28 → 2026-04-26), 10 *stashes*; HEAD não publicado |

### 4.2 Avaliação franca

- **Arquitetura:** é um "Smart UI" com um objeto-deus global (`TDados`) e um domínio mutável que conhece o serviço e dispara eventos de tela. Não há camada de aplicação, interfaces nem injeção. O proxy REST é estático, lê e escreve configuração global e decide entre síncrono e assíncrono rota a rota, sem critério. O resultado é que **nada pode ser testado sem subir a UI e um servidor**.
- **Concorrência:** a segurança de threads foi "resolvida" fazendo quase tudo na thread principal, ao preço de congelar a UI em cada operação de rede. As partes concorrentes de verdade (WebRTC, captura, *callbacks* Go, `waveIn`) foram escritas depois, com travas pontuais e sem modelo de dono, e têm corridas e *use-after-free* (P5, P15).
- **Ciclo de vida:** o padrão "o objeto se libera no próprio evento" (`FreeAndNil(Self)`) e a posse implícita de streams e itens tornam o app sujeito a falhas que dependem do *timing* e do gerenciador de memória (P4).
- **Evolução por camadas:** dá para ver três gerações sobrepostas: 2024 (`TDados` + `Memoria`), 2025 (refatoração Proxy+Eventos, prototipada em VCL e aplicada pela metade) e 2026 (chamadas: TCP → WebRTC por "migração automática", com eventos, `Proxy.Extras` e waveform declarados e não ligados). Nenhuma geração removeu a anterior.
- **Segurança:** o REST por WinHTTP está certo. O resto (WebSocket, senha, anexos, mídia) tem problemas de projeto, não de detalhe.
- **Contrato:** o código foi escrito para o servidor Delphi. Contra o Bun atual, upload, download, mensagens novas, chamadas (TURN) e outras áreas quebram (relatórios A5/A7). Como os erros são silenciados (P9), o usuário não vê *por que* nada funciona.
- **Pontos positivos reais:**
  - Ideia correta de entregar respostas na thread principal por um barramento tipado (`TEventBase.Send` + `ForceQueue`).
  - Listagens (conversas, mensagens, histórico de chamadas) já assíncronas com evento de volta; o histórico de chamadas (`Conversa.Chamada.Listagem.pas`) é o exemplo mais limpo do app.
  - REST sobre WinHTTP (TLS e proxy do sistema).
  - Deduplicação de anexos por SHA-256 (`anexo/existe`).
  - Conversor de datas ISO-8601 centralizado (`src/Conversa.Serializer.pas:69-88`).
  - Anexos nunca executados automaticamente.
  - Integração cuidadosa com o Windows: badge na barra de tarefas, bandeja, instância única que traz a janela para frente, barra de título própria com *snap*, escala com Ctrl+roda, posição de janela salva, aviso de inatividade.
  - UI própria e polida (59 frames), **referência visual adotada pelo Android novo**.
  - Pipeline WebRTC nativo (Pion + FFmpeg) com documentação (`conversa-webrtc/pion/DOC_*.md`) e *harness* de teste.
  - Notificações empilháveis próprias com ações (atender/recusar).
  - `docs/todo.md` (jun/2026) já fazia uma revisão honesta da documentação.

---

## 5. Problemas encontrados

Formato: **Pn [SEVERIDADE] Título.** Local, o que acontece, efeitos e correção. A numeração é provisória (para consolidação com A1–A7).

### CRÍTICO

**P1 [CRÍTICO] Toda chamada transmite a tela inteira do usuário, sem aviso e sem consentimento.**
- **Local:** `src/chamada/Conversa.Chamada.pas:502` (`PublicarLocalNaSala(ChamadaId, MeuId, True, True)`, `EnviarVideo = True` fixo, chamado ao iniciar em `:469` e ao atender em `:300`); `src/chamada/Conversa.Chamada.WebRTC.pas:203-221` (`TScreenCapture.Create` + `Start(30)`); `conversa-webrtc/Screen.Capture.pas:74-103` (`BitBlt` do monitor principal inteiro, 30 fps); `src/chamada/Conversa.Chamada.view.pas:149-150` (ícone de vídeo começa em "Indisponível") e `:269-286` (em andamento não muda o ícone).
- **O que acontece:** ao iniciar ou atender qualquer chamada, de voz inclusive, o app captura e publica no MediaMTX o monitor principal em H.264 1280×720. A UI mostra o vídeo como indisponível. O botão de vídeo só alterna o que já está ligado (`:110-120`).
- **Efeitos:** vazamento de tudo o que está na tela (e-mails, senhas exibidas, documentos) para todos os participantes e, com P13, para qualquer um que assine o caminho previsível `call-{id}-u-{uid}`. É também um problema de LGPD.
- **Correção:** vídeo **desligado por padrão** (`EnviarVideo = False`); compartilhar tela só por ação explícita, com escolha de monitor ou janela (Windows Graphics Capture mostra a borda do sistema) e indicador permanente "Você está compartilhando a tela"; separar câmera de tela; renegociar a publicação ao ligar.

**P2 [CRÍTICO] WebSocket com TLS sem validação de certificado nem de host, aceitando TLS 1.0/1.1, transportando o JWT; o OpenSSL não vem com o app.**
- **Local:** `lib/bird-socket-client/Bird.Socket.Client.pas:263-272` (`TIdSSLIOHandlerSocketOpenSSL` sem `VerifyMode`/`OnVerifyPeer`, `SSLVersions = [TLSv1, TLSv1_1, TLSv1_2]`); `Conversa.Dados.pas:432-450` (com a mudança *staged*, `https` → `wss`, e o token vai no primeiro quadro `{"tipo":1,"token":…}`). `bin/` não tem `libeay32.dll`/`ssleay32.dll`, e não há `IdOpenSSLSetLibPath`.
- **O que acontece:** com `VerifyMode = []`, o Indy usa `SSL_VERIFY_NONE`: qualquer certificado é aceito e o host não é conferido. As DLLs do OpenSSL 1.0.x (EOL desde 2019) são procuradas pelo `PATH`. Se não acha, o `wss` falha (P3); se acha, carrega **qualquer** versão que estiver lá (*DLL planting*).
- **Efeitos:** quem estiver no meio da rede (Wi-Fi público, proxy corporativo) lê o JWT e tem acesso total à API por até 12 h, além de ver os eventos (quem fala com quem, chamadas). Ou então o app fica sem tempo real.
- **Correção:** trocar o cliente por **WebSocket do WinHTTP** (`WinHttpWebSocketCompleteUpgrade/Send/Receive`; SChannel, validação e proxy do Windows, sem DLL extra) ou por uma biblioteca mantida com OpenSSL 3 empacotado e verificação de cadeia e de host. Só TLS 1.2+. Nunca mandar o token sem conexão verificada.

**P3 [CRÍTICO] O tempo real morre na primeira queda e nunca volta.**
- **Local:**
  - `Conversa.Dados.pas:420-451`: conecta uma vez, na thread principal; o `if Assigned(FBirdSocket) then Exit` impede nova tentativa.
  - `lib/bird-socket-client/Bird.Socket.Client.pas:306`: `FAutoReconnect := False`, e o app nunca liga a reconexão.
  - `:643-647`: o `Reconnect` não reenviaria o login.
  - `:437-446`: `HandleException` só fecha.
  - `:637-638`: falha no *handshake* vira exceção na UI.
  - Não há ouvinte de `OPEN`, `CLOSE` nem `ERROR` (só `MESSAGE`, `Conversa.Dados.pas:439`).
  - `TEventoStatusConexao` nunca é enviado (`Conversa.Tela.Inicial.view.pas:94`, `:274-277`).
  - Não há polling alternativo.
- **O que acontece:** suspender o notebook, trocar de Wi-Fi, reiniciar o servidor ou o proxy fechar a conexão derruba o socket para sempre. O app continua na bandeja, com aparência normal.
- **Efeitos:** **mensagens e chamadas deixam de chegar** até o usuário reiniciar o app, sem nenhum aviso. Para um mensageiro que vive na bandeja, é a falha mais grave de uso diário.
- **Correção:** cliente de tempo real com máquina de estados própria (Desconectado → Conectando → Autenticando → Conectado → Aguardando com *backoff* de 1 s a 30 s e *jitter*), relogin no 401 ou no evento tipo 0, ressincronização ao conectar (doc 01 §6.7 do Android: contatos online, atividades, chamadas pendentes, mensagens novas, conversas), polling de 8 s com o socket fora (como o web), faixa visível de "sem conexão" e reação a `WM_POWERBROADCAST` e mudança de rede.

**P4 [CRÍTICO] O ciclo de vida da chamada e das notificações usa objetos já liberados.**
- **Local:**
  - `src/chamada/Conversa.Chamada.pas:472-483`: `FinalizarLocalmente` termina em `FreeAndNil(Self)`, e os chamadores continuam usando o objeto:
    - `OnChamadaFinalizada` (`:326-332`) lê `FID` depois;
    - `OnUsuarioRecusou` (`:349-354`) e `OnUsuarioSaiu` (`:399-405`) idem;
    - `Sair` (`:309-324`) é chamado por `FinalizarTodas` (`:199-216`), que depois faz `Chamada.Free` (**double free**) e remove do dicionário **durante a iteração**; tudo dentro de `try … except end`.
  - `NotificarChamada` (`:582-591`): `FChamadas.Items[AID]` lança `EListError` se a chamada já acabou.
  - Toasts: `Conversa.Notificacao.Item.Chamada.pas:102-107`. O `FOnAtender` → `Entrar` → `SetStatusLocal` → `TNotificacaoManager.Fechar` (`Conversa.Chamada.pas:613`) **libera o próprio toast** (`Conversa.Notificacao.pas:182-183`), e o handler ainda chama o método virtual `Fechar` do objeto morto.
  - `Conversa.Notificacao.Item.Mensagem.pas:212-215`: `Fechar` e depois lê `FChatId` do objeto liberado.
  - O "desligar" da janela de chamada já contorna o problema com uma thread, `Sleep(100)` e `Synchronize` (`Conversa.Chamada.view.pas:122-141`).
- **O que acontece:** com o gerenciador de memória do Delphi, o início de um bloco pequeno liberado é sobrescrito pela lista livre. A chamada virtual em objeto liberado tende a gerar *Access Violation*. Ler um campo funciona "por sorte".
- **Efeitos:** AV ao atender pelo toast (provável, não confirmado em execução), ao encerrar ou ser recusado, corrupção de heap, travamento ao fechar o app com chamada ativa.
- **Correção:** um **gerenciador de chamadas** único, dono de todas as chamadas e da UI delas; transições por máquina de estados; liberação **adiada** (`TThread.ForceQueue(nil, …Free)`) ou por contagem de referência; toasts fechados pelo gerenciador depois que o handler retorna; nunca `FreeAndNil(Self)`.

**P5 [CRÍTICO] Microfone e tela podem continuar transmitindo depois que a chamada acaba.**
- **Local:**
  - `src/chamada/Conversa.Chamada.pas:485-505`: publicação numa thread anônima, sem referência guardada.
  - `src/chamada/Conversa.Chamada.WebRTC.pas:169-244`: `WhipConnect` bloqueia na negociação e só **depois** cria encoders e capturas, sem trava nem checagem de cancelamento.
  - `:351-388`: `Desligar` sem trava nem espera pela thread de publicação.
  - Estado único da instância (`FChamadaId`, `FTxHandle`, `:66-79`) compartilhado por todas as chamadas.
- **O que acontece:** se a chamada é cancelada, recusada ou encerrada enquanto `WhipConnect` ainda negocia (segundos), o `Desligar` roda primeiro. Quando `WhipConnect` volta, a thread grava `FTxHandle` e liga `TMicCapture` e `TScreenCapture`. Uma segunda chamada sobrescreve o estado da primeira.
- **Efeitos:** microfone e tela seguem publicados sem chamada na tela, até a próxima chamada ou o fechamento do app. É uma violação de privacidade silenciosa. Também deixa *handles* WHIP órfãos.
- **Correção:** cada sessão de mídia com id de geração e `TCancellationToken`; `Desligar` cancela, espera a thread e descarta resultados de gerações antigas; uma instância de mídia por chamada; indicador de microfone e tela ativos ligado ao estado real.

**P6 [CRÍTICO] Senha salva com cifra reversível ligada ao serial da placa-mãe, e login automático.**
- **Local:** `Conversa.Login.pas:68-73` (lê, decifra e entra sozinho) e `:81-83` (cifra e salva); `lib/AES/Conversa.AES.pas:20-60` (IV fixo; chave = serial WMI + salt gravado junto); `Conversa.WMI.pas:79-105`; `src/configuracoes/Conversa.Configuracoes.pas:13-24`, `:41-47`, `:74`. Há `Senha` preenchida em `bin/Conversa/conversa.json` (mascarada).
- **O que acontece:** qualquer processo do usuário, ou quem copiar o `conversa.json` e souber o serial (frequentemente vazio ou genérico), recupera a senha em texto puro. Se o WMI falhar, `OleCheck` lança e **nem o login manual funciona**. Se o hardware mudar, o *unpadding* sem validação gera lixo e a senha salva é apagada pelo 4xx (`Conversa.Proxy.pas:186-193`).
- **Efeitos:** comprometimento da senha (geralmente reutilizada em outros serviços); travamento do login em máquinas com WMI quebrado.
- **Correção:** **não guardar a senha.** Guardar só o token com DPAPI (`CryptProtectData`, escopo do usuário) ou no Credential Manager; quando der 401, pedir a senha. Pedir ao servidor um *refresh token* (pendência já registrada no doc 08 do Android). Remover WMI, DCPcrypt e `Conversa.AES`.

### ALTO

**P7 [ALTO] Identificador de anexo vindo de outro usuário vira caminho de arquivo sem sanitização (*path traversal*).**
- **Local:** `Conversa.Dados.pas:229-241` (`PastaDados + 'anexos' + PathDelim + sIdentificador`, `TDirectory.CreateDirectory(GetDirectoryName)`, `SaveToFile`); `:599-604` (download **automático** de imagens e áudios ao processar mensagens); `:352-393` (`SalvarAnexo` faz `TFile.Move(DownloadAnexo(Identificador), destino)`). O servidor só valida o `conteudo` de figurinha (tipo 7) (`conversa/src/mensagens.ts:179-181`); os tipos 2/3/4 aceitam qualquer texto.
- **O que acontece:** um participante manda uma "imagem" com `conteudo = ..\..\..\<caminho>`. O cliente de cada destinatário cria diretórios e um arquivo nesse caminho com o corpo da resposta (vazio em erro), sem sobrescrever arquivo existente (`TFile.Exists` antes). Se o arquivo já existe, ele é **exibido como imagem** no chat. Em "salvar" de um anexo do tipo arquivo, o app **move um arquivo do próprio usuário** para o destino escolhido.
- **Efeitos:** criação de arquivos e pastas arbitrários no perfil (DoS com DLL vazia em pasta de outro app, poluição de Inicializar), exposição local de arquivos e perda ou deslocamento de arquivos do usuário. O conteúdo gravado não é controlado pelo atacante no servidor atual (não confirmado em execução).
- **Correção:** validar o identificador com `^[0-9a-f]{64}$` (ou o formato do contrato) antes de qualquer uso; resolver com `TPath.GetFullPath` e conferir o prefixo da pasta de cache; **copiar**, nunca mover, do cache; gravar em temporário e renomear; aplicar Mark-of-the-Web no arquivo salvo (P20).

**P8 [ALTO] Rede síncrona na thread principal: a UI congela em quase toda operação.**
- **Local:**
  - Login e contatos: `Conversa.Login.pas:80` e `Conversa.Tela.Inicial.view.pas:225`.
  - Conexão do WS: `Conversa.Dados.pas:438-440`.
  - Envio de mensagem: `Conversa.Chat.Listagem.pas:105-110` → `Conversa.Dados.pas:243-290`, com leitura do arquivo inteiro, SHA-256, `anexo/existe` e `PUT mensagem` síncronos.
  - Criar conversa ou grupo: `Conversa.Chat.pas:257-258`, `Novo.Grupo.pas:118`.
  - Download de cada imagem e áudio ao exibir mensagens: `Conversa.Dados.pas:601`, `:603`.
  - `GET mensagens/novas` a cada evento WS 2: `Conversa.Dados.pas:477` → `Conversa.Proxy.pas:284-311`.
  - `GET chamada/dados` a cada evento 51–55 e ao entrar ou iniciar: `Conversa.Chamada.pas:408-421`, `:296`, `:462`.
  - Contatos no `TTimer`: `Conversa.Contatos.pas:55`, `Novo.Grupo.pas:76`.
- **O que acontece:** cada uma dessas operações bloqueia a fila de mensagens do Windows enquanto a rede responde. O timeout padrão do `TNetHTTPClient` é de dezenas de segundos.
- **Efeitos:** janela "Não respondendo", cliques perdidos, toasts e animações travados, e o vídeo da chamada acumula quadros na fila (P15). Com rede ruim, o app fica inutilizável.
- **Correção:** **nenhuma E/S na thread principal.** Serviços assíncronos com fila própria e cancelamento; a UI só recebe estado pelo barramento (§6.6).

**P9 [ALTO] Erros do servidor e das threads são silenciados.**
- **Local:**
  - `src/Conversa.Proxy.pas:154-167`: `ValidarErro` envia `TErroServidor` sem assinante e chama `Abort`.
  - Todas as rotas assíncronas usam `TThread.CreateAnonymousThread`, e a exceção morre com a thread: `:213-241`, `:574-605`, `:725-744`, `:788-814`.
  - Rotas que lançam antes de enviar o evento deixam a tela esperando para sempre (ex.: `conversa/dados` com `ValidarErro` em `:585`).
  - `except` vazios listados em §1.8.
  - `PublicarLocalNaSala` lança `waveInOpen falhou` numa thread sem tratamento (`conversa-webrtc/Mic.Capture.pas:104-107`).
  - `TConversaWebRTC.FOnErro` nunca é atribuído.
- **O que acontece:** upload recusado, mensagem não enviada, chamada sem áudio (microfone bloqueado pelas configurações de privacidade) ou servidor fora: o usuário não vê nada e o estado local fica divergente.
- **Efeitos:** "o app não funciona e não diz por quê". Também impede diagnóstico (sem logs, P27).
- **Correção:** erros tipados (`EApiErro` com status, código e mensagem); toda operação assíncrona termina em sucesso ou falha **publicados** no barramento; um ponto único de UI para erros (faixa, toast, diálogo); log estruturado.

**P10 [ALTO] A sessão expira em 12 h e o cliente não se recupera.**
- **Local:** `REST.API.pas:712-726` (`TAuthBearer.Get` lança `'Token vencido!'` **antes** de enviar, porque `PrepareAuth` fica fora do `try`, `:378`); `:728-753` (`Expired` decodifica o payload base64url com `TNetEncoding.Base64`: com `-` ou `_` no payload pode gerar `'Token com formato inválido!'` em toda requisição, não confirmado); `Conversa.Dados.pas:486-489` (WS tipo 0 "Token inválido ou expirado" vira exceção); servidor: `exp: '12h'` (`conversa/src/autenticacao.ts:6`), sem rota de *refresh* (doc 01 §2.2 do Android).
- **O que acontece:** depois de 12 h com o app aberto (normal para quem deixa na bandeja), toda chamada REST falha: em silêncio nas threads, com diálogo nas síncronas. Não há relogin.
- **Efeitos:** o app quebra diariamente.
- **Correção:** tratar 401 e o evento WS 0 como "sessão expirada" → tela de login (sem senha salva, P6), ou renovação quando o servidor ganhar *refresh token*; validar a expiração com decodificação base64url correta e folga de relógio, sem lançar exceção dentro do `PrepareAuth`.

**P11 [ALTO] Envio de anexo não é transacional, consome memória demais e envenena o cache.**
- **Local:** `Conversa.Dados.pas:265-283` (lê o arquivo inteiro num `TStringStream`, que é copiado de novo por `TBody.Value`, `REST.API.pas:543-554`; o upload sai numa **thread solta** (`Conversa.Proxy.pas:788-814`) e a mensagem é incluída **logo em seguida** (`Conversa.Dados.pas:286-287`); quando `Existe` é verdadeiro, o stream vaza); `:229-241` (`DownloadAnexo` grava a resposta **mesmo em erro**, ou seja, arquivo vazio, e nunca revalida porque `TFile.Exists` encerra).
- **O que acontece:** a mensagem pode referenciar um anexo que ainda não subiu (ou que falhou em silêncio, P9). Arquivos grandes estouram os 2 GB do processo Win32. Com o servidor atual, `GET /anexo` devolve `{url}` (`conversa/src/anexos.ts:55`), e o JSON fica gravado no cache **como se fosse a imagem, para sempre**.
- **Efeitos:** anexos quebrados para os destinatários, travamentos com arquivos grandes, imagens que nunca aparecem mesmo depois de corrigir o contrato (é preciso limpar o cache).
- **Correção:** fila de envio persistente (mensagem otimista → upload em *streaming* `TFileStream` para a URL assinada → `POST /anexo/confirmar` → `PUT mensagem`), com repetição e estado visível; download para arquivo temporário com checagem de hash e renomeação atômica; cache indexado pelo identificador validado.

**P12 [ALTO] Cliente REST genérico com defeitos de codificação e de protocolo.**
- **Local:** `REST.API.pas:436-448`, `:496-499` (`TStringStream.Create` sem encoding usa `TEncoding.Default`, que no Windows é **ANSI**: JSON UTF-8 do servidor Bun com acento ou emoji vira *mojibake*; provável, não confirmado em execução); `:654-666` + `:337` (query montada sem *URL-encode* por parâmetro: nomes com `&`, `#`, `+` quebram a requisição ou injetam parâmetros, como o `nome` do anexo em `Conversa.Proxy.pas:800-805`); `src/Conversa.Proxy.pas:121-135` (todo corpo, inclusive binário de anexo, é decodificado como texto e passado ao `ParseJSONValue`); `REST.API.pas:477-482` (3xx tratado como sucesso); `:195-203` (um `TNetHTTPClient` novo por requisição, sem timeout explícito); `Tentativa` (repetição) só em 2 rotas (`Conversa.Proxy.pas:584`, `:737`).
- **Efeitos:** nomes e mensagens acentuados corrompidos, uploads com nome errado, CPU e memória gastos em downloads, falhas sem repetição.
- **Correção:** cliente tipado sobre `THTTPClient` com `TEncoding.UTF8` explícito, `TNetEncoding.URL.EncodeQuery` por parâmetro, *streams* binários separados de JSON, timeouts, política de repetição só para idempotentes e testes com *fixtures* reais.

**P13 [ALTO] WHIP/WHEP sem TLS, sem autenticação e sem TURN/STUN, apontando para `localhost` por padrão.**
- **Local:** `src/configuracoes/Conversa.Configuracoes.pas:49-53`, `:66-67` (padrão `http://localhost:8889`, sem tela para mudar); `src/chamada/Conversa.Chamada.WebRTC.pas:180-191`, `:262-268` (sem auth; `FAuthUser`/`FAuthPass` nunca preenchidos); `conversa-webrtc/pion/main.go:169`, `:353` (`ICEServers: []`); `:268`, `:457` (`http.Client{}` sem timeout); `:307-326`, `:570-588` (fecha o *PeerConnection* sem `DELETE` no `Location`).
- **O que acontece:** fora da mesma máquina ou LAN do MediaMTX, as chamadas não conectam (o servidor atual exige TURN via `GET /api/ice`, conforme doc 01 do Android). Quando conectam, o SDP trafega em HTTP: quem estiver no meio pode trocar a *fingerprint* DTLS e interceptar a mídia. O caminho `call-{id}-u-{uid}` é previsível (somado a P1). Um servidor mudo prende a thread para sempre. As sessões ficam abertas no MediaMTX.
- **Efeitos:** chamadas quebradas fora da LAN; risco de escuta; threads e sessões penduradas.
- **Correção:** derivar a base de mídia da mesma origem HTTPS da API (`/webrtc`), com credenciais de `GET /api/ice`, auth por chamada, timeout HTTP, `DELETE` ao sair e erros publicados na UI.

**P14 [ALTO] Build não reprodutível e arquiteturas misturadas.**
- **Local:**
  - `bin/Conversa.exe` é PE32 (x86) e `bin/sk4d.dll` é PE32, enquanto `bin/avcodec-62.dll` e `bin/pion_whep.dll` são PE32+ (x64), importadas estaticamente (`conversa-webrtc/Pion.Whep.Binding.pas:26-71`, `conversa-webrtc/FFmpeg.Binding.pas:9-12`).
  - As DLLs de mídia estão **fora do Git** (`git status`: `?? bin/*.dll`).
  - Subclasse de janela com `SetWindowLong(…, GWL_WNDPROC, LongInt(@WndProc))` (`src/base/Conversa.FormularioBase.pas:324`, `:329`): em Win64 trunca o ponteiro se a imagem carregar acima de 4 GB (ASLR de alta entropia; não confirmado).
  - Offsets de `AVFrame`/`AVCodecContext`/`AVPacket` fixados "para FFmpeg 7.x Win64" (`conversa-webrtc/FFmpeg.Binding.pas:46`, `:74`, `:250`, `:319`; `Audio.Player.pas:170-171`), contra DLLs `avcodec-62` (FFmpeg 8), sem `avcodec_version()`.
- **O que acontece:** nenhum build atual carrega Skia e mídia ao mesmo tempo. Um clone limpo não abre. Uma troca de versão do FFmpeg corrompe memória em silêncio.
- **Efeitos:** "funciona na minha máquina"; quebras aleatórias em chamada; impossibilidade de distribuir.
- **Correção:** fixar **Win64**; usar `SetWindowLongPtr`; versionar as DLLs (Git LFS ou pacote com *hash*) ou baixá-las num passo de build; checar a versão do FFmpeg na carga; trocar offsets por funções `av_*` (getters/opções) ou por um *shim* C mínimo; carregar a mídia por `delayed`/`LoadLibrary` com caminho completo, para o app abrir mesmo sem ela.

**P15 [ALTO] Corridas e *use-after-free* no pipeline de mídia.**
- **Local:**
  - `src/chamada/Conversa.Chamada.WebRTC.pas:413-447`: os callbacks Go acham o *peer* sob trava e o usam **fora** dela, enquanto `DesconectarPeer` (`:337-349`) o libera na thread principal.
  - `:287-324`: cada quadro de vídeo copia `H*Stride` (~3,6 MB em 720p) e enfileira um `TThread.Queue` **sem limite**; com a UI travada (P8), a memória explode (o próprio `whep-viewer-spec.md:1456` aponta isso).
  - `conversa-webrtc/Mic.Capture.pas:47-67`: o callback do `waveIn` chama encoder e rede. A documentação do `waveInProc` proíbe chamar funções de sistema ali, então `waveInReset` no *mute* (`:125-140`, via `AlternarMicrofone`) pode travar (*deadlock*, não confirmado).
  - `conversa-webrtc/Audio.Player.pas:119-141`: sobrescreve o buffer de um *header* ainda em reprodução.
  - `:166-172`: assume saída S16 intercalada do decoder Opus; o decoder nativo do FFmpeg entrega FLTP (provável ruído, não confirmado).
  - `Desligar` libera encoders sem sincronizar com a thread de captura (`Conversa.Chamada.WebRTC.pas:356-369`).
- **Efeitos:** AV ao sair um participante, consumo de memória descontrolado, travamento ao mutar, áudio picotado ou ruidoso. Falta também cancelamento de eco, supressão de ruído, *jitter buffer* e controle de banda (o encoder é fixo em 2000 kbps).
- **Correção:** ver §6.6 (decisão da pilha de mídia). Se a pilha Pion + FFmpeg ficar: contagem de referência nos *peers*, fila de quadros com descarte (só o último), thread própria de áudio alimentada por *ring buffer*, `swr` para converter o formato, `waveOut` com *headers* controlados por `WHDR_DONE` e AEC (ex.: WebRTC APM).

### MÉDIO

**P16 [MÉDIO] Mensagem recebida duas vezes derruba o processamento e duplica conteúdos.**
- **Local:** `Conversa.Dados.pas:566-568` (`ObjConversa` pode ser `nil` → AV), `:570-607` (mensagem já existente recebe `conteudos.Add` de novo e é readicionada); `Conversa.Tipos.pas:618-627` (`raise 'Mensagem já adicionada!'`). Duas buscas concorrentes (dois eventos WS 2 seguidos, ou `AoChegarLimite` com novas mensagens) devolvem a mesma faixa.
- **Efeitos:** diálogo de erro técnico, lote interrompido no meio, bolhas com imagem e texto repetidos.
- **Correção:** *upsert* idempotente por id; cursor de sincronização único; busca serializada por conversa.

**P17 [MÉDIO] Notificações perdidas e prévias erradas na lista de conversas.**
- **Local:** `src/chat/Conversa.Chat.Listagem.pas:275-276` (`Exit` em vez de `Continue`: as conversas seguintes do lote não notificam, não tocam som e não atualizam); `:279`, `:305` (`Chat.Conversa.ID` com `Conversa = nil` → AV depois de `Limpar`); `:117-129` (a prévia mostra o **último conteúdo bruto**, ou seja, o caminho local `…\anexos\<sha>` de imagem e arquivo; índice −1 se não houver conteúdo); `:307` (um som por conversa do lote).
- **Correção:** reescrever no novo *ViewModel* da lista, usando `DescricaoSimples`/textos do contrato.

**P18 [MÉDIO] *Access violations* por `nil` espalhados pelas telas.**
- **Local:**
  - `src/chat/Conversa.Chat.pas`: `:173-178` (`SetConversa(nil)`), `:392-395` (`FConversa.ID` depois de `Limpar`), `:280-290` e `:157-166` (`Mensagens.Get` pode voltar `nil`).
  - `src/Conversa.Tipos.pas:446-454`: `Destinatario` pode ser `nil` em `FromDestinatario`.
  - `src/contatos/Conversa.Contatos.pas:62` e `src/novo/grupo/Novo.Grupo.pas:88`: `Contato.nome[1]` com nome vazio.
  - `src/chat/chat/frames/chat.editor.audio.pas:105`, `:170`: `DefaultAudioCaptureDevice` é `nil` sem microfone.
  - `src/chat/chat/frames/chat.conteudo.imagem.pas:74`: arquivo de imagem inválido lança exceção dentro da montagem do chat.
- **Correção:** estados explícitos no *ViewModel*; checagens e testes.

**P19 [MÉDIO] Conversas novas com id 0 colidem, e grupo criado pela metade fica órfão.**
- **Local:** `src/contatos/Conversa.Contatos.pas:70-81` + `src/Conversa.Tipos.pas:398-410` (dois "novos chats" pendentes têm id 0: o segundo não entra na lista, vaza, e a tela abre a conversa errada); `src/novo/grupo/Novo.Grupo.pas:112-124` e `Conversa.Dados.pas:309-322` (cria a conversa e inclui membros um a um; se um falhar, o `except` engole e libera, e a conversa fica criada no servidor).
- **Correção:** id local negativo e único para rascunhos; criação de conversa num caso de uso com compensação ou numa rota única do servidor.

**P20 [MÉDIO] Links e anexos externos sem validação.**
- **Local:** `src/chat/chat/frames/chat.conteudo.texto.pas:166-172` (o regex roda sobre o texto original, mas a exibição duplica `&` (`Replace('&','&&')`) e o link é recortado do texto **exibido**, `:101`: os índices desalinham e a URL aberta pode ser outra), `:121` (`ShellExecute` sem `TURI` e com `ftp://` aceito); `src/chat/Conversa.Chat.pas:368` ("Copiar" grava `&&` na área de transferência); `Conversa.Dados.pas:376-389` (anexo salvo sem Mark-of-the-Web e sem aviso para extensões perigosas; filtro e nome sugerido vêm do servidor).
- **Correção:** guardar os links como *ranges* sobre o texto original; validar com `TURI` (só `http`/`https`) e confirmar domínio externo; gravar `Zone.Identifier` (ZoneId=3) ou usar `IAttachmentExecute`; avisar em `.exe/.bat/.cmd/.lnk/.js/.vbs/.ps1/.msi`.

**P21 [MÉDIO] Fluxo de chamada com buracos de UX e de estado.**
- **Local:**
  - `src/chamada/Conversa.Chamada.BarraTitulo.pas:80-98`: o botão "Encerrar Chamada" da barra de título não faz nada.
  - Não há toque de chamada recebida: o único som é `nova_mensagem` (`Conversa.dproj:371-375`).
  - Não há timeout de "Chamando…" nem de "Recebendo".
  - O evento 56 não é tratado (o próprio comentário *staged* reconhece, `Conversa.Chamada.WebRTC.pas:27-29`).
  - `src/chamada/Conversa.Chamada.pas:462-469`: com falha no `chamada/iniciar`, `FID` fica 0 e a publicação vai para `call-0-u-X`; a segunda tentativa colide no `FChamadas.Add(0)` (`:196`).
  - Uma segunda chamada durante a primeira compartilha o singleton de mídia (P5).
  - `src/chamada/Conversa.Chamada.Detalhe.pas:150`: "Ligar de volta" é TODO.
- **Correção:** máquina de estados do gerenciador de chamadas (§6.6), com testes de cada transição.

**P22 [MÉDIO] Vazamentos de memória e GDI, com o relatório de vazamento ligado em release.**
- **Local:** `Conversa.Inicializacoes.pas:33` (`ReportMemoryLeaksOnShutdown := True` sem `{$IFDEF DEBUG}`). Vazamentos:
  - `TUsuario` criado e não registrado (`Conversa.Dados.pas:651-654`);
  - `TStringStream` quando o anexo já existe (`:270-280`);
  - `TMensagem` de envio que falhou (`Conversa.Chat.pas:260-277`);
  - conversa duplicada ignorada (`Conversa.Tipos.pas:398-410`);
  - dois `HBITMAP` por atualização do badge (`lib/windows/Conversa.Windows.Overlay.pas:131-132`, nunca `DeleteObject`);
  - assinaturas sem cancelamento (§1.7).
- **Efeitos:** caixa "Unexpected Memory Leak" para o usuário final ao sair; esgotamento lento de GDI num app que fica dias aberto.
- **Correção:** `ReportMemoryLeaksOnShutdown := DebugHook <> 0` ou `{$IFDEF DEBUG}`; posse explícita; testes com FastMM em modo *full debug*.

**P23 [MÉDIO] Dados locais nos lugares errados e sem limpeza.**
- **Local:**
  - `src/configuracoes/Conversa.Configuracoes.pas:41-47`: modo "portátil" na pasta do exe, senão `%APPDATA%` **Roaming**. Perfis móveis sincronizam todo o cache de anexos.
  - `Conversa.Dados.pas:267-276`: **cópia** de cada arquivo enviado para o cache, sem limite nem limpeza.
  - `src/chat/chat/frames/chat.editor.texto.pas:140-152`: imagem colada (Ctrl+V) gravada em `<pasta do exe>\clipboard\clipboardN.png`, nunca apagada. `bin/clipboard` já tem 24 capturas. Falha em `Program Files` (sem permissão), e o nome por contagem colide quando um arquivo é apagado.
  - `Conversa.Log.Pas:32`: log na pasta de dados.
- **Correção:** dados em `%LOCALAPPDATA%\Conversa` (cache e banco) e configuração mínima em `%APPDATA%`; temporários em `TPath.GetTempPath` com limpeza; cota e limpeza do cache (LRU); nada na pasta do exe.

**P24 [MÉDIO] Domínio acoplado a global e a UI; nada é testável.**
- **Local:** `src/Conversa.Tipos.pas:269-271`, `:579`, `:861`, `:894` (o domínio chama `Dados`); `Conversa.Dados.pas:376-392` (o serviço abre diálogo); `src/Conversa.Proxy.pas:114`, `:186-193` (o proxy lê e grava configuração global); `src/chamada/Conversa.Chamada.pas:538-559` (o estado da chamada cria forms e lê `TelaInicial`).
- **Efeitos:** impossível escrever testes DUnitX de regra sem subir UI e servidor; qualquer mudança no núcleo é "testar na mão".
- **Correção:** camadas e interfaces (§6.6).

**P25 [MÉDIO] Bandeja, encerramento e sessão incompletos.**
- **Local:** `Conversa.Tela.Inicial.view.pas:49`, `:269` (`TrayIconAdded` nunca vira `True`: o ícone não é removido ao sair e fica "fantasma"); `:197-204` (em release o "X" só esconde a janela) e `:253-265` (a bandeja só restaura, sem menu "Sair", "Trocar usuário" ou "Servidor…"); não existe logout; trocar de servidor exige editar o JSON (`TConfigurarConexao` só aparece com `Host` vazio, `Conversa.Configurar.Conexao.pas:48-55`).
- **Correção:** menu de bandeja (Abrir, Não perturbe, Sair), logout que limpa sessão e cache, tela de servidor acessível.

**P26 [MÉDIO] Lista de mensagens sem virtualização e com posicionamento quadrático.**
- **Local:** `src/chat/chat/chat.visualizador.pas:120-229` (um `TFrame` por mensagem e mais um por conteúdo); `:238-…` (`ObtemTopMensagem` monta e ordena **todas** as mensagens a cada inclusão, O(n² log n)); `src/chat/chat/frames/chat.conteudo.mensagem.audio.pas:62` (um `TMediaPlayer` aberto por bolha de áudio).
- **Efeitos:** conversas longas ficam lentas e pesadas em memória; muitos *handles* de mídia abertos.
- **Correção:** lista virtualizada com reciclagem de células; *player* único compartilhado.

### BAIXO

**P27 [BAIXO] Logs praticamente inexistentes e não thread-safe.**
- **Local:** `Conversa.Log.Pas:26-37`, chamado só de threads Go (`Conversa.Chamada.WebRTC.pas:456`, `:458`); o `Rewrite` apaga o log a cada execução; a Pion grava em `C:\pion_whep.log` no *fallback* (`conversa-webrtc/pion/main.go:54-62`).
- **Correção:** logger com fila e thread própria, rotação e redação (token, senha, conteúdo) por padrão.

**P28 [BAIXO] Monitor de atividade agressivo e com risco de travar no fechamento.**
- **Local:** `lib/windows/Conversa.Windows.UserActivity.pas:31-33` (polling de 100 ms; inativo após **1 s**), `:52-79` (`Synchronize`), `:105-110` (`MonitorTask.Wait` na thread principal no fechamento: se a tarefa estiver dentro do `Synchronize`, as duas threads se esperam).
- **Correção:** `WM_WTSSESSION_CHANGE`/`GetLastInputInfo` a cada 5–15 s, limiar de minutos, `Queue` em vez de `Synchronize`, cancelamento sem `Wait` bloqueante.

**P29 [BAIXO] PascalStyleScript carregado mas desligado.** Ver §3.1 (`src/pss/PascalStyleScript.pas:520-522`, `:148`, `:435-447`).

**P30 [BAIXO] Skia vendorizado sem uso efetivo.** Ver §3.2.

**P31 [BAIXO] Código morto e duplicado.** Ver §3.3 e §3.5 (inclui a armadilha de UAF do `Proxy.Extras` e as duas units `Conversa.Audio`).

**P32 [BAIXO] Hacks de UI.** Nomes por *timestamp* com `Sleep(1)`, `Sleep(0)` como ponto de parada, `ProcessMessages`, emoji por `SendInput`, var `Login` nunca atribuída. Ver §3.6.

**P33 [BAIXO] Strings de UI sem centralização e erros de digitação que viraram API.** Ver §3.5 e §3.6 (inclui `adicinoado_em`, que nunca desserializa).

**P34 [BAIXO] Áudio de mensagem: extensão e duração erradas.**
- **Local:** `src/chat/chat/frames/chat.editor.audio.pas:169` (grava `.mp3`, mas a captura do FMX no Windows gera WAV; provável, não confirmado); `src/chat/chat/frames/chat.conteudo.mensagem.audio.pas:79`, `:101`, `:147` (`Duration.ToString` mostra *ticks* de 100 ns).

**P35 [BAIXO] Implementação de WebSocket ingênua.**
- **Local:** `lib/bird-socket-client/Bird.Socket.Client.pas:547-583` (lê byte a byte concatenando arrays, O(n²); não trata fragmentação nem `FIN=0`); `:380-388` (para quadros de 64 KiB ou mais, escreve 4 bytes de tamanho estendido em vez de 8); `:389-392`, `:425-427` (`Random` como máscara e chave); `:197-215` (um único ouvinte por tipo); *heartbeat* sem ouvinte (`:716-740`).
- **Nota:** só deixa de ser relevante se P2/P3 trocarem o cliente.

**P36 [BAIXO] Configuração frágil.**
- **Local:** `src/configuracoes/Conversa.Configuracoes.pas:70-78` (gravação não atômica com `TFile.WriteAllText`; gravada de vários pontos, inclusive a cada Ctrl+roda, `Conversa.Tela.Inicial.view.pas:165-166`); `lib/windows/Conversa.Windows.Utils.pas:187-198` (restaura a posição sem checar se o monitor ainda existe: janela fora da tela); WMI na thread principal no login (`lib/AES/Conversa.AES.pas:31`, `:52`).

**P37 [BAIXO] Resíduos de alvo Android num app só Windows.** `Conversa.dproj:9` (Android e Android64), `{$IFDEF Android}` em `src/chat/chat/chat.selectfile.pas` e `lib/Conversa.DeviceInfo.Utils.pas`, pasta `Android64/`.

**P38 [BAIXO] Exceções técnicas como UX de erro.** `Novo.Grupo.pas:103`, `:110`; `Conversa.Dados.pas:488`; `Bird.Socket.Client.pas:118-134`, `:637-638`; `REST.API.pas:716-744`. Mensagens cruas, metade em inglês, no diálogo padrão.

---

## 6. Avaliação: evoluir ou recomeçar?

> Premissas: continua **Delphi FMX**, alvo **só Windows**. A comparação é entre **evoluir o código atual** e **recomeçar uma nova base Delphi FMX**, transplantando o que presta.

### 6.1 Argumentos para evoluir o código atual

1. **O visual é bom e já é referência:** 59 frames/forms próprios, cuja paleta o Android novo adotou (`conversa-android-kotlin/CLAUDE.md`, "Cores: … vêm do conversa-windows-fmx"). Em FMX esse trabalho é caro de refazer.
2. **Há componentes de UI com valor real:** renderizador de bolhas (`chat.visualizador`, `chat.mensagem`, `chat.conteudo.*`), editor com anexo, áudio e emoji, toasts empilháveis com ações, barra de título própria, badge na barra de tarefas, bandeja, visualizador de imagem.
3. **O pipeline WebRTC nativo é recente** (abr/2026), tem documentação e um *harness* de teste.
4. **A equipe conhece o código** e o Delphi; não há troca de linguagem.

### 6.2 Argumentos para recomeçar (o núcleo e o esqueleto)

1. **Os defeitos críticos estão no núcleo, não nas bordas:** sessão e senha (P6, P10), WebSocket (P2, P3), E/S na UI (P8), erros silenciados (P9), anexos (P7, P11), ciclo de vida e mídia da chamada (P1, P4, P5, P15). Corrigir significa reescrever `Conversa.Dados`, `Conversa.Memoria`, `Conversa.Tipos`, `Conversa.Proxy*`, `REST.API`, `Bird.Socket.Client`, `Conversa.Login`, `Conversa.Configuracoes`, `Conversa.AES`, `Conversa.Chamada` e `Conversa.Chamada.WebRTC`, que é **tudo o que tem estado ou faz E/S**.
2. **O contrato mudou por baixo** (servidor reescrito em Bun; relatórios A5/A7): upload e download por MinIO, mensagens ocultas, referências, enquetes, atividades, TURN, eventos 57/61/62. A camada de dados precisa ser refeita de qualquer forma.
3. **Não existe rede de proteção:** zero testes, estado global e domínio que chama o serviço global (P24). Evoluir "no lugar" obrigaria a manter o `Dados` global vivo durante a transição, com as duas gerações convivendo, como já aconteceu três vezes (§4.2).
4. **A maior parte do produto ainda não existe:** o web tem 137 funcionalidades (doc 03 do Android); o FMX cobre uma fração (relatórios A5a/A5b). Construir o que falta sobre um núcleo síncrono e global multiplica o custo.
5. **O build precisa ser refeito de qualquer forma:** Win64 único, DLLs versionadas, Skia do produto, instalador assinado e atualização (P14). Também falta uma licença que permita compilar por linha de comando.
6. **Código morto, vendorizado e duplicado** (~11% do código, mais 46,6 mil linhas vendorizadas) aumentam o custo de qualquer manutenção.

### 6.3 Recomendação

**Recomeçar o núcleo e o esqueleto numa nova base Delphi FMX (Win64), e transplantar a UI frame a frame.** Nem remendar o atual, nem descartar o visual.

- **Onde:** mesmo repositório. Novo projeto (`app/Conversa.dpr`, Win64) em branch própria. O app atual fica congelado numa tag (`legado-fmx-v1`), recebendo só o pacote de higiene do §6.8 se alguém depender dele.
- **Ordem:** primeiro o núcleo testável (sessão, HTTP tipado, tempo real, cache, barramento), depois chat, depois chamadas, depois paridade com o web, seguindo a fila de correções (doc 06) e a matriz de paridade.
- **Proporção esperada:** de ~23,2 mil linhas próprias, cerca de **35–40% são transplantáveis** (frames e componentes de UI, integrações com o Windows, tabela de emoji e bindings de mídia com ajustes). O restante é reescrito ou descartado.

### 6.4 Aproveitáveis (com os ajustes indicados)

| Peça | Arquivo(s) | Ajustes |
|---|---|---|
| Visual de forms e frames | `src/**/*.fmx` + `.pas` de apresentação (lista, chat, editor, contatos, grupo, chamada, histórico, sobre, login) | Tirar toda chamada a `Dados`/`TAPIConversa`; ligar a *ViewModels*/*Presenters*; remover nomes por *timestamp* e `Sleep`; usar um só `TListBoxItem` (ou lista virtual) |
| Renderizador de mensagens | `src/chat/chat/chat.visualizador.pas`, `chat.expositor`, `chat.ordenador`, `frames/chat.mensagem*`, `chat.conteudo.*`, separadores | Virtualizar (P26); receber modelos imutáveis, não caminhos de arquivo; formato pela `extensao` |
| Editor de mensagem | `src/chat/chat/frames/chat.editor*.pas` | Áudio em formato real (P34); colar imagem em `%TEMP%` (P23); envio pelo caso de uso (fila) |
| Emoji | `src/chat/chat/chat.emoji.pas` (tabela) + `TEmojiItem.SoEmoji` | Manter a tabela; trocar o `SendInput` (P32) por um seletor próprio ou mantê-lo isolado |
| Toasts | `src/notificacao/Conversa.Notificacao*.pas` (menos `Item.pas`) | Fechar pelo gerenciador **depois** do handler (P4); considerar notificações nativas do Windows (*toast* WinRT) como alternativa |
| Barra de título, bandeja e instância única | `src/base/Conversa.FormularioBase.pas`, `Conversa.Tela.Inicial.view.pas` (partes), `lib/windows/Conversa.Windows.Utils.pas` | `SetWindowLongPtr` (P14); `TrayIconAdded` (P25); *mutex* nomeado para instância única; menu da bandeja |
| Badge na barra de tarefas | `lib/windows/Conversa.Windows.Overlay.pas` | `DeleteObject` dos bitmaps (P22) |
| Inatividade | `lib/windows/Conversa.Windows.UserActivity.pas` | P28 |
| Barramento de eventos (ideia) | `src/Conversa.Evento.Base.pas` | Manter a entrega na thread principal; acrescentar multi-assinante com token de cancelamento, isolamento de exceção e "último valor" |
| Conversor de datas | `src/Conversa.Serializer.pas` | Cobrir `null` (TODO `:17`) e testar |
| Info do dispositivo | `lib/Conversa.DeviceInfo.Utils.pas` (parte Windows) | — |
| Popup e menu | `lib/popupmenu/*` | Remover nomes por *timestamp* |
| Visualizador de imagem | `src/visualizadormidia/*` | Remover `FreeAndNil(Self)` |
| Mídia nativa (se a opção A do §6.6 for escolhida) | `conversa-webrtc/Pion.Whep.Binding.pas`, `pion/main.go`, `Video.Encoder/Decoder`, `Audio.Encoder/Player`, `Mic.Capture`, `Screen.Capture` | P13 (ICE/TURN, auth, timeout, `DELETE`), P14 (versão do FFmpeg, offsets), P15 (threads, formatos, AEC); captura de tela só por escolha (P1) |
| Waveform (visual) | `src/chamada/Conversa.Chamada.Waveform.pas` + `TWaveformData` (`lib/audio/AudioTypes.pas`) | Alimentar a partir do decoder |
| Histórico de chamadas | `src/chamada/Conversa.Chamada.Listagem*.pas`, `Detalhe` | Já é o padrão certo (assíncrono e evento); ajustar ao contrato |
| *Harness* de WebRTC | `conversa-webrtc/Inicio.view.pas`, `Whip.view.pas` | Manter como ferramenta de desenvolvimento, fora do app |

### 6.5 Descartar

- `Conversa.Dados`, `Conversa.Memoria`, `Conversa.Tipos` (reescrever como domínio imutável), `Conversa.Proxy`, `Conversa.Proxy.Tipos` (DTOs novos a partir do contrato), `Conversa.Proxy.Extras`, `REST.API`.
- `lib/bird-socket-client/*` (trocar por WinHTTP WebSocket).
- `Conversa.Login` (lógica), `Conversa.Configuracoes` (refazer em `%LOCALAPPDATA%`), `lib/AES/*` (inclusive DCPcrypt), `Conversa.WMI`.
- `Conversa.Chamada` e a orquestração de `Conversa.Chamada.WebRTC` (refazer como gerenciador com máquina de estados).
- `Conversa.Log` (trocar por logger), `src/pss/*` e `bin/tema/*`, a cópia do Skia (`src/chat/chat/skia/**`) e `bin/sk4d.dll`.
- `lib/tcp.pas`, `lib/audio/AudioCapture|AudioPlayer|AudioMixer`, `src/chamada/Conversa.Audio*.pas`, `src/chat/Conversa.Conteudo.pas`, `src/notificacao/Conversa.Notificacao.Item.pas`, `Conversa.Chamada.Participante.Item.pas`, `chat.anexo.item.pas`, `chat.editor.anexo.item.pas`, `Teste.Proxy.pas`, `Bird.Socket.Client.Consts.pas`, `PopupMenu.Item.Action.Container.pas`.
- `teste/` (arquivar fora do app), `Android64/`, `Serializer/`, `api/`, ramos `{$IFDEF Android}`.
- `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md` (arquivar como legado, como o `docs/todo.md` já propõe).

### 6.6 Arquitetura-alvo (Delphi FMX, Win64)

**Estrutura** (pacotes lógicos; podem ser pastas e units com prefixo antes de virarem `.bpl`):

```
conversa-windows-fmx/
├── app/                 Conversa.dpr (Win64) · composição (registro de serviços) · bootstrap · TTelaPrincipal
├── core/
│   ├── dominio/         Conversa.Dominio.*  — records e classes imutáveis (Conversa, Mensagem, Conteudo, Usuario,
│   │                    Chamada, Atividade, Enquete…), enums do contrato, regras puras. Sem FMX, sem rede.
│   ├── contrato/        DTOs + mapeadores DTO→domínio (System.JSON.Serializers com conversores), testados com
│   │                    fixtures JSON reais (tirados dos testes do servidor)
│   ├── infra/
│   │   ├── http/        IConversaApi + TConversaApi sobre THTTPClient (WinHTTP: TLS, proxy e certificados do Windows),
│   │   │                UTF-8 explícito, query codificada, timeouts, retry só em idempotentes, EApiErro tipado,
│   │   │                tratamento de 401 → evento "SessaoExpirada"
│   │   ├── tempo-real/  ITempoReal + TTempoRealWinHttp (WinHttpWebSocket*), thread própria, máquina de estados
│   │   │                com backoff + jitter, geração por conexão, ping; TParserEventos → eventos tipados (0–62)
│   │   ├── armazenamento/ SQLite via FireDAC (ou mORMot2 estático) em %LOCALAPPDATA%\Conversa: conversas,
│   │   │                mensagens, usuários, cursores, fila de envio; migrações versionadas
│   │   ├── sessao/      TSessaoDPAPI (CryptProtectData) — só o token; nunca a senha
│   │   ├── anexos/      TGerenciadorAnexos: upload em streaming p/ URL assinada + confirmar; download p/ temp
│   │   │                + hash + rename; cache por identificador VALIDADO com cota/LRU; Mark-of-the-Web ao salvar
│   │   └── log/         TLogger (fila + thread, rotação, redação de token/senha/conteúdo)
│   ├── aplicacao/       Casos de uso/serviços: TSessaoServico, TConversasServico, TMensagensServico (envio
│   │                    otimista + fila persistente), TSyncManager (ressincroniza ao reconectar), TPresenca,
│   │                    TAtividades, TGerenciadorChamadas (máquina de estados, dono único das chamadas)
│   └── eventos/         TBarramento: multi-assinante, tipado, entrega na thread principal por fila,
│                        assinatura devolve IInterface (cancela no Free), isolamento de exceção, "último valor"
├── midia/               IMidiaChamada  → opção A: TMidiaPion (pion_whep.dll + FFmpeg, corrigidos)
│                                       → opção B: TMidiaWebView2 (WebRTC do navegador numa página local)
├── ui/                  frames transplantados + ViewModels/Presenters (sem E/S), tema por tokens de cor,
│                        textos em units de resourcestring alinhadas ao web
├── testes/              DUnitX: parser WS, mapeadores, máquina de estados de chamada, SyncManager,
│                        validação de identificador, fila de envio, sessão; fakes de IConversaApi/ITempoReal
└── build/               scripts msbuild (Win64 Release/Debug), obtenção das DLLs com hash, instalador
                         (Inno Setup/MSIX) assinado, canal de atualização
```

**Regras de projeto:**

1. **Nenhuma E/S na thread principal.** Serviços rodam em threads ou tarefas próprias com `TCancellationToken`; a UI só recebe estado pelo barramento (fila para a thread principal).
2. **Dono único por recurso:** a sessão é do `TSessaoServico`, a conexão do `TTempoReal` e cada chamada do `TGerenciadorChamadas`. Nenhum objeto se libera dentro do próprio evento.
3. **Domínio imutável entre threads.** Mudanças viram novos valores publicados ("estado" por tela).
4. **Erros publicados, nunca engolidos**, com um ponto central de UI.
5. **Contrato como fonte da verdade:** doc 01 do Android e os testes do servidor. Nada é deduzido do código legado.

**Tempo real:** `WinHttpWebSocket*` (Windows 8+) dá TLS do sistema, validação de certificado, proxy corporativo e nenhuma DLL extra, resolvendo P2 e P35 de uma vez. Alternativas: sgcWebSockets (comercial, maduro) ou ICS (OpenSSL 3, gratuito). Comportamento igual ao web: login `{tipo:1}`, ressincronização na reconexão, polling de 8 s com o socket fora.

**Gerenciador de chamadas** (estados mínimos): `Ocioso → Chamando | Recebendo → Conectando → EmAndamento → Encerrando → Encerrada`, mais `Falhou`. Entradas: eventos WS 51–57, ações do usuário, timeouts (toque e "chamando"), eventos de mídia. Saídas: comandos REST (iniciar, cancelar, recusar, entrar, sair, finalizar, vídeo, usuário), comandos de mídia e estado para a UI e os toasts. **Toda transição tem teste DUnitX.** A mídia é criada e destruída só pelo gerenciador, com id de geração (resolve P4 e P5).

**Pilha de mídia (decisão a validar com protótipo):**

| Opção | Prós | Contras |
|---|---|---|
| **A — Pion + FFmpeg** (transplante corrigido) | Controle total; já existe; sem navegador | ~133 MB de DLLs; offsets e versões do FFmpeg (P14); **sem AEC, supressão de ruído, AGC, *jitter buffer* nem controle de banda** (eco com caixa de som); captura e codec mantidos à mão; cgo + Go para depurar |
| **B — WebView2** (`TWebBrowser` do FMX com motor Edge, ou WebView2 direto) com uma página local de chamada que reaproveita a lógica WebRTC do web (`conversa-web/src/stores/call.ts`) e uma ponte JS↔Delphi para sinalização e estado | AEC, NS, AGC, *jitter buffer*, TURN, codecs, `getDisplayMedia` com seletor do sistema e indicador nativo de compartilhamento; paridade com o web quase automática | Depende do WebView2 Runtime (presente no Windows 10/11 atualizados); UI de chamada híbrida; validar permissões de mídia (`PermissionRequested`) na versão do Delphi 12 |

**Recomendação:** fazer um *spike* da opção B no início da fase de chamadas e manter A como plano B. A interface `IMidiaChamada` isola a escolha.

**Cache local:** SQLite (FireDAC com driver SQLite; confirmar que a edição licenciada inclui, ou usar o SQLite estático do mORMot2). Habilita abrir o app offline com o histórico, envio otimista e cursor de sincronização.

**Testes e CI:**
- DUnitX (vem com o Delphi) e TestInsight no IDE.
- CI com `msbuild` (via `rsvars.bat`) num *runner self-hosted*: build Win64 Release, testes, análise (Pascal Analyzer ou FixInsight, opcional), empacotamento e assinatura.
- **Bloqueio:** a edição instalada não compila por linha de comando (Community). CI exige Professional ou superior.

**Riscos:**
1. **Custo e prazo:** paridade com 137 funcionalidades do web. O app atual fica congelado (só a higiene do §6.8).
2. **Licença** para build por linha de comando (CI) e possível ausência de FireDAC/SQLite na edição.
3. **Mídia:** maior risco técnico (A × B). Exige protótipo cedo e testes manuais de áudio e eco em notebooks reais.
4. **Desempenho do FMX** em listas longas: virtualização feita à mão.
5. **Contrato em movimento** (servidor com 69 rotas e mudanças semanais): mitigar com testes de contrato com *fixtures* e revisão semanal (como no Android).
6. **Dependências do servidor:** *refresh token* (sem ele, pedir a senha a cada 12 h), auth no MediaMTX e checagem de participação em `GET /anexo` (pendências S… do doc 08 do Android).
7. **Disciplina nova:** testes, revisão e histórico de alterações são práticas que o projeto ainda não tem.

### 6.7 Fases sugeridas (resumo)

| Fase | Entrega | Critério de pronto |
|---|---|---|
| F0 (opcional) | Higiene do app atual (§6.8) | Só se houver usuário dependendo do exe atual |
| F1 Esqueleto | Projeto Win64, composição, logger, configuração e sessão (DPAPI), `IConversaApi` tipado (login, conversas, mensagens), `ITempoReal` WinHTTP + parser + barramento, SQLite, DUnitX + CI | Login, lista de conversas e chegada de mensagem em tempo real **com reconexão**, sem travar a UI; testes verdes no CI |
| F2 Chat | Lista e chat transplantados (virtualizados), envio otimista com fila, anexos MinIO, download seguro, notificações | Paridade com o núcleo de mensagens do web (A5b) |
| F3 Chamadas | `TGerenciadorChamadas` + `IMidiaChamada` (*spike* A × B), TURN, compartilhar tela só por ação, toque e timeouts | Matriz de testes de chamada (1:1, grupo, cancelar, recusar, queda de rede, suspensão) |
| F4 Paridade e distribuição | Restante do inventário do web por prioridade; instalador assinado; atualização | Matriz de paridade atualizada; instalador publicado |

### 6.8 Ações imediatas, se o app atual continuar em uso enquanto a nova base nasce

1. **P1:** `PublicarLocalNaSala(ChamadaId, MeuId, False, True)` (`Conversa.Chamada.pas:502`); vídeo só pelo botão.
2. **P6:** parar de salvar a senha (remover `Encrypt` e o login automático em `Conversa.Login.pas:69-73`, `:82`) e apagar `Senha` dos `conversa.json` existentes.
3. **P7:** validar o identificador (`^[0-9a-f]{64}$`) em `DownloadAnexo` e `SalvarAnexo`; trocar `TFile.Move` por `TFile.Copy`.
4. **P2:** no mínimo `VerifyMode := [sslvrfPeer]` com `OnVerifyPeer` checando o host, só TLS 1.2 e OpenSSL na pasta do app com `IdOpenSSLSetLibPath`; ou manter o WS desligado fora de rede confiável.
5. **P5/P4:** guardar a thread de publicação e fazer `Desligar` esperar por ela; trocar `FreeAndNil(Self)` por liberação adiada (`TThread.ForceQueue`).
6. **P22:** `ReportMemoryLeaksOnShutdown` só em DEBUG.
7. **P14:** fixar uma arquitetura (Win64) e versionar ou documentar as DLLs.

Mesmo com isso, o app atual **não deve ser distribuído** a novos usuários: as quebras de contrato (A5/A7), P3, P8 e P10 continuam.

---

*Fim do relatório A6.*
