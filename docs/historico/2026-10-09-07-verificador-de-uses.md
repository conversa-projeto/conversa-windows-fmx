# 2026-10-09 · 07 · Verificador estático das units (`ferramentas/verificar-uses`)

- **Fluxo:** Qualidade, segurança e publicação (cita "Repositório e build")
- **Tipo:** ferramenta
- **Itens:** ADR 0001 (decisão de build); `CLAUDE.md` (regra de revisão sem compilar); FC-950
- **Branch:** `chamada`
- **Commits:** `9b796ef` (1ª versão); correção (`.Pas` maiúsculo, `TX` × `TX<T>`) — (preencher)

## Contexto
Sem compilação por linha de comando e sem o `DelphiLSP` fora do IDE, o código da nova base vai ser escrito sem compilar. O responsável pediu "sempre revise bem, uses, etc...". O verificador cobre os erros que mais aparecem num build sem teste prévio:
- `uses` faltando ou errado;
- `begin`/`end` desbalanceado;
- método declarado e não implementado.

## O que foi feito
- `ferramentas/verificar-uses/verificar.mjs` (Node 18+, sem dependências):
  - **índice** de ~128 mil identificadores de nível de unit da seção `interface` da RTL, FMX, FireDAC (dados), DUnitX, Skia, XML e *internet* instalados (`Studio\23.0\source`), mais os nomes de membros das classes e a lista de units compiladas (`lib\win64`);
  - **por unit:** confere `uses`, identificadores sem a unit, estrutura de blocos, métodos/rotinas declarados × implementados e formulários × `.fmx`;
  - avalia a compilação condicional como num build Win64 Debug;
  - aceita `// verificar-uses: ignorar X` para falso positivo.
- `ferramentas/verificar-uses/LEIA.md`: uso, o que confere, limites e a calibração.

## Como foi verificado
- **Calibração contra o código do app atual**, que compila no IDE (153 arquivos: `src`, `lib`, `conversa-webrtc` e as units da raiz):
  - a 1ª versão apontou 1.963 erros, todos analisados;
  - cada falso positivo virou uma regra: parâmetro `const` tratado como seção, BOM, `SCOPEDENUMS`, tipos embutidos, `Self` implícito, `with`, rotina local aninhada, `record` aninhado com métodos, tipo com atributo, compilação condicional, nomes curtos de unit, `TX` × `TX<T>` e a extensão `.Pas` em maiúsculas (o `Conversa.Log.Pas` chegou a ser dado como inexistente).
- **Sobraram 7 erros, todos acertos reais**, em units que não estão no `Conversa.dproj`:
  - `src/chat/Conversa.Conteudo.pas`: 4 units inexistentes;
  - `lib/tcp.pas`: `IPPROTO_IP`/`IP_TOS` sem `Winapi.WinSock`;
  - `src/chamada/Conversa.Audio.Windows.pas`: `ECaptureDeviceException` com o `FMX.Media` comentado.
- **Avisos (76):** nomes curtos de unit e objetos do `.fmx` sem campo publicado.
- **Conferência inversa:** numa unit com 11 erros plantados, todos foram apontados, e o método `abstract` não foi.
- **Desempenho:** o índice leva ~3 s e fica em cache no `%TEMP%`.

## Decisões
- O verificador roda antes de cada commit de código da nova base; ele não substitui a revisão das assinaturas contra o fonte do Delphi nem o build do responsável.
- Na nova base, **não usar `with`** (o verificador não consegue conferir membros dentro dele).

## Pendências / próximos passos
- Achados reais do app atual registrados aqui; não corrigir no legado (congelado).
- Se o build revelar uma classe de erro que o verificador deixou passar, acrescentar a regra e registrar.
