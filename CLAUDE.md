# CLAUDE.md — conversa-windows-fmx

Instruções para quem trabalha neste repositório, pessoas ou agentes de IA. Leia antes de qualquer alteração.

## O projeto

- Cliente **Windows (Delphi 12 / FireMonkey)** do Conversa. Os repositórios irmãos:
  - `../conversa`: servidor Bun + Elysia + Postgres + MinIO + MediaMTX + coturn;
  - `../conversa-web`: cliente web Vue, que é a **referência de comportamento**;
  - `../conversa-android-kotlin`: o app Android (nova base em Kotlin). **As cores do Android vêm deste app** (`docs/design/cores.md`).
- **Situação (2026-10-09):** o app atual foi escrito para o servidor Delphi (parou em abril de 2026). A auditoria de outubro decidiu **recomeçar o núcleo numa nova base Delphi FMX Win64 e transplantar a interface** (`docs/adr/0001-nova-base.md`, **aceito** em 2026-10-09). O trabalho segue o `TODO.md`, na branch `nova-base`; o app atual fica em `legado/` e na branch `legado/abril-2026`.
- **Trabalho autônomo sem compilar:** o responsável pediu que o trabalho siga sozinho, como no Android, e ele compila no IDE depois ("build geral"). Como esta máquina não compila por linha de comando (ver Build), **todo código novo passa por revisão antes do commit**:
  - cada identificador da RTL/FMX conferido no fonte do Delphi (`C:\Program Files (x86)\Embarcadero\Studio\23.0\source`), com a unit que o declara;
  - `uses` conferidos por `node ferramentas/verificar-uses/verificar.mjs` (sem nada faltando, sem unit inexistente);
  - estrutura conferida (cada `begin`/`try`/`case`/`record`/`class` fechado; `interface`/`implementation` coerentes com as declarações).
  - Erros que o build revelar são corrigidos com registro no histórico (fluxo "Repositório e build").

## Onde está cada coisa

| O quê | Onde |
|---|---|
| Visão geral, decisão e índice da auditoria | `docs/auditoria-2026-10/00-LEIAME.md` |
| **Contrato do servidor (fonte da verdade)**: rotas, WebSocket, push, anexos, chamadas, pegadinhas (inclusive as de cliente desktop sempre conectado) | `docs/auditoria-2026-10/01-contrato-servidor-atual.md` |
| O que mudou no servidor e as quebras do FMX (Q1–Q14) | `docs/auditoria-2026-10/02-mudancas-servidor-desde-abril.md` |
| Funcionalidades do web (IDs AUT/CON/MSG/ENV/ANX/PES/CHA/SIP/NOT/PRE/ATV/CFG/GER) e comportamentos de desktop (§7) | `docs/auditoria-2026-10/03-inventario-web.md` |
| Problemas do app atual (#1–#103) | `docs/auditoria-2026-10/04-auditoria-fmx.md` |
| Paridade web × Windows e requisitos de desktop (WIN-01–WIN-33) | `docs/auditoria-2026-10/05-matriz-paridade.md` |
| Fila de correções (FC-xxx) | `docs/auditoria-2026-10/06-fila-de-correcoes.md` |
| Arquitetura da nova base | `docs/auditoria-2026-10/07-plano-nova-base.md` |
| Pendências do servidor (S1–S24) e achados no web (W1–W4) | `docs/auditoria-2026-10/08-pendencias-servidor.md` |
| Relatórios de varredura com todas as evidências | `docs/auditoria-2026-10/apoio/` |
| **Passo a passo do trabalho** | `TODO.md` |
| **Histórico de alterações** | `docs/historico/indice.md` + `docs/historico/*.md` |
| Decisões de arquitetura | `docs/adr/NNNN-*.md` |
| Cores (este app é a fonte) | `docs/design/cores.md` |
| Rodar contra o servidor de desenvolvimento, certificado, contas de teste, build | `docs/desenvolvimento/servidor-de-dev.md` |
| Contrato publicado pelo servidor (OpenAPI) | `docs/contrato/openapi.json` |
| Documentação antiga e *stashes* do app atual (não usar como referência) | `docs/legado/` (`LEIA.md` tem o mapa) |

## Regra obrigatória: histórico de alterações

**Toda alteração** gera um registro em `docs/historico/`, **no mesmo commit da alteração**. Vale para código, documentação, configuração, build, dependências e decisões.

1. **Arquivo de detalhe:** `docs/historico/AAAA-MM-DD-NN-assunto-curto.md`.
   - `NN` é a sequência do dia (01, 02, …); o assunto vai em kebab-case, sem acentos.
   - Use o modelo `docs/historico/_modelo.md`: fluxo, tipo, itens (FC/TODO/IDs/#n), branch, commits, contexto, o que foi feito (com arquivos), como foi verificado, decisões e pendências.
2. **Índice:** acrescente **uma linha** em `docs/historico/indice.md`, **na seção do fluxo** correspondente, em ordem cronológica (mais recente embaixo). Formato:
   `- AAAA-MM-DD · [Título](AAAA-MM-DD-NN-assunto.md) — resumo de uma linha`
   - Se a alteração toca mais de um fluxo, registre no fluxo principal e cite os outros no detalhe.
   - Se surgir um fluxo novo, crie a seção no índice.
3. **Commit:** depois de commitar, preencha o hash no campo **Commits** do detalhe (pode ir no commit seguinte).
4. **Mudou o servidor ou o web?** Registre no fluxo "Sincronização com servidor e web" e atualize os docs afetados (01, 02, 03, 05, 06, 08, `TODO.md`), marcando o que mudou com 🆕 e o commit de origem.

## Como trabalhar com o `TODO.md`

- Siga a ordem das etapas. Cada linha é uma ação pequena; ao concluir, marque `[x]` e anote o commit (`✔ abc1234`) **assim que terminar o item** (não só no fim da seção).
- Só passe de seção depois de marcar as linhas **Teste:**.
- Ao fazer algo que não está no TODO, inclua a linha no lugar certo (e registre no histórico).
- Itens bloqueados: deixe `[ ]` e acrescente `⛔ motivo` na mesma linha.
- Toda semana: atualize a matriz de paridade (doc 05) e confira se o servidor/web mudaram:
  - `git -C ../conversa fetch && git -C ../conversa log HEAD..origin/main --oneline`
  - o mesmo para `../conversa-web`.

## Git

- **Não** misture alterações: commite só os arquivos do assunto (`git commit -- <arquivos>` quando houver outras alterações preparadas).
- **Push** e operações destrutivas (apagar branch, `stash drop`, reescrever histórico, apagar arquivos locais não versionados) **só com autorização** do responsável.
- Mensagens no imperativo/descritivas em português ("Corrige …", "Adiciona …"); prefixos `feat:`, `fix:`, `chore:`, `docs:` aceitos.

## Build

- **Delphi 12.1 Athens** (`C:\Program Files (x86)\Embarcadero\Studio\23.0`). A edição instalada é **Community**: **não compila por linha de comando** (o MSBuild responde "This version of the product does not support command line compiling" e **sai com código 0**). Com uma edição que permita:
  `cmd /c "call ""C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"" && msbuild Conversa.dproj /t:Build /p:Config=Debug /p:Platform=Win64"`
  — e conferir o exe e o log, nunca só o código de saída.
- **Alvo: Win64.** O app atual tem Win32 como padrão e DLLs de mídia x64 com *import* estático: em Win32 o exe não abre. Dependências em tempo de execução e como montar a `bin/`: `docs/desenvolvimento/servidor-de-dev.md` §5.
- O *PreBuild* do `.dproj` atual mata qualquer `Conversa.exe` aberto na máquina.
- Antes de builds longos, conferir o espaço livre do C:.

## Convenções

- **Idioma:** português do Brasil em código de domínio, textos de UI, commits e documentação, como nos repositórios irmãos.
- **Contrato:** nunca deduza formatos do código legado. Consulte o doc 01 e, em caso de dúvida, o código do servidor (`../conversa/src`) e o cliente web (`../conversa-web/src`).
- **Segurança:**
  - nunca desligar a validação de certificado (no desenvolvimento, instalar a CA do mkcert no repositório do usuário);
  - nunca registrar em log token, senha ou conteúdo de mensagem;
  - nunca guardar a senha do usuário em texto ou com cifra reversível (sessão com DPAPI; ver ADR 0001);
  - validar todo identificador vindo do servidor antes de usá-lo como caminho de arquivo;
  - vídeo e tela **nunca** são enviados sem ação explícita do usuário.
- **Threads:** nenhuma E/S de rede ou disco pesada na thread da interface; resultados voltam pelo barramento (`TThread.Queue`/`ForceQueue`); nenhum objeto se libera dentro do próprio evento (`FreeAndNil(Self)` é proibido).
- **Textos de UI:** centralizados (`resourcestring`); quando existir no web, use o mesmo texto (doc 03 §6), acentuado.
- **Cores:** só as de `docs/design/cores.md`, por tokens; nada de cor solta em `.fmx`/`.pas` na nova base.
- **Testes:** parsers, mapeadores, regras de domínio e a máquina de estados de chamada sempre com teste DUnitX.
- **Datas:** o servidor manda ISO-8601 UTC com `Z`; converter para o fuso local só na tela; formatos pt-BR fixos (`TFormatSettings`), não os da localidade do Windows.
