# 2026-10-09 · 01 · TODO literal por etapas

- **Fluxo:** Planejamento e documentação
- **Tipo:** documentação
- **Itens:** `TODO.md` (raiz); FC-001…FC-955 (doc 06)
- **Branch:** `chamada`
- **Commits:** `6d53c23` (junto com a auditoria)

## Contexto
Continuação da auditoria de 2026-10-08: o passo a passo do trabalho, no mesmo formato do `TODO.md` do Android (cada linha uma ação pequena, linhas **Teste:** por seção, ⛔ para bloqueios, ✔ hash ao concluir).

## O que foi feito
- `TODO.md` com **539 passos** (809 linhas):
  - **Etapa 0** — decisões do responsável, preservação (commit do *staged*, branch `legado/abril-2026`, tag `legado-v1-final`, 27 *stashes* em tags e patches, tag da `alteracao-base`), publicação, build, `.gitignore`, documentação, protótipos de tempo real (WebSocket do WinHTTP) e de mídia (WebView2), pedidos ao servidor e ao web, limpeza do histórico;
  - **Etapas 1–9** — fundação, sessão e conversas, mensagens, anexos, notificações e Windows, chamadas, ações sobre mensagens, atividades/pesquisa/perfil/configurações, extras e distribuição;
  - **Qualidade**, **Opcional — remendos no app atual** e **Revisão periódica**.
- 41 linhas **Teste:**; 14 itens já marcados com ⛔ (push e decisões do responsável, compilar, mudanças em outros repositórios, testes que dependem de FCM).
- Cada seção aponta o FC, o problema (#n), a quebra (Qn), o ID do web ou WIN-nn e, quando há transplante, o arquivo de origem em `legado/`.

## Como foi verificado
- Contagem por *script* (`grep`): 539 itens, 41 testes, 14 bloqueios.
- Conferência cruzada com o doc 06 (cada FC tem a sua seção) e com o doc 07 (fases F0–F8).

## Decisões
- A ordem das etapas segue a do Android (anexos antes de notificações; chamadas antes das ações sobre mensagens); a Etapa 5 é "Notificações e integração com o Windows" (sem FCM no desktop).
- Os remendos no app atual ficam no fim, opcionais, como no Android.

## Pendências / próximos passos
- Etapa 0 depende das decisões do responsável (0.1) e de conseguir compilar (0.4).
