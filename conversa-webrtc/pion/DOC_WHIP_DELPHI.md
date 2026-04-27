# WHIP — Lado Delphi

## Visão Geral

O lado Delphi do WHIP captura tela e microfone, encoda os streams com FFmpeg
e envia para um servidor WHIP (ex: MediaMTX) via a DLL Go (`pion.dll`).

```
TScreenCapture ──► TVideoEncoder ──► WhipSendVideo(handle, data, size, durationMs)
                   (H264 / BGR0→YUV420P)

TMicCapture ─────► TAudioEncoder ──► WhipSendAudio(handle, data, size, 20)
                   (Opus / S16→FLTP)
```

---

## Pré-requisitos

### DLLs FFmpeg (Win64) na pasta do executável
| DLL | Versão | Uso |
|-----|--------|-----|
| `avcodec-62.dll` | FFmpeg 7.x | Encoder H264 + Opus |
| `avutil-60.dll` | FFmpeg 7.x | AVFrame, AVPacket, av_opt |
| `swscale-9.dll` | FFmpeg 7.x | BGR0 → YUV420P |
| `swresample-6.dll` | FFmpeg 7.x | S16 → FLTP (para Opus) |

O `avcodec-62.dll` deve ser compilado com `--enable-libx264` para H264.

### DLL Go
| DLL | Exportações usadas |
|-----|--------------------|
| `pion.dll` | `WhipInit`, `WhipConnect`, `WhipSendVideo`, `WhipSendAudio`, `WhipDisconnect` |

---

## Units Delphi

### `Screen.Capture.pas` — TScreenCapture
Captura a tela principal via GDI em uma thread dedicada.

```pascal
var Cap := TScreenCapture.Create;
Cap.OnFrame := procedure(Data: PByte; W, H: Integer)
begin
  // Data = W*H*4 bytes, formato BGR0 (32bpp, alpha=0), top-down
end;
Cap.Start(30);  // 30 FPS
// ...
Cap.Stop;
Cap.Free;
```

**Notas:**
- Entrega `BGR0` (equivalente a `AV_PIX_FMT_BGR0 = 123`), não BGRA.
- O buffer `Data` é válido somente durante a execução do callback.
- `Stop` aguarda a thread terminar (bloqueante).

---

### `Mic.Capture.pas` — TMicCapture
Captura microfone via waveIn (MMSystem).

```pascal
var Mic := TMicCapture.Create(48000, 2);  // 48kHz, estéreo
Mic.OnData := procedure(PCM: PByte; Samples: Integer)
begin
  // PCM = S16 interleaved estéreo
  // Samples = número de pares L+R (ex: 960 = 20ms)
end;
Mic.Start;
// ...
Mic.Stop;
Mic.Free;
```

**Notas:**
- Usa pool de 4 buffers × 3840 bytes (960 amostras × 2 canais × 2 bytes).
- O callback `WaveInProc` roda na thread de alta prioridade do waveIn.
- Re-enfileira automaticamente cada buffer após entrega.

---

### `Video.Encoder.pas` — TVideoEncoder
Encoda frames BGR0 em H264 Annex-B via libx264.

```pascal
var Enc := TVideoEncoder.Create(1280, 720, 30, 2000);  // W, H, FPS, kbps
Enc.OnPacket := procedure(Data: PByte; Size, DurationMs: Integer)
begin
  // Data = pacote H264 Annex-B pronto para WhipSendVideo
end;
Enc.FeedFrame(BGR0Ptr, W, H);
// ...
Enc.Free;
```

**Parâmetros do encoder:**
- Preset: `ultrafast`
- Tune: `zerolatency`
- GOP: 1 keyframe/segundo
- B-frames: 0 (baixa latência)
- Pixel format: YUV420P (convertido internamente de BGR0)

**Notas:**
- `FeedFrame` aceita frames de qualquer resolução (swscale redimensiona para W×H do constructor).
- Thread-safe: usa `TCriticalSection` internamente.

---

### `Audio.Encoder.pas` — TAudioEncoder
Encoda PCM S16 estéreo em Opus via FFmpeg.

```pascal
var Enc := TAudioEncoder.Create;  // 48kHz, estéreo, 128kbps
Enc.OnPacket := procedure(Data: PByte; Size: Integer)
begin
  // Data = pacote Opus pronto para WhipSendAudio
end;
Enc.FeedPCM(PCMPtr, Samples);  // S16 interleaved
// ...
Enc.Free;
```

**Notas:**
- Acumula amostras internamente até ter um frame completo (tipicamente 960 = 20ms).
- Converte S16 interleaved → FLTP planar via swresample antes de codificar.
- `FeedPCM` é thread-safe.

---

### `Whip.view.pas` — TFormWhip
Form FMX de transmissão WHIP.

**Campos:**
| Campo | Descrição |
|-------|-----------|
| Host | Endereço do servidor (ex: `localhost`) |
| Porta | Porta HTTP (ex: `8889` para MediaMTX) |
| Path | Caminho do stream (ex: `/live`) |
| Usuário / Senha | Credenciais Basic Auth (opcional) |
| Vídeo | Habilita captura de tela |
| Áudio | Habilita captura de microfone |

**URL WHIP montada:** `http://<host>:<porta><path>/whip`

**Abrir via código:**
```pascal
uses Whip.view;
// ...
FormWhip.Show;
```

---

## Fluxo Completo

```
[BtnTransmitir]
     │
     ├─ Cria TVideoEncoder(1280,720,30)  + TScreenCapture
     ├─ Cria TAudioEncoder               + TMicCapture
     │
     └─ Thread: WhipConnect(url, 'basic', user, pass, sendVid, sendAud)
           │
           ├─ Retorna handle > 0
           │
           ├─ TVideoEncoder.OnPacket → WhipSendVideo(handle, data, size, durationMs)
           ├─ TScreenCapture.OnFrame  → TVideoEncoder.FeedFrame(data, w, h)
           ├─ TAudioEncoder.OnPacket → WhipSendAudio(handle, data, size, 20)
           └─ TMicCapture.OnData     → TAudioEncoder.FeedPCM(pcm, samples)

[BtnParar]
     │
     ├─ FHandle := 0  (callbacks param para enviar imediatamente)
     ├─ FScreenCapture.Stop  +  FMicCapture.Stop
     ├─ FVideoEncoder.Free   +  FAudioEncoder.Free
     └─ WhipDisconnect(handle)
```

---

## Configuração MediaMTX

```yaml
# mediamtx.yml
paths:
  live:
    source: publisher
    # Habilita endpoint WHIP em /live/whip
    whipEnabled: yes
    # Opcional: autenticação
    publishUser: user
    publishPass: pass
```

Iniciar: `mediamtx`

Para visualizar o stream recebido, use o form WHEP (Form1) apontando para o mesmo path.

---

## Exemplo Mínimo (sem form)

```pascal
uses
  Screen.Capture, Mic.Capture, Video.Encoder, Audio.Encoder,
  Pion.Whep.Binding;

var
  Screen: TScreenCapture;
  Mic:    TMicCapture;
  VEnc:   TVideoEncoder;
  AEnc:   TAudioEncoder;
  Handle: Int32;

begin
  WhipInit(nil);

  Handle := WhipConnect('http://localhost:8889/live/whip',
    'basic', 'user', 'pass', 1, 1);
  if Handle < 0 then raise Exception.CreateFmt('WhipConnect falhou: %d', [Handle]);

  VEnc := TVideoEncoder.Create(1280, 720, 30, 2000);
  VEnc.OnPacket := procedure(Data: PByte; Size, DurationMs: Integer)
  begin
    WhipSendVideo(Handle, Data, Size, DurationMs);
  end;

  AEnc := TAudioEncoder.Create;
  AEnc.OnPacket := procedure(Data: PByte; Size: Integer)
  begin
    WhipSendAudio(Handle, Data, Size, 20);
  end;

  Screen := TScreenCapture.Create;
  Screen.OnFrame := procedure(Data: PByte; W, H: Integer)
  begin
    VEnc.FeedFrame(Data, W, H);
  end;

  Mic := TMicCapture.Create;
  Mic.OnData := procedure(PCM: PByte; Samples: Integer)
  begin
    AEnc.FeedPCM(PCM, Samples);
  end;

  Screen.Start(30);
  Mic.Start;

  // ... aguarda sinal de parada ...

  Screen.OnFrame := nil; Screen.Stop; Screen.Free;
  Mic.OnData := nil;     Mic.Stop;    Mic.Free;
  VEnc.Free;
  AEnc.Free;
  WhipDisconnect(Handle);
end;
```

---

## Resolução de Problemas

| Sintoma | Causa provável | Solução |
|---------|---------------|---------|
| `WhipConnect` retorna -1 | Erro ao criar PeerConnection | Verificar `pion.dll` |
| `WhipConnect` retorna -2/-4 | Erro ao criar/adicionar track de vídeo | Verificar `sendVideo=1` |
| `WhipConnect` retorna -7/-8 | Erro HTTP | Verificar URL e se o servidor está rodando |
| `WhipConnect` retorna -10 | Erro ao setar answer SDP | Resposta do servidor inválida |
| H264 encoder não encontrado | `avcodec-62.dll` sem libx264 | Usar build FFmpeg com `--enable-libx264` |
| Opus encoder não encontrado | DLL errada | Verificar versão `avcodec-62.dll` |
| ACCESS_VIOLATION no encoder | Offsets de struct incorretos | Verificar versão FFmpeg (esperado 7.x) |
| Sem áudio no receptor | Formato de sample errado | Verificar se `swresample-6.dll` está presente |
