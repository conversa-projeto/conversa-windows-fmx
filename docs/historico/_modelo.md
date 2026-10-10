# AAAA-MM-DD · NN · Título curto da alteração

- **Fluxo:** (um dos fluxos do `indice.md`)
- **Tipo:** código | documentação | configuração | build | decisão | correção
- **Itens:** FC-xxx / seções do `TODO.md` / IDs de funcionalidade (ex.: MSG-07, WIN-03) / problemas (#n)
- **Branch:** (ex.: `chamada`, `nova-base`)
- **Commits:** `abc1234` (preencher depois do commit, se for o caso)

## Contexto
Por que a alteração foi feita (pedido, bug, mudança no servidor/web…).

## O que foi feito
- Lista objetiva do que mudou, com arquivos (`caminho/Unidade.pas`).

## Como foi verificado
- Build (`msbuild … /p:Platform=Win64`), testes DUnitX, teste manual (contra o servidor de desenvolvimento, com o outro lado no web), prints.

## Decisões
- Escolhas feitas e o motivo (se for estrutural, criar também um ADR em `docs/adr/`).

## Pendências / próximos passos
- O que ficou para depois.
