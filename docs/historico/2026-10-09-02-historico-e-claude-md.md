# 2026-10-09 · 02 · Criação do histórico de alterações e do CLAUDE.md

- **Fluxo:** Planejamento e documentação
- **Tipo:** documentação / decisão de processo
- **Itens:** FC-007
- **Branch:** `chamada` (não commitado)
- **Commits:** — (a commitar na Etapa 0.6)

## Contexto
Mesmo processo do Android: toda alteração no repositório passa a ter um registro no histórico, e quem trabalha no repositório (pessoas ou agentes de IA) segue um `CLAUDE.md` com as regras e o mapa da documentação.

## O que foi feito
- `docs/historico/indice.md`: índice por fluxo (planejamento; sincronização com servidor e web; repositório e build; uma seção por etapa do `TODO.md`; qualidade; app legado).
- `docs/historico/_modelo.md`: modelo do registro (fluxo, tipo, itens, branch, commits, contexto, o que foi feito, verificação, decisões, pendências).
- Registros 2026-10-08-01 (auditoria), 2026-10-09-01 (TODO) e este.
- `CLAUDE.md` na raiz: o projeto e a situação; onde está cada coisa; **regra obrigatória do histórico**; como trabalhar com o `TODO.md`; Git (commits só do assunto; push e operações destrutivas só com autorização); build (Delphi 12.1 Community sem linha de comando; Win64; dependências); convenções (pt-BR, contrato, segurança, threads, textos, cores, testes, datas).

## Como foi verificado
- Links do índice conferidos com os arquivos existentes.

## Decisões
- Regras do Android mantidas e adaptadas ao Delphi: proibido `FreeAndNil(Self)`; nenhuma E/S na thread da interface; validar identificadores do servidor antes de usá-los como caminho; vídeo e tela só por ação explícita; datas em pt-BR fixo.

## Pendências / próximos passos
- Commitar junto com a auditoria (Etapa 0.6).
