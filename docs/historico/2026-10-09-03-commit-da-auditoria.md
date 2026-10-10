# 2026-10-09 · 03 · Commit da auditoria e correção do estado do `4759ba5`

- **Fluxo:** Planejamento e documentação (cita também "Repositório e build")
- **Tipo:** documentação / repositório
- **Itens:** `TODO.md` 0.6 (commit da auditoria e hashes), 0.2 e 0.3; FC-003; #93
- **Branch:** `chamada`
- **Commits:** `6d53c23` (auditoria), `4a762dc` (hashes), `65b1aa5` (esta correção)

## Contexto
O responsável pediu o commit da documentação da auditoria **antes** da preservação da Etapa 0.2. Pelo `TODO.md`, o commit ficava na 0.6, depois do commit do *staged* e das tags dos *stashes*.

## O que foi feito
- **`6d53c23`** `docs: auditoria de 2026-10 (docs 00–08, apoio, ADRs, cores, contrato), histórico, CLAUDE.md e TODO`: 30 arquivos, +12.154 linhas, só documentação.
  - Commit feito com *pathspec* (`git commit -F … -- <arquivos>`). As alterações *staged* do responsável (`Conversa.Dados.pas`, `src/chamada/Conversa.Chamada.WebRTC.pas`) **não entraram** e continuam preparadas para a 0.2.
  - `docs/contrato/openapi.json` foi adicionado com `git add -f`, porque o `.gitignore` ainda ignora `*.json`. O ajuste é a 0.5 (`!docs/**/*.json`).
  - Ficaram de fora: as DLLs em `bin/` (0.5) e `docs/todo.md` (vai para `docs/legado/` na 0.6).
- **`4a762dc`** `docs: hash da auditoria no histórico e no TODO`: preenche o `6d53c23` nos registros 2026-10-08-01, 2026-10-09-01 e 2026-10-09-02 e marca os dois itens da 0.6.
- **Correção do estado do `4759ba5`:** ao conferir o resultado, o `origin/chamada` já apontava para o `4759ba5`. O reflog registra o envio em 2026-10-08 23:58 (−0400), feito desta máquina pelo responsável. Nenhum agente da auditoria rodou `git push` (conferido nos registros da sessão). A auditoria dizia "só existe nesta máquina" / "não enviado". Os docs consolidados foram corrigidos:
  - `00-LEIAME.md`: resumo e linha 5 de "O que depende de você";
  - `04-auditoria-fmx.md`: resumo, tabela do repositório (§1), métricas e #93;
  - `06-fila-de-correcoes.md`: FC-003;
  - `TODO.md`: 0.3;
  - registro 2026-10-08-01: achados.
- Os relatórios de `apoio/` (A1, A6) **não** foram alterados: registram o estado no momento da varredura.

## Como foi verificado
- *Hash* do `git diff --cached` igual antes e depois dos commits (`e2d51ce…`): o *staged* do responsável não mudou.
- `git status --short` depois dos commits: só o *staged* do responsável, as 5 DLLs e `docs/todo.md`.
- `git rev-list --left-right --count origin/chamada...HEAD` → `0 2` antes desta correção; `git branch -r --contains 4759ba5` → `origin/chamada`; `git reflog show origin/chamada`.
- Busca de segredos nos arquivos commitados (token, e-mail, chave privada, senha das contas de teste): só um token de exemplo truncado no doc 01 (`eyJhbGciOi...`). O doc do servidor de dev aponta onde estão as senhas das contas de teste, sem copiá-las.

## Decisões
- Antecipar o commit dos docs não muda a 0.2: o *staged* continua sendo commitado sozinho, e a branch `legado/abril-2026` sai desse commit.
- Os relatórios de apoio ficam como evidência datada; a correção vai só nos docs consolidados e no histórico.

## Pendências / próximos passos
- Push da `chamada` (agora com os commits da auditoria) ⛔ feito pelo responsável.
- Etapa 0.2 (commit do *staged*, `legado/abril-2026`, tags dos 27 *stashes*) e 0.5 (`.gitignore`, para o `openapi.json` deixar de precisar de `-f`).
