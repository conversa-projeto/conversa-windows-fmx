# WHEP Video Viewer — Delphi 11 FMX Win64

## Especificação Completa para Implementação

---

## 1. VISÃO GERAL DO PROJETO

Aplicação Delphi 11 FMX Windows 64-bit que conecta a um servidor MediaMTX via protocolo WHEP (WebRTC-HTTP Egress Protocol), recebe um stream de vídeo H264 e áudio Opus, decodifica e exibe em tela.

### Arquitetura

```
MediaMTX (WHIP publisher) 
    │
    ▼ (WHEP - HTTP + WebRTC)
┌─────────────────────────────────┐
│  Pion DLL (Go)                  │
│  - Negociação WHEP (SDP)        │
│  - ICE / DTLS-SRTP              │
│  - Recebe pacotes RTP           │
│  - Entrega H264 NALUs + Opus    │
│    via callbacks para Delphi    │
└──────────┬──────────────────────┘
           │ callbacks (função C)
           ▼
┌─────────────────────────────────┐
│  FFmpeg DLLs                    │
│  - Decodifica H264 → YUV/RGB   │
│  - Decodifica Opus → PCM       │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│  Delphi FMX App                 │
│  - Renderiza frames em TImage   │
│  - Reproduz áudio via WASAPI    │
│  - Interface com campos config  │
└─────────────────────────────────┘
```

### Fluxo WHEP simplificado

1. Delphi faz HTTP POST para `http://{host}:{port}/{path}/whep` com SDP offer (gerado pela Pion DLL)
2. MediaMTX responde com SDP answer
3. Pion DLL processa o SDP answer, estabelece conexão ICE/DTLS
4. Pacotes RTP chegam → Pion depacketiza → entrega H264 NALUs e Opus frames via callback
5. Delphi recebe os dados, decodifica via FFmpeg, renderiza/reproduz

---

## 2. PRÉ-REQUISITOS DE AMBIENTE

### 2.1 Go (para compilar a DLL Pion)

- Baixar: https://go.dev/dl/ → arquivo `go1.22.x.windows-amd64.msi` (ou versão estável mais recente)
- Instalar com padrão (próximo, próximo, fim)
- Verificar: abrir cmd → `go version` deve retornar a versão
- Variável PATH já é configurada pelo instalador MSI
- **CGO**: precisa estar habilitado. Definir variável de ambiente: `set CGO_ENABLED=1`
- **Compilador C para CGO**: instalar **TDM-GCC 64-bit** (https://jmeubank.github.io/tdm-gcc/download/) — necessário para `buildmode=c-shared` no Windows

### 2.2 FFmpeg DLLs

- Baixar build compartilhado (shared) Win64: https://github.com/BtbN/FFmpeg-Builds/releases
- Arquivo: `ffmpeg-n7.x-latest-win64-lgpl-shared-7.x.zip` (ou versão mais recente, LGPL)
- Extrair. As DLLs necessárias estão em `/bin/`:
  - `avcodec-61.dll` (ou número de versão atual)
  - `avutil-59.dll`
  - `swscale-8.dll`
  - `swresample-5.dll`
- Copiar essas 4 DLLs para a pasta de output do projeto Delphi (mesma pasta do .exe)
- Os headers C estarão em `/include/` — não são usados diretamente pelo Delphi, apenas referência para os bindings

### 2.3 Delphi 11

- RAD Studio 11 (Alexandria) com plataforma Win64 configurada
- Projeto FMX Application (Multi-Device, mas target apenas Windows 64-bit)

---

## 3. DLL PION (Go) — `pion_whep.dll`

### 3.1 Estrutura do projeto Go

Criar pasta: `C:\pion_whep\` (ou qualquer local)

Arquivo: `C:\pion_whep\go.mod`
```
module pion_whep

go 1.22

require (
    github.com/pion/webrtc/v4 v4.0.0
)
```

Após criar o `go.mod`, rodar no cmd dentro da pasta:
```
go mod tidy
```
Isso baixa as dependências.

### 3.2 Código da DLL

Arquivo: `C:\pion_whep\main.go`

A DLL deve exportar as seguintes funções C:

```go
package main

/*
#include <stdint.h>
#include <stdlib.h>

// Callback para frames de vídeo H264 (NALUs completos com start code)
// data: ponteiro para bytes H264
// size: tamanho em bytes
// timestamp_ms: timestamp em milissegundos
typedef void (*VideoFrameCallback)(uint8_t* data, int32_t size, int64_t timestamp_ms);

// Callback para frames de áudio Opus
// data: ponteiro para bytes Opus
// size: tamanho em bytes
// timestamp_ms: timestamp em milissegundos
typedef void (*AudioFrameCallback)(uint8_t* data, int32_t size, int64_t timestamp_ms);

// Callback para status da conexão
// state: 0=disconnected, 1=connecting, 2=connected, 3=failed
typedef void (*StateCallback)(int32_t state);
*/
import "C"

import (
    "bytes"
    "context"
    "fmt"
    "io"
    "net/http"
    "sync"
    "unsafe"

    "github.com/pion/webrtc/v4"
    "github.com/pion/webrtc/v4/pkg/media"
)

var (
    peerConnection *webrtc.PeerConnection
    cancelFunc     context.CancelFunc
    mu             sync.Mutex

    videoCallback C.VideoFrameCallback
    audioCallback C.AudioFrameCallback
    stateCallback C.StateCallback
)

//export WhepInit
func WhepInit(videoCb C.VideoFrameCallback, audioCb C.AudioFrameCallback, stateCb C.StateCallback) C.int32_t {
    mu.Lock()
    defer mu.Unlock()

    videoCallback = videoCb
    audioCallback = audioCb
    stateCallback = stateCb

    return 0
}

//export WhepConnect
func WhepConnect(whepURL *C.char) C.int32_t {
    mu.Lock()
    defer mu.Unlock()

    url := C.GoString(whepURL)

    // Notificar connecting
    if stateCallback != nil {
        C.stateCallback(1)
    }

    // Configurar PeerConnection
    config := webrtc.Configuration{
        ICEServers: []webrtc.ICEServer{},
    }

    // Criar MediaEngine com codecs padrão
    m := &webrtc.MediaEngine{}
    if err := m.RegisterDefaultCodecs(); err != nil {
        notifyState(3)
        return -1
    }

    api := webrtc.NewAPI(webrtc.WithMediaEngine(m))

    pc, err := api.NewPeerConnection(config)
    if err != nil {
        notifyState(3)
        return -1
    }

    peerConnection = pc

    // Configurar handler de track
    pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
        codec := track.Codec()

        if track.Kind() == webrtc.RTPCodecTypeVideo {
            go readVideoTrack(track)
        } else if track.Kind() == webrtc.RTPCodecTypeAudio {
            go readAudioTrack(track)
        }
        _ = codec
    })

    pc.OnConnectionStateChange(func(state webrtc.PeerConnectionState) {
        switch state {
        case webrtc.PeerConnectionStateConnected:
            notifyState(2)
        case webrtc.PeerConnectionStateFailed:
            notifyState(3)
        case webrtc.PeerConnectionStateDisconnected:
            notifyState(0)
        case webrtc.PeerConnectionStateClosed:
            notifyState(0)
        }
    })

    // Adicionar transceivers para receber vídeo e áudio
    _, err = pc.AddTransceiverFromKind(webrtc.RTPCodecTypeVideo, webrtc.RTPTransceiverInit{
        Direction: webrtc.RTPTransceiverDirectionRecvonly,
    })
    if err != nil {
        notifyState(3)
        return -2
    }

    _, err = pc.AddTransceiverFromKind(webrtc.RTPCodecTypeAudio, webrtc.RTPTransceiverInit{
        Direction: webrtc.RTPTransceiverDirectionRecvonly,
    })
    if err != nil {
        notifyState(3)
        return -3
    }

    // Criar offer
    offer, err := pc.CreateOffer(nil)
    if err != nil {
        notifyState(3)
        return -4
    }

    err = pc.SetLocalDescription(offer)
    if err != nil {
        notifyState(3)
        return -5
    }

    // Aguardar ICE gathering completar
    gatherComplete := webrtc.GatheringCompletePromise(pc)
    <-gatherComplete

    // Enviar offer via HTTP POST (WHEP)
    offerSDP := pc.LocalDescription().SDP

    resp, err := http.Post(url, "application/sdp", bytes.NewReader([]byte(offerSDP)))
    if err != nil {
        notifyState(3)
        return -6
    }
    defer resp.Body.Close()

    if resp.StatusCode != 201 && resp.StatusCode != 200 {
        notifyState(3)
        return -7
    }

    answerBytes, err := io.ReadAll(resp.Body)
    if err != nil {
        notifyState(3)
        return -8
    }

    answer := webrtc.SessionDescription{
        Type: webrtc.SDPTypeAnswer,
        SDP:  string(answerBytes),
    }

    err = pc.SetRemoteDescription(answer)
    if err != nil {
        notifyState(3)
        return -9
    }

    return 0
}

//export WhepDisconnect
func WhepDisconnect() C.int32_t {
    mu.Lock()
    defer mu.Unlock()

    if peerConnection != nil {
        peerConnection.Close()
        peerConnection = nil
    }

    notifyState(0)
    return 0
}

func notifyState(state int32) {
    if stateCallback != nil {
        stateCallback := stateCallback
        C.stateCallback(C.int32_t(state))
    }
}

func readVideoTrack(track *webrtc.TrackRemote) {
    // Buffer para acumular H264 NALUs
    // Pion entrega pacotes RTP já depacketizados como amostras
    for {
        pkt, _, err := track.ReadRTP()
        if err != nil {
            return
        }

        payload := pkt.Payload
        if len(payload) == 0 {
            continue
        }

        if videoCallback != nil {
            cData := C.CBytes(payload)
            C.videoCallback(
                (*C.uint8_t)(cData),
                C.int32_t(len(payload)),
                C.int64_t(pkt.Timestamp),
            )
            C.free(cData)
        }
    }
}

func readAudioTrack(track *webrtc.TrackRemote) {
    for {
        pkt, _, err := track.ReadRTP()
        if err != nil {
            return
        }

        payload := pkt.Payload
        if len(payload) == 0 {
            continue
        }

        if audioCallback != nil {
            cData := C.CBytes(payload)
            C.audioCallback(
                (*C.uint8_t)(cData),
                C.int32_t(len(payload)),
                C.int64_t(pkt.Timestamp),
            )
            C.free(cData)
        }
    }
}

func main() {}
```

### 3.3 Compilação da DLL

Abrir cmd na pasta `C:\pion_whep\`:

```batch
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64
go build -buildmode=c-shared -o pion_whep.dll .
```

**Resultado:** dois arquivos gerados:
- `pion_whep.dll` — a DLL
- `pion_whep.h` — header C gerado automaticamente

Copiar `pion_whep.dll` para a pasta de output do projeto Delphi (junto ao .exe).

---

## 4. BINDINGS FFmpeg PARA DELPHI

### 4.1 Unit: `FFmpeg.Binding.pas`

Esta unit declara as funções externas das DLLs do FFmpeg necessárias para decodificar H264 e Opus.

**Constantes de versão das DLLs:** os nomes exatos dos arquivos DLL variam conforme a versão baixada do FFmpeg. Verificar os números de versão reais dos arquivos `.dll` e ajustar as constantes abaixo.

```pascal
unit FFmpeg.Binding;

interface

uses
  System.SysUtils;

const
  AVCODEC_DLL  = 'avcodec-61.dll';    // AJUSTAR número conforme versão
  AVUTIL_DLL   = 'avutil-59.dll';     // AJUSTAR número conforme versão
  SWSCALE_DLL  = 'swscale-8.dll';     // AJUSTAR número conforme versão

  // Pixel formats
  AV_PIX_FMT_YUV420P = 0;
  AV_PIX_FMT_BGRA    = 28;

  // Codec IDs
  AV_CODEC_ID_H264 = 27;
  AV_CODEC_ID_OPUS = 86076;

  // AVFrame flags
  AV_FRAME_FLAG_NONE = 0;

type
  PAVCodec = Pointer;
  PAVCodecContext = Pointer;
  PAVPacket = Pointer;
  PAVFrame = Pointer;
  PSwsContext = Pointer;

  // Estrutura mínima para acessar campos do AVFrame
  // Os offsets podem variar entre versões do FFmpeg
  // Usaremos funções helper para acessar os campos

  TAVFrameHelper = record
    class function GetData(Frame: PAVFrame; PlaneIndex: Integer): PByte; static;
    class function GetLinesize(Frame: PAVFrame; PlaneIndex: Integer): Integer; static;
    class function GetWidth(Frame: PAVFrame): Integer; static;
    class function GetHeight(Frame: PAVFrame): Integer; static;
    class function GetFormat(Frame: PAVFrame): Integer; static;
  end;

// === avcodec ===
function avcodec_find_decoder(id: Cardinal): PAVCodec; cdecl;
  external AVCODEC_DLL;

function avcodec_alloc_context3(codec: PAVCodec): PAVCodecContext; cdecl;
  external AVCODEC_DLL;

function avcodec_open2(ctx: PAVCodecContext; codec: PAVCodec; options: Pointer): Integer; cdecl;
  external AVCODEC_DLL;

function avcodec_send_packet(ctx: PAVCodecContext; pkt: PAVPacket): Integer; cdecl;
  external AVCODEC_DLL;

function avcodec_receive_frame(ctx: PAVCodecContext; frame: PAVFrame): Integer; cdecl;
  external AVCODEC_DLL;

procedure avcodec_free_context(var ctx: PAVCodecContext); cdecl;
  external AVCODEC_DLL;

function av_packet_alloc: PAVPacket; cdecl;
  external AVCODEC_DLL;

procedure av_packet_free(var pkt: PAVPacket); cdecl;
  external AVCODEC_DLL;

procedure av_packet_unref(pkt: PAVPacket); cdecl;
  external AVCODEC_DLL;

// Funções para setar dados no AVPacket
// AVPacket.data offset = 24, AVPacket.size offset = 32 (Win64, FFmpeg 7.x)
procedure av_packet_set_data(pkt: PAVPacket; data: PByte; size: Integer);

// === avutil ===
function av_frame_alloc: PAVFrame; cdecl;
  external AVUTIL_DLL;

procedure av_frame_free(var frame: PAVFrame); cdecl;
  external AVUTIL_DLL;

procedure av_frame_unref(frame: PAVFrame); cdecl;
  external AVUTIL_DLL;

function av_image_get_buffer_size(pixFmt, width, height, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_image_fill_arrays(
  dstData: Pointer; dstLinesize: Pointer;
  src: PByte; pixFmt, width, height, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

// === swscale ===
function sws_getContext(
  srcW, srcH, srcFormat,
  dstW, dstH, dstFormat: Integer;
  flags: Integer;
  srcFilter, dstFilter, param: Pointer): PSwsContext; cdecl;
  external SWSCALE_DLL;

function sws_scale(
  ctx: PSwsContext;
  srcSlice: Pointer; srcStride: Pointer;
  srcSliceY, srcSliceH: Integer;
  dst: Pointer; dstStride: Pointer): Integer; cdecl;
  external SWSCALE_DLL;

procedure sws_freeContext(ctx: PSwsContext); cdecl;
  external SWSCALE_DLL;

const
  SWS_BILINEAR = 2;

implementation

procedure av_packet_set_data(pkt: PAVPacket; data: PByte; size: Integer);
var
  P: PByte;
begin
  // AVPacket layout (FFmpeg 7.x, Win64):
  // offset 24 = data (PByte)
  // offset 32 = size (int32)
  P := PByte(pkt);
  PPointer(@P[24])^ := data;
  PInteger(@P[32])^ := size;
end;

{ TAVFrameHelper }

class function TAVFrameHelper.GetData(Frame: PAVFrame; PlaneIndex: Integer): PByte;
var
  P: PByte;
begin
  // AVFrame.data[0..7] começa no offset 0 (array de 8 ponteiros)
  P := PByte(Frame);
  Result := PPointer(@P[PlaneIndex * SizeOf(Pointer)])^;
end;

class function TAVFrameHelper.GetLinesize(Frame: PAVFrame; PlaneIndex: Integer): Integer;
var
  P: PByte;
begin
  // AVFrame.linesize[0..7] começa no offset 64 (8 ponteiros * 8 bytes cada)
  P := PByte(Frame);
  Result := PInteger(@P[64 + PlaneIndex * SizeOf(Integer)])^;
end;

class function TAVFrameHelper.GetWidth(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  // AVFrame.width offset = 96 (após data[8] + linesize[8])
  P := PByte(Frame);
  Result := PInteger(@P[96])^;
end;

class function TAVFrameHelper.GetHeight(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  // AVFrame.height offset = 100
  P := PByte(Frame);
  Result := PInteger(@P[100])^;
end;

class function TAVFrameHelper.GetFormat(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  // AVFrame.format offset = 104
  P := PByte(Frame);
  Result := PInteger(@P[104])^;
end;

end.
```

**NOTA IMPORTANTE:** Os offsets de campos das structs do FFmpeg (AVFrame, AVPacket) podem variar entre versões. Os offsets acima são para FFmpeg 7.x Win64. Se a decodificação não funcionar, será necessário verificar os offsets reais compilando um pequeno programa C que imprime `offsetof(AVFrame, data)`, `offsetof(AVFrame, width)`, etc. Alternativamente, usar o header `pion_whep.h` como referência ou criar uma mini DLL helper em C que retorna os valores dos campos.

**ABORDAGEM ALTERNATIVA MAIS SEGURA:** Criar uma DLL wrapper minúscula em C que encapsula o FFmpeg e expõe funções simples como `decode_h264_frame(input, inputSize, outputRGBA, width, height)`. Isso elimina o problema de offsets. Esta abordagem é RECOMENDADA se houver problemas com os offsets diretos.

---

## 5. BINDINGS PION DLL PARA DELPHI

### 5.1 Unit: `Pion.Whep.Binding.pas`

```pascal
unit Pion.Whep.Binding;

interface

uses
  System.SysUtils;

const
  PION_DLL = 'pion_whep.dll';

type
  // Callbacks - devem usar cdecl
  TVideoFrameCallback = procedure(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
  TAudioFrameCallback = procedure(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
  TStateCallback = procedure(State: Int32); cdecl;

  // Estados de conexão
  TWhepConnectionState = (
    wsDisconnected = 0,
    wsConnecting = 1,
    wsConnected = 2,
    wsFailed = 3
  );

// Inicializa a DLL com callbacks
function WhepInit(
  VideoCb: TVideoFrameCallback;
  AudioCb: TAudioFrameCallback;
  StateCb: TStateCallback
): Int32; cdecl; external PION_DLL;

// Conecta ao endpoint WHEP
// URL deve ser completa: http://host:port/path/whep
function WhepConnect(WhepURL: PAnsiChar): Int32; cdecl; external PION_DLL;

// Desconecta
function WhepDisconnect: Int32; cdecl; external PION_DLL;

implementation

end.
```

---

## 6. DECODIFICADOR DE VÍDEO H264

### 6.1 Unit: `Video.Decoder.pas`

Responsável por receber NALUs H264, decodificar via FFmpeg e entregar frames BGRA.

```pascal
unit Video.Decoder;

interface

uses
  System.SysUtils, System.SyncObjs, FFmpeg.Binding;

type
  TOnVideoFrame = procedure(BGRA: PByte; Width, Height, Stride: Integer) of object;

  TVideoDecoder = class
  private
    FCodecCtx: PAVCodecContext;
    FPacket: PAVPacket;
    FFrame: PAVFrame;
    FFrameBGRA: PAVFrame;
    FSwsCtx: PSwsContext;
    FBGRABuffer: TBytes;
    FLastWidth: Integer;
    FLastHeight: Integer;
    FLock: TCriticalSection;
    FOnFrame: TOnVideoFrame;

    // Buffer para acumular NALUs e formar frames completos
    FNaluBuffer: TBytes;
    FNaluBufferSize: Integer;

    procedure InitSwsContext(Width, Height: Integer);
    procedure DecodeAndDeliver(Data: PByte; Size: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    // Chamado pelo callback da Pion DLL (dados RTP H264)
    procedure FeedData(Data: PByte; Size: Integer);

    property OnFrame: TOnVideoFrame read FOnFrame write FOnFrame;
  end;

implementation

constructor TVideoDecoder.Create;
var
  Codec: PAVCodec;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastWidth := 0;
  FLastHeight := 0;
  FNaluBufferSize := 0;

  Codec := avcodec_find_decoder(AV_CODEC_ID_H264);
  if Codec = nil then
    raise Exception.Create('H264 decoder not found in FFmpeg');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Failed to allocate codec context');

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Failed to open H264 codec');

  FPacket := av_packet_alloc;
  FFrame := av_frame_alloc;
  FFrameBGRA := av_frame_alloc;
end;

destructor TVideoDecoder.Destroy;
begin
  if FSwsCtx <> nil then
    sws_freeContext(FSwsCtx);
  if FFrame <> nil then
    av_frame_free(FFrame);
  if FFrameBGRA <> nil then
    av_frame_free(FFrameBGRA);
  if FPacket <> nil then
    av_packet_free(FPacket);
  if FCodecCtx <> nil then
    avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TVideoDecoder.InitSwsContext(Width, Height: Integer);
begin
  if FSwsCtx <> nil then
    sws_freeContext(FSwsCtx);

  FSwsCtx := sws_getContext(
    Width, Height, AV_PIX_FMT_YUV420P,
    Width, Height, AV_PIX_FMT_BGRA,
    SWS_BILINEAR,
    nil, nil, nil
  );

  // Alocar buffer BGRA
  SetLength(FBGRABuffer, Width * Height * 4);
  FLastWidth := Width;
  FLastHeight := Height;
end;

procedure TVideoDecoder.FeedData(Data: PByte; Size: Integer);
begin
  FLock.Enter;
  try
    DecodeAndDeliver(Data, Size);
  finally
    FLock.Leave;
  end;
end;

procedure TVideoDecoder.DecodeAndDeliver(Data: PByte; Size: Integer);
var
  Ret: Integer;
  W, H: Integer;
  SrcData: array[0..3] of PByte;
  SrcStride: array[0..3] of Integer;
  DstData: array[0..3] of PByte;
  DstStride: array[0..3] of Integer;
begin
  // Setar dados no packet
  av_packet_set_data(FPacket, Data, Size);

  Ret := avcodec_send_packet(FCodecCtx, FPacket);
  if Ret < 0 then
    Exit;

  while True do
  begin
    av_frame_unref(FFrame);
    Ret := avcodec_receive_frame(FCodecCtx, FFrame);
    if Ret < 0 then
      Break;

    W := TAVFrameHelper.GetWidth(FFrame);
    H := TAVFrameHelper.GetHeight(FFrame);

    if (W <> FLastWidth) or (H <> FLastHeight) then
      InitSwsContext(W, H);

    if FSwsCtx = nil then
      Continue;

    // Preparar ponteiros source (YUV420P)
    SrcData[0] := TAVFrameHelper.GetData(FFrame, 0);
    SrcData[1] := TAVFrameHelper.GetData(FFrame, 1);
    SrcData[2] := TAVFrameHelper.GetData(FFrame, 2);
    SrcData[3] := nil;

    SrcStride[0] := TAVFrameHelper.GetLinesize(FFrame, 0);
    SrcStride[1] := TAVFrameHelper.GetLinesize(FFrame, 1);
    SrcStride[2] := TAVFrameHelper.GetLinesize(FFrame, 2);
    SrcStride[3] := 0;

    // Preparar ponteiros destino (BGRA)
    DstData[0] := @FBGRABuffer[0];
    DstData[1] := nil;
    DstData[2] := nil;
    DstData[3] := nil;

    DstStride[0] := W * 4;
    DstStride[1] := 0;
    DstStride[2] := 0;
    DstStride[3] := 0;

    // Converter YUV → BGRA
    sws_scale(FSwsCtx, @SrcData[0], @SrcStride[0], 0, H, @DstData[0], @DstStride[0]);

    // Entregar frame
    if Assigned(FOnFrame) then
      FOnFrame(@FBGRABuffer[0], W, H, W * 4);
  end;
end;

end.
```

---

## 7. REPRODUTOR DE ÁUDIO

### 7.1 Unit: `Audio.Player.pas`

Decodifica Opus via FFmpeg e reproduz via WASAPI (Windows Audio Session API) nativo.

**NOTA:** A reprodução via WASAPI direta é complexa. Uma alternativa mais simples é usar a unit `MMSystem` do Windows com `waveOut` API. Abaixo segue implementação com `waveOut` que é mais direta:

```pascal
unit Audio.Player;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes,
  Winapi.Windows, Winapi.MMSystem,
  FFmpeg.Binding;

type
  TAudioPlayer = class
  private
    FCodecCtx: PAVCodecContext;
    FPacket: PAVPacket;
    FFrame: PAVFrame;
    FLock: TCriticalSection;

    // waveOut
    FWaveOut: HWAVEOUT;
    FWaveFormat: TWaveFormatEx;
    FIsOpen: Boolean;

    // Pool de buffers
    FHeaders: array[0..7] of TWaveHdr;
    FBuffers: array[0..7] of TBytes;
    FCurrentHeader: Integer;

    procedure OpenWaveOut(SampleRate, Channels: Integer);
    procedure CloseWaveOut;
    procedure WriteAudioData(PCM: PByte; Size: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    // Chamado pelo callback da Pion DLL (dados Opus)
    procedure FeedData(Data: PByte; Size: Integer);
  end;

implementation

const
  AUDIO_BUFFER_SIZE = 8192;

constructor TAudioPlayer.Create;
var
  Codec: PAVCodec;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FIsOpen := False;
  FCurrentHeader := 0;

  Codec := avcodec_find_decoder(AV_CODEC_ID_OPUS);
  if Codec = nil then
    raise Exception.Create('Opus decoder not found in FFmpeg');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Failed to allocate audio codec context');

  // Opus padrão: 48000 Hz, stereo
  // Configurar sample rate e channels no contexto antes de abrir
  // Os offsets dependem da versão do FFmpeg
  // Abordagem: abrir com defaults e deixar o decoder detectar

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Failed to open Opus codec');

  FPacket := av_packet_alloc;
  FFrame := av_frame_alloc;
end;

destructor TAudioPlayer.Destroy;
begin
  CloseWaveOut;
  if FFrame <> nil then
    av_frame_free(FFrame);
  if FPacket <> nil then
    av_packet_free(FPacket);
  if FCodecCtx <> nil then
    avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TAudioPlayer.OpenWaveOut(SampleRate, Channels: Integer);
var
  I: Integer;
begin
  if FIsOpen then
    Exit;

  FillChar(FWaveFormat, SizeOf(FWaveFormat), 0);
  FWaveFormat.wFormatTag := WAVE_FORMAT_PCM;
  FWaveFormat.nChannels := Channels;
  FWaveFormat.nSamplesPerSec := SampleRate;
  FWaveFormat.wBitsPerSample := 16;
  FWaveFormat.nBlockAlign := Channels * 2;
  FWaveFormat.nAvgBytesPerSec := SampleRate * Channels * 2;

  if waveOutOpen(@FWaveOut, WAVE_MAPPER, @FWaveFormat, 0, 0, CALLBACK_NULL) = MMSYSERR_NOERROR then
  begin
    FIsOpen := True;

    // Preparar pool de buffers
    for I := 0 to High(FHeaders) do
    begin
      SetLength(FBuffers[I], AUDIO_BUFFER_SIZE);
      FillChar(FHeaders[I], SizeOf(TWaveHdr), 0);
      FHeaders[I].lpData := @FBuffers[I][0];
      FHeaders[I].dwBufferLength := AUDIO_BUFFER_SIZE;
    end;
  end;
end;

procedure TAudioPlayer.CloseWaveOut;
begin
  if FIsOpen then
  begin
    waveOutReset(FWaveOut);
    waveOutClose(FWaveOut);
    FIsOpen := False;
  end;
end;

procedure TAudioPlayer.WriteAudioData(PCM: PByte; Size: Integer);
var
  Hdr: PWaveHdr;
begin
  if not FIsOpen then
    Exit;

  if Size > AUDIO_BUFFER_SIZE then
    Size := AUDIO_BUFFER_SIZE;

  Hdr := @FHeaders[FCurrentHeader];

  // Esperar se o buffer ainda está em uso
  if (Hdr.dwFlags and WHDR_DONE) <> 0 then
    waveOutUnprepareHeader(FWaveOut, Hdr, SizeOf(TWaveHdr));

  Move(PCM^, FBuffers[FCurrentHeader][0], Size);
  Hdr.dwBufferLength := Size;

  waveOutPrepareHeader(FWaveOut, Hdr, SizeOf(TWaveHdr));
  waveOutWrite(FWaveOut, Hdr, SizeOf(TWaveHdr));

  FCurrentHeader := (FCurrentHeader + 1) mod Length(FHeaders);
end;

procedure TAudioPlayer.FeedData(Data: PByte; Size: Integer);
var
  Ret: Integer;
  PCMData: PByte;
  PCMSize: Integer;
  Channels, SampleRate: Integer;
begin
  FLock.Enter;
  try
    av_packet_set_data(FPacket, Data, Size);

    Ret := avcodec_send_packet(FCodecCtx, FPacket);
    if Ret < 0 then
      Exit;

    while True do
    begin
      av_frame_unref(FFrame);
      Ret := avcodec_receive_frame(FCodecCtx, FFrame);
      if Ret < 0 then
        Break;

      // Obter PCM do frame decodificado
      PCMData := TAVFrameHelper.GetData(FFrame, 0);
      // nb_samples está em offset 108 (após format), channels detectable
      // Para simplificar, assumir 48000Hz stereo (padrão Opus)

      if not FIsOpen then
        OpenWaveOut(48000, 2); // Opus padrão

      // Tamanho PCM = nb_samples * channels * 2 (16-bit)
      // nb_samples no offset 108
      PCMSize := PInteger(PByte(FFrame) + 108)^ * 2 * 2; // stereo, 16-bit

      WriteAudioData(PCMData, PCMSize);
    end;
  finally
    FLock.Leave;
  end;
end;

end.
```

---

## 8. INTERFACE FMX — FORM PRINCIPAL

### 8.1 Layout do Form

**Form:** `FrmMain`
- **Tamanho:** 900 x 600

**Componentes (de cima para baixo):**

```
┌─────────────────────────────────────────────────────┐
│ Panel (Top, Height=80, Align=Top)                   │
│  ┌──────────────────────────────────────────────┐   │
│  │ Label "Host:"  [Edit: EdtHost     ]          │   │
│  │ Label "Porta:" [Edit: EdtPort     ]          │   │
│  │ Label "Path:"  [Edit: EdtPath     ]          │   │
│  │             [Btn: BtnConnect] [Btn: BtnStop] │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│ Panel (Client, Align=Client)                        │
│  ┌──────────────────────────────────────────────┐   │
│  │ Image: ImgVideo (Align=Client)               │   │
│  │  - HitTest = False                           │   │
│  │  - WrapMode = Fit                            │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│ Panel (Bottom, Height=30, Align=Bottom)             │
│  ┌──────────────────────────────────────────────┐   │
│  │ Label: LblStatus (Align=Client)              │   │
│  │  Text: "Desconectado"                        │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**Valores padrão dos campos:**
- `EdtHost.Text` = `'192.168.1.100'` (placeholder, editável)
- `EdtPort.Text` = `'8889'` (porta WHEP padrão do MediaMTX)
- `EdtPath.Text` = `'live'` (nome do stream)

### 8.2 Nomes dos componentes (exatos):
- `EdtHost: TEdit`
- `EdtPort: TEdit`
- `EdtPath: TEdit`
- `BtnConnect: TButton` (Text = 'Conectar')
- `BtnStop: TButton` (Text = 'Parar', Enabled = False)
- `ImgVideo: TImage`
- `LblStatus: TLabel`

---

## 9. UNIT PRINCIPAL — `Main.pas`

### 9.1 Código do Form

```pascal
unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.SyncObjs,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls,
  FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  Pion.Whep.Binding, Video.Decoder, Audio.Player;

type
  TFrmMain = class(TForm)
    PnlTop: TPanel;
    EdtHost: TEdit;
    EdtPort: TEdit;
    EdtPath: TEdit;
    BtnConnect: TButton;
    BtnStop: TButton;
    PnlVideo: TPanel;
    ImgVideo: TImage;
    PnlBottom: TPanel;
    LblStatus: TLabel;
    LblHost: TLabel;
    LblPort: TLabel;
    LblPath: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
  private
    FVideoDecoder: TVideoDecoder;
    FAudioPlayer: TAudioPlayer;
    FConnected: Boolean;

    procedure OnVideoFrame(BGRA: PByte; Width, Height, Stride: Integer);
    procedure UpdateStatus(const Status: string);
  end;

var
  FrmMain: TFrmMain;

  // Variáveis globais para callbacks (cdecl não suporta métodos de objeto)
  GVideoDecoder: TVideoDecoder;
  GAudioPlayer: TAudioPlayer;
  GForm: TFrmMain;

// Callbacks cdecl para a Pion DLL
procedure VideoCallback(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure AudioCallback(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure StateCallback(State: Int32); cdecl;

implementation

{$R *.fmx}

procedure VideoCallback(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
begin
  if GVideoDecoder <> nil then
    GVideoDecoder.FeedData(Data, Size);
end;

procedure AudioCallback(Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
begin
  if GAudioPlayer <> nil then
    GAudioPlayer.FeedData(Data, Size);
end;

procedure StateCallback(State: Int32); cdecl;
var
  Msg: string;
begin
  case State of
    0: Msg := 'Desconectado';
    1: Msg := 'Conectando...';
    2: Msg := 'Conectado';
    3: Msg := 'Falha na conexão';
  else
    Msg := 'Desconhecido';
  end;

  if GForm <> nil then
    GForm.UpdateStatus(Msg);
end;

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FConnected := False;

  FVideoDecoder := TVideoDecoder.Create;
  FVideoDecoder.OnFrame := OnVideoFrame;

  FAudioPlayer := TAudioPlayer.Create;

  // Registrar globals para callbacks
  GVideoDecoder := FVideoDecoder;
  GAudioPlayer := FAudioPlayer;
  GForm := Self;

  // Inicializar Pion DLL
  WhepInit(@VideoCallback, @AudioCallback, @StateCallback);

  LblStatus.Text := 'Desconectado';
  BtnStop.Enabled := False;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  if FConnected then
    WhepDisconnect;

  GVideoDecoder := nil;
  GAudioPlayer := nil;
  GForm := nil;

  FVideoDecoder.Free;
  FAudioPlayer.Free;
end;

procedure TFrmMain.BtnConnectClick(Sender: TObject);
var
  URL: AnsiString;
  Ret: Int32;
begin
  URL := AnsiString(Format('http://%s:%s/%s/whep', [
    EdtHost.Text, EdtPort.Text, EdtPath.Text
  ]));

  Ret := WhepConnect(PAnsiChar(URL));

  if Ret = 0 then
  begin
    FConnected := True;
    BtnConnect.Enabled := False;
    BtnStop.Enabled := True;
  end
  else
    LblStatus.Text := Format('Erro ao conectar: %d', [Ret]);
end;

procedure TFrmMain.BtnStopClick(Sender: TObject);
begin
  WhepDisconnect;
  FConnected := False;
  BtnConnect.Enabled := True;
  BtnStop.Enabled := False;
  LblStatus.Text := 'Desconectado';
end;

procedure TFrmMain.OnVideoFrame(BGRA: PByte; Width, Height, Stride: Integer);
begin
  // Esta procedure é chamada de thread secundária (callback da DLL)
  // Precisa sincronizar com a thread principal para atualizar o FMX
  TThread.Queue(nil,
    procedure
    var
      BmpData: TBitmapData;
      Bmp: TBitmap;
      Y: Integer;
      SrcLine, DstLine: PByte;
    begin
      Bmp := ImgVideo.Bitmap;

      if (Bmp.Width <> Width) or (Bmp.Height <> Height) then
        Bmp.SetSize(Width, Height);

      if Bmp.Map(TMapAccess.Write, BmpData) then
      try
        for Y := 0 to Height - 1 do
        begin
          SrcLine := BGRA + (Y * Stride);
          DstLine := PByte(BmpData.Data) + (Y * BmpData.Pitch);
          Move(SrcLine^, DstLine^, Width * 4);
        end;
      finally
        Bmp.Unmap(BmpData);
      end;

      ImgVideo.Repaint;
    end
  );
end;

procedure TFrmMain.UpdateStatus(const Status: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      LblStatus.Text := Status;
    end
  );
end;

end.
```

---

## 10. PROBLEMAS CONHECIDOS E SOLUÇÕES

### 10.1 RTP vs NALUs completos

**PROBLEMA CRÍTICO:** O código Go acima usa `track.ReadRTP()` que entrega pacotes RTP individuais. Um frame H264 pode ser fragmentado em múltiplos pacotes RTP (FU-A). Enviar cada pacote RTP diretamente ao decoder FFmpeg vai falhar.

**SOLUÇÃO:** No código Go, trocar `ReadRTP()` por `Read()` que entrega amostras completas (media samples já reagrupadas):

Substituir `readVideoTrack` no `main.go` por:

```go
func readVideoTrack(track *webrtc.TrackRemote) {
    buf := make([]byte, 1500*100) // buffer grande para frames grandes
    for {
        n, _, err := track.Read(buf)
        if err != nil {
            return
        }
        if n == 0 {
            continue
        }

        // Adicionar start code se necessário
        data := buf[:n]
        
        // Verificar se já tem start code (0x00 0x00 0x00 0x01)
        hasStartCode := len(data) >= 4 && 
            data[0] == 0 && data[1] == 0 && data[2] == 0 && data[3] == 1

        var frameData []byte
        if hasStartCode {
            frameData = make([]byte, n)
            copy(frameData, data)
        } else {
            // Prefixar com Annex B start code
            frameData = make([]byte, 4+n)
            frameData[0] = 0
            frameData[1] = 0
            frameData[2] = 0
            frameData[3] = 1
            copy(frameData[4:], data)
        }

        if videoCallback != nil {
            cData := C.CBytes(frameData)
            C.videoCallback(
                (*C.uint8_t)(cData),
                C.int32_t(len(frameData)),
                C.int64_t(0),
            )
            C.free(cData)
        }
    }
}
```

Mesma correção para áudio (Opus não tem fragmentação significativa, mas usar `Read()` é mais consistente):

```go
func readAudioTrack(track *webrtc.TrackRemote) {
    buf := make([]byte, 4096)
    for {
        n, _, err := track.Read(buf)
        if err != nil {
            return
        }
        if n == 0 {
            continue
        }

        data := make([]byte, n)
        copy(data, buf[:n])

        if audioCallback != nil {
            cData := C.CBytes(data)
            C.audioCallback(
                (*C.uint8_t)(cData),
                C.int32_t(n),
                C.int64_t(0),
            )
            C.free(cData)
        }
    }
}
```

### 10.2 Offsets FFmpeg

Os offsets de structs AVFrame/AVPacket são o maior risco. Se não funcionarem, criar uma DLL C mínima (`ffmpeg_helper.dll`) com funções tipo:

```c
// ffmpeg_helper.c
#include <libavcodec/avcodec.h>
#include <libavutil/frame.h>
#include <libswscale/swscale.h>

typedef void (*FrameCallback)(uint8_t* bgra, int width, int height, int stride);

static AVCodecContext* ctx = NULL;
static AVPacket* pkt = NULL;
static AVFrame* frame = NULL;
static AVFrame* frameBGRA = NULL;
static struct SwsContext* sws = NULL;
static uint8_t* bgraBuffer = NULL;
static int lastW = 0, lastH = 0;
static FrameCallback callback = NULL;

__declspec(dllexport) int ffhelper_init(FrameCallback cb) {
    const AVCodec* codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec) return -1;
    ctx = avcodec_alloc_context3(codec);
    if (!ctx) return -2;
    if (avcodec_open2(ctx, codec, NULL) < 0) return -3;
    pkt = av_packet_alloc();
    frame = av_frame_alloc();
    frameBGRA = av_frame_alloc();
    callback = cb;
    return 0;
}

__declspec(dllexport) int ffhelper_decode(uint8_t* data, int size) {
    pkt->data = data;
    pkt->size = size;
    
    int ret = avcodec_send_packet(ctx, pkt);
    if (ret < 0) return ret;
    
    while (1) {
        ret = avcodec_receive_frame(ctx, frame);
        if (ret < 0) break;
        
        int w = frame->width;
        int h = frame->height;
        
        if (w != lastW || h != lastH) {
            if (sws) sws_freeContext(sws);
            sws = sws_getContext(w, h, frame->format,
                                w, h, AV_PIX_FMT_BGRA,
                                SWS_BILINEAR, NULL, NULL, NULL);
            if (bgraBuffer) free(bgraBuffer);
            bgraBuffer = (uint8_t*)malloc(w * h * 4);
            lastW = w;
            lastH = h;
        }
        
        uint8_t* dstData[1] = { bgraBuffer };
        int dstStride[1] = { w * 4 };
        
        sws_scale(sws, (const uint8_t* const*)frame->data,
                  frame->linesize, 0, h, dstData, dstStride);
        
        if (callback)
            callback(bgraBuffer, w, h, w * 4);
    }
    return 0;
}

__declspec(dllexport) void ffhelper_free() {
    if (sws) sws_freeContext(sws);
    if (frame) av_frame_free(&frame);
    if (frameBGRA) av_frame_free(&frameBGRA);
    if (pkt) av_packet_free(&pkt);
    if (ctx) avcodec_free_context(&ctx);
    if (bgraBuffer) free(bgraBuffer);
}
```

Esta DLL helper é compilável com:
```
gcc -shared -o ffmpeg_helper.dll ffmpeg_helper.c -I<ffmpeg_include_path> -L<ffmpeg_lib_path> -lavcodec -lavutil -lswscale
```

Se esta abordagem for necessária, o binding Delphi para a DLL helper é trivial (3 funções apenas).

### 10.3 Thread Safety no FMX

O `TThread.Queue` no `OnVideoFrame` pode acumular chamadas se o FMX não processar rápido o suficiente. Solução: adicionar um flag `FRendering: Boolean` para fazer skip de frames quando o anterior ainda não foi renderizado. Isso evita memory pressure.

### 10.4 Liberação de memória dos callbacks

Os dados passados nos callbacks (`Data: PByte`) são alocados pela DLL Go com `C.CBytes` e liberados com `C.free` logo após o callback retornar. O Delphi **NÃO DEVE** armazenar esses ponteiros — deve copiar os dados para buffer próprio dentro do callback. O `TVideoDecoder.FeedData` e `TAudioPlayer.FeedData` processam os dados imediatamente, o que é correto.

---

## 11. LISTA DE ARQUIVOS DO PROJETO

### DLLs necessárias (copiar para pasta do .exe):
1. `pion_whep.dll` (compilada do Go)
2. `avcodec-61.dll` (FFmpeg)
3. `avutil-59.dll` (FFmpeg)
4. `swscale-8.dll` (FFmpeg)
5. `swresample-5.dll` (FFmpeg — dependência indireta)

### Units Delphi:
1. `Main.pas` + `Main.fmx` — Form principal
2. `Pion.Whep.Binding.pas` — Bindings da DLL Pion
3. `FFmpeg.Binding.pas` — Bindings do FFmpeg
4. `Video.Decoder.pas` — Decodificador H264
5. `Audio.Player.pas` — Player de áudio Opus

### Projeto Go:
1. `C:\pion_whep\go.mod`
2. `C:\pion_whep\main.go`

### Opcional (se offsets FFmpeg falharem):
1. `ffmpeg_helper.c` → compilar para `ffmpeg_helper.dll`

---

## 12. SEQUÊNCIA DE IMPLEMENTAÇÃO

1. **Instalar Go** e TDM-GCC 64-bit
2. **Criar projeto Go**, rodar `go mod tidy`, compilar DLL
3. **Baixar FFmpeg** shared Win64, extrair DLLs
4. **Criar projeto Delphi** FMX, plataforma Win64
5. **Criar as units** na ordem: FFmpeg.Binding → Pion.Whep.Binding → Video.Decoder → Audio.Player → Main
6. **Desenhar o form** conforme layout da seção 8
7. **Copiar DLLs** para pasta de output
8. **Compilar e testar** contra MediaMTX rodando com um stream ativo
9. **Se offsets FFmpeg falharem**, compilar a `ffmpeg_helper.dll` e ajustar bindings

---

## 13. COMANDOS DE COMPILAÇÃO RESUMIDOS

### Go DLL:
```batch
cd C:\pion_whep
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64
go mod tidy
go build -buildmode=c-shared -o pion_whep.dll .
```

### FFmpeg Helper (opcional, se necessário):
```batch
gcc -shared -o ffmpeg_helper.dll ffmpeg_helper.c -I"C:\ffmpeg\include" -L"C:\ffmpeg\lib" -lavcodec -lavutil -lswscale -O2
```

### Delphi:
- Build Configuration: Release
- Target Platform: Windows 64-bit
- Output directory: deve conter todas as DLLs listadas na seção 11
