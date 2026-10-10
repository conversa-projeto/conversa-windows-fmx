# 2026-10-09 · 06 · Protótipo do tempo real (WebSocket do WinHTTP)

- **Fluxo:** Planejamento e documentação (cita "Fundação (etapa 1)": define a 1.12)
- **Tipo:** protótipo / decisão técnica
- **Itens:** `TODO.md` 0.7; doc 07 §10 item 2 e D9; FC-111
- **Branch:** `chamada`
- **Commits:** `9b796ef`

## Contexto
A decisão D9 (WebSocket do WinHTTP numa thread própria) precisava ser provada antes da Etapa 1. Os pontos em aberto eram: o certificado do mkcert, o login do socket, o comportamento ocioso (o servidor não tem *ping* de aplicação) e a reconexão. Sem compilação Delphi por linha de comando, o protótipo foi feito com **as mesmas funções do WinHTTP** chamadas de C# (PowerShell `Add-Type`).

## O que foi feito
- `ferramentas/prototipo-ws/prototipo-ws.ps1`:
  1. login REST;
  2. *handshake* WebSocket pelo WinHTTP (`WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET`, `WinHttpWebSocketCompleteUpgrade`);
  3. `{"tipo":1,"token":…}` com `tipo` numérico;
  4. recepção juntando fragmentos;
  5. registro só do tipo e do tamanho de cada evento;
  6. reconexão com *backoff* `min(30 s, 2^n)` com *jitter* de ±20%;
  7. *keepalive* configurável.
- `ferramentas/prototipo-ws/LEIA.md`: como rodar, resultados e o que isso define para a nova base.
- `docs/desenvolvimento/servidor-de-dev.md` §2: o WinHTTP não confere revogação por padrão (e a RTL não liga); o `curl` do Windows confere e falha com o mkcert (`--ssl-no-revoke`, nunca `-k`).
- Doc 07 (D9, §2, §3.2, §10) e `TODO.md` 1.12: *ping* periódico substituído pelo *keepalive* do WinHTTP no *handle* do WebSocket.

## Como foi verificado
Servidor de desenvolvimento local (`https://localhost`), usuário A = `teste.android.a` no protótipo. O usuário B (`teste.android.b`) mandou mensagens por REST, com um *script* no *scratchpad* que não registra token nem conteúdo.

| Momento | Resultado |
|---|---|
| Conexão | `HTTP 101` em 25 ms; mkcert validado pelo repositório do usuário |
| 1ª mensagem do B | WS 2 (104 bytes) na hora |
| Depois de 280 s sem eventos | WS 2 na hora |
| `docker restart api` | `Receive` voltou com 12030 (`ERROR_WINHTTP_CONNECTION_ERROR`) em ~1,2 s; 1ª reconexão: 502 do nginx; 2ª (2,1 s depois): conectou |
| Mensagem depois da reconexão | WS 2 na hora |
| Depois de 325 s sem eventos | WS 2 na hora |
| *Keepalive* | `WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL` recusado na sessão e no pedido (12018); aceito no *handle* do WebSocket (15000 ms) |

- **Valores do `winhttp.h` declarados à mão** (a RTL não tem; não há SDK do Windows nesta máquina): 114, 116, tipos de *buffer* 0–4 e `WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY` = 4. Ficaram confirmados pelo comportamento.
- **Recepção bloqueante:** um `Stop-Job` não interrompe a recepção bloqueada dentro do WinHTTP; o job só terminou quando chegou um evento.
- **Efeito no ambiente:** o `docker restart api` derrubou a API de desenvolvimento por ~2 s. O servidor de desenvolvimento é local e descartável, e a API voltou sozinha (401 sem token).

## Decisões
- **Sem *ping* de aplicação:**
  - a conexão fica viva com o *keepalive* do WinHTTP (30 s), configurado **depois** do *upgrade*, no *handle* do WebSocket;
  - a conexão morta aparece como erro no `Receive`;
  - ao voltar da suspensão e quando a rede muda, reconectar na hora.
- **Encerrar a thread do socket** fechando o *handle* do WebSocket a partir de outra thread, nunca matando a thread.
- **502/503 do nginx** no *handshake* é erro temporário (*backoff*).
- O protótipo fica versionado como ferramenta de diagnóstico (roda em qualquer Windows 10/11 sem instalar nada).

## Pendências / próximos passos
- Implementar `TTempoRealWinHttp` em Delphi na Etapa 1.12 com estas decisões; o teste no app depende do build pelo responsável.
- Pedido S21 ao servidor (opções explícitas de *keepalive*) continua valendo (0.9).
