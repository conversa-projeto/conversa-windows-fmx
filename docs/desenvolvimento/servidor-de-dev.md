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
  - O `THTTPClient`/`TNetHTTPClient` (WinHTTP) usa esse repositório: o REST funciona com `https://localhost` sem nada extra.
  - O `curl` do Git Bash **não** usa esse repositório (precisa de `-k` ou do `rootCA.pem`).
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

## 6. Compilar

- **Delphi 12.1 Athens, edição Community** nesta máquina: **compila só pelo IDE**. `msbuild`, `dcc32` e `dcc64` respondem "This version of the product does not support command line compiling" — e **o MSBuild sai com código 0** mesmo assim.
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
