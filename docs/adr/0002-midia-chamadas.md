# ADR 0002 — Pilha de mídia das chamadas no cliente Windows

- **Status:** **proposto** — a decisão depende do protótipo da etapa 0.5 do `TODO.md` (FC-700)
- **Data:** 2026-10-08
- **Base:** `docs/auditoria-2026-10/04-auditoria-fmx.md` (#1, #8, #12–#14, #35–#38, #63–#65), `07-plano-nova-base.md` §6, `apoio/A4-chamadas-midia.md` §8

## Contexto
- A pilha atual é **Pion (DLL em Go) + FFmpeg 8 (build GPLv3)**, ligada por *import* estático. O exe não abre sem as 5 DLLs (~127 MiB), mesmo sem chamada.
- Contra o servidor atual, nenhuma chamada funciona de ponta a ponta:
  - não usa `GET /api/ice` nem TURN, e a base aponta para `http://localhost:8889`;
  - o áudio recebido chega com o cabeçalho RTP e no formato errado; o enviado provavelmente nunca sai;
  - o vídeo remoto nunca é exibido; não há câmera; o vídeo enviado é **a tela inteira**, sempre.
- Mesmo corrigida, a pilha não tem **cancelamento de eco, supressão de ruído, ganho automático, *jitter buffer* nem controle de banda** — coisas que o web recebe prontas do navegador.
- O FFmpeg GPLv3 com x264/x265 torna a distribuição juridicamente frágil (RTL proprietária ligada estaticamente) e traz risco de patente do H.264.
- O servidor exige: TURN sobre TCP com `iceTransportPolicy: relay`; WHIP/WHEP em `<base>/webrtc/call-<chamada>-u-<usuario>`; vídeo **H264 ou VP9** para ser gravado; áudio Opus.

## Opções

| Opção | Resumo | Esforço (ordem de grandeza) |
|---|---|---|
| **A — WebView2 com o módulo de chamada do web** | Janela de chamada FMX com um `TWebBrowser` em modo Edge (ou WebView4Delphi) carregando uma página "chamada embutida" do próprio servidor, que reaproveita `conversa-web/src/stores/call.ts`; ponte JS ↔ Delphi para sinalização, estado e token. O gerenciador de chamadas, toque, notificação, bandeja e histórico continuam em Delphi | 2–4 semanas (+ a rota no web) |
| B — libwebrtc nativa | `webrtc-sdk/libwebrtc` + *shim* C; interface 100% FMX; mesmo motor do Chrome | 8–14 semanas |
| C — Pion + FFmpeg corrigido | Corrigir ICE, áudio, *offsets*, threads; acrescentar AEC/NS/AGC (WebRTC APM ou DSP do Windows), *jitter buffer*, controle de banda; FFmpeg LGPL | 16–30+ semanas, com risco de qualidade |

## Decisão (proposta)
**Prototipar a opção A primeiro.** Se ela atender aos critérios abaixo, adotá-la; senão, prototipar a B. A C fica só como reserva. Em qualquer caso, a mídia fica atrás da interface `IMidiaChamada`.

**Critérios do protótipo (todos obrigatórios):**
1. áudio nos dois sentidos entre o FMX e o web, em redes diferentes, pelo TURN;
2. com alto-falante, **sem eco** para o outro lado;
3. vídeo da câmera nos dois sentidos; tela só por ação explícita, com o seletor e o indicador do sistema;
4. a gravação aparece no MediaMTX (H264 ou VP9 + Opus);
5. microfone e câmera concedidos à página sem aviso do navegador (pela API de permissões do WebView2) — confirmar no FMX do Delphi 12;
6. a janela de chamada convive com a bandeja, a chamada recebida no topo e o "minimizar" do app.

## Consequências (se A for aceita)
- Remove do app a `pion_whep.dll` e as DLLs do FFmpeg (e o problema de licença), e traz para o desktop o cancelamento de eco e o resto do motor do navegador.
- Exige no `conversa-web` uma rota de chamada embutida e um jeito seguro de passar o token (pendência a abrir no web; doc 06, Bloco M).
- Depende do WebView2 Runtime (presente no Windows 10/11 atualizados; o instalador leva o *bootstrapper*).
- A interface da chamada passa a ser HTML (a do web), com as cores do FMX aplicadas pela página, se for o caso.
- A bancada `conversa-webrtc/` continua útil como ferramenta de teste do MediaMTX.
