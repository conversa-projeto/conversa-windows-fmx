# Cores do Conversa (fonte: este cliente Windows FMX)

> **Este app é a fonte de verdade visual do Conversa.** O app Android
> (`conversa-android-kotlin/docs/design/cores.md`) usa **estas** cores, e não as do cliente web.
> **Toda cor nova entra primeiro aqui** (hex, ARGB, papel e `arquivo:linha`), depois no código do
> FMX e só então no Android.

| | |
|---|---|
| Data | **2026-10-08** |
| HEAD conferido | `4759ba54547b7a6a73a4bf693663fd752439da2d` (`4759ba5`, branch `chamada`) |
| Origem deste texto | `conversa-android-kotlin/docs/design/cores.md` (levantamento de 2026-10-06, com acréscimos até 2026-10-08), reconferido nesta árvore |

Caminhos relativos a `conversa-windows-fmx/`, salvo indicação.

## 1. Fonte

| Item | Valor |
|---|---|
| Repositório | `C:\Users\danie\Desktop\GIT\conversa-projeto\conversa-windows-fmx` |
| HEAD analisado | `4759ba5` — "feat: Integra chamadas com WebRTC (audio + video) via MediaMTX" (2026-04-26) |
| Árvore de trabalho | `Conversa.Dados.pas` e `src/chamada/Conversa.Chamada.WebRTC.pas` **staged**, sem commit. Não há nenhuma alteração de cor no diff (`git diff --cached` sem `Color`, `cla…`, `$FF…` nem `TAlphaColor`). Fora do git: DLLs em `bin/`, `docs/historico/` e `docs/todo.md`. |
| Primeira análise | 2026-10-06 (pelo repositório Android) |
| Conferência desta versão | 2026-10-08 (§2.1) |
| Ignorado | `conversa-windows-fmx - Copia`, `__history`, `__recovery`, `Win32/Win64/Android64`, `*.dcu`, `bin/` (exceto `bin/tema`), `src/chat/chat/skia` (biblioteca Skia4Delphi), `lib/AES`, `lib/audio`, `lib/bird-socket-client`, `conversa-webrtc/` (app de teste separado), `teste/` |

No escopo: **59 `.fmx`** (41 com cor gravada, 230 linhas de cor) e **93 `.pas`** (12 com cor fixa, 44 linhas, sem contar o PSS).

### Mudanças recentes de cor (git log)

Últimos 15 commits: `4759ba5`, `ebe5cb9`, `784c989`, `3d57153`, `50724b7`, `bb6c031`, `e7aed82`, `3b73c9d`, `f2442c7`, `a084ef2`, `5936215`, `34ae54b`, `2ceca9f`, `bfd9d9a`, `1baab7d`.

- **`ebe5cb9` (2026-02-03) "Padroniza design visual do item de chamada"**: a única mudança de cor recente.
  - O item da lista de chamadas passou de `claWhite` para `claWhitesmoke`.
  - O hover passou de `White→#E6E6E6` para `Whitesmoke→White`, "alinhando com o padrão de Contatos e Novo Grupo".
  - Isso indica o **padrão atual dos itens de listagem secundária**: fundo `#F5F5F5` com hover `#FFFFFF`.
- `3d57153` (2026-02-02) criou as telas de histórico e detalhe de chamada (cores `#333333/#666666/#999999`, `#00C853`, `#FF5252`).
- `bin/tema/*.pss` e `src/pss/PascalStyleScript.pas` não mudam de cor desde 2024.
  - Último commit relevante: `7327be8` (2024-08-29) "PSS - Correção de Warning", que pôs o `Exit` em `RegisterObject`.
  - `2fed0f5` (2025-10-13) mexeu no PSS só para comentar três variáveis sem uso (`PascalStyleScript.pas:287-289`). Não mexe em cor.

## 2. Método

1. Listagem de todos os `.fmx` e `.pas` do app (fora das pastas ignoradas).
2. Extração por script de toda linha `Fill.Color`, `Stroke.Color`, `TextSettings.FontColor`, `StartValue/StopValue` de `TColorAnimation` e `ShadowColor`, com o nome e a classe do componente dono e o `arquivo:linha`.
3. Busca em `.pas` por `$FFxxxxxx`, `TAlphaColors.*`, `TAlphaColorF.Create`, `MakeColor` e `claXxx`.
4. Busca de **shapes sem `Fill.Color` gravado**. No FMX o valor padrão não é salvo no `.fmx`.
   - Padrão de `TShape` (`TRectangle`, `TCircle`, `TPath`): **Fill `$FFE0E0E0`**, Stroke `$FF000000`.
   - Padrão de `TText.TextSettings.FontColor`: **`claBlack`**.
   - Esses defaults contam como cor efetiva (marcados "default FMX").
5. Leitura do sistema de tema `PascalStyleScript` (`src/pss/PascalStyleScript.pas`) e dos arquivos `bin/tema/{default,claro,escuro}.pss`.
6. Nomes `claXxx` convertidos com os valores de `System.UITypes` (`TAlphaColorRec`).
7. Conversão: o FMX usa `AARRGGBB` (`xFF007DFF` no `.fmx`, `$FF007DFF` no `.pas`) → `#RRGGBB`. Alfa diferente de `FF` é anotado.
   - Em Delphi o token fica `TAlphaColor($FF007DFF)`; no Android (Compose), `Color(0xFF007DFF)`. A ordem dos bytes é a mesma.

Não existem `.style`, `.fsf`, `.vsf`, `TStyleBook` nem estilos embutidos com cor. Os `StyleLookup` usados são os do estilo padrão da plataforma (§6.5). `res/` só contém `nova_mensagem.wav`. README e docs não descrevem cores.

### 2.1 Conferência desta versão (2026-10-08)

- **157 linhas conferidas** com script (cada `arquivo:linha` desta §4 contra a cor esperada): 155 linhas de **51 cores diferentes** (todas as citadas na §4) e as 2 linhas do PSS. Resultado: **157 OK, 0 falhas**.
- **14 shapes "default FMX"** conferidos: continuam sem `Fill.Color` gravado (`Conversa.Login.fmx:18,45`, `chat.editor.fmx:13`, `Conversa.Chamada.view.fmx:7,16`, `chat.separador.data.fmx:5`, `chat.ultima.fmx:5`, `Conversa.Principal.fmx:18,69,144,212,304`, `Conversa.Chamada.Usuario.view.fmx:46`).
- **Contagens refeitas** para `#007DFF` (22), `#007FFF` (7), `#F5F5F5` (41), `#C8C8C8` (4), `#E6E6E6` (3), `#141414` (4), `#646464` (4), `#808080` (8) e `#333333` (7): todas batem.
- **Varredura completa**: toda cor que aparece nos `.fmx` e `.pas` do escopo está na §4. Nenhuma cor nova desde a primeira análise.
- **Correções em relação ao texto do Android:**
  1. `#545454` (`chat.editor.texto.fmx:161`) é o **placeholder "Mensagem"** (`txtMensagem: TText`), visível só com o campo vazio (`chat.editor.texto.pas:111`). Não é o texto digitado.
     - O texto digitado (`mmMensagem: TMemo`) usa a cor do estilo padrão da plataforma (§6.5).
  2. `#FF0000`: faltavam `src/visualizadormidia/Conversa.Visualizador.Midia.pas:144` (hover do fechar do visualizador) e `chat.editor.audio.fmx:176` (`StopValue` da animação de gravação).
  3. `#FFFFFF` e `#000000`: as contagens do Android eram só de `.fmx`. Agora os `.pas` aparecem separados.
  4. O PSS não está 100% inerte: `default.pss` **é lido** na partida (só não é aplicado). Ver "Achado importante" abaixo.
  5. Contraste de preto sobre `#CFE7FF`: ~16,5:1 (o texto anterior dizia ~17:1).

### Achado importante: o tema PSS está DESLIGADO

- `TPascalStyleScript.RegisterObject` começa com `Result := Self; Exit;` (`src/pss/PascalStyleScript.pas:521-522`). Nenhum objeto é registrado e nada é aplicado.
- `LoadFromFile` (que carregaria `claro.pss`/`escuro.pss`) **não é chamado em lugar nenhum**. `claro.pss` e `escuro.pss` não são citados em nenhum `.pas`, `.dpr`, `.dproj` ou `.fmx`.
- Logo, **as cores reais são as dos `.fmx` + `.pas`**. Detalhes do motor em §6.3.
- Os `.pss` são histórico (nov/2024), mas úteis:
  - `default.pss` é um *snapshot* das cores de runtime da época (confirma, por exemplo, `#E0E0E0` nos campos de login: `Login.rctFundo.lytCenter.rctUsuario`/`rctSenha`);
  - `escuro.pss` é a **única pista de um modo escuro** pretendido.

| Token PSS | `claro.pss` | `escuro.pss` | `default.pss` |
|---|---|---|---|
| `fundo` | `#F0F0F0` | `#323232` | `#F0F0F0` |
| `fundo_claro_1` | `#FAFAFA` | `#3C3C3C` | `#FAFAFA` |
| `fundo_escuro` | `#F0F0F0` | `#282828` | `#C8C8C8` |
| `primaria` | `#007FFF` | `#007FFF` | `#007FFF` |
| `primaria_clara` | `#007FFF` α `0x50` (31%) | idem | idem |

**Conclusão: o FMX não tem modo escuro ativo.** O esquema escuro da §7 é **PROPOSTA** derivada de `escuro.pss`.

## 3. Valores dos nomes `claXxx` usados

| Nome FMX | ARGB | Hex |
|---|---|---|
| `claWhite` | `$FFFFFFFF` | `#FFFFFF` |
| `claWhitesmoke` | `$FFF5F5F5` | `#F5F5F5` |
| `claSnow` | `$FFFFFAFA` | `#FFFAFA` |
| `claGainsboro` | `$FFDCDCDC` | `#DCDCDC` |
| `claLightgray` | `$FFD3D3D3` | `#D3D3D3` |
| `claSilver` | `$FFC0C0C0` | `#C0C0C0` |
| `claGray` | `$FF808080` | `#808080` |
| `claDimgray` | `$FF696969` | `#696969` |
| `claBlack` | `$FF000000` | `#000000` |
| `claNull` | `$00000000` | transparente |
| `claRed` | `$FFFF0000` | `#FF0000` |
| `claLightcoral` | `$FFF08080` | `#F08080` |
| `claGreen` | `$FF008000` | `#008000` |
| `claLime` | `$FF00FF00` | `#00FF00` |
| `claBlue` | `$FF0000FF` | `#0000FF` |
| `claLightblue` | `$FFADD8E6` | `#ADD8E6` |
| `claLightsteelblue` | `$FFB0C4DE` | `#B0C4DE` |

## 4. Paleta completa

Ocorrências = declarações explícitas em `.fmx` (inclusive `TColorAnimation` e `ShadowColor`) + atribuições em `.pas`. "+N default" = shapes e textos sem cor gravada, que herdam o default do FMX.

### 4.1 Paleta principal (uso recorrente)

| Hex | ARGB original | Papel | Onde (evidência) | Ocorr. |
|---|---|---|---|---|
| `#007DFF` | `xFF007DFF` / `$FF007DFF` | **Primária / marca**: ícones de ação, badge de não lidas, letra do avatar, "visualizada", botão primário | `chat.editor.fmx:53` pthEnviar, `:98` pthMicrofone; `chat.editor.texto.fmx:59` pthEmoji, `:106` pthAnexo; `chat.editor.audio.fmx:74,139,164`; `Conversa.Chat.Listagem.Item.fmx:92` rctCount (badge), `:45` txtAbreviatura; `Conversa.Principal.fmx:322` txtUserLetra; `Conversa.Chamada.Detalhe.fmx:209` rctBtnChamar, `:31` crclIcone; `chat.mensagem.pas:165` (check azul "visualizada"); `chat.editor.audio.pas:206`; `Conversa.Chamada.Detalhe.pas:130`; avatares em Contatos/Novo Grupo/Chamadas | 22 (19 `.fmx` + 3 `.pas`) |
| `#007FFF` | `xFF007FFF` | **Primária (variante)**: praticamente idêntica a `#007DFF` (diferença de 2 no canal G, imperceptível). Usada em telas mais antigas e no PSS (`primaria`) | `Conversa.Login.fmx:84` rctBotaoEntrar; `Conversa.Notificacao.Item*.fmx` rctFundo (×3); `Conversa.Conexao.AvisoInicioSistema.fmx:106`, `Conversa.Configurar.Conexao.fmx:142`, `Novo.Grupo.fmx:113` (texto dos botões "Salvar"/"Configurações") | 7 (+PSS) |
| `#FFFFFF` | `claWhite` / `TAlphaColors.White` | Superfície: lista de conversas, item de conversa, cards/diálogos, texto/ícone sobre primária | `Conversa.Chat.Listagem.fmx:22` rctListaConversas; `Conversa.Chat.Listagem.Item.fmx:6` rctFundo, `:109` txtCount; `Conversa.Conteudo.fmx:13` rctTitulo; `Conversa.Configurar.Conexao.fmx:13` rctCenter; `Conversa.Conexao.AvisoInicioSistema.fmx:13`; `Conversa.Chamada.view.fmx:33,176` botões redondos; textos sobre azul (`txtBotaoEntrar`, `txtCount`, `txtBtnChamar`, notificações: `Conversa.Notificacao.Item.pas:141,152`, `.Mensagem.pas:142,153`); `Conversa.Chat.Listagem.Item.pas:128` (item não selecionado) | 48 `.fmx` + 10 `.pas` |
| `#F5F5F5` | `claWhitesmoke` | **Fundo do app** (forms/telas), fundo do editor de mensagem, fundo do avatar, botões secundários, campos | `src/base/Conversa.FormularioBase.fmx:7,16` (form base); `Conversa.Login.fmx:6`; `Conversa.Chat.fmx:6`, `Conversa.Chat.Listagem.fmx:13`; `chat.editor.fmx:8` rtgFundo; `crclFoto` em todos os itens; `rctBotaoCancelar/Salvar`; itens de Contatos/Novo Grupo/Chamadas (`ebe5cb9`); `Conversa.Configurar.Conexao.pas:90` (fim do hover) | 41 (+1 `.pas`) |
| `#000000` | `claBlack` / `TAlphaColors.Black` (+ default FMX de `TText`) | Texto da bolha, ícones neutros (menu lateral, mic/vídeo na chamada), loading, "X" da barra de título | `Conversa.Principal.fmx:61,135,203,277` ícones do menu; `Conversa.Chamada.view.fmx:71,111,204,232`; `Conversa.Chamada.Usuario.view.fmx:76`; `Conversa.Loading.Pontos.frame.fmx:16,35,56`; `chat.conteudo.mensagem.audio.fmx:15` crclAction; `PopupMenu.fmx:32` sombra; `PopupMenu.Item.fmx:42`; `Conversa.FormularioBase.pas:352-353` e `Conversa.Visualizador.Midia.pas:149-150` (X do fechar) | 15 `.fmx` + 4 `.pas` (+todos os TText sem cor) |
| `#E0E0E0` | `xFFE0E0E0` + default `TShape` | Campo de entrada (login, editor), barra inferior da chamada, separador de data, "ir para última", botão secundário cinza, botões do menu lateral | `Conversa.Chamada.Detalhe.fmx:186` rctBtnVoltar (explícito); default: `Conversa.Login.fmx:18,45` rctUsuario/rctSenha, `chat.editor.fmx:13` rtgEditor, `Conversa.Chamada.view.fmx:16` rtgBarraInferior, `chat.separador.data.fmx:5`, `chat.ultima.fmx:5`, `Conversa.Principal.fmx:18,69,144,212,304`; `default.pss` confirma `#FFE0E0E0` | 1 (+~14 default) |
| `#C8C8C8` | `xFFC8C8C8` | Barra de título da janela e **menu lateral** (rail de navegação) | `src/base/Conversa.FormularioBase.fmx:39` rctTitleBar, `:136`; `Conversa.Principal.fmx:13` rctMenuLateral; `Conversa.Visualizador.Midia.fmx:173` | 4 |
| `#CFE7FF` | `$FFCFE7FF` | **Bolha da própria mensagem** (lado direito) | `src/chat/chat/frames/chat.mensagem.pas:101` (`CorFundo`, `TLado.Direito`) | 1 |
| `#EDEDED` | `$FFEDEDED` | **Bolha da mensagem do outro** (lado esquerdo) | `src/chat/chat/frames/chat.mensagem.pas:102` (`TLado.Esquerdo`) | 1 |
| `#E3F1FF` | `$FFE3F1FF` | **Conversa selecionada** na lista | `src/chat/Conversa.Chat.Listagem.Item.pas:126` (`Selecionado`) | 1 |
| `#E6E6E6` | `xFFE6E6E6` | Hover/pressionado de item (conversa, participante, usuário) | `Conversa.Chat.Listagem.Item.fmx:131` (`ColorAnimation1`, `White→#E6E6E6`, disparada em `.pas:107-118`); `Conversa.Chamada.Participante.Item.fmx:87`; `Conversa.Chamada.Usuarios.Listagem.Item.fmx:87` | 3 |
| `#141414` | `xFF141414` | **Texto primário** (nome na lista) | `Conversa.Chat.Listagem.Item.fmx:66` lblNome; `Conversa.Contatos.Listagem.Item.fmx:65`; `Novo.Grupo.Usuario.Item.fmx:66`; `Conversa.Chamada.Listagem.Item.fmx:244` | 4 |
| `#646464` | `xFF646464` | **Texto secundário** (prévia da última mensagem, status) | `Conversa.Chat.Listagem.Item.fmx:85` txtMensagem; `Conversa.Chamada.Listagem.Item.fmx:261`; `Conversa.Chamada.Participante.Item.fmx:66`; `Conversa.Chamada.Usuarios.Listagem.Item.fmx:66` | 4 |
| `#808080` | `claGray` / `TAlphaColors.Gray` | Ícones/texto discretos: status pendente/recebida (✓/✓✓ cinza), "digitando…", ícone iniciar chamada | `chat.mensagem.fmx:66`, `chat.mensagem.pas:147,156`; `Conversa.Chat.fmx:170` pthIniciarChamada, `:212` txtNomeDigitando; `Conversa.Conteudo.fmx:149`; `Conversa.Notificacao.Item.Chamada.fmx:66,154` | 8 |
| `#FF0000` | `claRed` / `TAlphaColors.Red` | Perigo genérico: hover do botão fechar janela, gravando áudio, alertas de mic/vídeo, ícone de erro de conexão, chamada recusada | `Conversa.FormularioBase.pas:347`; `Conversa.Visualizador.Midia.pas:144`; `chat.editor.audio.fmx:176` (animação), `:190`, `.pas:173`; `Conversa.Chamada.view.fmx:164,283`; `Conversa.Conexao.AvisoInicioSistema.fmx:154,160`; `Conversa.Chamada.BarraTitulo.fmx:59,228`; `Conversa.Chamada.Listagem.Item.fmx:218` | 12 (+1 bandeja, §4.3) |
| `#333333` | `xFF333333` | Texto de título/valor (telas novas: Detalhe de chamada, Sobre) | `Conversa.Chamada.Detalhe.fmx:63,103,126,149,172,203`; `Conversa.Sobre.fmx:27` | 7 |

### 4.2 Cores de apoio e pontuais

| Hex | ARGB original | Papel | Onde | Ocorr. |
|---|---|---|---|---|
| `#F0F0F0` | `xFFF0F0F0` | Cabeçalho (toolbar) da conversa aberta | `src/chat/Conversa.Chat.fmx:13` rctTitulo | 1 (+PSS `fundo`) |
| `#FAFAFA` | só PSS | `fundo_claro_1` (lista de conversas em 2024). **Não é usado hoje** (a lista é `#FFFFFF`) | `bin/tema/claro.pss:10` | 0 |
| `#DCDCDC` | `claGainsboro` | Borda do popup menu, borda do avatar no painel de conteúdo | `lib/popupmenu/PopupMenu.fmx:17`; `Conversa.Conteudo.fmx:41` | 2 |
| `#DBDBDB` | `xFFDBDBDB` | Divisor (linhas) | `src/novo/grupo/Novo.Grupo.fmx:191,202` | 2 |
| `#000000` α `0x32` (20%) | `x32000000` | Divisor vertical lista/conversa | `src/chat/Conversa.Chat.Listagem.fmx:2527` lnSeparador | 1 |
| `#999999` | `xFF999999` | Rótulos (label) na tela de detalhe | `Conversa.Chamada.Detalhe.fmx:92,115,138,161` | 4 |
| `#9E9E9E` | `xFF9E9E9E` | Duração / data-hora (terciário) no item de chamada | `Conversa.Chamada.Listagem.Item.fmx:276,291` | 2 |
| `#666666` | `xFF666666` | Texto secundário (Detalhe, Sobre) | `Conversa.Chamada.Detalhe.fmx:74`; `Conversa.Sobre.fmx:37,47` | 3 |
| `#545454` | `xFF545454` | **Placeholder "Mensagem"** do editor (corrigido em 2026-10-08: não é o texto digitado) | `chat.editor.texto.fmx:161` txtMensagem (`TText`, some quando há texto: `chat.editor.texto.pas:111`) | 1 |
| `#4B4B4B` | `xFF4B4B4B` | Ícone "remover anexo" | `chat.anexo.item.fmx:111`; `chat.editor.anexo.item.fmx:110` | 2 |
| `#696969` | `claDimgray` | Nome no painel de conteúdo | `Conversa.Conteudo.fmx:137` | 1 |
| `#C0C0C0` | `claSilver` | Ícone "ir para última mensagem" | `chat.ultima.fmx:24` | 1 |
| `#B0C4DE` | `claLightsteelblue` | Separador "mensagens não lidas"; fundo dos botões de gravação de áudio | `chat.separador.lidas.fmx:7`; `chat.editor.audio.fmx:31,95` | 3 |
| `#FFFAFA` | `claSnow` | Item do popup menu (o hover anima `#FFFFFF→#F5F5F5`) | `lib/popupmenu/PopupMenu.Item.fmx:5,18-19` | 1 |
| `#E6F2FF` | `MakeColor(230,242,255)` | Hover do botão "Salvar" (configuração de conexão) | `src/configuracoes/Conversa.Configurar.Conexao.pas:85` | 1 |
| `#0000EE` | `TAlphaColorF(0,0,238/255)` | **Link** em mensagem | `chat.conteudo.texto.pas:172` | 1 |
| `#551A8B` | `TAlphaColorF(85,26,139)/255` | Link depois do clique (visitado) | `chat.conteudo.texto.pas:106` | 1 |
| `#000000` α 50% | `txtHora.Opacity = 0.5` | **Hora dentro da bolha** (texto preto com opacidade 0,5) | `chat.mensagem.fmx:50,53` txtHora (Opacity 0,5, fonte 10) | 1 |
| `#FFFFFF` α ~10% | `TAlphaColorF.Create(255,255,255,0.1)` | Hover de maximizar/minimizar da barra de título. Resultado provável com clamp do RGB em 1,0: `#1AFFFFFF` (incerto) | `Conversa.FormularioBase.pas:364,379`; `Conversa.Visualizador.Midia.pas:156,172` | 4 |
| `#000000` α `0x64` (39%) | `x64000000` | Scrim de modal | `src/principal/Conversa.ModalView.fmx:7` | 1 |
| `#000000` α `0xC8` (78%) | `xC8000000` | Fundo do visualizador de mídia | `src/visualizadormidia/Conversa.Visualizador.Midia.fmx:5` | 1 |
| `#F08080` | `claLightcoral` | Faixa de aviso "sem conexão" (texto branco) | `Conversa.Tela.Inicial.view.fmx:2471` rctAvisoConexao | 1 |
| `#00FF00` | `claLime` | Check de seleção de usuário (Novo Grupo) | `Novo.Grupo.Usuario.Item.fmx:97` | 1 |
| `#0000FF` | `claBlue` | Ícone "chamada realizada" (lista/barra); cor inicial da animação de loading | `Conversa.Chamada.Listagem.Item.fmx:150`; `Conversa.Chamada.BarraTitulo.fmx:160`; `Conversa.Loading.Pontos.frame.fmx:29,50,71` | 5 |

### 4.3 Chamadas e notificações

| Hex | ARGB original | Papel | Onde | Ocorr. |
|---|---|---|---|---|
| `#F5F5F5` + `#E0E0E0` | herdado / default | A tela de chamada é **clara**: fundo do form base `#F5F5F5`, barra inferior `#E0E0E0`, avatar do participante `#E0E0E0` com ícone preto | `Conversa.Chamada.view.fmx:7,16`; `Conversa.Chamada.Usuario.view.fmx:46,76` | — |
| `#FFFFFF` / `#000000` | `claWhite` / `claBlack` | Botões redondos mic/vídeo: fundo branco, ícone preto | `Conversa.Chamada.view.fmx:33,71,111,176,204,232` | 6 |
| `#D44242` | `xFFD44242` | **Encerrar chamada** (círculo), ícone branco | `Conversa.Chamada.view.fmx:295` | 1 |
| `#008000` | `claGreen` | **Atender chamada** (círculo, tela de chamada); ícones atender/recebida | `Conversa.Chamada.view.fmx:348`; `Conversa.Chamada.BarraTitulo.fmx:130,176`; `Conversa.Chamada.Listagem.Item.fmx:166` | 4 |
| `#85FF85` | `xFF85FF85` | Barra de título "em chamada" (faixa verde) | `src/chamada/Conversa.Chamada.BarraTitulo.fmx:6` | 1 |
| `#00D26A` | `$FF00D26A` | Waveform de áudio | `src/chamada/Conversa.Chamada.Waveform.pas:45` | 1 |
| `#00C853` | `$FF00C853` | Ícone "recebida" na tela de **detalhe** | `Conversa.Chamada.Detalhe.pas:135` | 1 |
| `#FF5252` | `$FFFF5252` | Ícone "perdida/recusada" na tela de **detalhe** | `Conversa.Chamada.Detalhe.pas:139` | 1 |
| `#007FFF` | `xFF007FFF` | Fundo do toast de notificação (mensagem e chamada) | `Conversa.Notificacao.Item.fmx:8`, `.Mensagem.fmx:4`, `.Chamada.fmx:4` | 3 |
| `#1B8DFF` | `xFF1B8DFF` | Avatar no toast de mensagem | `Conversa.Notificacao.Item.fmx:100`; `.Mensagem.fmx:96` | 2 |
| `#ADD8E6` | `claLightblue` | Hora no toast | `Conversa.Notificacao.Item.fmx:155`; `.Mensagem.fmx:151` | 2 |
| `#D3D3D3` | `claLightgray` | Tipo de chamada no toast | `Conversa.Notificacao.Item.Chamada.fmx:142` | 1 |
| `#4CAF50` | `xFF4CAF50` | Avatar no toast de chamada | `Conversa.Notificacao.Item.Chamada.fmx:93` | 1 |
| `#E53935` | `xFFE53935` | Botão **Recusar** (toast de chamada) | `Conversa.Notificacao.Item.Chamada.fmx:170` | 1 |
| `#43A047` | `xFF43A047` | Botão **Atender** (toast de chamada) | `Conversa.Notificacao.Item.Chamada.fmx:193` | 1 |
| `#FF0000` / `#FFFFFF` | `TAlphaColors` | Ícone da bandeja (contador sobreposto) | `lib/windows/Conversa.Windows.Overlay.pas:111,120` | 2 |

### 4.4 Papéis sem equivalente no FMX

- **Indicador online:** não existe cor de presença no FMX (nenhum componente "online"). O Android usa `#43A047` provisório (§9, pergunta 1).
- **Modo escuro:** só `bin/tema/escuro.pss`, inativo.
- **Botão danger com texto:** não existe botão vermelho com texto além de "Recusar" (`#E53935`).
- **Destaque de código e Markdown:** o FMX não renderiza blocos de código nem Markdown. Os papéis usados no Android estão na §7.6.

## 5. Contraste (WCAG): atenção

| Combinação | Razão | Observação |
|---|---|---|
| `#FFFFFF` sobre `#007DFF` | 3,9:1 | Passa só para texto grande e ícones (≥3:1). O FMX usa assim (badge, botões). Manter, mas evitar texto pequeno branco em `#007DFF`. |
| `#FFFFFF` sobre `#007FFF` (toast) | 3,8:1 | Idem. |
| `#000000` sobre `#CFE7FF` | 16,5:1 | OK |
| `#000000` sobre `#EDEDED` | 17,9:1 | OK |
| `#141414` sobre `#FFFFFF` | 18,4:1 | OK |
| `#646464` sobre `#FFFFFF` | 5,9:1 | OK |
| `#333333` sobre `#F5F5F5` | 11,6:1 | OK |
| `#666666` sobre `#F5F5F5` | 5,3:1 | OK |
| `#545454` sobre `#E0E0E0` (placeholder) | 5,7:1 | OK |
| `#FFFFFF` sobre `#D44242` | 4,5:1 | OK (no limite) |
| `#FFFFFF` sobre `#E53935` | 4,2:1 | Só texto grande/negrito ("Recusar"). |
| `#FFFFFF` sobre `#43A047` | 3,3:1 | Só texto grande/negrito ("Atender"). |
| `#FFFFFF` sobre `#F08080` | 2,6:1 | **Reprova.** Faixa "sem conexão". Proposta: texto `#410002` (§7.2, `TextoAvisoConexao`). |
| `#ADD8E6` sobre `#007FFF` (hora no toast) | 2,5:1 | **Reprova** para texto pequeno. *Acrescentado em 2026-10-08.* |
| `#D3D3D3` sobre `#007FFF` (tipo no toast) | 2,6:1 | **Reprova** para texto pequeno. *Acrescentado em 2026-10-08.* |
| `#808080` sobre `#F0F0F0` ("digitando…" no cabeçalho) | 3,5:1 | Reprova para texto pequeno (precisa 4,5:1). *Acrescentado em 2026-10-08.* |
| `#9E9E9E` sobre `#F5F5F5` (duração/data no item de chamada) | 2,5:1 | **Reprova.** O Android usa `textoTerciario` em 17 lugares. *Acrescentado em 2026-10-08.* |
| `#999999` sobre `#F5F5F5` (rótulos do detalhe) | 2,6:1 | **Reprova.** *Acrescentado em 2026-10-08.* |

Os cinzas terciários (`#9E9E9E`, `#999999`) e o `#808080` em texto pequeno ficam abaixo do mínimo. Ver §9, pergunta 17.

## 6. Como as cores são aplicadas hoje no FMX

Resumo: **não há tema**. Cada cor está gravada no `.fmx` da tela ou atribuída no `.pas`, sem nome de papel. O motor de tema (PSS) existe, mas está desligado. Uma parte das cores efetivas nem está escrita: vem dos defaults do FMX.

### 6.1 Cores gravadas nos `.fmx` (a maioria)

- **230 linhas de cor em 41 dos 59 `.fmx`** do app: `Fill.Color`, `Stroke.Color`, `TextSettings.FontColor`, `ShadowColor` e `StartValue/StopValue` de `TColorAnimation`.
- Os valores aparecem de três jeitos: nome (`claWhitesmoke`), hex (`xFF007DFF`) ou animação (`ColorAnimation1: White→#E6E6E6`, `Conversa.Chat.Listagem.Item.fmx:125-132`).
- A mesma cor de papel se repete em muitos arquivos. `claWhite` aparece 48 vezes e `claWhitesmoke` 41.
- Variantes quase iguais convivem: `#007DFF`/`#007FFF`, `#DBDBDB`/`#DCDCDC`, `#E3F1FF`/`#E6F2FF`, `#646464`/`#666666`/`#696969`, `#999999`/`#9E9E9E`.
- Os frames herdam de `TFrameBase` (`src/base/Conversa.FrameBase.pas`) e os forms de `TFormularioBase` (`src/base/Conversa.FormularioBase.pas`). As cores do form base (fundo `#F5F5F5` e barra de título `#C8C8C8`) vêm de `Conversa.FormularioBase.fmx:7,16,39,136` e são herdadas (`inherited rctFundo`).

### 6.2 Cores fixas no código (`.pas`)

44 linhas em 12 units. Nenhuma passa pelo PSS:

| Unit | Linhas | O que faz | Cores |
|---|---|---|---|
| `src/chat/Conversa.Chat.Listagem.Item.pas` | 125-128 | Conversa selecionada / não selecionada | `$FFE3F1FF` / `TAlphaColors.White` |
| `src/base/Conversa.FormularioBase.pas` | 343-355 | Hover do botão fechar: fundo vermelho e X branco; ao sair, X preto e fundo transparente | `TAlphaColors.Red/White/Black`, `TAlphaColorF(255,255,255,0)` |
| `src/base/Conversa.FormularioBase.pas` | 362-385 | Hover de maximizar/minimizar | `TAlphaColorF(255,255,255,0.1)` / transparente |
| `src/visualizadormidia/Conversa.Visualizador.Midia.pas` | 140-178 | Mesma barra de título, duplicada no visualizador | idem |
| `src/chat/chat/frames/chat.mensagem.pas` | 98-104, 147, 156, 165 | Fundo da bolha por lado; cor do ✓/✓✓ por status | `$FFCFE7FF`, `$FFEDEDED`, `TAlphaColors.Gray`, `$FF007DFF` |
| `src/chat/chat/frames/chat.editor.audio.pas` | 173, 206 | Microfone gravando / parado | `TAlphaColors.Red` / `$FF007DFF` |
| `src/chat/chat/frames/chat.conteudo.texto.pas` | 106, 172 | Link e link visitado | `TAlphaColorF` → `#0000EE`, `#551A8B` |
| `src/chamada/Conversa.Chamada.Detalhe.pas` | 124-141 | Ícone realizada/recebida/perdida | `$FF007DFF`, `$FF00C853`, `$FFFF5252` |
| `src/chamada/Conversa.Chamada.Waveform.pas` | 45 | Cor da waveform | `$FF00D26A` |
| `src/configuracoes/Conversa.Configurar.Conexao.pas` | 83-91 | Hover do "Salvar" | `MakeColor(230,242,255)` / `TAlphaColors.Whitesmoke` |
| `src/notificacao/Conversa.Notificacao.Item.pas`, `.Item.Mensagem.pas` | 141-153 / 142-154 | Texto do toast (layout e negrito) | `TAlphaColors.White` |
| `lib/windows/Conversa.Windows.Overlay.pas` | 107-120 | Ícone da bandeja desenhado no canvas | `TAlphaColors.Red/White/Null` |

### 6.3 O motor PSS (`src/pss/PascalStyleScript.pas`)

**Como funcionaria:**

- `TPascalStyleScript` guarda um JSON com `tema.cores` (nome → cor) e `schema` (id do componente → propriedade → valor).
  - O id é o **caminho do componente**, por exemplo `Login.rctFundo.lytCenter.rctUsuario`.
  - O valor pode citar um token: `@cores.fundo`.
- Cada form e frame se registra no construtor: `Conversa.FormularioBase.pas:318` e `Conversa.FrameBase.pas:40` (`RegisterObject(Self, GetPSSClassName)`).
- Ao aplicar, o motor percorre os filhos e anima cada cor até o valor do tema (`TAnimator.AnimateColor`, 0,25 s, linha 336).
- Só cobre `TBrush.Color`, `TStrokeBrush.Color/Kind` e `TTextSettings.FontColor/Font` (registro nas linhas 187-190).

**O que acontece hoje:**

| Passo | Onde | Efeito |
|---|---|---|
| `TPascalStyleScript.Start` | `Conversa.Inicializacoes.pas:37` | Cria a instância na partida, antes de `Application.Initialize`. |
| `Create` → `LoadDefault` | `PascalStyleScript.pas:183, 199-202` | **Lê** `.\tema\default.pss` (constante na linha 148). O diretório atual é a pasta do exe (`DefinirDiretorio`, `lib/windows/Conversa.Windows.Utils.pas:200-203`), então o arquivo lido é `bin/tema/default.pss`. |
| Arquivo ausente | `PascalStyleScript.pas:601-602` | `raise Exception.Create('Arquivo de tema não encontrado!')`. **Sem `bin/tema/default.pss` o app não inicia**, mesmo sem usar nada dele. |
| `RegisterObject` | `PascalStyleScript.pas:521-522` | `Result := Self; Exit;`: não registra nem aplica nada (desde `7327be8`, 2024-08-29). |
| `LoadFromFile` | `PascalStyleScript.pas:204-207` | Nunca é chamado. `claro.pss` e `escuro.pss` nunca são lidos. |
| `InternalApply` / `SaveDefault` | `PascalStyleScript.pas:422-433, 632-635` | Nunca rodam, porque só são alcançados por `LoadFromFile` e `RegisterObject`. Se rodassem, **regravariam** `default.pss` em `bin/tema`. |

### 6.4 Cores fixas que ignoram o PSS

Mesmo que o PSS fosse religado, estas cores continuariam fora dele:

- **Toda atribuição em `.pas`** (§6.2). O PSS só aplica na criação, e o código sobrescreve depois. Exemplos:
  - `src/chat/Conversa.Chat.Listagem.Item.pas:126-128`: seleção `$FFE3F1FF` / `White`;
  - `src/base/Conversa.FormularioBase.pas:343-355`: hover do fechar `Red/White/Black`;
  - `chat.mensagem.pas:101-102`: cores das bolhas.
- **Animações de hover** gravadas no `.fmx` (`TColorAnimation.StartValue/StopValue`: `Conversa.Chat.Listagem.Item.fmx:130-131`, `PopupMenu.Item.fmx:18-19`, `chat.editor.audio.fmx:176`, `Conversa.Loading.Pontos.frame.fmx:29,50,71`). O PSS não registra `TColorAnimation`.
- **`ShadowColor`** (`PopupMenu.fmx:32`), **atributos de texto** (`TTextAttribute` nas notificações e nos links) e **desenho em canvas** (bandeja, waveform).
- **Componentes sem `Name`**: o PSS pula filhos sem nome (linhas 410 e 564).

### 6.5 Defaults do FMX que contam como cor efetiva

- **`TShape` sem `Fill.Color` gravado** → `#E0E0E0`. Exemplos: campos do login, editor, barra inferior da chamada, separador de data, "ir para última", botões do menu lateral e avatar do participante (lista conferida na §2.1).
  - Stroke padrão `#000000` quando não há `Stroke.Kind = None` (por exemplo, `chat.ultima.fmx:5` `rtgUltima`).
- **`TText` sem `FontColor`** → `#000000`. É o texto das bolhas e de vários rótulos.
- **Controles com estilo da plataforma** (o app não tem `TStyleBook`): a cor do texto, a seleção, o cursor e a barra de rolagem vêm do estilo padrão do FMX no Windows.
  - `TEdit` com `StyleLookup = 'transparentedit'`: `Conversa.Login.fmx:30,58`, `Conversa.Configurar.Conexao.fmx:62`.
  - `TMemo mmMensagem`: o fundo do estilo é removido em `chat.editor.texto.pas:82-84`; o texto digitado fica com a cor do estilo.
  - `TListBox` com `'transparentlistboxstyle'` (×5) e `'scrollboxstyle'` (`ImageViewerFrame.fmx:17`).
  - Não foi verificado em execução (§9, pergunta 7).

### 6.6 Consequências

- Trocar uma cor de papel (por exemplo, a primária) exige editar dezenas de `.fmx` e `.pas`.
- Variantes quase iguais (§6.1) nasceram dessa dispersão.
- Um modo escuro é inviável sem antes centralizar: hoje teria que ser feito tela por tela.
- O PSS cria uma dependência de arquivo na partida (`default.pss`) sem entregar nada.

## 7. Proposta para centralizar

Vale para a evolução deste cliente ou para uma nova base FMX. **Nada disto está implementado.**

### 7.1 Unit de tokens `Conversa.Cores.pas`

- **Uma unit só** com todas as cores, nomeadas pelo **papel** (não pela cor): `BolhaPropria`, não `AzulClaro`.
- **Mesmos papéis do Android.** O Android tem `ConversaCores` + `MaterialTheme.colorScheme` (`core/ui/.../tema/Cores.kt`); aqui ficam em PascalCase (`bolhaPropria` → `BolhaPropria`). A correspondência completa está na §7.7.
- **Um record `TConversaCores`** e duas constantes tipadas:
  - `CoresClaro`: o visual atual, fiel à §4;
  - `CoresEscuro`: **proposta**, derivada de `escuro.pss` e do escuro do Android.
- **Acesso por função:** `Cores.ItemSelecionado`. Trocar de tema = `DefinirTema(TConversaTema.Escuro)`, que avisa as telas por `TMessageManager`.
- **Comentário de origem** em cada valor do claro (`arquivo:linha` da §4), para rastrear.

### 7.2 Tokens (claro atual e escuro proposto)

**Base.** No Android são papéis do Material 3.

| Token Delphi | Claro | Escuro (proposta) | Origem no FMX |
|---|---|---|---|
| `Primaria` | `#007DFF` | `#007DFF` | `chat.editor.fmx:53` |
| `SobrePrimaria` | `#FFFFFF` | `#FFFFFF` | `Conversa.Chat.Listagem.Item.fmx:109` |
| `Fundo` | `#F5F5F5` | `#323232` (`escuro.pss` `fundo`) | `Conversa.FormularioBase.fmx:7` |
| `Superficie` | `#FFFFFF` | `#3C3C3C` (`fundo_claro_1`) | `Conversa.Chat.Listagem.fmx:22` |
| `Topo` | `#F0F0F0` | `#323232` (proposta; ver §9, pergunta 16) | `Conversa.Chat.fmx:13` |
| `MenuLateral` | `#C8C8C8` | `#282828` (`fundo_escuro`) | `Conversa.Principal.fmx:13` |
| `TextoPrimario` | `#141414` | `#F0F0F0` | `Conversa.Chat.Listagem.Item.fmx:66` |
| `TextoSecundario` | `#646464` | `#B4B4B4` | `Conversa.Chat.Listagem.Item.fmx:85` |
| `TextoTitulo` | `#333333` | `#F0F0F0` | `Conversa.Chamada.Detalhe.fmx:63` |
| `Divisor` | `#DBDBDB` | `#464646` | `Novo.Grupo.fmx:191` |
| `Erro` | `#E53935` | `#EF5350` | `Conversa.Notificacao.Item.Chamada.fmx:170` |
| `SobreErro` | `#FFFFFF` | `#FFFFFF` | — |
| `TextoAvisoConexao` | `#410002` (proposta; o FMX usa branco) | `#FFDAD6` | `Conversa.Tela.Inicial.view.fmx:2471` |

**Tokens do app** (os de `ConversaCores` no Android). "Só no doc" = papel do `cores.md` do Android que não está em `Cores.kt`.

| Token Delphi | Claro | Escuro (proposta) | Origem no FMX |
|---|---|---|---|
| `BolhaPropria` | `#CFE7FF` | `#16406B` | `chat.mensagem.pas:101` |
| `BolhaOutro` | `#EDEDED` | `#3C3C3C` | `chat.mensagem.pas:102` |
| `TextoBolhaPropria` | `#000000` | `#F0F0F0` | default TText |
| `TextoBolhaOutro` | `#000000` | `#F0F0F0` | default TText |
| `HoraBolha` | `$80000000` (preto 50%) | `$99FFFFFF` | `chat.mensagem.fmx:50,53` |
| `StatusEntregue` (pendente e recebida) | `#808080` | `#9E9E9E` | `chat.mensagem.pas:147,156` |
| `StatusLida` | `#007DFF` | `#4DA3FF` | `chat.mensagem.pas:165` |
| `Link` | `#0000EE` | `#8AB4F8` | `chat.conteudo.texto.pas:172` |
| `LinkVisitado` (só no doc) | `#551A8B` | `#C58AF9` | `chat.conteudo.texto.pas:106` |
| `BadgeNaoLidas` | `#007DFF` | `#007DFF` | `Conversa.Chat.Listagem.Item.fmx:92` |
| `TextoBadge` | `#FFFFFF` | `#FFFFFF` | `Conversa.Chat.Listagem.Item.fmx:109` |
| `ItemSelecionado` | `#E3F1FF` | `#2B3A4A` | `Conversa.Chat.Listagem.Item.pas:126` |
| `ItemPressionado` | `#E6E6E6` | `#464646` | `Conversa.Chat.Listagem.Item.fmx:131` |
| `DivisorLista` | `$32000000` | `$33FFFFFF` | `Conversa.Chat.Listagem.fmx:2527` |
| `SeparadorNaoLidas` | `#B0C4DE` | `#3A4A5E` | `chat.separador.lidas.fmx:7` |
| `SeparadorData` | `#E0E0E0` | `#464646` | `chat.separador.data.fmx:5` (default) |
| `CampoEntrada` | `#E0E0E0` | `#464646` | `chat.editor.fmx:13`, login (default) |
| `TextoCampo` (placeholder) | `#545454` | `#DCDCDC` | `chat.editor.texto.fmx:161` |
| `IconeAcao` | `#007DFF` | `#007DFF` | editor (enviar/mic/emoji/anexo) |
| `IconeNeutro` (só no doc) | `#000000` | `#F0F0F0` | menu lateral, chamada |
| `IconeDiscreto` | `#808080` | `#9E9E9E` | `Conversa.Chat.fmx:170` |
| `AvatarFundo` | `#F5F5F5` | `#464646` | `crclFoto` |
| `AvatarLetra` | `#007DFF` | `#4DA3FF` | `Conversa.Chat.Listagem.Item.fmx:45` |
| `TextoTerciario` | `#9E9E9E` | `#8C8C8C` | `Conversa.Chamada.Listagem.Item.fmx:276` |
| `Digitando` (só no doc) | `#808080` | `#9E9E9E` | `Conversa.Chat.fmx:212` |
| `GravandoAudio` | `#FF0000` | `#FF5252` | `chat.editor.audio.pas:173` |
| `FundoBotaoGravacao` (só no doc) | `#B0C4DE` | `#3A4A5E` | `chat.editor.audio.fmx:31,95` |
| `ChamadaFundo` | `#F5F5F5` | `#282828` | form base (tela de chamada clara) |
| `ChamadaBarraInferior` | `#E0E0E0` | `#3C3C3C` | `Conversa.Chamada.view.fmx:16` |
| `ChamadaBotao` | `#FFFFFF` | `#464646` | `Conversa.Chamada.view.fmx:33` |
| `ChamadaIconeBotao` | `#000000` | `#F0F0F0` | `Conversa.Chamada.view.fmx:71` |
| `ChamadaEncerrar` | `#D44242` | `#D44242` | `Conversa.Chamada.view.fmx:295` |
| `ChamadaAtender` | `#008000` | `#43A047` | `Conversa.Chamada.view.fmx:348` |
| `ChamadaAlerta` (só no doc) | `#FF0000` | `#FF5252` | `Conversa.Chamada.view.fmx:164` |
| `ChamadaEmAndamento` | `#85FF85` | `#2E7D32` | `Conversa.Chamada.BarraTitulo.fmx:6` |
| `Waveform` | `#00D26A` | `#00D26A` | `Conversa.Chamada.Waveform.pas:45` |
| `ChamadaRealizada` | `#007DFF` | `#4DA3FF` | `Conversa.Chamada.Detalhe.pas:130` |
| `ChamadaRecebida` | `#00C853` | `#00C853` | `Conversa.Chamada.Detalhe.pas:135` |
| `ChamadaPerdida` | `#FF5252` | `#FF5252` | `Conversa.Chamada.Detalhe.pas:139` |
| `NotificacaoFundo` (só no doc) | `#007FFF` | `#007FFF` | `Conversa.Notificacao.Item.fmx:8` |
| `NotificacaoAvatar` (só no doc) | `#1B8DFF` | `#1B8DFF` | `Conversa.Notificacao.Item.fmx:100` |
| `NotificacaoHora` (só no doc) | `#ADD8E6` | `#ADD8E6` | `Conversa.Notificacao.Item.fmx:155` |
| `NotificacaoAvatarChamada` (só no doc) | `#4CAF50` | `#4CAF50` | `Conversa.Notificacao.Item.Chamada.fmx:93` |
| `BotaoRecusar` | `#E53935` | `#E53935` | `Conversa.Notificacao.Item.Chamada.fmx:170` |
| `BotaoAtender` | `#43A047` | `#43A047` | `Conversa.Notificacao.Item.Chamada.fmx:193` |
| `AvisoConexao` | `#F08080` | `#8C1D18` | `Conversa.Tela.Inicial.view.fmx:2471` |
| `SelecaoCheck` (só no doc) | `#00FF00` hoje → sugerido `#43A047` | `#66BB6A` | `Novo.Grupo.Usuario.Item.fmx:97` |
| `OverlayModal` | `$64000000` | `$64000000` | `Conversa.ModalView.fmx:7` |
| `FundoVisualizadorMidia` | `$C8000000` | `$C8000000` | `Conversa.Visualizador.Midia.fmx:5` |
| `Online` | `#43A047` (**provisório**, não existe no FMX) | `#43A047` | — (§9, pergunta 1) |

**Tokens só do desktop.** Não existem no Android (barra de título própria, popup, bandeja). A coluna "Sugestão" propõe reaproveitar um token existente quando a diferença é imperceptível ou pequena. Isso precisa de aprovação (§9, pergunta 15).

| Token Delphi | Claro (hoje) | Sugestão | Origem |
|---|---|---|---|
| `BarraTitulo` | `#C8C8C8` | mesmo valor de `MenuLateral` | `Conversa.FormularioBase.fmx:39,136`; `Conversa.Visualizador.Midia.fmx:173` |
| `IconeBarraTitulo` | `#000000` (X); `#FFFFFF` no hover do fechar | `IconeNeutro` / `SobreErro` | `Conversa.FormularioBase.pas:345-353` |
| `BotaoFecharHover` | `#FF0000` | manter (convenção de janela) | `Conversa.FormularioBase.pas:347`; `Conversa.Visualizador.Midia.pas:144` |
| `BotaoJanelaHover` | `$1AFFFFFF` (provável) | manter | `Conversa.FormularioBase.pas:364,379` |
| `PopupFundo` | `#FFFAFA` | `Superficie` (`#FFFFFF`) | `PopupMenu.Item.fmx:5` |
| `PopupItemHover` | `#FFFFFF → #F5F5F5` | `Superficie → Fundo` | `PopupMenu.Item.fmx:18-19` |
| `PopupBorda` / `BordaAvatar` | `#DCDCDC` | `Divisor` (`#DBDBDB`) | `PopupMenu.fmx:17`; `Conversa.Conteudo.fmx:41` |
| `Sombra` | `#000000` | manter | `PopupMenu.fmx:32` |
| `NomePainelConteudo` | `#696969` | `TextoSecundario` (`#646464`) | `Conversa.Conteudo.fmx:137` |
| `TextoSecundarioDetalhe` | `#666666` | `TextoSecundario` (`#646464`) | `Conversa.Chamada.Detalhe.fmx:74`; `Conversa.Sobre.fmx:37,47` |
| `RotuloDetalhe` | `#999999` | `TextoTerciario` (`#9E9E9E`) | `Conversa.Chamada.Detalhe.fmx:92` |
| `IconeIrUltima` | `#C0C0C0` | manter | `chat.ultima.fmx:24` |
| `IconeRemoverAnexo` | `#4B4B4B` | manter | `chat.anexo.item.fmx:111` |
| `BotaoSalvarHover` | `#E6F2FF` | `ItemSelecionado` (`#E3F1FF`) | `Conversa.Configurar.Conexao.pas:85` |
| `TextoBotaoLegado` | `#007FFF` | `Primaria` (`#007DFF`) | `Conversa.Configurar.Conexao.fmx:142` e outros |
| `LoadingPonto` | `#000000 ↔ #0000FF` (animação) | `IconeNeutro ↔ Primaria` | `Conversa.Loading.Pontos.frame.fmx:16,29` |
| `NotificacaoTipoChamada` | `#D3D3D3` | manter (ver contraste, §5) | `Conversa.Notificacao.Item.Chamada.fmx:142` |
| `BandejaContador` / `TextoBandeja` | `#FF0000` / `#FFFFFF` | manter | `lib/windows/Conversa.Windows.Overlay.pas:111,120` |

O escuro dos tokens só do desktop segue o token sugerido. Os marcados "manter" ficam iguais ou ainda precisam de definição.

### 7.3 Exemplo de unit (15 tokens)

Recorte com 15 dos tokens. A unit real tem todos os da §7.2, na mesma ordem nos dois temas: em Delphi, uma constante de record precisa listar os campos na ordem da declaração.

```pascal
unit Conversa.Cores;

{ Tokens de cor do Conversa. Fonte e regras: docs/design/cores.md.
  Mesmos papéis do Android (ConversaCores / MaterialTheme.colorScheme), em PascalCase.
  Nenhuma cor fora desta unit. }

interface

uses
  System.UITypes,
  System.Messaging;

type
  TConversaTema = (Claro, Escuro);

  TConversaCores = record
    Primaria: TAlphaColor;
    SobrePrimaria: TAlphaColor;
    Fundo: TAlphaColor;
    Superficie: TAlphaColor;
    Topo: TAlphaColor;
    TextoPrimario: TAlphaColor;
    TextoSecundario: TAlphaColor;
    BolhaPropria: TAlphaColor;
    BolhaOutro: TAlphaColor;
    HoraBolha: TAlphaColor;
    ItemSelecionado: TAlphaColor;
    ItemPressionado: TAlphaColor;
    CampoEntrada: TAlphaColor;
    ChamadaEncerrar: TAlphaColor;
    Online: TAlphaColor;
  end;

  /// Enviada por DefinirTema; as telas reaplicam as cores.
  TMensagemTemaAlterado = class(TMessage);

const
  CoresClaro: TConversaCores = (
    Primaria:        $FF007DFF; // chat.editor.fmx:53
    SobrePrimaria:   $FFFFFFFF; // claWhite sobre a primária
    Fundo:           $FFF5F5F5; // claWhitesmoke, Conversa.FormularioBase.fmx:7
    Superficie:      $FFFFFFFF; // Conversa.Chat.Listagem.fmx:22
    Topo:            $FFF0F0F0; // Conversa.Chat.fmx:13
    TextoPrimario:   $FF141414; // Conversa.Chat.Listagem.Item.fmx:66
    TextoSecundario: $FF646464; // Conversa.Chat.Listagem.Item.fmx:85
    BolhaPropria:    $FFCFE7FF; // chat.mensagem.pas:101
    BolhaOutro:      $FFEDEDED; // chat.mensagem.pas:102
    HoraBolha:       $80000000; // txtHora: preto com Opacity 0,5
    ItemSelecionado: $FFE3F1FF; // Conversa.Chat.Listagem.Item.pas:126
    ItemPressionado: $FFE6E6E6; // Conversa.Chat.Listagem.Item.fmx:131
    CampoEntrada:    $FFE0E0E0; // default de TShape (login, editor)
    ChamadaEncerrar: $FFD44242; // Conversa.Chamada.view.fmx:295
    Online:          $FF43A047  // PROVISÓRIO: não existe no FMX (§9, pergunta 1)
  );

  // PROPOSTA: o FMX não tem modo escuro (base: bin/tema/escuro.pss)
  CoresEscuro: TConversaCores = (
    Primaria:        $FF007DFF;
    SobrePrimaria:   $FFFFFFFF;
    Fundo:           $FF323232; // escuro.pss "fundo"
    Superficie:      $FF3C3C3C; // escuro.pss "fundo_claro_1"
    Topo:            $FF323232;
    TextoPrimario:   $FFF0F0F0;
    TextoSecundario: $FFB4B4B4;
    BolhaPropria:    $FF16406B;
    BolhaOutro:      $FF3C3C3C;
    HoraBolha:       $99FFFFFF;
    ItemSelecionado: $FF2B3A4A;
    ItemPressionado: $FF464646;
    CampoEntrada:    $FF464646;
    ChamadaEncerrar: $FFD44242;
    Online:          $FF43A047
  );

/// Cores do tema em uso.
function Cores: TConversaCores;
function TemaAtual: TConversaTema;
/// Troca o tema e avisa as telas (TMensagemTemaAlterado).
procedure DefinirTema(const Tema: TConversaTema);

implementation

var
  FTema: TConversaTema = TConversaTema.Claro;

function Cores: TConversaCores;
begin
  if FTema = TConversaTema.Escuro then
    Result := CoresEscuro
  else
    Result := CoresClaro;
end;

function TemaAtual: TConversaTema;
begin
  Result := FTema;
end;

procedure DefinirTema(const Tema: TConversaTema);
begin
  if Tema = FTema then
    Exit;
  FTema := Tema;
  TMessageManager.DefaultManager.SendMessage(nil, TMensagemTemaAlterado.Create);
end;

end.
```

Uso, no lugar das cores fixas de hoje:

```pascal
// Conversa.Chat.Listagem.Item.pas:125-128 (hoje: $FFE3F1FF / TAlphaColors.White)
if Value then
  rctFundo.Fill.Color := Cores.ItemSelecionado
else
  rctFundo.Fill.Color := Cores.Superficie;

// chat.mensagem.pas:98-104 (hoje: $FFCFE7FF / $FFEDEDED)
case Value of
  TLado.Direito:  Result := Cores.BolhaPropria;
  TLado.Esquerdo: Result := Cores.BolhaOutro;
end;
```

### 7.4 Como aplicar nas telas

| Caminho | Cobre | Limites |
|---|---|---|
| **Por código (recomendado)** — `procedure AplicarCores; virtual;` em `TFormularioBase` e `TFrameBase`, chamado no construtor (no lugar do `RegisterObject` do PSS, `FormularioBase.pas:318` e `FrameBase.pas:40`) e ao receber `TMensagemTemaAlterado`. Cada tela atribui `Fill.Color`, `Stroke.Color`, `FontColor` e os `StartValue/StopValue` das `TColorAnimation` a partir de `Cores`. | Tudo: shapes, textos, animações, canvas, atributos de texto. | Código repetitivo por tela, mas explícito, com verificação do compilador e sem RTTI. |
| **Marcação no `.fmx` + aplicador genérico** (variante do anterior): no `TagString` do componente (hoje não usado no app), escrever o papel, por exemplo `Fill=Superficie;Stroke=Divisor`. Um `AplicarCoresPorMarcacao(Raiz)` percorre os filhos e resolve o nome do token por RTTI do record. | Shapes e textos sem escrever código por tela. | Erro de digitação só aparece em execução (validar com um teste que percorre os forms); animações e canvas continuam por código. |
| **`TStyleBook`** (estilo FMX) | Controles com estilo: `TEdit`, `TMemo`, `TListBox`, barra de rolagem, seleção, cursor (§6.5). | **Não cobre `TRectangle`, `TCircle`, `TPath` e `TText`**, que não têm `StyleLookup` e são a maior parte do visual deste app. Usar só para os controles nativos, com as cores dos tokens. |
| **Religar o PSS** | Em tese, tudo que é `TBrush`, `TStrokeBrush` e `TTextSettings`. | Ids por caminho de componente (quebram ao renomear), anima toda cor ao aplicar, regrava `default.pss` em `bin`, não cobre `.pas`, animações e canvas (§6.4). **Não recomendado.** Decidir se remove (§9, pergunta 13). |

Ordem sugerida de migração:

1. Criar `Conversa.Cores.pas` com todos os tokens da §7.2 (claro = valores atuais; nada muda na tela).
2. Trocar as 44 linhas de `.pas` (§6.2) por `Cores.Xxx`.
3. Tela por tela, mover as cores do `.fmx` para `AplicarCores` (ou para a marcação). O valor no `.fmx` fica só como prévia do designer, igual ao token claro.
4. Criar o `TStyleBook` dos controles nativos com os tokens.
5. Só então ligar o escuro (`DefinirTema`), depois de aprovado (§9, pergunta 9).

### 7.5 Tema escuro

- **Claro** = o visual atual, sem mudança.
- **Escuro** = proposta do Android (`conversa-android-kotlin/docs/design/cores.md` §6.2 e `core/ui/.../tema/Cores.kt`, `EsquemaEscuro` e `ConversaCoresEscuro`). Valores na coluna "Escuro" da §7.2.
- Do FMX vêm só `#323232`, `#3C3C3C`, `#282828` e `#007FFF` (`escuro.pss`). O resto é proposta.
- No Android o escuro existe no código, mas está **desligado** (`ConversaTema(escuro = false)`). No FMX, ligar só depois da aprovação e da migração (§7.4).

### 7.6 Destaque de código, Markdown e outros papéis derivados

O FMX não tem blocos de código, Markdown nem Mermaid (§4.4). O Android criou esses papéis **sem cor nova**, reaproveitando tokens. Se o FMX ganhar essas funções, deve usar os **mesmos tokens**.

**Destaque de código** (Android: `feature/chat/.../BlocoCodigo.kt`, `textoDestacado`):

| Papel | Token Delphi | Claro | Escuro (proposta) |
|---|---|---|---|
| Palavra-chave, tag de XML/HTML | `Primaria` | `#007DFF` | `#007DFF` (*) |
| Texto entre aspas | `ChamadaAtender` | `#008000` | `#43A047` |
| Comentário (itálico) | `TextoTerciario` | `#9E9E9E` | `#8C8C8C` |
| Número | `ChamadaEncerrar` | `#D44242` | `#D44242` |
| Atributo de XML/HTML | `Link` | `#0000EE` | `#8AB4F8` |
| Cabeçalho do bloco ("js", "Copiar") | fundo `CampoEntrada`, linguagem `TextoTerciario`, "Copiar" `IconeAcao`, "Copiado!" `ChamadaAtender` | — | — |

(*) O `cores.md` do Android dá `#4DA3FF` para a palavra-chave no escuro. Mas o código usa `colorScheme.primary`, que no escuro é `#007DFF`. Aqui vale o código. Ver §9, pergunta 12.

**Markdown formatado** (Android: `coresDoMarkdown`):

| Papel | Token Delphi |
|---|---|
| Texto | `TextoPrimario` |
| Fundo do código e da tabela | `CampoEntrada` |
| Divisórias; fundo do "Visualizar"/"Código" | `DivisorLista` |
| Link | `Primaria` |
| Alertas do GitHub | nota `Primaria`; dica `ChamadaAtender`; importante `Link`; aviso `AvisoConexao`; cuidado `ChamadaEncerrar` |

**Mermaid** (Android: `DiagramaMermaid.kt:86-106`, `themeVariables`):

| Variável | Token Delphi |
|---|---|
| `background`, `tertiaryColor` | `Superficie` |
| `primaryColor`, `noteBkgColor` | `CampoEntrada` |
| `primaryTextColor`, `textColor`, `noteTextColor` | `TextoPrimario` |
| `primaryBorderColor` | `Primaria` |
| `secondaryColor` | `DivisorLista` |
| `lineColor` | `TextoTerciario` |

**Outros papéis derivados no Android** (sem cor nova; registrados em `conversa-android-kotlin/docs/historico/`):

| Papel | Token |
|---|---|
| Botões da chamada desligados (mic/câmera) e faixa "Reconectando…" | `ChamadaEncerrar`, com ícone/texto branco |
| Faixa da chamada minimizada | `ChamadaAtender` |
| Contorno de quem está falando | `ChamadaEmAndamento` |
| Ponteiros na tela compartilhada (`id % 5`) | `ChamadaPerdida`, `Primaria`, `ChamadaRecebida`, `AvisoConexao`, `Link` |
| Seta do histórico realizada / recebida / perdida; nome da perdida | `ChamadaRealizada` / `ChamadaRecebida` / `ChamadaPerdida` |
| Resumo de chamada na conversa: encerrada / falhou | `ChamadaRecebida` / `ChamadaPerdida` |
| Áudio "não ouvido" | `Waveform` |
| Selo de mensagem agendada | `CampoEntrada` (fundo) + `IconeAcao` (texto e ícone) |
| Enquete (marcadores e barra) | `Primaria` (fundo da barra = primária com transparência) |

### 7.7 Correspondência com o Android

Para os dois clientes ficarem iguais. No Android, os tokens do app são lidos com `ConversaTema.cores.xxx` (ou `LocalConversaCores.current.xxx`) e os do Material com `MaterialTheme.colorScheme.xxx`. "Só no doc" = o papel está no `cores.md` do Android, mas não em `Cores.kt`.

| Papel | Android | Delphi (`Cores.`) |
|---|---|---|
| Primária / marca | `colorScheme.primary` | `Primaria` |
| Texto e ícone sobre a primária | `colorScheme.onPrimary` | `SobrePrimaria` |
| Fundo das telas | `colorScheme.background` | `Fundo` |
| Superfície (lista, cards, diálogos) | `colorScheme.surface` | `Superficie` |
| Cabeçalho da conversa | `colorScheme.surfaceContainer` (escuro sem valor próprio) | `Topo` |
| Menu lateral / rail | `colorScheme.surfaceContainerHighest` (doc: `menuLateral`) | `MenuLateral` |
| Texto primário | `colorScheme.onSurface` (doc: `textoPrimario`) | `TextoPrimario` |
| Texto secundário | `colorScheme.onSurfaceVariant` (doc: `textoSecundario`) | `TextoSecundario` |
| Título (Detalhe, Sobre) | só no doc: `textoTitulo` | `TextoTitulo` |
| Divisor | `colorScheme.outlineVariant` (doc: `divisor`) | `Divisor` |
| Erro | `colorScheme.error` | `Erro` |
| Texto sobre erro | `colorScheme.onError` | `SobreErro` |
| Texto da faixa "sem conexão" | `colorScheme.onErrorContainer` | `TextoAvisoConexao` |
| Verde de apoio | `colorScheme.tertiary` (= `#43A047`) | `BotaoAtender` |
| Bolha própria | `ConversaCores.bolhaPropria` (= `primaryContainer`) | `BolhaPropria` |
| Bolha do outro | `ConversaCores.bolhaOutro` | `BolhaOutro` |
| Texto da bolha própria / do outro | `ConversaCores.textoBolhaPropria` / `.textoBolhaOutro` | `TextoBolhaPropria` / `TextoBolhaOutro` |
| Hora na bolha | `ConversaCores.horaBolha` | `HoraBolha` |
| Status pendente/entregue | `ConversaCores.statusEntregue` | `StatusEntregue` |
| Status lida | `ConversaCores.statusLida` | `StatusLida` |
| Link / visitado | `ConversaCores.link` / só no doc: `linkVisitado` | `Link` / `LinkVisitado` |
| Badge de não lidas / texto | `ConversaCores.badgeNaoLidas` / `.textoBadge` | `BadgeNaoLidas` / `TextoBadge` |
| Item selecionado | `ConversaCores.itemSelecionado` (= `secondaryContainer`) | `ItemSelecionado` |
| Item pressionado (hover) | `ConversaCores.itemPressionado` | `ItemPressionado` |
| Divisor lista/conversa | `ConversaCores.divisorLista` | `DivisorLista` |
| Separador "não lidas" / de data | `ConversaCores.separadorNaoLidas` / `.separadorData` | `SeparadorNaoLidas` / `SeparadorData` |
| Campo de entrada | `ConversaCores.campoEntrada` (= `surfaceContainerHigh`) | `CampoEntrada` |
| Placeholder do campo | `ConversaCores.textoCampo` | `TextoCampo` |
| Ícone de ação / neutro / discreto | `ConversaCores.iconeAcao` / só no doc: `iconeNeutro` / `ConversaCores.iconeDiscreto` | `IconeAcao` / `IconeNeutro` / `IconeDiscreto` |
| Avatar: fundo / letra | `ConversaCores.avatarFundo` / `.avatarLetra` | `AvatarFundo` / `AvatarLetra` |
| Texto terciário | `ConversaCores.textoTerciario` | `TextoTerciario` |
| "Digitando…" | só no doc: `digitando` | `Digitando` |
| Gravando áudio / fundo dos botões de gravação | `ConversaCores.gravandoAudio` / só no doc: `fundoBotaoGravacao` | `GravandoAudio` / `FundoBotaoGravacao` |
| Chamada: fundo / barra inferior | `ConversaCores.chamadaFundo` / `.chamadaBarraInferior` | `ChamadaFundo` / `ChamadaBarraInferior` |
| Chamada: botão / ícone do botão | `ConversaCores.chamadaBotao` / `.chamadaIconeBotao` | `ChamadaBotao` / `ChamadaIconeBotao` |
| Encerrar / atender (tela de chamada) | `ConversaCores.chamadaEncerrar` / `.chamadaAtender` | `ChamadaEncerrar` / `ChamadaAtender` |
| Alerta de mic/vídeo | só no doc: `chamadaAlerta` | `ChamadaAlerta` |
| Em chamada (faixa) | `ConversaCores.chamadaEmAndamento` | `ChamadaEmAndamento` |
| Waveform | `ConversaCores.waveform` | `Waveform` |
| Histórico: realizada / recebida / perdida | `ConversaCores.chamadaRealizada` / `.chamadaRecebida` / `.chamadaPerdida` | `ChamadaRealizada` / `ChamadaRecebida` / `ChamadaPerdida` |
| Toast: fundo / avatar / hora / avatar de chamada | só no doc: `notificacaoFundo` / `notificacaoAvatar` / `notificacaoHora` / `notificacaoAvatarChamada` | `NotificacaoFundo` / `NotificacaoAvatar` / `NotificacaoHora` / `NotificacaoAvatarChamada` |
| Recusar / atender (toast) | `ConversaCores.botaoRecusar` / `.botaoAtender` | `BotaoRecusar` / `BotaoAtender` |
| Faixa "sem conexão" | `ConversaCores.avisoConexao` (= `errorContainer`) | `AvisoConexao` |
| Check de seleção | só no doc: `selecaoCheck` | `SelecaoCheck` |
| Scrim de modal | `ConversaCores.overlayModal` | `OverlayModal` |
| Fundo do visualizador de mídia | `ConversaCores.fundoVisualizadorMidia` | `FundoVisualizadorMidia` |
| Online | `ConversaCores.online` (provisório) | `Online` |
| Barra de título, popup, bandeja, hovers de janela | — (só desktop) | ver "Tokens só do desktop" (§7.2) |

## 8. Regras

1. **Cor nova entra primeiro aqui.** Se faltar um papel:
   1. procurar no FMX (§4);
   2. registrar aqui (hex, ARGB, papel, `arquivo:linha`);
   3. criar o token em `Conversa.Cores.pas` (quando existir);
   4. só então usar.

   O Android copia daqui (`conversa-android-kotlin/docs/design/cores.md` e `Cores.kt`).
2. **Não usar as cores do web**: nem a paleta do cliente web, nem cores padrão de bibliotecas web. Também não usar os estilos prontos da Embarcadero (por exemplo, estilos escuros) como fonte de cor.
3. **Não gravar cor solta em `.fmx` nem em `.pas`.**
   - Toda cor vem de um token (`Cores.Xxx`).
   - O valor que fica no `.fmx` é só a prévia do designer e deve ser igual ao token claro.
   - Enquanto a unit não existir: cor nova só se já estiver na §4, citando o papel.
4. **Primária única: `#007DFF`.** `#007FFF` é legado (login, notificações, PSS): trocar ao mexer na tela.
5. **Cores puras de "nome HTML"** (`claRed #FF0000`, `claGreen #008000`, `claBlue #0000FF`, `claLime #00FF00`) são **legado**. Ao mexer, usar os equivalentes já presentes no FMX mais novo (`#E53935`/`#FF5252`, `#43A047`/`#00C853`, `#007DFF`), salvo decisão contrária (§9, perguntas 3–6).
6. **Variantes quase iguais** (§6.1) não ganham token próprio sem motivo. Preferir o token existente (tabela "Tokens só do desktop", §7.2).
7. **Não religar o PSS** sem decisão (§9, pergunta 13).
8. **Alterou cor no FMX?** Atualizar este documento (com o hash do commit) e avisar o Android, para manter a §7.7 em dia.

## 9. Perguntas em aberto / incertezas

Respostas já existentes estão marcadas com **Situação (2026-10-08)**. As fontes são `conversa-android-kotlin/docs/historico/`, o `TODO.md` e o código do Android.

1. **Indicador online:** o FMX não tem. Definir a cor (proposta provisória `#43A047`) ou omitir.
   - **Situação:** o Android adotou `#43A047` provisório (`historico/2026-10-07-01-cores-do-fmx.md`, "Decisões"; `Cores.kt` `online`; bolinha em `core/ui/.../Avatar.kt:76`). Falta a decisão definitiva e a cor no FMX.
2. **`#007DFF` vs `#007FFF`:** duas primárias quase idênticas. Proposta: unificar em `#007DFF` (mais usada e mais recente).
   - **Situação:** o Android decidiu "primária única `#007DFF`" (mesmo histórico). No FMX ainda convivem as duas (§4.1).
3. **Verde de atender:** `claGreen #008000` (tela de chamada) vs `#43A047` (toast) vs `#00C853` (detalhe). Proposta: `#43A047` para botões e `#00C853` para o ícone "recebida"; `#008000` só para fidelidade literal.
   - **Situação:** o Android mantém os três como no FMX (`chamadaAtender #008000` no claro, `botaoAtender #43A047`, `chamadaRecebida #00C853`). Não houve decisão.
4. **Vermelhos:** `#FF0000` (vários), `#D44242` (encerrar), `#E53935` (recusar), `#FF5252` (perdida). Proposta: `Erro = #E53935`, encerrar chamada `#D44242`, perdida `#FF5252`.
   - **Situação:** o Android implementou assim (`error #E53935`). Também usa `chamadaEncerrar` para os botões desligados e a faixa "Reconectando…" (`TelaChamada.kt:711,886`). O `#FF0000` segue em `gravandoAudio`.
5. **Ícones do histórico de chamadas inconsistentes:** a lista usa `claBlue/claGreen/claRed` (`Conversa.Chamada.Listagem.Item.fmx:150,166,218`); o detalhe usa `#007DFF/#00C853/#FF5252` (`Conversa.Chamada.Detalhe.pas:130-139`). Proposta: seguir o detalhe.
   - **Situação:** o Android segue o detalhe (`HistoricoChamadas.kt:302-305`; `historico/2026-10-08-12-…`). Falta alinhar a lista do FMX.
6. **`claLime #00FF00`** no check de seleção do Novo Grupo é berrante/legado. Confirmar se troca por `#43A047`.
   - **Situação:** sem decisão; o Android não tem esse token no código.
7. **Defaults do FMX:**
   - `#E0E0E0` (fill de `TShape`) e `#000000` (`TText`) foram inferidos pelo default do framework, não lidos do arquivo. `default.pss` (snapshot de 2024) confirma `#E0E0E0` nos campos de login.
   - O estilo da plataforma (Windows) define a cor do texto de `TEdit`/`TMemo`/`TListBox`. Isso não foi verificado em execução (§6.5).
8. **Hover da barra de título:** `TAlphaColorF.Create(255,255,255,0.1)` passa 255 onde se espera 0..1. O resultado provável (com clamp) é branco 10% (`#1AFFFFFF`), quase invisível sobre `#C8C8C8`. Corrigir para `TAlphaColorF.Create(1,1,1,0.1)` ou definir outro hover (token `BotaoJanelaHover`).
9. **Modo escuro:** tudo na coluna "Escuro" da §7.2 é proposta. Só `#323232/#3C3C3C/#282828/#007FFF` vêm de `escuro.pss` (inativo).
   - **Situação:** no Android o escuro existe no código, mas está **desligado** até aprovação (`historico/2026-10-07-01-…`; `TODO.md` 1.5). A escolha "Sistema / Claro / Escuro" está pendente (`TODO.md:839`).
10. **Tela de chamada:** o FMX é claro; apps móveis costumam usar chamada escura.
    - **Situação:** o Android manteve a chamada **clara**, como no FMX (`TelaChamada.kt:246` usa `chamadaFundo #F5F5F5`). É uma decisão de fato, não formalizada.
11. **Cabeçalho:** `Conversa.Chat.fmx:13` usa `#F0F0F0`, mas `Conversa.Conteudo.fmx:13` usa `#FFFFFF`. Proposta: cabeçalho = `#F0F0F0` (`Topo`).
    - **Situação:** sem decisão.
12. **Destaque de código (§7.6):** o Android reaproveita tokens da paleta (azul, verde de atender, cinza terciário, vermelho de encerrar, link), no Markdown e no Mermaid também. Confirmar ou propor outro esquema.
    - **Situação:** implementado no Android (`74ce225`, `26f4ea2`; `historico/2026-10-08-27-…`, `-35-…`, `-36-…`), aguardando confirmação.
    - Há uma divergência: o `cores.md` do Android dá `#4DA3FF` para a palavra-chave no escuro, mas o código usa a primária (`#007DFF`).

*Perguntas novas, deste documento (2026-10-08):*

13. **PSS:** remover ou reaproveitar? Hoje ele só cria uma dependência: o app não inicia sem `bin/tema/default.pss` (§6.3), e nada é aplicado. Proposta: remover quando `Conversa.Cores.pas` existir (§7.4).
14. **`TextoCampo`:** `#545454` é o placeholder, não o texto digitado (§2.1). O texto digitado deve usar `TextoPrimario`? No Android o token `textoCampo` existe, mas não é usado.
15. **Tokens só do desktop:** aprovar as unificações sugeridas na §7.2. Por exemplo, `#DCDCDC → Divisor`, `#666666/#696969 → TextoSecundario`, `#999999 → TextoTerciario`, `#E6F2FF → ItemSelecionado`, `#FFFAFA → Superficie`, `#0000FF` do loading → `Primaria`.
16. **Escuro do cabeçalho:** o `EsquemaEscuro` do Android não define `surfaceContainer` e cai no padrão do Material 3, que não é cor do FMX. Proposta: `Topo` escuro = `#323232` (o `default.pss` mapeava o cabeçalho para `@cores.fundo`). Alinhar o Android.
17. **Contraste dos cinzas:** `#9E9E9E`, `#999999` e `#808080` em texto pequeno reprovam (§5). Manter a fidelidade ou escurecer (por exemplo, `TextoTerciario` → `#757575`, que é cor nova)?
