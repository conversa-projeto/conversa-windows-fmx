# pion_whep.dll — WHIP: Documentação da API de Envio

## Visão Geral

Além do WHEP (recepção), a DLL implementa o protocolo **WHIP** (WebRTC HTTP
Ingestion Protocol), permitindo **enviar** streams de vídeo H264 e/ou áudio Opus
para um servidor como o MediaMTX.

O Delphi fica responsável por:
1. Capturar vídeo (câmera) e/ou áudio (microfone)
2. Encodar com FFmpeg (`avcodec_encode_video2` / `avcodec_encode_audio2`)
3. Passar os frames já encodados para a DLL via `WhipSendVideo` / `WhipSendAudio`

A DLL faz o empacotamento RTP e toda a sinalização WebRTC.

---

## Fluxo de uso

```
1. WhipInit(stateCb)                        ← uma vez (ou usar WhepInit se já chamou)
2. Em thread separada:
   Handle := WhipConnect(url, auth, user, pass, sendVideo, sendAudio)
3. Loop de captura/encoding:
   WhipSendVideo(Handle, h264Data, size, durationMs)
   WhipSendAudio(Handle, opusData, size, durationMs)
4. WhipDisconnect(Handle)                   ← para encerrar
```

WHEP e WHIP podem rodar simultaneamente. Cada `WhipConnect` retorna um
**handle** único, independente dos handles WHEP.

---

## Funções Exportadas

### `WhipInit`

```c
int32_t WhipInit(StateCallback stateCb);
```

Registra o `StateCallback` para conexões WHIP. Usar quando **só se usa WHIP**
(sem recepção WHEP). Se `WhepInit` já foi chamado, o `StateCallback` já está
registrado — não é necessário chamar `WhipInit`.

**Retorno:** `0` em sucesso.

---

### `WhipConnect`

```c
int32_t WhipConnect(
    const char* whipURL,
    const char* authType,
    const char* username,
    const char* password,
    int32_t     sendVideo,
    int32_t     sendAudio
);
```

Abre uma conexão WHIP. **Bloqueia** até o ICE gathering e o handshake HTTP
completarem. Chamar em thread separada.

| Parâmetro   | Descrição                                                        |
|-------------|------------------------------------------------------------------|
| `whipURL`   | URL do endpoint WHIP, ex: `http://host:8889/cam/whip`            |
| `authType`  | `"Basic"` ou `""` para sem autenticação                          |
| `username`  | Usuário (pode ser `""`)                                          |
| `password`  | Senha (pode ser `""`)                                            |
| `sendVideo` | `1` para enviar vídeo H264, `0` para desabilitar                 |
| `sendAudio` | `1` para enviar áudio Opus, `0` para desabilitar                 |

**Retorno:** `> 0` = handle, `< 0` = erro.

| Código | Causa                                        |
|--------|----------------------------------------------|
| `-1`   | Falha ao criar MediaEngine ou PeerConnection |
| `-2`   | Falha ao criar track de vídeo H264           |
| `-3`   | Falha ao criar track de áudio Opus           |
| `-4`   | Falha ao adicionar track ao PeerConnection   |
| `-5`   | Falha ao criar SDP offer                     |
| `-6`   | Falha ao setar LocalDescription              |
| `-7`   | Falha no HTTP POST (rede ou URL inválida)    |
| `-8`   | Servidor retornou status != 200/201          |
| `-9`   | Falha ao ler SDP answer                      |
| `-10`  | Falha ao setar RemoteDescription             |

---

### `WhipSendVideo`

```c
int32_t WhipSendVideo(
    int32_t  handle,
    uint8_t* data,
    int32_t  size,
    int32_t  durationMs
);
```

Envia um frame H264 para o servidor.

| Parâmetro    | Descrição                                                          |
|--------------|--------------------------------------------------------------------|
| `handle`     | Handle retornado por `WhipConnect`                                 |
| `data`       | Frame H264 no formato **Annex-B** (com start code `00 00 00 01`)   |
| `size`       | Tamanho em bytes                                                   |
| `durationMs` | Duração do frame em ms (ex: `33` para 30fps); `0` = usa 33ms      |

> O start code Annex-B é o mesmo formato que o decoder FFmpeg gera na saída.
> Não é necessário remover os start codes — a DLL faz isso internamente.

**Retorno:** `0` = sucesso, `-1` = handle inválido ou vídeo não habilitado, `-2` = erro de envio.

---

### `WhipSendAudio`

```c
int32_t WhipSendAudio(
    int32_t  handle,
    uint8_t* data,
    int32_t  size,
    int32_t  durationMs
);
```

Envia um payload Opus bruto para o servidor.

| Parâmetro    | Descrição                                                     |
|--------------|---------------------------------------------------------------|
| `handle`     | Handle retornado por `WhipConnect`                            |
| `data`       | Payload Opus bruto (saída do encoder `AV_CODEC_ID_OPUS`)      |
| `size`       | Tamanho em bytes                                              |
| `durationMs` | Duração em ms (ex: `20`); `0` = usa 20ms (padrão Opus)       |

**Retorno:** `0` = sucesso, `-1` = handle inválido ou áudio não habilitado, `-2` = erro de envio.

---

### `WhipDisconnect`

```c
int32_t WhipDisconnect(int32_t handle);
```

Encerra a conexão WHIP e libera recursos. O `StateCallback` é disparado com
estado `0` (Disconnected).

**Retorno:** `0` sempre.

---

## Exemplo — Delphi (Pascal)

```pascal
// Imports (em Pion.Whep.Binding.pas)
function  WhipInit(StateCb: TStateCallback): Int32; cdecl; external 'pion_whep.dll';
function  WhipConnect(URL, AuthType, User, Pass: PAnsiChar;
                      SendVideo, SendAudio: Int32): Int32; cdecl; external 'pion_whep.dll';
function  WhipSendVideo(Handle: Int32; Data: PByte; Size, DurationMs: Int32): Int32; cdecl; external 'pion_whep.dll';
function  WhipSendAudio(Handle: Int32; Data: PByte; Size, DurationMs: Int32): Int32; cdecl; external 'pion_whep.dll';
function  WhipDisconnect(Handle: Int32): Int32; cdecl; external 'pion_whep.dll';

// Inicialização (se não chamou WhepInit)
WhipInit(@MeuStateCallback);

// Conexão em thread separada — envio de vídeo e áudio
TThread.CreateAnonymousThread(procedure
var
  H: Int32;
  URLAnsi: AnsiString;
begin
  URLAnsi := 'http://192.168.1.1:8889/cam/whip';
  H := WhipConnect(PAnsiChar(URLAnsi), '', '', '', 1 {video}, 1 {audio});
  if H > 0 then
  begin
    // Loop de captura e encoding...
    // WhipSendVideo(H, h264Ptr, h264Size, 33);
    // WhipSendAudio(H, opusPtr, opusSize, 20);
  end;
end).Start;

// Para encerrar:
WhipDisconnect(Handle);
```

---

## Configuração do MediaMTX

Para aceitar WHIP, o `mediamtx.yml` precisa ter o path configurado com
`whipAddress`:

```yaml
paths:
  cam:
    source: publisher
```

O endpoint WHIP padrão do MediaMTX é:
```
http://HOST:8889/CAMINHO/whip
```

---

## Diferenças WHEP vs WHIP

| Aspecto | WHEP (recepção) | WHIP (envio) |
|---------|-----------------|--------------|
| Função de conexão | `WhepConnect` | `WhipConnect` |
| Direção RTP | `recvonly` | `sendonly` |
| Callbacks de mídia | `VideoFrameCallback`, `AudioFrameCallback` | nenhum (dados vão para o servidor) |
| Formato de vídeo | H264 Annex-B entregue ao app | H264 Annex-B enviado pela app |
| Formato de áudio | Opus bruto entregue ao app | Opus bruto enviado pela app |
| Função de envio | — | `WhipSendVideo`, `WhipSendAudio` |
| Endpoint servidor | `.../CAMINHO/whep` | `.../CAMINHO/whip` |

---

## Limitações

| Item | Detalhe |
|------|---------|
| Somente H264 | Apenas H264 suportado para vídeo |
| Somente Opus | Apenas Opus suportado para áudio |
| Sem TURN | Apenas ICE local (host). Não funciona com NAT estrito |
| Sem feedback de congestionamento | RTCP REMB não implementado nesta versão |
| `authType` | Apenas `"Basic"` implementado |
