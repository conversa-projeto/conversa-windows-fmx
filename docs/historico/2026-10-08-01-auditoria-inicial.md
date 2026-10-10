# 2026-10-08 · 01 · Auditoria inicial do cliente Windows contra o servidor e o web

- **Fluxo:** Planejamento e documentação
- **Tipo:** documentação (nenhum código alterado)
- **Itens:** `docs/auditoria-2026-10/00` a `08`, `apoio/`; ADR 0001 e 0002 (propostos); FC-001…FC-955; #1–#103; Q1–Q14; S17–S24; WIN-01–WIN-33
- **Branch:** `chamada`
- **Commits:** `6d53c23` (2026-10-09, junto com o `TODO.md`, o histórico e o `CLAUDE.md`)

## Contexto
O cliente FMX parou em 2026-04-26, escrito para o servidor Delphi. Desde então:
- o servidor foi reescrito para Node (13/09) e depois para Bun + Elysia (26/09), com 26 commits até `779c8ed`;
- o web recebeu dezenas de funcionalidades (até `e8d82cb`).

O responsável pediu para o FMX o mesmo processo feito no Android em 2026-10-06 (`conversa-android-kotlin/docs/auditoria-2026-10/`): varredura completa, documentação equivalente e `TODO.md`, "sem mesquinhez, validando todas as diferenças". Premissas aceitas: o cliente continua em **Delphi FMX**; alvo **só Windows**; docs 01 e 03 copiados com data do Android e revalidados.

## O que foi feito
- **Varredura em 8 frentes** (relatórios em `docs/auditoria-2026-10/apoio/`):
  - A1 repositório, build, dependências e métricas;
  - A2 REST e anexos × servidor atual e de abril;
  - A3 WebSocket, sessão, eventos, presença, notificações;
  - A4 chamadas e mídia (Pion, FFmpeg, WHIP/WHEP);
  - A5a/A5b inventário de funcionalidades (todos os 137 IDs) e requisitos de desktop;
  - A6 arquitetura, qualidade, segurança e "evoluir × recomeçar";
  - A7 validação dos docs 01 e 03 contra o código atual e comportamentos de desktop do web.
- **Documentos** em `docs/auditoria-2026-10/`:
  - `00-LEIAME.md` (índice, resumo, decisões pendentes);
  - `01-contrato-servidor-atual.md` (cópia do Android revalidada em `779c8ed`: correções D1–D15, referências de linha atualizadas, trechos do Android reescritos para Windows, pegadinhas 51–54 de cliente desktop sempre conectado);
  - `02-mudancas-servidor-desde-abril.md` (Q1–Q14);
  - `03-inventario-web.md` (cópia do Android revalidada em `e8d82cb`: 82 itens conferidos, correções 🔎, nova §7 de comportamentos de desktop, §13 da revalidação);
  - `04-auditoria-fmx.md` (103 problemas: 16 críticos, 24 altos, 34 médios, 29 baixos; avaliação e recomendação);
  - `05-matriz-paridade.md` (137 funcionalidades: 1 ✅, 40 🟡, 14 🔴, 76 ⬜, 6 ➖; WIN-01–WIN-33);
  - `06-fila-de-correcoes.md` (FC-001…FC-955, blocos A–M);
  - `07-plano-nova-base.md` (D1–D17, estrutura, componentes, mídia, fases, riscos);
  - `08-pendencias-servidor.md` (S1–S16 reavaliadas, S17–S24 novas, W1–W4 no web).
- **ADRs** (status **proposto**): `docs/adr/0001-nova-base.md`, `docs/adr/0002-midia-chamadas.md`.
- `docs/design/cores.md` (paleta do FMX, que é a fonte das cores do Android, com proposta de tokens em Delphi).
- `docs/contrato/openapi.json` (baixado do servidor de desenvolvimento: 70 operações = 69 rotas + `/ws/`).
- `docs/desenvolvimento/servidor-de-dev.md` (servidor de dev, certificado, contas de teste, build, limites).

## Como foi verificado
- Código lido no FMX (árvore de trabalho), no servidor (`779c8ed` e `56e7cc0`) e no web (`e8d82cb`), com `arquivo:linha` dos dois lados.
- GETs sem efeito colateral no servidor de desenvolvimento (`/api/docs/json`; `/ws` → 301; `GET /mensagem/visualizar` e `GET /conversa/dados` → 404).
- **Build:** tentado com `msbuild` (Win64 Debug): o Delphi 12.1 é Community e **não compila por linha de comando** (o MSBuild sai com código 0 sem compilar). Nenhum arquivo versionado mudou (conferido com `git status` e os *hashes* do índice). Por indícios, a árvore atual compilou no IDE em Win32 (2026-06-27) e o HEAD em Win64 (2026-04-26).
- DLLs só lidas (`VersionInfo`, cabeçalho PE, cadeias), nunca executadas. O app não foi executado.
- A CA do mkcert está no repositório de certificados do usuário (`certutil -user -store Root`).
- Numeração conferida por *script*: 103 problemas sem lacuna; 137 IDs na matriz; 137 IDs no doc 03.

## Decisões
- **Recomendação:** recomeçar o núcleo numa nova base Delphi FMX Win64 e transplantar a interface (ADR 0001, proposto).
- **Mídia:** prototipar o WebView2 com o módulo de chamada do web antes de decidir (ADR 0002, proposto).
- Numeração dos FC segue a divisão em blocos do Android, mas os itens são próprios do FMX; S1–S16 compartilhadas com o Android, S17+ novas.
- Os relatórios de varredura foram mantidos no repositório (`apoio/`) como evidência; a consolidação está nos docs 00–08.

## Achados principais
- **Q1–Q14:** anexos quebrados nos dois sentidos; "visualizar" e `conversa/dados` com 404; histórico de chamadas com modelo inexistente; mensagem oculta exibida; tipos 5–8 vazios; `mensagens/novas` com parâmetro errado; WebSocket dependente de OpenSSL ausente e provável queda pelo *ping* vazio; chamadas sem TURN.
- **Críticos internos:** toda chamada transmite a tela inteira sem aviso; WebSocket sem reconexão e sem validação de TLS; sessão de 12 h que vence em silêncio; senha salva com cifra reversível; *use-after-free* na chamada; build não reprodutível (exe x86 × DLLs x64; FFmpeg GPLv3).
- **Servidor:** com o desktop conectado, o push de todos os aparelhos do usuário é suprimido (S2/S18).
- **Origem do contrato do FMX** (doc 02 §1.1): o FMX usa o contrato da árvore antiga do servidor (`rest/conversa.rest.dpr`), substituída em `61b7dbe` (2026-03-01) e apagada em `eb59c61` (2026-03-13); por isso várias quebras já existiam em abril (Q1–Q5, Q8, Q13, Q14 são [ABRIL]). A Q9 é mista: a URL do HEAD já não funcionava em abril, e o `wss` obrigatório é novo.
- **Correção feita na consolidação:** a hipótese de `ERangeError` com os tipos 5–8 no build Debug (relatórios A2/A5b) foi descartada (o `{$R+}` não confere *casts* explícitos para enum); o efeito é só a bolha vazia (doc 04 #22).
- **Repositório:** o commit `4759ba5` (+8.486 linhas) só existe nesta máquina; 27 *stashes*; `main` 23 commits atrás.

## Pendências / próximos passos
- Decisões do responsável (`00-LEIAME.md` §5): ADR 0001, build/licença, senha, desktop × celular, push, protótipo de mídia, *issues* no servidor e no web, histórico com o fonte da Embarcadero.
- ~~Commitar estes documentos na Etapa 0.6 do `TODO.md`~~ Feito em `6d53c23`, a pedido do responsável, **antes** da preservação da 0.2: só os docs entraram no commit; o *staged* (`Conversa.Dados.pas`, `src/chamada/Conversa.Chamada.WebRTC.pas`) continua preparado, à espera da 0.2.
- Copiar S17–S24 para o doc 08 do Android (outro repositório; com autorização).
