# TODO — Correções e Dúvidas da Documentação (`docs/`)

> Revisão completa de `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md`
> confrontados com o código real de **conversa-windows-fmx** (cliente), **conversa**
> (servidor REST/Delphi) e **conversa-web** (cliente web).
> Data da revisão: 2026-06-27.

## Como ler

| Marca | Significado |
|-------|-------------|
| 🔴 | Crítico — o documento afirma algo que **não existe** ou contradiz o código ativo |
| 🟡 | Médio — impreciso, incompleto ou descreve código morto/órfão |
| 🟢 | Menor — detalhe a ajustar |
| ✅ | Conferido e **correto** (nada a fazer) |
| ❓ | Dúvida / decisão necessária |

---

## 0. Resumo executivo (leia primeiro)

A descoberta mais importante da revisão: **o projeto migrou de áudio por TCP para WebRTC
(MediaMTX / WHIP / WHEP via Pion)**, tanto no cliente Windows quanto no conversa-web.
Isso afeta os **dois** documentos:

1. **`ALTERACOES_TCP_RECONEXAO.md`** descreve um relay de áudio por TCP com protocolo
   binário próprio e heartbeat. Esse caminho está **órfão no cliente** e **removido do
   servidor ativo**. Boa parte do documento está marcada com ✅ (concluído), mas várias
   dessas funcionalidades **nunca foram implementadas** ou **foram removidas**.

2. **`waveform-spec.md`** descreve a visualização de onda de áudio. A classe visual
   (`TWaveformView`) existe e confere, mas as **fontes de dados descritas não existem**
   na arquitetura atual (WebRTC), e o componente hoje **renderiza vazio** (sem dados).

Evidência da migração:
- Cliente: [Conversa.Chamada.pas:23](conversa-windows-fmx/src/chamada/Conversa.Chamada.pas) usa `Conversa.Chamada.WebRTC`, `TConversaWebRTC.Instance`, `IniciarWebRTC`, `PublicarLocalNaSala` (MediaMTX).
- conversa-web: `src/stores/call.ts` usa `RTCPeerConnection` + WHIP/WHEP contra MediaMTX (`/webrtc`).
- Servidor: `conversa.api.pas` tem TODOs explícitos de integração com a **API do MediaMTX** dentro de `ChamadaIniciar`/`ChamadaSair`.

**Decisão de fundo necessária (ver §5):** arquivar/reescrever os docs para refletir
WebRTC, ou registrar que o TCP é um caminho legado mantido de propósito?

---

## 1. `ALTERACOES_TCP_RECONEXAO.md`

### 1.1 O que ESTÁ correto ✅ (para registro)

Estas afirmações conferem com [lib/tcp.pas](conversa-windows-fmx/lib/tcp.pas) (cliente):

- ✅ Enum `TTCPClientState = (Disconnected, Connecting, Connected, Reconnecting)` — [lib/tcp.pas:23](conversa-windows-fmx/lib/tcp.pas).
- ✅ Callbacks `OnConnected` / `OnDisconnected` — [lib/tcp.pas:76-77](conversa-windows-fmx/lib/tcp.pas).
- ✅ Backoff `0 / 500 / 1000 / 2000 / 5000ms` (`GetBackoffMs`) — [lib/tcp.pas:227-237](conversa-windows-fmx/lib/tcp.pas).
- ✅ Reenvio automático dos dados de registro ao reconectar — [lib/tcp.pas:263-264](conversa-windows-fmx/lib/tcp.pas).
- ✅ `Sleep(3000)` foi de fato removido (não há nenhuma ocorrência no código).

> Observação: tudo isso está implementado, **mas o `TTCPClient` não é usado por nenhuma
> funcionalidade** — é código órfão (ver 1.2 abaixo).

### 1.2 Correções necessárias

- [ ] 🔴 **Heartbeat (Ping/Pong) — seção 1.5 marcada ✅ mas NÃO existe.**
  Não há envio de ping a cada 2s, nem timeout de pong em 3s, nem mensagens `[2]`/`[3]`
  em lugar nenhum do cliente. `TTCPClient.Execute` só lê dados e reconecta quando
  `not Self.Connected` — [lib/tcp.pas:275-317](conversa-windows-fmx/lib/tcp.pas).
  → Remover o ✅ e mover para "não implementado", **ou** implementar de fato.

- [ ] 🔴 **`OnStateChanged` — seção 1.2 marcada ✅ mas NÃO existe.**
  Não há propriedade/callback `OnStateChanged` em parte alguma. Só existem
  `OnConnected` e `OnDisconnected`.
  → Corrigir a lista de callbacks.

- [ ] 🔴 **Servidor TCP — seção 2 inteira (2.1 pong, 2.2 timeout 10s) NÃO existe no build ativo.**
  O `tcp.pas` ativo do servidor não responde a `[2]` com `[3]`, não tem timeout de 10s
  e não dispara `OnClientDisconnect` por inatividade — [conversa/src/tcp/tcp.pas:221-255](conversa/src/tcp/tcp.pas).
  Pior: o unit `tcp` **não está no `uses` do `conversa.rest.dpr`** (linhas 27-37), ou seja,
  **nem é compilado** no servidor ativo.

- [ ] 🔴 **`conversa.chamada.pas` (servidor) — seção 3 inteira referencia arquivo que NÃO existe no código ativo.**
  Não há `conversa.chamada.pas` em `conversa/src/conversa/`. Ele só sobrevive em
  `conversa/rest/src/conversa/__history/conversa.chamada.pas.~NN~` (histórico do Delphi)
  e como `.dcu` compilado antigo. Esse arquivo histórico continha o relay de áudio
  (`TTCPServer`, `MapaClientes`, `DisconnectClient`, broadcast de áudio entre
  participantes) — exatamente o que a seção 3 descreve, mas **foi removido**.

- [ ] 🔴 **`ConectarTCPAudio` (seções 4.2/4.3/4.4) — método NÃO existe.**
  Não há `ConectarTCPAudio` em nenhum `.pas`. O cliente conecta áudio via
  `IniciarWebRTC` → `TConversaWebRTC.Instance.PublicarLocalNaSala(...)`
  — [Conversa.Chamada.pas:485-505](conversa-windows-fmx/src/chamada/Conversa.Chamada.pas).
  Não existem `FCaptureThread`/`FPlayerThread` no fluxo de chamada (a captura é
  `TMicCapture.Start` no caminho WebRTC). Toda a seção 4 descreve um fluxo inexistente.

- [ ] 🟡 **Caminhos de arquivo errados (seções 2, 3, 8).**
  O doc cita `rest/src/tcp/tcp.pas` e `rest/src/conversa/conversa.chamada.pas`. No layout
  ativo isso é `src/tcp/tcp.pas` (não compilado) e `src/conversa/` (sem o arquivo).
  O prefixo `rest/` hoje só aponta para a pasta de `__history`.

- [ ] 🟡 **Seção 1.3 ("`SetConnectionParams` ou `Connect`") imprecisa.**
  Não existe método único `SetConnectionParams`. O setup é dividido em:
  construtor `Create(Host, Port)` [lib/tcp.pas:161](conversa-windows-fmx/lib/tcp.pas),
  `SetRegistrationData(Data)` [lib/tcp.pas:270](conversa-windows-fmx/lib/tcp.pas)
  e a propriedade `OnConnected`. Ajustar a descrição.

- [ ] 🟡 **Os checkmarks ✅ ao longo do documento são enganosos.**
  Eles sugerem "implementado/concluído", mas misturam: (a) implementado e ativo,
  (b) implementado porém órfão, (c) nunca implementado, (d) removido. Sugiro trocar por
  um quadro de status honesto (Ativo / Órfão / Não implementado / Removido).

- [ ] 🟢 **Seções 5, 6, 7 (protocolo e fluxos):** internamente coerentes, mas descrevem o
  sistema TCP obsoleto. Marcar como "arquitetura legada (substituída por WebRTC)".

---

## 2. `waveform-spec.md`

### 2.1 O que ESTÁ correto ✅ (para registro)

Confere com [Conversa.Chamada.Waveform.pas](conversa-windows-fmx/src/chamada/Conversa.Chamada.Waveform.pas):

- ✅ `TWaveformView` com `FPath: TPath`, `FTimer: TTimer`, `FData: TWaveformData`,
  `Color: TAlphaColor`; métodos `Atualizar`, `Vincular`, `Iniciar`, `Parar`.
- ✅ Timer de **33ms** (~30 fps) — [Conversa.Chamada.Waveform.pas:58](conversa-windows-fmx/src/chamada/Conversa.Chamada.Waveform.pas).
- ✅ `TWaveformData`: `FAmplitudes: array[0..299] of Single` + `FWritePos` — buffer de
  300 pontos (10s @ 30fps) — [AudioTypes.pas:13-14](conversa-windows-fmx/lib/audio/AudioTypes.pas).

### 2.2 Correções necessárias

- [ ] 🔴 **`TWaveformData` está no arquivo ERRADO no doc.**
  A tabela "Arquivos" diz que `Conversa.Chamada.Waveform.pas` contém
  *"TWaveformData e TWaveformView"*. Na verdade `TWaveformData` está em
  **[lib/audio/AudioTypes.pas](conversa-windows-fmx/lib/audio/AudioTypes.pas)** e o
  `Conversa.Chamada.Waveform.pas` contém **apenas** `TWaveformView` (que importa
  `AudioTypes`). Corrigir a tabela de componentes e a de arquivos.

- [ ] 🔴 **Fonte do "Waveform Geral" (`FPlayerAudioBuffer`) NÃO existe.**
  Não há nenhum campo/símbolo `FPlayerAudioBuffer` no código (0 ocorrências). O waveform
  geral é vinculado a `Chamada.WaveformDataGeral`
  — [Conversa.Chamada.view.pas](conversa-windows-fmx/src/chamada/Conversa.Chamada.view.pas) —
  mas `FWaveformDataGeral` **nunca é instanciado** no construtor de `TConversaChamada`
  (declarado em [Conversa.Chamada.pas:66](conversa-windows-fmx/src/chamada/Conversa.Chamada.pas),
  só liberado no destrutor). Resultado: a view recebe `nil`.

- [ ] 🔴 **Fonte do "Waveform por Usuário" (`ClientStream[N].Buffer`) NÃO está ativa.**
  O vínculo passa por `Chamada.GetClientStreams` / `FClientStreams`
  ([Conversa.Chamada.pas:65,428](conversa-windows-fmx/src/chamada/Conversa.Chamada.pas)),
  mas `FClientStreams` **nunca é instanciado** → a lista é `nil` e cada item recebe `nil`.

- [ ] 🔴 **`AddSamples` nunca é chamado.**
  `TWaveformData.AddSamples` só aparece na definição/implementação
  ([AudioTypes.pas:20,66](conversa-windows-fmx/lib/audio/AudioTypes.pas)) — **zero call
  sites**. Ou seja: **o waveform hoje não recebe nenhum dado e renderiza vazio**. O doc
  descreve um recurso funcional que, na prática, está inerte.

- [ ] 🟡 **Parâmetros de áudio descrevem o pipeline MORTO (44100/mono).**
  O doc cita 44100 Hz / 16 bits / mono / ~1470 samples por frame. Esses valores batem com
  o pipeline legado `lib/audio` (`AudioCapture`/`AudioPlayer` em 44100 mono), que **não é
  usado** na chamada atual. O caminho **vivo é WebRTC a 48000 Hz, estéreo (2 canais), Opus**
  — `TMicCapture.Create(48000, 2)`
  ([Conversa.Chamada.WebRTC.pas](conversa-windows-fmx/src/chamada/Conversa.Chamada.WebRTC.pas))
  e `Audio.Encoder.pas` (`SAMPLE_RATE=48000; CHANNELS=2`). Atualizar conforme a decisão do §5.

- [ ] 🟡 **Tabelas de componentes incompletas.**
  `TWaveformData` também tem `FLastWriteTick`, `FLock` e os métodos `AddSilence` e
  `MsSinceLastWrite` (usados pela view em [Conversa.Chamada.Waveform.pas:91-92](conversa-windows-fmx/src/chamada/Conversa.Chamada.Waveform.pas)).
  `TWaveformView` também tem `FOwnsData`. O doc omite todos esses.

- [ ] 🟢 **Diagrama "Fluxo de Dados" desatualizado.**
  O fluxo `Captura → FCaptureAudioBuffer → TCP → ClientStream[N] → Mixer → FPlayerAudioBuffer`
  reflete a arquitetura TCP+mixer morta. Reescrever para o fluxo WebRTC (ou marcar como legado).

---

## 3. Consistência com **conversa** (servidor)

- [ ] 🔴 Servidor ativo trata chamada **apenas como sinalização**: endpoints REST
  `/api/chamada/{iniciar,entrar,sair,recusar,cancelar,finalizar,dados,usuario,video}`
  + notificações WebSocket (`conversa.api.pas`, `WebSocket.pas`). **Não há relay de áudio.**
- [ ] 🔴 `tcp` unit e `conversa.chamada` **não constam** no `uses` do
  [conversa.rest.dpr](conversa/conversa.rest.dpr) → não fazem parte do build.
- [ ] 🟡 Há TODOs no servidor apontando integração futura com a **API do MediaMTX**
  (em `ChamadaIniciar`/`ChamadaSair`), confirmando a direção WebRTC. Vale referenciar nos docs.
- [ ] 🟢 Não existe projeto `conversa.socket.dpr`/`.dproj` (só restam `*.local`/`*.identcache`
  órfãos na pasta `conversa/socket`). Confirmar se a pasta deve ser removida.

---

## 4. Consistência com **conversa-web**

- [ ] 🔴 conversa-web usa **WebRTC WHIP/WHEP via MediaMTX** (`src/stores/call.ts`), **não**
  o protocolo TCP binário do `ALTERACOES_TCP_RECONEXAO.md`. Os tipos de mensagem 0/1/2/3,
  registro com UserID e ping/pong **não existem** no web.
- [ ] 🔴 conversa-web **não tem waveform de chamada**. Só há uma barra de gravação
  **animada por CSS** no input de mensagem (`BarraGravacao.vue`) — sem AnalyserNode/Web Audio.
  Doc B descreve um recurso ausente no web.
- [ ] 🟡 Reconexão: conversa-web reconecta o **WebSocket** com backoff exponencial
  `1s → 2s → 4s … (máx 30s)` + polling de 8s (`src/stores/chat.ts`). É **diferente** do
  esquema do Doc A (`0/500/1000/2000/5000ms`, ping 2s, pong 3s) — e aplica-se ao WS de
  mensagens, não a áudio.
- [ ] 🟢 Backend é o mesmo: REST `/api/chamada/*` + WS `/ws/` + MediaMTX em `/webrtc`.
  Os docs do conversa-web (`README.md`, `CLAUDE.md`) já afirmam "Chamadas: WebRTC nativo".
  Os docs em `conversa-windows-fmx/docs` ficaram para trás dessa realidade.

---

## 5. Dúvidas / decisões necessárias ❓

- [ ] ❓ **Os dois documentos descrevem uma arquitetura (áudio TCP) que foi substituída por
  WebRTC.** Qual o destino deles?
  1. Arquivar/marcar como **LEGADO** (mover para `docs/legacy/` com aviso no topo), ou
  2. **Reescrever** para documentar o fluxo WebRTC/MediaMTX atual, ou
  3. Há **plano de reativar** o áudio TCP (e por isso `lib/tcp.pas`, o QoS/DSCP, e a infra
     foram mantidos)?

- [ ] ❓ **`TTCPClient` (cliente) está completo mas órfão.** Manter como utilitário/fallback,
  ou remover junto com o pipeline `lib/audio` legado?

- [ ] ❓ **Waveform: recurso planejado, incompleto ou abandonado?**
  A UI existe mas não recebe dados. Devemos:
  (a) **religar** o waveform ao áudio WebRTC (decodificado a 48k/estéreo), ou
  (b) **remover** `TWaveformView`/`TWaveformData` e a seção visual, ou
  (c) deixar como "em desenvolvimento" e marcar isso no doc?

- [ ] ❓ **Se o waveform for religado, quais parâmetros?** O caminho vivo é 48000 Hz estéreo;
  o doc assume 44100 mono. Definir a fonte canônica de amplitude.

- [ ] ❓ **Pipeline legado `lib/audio`** (`AudioCapture`, `AudioPlayer`, `AudioMixer`,
  `TClientAudioStream`, `TAudioBuffer`): é código morto a remover, ou base para religar o
  waveform/áudio? Decide o que fazer com `AudioTypes.pas` (onde vive `TWaveformData`).

- [ ] ❓ **Paridade desktop × web:** o waveform deve existir nos dois clientes, ou é
  intencionalmente só desktop?

- [ ] ❓ **Pasta `conversa/socket` e o tree `conversa/rest/src/...__history`**: limpar?

---

## 6. Sugestão de ação imediata (mínimo viável)

Independentemente das decisões do §5, estas correções deixam os docs honestos:

1. [ ] Adicionar no topo de **ambos** os docs um aviso de status:
   *"⚠️ Arquitetura de áudio migrada para WebRTC/MediaMTX. Este documento descreve o
   sistema TCP legado / um recurso ainda não funcional — ver `docs/todo.md`."*
2. [ ] Em `ALTERACOES_TCP_RECONEXAO.md`: trocar os ✅ por status reais (Ativo/Órfão/Não
   implementado/Removido) e corrigir os caminhos `rest/src/...`.
3. [ ] Em `waveform-spec.md`: corrigir a atribuição de `TWaveformData` (→ `AudioTypes.pas`),
   remover/atualizar `FPlayerAudioBuffer` e `ClientStream[N].Buffer`, e sinalizar que
   `AddSamples` ainda não é alimentado.
4. [ ] Responder às dúvidas do §5 para definir se é reescrita ou arquivamento.
