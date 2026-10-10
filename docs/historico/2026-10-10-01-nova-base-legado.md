# 2026-10-10 · 01 · Branch `nova-base` e o app atual em `legado/`

- **Fluxo:** Fundação (etapa 1)
- **Tipo:** repositório
- **Itens:** `TODO.md` 1.1 (dois primeiros passos); FC-100; D2 (doc 07)
- **Branch:** `nova-base` (criada a partir da `chamada` em `320d524`)
- **Commits:** — (preencher)

## Contexto
Primeiro passo da Etapa 1: a nova base nasce no mesmo repositório, e o código atual fica em `legado/`, fora do build, como referência para o transplante da interface (D2). O app atual também está preservado na branch `legado/abril-2026` e na tag `legado-v1-final`.

## O que foi feito
- `git switch -c nova-base` a partir da `chamada` (`320d524`, depois da Etapa 0).
- `git mv` de 261 arquivos versionados para `legado/`:
  - units da raiz (`Conversa.*.pas/.fmx`, `REST.API.pas`, `Teste.Proxy.pas`, `Conversa.Log.Pas`);
  - `Conversa.dpr`/`Conversa.dproj` e `Conversa_Icon.ico`;
  - as pastas `src/`, `lib/`, `conversa-webrtc/`, `bin/`, `res/` e `teste/`.
- Os restos locais ignorados do app atual também foram para `legado/` (só movidos, nada apagado):
  - `Android64/`, `Serializer/`, `__history/`, `__recovery/`, `api/`;
  - `Conversa.dproj.local`, `.dres`, `.identcache`, `.res` e `ConversaResource.rc`.
  - O `bin/` foi inteiro, com o `Conversa.exe`, as DLLs e os dados do app (`bin/Conversa/`).
- `.gitignore`: as regras com barra no meio (`bin/Conversa/` etc.) só valiam na raiz. Viraram `**/bin/Conversa/`, `**/bin/clipboard/`, `**/bin/dcu/`, `**/bin/dcp/`, `**/bin/bin-2/`, `**/bin/Win32/`, `**/bin/Win64/` e `**/bin/**/anexos/`, para continuarem valendo em `legado/bin/`. Sem isso, o `conversa.json` do app atual (que guarda a senha) apareceria como não rastreado.
- `docs/desenvolvimento/servidor-de-dev.md` §5/§5.1: caminhos do app atual em `legado/bin/` e `legado/conversa-webrtc/`.
- Hash `320d524` no registro 2026-10-09-07.

## Como foi verificado
- `git status`: 261 renomeações (R) e nenhum arquivo não rastreado.
- `git check-ignore`:
  - ignorados: `legado/bin/Conversa/conversa.json`, os anexos baixados, `legado/bin/bin-2`, as DLLs, `bin/Win64/...` e `app/Win64/...`;
  - não ignorados: `core/infra/anexos/*.pas` e `testes/fixtures/*.json`.
- Nenhum `Conversa.exe` aberto no momento da movimentação (`tasklist`).

## Decisões
- O app atual em `legado/` mantém a estrutura relativa (o `.dproj` continua apontando para `bin\` dentro de `legado/`), para quem precisar abri-lo no IDE.

## Pendências / próximos passos
- Etapa 1.1 em diante: `app/Conversa.dpr` + `.dproj` (Win64), estrutura de pastas, núcleo.
