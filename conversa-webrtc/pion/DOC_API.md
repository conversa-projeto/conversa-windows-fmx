# pion_whep.dll — Documentação da API

## Visão Geral

`pion_whep.dll` é uma DLL Windows 64-bit escrita em Go utilizando a biblioteca
[Pion WebRTC](https://github.com/pion/webrtc). Ela implementa o lado cliente do
protocolo **WHEP** (WebRTC-HTTP Egress Protocol), permitindo que aplicações
nativas (Delphi, C++, etc.) recebam streams de vídeo H264 e áudio Opus a partir
de servidores como o **MediaMTX**.

### O que ela faz

1. Gera um SDP offer (WebRTC) com transceptores de vídeo e áudio (recvonly)
2. Aguarda o ICE gathering completar
3. Envia o offer via HTTP POST para o endpoint WHEP do servidor
4. Recebe o SDP answer e estabelece a conexão ICE/DTLS-SRTP
5. Recebe pacotes RTP H264, depacketiza para Annex-B e entrega via callback de vídeo
6. Recebe pacotes RTP Opus e entrega os payloads brutos via callback de áudio

### O que ela NÃO faz

- Não decodifica vídeo (isso fica no lado do consumidor, ex: FFmpeg)
- Não decodifica áudio (isso fica no lado do consumidor, ex: FFmpeg Opus)
- Não faz relay, gravação ou reencaminhamento

---

## Fluxo de uso

```
1. WhepSetLogEnabled(1)              ← opcional, habilita log em arquivo
2. WhepInit(videoCb, audioCb, stateCb) ← uma vez ao iniciar a aplicação
3. WhepConnect(url, auth, user, pass)  ← uma vez por stream; retorna handle
4. [callbacks disparam em threads]
5. WhepDisconnect(handle)              ← para encerrar cada stream
```

Múltiplas conexões simultâneas são suportadas. Cada chamada a `WhepConnect`
retorna um **handle** único que identifica aquela conexão em todos os callbacks.

---

## Funções Exportadas

### `WhepSetLogEnabled`

```c
void WhepSetLogEnabled(int32_t enabled);
```

Habilita (`1`) ou desabilita (`0`) o log em arquivo. **Por padrão o log começa
desabilitado.** Pode ser chamada antes ou depois de `WhepInit`.

Quando habilitado, grava `pion_whep.log` na mesma pasta do executável que
carregou a DLL. Em caso de falha de permissão, tenta `C:\pion_whep.log`.

---

### `WhepInit`

```c
int32_t WhepInit(
    VideoFrameCallback videoCb,
    AudioFrameCallback audioCb,
    StateCallback      stateCb
);
```

Registra os callbacks globais. Deve ser chamada **uma única vez** antes de
qualquer `WhepConnect`.

| Parâmetro  | Tipo                  | Descrição                           |
|------------|-----------------------|-------------------------------------|
| `videoCb`  | `VideoFrameCallback`  | Callback para frames H264 Annex-B   |
| `audioCb`  | `AudioFrameCallback`  | Callback para payloads Opus brutos  |
| `stateCb`  | `StateCallback`       | Callback para mudanças de estado    |

**Retorno:** `0` em sucesso.

---

### `WhepConnect`

```c
int32_t WhepConnect(
    const char* whepURL,
    const char* authType,
    const char* username,
    const char* password
);
```

Inicia uma conexão WHEP. **Bloqueia** até o ICE gathering e o handshake HTTP
completarem (tipicamente 1–5 segundos). Deve ser chamada em uma thread separada
para não travar a UI.

| Parâmetro   | Tipo          | Descrição                                                      |
|-------------|---------------|----------------------------------------------------------------|
| `whepURL`   | `const char*` | URL completa do endpoint WHEP, ex: `http://host:8889/cam/whep` |
| `authType`  | `const char*` | Tipo de autenticação: `"Basic"` ou `""` para nenhuma           |
| `username`  | `const char*` | Usuário (pode ser `""`)                                        |
| `password`  | `const char*` | Senha (pode ser `""`)                                          |

**Retorno:**
- `> 0` — handle da conexão (usar para callbacks e disconnect)
- `< 0` — código de erro (ver tabela abaixo)

| Código | Causa                                        |
|--------|----------------------------------------------|
| `-1`   | Falha ao criar MediaEngine ou PeerConnection |
| `-2`   | Falha ao adicionar transceiver de vídeo      |
| `-3`   | Falha ao adicionar transceiver de áudio      |
| `-4`   | Falha ao criar SDP offer                     |
| `-5`   | Falha ao setar LocalDescription              |
| `-6`   | Falha no HTTP POST (rede ou URL inválida)    |
| `-7`   | Servidor retornou status != 200/201          |
| `-8`   | Falha ao ler SDP answer                      |
| `-9`   | Falha ao setar RemoteDescription             |

---

### `WhepDisconnect`

```c
int32_t WhepDisconnect(int32_t handle);
```

Encerra a conexão identificada pelo handle e libera recursos.
O `StateCallback` será disparado com estado `0` (Disconnected).

**Retorno:** `0` sempre.

---

## Callbacks

Os callbacks são chamados em **threads internas da DLL** (goroutines Go).
O código do consumidor deve ser thread-safe e não deve bloquear o callback
por longos períodos.

### `VideoFrameCallback`

```c
typedef void (*VideoFrameCallback)(
    int32_t handle,
    uint8_t* data,
    int32_t  size,
    int64_t  timestamp_ms
);
```

Chamado cada vez que um frame H264 completo está disponível.

| Parâmetro      | Descrição                                                                    |
|----------------|------------------------------------------------------------------------------|
| `handle`       | Identifica qual conexão gerou o frame                                        |
| `data`         | Ponteiro para os bytes H264 no formato **Annex-B** (start code `00 00 00 01`) |
| `size`         | Tamanho em bytes                                                             |
| `timestamp_ms` | Sempre `0` na versão atual                                                   |

> **IMPORTANTE:** O ponteiro `data` é válido apenas durante a execução do
> callback. Copie os dados antes de retornar.

### `AudioFrameCallback`

```c
typedef void (*AudioFrameCallback)(
    int32_t handle,
    uint8_t* data,
    int32_t  size,
    int64_t  timestamp_ms
);
```

Chamado cada vez que um payload Opus bruto está disponível (conteúdo do pacote RTP,
sem cabeçalho RTP). O consumidor é responsável por decodificar via FFmpeg ou similar.

| Parâmetro      | Descrição                             |
|----------------|---------------------------------------|
| `handle`       | Identifica qual conexão gerou o frame |
| `data`         | Payload Opus bruto                    |
| `size`         | Tamanho em bytes                      |
| `timestamp_ms` | Sempre `0` na versão atual            |

> **IMPORTANTE:** O ponteiro `data` é válido apenas durante a execução do
> callback. Copie os dados antes de retornar.

### `StateCallback`

```c
typedef void (*StateCallback)(
    int32_t handle,
    int32_t state
);
```

| `state` | Significado         |
|---------|---------------------|
| `0`     | Desconectado        |
| `1`     | Conectando...       |
| `2`     | Conectado           |
| `3`     | Falha na conexão    |

---

## Exemplo — Delphi (Pascal)

```pascal
// Tipos
TVideoFrameCallback = procedure(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
TAudioFrameCallback = procedure(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
TStateCallback      = procedure(Handle: Int32; State: Int32); cdecl;

// Imports
procedure WhepSetLogEnabled(Enabled: Int32); cdecl; external 'pion_whep.dll';
function  WhepInit(VideoCb: TVideoFrameCallback; AudioCb: TAudioFrameCallback;
                   StateCb: TStateCallback): Int32; cdecl; external 'pion_whep.dll';
function  WhepConnect(URL, AuthType, User, Pass: PAnsiChar): Int32; cdecl; external 'pion_whep.dll';
function  WhepDisconnect(Handle: Int32): Int32; cdecl; external 'pion_whep.dll';

// Uso
WhepSetLogEnabled(1); // habilitar log (opcional)
WhepInit(@MeuVideoCallback, @MeuAudioCallback, @MeuStateCallback);

// Em thread separada:
Handle := WhepConnect('http://192.168.1.1:8889/cam/whep', 'Basic', 'admin', 'senha');
if Handle > 0 then
  // conexão estabelecida, guardar Handle para desconectar depois

// Para encerrar:
WhepDisconnect(Handle);
```

---

## Log

Por padrão o log está **desabilitado**. Para habilitar, chamar:

```c
WhepSetLogEnabled(1);
```

Quando habilitado, o log é gravado em `pion_whep.log` na mesma pasta do executável
que carregou a DLL. Em caso de falha de permissão de escrita, tenta `C:\pion_whep.log`.

O log registra cada etapa da conexão, frames recebidos (primeiros 5 e a cada 300)
e erros detalhados.

---

## Limitações conhecidas

| Item | Detalhe |
|------|---------|
| Somente H264 | Vídeo decodificado no cliente; apenas H264 depacketizado na DLL |
| Áudio Opus bruto | Payload entregue sem decodificação; decodificar com FFmpeg no cliente |
| Sem TURN | Apenas candidatos ICE locais (host). Não funciona com NAT estrito entre cliente e servidor |
| `timestamp_ms` sempre 0 | Timestamp RTP não é convertido para ms na versão atual |
| `authType` | Apenas `"Basic"` implementado |
| Sem TLS | HTTPS não testado; use HTTP em redes locais |
