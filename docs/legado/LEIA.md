# Legado do cliente Windows (app de abril de 2026)

> ⚠️ **Tudo nesta pasta está desatualizado.** Descreve o app FMX escrito para o servidor Delphi, que parou em 2026-04-26. **Não use como referência do contrato nem do comportamento.** A fonte da verdade é `docs/auditoria-2026-10/` (contrato: doc 01; comportamento: doc 03 e o `conversa-web`).

## Onde está o código do app atual

| O quê | Onde |
|---|---|
| Último estado do app atual (com as alterações que estavam *staged* desde 2026-06-27) | branch `legado/abril-2026` e tag anotada `legado-v1-final` → commit `9678749` |
| O mesmo código, para consulta durante o transplante | pasta `legado/` da branch `nova-base` (fora do build; Etapa 1.1 do `TODO.md`) |
| Commit exclusivo da branch `alteracao-base` ("Adiciona fontes e IFDEF") | tag `legado/alteracao-base` → `a8dcfe8` |
| *Stashes* (27) | tags `legado/stash-00` … `legado/stash-26` (sem perda) e patches de texto em `stashes/NN.patch` |
| Auditoria do app atual (103 problemas) | `docs/auditoria-2026-10/04-auditoria-fmx.md` |

> As branches e tags acima foram criadas **só nesta máquina** em 2026-10-09. O envio para o GitHub (`git push`) é feito pelo responsável (Etapa 0.3 do `TODO.md`).

## Documentos antigos (movidos em 2026-10-09)

| Arquivo | Origem | Assunto |
|---|---|---|
| `ALTERACOES_TCP_RECONEXAO.md` | `docs/` | Reconexão TCP do app atual |
| `waveform-spec.md` | `docs/` | Especificação da forma de onda dos áudios |
| `refatoracao_notificacao.md` | `src/notificacao/` | Refatoração das notificações |
| `whep-viewer-spec.md` | `conversa-webrtc/` | Visualizador WHEP da bancada de testes |
| `revisao-docs-2026-06.md` | `docs/todo.md` (não versionado até 2026-10-09) | Revisão dos dois primeiros documentos contra o código, feita em 2026-06-27 |

## Mapa dos *stashes*

Cada *stash* tem uma tag (`legado/stash-NN`, que guarda tudo, inclusive binários) e um patch de texto em `stashes/NN.patch`.

- **Patches:** gerados com `git diff stash@{N}^1 stash@{N}`, sem binários (`*.dll`, `*.exe`, `*.dcu`, `*.res`, imagens etc.). Só dois binários ficaram de fora: `bin/sk4d.dll` (*stash* 07) e `Conversa_Icon.ico` (*stash* 08). Nenhum *stash* tinha arquivos não rastreados.
- **Conferência:** os patches foram conferidos em 2026-10-09 e não têm senhas, tokens nem chaves:
  - o `apiKey=` do *stash* 20 é um campo vazio do Android no `.dproj`;
  - o `bin/log.txt` do *stash* 12 está vazio;
  - os `bin/teste.txt` são logs de métricas de janela;
  - os *stashes* 11 e 12 têm só o marcador de pasta do Syncthing (`bin/.stfolder/`).
- **Para aplicar um *stash*:** `git stash apply legado/stash-NN` (pela tag) ou `git apply docs/legado/stashes/NN.patch`, numa branch própria a partir do commit-base da tabela.

| NN | Data | Branch | Commit-base | Nome do *stash* | Arquivos | Principais pastas | Patch |
|---|---|---|---|---|---|---|---|
| 00 | 2026-01-11 14:31 | `chamada` | `bfd9d9a` | 20260111_1431 | 6 | lib/ (3), src/ (1), Conversa.Tela.Inicial.view.pas (1) | 12 KB |
| 01 | 2026-01-11 11:14 | `chamada` | `bfd9d9a` | 20250111_1115 | 14 | src/ (11), docs/ (1), Conversa.dproj (1) | 54 KB |
| 02 | 2025-10-20 01:32 | `chamada` | `e73f85c` | 20251020_0132 | 5 | src/ (3), Conversa.dproj (1), Conversa.dpr (1) | 15 KB |
| 03 | 2025-08-03 13:43 | `main` | `2f49a51` | 20250803_1343 | 13 | src/ (10), Conversa.dproj (1), Conversa.dpr (1) | 101 KB |
| 04 | 2025-05-07 21:54 | `main` | `b639fab` | 20250507_2154 | 20 | api/ (11), src/ (4), Conversa.dproj (1) | 470 KB |
| 05 | 2025-05-07 21:02 | `main` | `b639fab` | 20250507 | 20 | api/ (11), src/ (4), Conversa.dproj (1) | 462 KB |
| 06 | 2024-11-07 20:17 | `alteracao-base` | `a8dcfe8` | 20241107_2017 | 11 | src/ (5), lib/ (1), Conversa.dproj (1) | 15 KB |
| 07 | 2024-11-05 19:37 | `main` | `f1ae5dd` | 20241105_1937 | 44 | src/ (25), lib/ (5), xml/ (1) | 923 KB |
| 08 | 2024-09-19 10:09 | `main` | `d638318` | Pull autostash 19/09/2024 10:09:47 | 7 | src/ (3), Conversa_Icon.ico (1), Conversa.dproj (1) | 512 KB |
| 09 | 2024-08-30 19:10 | `main` | `7327be8` | 20240830_1910 | 4 | src/ (3), Conversa.dproj (1) | 24 KB |
| 10 | 2024-08-29 21:40 | `main` | `4a9bdfc` | Pull autostash 29/08/2024 21:40:03 | 5 | src/ (4), Conversa.Tela.Inicial.view.fmx (1) | 111 KB |
| 11 | 2024-08-28 22:09 | `main` | `0ab37c9` | 20240828_220908 | 3 | src/ (1), bin/ (1), Conversa.Dados.pas (1) | 4 KB |
| 12 | 2024-08-28 22:06 | `main` | `f99a793` | 20240828_2206 | 4 | bin/ (2), src/ (1), Conversa.Dados.pas (1) | 4 KB |
| 13 | 2024-07-29 19:59 | `main` | `0d34d54` | Pull autostash 29/07/2024 19:59:28 | 10 | src/ (5), Conversa.Tela.Inicial.view.pas (1), Conversa.Memoria.pas (1) | 35 KB |
| 14 | 2024-07-27 13:37 | `main` | `428d04e` | 20240727_1336 | 25 | src/ (11), bin/ (7), lib/ (2) | 369 KB |
| 15 | 2024-07-26 20:48 | `main` | `cc902a4` | 20240726_2048 | 12 | bin/ (7), lib/ (1), Conversa.dproj (1) | 276 KB |
| 16 | 2024-07-23 19:19 | `main` | `4d443ea` | 20240723_1919 | 10 | bin/ (7), Conversa.dproj (1), Conversa.Tela.Inicial.view.pas (1) | 272 KB |
| 17 | 2024-07-17 19:44 | `main` | `3a0d062` | Pull autostash 17/07/2024 19:44:16 | 4 | bin/ (1), Conversa.dproj (1), Conversa.Memoria.pas (1) | 27 KB |
| 18 | 2024-07-13 17:52 | `main` | `8b557ce` | Pull autostash 13/07/2024 17:52:39 | 8 | src/ (4), bin/ (1), Conversa.dproj (1) | 49 KB |
| 19 | 2024-07-13 16:10 | `main` | `8b557ce` | 20240713_1610 | 12 | bin/ (7), src/ (3), Conversa.Tela.Inicial.view.pas (1) | 240 KB |
| 20 | 2024-07-13 16:09 | `main` | `26fcf4a` | Pull autostash 13/07/2024 16:09:23 | 7 | src/ (3), bin/ (1), Conversa.dproj (1) | 239 KB |
| 21 | 2024-07-02 22:27 | `main` | `a798267` | 20240702_2227 | 26 | src/ (14), bin/ (7), Conversa.dproj (1) | 389 KB |
| 22 | 2024-06-28 20:41 | `main` | `a798267` | 20240628_2041 | 21 | src/ (11), bin/ (5), Conversa.dproj (1) | 140 KB |
| 23 | 2024-06-24 16:24 | `main` | `1317991` | Pull autostash 24/06/2024 16:24:46 | 9 | src/ (4), Conversa.dproj (1), Conversa.dpr (1) | 82 KB |
| 24 | 2024-05-27 20:21 | `main` | `2178dc9` | 20240527_2021 | 31 | src/ (15), Win32/ (4), Conversa.dproj (1) | 306 KB |
| 25 | 2024-05-23 22:44 | `main` | `87fca42` | Pull autostash 23/05/2024 22:44:18 | 8 | Conversa.dproj (1), Conversa.dpr (1), Conversa.Principal.vlb (1) | 68 KB |
| 26 | 2024-05-19 15:31 | `main` | `fa815d8` | 20240519_1531 | 19 | src/ (8), Conversa.dproj (1), Conversa.dpr (1) | 125 KB |

> O *stash* 01 se chama `20250111_1115`, mas é de 2026-01-11 (provável erro de digitação no nome). Nos maiores patches (04, 05, 07, 08), quase todo o volume vem de um ou dois `.fmx` reescritos inteiros (`Conversa.Tela.Inicial.view.fmx`, `src/chat/Conversa.Chat.Listagem.fmx`) e de `.dproj`/`.deployproj`.
