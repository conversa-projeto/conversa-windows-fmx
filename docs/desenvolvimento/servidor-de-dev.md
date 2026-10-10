# Rodar o cliente Windows contra o servidor de desenvolvimento

Como compilar o FMX e testá-lo de ponta a ponta contra o servidor local (`../conversa`), com o outro lado no cliente web.

## 1. O servidor de desenvolvimento

- Sobe com `conversa/bin/iniciar-desenvolvimento.bat` (Docker: `api`, `nginx`, `postgres`, `minio`, `mediamtx`, `coturn`; o web de desenvolvimento roda no container `dev`).
- Ponto de entrada único: **`https://localhost`** (nginx na porta **443**; antes era 4430):
  - `/api/` → API (Bun + Elysia, `127.0.0.1:8080` por dentro);
  - `/ws/` → WebSocket (com a barra final; `/ws` recebe 301, que um cliente WebSocket não segue);
  - `/storage/` → MinIO (URLs assinadas);
  - `/webrtc/` → MediaMTX (WHIP/WHEP);
  - TURN fora do nginx: `turn:localhost:3478?transport=tcp` (só TCP).
- Conferir: `GET https://localhost/api/usuario/permissoes` sem token → **401** com `{"error":"Token não informado"}`.
- **Use sempre o nginx** (não a API direto em `:8080`): sem ele faltam o `X-Forwarded-Proto` e o `Host` público, e as URLs do MinIO e do TURN saem erradas (doc 01, D15).

## 2. Certificado (TLS)

- O certificado do nginx de desenvolvimento é do **mkcert** (`conversa/bin/setup-cert.bat`), com os nomes `localhost`, `127.0.0.1` e o IP digitado no *script*.
- **Nesta máquina a CA do mkcert já está instalada** no repositório "Autoridades de Certificação Raiz Confiáveis" do **usuário atual** (conferido com `certutil -user -store Root` em 2026-10-08).
  - O `THTTPClient`/`TNetHTTPClient` (WinHTTP) usa esse repositório: o REST funciona com `https://localhost` sem nada extra. O WinHTTP **não confere revogação** por padrão, e a RTL do Delphi não liga essa checagem (`System.Net.HttpClient.Win.pas` não usa `WINHTTP_ENABLE_SSL_REVOCATION`).
  - O WebSocket do WinHTTP (nova base) também usa esse repositório: conferido com o protótipo `ferramentas/prototipo-ws/` em 2026-10-09.
  - O `curl` do Git Bash usa o SChannel (o mesmo repositório), mas **confere revogação**, e o mkcert não publica lista de revogação. Por isso o `curl` falha com `CRYPT_E_NO_REVOCATION_CHECK (0x80092012)`. Use `curl --ssl-no-revoke https://localhost/...`, que continua validando a cadeia (nunca `-k`).
  - O Indy/OpenSSL (o WebSocket do app atual) também **não** usa: precisa das DLLs do OpenSSL e não valida o certificado (doc 04 #5).
- Em outro PC: copiar o `rootCA.pem` (pasta de `mkcert -CAROOT` da máquina do servidor) e importar no repositório do usuário: `certutil -user -addstore Root rootCA.pem`. **Nunca** desligar a validação de certificado no código.

## 3. Contas de teste

O banco de desenvolvimento (`conversa_dev`) tem as contas descartáveis criadas para os testes do Android: `teste.android.a`, `teste.android.b` e `teste.android.c` (as senhas estão em `../conversa-android-kotlin/docs/desenvolvimento/emulador.md`). Elas só existem no servidor local. Se o desktop precisar de contas próprias, criar `teste.windows.a`/`b` pelo cadastro e registrar aqui.

## 4. O outro lado: o cliente web

Para conversar com o desktop e testar chamadas, o outro usuário fica no web, num Chrome de **perfil descartável** (fora do perfil da pessoa), com câmera e microfone falsos:

```
chrome.exe --user-data-dir=<pasta temporária> --use-fake-device-for-media-stream --use-fake-ui-for-media-stream https://localhost/
```

O guia completo (inclusive como comandar o web por *scripts* pelo DevTools Protocol) está em `../conversa-android-kotlin/docs/desenvolvimento/emulador.md`, seção "Chamadas".

## 5. O app atual (legado) contra o servidor de desenvolvimento

O app atual foi escrito para o servidor Delphi. Para rodá-lo hoje:

1. **Compilar em Win64** no IDE (a plataforma padrão do `.dproj` é Win32, e as DLLs de mídia são x64).
2. **Montar a pasta `bin/`** (nada disso está no Git):
   - `pion_whep.dll`: `conversa-webrtc/bin/` (ou compilar: `conversa-webrtc/pion/DOC_COMPILACAO.md`, Go + GCC 64 bits) → copiar para `bin/`;
   - FFmpeg 8.x *win64 shared* (`avcodec-62`, `avutil-60`, `swresample-6`, `swscale-9`) → `bin/` (**atenção:** o build atual é GPLv3; ver ADR 0002);
   - `sk4d.dll` **x64**: `C:\Program Files (x86)\Embarcadero\Studio\23.0\bin64\sk4d.dll` (o `bin/sk4d.dll` versionado é x86);
   - `bin/tema/default.pss` (o app não abre sem ele; o caminho é relativo ao diretório atual).
3. **Endereço:** na primeira execução, o campo "Host" deve ser **`https://localhost/api/`** (com `/api/`). O `conversa.json` de desenvolvimento antigo aponta para `https://localhost:4430/api/`, que não existe mais.
4. **WebSocket:** com `https`, o Indy precisa de `libeay32.dll` e `ssleay32.dll` (OpenSSL 1.0.2 x64) ao lado do exe — **não estão na máquina**. Sem elas, o app abre e faz login, mas fica **sem tempo real**. Alternativa só para teste: o *proxy* sem TLS do Android (`node ../conversa-android-kotlin/ferramentas/proxy-dev.mjs`, porta 8081, repassa `/api/`, `/ws/`, `/storage/` e `/webrtc/`) e o "Host" `http://localhost:8081/api/` — aí o WebSocket vai em `ws://` e não precisa de OpenSSL.
5. **Chamadas:** não funcionam contra o servidor atual (sem TURN; doc 04 #12) e **transmitem a tela inteira** (doc 04 #1). Não testar chamadas com o app atual em ambiente com dados reais.

### 5.1 DLLs presentes nesta máquina (conferidas em 2026-10-09)

Nenhuma é versionada, exceto o `bin/sk4d.dll` x86, que já estava no Git. Arquitetura lida do cabeçalho PE; nenhuma foi executada.

| Arquivo | Onde | Arq. | Tamanho (bytes) | Versão | SHA-256 |
|---|---|---|---|---|---|
| `pion_whep.dll` | `bin/` (cópia de `conversa-webrtc/bin/`) | x64 | 19.480.956 | — | `195c9ce6de36965dde5b1342ba0e6523d68886575dc585267c0bf839c7c7ee6d` |
| `avcodec-62.dll` | `bin/` | x64 | 97.576.448 | 62.29.101 | `33ba2e735252b5bfcd30e5c2da326cfde78ee86092fdc12d621814c24421c724` |
| `avutil-60.dll` | `bin/` | x64 | 2.930.688 | 60.29.100 | `b3b174c399856c59ca7354292098bd77842f5fdb643ab0fcd19f2b97053b43ab` |
| `swresample-6.dll` | `bin/` | x64 | 722.944 | 6.4.100 | `59ed65b2c16fcf2d4b6b851384b79a2c2c55fa0aa51fb723446c4c2a3cdcc882` |
| `swscale-9.dll` | `bin/` | x64 | 12.537.344 | 9.7.100 | `9cc8a26e3951ba60859ad29455fa7abb3eb624293f369410a8e6a0be63c7b252` |
| `sk4d.dll` | `bin/` (versionado) | **x86** | 18.961.920 | — | `6fec995537fb76b6da424229394a80bdf6e4d415b76121c372aa4ca4b6643fca` |
| `sk4d.dll` | `Studio\23.0\bin64\` | x64 | 19.870.192 | — | `67f7a4e0bcae89dd9f6d8416281f85cc9ddd6a77de83d6cb7100e8ab4ee024e3` |

A `bin/` do legado **não foi montada em Win64** na Etapa 0: o app atual fica congelado (ADR 0001), e o teste dele depende do build no IDE e de clicar na janela (§7).

## 6. Compilar

- **Delphi 12.1 Athens, edição Community** nesta máquina (registro: `Edition = Starter`): **compila só pelo IDE**. `msbuild`, `dcc32` e `dcc64` respondem "This version of the product does not support command line compiling" — e **o MSBuild sai com código 0** mesmo assim. Os `dcc32.exe`/`dcc64.exe` da pasta `bin` são *stubs* de 23 KB.
- O `DelphiLSP.exe` (diagnósticos do *Error Insight*) também não serve fora do IDE nesta edição: testado em 2026-10-09 com um cliente LSP mínimo, respondeu "A valid license was not found. Please contact Embarcadero Support." e não publicou diagnósticos.
- **Decisão (ADR 0001, 2026-10-09):** o código é escrito e revisado sem compilar (APIs conferidas no fonte do Delphi; `uses` conferidos por `ferramentas/verificar-uses`), e o responsável compila no IDE ("build geral") e devolve os erros.
- Com licença Professional ou superior:
  ```
  cmd /c "call ""C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"" && msbuild Conversa.dproj /t:Build /p:Config=Debug /p:Platform=Win64"
  ```
  Conferir **o exe gerado e o log** (data do exe, ausência de `error`/`Fatal`), não só o código de saída.
- O `.dproj` atual tem um *PreBuild* `taskkill /f /t /im Conversa.exe`, que **fecha qualquer Conversa aberto na máquina** a cada build.
- Antes de builds longos, conferir o espaço livre do C: (`(Get-PSDrive C).Free`); a pasta do repositório já ocupa ~876 MB de saídas e restos de build.

## 7. Limites de teste nesta máquina

- O agente de IA que trabalha no repositório **não consegue clicar na janela do app** (só tem ferramentas de navegador): testes de interface ficam com a pessoa, ou com uma automação a montar (ex.: um *hook* de diagnóstico no próprio app).
- A lógica deve ter testes DUnitX (doc 07 D17), que dependem de conseguir compilar (§6).
