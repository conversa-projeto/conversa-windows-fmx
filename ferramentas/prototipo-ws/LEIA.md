# Protótipo do tempo real (WebSocket do WinHTTP)

Etapa 0.7 do `TODO.md` (doc 07 §10, decisão D9). O *script* chama **as mesmas funções do WinHTTP** que a nova base usa em Delphi (`WinHttpWebSocketCompleteUpgrade`, `WinHttpWebSocketSend`, `WinHttpWebSocketReceive`, `WinHttpWebSocketClose`). Como esta máquina não compila Delphi por linha de comando (ADR 0001), o protótipo é PowerShell com C# embutido (`Add-Type`, compilado pelo .NET Framework do próprio Windows): roda em qualquer Windows 10/11 sem instalar nada.

## Como rodar

```powershell
$env:CONVERSA_LOGIN = 'teste.android.a'
$env:CONVERSA_SENHA = '<senha da conta de teste>'   # contas: docs/desenvolvimento/servidor-de-dev.md §3
.\ferramentas\prototipo-ws\prototipo-ws.ps1 -Servidor https://localhost -Minutos 8
```

- Mande mensagens para esse usuário pelo web (outro usuário) e veja os eventos chegarem.
- Para testar a queda: `docker restart api`.
- O *script* só registra o **tipo e o tamanho** de cada evento, nunca o token, a senha ou o conteúdo.
- Para encerrar antes do prazo, feche a janela. A recepção bloqueia dentro do WinHTTP, e um `Stop-Job` não a interrompe.

## Resultado (2026-10-09, servidor de desenvolvimento em `https://localhost`)

| Teste | Resultado |
|---|---|
| *Handshake* em `wss://localhost/ws/` com o certificado do mkcert (CA no repositório do usuário) | `HTTP 101` em 25 ms; o WinHTTP valida a cadeia normalmente e **não** confere revogação por padrão (o mkcert não publica lista de revogação; o `curl` do Windows falha justamente nisso, ver `docs/desenvolvimento/servidor-de-dev.md` §2) |
| Login `{"tipo":1,"token":"…"}` com `tipo` numérico | aceito (não há resposta de sucesso, como diz o contrato) |
| Mensagem do usuário B (`PUT /api/mensagem`) | WS 2 (104 bytes) chegou no A na hora (dentro dos ~2 s que o *script* do B leva para entrar e enviar) |
| **Ocioso** | WS 2 recebido depois de **280 s** e de **325 s** sem nenhum evento. Pelo doc 01 §6.7, o padrão do Bun é encerrar conexões ociosas em 120 s; o *keepalive* do WinHTTP (padrão de 30 s) as manteve |
| `docker restart api` | a recepção terminou com o erro **12030** (`ERROR_WINHTTP_CONNECTION_ERROR`) ~1,2 s depois; a 1ª reconexão recebeu **502** do nginx (API subindo); a 2ª, 2,1 s depois, conectou; o WS 2 seguinte chegou normalmente |
| *Keepalive* (`WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL` = 116) | **só é aceito no *handle* do WebSocket**, depois do `WinHttpWebSocketCompleteUpgrade`; na sessão e no pedido dá **12018** (`ERROR_WINHTTP_INCORRECT_HANDLE_TYPE`). 15000 ms (o mínimo) foi aceito; o padrão é 30000 |
| Valores do `winhttp.h` que a RTL do Delphi não declara | confirmados na prática: `WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET` = 114, `…KEEPALIVE_INTERVAL` = 116, tipos de *buffer* 0–4 (o 2 é mensagem UTF-8), `WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY` = 4 |

## O que isso define para a nova base (`TTempoRealWinHttp`, Etapa 1.12)

- **Sem *ping* de aplicação** (o servidor não tem; doc 01 §6.7).
  - A conexão fica viva com o *keepalive* do WinHTTP (30 s, configurado no *handle* do WebSocket).
  - Uma conexão morta aparece como erro no `WinHttpWebSocketReceive`:
    - na hora, quando a outra ponta fecha;
    - pelo tempo de retransmissão do TCP, quando a rede some.
  - Ao voltar da suspensão e quando a rede muda, reconectar na hora, sem esperar o erro.
- **A recepção bloqueia** dentro do WinHTTP. Para encerrar a thread, fechar o *handle* do WebSocket (`WinHttpWebSocketClose`/`WinHttpCloseHandle`) a partir de outra thread, o que faz o `Receive` voltar com erro. Nunca matar a thread.
- **502/503 do nginx no *handshake*** é erro temporário: entra no *backoff* normal.
- O pedido HTTP do *handshake* pode (e deve) ser fechado logo depois do *upgrade*.
