> **Relatório de apoio da auditoria de 2026-10-08** — frente: funcionalidades MSG, ENV e ANX.
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A5b — Inventário de funcionalidades de mensagens no conversa-windows-fmx (MSG, ENV, ANX)

**Alvo:** `conversa-windows-fmx`, branch `chamada`, HEAD `4759ba5` (2026-04-26) + alterações *staged* (só `Conversa.Dados.pas`, URL do WebSocket, e `Conversa.Chamada.WebRTC.pas`). Auditada a árvore de trabalho.
**Referências:** servidor `conversa` `779c8ed`; web `conversa-web` `e8d82cb`; docs `conversa-android-kotlin/docs/auditoria-2026-10/` (01 contrato, 03 inventário web, 05 modelo de matriz).
**Data:** 2026-10-08. **Modo:** somente leitura.

**Convenções:**
- Caminhos sem prefixo são relativos a `conversa-windows-fmx/`.
- `conversa/…` é o servidor e `conversa-web/…` é o web.
- "doc 01/03" são os documentos da auditoria do Android.
- Linhas citadas conferidas na árvore de trabalho.

---

## 0. Resumo executivo

1. **Nada do grupo está ✅.** Dos 58 IDs: 18 🟡, 6 🔴, 32 ⬜ e 2 ➖. O chat do FMX é o do servidor Delphi de 2024: texto, imagem, arquivo e "mensagem de áudio". Não há resposta, encaminhamento, reações, menções, código, votação, figurinha, agendamento, ocultar nem digitando.
2. **Anexos quebram por inteiro contra o servidor atual:**
   - o upload ainda manda os bytes em `PUT /anexo` (agora é JSON + URL assinada);
   - o download grava o JSON `{"url": …}` como se fosse o arquivo.
   - **Efeitos:**
     - quem recebe vê mensagens de imagem vazias;
     - uma imagem recebida **derruba a renderização do lote** (exceção em `TBitmap.LoadFromFile`);
     - o JSON fica preso no cache para sempre.
3. **Mensagem oculta mostra o conteúdo original.** `excluida_em` não é lido (P0 de privacidade, igual ao Android).
4. **Visualizar usa `GET` → 404.** O servidor nunca registra a leitura e o remetente nunca vê ✓✓ azul.
5. **Tipos 5, 6, 7 e 8 não existem no modelo:**
   - toda gravação de áudio feita no web (tipo 5) aparece como bolha vazia;
   - o mesmo vale para chamada, figurinha e votação.
6. **Paginação por aritmética de id global** (`menor id − 1`, `maior id + 1`):
   - re-buscar uma mensagem já carregada **duplica os conteúdos no modelo e levanta exceção** ("Mensagem já adicionada!");
   - carregar as anteriores faz a tela **pular para o fim**.
7. **Envio sem otimista e síncrono na thread da interface.** Em erro o texto **não se perde** (fica no campo), mas **nenhum aviso aparece**: o evento `TErroServidor` não tem assinante, e o `EAbort` é silencioso.
8. **Desempenho:** um `TFrame` por mensagem e outro por conteúdo, posicionamento O(n² log n), separadores recriados a cada lote e `SoEmoji` varrendo cerca de 5 000 emojis por texto. Não há virtualização.
9. **Pontos aproveitáveis:**
   - Enter envia e Shift+Enter quebra linha;
   - fila de anexos com várias seleções;
   - colar imagem (`Ctrl+V`);
   - gravação com segurar, travar e cancelar;
   - visualizador de imagem com zoom;
   - botão "ir para o fim";
   - SHA-256 compatível com o web (a deduplicação bate);
   - `GET /mensagens`, `PUT /mensagem` (texto) e `GET /mensagem/status` com os nomes certos;
   - menu próprio (`lib/popupmenu`) que aceita submenu, separador e item-frame;
   - Skia já está no projeto (Lottie possível) e o FFmpeg já é distribuído (decodificar Opus/WebM e vídeo).

---

## 1. Matriz por ID

### Legenda

| Símbolo | Significado no FMX **atual** (contra o servidor `779c8ed`) |
|---|---|
| ✅ | Existe e funciona |
| 🟡 | Parcial ou com defeito relevante |
| 🔴 | Existe, mas **quebra contra o servidor atual** |
| ⬜ | Não existe |
| ➖ | Não se aplica literalmente ao desktop; ver "Adaptação" |

**Fases (as mesmas do doc 05):**

| Fase | Escopo |
|---|---|
| F0 | Fundação |
| F1 | Sessão e conversas |
| F2 | Mensagens: núcleo |
| F3 | Anexos e mídia |
| F4 | Ações sobre mensagens |
| F5 | Notificações |
| F6 | Chamadas |
| F7 | Atividades, pesquisa e configurações |
| F8 | Extras |

**Prioridades:**

| Prio | Significado |
|---|---|
| P0 | Obrigatório para o cliente funcionar contra o servidor atual |
| P1 | Paridade essencial |
| P2 | Paridade completa |
| P3 | Opcional |

### Placar

| Grupo | Total | ✅ | 🟡 | 🔴 | ⬜ | ➖ |
|---|---|---|---|---|---|---|
| MSG | 20 | 0 | 8 | 2 | 9 | 1 |
| ENV | 23 | 0 | 6 | 0 | 17 | 0 |
| ANX | 15 | 0 | 4 | 4 | 6 | 1 |
| **Total** | **58** | **0** | **18** | **6** | **32** | **2** |

### MSG — Exibição e leitura

| ID | Funcionalidade | FMX | Situação / evidência | Adaptação Windows | Fase | Prio |
|---|---|---|---|---|---|---|
| MSG-01 | Carregamento e paginação bidirecional | 🟡 | **Abertura:** `GET /mensagens?conversa&mensagemreferencia=0&mensagensprevias=50` (`Conversa.Dados.pas:545-546`, constante `:83`). A rota e os nomes dos parâmetros estão certos, e 50 está dentro do limite de 100. **Anteriores:** disparam ao chegar ao topo (`chat.visualizador.pas:112-114` → `Conversa.Chat.pas:371-378`), com `mensagemreferencia = menor id − 1` (`Conversa.Dados.pas:532-542`). **Novas:** `maior id + 1` com `mensagensseguintes=50` (`:547-548`). **Problemas:** os ids são globais e, se o vizinho não existe, o servidor resolve a posição como nula e devolve lista vazia (`conversa/src/mensagens.ts:334`). Não há fim de lista, indicador "Carregando…" nem paginação para baixo. Ao chegar a página anterior, a tela pula para o fim (`Conversa.Chat.pas:392-395`). Re-busca duplica e lança exceção (A5b-01). Ver §2.1 | Igual ao web: referência = id da primeira/última mensagem salva, descartar a repetida, parar quando vier menos que o pedido; prefetch a 1,5× a altura visível preservando a âncora; textos "Carregando mensagens…" | F2 | P0 |
| MSG-02 | Separadores de dia e nome do remetente em grupo | 🟡 | O separador de data existe (`chat.separador.data.pas:48-53`) no formato `dd/mm` (`/yyyy` só com mais de 6 meses, `:51`), sem dia da semana, e é destruído e recriado a cada lote (`chat.visualizador.pas:282-335`). Em grupo o nome aparece em **todas** as bolhas, inclusive nas próprias (`Conversa.Chat.pas:204`), sem agrupar mensagens seguidas do mesmo remetente | "seg., 05/10/2026" (`FormatDateTime` com `FormatSettings` pt-BR); nome só nas recebidas e só quando o remetente muda | F2 | P0 |
| MSG-03 | Linha "Últimas" (não lidas) | ⬜ | O frame existe (`chat.separador.lidas.pas`, texto "Mensagens não lidas" em `chat.separador.lidas.fmx:21`), assim como `ExibirSeparadorLidas`/`OcultarSeparadorLidas` (`chat.visualizador.pas:265-280`), **mas ninguém os chama**. Ao abrir uma conversa, a tela sempre rola ao fim (`Conversa.Chat.Listagem.pas:240`, `tmrUltima`) | Reaproveitar o frame com o texto "Últimas" e as 5 regras do web (doc 03 MSG-03); "janela focada" = `IsFormActive` (`chat.so.pas:33-58`); abrir com a primeira não lida no topo (40 px) | F2 | P1 |
| MSG-04 | Marcar como visualizada | 🔴 | Chama `GET mensagem/visualizar?conversa&mensagem` (`Conversa.Proxy.pas:723-744`, método em `:736`) → **404**; a rota é `POST /mensagem/visualizar {conversa, mensagem}` (doc 01 §4 #26, §10.5). O app marca localmente e desconta o contador (`Conversa.Tipos.pas:845-864`), mas o servidor nunca grava. O gatilho principal é a **pintura** do frame com a janela ativa (`chat.mensagem.pas:265-270`), que conta mensagem só parcialmente visível. No `FormActivate` o critério certo é usado (totalmente visível: `Conversa.Chat.pas:157-166`, `chat.visualizador.pas:408-416`) | `POST` com corpo JSON, em segundo plano; só com `IsFormActive` e mensagem totalmente visível (ou com o fim visível); uma chamada por mensagem; descontar o contador só depois do sucesso | F2 | **P0** |
| MSG-05 | "Ir para o final" / "Há novas mensagens" | 🟡 | O botão `TChatUltima` aparece a mais de 300 px do fim e rola com animação (`chat.ultima.pas:57-73`, limite em `:61`). Não há o aviso "Há novas mensagens". Toda mensagem nova força a rolagem ao fim, mesmo com o usuário lendo o histórico (`Conversa.Chat.pas:243-244`, `:392-395`) | Limite de 1000 px; botão "Há novas mensagens"; rolagem automática só perto do fim | F2 | P1 |
| MSG-06 | Ir para uma mensagem | ⬜ | `Posicionar(ID)` e `Piscar` existem (`chat.visualizador.pas:377-391`, `chat.mensagem.pas:214-219`) sem uso. Não há carga de contexto | Contexto 30/30 (fallback 120/120), substituir a lista, centralizar e destacar por 1,2 s (o `Piscar` serve); erro "Nao foi possivel localizar esta mensagem no contexto da conversa." | F4 | P1 |
| MSG-07 | Classificação das bolhas | 🟡 | **Modelo:** só 4 tipos (`TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo, MensagemAudio)` em `Conversa.Tipos.pas:220`; `TTipo` em `chat.tipos.pas:19`). **Tipos sem bolha:** 5 (gravação: **todo áudio gravado no web**), 6 (chamada), 7 (figurinha) e 8 (votação) viram enum fora da faixa (`Conversa.Dados.pas:596`, `Conversa.Chat.pas:196`) e a bolha sai **vazia**, porque `chat.visualizador.pas:150-222` não tem caso para eles. **Prioridades do web:** não existem (oculta, código, referência, texto curto); "só emoji" apenas aumenta a fonte. Ver §2.3 | Mesma prioridade de `classificarMensagem.ts`; um frame por variante | F2 (mídia F3, ações F4) | P0 |
| MSG-08 | Ícone de status de entrega | 🟡 | Só nas próprias mensagens (`chat.mensagem.pas:136-177`): ✓ cinza (não recebida), ✓✓ cinza (recebida), ✓✓ `#007DFF` (visualizada). Sem estado "enviando" (relógio), porque não há envio otimista | Relógio para id < 0; ✓/✓✓ como hoje; sem ✓ em mensagem de chamada | F2 | P0 |
| MSG-09 | Detalhe do status | ⬜ | — | Popup ao parar o mouse 300 ms sobre o ✓ (o `lib/popupmenu` aceita frame próprio); `GET /mensagem/status/detalhe?id=` devolve **datas**, não booleanos | F4 | P2 |
| MSG-10 | Status em tempo real (WS 3) | 🟡 | **O que funciona:** WS 3 → `GET /mensagem/status?conversa&mensagem=<CSV>` (`Conversa.Dados.pas:479-485`, `Conversa.Proxy.pas:666-708`) → atualiza recebida/visualizada (`Conversa.Dados.pas:395-418`). **O que falta:** `excluida_em` é ignorado (o campo nem existe no registro, `Conversa.Proxy.Tipos.pas:116-122`), então o ocultar feito em outro aparelho não chega; ids desconhecidos são descartados sem recarregar a conversa ativa; `/conversas` não é recarregado | Tratar `excluida_em`; recarregar a conversa ativa quando chegar id desconhecido | F2 | P0 |
| MSG-11 | Links clicáveis | 🟡 | Regex só para `http`, `https` e `ftp` (`chat.conteudo.texto.pas:169`), sem `www.`. A pontuação final `.,;:!` já fica de fora; `)` não é tratado. Abre com `ShellExecute` (`:121`) e mostra cursor de mão (`:129-154`). As faixas coloridas desalinham quando o texto tem `&`, porque o texto exibido troca `&` por `&&` (`:166`) | Regras de `parseLinks` (`conversa-web/src/utils/formatters.ts:164-187`); `www.` ganha `https://` | F2 | P1 |
| MSG-12 | Menções na mensagem | ⬜ | Aparece o texto cru `@[Nome](id)` | `@Nome` destacado (atributo de `TTextLayout`), hover com cartão (foto e nome), clique abre a conversa direta | F4 | P1 |
| MSG-13 | Mensagem de chamada (tipo 6) | ⬜ | Bolha vazia (MSG-07) | Bolha "Chamada de áudio/vídeo [em grupo]" lendo o JSON do doc 01 §9.8 (datas sem fuso); sem menu e sem ✓ | F2 | P0 |
| MSG-14 | Mensagem só de emojis | 🟡 | `TEmojiItem.SoEmoji` (`chat.emoji.pas:5113-5120`) → fonte 30 (`chat.visualizador.pas:156-157`), mas a bolha mantém o fundo. A verificação percorre a tabela inteira (~5 000 itens) a cada texto (`chat.emoji.pas:5071-5111`). Texto vazio conta como "só emoji" | Sem fundo de bolha; detecção por varredura de *code points* (`TCharacter`/regex), sem a tabela | F2 | P2 |
| MSG-15 | Blocos de código / Markdown / Mermaid | ⬜ | Aparecem as crases cruas | Porte de `codeBlocks.ts`. Frame com cabeçalho (linguagem, "Copiar"/"Copiado!"), fonte monoespaçada e recolhido em 240 px ("Expandir código"/"Recolher código"). Destaque por tokenizador simples com atributos de `TTextLayout`. Markdown: render próprio (Skia paragraph) ou `TWebBrowser` (WebView2) isolado. Mermaid: só em WebView2 isolado, senão mostrar o código | F4 | P1 (código/Markdown), P2 (Mermaid) |
| MSG-16 | Mensagem oculta | 🔴 | `excluida_em` não é lido (`Conversa.Proxy.Tipos.pas:99-111`), então o FMX **mostra o conteúdo original**, que o servidor continua mandando (doc 01 §10.9 e §19.18) | Bolha "Mensagem oculta" com clique que revela/oculta (tooltip "Clique para ver o conteúdo"/"Clique para ocultar o conteúdo"); sem menu nem reações; fora do visualizador; citação mostra "Mensagem oculta"; votação oculta mostra o resumo | F2 | **P0** |
| MSG-17 | Agendadas (selo → relógio) | ⬜ | `visivel_em` não é lido nem enviado (`Conversa.Proxy.Tipos.pas:81-86`, `:99-111`). O servidor devolve ao autor as próprias agendadas futuras (doc 01 §10.4). **Autor:** as agendadas criadas no web aparecem no chat do FMX como mensagens comuns, na posição de `inserida`. **Destinatários:** quando amadurecem, elas entram no passado (posição de `inserida`), não no fim | Ordenar por `coalesce(visivel_em, inserida)`; esconder as futuras; relógio com contador ao lado do microfone (campo vazio) e janela "Mensagens agendadas" | F4 | P2 |
| MSG-18 | Modo conexão lenta | ➖ | — | No desktop é opcional: "Clique para carregar" para mídia grande ou rede tarifada (`INetworkListManager`) | — | P3 |
| MSG-19 | Citação de resposta/encaminhada | ⬜ | `mensagem_referencia` não é lida (`Conversa.Proxy.Tipos.pas:99-111`). A resposta aparece só com o texto novo; a encaminhada aparece com os conteúdos copiados, sem "Encaminhado de …" | Frame recursivo até 5 níveis; clique no título → MSG-06; `semCopiasDaReferencia` | F4 | P1 |
| MSG-20 | Bolha de votação (tipo 8) | ⬜ | Bolha vazia. O WS 62 cai fora do enum `TSocketMessageType` (`Conversa.Tipos.pas:17-38`) | Frame com `GET /enquete?id=` (cache por id), votar com a lista completa, WS 62, data final e encerrar; no F2, pelo menos o marcador "📊 Votação" | F4 (marcador F2) | P1 (marcador P0) |

### ENV — Composição e ações

| ID | Funcionalidade | FMX | Situação / evidência | Adaptação Windows | Fase | Prio |
|---|---|---|---|---|---|---|
| ENV-01 | Enviar texto (otimista) | 🟡 | **O que funciona:** Enter envia e Shift+Enter quebra linha (`chat.editor.texto.pas:124-129`); `PUT /mensagem {conversa_id, conteudos[{ordem,tipo,conteudo}]}` usa os nomes certos (`Conversa.Proxy.pas:641-664`, `Conversa.Proxy.Tipos.pas:75-86`); o botão alterna entre microfone e enviar (`chat.editor.pas:140-150`). **O que falta:** o envio é **síncrono na thread da interface** (`Conversa.Chat.Listagem.pas:105-110` → `Conversa.Dados.pas:243-290`) e não há mensagem otimista; o texto não passa por `trim()` (`chat.editor.texto.pas:214-217`); placeholder "Mensagem" (`chat.editor.texto.fmx:160`); o campo cresce até 212 px (`chat.editor.texto.pas:34`). **Em erro:** `ValidarErro` publica `TErroServidor` (sem assinante) e levanta `EAbort` (`Conversa.Proxy.pas:154-167`). O texto continua no campo, porque `Limpar` não roda (`chat.editor.pas:152-174`), mas não aparece aviso nenhum | Otimista (id negativo, relógio), envio em tarefa de fundo, erro visível acima do campo com "Tentar de novo", `trim()`, texto "Digite uma mensagem" | F2 | P0 |
| ENV-02 | Atalhos de emoji (`:)` → 🙂) | ⬜ | — | Porte de `emojiAtalhos.ts` (troca ao digitar espaço ou Enter, nunca dentro de crases). No desktop, com teclado físico, vale mais que no Android | F4 | P2 |
| ENV-03 | Seletor de emoji | 🟡 | O botão abre o **painel de emojis do Windows** (Win+.), simulando as teclas numa janela `EDIT` temporária (`chat.so.pas:60-122`, chamado em `chat.editor.texto.pas:97-100`). Não tem as categorias do web nem os nomes em português. É frágil: depende de foco, de temporização de 100 ms e de a tecla Windows não estar bloqueada | Aceitável usar o painel do sistema. Melhor: popup próprio com as listas do web (a tabela de `chat.emoji.pas` já existe) e inserção no cursor | F4 | P2 |
| ENV-04 | Figurinhas Lottie (tipo 7) | ⬜ | As recebidas aparecem vazias (MSG-07) | Embutir os JSON (pacotes `basico`, `rostos` e `coisas`) como recurso e tocar com `TSkAnimatedImage`/Skottie (§2.13); aba "Figurinhas" no seletor; com o campo vazio, enviar sozinha | F4 | P1 |
| ENV-05 | Menções no campo | ⬜ | — | Popup com até 6 contatos ao digitar `@`; ↑/↓, Enter/Tab, Esc; enviar `@[Nome](id)`. O `TMemo` não colore trechos, então o campo precisa ser próprio (ver ENV-21) | F4 | P1 |
| ENV-06 | Responder | ⬜ | Não há `mensagem_referencia` no `TReqMensagem` (`Conversa.Proxy.Tipos.pas:81-86`) | Barra acima do campo com nome, resumo e ×; enviar `{tipo:1, origem_mensagem_id}` | F4 | P0 |
| ENV-07 | Responder no privado | ⬜ | — | Igual ao web (encaminhada tipo 2 na direta) | F4 | P2 |
| ENV-08 | Encaminhar | ⬜ | Só existe código morto: `TMensagemExtras.EnviarComReferencia` (`src/Conversa.Proxy.Extras.pas:322-354`) manda `referencia {tipo, destino_mensagem_id}`. O servidor ignora campos extras (doc 01 §3), então a referência se perderia. A unit nem está no `.dpr` | Modal "Encaminhar mensagem" com "Buscar destino"; `PUT /mensagem` no destino com os conteúdos reordenados 1..n e `{tipo:2, origem_mensagem_id}`; esconder para votação | F4 | P1 |
| ENV-09 | Colar código / texto longo | ⬜ | — | Vale literalmente: colar mais de 10 linhas abre "Inserir código"; detecção heurística de linguagem; interceptar `Ctrl+V` e `Shift+Insert` | F4 | P2 |
| ENV-10 | Janela "Inserir código" | ⬜ | — | Modal com seletor de linguagem e `TMemo` monoespaçado; Ctrl+Enter envia | F4 | P2 |
| ENV-11 | Colar imagem | 🟡 | `Ctrl+V` com imagem grava um PNG em `<pasta do exe>\clipboard\clipboardN.png` e o põe na fila (`chat.editor.texto.pas:132-156`, caminho em `:140-145`). **Problemas:** grava ao lado do executável (falha em `Program Files`); nunca limpa; o nome por contagem colide quando arquivos são apagados; só `Ctrl+V` (nem `Shift+Insert` nem menu de contexto). O envio depois quebra no upload (ANX-02) | Gravar na pasta temporária ou de cache do app como `print-<timestamp>.png`; aceitar todas as formas de colar | F3 | P1 |
| ENV-12 | Teclado do campo | 🟡 | Enter/Shift+Enter funcionam; o campo recebe foco ao trocar de conversa (`Conversa.Chat.Listagem.pas:235`, `Conversa.Chat.pas:387-390`). Tab = 4 espaços não foi implementado (o comportamento padrão do `TMemo` não foi confirmado). Uma letra digitada fora do campo não leva o foco ao campo | Igual ao web (vale literalmente) | F2 | P2 |
| ENV-13 | Agendar mensagem | ⬜ | — | Botão "Agendar mensagem" e modal Data/Hora (padrão amanhã 08:00) com as validações do web; `visivel_em` em ISO UTC | F4 | P2 |
| ENV-14 | Cancelar agendada | ⬜ | `DELETE /mensagem?id=` existe no proxy (`Conversa.Proxy.pas:710-721`), sem uso | Lista "Mensagens agendadas" pelo relógio, com "Cancelar" e a confirmação do web | F4 | P2 |
| ENV-15 | Digitando | ⬜ | O layout "digitando..." existe no cabeçalho (`Conversa.Chat.fmx:210`), mas fica sempre oculto (`Conversa.Chat.pas:110`). O WS 4 não é tratado (`Conversa.Dados.pas:469-490`). O envio só existe no código morto `TConversaIndicadores.Digitando`, com o campo errado `conversa_id` (o servidor espera `id` → 400; `src/Conversa.Proxy.Extras.pas:358-373`) | `POST /conversa/digitando {id}` com throttle de 2,5 s; WS 4 expirando em 4 s; textos do web no cabeçalho e acima do campo | F2 | P1 |
| ENV-16 | Gravando áudio (indicador) | ⬜ | WS 5 ignorado; `GravandoAudio` também usa `conversa_id` (`src/Conversa.Proxy.Extras.pas:375-390`) | `POST /conversa/gravando {id}` ao começar e a cada 2,5 s; texto em vermelho | F3 | P1 |
| ENV-17 | Reações | ⬜ | `reacoes` não é lido e o WS 7 é ignorado. `Reagir` (`src/Conversa.Proxy.Extras.pas:261-280`) tem o corpo certo, mas é código morto | Linha de reações no menu (o `lib/popupmenu` aceita item-frame); chips abaixo da bolha com tooltip de quem reagiu; limite de 5 emojis e chip "+N"; Ctrl + clique direito abre só as reações | F4 | P0 |
| ENV-18 | Ocultar mensagem | ⬜ | `TMensagem.Excluir` (`Conversa.Proxy.pas:710-721`) existe, sem interface | Item "Ocultar" com a confirmação exata do web (foco inicial em "Cancelar") | F4 | P0 |
| ENV-19 | Copiar | 🟡 | Clique direito → "Copiar" (`Conversa.Chat.pas:326-333`): copia todos os textos unidos por quebra de linha, mas troca `&` por `&&` na área de transferência (`:368`). **Copiar imagem nunca funciona:** o teste exige `TImage` (`:350`), mas o objeto clicado é o `TChatConteudoImagem` (`chat.visualizador.pas:175`). Não dá para selecionar parte do texto (`TText`) | Copiar a imagem clicada (PNG) ou o texto; permitir seleção parcial do texto | F4 | P1 |
| ENV-20 | Menu de ações | 🟡 | Só clique direito, e só com "Copiar" (`Conversa.Chat.pas:326-333`). Não há botão ⋯ no hover | Botão ⋯ ao passar o mouse e clique direito; itens na ordem do web (reações, Responder, Responder no privado, Encaminhar, Copiar, Ocultar); sem "Encaminhar" para votação | F4 | P0 |
| ENV-21 | Campo de mensagem rico | ⬜ | Hoje há um `TMemo` e uma fila de anexos separada (modelo antigo, ANX-01). Envio na ordem [anexos…, áudio, texto] (`chat.editor.pas:152-174`) | **Decisão de produto** (análoga à FC-416 do Android): editor por blocos (texto ↔ peça) sobre `TLayout`/Skia, ou manter fila + texto (perde a intercalação). Arrastar e soltar dentro do campo | F3 | P1 |
| ENV-22 | Criar votação | ⬜ | — | Modal "Nova votação" a partir do "+" (só em grupo), com data final | F4 | P1 |
| ENV-23 | Rascunho por conversa | ⬜ | Trocar de conversa **destrói o editor** (`Limpar` → `FreeAndNil(Editor)`, `Conversa.Chat.pas:143-149`): o texto, a fila de anexos e a gravação em andamento se perdem | Guardar por usuário e conversa (JSON na pasta de dados ou SQLite local): texto, menções, anexos e resposta pendente; restaurar ao abrir; apagar ao enviar | F4 | P1 |

### ANX — Anexos e mídia

| ID | Funcionalidade | FMX | Situação / evidência | Adaptação Windows | Fase | Prio |
|---|---|---|---|---|---|---|
| ANX-01 | Fila de anexos (substituída no web pelo ENV-21) | 🟡 | **O que existe:** o clipe abre um `TOpenDialog` com seleção múltipla (`chat.selectfile.pas:38-55`); a fila mostra ícone ou miniatura, nome, tamanho em MB e "remover" (`chat.editor.anexo.pas:60-94`, `chat.editor.anexo.item.pas:55-83`), com cancelar tudo. **Problemas:** ordem **invertida** no envio (`chat.editor.anexo.pas:148`, `downto`); nome com ponto final (`:159`: "foto.jpg" vira nome "foto.", exibido como "foto..jpg"); não aceita arrastar e soltar; sem prévia nem player na fila | Arrastar e soltar sobre a conversa (overlay "Solte para enviar o arquivo"); ordem preservada; tamanhos B/KB/MB/GB | F3 | P0 |
| ANX-02 | Upload com deduplicação e progresso | 🔴 | **Certo:** SHA-256 hex e `GET /anexo/existe` (`Conversa.Dados.pas:270-279`, `Conversa.Proxy.pas:748-760`); a deduplicação bate com o web. **Quebrado:** o upload é o do servidor antigo, `PUT /anexo` com corpo `application/octet-stream` e `tipo`/`nome`/`extensao` na query (`Conversa.Proxy.pas:788-814`) → 400, porque o servidor exige JSON `{identificador, tipo, nome, extensao, tamanho}` (doc 01 §8.2). O `tipo` vai sempre 0 (`Conversa.Dados.pas:280`). **Efeito:** o upload roda numa thread que ninguém espera, e o `PUT /mensagem` sai antes, com o identificador órfão. Os outros **veem a mensagem vazia** (conteúdo de anexo inexistente é omitido, doc 01 §10.2); o remetente vê a imagem local. **Outros:** o arquivo inteiro é lido na memória (`:270-271`); sem progresso | `PUT /anexo` (JSON) → `PUT upload_url` (stream, sem `Authorization`, em até 300 s) → `POST /anexo/confirmar?identificador=`; a mensagem só depois; hash em streaming; barra de progresso após 2 s; cancelar a mensagem se algum upload falhar | F3 | **P0** |
| ANX-03 | Tipo de conteúdo por arquivo | 🟡 | **Imagem:** detectada por lista de extensões (`bmp, jpg, png, lottie, tgs, gif, webp, svg`, `chat.tipos.pas:45`), então `.jpeg`, `.jfif`, `.heic` e `.tif` vão como arquivo. **Áudio:** `.mp3`, `.m4a` etc. vão como 3, não 4. **Gravação:** vai como 4, não 5 (`chat.editor.audio.pas:306-309` → `Conversa.Dados.pas:258`). Vídeo como 3 está certo. A extensão não é limitada a 10 caracteres (a coluna do servidor tem 10, doc 01 §19.42) | Detectar por assinatura/MIME (`image/*`→2, `audio/*`→4, gravação→5, demais→3); extensão com até 10 caracteres | F3 | P0 |
| ANX-04 | Visualizador de imagens e vídeos | 🟡 | **O que existe:** clique na imagem abre `TVisualizadorMidia` (`Conversa.Chat.pas:323-324`, `Conversa.Visualizador.Midia.pas:100-117`) com uma imagem, zoom pela roda de 10% a 1000% (`ImageViewerFrame.pas:160-163`, `:252-255`), duplo clique alternando 100%, Esc fechando (`Conversa.Visualizador.Midia.pas:127-132`) e Ctrl+clique abrindo em janela maximizada. **O que falta:** galeria, miniaturas, ←/→, legenda, botões −/%/+, "Copiar imagem (Ctrl+C)" e vídeo. **Defeitos:** GIF/WebP/SVG passam `Bitmap = nil` (`chat.conteudo.imagem.pas:95-100`), com provável divisão por zero (`ImageViewerFrame.pas:169-171`). Contra o servidor atual, só abre imagens enviadas pelo próprio usuário (ANX-14) | Overlay/janela com galeria da conversa (sem ocultas), legenda, ←/→, +/−, Ctrl+C, vídeo (`TMediaPlayer` ou FFmpeg), "Carregando imagem" | F3 | P0 |
| ANX-05 | Vídeo na conversa | ⬜ | Aparece como arquivo genérico | Primeiro quadro via FFmpeg (já existem `conversa-webrtc/FFmpeg.Binding.pas` e `Video.Decoder.pas`), ícone de play e reprodução no visualizador; "Baixar video" | F3 | P1 |
| ANX-06 | Visualizador de PDF | ⬜ | — | "Abrir": `TWebBrowser` (WebView2) com o PDF num arquivo temporário, ou o app padrão via `ShellExecute` | F3 | P2 |
| ANX-07 | HTML isolado | ⬜ | — | Abrir no navegador padrão a partir de arquivo temporário, ou WebView2 sem ponte JS e sem o token | F3 | P3 |
| ANX-08 | Markdown e Mermaid | ⬜ | — | Ver MSG-15 | F4 | P2 |
| ANX-09 | Download | 🔴 | O ícone abre um `TSaveDialog` (`Conversa.Dados.pas:352-393`); `DownloadAnexo` grava **o JSON `{"url": …}`** devolvido por `GET /anexo` como se fosse o arquivo (`Conversa.Proxy.pas:762-786`, `:779`) e o move para o destino: o usuário recebe um "PDF" que é um JSON. Um erro (400 "Upload ainda não foi concluído") vira arquivo vazio. Extensão vazia gera "Nome." no diálogo | `GET /anexo?identificador=` → baixar a URL assinada em segundo plano com progresso; salvar em Downloads (ou pelo diálogo); "Abrir" via `ShellExecute`; erro "Não foi possível baixar" | F3 | P0 |
| ANX-10 | Player de áudio | 🔴 | **O que existe:** frame com play/pause e barra com arraste (`chat.conteudo.mensagem.audio.pas:67-157`). **Defeitos:** depende do download quebrado (ANX-14); a duração aparece em unidades de 100 ns (`TMediaTime.ToString`, `:79`, `:101`, `:147`); um `TMediaPlayer` por bolha, aberto já no carregamento (`:58-63`, `:75-80`); vários áudios tocam ao mesmo tempo. **Falta:** verde "não ouvido" e `POST /mensagem/reproduzir`; o `Reproduzir` do código morto manda `{mensagem_id, conversa_id}` (`src/Conversa.Proxy.Extras.pas:282-298`) em vez de `{conversa, mensagem}`. **Formatos:** arquivos sem extensão e as gravações webm/ogg (Opus) do web provavelmente não abrem no `TMediaPlayer` do Windows (não confirmado) | Gerenciador "um áudio por vez"; URL buscada só no primeiro play; `mm:ss`; verde até ouvir; `POST /mensagem/reproduzir {conversa, mensagem}` uma vez; decodificar com o FFmpeg já distribuído (`bin/avcodec-62.dll` etc.) | F3 | P0 |
| ANX-11 | Gravação de áudio | 🟡 | **Funciona localmente:** segurar o microfone 250 ms começa (`chat.editor.pas:188-212`); soltar no botão envia; arrastar para cima trava; há "Cancelar" (`chat.editor.audio.pas:108-230`). **Problemas:** vai como tipo 4, sem nome nem extensão (`:306-309`); o arquivo é nomeado `.mp3` (`:169`) sem garantia do formato real; não chama `POST /conversa/gravando`; clique curto não faz nada (o web entra no modo travado); sem pausar nem ouvir antes; tempo em `00:05,123` (`:302`); trocar de conversa durante a gravação não para a captura. O envio quebra no upload (ANX-02) | Igual ao web: segurar ≥ 300 ms e soltar envia; clique curto trava; barra com "Descartar", "Pausar gravação", "Ouvir gravação" e "Enviar áudio"; formato conhecido (Opus/WebM via FFmpeg, ou M4A/WAV); `audio-<timestamp>.<ext>`, tipo 5 | F3 | P0 |
| ANX-12 | Transcrição de áudio | ⬜ | — | "Transcrever" abaixo de áudios 4/5; `PUT/GET /anexo/transcricao` com polling de 3 s | F3 | P1 |
| ANX-13 | Página de anexos | ⬜ | Só `TAnexoExtras.Listar`, código morto (`src/Conversa.Proxy.Extras.pas:488-514`) | Tela ou painel "Anexos" com filtros, grade e paginação | F7 | P2 |
| ANX-14 | URLs assinadas e renovação | 🔴 | **Como está:** o FMX trata `GET /anexo` como download direto dos bytes (servidor antigo) e grava o resultado no cache `PastaDados\anexos\<identificador>` (`Conversa.Dados.pas:229-241`), **de forma síncrona na thread da interface**, para cada imagem e áudio carregados (`:601`, `:603`). **Com o servidor atual:** o cache recebe o JSON; `TBitmap.LoadFromFile` lança exceção (`chat.conteudo.imagem.pas:73-74`) e interrompe o lote, e as mensagens mais antigas que a imagem não aparecem (`Conversa.Chat.pas:231-238`). O JSON fica no cache e é reaproveitado para sempre (`TFile.Exists`, `Conversa.Dados.pas:232`) | Download assíncrono em duas etapas; cache por identificador (conteúdo imutável), gravado só depois do sucesso e validado (tamanho/assinatura); nunca cachear a URL; limpar o cache envenenado na migração; `try/except` por mensagem | F3 | **P0** |
| ANX-15 | Pré-visualização antes de enviar | ➖ | No web é código sem gatilho; a fila do FMX já mostra a miniatura (`chat.editor.anexo.item.pas:62-67`) | — | — | P3 |

---

## 2. Pontos de atenção especial

### 2.1 Paginação (`mensagemreferencia` / `mensagensprevias` / `mensagensseguintes`, no máximo 100)

**O que o FMX faz** (`Conversa.Dados.pas:510-549`):

| Momento | Chamada |
|---|---|
| Primeira carga | `ref=0, previas=50, seguintes=0` |
| Novas | `ref = UltimaMensagemSincronizada + 1, previas=0, seguintes=50` |
| Anteriores | `ref = menor id carregado − 1, previas=50, seguintes=0` (sai se ≤ 0) |

**Como o servidor responde** (`conversa/src/mensagens.ts:328-375`):
- a posição de referência é `(select coalesce(visivel_em, inserida) from mensagem where id = ref), ref`;
- os ids são **globais**, de todas as conversas;
- se `ref` não existe (lacuna na sequência, agendada apagada de vez, ou id ainda não criado), a posição é **nula** e a comparação de linha devolve **nada**.

**Consequências:**
1. **Mensagem perdida por corrida (ALTO):**
   1. B envia a mensagem 99;
   2. A envia a 100 pelo FMX, e o `UltimaMensagemSincronizada` de A vira 100;
   3. chega o WS 2 da 99, e o FMX pede `ref=101`;
   4. se 101 ainda não existe, a resposta é vazia;
   5. quando 101 existir, a posição dela é posterior à 99, então a 99 fica fora **para sempre** na sessão.
2. **Página anterior pode não vir:** se `menor − 1` for uma lacuna, a resposta é vazia. Também não há como saber que a lista acabou (rolar ao topo repete a chamada).
3. **Re-busca duplica e quebra (CRÍTICO, A5b-01).** Quando uma resposta traz uma mensagem já carregada:
   - `EventoObterMensagens` reaproveita o objeto (`Conversa.Dados.pas:570-575`);
   - **acrescenta os conteúdos de novo** (`:591-606`);
   - chama `Mensagens.Add`, que levanta `Exception('Mensagem já adicionada!…')` (`Conversa.Tipos.pas:622-624`);
   - o resto do lote é abandonado e aparece o diálogo de erro.
   - **Isso acontece:**
     - com dois WS 2 próximos ou duplicados (doc 01 §19.29), que disparam duas buscas iguais antes da primeira resposta;
     - com o topo da rolagem disparando várias vezes (`chat.visualizador.pas:112-114` chama a cada mudança com `Value = 0`);
     - com agendadas do próprio autor (posição futura).
4. **A tela pula para o fim depois de carregar as anteriores.** `AoChegarLimite` dispara a busca assíncrona. A resposta volta por `TExibirMensagem` → `TChat.EventoExibirMensagens` → `AdicionarMensagens(…)` com `IrParaUltima = True` por padrão (`Conversa.Chat.pas:392-395`, `:243-244`). A chamada imediata em `:376` não tem efeito, porque a resposta ainda não chegou.
5. **`/mensagens/novas` errado:**
   - a chamada manda `?ultima=<id>` (`Conversa.Proxy.pas:290`);
   - o servidor só conhece `desde`, e campos extras são ignorados, então `desde=''` significa "desde sempre";
   - o servidor devolve **todas** as conversas com qualquer mensagem não visualizada, e o FMX dispara um `GET /mensagens` para cada uma (`Conversa.Dados.pas:496-508`);
   - como o visualizar está quebrado (MSG-04), essa lista só cresce.

**Correção:**
- **Cursores:** usar o **id da primeira/última mensagem salva** como referência (inclusiva), descartar a repetida e parar quando vierem menos itens que o pedido.
- **Anteriores:** uma requisição por vez por conversa (*in-flight guard*), preservando a âncora de rolagem.
- **Novas:** por WS 2 → `GET /mensagens/novas?desde=<ate>` (cursor) → para cada conversa, `ref = última salva`, `seguintes`.
- **Modelo:** fazer *upsert* (atualizar status, `excluida_em` e reações; nunca reanexar conteúdos).

### 2.2 Ordem (`coalesce(visivel_em, inserida)`, id como desempate, otimistas no fim)

- O FMX posiciona cada frame pela data `Inserida` (`chat.visualizador.pas:228`, `:238-263`, `ObtemTopMensagem`) e usa `Align = Top`.
- `visivel_em` é ignorado, então a agendada amadurecida entra no passado (MSG-17).
- **Não há desempate por id.** Com datas iguais, `Data <= Item.Data` põe a nova **antes** da existente, ou seja, ordem invertida para mensagens no mesmo milissegundo.
- A mensagem própria usa o relógio local (`Inserida(Now)`, `Conversa.Chat.pas:262`), e não a data do servidor. Com relógio adiantado ou atrasado ela fica fora de lugar, até a próxima recarga, que nunca acontece (o *upsert* não existe).
- `OrdemTempo` (`Conversa.Tipos.pas:1065-1083`) ordena de forma **decrescente** e compara `Alterada`, que é sempre nulo no servidor atual. Só afeta a ordem de iteração.

### 2.3 Classificação das bolhas × `classificarMensagem.ts`

Web (`conversa-web/src/utils/classificarMensagem.ts:20-72`), na ordem: oculta > chamada > imagem > enquete > figurinha > código > emoji > com referência > texto curto > padrão.

| Variante web | Condição | FMX hoje |
|---|---|---|
| Excluída/oculta | `excluida_em` | **Não existe.** Mostra o conteúdo original (MSG-16) |
| Chamada | único tipo 6 | Bolha vazia (tipo fora do enum) |
| Imagem | único tipo 2, sem referência | Frame de imagem, sempre dentro da bolha padrão com o nome; sem a variante "hora sobre a imagem". Com o servidor atual, exceção (ANX-14) |
| Enquete | único tipo 8 (com ou sem referência) | Bolha vazia |
| Figurinha | único tipo 7, sem referência | Bolha vazia |
| Código | texto único só com blocos | Texto cru |
| Emoji | texto único só com emojis | Fonte 30 **com** fundo de bolha |
| Com referência | `mensagem_referencia.mensagem` | Não lido; aparece como padrão |
| Texto curto | uma linha, ≤ 60 caracteres | Não existe (a largura da bolha já se ajusta ao texto, `chat.mensagem.pas:221-263`) |
| Padrão | demais | Bolha única com os conteúdos empilhados |

Também há divergências na gravação (tipo 5) e no áudio (tipo 4):
- **gravação (tipo 5):** vazia;
- **áudio (tipo 4):** aparece com o frame de "mensagem de áudio";
- o web mostra a hora dentro do player numa bolha só de áudio. O FMX move `lytBottom` para dentro do frame do anexo ou áudio (`chat.visualizador.pas:202-203`, `:217-218`), o que se aproxima disso.

### 2.4 Mensagem oculta (`excluida_em`)

O servidor manda o conteúdo original (doc 01 §10.9). O FMX **não esconde**:
- o campo não existe em `Conversa.Proxy.Tipos.TMensagem` (`:99-111`) nem em `TMensagemStatus` (`:116-122`);
- o modelo `Conversa.Tipos.TMensagem` também não o tem (`:174-218`).

**O que fazer:**
1. Ler `excluida_em` em `/mensagens`, `/mensagem/status` e nas referências.
2. Classificar como oculta antes de tudo.
3. Clique alterna entre revelar e ocultar, com os tooltips do web.
4. Sem menu e sem reações.
5. Fora da galeria.
6. Citação com "Mensagem oculta".
7. Votação oculta mostra o resumo.

**P0 de privacidade.**

### 2.5 Agendadas (`visivel_em`)

Não há leitura nem envio de `visivel_em`. Efeitos práticos (o FMX não agenda, mas convive com o web):
- **autor:** vê no FMX as próprias agendadas futuras (feitas no web) como mensagens comuns, inclusive marcadas como enviadas;
- **destinatários:** a mensagem amadurecida entra na posição de `inserida`, no meio do histórico; com a rolagem forçada ao fim, o usuário nem a vê.

**Correção:**
1. ordenar pela data efetiva;
2. esconder as futuras;
3. relógio com o número de agendadas e a lista "Mensagens agendadas";
4. agendar com `visivel_em` (≥ agora + 5 min e ≤ 1 ano).

### 2.6 Linha "Últimas"

Existe o frame com o texto "Mensagens não lidas" e os métodos de exibir/ocultar, mas **sem chamada**; ver MSG-03. A informação necessária já existe: `PrimeiraExibicao` (`Conversa.Dados.pas:589`, `Conversa.Tipos.pas:815-816`) marca as não visualizadas na primeira carga.

**Implementar as 5 regras do web:**
1. posição fixada na primeira aparição;
2. a linha fica enquanto a conversa está aberta;
3. com a janela sem foco, a linha passa para cima da mensagem nova;
4. sem linha se a janela está focada e a rolagem está a ≤ 500 px do fim;
5. o auto-scroll não empurra a linha para fora.

### 2.7 Status ✓/✓✓ e WS 3

- **O que funciona:**
  - `TSocketMessageType.AtualizacaoStatusMensagem = 3` (`Conversa.Tipos.pas:23`);
  - CSV quebrado em inteiros;
  - `GET /mensagem/status`;
  - `TObterMensagensStatus`;
  - `Recebida(...)`/`Visualizada(...)`;
  - `TEventoAtualizacaoMensagem` → `TChat.AoAtualizarMensagem` (`Conversa.Chat.pas:292-315`) troca o ícone.
- **Falhas:**
  - `excluida_em` é ignorado;
  - id desconhecido não recarrega a conversa ativa;
  - `/conversas` não é recarregado.
- **Riscos:**
  - `TChatVisualizador.GetMensagem`/`GetVisivel` usam o indexador do `TDictionary`, que lança exceção para id ausente (`chat.visualizador.pas:408-411`, `:437-440`);
  - `TChat` assina `TEventoAtualizacaoMensagem` e nunca cancela a assinatura (`Conversa.Chat.pas:113` × `:116-123`).
- **Contador:** `Visualizada(True)` vinda do servidor ao carregar o histórico **desconta** o contador de não lidas de mensagens que já estavam lidas (`Conversa.Tipos.pas:854-856`, chamado em `Conversa.Dados.pas:588`). Isso combina com o `Inc` de `:609-610` e com o valor de `/conversas` (`:216-217`): o contador fica imprevisível. É área do CON/NOT, citada aqui por causar o efeito.

### 2.8 Marcar como visualizada

- Rota errada (`GET` × `POST` com corpo): **404** (MSG-04).
- `Tentativa(5)` não repete erro HTTP (só `Unknown`), e `ValidarErro` aborta a thread em silêncio.
- **Critério:**
  - `FramePaint` + `IsFormActive` (`chat.mensagem.pas:265-270`) marca ao pintar, ou seja, até mensagem quase toda fora da tela;
  - o `ValidarVisualizacao` do `FormActivate` usa o critério certo.
- **Corrigir:**
  1. `POST`;
  2. marcar só mensagens de outro, totalmente visíveis, com a janela em primeiro plano e não minimizada;
  3. descontar o contador só após sucesso;
  4. ao zerar, fechar a notificação da conversa.

### 2.9 Menções `@[Nome](id)`

- Não há renderização: o texto cru aparece na bolha.
- Também não há inserção no campo.
- **Renderização sugerida:**
  - trocar por `@Nome` com atributo de cor;
  - guardar a faixa para hover/clique, reaproveitando o mecanismo de links de `chat.conteudo.texto.pas:21-27`, `:78-154`.
- **Campo:**
  - o `TMemo` não colore trechos, então é preciso um campo próprio (ENV-21) ou uma camada de realce atrás do `TMemo`, como o web fazia antes do Tiptap;
  - no envio, `@[Nome](id)`;
  - "@Ana" não casa com "@Anabela".

### 2.10 Blocos de código, Markdown e Mermaid

- Nada existe: as crases aparecem cruas.
- **Desktop:**
  - porte literal de `codeBlocks.ts` (detecção de cercas, aninhamento e `md` fechando na última cerca);
  - frame de código com fonte monoespaçada, cabeçalho, "Copiar"/"Copiado!" e "Expandir código"/"Recolher código";
  - destaque de sintaxe por tokenizador por linguagem (palavras-chave, strings, comentários) com `TTextLayout.AddAttribute`;
  - **Markdown/Mermaid:** WebView2 (`TWebBrowser` com motor Edge) isolado, sem ponte, com HTML gerado localmente; alternativa: só "Código".
  - **Colar mais de 10 linhas** abre "Inserir código" (ENV-09/10). Vale literalmente no Windows.

### 2.11 Links

- Parcial (MSG-11): `http/https/ftp` com `ShellExecute`.
- **Faltam:** `www.`, o tratamento de `)` e a correção das faixas com `&`.
- **Atenção:** `TText.SetNewText` grava `Value.Replace('&', '&&')` (`chat.conteudo.texto.pas:166`) e calcula as faixas sobre o texto original. Se o `TText` do FMX não interpreta `&` (não confirmado), o usuário vê `&&` na bolha.

### 2.12 Emojis

- **Só emoji:** fonte 30, mas com fundo de bolha. A detecção varre a tabela de cerca de 5 000 emojis com `Pos` e `StringReplace` a cada texto (`chat.emoji.pas:5071-5120`): é custo O(5 000 × tamanho) por mensagem no carregamento.
- **Atalhos `:)` etc.:** não existem (ENV-02).
- **Seletor:** painel do Windows por simulação de teclas (ENV-03).
- **Emoji colorido:** não confirmado no canvas padrão. O `.dpr` não liga `GlobalUseSkia`.

### 2.13 Figurinhas Lottie (tipo 7)

- O tipo não existe no modelo; a bolha sai vazia.
- **O projeto já tem Skia:**
  - `chat.conteudo.imagem.pas` usa `FMX.Skia`/`Skia` com `TSkAnimatedImage` e `TSkSvg` (`:49-84`);
  - há uma cópia local do Skia4Delphi em `src/chat/chat/skia/`. Não foi confirmado qual versão entra no build, nem se conflita com o Skia embutido do Delphi 12.
- O `TSkAnimatedImage` toca **Lottie JSON e `.tgs` (Skottie)**.
- **Implementação sugerida:**
  1. embutir os 24 JSON (`basico`, `rostos`, `coisas`) como `RCDATA`, porque o servidor não os serve (doc 01 §10.6);
  2. bolha de 160 px, 64 px no seletor, 120 px na resposta;
  3. tocar só quando visível;
  4. em falha, mostrar o texto "Figurinha".
- O ramo Skia atual de `LoadFromFile` decide pela **extensão do arquivo** (`chat.conteudo.imagem.pas:53`), mas o cache grava sem extensão (`PastaDados\anexos\<sha>`). Na prática GIF/WebP nunca animam e SVG nunca é reconhecido.

### 2.14 Reações

- Nada na interface.
- `reacoes` não é lido, o WS 7 é ignorado, e `Reagir` correto só existe no código morto.
- **Implementar:**
  1. barra de reações rápidas no menu (`TPopupMenu.Add(AItem: TFrame)` permite um item-frame com os 7 emojis + "Mais emojis");
  2. chips abaixo da bolha, destacados se eu reagi, com tooltip de quem reagiu;
  3. limite de 5 emojis diferentes por pessoa conferido antes da otimista, com o diálogo "Não foi possível reagir"; chip "+N";
  4. WS 7 com `acao: "remove"`;
  5. mensagem oculta não mostra reações.

### 2.15 Responder / encaminhar (`mensagem_referencia {tipo, origem_mensagem_id}`)

- **Não existe.**
- O `TReqMensagem` (`Conversa.Proxy.Tipos.pas:81-86`) não tem o campo.
- O código morto `EnviarComReferencia` usa nomes errados (`referencia`, `destino_mensagem_id`; `src/Conversa.Proxy.Extras.pas:337-339`); o servidor ignoraria a referência sem erro.
- **Lembrar:**
  - `origem_mensagem_id` = id da mensagem **referenciada**;
  - "Responder no privado" = tipo 2, com os conteúdos da original antes do texto;
  - votação não pode ser encaminhada (400).

### 2.16 Citação recursiva

- Não existe.
- **Implementar:**
  - frame recursivo até 5 níveis, a partir de `mensagem_referencia.mensagem` (que pode faltar);
  - título com o remetente, ou "Encaminhado de <nome>"/"Encaminhado";
  - clique leva à original (MSG-06);
  - a encaminhada não repete os conteúdos iguais (`semCopiasDaReferencia`);
  - oculta mostra "Mensagem oculta".

### 2.17 Enquete (tipo 8)

- Bolha vazia; WS 62 fora do enum; nada de criar.
- Ver MSG-20 e ENV-22.
- No mínimo, o marcador "📊 Votação" no F2.

### 2.18 Campo rico (ENV-21)

- Não existe.
- O modelo atual é fila de anexos + `TMemo`, enviados como [anexos (ordem invertida), áudio, texto].
- **Decisão de produto:**
  - **(a)** editor por blocos (cada bloco é um `TMemo` ou uma "peça" com miniatura e ×; Backspace apaga a peça; ordem preservada no envio);
  - **(b)** manter fila + texto, perdendo a intercalação, mas corrigindo a ordem e acrescentando arrastar e soltar.
- **Figurinha e gravação com o campo vazio:** envio imediato.

### 2.19 Rascunho (ENV-23)

- Não existe. **Pior:** trocar de conversa destrói o editor (`Conversa.Chat.pas:143-149`), então tudo o que foi digitado ou anexado se perde.
- Se houver gravação em andamento, a captura continua: o microfone fica ocupado e o arquivo fica preso (`chat.editor.audio.pas:171` não tem par no destrutor).
- **Implementar:**
  1. salvar com atraso a cada mudança (JSON por usuário e conversa na pasta de dados);
  2. restaurar em `AbrirChat`;
  3. apagar ao enviar.

### 2.20 Colar imagem

- Existe, com defeitos: ver ENV-11. Pasta do executável e nome por contagem.
- Interceptar também `Shift+Insert` e o "Colar" do menu de contexto do `TMemo`.
- Converter para PNG está certo.

### 2.21 Arrastar arquivo

- **Não existe:** não há `OnDragOver`/`OnDragDrop` em `src/chat`.
- O FMX no Windows entrega os arquivos em `TDragObject.Files`.
- **Implementar:**
  1. overlay "Solte para enviar o arquivo" / "Imagens mostrarao uma previa antes de enviar" sobre a conversa;
  2. soltar adiciona os arquivos à fila (ou ao campo rico) na ordem.

### 2.22 Gravação de áudio (`chat.editor.audio`)

**Fluxo atual:**
- `TAudioCaptureDevice` padrão (`:105`), segurar 250 ms, captura do mouse no formulário (`:177-183`), "Solte para enviar, ou deslize para cancelar", travar ao arrastar para cima, "Cancelar".

**Contrato:**
- **tipo 4** em vez de 5 (`:308`);
- sem `Nome`/`Extensao`, então o servidor grava `nome`/`extensao` nulos;
- nome local `.mp3` (`:169`). Formato real que o `TAudioCaptureDevice` grava no Windows: não confirmado;
- sem `POST /conversa/gravando`.

**Interface:**
- falta clique curto → modo travado;
- falta pausar/continuar e ouvir antes com seek;
- falta "Descartar"/"Enviar áudio";
- tempo `m:ss` (hoje `00:05,123`).

**Sugestão:** gravar PCM e codificar em Opus/WebM com o FFmpeg já distribuído (mesmo formato do web, que os navegadores tocam), ou M4A/AAC. Nome `audio-<timestamp>.<ext>`.

### 2.23 Player de áudio

Ver ANX-10.

**Necessário:**
1. **um por vez:** um gerenciador global que para o anterior;
2. **verde até ouvir:** precisa do estado `reproduzida` do próprio usuário, que vem em `/mensagens` (doc 01 §10.2); hoje o FMX lê `reproduzida` no registro, mas não usa;
3. `POST /mensagem/reproduzir {conversa, mensagem}` no primeiro play;
4. duração em `mm:ss`;
5. não criar `TMediaPlayer` por bolha nem abrir a mídia no carregamento; buscar a URL só no primeiro play.

**Formato:** as gravações do web são webm/ogg (Opus) (`conversa-web/src/composables/useAudioRecording.ts:59`). Tocar com o `Audio.Player`/FFmpeg do módulo WebRTC é o caminho mais seguro.

### 2.24 Transcrição

- Não existe (ANX-12).
- **Implementar:**
  - estado inicial vindo de `transcricao_status`/`transcricao` nos conteúdos;
  - "Transcrever" → `PUT /anexo/transcricao` → polling de 3 s em `GET`;
  - "(nenhuma fala reconhecida)";
  - erro "Não foi possível transcrever. Tentar de novo".

### 2.25 Visualizadores (imagem, vídeo, PDF)

**Imagem:** `TVisualizadorMidia` + `TImageViewerFrame`.
- **Bom:** zoom pela roda centrado no mouse e duplo clique alternando 100%.
- **Faltam:**
  - galeria da conversa (sem ocultas), com miniaturas e ←/→;
  - legenda;
  - "Copiar imagem (Ctrl+C)" e o menu de contexto;
  - botões −/%/+;
  - vídeo;
  - "Carregando imagem".
- **Detalhes:**
  - clicar fora da imagem (`lytMediaClick`) fecha o visualizador, o que pode surpreender durante o arraste;
  - o clique em GIF/WebP/SVG manda `nil`.

**Vídeo e PDF:** não existem.

### 2.26 Download

Quebrado (ANX-09): grava o JSON da URL assinada. Além disso:
- `TFile.Move` tira o arquivo do cache;
- o filtro do diálogo "Arquivo|*.ext" com extensão vazia gera "Nome.";
- um anexo não localizado levanta `Exception('Anexo não encontrado!')` sem tratamento (`Conversa.Dados.pas:372-373`).

**Implementar:**
1. `GET /anexo` → URL;
2. baixar em segundo plano com progresso;
3. "Abrir" via `ShellExecute`;
4. aviso "Não foi possível baixar".

### 2.27 Envio otimista e falha

- **Não há otimista.** A mensagem só aparece depois do `PUT /mensagem`, executado na thread da interface (`Conversa.Chat.Listagem.pas:105-110`).
- Com anexo, antes disso ainda roda o hash do arquivo inteiro na memória e o `GET /anexo/existe` síncrono.
- **Em falha:**
  - `ValidarErro` publica `TErroServidor` (sem assinante) e levanta `EAbort`, que é silencioso;
  - o texto e os anexos **continuam no editor**, porque `Limpar` não roda (`chat.editor.pas:152-174`): **não se perdem**;
  - o usuário **não recebe aviso**;
  - o `TMensagem` criado em `TChat.AoEnviar` vaza (`Conversa.Chat.pas:260-264`).
- **No caminho do áudio:** o `EAbort` impede `SetEditor(Texto)` (`chat.editor.audio.pas:224-230`), e o editor fica no modo áudio com a gravação pronta para reenviar. Funciona por acidente.
- **Implementar:**
  1. mensagem com id negativo e relógio, aparecendo na hora;
  2. envio em tarefa de fundo;
  3. em erro, remover a otimista e mostrar o erro acima do campo, devolvendo o conteúdo ao campo;
  4. depois do sucesso, trocar pelo id do servidor e recarregar `/conversas`.

---

## 3. Textos de UI × web (doc 03 §6.1)

| Situação | FMX (arquivo:linha) | Web (texto exato) | Ação |
|---|---|---|---|
| Placeholder do campo | "Mensagem" (`chat.editor.texto.fmx:160`) | "Digite uma mensagem" | Trocar |
| Linha de não lidas | "Mensagens não lidas" (`chat.separador.lidas.fmx:21`; não usada) | "Últimas" | Trocar e usar |
| Separador de dia | "21/08" ou "21/08/2025" (`chat.separador.data.pas:51`) | "seg., 05/10/2026" | Trocar o formato |
| Digitando | "digitando..." (`Conversa.Chat.fmx:210`; sempre oculto) | "Digitando..." / "<nome> está digitando..." / … | Trocar e implementar |
| Lista vazia | "Selecione um Chat para conversar" (`Conversa.Chat.Listagem.fmx:62`) | "Selecione uma conversa." | Trocar (área CON) |
| Menu de ações | "Copiar" (`Conversa.Chat.pas:328`) | "Responder", "Responder no privado", "Encaminhar", "Copiar", "Ocultar" + reações | Completar |
| Imagem ausente | "Erro: Imagem não encontrada!" (`chat.visualizador.pas:180`) | (sem equivalente; o web mostra "Erro" na grade de anexos) | Mostrar um placeholder de imagem com "Toque para tentar de novo"/"Erro", sem o texto técnico |
| Gravação | "Solte para enviar, ou deslize para cancelar" (`chat.editor.audio.pas:166`, `chat.editor.audio.fmx:226`), "Cancelar" (`:192`) | "Descartar", "Pausar gravação"/"Continuar gravação", "Ouvir gravação"/"Parar preview", "Enviar áudio" | Alinhar ao web (o aviso de "soltar para enviar" pode ficar como dica do modo segurar) |
| Tempo de gravação | "00:05,123" (`chat.editor.audio.pas:302`, `.fmx:215`) | "0:05" (`m:ss`) | Trocar |
| Duração/tamanho do áudio | `<ticks de 100 ns>, 34 kb` (`chat.conteudo.mensagem.audio.pas:79`) e `<ticks> / <ticks>` (`:101`) | `mm:ss` (`formatarDuracao`) | Corrigir |
| Tamanho de arquivo na bolha | "10 KB" fixo do design (`chat.conteudo.anexo.fmx:16`) | `formatarTamanho` (B/KB/MB/GB); o servidor não manda o tamanho em `/mensagens` | Esconder ou buscar o tamanho (ex.: `GET /anexo/existe`) |
| Tamanho na fila | "0,01 MB" (`chat.editor.anexo.item.pas:80`, `:82`) | "12.3 KB" etc. | Trocar a formatação |
| Título da fila | "Enviar" (`chat.editor.anexo.fmx:19`) | (sem título) | Rever |
| Download | diálogo "Salvar Arquivo", filtro "Arquivo\|*.ext" (`Conversa.Dados.pas:378-382`) | botão "Download"; erro "Não foi possível baixar" | Trocar e acrescentar o erro |
| Anexo não achado | `Exception('Anexo não encontrado!')` (`Conversa.Dados.pas:373`) | — | Aviso amigável |
| Colar imagem | `EBitmapSavingFailed('Erro ao converter a imagem do clipboard para png!')` (`chat.editor.texto.pas:150`) | — | Aviso amigável |
| Prévia/notificação de conteúdo | "📷 Imagem", "📦 Arquivo" (`Conversa.Tipos.pas:907-908`); "Imagem"/"Arquivo" na notificação (`Conversa.Chat.Listagem.pas:286-287`) | notificação: "Imagem", "Gravacao de audio", "Audio", "Figurinha", "Arquivo"; resumo: "Imagem", "Áudio", "Arquivo", "Código (linguagem)", "Votação" | Completar os tipos 4–8 (área CON/NOT) |
| Hint do botão de chamada | "Iniciar Chamada" (`Conversa.Chat.fmx:121`) | — (área CHA) | — |
| Textos inexistentes no FMX | — | "Mensagem oculta" + tooltips; "Encaminhado de <nome>"; "Há novas mensagens"/"Ir para o final"; "Copiado!"; "Expandir código"/"Recolher código"; "Transcrever"…; "Carregando mensagens…"; confirmações de ocultar e cancelar agendada | Implementar com os textos exatos do doc 03 §6.1 |

---

## 4. Problemas encontrados (numeração provisória A5b-NN)

| # | Sev. | Onde | Efeito | Correção sugerida |
|---|---|---|---|---|
| A5b-01 | **CRÍTICO** | `Conversa.Dados.pas:570-607`; `Conversa.Tipos.pas:622-624` | Re-buscar uma mensagem já carregada **acrescenta os conteúdos de novo** e levanta "Mensagem já adicionada!", com diálogo de erro e o resto do lote perdido. Acontece com WS 2 próximos ou duplicados, com o topo da rolagem disparando várias vezes e com agendadas do autor (§2.1) | *Upsert* por id (atualizar status, `excluida_em` e reações; nunca reanexar conteúdos); uma requisição por conversa e direção de cada vez |
| A5b-02 | **CRÍTICO** | `Conversa.Proxy.pas:762-786`; `Conversa.Dados.pas:229-241`, `:601`, `:603`; `chat.conteudo.imagem.pas:73-74`; `Conversa.Chat.pas:231-238` | O download grava o JSON `{url}` como arquivo. A imagem recebida lança exceção no `LoadFromFile` e **interrompe a renderização do lote**: as mensagens mais antigas que a imagem somem. O cache fica envenenado (`TFile.Exists`). Áudio provavelmente idem (não confirmado) | Download em duas etapas, assíncrono, com validação antes de gravar no cache; `try/except` por mensagem com placeholder; apagar o cache antigo na migração |
| A5b-03 | **CRÍTICO** | `Conversa.Proxy.pas:788-814`; `Conversa.Dados.pas:265-281` | O upload no formato antigo dá 400; roda numa thread que ninguém espera, com `tipo = 0`. A mensagem sai com identificador órfão e **chega vazia** aos outros; o erro é engolido | Fluxo novo (`PUT /anexo` JSON → `PUT upload_url` → confirmar) **antes** do `PUT /mensagem`; abortar a mensagem se falhar |
| A5b-04 | **ALTO** | `Conversa.Proxy.Tipos.pas:99-111`, `:116-122`; `Conversa.Dados.pas:551-620` | Mensagem oculta mostra o conteúdo original (privacidade) | Ler `excluida_em` em todas as respostas; bolha "Mensagem oculta" |
| A5b-05 | **ALTO** | `Conversa.Proxy.pas:723-744` | Visualizar com `GET` → 404: o servidor nunca marca, o remetente não vê ✓✓ azul, o contador volta e `/mensagens/novas` cresce para sempre | `POST /mensagem/visualizar {conversa, mensagem}` |
| A5b-06 | **ALTO** | `Conversa.Dados.pas:532-548`; `conversa/src/mensagens.ts:334` | Cursor por aritmética de id global (`±1`): resposta vazia quando o vizinho não existe; **mensagem perdida por corrida** depois de enviar; a página anterior pode nunca vir | Referência = id salvo (inclusivo) e descartar o repetido (§2.1) |
| A5b-07 | **ALTO** | `Conversa.Chat.pas:243-244`, `:371-378`, `:392-395` | Carregar mensagens anteriores (ou receber uma nova) **pula a tela para o fim**, mesmo lendo o histórico; o "carregar anteriores" fica inutilizável | `IrParaUltima` só se o usuário estava a ≤ N px do fim; ao inserir no topo, compensar a rolagem (âncora) |
| A5b-08 | **ALTO** | `Conversa.Proxy.pas:284-311` (`'ultima'`, `:290`); `Conversa.Dados.pas:496-508` | `/mensagens/novas` com parâmetro inexistente: o servidor usa `desde = ''` e devolve todas as conversas com não lidas; cada WS 2 vira N `GET /mensagens` | `desde = ate` (cursor ISO) |
| A5b-09 | **ALTO** | `Conversa.Tipos.pas:220`; `chat.tipos.pas:19`; `Conversa.Dados.pas:596`; `Conversa.Chat.pas:196` | Tipos 5–8 viram enum fora da faixa e a bolha sai vazia: **todas as gravações do web**, chamadas, figurinhas e votações | Enum com 1..8 e um frame (ou ao menos um marcador) por tipo |
| A5b-10 | MÉDIO | `chat.editor.audio.pas:169`, `:306-309`; `Conversa.Dados.pas:258` | Gravação enviada como tipo 4, sem nome nem extensão, com arquivo `.mp3` de formato não garantido; o web a classifica como áudio comum, e a página de anexos a põe em "Audios", não em "Gravacoes" | Tipo 5, extensão real, `audio-<timestamp>.<ext>` |
| A5b-11 | MÉDIO | `chat.conteudo.mensagem.audio.pas:58-63`, `:75-80`, `:79`, `:101`, `:147` | Duração exibida em unidades de 100 ns; um `TMediaPlayer` por bolha, aberto no carregamento (custo e handles); vários áudios ao mesmo tempo; sem `reproduzir` | Player único e preguiçoso, `mm:ss`, `POST /mensagem/reproduzir` |
| A5b-12 | MÉDIO | `chat.visualizador.pas:138-228`, `:238-263`, `:282-335`; `Conversa.Chat.pas:228-241`; `chat.emoji.pas:5071-5120`; `Conversa.Tipos.pas:641-654` | **Desempenho:** um `TFrame` (carregado do recurso `.fmx`) por mensagem e outro por conteúdo; `ObtemTopMensagem` monta e ordena o vetor inteiro a cada inserção (O(n² log n) por lote); `Align = Top` realinha tudo a cada inserção; separadores apagados e recriados a cada lote; `SoEmoji` varre ~5 000 emojis por texto; `TMensagens.Get` é linear (O(n²) no carregamento); frames e modelos nunca são descarregados. Com centenas de mensagens a abertura e a rolagem ficam lentas | Lista virtualizada (desenho próprio com Skia/`TTextLayout`, ou reciclagem de frames só para a janela visível); índice por id (`TDictionary`); inserção binária; separadores calculados uma vez; detecção de emoji por *code point* |
| A5b-13 | MÉDIO | `Conversa.Chat.Listagem.pas:105-110`; `Conversa.Dados.pas:243-290`; `Conversa.Proxy.pas:154-167`; `Conversa.Chat.pas:260-264` | Envio síncrono na thread da interface (congela com arquivos grandes), sem otimista, **erro silencioso** (`TErroServidor` sem assinante + `EAbort`) e vazamento do `TMensagem` em falha | Envio em tarefa de fundo com otimista e erro visível; um assinante global de `TErroServidor` com aviso |
| A5b-14 | MÉDIO | `Conversa.Chat.pas:143-149`; `chat.editor.audio.pas:171` | Trocar de conversa destrói o editor: perde texto, anexos e gravação; a captura de áudio continua | Rascunho por conversa (ENV-23); parar a captura no destrutor |
| A5b-15 | MÉDIO | `Conversa.Chat.pas:350`, `:368`; `chat.visualizador.pas:175` | "Copiar" imagem nunca copia (o teste procura `TImage`, mas o *Sender* é o frame); o texto copiado troca `&` por `&&` | Testar `TChatConteudoImagem` e usar o bitmap (ou o arquivo); copiar o texto sem trocas |
| A5b-16 | MÉDIO | `chat.conteudo.anexo.fmx:16`; `chat.visualizador.pas:188-210` | Toda bolha de arquivo mostra "10 KB" (texto do design) | Esconder ou buscar o tamanho real |
| A5b-17 | MÉDIO | `chat.editor.anexo.pas:148`, `:153`, `:159`; `chat.tipos.pas:45` | Fila enviada em ordem invertida; nome com ponto final ("foto." → "foto..jpg"); `.jpeg`/`.jfif`/`.heic` vão como arquivo; áudio vai como arquivo | Ordem de inserção; `TPath.GetFileNameWithoutExtension`; detecção por assinatura/MIME |
| A5b-18 | MÉDIO | `chat.editor.texto.pas:140-145` | Colar imagem grava em `<pasta do exe>\clipboard`: falha sem permissão (Program Files), acumula arquivos, o nome por contagem colide | Pasta temporária ou de cache, `print-<timestamp>.png`, limpeza após o envio |
| A5b-19 | MÉDIO | `chat.mensagem.pas:265-270` | Marca como visualizada ao **pintar** (mensagem parcialmente visível) | Usar só o critério de totalmente visível na rolagem e no foco |
| A5b-20 | MÉDIO | `Conversa.Dados.pas:270-275` | Upload lê o arquivo inteiro num `TStringStream` (até 1 GiB) e o copia para o cache antes de enviar | Hash e envio em streaming; copiar para o cache só depois do sucesso, ou guardar só a referência |
| A5b-21 | MÉDIO | `Conversa.Dados.pas:352-393` | Salvar anexo move o arquivo do cache; extensão vazia gera "Nome."; exceção crua se o anexo não é achado; depende do download quebrado (A5b-02) | Baixar para o destino escolhido; nomes saneados; aviso amigável |
| A5b-22 | BAIXO | `ImageViewerFrame.pas:165-178`; `chat.conteudo.imagem.pas:95-100`; `Conversa.Chat.pas:324` | Clicar em GIF/WebP/SVG manda `nil` ao visualizador; divisão por zero provável | Passar o arquivo, ou renderizar o quadro atual |
| A5b-23 | BAIXO | `chat.conteudo.imagem.pas:53` | O ramo Skia (GIF/WebP/SVG animados) decide pela extensão, mas o cache não tem extensão: animação nunca toca | Decidir pela assinatura do arquivo ou guardar a extensão |
| A5b-24 | BAIXO | `Conversa.Chat.pas:113` × `:116-123` | `TChat` não cancela a assinatura de `TEventoAtualizacaoMensagem` | `Unsubscribe` no destrutor |
| A5b-25 | BAIXO | `chat.visualizador.pas:408-411`, `:418-425`, `:437-440` | `Mensagem[ID]`/`Visivel[ID]` lançam exceção para id ausente (indexador do dicionário); `Listar` devolve índices, não ids | `TryGetValue`; corrigir ou remover `Listar` |
| A5b-26 | BAIXO | `chat.conteudo.texto.pas:166-174` | Faixas de link deslocadas quando há `&`; links acumulam se o texto for atribuído duas vezes; o `TText` não permite selecionar parte do texto | Calcular sobre o texto exibido; limpar `Links`; componente que permita seleção |
| A5b-27 | BAIXO | `chat.so.pas:139` (`SHGetFileInfoA` com `AnsiString`) | Ícone de arquivo falha em nomes fora do ANSI | `SHGetFileInfoW` |
| A5b-28 | BAIXO | `chat.so.pas:60-122` | Seletor de emoji por `SendInput` de Win+. numa janela temporária com `Sleep`/`ProcessMessages`: frágil | Seletor próprio, ou chamar o painel sem a janela fantasma |
| A5b-29 | BAIXO | `Conversa.Chat.pas:204`; `chat.separador.data.pas:51` | Nome do remetente em todas as bolhas do grupo, inclusive nas próprias; separador sem dia da semana | Regras do web (MSG-02) |
| A5b-30 | BAIXO | `Conversa.Chat.pas:192-193`; `chat.visualizador.pas:130-135` | Restos de depuração (`Sleep(0)`) e um TODO "Inclusão Repetida" que esconde o problema A5b-01 | Remover depois de corrigir |
| A5b-31 | BAIXO | `src/Conversa.Proxy.Extras.pas` (fora do `.dpr`, token nunca definido, campos errados em `:287-288`, `:337-339`, `:363`, `:380`); `src/chat/Conversa.Conteudo.pas` (usa units `Mensagem.*` inexistentes, fora do `.dpr`); `src/chat/chat/frames/chat.anexo.item.pas` (classe `TChatAnexoItem` duplicada); `src/chat/chat/frames/__recovery/chat.editor.pas` | Código morto que parece funcionalidade pronta e induz a erro | Apagar ou corrigir e incluir; no mínimo, marcar como legado |
| A5b-32 | BAIXO | `Conversa.Proxy.pas:572-605` (`'conversa/dados'`, `:582`), chamado em `Conversa.Chat.pas:173-178` | A cada abertura de conversa, `GET /conversa/dados` → 404: a rota não existe no servidor atual (doc 01 §4) | Usar `GET /conversa/usuarios?conversa=` (área CON) |
| A5b-33 | BAIXO | `Conversa.Tipos.pas:854-856`; `Conversa.Dados.pas:216-217`, `:588`, `:609-610` | Contador de não lidas desconta mensagens já lidas ao carregar o histórico e soma em dobro com o valor de `/conversas` | Usar só `mensagens_sem_visualizar` do servidor e o resultado do `visualizar` (área CON/NOT) |
| A5b-34 | BAIXO | `Conversa.Chat.Listagem.pas:275-276` | `Exit` dentro do laço de conversas (deveria ser `Continue`): as conversas seguintes do mesmo lote não são notificadas nem atualizadas | `Continue` (área NOT) |

---

## 5. Dependências e observações para outros grupos

- **WebSocket** (`Conversa.Dados.pas:453-494`):
  - tipos 4, 5, 7, 61 e 62 não são tratados (cast para o enum sem os valores);
  - `tipo 0` levanta exceção na thread do socket (`:486-489`).
- **CON:**
  - `GET /conversa/dados` inexistente (A5b-32);
  - contador (A5b-33);
  - prévia "📷 Imagem/📦 Arquivo" sem os tipos 4–8.
- **NOT:**
  - `EventoExibirMensagens` da listagem (A5b-34) toca `nova_mensagem` a cada lote, inclusive com a conversa aberta e a janela sem foco;
  - notificação com textos só para tipos 1–3 (`Conversa.Chat.Listagem.pas:284-288`).
- **CHA:**
  - o resumo de chamada (tipo 6) depende do MSG-13;
  - o "Chat da chamada" completo (CHA-24) depende de todo este grupo.
- **Decisões de arquitetura** sugeridas para a reescrita do chat:
  1. modelo de mensagem com **todos** os campos do `MensagemResposta` (doc 01 §10.2);
  2. repositório com *upsert* por id e cursores corretos;
  3. lista virtualizada;
  4. serviço de anexos assíncrono com cache por identificador;
  5. player e gravador únicos (FFmpeg);
  6. menu de ações sobre o `lib/popupmenu`.

---

## 6. Arquivos lidos

| Área | Arquivos |
|---|---|
| Chat | `src/chat/Conversa.Chat.pas/.fmx`, `src/chat/Conversa.Chat.Listagem.pas` (partes de envio e exibição), `src/chat/Conversa.Conteudo.pas` (morto) |
| Lógica do chat | `src/chat/chat/chat.visualizador.pas`, `chat.ordenador.pas`, `chat.tipos.pas`, `chat.selectfile.pas`, `chat.so.pas`, `chat.emoji.pas` (só a lógica, `:1-30` e `:5060-5128`) |
| Frames | `src/chat/chat/frames/*.pas`, mais os `.fmx` de anexo, editor, separadores e mensagem |
| Mídia | `src/visualizadormidia/*.pas` |
| Dados e proxy | `Conversa.Dados.pas`, `src/Conversa.Proxy.pas`, `src/Conversa.Proxy.Tipos.pas`, `src/Conversa.Proxy.Extras.pas`, `src/Conversa.Tipos.pas`, `src/Conversa.Eventos.pas`, `src/Conversa.Evento.Base.pas`, `src/Conversa.Serializer.pas` (conversor de datas), `Conversa.Audio.pas`, `Conversa.dpr` |
| Servidor | `conversa/src/mensagens.ts:120-230` e `:315-375`, `conversa/src/rotas.ts:85-140`, `conversa/src/esquemas.ts:40-80` |
| Web | `conversa-web/src/utils/classificarMensagem.ts`, `conversa-web/src/utils/formatters.ts` (só emoji, links, tamanhos) e referências pontuais |
