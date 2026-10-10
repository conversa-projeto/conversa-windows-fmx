# 04 — Auditoria do cliente Windows (Delphi 12 / FireMonkey)

**Repositório:** `conversa-windows-fmx` · **Data da auditoria:** 2026-10-08 · **Branch auditada:** `chamada` (HEAD `4759ba5`, 2026-04-26) + alterações *staged* em 2 arquivos.
**Comparado com:** servidor `conversa` em `779c8ed` (Bun + Elysia; contrato no doc 01) e cliente web `conversa-web` em `e8d82cb` (comportamento no doc 03). O servidor de abril (Delphi/Horse, `56e7cc0`) foi usado para separar o que quebrou na reescrita do que já não funcionava.
**Escopo:** todo o código próprio (`*.pas`, `*.dpr` e o necessário dos `*.fmx`), o `Conversa.dproj`, o histórico Git (branches, *stashes*, *staged*), as DLLs de tempo de execução (só lidas, nunca executadas), a documentação existente e os projetos auxiliares (`conversa-webrtc/`, `teste/`). O código vendorizado (Skia4Delphi, DCPcrypt, dados de emoji e de imagem) foi avaliado só quanto ao uso e à licença.
**Restrição respeitada:** nenhum arquivo do projeto foi modificado. A tentativa de build gerou só arquivos já ignorados pelo `.gitignore` (`Conversa.res`, `Conversa.dres`, `ConversaResource.rc`).
**Como foi feita:** varredura em 8 frentes (repositório e build; REST e anexos; WebSocket, sessão e notificações; chamadas e mídia; funcionalidades gerais e de desktop; funcionalidades de mensagens; qualidade e segurança; validação dos docs 01 e 03). Os relatórios completos de cada frente estão em `apoio/` (A1–A7), com todas as evidências. Este documento consolida e numera os problemas (#1–#103).

> Convenção de caminhos: relativos à raiz de `conversa-windows-fmx/`. `conversa/…` é o servidor e `conversa-web/…` é o web. `arquivo:linha` se refere à **árvore de trabalho** (HEAD + *staged*). "Não confirmado" = dedução do código, sem execução.

---

## Sumário executivo

- **Build:** não foi possível compilar. O Delphi desta máquina é o **12.1 Athens Community** (o registro informa `Edition = Starter`), que **bloqueia a compilação por linha de comando** (`msbuild`, `dcc32` e `dcc64` respondem *"This version of the product does not support command line compiling"*). Pior: **o MSBuild sai com código 0** mesmo sem compilar. Por indícios (datas dos `.dcu` e do `.rsm`), a árvore atual compilou no IDE em **Win32** em 2026-06-27 e o HEAD compilou em **Win64** em 2026-04-26.
- **O app provavelmente nem abre como está em `bin/`:** o `bin/Conversa.exe` é **x86**, mas as 5 DLLs de mídia (`pion_whep.dll` e FFmpeg) são **x64** e entram por *import* estático; já um build Win64 carregaria o `bin/sk4d.dll` versionado, que é **x86**. As DLLs de mídia (133 MB) estão **fora do Git** e não há instrução de como obtê-las.
- **Contra o servidor atual, funciona pouco:** login, registro do dispositivo, lista de conversas e de contatos, criar conversa e grupo, enviar e receber **texto** e o status ✓/✓✓ por WS 3. **Quebram** (doc 02, Q1–Q14): anexos nos dois sentidos, "visualizada", membros de grupo, histórico de chamadas, mensagem oculta (aparece com o conteúdo), conteúdos tipo 5–8 (bolha vazia) e **toda a mídia de chamada** (sem TURN).
- **Tempo real frágil:** o WebSocket **nunca reconecta** (#2), provavelmente **cai ~2 min depois de abrir** porque o leitor não trata o *ping* vazio do Bun (#3), usa TLS **sem validar o certificado** e depende de OpenSSL 1.0.2, que não está na máquina (#5). A sessão de 12 h vence e o app **para de atualizar em silêncio** (#4).
- **Privacidade e segurança:** **toda chamada transmite a tela inteira do usuário**, sem aviso, inclusive as de voz (#1); microfone e tela podem continuar transmitindo depois de desligar (#8); a **senha fica salva** com uma cifra cuja chave é o número de série da placa-mãe (#6); o identificador de anexo vira caminho de arquivo sem validação (#26).
- **Desktop × celular:** com o app desktop conectado, o servidor **não manda push para nenhum outro aparelho do usuário** (regra por usuário, não por aparelho). Hoje isso é mascarado porque o WebSocket do FMX cai; corrigir a reconexão sem tratar isso deixa o celular sem push sempre que o PC estiver ligado (#15; pendência S2/S17 no doc 08).
- **Dívida:** um objeto global (`Dados`) concentra cache, regras, rede e até diálogos; o domínio chama esse global; quase toda a rede roda **na thread da interface**; **0 testes**; ~11% de código morto; Skia e DCPcrypt vendorizados; 27 *stashes*; o commit mais importante (`4759ba5`, +8.486 linhas) **só existe nesta máquina**.
- **Paridade:** das 137 funcionalidades do web, **1** está íntegra no FMX, 40 parciais, 14 quebradas, 76 inexistentes e 6 precisam de adaptação (doc 05). O FMX tem, por outro lado, integrações de desktop que valem ser mantidas (bandeja, contador na barra de tarefas, barra de título com *snap*, notificação que não rouba foco).
- **Recomendação (§8):** **recomeçar o núcleo numa nova base Delphi FMX Win64 e transplantar a interface tela a tela.** Em FMX, "recomeçar" não é jogar fora o visual: frames, renderizador de mensagens, editor, notificações e integrações com o Windows (cerca de 35–40% do código próprio) são aproveitáveis. O que nasce de novo é tudo o que tem estado ou faz E/S: sessão, HTTP, tempo real, cache, envio e anexos, gerenciador de chamadas e mídia.

---

## 1. Estado do repositório

### 1.1 Branch, remoto e histórico

| Item | Valor |
|---|---|
| Remoto | `origin https://github.com/conversa-projeto/conversa-windows-fmx.git` (`origin/HEAD → origin/main`) |
| Branch atual | `chamada` → `origin/chamada`, **1 commit à frente e não enviado**: `4759ba5` (2026-04-26 22:39, "feat: Integra chamadas com WebRTC (audio + video) via MediaMTX", 37 arquivos, +8.486/−179) |
| `main` (= `origin/main`) | `e970c92` 2025-08-03, **23 commits atrás** de `chamada` (contida nela). O branch padrão do GitHub está 14 meses atrás do código real |
| Outras branches | `alteracao-base` (`a8dcfe8`, 2024-11-05; **1 commit só dela**, experimento multiplataforma Android/Windows abandonado) · `keen-buck` e `vigorous-lichterman` (`b610774`, 2025-11-02; nomes de *worktree* de ferramenta, já contidas em `chamada`) |
| Tags | `v0.0.1` (`24dffba`, 2024-09-03) e `v0.0.2` (`b3fb461`, 2024-09-19), sem relação com a versão do exe (fixa em 1.0.0.0) |
| Commits | 183 em `chamada` (2023: 8 · 2024: 134 · 2025: 25 · 2026: 16); primeiro `8e4d9fc` 2023-06-28; 7 *merges* |
| Autores | Daniel de Araujo Costa (138) e Eduardo (45). Dois commits coassinados por IA (`ebe5cb9`, `4759ba5`); cabeçalhos "Migracao automatica 2026-04-21" em `src/chamada/Conversa.Chamada.WebRTC.pas` e `src/Conversa.Proxy.Extras.pas` |
| `.git` | 93 MB com **2.795 objetos soltos** (nunca compactado). Maiores *blobs*: `bin/sk4d.dll` (2 versões de ~18,5 MB), `ImageViewerFrame.fmx` (4,7 MB), `chat.emoji.pas` |
| *Stashes* | **27** (de 2024-05 a 2026-01). Todos foram conferidos arquivo a arquivo contra o HEAD: já absorvidos ou superados; nenhum contém segredo. Detalhe em `apoio/A1-repositorio-build.md` §1.3 |

### 1.2 Alterações não commitadas

**Staged (2 arquivos, +15/−7):**

| Arquivo | O que muda |
|---|---|
| `Conversa.Dados.pas` (`TDados.IniciarMonitoramento`, `:420-450`) | O WebSocket passa de `ws://host:(8000 + porta)` (padrão do servidor Delphi, porta 9090) para **`ws(s)://host:porta/ws/`**, derivado do endereço REST (`:432-438`). Alinha com o servidor atual (`conversa/src/websocket.ts:56`). Com `https`, porém, o Indy precisa do OpenSSL 1.0.2, que não está na máquina (#5) |
| `src/chamada/Conversa.Chamada.WebRTC.pas` (`:12-29`) | Só o comentário de cabeçalho: registra que a pilha WebRTC está em `conversa-webrtc/`, que a captura é de **tela** ("webcam ainda NAO implementada") e que o evento 56 não tem tratamento |

**Não rastreados:** as 5 DLLs de mídia em `bin/` (`pion_whep.dll`, `avcodec-62.dll`, `avutil-60.dll`, `swresample-6.dll`, `swscale-9.dll`, 133 MB, **nem versionadas nem ignoradas**: um `git add .` as versionaria, e o `avcodec-62.dll` tem 97,6 MB, colado no limite de 100 MB do GitHub); `docs/todo.md` (revisão de 2026-06-27 dos docs de áudio TCP e *waveform*); e os documentos desta auditoria.

### 1.3 Lixo e artefatos

| Item | Situação | Ação |
|---|---|---|
| `bin/sk4d.dll` (19 MB, versionado) | Cópia **x86** do redistribuível do Delphi 12.1 (sem a assinatura), errada para Win64 | Tirar do Git; usar o Skia do Delphi |
| `src/chat/chat/skia/**` (31.829 linhas) | Skia4Delphi **6.2.0** vendorizado, que **sombreia** o 6.1.0 do Delphi pelo *search path*; sem o arquivo de licença; uso real só em `chat.conteudo.imagem.pas` | Remover e usar o Skia do Delphi (#89) |
| `src/visualizadormidia/ImageViewerFrame.fmx` (4,9 MB) | Carrega um PNG 1920×1200 esquecido em tempo de design, que vai para dentro do exe | Limpar o `Bitmap` no designer (#90) |
| DCPcrypt (`lib/AES/Ciphers`, `Hashes`; 25 units, 8.570 linhas mortas) | Só Rijndael + base64 são usados, para a senha salva (#6) | Remover junto com a senha salva |
| `teste/` (2.584 linhas) + `Teste.Proxy.pas` | Protótipo **VCL** de maio/2025 da refatoração "Proxy + Eventos", com cópias que divergiram do `src/`. **Não são testes** | Apagar (fica no histórico) |
| `conversa-webrtc/` | Mistura os *bindings* usados pelo app com o app de teste `TesteWebRTC`; `.gitignore` copiado de outro projeto (`LOJAS/MD006/…`) | Separar os *bindings* (ex.: `lib/webrtc/`) da bancada |
| `src/notificacao/Conversa.Notificacao.Item.pas/.fmx`, `src/chat/chat/frames/chat.anexo.fmx` (sem `.pas`) | Mortos (o primeiro nem compila) | Apagar |
| `Android64/` (211 MB), `.dcu`/`.o` espalhados (57 MB), `__history/` (37 MB), `Serializer/` (projeto sem fonte), `api/` (só `__history`), `src/chat/mensagem/` (só `__history`), `bin/bin-2/`, `bin/dcp/` | Ignorados, mas ocupam disco | Limpar |
| `bin/Conversa/` | Dados do usuário de desenvolvimento (`conversa.json` com **senha cifrada**, `anexos/`), ignorados **por acaso** (`*.json`, `anexos`) | Ignorar explicitamente; mover os dados para fora da pasta do exe |
| `bin/clipboard/` | 24 PNGs colados no chat (ignorados por `*.png`) | Idem |

O disco do repositório ocupa 876 MB (fora o `.git`); os arquivos versionados somam 29 MB.

### 1.4 `.gitignore`

- **Falta:** `*.dll` (ou `bin/*.dll`); pastas de saída explícitas (`bin/dcu/`, `bin/dcp/`, `bin/Conversa/`, `bin/clipboard/`); `Android64/`, `Win32/`, `Win64/`, `__astcache/`; `*.log` e `log.txt`; `.claude/`; `*.deployproj`; `Serializer/`.
- **Amplo demais:** `*.json` bloqueia `docs/contrato/openapi.json` e qualquer exemplo de configuração; `*.png` bloqueia imagens de interface e de documentação (é por isso que os ícones acabam embutidos em hexadecimal nos `.fmx`).

### 1.5 Segredos e endereços fixos

- **Nenhuma chave, token ou senha real em arquivo versionado**, nem nos 27 *stashes*. Os e-mails dos autores estão no histórico público e foram omitidos.
- **Senha local:** IV constante e chave derivada do serial da placa-mãe em `lib/AES/Conversa.AES.pas:30-37`, `:51-59` (#6). Em `bin/Conversa/conversa.json` (ignorado) há uma senha cifrada (não copiada).
- **Endereços:** `MediaMtxBase` padrão `http://localhost:8889` (`src/configuracoes/Conversa.Configuracoes.pas:52`, `:67`), que contorna o *proxy* `/webrtc` e não funciona fora da máquina do servidor; IP de LAN em comentário (`src/chamada/Conversa.Chamada.WebRTC.pas:66`); `C:\pion_whep.log` como *fallback* de log (`conversa-webrtc/pion/main.go:56`, `:62`); senha de exemplo `'senha123'` no app de teste (`conversa-webrtc/Inicio.view.fmx:110`, `:263`); caminhos `C:\Users\danie\...` gravados em `.fmx` como metadado de design (`Conversa.Tela.Inicial.view.fmx:2462`, `src/chat/Conversa.Chat.Listagem.fmx:2511`, `src/base/Conversa.FormularioBase.fmx:535`).
- **Licença:** o histórico público contém o fonte proprietário da Embarcadero `src/fmx/FMX.Platform.Win.pas` (adicionado em `1712a09`, 2024-05-28; removido em `428d04e`, 2024-07-26). Só uma reescrita de histórico remove de fato. Fica para decisão (#97).

---

## 2. Build e toolchain

### 2.1 `Conversa.dproj` e `Conversa.dpr`

| Item | Valor | Comentário |
|---|---|---|
| Versão do projeto | 20.1 (Delphi 12), FMX | — |
| Plataforma padrão | **Win32** (`Conversa.dproj:8`) | Incompatível com as DLLs x64 de mídia |
| Plataformas habilitadas | Android, Android64, Win32, Win64 (`:9`) | Android é resto de experimento; há permissões Android no `Base` (`:92-99`) |
| Saída | `.\bin` para **todas** as plataformas e configurações; `.dcu` em `.\bin\dcu` (`:84-85`) | Win32 e Win64 sobrescrevem o mesmo `bin\Conversa.exe`; `.dcu` misturados |
| *Search path* | 15 pastas, inclusive `src\chat\chat\skia` (`:103`) | 57 das 112 units compiladas entram **só pelo *search path***; a cópia do Skia tem prioridade sobre a do Delphi |
| *PreBuild* | `taskkill /f /t /im Conversa.exe` (`:104-106`, repetido em 8 combinações) | **Mata qualquer `Conversa.exe` da máquina** a cada build |
| Versão | `FileVersion=1.0.0.0` fixo, *locale* 1033 (en-US) (`:166-167`, `:179-180`) | O "Sobre" sempre mostra 1.0.0.0 |
| DPI | PerMonitorV2 em Debug e Release (`:209`, `:215`) | OK |
| Pacotes / componentes de terceiros | Nenhum (exe monolítico; `.fmx` só com componentes padrão) | O único código de terceiros é vendorizado ou vem com o Delphi (Indy) |
| Deploy | Só Win32 (exe e `.wav`), **nenhuma DLL** (`:401-440`) | O *Deploy* do IDE não gera pacote que funcione |
| `Conversa.dpr` | 55 units do projeto + 4 do RTL; **`MidasLib` sem uso** (`:7`; nenhum `TClientDataSet`) | Duas units chamadas `Conversa.Audio` (raiz e `src/chamada`): o `in '...'` do `.dpr` resolve hoje, mas uma remoção troca a unit sem aviso |

### 2.2 Dependências em tempo de execução

| DLL | Arquitetura | Tamanho | Origem | Versionada? | Licença | Carregamento |
|---|---|---|---|---|---|---|
| `bin/sk4d.dll` | **x86** | 19 MB | Redistribuível do Delphi 12.1 | Sim | BSD-3 + MIT | Dinâmico (`System.Skia.API.pas:4566`) |
| `pion_whep.dll` | x64 | 19,5 MB | `go build -buildmode=c-shared` de `conversa-webrtc/pion/main.go` (Go **1.26.1**, Pion **v4.0.0** de out/2024, sem `-s -w`) | **Não** | MIT + BSD | **Estático** |
| `avcodec-62`, `avutil-60`, `swresample-6`, `swscale-9` | x64 | 113,8 MB | Build ***nightly* (master) de 2026-03-31** da BtbN, linha FFmpeg 8.x (os docs citam 7.x LGPL) | **Não** | **GPLv3** (`--enable-gpl --enable-version3`, com libx264/libx265) | **Estático** |
| `libeay32.dll`, `ssleay32.dll` (OpenSSL **1.0.2**) | — | — | Exigidas pelo Indy para `wss://` | **Ausentes** (nem em `bin/`, nem no `PATH`) | OpenSSL | Dinâmico |

**Matriz plataforma × DLL:** em **Win32** (o padrão), as DLLs x64 de mídia impedem o exe de abrir (`0xc000007b`); em **Win64**, o `sk4d.dll` x86 versionado faz o Skia falhar. **Nenhum build atual carrega Skia e mídia ao mesmo tempo.** Um clone limpo não tem como montar a pasta `bin/` (nada disso está no README).

### 2.3 Resultado do build

```
cmd /c "call rsvars.bat && msbuild Conversa.dproj /t:Build /p:Config=Debug /p:Platform=Win64 /v:minimal"
→ 1,3 s · código de saída 0 (!)
  "This version of the product does not support command line compiling."
```

- `dcc32.exe` e `dcc64.exe` respondem o mesmo. Edição: **Delphi 12.1 Athens Community** (`bds.exe` 29.0.51961.7529; registro `Edition = Starter`).
- **Consequências para o trabalho:** não há como compilar nem rodar testes DUnitX por linha de comando nesta máquina, nem montar CI com `msbuild`, sem uma licença **Professional ou superior**. A licença Community também restringe o uso comercial (decisão do responsável pelo projeto, fora do escopo técnico).
- Evidência indireta de compilação: `bin/Conversa.exe` x86 e 112 `.dcu` de 2026-06-27 20:56 (depois das alterações *staged*, de 20:50–20:51) → a árvore atual compilou em **Win32 Debug** no IDE; `bin/Conversa.rsm` de 2026-04-26 22:37 → o HEAD compilou em **Win64 Debug**.
- Não tentado: `bds.exe -b` (build em lote pelo IDE), porque abre a interface e pode regravar o `.dproj` versionado. Fica como item a verificar (TODO 0.3).

---

## 3. Arquitetura atual

### 3.1 Módulos

```
conversa-windows-fmx/                               linhas próprias
├── Conversa.dpr + raiz (Dados, Memoria, Login,      2.386   TDados (global), TDadosApp, login, tela inicial, WMI,
│   Tela.Inicial, WMI, Log, Audio, Inicializacoes,           log, som de mensagem, REST.API (cliente HTTP genérico)
│   REST.API, Teste.Proxy)
├── src/                                            14.505   (+5.128 da tabela de emoji)
│   ├── Conversa.Tipos / Proxy / Proxy.Tipos /       ~3.100   domínio (classes mutáveis), proxy REST (records estáticos),
│   │   Proxy.Extras / Eventos / Evento.Base /               DTOs, Proxy.Extras (533, MORTO), eventos, serializer
│   │   Serializer / Loading
│   ├── base/          FormularioBase, FrameBase       574   form com barra de título própria (WndProc), frame base
│   ├── chat/          lista, chat, chat/* (frames)  ~4.900   lista de conversas, chat, renderizador, editor, emoji
│   ├── chamada/       16 units                      ~2.700   chamada (estado+REST+UI), WebRTC, histórico, waveform
│   ├── notificacao/   gerenciador + itens           ~1.200   notificações próprias (janela no canto da tela)
│   ├── pss/           PascalStyleScript               789   motor de temas DESLIGADO
│   └── configuracoes, conexao, contatos, novo/grupo,  ~1.100
│       principal, sobre, visualizadormidia
├── lib/                                             3.999   bird-socket-client (WebSocket sobre Indy), popupmenu,
│                                                            audio (TCP legado), tcp.pas (MORTO), windows, AES
├── conversa-webrtc/                                 2.300   bindings Pion/FFmpeg, encoders/decoders, captura;
│                                                            Inicio.view/Whip.view = bancada de teste
├── teste/                                           2.572   protótipo VCL (não são testes)
└── src/chat/chat/skia/                             31.829   Skia4Delphi 6.2.0 vendorizado
```

### 3.2 Como os módulos se ligam

```
 Conversa.dpr ─► Iniciar ─► DefinirDiretorio (CWD = pasta do exe) ─► TConfiguracoes.Load (conversa.json: Host, Usuario,
 │                          Senha cifrada, MediaMtxBase, DispositivoId) ─► TPascalStyleScript.Start (inerte)
 │                          ─► AtualizarContadorNotificacao ─► UserActivity (poll de 100 ms)
 └─► TTelaInicial (form principal, bandeja, WndProc próprio) ── cria ──► Dados := TDados   (GLOBAL)
        │                                                                 └─ TDadosApp: Usuarios/Conversas/Mensagens
        ├─ TConfigurarConexao / TConexaoFalhaInicio (ServerOnline = sempre True)        ▲ Conversa.Tipos chama Dados
        ├─ TLogin ── Decrypt(Senha) [WMI] ─► Dados.Login ─► TAPIConversa.Login  (REST SÍNCRONO na UI)
        └─ TPrincipalView ─► TChatListagem (GLOBAL Chats) ─► TChat ─► chat.visualizador / chat.editor
                │   UI chama direto ─► Dados.* ─► TAPIConversa (records estáticos)
                │        a) síncrono na thread da UI (login, contatos, envio, anexo, mensagens/novas, chamada)
                │        b) TThread.CreateAnonymousThread ─► TEventBase.Send ─► ForceQueue ─► handler na UI
                │   TMessageManager.DefaultManager ◄── setters do domínio (contadores, lista, mensagem) ─► UI
        TBirdSocketClient (Indy + OpenSSL 1.0, wss SEM verificação, sem reconexão)
             leitor TTask ─► TThread.Queue ─► Dados.NotificacaoSocket (UI)
                   ├─ 51–55 ─► TConversaChamadas ─► TConversaChamada (REST síncrono + forms + toast)
                   │                └─ TConversaWebRTC (singleton) ─► pion_whep.dll (Go/cgo) + FFmpeg
                   │                     TScreenCapture (TELA INTEIRA, sempre) + TMicCapture (waveIn)
                   ├─ 2  ─► GET mensagens/novas (SÍNCRONO) ─► GET mensagens por conversa (threads)
                   ├─ 3  ─► GET mensagem/status (thread)       ├─ 40 ─► GET conversas (thread)
                   └─ 0  ─► raise Exception (diálogo de erro)    (4, 5, 7, 9, 56, 57, 60, 61, 62 ignorados)
```

### 3.3 Camadas, estado e threads

- **Não há camadas.** A UI chama `Dados.*` e `TAPIConversa.*` direto (ex.: `src/novo/grupo/Novo.Grupo.pas:76` e `src/contatos/Conversa.Contatos.pas:55` fazem REST síncrono num `TTimer`). O "serviço" `TDados` mistura cache, regras, E/S e **UI** (abre `TSaveDialog`, `Conversa.Dados.pas:376-392`). O domínio (`src/Conversa.Tipos.pas`) tem *setters* que **disparam eventos de tela** (`:912-917`) e **usa o global `Dados`** (`:579`, `:861`, `:894`): dependência circular domínio ↔ serviço. O proxy REST é um *record* com `class var`s (não injetável) que lê **e grava** a configuração global (`src/Conversa.Proxy.pas:114`, `:186-193`).
- **Globais e *singletons*:** `Dados`, `Configuracoes`/`PastaDados`, `Chats`, `TelaInicial`, `TConversaChamadas`, `TConversaWebRTC` (uma instância para todas as chamadas), `TNotificacaoManager`, `TPascalStyleScript`, o token JWT em **três cópias** (`Conversa.Proxy.pas:98`, `Conversa.Proxy.Extras.pas:153` — nunca preenchida —, `Conversa.Dados.pas:41`).
- **Dois barramentos de eventos:** `TEventBase<T,T2>` (`src/Conversa.Evento.Base.pas`), que entrega na thread principal por `ForceQueue` — **a melhor ideia de concorrência do código** —, e `TMessageManager.DefaultManager` para invalidações de UI. Eventos declarados e nunca usados: digitando, gravando, status de usuário, conversa atualizada, vídeo ativado, reação. **`TErroServidor` é enviado e ninguém assina** (erros silenciados, #25); **`TEventoStatusConexao` é assinado e ninguém envia** (a faixa de conexão nunca aparece, #2).
- **Threads:** quase toda a E/S roda **na thread principal** (login, contatos, criar conversa, envio de mensagem com leitura do arquivo inteiro e SHA-256, download de cada imagem e áudio, `GET mensagens/novas` a cada WS 2, `GET chamada/dados` a cada evento 51–55, `Connect` do WebSocket sem *timeout* de leitura). As partes concorrentes de verdade (WebRTC: *callbacks* da DLL Go, `waveIn`, captura de tela) têm corridas e *use-after-free* (#7, #8). **Não foi encontrado acesso a componente visual fora da thread principal**; o problema é o inverso (UI congelada, #24).
- **Memória:** tudo é classe com `Free` manual; **6 `FreeAndNil(Self)`** dentro de eventos do próprio objeto; posse implícita de *streams* (`REST.API.pas:543-554` libera o *stream* do chamador); assinaturas de eventos nunca canceladas; `ReportMemoryLeaksOnShutdown := True` também em Release (#68).
- **Erros:** `ValidarErro` (`src/Conversa.Proxy.pas:154-167`) envia `TErroServidor` e chama `Abort` → silêncio. Exceções de threads anônimas morrem com a thread. 7 `try … except end` vazios. Validações de formulário feitas por exceção, com o diálogo padrão do FMX e textos técnicos.
- **Logs:** `Conversa.Log.Pas` grava `log.txt` **truncado a cada execução**, sem trava entre threads, usado só pela mudança de estado do WebRTC (a partir de threads Go). Não registra nada sensível, mas também nada útil.

---

## 4. Inventário de telas

| Tela | Arquivos | O que faz hoje | Situação contra o servidor atual |
|---|---|---|---|
| Configurar conexão | `src/configuracoes/Conversa.Configurar.Conexao.*` | Pede o "Host" (com `/api/`) **só na primeira execução**; "Cancelar" sem ação | Funciona se o host for `https://<host>/api/` e a CA do mkcert estiver instalada; sem teste de conexão; não dá para mudar depois (só editando o `conversa.json`) |
| Falha de conexão ao iniciar | `src/conexao/Conversa.Conexao.AvisoInicioSistema.*` | Nunca aparece (`ServerOnline` devolve sempre `True`, `Conversa.Dados.pas:324-339`) | Morta |
| Login | `Conversa.Login.*` | "Login"/"Senha"/"Entrar"; **salva a senha** e entra sozinho na próxima vez; síncrono na UI | `POST /login` ✅; erro como diálogo de exceção (inclusive o HTML do 503 do nginx); sem cadastro |
| Tela inicial (form principal) | `Conversa.Tela.Inicial.view.*`, `src/base/Conversa.FormularioBase.*` | Barra de título própria com *Snap Layouts*, ícone na bandeja, contador na barra de tarefas, zoom com Ctrl+roda, faixa "Falha na conexão" (morta) | X esconde (Release) e não há "Sair"; ícone da bandeja sem menu |
| Principal (barra lateral) | `src/principal/*` | Contatos, Novo Grupo, Chamadas, Sobre; círculo com a inicial (sem ação) | Sem Atividades, Configurações, perfil, logout |
| Lista de conversas | `src/chat/Conversa.Chat.Listagem*` | Inicial, nome, prévia, data/hora, contador, negrito; notificação e som | Arquivadas/fixadas ignoradas; prévia crua (às vezes mostra o caminho local do arquivo); contador preso (visualizar 404) |
| Chat | `src/chat/Conversa.Chat.*`, `src/chat/chat/**` | Cabeçalho (nome; botão "Iniciar Chamada"), bolhas (texto, imagem, arquivo, "mensagem de áudio"), separador de data, botão "ir para o fim", editor (Enter envia, Shift+Enter quebra, fila de anexos, colar imagem, gravar segurando, painel de emoji do Windows), menu "Copiar" | Texto ✅; anexos ✗ (Q1/Q2); oculta mostra conteúdo; tipos 5–8 vazios; `GET /conversa/dados` 404 ao abrir; paginação frágil |
| Visualizador de mídia | `src/visualizadormidia/*` | Uma imagem, zoom pela roda, duplo clique 100%, Esc | Só abre imagens enviadas pelo próprio usuário (download quebrado) |
| Contatos (modal) | `src/contatos/*` | Lista todos os usuários (**inclusive o próprio**) e abre/cria a conversa direta | `GET /usuario/contatos` ✅ |
| Novo grupo | `src/novo/grupo/*` | Nome + seleção (exige **2** contatos; lista o próprio usuário) | Cria ✅; erro do servidor engolido; não abre o grupo |
| Histórico de chamadas | `src/chamada/Conversa.Chamada.Listagem*`, `Detalhe` | Lista e detalhe | Modelo inexistente no servidor → itens vazios (Q5) |
| Janela de chamada | `src/chamada/Conversa.Chamada.view*`, `Usuario.view`, `Usuarios.Listagem*`, `BarraTitulo` | Form 300×480, microfone, "vídeo" (liga/desliga a **captura de tela**), encerrar; indicador com cronômetro na barra de título | Sem mídia (Q11); vídeo remoto invisível; "encerrar" da barra de título não faz nada |
| Notificações | `src/notificacao/*` | Janela própria no canto inferior direito, sem roubar foco, agrupada por conversa, pausa com o usuário ausente; notificação de chamada com Atender/Recusar | Sem toque; "×" recusa a chamada; *use-after-free* no clique (#7) |
| Sobre | `src/sobre/*` | Nome, versão (1.0.0.0 fixo) e "Build" (data do arquivo) | — |

Detalhe por funcionalidade (IDs do web) no **doc 05**.

---

## 5. Inventário técnico do contrato usado

Detalhe completo, com evidência dos dois lados, no **doc 02**. Resumo:

- **REST:** `TNetHTTPClient` (WinHTTP/SChannel), um por requisição, sem *timeout* explícito; URL base inteira em `Configuracoes.Host` (inclui `/api`); `Authorization: Bearer` por `TAuthBearer`; erro lido de `{error}`; **TLS validado pelo repositório do Windows** (sem *callback* que aceite tudo ✅); nada sensível em log ✅. O FMX usa de fato ~23 rotas: `POST /login`, `PATCH /dispositivo` (manda o `id` ✅), `GET /usuario/contatos`, `PUT /conversa`, `PUT /conversa/usuario`, `GET /conversas`, `GET /conversa/dados` (🔴 não existe), `GET /mensagens`, `PUT /mensagem`, `GET /mensagens/novas` (🟠 `ultima` × `desde`), `GET /mensagem/status`, `GET /mensagem/visualizar` (🔴 é `POST`), `GET /anexo/existe`, `GET /anexo` (🔴 devolve `{url}`), `PUT /anexo` (🔴 contrato antigo), `PUT /chamada/iniciar`, `POST /chamada/cancelar|recusar|entrar|sair|finalizar`, `GET /chamada/dados`, `GET /chamadas` (🔴 modelo). Outras ~20 rotas existem só em **código morto** (`src/Conversa.Proxy.Extras.pas` e métodos sem chamador).
- **WebSocket:** `TBirdSocketClient` (cópia local do *bird-socket-client*, sobre Indy 10), frames montados e lidos à mão. Trata os tipos 0, 2, 3, 40 e 51–55; ignora 4, 5, 7, 56, 57, 60, 61 e 62. Envia só `{tipo:1, token}` uma vez.
- **Mídia de chamada:** WHIP/WHEP pela `pion_whep.dll` em `<MediaMtxBase>/call-<chamada>-u-<usuario>/whip|whep` (o nome do caminho está certo; a base, não); H264 (libx264) + Opus; **sem servidor ICE** (nem STUN nem TURN).
- **Anexos:** SHA-256 de verdade (compatível com o web) e `GET /anexo/existe` ✅; upload e download no contrato **anterior ao MinIO**.
- **Serialização:** `TJsonSerializer` com conversor de datas que trata o ISO-8601 com `Z` e converte para o fuso local ✅; campos novos são ignorados sem quebrar o *parse* (mas também não são lidos: `excluida_em`, `fixada_ordem`, `arquivada_em`, `reacoes`, `mensagem_referencia`…).

---

## 6. Problemas encontrados

Formato: **#n [SEVERIDADE] Título.** Local, o que acontece, efeito e correção. Críticos e altos em detalhe; médios e baixos em tabela. A coluna "Origem" das tabelas e as notas "(A3-01, P3…)" apontam o item correspondente nos relatórios de apoio (`apoio/`), onde está a evidência completa.

Total: **103 problemas** — 16 CRÍTICOS, 24 ALTOS, 34 MÉDIOS, 29 BAIXOS.

### CRÍTICO

**#1 [CRÍTICO] Toda chamada transmite a tela inteira do usuário, sem aviso.** (A4-01, P1)
- **Local:** `src/chamada/Conversa.Chamada.pas:502` (`PublicarLocalNaSala(ChamadaId, MeuId, True, True)`, chamado ao iniciar em `:469` e ao atender em `:300`); `src/chamada/Conversa.Chamada.WebRTC.pas:203-221` (`TScreenCapture.Create` + `Start(30)`); `conversa-webrtc/Screen.Capture.pas:259-326` (`BitBlt` do monitor principal inteiro); `src/chamada/Conversa.Chamada.view.pas:149-150` (o ícone de vídeo começa como "indisponível").
- **O que acontece:** ao iniciar ou atender qualquer chamada, inclusive de voz e antes de alguém atender, o app captura o monitor principal e publica em H264 1280×720. O botão de vídeo só liga e desliga o que já está ligado.
- **Efeito:** tudo o que está na tela (e-mails, documentos, senhas exibidas) vai para os participantes e é **gravado no servidor** (o MediaMTX grava os caminhos `call-*`, `conversa/bin/mediamtx/mediamtx.docker.yml:32-37`, por 90 dias por padrão), num caminho previsível e sem autenticação (#34). É um problema de LGPD. Hoje só não vaza porque a mídia não chega ao servidor (#12).
- **Correção:** vídeo **desligado por padrão**; câmera só em chamada de vídeo; tela só por ação explícita, com escolha de monitor ou janela, indicador permanente e anúncio pelo WS 57. No app atual, enquanto ele existir: `EnviarVideo = False`.

**#2 [CRÍTICO] O WebSocket nunca reconecta; não há detecção de queda, ressincronização nem modo degradado.** (A3-01, A5a-02, A5a-11, P3)
- **Local:** `Conversa.Dados.pas:420-451` (conecta uma vez; `if Assigned(FBirdSocket) then Exit`; só o ouvinte `MESSAGE`); `lib/bird-socket-client/Bird.Socket.Client.pas:306` (`FAutoReconnect := False`); `Conversa.Tela.Inicial.view.pas:94`, `:274-277` (a faixa "Falha na conexão com o servidor!" é assinada e ninguém a dispara); `Conversa.Dados.pas:324-339` (`ServerOnline` fixo em `True`).
- **O que acontece:** qualquer queda (Wi-Fi, troca de rede, suspensão do PC, API reiniciada, 502 do nginx, #3) fecha o socket. Ninguém percebe, nada reabre, não há *polling* nem aviso.
- **Efeito:** o app continua na bandeja, com aparência normal, **sem receber mensagens nem chamadas** até ser reiniciado. É a falha mais grave de uso diário num mensageiro de bandeja.
- **Correção:** cliente de tempo real com máquina de estados (desconectado → conectando → autenticando → conectado → aguardando), **geração** por conexão, *backoff* `min(30 s, 1 s × 2^n)` com *jitter*, `{tipo:1}` a cada abertura, ressincronização (doc 01 §6.7), *polling* de 8 s com o socket fora, faixa após 5 s com o texto do web e reação a `WM_POWERBROADCAST`. **Não** ligar o `AutoReconnect` do Bird: o monitor faz `Connect` na thread da UI via `Synchronize` e pode travar (*deadlock*, `Bird.Socket.Client.ConnectionMonitor.pas:92-96` × `Bird.Socket.Client.pas:342-346`), além de não reenviar o login. Tratar junto com #15.

**#3 [CRÍTICO, provável] O leitor de frames do Bird não trata quadros de controle sem carga: o *ping* do servidor derruba a conexão em ~2 min.** (A3-02, A7 §4.4; não confirmado em execução)
- **Local:** `lib/bird-socket-client/Bird.Socket.Client.pas:567-580` (com `LSize = 0`, `LPosition := 0` e depois o `Inc(LPosition)` incondicional deixa o frame "aberto"), `:583-599` (o PONG só é enviado com bytes no *spool*); servidor sem opções de WebSocket (`conversa/src/websocket.ts:56`), ou seja, valem os padrões do Bun (pela documentação: `idleTimeout` 120 s e *pings* automáticos de carga vazia).
- **O que acontece:** o FMX não envia nada depois do login. Após ~120 s, o servidor manda um *ping* vazio. O Bird não responde e passa a ler o primeiro byte do frame seguinte como tamanho, o que **desalinha o fluxo**. O servidor fecha por falta de resposta.
- **Efeito:** o tempo real provavelmente morre cerca de 2 minutos depois de abrir o app; um evento que chegue nesse intervalo vem corrompido. Junto com #2, o app fica sem tempo real quase o tempo todo — o que, ironicamente, mascara o #15.
- **Correção:** trocar o cliente WebSocket (#5). **Teste para confirmar:** abrir o app, ficar 3 min sem mexer e mandar uma mensagem pelo web; ou observar a bolinha "online" do usuário apagar no web ~2 min depois do login.

**#4 [CRÍTICO] Sessão de 12 h sem renovação; 401 ignorado em todo o app.** (A3-04, A5a-01, P10)
- **Local:** `src/Conversa.Proxy.pas:121-135`, `:154-167`; `Conversa.Dados.pas:191-192`, `:500-501`, `:561-562` (`if Status <> Sucess then Exit`); `REST.API.pas:712-726` (`TAuthBearer.Get` lança `'Token vencido!'` **antes** de enviar); `Conversa.Dados.pas:486-489` (WS tipo 0 "Token inválido ou expirado" vira exceção); servidor `conversa/src/autenticacao.ts:6` (`exp: '12h'`, sem *refresh*).
- **O que acontece:** depois de 12 h, toda rota responde 401, e o app trata como "sem dados", em silêncio nas threads e com diálogo nas chamadas síncronas. O socket, se vivo, continua autenticado (o servidor não revalida).
- **Efeito:** num app de bandeja sem "Sair", isso acontece **todo dia**. Mensagens e chamadas param de carregar sem aviso; o usuário segue "online" e com o push suprimido (#15).
- **Correção:** tratamento global de 401 e do evento WS 0 como "sessão expirada" → tela de login (ou relogin silencioso, se houver credencial guardada com DPAPI — decisão no ADR); fechar e reabrir o socket com o token novo; guardar o `exp` e avisar antes de vencer; pedir *refresh token* ao servidor (S13).

**#5 [CRÍTICO] WebSocket com TLS sem validar certificado nem host, aceitando TLS 1.0/1.1, transportando o JWT; o OpenSSL 1.0.2 não vem com o app.** (A3-06, A3-07, A5a-08, P2)
- **Local:** `lib/bird-socket-client/Bird.Socket.Client.pas:263-272` (`TIdSSLIOHandlerSocketOpenSSL` sem `VerifyMode`/`OnVerifyPeer`/`RootCertFile`; `SSLVersions` com TLS 1.0, 1.1 e 1.2); Indy do Delphi 12 carrega `libeay32.dll`/`ssleay32.dll` (OpenSSL 1.0.x); nenhuma das duas em `bin/` nem no `PATH` desta máquina; `Conversa.Dados.pas:442-450` (o token vai no primeiro quadro).
- **O que acontece:** sem as DLLs, o `Connect` falha com "Could not load SSL library", a exceção interrompe o fluxo de login e o app segue **sem tempo real** (o REST funciona, o que confunde o diagnóstico). Com as DLLs, **qualquer certificado é aceito** e elas são procuradas pelo `PATH` (*DLL planting*). O OpenSSL 1.0.2 está sem suporte desde 2019.
- **Efeito:** quem estiver no meio da rede (Wi-Fi público, *proxy*) captura o JWT e tem acesso à API por até 12 h; ou o app fica sem tempo real. Contraste: o REST (WinHTTP) valida certo, o que dá falsa sensação de segurança.
- **Correção:** WebSocket do **WinHTTP** (`WinHttpWebSocketCompleteUpgrade/Send/Receive`: SChannel, validação e *proxy* do Windows, nenhuma DLL extra), ou biblioteca mantida com OpenSSL 3 empacotado e verificação de cadeia e de host. Só TLS 1.2+.

**#6 [CRÍTICO] Senha salva com cifra reversível ligada ao serial da placa-mãe, e login automático.** (A3-11, A5a-07, P6, A1 §3)
- **Local:** `Conversa.Login.pas:68-73` (decifra e entra sozinho), `:80-83` (cifra e salva sempre, sem opção "lembrar"); `lib/AES/Conversa.AES.pas:30-37`, `:51-59` (AES-256-CBC com **IV fixo**; chave = serial da placa-mãe pelo WMI + *salt* GUID **gravado junto** do texto cifrado); `Conversa.WMI.pas:79-105`; `src/configuracoes/Conversa.Configuracoes.pas:41-47` (`conversa.json` na pasta do exe, se existir, senão em `%APPDATA%` *Roaming*).
- **O que acontece:** qualquer processo do usuário lê o serial pelo WMI sem privilégio; em VMs e placas genéricas o serial é vazio ou "Default string", e a chave vira praticamente o *salt* que está no arquivo. No modo "portátil", **todos os usuários do Windows compartilham o mesmo `conversa.json`**. Se o WMI falhar, `OleCheck` lança e **nem o login manual funciona**. Se o hardware mudar, o *unpadding* sem validação gera lixo, o login automático falha com 4xx e a senha salva é apagada.
- **Efeito:** a senha (geralmente reaproveitada em outros serviços) é recuperável por quem tiver o arquivo; um usuário do PC entra na conta do outro.
- **Correção:** **não guardar a senha.** Guardar só o token com DPAPI (`CryptProtectData`, escopo do usuário) ou no Gerenciador de Credenciais; pedir a senha no 401 (ou guardar a credencial com DPAPI se o ADR decidir pelo relogin silencioso, enquanto o servidor não tiver *refresh token*). Remover WMI, DCPcrypt e `Conversa.AES`. Configuração em `%LOCALAPPDATA%`, por usuário.

**#7 [CRÍTICO] O ciclo de vida da chamada e das notificações usa objetos já liberados.** (A3-10, A4-06, P4)
- **Local:** `src/chamada/Conversa.Chamada.pas:472-483` (`FinalizarLocalmente` termina em `FreeAndNil(Self)`; os chamadores continuam usando o objeto: `:326-332` lê `FID` depois; `:349-354`, `:399-405`); `:199-216` (`FinalizarTodas` remove do dicionário **durante a iteração** e ainda dá `Free` de novo: *double free*, tudo dentro de `try … except end`); `src/notificacao/Conversa.Notificacao.Item.Chamada.pas:95-114` (Atender/Recusar/× liberam o próprio *frame* no clique e depois chamam `Fechar`); `src/notificacao/Conversa.Notificacao.Item.Mensagem.pas:202-205`, `:212-217` (o fechamento automático libera o *frame* dentro do `OnFinish` da animação que é filha dele; o clique lê `FChatId` depois de liberar); `src/notificacao/Conversa.Notificacao.pas:175-187`.
- **Efeito:** *access violations* intermitentes ao atender pelo toast, ao encerrar ou ser recusado, corrupção de *heap* e exceção ao fechar o app com chamada ativa. A janela de chamada já contorna o problema com thread + `Sleep(100)` + `Synchronize` (`src/chamada/Conversa.Chamada.view.pas:122-141`).
- **Correção:** um **gerenciador de chamadas** único, dono das chamadas e da UI delas; liberação adiada (`TThread.ForceQueue(nil, …Free)`); toasts fechados pelo gerenciador depois que o *handler* retorna; nunca `FreeAndNil(Self)`; iterar sobre cópia.

**#8 [CRÍTICO] Microfone e tela podem continuar transmitindo depois que a chamada acaba; corridas no pipeline de mídia.** (A4-05, P5, P15)
- **Local:** `src/chamada/Conversa.Chamada.pas:485-505` (publicação numa thread anônima sem referência guardada); `src/chamada/Conversa.Chamada.WebRTC.pas:169-244` (`WhipConnect` bloqueia na negociação e só **depois** cria encoders e capturas, sem checar cancelamento), `:351-388` (`Desligar` sem trava nem espera), `:413-447` (os *callbacks* da DLL pegam o *peer* sob trava e usam fora dela enquanto `DesconectarPeer` libera), `:246-335` (a assinatura registra o *peer* **depois** do `Desligar`); `conversa-webrtc/Mic.Capture.pas:267-287` (encoder e rede dentro do *callback* do `waveIn`); estado único (`FChamadaId`, `FTxHandle`) para todas as chamadas.
- **O que acontece:** se a chamada termina enquanto o `WhipConnect` ainda negocia, o `Desligar` roda primeiro; quando o `WhipConnect` volta, a thread liga microfone e captura de tela. Uma segunda chamada sobrescreve o estado da primeira. Exceções Delphi nos *callbacks* `cdecl` atravessam o cgo e **derrubam o processo**.
- **Efeito:** microfone e tela publicados sem chamada na tela (violação de privacidade silenciosa); WHEP "zumbi" tocando áudio; *access violations*.
- **Correção:** sessão de mídia por chamada com id de geração e cancelamento; `Desligar` cancela, espera as threads e descarta resultados antigos; *peers* com contagem de referência; `try/except` em todo *callback* exportado; indicador de microfone e tela ligado ao estado real.

**#9 [CRÍTICO] Download de anexos grava o JSON `{url}` como se fosse o arquivo; uma imagem recebida interrompe a renderização do lote; o cache fica envenenado.** (A5b-02, A2 Q1, P11)
- **Local:** `src/Conversa.Proxy.pas:762-786` (`Result.Dados := Response.ToStream.Bytes`, `:779`); `Conversa.Dados.pas:229-241` (grava em `PastaDados\anexos\<identificador>`, **também em erro**, e nunca revalida por causa do `TFile.Exists`), `:599-604` (download **síncrono na UI** de cada imagem e áudio); `src/chat/chat/frames/chat.conteudo.imagem.pas:73-74` (`LoadFromFile` lança); `src/chat/Conversa.Chat.pas:231-238` (a exceção interrompe o lote); servidor `conversa/src/anexos.ts:41-56` (devolve `{url}` assinada desde `f28ff10`, março de 2026).
- **Efeito:** imagens recebidas nunca aparecem e **as mensagens mais antigas que a imagem somem do lote**; áudios não tocam; "Salvar" entrega um "PDF" que é um JSON. Mesmo depois de corrigir o contrato, o cache antigo continua errado.
- **Correção:** download em duas etapas (`GET /anexo` → URL assinada → baixar **sem** `Authorization`), assíncrono, para arquivo temporário, validado (tamanho/assinatura) e renomeado; cache por identificador **validado** (#26); `try/except` por mensagem com marcador de erro; limpar o cache antigo na migração.

**#10 [CRÍTICO] Upload de anexos no contrato antigo: bytes em `PUT /anexo`, `tipo` 0, sem MinIO nem `confirmar`; a mensagem chega vazia aos outros.** (A5b-03, A2 Q2, P11)
- **Local:** `src/Conversa.Proxy.pas:788-814` (corpo `application/octet-stream`, `tipo`/`nome`/`extensao` na *query*); `Conversa.Dados.pas:265-283` (arquivo inteiro num `TStringStream`; `Anexo.Incluir(0, …)` com **`tipo` 0**, `:280`; o upload sai numa **thread solta** e o `PUT /mensagem` sai logo depois, `:286-287`); servidor `conversa/src/esquemas.ts:74` + `conversa/src/anexos.ts:58-81` (exige JSON `{identificador, tipo, nome, extensao, tamanho}`) e `client_max_body_size 1m` no nginx.
- **Efeito:** ≤ 1 MiB → 400 de validação; > 1 MiB → 413 em HTML; o erro é engolido. A mensagem sai com um identificador órfão: os outros **veem a mensagem vazia** (conteúdo sem registro de anexo é omitido, doc 01 §19.19); o remetente vê a imagem local e acha que funcionou.
- **Correção:** fila de envio persistente: mensagem otimista → `PUT /anexo` (JSON) → `PUT` em *streaming* na URL assinada (em até 300 s, sem `Authorization`) → `POST /anexo/confirmar?identificador=` → só então `PUT /mensagem`; tipos certos (2/3/4/5); cancelar a mensagem inteira se um upload falhar (como o web).

**#11 [CRÍTICO] Mensagem recebida de novo reanexa os conteúdos e lança "Mensagem já adicionada!".** (A5b-01, A3-09, P16)
- **Local:** `Conversa.Dados.pas:566-568` (`ObjConversa` pode ser `nil`), `:570-607` (a mensagem existente recebe `conteudos.Add` de novo e é readicionada); `src/Conversa.Tipos.pas:618-627` (`raise 'Mensagem já adicionada!'`); `src/chat/chat/chat.visualizador.pas:112-114` (o topo da rolagem dispara várias vezes).
- **O que acontece:** dois WS 2 seguidos (ou o **mesmo** WS 2 duplicado, porque o servidor manda um por aparelho com `token_fcm` do destinatário — doc 01 §19.29), o topo da rolagem disparando de novo ou agendadas do autor fazem duas buscas da mesma faixa.
- **Efeito:** diálogo de erro técnico; o resto do lote é abandonado; bolhas com conteúdo repetido.
- **Correção:** *upsert* idempotente por id (atualizar status, `excluida_em`, reações; nunca reanexar conteúdos); uma busca em andamento por conversa e direção (com "busca pendente" coalescida); cursor de sincronização único.

**#12 [CRÍTICO] Chamadas sem mídia contra o servidor atual: sem TURN, base errada, ICE só *host*.** (A4-02, P13)
- **Local:** `conversa-webrtc/pion/main.go:169`, `:353` (`ICEServers: []`); `src/configuracoes/Conversa.Configuracoes.pas:51-52`, `:66-67` (`MediaMtxBase` padrão `http://localhost:8889`, sem tela para mudar); `src/chamada/Conversa.Chamada.WebRTC.pas:180`, `:262`; o FMX não chama `GET /api/ice`. Servidor: o MediaMTX só escuta em `127.0.0.1:8889` (`conversa/docker-compose.yml:123-124`) e anuncia só o IP do container (`conversa/bin/mediamtx/mediamtx.docker.yml:20-24`); o coturn aceita só TCP (`conversa/bin/coturn/turnserver.conf`).
- **Efeito:** o ICE falha e as chamadas ficam **mudas**, em silêncio (o estado 3 só vai para o log). Também: o SDP trafega em HTTP; `http.Client{}` sem *timeout* e *gathering* sem limite prendem threads para sempre (`main.go:245`, `:268`, `:440`, `:457`).
- **Correção:** base `https://<host>/webrtc`, derivada do mesmo endereço da API; `GET /api/ice` a cada conexão com `iceTransportPolicy` (relay); *gathering* ≤ 5 s; *timeout* HTTP. Na pilha atual, isso exige uma função nova na DLL (`WhipConnectEx` com a configuração ICE). A escolha da pilha de mídia é do ADR 0002 (doc 07 §6).

**#13 [CRÍTICO] Áudio recebido inutilizável.** (A4-03)
- **Local:** `conversa-webrtc/pion/main.go:684-711` (`track.Read` entrega o **pacote RTP com cabeçalho**, embora `pion/DOC_API.md:175-176` prometa "sem cabeçalho"); `conversa-webrtc/Audio.Player.pas:52`, `:144-178` (a saída do decodificador Opus nativo, FLTP, é lida como S16 intercalado pelo *offset* fixo 112).
- **Efeito:** ruído ou silêncio do outro lado, mesmo depois de corrigir o ICE.
- **Correção:** entregar só o *payload* (`ReadRTP` → `pkt.Payload`, com sequência e *timestamp* para um *jitter buffer*); converter FLTP → S16 (`swr_convert`); *jitter buffer* + PLC. Ou trocar a pilha (ADR 0002).

**#14 [CRÍTICO, provável] O áudio enviado provavelmente nunca sai.** (A4-04; não confirmado sem executar)
- **Local:** `conversa-webrtc/Audio.Encoder.pas:67-83`, `:186-197`; build do FFmpeg com `--enable-libopus`.
- **O que acontece:** `avcodec_find_encoder` pula o Opus nativo (experimental) e pega o `libopus`, que **não aceita `fltp`** → `avcodec_open2` falha numa thread, em silêncio. Mesmo aberto, o `AVFrame` vai sem `ch_layout` e sem *buffer* referenciado → `avcodec_send_frame` falha.
- **Efeito:** os outros não ouvem quem está no FMX.
- **Correção:** `libopus` com S16 intercalado e `ch_layout` via `av_opt_set`, quadro alocado com `av_frame_get_buffer`; ou a `opus.dll` direta; ou trocar a pilha. Teste de bancada: publicar e conferir a trilha na gravação do MediaMTX.

**#15 [CRÍTICO] Desktop conectado suprime o push de todos os aparelhos do usuário.** (A3-03, A7 §4; a correção é no servidor + medidas no cliente)
- **Local:** servidor `conversa/src/notificacoes.ts:71` (`token_fcm && !arquivada && !usuarioConectado(usuario_id)`) e `conversa/src/websocket.ts:131-133` (`usuarioConectado` = qualquer conexão do **usuário**, de qualquer aparelho); o login do WS não informa o dispositivo; o token vencido não remove a conexão.
- **O que acontece:** enquanto o FMX estiver com o socket aberto (inclusive minimizado na bandeja, com a tela bloqueada, de noite no escritório e mesmo com o JWT vencido), **o celular e o web em segundo plano do mesmo usuário não recebem push de mensagem nenhuma**. O usuário aparece online 24 h. O temporizador de 30 s do desktop recusa a chamada **por todos os aparelhos**.
- **Efeito:** hoje é mascarado pelo #2/#3 (o socket do FMX cai e não volta). **Corrigir a reconexão sem tratar isto piora a experiência no celular.**
- **Correção:** no servidor, rastrear conexões **por dispositivo** e suprimir o push só no aparelho conectado (S2.2), e/ou um sinal de "ausente" vindo do desktop (S18). No cliente, enquanto o servidor não muda: fechar o socket ao bloquear a sessão (`WTS_SESSION_LOCK`), ao suspender (`PBT_APMSUSPEND`) e depois de N minutos ocioso (`GetLastInputInfo`), mantendo *polling* REST nesse período e reabrindo ao voltar. Decisão no ADR 0001.

**#16 [CRÍTICO] Build não reprodutível: exe Win32 com DLLs x64 de *import* estático, `sk4d.dll` x86, DLLs fora do Git e Delphi sem compilação por linha de comando.** (A1 §5–§6, A5a-09, A4-13, P14)
- **Local:** `Conversa.dproj:8` (padrão Win32), `:84-85` (mesma pasta de saída para todas as plataformas); `conversa-webrtc/Pion.Whep.Binding.pas:26-71`, `conversa-webrtc/FFmpeg.Binding.pas:9-12`, `:117-242` (`external` estático, sem `delayed`); `bin/sk4d.dll` (x86, versionado); `git status` (`?? bin/*.dll`); `msbuild` sem efeito (Community).
- **Efeito:** o `bin/Conversa.exe` atual (x86) provavelmente nem abre (`0xc000007b`); um build Win64 não carrega o Skia; um clone limpo não tem como gerar um exe que funcione; **o app não abre sem as 5 DLLs de mídia (≈127 MiB)**, mesmo quem nunca faz chamada (o *runtime* Go sobe ao carregar o exe); não há CI possível.
- **Correção:** alvo único **Win64**; saída por `$(Platform)\$(Config)`; mídia carregada sob demanda (`delayed`/`LoadLibrary` com caminho completo) e com mensagem amigável se faltar; *script* de obtenção das dependências com versão fixa e *hash*; Skia do Delphi; licença que permita build por linha de comando (decisão do responsável); um *script* de build que **não confie no código de saída do MSBuild** sozinho.

### ALTO

**#17 [ALTO] Mensagem oculta aparece com o conteúdo original.** (A5b-04, A2 Q6)
- **Local:** `src/Conversa.Proxy.Tipos.pas:99-111` e `:116-122` (sem `excluida_em`); `src/Conversa.Tipos.pas:174-218`; servidor `conversa/src/mensagens.ts:303-314`, `:603-618` (exclusão lógica; o conteúdo continua vindo, doc 01 §10.9).
- **Efeito:** quem ocultou uma mensagem (no web ou no Android) continua com ela **visível** no FMX dos outros. Problema de privacidade.
- **Correção:** ler `excluida_em` em `/mensagens`, `/mensagem/status` e nas referências; bolha "Mensagem oculta" com clique para revelar (texto e *tooltips* do web); sem menu nem reações; fora do visualizador; citação mostra "Mensagem oculta".

**#18 [ALTO] "Marcar como visualizada" usa `GET` e recebe 404; o contador fica preso.** (A5b-05, A3-05, A5a-04, A2 Q3)
- **Local:** `src/Conversa.Proxy.pas:723-744` (`GET mensagem/visualizar?conversa&mensagem` com `Tentativa(5)`, que não repete 404); `Conversa.Dados.pas:216-217` (a lista só aceita o contador do servidor quando o local é 0); servidor `conversa/src/rotas.ts:112-113` (`POST` com corpo `{conversa, mensagem}`, desde `9b9a32f`).
- **Efeito:** o remetente nunca vê ✓✓ azul do que foi lido no PC; os contadores do celular e do web não zeram; `/mensagens/novas` devolve essas conversas para sempre; depois de reiniciar, contador, *badge* da barra de tarefas e notificações **voltam** para mensagens já lidas.
- **Correção:** `POST /mensagem/visualizar {conversa, mensagem}` em segundo plano; só mensagens de outros, **totalmente** visíveis, com a janela ativa (#54); descontar o contador só depois do sucesso; sempre adotar `mensagens_sem_visualizar` do servidor.

**#19 [ALTO] `/mensagens/novas` com parâmetro inexistente (`ultima`): o servidor devolve tudo "desde sempre".** (A5b-08, A5a-17, A2 Q8)
- **Local:** `src/Conversa.Proxy.pas:284-311` (`AddPair('ultima', …)`, `:290`), chamado **síncrono na UI** em `Conversa.Dados.pas:477`; `:496-508` (um `GET /mensagens` por conversa); servidor `conversa/src/esquemas.ts:68` (`desde` ISO; `ultima` é ignorado — já era assim em abril).
- **Efeito:** cada WS 2 vira N requisições; a UI congela; a primeira mensagem depois de abrir o app pode disparar notificações e sons das conversas antigas não lidas (não confirmado); alimenta a corrida do #11.
- **Correção:** cursor `desde` (ISO), avançado pelo maior `ate` e nunca para o futuro (como o web, doc 03 §1.4); deduplicação por `mensagem_id`; nada síncrono na UI.

**#20 [ALTO] Paginação por aritmética de id global (`menor id − 1`, `maior id + 1`).** (A5b-06, A3-22)
- **Local:** `Conversa.Dados.pas:532-548`; servidor `conversa/src/mensagens.ts:334` (a posição é a da linha `id = referencia`; se ela não existir, a comparação com `NULL` não devolve nada).
- **Efeito:** **mensagem perdida por corrida** logo depois de enviar (o cursor salta para `100+1` antes de a 99 de outra pessoa ser buscada); página anterior vazia quando o vizinho é uma lacuna; uma conversa pode **parar de receber mensagens** até reiniciar o app; não há "fim da lista".
- **Correção:** referência = id da primeira/última mensagem **salva** (inclusiva), descartar a repetida, parar quando vier menos que o pedido; uma requisição por vez por conversa e direção.

**#21 [ALTO] Carregar mensagens anteriores (ou receber uma nova) pula a tela para o fim.** (A5b-07)
- **Local:** `src/chat/Conversa.Chat.pas:243-244`, `:371-378`, `:392-395` (`IrParaUltima = True` por padrão no retorno assíncrono).
- **Efeito:** ler o histórico fica impossível: cada página anterior e cada mensagem nova levam ao fim.
- **Correção:** rolar ao fim só se o usuário estava perto do fim; ao inserir no topo, preservar a âncora; botão "Há novas mensagens" quando estiver longe.

**#22 [ALTO] Conteúdos tipo 5–8 aparecem como bolha vazia.** (A5b-09, A2 Q7)
- **Local:** `src/Conversa.Tipos.pas:220` (`TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo, MensagemAudio)`); `Conversa.Dados.pas:596` (`TTipoConteudo(Ctd.tipo)`); `src/chat/chat/chat.visualizador.pas:150-222` (só 4 ramos).
- **Efeito:** **toda gravação de áudio feita no web (tipo 5)**, resumo de chamada (6), figurinha (7) e votação (8) aparecem como bolha vazia. (Os relatórios A2/A5b levantaram a hipótese de `ERangeError` no build Debug, com *range checking* ligado; a conferência do doc 02, Q7, mostrou que é **improvável**: o `{$R+}` do Delphi não confere *casts* explícitos como `TTipoConteudo(x)`, e nenhum vetor é indexado por esse tipo.)
- **Correção:** enum completo 1..8 (e tolerância a tipos desconhecidos); um *frame* (ou pelo menos um marcador) por tipo; classificação na ordem de `classificarMensagem.ts` (doc 03 MSG-07).

**#23 [ALTO] `GET /conversa/dados` não existe: membros de grupo nunca carregam; chamada em grupo vira `[eu]` → 500.** (A5a-03, A2 Q4, A4-21)
- **Local:** `src/chat/Conversa.Chat.pas:173-178` → `src/Conversa.Proxy.pas:572-605` (rota em `:582`; 404 confirmado no servidor de desenvolvimento); `src/chat/Conversa.Chat.pas:151-155`; `Conversa.Dados.pas:207-209` (membros só de `/conversas`: `[eu, destinatario]`); servidor `conversa/src/notificacoes.ts:33-35` (chamada só consigo mesmo → 500).
- **Efeito:** cabeçalho sem membros; chamada em grupo só com quem já mandou mensagem ou falha com 500 e `FID = 0` (a publicação vai para `call-0-u-<eu>` e a segunda tentativa colide em `FChamadas.Add(0)`); erro silencioso.
- **Correção:** `GET /conversa/usuarios?conversa=` (doc 01 §11.4).

**#24 [ALTO] Rede síncrona na thread da interface: a janela congela em quase toda operação.** (A5a-05, A3-13, A5b-13, A4-19, P8)
- **Local:** login (`Conversa.Login.pas:80`); contatos (`Conversa.Tela.Inicial.view.pas:225`, `src/contatos/Conversa.Contatos.pas:54`, `src/novo/grupo/Novo.Grupo.pas:80`); `Connect` do WebSocket com *handshake* **sem *timeout* de leitura** (`Conversa.Dados.pas:438-450`; `Bird.Socket.Client.pas:472-516`); envio (`src/chat/Conversa.Chat.Listagem.pas:105-110` → `Conversa.Dados.pas:243-290`); criar conversa (`Conversa.Dados.pas:309-322`); download de cada imagem e áudio (`:601`, `:603`); `mensagens/novas` a cada WS 2 (`:477`); `chamada/dados` a cada evento 51–55 e iniciar/entrar (`src/chamada/Conversa.Chamada.pas:296`, `:408-421`, `:462`).
- **Efeito:** "Não respondendo" com servidor lento; congelamento **indefinido** se o servidor aceitar o TCP e não responder ao *upgrade*; cliques perdidos; toasts e vídeo travados.
- **Correção:** nenhuma E/S na thread principal; serviços assíncronos com fila, *timeouts* explícitos e cancelamento; a UI só recebe estado pelo barramento.

**#25 [ALTO] Erros do servidor e das threads são silenciados.** (P9, A2 §7, A3-14)
- **Local:** `src/Conversa.Proxy.pas:154-167` (`ValidarErro` → `TErroServidor` **sem assinante** + `Abort`); rotas assíncronas em `TThread.CreateAnonymousThread` (a exceção morre com a thread: `:213-241`, `:574-605`, `:725-744`, `:788-814`); `conversa-webrtc/Mic.Capture.pas:104-107` (`waveInOpen falhou` sem tratamento, ex.: microfone bloqueado na Privacidade do Windows); `TConversaWebRTC.FOnErro` nunca atribuído; falha no *upgrade* do WebSocket engolida (`Bird.Socket.Client.pas:529-530`).
- **Efeito:** upload recusado, mensagem não enviada, chamada sem áudio, servidor fora: "o app não funciona e não diz por quê", e sem log para diagnosticar.
- **Correção:** erros tipados (status, código, mensagem); toda operação assíncrona termina em sucesso **ou** falha publicada; um ponto único de UI para erros (faixa, toast, diálogo); log estruturado (#85).

**#26 [ALTO] Identificador de anexo vindo de outro usuário vira caminho de arquivo sem validação (*path traversal*).** (P7)
- **Local:** `Conversa.Dados.pas:229-241` (`PastaDados + 'anexos' + PathDelim + sIdentificador`, `TDirectory.CreateDirectory`, `SaveToFile`), `:599-604` (download **automático** ao exibir), `:352-393` (`SalvarAnexo` faz `TFile.Move` do "cache"); o servidor só valida o `conteudo` de figurinha (tipo 7, `conversa/src/mensagens.ts:179-181`).
- **O que acontece:** um participante manda uma "imagem" com `conteudo = ..\..\..\<caminho>`; o cliente de cada destinatário cria pastas e um arquivo nesse caminho (sem sobrescrever existente); se o arquivo já existe, ele é **exibido** no chat; "salvar" de um anexo **move um arquivo do próprio usuário**.
- **Efeito:** criação de arquivos e pastas arbitrários no perfil, exposição local e perda/deslocamento de arquivos do usuário (o conteúdo gravado não é controlado pelo atacante no servidor atual — não confirmado em execução).
- **Correção:** validar o identificador (`^[0-9a-f]{64}$`) antes de qualquer uso; `TPath.GetFullPath` e conferência do prefixo da pasta de cache; **copiar**, nunca mover; temporário + renomeação; Mark-of-the-Web ao salvar (#56). Registrar no doc 08 que o servidor também deveria validar (S20).

**#27 [ALTO] Não há como sair do app pela interface; bandeja incompleta.** (A5a-06, A3-21, A5a-24, P25)
- **Local:** `Conversa.Tela.Inicial.view.pas:197-204` (em Release o X só esconde), `:236-272` (`Shell_NotifyIcon` próprio; clique esquerdo e direito só restauram; sem menu; `TrayIconAdded` nunca vira `True`, então `NIM_DELETE` não roda e fica um ícone "fantasma"; sem `TaskbarCreated`, o ícone some se o Explorer reiniciar e a janela oculta só volta abrindo o exe de novo).
- **Efeito:** sair só pelo Gerenciador de Tarefas ou por Alt+F4/"Fechar janela" na barra de tarefas (que fecham de verdade: comportamento inconsistente); não existe logout nem troca de conta.
- **Correção:** menu da bandeja ("Abrir Conversa", "Não perturbe", "Sair do Conversa"); X fecha para a bandeja (configurável, com aviso na primeira vez); "Sair da conta" separado; `NIM_DELETE` correto; recriar o ícone no `TaskbarCreated`; dica com o número de não lidas.

**#28 [ALTO] A barra de título própria troca o `WndProc` com `SetWindowLong(…, LongInt(@WndProc))`, inseguro em 64 bits.** (A5a-10, P14)
- **Local:** `src/base/Conversa.FormularioBase.pas:324`, `:329`.
- **Efeito:** em Win64 (alvo obrigatório por causa das DLLs) o ponteiro pode ser truncado quando a imagem carrega acima de 4 GB (ASLR de alta entropia), quebrando todas as janelas com barra própria (não confirmado em execução).
- **Correção:** `SetWindowLongPtr(…, GWLP_WNDPROC, LONG_PTR(@WndProc))`.

**#29 [ALTO] Corrida no Indy: `Connected` lê do socket e é chamado em três threads.** (A3-08)
- **Local:** `lib/bird-socket-client/Bird.Socket.Client.pas:288-295`, `:547` (leitor), `:651` (UI, no `Send`), `:725` (*heartbeat* a cada 500 ms, sem ouvinte); no Indy, `TIdIOHandlerStack.Connected` executa `ReadFromSource`.
- **Efeito:** leituras concorrentes no mesmo `InputBuffer` (e, com TLS, `SSL_read` concorrente): bytes perdidos ou fora de ordem, eventos sumindo, exceções esporádicas, possível AV dentro do OpenSSL.
- **Correção:** um único dono do socket (a thread leitora); estado de conexão num campo próprio; ou trocar a biblioteca (#5).

**#30 [ALTO] Chamada com o mesmo usuário em vários aparelhos.** (A3-12, A4-07)
- **Local:** `src/chamada/Conversa.Chamada.pas:170-190` (cria objeto para qualquer `chamada_id`), `:342-347`, `:358-365` (53/54 com o meu id em "Recebendo" são ignorados), `:199-216`, `:309-324`; servidor `conversa/src/chamadas.ts:164-226` e o padrão `overridePublisher` do MediaMTX.
- **Efeito:** atender ou recusar no celular **não para o toque** no PC; atender no PC publica no mesmo `call-C-u-EU` e **derruba a mídia do aparelho que já estava na chamada**; recusar depois manda um 53 a todos; um 54 próprio sem o 51 cria uma chamada "fantasma" e, ao fechar o app, `POST /chamada/sair` **tira o usuário da chamada do celular**.
- **Correção:** 53/54 com `usuario_id = eu` e estado "recebendo" → parar de tocar e descartar localmente, sem REST; não criar objeto para chamada desconhecida (exceto 51); uma publicação por usuário.

**#31 [ALTO] Sem retentativa de WHEP, sem sincronização periódica e sem reconexão de mídia: áudio de mão única.** (A4-08)
- **Local:** `src/chamada/Conversa.Chamada.WebRTC.pas:264-275` (uma tentativa só), `:277-331` (o *peer* é registrado depois do SRD: o primeiro IDR se perde), `:449-466`; `src/chamada/Conversa.Chamada.pas:358-387`; `conversa-webrtc/pion/main.go:186-301` (vaza o `pc` nos erros).
- **O que acontece:** o servidor emite o 54 durante o `/chamada/entrar`, antes de quem atende publicar; quem liga faz o WHEP na hora, recebe 404 e desiste.
- **Efeito:** quem liga não ouve quem atende; qualquer queda é permanente.
- **Correção:** retentativas (áudio 12 × 0,8 s, vídeo 40 × 1 s, como o web); sincronização a cada 4 s com `GET /chamada/dados`; republicar e reassinar em `failed`/`disconnected`; fechar o `pc` em todo erro.

**#32 [ALTO] 51 durante a chamada e "ocupado" abrem outra janela e corrompem a mídia.** (A4-09)
- **Local:** `src/chamada/Conversa.Chamada.pas:170-190`, `:276`, `:334-340`; `src/chamada/Conversa.Chamada.WebRTC.pas:61-114` (*singleton* de mídia); servidor `conversa/src/chamadas.ts:283-291` (adicionar participante manda 51 a quem já está na chamada).
- **Efeito:** alguém adicionar um participante faz a chamada atual **voltar a "Recebendo"**; recusar marca como "recusou" quem tem `entrou_em` nulo, inclusive o criador; uma segunda chamada sobrescreve encoders e *handle* da primeira.
- **Correção:** 51 da chamada atual → só sincroniza *peers*; 51 de outra → `POST /chamada/recusar {id, nao_atendeu:true}` sem tocar; uma chamada ativa por vez.

**#33 [ALTO] Histórico de chamadas com um modelo que o servidor não devolve.** (A4-10, A2 Q5)
- **Local:** `src/Conversa.Proxy.Tipos.pas:186-217` (`chamada_id`, `tipo_chamada`, `status_chamada`, `usuario_exibido_nome`, `tipo_acao`, `quantidade_outros_usuarios`, `adicinoado_em`…); `src/Conversa.Proxy.pas:313-337` (sem filtros); servidor `conversa/src/chamadas.ts:429-450` (`{id, tipo, status, criado_em, criado_por, conversa_id, iniciada, finalizada, duracao, participantes[]}` — não batia nem em abril).
- **Efeito:** lista sem nome, ícone, status e duração; status 5 "Perdida" no FMX × "Desconectada" no servidor; "Ligar novamente" é TODO (`src/chamada/Conversa.Chamada.Detalhe.pas:148-152`).
- **Correção:** modelo `ChamadaHistoricoItem` (doc 01 §9.7); abas Todas/Perdidas (perdida = recebida em que eu não entrei, como o Android); filtros; "Ligar novamente".

**#34 [ALTO] MediaMTX sem autenticação e WHIP/WHEP em HTTP sem credencial.** (A4-11, P13; servidor S4)
- **Local:** servidor `conversa/bin/mediamtx/mediamtx.docker.yml:26-38`, `conversa/bin/nginx/nginx.conf:135-140`; FMX `conversa-webrtc/pion/main.go:256-266`, `:452-455` (só `Basic`), `src/chamada/Conversa.Chamada.WebRTC.pas:185-191`, `:264-268` (credenciais vazias).
- **Efeito:** qualquer usuário logado (que recebe TURN pelo `/api/ice`) pode assistir ou publicar em `call-<id>-u-<uid>`, com ids sequenciais. **Somado ao #1, permite ver a área de trabalho de outras pessoas.**
- **Correção:** no servidor, autenticação HTTP ou JWT no MediaMTX com token de chamada (S4); no cliente, mandar `Authorization: Bearer` no WHIP/WHEP; base HTTPS.

**#35 [ALTO] O vídeo remoto nunca aparece; não há câmera; o decodificador quebra com vários *slices* e com VP9.** (A4-12)
- **Local:** `src/chamada/Conversa.Chamada.Usuario.view.pas:53-58`, `src/chamada/Conversa.Chamada.Usuarios.Listagem.Item.pas:54-59` (`TImage` criado invisível e nunca mostrado); `src/chamada/Conversa.Chamada.WebRTC.pas:23` ("webcam ainda NAO implementada"); `conversa-webrtc/Video.Decoder.pas:285-343` (NAL a NAL, sem `AV_CODEC_FLAG2_CHUNKS`); `conversa-webrtc/pion/main.go:190-197`, `:593-682` (não confere o codec da trilha).
- **Efeito:** chamadas de vídeo sem vídeo; com o H264 do Chrome (vários *slices*) os quadros se corrompem; um web sem H264 publica VP9 e o FMX mostra lixo.
- **Correção:** depende da pilha (ADR 0002). Na atual: mostrar o destino no primeiro quadro, agrupar por *access unit*, conferir o `MimeType`, câmera por Media Foundation.

**#36 [ALTO] Distribuir o pacote atual exige cumprir a GPLv3; risco de patente do H.264.** (A4-14, A1 §5)
- **Local:** `bin/avcodec-62.dll` (`--enable-gpl --enable-version3`, com libx264 e libx265); `LICENSE` (MIT); RTL e FMX da Embarcadero (proprietários) ligados estaticamente.
- **Efeito:** a distribuição binária fica sob as obrigações da GPLv3 (oferta do código-fonte do FFmpeg e de cada biblioteca, *scripts* de build) — juridicamente frágil com a RTL proprietária; além disso, encoder/decoder H.264 podem exigir licença de patente (não é parecer jurídico). Um `.md` do próprio repositório recomendava o FFmpeg 7.x LGPL.
- **Correção:** build LGPL mínimo, OpenH264 da Cisco ou os codecs do Windows (Media Foundation), ou trocar a pilha (ADR 0002); arquivo de avisos de terceiros (WIN-32).

**#37 [ALTO] *Offsets* de *structs* do FFmpeg escritos à mão para a 7.x, usados com a 8.x.** (A4-15, P14)
- **Local:** `conversa-webrtc/FFmpeg.Binding.pas:46-56`, `:74-96`, `:316-322`, `:340-370` (o `pts` é gravado no *offset* 128; pelo layout público do `AVFrame` ele fica em 136); `conversa-webrtc/Audio.Player.pas:170-171`.
- **Efeito:** valores gravados no campo errado (o quadro vai com `pts = AV_NOPTS_VALUE`); qualquer troca de versão do FFmpeg pode **corromper memória em silêncio**.
- **Correção:** `av_opt_set`/funções `av_*` em vez de *offsets*, ou um *shim* em C compilado contra os cabeçalhos da versão empacotada; conferir `avcodec_version()` na carga.

**#38 [ALTO] Sem cancelamento de eco, supressão de ruído e ganho automático; Opus 128 kbps estéreo; MME.** (A4-16)
- **Local:** `conversa-webrtc/Mic.Capture.pas` (`waveIn` cru com `WAVE_MAPPER`); `conversa-webrtc/Audio.Encoder.pas:19-21`; `conversa-webrtc/Audio.Player.pas:95` (`waveOut`, 8 *buffers* que sobrescrevem um ainda em reprodução, `:129-141`).
- **Efeito:** **eco** para os outros quando o usuário usa alto-falante; latência alta; sem escolha de microfone ou saída; estalos.
- **Correção:** AEC obrigatório (pilha do navegador via WebView2, libwebrtc, ou o DSP "Voice Capture" do Windows); Opus mono 24–32 kbps com FEC; WASAPI em modo comunicação; seletores de dispositivo. Decisão no ADR 0002.

**#39 [ALTO] Cliente REST genérico com defeitos de codificação e de protocolo.** (P12, A2 §7)
- **Local:** `REST.API.pas:436-448`, `:496-499` (`TStringStream.Create` sem *encoding* usa `TEncoding.Default`, que no Windows é **ANSI**: JSON UTF-8 com acento ou emoji pode virar *mojibake* — provável, não confirmado em execução); `:654-666` + `:337` (*query* sem *URL-encode* por parâmetro: nomes com `&`, `#`, `+` quebram a requisição); `:329` (`Length(Result)` no lugar de `Length(sURL)`, inócuo hoje); `:477-482` (3xx tratado como sucesso); `:195-203` (um `TNetHTTPClient` novo por requisição, sem *timeout* explícito nem reaproveitamento de conexão); `src/Conversa.Proxy.pas:121-135` (todo corpo, inclusive binário, passa pelo `ParseJSONValue`).
- **Efeito:** nomes e mensagens acentuados corrompidos (não confirmado), uploads com nome errado, CPU e memória gastos, falhas sem repetição.
- **Correção:** cliente tipado sobre `THTTPClient` com UTF-8 explícito, `TNetEncoding.URL` por parâmetro, *streams* binários separados de JSON, *timeouts* e repetição só em requisições idempotentes, testado com *fixtures* reais.

**#40 [ALTO] Primeira mensagem de conversa nova pode não aparecer nem notificar.** (A3-18)
- **Local:** `Conversa.Dados.pas:470-473` (WS 40 → `GET /conversas` assíncrono), `:517-527` (`ObterMensagens`: se a conversa não está em memória, chama `CarregarConversas`, também assíncrono, e **sai**).
- **Efeito:** a criação gera WS 40 e logo depois WS 2; o 2 é processado antes de a lista chegar, e a primeira mensagem de uma conversa nova (inclusive um grupo em que a pessoa acabou de ser incluída) não é baixada nem notificada.
- **Correção:** no WS 2, ao encontrar conversa desconhecida, aguardar `/conversas` e repetir; ou buscar `GET /mensagens` direto pelo `conversa_id` do `/mensagens/novas`.

### MÉDIO

| # | Problema | Local | Efeito | Correção | Origem |
|---|---|---|---|---|---|
| 41 | **Vazamento de GDI no contador da barra de tarefas** | `lib/windows/Conversa.Windows.Overlay.pas:67-97`, `:128-134` (`CreateIconIndirect` copia os bitmaps e ninguém faz `DeleteObject`) | Dois `HBITMAP` vazam a cada mudança do contador; um app que fica dias aberto esgota os objetos GDI (limite de 10.000) e para de desenhar e de criar janelas | `DeleteObject(hbmMask)` e `DeleteObject(hbmColor)` depois do `CreateIconIndirect`; máscara monocromática | A3-20 |
| 42 | **Notificações de mensagem com lógica errada** | `src/chat/Conversa.Chat.Listagem.pas:244-310`: `Exit` em vez de `Continue` (`:275-276`); `sConteudo` não reiniciado (`:284-288`); `Chat.Conversa` pode ser `nil` (`:279`, `:305`); um som por conversa (`:307`); o FMX não lê `arquivada_em` (`src/Conversa.Proxy.Tipos.pas:50-62`) | A primeira conversa sem pendências **descarta as seguintes do lote**; áudio, figurinha, votação e chamada mostram **o texto da conversa anterior**; **conversas arquivadas notificam e tocam**; menções e código crus; rajada de notificações antigas depois de reiniciar (com #18) | `Continue`; resumo por tipo como o web (NOT-02); respeitar `arquivada_em`; um som por lote; notificar só o que é novo pelo cursor; fechar a notificação quando o contador zerar | A3-17, A5a-13, A5a-16, A5b-34, P17 |
| 43 | **Contadores e mensagens próprias não sincronizam entre aparelhos** | `Conversa.Dados.pas:216-217` (só aceita `mensagens_sem_visualizar` do servidor se o local for 0), `:588`, `:609-610`; `src/Conversa.Tipos.pas:854-856`; servidor `conversa/src/notificacoes.ts:43-48`, `:65` (sem evento para o próprio usuário) | Ler no celular não zera o contador nem o *badge* do PC; o contador desconta mensagens já lidas ao carregar o histórico e soma em dobro; mensagem enviada pelo celular só aparece no PC quando outro evento força a busca daquela conversa | Recarregar `/conversas` no foco, na reconexão e no WS 3, **sempre** adotando o valor do servidor; pedir ao servidor eventos para as outras conexões do próprio usuário (S17) | A3-19, A5b-33 |
| 44 | **Nenhuma ressincronização na abertura nem na (futura) reconexão** | `Conversa.Tela.Inicial.view.pas:223-234`; `Conversa.Dados.pas:420-451`; as rotas existem só na unit morta | Sem `chamadas/pendentes`, `contatos/online`, `atividades/novas` nem `mensagens/novas` ao conectar: chamada que já tocava não aparece; eventos perdidos nunca são recuperados; `GET /conversas` roda duas vezes na abertura | A sequência do web (doc 03 §1.4) a cada abertura do socket e no início | A3-15 |
| 45 | **Presença, digitando e gravando não existem** | `Conversa.Dados.pas:469-490` (sem `case` para 4, 5, 60); `src/chat/Conversa.Chat.pas:45-48`, `:110` (a área "digitando…" fica sempre oculta); `src/Conversa.Proxy.Extras.pas:356-390` (corpo `{conversa_id}` em vez de `{id}`, token nunca preenchido) | Sem paridade com PRE-01, ENV-15 e ENV-16; se alguém ligar o `Proxy.Extras` como está, recebe 400/401 | Envio com intervalo mínimo de 2,5 s (o último adiado) e corpo `{id}`; recepção com expiração de 4 s; textos do web; bolinha online com `contatos/online` + WS 60 | A3-16 |
| 46 | **Erros do socket e erros técnicos como UX** | `Conversa.Dados.pas:486-489` (`raise` no tipo 0 → diálogo genérico; socket fica aberto e mudo); `lib/bird-socket-client/Bird.Socket.Client.pas:118-134`, `:529-530`, `:637-638`; `src/novo/grupo/Novo.Grupo.pas:103`, `:110` (validação por exceção); `src/Conversa.Proxy.pas:195` (erro de login cru, inclusive o HTML do 503); `REST.API.pas:716-744` | Diálogos com textos técnicos, metade em inglês ("Websocket not connected or timeout…", "Token vencido!", "Mensagem já adicionada! [TMensagens]…"); falha no *upgrade* sem aviso | Tratar 0/9 como estado (não autenticado → relogar → reconectar); mensagens amigáveis e não modais; validação de formulário inline; HTML do nginx → "Servidor indisponível" (como o web) | A3-14, A5a-12, P38 |
| 47 | **Envio sem mensagem otimista e com erro silencioso** | `src/chat/Conversa.Chat.Listagem.pas:105-110` → `Conversa.Dados.pas:243-290` (síncrono na UI); `src/Conversa.Proxy.pas:154-167`; `src/chat/Conversa.Chat.pas:260-264` | A mensagem só aparece depois do `PUT`; em erro o texto fica no campo (não se perde), mas **nenhum aviso aparece** e o `TMensagem` criado vaza | Mensagem otimista com id negativo e relógio; envio por fila em segundo plano; erro visível com "Tentar de novo" | A5b-13 |
| 48 | **Trocar de conversa destrói o editor** | `src/chat/Conversa.Chat.pas:143-149` (`Limpar` → `FreeAndNil(Editor)`); `src/chat/chat/frames/chat.editor.audio.pas:171` (sem par no destrutor) | Texto, fila de anexos e gravação em andamento se perdem; a captura do microfone **continua** e o arquivo fica preso | Rascunho por conversa (ENV-23); parar a captura no destrutor | A5b-14 |
| 49 | **"Copiar" quebrado** | `src/chat/Conversa.Chat.pas:350`, `:368`; `src/chat/chat/chat.visualizador.pas:175` | Copiar imagem **nunca** funciona (o teste procura `TImage`, mas o objeto clicado é o *frame*); o texto copiado troca `&` por `&&`; não dá para selecionar parte do texto | Testar o *frame* de imagem e copiar o bitmap; copiar o texto sem trocas; componente que permita seleção | A5b-15 |
| 50 | **Toda bolha de arquivo mostra "10 KB"** | `src/chat/chat/frames/chat.conteudo.anexo.fmx:16`; `src/chat/chat/chat.visualizador.pas:188-210` | Tamanho falso (texto do *design*) | Esconder ou buscar o tamanho real (`GET /anexo/existe` traz `tamanho`) | A5b-16 |
| 51 | **Fila de anexos: ordem invertida, nome com ponto, tipo por extensão** | `src/chat/chat/frames/chat.editor.anexo.pas:148` (`downto`), `:153`, `:159`; `src/chat/chat/chat.tipos.pas:45` | Envia na ordem contrária à escolhida; "foto.jpg" vira nome "foto." (exibido "foto..jpg"); `.jpeg`, `.jfif`, `.heic` vão como arquivo; `.mp3`/`.m4a` vão como 3 em vez de 4 | Ordem de inserção; `TPath.GetFileNameWithoutExtension`; detecção por assinatura/MIME; extensão ≤ 10 caracteres | A5b-17 |
| 52 | **Colar imagem grava na pasta do exe** | `src/chat/chat/frames/chat.editor.texto.pas:132-156` (`<pasta do exe>\clipboard\clipboardN.png`) | Falha em `Program Files` (sem permissão); acumula arquivos (24 em `bin/clipboard`); o nome por contagem colide; só `Ctrl+V` (nem `Shift+Insert` nem o menu) | Pasta temporária, `print-<ms>.png` (como o web), limpeza depois do envio; todas as formas de colar | A5b-18 |
| 53 | **Marca como visualizada ao pintar** | `src/chat/chat/frames/chat.mensagem.pas:265-270` (`FramePaint` + janela ativa) | Conta como lida uma mensagem só parcialmente visível | Só "totalmente visível", com a janela ativa e não minimizada (o `FormActivate` já usa o critério certo, `src/chat/Conversa.Chat.pas:157-166`) | A5b-19 |
| 54 | **Upload lê o arquivo inteiro na memória** | `Conversa.Dados.pas:270-275` (`TStringStream.LoadFromFile`, até 1 GiB, copiado de novo por `REST.API.pas:543-554`); o *stream* vaza quando o anexo já existe | Arquivos grandes estouram a memória (2 GB no Win32); custo de cópia | Hash e envio em *streaming* (`TFileStream`); copiar para o cache só depois do sucesso, ou guardar só a referência | A5b-20, P11 |
| 55 | **Salvar anexo move o arquivo do cache e não marca a origem** | `Conversa.Dados.pas:352-393` (`TFile.Move`; `Cont.Nome`/`Cont.Extensao` do servidor no `TSaveDialog` sem sanitização; extensão vazia gera "Nome."; `Exception('Anexo não encontrado!')` sem tratamento) | O cache perde o arquivo; nomes do servidor sem filtro; o arquivo salvo fica **sem Mark-of-the-Web**: um `.exe`, `.js` ou `.lnk` recebido abre sem o aviso do SmartScreen | Copiar, nunca mover; sanitizar o nome sugerido; gravar `Zone.Identifier` (ou `IAttachmentExecute`); aviso para extensões perigosas | A5b-21, A2 §7, P20 |
| 56 | **Links sem validação e com faixas desalinhadas** | `src/chat/chat/frames/chat.conteudo.texto.pas:101`, `:121`, `:166-174` (regex sobre o texto original, mas a exibição troca `&` por `&&`; o link é recortado do texto **exibido**; `ShellExecute` aceita `ftp://`) | A URL aberta pode ser outra que não a sublinhada; sem `www.`; `)` não tratado | Guardar *ranges* sobre o texto original; validar com `TURI` (só `http`/`https`); regras de `parseLinks` do web | A5b-26, P20 |
| 57 | **Gravação e reprodução de áudio** | `src/chat/chat/frames/chat.editor.audio.pas:169`, `:302`, `:306-309` (tipo 4 sem nome nem extensão; arquivo `.mp3` sobre um WAV/AVI RIFF; tempo `00:05,123`; sem `POST /conversa/gravando`; clique curto não trava); `src/chat/chat/frames/chat.conteudo.mensagem.audio.pas:58-63`, `:75-80`, `:79`, `:101`, `:147` (duração em unidades de 100 ns; um `TMediaPlayer` por bolha, aberto no carregamento; vários áudios ao mesmo tempo; sem `POST /mensagem/reproduzir`) | O web e o Android tratam a gravação como áudio comum; formato e extensão errados; duração ilegível; muitos *handles*; as gravações Opus/WebM do web provavelmente não tocam no `TMediaPlayer` (não confirmado) | Tipo 5, formato real (Opus/WebM, M4A ou WAV declarado), `audio-<timestamp>.<ext>`; "gravando" a cada 2,5 s; *player* único e preguiçoso, `mm:ss`, verde até ouvir, `reproduzir` no primeiro *play* | A5b-10, A5b-11, A2 Q13, P34 |
| 58 | **Lista de mensagens sem virtualização** | `src/chat/chat/chat.visualizador.pas:120-229` (um `TFrame` por mensagem e outro por conteúdo), `:238-263` (`ObtemTopMensagem` ordena tudo a cada inclusão: O(n² log n)), `:282-335` (separadores recriados a cada lote); `src/chat/chat/chat.emoji.pas:5071-5120` (`SoEmoji` varre ~5.000 emojis por texto); `src/Conversa.Tipos.pas:641-654` (busca linear) | Conversas longas lentas para abrir e rolar; memória e *handles* crescendo | Lista virtualizada com reciclagem; índice por id; inserção binária; detecção de emoji por *code point* | A5b-12, P26 |
| 59 | ***Access violations* por `nil` espalhados** | `src/chat/Conversa.Chat.pas:157-166`, `:173-178`, `:280-290`, `:392-395`; `src/Conversa.Tipos.pas:446-454` (`Destinatario` `nil`); `src/contatos/Conversa.Contatos.pas:62`, `src/novo/grupo/Novo.Grupo.pas:88`, `src/chat/Conversa.Chat.Listagem.Item.pas:144`, `src/Conversa.Tipos.pas:387` (`nome[1]` com nome vazio; a inicial pela primeira unidade UTF-16 quebra emoji); `src/chat/chat/frames/chat.editor.audio.pas:105`, `:170` (sem microfone) | AV em situações comuns (nome vazio, sem microfone, conversa fechada) | Estados explícitos; checagens; inicial pelo primeiro grafema (GER-07) | P18, A5a-27 |
| 60 | **Conversas novas com id 0 colidem; grupo criado pela metade fica órfão** | `src/contatos/Conversa.Contatos.pas:70-81` + `src/Conversa.Tipos.pas:398-410`; `src/chat/Conversa.Chat.Listagem.pas:219-220`; `src/novo/grupo/Novo.Grupo.pas:112-124`, `Conversa.Dados.pas:309-322` | Dois "novos chats" pendentes têm id 0: o segundo não entra na lista, vaza, e a tela abre a conversa errada; se um membro falhar, a conversa fica criada no servidor e o erro é engolido | Id local negativo e único; criação de conversa num caso de uso com compensação (ou rota única no servidor, S8) | A5a-15, P19 |
| 61 | **Fluxo de chamada com buracos de UX** | `src/chamada/Conversa.Chamada.BarraTitulo.pas:80-100` ("encerrar" com corpo comentado); só existe o som `nova_mensagem` (sem toque, sem "chamando"); sem *timeout* de 30 s nem de "chamando"; `src/chamada/Conversa.Chamada.pas:567-579` (sempre "Chamada de Voz", nome do primeiro participante e não de quem ligou); `src/notificacao/Conversa.Notificacao.Item.Chamada.pas:95-100` (o "×" **recusa**); `src/base/Conversa.FormularioBase.pas:416-419` (fechar a janela só esconde, sem como reabrir); `src/chamada/Conversa.Chamada.Detalhe.pas:148-152` ("Ligar novamente" TODO) | Quem liga fica chamando para sempre; o FMX nunca gera "chamada perdida" própria; o usuário não ouve a chamada chegar | Gerenciador de chamadas com toque em loop, 30 s → `recusar {nao_atendeu:true}`, textos do web, "×" só esconde, indicador que reabre a janela | P21, A4-23, A5a-19 |
| 62 | **`PUT /chamada/iniciar` sem `tipo` nem `conversa_id`; o fim da chamada decidido pelo tipo errado** | `src/chamada/Conversa.Chamada.pas:433-470`, `:349`, `:399-405`; servidor `conversa/src/chamadas.ts:88-110` (doc 01 §9.1, S11) | Sem resumo tipo 6 no chat; o FMX usa `tipo` como Simples/Grupo e o web manda áudio/vídeo: a 1:1 de vídeo do web nunca termina no FMX pelo 55, e a de áudio em grupo termina na primeira saída; a janela abre antes da API e não desfaz em erro | `tipo` como o web, `usuarios` com o próprio usuário (por `/conversa/usuarios`), `conversa_id` da conversa; fim decidido por `GET /chamada/dados` (ninguém mais "Entrou") | A4-21, A4-22 |
| 63 | **Mídia sem controle de rede** | `conversa-webrtc/pion/main.go:171-179`, `:355-362`, `:519-523` (sem interceptores: sem NACK, RTCP, PLI/FIR, TWCC); `conversa-webrtc/Video.Encoder.pas:60` (2 Mbps fixos); duração fixa de 33 ms | Atraso crescente em rede fraca sobre TURN/TCP; *timestamps* errados; sem recuperação de perda | Interceptores padrão do Pion + leitura de RTCP, ou a pilha do ADR 0002 | A4-17 |
| 64 | **Codificação e rede dentro do *callback* do `waveIn`** | `conversa-webrtc/Mic.Capture.pas:267-287`, `:345-361` | O MSDN proíbe chamar funções do sistema ali: risco de *glitch* e *deadlock* (no *mute*); corrida entre `Stop` e o *callback* | O *callback* só sinaliza; uma thread própria codifica e envia (ou WASAPI em modo evento) | A4-18 |
| 65 | **Vídeo recebido: um `Queue` por quadro com cópia de 3,7 MB e sem descarte** | `src/chamada/Conversa.Chamada.WebRTC.pas:287-324` (render com a trava global, que também bloqueia os *callbacks* de áudio) | Com a UI ocupada (#24), a memória explode e o áudio engasga | Um quadro "mais recente" por *peer*; render sem a trava global | A4-20 |
| 66 | **Indicador de fala sem dados** | `src/chamada/Conversa.Chamada.pas:65-66`, `:245-259`; `lib/audio/AudioTypes.pas:20`, `:66`; `src/chamada/Conversa.Chamada.Waveform.pas:89-94` | O *waveform* desenha uma linha reta | RMS do áudio do microfone e de cada *peer* (> 0,02, segura 400 ms) ou remover | A4-24 |
| 67 | **Relatório de vazamento ligado em Release, com vazamentos reais** | `Conversa.Inicializacoes.pas:33`; vazamentos em `Conversa.Dados.pas:651-654`, `:270-280`; `src/chat/Conversa.Chat.pas:260-277`; `src/Conversa.Tipos.pas:398-410`; assinaturas nunca canceladas | O usuário final pode ver a caixa "Unexpected Memory Leak" ao sair | `{$IFDEF DEBUG}`; posse explícita; FastMM em modo *full debug* nos testes | A5a-22, P22 |
| 68 | **Dados locais nos lugares errados e sem limpeza** | `src/configuracoes/Conversa.Configuracoes.pas:41-47` (modo "portátil" na pasta do exe, senão `%APPDATA%` *Roaming*); `Conversa.Dados.pas:231`, `:267-276` (cópia de cada arquivo enviado para o cache, sem limite) | Perfis móveis sincronizam o cache inteiro; cache cresce para sempre; dados na pasta do exe | Configuração em `%APPDATA%\Conversa`; cache, banco e logs em `%LOCALAPPDATA%\Conversa` com cota e limpeza; nada na pasta do exe | P23, A5a-36 |
| 69 | **Domínio acoplado ao global e à UI; nada é testável** | `src/Conversa.Tipos.pas:269-271`, `:579`, `:861`, `:894`; `Conversa.Dados.pas:376-392`; `src/Conversa.Proxy.pas:114`, `:186-193`; `src/chamada/Conversa.Chamada.pas:538-559` | Impossível escrever testes de regra sem subir UI e servidor | Camadas e interfaces (doc 07) | P24 |
| 70 | **Servidor configurável só na primeira vez** | `src/configuracoes/Conversa.Configurar.Conexao.pas:48-81`, `.fmx:100-117` ("Cancelar" sem ação); `src/configuracoes/Conversa.Configuracoes.pas:52`, `:67` (`MediaMtxBase` separado); `Conversa.Dados.pas:324-339` (`ServerOnline` sempre `True`) | Sem validação nem teste; a URL precisa vir com `/api/`; mudar de servidor exige editar o `conversa.json`; a mídia aponta para outro lugar | Um campo "Endereço do servidor" do qual derivam `/api/`, `/ws/` e `/webrtc/`; "Testar conexão"; aba "Servidor" nas configurações (WIN-01) | A5a-20 |
| 71 | **Modais sem teclado; "botões" não focáveis** | `src/principal/Conversa.ModalView.pas:38-72`; botões feitos de `TRectangle` + `TText` em `Conversa.Login.fmx:81-101`, `src/novo/grupo/Novo.Grupo.fmx:72-111`, `src/principal/Conversa.Principal.fmx:18-232` | Sem Esc/Enter; foco não preso; clique fora fecha e perde o que foi digitado; navegação por Tab e leitores de tela não funcionam | Componentes focáveis, Esc/Enter, foco visível, `Hint` em todos os ícones (WIN-12, WIN-22) | A5a-21 |
| 72 | **Tema desligado e frágil** | `src/pss/PascalStyleScript.pas:520-522` (`RegisterObject` sai na hora: o tema não se aplica), `:148` (`.\tema\default.pss` relativo ao diretório atual; sem ele o app não abre), `:421-432`, `:632-635` (grava na pasta do exe), `:435-447` (recursão no `except`); `claro.pss`/`escuro.pss` nunca carregados; cores fixas em `src/chat/Conversa.Chat.Listagem.Item.pas:126-128`, `src/base/Conversa.FormularioBase.pas:343-355` | Sem tema escuro; o app depende de um arquivo solto; manutenção de cor espalhada | Remover o PSS; tokens de cor numa unit (doc `design/cores.md` §7); claro/escuro/seguir o Windows | A5a-23, P29 |
| 73 | **`src/Conversa.Proxy.Extras.pas` é código morto com contratos errados** | O arquivo inteiro (533 linhas, fora do `.dpr`): `alterar-senha` com `senha_nova` (`:247`), `reproduzir` com `mensagem_id/conversa_id` (`:287-288`), `digitando/gravando` com `conversa_id` (`:363`, `:380`), `mensagem` com `referencia.destino_mensagem_id` (`:336-339`), token próprio nunca preenchido (`:151-177`), objetos JSON devolvidos depois de liberados (`:200-204`) | Parece funcionalidade pronta (pendentes, online, reações, SIP…) e induz a erro; se religado, herda 400/401 e *use-after-free* | Apagar; reescrever a partir do doc 01 | A5a-25, A2 §7, P31 |
| 74 | **Criar grupo e Contatos divergem do web** | `src/novo/grupo/Novo.Grupo.pas:80`, `:88`, `:100-124` (exige **2** contatos — o web exige 1; erro do servidor engolido; não abre o grupo criado); `src/contatos/Conversa.Contatos.pas:54-87` e `Novo.Grupo.pas:80-90` (listam o **próprio usuário**) | Dá para abrir "conversa direta" consigo mesmo; grupo de 2 não pode ser criado; falha sem aviso | Regras e textos do web (CON-06, CON-07); filtrar o próprio id | A5a-18, A5a-38 |

### BAIXO

| # | Problema | Local | Efeito / correção | Origem |
|---|---|---|---|---|
| 75 | Monitor de atividade agressivo | `lib/windows/Conversa.Windows.UserActivity.pas:31-34`, `:91-101`, `:104-109` | *Poll* de 100 ms, "inativo" após 1 s, `Synchronize`; roda antes do `Application.Run` (numa partida lenta termina antes de começar e as notificações nunca fecham sozinhas); `Wait` bloqueante na saída pode travar. Iniciar depois do `Run`, limiar de minutos, `Queue`, `WTSRegisterSessionNotification` | A3-24, A5a-34, P28 |
| 76 | Notificações próprias ignoram o Windows | `src/notificacao/Conversa.Notificacao.Visualizador.pas:77-87`, `:117-175`; `src/configuracoes/Conversa.Configuracoes.pas:49-54`, `:63-64` | Janela TOPMOST ignora "não perturbe" e tela cheia; não vai para a Central de Notificações; sempre no monitor principal; sem `FlashWindowEx`; na primeira execução o `Timeout` é 0 e a notificação some na hora. Decidir toast nativo × janela própria (WIN-05) | A3-25, A5a-28, A5a-29 |
| 77 | Implementação de WebSocket ingênua | `lib/bird-socket-client/Bird.Socket.Client.pas:380-388` (comprimento de 64 bits com 4 bytes), `:389-392` (`Random` na máscara), `:547-583` (leitura byte a byte, O(n²); sem fragmentação), `:161-163` (`Upgrade: WebSocket`), `:197-215` (um ouvinte por tipo), `:716-740` (*heartbeat* sem ouvinte) | Só importa se o Bird for mantido (#5 recomenda trocar) | A3-26, P35 |
| 78 | Saída do app | `Conversa.Dados.pas:99-102` (`Disconnect` sem checar `nil`: fechar antes de logar dá AV); `Bird.Socket.Client.pas:742-750` (*closures* na fila referenciam o socket liberado), `:311-340` | AV ao sair em situações de borda. Gerente de conexão com geração | A3-27 |
| 79 | Instância única só em Release e sem *mutex* | `Conversa.Inicializacoes.pas:26-29`; `lib/windows/Conversa.Windows.Utils.pas:89-158`; `WM_USER+1` usado para duas mensagens | Em Debug, várias instâncias com sockets e notificações duplicados; duas aberturas rápidas passam; não repassa argumentos. *Mutex* por sessão, `RegisterWindowMessage`, `WM_COPYDATA` (WIN-09) | A3-28, A5a-30 |
| 80 | Código morto e enganoso | `lib/tcp.pas` (441); `lib/audio/AudioCapture`, `AudioPlayer` (392), `AudioMixer`/`AudioTypes` só pelo tipo; `src/chamada/Conversa.Audio.pas` + `Conversa.Audio.Windows.pas` (449, **mesmo nome de unit** que a da raiz, sombreadas); `src/notificacao/Conversa.Notificacao.Item.pas` (não compila); `src/chat/Conversa.Conteudo.pas`; `src/chamada/Conversa.Chamada.Participante.Item.pas`; `src/chat/chat/frames/chat.anexo.item.pas`, `chat.anexo.fmx`; `lib/popupmenu/PopupMenu.Item.Action.Container.pas`; `lib/bird-socket-client/Bird.Socket.Client.Consts.pas`; `Teste.Proxy.pas`; `teste/`; eventos declarados e nunca usados (`src/Conversa.Eventos.pas:24-39`); ~180 linhas comentadas em `Conversa.Memoria.pas`; restos TCP em `src/chamada/Conversa.Chamada.pas:17`, `:28`, `:116-127` | ~2,3 mil linhas (~11%) que dão a impressão de funcionalidades que não existem. Apagar (fica no histórico) | A3-29, A4-31, A5a-37, A5b-31, P31 |
| 81 | Detalhes de sessão e janela | `src/Conversa.Proxy.pas:130-133`, `:188`, `:195` (503 em HTML; "Seção Encerrada!" detectado pelo texto); `Conversa.Dados.pas:432-438` (o subcaminho do endereço é descartado na URL do WS); `src/base/Conversa.FormularioBase.pas:106-139` (`MinimizeApp` mexe em `SPI_SETANIMATION`, configuração **global da sessão**); `Conversa.Dados.pas:131-132` (o dispositivo nunca é atualizado depois do primeiro registro) | Mensagens amigáveis; caminho do WS configurável; não alterar configuração do sistema | A3-30 |
| 82 | Datas e horas | `src/chat/Conversa.Chat.Listagem.Item.pas:215-224` (`DaysBetween = 0` olha 24 h, não o dia); `src/notificacao/Conversa.Notificacao.pas:151` (`TimeToStr` com segundos) | "Ontem 23h" visto às 8h mostra só a hora; formato depende da localidade do Windows (num Windows em inglês sai `mm/dd/yyyy`). Comparar a data do calendário; `HH:mm`; `TFormatSettings` pt-BR fixo | A5a-26 |
| 83 | Lista de conversas desatualizada | `Conversa.Tela.Inicial.view.pas:232`; `src/chat/Conversa.Chat.Listagem.pas:99-103`; `Conversa.Dados.pas:185-227`; `src/Conversa.Tipos.pas:1028` | Carregada duas vezes na abertura; conversa que o usuário deixou nunca sai; `OrdemAtualizacao` ordena o *array* interno. Carga única e sincronização da lista inteira | A5a-31 |
| 84 | Logs | `Conversa.Log.Pas:26-37` (truncado a cada execução, sem trava, sem *flush*); `conversa-webrtc/pion/main.go:47-70` (log da DLL pode cair em `C:\pion_whep.log`) | Sem diagnóstico. *Logger* com fila, níveis, rotação e redação (token, senha, conteúdo); `%LOCALAPPDATA%\Conversa\logs` | A5a-32, A4-26, P27 |
| 85 | Versão e "Sobre" | `Conversa.dproj:166-167`, `:179-180` (1.0.0.0 fixo, *locale* en-US); `src/sobre/Conversa.Sobre.pas:54-57` ("Build" = data do arquivo) | Não dá para saber que versão o usuário tem. Versão automática (tag/data), *locale* pt-BR, data real do build, licenças de terceiros (WIN-20, WIN-32) | A5a-33, A1 |
| 86 | Registro do dispositivo | `lib/Conversa.DeviceInfo.Utils.pas:53-61`, `:151-169`; `Conversa.Dados.pas:131-144` | `versao_so` por `GetVersionEx` (depende do manifesto); `modelo` vazio; o `DispositivoId` é por máquina, não por usuário (alternar contas cria um dispositivo novo a cada troca). `RtlGetVersion` (≤ 15 caracteres), modelo pelo WMI (≤ 50), `dispositivo_id` por login | A5a-35, A3 §4.3 |
| 87 | Skia vendorizado sem uso efetivo | `src/chat/chat/skia/**` (6.2.0, sombreia o 6.1.0 do Delphi; sem LICENSE); `bin/sk4d.dll` x86 versionado; `src/chat/chat/frames/chat.conteudo.imagem.pas:53` (decide pela extensão, mas o cache não tem extensão: GIF/WebP nunca animam, SVG nunca é reconhecido) | Remover e usar o Skia do Delphi ("Enable Skia"); decidir o formato pela `extensao` do conteúdo | A1, A5b-23, P30 |
| 88 | PNG esquecido no visualizador | `src/visualizadormidia/ImageViewerFrame.fmx:23` (PNG 1920×1200, 4,9 MB) | Vai para dentro do exe. Limpar o `Bitmap` no designer | A1 |
| 89 | *Hacks* de UI | nomes de componente por *timestamp* com `Sleep(1)` (`lib/popupmenu/Popup.pas:146-148`, `:279-285`; `src/notificacao/*`; `src/chat/Conversa.Chat.pas:103-104`; `src/chamada/*`); `Sleep(0)` como "ponto de parada" (`src/chat/Conversa.Chat.pas:192-193`, `src/chat/chat/chat.visualizador.pas:130-135`); `Application.ProcessMessages` (3); seletor de emoji por `SendInput` de Win+. numa janela temporária (`src/chat/chat/chat.so.pas:60-122`); var `Login` nunca atribuída (`Conversa.Login.pas:51-52`) | Comportamento frágil e dependente de tempo. Remover | A5b-28, A5b-30, P32 |
| 90 | Textos e nomes | 0 `resourcestring`, ~272 textos de UI literais em `.pas`/`.fmx`; erros de digitação que viraram API: `RecebentoChamada` (`src/Conversa.Tipos.pas:43`), `Indisposivel`, `Sucess` (`REST.API.pas:44`), **`adicinoado_em`** (`src/Conversa.Proxy.Tipos.pas:170`, nunca desserializa), "Seção Encerrada!"; status 5 "Perdida" × "Desconectada" no servidor; enum sem 57 | Textos centralizados alinhados ao web (doc 03 §6); nomes corrigidos na nova base | A4-30, P33 |
| 91 | Resíduos de Android | `Conversa.dproj:9` (Android e Android64), `:92-99` (permissões `AUP_*`); `{$IFDEF Android}` em `src/chat/chat/chat.selectfile.pas` e `lib/Conversa.DeviceInfo.Utils.pas`; pasta `Android64/` (211 MB) | Alvo é só Windows. Remover | P37 |
| 92 | Configuração frágil | `src/configuracoes/Conversa.Configuracoes.pas:70-78` (`TFile.WriteAllText` não atômico, gravado de vários pontos, inclusive a cada Ctrl+roda); `lib/windows/Conversa.Windows.Utils.pas:187-198` (restaura a posição sem checar se o monitor ainda existe); WMI na thread da UI no login | Arquivo corrompido em queda de energia; janela fora da tela. Gravação atômica (temporário + renomear); checar o monitor | P36 |
| 93 | Higiene do repositório | HEAD `4759ba5` **não enviado**; `main` 23 commits atrás; 27 *stashes*; branches mortas (`alteracao-base`, `keen-buck`, `vigorous-lichterman`); `.git` sem `gc` (2.795 objetos soltos); `.gitignore` com lacunas (§1.4); *PreBuild* `taskkill` global; Win32 e Win64 na mesma pasta de saída; `MidasLib` sem uso; `conversa-webrtc/.gitignore` de outro projeto | Etapa 0 do `TODO.md` | A1 |
| 94 | Fonte proprietário no histórico público | `src/fmx/FMX.Platform.Win.pas` (© Embarcadero), `1712a09` → `428d04e` (2024) | Redistribuição do fonte do RTL viola o EULA. Só reescrita de histórico remove; decisão do responsável | A1 |
| 95 | `pion_whep.dll` | Pion `v4.0.0` (out/2024) com dependências defasadas; build sem `-trimpath -ldflags "-s -w"` (19 MB com símbolos), `vcs.modified=true`; `go.mod` com `go 1.22` (liga `GODEBUG` legados de TLS/x509) | Atualizar o Pion e rodar `govulncheck`, build reprodutível — se a pilha for mantida (ADR 0002) | A4-25 |
| 96 | Detalhes da chamada | `src/chamada/Conversa.Chamada.WebRTC.pas:401-409` (*mute* fecha e reabre o `waveIn`: estalo e latência); `src/chamada/Conversa.Chamada.view.pas:276` (microfone marcado "Ativo" sem saber se abriu); `src/chamada/Conversa.Chamada.pas:657-674` (cronômetro com milissegundos a cada 30 ms) | *Mute* por *flag*; estado vindo da captura; `mm:ss` a cada 1 s | A4-28, A4-29 |
| 97 | Corrida no id da chamada | `src/chamada/Conversa.Chamada.WebRTC.pas:177`, `:253`; `src/chamada/Conversa.Chamada.pas:499-504`, `:529-534` | A assinatura pode sair com id 0 (o `FChamadaId` só é definido dentro da thread de publicação). Definir chamada e usuário antes de criar as threads | A4-27 |
| 98 | Ícones e visualizador | `src/chat/chat/chat.so.pas:139` (`SHGetFileInfoA` com `AnsiString`: falha em nomes fora do ANSI); `src/chat/chat/frames/chat.conteudo.imagem.pas:95-100` + `src/visualizadormidia/ImageViewerFrame.pas:165-178` (GIF/WebP/SVG passam `nil`: divisão por zero provável) | `SHGetFileInfoW`; passar o arquivo ao visualizador | A5b-22, A5b-27 |
| 99 | Assinaturas e dicionários | `src/chat/Conversa.Chat.pas:113` × `:116-123` (`TChat` não cancela a assinatura); `src/chat/chat/chat.visualizador.pas:408-411`, `:418-425`, `:437-440` (indexador lança para id ausente; `Listar` devolve índices, não ids) | `Unsubscribe` no destrutor; `TryGetValue` | A5b-24, A5b-25 |
| 100 | Bolhas de grupo e separador de data | `src/chat/Conversa.Chat.pas:204` (nome do remetente em **todas** as bolhas, inclusive nas próprias, sem agrupar); `src/chat/chat/frames/chat.separador.data.pas:51` (`dd/mm`, sem dia da semana) | Regras do web (MSG-02): nome só nas recebidas e quando o remetente muda; "seg., 05/10/2026", "Hoje", "Ontem" | A5b-29 |
| 101 | Avatar sem foto | barra lateral, lista, cabeçalho e contatos mostram só a inicial (`src/principal/Conversa.Principal.fmx:304-319`; `src/chat/Conversa.Chat.pas:108`); o círculo do novo grupo tem "C" fixo (`src/novo/grupo/Novo.Grupo.fmx:173`) | Componente `Avatar` único: foto (`avatar_url`, renovando a URL que expira em 600 s), senão a inicial pelo grafema e cor estável (GER-07) | A5a GER-07 |
| 102 | Tipos duplicados e *hard casts* | três `TConversa` (`Conversa.Tipos`, `Conversa.Proxy.Tipos` e `Conversa.Proxy` — este é a API), três `TMensagem`, três `TConteudo`, dois `TUsuario`/`TContato`; `TListBoxItem = class(FMX.ListBox.TListBoxItem)` redeclarado em 5 units com *hard casts* que dependem da ordem do `uses` | Código cheio de nomes qualificados; quebra silenciosa ao reordenar `uses`. Nomes únicos na nova base | P31 (§3.5 do A6) |
| 103 | Documentação desatualizada | `README.md` (fala em Linux e Android FMX; não diz como compilar, nem das DLLs, nem do servidor Bun); `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md` (descrevem o áudio TCP, morto); `conversa-webrtc/whep-viewer-spec.md` (Delphi 11, FFmpeg 7.x LGPL, `ffmpeg_helper.dll` que não existe); `conversa-webrtc/pion/DOC_COMPILACAO.md` (caminhos `D:\testewebrtc\pion`; não diz para copiar a DLL para `bin/`); `docs/todo.md` (não versionado; certo quanto ao cliente, mas descreve o servidor Delphi) | Etapa 0: README novo, docs antigos em `docs/legado/` com aviso | A1 §8 |

---

## 7. Qualidade geral e dívida técnica

### 7.1 Métricas

| Métrica | Valor |
|---|---|
| Units compiladas no exe | 112 (55 no `.dpr` + 57 só pelo *search path*) |
| Linhas Pascal próprias vivas | **~19 mil** (contando `lib/bird-socket-client` como terceiro e os *bindings* de `conversa-webrtc/` como próprios); **~23 mil** contando toda a `lib/` e a bancada de teste. Mais 5.128 da tabela de emoji e 714 de Go (`pion/main.go`) |
| Código próprio morto | 11 units, ~2,3 mil linhas (~11%), mais `teste/` (2,6 mil) e a bancada WebRTC (0,8 mil) |
| Vendorizado | Skia4Delphi 31.829 · DCPcrypt 14.769 (só ~2,3 mil usadas) · Bird 961 |
| `.fmx` próprios | 59 (4 *forms*, ~50 *frames*; 6 sem uso); 78 mil linhas, das quais 66 mil são o PNG esquecido do visualizador |
| Testes automatizados / CI / instalador | **0 / 0 / 0** |
| Maiores units | `Conversa.Tipos` 1.093 · `Conversa.Proxy` 939 · `PascalStyleScript` 789 (inerte) · `REST.API` 768 · `Bird.Socket.Client` 758 · `Conversa.Chamada` 683 · `Conversa.Dados` 659 · `Proxy.Extras` 533 (morta) · `FormularioBase` 495 · `Chamada.WebRTC` 473 · `chat.visualizador` 452 · `tcp` 441 (morta) |
| Maiores rotinas | `WndProc` (`FormularioBase`) ~159 linhas · `TPascalStyleScript.Apply` ~145 · `TBirdSocketClient.ReadFromWebSocket` ~119 · `TChatVisualizador.AdicionarMensagem` ~110 · `TConversaWebRTC.AssinarDePeer` ~90 |
| Concorrência à mão | 16 `CreateAnonymousThread` (cada chamada REST assíncrona cria uma thread nova, sem *pool*) · 5 `TTask.Run` · 12 `TThread.Queue` · 7 `Synchronize` · 13 `TCriticalSection` · **0 cancelamento** |
| E/S síncrona na thread principal | ≥ 15 rotas (#24) |
| `FreeAndNil(Self)` / `with … do` / `Sleep(` / `ProcessMessages` / `except` vazio | 6 / 75–96 / ~30 / 3 / 6–7 |
| Globais e *singletons* | ~15 |
| Textos de UI literais / `resourcestring` | ~272 / 0 |
| Histórico | 183 commits (2023-06-28 → 2026-04-26), 27 *stashes*, HEAD não publicado |

### 7.2 Avaliação franca

- **Arquitetura:** é um app "UI inteligente" com um objeto global (`TDados`) e um domínio mutável que conhece o serviço global e dispara eventos de tela. Não há camada de aplicação, interfaces nem injeção. O proxy REST é estático, lê e escreve configuração global e decide entre síncrono e assíncrono rota a rota. **Nada pode ser testado sem subir a interface e um servidor.**
- **Concorrência:** a segurança de threads foi "resolvida" fazendo quase tudo na thread principal, ao preço de congelar a interface em cada operação de rede. As partes concorrentes de verdade (WebRTC, captura, *callbacks* Go, `waveIn`) vieram depois, com travas pontuais e sem modelo de dono, e têm corridas e *use-after-free*.
- **Ciclo de vida:** o padrão "o objeto se libera no próprio evento" e a posse implícita de *streams* e itens tornam o app sujeito a falhas que dependem de *timing*.
- **Evolução por camadas:** dá para ver três gerações sobrepostas — 2024 (`TDados` + `Memoria`), 2025 (refatoração "Proxy + Eventos", prototipada em VCL e aplicada pela metade) e 2026 (chamadas: TCP → WebRTC por "migração automática", com eventos, `Proxy.Extras` e *waveform* declarados e não ligados). Nenhuma geração removeu a anterior.
- **Contrato:** o código foi escrito para o servidor Delphi, e contra o Bun atual anexos, mensagens novas, chamadas e outras áreas quebram (doc 02). Como os erros são silenciados (#25), o usuário não vê *por que* nada funciona.
- **Segurança:** o REST por WinHTTP está certo. O resto (WebSocket, senha, anexos, mídia) tem problemas de projeto, não de detalhe.
- **Pontos positivos reais:**
  - a ideia de entregar respostas na thread principal por um barramento tipado (`TEventBase.Send` + `ForceQueue`);
  - listagens (conversas, mensagens, histórico de chamadas) já assíncronas com evento de volta — o histórico de chamadas é o exemplo mais limpo do app;
  - REST sobre WinHTTP (TLS, *proxy* e certificados do sistema);
  - deduplicação de anexos por SHA-256 compatível com o web;
  - conversor de datas ISO-8601 centralizado e correto (`src/Conversa.Serializer.pas:69-88`);
  - anexos nunca executados automaticamente;
  - **integração cuidadosa com o Windows:** contador na barra de tarefas, bandeja, instância única que traz a janela para frente, barra de título própria com *Snap Layouts*, zoom com Ctrl+roda, posição da janela salva, notificação que não rouba o foco e espera o usuário voltar;
  - **interface própria e polida (59 *frames*), adotada como referência visual pelo Android novo** (`docs/design/cores.md`);
  - Enter envia / Shift+Enter quebra linha, fila de anexos, colar imagem, gravar segurando, visualizador com zoom;
  - documentação da DLL de mídia (`conversa-webrtc/pion/DOC_*.md`) e uma bancada de teste WHIP/WHEP;
  - o `docs/todo.md` (junho de 2026) já fazia uma revisão honesta da documentação.

---

## 8. Avaliação: evoluir ou recomeçar?

> Premissas aceitas pelo responsável: o cliente **continua em Delphi FMX** e o alvo é **só Windows**. A comparação é entre **evoluir o código atual** e **recomeçar uma nova base Delphi FMX**, transplantando o que presta.

### 8.1 Argumentos para evoluir o código atual

1. **O visual é bom e já é referência:** 59 *frames*/*forms* próprios, cuja paleta o Android novo adotou. Em FMX, esse trabalho é caro de refazer.
2. **Há componentes de interface com valor real:** renderizador de bolhas, editor com anexo, áudio e emoji, notificações empilháveis com ações, barra de título própria, contador na barra de tarefas, bandeja, visualizador de imagem.
3. **A pilha WebRTC nativa é recente** (abril de 2026) e tem documentação e bancada.
4. **A equipe conhece o código e o Delphi;** não há troca de linguagem.

### 8.2 Argumentos para recomeçar (o núcleo e o esqueleto)

1. **Os defeitos críticos estão no núcleo, não nas bordas:** sessão e senha (#4, #6), WebSocket (#2, #3, #5), E/S na interface (#24), erros silenciados (#25), anexos (#9, #10, #26), ciclo de vida e mídia da chamada (#1, #7, #8, #12–#14). Corrigir significa reescrever `Conversa.Dados`, `Conversa.Memoria`, `Conversa.Tipos`, `Conversa.Proxy*`, `REST.API`, `Bird.Socket.Client`, `Conversa.Login`, `Conversa.Configuracoes`, `Conversa.AES`, `Conversa.Chamada` e `Conversa.Chamada.WebRTC` — **tudo o que tem estado ou faz E/S**.
2. **O contrato mudou por baixo** (servidor reescrito em Bun): upload e download por MinIO, mensagens ocultas, referências, enquetes, atividades, TURN, eventos 57/61/62. A camada de dados precisa ser refeita de qualquer forma.
3. **Não existe rede de proteção:** zero testes, estado global e domínio que chama o serviço global (#69). Evoluir "no lugar" obrigaria a manter o `Dados` global vivo durante a transição, com duas gerações convivendo — o que já aconteceu três vezes (§7.2).
4. **A maior parte do produto ainda não existe:** das 137 funcionalidades do web, 76 nunca existiram no FMX e 54 estão parciais ou quebradas (doc 05). Construí-las sobre um núcleo síncrono e global multiplica o custo.
5. **O build precisa ser refeito de qualquer forma:** Win64 único, dependências obtidas por *script*, Skia do produto, mídia sob demanda, instalador e licença que permita compilar por linha de comando (#16).
6. **A pilha de mídia precisa de uma decisão** antes de qualquer investimento: a atual não tem cancelamento de eco, tem áudio quebrado nos dois sentidos, usa um FFmpeg GPLv3 e *offsets* frágeis (#13, #14, #36–#38). A recomendação da auditoria é trocá-la (doc 07 §6, ADR 0002).
7. **Código morto, vendorizado e duplicado** (~11% do código próprio, mais 46,6 mil linhas vendorizadas) aumenta o custo de qualquer manutenção.

### 8.3 Recomendação

**Recomeçar o núcleo e o esqueleto numa nova base Delphi FMX (Win64) e transplantar a interface *frame* a *frame*.** Nem remendar o atual, nem descartar o visual.

- **Onde:** mesmo repositório, em branch própria (proposta: `nova-base`), com o app novo numa pasta própria (`app/`). O app atual fica congelado na branch `legado/abril-2026` e na tag `legado-v1-final`, recebendo só o pacote de higiene do doc 06, Bloco B, se alguém depender dele.
- **Ordem:** primeiro o núcleo testável (sessão, HTTP tipado, tempo real, cache, barramento), depois conversas e mensagens, anexos, notificações do Windows, chamadas (depois do protótipo da pilha de mídia) e o restante da paridade, seguindo a fila (doc 06) e o `TODO.md`.
- **Proporção esperada:** de ~19–23 mil linhas próprias, cerca de **35–40% são transplantáveis** (*frames* e componentes de interface, integrações com o Windows, tabela de emoji e, se a pilha atual for mantida, os *bindings* de mídia com ajustes). O restante é reescrito ou descartado.
- **Condição prévia:** resolver como compilar e testar (licença Professional ou superior para linha de comando e CI, ou um fluxo de build pelo IDE combinado com o responsável). Sem isso, o trabalho autônomo de implementação não é possível nesta máquina (doc 00 §5).

**Aproveitáveis (com os ajustes indicados):**

| Peça | Arquivo(s) | Ajustes |
|---|---|---|
| Visual de *forms* e *frames* | `src/**/*.fmx` + `.pas` de apresentação (lista, chat, editor, contatos, grupo, chamada, histórico, sobre, login) | Tirar toda chamada a `Dados`/`TAPIConversa`; ligar a *ViewModels*/*Presenters*; remover nomes por *timestamp* e `Sleep` |
| Renderizador de mensagens | `src/chat/chat/chat.visualizador.pas`, `chat.expositor`, `chat.ordenador`, `frames/chat.mensagem*`, `chat.conteudo.*`, separadores | Virtualizar (#58); receber modelos imutáveis; formato pela `extensao` |
| Editor de mensagem | `src/chat/chat/frames/chat.editor*.pas` | Áudio em formato real (#57); colar em `%TEMP%` (#52); envio pela fila |
| Emoji | `src/chat/chat/chat.emoji.pas` (tabela) | Manter a tabela; trocar o `SendInput` por seletor próprio |
| Notificações | `src/notificacao/Conversa.Notificacao*.pas` (menos `Item.pas`) | Fechar pelo gerenciador depois do *handler* (#7); avaliar toast nativo (WIN-05) |
| Barra de título, bandeja, instância única | `src/base/Conversa.FormularioBase.pas`, partes de `Conversa.Tela.Inicial.view.pas`, `lib/windows/Conversa.Windows.Utils.pas` | `SetWindowLongPtr` (#28); menu da bandeja (#27); *mutex* (#79) |
| Contador na barra de tarefas | `lib/windows/Conversa.Windows.Overlay.pas` | `DeleteObject` (#41) |
| Inatividade | `lib/windows/Conversa.Windows.UserActivity.pas` | #75 |
| Barramento de eventos (a ideia) | `src/Conversa.Evento.Base.pas` | Manter a entrega na thread principal; multi-assinante com cancelamento, isolamento de exceção e "último valor" |
| Conversor de datas | `src/Conversa.Serializer.pas` | Cobrir `null`; testar |
| Informações do dispositivo | `lib/Conversa.DeviceInfo.Utils.pas` (parte Windows) | `RtlGetVersion` (#86) |
| Menu e *popup* | `lib/popupmenu/*` | Remover nomes por *timestamp*; teclado |
| Visualizador de imagem | `src/visualizadormidia/*` | Remover `FreeAndNil(Self)`; galeria |
| Histórico de chamadas (estrutura) | `src/chamada/Conversa.Chamada.Listagem*.pas`, `Detalhe` | Modelo do contrato (#33) |
| *Waveform* (visual) | `src/chamada/Conversa.Chamada.Waveform.pas` | Alimentar com o nível de áudio |
| Mídia nativa (só se o ADR 0002 mantiver Pion + FFmpeg) | `conversa-webrtc/*.pas`, `pion/main.go` | #12–#14, #35–#38, #63–#65 |
| Bancada WebRTC | `conversa-webrtc/Inicio.view.pas`, `Whip.view.pas` | Ferramenta de desenvolvimento, fora do app |

**Descartar:**
- `Conversa.Dados`, `Conversa.Memoria`, `Conversa.Tipos` (reescrever como domínio imutável), `Conversa.Proxy`, `Conversa.Proxy.Tipos` (DTOs novos a partir do contrato), `Conversa.Proxy.Extras`, `REST.API`;
- `lib/bird-socket-client/*` (trocar por WebSocket do WinHTTP);
- a lógica de `Conversa.Login`, `Conversa.Configuracoes` (refazer em `%APPDATA%`/`%LOCALAPPDATA%`), `lib/AES/*` (inclusive DCPcrypt), `Conversa.WMI`;
- `Conversa.Chamada` e a orquestração de `Conversa.Chamada.WebRTC` (refazer como gerenciador com máquina de estados);
- `Conversa.Log` (trocar por *logger*), `src/pss/*` e `bin/tema/*`, a cópia do Skia e `bin/sk4d.dll`;
- todo o código morto do #80, `teste/`, `Android64/`, `Serializer/`, `api/`, ramos `{$IFDEF Android}`;
- `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md` (para `docs/legado/`).

**Ações imediatas, se o app atual continuar em uso enquanto a nova base nasce** (doc 06, Bloco B, opcional):
1. #1: `PublicarLocalNaSala(ChamadaId, MeuId, False, True)` — nada de vídeo automático.
2. #6: parar de salvar a senha e apagar `Senha` dos `conversa.json` existentes.
3. #26: validar o identificador de anexo; copiar em vez de mover.
4. #5: no mínimo `VerifyMode := [sslvrfPeer]` com conferência do host, só TLS 1.2 e OpenSSL na pasta do app.
5. #7/#8: liberação adiada e `Desligar` esperando a publicação.
6. #67: relatório de vazamento só em Debug.
7. #16: fixar Win64 e documentar como obter as DLLs.

Mesmo com isso, o app atual **não deve ser distribuído a novos usuários**: as quebras de contrato (doc 02), #2, #3, #4 e #24 continuam.

---

*Fim do relatório. Evidências completas nos relatórios de apoio (`apoio/A1`–`A7`).*
