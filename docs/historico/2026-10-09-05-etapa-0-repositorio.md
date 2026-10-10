# 2026-10-09 · 05 · Etapa 0 — preservação, `.gitignore` e documentação antiga

- **Fluxo:** Repositório e build
- **Tipo:** configuração / documentação
- **Itens:** `TODO.md` 0.2, 0.4 (parte), 0.5, 0.6; FC-002, FC-004, FC-005, FC-006; #93, #103
- **Branch:** `chamada`
- **Commits:**
  - `9678749` — o *staged* do responsável, num commit próprio (base da preservação);
  - `ccc8138` — o commit da Etapa 0 (este registro).

## Contexto
Primeira etapa do `TODO.md`: guardar tudo o que existia antes de começar a nova base e preparar o repositório. Mesmo processo do Android (registro `2026-10-06-05` daquele repositório).

## O que foi feito
- **0.2 Preservação:**
  - as alterações *staged* desde 2026-06-27 (`Conversa.Dados.pas`: WebSocket em `wss://host/ws/`; `src/chamada/Conversa.Chamada.WebRTC.pas`: só o comentário do cabeçalho) foram commitadas sozinhas em `9678749`;
  - branch local `legado/abril-2026` e tag anotada `legado-v1-final` em `9678749`;
  - os 27 *stashes* em tags `legado/stash-00` … `legado/stash-26` (sem perda) e em patches de texto `docs/legado/stashes/NN.patch` (5,3 MB, sem binários; ficaram de fora só `bin/sk4d.dll` do *stash* 07 e `Conversa_Icon.ico` do *stash* 08);
  - tag `legado/alteracao-base` → `a8dcfe8`, o commit exclusivo da branch `alteracao-base`.
- **0.4 Build (parte):** a edição do Delphi e a decisão de build estão no registro 2026-10-09-04. As versões, a arquitetura e o SHA-256 das 7 DLLs da máquina foram para `docs/desenvolvimento/servidor-de-dev.md` §5.1. A `bin/` do legado não foi montada em Win64, porque o app atual fica congelado.
- **0.5 `.gitignore`:**
  - entraram as saídas de build (`Win32/`, `Win64/`, `Android64/`, `__astcache/`, `bin/Conversa/`, `bin/clipboard/`, `bin/dcu/`, `bin/dcp/`, `bin/Win32/`, `bin/Win64/`, `*.deployproj`, `Serializer/`), `*.dll`, logs, `.claude/`, `.vscode/` e `*.delphilsp.json`;
  - o `anexos` sem barra (que ignoraria a futura `core/infra/anexos/`) virou `bin/**/anexos/`;
  - `*.json` e `*.png` continuam ignorados (o `conversa.json` do legado guarda a senha), com exceções para `docs/`, `testes/fixtures/`, `ui/recursos/`, `app/recursos/` e `ferramentas/`;
  - `conversa-webrtc/.gitignore`: saíram as regras `LOJAS/…`/`MATRIZ/…` copiadas de outro projeto.
- **0.6 Documentação:**
  - movidos com `git mv` para `docs/legado/`: `docs/ALTERACOES_TCP_RECONEXAO.md`, `docs/waveform-spec.md`, `src/notificacao/refatoracao_notificacao.md` e `conversa-webrtc/whep-viewer-spec.md`;
  - `docs/todo.md` (não versionado, revisão de 2026-06-27) → `docs/legado/revisao-docs-2026-06.md`, agora versionado;
  - novo `docs/legado/LEIA.md`: aviso de desatualizado, onde está o código legado, os documentos movidos e o mapa dos 27 *stashes* (data, branch, commit-base, arquivos, tamanho);
  - `README.md` reescrito: o que é o app, "em reescrita", links para os docs, como compilar (Win64, IDE × linha de comando, licença), servidor de desenvolvimento e ecossistema com os quatro repositórios;
  - `CLAUDE.md`: a linha da documentação antiga aponta para `docs/legado/`.

## Como foi verificado
- `git tag -l 'legado/stash-*' | wc -l` → 27; 27 patches; `git diff --cached` vazio depois do commit `9678749`.
- **Patches conferidos** (token, senha, chave, Bearer, chave do Firebase, e-mails, marcadores do Syncthing):
  - o `apiKey=` do *stash* 20 é vazio;
  - o `bin/log.txt` do *stash* 12 está vazio;
  - os *stashes* 11 e 12 têm só o marcador do Syncthing;
  - nenhuma cadeia com cara de token fora dos `.fmx`.
- **`.gitignore`:**
  - `git check-ignore docs/contrato/openapi.json` não acusa nada;
  - caminhos de exemplo conferidos (`testes/fixtures/*.json` e `core/infra/anexos/*.pas` não ignorados; `bin/Conversa/conversa.json`, DLLs e `Win64/` ignorados);
  - `git status` sem as DLLs.
- **Referências aos docs movidos:** só restam no histórico e na auditoria, que descrevem o estado de 2026-10-08.

## Decisões
- Os patches dos *stashes* ficam versionados (5,3 MB), como no Android; as tags guardam o original completo.
- O `bin/sk4d.dll` x86 continua versionado (a regra `*.dll` só afeta arquivos novos); a nova base usa o x64 do `Studio\23.0\bin64`.

## Pendências / próximos passos
- ⛔ Push (0.3), feito pelo responsável: `chamada`, `legado/abril-2026`, `legado-v1-final`, `legado/alteracao-base` e `refs/tags/legado/stash-*`.
- ⛔ 0.10 (apagar branches mortas, `git gc`, fonte proprietário no histórico) continua dependendo de autorização.
- O teste da 0.6 ("um clone limpo, seguindo o README, sabe como compilar") depende da nova base existir (Etapa 1.1) e do build pelo IDE.
