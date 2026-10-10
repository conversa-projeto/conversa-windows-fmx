# Relatórios de apoio da auditoria (2026-10-08)

Varredura feita em 8 frentes, cada uma com leitura integral da sua parte do código do `conversa-windows-fmx` e conferência no servidor (`conversa` `779c8ed`) e no web (`conversa-web` `e8d82cb`). Os documentos `00`–`08` desta auditoria consolidam estes relatórios; aqui ficam as evidências completas (`arquivo:linha` dos dois lados), as tabelas detalhadas e os pontos "não confirmados".

| Arquivo | Frente | Linhas |
|---|---|---|
| [`A1-repositorio-build.md`](A1-repositorio-build.md) | repositório, build, dependências e métricas | 557 |
| [`A2-rest-anexos.md`](A2-rest-anexos.md) | REST e anexos: o contrato que o FMX usa × o servidor atual | 214 |
| [`A3-websocket-sessao-notificacoes.md`](A3-websocket-sessao-notificacoes.md) | WebSocket, sessão, eventos, presença, notificações e ciclo de vida | 855 |
| [`A4-chamadas-midia.md`](A4-chamadas-midia.md) | chamadas e mídia (WHIP/WHEP, Pion, FFmpeg) | 671 |
| [`A5a-funcionalidades-gerais.md`](A5a-funcionalidades-gerais.md) | funcionalidades AUT, CON, PES, SIP, NOT, PRE, ATV, CFG, GER e requisitos de desktop (WIN-xx) | 346 |
| [`A5b-funcionalidades-mensagens.md`](A5b-funcionalidades-mensagens.md) | funcionalidades MSG, ENV e ANX | 626 |
| [`A6-qualidade-seguranca.md`](A6-qualidade-seguranca.md) | arquitetura, qualidade, segurança e "evoluir ou recomeçar" | 734 |
| [`A7-validacao-servidor-web.md`](A7-validacao-servidor-web.md) | validação dos docs 01 e 03 e comportamentos de desktop do web | 762 |

**Como usar:** para entender um problema do doc 04, procure o número provisório indicado na coluna "Origem" (ex.: `A3-02`) no relatório correspondente. Nenhum código foi alterado durante a varredura.
