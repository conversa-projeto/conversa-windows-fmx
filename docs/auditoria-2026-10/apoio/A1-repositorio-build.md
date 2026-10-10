> **Relatório de apoio da auditoria de 2026-10-08** — frente: repositório, build, dependências e métricas.
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A1 — conversa-windows-fmx: repositório, build, dependências e métricas

**Repositório:** `conversa-windows-fmx` · **Data:** 2026-10-08 · **Branch auditada:** `chamada` (HEAD `4759ba5`, 2026-04-26) + alterações *staged* em 2 arquivos
**Escopo desta parte:** Git (branches, stashes, staged, histórico), lixo e artefatos, segredos e endereços fixos, `Conversa.dproj`/`.dpr`, projetos auxiliares, DLLs de runtime, tentativa de build real, métricas e documentação existente.
**Restrições respeitadas:** nenhum arquivo versionado foi alterado (conferido com `git status --porcelain`, hash do índice e hash do `git diff --cached` antes e depois). As únicas escritas no repositório foram as do MSBuild em arquivos **ignorados** (`Conversa.res`, `Conversa.dres`, `ConversaResource.rc`, regenerados às 23:08). Os scripts de análise ficaram no scratchpad.

> Convenção: `arquivo:linha` é relativo à raiz de `conversa-windows-fmx` e se refere à **árvore de trabalho** (HEAD + staged). Quando não deu para confirmar algo, está escrito "não confirmado".

> **Observação de processo:** durante a auditoria apareceram em `docs/` as pastas `adr/`, `auditoria-2026-10/`, `contrato/` (com `openapi.json`, ignorado pelo `*.json`), `desenvolvimento/`, `design/` e `historico/_modelo.md` (22:59–23:00). **Não foram criadas por este agente** (outro processo da auditoria). `docs/historico/` aparece como não rastreado no `git status`.

---

## Sumário executivo

- **Build pela linha de comando é impossível nesta máquina.** O Delphi instalado é o **12.1 Athens** (`bds.exe` 29.0.51961.7529) na edição **Community** (o registro informa `Edition = Starter`). `msbuild` e `dcc32`/`dcc64` respondem *"This version of the product does not support command line compiling."* O pior: **o MSBuild sai com código 0** mesmo sem compilar nada. Por isso não há contagem de warnings/hints (§6). Há evidência indireta de que a árvore atual compilou no IDE para Win32 em 2026-06-27 20:56 e de que o HEAD compilou para Win64 em 2026-04-26 22:37.
- **O exe que está em `bin/` hoje é Win32 (x86), mas as DLLs de WebRTC/FFmpeg são só x64** e entram por *import* estático. O Win32 é a plataforma padrão do `.dproj` (`Conversa.dproj:8`). O `bin/Conversa.exe` atual muito provavelmente nem abre (erro `0xc000007b`; não executei para confirmar). Já um build Win64 carregaria o `bin/sk4d.dll` **x86** versionado, e o Skia falharia (`Abort` em `System.Skia.API.pas:4569`).
- **O commit HEAD `4759ba5` (WebRTC, +8.486 linhas) não foi enviado** (`chamada` está 1 à frente de `origin/chamada`). O `main` remoto está parado em 2025-08-03, 23 commits atrás. Existem **27 stashes** (não 10), dos quais nenhum parece valioso: todos foram absorvidos ou superados.
- **Staged:** o WebSocket passa a usar `wss://host:porta/ws/` derivado do `Host` REST, como o servidor Bun atual (`conversa/src/websocket.ts:53-56`). Com `https` isso passa pelo Indy + OpenSSL **1.0.2** (`libeay32`/`ssleay32`), **que não existem na máquina nem em `bin/`**. Provavelmente o socket não conecta no ambiente de dev atual (não confirmado em execução).
- **Licenças e distribuição:** as DLLs FFmpeg são um build *nightly* da BtbN **GPLv3** (`--enable-gpl --enable-version3`, libx264/libx265). Um `.md` do próprio repositório recomenda o LGPL. Também ficou no histórico público (2024) o fonte proprietário da Embarcadero `src/fmx/FMX.Platform.Win.pas`.
- **Dívida:** 51 units versionadas fora do build (11 próprias, 2.316 linhas, incluindo o `Conversa.Proxy.Extras.pas` de 534 linhas criado no HEAD e nunca referenciado). Há duas units com o mesmo nome `Conversa.Audio`. O Skia está vendorizado (6.2.0) e "sombreia" o Skia 6.1.0 do Delphi. Um `.fmx` de 4,9 MB carrega um PNG 1920×1200 esquecido. O `.git` tem 2.795 objetos soltos (86 MiB) e nunca foi compactado.
- **Segurança local:** a senha do usuário é guardada em `conversa.json` com AES de **IV fixo** e chave = serial da placa-mãe + salt gravado junto (`lib/AES/Conversa.AES.pas:30-37`). Na prática é ofuscação. O Indy aceita TLS 1.0/1.1 e não valida o certificado.

---

## 1. Git

### 1.1 Visão geral

| Item | Valor |
|---|---|
| Remoto | `origin https://github.com/conversa-projeto/conversa-windows-fmx.git` (`origin/HEAD → origin/main`) |
| Branch atual | `chamada` → rastreia `origin/chamada`, **1 commit à frente** (`4759ba5`, não enviado) |
| Worktrees | só a principal (`C:/Users/danie/Desktop/GIT/conversa-projeto/conversa-windows-fmx`) |
| Tags | `v0.0.1` (anotada, "Teste do primeiro versionamento", aponta para `24dffba` 2024-09-03) e `v0.0.2` (anotada, sem mensagem, `b3fb461` 2024-09-19 "Altera para release"). As duas estão contidas em `chamada`. **Não têm relação com o VersionInfo do exe**, que é fixo em 1.0.0.0 (§4.1). |
| Total de commits | 183 em `chamada` (186 em `--all`, contando o commit de `alteracao-base` e os de stash) |
| Primeiro commit | `8e4d9fc` 2023-06-28 "Initial commit" |
| Último commit | `4759ba5` 2026-04-26 22:39 "feat: Integra chamadas com WebRTC (audio + video) via MediaMTX" |
| Commits por ano (chamada) | 2023: 8 · 2024: 134 · 2025: 25 · 2026: 16 |
| Merges | 7 |
| Autores (chamada) | Daniel de Araujo Costa: 138 (130 como `DanielAraujo-dac` + 8 pela interface do GitHub) · Eduardo: 45 (36 + 9 pela interface do GitHub). E-mails omitidos. |
| Coautoria de IA | 2 commits: `ebe5cb9` (Claude Opus 4.5) e `4759ba5` (Claude Opus 4.7). O cabeçalho de `Conversa.Chamada.WebRTC.pas` e de `Conversa.Proxy.Extras.pas` diz "Migracao automatica 2026-04-21". |
| Tamanho do `.git` | **93 MB, com 2.795 objetos soltos (85,8 MiB) e 1 pack de 5 KiB.** O repositório nunca foi compactado (`git gc`). Maiores blobs: `bin/sk4d.dll` (duas versões de ~18,5 MB), `ImageViewerFrame.fmx` (4,7 MB), `chat.emoji.pas` (899 KB ×2), fontes do Skia. |

### 1.2 Branches

Os números de "à frente/atrás" são relativos a `chamada` (`git rev-list --left-right --count X...chamada`).

| Branch | Último commit | Data | Só nela / só em `chamada` | Contida em `chamada`? | Observação |
|---|---|---|---|---|---|
| `chamada` (local) | `4759ba5` feat: Integra chamadas com WebRTC… | 2026-04-26 | — | — | Desenvolvimento de fato. |
| `origin/chamada` | `ebe5cb9` fix: Padroniza design visual do item de chamada | 2026-02-03 | 0 / 1 | Sim | Falta o push do HEAD. |
| `main` = `origin/main` | `e970c92` Adiciona socket para atualização de eventos | 2025-08-03 | 0 / 23 | Sim | O branch padrão do GitHub está **14 meses atrás** do código real. |
| `alteracao-base` | `a8dcfe8` Adiciona fontes e IFDEF | 2024-11-05 | **1** / 41 | **Não** | Experimento multiplataforma (Android/Windows): `AndroidManifest.template.xml`, `Conversa.deployproj`, `src/base/Conversa.Formulario.{Android,Base,TitleBar,Windows}.*`, `src/base/reset/*`, `bin/sk4d.dll` trocado. Nada disso existe no HEAD. Abandonado; o app Android seguiu em outro repositório. |
| `keen-buck` | `b610774` Correções ao iniciar nova conversa | 2025-11-02 | 0 / 16 | Sim | Nome típico de worktree do Claude Code. A worktree já não existe; dá para apagar a branch. |
| `vigorous-lichterman` | `b610774` (o mesmo) | 2025-11-02 | 0 / 16 | Sim | Idem. |

**Commits locais não enviados:** `git rev-list origin/chamada..chamada` → só `4759ba5` (2026-04-26 22:39:42, 37 arquivos, +8.486/−179). É o commit mais importante do repositório e **existe só nesta máquina**.

### 1.3 Stashes (27, não 10)

Nenhum stash tem parte *untracked* (`stash@{n}^3` não existe em nenhum). Na tabela, "Iguais/Dif./Ausentes" compara cada arquivo do stash com `chamada:HEAD`: igual ao HEAD, diferente, ou o arquivo nem existe no HEAD.

| Stash | Data | Origem (base) | Arquivos (±) | Iguais/Dif./Ausentes | O que é | Avaliação |
|---|---|---|---|---|---|---|
| `{0}` "20260111_1431" | 2026-01-11 | chamada (`bfd9d9a` pingpong) | 6 (+124/−72) | 0/6/0 | Botão "Teste Áudio" em `Conversa.Tela.Inicial.view.*` (loopback captura→player do pipeline **TCP**), `OutputDebugString` de depuração em `AudioMixer`/`AudioPlayer`/`Conversa.Chamada.pas`, remoção do pingpong do `tcp.pas` (já commitada em `2ceca9f`) e troca de `FStatus` por `FStatusLocal`. Também **corrompe acentos** (comentários com `�`). | **Descartável.** O pipeline TCP foi substituído pelo WebRTC. |
| `{1}` "20250111_1115" (data no nome errada: é 2026) | 2026-01-11 | chamada (`bfd9d9a`) | 14 (+1349/−95) | 9/5/0 | É praticamente o commit `5936215` "Notificação de chamada": `Conversa.Notificacao.Item.{Base,Chamada,Mensagem}`, `Tipos`, `refatoracao_notificacao.md`. Comparado com `5936215`, só muda a cor de fundo do item de chamada (`xFF2D2D2D` × `xFF007FFF`) e 9 linhas de `Conversa.Chamada.pas`. | **Descartável** (já commitado). |
| `{2}` "20251020_0132" | 2025-10-20 | chamada (`e73f85c`) | 5 (+315/−9) | 0/3/2 | Primeiro rascunho de notificação de chamada (`Conversa.Notificacao.Chamada.fmx/.pas`, `TTipoNotificacao`). | **Descartável** (superado por `Notificacao.Item.Chamada`). |
| `{3}` "20250803_1343" | 2025-08-03 | main (`2f49a51`) | 13 (+1614/−338) | 3/8/2 | Rascunho da tela de chamada (`Conversa.Audio.Windows`, `Conversa.Audio`, `Chamada.BarraTitulo`, `Chamada.Participante.view`, `Chamada.view`). Foi commitado depois em `a34eea2` (2025-09-24). | **Descartável.** |
| `{4}` "20250507_2154" / `{5}` "20250507" | 2025-05-07 | main (`b639fab`) | 20 (~+3000/−3000) | 1/9/11 | Camada `api/` abandonada (`Conversa.API`, `Auth`, `Controller`, `Handler`, `Dispositivo`, `Proxy`, `REST`, `entidade/*`) + `REST.API.pas` movido + `Conversa.Tela.Inicial.view.fmx` regravado (5.352 linhas). `{4}` e `{5}` diferem só no dpr/dproj. A pasta `api/` no disco (só `__history`) é resto disso. A abordagem que ficou foi `src/Conversa.Proxy.pas`. | **Descartáveis.** |
| `{6}` "20241107_2017" | 2024-11-07 | alteracao-base (`a8dcfe8`) | 11 (+98/−56) | 0/5/6 | Ajustes na base multiplataforma (Android/TitleBar) e em `Conversa.AES.pas`. | **Descartável** (a branch está abandonada). |
| `{7}` "20241105_1937" | 2024-11-05 | main (`f1ae5dd`) | 44 (+6276/−6397) | 2/25/17 | Mesmo experimento (`src/base/reset/*`, `xml/network_security_config.xml`, `AndroidManifest`, regravação de `Chat.Listagem.fmx`). | **Descartável.** |
| `{8}` (Pull autostash) | 2024-09-19 | main (`d638318`) | 7 (+5883/−348) | 1/6/0 | `.fmx` regravados, ícone novo. | Descartável. |
| `{9}` "20240830_1910" | 2024-08-30 | main | 4 | 0/4/0 | Notificação (versão antiga) + dproj. | Descartável. |
| `{10}` (autostash) | 2024-08-29 | main | 5 | 0/5/0 | Regravação de `.fmx` (escala/estilo). | Descartável. |
| `{11}`, `{12}` | 2024-08-28 | main | 3–4 | 0/2/1–2 | `Conversa.Dados`/`Chat` + marcador do **Syncthing** (`bin/.stfolder/...`) e `bin/log.txt`. | Descartáveis. |
| `{13}` (autostash) | 2024-07-29 | main | 10 (+483/−105) | 0/6/4 | `Conversa.Dados.dfm`, `src/chat/mensagem/*` (units que não existem mais). | Descartável. |
| `{14}` "20240727_1336" | 2024-07-27 | main | 25 (+10403/−826) | 1/15/9 | FormularioBase/Chat/mensagem + `bin/teste.txt` (7.956 linhas de log) + `localdev.bat`. | Descartável. |
| `{15}`, `{16}`, `{19}` | 2024-07-13 a 07-26 | main | 10–12 | 0/4–6/6 | `bin/localdev.bat` (`xcopy` do exe para `bin-2`/`vanessa`), `bin/teste.txt`, temas `.pss`, `Conversa.Windows.Utils`. | Descartáveis. |
| `{17}`, `{18}`, `{20}` (autostash) | 2024-07-13 a 07-17 | main | 4–8 | 0/4–7/0–1 | `PascalStyleScript.pas` (+501), `default.pss`, dproj. | Descartáveis. |
| `{21}`, `{22}` | 2024-06-28 / 07-02 | main (`a798267`) | 21–26 | 2/12–14/7–10 | Rascunho inicial de chamada (`Conversa.Conexao.pas` 466, `src/Tipos.pas`) e, em `{21}`, **cópia de `src/fmx/FMX.Platform.Win.pas`** da Embarcadero. | Descartáveis. |
| `{23}` (autostash) | 2024-06-24 | main | 9 | 0/9/0 | Login/Chat/Principal antigos. | Descartável. |
| `{24}` "20240527_2021", `{26}` "20240519_1531" | 2024-05 | main | 19–31 | 2/6–12/11–17 | Estrutura antiga (`src/conversas/*`, `Conversa.Desktop.view`, `Win32/Debug/tema/*`). `{24}` traz `src/fmx/FMX.Platform.Win.pas` (4.646 linhas, © Embarcadero). | Descartáveis. |
| `{25}` (autostash) | 2024-05-23 | main | 8 | 2/5/1 | Login/Dados (`.dfm`) da época VCL→FMX. | Descartável. |

**Conclusão:** nenhum stash contém trabalho que não esteja no HEAD ou que ainda faça sentido (a maior parte é anterior à migração para WebRTC e ao servidor Bun). Uma varredura por IPs, senhas e tokens nos 27 não achou nada sensível. Recomendação: exportar a lista (`git stash list > ...`), se quiser registro, e limpar.

### 1.4 Alterações *staged* (`git diff --cached`: 2 arquivos, +15/−7)

**`Conversa.Dados.pas` (`TDados.IniciarMonitoramento`, `:420-450`)**

| Antes (HEAD) | Depois (staged) | Por quê / efeito |
|---|---|---|
| `URI.Scheme := 'ws';` | `if SameText(URI.Scheme,'https') then URI.Scheme := 'wss' else URI.Scheme := 'ws';` (`:433-436`) | Passa a usar TLS quando o REST é `https`. |
| `URI.Port := 8000 + URI.Port;` | (removido) | Antes, o socket ficava em "porta REST + 8000" (ex.: REST `:90` → WS `:8090`; `:1090` → `:9090`), padrão do servidor Delphi antigo. Agora usa a **mesma porta** do REST/proxy. |
| (Path herdado do Host, ex. `/api/`) | `URI.Path := '/ws/';` (`:437`) | Alinha com o servidor atual: `conversa/src/websocket.ts:53-56` registra `.ws('/ws/')` na mesma porta da API, e a 1ª mensagem é `{tipo:1, token}`, que o cliente já envia (`:443-449`; `TSocketMessageType.Login = 1` em `src/Conversa.Tipos.pas:19`). |
| comentário "Inicia WebSocket" | comentário de 4 linhas (`:428-431`) | Documenta que o `Host` precisa apontar para o proxy (ex. `https://host:4430/api`). Avisa que um certificado *self-signed* "pode exigir confiança". O comentário diz "em vez de ws://host:9090" (o código antigo era `8000+porta`). |

Riscos da mudança (não confirmados em execução):

1. Com `https`, o `TBirdSocketClient` cria um `TIdSSLIOHandlerSocketOpenSSL` (`lib/bird-socket-client/Bird.Socket.Client.pas:263-271`). O Indy do Delphi 12 usa OpenSSL **1.0.2** (`libeay32.dll`/`ssleay32.dll`). Essas DLLs **não estão em `bin/`, nem em `System32`/`SysWOW64`, nem no PATH**. A configuração local (`bin/Conversa/conversa.json`, ignorado) usa `Host = https://localhost:4430/api/`, então o socket provavelmente falha com "Could not load SSL library". Isso impede a entrega de mensagens e de chamadas em tempo real.
2. O handler não valida o certificado e aceita TLS 1.0/1.1 (`:269`).
3. Clientes ainda configurados para o servidor Delphi antigo (`http://host:90`) deixam de conectar (`ws://host:90/ws/`). Era o esperado, porque o servidor mudou.

**`src/chamada/Conversa.Chamada.WebRTC.pas` (só comentário de cabeçalho, `:12-29`)**

- "Arquivos que DEVEM ser copiados…" vira "Stack WebRTC (JA presente em conversa-webrtc/ e incluida no Conversa.dproj)". Está correto: os 8 bindings estão no dpr (`Conversa.dpr:57-65`).
- `Screen.Capture.pas` passa a ser descrito como captura de **tela** ("webcam ainda NAO implementada").
- A responsabilidade dos eventos 51–55 é corrigida: eles são tratados por `Conversa.Chamada.pas` (`ProcessarSocket`, `:80`), chamado de `TDados.NotificacaoSocket`. **Registra que `VideoAtivado (56)` não tem handler.** Confirmado: o símbolo só aparece na declaração `src/Conversa.Tipos.pas:35` e nesse comentário.

As datas casam com o build do IDE: `Conversa.Dados.pas` foi modificado em 2026-06-27 20:50, `Conversa.Chamada.WebRTC.pas` em 20:51, e `bin/Conversa.exe` + 112 `.dcu` foram gerados às 20:56. A árvore staged **compilou** (em Win32, §6).

### 1.5 Unstaged, não rastreados e ignorados

- **Unstaged:** nenhum (`git diff --stat` vazio).
- **Não rastreados:**

| Caminho | Tamanho | Observação |
|---|---|---|
| `bin/avcodec-62.dll`, `bin/avutil-60.dll`, `bin/swresample-6.dll`, `bin/swscale-9.dll`, `bin/pion_whep.dll` | 133 MB no total | Necessárias em runtime (§5), mas **nem versionadas nem ignoradas**: o `.gitignore` da raiz não tem `*.dll`. Um `git add .` versionaria 133 MB, e o `avcodec-62.dll` (97,6 MB) está colado no limite rígido de 100 MB do GitHub. |
| `docs/todo.md` | 14 KB, 249 linhas | Revisão de 2026-06-27 dos docs (§8). |
| `docs/historico/` | 911 B | Criado durante a auditoria por outro processo. |

- **Ignorados (164 entradas):**

| Item | Tamanho | O que é |
|---|---|---|
| `Android64/Debug/*.dcu, *.o` | **211 MB** | Saída de um build Android antigo. Inútil. |
| `conversa-webrtc/bin/` | **260 MB** | FFmpeg completo (inclui `avdevice`, `avfilter`, `avformat`, `ffmpeg.exe`, `ffplay.exe`, `ffprobe.exe`, que o app não usa) + `pion_whep.dll`. É o `.gitignore` de `conversa-webrtc` que ignora. |
| `bin/Conversa.exe` / `bin/Conversa.rsm` | 46,5 MB / 84,6 MB | Saída do build (Win32 de 06-27; `.rsm` do Win64 de 04-26). |
| `bin/dcu/` | 6,1 MB, 133 `.dcu` | Saída das units: 112 de 06-27, o resto de builds antigos (até 2025-05). |
| `.dcu`/`.o` espalhados em `src/` e `lib/` (fora de `bin/dcu`) | **106 arquivos, 57 MB** | Restos da época em que não havia `DCC_DcuOutput` (inclui `.o` de Android). |
| `__history/` | **50 pastas, 1.850 arquivos, 37 MB** | Backups do IDE. `__recovery/` está vazio. |
| `Serializer/` | 6,8 MB | Projeto órfão `ConversaSerializers`: só `.exe`, `.dcu`, `.res`, `.identcache`, `.dproj.local` e `__history` do `.dpr`. **O `.dpr` e o `.dproj` não existem.** |
| `api/` | 195 KB | Só `__history` da camada `api/` abandonada (stash `{4}`/`{5}`). |
| `src/chat/mensagem/` | 2,1 MB | Só `__history` de units apagadas (`Mensagem.*`). |
| `bin/Conversa/` | ~0,9 MB | Dados do usuário de dev: `conversa.json`, `conversa-.json` (host, usuário, **senha cifrada**, DispositivoId) e `anexos/`. Está ignorado só por acaso, pelo `*.json` e pelo `anexos`. |
| `bin/clipboard/` | 1,1 MB | 24 PNGs colados no chat (ignorados pelo `*.png`). |
| `bin/bin-2/tema`, `bin/dcp` | vazios | Restos. |
| `teste/dcu`, `teste/exe` | 0,5 MB / 17 MB | Saída do projeto `teste/Exemplo`. |
| `Conversa.dproj.local`, `Conversa.identcache`, `Conversa.res`, `Conversa.dres`, `ConversaResource.rc`, os mesmos de `TesteWebRTC`/`Exemplo` | — | Corretamente ignorados. |
| `.claude/settings.local.json` | 530 B | Ignorado pelo `*.json`/`*.local`, **não versionado**. Contém só uma permissão `git add`/`git commit` com a mensagem do `ebe5cb9`. |
| `docs/contrato/openapi.json` | 42 KB | Criado durante a auditoria. **Ignorado pelo `*.json`**, ou seja, o contrato não poderia ser versionado sem ajustar o `.gitignore`. |

O disco do repositório ocupa **876 MB** (fora o `.git`). Os arquivos versionados somam **29 MB**.

### 1.6 Últimos 15 commits (`git log --stat -15`)

| Commit | Data | Resumo |
|---|---|---|
| `4759ba5` | 2026-04-26 | **WebRTC (áudio + vídeo) via MediaMTX.** 37 arquivos, +8.486/−179. Cria `conversa-webrtc/` (projeto `TesteWebRTC` + bindings Pion/FFmpeg, encoders H264/Opus, `Screen.Capture`, `Mic.Capture`, `pion/main.go` 714 linhas, 4 docs `DOC_*.md`, `whep-viewer-spec.md` 1.523 linhas) e `src/chamada/Conversa.Chamada.WebRTC.pas` (471). Cria `src/Conversa.Proxy.Extras.pas` (533), **que nunca foi referenciado**. Reescreve `Conversa.Chamada.pas` (262 linhas alteradas) e adiciona `MediaMtxBase` às configurações e os eventos 51–56 aos tipos. Não enviado. |
| `ebe5cb9` | 2026-02-03 | fix: design do item de chamada (1 `.fmx`). |
| `784c989` | 2026-02-02 | fix: campo de hora da chamada (1 linha). |
| `3d57153` | 2026-02-02 | Histórico de chamadas: `Chamada.Detalhe`, `Chamada.Listagem(.Item)`, endpoints em `Proxy`/`Proxy.Tipos` (13 arquivos, +1.155). |
| `50724b7` | 2026-01-29 | "QOS no pacote de áudio" em `lib/tcp.pas` (hoje código morto). |
| `bb6c031` | 2026-01-21 | Waveform: `Conversa.Chamada.Waveform.pas`, `AudioTypes`, `docs/waveform-spec.md` (+439). |
| `e7aed82` | 2026-01-15 | Mute (+22). |
| `3b73c9d` | 2026-01-14 | Tipos de mensagem (±2). |
| `f2442c7` | 2026-01-12 | Tela "Sobre" (+206). |
| `a084ef2` | 2026-01-11 | Remove código de teste (`Dados` −3). |
| `5936215` | 2026-01-11 | Notificação de chamada: `Notificacao.Item.{Base,Chamada,Mensagem}`, `Tipos`, `refatoracao_notificacao.md`, `docs/ALTERACOES_TCP_RECONEXAO.md` (+1.358/−100). |
| `34ae54b` | 2026-01-11 | Validação de status (1 linha). |
| `2ceca9f` | 2026-01-11 | Remove o pingpong de `tcp.pas` (−53). |
| `bfd9d9a` | 2026-01-10 | Pingpong de conexão (+50). |
| `1baab7d` | 2026-01-10 | **Chamada por áudio TCP:** `lib/audio/*` (Capture, Mixer, Player, Types) e `lib/tcp.pas` (434). Substituída pelo WebRTC em abril; restos mortos em §4.3. |

As mensagens são curtas e em português, com alguns prefixos `feat:`/`fix:` recentes. Os commits misturam código, `.dproj` e `.fmx` regravados pelo IDE, o que deixa os diffs grandes e ruidosos.

---

## 2. Lixo e artefatos

### 2.1 Versionado que não deveria estar (ou que está sobrando)

| Item | Tamanho | Problema | Ação sugerida |
|---|---|---|---|
| `bin/sk4d.dll` | 18,96 MB (×2 versões no histórico, ~37 MB no `.git`) | Binário **x86**, idêntico byte a byte ao `Studio\23.0\bin\sk4d.dll` do Delphi 12.1, **sem a assinatura Authenticode da Idera** (9 bytes diferentes no prefixo comum). Redundante, porque vem com o Delphi, e **errado para Win64** (§5). | Tirar do Git; copiar no build o `bin64\sk4d.dll` (ou ativar o Skia do Delphi). |
| `src/chat/chat/skia/**` (6 units, 31.829 linhas) | ~1,4 MB | Skia4Delphi **6.2.0** vendorizado. O Delphi 12.1 já traz o 6.1.0 (§4.4). **Falta o arquivo de licença** (BSD/MIT exigem o texto). | Remover e usar o Skia do Delphi, ou manter com LICENSE e justificativa. |
| `src/visualizadormidia/ImageViewerFrame.fmx` | **4,9 MB / 66.314 linhas** | `ivImageViewer.Bitmap.PNG` traz um PNG **1920×1200** gravado em tempo de design (`:23`). Vai para dentro do exe. | Limpar o `Bitmap` no designer. |
| `Teste.Proxy.pas` | 13 linhas | Classe vazia, fora do dpr. | Apagar. |
| `teste/` (Exemplo VCL + cópias de `Conversa.Proxy*`, `Eventos`, `REST.API`, `socket/GenericSocket*`) | 2.584 linhas | Sandbox de maio/2025 da refatoração do Proxy. As cópias **divergiram**: `Conversa.Proxy` tem 385 linhas diferentes e `Proxy.Tipos` 135. | Apagar (está no histórico). |
| `conversa-webrtc/Inicio.view.*`, `Whip.view.*`, `TesteWebRTC.dpr/.dproj` | ~1.800 linhas + dproj de 1.025 | Aplicativo de teste do WebRTC. Os bindings do mesmo diretório **são usados** pelo app principal (pasta mista). | Separar os bindings (ex. `lib/webrtc/`) do app de teste. |
| `conversa-webrtc/.gitignore` | — | Copiado de **outro projeto**: tem regras como `LOJAS/MD006/PROXY/DS\.Proxy\.pas` e `MATRIZ/MD009/...`. | Limpar. |
| `conversa-webrtc/bin/pion_whep.h` | 3,4 KB | Header gerado pelo `go build`, versionado. A DLL que ele descreve não é versionada. | Coerente só se a DLL também for. Decidir. |
| `src/chat/chat/frames/chat.anexo.fmx` | — | `.fmx` **sem `.pas`** (órfão). | Apagar. |
| `src/notificacao/Conversa.Notificacao.Item.pas/.fmx` | 239 linhas | O `refatoracao_notificacao.md` diz que foi **renomeado** para `Item.Mensagem`, mas o antigo continuou versionado (morto). | Apagar. |
| Units mortas próprias (§4.3) | 2.316 linhas | Incluem `Conversa.Proxy.Extras.pas` (534, do HEAD), `lib/tcp.pas` (442), `src/chamada/Conversa.Audio*.pas` (451), `lib/audio/AudioCapture`/`AudioPlayer` (394). | Apagar ou integrar. |
| DCPcrypt completo (`lib/AES/Ciphers`, `Hashes`) | 25 units mortas, 8.570 linhas + `.inc` | Só Rijndael + base64 + blockciphers são usados. | Trocar pelo `System.Hash`/AES do RTL, ou podar. |
| `res/nova_mensagem.wav` | — | Legítimo, mas fica embutido 2 vezes: `RcItem` (`Conversa.dproj:371`) e `DeployFile` (`:429-440`). | Escolher um. |
| `bin/tema/*.pss` | 6 KB | Recurso de runtime dentro da pasta de saída, carregado por caminho **relativo ao diretório atual** (`src/pss/PascalStyleScript.pas:148`). | Mover para `res/` e embutir, ou resolver pelo caminho do exe. |

**O que o pedido presumia mas não confere:** `.dproj.local`, `.identcache`, `.res`, `.dres` e `.claude/settings.local.json` **não são versionados** (estão no `.gitignore`). O único binário de build versionado é `bin/sk4d.dll`. O `Conversa_Icon.ico` (255 KB) e o `.wav` são legítimos.

### 2.2 Pastas sem uso no disco

| Pasta | Situação |
|---|---|
| `Android64/` | 211 MB de `.dcu`/`.o`, ignorada. Resto da plataforma Android, que continua marcada no dproj (§4.1). |
| `api/` | Só `__history` (ignorado). Resto dos stashes `{4}`/`{5}`. |
| `Serializer/` | Projeto sem fonte (ignorado). |
| `teste/` | Versionada, sandbox (§2.1). |
| `__history/`, `__recovery/` | Ignorados; 37 MB. |
| `bin/bin-2/`, `bin/dcp/` | Vazias. |
| `src/chat/mensagem/` | Só `__history`. |

### 2.3 `.gitignore` (raiz, 45 linhas, CRLF)

Cobre os binários do Delphi (`*.exe`, `*.dcu`, `*.o`, `*.res`, `*.dres`, `*Resource.rc`, `*.local`, `*.identcache`, `__history/`, `__recovery/`, `*.~*`), além de `anexos`, `*.json`, `*.png` e `bin/log.txt`.

**Falta:**

- `*.dll` (ou `bin/*.dll`), para evitar commitar 133 MB por acidente (hoje elas aparecem como `??`).
- Pastas de saída explícitas: `bin/dcu/`, `bin/dcp/`, `bin/Conversa/` (dados do usuário com senha cifrada) e `bin/clipboard/`. Hoje são ignoradas por extensão, por acaso.
- `Android64/`, `Win32/`, `Win64/` e `__astcache/` (o cache do LSP do Delphi 12).
- `*.log` (a `pion_whep.dll` grava `pion_whep.log` ao lado do exe, `conversa-webrtc/pion/main.go:50-62`) e `log.txt` em qualquer pasta (o `Conversa.Log` grava em `PastaDados`).
- `.claude/` explícito, `*.deployproj` (o dproj importa `Conversa.deployproj` se existir, `Conversa.dproj:1409`) e `Serializer/`.

**Regras amplas demais:**

- `*.json` bloqueia `docs/contrato/openapi.json` e qualquer fixture ou exemplo de configuração (`conversa.example.json`).
- `*.png` bloqueia qualquer imagem de interface ou documentação. É por isso que os ícones acabam embutidos como hexadecimal nos `.fmx`.

### 2.4 `.claude/settings.local.json`

Não é versionado (ignorado por `*.json` e `*.local`). O conteúdo é só uma permissão de `git add`/`git commit` com a mensagem do `ebe5cb9`. Sem segredos.

---

## 3. Segredos e endereços fixos

| Local | Tipo | Valor (mascarado quando sensível) | Risco |
|---|---|---|---|
| `lib/AES/Conversa.AES.pas:30`, `:51` | IV constante | `'1234567890123456'` | **Alto, para a senha guardada.** AES-256-CBC com IV fixo. |
| `lib/AES/Conversa.AES.pas:31-37`, `:55-59` | Derivação da chave | chave = `GetWin32_BaseBoardInfo` (serial da placa-mãe via WMI) + salt (GUID); o **salt é gravado junto do texto cifrado** (`Base64(salt:cifra)`) | **Alto.** Qualquer processo do usuário obtém o serial pelo WMI, então é ofuscação. Placas com serial vazio ou "To be filled by O.E.M." deixam a chave = salt (decifrável só com o arquivo). O certo seria usar a DPAPI (`CryptProtectData`) ou não guardar a senha (usar refresh token). |
| `Conversa.Login.pas:69`, `:82` + `src/configuracoes/Conversa.Configuracoes.pas:16`, `:74` | Senha persistida | `Configuracoes.Senha := Encrypt(edtSenha.Text)` → `conversa.json` | Médio/alto, ver acima. O arquivo fica em `<exe>\Conversa\` se existir, senão em `%APPDATA%\Conversa\` (`Configuracoes.pas:41-47`). Em dev existe `bin/Conversa/conversa.json` (ignorado) com `Host`, `Usuario` e `Senha` cifrada de 88 caracteres. **Valores não copiados.** |
| `src/configuracoes/Conversa.Configuracoes.pas:52`, `:67` | URL padrão | `http://localhost:8889` (`MediaMtxBase`) | Médio. Aponta para a **porta direta do MediaMTX, em HTTP**, contornando o proxy `/webrtc`. No `docker-compose` do servidor a 8889 só escuta em `127.0.0.1` (`conversa/docker-compose.yml:124`), então fora da máquina do servidor isso não funciona. |
| `src/chamada/Conversa.Chamada.WebRTC.pas:66` | IP de LAN em comentário | `http://192.168.2.4:8889` | Baixo. |
| `src/chamada/Conversa.Chamada.WebRTC.pas:180`, `:262` | Padrão de URL | `%s/call-%d-u-%d/whip` e `/whep` | Médio. Paths previsíveis, sem token (`:187-189` passam *bearer* vazio e `FAuthUser`/`FAuthPass`). |
| `Conversa.Dados.pas:432-438` (staged) | Derivação de URL | `ws(s)://<host REST>:<porta>/ws/` | Ver §1.4 (OpenSSL ausente, TLS sem verificação). |
| `lib/bird-socket-client/Bird.Socket.Client.pas:267-271` | TLS | TLS 1.0/1.1/1.2, sem `VerifyMode`/`OnVerifyPeer` | Médio. Aceita qualquer certificado (MITM). |
| `conversa-webrtc/pion/main.go:169`, `:353` | ICE | `ICEServers: []` (sem STUN/TURN) | Médio. Só funciona com rota direta até o MediaMTX (LAN/localhost). |
| `conversa-webrtc/pion/main.go:268`, `:457` | HTTP | `(&http.Client{}).Do(req)` sem timeout | Baixo/médio. Pode travar o WHIP/WHEP indefinidamente. A validação TLS fica ligada (padrão), então um MediaMTX atrás de proxy com certificado *self-signed* não conecta. |
| `conversa-webrtc/pion/main.go:56`, `:62` | Caminho absoluto | `C:\pion_whep.log` (fallback) | Baixo. Gravar na raiz do C: costuma falhar sem privilégio. |
| `conversa-webrtc/Inicio.view.fmx:110`, `:263` | Senha de teste | `'senha123'` em `TEdit` (usuário MediaMTX do app de teste) | Baixo. Credencial de exemplo no repositório público. Confirmar que não é usada em nenhum MediaMTX real. |
| `conversa-webrtc/Inicio.view.fmx:37`, `:190`, `Whip.view.fmx:30`; `Inicio.view.pas:275`; `Whip.view.pas:123-125` | Host/esquema | `localhost`, `http://` fixo | Baixo (app de teste). |
| `Conversa.Tela.Inicial.view.fmx:2462`, `src/chat/Conversa.Chat.Listagem.fmx:2511`, `src/base/Conversa.FormularioBase.fmx:535` | Caminho absoluto da máquina | `C:\Users\danie\Downloads\conversa2.png`, `C:\Users\danie\Desktop\GIT\log-o.png` | Baixo. Só metadado de design (a imagem está embutida), mas expõe o nome do usuário. |
| `conversa-webrtc/pion/DOC_COMPILACAO.md:65`, `:78` | Caminho absoluto | `D:\testewebrtc\pion` | Baixo. O caminho está errado para este repositório. |
| `src/pss/PascalStyleScript.pas:148` | Caminho relativo ao diretório atual | `'.\tema\default.pss'` | Baixo/médio. Se o exe for aberto de outro diretório (atalho, instalador), o tema não carrega. |
| `teste/Conversa.Proxy.pas:98`, `teste/Exemplo.Principal.pas:70` | Host/porta | `http://localhost:90`, `localhost:55888` | Baixo (sandbox). |
| `Conversa.WMI.pas:87` | WMI | `winmgmts:\\localhost\root\CIMV2` | Nenhum. |
| `src/sobre/Conversa.Sobre.pas:40` | Versão | `'0.0.0.0'` de fallback | Nenhum. |

**Não foram encontrados** chaves de API, tokens ou senhas reais em arquivos versionados, nos 27 stashes ou no `.claude/`. Os e-mails dos autores aparecem no histórico do GitHub (público) e foram omitidos aqui.

**Licença (também é "conteúdo indevido"):** o histórico público contém `src/fmx/FMX.Platform.Win.pas` (© Embarcadero, "All rights reserved"), adicionado em `1712a09` (2024-05-28) e removido em `428d04e` (2024-07-26). Redistribuir o fonte do RTL viola o EULA do Delphi. Só uma reescrita de histórico remove de fato. Fica registrado para decisão.

---

## 4. Projeto

### 4.1 `Conversa.dproj`

| Item | Valor | Evidência | Comentário |
|---|---|---|---|
| ProjectVersion / Framework | 20.1 (Delphi 12) / FMX | `:4-5` | Mudou de 19.5 (Delphi 11) para 20.1 em `acf0be2` (2024-09-19). |
| Plataforma padrão | **Win32** | `:8` | **Incompatível com as DLLs x64 de WebRTC** (§5). Deveria ser Win64. |
| Plataformas habilitadas | Android, Android64, Win32, Win64 (`TargetedPlatforms=32787`) | `:9`, `:1398-1403` | Android é resto (a pasta `Android64/` tem 211 MB). Há permissões Android no `Base`: `AUP_CALL_PHONE`, localização, câmera, `READ_PHONE_STATE`… (`:92-99`). |
| Configurações | Debug (`Cfg_1`) e Release (`Cfg_2`) | `:37-81` | — |
| Saída do exe | `.\bin` (**todas** as plataformas e configurações) | `:85` | Win32 e Win64, Debug e Release **sobrescrevem o mesmo `bin\Conversa.exe`**. Não dá para saber qual exe está lá sem olhar o PE. |
| Saída das units | `.\bin\dcu` (todas) | `:84` | Mistura `.dcu` de Win32 e Win64 na mesma pasta, o que força recompilação total a cada troca e mantém `.dcu` velhos (133 arquivos para 112 units). |
| DCP | `.\bin\dcp` | `:107` | Vazio. |
| Search path | `lib\AES`, `lib\AES\Ciphers`, `lib\AES\Hashes`, `lib\popupmenu`, `lib\windows`, `lib`, `src\chat\chat`, `src\chat\chat\frames`, **`src\chat\chat\skia`**, **`src\chat\chat\skia\FMX`**, `lib\bird-socket-client`, `lib\audio`, `src\sobre`, `src\chamada`, `conversa-webrtc` | `:103` | 57 das 112 units compiladas entram **só pelo search path** (não estão no dpr). As pastas do Skia fazem as cópias vendorizadas terem prioridade sobre as do Delphi. |
| Defines | `DEBUG` (Debug), `RELEASE` (Release) | `:188`, `:219` | Nenhum define próprio. |
| Debug | `DebugDCUs`, `Optimize=false`, stack frames, debug info no exe, **range e overflow checking ligados**, RemoteDebug ligado (desligado só em Win32) | `:188-195`, `:208` | Por isso o Win64 Debug gera um `.rsm` de 84 MB. |
| Release | Sem debug info nem símbolos locais | `:217-221` | Sem otimizações extras. Ninguém usa (não há pipeline de release). |
| PreBuildEvent | `taskkill /f /t /im Conversa.exe` | `:104-106` (Base) e repetido nas 8 combinações de configuração e plataforma (`:1411-1467`) | **Mata qualquer processo `Conversa.exe` da máquina** a cada build, inclusive uma instância "de produção" do usuário. Executou na tentativa de build desta auditoria (nenhum processo encontrado). |
| VersionInfo | `FileVersion=1.0.0.0; ProductVersion=1.0.0.0`; CompanyName vazio; Locale **1033 (en-US)** | `:166-167`, `:179-180` | Versão fixa, sem `AutoGenVersion`. A tela "Sobre" (`src/sobre/Conversa.Sobre.pas:32-50`) sempre mostra 1.0.0.0. As tags `v0.0.x` não se refletem. O locale deveria ser 1046 (pt-BR). |
| Ícone | `Conversa_Icon.ico` | `:172`, `:185`, `:212` | OK. No `Base` ainda é o ícone padrão do Delphi (`:100`). |
| Manifest / DPI | `$(BDS)\bin\default_app.manifest`; DPI `none` no Base, **PerMonitorV2** em Debug e Release | `:168`, `:171`, `:181`, `:184`, `:209`, `:215`, `:224`, `:227` | Na prática é PerMonitorV2. Sem manifest próprio (nome, `requestedExecutionLevel` padrão). |
| Pacotes de runtime | `DCC_UsePackage` lista os pacotes padrão do IDE (+ `HGMComponents` em Win32, `:162`), mas **`UsePackages` não está ligado** | `:110`, `:136`, `:162`, `:175` | Exe monolítico. `HGMComponents` é um pacote de terceiros fantasma, inofensivo mas confuso. |
| Componentes de terceiros | **Nenhum.** Todos os `.fmx` usam só componentes padrão do FMX (`TLayout`, `TText`, `TRectangle`, `TPath`, `TImageViewer`…) e frames do próprio projeto | grep nos `.fmx` | O único código de terceiros é vendorizado (Skia, DCPcrypt, Bird.Socket.Client) ou vem com o Delphi (Indy). |
| Recursos | `RcItem res\nova_mensagem.wav` (RCDATA `nova_mensagem`) → gera `ConversaResource.rc`/`Conversa.dres` (ignorados, regenerados pelo MSBuild: confirmado) | `:371-375`; `Conversa.dpr:4` | OK. |
| Deploy | Entradas só para **Win32** (`bin\Conversa.exe` e o `.wav`) + o padrão do IDE (iOS/OSX/Android) | `:401-440` | **Nenhuma DLL no deploy**, nada para Win64. O "Deploy" do IDE não gera um pacote que funcione. |
| Imports | `CodeGear.Delphi.Targets`, `UserTools.proj` (do usuário), `Conversa.deployproj` (se existir) | `:1407-1409` | — |

### 4.2 `Conversa.dpr`

- `Conversa.dpr:4` `{$R *.dres}`, `:7` **`MidasLib`** (liga o midas estático). Esse vínculo só se justifica por `Data.DB` e `Datasnap.DBClient` no `uses` de `Conversa.Dados.pas:14-15`, mas **nenhum `TClientDataSet` é usado**. É uma dependência morta que aumenta o exe.
- **55 units do projeto** no dpr (`:11-65`) + 4 do RTL. O fecho transitivo (resolvido com o search path, os namespaces do dproj e `{$IFDEF}` avaliado para `MSWINDOWS`/`WIN64`) dá **112 units compiladas**: 55 do dpr + 57 só pelo search path. Entre essas 57 estão todo o `src/chat/chat/**`, o Skia, o DCPcrypt usado, o Bird socket, `lib/popupmenu`, `lib/windows`, `lib/audio/AudioMixer`/`AudioTypes`, `Chamada.Detalhe`/`Listagem`/`Waveform` e `Conversa.Sobre`.
- **Units do dpr que nenhuma outra usa:** só `Conversa.Inicializacoes.pas`, o que é normal porque o `begin…end` do dpr chama `Iniciar`/`Finalizar` (`:72`, `:84`).
- Cosmético: `Application.Run;` sem indentação (`:79`); comentário "Eduardo - 03/03/2024" (`:1`).
- **Conflito de nome:** existem **duas units `Conversa.Audio`**: `Conversa.Audio.pas` (raiz, no dpr) e `src/chamada/Conversa.Audio.pas` (morta, mas dentro de uma pasta do search path). Hoje o `in '...'` do dpr resolve. Um rename ou uma remoção da linha do dpr troca a unit sem aviso.

### 4.3 Código morto (units versionadas fora do fecho de compilação)

São 51 arquivos `.pas` no total. Vários casos foram conferidos também com grep.

| Grupo | Arquivos | Linhas | Itens |
|---|---|---|---|
| **Próprio** | 11 | **2.316** | `src/Conversa.Proxy.Extras.pas` (534; criado no HEAD, "paridade com o conversa-web", **nunca incluído no dpr nem usado**) · `lib/tcp.pas` (442; áudio TCP) · `src/chamada/Conversa.Audio.Windows.pas` (360) + `src/chamada/Conversa.Audio.pas` (91) · `lib/audio/AudioCapture.pas` (182) + `lib/audio/AudioPlayer.pas` (212) (no WebRTC, `TAudioPlayer` vem de `conversa-webrtc/Audio.Player.pas`; `AudioMixer`/`AudioTypes` continuam vivos só por causa do waveform) · `src/notificacao/Conversa.Notificacao.Item.pas` (239) · `src/chat/Conversa.Conteudo.pas` (85) · `src/chat/chat/frames/chat.anexo.item.pas` (93) · `src/chamada/Conversa.Chamada.Participante.Item.pas` (43) · `lib/popupmenu/PopupMenu.Item.Action.Container.pas` (46) |
| DCPcrypt sem uso | 25 | 8.570 | Todas as cifras menos Rijndael; todos os hashes (`haval`, `md4`, `md5`, `ripemd*`, `sha1`, `sha256`, `sha512`, `tiger`). |
| Bird socket | 1 | 13 | `Bird.Socket.Client.Consts.pas`. |
| Sandbox `teste/` + `Teste.Proxy.pas` | 12 | 2.558 | Projeto VCL `Exemplo` e cópias divergentes. |
| Sandbox WebRTC | 2 | 768 | `conversa-webrtc/Inicio.view.pas`, `Whip.view.pas` (só no `TesteWebRTC.dpr`). |
| `.fmx` sem uso | 6 | — | Os `.fmx` das 5 units mortas que têm form + `chat.anexo.fmx` (órfão). |

### 4.4 Skia vendorizado

- **Onde:** `src/chat/chat/skia/System.Skia.API.pas` (6.598), `System.Skia.pas` (13.457), `FMX/FMX.Skia.pas` (6.347), `FMX/FMX.Skia.Canvas.pas` (4.045), `FMX/FMX.Skia.Canvas.GL.pas` (1.159), `FMX/FMX.Skia.Canvas.Metal.pas` (223). Total de 31.829 linhas.
- **Versão:** Skia4Delphi **6.2.0** (`SkVersion = '6.2.0'` em `System.Skia.pas:60`). O Delphi 12.1 instalado traz o **6.1.0** (`source\rtl\common\System.Skia.pas`). A diferença está em ~3.700 linhas do `System.Skia.API.pas` (suporte a `CompilerVersion >= 37` e *static link* em Android/OSX) e em poucas linhas no resto.
- **Uso real:** só `src/chat/chat/frames/chat.conteudo.imagem.pas:11-12` (`FMX.Skia`, `Skia`), para exibir **SVG, GIF, WebP, Lottie e TGS** (`:53-67`). Essas units entram no build pelo search path (o `bin/dcu` tem `System.Skia*.dcu` e `FMX.Skia*.dcu` gerados do fonte vendorizado), então **elas sombreiam o Skia do Delphi**.
- **Carregamento:** dinâmico. `System.Skia.API.pas:4566` faz `SafeLoadLibrary('sk4d.dll')` e chama `Abort` se falhar (`:4569`). Isso acontece no `class constructor TSkObject.Create` (`System.Skia.pas:4131-4134`). O `sk4d.dll` não aparece na tabela de imports do exe (conferido com `tdump`).
- **Por quê:** o Skia entrou em `1e987c7` (2024-09-14, Eduardo, "Adiciona Skia para visualização de outros formatos de imagem"), quando o projeto ainda era Delphi 11 (ProjectVersion 19.5), que não trazia Skia. Depois foi removido (`5793408`, 2025-04-18, Daniel) e recolocado no dia seguinte (`b639fab`, 2025-04-19, Eduardo). A hipótese mais provável, **não confirmada**, é que algum ambiente (IDE de outro desenvolvedor ou Delphi 11) precisava do fonte. No Delphi 12 bastaria usar o Skia embutido ("Enable Skia" no projeto), o que eliminaria o vendor e o `sk4d.dll` versionado.

### 4.5 Projetos auxiliares

| Projeto | O que é | Compila? | Serve para algo? |
|---|---|---|---|
| `conversa-webrtc/TesteWebRTC.dproj` / `.dpr` | App FMX de teste: `Inicio.view` (assina 2 streams WHEP com host/porta/path/usuário/senha) e `Whip.view` (publica tela + microfone por WHIP). Plataforma padrão Win64 (`:8`), `TargetedPlatforms=3` (Win32+Win64), saída em `.\bin\` = `conversa-webrtc/bin/` (onde estão as DLLs, ignoradas). | Não testado (CLI bloqueado). Nunca foi compilado nesta cópia: não há `TesteWebRTC.exe` nem `bin\dcu`. | É útil como banco de testes isolado do WHIP/WHEP. Os bindings são **os mesmos arquivos** usados pelo app principal. |
| `teste/Exemplo.dproj` / `.dpr` | App **VCL** (Win32 só, `:1112-1113`) de maio/2025 que testou a refatoração "Proxy + Eventos" e um `GenericSocket` (cliente/servidor TCP próprio). Saída em `teste/exe` e `teste/dcu` (ignorados; há um exe de 17 MB no disco). | Não testado. As cópias divergiram do `src/`. | **Não.** Valor histórico só. Apagar. |
| `Serializer/` (sem fonte) | Saídas de um `ConversaSerializers.dpr` que não existe mais. | — | Não. |

---

## 5. Dependências em tempo de execução

### 5.1 Como o exe carrega cada coisa

A tabela de imports do `bin/Conversa.exe` atual (Win32, 2026-06-27) foi lida com `tdump -em`. Os imports **estáticos** são: `kernel32`, `user32`, `gdi32`, `msvcrt`, `oleaut32`, `advapi32`, `winhttp`, `ole32`, `winmm`, **`avcodec-62.dll` (12 funções)**, `winspool.drv`, `opengl32`, **`avutil-60.dll` (8)**, **`pion_whep.dll` (7)**, **`swresample-6.dll` (4)**, `shell32`, `comdlg32`, `version`, **`swscale-9.dll` (3)**, `d3d9`, `comctl32`, `URLMON`, `SHFolder`. Os imports **delayed** são `d3d10`/`d3d10_1`/`d3d11`, `gdiplus`, `Shcore`, `Crypt32` e outros do sistema.

Não há `delayed` nem `LoadLibrary` nos bindings próprios: `conversa-webrtc/Pion.Whep.Binding.pas:9`, `:26-71` e `conversa-webrtc/FFmpeg.Binding.pas:9-12`, `:117-242` usam `external '<dll>'`. **Se faltar qualquer uma das 5 DLLs de WebRTC, o exe não abre**, mesmo quem nunca faz chamada.

### 5.2 Tabela de DLLs

| DLL | Arq. | Tamanho | Versão / metadados PE | Origem | Versionada? | Licença provável | Como um clone limpo obtém | Carregamento |
|---|---|---|---|---|---|---|---|---|
| `bin/sk4d.dll` | **x86** | 18.961.920 | Sem VersionInfo; link 2023-10-11; = `Studio\23.0\bin\sk4d.dll` sem a assinatura (a do Delphi está assinada "Idera") | Redist do Delphi 12.1 (Skia m107 / Skia4Delphi 6.x) | **Sim** | BSD-3 (Skia/Google) + MIT (Skia4Delphi) | Vem no clone, **mas só serve para Win32**. Para Win64 é preciso o `Studio\23.0\bin64\sk4d.dll` (x64, 19.870.192 bytes), que não está no repositório. | Dinâmico (`SafeLoadLibrary`, `System.Skia.API.pas:4566`) |
| `pion_whep.dll` | x64 | 19.480.956 | Sem VersionInfo nem timestamp (linker do Go). Strings do binário: **Go 1.26.1**, `github.com/pion/webrtc/v4 v4.0.0`, módulo `pion_whep (devel)` | Compilada de `conversa-webrtc/pion/main.go` (714 linhas) com `go build -buildmode=c-shared` | **Não.** Em `bin/` está *untracked*; em `conversa-webrtc/bin/` é ignorada (as duas cópias são idênticas, SHA-256 `195c9ce6…`) | MIT (Pion) + BSD-3 (Go runtime, `golang.org/x/*`) | Instalar Go ≥ 1.22 (testado 1.26.1) + GCC 64-bit (WinLibs 14), rodar `go build` em `conversa-webrtc/pion` (gera em `conversa-webrtc/bin/`) e **copiar à mão para `bin/`**. O README não diz nada disso. | **Estático** |
| `avcodec-62.dll` | x64 | 97.576.448 | 62.29.101; ProductVersion `N-123777-g53537f6cf5-20260331`; "FFmpeg Project" | **Build nightly (master) do BtbN FFmpeg-Builds**, `win64-gpl-shared` (inferido de `--prefix=/ffbuild/prefix`, `--extra-version=20260331`). A série é **FFmpeg 8.x** (avcodec 62), não a 7.x que os docs citam. | **Não** (untracked; ignorada em `conversa-webrtc/bin`) | **GPL v3+** (`--enable-gpl --enable-version3`, com `libx264`, `libx265`, `libopenh264`, `libopus`, `libvpx`; a string `"GPL version 3 or later"` está no binário) | Download manual, sem versão fixada nem script. O `whep-viewer-spec.md:65-66` manda baixar o **LGPL 7.x**, o que contradiz o que está em uso, e `Video.Encoder.pas:7` exige `libx264`. | **Estático** |
| `avutil-60.dll` | x64 | 2.930.688 | 60.29.100 (mesmo build) | idem | Não | GPLv3 (mesmo build) | idem | Estático |
| `swresample-6.dll` | x64 | 722.944 | 6.4.100 | idem | Não | idem | idem | Estático |
| `swscale-9.dll` | x64 | 12.537.344 | 9.7.100 | idem | Não | idem | idem | Estático |
| `libeay32.dll` / `ssleay32.dll` (OpenSSL **1.0.2**, x64) | — | — | **Ausentes** (não estão em `bin/`, `System32`, `SysWOW64` nem no PATH) | — | — | Licença OpenSSL/SSLeay | Não documentado | Dinâmico (Indy), só para `wss://`/`https` via `TBirdSocketClient` (§1.4) |
| midas | — | — | — | `MidasLib` estático (`Conversa.dpr:7`) | — | Delphi | Não precisa de DLL | Estático |

**Peso total de DLLs para o Win64 funcionar:** cerca de 153 MB (pion 19,5 + FFmpeg 113,8 + sk4d x64 19,9), fora as do OpenSSL. **Sem instalador e sem script** que monte a pasta.

**Fragilidade de ABI:** `FFmpeg.Binding.pas:79` acessa campos de structs do FFmpeg por **offset fixo** (comentário "codec_id @ 24"). Com um build *master*, qualquer troca de versão do FFmpeg pode corromper memória em silêncio. Seria preciso fixar a versão (ex. tag `n8.0.x`) e checar `avcodec_version()` na inicialização.

**Licenciamento, para decidir:** distribuir o Conversa (MIT) com esse FFmpeg GPLv3 coloca a distribuição binária sob as obrigações da GPLv3 (oferta de fonte etc.), além da questão de patentes do H.264/x264. Alternativas: build **LGPL** + `libopenh264` (Cisco) ou o encoder do Windows (`h264_mf`, Media Foundation).

### 5.3 Matriz plataforma × DLL (o problema central)

| | Win32 (padrão do `.dproj`) | Win64 |
|---|---|---|
| `sk4d.dll` em `bin/` (x86) | OK | **Falha.** `SafeLoadLibrary` recusa x86 → `Abort` no class constructor (não confirmado se derruba a inicialização ou só o 1º uso) |
| `pion_whep.dll` + FFmpeg (x64) | **Falha.** O loader recusa a imagem (o próprio `DOC_COMPILACAO.md` cita o `0xc000007b`) e o exe nem abre, porque os imports são estáticos | OK |

O `bin/Conversa.exe` presente hoje é **x86** (PE machine `0x14C`, link 2026-06-28 UTC), ou seja, cai no primeiro caso. **Não executei o app para confirmar** (evitei efeitos colaterais).

### 5.4 Outras dependências externas implícitas

- **MediaMTX** acessível em `MediaMtxBase` (padrão `http://localhost:8889`), sem STUN/TURN.
- **Servidor** REST + WS no `Host` configurado. HTTPS pelo `System.Net.HttpClient` (WinHTTP/SChannel), sem callback de validação, então um certificado *self-signed* precisa estar no repositório de certificados do Windows. Não confirmado neste ambiente.
- **Temas** `.\tema\*.pss` relativos ao diretório atual.
- **WMI** (serial da placa-mãe) para a chave da senha.

---

## 6. Build real

### 6.1 Antes de compilar

- **Destino da saída:** `DCC_ExeOutput=.\bin`, `DCC_DcuOutput=.\bin\dcu`, `DCC_DcpOutput=.\bin\dcp` (`Conversa.dproj:84-85`, `:107`). A pasta `bin/` **não** está ignorada como pasta e contém arquivos versionados (`bin/sk4d.dll`, `bin/tema/*.pss`). Mas tudo o que o build grava tem extensão ignorada: `*.exe`, `*.dcu`, `*.rsm`, `*.map`, `*.drc`, `*.res`, `*.dres`, `*Resource.rc`. **Conclusão: o build só escreve arquivos ignorados, então foi permitido rodar.**
- Espaço livre em C: **13,33 GB** (acima do mínimo de 2 GB).
- Nenhum `Conversa.exe` nem `bds.exe` em execução, o que importa porque o PreBuildEvent faz `taskkill`.
- Snapshot feito: `git status --porcelain` e `--ignored`, hash de `git ls-files -s` (`c056c706…`) e hash de `git diff --cached` (`2913ef00…`).

### 6.2 Execução

```
cmd /c "call "...\Studio\23.0\bin\rsvars.bat" && msbuild Conversa.dproj /t:Build /p:Config=Debug /p:Platform=Win64 /v:minimal"
→ tempo: 1,3 s · código de saída: 0 (!)
  ERRO: o processo "Conversa.exe" não foi encontrado.          ← PreBuildEvent (taskkill)
  This version of the product does not support command line compiling.
```

- Confirmado direto: `dcc64.exe` e `dcc32.exe` sem argumentos imprimem a mesma frase.
- **Edição do Delphi:** registro `HKCU\Software\Embarcadero\BDS\23.0` e `HKLM\...\WOW6432Node\...` → `Edition = Starter`, que é como a **Community Edition** se identifica. `bds.exe` 29.0.51961.7529 = **Delphi 12.1 Athens**. O Delphi 12.2/12.3 e o RAD Studio 13 já existiam, mas a atualização para esta edição não foi confirmada.
- **Não compilou nada.** Erros e warnings: n/d. O `bin/Conversa.exe` não foi tocado (continua com 46.535.522 bytes, 2026-06-27 20:56).
- **O MSBuild devolveu 0 mesmo sem compilar.** Um script de CI ou `.bat` que confie no `errorlevel` vai reportar sucesso falso.
- O passo de recursos rodou antes do compilador e **regenerou** `Conversa.res`, `Conversa.dres` e `ConversaResource.rc` (23:08). Isso confirma que um clone limpo recria esses arquivos ignorados.
- **Win32:** não tentado, pela mesma limitação.
- **`bds.exe -b` (build pelo IDE em lote):** não tentado. Abre a interface gráfica e pode regravar o `Conversa.dproj`, que é versionado.

### 6.3 Depois

`git status --porcelain` está idêntico ao snapshot. Os hashes do índice e do `diff --cached` são os mesmos. **Nenhum arquivo versionado mudou.**

### 6.4 Evidência indireta de compilação (sem warnings)

| Evidência | Conclusão |
|---|---|
| `bin/Conversa.exe` x86, 46,5 MB, 2026-06-27 20:56, e **112 `.dcu` com o mesmo horário** em `bin/dcu`. Os arquivos staged foram modificados às 20:50/20:51. | A árvore atual (HEAD + staged) **compilou e linkou em Win32 Debug** no IDE. |
| `bin/Conversa.rsm` (84,6 MB) de 2026-04-26 22:37. O `.rsm` só é gerado com `DCC_RemoteDebug=true`, que o dproj desliga para Win32 (`:208`) e mantém para Win64 (`:193`). | Houve um build **Win64 Debug** 2 minutos antes do commit `4759ba5` (22:39), ou seja, o HEAD compilou para Win64. |
| `bin/dcu` também tem `.dcu` de 2025-05 a 2026-04. | São `.dcu` velhos, de units que já não existem ou não são mais compiladas. |

### 6.5 O que um clone limpo precisa para gerar um exe que funcione (estado atual)

1. **Delphi 12 Professional ou superior** para compilar por linha de comando ou em CI. A Community só compila no IDE, e a licença dela restringe uso comercial.
2. Trocar a plataforma para **Win64** (a padrão é Win32).
3. Copiar para `bin/`: `sk4d.dll` **x64** (do `bin64` do Delphi; o versionado é x86), `pion_whep.dll` (compilar com Go + GCC), as 4 DLLs do FFmpeg 8.x x64 (baixar o build certo) e, para `https`/`wss`, OpenSSL 1.0.2 x64.
4. Ter `.\tema\*.pss` no diretório de trabalho.
5. Nada disso está no `README.md`.

---

## 7. Métricas

### 7.1 Linhas por categoria (arquivos versionados)

| Categoria | Arquivos | Linhas | Observação |
|---|---|---|---|
| **Próprio `.pas` + `.dpr`** | 107 | **21.268** | 18.952 vivas (96 arquivos) + **2.316 mortas** (11 arquivos, 10,9%). Inclui os 8 bindings vivos de `conversa-webrtc` (1.508). |
| Próprio `.fmx` | 59 | 77.536 | **66.314** só no `ImageViewerFrame.fmx` (PNG embutido). Sem ele são 11.222. |
| Go (`pion/main.go`) | 1 | 714 | Fonte da `pion_whep.dll`. |
| Vendor: Skia4Delphi 6.2.0 | 6 | 31.829 | Duplica o que o Delphi 12 já traz. |
| Vendor: DCPcrypt 2.1 | 30 `.pas` + 15 `.inc` | 10.886 + 3.883 | Vivo: 5 units, 2.321 linhas. Morto: 25 units, 8.570 linhas. |
| Vendor: snippet AES (StackOverflow) | 1 | 157 | `lib/AES/Prism.Crypto.AES.pas`. |
| Vendor: Bird.Socket.Client | 5 | 961 | WebSocket sobre Indy. |
| Dados: tabela de emojis `chat.emoji.pas` | 1 | 5.128 (899 KB) | Gerada de `emoji.json@15.1.0` (`:31`). |
| Sandbox `teste/` + `Teste.Proxy.pas` | 13 | 2.584 | Morto. |
| Sandbox TesteWebRTC (`.pas`/`.dpr`/`.fmx`) | 5 | 792 + 494 | Fora do build principal. |

**Total de linhas próprias:** **21.268** em Pascal (18.952 vivas) + 714 em Go. Somando os `.fmx` próprios sem o PNG, ~11,2 mil. Sem o PNG e sem os vendors, o código próprio é **cerca de 30% do Pascal versionado** (~21 mil de ~70 mil).

### 7.2 Linhas próprias por área (vivas / mortas)

| Área | Arquivos | Vivas | Mortas |
|---|---|---|---|
| `src/chat` (inclui `chat/chat/**` sem o Skia e sem o emoji) | 27 | 4.322 | 176 |
| `src/chamada` | 14 | 2.505 | 491 |
| raiz (`Conversa.Dados`, `REST.API`, `Login`, `Memoria`, `Tela.Inicial`…) | 10 | 2.374 | 0 |
| `conversa-webrtc` (bindings) | 8 | 1.508 | 0 |
| `src/Conversa.Tipos.pas` | 1 | 1.093 | 0 |
| `src/Conversa.Proxy.pas` | 1 | 939 | 0 |
| `lib/popupmenu` | 6 | 890 | 45 |
| `src/notificacao` | 7 | 882 | 238 |
| `src/pss` | 1 | 789 | 0 |
| `src/base` | 2 | 574 | 0 |
| `src/visualizadormidia` | 3 | 544 | 0 |
| `lib/windows` | 3 | 491 | 0 |
| `lib/audio` | 4 | 431 | 392 |
| `src/Conversa.Proxy.Extras.pas` | 1 | 0 | 533 |
| `lib/tcp.pas` | 1 | 0 | 441 |
| demais (`novo`, `principal`, `configuracoes`, `contatos`, `conexao`, `sobre`, `Serializer`, `Evento.Base`, `Eventos`, `Loading`, `DeviceInfo`, `Utils`, `AES`) | 15 | ~1.600 | 0 |

### 7.3 As 15 maiores units próprias

| # | Linhas | Unit | Situação |
|---|---|---|---|
| 1 | 1.093 | `src/Conversa.Tipos.pas` | viva |
| 2 | 939 | `src/Conversa.Proxy.pas` | viva |
| 3 | 789 | `src/pss/PascalStyleScript.pas` | viva |
| 4 | 768 | `REST.API.pas` | viva |
| 5 | 683 | `src/chamada/Conversa.Chamada.pas` | viva |
| 6 | 659 | `Conversa.Dados.pas` | viva |
| 7 | 533 | `src/Conversa.Proxy.Extras.pas` | **morta** |
| 8 | 495 | `src/base/Conversa.FormularioBase.pas` | viva |
| 9 | 473 | `src/chamada/Conversa.Chamada.WebRTC.pas` | viva |
| 10 | 452 | `src/chat/chat/chat.visualizador.pas` | viva |
| 11 | 441 | `lib/tcp.pas` | **morta** |
| 12 | 397 | `src/chat/Conversa.Chat.pas` | viva |
| 13 | 382 | `conversa-webrtc/FFmpeg.Binding.pas` | viva |
| 14 | 370 | `lib/popupmenu/Popup.pas` | viva |
| 15 | 359 | `src/chamada/Conversa.Audio.Windows.pas` | **morta** |

Maiores `.fmx`: `ImageViewerFrame.fmx` 66.314 linhas (4,9 MB), `Conversa.Chat.Listagem.fmx` 2.542 (208 KB), `Conversa.Tela.Inicial.view.fmx` 2.497 (207 KB), `Conversa.FormularioBase.fmx` 553, `Conversa.Chamada.view.fmx` 435.

### 7.4 Forms e frames

- **59 `.fmx` próprios**, dos quais 6 sem uso (5 de units mortas + o órfão `chat.anexo.fmx`).
- **Forms (4):** `TTelaInicial` (`Conversa.Tela.Inicial.view`, herda `TFormularioBase`), `TFormularioBase`, `TConversaChamadaView` (herda `TFormularioBase`) e `TNotificacaoVisualizador`. Os `Inicio.view`/`Whip.view` do app de teste somam mais 2.
- **Frames:** cerca de 50 (`TFrameBase`, `TChatBase`/`TChatConteudo`/`TChatEditorBase`, `TNotificacaoItemBase`, `TPopupMenuItemBase` e frames diretos). Dois estão mortos.

### 7.5 Padrões de código (próprio, `.pas`/`.dpr`, sem comentários)

| Padrão | Total | Em código vivo | Onde se concentra |
|---|---|---|---|
| `TThread.` (qualquer uso) | 25 | 20 | `Conversa.Proxy.pas` 7, `Conversa.Windows.UserActivity` 3, `Conversa.Chamada` 3 (+ `tcp.pas` 5, morto) |
| `TThread.CreateAnonymousThread` | 13 | 13 | `Conversa.Proxy.pas` 7 (cada chamada REST assíncrona cria uma thread nova; **sem pool**), `Conversa.Chamada.pas` 3 |
| `Synchronize(` | 3 | 3 | `Conversa.Windows.UserActivity` 2, `Conversa.Chamada.view` 1 |
| `Queue(`/`ForceQueue(` | 7 | 2 | `Conversa.Evento.Base` 1, `Conversa.Chamada.WebRTC` 1 (+ `tcp.pas` 5) |
| `class(TThread)` | 3 | 1 | `lib/audio/AudioMixer` (vivo, sem uso funcional) |
| `TTask.` | 4 | 1 | `Conversa.Windows.UserActivity` |
| `try … except end` **vazio** | 7 | **6** | `lib/windows/Conversa.Windows.UserActivity.pas:61`, `:78` · `lib/windows/Conversa.Windows.Utils.pas:183` · `src/chamada/Conversa.Chamada.pas:211`, `:266` · `src/chamada/Conversa.Chamada.view.pas:135` · (`lib/tcp.pas:153`, morto) |
| `ShowMessage(` | 1 | 1 | `src/chat/chat/chat.selectfile.pas:144`, que mostra o *mimeType* (resto de depuração, ramo Android) |
| Log (`AddLog(`) | 4 | 4 | Definição em `Conversa.Log.Pas` (2) + `Conversa.Chamada.WebRTC.pas:456`, `:458`. Há outros **18 `AddLog` comentados** em `Conversa.Memoria.pas:70-243`. O log **não é thread-safe** (`TextFile` global sem lock, `Conversa.Log.Pas:26-36`), mas é chamado de dentro dos callbacks da DLL Go. Também é **truncado a cada execução** (`Rewrite`). |
| `OutputDebugString` | 0 | 0 | (só nos stashes) |
| `FreeAndNil(` | 73 | 71 | `REST.API.pas` 17, `Conversa.Chamada.WebRTC` 9, `Conversa.Chamada` 7 |
| `with … do` | 93 | **75** | `Conversa.Proxy.pas` 46, `Conversa.Proxy.Extras` 18 (morto), `Conversa.Dados` 5, `PascalStyleScript` 4. Inclui `with TJsonSerializer.Create do` em `Conversa.Configuracoes.pas:56`, `:72`. |
| `Application.ProcessMessages` | 3 | 3 | `Conversa.Tela.Inicial.view`, `Conversa.Chat.Listagem`, `chat.so` |
| `Sleep(` | 29 | 20 | `lib/audio/*`, `Popup.pas` 2… |
| TODO/FIXME | 5 | 5 | Esparsos. |

### 7.6 Resumo em formato de ficha

| Métrica | Valor |
|---|---|
| Units compiladas no exe | 112 (55 no dpr + 57 pelo search path) |
| Units versionadas fora do build | 51 (11 próprias, 2.316 linhas) |
| Linhas Pascal próprias (vivas) | 18.952 |
| Vendor no repositório | Skia 31.829 · DCPcrypt 14.769 · Bird 961 · emoji 5.128 |
| Forms / frames / `.fmx` | 4 / ~50 / 59 |
| Testes automatizados | **0** (não há DUnitX nem projeto de testes) |
| CI / script de build / instalador | **0 / 0 / 0** |
| Threads ad hoc (`CreateAnonymousThread`) | 13 |
| `except` vazio | 6 (vivos) |
| `with` | 75 (vivos) |

---

## 8. Documentação existente

| Documento | Linhas | O que diz | Situação |
|---|---|---|---|
| `README.md` | 20 | Apresentação genérica ("serviço de mensagens… desenvolvido em delphi, disponível para Windows, Linux e Android"), aviso de que é só o cliente, links do ecossistema (servidor, android-fmx, windows-fmx), licença MIT. | **Desatualizado e insuficiente.** Não fala de Delphi 12/Win64, DLLs, Go, FFmpeg, MediaMTX, configuração (`conversa.json`) nem do servidor Bun. Não existe cliente Linux. O link do Android aponta para o FMX, sem citar o Kotlin. Não diz como compilar. |
| `docs/ALTERACOES_TCP_RECONEXAO.md` | 191 | Plano/registro (com ✅) de reconexão TCP com backoff, heartbeat ping/pong, relay de áudio TCP no servidor Delphi e `ConectarTCPAudio`. | **Obsoleto.** O áudio TCP foi substituído pelo WebRTC. `lib/tcp.pas` está morto. Vários ✅ são falsos (heartbeat, `OnStateChanged`, servidor), como o próprio `docs/todo.md` aponta. |
| `docs/waveform-spec.md` | 77 | Especificação do `TWaveformData` (300 pontos, 30 fps) e do `TWaveformView`, com parâmetros 44,1 kHz mono. | **Parcial.** A parte visual confere, mas as fontes de dados descritas (`FPlayerAudioBuffer`, `ClientStream[N].Buffer`) não existem mais. O waveform renderiza vazio (detalhado no `todo.md`). |
| `docs/todo.md` (**não rastreado**) | 249 | Revisão de 2026-06-27 dos dois docs acima contra o código do cliente, do servidor (Delphi) e do web: lista 🔴/🟡/🟢 com `arquivo:linha` e decisões ❓ (manter TCP? waveform? `lib/audio`?). | **Atual quanto ao cliente, desatualizado quanto ao servidor.** Cita `conversa.rest.dpr`/`tcp.pas` do servidor Delphi, que virou Node/Bun em 2026-09-13 (`conversa@97f9341`). Vale versionar ou incorporar à auditoria. |
| `src/notificacao/refatoracao_notificacao.md` | 117 | Checklist (tudo `[x]`) da refatoração de notificações: `Tipos`, `Item.Base`, `Item.Mensagem` (renomeado), `Item.Chamada` com Atender/Recusar. | **Atual quanto ao que foi feito.** Mas o arquivo antigo `Conversa.Notificacao.Item.pas/.fmx` continuou versionado, e o doc está dentro de `src/`, quando deveria ir para `docs/`. |
| `conversa-webrtc/whep-viewer-spec.md` | 1.523 | Especificação completa de um "WHEP Video Viewer — Delphi **11** FMX Win64": código Go inteiro, bindings FFmpeg, um `ffmpeg_helper.dll` em C, caminhos `C:\pion_whep\`, FFmpeg **7.x LGPL**. | **Protótipo/histórico.** Diverge do código atual (Delphi 12, FFmpeg 8 GPL, não existe `ffmpeg_helper.dll`, o WHIP veio depois). Útil só como referência de projeto. |
| `conversa-webrtc/pion/DOC_API.md` | 261 | API WHEP da DLL (`WhepSetLogEnabled`, `WhepInit`, `WhepConnect`, `WhepDisconnect`), callbacks de vídeo/áudio/estado, log em `pion_whep.log`/`C:\pion_whep.log`. | **Coerente** com `main.go` (exports conferidos em `:116-307` e no binário). |
| `conversa-webrtc/pion/DOC_WHIP_API.md` | 233 | API WHIP (`WhipInit`, `WhipConnect`, `WhipSendVideo`, `WhipSendAudio`, `WhipDisconnect`), exemplo em Pascal, configuração do MediaMTX, limitações. | **Coerente** com `main.go:335-570`. |
| `conversa-webrtc/pion/DOC_WHIP_DELPHI.md` | 274 | Lado Delphi do WHIP: DLLs FFmpeg x64 na pasta do exe, units `Screen.Capture`, `Mic.Capture`, `Video.Encoder`, `Audio.Encoder`, `TFormWhip`, fluxo e `mediamtx.yml`. | **Parcial.** Diz "FFmpeg 7.x", mas as DLLs são 8.x (avcodec-62). Descreve o app de teste, não a integração no Conversa (`Conversa.Chamada.WebRTC`). |
| `conversa-webrtc/pion/DOC_COMPILACAO.md` | 153 | Como gerar a `pion_whep.dll`: Go (testado **1.26.1**), GCC 64-bit (WinLibs 14 ou TDM), `go mod tidy`, `CGO_ENABLED=1 GOARCH=amd64 go build -buildmode=c-shared -o ..\bin\pion_whep.dll .`, erros comuns (inclui `0xc000007b` = DLL 64 em app 32). | **Útil e quase atual.** Os caminhos `D:\testewebrtc\pion` estão errados. A saída vai para `conversa-webrtc/bin`, sem dizer que é preciso copiar para `bin/` do app. O `go.mod` mostrado é resumido. A versão do Go no `go.mod` é `1.22`, a usada foi 1.26.1 (confirmado no binário). |

---

## 9. Recomendações (só o que é desta parte)

1. **Hoje:** `git push` do `chamada`, para tirar o `4759ba5` desta máquina só. Decidir se o `main` deve avançar.
2. Trocar a plataforma padrão para **Win64**. Separar `DCC_ExeOutput`/`DCC_DcuOutput` por `$(Platform)\$(Config)`. Tirar Android/Android64 e as permissões `AUP_*`. Trocar o `taskkill` global do PreBuildEvent.
3. Definir **como as DLLs chegam**: script `tools/obter-dependencias` com versões fixadas e SHA-256 (FFmpeg com tag fixa, de preferência LGPL + openh264/`h264_mf`; `pion_whep.dll` compilada a partir do `pion/`; `sk4d.dll` x64 do Delphi; OpenSSL ou troca do Bird/Indy por `System.Net.WebSocket`/WinHTTP). Acrescentar `*.dll` ao `.gitignore` e tirar o `bin/sk4d.dll` x86 do Git.
4. Ter um **build reproduzível**, o que exige licença Professional ou superior (a Community bloqueia a linha de comando) e um `.bat`/CI que **não confie no código de saída do MSBuild** sozinho (verificar se o exe existe e procurar `error`/`Fatal` no log).
5. Limpeza: apagar as 11 units próprias mortas, `teste/`, `Teste.Proxy.pas`, o DCPcrypt não usado, o Skia vendorizado (usar o do Delphi), o PNG do `ImageViewerFrame.fmx`, `MidasLib`/`Data.DB`, os 27 stashes e as branches `keen-buck`/`vigorous-lichterman`/`alteracao-base`. Rodar `git gc`. Revisar o `.gitignore` (§2.3).
6. Senha: trocar `Conversa.AES` por DPAPI, ou não guardar a senha.
7. Reescrever o `README.md` (requisitos, DLLs, configuração, build Win64) e arquivar os docs TCP/waveform obsoletos.
8. Decidir sobre o `FMX.Platform.Win.pas` da Embarcadero no histórico público.

---

### Anexo — comandos e artefatos da auditoria

- Scripts e saídas no scratchpad: `auditoria-fmx/units.js` (fecho de compilação com pré-processador de `{$IFDEF}`), `auditoria-fmx/metrics.js`, `auditoria-fmx/closure.json`, `auditoria-fmx/build/build-win64-debug.log`, `auditoria-fmx/build/status-*.txt`.
- Ferramentas: `git` (só leitura), `tdump.exe -em` (imports do PE), PowerShell (`VersionInfo`, cabeçalho PE, `Get-AuthenticodeSignature`, registro), `grep -a` nas DLLs (configuração do FFmpeg, versão do Go e do Pion).
- Não feito, de propósito: executar o `Conversa.exe` ou o `ffmpeg.exe`, abrir o IDE (`bds -b`), `git gc`/`fetch`/qualquer escrita no Git.
