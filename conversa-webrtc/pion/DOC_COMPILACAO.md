# pion_whep.dll — Guia de Compilação

## Pré-requisitos

### 1. Go (compilador)

- **Download:** https://go.dev/dl/
- Baixar o instalador `.msi` para Windows 64-bit (ex: `go1.26.x.windows-amd64.msi`)
- Instalar com as opções padrão (o instalador já adiciona ao PATH)
- Verificar:
  ```
  go version
  ```
  Deve retornar algo como: `go version go1.26.1 windows/amd64`

### 2. GCC 64-bit (necessário para CGO)

O Go precisa de um compilador C para gerar DLLs com `buildmode=c-shared`.
O GCC padrão do Windows para isso é o **WinLibs** (recomendado) ou TDM-GCC.

#### Opção A — WinLibs (recomendado)

- **Download:** https://winlibs.com/
- Na seção **Release versions**, baixar:
  - **GCC 14.x** → **UCRT runtime** → arquivo **Win64** → `.zip`
  - Exemplo: `winlibs-x86_64-posix-seh-gcc-14.x.x-mingw-w64ucrt-x.x.x-rx.zip`
- Extrair para uma pasta, ex: `C:\winlibs-gcc\`
- Adicionar `C:\winlibs-gcc\mingw64\bin` ao PATH do sistema

#### Opção B — TDM-GCC

- **Download:** https://jmeubank.github.io/tdm-gcc/download/
- Baixar e executar o instalador `.exe` (não o zip — o zip não instala os headers)
- Instalar com as opções padrão

#### Verificar GCC

```
gcc --version
```
Deve retornar algo como: `gcc (x86_64-posix-seh-rev0, Built by MinGW-Builds project) 14.x.x`

---

## Estrutura de arquivos

```
pion\
├── go.mod      ← dependências do módulo
├── go.sum      ← hashes de integridade (gerado automaticamente)
├── main.go     ← código-fonte da DLL
├── DOC_API.md
└── DOC_COMPILACAO.md
```

---

## Compilação

### Passo 1 — Baixar dependências

Na pasta `pion\`, executar uma vez:

```bat
cd D:\testewebrtc\pion
go mod tidy
```

Isso baixa automaticamente:
- `github.com/pion/webrtc/v4` — stack WebRTC
- e todas as dependências transitivas (ice, dtls, srtp, sdp, rtp, etc.)

As dependências ficam em cache em `%USERPROFILE%\go\pkg\mod\`.

### Passo 2 — Compilar a DLL

```bat
cd D:\testewebrtc\pion
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64
go build -buildmode=c-shared -o ..\bin\pion_whep.dll .
```

**Resultado:** dois arquivos gerados em `..\bin\`:
- `pion_whep.dll` — a DLL para distribuição
- `pion_whep.h` — header C gerado automaticamente (referência, não necessário para Delphi)

### Script de build completo

Salvar como `build.bat` dentro da pasta `pion\`:

```bat
@echo off
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64
echo Compilando pion_whep.dll...
go build -buildmode=c-shared -o ..\bin\pion_whep.dll .
if %ERRORLEVEL% == 0 (
    echo OK: ..\bin\pion_whep.dll gerada com sucesso.
) else (
    echo ERRO: falha na compilacao. Verifique go e gcc no PATH.
)
pause
```

---

## Erros comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `gcc not found in %PATH%` | GCC não instalado ou não está no PATH | Instalar WinLibs e adicionar ao PATH |
| `fatal error: stddef.h: No such file or directory` | TDM-GCC instalado via zip (incompleto) | Reinstalar via instalador `.exe` ou usar WinLibs |
| `go: module not found` | Sem acesso à internet ou proxy bloqueando | Rodar `go env GOPROXY` e verificar conectividade |
| DLL gerada mas app falha com `0xc000007b` | DLL 64-bit sendo carregada em app 32-bit | Compilar o app consumidor para Win64 |

---

## Dependências Go (go.mod)

```
module pion_whep

go 1.22

require github.com/pion/webrtc/v4 v4.0.0
```

Dependências indiretas relevantes (gerenciadas automaticamente pelo `go mod tidy`):

| Pacote | Função |
|--------|--------|
| `pion/ice/v4` | Negociação ICE (descoberta de candidatos de rede) |
| `pion/dtls/v3` | Handshake DTLS (criptografia da conexão WebRTC) |
| `pion/srtp/v3` | Decodifica o envelope SRTP dos pacotes RTP |
| `pion/sdp/v3` | Parseia e gera SDP offer/answer |
| `pion/rtp` | Estruturas de pacotes RTP |
| `pion/rtcp` | Pacotes RTCP (controle) |
| `pion/interceptor` | Pipeline de interceptadores RTP/RTCP |

---

## Versões testadas

| Ferramenta | Versão testada |
|------------|----------------|
| Go | 1.26.1 windows/amd64 |
| pion/webrtc | v4.0.0 |
| GCC (WinLibs) | 14.x |
| MediaMTX (servidor WHEP) | v1.12.2 |
| Windows | 11 Pro 64-bit |
