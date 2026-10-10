> **Relatório de apoio da auditoria de 2026-10-08** — frente: chamadas e mídia (WHIP/WHEP, Pion, FFmpeg).
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A4 — Chamadas de voz/vídeo e mídia no conversa-windows-fmx (WebRTC via MediaMTX, WHIP/WHEP, Pion, FFmpeg)

**Alvo:** `conversa-windows-fmx`, branch `chamada`, HEAD `4759ba5` (2026-04-26, "Integra chamadas com WebRTC (audio + video) via MediaMTX") + alterações *staged*. As alterações *staged* são `Conversa.Dados.pas` (URL do WebSocket) e `src/chamada/Conversa.Chamada.WebRTC.pas`, esta só no comentário do cabeçalho. Auditada a árvore de trabalho.
**Referências:**
- servidor `conversa` `779c8ed`;
- servidor Delphi de abril: `conversa` `56e7cc0`;
- web `conversa-web` `e8d82cb`;
- auditoria Android `conversa-android-kotlin/docs/auditoria-2026-10/`: doc 01 §9, doc 03 §3.7 e §5, doc 05 (linhas CHA), doc 06 (FC-700…723), doc 08 (S4, S11).

**Data:** 2026-10-08.
**Modo:** somente leitura nos 4 repositórios. As DLLs foram só lidas (`VersionInfo` e cadeias de texto), nunca executadas.

**Convenções:**
- Caminhos sem prefixo são relativos a `conversa-windows-fmx/`. `conversa/…` é o servidor e `conversa-web/…` é o web.
- "doc 01/03/05/06/08" são os documentos da auditoria do Android.
- Linhas conferidas na árvore de trabalho.
- "Não confirmado" marca o que depende de execução ou de cabeçalhos do FFmpeg/Pion que não estão na máquina.

---

## 0. Resumo executivo

1. **Nenhuma chamada funciona de ponta a ponta contra o servidor atual.**
   - A sinalização REST básica está certa: `iniciar`, `entrar`, `recusar`, `sair`, `cancelar` e `dados`, com as rotas e os corpos do contrato.
   - A mídia não conecta:
     - a `pion_whep.dll` cria as `PeerConnection` **sem nenhum servidor ICE** (`conversa-webrtc/pion/main.go:169`, `:353`);
     - o FMX **não chama `GET /api/ice`**;
     - a base do MediaMTX é uma configuração à parte, com padrão `http://localhost:8889` (`src/configuracoes/Conversa.Configuracoes.pas:51-52`, `:66-67`).
   - No servidor, o MediaMTX só escuta em `127.0.0.1:8889` (`conversa/docker-compose.yml:123-124`) e anuncia apenas o IP do container, alcançável só pelo coturn via TCP (`conversa/bin/mediamtx/mediamtx.docker.yml:20-24`).
2. **CRÍTICO (privacidade): toda chamada transmite a TELA INTEIRA do usuário.**
   - Isso vale para "chamada de voz" e começa antes de alguém atender.
   - `IniciarWebRTC` publica com `EnviarVideo=True` (`src/chamada/Conversa.Chamada.pas:502`), e isso liga `TScreenCapture.Start(30)` (`src/chamada/Conversa.Chamada.WebRTC.pas:203-221`).
   - Não há aviso: o botão de vídeo mostra "indisponível" (`src/chamada/Conversa.Chamada.view.pas:149-150`).
   - O MediaMTX **grava** todo caminho `call-*` (`conversa/bin/mediamtx/mediamtx.docker.yml:32-37`) e não tem autenticação (doc 08 S4).
   - Hoje isso só não vaza porque a mídia não chega ao servidor (item 1).
3. **Áudio quebrado nos dois sentidos.**
   - **Recepção:**
     - a DLL entrega o **pacote RTP com cabeçalho** (`track.Read`, `main.go:684-711`), embora o próprio `DOC_API.md:175-176` prometa "sem cabeçalho RTP";
     - o player trata a saída do decodificador Opus nativo (float planar) como S16 intercalado (`conversa-webrtc/Audio.Player.pas:165-173`).
   - **Envio, muito provavelmente quebrado** (não confirmado sem executar):
     - o FFmpeg empacotado tem `--enable-libopus`, e o libopus não aceita `fltp`;
     - além disso, o `AVFrame` vai sem `ch_layout` e sem buffer refcontado, e `avcodec_send_frame` falha em silêncio (`conversa-webrtc/Audio.Encoder.pas:67-83`, `:189-197`).
   - Não há cancelamento de eco, supressão de ruído nem ganho automático.
4. **O vídeo remoto nunca aparece.** O `TImage` de destino é criado invisível e nunca é mostrado (`src/chamada/Conversa.Chamada.Usuario.view.pas:57`, `src/chamada/Conversa.Chamada.Usuarios.Listagem.Item.pas:59`). **Não há câmera** (`Conversa.Chamada.WebRTC.pas:23`).
5. **O ciclo de vida cobre só 51–55, e mal.** Faltam:
   - o tratamento de 56 e 57;
   - os 30 s → `nao_atendeu`;
   - "ocupado";
   - "atendida/recusada em outro aparelho";
   - `GET /chamadas/pendentes`;
   - a sincronização a cada 4 s;
   - as retentativas de WHEP.

   Na prática, **quem liga tende a não ouvir quem atende**: assina no WS 54, antes de o outro publicar, e um 404 não é repetido.
6. **A gerência de memória é perigosa:**
   - `FinalizarLocalmente` faz `FreeAndNil(Self)` e os chamadores continuam usando o objeto (`Conversa.Chamada.pas:331`, `:472-483`);
   - os callbacks da DLL usam o peer fora do lock (`Conversa.Chamada.WebRTC.pas:413-447`);
   - o toast de chamada é liberado dentro do próprio clique (`src/notificacao/Conversa.Notificacao.Item.Chamada.pas:102-114`);
   - `FinalizarTodas` altera o dicionário durante a iteração e libera duas vezes (`Conversa.Chamada.pas:199-216`).
7. **O histórico usa um modelo que o servidor não devolve.** Faltam `tipo_acao`, `usuario_exibido_nome`, `quantidade_outros_usuarios`…: `src/Conversa.Proxy.Tipos.pas:194-214` × `conversa/src/chamadas.ts:429-450`. Já não batia com o servidor de abril.
8. **DLLs:**
   - **São 5 DLLs (≈127 MiB), fora do git.** São importadas de forma estática, então o **EXE não abre sem elas**, mesmo sem chamada.
   - **O FFmpeg é um build "master" GPLv3** (N-123777, 2026-03-31) com libx264 e libx265, num app MIT com a RTL do Delphi proprietária.
   - **A DLL Go** usa Pion `v4.0.0` (out/2024), compilado com Go 1.26.1 e diretiva `go 1.22`.
9. **Os offsets das structs do FFmpeg foram escritos à mão** para "FFmpeg 7.x", com DLL 62.29 (linha 8.x). O `pts` é gravado no offset 128; pelo layout público do `AVFrame` ele fica em 136 (`conversa-webrtc/FFmpeg.Binding.pas:316-322`).
10. **Código órfão confirmado:**
    - `lib/tcp.pas`;
    - `lib/audio/AudioCapture.pas` e `AudioPlayer.pas`;
    - `AudioMixer` (só o tipo é usado);
    - `src/chamada/Conversa.Audio*.pas`, sombreadas pela unit homônima da raiz;
    - `Conversa.Chamada.Participante.Item`;
    - `src/Conversa.Proxy.Extras.pas`, que nem é compilado.
11. **Recomendação:** não investir mais em Pion + FFmpeg para chamadas bidirecionais.
    - O caminho de menor custo para paridade é o **WebView2 com o módulo de chamada do web**.
    - A alternativa nativa é a **libwebrtc** (ex.: `webrtc-sdk/libwebrtc`) com um *shim* C.
    - **Imediato:** desligar o envio de tela automático e pôr as chamadas atrás de *feature flag* e carregamento tardio das DLLs (§8, §9).

**Placar CHA (24 IDs):** 0 ✅ · 5 🟡 · 7 🔴 · 12 ⬜ · 0 ➖. Linha extra "Gravação (codec)": 🟡.

---

## 1. Arquitetura de mídia do FMX

### 1.1 Visão geral

```
                 ┌──────────────────────────── Conversa.exe (Delphi 12 FMX, Win64) ───────────────────────────┐
 WS 51–55 ──────►│ Conversa.Dados.NotificacaoSocket (thread da UI, via TThread.Queue do Bird socket)           │
                 │   └─► TConversaChamadas.ProcessarSocket → TConversaChamada (estado + janela + toast)        │
                 │          ├─ REST síncrono: /chamada/iniciar|entrar|recusar|sair|cancelar|dados (thread da UI)│
                 │          └─ TConversaWebRTC (singleton)                                                     │
                 │               TX: thread anônima → WhipConnect ──► POST {base}/call-C-u-EU/whip              │
                 │                   Tela: TScreenCapture (GDI BitBlt) → TVideoEncoder (swscale+libx264)       │
                 │                         → WhipSendVideo                                                      │
                 │                   Mic : waveIn (MME) → TAudioEncoder (swresample+Opus) → WhipSendAudio      │
                 │               RX: thread anônima por peer → WhepConnect ──► POST {base}/call-C-u-OUTRO/whep  │
                 │                   callbacks da DLL em threads Go:                                          │
                 │                     vídeo: NAL Annex-B → TVideoDecoder (h264+swscale→BGRA) → Queue → TImage │
                 │                     áudio: pacote RTP inteiro → TAudioPlayer (Opus→"PCM") → waveOut (MME)   │
                 └──────────────┬───────────────────────────────────────────────┬─────────────────────────────┘
                                │ cgo (cdecl)                                    │ cdecl
                       pion_whep.dll (Go 1.26.1 + Pion v4.0.0)        avcodec-62 / avutil-60 / swscale-9 / swresample-6
                       ICE só com candidatos host, sem TURN            (build GPLv3 "master" de 2026-03-31)
```

Malha: cada participante publica **uma** transmissão (WHIP) e assina a de cada outro (WHEP). É o mesmo desenho do web (doc 03 §5) e do contrato (doc 01 §9.9).

### 1.2 API exportada pela `pion_whep.dll` (`conversa-webrtc/pion/main.go`, cabeçalho `conversa-webrtc/bin/pion_whep.h:105-113`, binding `conversa-webrtc/Pion.Whep.Binding.pas:24-71`)

| Export | Comportamento | Observações |
|---|---|---|
| `WhepSetLogEnabled(int32)` | Liga o log em `<pasta do exe>\pion_whep.log`; se não conseguir, usa `C:\pion_whep.log` (`main.go:47-70`, `:116-123`) | O FMX não chama: log desligado |
| `WhepInit(videoCb, audioCb, stateCb)` | Grava 3 callbacks globais (`:127-136`) | O FMX chama uma vez no construtor do singleton (`Conversa.Chamada.WebRTC.pas:163-167`) |
| `WhipInit(stateCb)` | Só o callback de estado (`:141-148`) | Não usado |
| `WhepConnect(url, authType, user, pass)` → handle > 0 ou −1…−9 | `MediaEngine.RegisterDefaultCodecs` e `NewAPI` **sem `InterceptorRegistry`** (`:171-179`). **`ICEServers` vazio** (`:169`). Transceivers *recvonly* de vídeo **e** áudio (`:213-229`). **Espera o gathering completo, sem limite de tempo** (`:245`). `POST application/sdp` (`:248-254`); `Basic` opcional (`:256-266`); aceita 200/201 (`:278`) | Não lê `Location`. Nos erros depois de `:186` **não fecha o `pc` nem o tira do mapa** (vazamento). `http.Client{}` sem *timeout* (`:268`) |
| `WhepDisconnect(handle)` | `pc.Close()` e `notifyState(0)` (`:307-327`) | Sem `DELETE` WHEP |
| `WhipConnect(url, auth, user, pass, sendVideo, sendAudio)` | Trilha H264 (`TrackLocalStaticSample`, `:373-376`) e/ou Opus (`:392-395`). `ICEServers` vazio (`:353`); gathering completo (`:440`); `POST` (`:443-457`); fecha o `pc` nos erros | Bloqueia até o HTTP responder; *timeout* só o do TCP |
| `WhipSendVideo(h, data, size, durMs)` | `WriteSample` de H264 Annex-B; 0 → 33 ms (`:507-534`) | Duração fixa: o timestamp RTP não segue o relógio real |
| `WhipSendAudio(h, data, size, durMs)` | `WriteSample` de Opus; 0 → 20 ms (`:539-566`) | |
| `WhipDisconnect(h)` | `pc.Close()` (`:570-589`) | Sem `DELETE` WHIP |

**Callbacks** (todos em threads do runtime Go, nunca na thread da UI):
- `VideoFrameCallback(handle, data, size, ts=0)`:
  - chamado **por NAL** (FU-A remontado, STAP-A expandido), pelo depacketizador próprio (`:593-682`);
  - sem reordenação, sem tratar perda e sem agrupar por *access unit*;
  - não confere o codec: assume H264 mesmo que a trilha seja VP8 ou VP9 (`:190-197`).
- `AudioFrameCallback(handle, data, size, ts=0)`: entrega o **pacote RTP inteiro**. `TrackRemote.Read` devolve o pacote RTP marshalado, não o *payload* (`:684-711`).
- `StateCallback(handle, 0..3)`: 0 desconectado, 1 conectando, 2 conectado, 3 falhou (`:106-110`, `:199-211`, `:410-422`).
- Os dados são liberados logo depois do callback (`C.free`, `:677-680`, `:707-710`).

### 1.3 Envio (WHIP)

1. `TConversaChamada.IniciarWebRTC` (`Conversa.Chamada.pas:485-505`) é chamado:
   - por quem liga, logo após `PUT /chamada/iniciar` (`:469`);
   - por quem atende, após `POST /chamada/entrar` (`:300`).
2. Uma thread anônima chama `PublicarLocalNaSala(ChamadaId, MeuId, True, True)` (`Conversa.Chamada.WebRTC.pas:169-244`):
   - URL `Format('%s/call-%d-u-%d/whip', [FMediaMtxBase, …])` (`:180`);
   - `WhipConnect` com `authType=''` (`:185-191`);
   - se der certo, `FTxHandle := Ret`.
3. **Vídeo, que é a tela** (`:203-221`):
   - `TVideoEncoder.Create(1280, 720, 30, 2000)`;
   - `TScreenCapture.Start(30)`: thread que faz `BitBlt` do monitor principal inteiro e `GetDIBits` em BGR0 (`conversa-webrtc/Screen.Capture.pas:259-326`);
   - `FeedFrame`: swscale BGR0 → YUV420P 1280×720, libx264 `ultrafast`/`zerolatency`, GOP = fps (1 *keyframe*/s), sem B-frames, 2 Mbps (`conversa-webrtc/Video.Encoder.pas:51-103`, `:133-198`);
   - `WhipSendVideo(…, 33)`.
4. **Áudio** (`:223-241`):
   - `TMicCapture.Create(48000, 2)`: `waveIn` com `WAVE_MAPPER`, 4 buffers de 20 ms (`conversa-webrtc/Mic.Capture.pas:314-343`);
   - no callback do waveIn: `FeedPCM` → acumula 960 amostras → swresample S16 → FLTP → `avcodec_send_frame` (`Audio.Encoder.pas:142-218`);
   - `WhipSendAudio(…, 20)`.
5. **O vídeo vem antes do áudio no código:** qualquer exceção no vídeo (encoder que não abre, captura) mata a publicação do áudio. As exceções na thread anônima se perdem.

### 1.4 Recepção (WHEP)

1. Quem atende chama `AssinarPeersExistentes` depois de `Entrar` (`Conversa.Chamada.pas:507-536`). Quem liga chama `OnUsuarioEntrou` ao receber o WS 54 (`:358-387`). Nos dois casos é uma thread anônima por peer com `AssinarDePeer` (`Conversa.Chamada.WebRTC.pas:246-335`).
2. `WhepConnect`, **uma tentativa só** (`:264-275`). Só **depois** do retorno são criados o `TWebRTCPeer` (decodificador H264 e player Opus) e o registro no dicionário (`:277-331`). O que chegar antes disso, como SPS/PPS ou o primeiro IDR, é descartado.
3. **Vídeo:**
   - o NAL chega na thread Go;
   - `GlobalVideoCallback` (`:413-429`) chama `TVideoDecoder.FeedData`, que faz `avcodec_send_packet` por NAL, **sem `AV_CODEC_FLAG2_CHUNKS` nem parser** (`conversa-webrtc/Video.Decoder.pas:285-343`);
   - swscale converte YUV420P em BGRA;
   - `OnFrame` copia `H*Stride` e enfileira um `TThread.Queue`;
   - na thread da UI, com `FLock` tomado, faz `Bitmap.Map`, a cópia e o `Repaint` (`Conversa.Chamada.WebRTC.pas:287-324`).
   - O destino é um `TImage` com `Visible := False`, que nunca é exibido (§0.4).
4. **Áudio:** o pacote RTP chega na thread Go e passa por `GlobalAudioCallback` (`:431-447`) até `TAudioPlayer.FeedData` (`conversa-webrtc/Audio.Player.pas:144-178`):
   - `avcodec_send_packet` com o cabeçalho RTP junto ao decodificador `opus` nativo, que devolve FLTP;
   - `data[0]` (canal esquerdo em float) é lido como S16 estéreo, `nb_samples×4` bytes, pelo offset fixo 112 (`:170-171`);
   - depois vai para `waveOutWrite` (`:119-142`).

### 1.5 Codecs

| Sentido | Mídia | Codec / biblioteca | Parâmetros | Evidência |
|---|---|---|---|---|
| Envio | Vídeo | H264 via **libx264** (GPL) | 1280×720, 30 fps-alvo, 2 Mbps, `ultrafast`/`zerolatency`, GOP 30, sem B | `Video.Encoder.pas:65`, `:74-84`; `main.go:373-376` |
| Envio | Áudio | Opus via `avcodec_find_encoder(AV_CODEC_ID_OPUS)`. O build tem `--enable-libopus` e o encoder nativo é experimental; `find_encoder` pula experimentais, então **deve escolher o libopus** (não confirmado sem executar) | 48 kHz, estéreo, **128 kbps**, `fltp` pedido, 20 ms | `Audio.Encoder.pas:19-21`, `:67-83` |
| Recepção | Vídeo | **Só H264** (depacketizador e decodificador `h264` nativo) | YUV420P presumido (`sws_getContext` fixo) | `main.go:593-653`; `Video.Decoder.pas:226`, `:263-268` |
| Recepção | Áudio | Opus, decodificador `opus` nativo (saída FLTP) | Saída tratada como S16 | `Audio.Player.pas:52`, `:165-173` |
| — | VP8, VP9, AV1, H265, G.711 | Não suportados na recepção. Um navegador sem H264 publica VP9 (`conversa-web/src/stores/call.ts:354`); o FMX trataria o VP9 como H264 | — | — |

### 1.6 Captura e reprodução de áudio

- **É MME (`waveIn`/`waveOut`), não WASAPI.** O cabeçalho da unit diz "Opus -> PCM + WASAPI" (`Conversa.Chamada.WebRTC.pas:22`) e o `whep-viewer-spec.md:824` repete, mas o código usa `waveOutOpen` e `waveInOpen` (`Audio.Player.pas:95`, `Mic.Capture.pas:324`).
- **Dispositivo:** sempre o padrão (`WAVE_MAPPER`), sem seleção de microfone ou saída.
- **Processamento:** nenhum. Sem AEC, NS ou AGC; o web usa `echoCancellation`, `noiseSuppression` e `autoGainControl` (doc 03 §5.3). Em alto-falante, o eco volta para os outros.
- **Reprodução:**
  - um `waveOut` por peer;
  - 8 buffers de 8 KB em rotação, que **sobrescrevem um buffer ainda em reprodução** porque não esperam `WHDR_DONE` (`Audio.Player.pas:129-141`);
  - sem *jitter buffer*, sem PLC e sem controle de deriva.
- **Mute:** fecha e reabre o `waveIn` (`Conversa.Chamada.WebRTC.pas:401-409`, `Mic.Capture.pas:314-361`).

### 1.7 Câmera e compartilhamento de tela

- **Câmera:** não existe. O cabeçalho diz "webcam ainda NAO implementada" (`Conversa.Chamada.WebRTC.pas:23`).
- **Tela:** GDI `BitBlt` do **monitor principal** em resolução cheia (`GetSystemMetrics(SM_CXSCREEN/SM_CYSCREEN)`, `Screen.Capture.pas:274-303`).
  - Não há seletor de monitor ou janela, cursor nem áudio do sistema.
  - O WS 57 `{acao:'tela'}` não é anunciado.
  - **Liga sozinho em toda chamada.** O botão de vídeo só para ou religa a captura (`Conversa.Chamada.view.pas:110-120`, `Conversa.Chamada.WebRTC.pas:390-399`). O primeiro clique "ativa" o que já estava ativo.

### 1.8 Threads, buffers e locks

| Thread | Origem | O que faz | Riscos |
|---|---|---|---|
| UI (principal) | FMX | Recebe os WS via `TThread.Queue` (`lib/bird-socket-client/Bird.Socket.Client.pas:742-748`). Faz o REST síncrono de chamada (`src/Conversa.Proxy.pas:818-937`, chamado em `Conversa.Chamada.pas:296`, `:410`, `:462`). Renderiza o vídeo | A UI congela a cada evento ou ação. Exceções do REST e da desserialização sobem dentro de um `Queue` sem `try` |
| "Publicar" (anônima) | `Conversa.Chamada.pas:499-504` | `WhipConnect` bloqueante; cria os encoders e as capturas | Sem *timeout*; exceção perdida; não é cancelada por `Desligar` |
| "Assinar" (anônima, uma por peer e por evento) | `Conversa.Chamada.pas:381-386`, `:529-534` | `WhepConnect` | Pode registrar o peer **depois** de `Desligar` (peer zumbi tocando áudio) |
| Captura de tela | `Screen.Capture.pas:259-329` | BitBlt, GetDIBits, swscale, x264 e `WhipSendVideo` (cgo) | Usa CPU alta (tela cheia a 30 fps) |
| Callback do waveIn (sistema) | `Mic.Capture.pas:267-287` | swresample, Opus e `WhipSendAudio` (cgo) **dentro do callback** | O MSDN proíbe chamar funções do sistema no callback, exceto um punhado: risco de *glitch* ou *deadlock* |
| Goroutines/threads do Go | `main.go:190-197` | Leitura RTP e callback Delphi; **a decodificação H264 e Opus e o `waveOutWrite` rodam na thread do Go** | Exceção Delphi atravessando o cgo derruba o processo (não há `try/except` nos callbacks) |
| Runtime Go (ICE, DTLS, GC) | Import estático | Sobe ao carregar o EXE | Memória e threads fixas mesmo sem chamada |

**Locks:**
- `TConversaWebRTC.FLock` protege o dicionário de peers **e** a renderização. O `Queue` de render segura o lock durante a cópia do bitmap, e os callbacks de áudio esperam (`Conversa.Chamada.WebRTC.pas:302-322`).
- Locks próprios em decodificador, player e encoders.

**Buffers:**

| Onde | Configuração |
|---|---|
| waveIn | 4 × 3 840 B (4 × 20 ms) |
| Acumulador Opus | Dinâmico |
| waveOut | 8 × 8 KB |
| Leitura RTP | MTU para vídeo; 4 096 B para áudio |
| Vídeo | **Uma cópia BGRA por quadro por `Queue`, sem descarte.** O `whep-viewer-spec.md:1454-1456` já alertava |

### 1.9 Latência (estimativa — **não medida**)

| Trecho | Áudio | Vídeo |
|---|---|---|
| Captura | 20–80 ms (4 buffers de 20 ms) | 10–40 ms (BitBlt + GetDIBits de tela cheia) |
| Conversão e codificação | ~1–3 ms | 5–15 ms (swscale + x264 ultrafast) |
| Rede | Hoje não conecta. Depois de corrigir: TURN/TCP, RTT/2 + ~1–5 ms no MediaMTX | idem |
| Recepção | Sem *jitter buffer*: toca na chegada. Picos viram estalos. waveOut (MME) costuma somar 40–100+ ms | Decodificação 3–10 ms; `Queue` + cópia 3,7 MB/quadro + `Repaint` 5–20 ms; atraso extra sempre que a UI está presa em REST síncrono |
| Sincronismo A/V | Nenhum | Nenhum |

### 1.10 Endereços e caminhos

- **Nome do stream:** `call-<chamada>-u-<usuario>` + `/whip` ou `/whep` (`Conversa.Chamada.WebRTC.pas:180`, `:262`). É **igual** ao web (`conversa-web/src/stores/call.ts:226-233`) e ao contrato (doc 01 §9.9). Os ids são inteiros, então não há o que sanitizar.
- **A base está errada:**
  - no FMX é `Configuracoes.MediaMtxBase`, padrão `http://localhost:8889` (`src/configuracoes/Conversa.Configuracoes.pas:17`, `:51-52`, `:66-67`);
  - **não é derivada de `Configuracoes.Host`** e não há tela para editá-la; só mexendo no `conversa.json`.
- **O certo:** `https://<host>[:porta]/webrtc`, a mesma origem da API (`conversa/bin/nginx/nginx.conf:135-140`; web: `${window.location.origin}/webrtc`, `call.ts:210-213`). No servidor, a porta 8889 só está publicada em `127.0.0.1` (`conversa/docker-compose.yml:123-124`).
- O `Conversa.Dados.pas` *staged* já passou o WebSocket para a mesma origem (`wss://host/ws/`). O WebRTC deve seguir o mesmo caminho.

### 1.11 ICE / TURN / relay / trickle

- **`GET /api/ice`:** não é usado.
  - O endpoint existe (`conversa/src/rotas.ts:212`) e devolve TURN com credencial HMAC de 1 h e `iceTransportPolicy` (`conversa/src/chamadas.ts:576-594`).
  - Com `turn_forcar_relay = '1'` (`conversa/src/configuracao.ts:169`) a política é `relay` (doc 01 §9.5).
  - O web busca a cada `RTCPeerConnection` (`call.ts:45-55`).
- **Pion:** `ICEServers: []`, sem `ICETransportPolicy` e sem `SettingEngine` (`main.go:169`, `:353`). Só sobem candidatos *host* do cliente.
- **Servidor:**
  - o MediaMTX anuncia só `172.30.0.20` (`mediamtx.docker.yml:20-24`);
  - o coturn aceita só TCP e retransmite só para o MediaMTX (`conversa/bin/coturn/turnserver.conf:13-17`, `:33-41`);
  - logo o ICE do FMX **falha** e o estado vira 3, que só é logado (`Conversa.Chamada.WebRTC.pas:449-466`).
- **Trickle:** não há. Espera o gathering completo **sem limite**; o web limita a 5 s (`call.ts:235-256`).
- **A correção é viável no Pion:** ele aceita `turn:host:3478?transport=tcp`, `turns:` e `ICETransportPolicyRelay`. Mas **a API da DLL não tem parâmetro** para isso; é preciso uma função nova, por exemplo `WhipConnectEx(url, configJson, …)`.

### 1.12 `Location`/`DELETE`, retentativas e reconexão

- **`Location` e `DELETE`:** não lê nem envia (`main.go:274-305`, `:307-327`, `:570-589`). O web também não faz isso (doc 03 §5.1): o MediaMTX encerra a sessão quando a DTLS fecha. Melhoria P3.
- **Retentativas de WHEP 404:** não há (`Conversa.Chamada.WebRTC.pas:264-275`). O web tenta 40×1 s (vídeo) e 12×0,8 s (áudio) (`call.ts:519-540`). Junto com a ordem dos eventos (§3), isso dá **áudio de mão única**.
- **Reconexão quando o ICE falha:** não há.
  - `GlobalStateCallback` só registra no log e chama `FOnErro`, que **nunca é atribuído** (nenhuma atribuição no projeto).
  - O web republica em `failed`/`disconnected` (`call.ts:442-457`), reassina depois de 2 s e sincroniza a cada 4 s (`call.ts:161-165`).

### 1.13 Quadro comparativo

| Aspecto | Contrato / web | FMX |
|---|---|---|
| Base MediaMTX | `https://host/webrtc` | `http://localhost:8889` (config separada) |
| ICE | `GET /api/ice` a cada PC; TURN TCP/TLS; `relay` | Nenhum servidor ICE |
| Gathering | Até 5 s | Ilimitado |
| Trilhas publicadas | ≤ 1 de áudio + ≤ 1 de vídeo; câmera ou tela (por escolha) | Áudio + **tela sempre** |
| Codec de vídeo | H264 → VP9 → resto (`call.ts:354-367`) | H264 (libx264) |
| Áudio | Opus 32/64/128k; mono (estéreo no modo música); AEC/NS/AGC | Opus 128k estéreo; sem processamento; envio provavelmente quebrado |
| WHEP | *recvonly*; vídeo só em chamada de vídeo; retentativas | *recvonly* vídeo + áudio sempre; uma tentativa |
| Recuperação | Republica e reassina; sincroniza a cada 4 s | Nenhuma |
| Encerramento | `pc.close()` | `pc.Close()` (equivalente) |

---

## 2. Codec e gravação

- **O servidor grava tudo em `call-*`:** fMP4, segmentos de 1 h, sem apagar sozinho (`conversa/bin/mediamtx/mediamtx.docker.yml:27-37`). A retenção é o parâmetro `gravacao_dias`, padrão 90 (doc 01 §9.10). **VP8 não é gravado**, H264 e VP9 sim.
- **O FMX publica H264 (libx264) + Opus**, ambos graváveis em fMP4, então **o codec está certo**. Porém:
  1. **O vídeo gravado é a tela inteira do usuário**, inclusive em chamada de voz. Uma chamada 1:1 iniciada pelo FMX vai com `tipo` 1, que o servidor e o web leem como áudio (doc 01 §9.1).
  2. A trilha de áudio provavelmente vai muda ou nem existe (A4-04).
  3. **Hoje nada chega ao MediaMTX** (A4-02), então não há gravação do FMX. Depois que o TURN for corrigido, a gravação da tela passa a acontecer.
  4. Na recepção, se um navegador sem H264 publicar VP9 (gravável e válido pelo contrato), o FMX mostra lixo. O depacketizador não confere o `MimeType` (`main.go:190-197`).
- **Conclusão:** a linha "Gravação (codec)" fica 🟡. O codec é gravável, mas o conteúdo está errado (privacidade) e a mídia não chega.

---

## 3. Ciclo de vida e regras (FMX × servidor × web)

### 3.1 Eventos WebSocket 51–57

Envelope: `{tipo, chamada_id, usuario_id}` (`conversa/src/websocket.ts:166-168`); o 57 acrescenta `dados` (`:162-164`, `:206-227`).

| Evento | Servidor | Web | FMX | Situação |
|---|---|---|---|---|
| **51** ChamadaRecebida | `iniciar`: a todos menos o criador. `adicionar`: a todos menos quem adicionou, **inclusive quem já está na chamada** (`conversa/src/chamadas.ts:88-110`, `:283-291`; `conversa/src/notificacoes.ts:25-39`) | Ignora o 51 próprio; chamada atual → só sincroniza; ocupado → `recusar {nao_atendeu:true}`; senão `GET dados`, `recebendo` e 30 s (`call.ts:1502-1538`) | Cria `TConversaChamada` se não existe (`Conversa.Chamada.pas:170-190`). `OnChamadaRecebida`: estado Recebendo, `GET dados`, toast e janela (`:334-340`). **Chamada atual → volta a "Recebendo"**. **Outra chamada em curso → segunda janela** | 🔴 |
| **52** ChamadaFinalizada | `cancelar`/`finalizar` (`chamadas.ts:153-160`, `:293-300`) | Encerra (`call.ts:1541-1549`) | `GET dados`, `Desligar`, `FinalizarLocalmente` (`Conversa.Chamada.pas:326-332`), **com uso de `FID` depois de liberar** (`:331`) | 🟡 |
| **53** UsuarioRecusou | `recusar`: aos outros **e a mim mesmo** (`chamadas.ts:193-195`) | Meu id e `recebendo` → para; 1:1 em que o outro recusou → encerra (`call.ts:1551-1573`) | Marca o usuário. Iniciando + Simples → Recusada e finaliza (`Conversa.Chamada.pas:342-356`). **Meu id em Recebendo → ignorado** | 🟡 |
| **54** UsuarioEntrou | `entrar`: aos outros **e a mim mesmo** (`chamadas.ts:199-212`) | Meu id → para de tocar se não atendi aqui; chamando → ativa; ativa → reanuncia a tela e sincroniza (`call.ts:1575-1600`) | Marca. Se não está Recebendo → EmAndamento, `GET dados` e **assina o peer uma vez, sem retentativa** (`Conversa.Chamada.pas:358-387`). **Meu id em Recebendo → ignorado** | 🔴 |
| **55** UsuarioSaiu | `sair`: aos outros. **Não manda 52** mesmo que a chamada termine (`chamadas.ts:214-225`; doc 01 §9.2) | Desconecta o peer, `GET dados`; se nenhum outro está "Entrou" → `sair` e encerra (`call.ts:1602-1618`) | Desconecta o peer. Simples + EmAndamento → finaliza localmente (`Conversa.Chamada.pas:389-406`). **Grupo → nada** | 🟡 |
| **56** VideoAtivado | `POST /chamada/video` (`chamadas.ts:302-305`) | Modal de 15 s ou reassina (`call.ts:1620-1646`) | Valor no enum (`src/Conversa.Tipos.pas:36`), **sem tratamento** (`Conversa.Chamada.WebRTC.pas:27-29`). `TEventoChamadaVideoAtivado` declarado e sem uso (`src/Conversa.Eventos.pas:29`) | ⬜ |
| **57** SinalChamada | Repasse a quem está "Entrou" (`websocket.ts:71-77`, `:206-227`). Criação do chat (`chamadas.ts:256-264`) | `tela`, `ponteiro`, `chat` (`call.ts:1413-1476`, `:1493-1498`) | **Não existe no enum** (`Conversa.Tipos.pas:16-38`); nem envia nem recebe | ⬜ |

**Ordem que quebra o áudio de quem liga:**
1. O servidor emite o 54 durante o `/chamada/entrar`, antes de quem atende sequer começar o WHIP (`chamadas.ts:199-212`).
2. O FMX de quem liga faz o WHEP na hora, recebe 404 e desiste.
3. Quem atende, por sua vez, assina quem liga (que já publicou), então o áudio só vai num sentido.
4. Se a ponta que atende for o web, o web insiste e consegue: o áudio do FMX chegaria ao web, mas não o do web ao FMX.

### 3.2 Regras automáticas e funções

| Regra / função | Contrato e web | FMX | Situação |
|---|---|---|---|
| Tocar 30 s → `POST /chamada/recusar {id, nao_atendeu:true}` | `call.ts:1530-1535`; doc 01 §9.13 | Sem timer. `TChamada.Recusar` só manda `{id}` (`src/Conversa.Proxy.pas:857-869`). Quem liga fica chamando sem fim, e o FMX nunca gera "chamada perdida" própria | ⬜ |
| Ocupado → recusar com `nao_atendeu` | `call.ts:1518-1522` | Abre uma segunda chamada com outra janela e o **mesmo singleton de mídia** (`Conversa.Chamada.WebRTC.pas:61-114`, `:169-244`): atender a segunda sobrescreve `FTxHandle` e os encoders da primeira | ⬜ |
| Atendida ou recusada em outro aparelho (53/54 com o meu id) | `call.ts:1554-1558`, `:1578-1585` | Ignorado: continua tocando até o 52. Atender aqui publica no **mesmo caminho** do outro aparelho; o padrão do MediaMTX é `overridePublisher: yes`, não sobrescrito no yml, e o novo publicador derruba o anterior | ⬜ |
| `GET /chamadas/pendentes` ao conectar; > 25 s → perdida; resposta sem `usuarios` | `call.ts:1648-1673`; doc 01 §9.6 | `TChamadaPendentes.Listar`/`TChamadaExtras.Pendentes` existem em `src/Conversa.Proxy.Extras.pas:225-236`, `:429-440`, **mas a unit não está no `.dpr` nem no `.dproj`** e ninguém chama. O WebSocket também não reconecta (sem `AutoReconnect`, `Conversa.Dados.pas:420-451`) | ⬜ |
| Cancelar enquanto chama (`/cancelar` × `/sair`) | `call.ts:1007-1016` | `Sair` escolhe pelo estado: Iniciando → `/cancelar`, Recebendo → `/recusar`, EmAndamento → `/sair` ou `/finalizar` (`Conversa.Chamada.pas:309-324`). Correto | ✅ (rota) |
| 55 sem 52: sair quando ninguém mais está "Entrou" | `call.ts:1607-1616` | Só em `FTipo = Simples` (`:399-405`). Com a ambiguidade do `tipo` (S11), uma 1:1 de **vídeo** do web (tipo 2) nunca termina no FMX, e uma de **áudio em grupo** do web (tipo 1) termina na primeira saída | 🟡 |
| Sincronização a cada 4 s | `call.ts:161-165`, `:795+` | Não há | ⬜ |
| Upgrade para vídeo (`/chamada/video`, WS 56, modal de 15 s) | `call.ts:1620-1646` | `TChamadaExtras.AtivarVideo` existe só no Extras, não compilado (`Proxy.Extras.pas:394-409`); sem câmera; sem modal | ⬜ |
| Adicionar participante (`PUT /chamada/usuario`) | `call.ts:1233+` | Só no Extras (`:411-427`), não compilado. Receber o 51 dessa ação durante a chamada é um defeito (A4-09) | ⬜ |
| Chat da chamada (`PUT /chamada/chat`, WS 57 `chat`) | `call.ts:1478+` | Não existe | ⬜ |
| Tela compartilhada e ponteiro (WS 57) | `call.ts:1370+`, `:1413+` | A tela é **sempre** enviada e nunca anunciada; o ponteiro não existe | 🔴 / ⬜ |
| Indicador de fala | `useFalaChamada.ts` (RMS > 0,02, segura 400 ms) | `TWaveformView` existe, mas **sem dados**: `FWaveformDataGeral` e `FClientStreams` nunca são criados (`Conversa.Chamada.pas:65-66`, `:245-259`) e `AddSamples` não tem chamador (`lib/audio/AudioTypes.pas:20`, `:66`). A view só adiciona silêncio (`src/chamada/Conversa.Chamada.Waveform.pas:89-94`): linha reta | 🔴 |
| Somente recepção | doc 03 CHA-21 | Sem microfone, `waveInOpen` lança exceção na thread de publicação (`Mic.Capture.pas:324-327`) **depois** de a tela já estar indo; não há interface | ⬜ |
| Janela de chamada | Flutuante e arrastável; barra | Formulário separado de 300×480 (`src/chamada/Conversa.Chamada.view.fmx:3-4`) com botão próprio na barra de tarefas (`view.pas:161-171`); **não fica no topo**. Fechar (X) **só esconde** (`src/base/Conversa.FormularioBase.pas:416-419`) e não há como reabrir. A barra de título da janela principal tem cronômetro, mas o **"encerrar" não faz nada** (`src/chamada/Conversa.Chamada.BarraTitulo.pas:80-100`). O toast fica no topo sem roubar foco (`src/notificacao/Conversa.Notificacao.Visualizador.pas:87`) | 🟡 |
| Controles | Microfone, câmera, saída, tela, chat, ponteiro, adicionar, minimizar, sair | Microfone (fecha o waveIn) e "vídeo", que liga ou desliga a **captura de tela**. Sem silenciar a saída, sem escolher microfone, saída ou câmera, sem câmera | 🟡 |
| Histórico (`GET /chamadas?participante=&de=&ate=`) | `ChamadaHistoricoItem` (doc 01 §9.7) | `GET chamadas` sem filtros (`src/Conversa.Proxy.pas:313-334`) com outro modelo (`src/Conversa.Proxy.Tipos.pas:186-217`) | 🔴 |
| Bolha de chamada (conteúdo tipo 6) | doc 01 §9.8 | `TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo, MensagemAudio)` não tem 6 (`src/Conversa.Tipos.pas:220`). O FMX não manda `conversa_id` no `iniciar` (`Conversa.Chamada.pas:455-462`), então **a chamada iniciada no FMX nem gera resumo** | ⬜ |
| Sons de "chamando" e de toque | `useCallPopup.ts:7-8` (`/toque.mp3`, `/chamando.mp3`) | Só `nova_mensagem.wav` existe (`ConversaResource.rc`), usado por mensagens (`src/chat/Conversa.Chat.Listagem.pas:307`) | ⬜ |

### 3.3 Máquina de estados atual do FMX

`TChamadaStatusLocal = (Desconhecido, IniciandoChamada, RecebentoChamada, ChamadaEmAndamento, ChamadaFinalizada, ChamadaPerdida, Recusada)` (`src/Conversa.Tipos.pas:40-48`).

Transições:

| De | Gatilho | Para |
|---|---|---|
| — | `IniciarChamada` | Iniciando |
| — | 51 | Recebendo |
| Recebendo | `Entrar` | EmAndamento |
| Iniciando | 54 de outro | EmAndamento |
| — | 52 | Finalizada |
| Iniciando + Simples | 53 | Recusada |
| EmAndamento + Simples | 55 | Finalizada |

- `ChamadaPerdida` nunca é atribuído.
- Toda saída passa por `FinalizarLocalmente`, que **libera o próprio objeto** (`Conversa.Chamada.pas:472-483`).
- Não há estado "Encerrando", nem proteção contra eventos fora de ordem.
- Um 54 de uma chamada desconhecida cria um objeto e o põe em "EmAndamento" sem janela (`:170-190`, `:358-368`).

---

## 4. Matriz CHA (formato do doc 05)

### Legenda

| Símbolo | Significado no FMX **atual** (contra o servidor `779c8ed`) |
|---|---|
| ✅ | Existe e funciona |
| 🟡 | Parcial ou com defeito relevante |
| 🔴 | Existe, mas **quebra contra o servidor atual** ou tem defeito crítico |
| ⬜ | Não existe |
| ➖ | Não se aplica literalmente ao desktop; ver "Adaptação" |

Fases e prioridades iguais às do doc 05 e do A5b (F6 = Chamadas; P0 = obrigatório contra o servidor atual … P3 = opcional).

### Placar

| Grupo | Total | ✅ | 🟡 | 🔴 | ⬜ | ➖ |
|---|---|---|---|---|---|---|
| CHA | 24 | 0 | 5 | 7 | 12 | 0 |

A linha extra "Gravação (codec)" e as linhas de apoio no fim da tabela não entram na contagem.

### CHA — Chamadas

| ID | Funcionalidade | FMX | Situação / evidência (FMX × servidor/web) | Adaptação desktop Windows | Fase | Prio |
|---|---|---|---|---|---|---|
| CHA-01 | Iniciar chamada de voz/vídeo | 🔴 | Um botão só, sem escolher voz ou vídeo (`src/chat/Conversa.Chat.pas:151-155`). `PUT /chamada/iniciar {usuarios}` **sem `tipo` e sem `conversa_id`** (`Conversa.Chamada.pas:455-467`; contrato `chamadas.ts:88-110`, web `call.ts:890`). Síncrono na UI, sem conferir `Status`; numa falha `FID = 0` e o WHIP vai para `call-0-u-<eu>`. Em grupo os membros vêm só de `/conversas` (`[eu, destinatario]`, `Conversa.Dados.pas:207-209`), porque `/conversa/dados` não existe (`Proxy.pas:582` × `conversa/src/rotas.ts:86`): o grupo vira `[eu]` e dá 500 (`notificacoes.ts:33-35`). Sem som de "chamando". Mídia: A4-02, A4-03, A4-04 | Botões "Chamada de voz" e "Chamada de vídeo" no cabeçalho; `tipo` como o web; `usuarios` incluindo eu, por `/conversa/usuarios`; `conversa_id`; REST assíncrono; som de chamando em loop (WASAPI/`PlaySound` assíncrono) | F6 | P0 |
| CHA-02 | Iniciar compartilhando a tela | 🔴 | O contrário do web: **toda** chamada já sai compartilhando o monitor principal (`Conversa.Chamada.pas:502`; `Conversa.Chamada.WebRTC.pas:203-221`; `Screen.Capture.pas:274-303`), sem pedir, sem indicador e sem anunciar `{acao:'tela'}`; a tela é gravada no servidor | Só por ação explícita; seletor de monitor ou janela (Windows.Graphics.Capture ou DXGI Desktop Duplication); borda ou indicador visível; anunciar pelo WS 57 | F8 | P3 (remover o envio automático é P0 → A4-01) |
| CHA-03 | Chamada recebida (toque, notificação, modal, 30 s) | 🟡 | 51 → `GET /chamada/dados` → toast no topo com Atender/Recusar (`Conversa.Chamada.pas:334-340`, `:561-599`; `Notificacao.Visualizador.pas:87`) + janela com "Atender". **Sem toque, sem 30 s/`nao_atendeu`**. Sempre "Chamada de Voz" (`:576-579`). O nome exibido é o do primeiro participante que não sou eu, não o de quem ligou (`:567-574`). Sem "Atender só assistindo". Clicar no toast libera o toast dentro do próprio clique (A4-06) | Toast próprio no topo (já existe) ou notificação do Windows com ações; `FlashWindowEx` e sobreposição na barra de tarefas; toque em loop até atender, recusar ou 52; temporizador de 30 s → `recusar {nao_atendeu:true}` | F6 | P0 |
| CHA-04 | Atender (fallback sem mídia; "só assistindo") | 🔴 | `Entrar` = `POST /chamada/entrar` síncrono → `IniciarWebRTC` (tela + microfone) → `AssinarPeersExistentes` uma vez (`Conversa.Chamada.pas:294-302`, `:507-536`). Sem fallback de mídia nem "só assistindo". A mídia não conecta nem toca (A4-02 a A4-04) | Fallback vídeo+áudio → só áudio → só recepção; publicar depois de `entrar`; assinar com retentativas | F6 | P0 |
| CHA-05 | Recusar | 🟡 | `Recusar` → `Sair` → `POST /chamada/recusar {id}` (`Conversa.Chamada.pas:289-292`, `:313`; `Proxy.pas:857-869`). A rota está certa. Use-after-free no toast (A4-06); não há toque a parar | Um caminho só; parar o toque; `nao_atendeu` opcional | F6 | P0 |
| CHA-06 | Ocupado → recusa automática com `nao_atendeu` | ⬜ | O 51 de outra chamada abre segunda janela e corrompe a mídia da primeira, que divide o singleton (A4-09) | Gerenciador de chamadas com uma chamada ativa só; 51 de outra → `recusar {nao_atendeu:true}` sem tocar | F6 | P0 |
| CHA-07 | Atendida/recusada em outro aparelho | ⬜ | 53/54 com o meu id em Recebendo são ignorados (`Conversa.Chamada.pas:346-347`, `:364-365`): continua tocando; atender aqui derruba a publicação do outro aparelho (A4-07) | Parar o toque, fechar o toast e voltar a inativo, como o web (`call.ts:1554-1558`, `:1578-1585`) | F6 | P0 |
| CHA-08 | Chamadas pendentes ao conectar (> 25 s → perdida) | ⬜ | Código só no `Proxy.Extras`, não compilado (`Proxy.Extras.pas:225-236`); token do `TAPIExtras` nunca definido (`:134-141`, `:172-177`). Sem reconexão do WebSocket | Ao conectar e ao reconectar o WS, e ao voltar da hibernação (`WM_POWERBROADCAST`): `GET /chamadas/pendentes` (modelo sem `usuarios`) e regra dos 25 s | F6 | P0 |
| CHA-09 | Cancelar enquanto chama | 🟡 | A rota certa sai pela janela: `crclFinalizarChamadaClick` → `Sair` → `/chamada/cancelar` (`view.pas:122-141`; `Conversa.Chamada.pas:311-312`; `Proxy.pas:843-855`). O "encerrar" da barra de título **não faz nada** (`BarraTitulo.pas:80-100`). Use-after-free no encerramento (A4-06) | Os botões de encerrar da janela, da barra e da barra de tarefas (*thumbnail toolbar*) caem no mesmo comando | F6 | P0 |
| CHA-10 | Entrada/saída dos outros, fim, sincronização a cada 4 s | 🔴 | 54 → uma assinatura sem retentativa (áudio de mão única, §3.1). 55 só encerra em "Simples" (`:399-405`). 52 encerra (`:326-332`). Sem sincronização periódica, sem reconexão (`Conversa.Chamada.WebRTC.pas:449-466`). Tipo ambíguo (A4-22) | Gerenciador de chamadas com: retentativas de WHEP; 55 → `GET dados` → sair se ninguém "Entrou"; timer de 4 s que reassina quem caiu ou está sem trilha | F6 | P0 |
| CHA-11 | Controles (mic, câmera, saída, sair…) | 🟡 | Microfone (`view.pas:101-108` → `Conversa.Chamada.WebRTC.pas:401-409`); "vídeo" liga ou desliga a captura de **tela**, com ícone enganoso (começa "indisponível" transmitindo: `view.pas:149-150`, `:110-120`). Sem saída, dispositivos, câmera, adicionar ou chat | Pílulas com chave como no web (`eaa8bac`); seletores de microfone, saída e câmera (MMDevice/WASAPI e Media Foundation); mute da saída; atalhos (ex.: Ctrl+D microfone); botões na miniatura da barra de tarefas (`ITaskbarList3::ThumbBarAddButtons`) | F6 | P0 |
| CHA-12 | Modos de exibição (grade, destaque, tela única) | ⬜ | Os destinos de vídeo existem, mas ficam **invisíveis** (`Conversa.Chamada.Usuario.view.pas:53-58`; `Conversa.Chamada.Usuarios.Listagem.Item.pas:54-59`): o vídeo remoto nunca aparece. Não há modos | Janela redimensionável; grade (1/2/3/4 colunas); duplo clique destaca; tela cheia (F11) | F6 | P1 |
| CHA-13 | Janela flutuante / barra de chamada | 🟡 | Janela própria de 300×480 + indicador com cronômetro na barra de título da principal (`Conversa.Chamada.pas:538-559`). Fechar só esconde, sem reabrir; o "encerrar" da barra não funciona | Mini-janela compacta opcionalmente no topo (`HWND_TOPMOST`); clicar no indicador reabre; botões na miniatura da barra de tarefas | F6 | P1 |
| CHA-14 | Adicionar participante | ⬜ | `AdicionarUsuario` só no Extras, não compilado (`Proxy.Extras.pas:411-427`). Quando outro adiciona, o FMX recebe 51 e **volta a tocar** (A4-09) | Modal "Adicionar à chamada" com contatos fora da chamada; `PUT /chamada/usuario` um por vez | F6 | P1 |
| CHA-15 | Compartilhar tela com áudio do sistema | ⬜ | Sem áudio do sistema, sem seletor; a captura de tela existe, mas é automática (CHA-02) | WASAPI *loopback* misturado ao microfone; Windows.Graphics.Capture | F8 | P3 |
| CHA-16 | Troca áudio → vídeo (WS 56 + modal de 15 s) | ⬜ | Sem tratamento do 56 (`Conversa.Chamada.WebRTC.pas:27-29`); `AtivarVideo` não compilado; sem câmera | Botão "Vídeo"; ao receber 56, modal "Apenas assistir / Transmitir também" com 15 s | F6 | P1 |
| CHA-17 | Ponteiro remoto (WS 57) | ⬜ | Tipo 57 ausente do enum (`Conversa.Tipos.pas:16-38`) | Desenhar sobre a tela compartilhada; enviar a cada 40 ms pelo mouse | F8 | P2 |
| CHA-18 | Chat da chamada (`PUT /chamada/chat`, WS 57 `chat`) | ⬜ | — | Painel lateral reaproveitando o chat; grupo criado no primeiro clique no campo (`eaa8bac`) | F6 | P2 |
| CHA-19 | Indicador de fala | 🔴 | O waveform existe e desenha linha reta: sem fonte de dados (§3.2) | RMS do PCM decodificado por peer e do microfone (> 0,02, segura 400 ms) → anel verde | F6 | P2 |
| CHA-20 | Qualidade da chamada (ruído, eco, ganho, bitrate, resolução, fps) | ⬜ | Fixo: 1280×720@30, 2 Mbps, Opus 128k estéreo (`Conversa.Chamada.WebRTC.pas:205`; `Audio.Encoder.pas:19-21`); **sem AEC/NS/AGC** (A4-16) | Tela de configurações de chamada; AEC obrigatório (§8) | F7 | P2 (AEC: P0) |
| CHA-21 | Somente recepção | ⬜ | Sem microfone a publicação aborta depois de a tela já sair (§3.2) | Entrar sem dispositivos; "Ativar microfone" e "Ativar câmera" | F6 | P2 |
| CHA-22 | Histórico de chamadas | 🔴 | `GET chamadas` sem filtros → `TChamadaHistorico` com `chamada_id`, `tipo_chamada`, `status_chamada`, `usuario_exibido_nome`, `tipo_acao`, `quantidade_outros_usuarios`… (`Proxy.Tipos.pas:194-214`). O servidor devolve `id`, `tipo`, `status`, `criado_em`, `criado_por`, `conversa_id`, `iniciada`, `finalizada`, `duracao`, `participantes[]` (`chamadas.ts:50-60`, `:429-450`; igual em abril). Resultado: nomes, ícones e status vazios. Status 5 = "Perdida" no FMX × "Desconectada" no servidor. "Ligar novamente" é TODO (`src/chamada/Conversa.Chamada.Detalhe.pas:148-152`) | Reescrever com `ChamadaHistoricoItem`: abas Todas/Perdidas, filtros de/até/contato, agrupar Hoje/Ontem/data, "Ligar novamente" | F6 | P0 |
| CHA-23 | Áudio remoto estável | 🔴 | Há um `waveOut` por peer vivo durante a chamada (conceito certo), mas a reprodução está quebrada (A4-03) e sobrescreve buffers em uso (`Audio.Player.pas:129-141`) | *Jitter buffer* + PLC; mixagem num único dispositivo de saída escolhido; sobreviver a trocas de dispositivo | F6 | P0 |
| CHA-24 | Chat completo da chamada | ⬜ | — | Reusar a tela de chat num painel durante a chamada | F6 | P2 |
| **Gravação** | Publicar vídeo em H264/VP9 (VP8 não é gravado) | 🟡 | Publica H264 (libx264) + Opus, graváveis (`main.go:373-376`, `:392-395`; `mediamtx.docker.yml:32-37`). Mas o vídeo é a **tela** (privacidade), o áudio provavelmente não sai e nada chega ao MediaMTX hoje (§2) | Câmera em H264 (Media Foundation/OpenH264) ou VP9; tela só por ação explícita | F6 | P0 |
| *(apoio)* Base/ICE | `https://host/webrtc` + `GET /api/ice` + `relay` | 🔴 | §1.10 e §1.11 | Base derivada de `Configuracoes.Host`; nova API da DLL com a config ICE | F6 | P0 |
| *(apoio)* Bolha tipo 6 | Resumo da chamada no chat | ⬜ | §3.2 (ver também o A5b, tipos 5–8 ausentes) | Bolha com ícone, tipo, duração ou status, "Ligar de novo" | F2/F6 | P1 |
| *(apoio)* Sons | Chamando e toque | ⬜ | §3.2 | WAV em recurso, laço em thread própria, respeitando "não perturbe" | F6 | P0 |

---

## 5. Código órfão (confirmação do `docs/todo.md`)

| Arquivo | Situação | Evidência |
|---|---|---|
| `lib/tcp.pas` | **Órfão**. Era o canal de áudio TCP até `4759ba5` | Nenhum `uses tcp` no projeto (busca em `*.pas`, `.dpr`, `.dproj`). O commit `4759ba5` tirou `tcp`, `TTCPClient`, `ConectarTCPAudio` etc. de `Conversa.Chamada.pas` (`git show 4759ba5 -- src/chamada/Conversa.Chamada.pas`). `docs/todo.md:57-58` já dizia isso |
| `lib/audio/AudioCapture.pas`, `lib/audio/AudioPlayer.pas` | **Órfãos** desde `4759ba5` | Removidos do `uses` no mesmo commit; sem referências |
| `lib/audio/AudioMixer.pas` | **Morto, mas compilado** só pelo tipo `TClientAudioStream` | `Conversa.Chamada.pas:25`, `:65`; `src/chamada/Conversa.Chamada.Usuarios.Listagem.pas:40`, `:58-76`. `TAudioMixer` nunca é criado; `FClientStreams` nunca é instanciado |
| `lib/audio/AudioTypes.pas` | **Vivo só pelo `TWaveformData`**, que nunca recebe amostras | `AddSamples` sem chamadores (`AudioTypes.pas:20`, `:66`); `TAudioBuffer` só serve ao mixer morto |
| `src/chamada/Conversa.Audio.pas` + `Conversa.Audio.Windows.pas` | **Órfãos e sombreados.** O `.dpr` liga `Conversa.Audio in 'Conversa.Audio.pas'`, da raiz, que só tem `PlayResource` (`Conversa.dpr:30`; `Conversa.Audio.pas:1-33`). A unit homônima em `src/chamada` não é compilada | `Conversa.Audio.Windows.pas:29` herda de `Conversa.Audio.TAudioCapture`, que não existe na unit da raiz: nem compilaria |
| `src/chamada/Conversa.Chamada.Participante.Item.pas` (+ `.fmx`) | **Órfão** | Sem referências fora do próprio arquivo |
| `src/Conversa.Proxy.Extras.pas` | **Não compilado**: fora do `.dpr`/`.dproj`, ninguém faz `uses` | Contém `AtivarVideo`, `AdicionarUsuario`, `Pendentes`; o token próprio nunca é definido |
| `IntToBytes`/`BytesToInt` e `uses IdGlobal`, `Winapi.MMSystem` em `Conversa.Chamada.pas` | Restos do protocolo TCP | `Conversa.Chamada.pas:17`, `:28`, `:116-127`, sem uso |
| `TConversaChamada.Finalizar` | Sem botão (o web também não tem) | `Conversa.Chamada.pas:304-307` |
| `conversa-webrtc/Inicio.view.*`, `Whip.view.*`, `TesteWebRTC.dpr` | App de teste (útil como bancada); fora do executável | — |
| `conversa-webrtc/bin/{ffmpeg,ffplay,ffprobe}.exe`, `avdevice-62`, `avfilter-11`, `avformat-62` | Não usados pelo app; fora do git | `ls`/`git ls-files` |
| `docs/ALTERACOES_TCP_RECONEXAO.md`, `docs/waveform-spec.md` | Descrevem o pipeline morto | `docs/todo.md` §1–§2 (confirmado) |

**Recomendação:** remover `lib/tcp.pas`, `AudioCapture`, `AudioPlayer`, `AudioMixer`, as duas `Conversa.Audio*` de `src/chamada`, o `Participante.Item` e os restos. Mover `TWaveformData` para junto do `TWaveformView`. Decidir o destino do `Proxy.Extras` dentro do plano de API (outro grupo). Marcar os dois docs como legado.

---

## 6. DLLs e licenças

### 6.1 `pion_whep.dll`

| Item | Valor | Evidência |
|---|---|---|
| Tamanho | 19 480 956 B; MD5 `556bf004…`, idêntica em `bin/` e `conversa-webrtc/bin/` | `ls`, `md5sum` |
| Como é gerada | `go build -buildmode=c-shared` com `CGO_ENABLED=1` (Go + GCC MinGW-w64/WinLibs UCRT) | `conversa-webrtc/pion/DOC_COMPILACAO.md`; caminho embutido `C:/Prog/winlibs_staging_ucrt/…/gcc-14.3.0` nas cadeias da DLL |
| Go | **1.26.1**, com diretiva `go 1.22` no `go.mod`. Isso liga *defaults* `GODEBUG` antigos (ex.: `tls3des=1`, `tlssha1=1`, `x509negativeserial=1`), visíveis em `build DefaultGODEBUG=` | Cadeias `go1.26.1` e `build DefaultGODEBUG=…`; `conversa-webrtc/pion/go.mod:3` |
| Pion | `github.com/pion/webrtc/v4 v4.0.0` (out/2024). Dependências: `dtls/v3 v3.0.3`, `ice/v4 v4.0.2`, `interceptor v0.1.37`, `srtp/v3 v3.0.4`, `turn/v4 v4.0.0`… | `go.mod:5-26`; cadeias `dep github.com/pion/… vX` (confere com o `go.mod`) |
| Build | `vcs.modified=true` (árvore suja); **sem `-s -w`**: símbolos e caminhos ficam, daí os 19 MB | Cadeias `build vcs.modified=true` |
| Dependências do sistema | `ws2_32`, `iphlpapi`, `crypt32`, `bcryptprimitives`, `api-ms-win-crt-*` (UCRT) | Cadeias |
| Fontes | `conversa-webrtc/pion/main.go` + `go.mod`/`go.sum` versionados; **a DLL não está no git** (`git status`: `?? bin/pion_whep.dll`) | — |

**Riscos do modelo Go *c-shared*:**
- o runtime Go sobe no `DllMain`, já no carregamento do EXE, porque o import é estático (`Pion.Whep.Binding.pas:24-71`);
- a DLL não pode ser descarregada;
- um `panic` em Go **encerra o processo**;
- exceções Delphi nos callbacks atravessam o cgo e derrubam o processo;
- são dois *runtimes* no mesmo processo, e depurar entre eles é difícil.

**Atualização e vulnerabilidades:** a v4.0.0 tem dois anos de defasagem. Rodar `govulncheck`. Há avisos conhecidos em dependências do Pion de 2025; exemplo provável: `pion/interceptor` < 0.1.39, tratamento de *padding* RTP. Não confirmado se o caminho é exercido aqui, já que nenhum interceptor é registrado.

### 6.2 FFmpeg

| Item | Valor | Evidência |
|---|---|---|
| Versões | `avcodec-62.dll` 62.29.101; `avutil-60` 60.29.100; `swresample-6` 6.4.100; `swscale-9` 9.7.100. **ProductVersion `N-123777-g53537f6cf5-20260331`**: *snapshot* do master de 2026-03-31, linha 8.x, **não é release** | `(Get-Item).VersionInfo` |
| Origem | Build no estilo **BtbN FFmpeg-Builds "win64-gpl-shared"**: `--prefix=/ffbuild/prefix`, `--cross-prefix=x86_64-w64-mingw32-`, `--extra-version=20260331` | Cadeia de configuração em `avcodec-62.dll` |
| Licença do build | **`--enable-gpl --enable-version3` → GPLv3** | idem |
| Bibliotecas externas habilitadas (amostra) | `libx264`, `libx265`, `libxvid`, `libopenh264`, `libopus`, `libvpx`, `libaom`, `libdav1d`, `libsvtav1`, `librav1e`, `libvvenc`, `libmp3lame`, `libvorbis`, `libtheora`, `libopencore-amrnb/wb`, `libsoxr`, `librubberband`, `libplacebo`, `libass`, `libzimg`, `whisper`, `vulkan`, `opencl`, `ffnvcodec`/`cuda-llvm`, `amf`, `libvpl`, `vaapi`, `schannel`, `sdl2`… (`--disable-libfdk-aac`) | idem |
| O que o app usa | Encoder `libx264`; decodificador `h264` nativo; encoder Opus (provavelmente `libopus`) e decodificador `opus` nativo; swscale (BGR0→YUV420P, YUV420P→BGRA); swresample (S16→FLTP) | §1.5 |
| Tamanho | 113 767 424 B só nas 4 DLLs de `bin/` (`avcodec` sozinha: 97,6 MB) | `ls` |
| Binding | `external` estático sem `delayed` (`FFmpeg.Binding.pas:117-242`); offsets à mão (`:46-104`, `:244-370`), comentário "FFmpeg 7.x" | A4-15 |

### 6.3 Licenças e implicações para distribuir (não é parecer jurídico)

- **Pion e Go:** MIT/BSD. Basta incluir os avisos de terceiros.
- **FFmpeg deste build é GPLv3** e inclui componentes GPL (x264, x265, xvid…) e "version3" (opencore-amr).
  - **Distribuir estas DLLs com o app obriga a cumprir a GPLv3:** oferta do código-fonte correspondente do FFmpeg e de cada biblioteca, *scripts* de build e texto da licença.
  - Pela interpretação da FSF, o conjunto ligado dinamicamente é obra combinada. O código do Conversa é MIT, compatível com GPL, **mas a RTL e o FMX da Embarcadero são proprietários e ligados estaticamente ao EXE**. Isso torna a distribuição do conjunto sob GPLv3 juridicamente frágil.
  - Para um app distribuído a clientes, o caminho seguro é um **build LGPL** (BtbN `lgpl-shared` ou build próprio só com o necessário), ou não usar FFmpeg.
- **Patentes H.264 e H.265:** distribuir encoder ou decoder H.264 (x264, decodificador do FFmpeg) pode exigir licença do pool AVC (Via LA), conforme país e volume. As saídas usuais:
  - **OpenH264 em binário baixado da Cisco** (a Cisco paga os royalties);
  - os codecs do próprio Windows (Media Foundation `h264_mf`, decodificador do SO);
  - VP9, que também é gravável.
- **Implicação prática:** o pacote atual (≈127 MiB de DLLs, GPLv3, fora do git e sem *script* de obtenção) **não está pronto para distribuição**.

---

## 7. Problemas encontrados (numeração provisória A4-NN)

| # | Sev. | Onde | Efeito | Correção sugerida |
|---|---|---|---|---|
| A4-01 | **CRÍTICO** | `Conversa.Chamada.pas:469`, `:502`; `Conversa.Chamada.WebRTC.pas:203-221`; `Screen.Capture.pas:259-326`; `view.pas:149-150`; servidor `mediamtx.docker.yml:32-37` | **A tela inteira é transmitida em toda chamada**, inclusive de voz e antes de atenderem, **sem aviso** e com o ícone de vídeo "indisponível". Ela é **gravada no servidor** (90 dias por padrão) e o MediaMTX não tem autenticação (A4-11). Risco grave de privacidade (LGPD) | Nunca enviar vídeo por padrão. Câmera só em chamada de vídeo; tela só por ação explícita com seletor, indicador visível e anúncio pelo WS 57. Até lá, **desligar** o envio de vídeo (`EnviarVideo=False`) ou as chamadas |
| A4-02 | **CRÍTICO** | `main.go:169`, `:353`; `Conversa.Configuracoes.pas:51-52`, `:66-67`; `Conversa.Chamada.WebRTC.pas:180`, `:262`; servidor `docker-compose.yml:123-124`, `mediamtx.docker.yml:20-24`, `turnserver.conf:13-17` | **A mídia não conecta** contra o servidor atual: sem TURN, a base aponta para `localhost:8889` (que no servidor só escuta em 127.0.0.1) e o ICE só tem *host*. As chamadas ficam mudas. As falhas são silenciosas | `GET /api/ice` a cada PC; nova API da DLL recebendo `iceServers` + `iceTransportPolicy`; gathering ≤ 5 s; base `https://<host>/webrtc` derivada de `Configuracoes.Host` (remover `MediaMtxBase` ou deixá-lo só como *override*) |
| A4-03 | **CRÍTICO** | `main.go:684-711` (× `pion/DOC_API.md:175-176`); `Audio.Player.pas:52`, `:144-178` | **Áudio recebido inutilizável:** vai o pacote RTP com cabeçalho para o decodificador Opus, e a saída FLTP é lida como S16 estéreo (só o canal esquerdo, em bytes de float). Resultado: ruído ou silêncio | Em Go: `ReadRTP()` e entregar `pkt.Payload` (e `SequenceNumber`/`Timestamp` para o *jitter buffer*). Em Delphi: `swr_convert` de FLTP para S16 (ou o decodificador `libopus` em S16); *jitter buffer* + PLC |
| A4-04 | **CRÍTICO** (não confirmado sem executar) | `Audio.Encoder.pas:67-83`, `:186-197`; build com `--enable-libopus` | **O áudio enviado provavelmente nunca sai.** (a) `find_encoder` pula o Opus nativo experimental e pega o `libopus`, que não aceita `fltp` → `avcodec_open2` falha → exceção perdida na thread. (b) Mesmo aberto, o `AVFrame` vai sem `ch_layout` e sem `buf[]` → `av_frame_ref` → `av_frame_get_buffer` = `EINVAL` → `avcodec_send_frame` falha em silêncio | Usar `libopus` com S16 intercalado (sem swresample) e `ch_layout` via `av_opt_set(ctx,'ch_layout','stereo')`, e um quadro alocado com `av_frame_get_buffer`. Melhor ainda: chamar a `opus.dll` (BSD) direto. Teste de bancada: publicar e conferir a trilha com `ffprobe` na gravação |
| A4-05 | **CRÍTICO** | `Conversa.Chamada.WebRTC.pas:413-447` × `:337-349`; `:351-388`; `:246-335`; `Mic.Capture.pas:267-287`, `:345-361` | **Corridas e use-after-free:** (a) o callback pega o peer sob lock e usa fora dele enquanto `DesconectarPeer` libera. (b) `Desligar` libera encoders com o callback do waveIn ou a thread de tela ainda dentro. (c) A thread de assinatura registra o peer **depois** do `Desligar`: WHEP zumbi tocando áudio e `ImgRenderer` pendurado. (d) Sem `try/except` nos callbacks `cdecl`: uma exceção atravessa o cgo e derruba o processo | Peers com contagem de referência (interface) ou lock por peer mantido durante o `Feed`; flag "encerrando" + `WhepDisconnect` antes de liberar; aguardar as threads; `try/except` em todo callback exportado; cancelar as assinaturas pendentes no `Desligar` |
| A4-06 | **CRÍTICO** | `Conversa.Chamada.pas:472-483` (`FreeAndNil(Self)`), `:326-332` (usa `FID` depois, `:331`), `:349-354`, `:399-405`, `:199-216`; `view.pas:122-141`; `Notificacao.Item.Chamada.pas:102-114` + `Notificacao.pas:175-186` | **Objetos se autodestroem e continuam em uso:** a chamada libera a si mesma (e a janela de onde veio o clique). O toast é liberado dentro do próprio `OnClick` e depois chama `Fechar` no objeto liberado. `FinalizarTodas` remove do dicionário durante o `for…in` e ainda dá `Free` de novo. Efeito: AVs intermitentes e **exceção ao fechar o app durante uma chamada** | Gerenciador de chamadas de escopo de app como dono único; destruição adiada (`TThread.ForceQueue`); nunca liberar `Self`; fechar o toast com `ForceQueue`; iterar sobre uma cópia (`ToArray`) |
| A4-07 | **ALTO** | `Conversa.Chamada.pas:342-347`, `:358-365`; servidor `chamadas.ts:193-195`, `:209-210`; padrão `overridePublisher` do MediaMTX | **Atendida ou recusada em outro aparelho:** o FMX continua tocando até o 52. Se o usuário atender no FMX, publica no mesmo `call-C-u-EU` e **derruba a mídia do aparelho que já estava na chamada** | 53/54 com o meu id em Recebendo → parar o toque e ir a inativo; só uma publicação por usuário |
| A4-08 | **ALTO** | `Conversa.Chamada.WebRTC.pas:264-275`, `:277-331`; `Conversa.Chamada.pas:358-387`; `main.go:186-301` | **Sem retentativa de WHEP, sincronização ou reconexão:** quem liga assina antes de quem atende publicar → **áudio de mão única**. Qualquer queda é permanente. `WhepConnect` vaza o `pc` nos erros. O peer só é registrado depois do `SetRemoteDescription`, e o primeiro IDR se perde | Retentativas 12×0,8 s (áudio) e 40×1 s (vídeo); sincronização a cada 4 s com `GET /chamada/dados`; republicar e reassinar em `failed`/`disconnected`; registrar o peer antes do SRD; fechar o `pc` em todo erro |
| A4-09 | **ALTO** | `Conversa.Chamada.pas:170-190`, `:276`, `:334-340`; `Conversa.Chamada.WebRTC.pas:61-114`; servidor `chamadas.ts:283-291`, `:167` | **51 durante a chamada** (alguém adicionou um participante) → volta a "Recebendo", com toast e botão Atender. Se recusar: `POST /chamada/recusar` marca como "Recusou" quem tem `entrou_em` nulo, **inclusive o criador**. **Ocupado:** segunda janela e mesmo singleton de mídia, e atender a segunda corrompe a primeira | 51 da chamada atual → só sincroniza peers; 51 de outra → `recusar {nao_atendeu:true}`; uma chamada ativa por vez |
| A4-10 | **ALTO** | `Proxy.Tipos.pas:186-217`; `Proxy.pas:313-334`; servidor `chamadas.ts:50-60`, `:429-450` | **Histórico** com modelo que não existe no servidor (nem em abril): lista sem nome, status e ícone; sem filtros; "Ligar novamente" é TODO | Modelo `ChamadaHistoricoItem` (doc 01 §9.7) |
| A4-11 | **ALTO** (servidor; agrava o A4-01) | servidor `mediamtx.docker.yml:26-38`, `nginx.conf:135-140` (doc 08 S4); FMX `main.go:256-266`, `:452-455`; `Conversa.Chamada.WebRTC.pas:185-191`, `:264-268` | **O MediaMTX não tem autenticação:** qualquer usuário logado (que recebe TURN pelo `/api/ice`) pode assistir ou publicar em `call-<id>-u-<uid>`, com ids sequenciais. Junto com o A4-01, é possível **ver a área de trabalho de outros**. A DLL só conhece `Basic` e o FMX manda vazio | Servidor: `authMethod: http` ou JWT com token de chamada (S4). DLL: aceitar `Authorization: Bearer`. FMX: mandar o token |
| A4-12 | **ALTO** | `Conversa.Chamada.Usuario.view.pas:53-58`; `Conversa.Chamada.Usuarios.Listagem.Item.pas:54-59`; `Video.Decoder.pas:294-305`; `main.go:190-197`, `:593-682` | **O vídeo remoto nunca é exibido** (`TImage` invisível). Não há câmera. O decodificador recebe NAL por NAL sem `AV_CODEC_FLAG2_CHUNKS`, e quadros com vários *slices* (comuns no H264 do Chrome) se corrompem. VP8/VP9 vira lixo | Mostrar o destino ao receber o primeiro quadro; agrupar por *access unit* (bit *marker* e timestamp RTP) na DLL ou usar `flags2 +chunks`; conferir o `MimeType` da trilha |
| A4-13 | **ALTO** | `Pion.Whep.Binding.pas:24-71`; `FFmpeg.Binding.pas:117-242`; `git status` (`?? bin/*.dll`) | **O app não abre sem as 5 DLLs (≈127 MiB)**, mesmo sem chamada, porque o import é estático. As DLLs estão fora do git, sem *script* de obtenção nem *hash*. O runtime Go sobe sempre | `delayed` ou `LoadLibrary` só ao iniciar a primeira chamada, com mensagem amigável se faltar; *script* de build e obtenção com *hash*; instalador |
| A4-14 | **ALTO** (legal) | §6.3; `avcodec-62.dll` (`--enable-gpl --enable-version3`, libx264/x265); `LICENSE` (MIT) | **Distribuir o pacote atual exige cumprir a GPLv3**, o que é incompatível na prática com a RTL proprietária ligada estaticamente. Há também risco de patente H.264 | Build LGPL mínimo, OpenH264 da Cisco ou codecs do Windows, ou trocar a pilha (§8); arquivo de avisos de terceiros |
| A4-15 | **ALTO** | `FFmpeg.Binding.pas:46-56`, `:74-96`, `:316-322`, `:340-370` | **Offsets de struct escritos à mão** ("7.x") contra a DLL 62.29: o `pts` é gravado no offset 128, mas pelo layout público do `AVFrame` (`format` → `pict_type` → `sample_aspect_ratio` → `pts`) ele fica em **136**. O valor cai no `sample_aspect_ratio` e o quadro vai com `pts = AV_NOPTS_VALUE`. Os offsets de `AVCodecContext` (largura, GOP, `pix_fmt`, `max_b_frames`) **não foram confirmados** e mudam entre versões maiores | Trocar os *setters* por `av_opt_set` (`video_size`, `pixel_format`, `g`, `bf`, `time_base`) ou por um *shim* C compilado contra os cabeçalhos da versão empacotada (o `whep-viewer-spec.md:1366-1452` já previa isso); conferir a versão em tempo de execução (`avcodec_version`) |
| A4-16 | **ALTO** | `Mic.Capture.pas` (waveIn cru); `Audio.Encoder.pas:19-21`; `Audio.Player.pas:95` | Sem AEC, NS e AGC: **eco** com alto-falante. Opus 128 kbps estéreo para voz (o padrão do web é mono, com 32k no modo voz). Sem escolha de microfone ou saída. MME com latência alta | AEC obrigatório: WebRTC APM, o DSP "Voice Capture" do Windows (DMO de AEC) ou a pilha nova (§8); Opus mono 24–32 kbps com FEC; WASAPI em modo comunicação; seletores de dispositivo |
| A4-17 | MÉDIO | `main.go:171-179`, `:355-362`, `:519-523`; `Video.Encoder.pas:60`; `Audio.Player.pas:129-141` | Pion sem interceptores: **sem NACK, RTCP, PLI/FIR, TWCC nem controle de congestionamento**. O FMX não lê RTCP do *sender*. Vídeo com **2 Mbps fixos** sobre TURN/TCP: atraso cresce em rede fraca. Duração fixa de 33 ms com a taxa real menor gera timestamps errados. Sem *jitter buffer* ou PLC. O waveOut sobrescreve buffers em uso | `webrtc.RegisterDefaultInterceptors` + laço de leitura de RTCP; GCC/REMB ou ao menos um limite adaptativo; timestamps pelo relógio real; *jitter buffer* (`pion/interceptor/jitterbuffer` ou próprio) |
| A4-18 | MÉDIO | `Mic.Capture.pas:267-287`, `:345-361` | Codificação Opus e chamada cgo **dentro do `WaveInProc`** (o MSDN proíbe chamar funções do sistema ali); corrida entre `Stop` e o callback (`FRunning`) | O callback só sinaliza (evento); uma thread própria lê, codifica e envia. Ou WASAPI em modo evento |
| A4-19 | MÉDIO | `Proxy.pas:818-937` chamado em `Conversa.Chamada.pas:296`, `:410`, `:462`; `Conversa.Chamada.WebRTC.pas:449-466`; `main.go:245`, `:268`, `:440`, `:457` | REST **síncrono na thread da UI**, inclusive no tratamento de WS (a tela congela). Exceções sem tratamento dentro do `Queue`. Erros silenciosos: `OnErro` nunca atribuído; exceções das threads anônimas perdidas; estado 3 só logado. `http.Client` sem *timeout* e gathering sem limite deixam threads presas | Chamadas assíncronas com estado; `try/except` + mensagem ao usuário ("Erro ao conectar com <nome>"); *timeouts* (HTTP 10 s, gathering 5 s) |
| A4-20 | MÉDIO | `Conversa.Chamada.WebRTC.pas:287-324` | Um `TThread.Queue` por quadro com cópia W×H×4 (3,7 MB em 720p), sem descarte, e render com `FLock` tomado (bloqueia os callbacks de áudio) | Um quadro "mais recente" por peer (substitui o anterior) + flag "renderizando"; render sem o lock global; converter direto para o formato do `TBitmap` |
| A4-21 | MÉDIO | `Conversa.Chamada.pas:433-470`; `Conversa.Dados.pas:207-209`; `Proxy.pas:582` | `iniciar` sem `tipo` nem `conversa_id`: sem resumo tipo 6 e com o tipo deduzido pelo número de pessoas. Grupo vira `[eu]` → 500 → `FID = 0` → WHIP em `call-0-u-<eu>`; a segunda falha dá `EListError` (chave 0 repetida). A janela abre antes da API, sem desfazer em caso de erro | Membros por `/conversa/usuarios`; `tipo` como o web; `conversa_id` da conversa ativa; conferir `Status` e desfazer |
| A4-22 | MÉDIO | `Conversa.Chamada.pas:349`, `:399`; servidor doc 01 §9.1 (S11) | O FMX usa `tipo` como Simples/Grupo para decidir o fim, mas o web manda áudio/vídeo. A 1:1 de **vídeo** do web nunca termina no FMX pelo 55; a de **áudio em grupo** termina na primeira saída | Decidir o fim por `GET /chamada/dados` (ninguém mais "Entrou"), como o web; acompanhar o S11 |
| A4-23 | MÉDIO | `BarraTitulo.pas:80-100`; `view.pas:110-120`, `:149-150`; `Detalhe.pas:148-152`; `FormularioBase.pas:416-419` | Controles mortos ou enganosos: "encerrar" da barra de título não faz nada; ícone de vídeo errado; "Ligar novamente" é TODO; fechar a janela a esconde sem forma de reabrir; não há sons de chamada | Comandos únicos; indicador clicável reabre a janela; sons |
| A4-24 | MÉDIO | `Conversa.Chamada.pas:65-66`, `:245-259`; `AudioTypes.pas:20`, `:66`; `Waveform.pas:89-94` | Indicador de fala (waveform) **sem fonte de dados**: desenha linha reta | RMS do PCM do microfone e de cada peer (CHA-19) ou remover |
| A4-25 | BAIXO | cadeias da `pion_whep.dll`; `go.mod:3-5` | DLL com símbolos (19 MB), `vcs.modified=true`, diretiva `go 1.22` (GODEBUG legado de TLS e x509); Pion `v4.0.0` defasado | Build reprodutível com `-trimpath -ldflags "-s -w"`, `go` ≥ 1.25 no `go.mod`, Pion atual, `govulncheck` no CI |
| A4-26 | BAIXO | `main.go:56`, `:62` | O log da DLL pode cair em `C:\pion_whep.log` (raiz do disco) | `%LOCALAPPDATA%\Conversa\logs` |
| A4-27 | BAIXO | `Conversa.Chamada.WebRTC.pas:177`, `:253`; `Conversa.Chamada.pas:499-504`, `:529-534` | Corrida: `AssinarDePeer` confere `FChamadaId`, que só é definido dentro da thread de publicação. A assinatura pode sair com id 0 e desistir | Definir chamada e usuário antes de criar as threads |
| A4-28 | BAIXO | `Conversa.Chamada.WebRTC.pas:401-409`; `view.pas:276` | Mute fecha e reabre o dispositivo (estalo, latência). A UI marca o microfone "Ativo" ao entrar sem saber se o dispositivo abriu | Mute por *flag* (enviar silêncio ou DTX); estado vindo da captura |
| A4-29 | BAIXO | `Conversa.Chamada.pas:657-674`; `Conversa.Chamada.Usuario.view.fmx:7` | Cronômetro com milissegundos, atualizado a cada 30 ms | `mm:ss`/`hh:mm:ss` a cada 1 s |
| A4-30 | BAIXO | `Proxy.Tipos.pas:133-141`, `:170`; `Conversa.Tipos.pas:16-38` | Status 5 "Perdida" × servidor "Desconectada"; *typo* `adicinoado_em`; enum sem 57 | Alinhar com doc 01 §9.1 e §6.4 |
| A4-31 | BAIXO | §5 | Código órfão compilado ou no repositório | Remover (§5) |

---

## 8. Avaliação da pilha de mídia (Pion + FFmpeg)

### 8.1 O que existe e o que falta

O que existe é um **protótipo portado de um visualizador WHEP** (`conversa-webrtc/whep-viewer-spec.md`). O commit `4759ba5` foi coescrito por IA. **Não há sinal de teste de ponta a ponta:**
- o áudio tem defeitos dos dois lados;
- o vídeo remoto é invisível;
- não há TURN.

Para chegar ao nível do web, a pilha atual precisaria de:

| Necessidade | Situação no Pion + FFmpeg | Esforço |
|---|---|---|
| TURN/relay, gathering com limite, autenticação Bearer | Pion suporta; falta API na DLL | Baixo |
| Retentativas, sincronização, reconexão, máquina de estados | Lógica em Delphi | Médio (necessário em qualquer pilha) |
| NACK, RTCP, PLI, TWCC e controle de congestionamento | Interceptores do Pion (o GCC ainda é experimental) | Médio |
| *Jitter buffer*, PLC e sincronismo A/V | Construir (`jitterbuffer`/`samplebuilder` do Pion + PLC do Opus) | **Alto** |
| **AEC, NS e AGC** | Não existe no Pion nem no FFmpeg. Exige WebRTC APM (C++) ou o DSP "Voice Capture" do Windows (COM/DMO) | **Alto** |
| Câmera, dispositivos, troca a quente | Media Foundation / MMDevice via COM em Delphi | Médio-alto |
| Tela com seletor e áudio do sistema | Windows.Graphics.Capture + WASAPI *loopback* | Médio-alto |
| Codificação por hardware, H264 sem GPL | Media Foundation (`h264_mf`) ou OpenH264 | Médio |
| Licenças e tamanho | Build LGPL mínimo ou abandonar o FFmpeg | Médio |
| Estabilidade de dois *runtimes* (Go + Delphi) | Callbacks cgo, `panic` mata o processo, DLL que não descarrega | Risco permanente |

**Resumo:** continuar significa **escrever um motor de VoIP**. Mesmo pronto, ele teria qualidade inferior à do motor do Chrome, usado pelo web: AEC3, NetEQ e GCC ajustados há anos.

### 8.2 Alternativas no Delphi/Windows

| Opção | Prós | Contras e riscos | Esforço (ordem de grandeza, **estimativa grosseira**) |
|---|---|---|---|
| **A. WebView2 (Edge) hospedando o módulo de chamada do web**: FMX `TWebBrowser` com motor Edge, ou WebView4Delphi (verificar a licença) | **Paridade imediata e mantida pelo próprio web**: `call.ts`, TURN, H264/VP9, AEC/NS/AGC, `getDisplayMedia` com áudio do sistema, ponteiro, chat, histórico. O H.264 vem licenciado no Edge. O *runtime* Evergreen é atualizado pela Microsoft (segurança). Nenhuma DLL de mídia nossa | Janela de chamada em HTML dentro do app FMX. O WebView2 Runtime precisa existir (vem no Win11; no Win10 normalmente vem com o Edge; há *bootstrapper*). Memória de ~150–300 MB por instância. Permissões de mic/câmera: dá para conceder automaticamente à própria origem pela API do WebView2 (no FMX puro, **não confirmado**; o WebView4Delphi expõe). Exige no web uma rota de "chamada embutida" + troca do token por `postMessage`/script inicial. Toque, toast e bandeja continuam em Delphi | **2–4 semanas** |
| **B. libwebrtc nativa via DLL** (ex.: `webrtc-sdk/libwebrtc`, usado pelo flutter-webrtc no Windows) + *shim* C para Delphi | Mesmo motor do Chrome (AEC3, NetEQ, GCC, simulcast); ADM WASAPI e captura de câmera e tela embutidos; UI 100% nativa FMX; sem GPL. VP9 é gravável, e o H264 depende do build (verificar se inclui OpenH264) | API C++ (exige *shim* C estável); renderizar I420 em FMX; atualizar a libwebrtc periodicamente; DLL de ~20–30 MB | **8–14 semanas** |
| **C. Continuar com Pion + FFmpeg** | Já existe um esqueleto; API pequena; o Pion é bom para *ingest*/*egress* | Todo o §8.1. Qualidade de áudio arriscada (eco); GPL/patentes; dois *runtimes* | **16–30+ semanas**, com risco de qualidade |
| D. CEF (CEF4Delphi) | Igual à A em capacidade | Builds padrão sem H.264; ~200 MB; atualização por nossa conta | 3–5 semanas, pior que a A |
| E. Componentes comerciais de WebRTC para Delphi | Possível atalho | Não avaliados; dependência de fornecedor | — |

### 8.3 Recomendação franca

1. **Agora (P0, qualquer que seja a decisão):**
   - desligar o envio automático da tela (A4-01);
   - pôr as chamadas WebRTC atrás de *feature flag*;
   - tornar o carregamento das DLLs tardio (A4-13), para o app não depender de 127 MiB de DLLs GPL que não estão no git;
   - corrigir os *use-after-free* que derrubam o app mesmo sem mídia (A4-06).
2. **Pilha de mídia:** **não seguir com Pion + FFmpeg para chamadas bidirecionais.**
   - **Preferência: WebView2 com o módulo de chamada do web.** Dá a paridade mais rápida e o menor custo de manutenção (as correções do web chegam ao desktop no mesmo deploy), além de resolver licenças e AEC de uma vez.
   - O FMX fica com o que o desktop faz melhor: toque, toast no topo, bandeja, barra de tarefas, atalhos, "ocupado", pendentes.
   - **Se a equipe exigir UI nativa:** libwebrtc via `webrtc-sdk` com um *shim* C pequeno (PeerConnection, trilhas, *sinks* de quadro). A lógica de chamada em Delphi pode copiar a do `call.ts`.
3. **O que reaproveitar do trabalho atual:**
   - a máquina de estados e as telas, depois de reescritas (gerenciador de chamadas);
   - o histórico, depois do modelo novo;
   - o toast de chamada;
   - a bancada `conversa-webrtc/`, como ferramenta de teste do MediaMTX.
4. **Registrar a decisão em ADR** (como o FC-001 do Android) com estes critérios: AEC, licença, tamanho do instalador, esforço, manutenção e UI nativa × HTML.

---

## 9. Rascunho de fila (prefixo provisório FX-7nn, formato do doc 06)

- [ ] **FX-700 · P0 · Parar o envio automático da tela** (A4-01).
  - `PublicarLocalNaSala(…, EnviarVideo=False, …)` até existir câmera ou compartilhamento explícito.
  - **CP:** em chamada de voz, nenhuma trilha de vídeo no SDP do WHIP e nenhuma gravação de vídeo no MediaMTX.
- [ ] **FX-701 · P0 · DLLs sob demanda e *feature flag*** (A4-13).
  - `delayed` ou `LoadLibrary` só na primeira chamada; mensagem se faltar DLL.
  - **CP:** o EXE abre numa máquina sem as DLLs e o chat funciona.
- [ ] **FX-702 · P0 · ADR da pilha de mídia** (§8).
  - **CP:** ADR commitado; protótipo de 1 dia da opção escolhida com áudio nos dois sentidos via TURN.
- [ ] **FX-703 · P0 · Gerenciador de chamadas de escopo de app** (A4-05, A4-06, A4-09, A4-22).
  - Estados `Inativo`, `Chamando`, `Recebendo`, `Conectando`, `Ativa`, `Encerrando`.
  - Dono único dos objetos e uma chamada ativa só.
  - Destruição adiada; `try/except` nos callbacks.
  - **CP:** testes das transições da tabela do doc 03 §5.9; fechar o app em chamada sem exceção.
- [ ] **FX-704 · P0 · ICE/TURN e base `/webrtc`** (A4-02).
  - `GET /api/ice` a cada PC; `relay`; gathering ≤ 5 s; base derivada de `Configuracoes.Host`.
  - **CP:** chamada FMX ↔ web em redes diferentes com áudio nos dois lados.
- [ ] **FX-705 · P0 · WHIP/WHEP robustos** (A4-08, A4-19).
  - Retentativas 12×0,8 s e 40×1 s; sincronização a cada 4 s; republicar e reassinar em `failed`.
  - Peer registrado antes do SRD; *timeouts*.
  - **CP:** desligar e religar o Wi-Fi no meio da chamada recupera em menos de 10 s.
- [ ] **FX-706 · P0 · Áudio correto + AEC** (A4-03, A4-04, A4-16, A4-17, A4-18; resolvido pela pilha nova se a escolha for A ou B).
  - **CP:** fala nos dois sentidos com alto-falante, sem eco; trilha Opus válida na gravação.
- [ ] **FX-707 · P0 · Chamada recebida** (CHA-03).
  - Toque; 30 s → `recusar {nao_atendeu:true}`; "Vídeo/Áudio"; nome de quem ligou; toast seguro.
- [ ] **FX-708 · P0 · Ocupado, outro aparelho e 51 da chamada atual** (CHA-06, CHA-07, A4-07, A4-09).
- [ ] **FX-709 · P0 · Pendentes** (CHA-08).
  - Ao conectar, ao reconectar o WS e ao retomar da hibernação; regra dos 25 s.
  - **Depende** da reconexão do WebSocket (outro grupo).
- [ ] **FX-710 · P0 · Eventos da chamada ativa** (CHA-10).
  - 55 → `GET dados` → sair se ninguém "Entrou"; 52; 53 em 1:1.
- [ ] **FX-711 · P0 · Iniciar** (CHA-01, A4-21).
  - `tipo`, `usuarios` (incluindo eu, por `/conversa/usuarios`), `conversa_id`; assíncrono; desfazer em caso de erro; som de chamando.
- [ ] **FX-712 · P0 · Histórico** (CHA-22, A4-10).
  - `ChamadaHistoricoItem`; abas, filtros, "Ligar novamente".
- [ ] **FX-713 · P0 · Licenças** (A4-14).
  - Sem FFmpeg GPL no pacote; avisos de terceiros; *script* reprodutível de obtenção e build das DLLs (se ainda houver).
- [ ] **FX-714 · P1 · Vídeo** (CHA-04 parte vídeo, CHA-12, CHA-16, A4-12).
  - Câmera; exibição remota; grade e destaque; 56 + modal de 15 s.
- [ ] **FX-715 · P1 · Controles e dispositivos** (CHA-11).
  - Microfone, saída, câmera; mute da saída; atalhos; botões na barra de tarefas.
- [ ] **FX-716 · P1 · Janela e indicador** (CHA-13, A4-23).
- [ ] **FX-717 · P1 · Adicionar participante** (CHA-14).
- [ ] **FX-718 · P1 · Bolha tipo 6** (ver também o A5b).
- [ ] **FX-719 · P2 · Chat da chamada, 57 (tela e ponteiro), indicador de fala, somente recepção, qualidade** (CHA-17 a CHA-21, CHA-24).
- [ ] **FX-720 · P2 · Limpeza do código órfão** (§5, A4-31).

---

## 10. Dependências com outros grupos e com o servidor

- **Servidor:**
  - **S4** (autenticação do MediaMTX): bloqueia a segurança da mídia. A DLL ou a pilha nova precisa mandar `Bearer`.
  - **S11** (`tipo` ambíguo): afeta o fim da chamada no FMX (A4-22).
  - O servidor **não manda o 52** quando a chamada termina por saídas (doc 01 §9.2), e o cliente precisa deduzir o fim.
  - O `adicionarUsuarioChamada` manda 51 a quem já está na chamada (o cliente deve ignorar).
- **Conexão (WebSocket):**
  - o Bird socket está sem `AutoReconnect` e sem tratamento de `close` (`Conversa.Dados.pas:420-451`);
  - depois de uma queda não chegam mais 51–55 e não há pendentes;
  - a URL `wss://host/ws/` *staged* está certa.
- **Conversas:** `/conversa/dados` não existe no servidor atual (`Proxy.pas:582` × `conversa/src/rotas.ts:86`). Sem `/conversa/usuarios`, a chamada em grupo inicia só comigo.
- **Mensagens (A5b):** o tipo 6 (resumo da chamada) não existe no modelo.
- **API/configurações:** `MediaMtxBase` deve sumir ou ser derivado do `Host`. O `conversa.json` guarda `Senha` em texto (`Conversa.Configuracoes.pas:16`), o que é de outro grupo, mas vale registrar.

---

## 11. Arquivos lidos

**FMX:**
- `src/chamada/*.pas` (todas), `Conversa.Chamada.view.fmx` (cabeçalho e eventos), `Conversa.Chamada.BarraTitulo.fmx`, `Conversa.Chamada.Usuario.view.fmx`;
- `conversa-webrtc/*.pas` (Audio.Encoder, Audio.Player, FFmpeg.Binding, Mic.Capture, Pion.Whep.Binding, Screen.Capture, Video.Decoder, Video.Encoder; trechos de Inicio.view);
- `conversa-webrtc/pion/main.go`, `go.mod`, `DOC_API.md`, `DOC_COMPILACAO.md`, `DOC_WHIP_API.md`, `DOC_WHIP_DELPHI.md` (trechos); `conversa-webrtc/whep-viewer-spec.md` (estrutura, §10); `conversa-webrtc/bin/pion_whep.h`;
- `lib/tcp.pas` (cabeçalho), `lib/audio/*.pas` (uses e tipos), `Conversa.Audio.pas`, `Conversa.Dados.pas` (socket, login, conversas), `Conversa.dpr`, `Conversa.dproj` (referências), `.gitignore`, `LICENSE`;
- `src/Conversa.Proxy.pas` (chamadas, histórico, `conversa/dados`), `src/Conversa.Proxy.Tipos.pas`, `src/Conversa.Proxy.Extras.pas`, `src/Conversa.Eventos.pas`, `src/Conversa.Tipos.pas` (enums);
- `src/notificacao/Conversa.Notificacao.Item.Chamada.pas`, `src/notificacao/Conversa.Notificacao.pas` (apresentar/fechar), `Conversa.Notificacao.Visualizador.pas` (topo);
- `src/configuracoes/Conversa.Configuracoes.pas`, `src/base/Conversa.FormularioBase.pas` (fechar), `src/chat/Conversa.Chat.pas` (botão de chamada), `src/principal/Conversa.Principal.pas` (histórico), `Conversa.Tela.Inicial.view.pas` (`FinalizarTodas`);
- `lib/bird-socket-client/Bird.Socket.Client.pas` (*dispatch*/reconexão);
- `docs/todo.md`, `docs/ALTERACOES_TCP_RECONEXAO.md` e `docs/waveform-spec.md` (estrutura);
- `git log`/`git show 4759ba5`/`git diff --cached`;
- DLLs: `VersionInfo`, MD5, cadeias (configuração do FFmpeg, *buildinfo* do Go, nomes de DLL).

**Servidor (`779c8ed`):**
- `src/chamadas.ts` (inteiro), `src/websocket.ts` (inteiro), `src/notificacoes.ts:25-39`, `src/rotas.ts` (chamadas e ICE), `src/configuracao.ts` (TURN);
- `bin/mediamtx/mediamtx.docker.yml`, `bin/mediamtx/Dockerfile`, `bin/coturn/turnserver.conf` (segredo omitido), `bin/nginx/nginx.conf`, `docker-compose.yml` (coturn, mediamtx, api);
- abril: `git show 56e7cc0:src/conversa/conversa.api.pas` (histórico de chamadas e TODOs do MediaMTX).

**Web (`e8d82cb`):** `src/stores/call.ts` (ICE, URLs, WHIP, WHEP, codecs, retentativas, eventos 51–57, pendentes, iniciar, aceitar, recusar, sair, cancelar), `src/composables/useCallPopup.ts` (sons).

**Auditoria Android:** doc 01 §9 (inteiro); doc 03 §3.7, §5 e CHA-24; doc 05 (legenda e linhas CHA); doc 06 (FC-700…723); doc 08 S4.
