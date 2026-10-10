# 03 — Inventário de funcionalidades e comportamento do cliente web (conversa-web) — checklist de paridade para o cliente Windows (FMX)

> **Cópia de 2026-10-08** do documento `docs/auditoria-2026-10/03-inventario-web.md` do repositório `conversa-android-kotlin`, **revalidada** contra o `conversa-web` em **`e8d82cb`** (2026-10-08 20:29, "Campo de mensagem no Tiptap; 'mais emojis' na barra de reações rápidas"), que vem depois de **`7322e83`** (2026-10-08 19:50, "Campo de mensagem: seleção, desfazer e rascunho; reações rápidas e agendadas"). Na revalidação:
> - os **137 IDs** foram conferidos (sem lacuna nem duplicata);
> - **82 itens, de todos os 13 grupos**, foram conferidos com o código, junto com as seções gerais (§1, §2), os endpoints (§4.1) e os eventos (§4.2);
> - as correções foram aplicadas no corpo, marcadas com **🔎**, e estão listadas na §13 (com os achados no web e o que ficou "não confirmado");
> - a §7 foi **reescrita para desktop** (atalhos, arrastar e soltar, colar, menus, janelas, notificações, abas de configurações), e as orientações "Para o Android" das §10–§12 viraram "Para o cliente Windows (FMX)".
>
> Histórico do original (mantido): auditoria de 2026-10-06 no commit `bfb79d8` (2026-10-06, "Abas Sistema e Acessos nas configurações; Equipes sai da barra"), **atualizada com `39d06f9`** (2026-10-06 21:22, "Campo de mensagem rico, votação em grupo e chat completo na chamada"), cujos itens estão marcados com 🆕 e resumidos na §10; **de novo em 2026-10-08** com `eaa8bac` e `785bdef` (2026-10-07 20:30 e 20:41), marcados com o commit (🆕 `eaa8bac`) e resumidos na §11; e com `7322e83` e `e8d82cb` (2026-10-08, noite), resumidos na §12. Foram lidos `CLAUDE.md`, `README.md`, todo o `src/`, `chat-popup.html`, `public/firebase-messaging-sw.js`, `package.json`, `vite.config.ts`, os nomes dos testes em `tests/unit/` (589 casos) e o `git show --stat` de todos os commits desde 2026-09-12. Servidor de referência: `conversa` em `779c8ed` (sem mudança de contrato desde `5cad911`).
>
> Objetivo: servir de **checklist de paridade** para o cliente Windows **`conversa-windows-fmx`** (Delphi 12 / FireMonkey). Cada funcionalidade tem um ID (ex.: `MSG-07`) para ser marcada como "feito / parcial / falta" na comparação com o FMX. **Os IDs são os mesmos do documento do Android** e não mudam: um mesmo ID descreve o mesmo comportamento do web nos dois checklists.
>
> Caminhos de arquivo são relativos a `conversa-web/` salvo indicação. Rotas REST são relativas a `/api` (o cliente Eden monta `https://<host>/api/<rota>`). As referências `arquivo:linha` acrescentadas na revalidação são do `conversa-web` em `e8d82cb` (e do servidor em `779c8ed`, quando dito).

---

## Sumário

1. [Arquitetura do cliente web](#1-arquitetura-do-cliente-web)
2. [Mapa de telas, rotas, painéis e navegação](#2-mapa-de-telas-rotas-painéis-e-navegação)
3. [Lista de funcionalidades (checklist de paridade)](#3-lista-de-funcionalidades-checklist-de-paridade)
4. [Todos os endpoints REST e eventos WebSocket](#4-todos-os-endpoints-rest-e-eventos-websocket)
5. [WebRTC / MediaMTX / WHIP / WHEP](#5-webrtc--mediamtx--whip--whep)
6. [Regras de UX e textos exatos para replicar](#6-regras-de-ux-e-textos-exatos-para-replicar)
7. [Comportamentos de desktop e adaptações para o cliente Windows (FMX)](#7-comportamentos-de-desktop-e-adaptações-para-o-cliente-windows-fmx)
   - 7.1 Atalhos de teclado · 7.2 Arrastar e soltar · 7.3 Colar · 7.4 Menu de contexto, hover e toque longo · 7.5 Popup de conversa · 7.6 Janela flutuante da chamada · 7.7 Discador SIP · 7.8 Notificações, sons e saída com upload · 7.9 Abas de configurações · 7.10 Conexão lenta · 7.11 Regras de foco da janela · 7.12 Outras adaptações · 7.13 O que não se aplica ao desktop
8. [Anexo A — Commits desde 2026-09-12 e o que tocaram](#8-anexo-a--commits-desde-2026-09-12-e-o-que-tocaram)
9. [Anexo B — Código morto / legado encontrado](#9-anexo-b--código-morto--legado-encontrado)
10. [🆕 Atualização de 2026-10-06 (noite) — commit `39d06f9`](#10-atualização-de-2026-10-06-noite--commit-39d06f9)
11. [🆕 Atualização de 2026-10-08 — commits `eaa8bac` e `785bdef`](#11-atualização-de-2026-10-08--commits-eaa8bac-e-785bdef)
12. [🆕 Atualização de 2026-10-08 (noite) — commits `7322e83` e `e8d82cb`](#12-atualização-de-2026-10-08-noite--commits-7322e83-e-e8d82cb)
13. [🔎 Revalidação de 2026-10-08 contra `e8d82cb` (cópia para o FMX)](#13-revalidação-de-2026-10-08-contra-e8d82cb-cópia-para-o-fmx)

---

## 1. Arquitetura do cliente web

### 1.1 Stack

| Camada | Tecnologia | Onde |
|---|---|---|
| Framework | Vue 3 `<script setup lang="ts">` | `src/**/*.vue` |
| Estado | Pinia 3 (Composition API) | `src/stores/{auth,chat,call,sip,atividades,enquetes}.ts` (🔎 a store `enquetes` faltava) |
| 🔎 Campo de mensagem | **Tiptap 3** (`@tiptap/*` 3.31.4, sobre ProseMirror): `Document`, `Paragraph`, `Text`, `HardBreak`, `Gapcursor`, `Dropcursor`, `TrailingNode`, `UndoRedo`, `Mention` + peças próprias | `src/editor/pecas.ts`, `src/editor/PecaAnexo.vue`, `src/editor/PecaFigurinha.vue`, `components/MessageInput.vue` |
| 🔎 Rascunhos | IndexedDB `conversa-rascunhos`, loja `rascunhos`, chave `usuarioId:conversaId` (ENV-23) | `services/rascunhos.ts` |
| Estilo | Tailwind 3 + CSS variables, tema pela classe `dark` no `<html>` | `src/style.css`, `tailwind.config.js` |
| Runtime/build | Bun ≥ 1.4, Vite 7, vue-tsc (via `scripts/vue-tsc.ts`) | `package.json`, `vite.config.ts` |
| HTTP | Eden (`@elysiajs/eden` 1.4.9), tipado pelas rotas do backend (`../conversa/src/app.ts`) | `src/services/eden.ts`, `src/services/conversaApi.ts` |
| Tempo real | WebSocket nativo, reconexão com backoff, polling de 8 s como fallback | `src/stores/chat.ts` |
| Push | Firebase Cloud Messaging (web, VAPID) + service worker | `src/services/firebase.ts`, `public/firebase-messaging-sw.js` |
| Upload | MinIO por URL pré-assinada, `XMLHttpRequest` (progresso) | `conversaApi.ts#uploadMinio` |
| Hash | `hash-wasm` SHA-256 em blocos de 2 MB (deduplicação) | `conversaApi.ts#sha256File` |
| Código | highlight.js (sob demanda) + CodeMirror 6 (janela de código) | `composables/useCodeHighlight.ts`, `components/CodigoModal.vue` |
| Markdown / diagramas | `marked` + `DOMPurify`, `mermaid` (securityLevel strict) | `composables/useMarkdown.ts`, `composables/useMermaid.ts` |
| PDF | `pdfjs-dist` 6 | `components/VisualizadorPdf.vue` |
| Figurinhas | `lottie-web` (build `lottie_light`, só SVG) | `utils/figurinhas.ts`, `components/FigurinhaLottie.vue` |
| VoIP | `sip.js` 0.21 | `src/stores/sip.ts` |
| Chamadas | WebRTC nativo contra MediaMTX (WHIP publica / WHEP assina) | `src/stores/call.ts` |

Duas entradas HTML (Vite multi-page): `index.html` → `src/main.ts` → `App.vue`; `chat-popup.html` → `src/chat-popup.ts` → `ChatPopup.vue` (janela separada de uma conversa).

Topologia (nginx do backend, mesmo host em dev e prod — `README.md`):

```
https://HOST
 ├── /          → página (Vite em dev, bin/web em prod)
 ├── /api/      → API REST
 ├── /ws/       → WebSocket da API
 ├── /storage/  → anexos (MinIO)
 └── /webrtc/   → MediaMTX (WHIP/WHEP)
```

### 1.2 Estado

| Store | Responsabilidade | Persistência |
|---|---|---|
| `auth` (`stores/auth.ts`) | token, usuário, `dispositivoId`, URL do avatar resolvida, permissões do sistema (`permissoes`, `temPermissao`) | `localStorage`: `conversa.token`, `conversa.user` (JSON), `conversa.deviceId`, `conversa.apiBase` |
| `chat` (`stores/chat.ts`) | contatos, conversas, mensagens por conversa, conversa ativa, resposta pendente, digitando/gravando, online, WebSocket, polling, cursor de sincronização, buscas | memória (não persiste mensagens) |
| `call` (`stores/call.ts`) | estado da chamada (`inativo`/`chamando`/`recebendo`/`ativa`/`encerrando`), peers WHIP/WHEP, mídia local, tela, ponteiros, chat da chamada | memória |
| `sip` (`stores/sip.ts`) | config do ramal, UserAgent/Registerer sip.js, sessão, tons | memória |
| `atividades` (`stores/atividades.ts`) | lista paginada, contador de novas, tela aberta | memória |
| 🔎 `enquetes` (`stores/enquetes.ts`) | cache de votações por id, leituras simultâneas deduplicadas, votar/encerrar/alterar prazo, releitura no WS 62 (MSG-20) | memória |

Estados globais fora do Pinia (composables singleton): tema (`useTheme`, chave `theme` = `dark`/`light`), cores personalizadas (`useCoresPersonalizadas`, 🔎 chave `conversa.cores` no localStorage, por tema, sincronizada entre janelas pelo evento `storage`), qualidade das chamadas (`useConfigChamada`, chave `conversa.chamada`), uploads ativos (`useUploadProgress`), áudio tocando (`useAudioManager`), relógio compartilhado (`useAgora`), conexão lenta (`useConexao`).

🔎 Persistência fora do localStorage: o **rascunho de cada conversa** (ENV-23) fica no **IndexedDB** `conversa-rascunhos` (loja `rascunhos`, chave `usuarioId:conversaId`), com os arquivos como `Blob` (`services/rascunhos.ts:29-30,58-72`). O logout **não** apaga esses rascunhos (§1.5, §13.3).

### 1.3 Como fala com a API (Eden)

- `api()` (`services/eden.ts`) devolve o cliente das rotas `/api` no endereço `getApiBase()` = `localStorage['conversa.apiBase']` ou `window.location.origin`. O cliente é recriado se a base muda. (Não há mais campo na tela de login para trocar a base, só `auth.setApiBase`, sem uso na UI.)
- Header `authorization: Bearer <token>` lido do `localStorage` a cada requisição.
- `dados(chamada)` devolve `data` ou lança:
  - **401** → `limparToken()` (remove `conversa.token` do localStorage) e lança `ErroNaoAutenticado`.
  - Corpo HTML (página de erro do nginx 502/504) → mensagem `"Servidor indisponível"`.
  - JSON `{ error }` ou `{ message }` → a string; senão `Erro HTTP <status>`.
  - 🔎 Nuance: um corpo de erro em **texto não-HTML** volta como está; só sem nada aproveitável vira `Erro HTTP <status>` (`services/eden.ts:76-98`).
- **Datas**: o JSON é lido com reviver que só converte para `Date` as chaves em `CAMPOS_DATA` (`inserida, alterada, visivel_em, encerra_em, encerrada_em, criado_em, atualizado_em, ultima_mensagem, arquivada_em, iniciada, finalizada, adicionado_em, entrou_em, saiu_em, recusou_em, recebida, visualizada, reproduzida, excluida_em, reagido_em, online_em, ate, vistas_em` — 🔎 `encerra_em` e `encerrada_em`, da votação, faltavam; `services/eden.ts:8-32`) e só se o valor for ISO-8601 com fuso. Texto de mensagem nunca vira data. **Atenção FMX**: `recebida`/`visualizada`/`reproduzida` são booleanos na lista de mensagens, mas datas (ou null) no detalhe de status — o mesmo nome de campo tem tipos diferentes por rota. No Delphi, ler esses campos com tolerância (`TJSONBool` **ou** `TJSONString`/`TJSONNull`) e converter as datas com `ISO8601ToDate(valor, False)` (UTC), só passando para a hora local na tela.
- Verbos: `GET` consulta, `PUT` cria, `PATCH` altera, `POST` ações, `DELETE` remove.

### 1.4 WebSocket

Arquivo: `src/stores/chat.ts` (`conectarWebSocket`, `tratarEventoSocket`).

- URL: `${wss|ws}://${window.location.host}${VITE_WS_PATH || '/ws/'}` — **usa o host da página, não `conversa.apiBase`**. No FMX: `wss://<host-da-api>/ws/`, **sempre com a barra final** (`/ws` sem barra recebe 301 do nginx, e a maioria dos clientes WebSocket não segue redirecionamento — doc 01 §1.2), e com o `tipo` como **número JSON** (`{"tipo":1,...}`; `"1"` em texto é ignorado em silêncio).
- `onopen`:
  1. `conectadoTempoReal = true`, zera tentativas.
  2. Envia `{"tipo":1,"token":"<token>"}` (autenticação).
  3. Recarrega quem está online (`GET /contatos/online`) — quem saiu durante a queda não fica "online".
  4. Atualiza o contador de atividades (`GET /atividades/novas`).
  5. Se o handler de chamada já está registrado, verifica chamadas pendentes (`GET /chamadas/pendentes`).
- `onclose` → agenda reconexão com espera `min(30000, 1000 * 2^tentativas)` ms (1 s, 2 s, 4 s, … até 30 s).
- **Polling de fallback**: a cada 8 s, **só se o socket estiver desconectado**, executa o mesmo fluxo de "nova mensagem" (`GET /mensagens/novas`) e verifica chamadas pendentes.
- **Aviso visual**: se o socket fica desconectado por mais de 5 s com o usuário logado, aparece a faixa vermelha no topo: `Conexao em tempo real indisponivel — usando atualizacao periodica` (`App.vue`).
- Envio: `{tipo:1, token}` (login) e `{tipo:57, chamada_id, dados}` (sinal de chamada; descartado se o socket não estiver `OPEN`).
- Recebimento: ver tabela completa em §4.2.

**Sincronização incremental (evento 2):** o evento `NovaMensagem` (tipo 2) não traz a mensagem. O cliente chama `GET /mensagens/novas?desde=<cursorSync ISO>` (devolve `[{conversa_id, mensagem_id, ate}]`), avança o cursor para o maior `ate` (e para `coalesce(visivel_em, inserida)` de cada mensagem recebida, **nunca para o futuro** — agendadas futuras do autor não avançam o cursor), busca `GET /mensagens?conversa=X&mensagemreferencia=0&mensagensprevias=10` de cada conversa afetada para ter o conteúdo (notificação), recarrega `GET /conversas` e, se a conversa ativa foi afetada, recarrega as 80 últimas mensagens dela. Também limpa o "digitando" das conversas que receberam mensagem. O cursor começa em `new Date()` no carregamento da página (não é persistido).

### 1.5 Sessão, token expirado e "login volta sem F5 depois que o servidor reinicia"

Arquivos: `App.vue#iniciarSessao`, `services/eden.ts`, `stores/auth.ts` (commit `c32209a`).

- `iniciarSessao()` roda ao montar o app já logado **e** quando `auth.isAuthenticated` vira `true` (login pelo formulário). Sequência: `chat.inicializar()` (contatos + conversas em paralelo, WebSocket, polling, pede permissão de notificação) → `sip.inicializarSessao(false)` → resolve URL do avatar → carrega permissões (`GET /usuario/permissoes`, falha silenciosa) → registra o handler de eventos de chamada → `call.verificarChamadasPendentes()` → aplica deep link da URL.
- **Erro `ErroNaoAutenticado` (401)** → `sair()` (logout local, sem mensagem de erro).
- **Qualquer outro erro** (API ainda subindo após reiniciar, 502 do nginx) → **mantém o login**, mostra o toast `"<mensagem> (tentando de novo...)"` e tenta de novo a cada **5 s**. Quando dá certo, o toast some (se ainda for o mesmo).
- Logout (`sair()`): cancela retentativa, para toque/notificação de chamada, encerra chamada, remove handler, fecha WS + polling, limpa conversa ativa, limpa atividades, encerra SIP, `auth.logout()` (remove `conversa.token` e `conversa.user`; **mantém** `conversa.deviceId`, que é reenviado no próximo login para reaproveitar o dispositivo). **Não há chamada de logout na API.** 🔎 O logout **não apaga os rascunhos** do IndexedDB (ENV-23): o texto e os arquivos rascunhados continuam no navegador para o próximo usuário da máquina — achado de privacidade (§13.3; `App.vue:688-698`).
- Lacuna conhecida do web: um 401 em qualquer chamada **depois** do início só apaga o token do localStorage; o `auth.token` em memória continua e a tela não volta ao login até o próximo `iniciarSessao` (F5 ou falha seguinte).
- **Para o FMX:** o app fica aberto o dia todo e o token dura **12 h** sem renovação, então o 401 vai acontecer todo dia. Tratar 401 em qualquer chamada como **sessão vencida**: refazer o login com o mesmo `dispositivo_id` (pedindo a senha ao usuário ou usando uma credencial guardada com DPAPI/Gerenciador de Credenciais, conforme a decisão do projeto), **sem laço** (o login tem limite de taxa, compartilhado pela rede inteira em desenvolvimento) e, ao reconectar o WebSocket, mandar o token novo (o WS não revalida o token depois do login). No logout do FMX, apagar também os rascunhos locais do usuário.

### 1.6 FCM web e notificações

- `services/firebase.ts`: projeto `conversa-23858`, `getToken(messaging, { vapidKey })` após `Notification.requestPermission()`; sem permissão → `null`.
- Após login: `PATCH /dispositivo {id, nome, modelo, versao_so, plataforma:'Web'}` (detecção pelo user agent — iPhone/iPad antes de macOS) e depois `PATCH /dispositivo {id, token_fcm}`. 🔎 Os dois `PATCH` saem em sequência **sem esperar** um pelo outro (`stores/auth.ts:170-174`).
- **Para o FMX (sem FCM):** um só `PATCH /dispositivo {id, nome: <nome do computador, ≤ 50>, modelo: 'Desktop', versao_so: <ex.: 10.0.22621, ≤ 15>, plataforma: 'Windows'}`, **sem `token_fcm`** (texto acima do limite da coluna dá 500). As mensagens chegam pelo WebSocket (WS 2 → `GET /mensagens/novas`) e a notificação é local (§7.8). Atenção à regra do servidor: enquanto o FMX estiver conectado, **nenhum aparelho do mesmo usuário recebe push** (o teste é por usuário, não por aparelho — doc 01 §15.1).
- **Payload do push** (o servidor manda só `data`): `{ titulo, mensagem, conversa }`. O service worker (`public/firebase-messaging-sw.js`) mostra `showNotification(titulo, {body: mensagem, icon:'/logo.png', silent:true, tag:'conversa-<id>', data:{conversa}})`.
- Clique na notificação (SW): procura a janela principal (exclui `/chat-popup`), prioriza a focada, depois a visível; foca e envia `postMessage({tipo:'conversa-abrir', conversaId})`; o `App.vue` abre a conversa. Sem janela aberta → `clients.openWindow('/chat/<id>')` (ou `/`).
- Com o app aberto, as notificações de mensagem e de chamada são geradas pelo próprio cliente (ver `NOT-*` em §3). `ouvirMensagensForeground` existe em `firebase.ts` mas **não é usado**.

### 1.7 Upload de anexos (deduplicação)

`conversaApi.ts#uploadAnexo(tipo, nome, extensao, blob, onProgress)`:
1. `identificador = sha256(blob)` (hex, blocos de 2 MB).
2. `GET /anexo/existe?identificador=` → se a resposta tem `id`, o arquivo já existe: progresso 100%, devolve `{id, identificador}` sem subir nada.
3. `PUT /anexo {identificador, tipo, nome, extensao, tamanho}` → `{id, upload_url}`.
4. `PUT upload_url` (XHR, corpo = arquivo) com progresso.
5. A mensagem leva no conteúdo o **identificador** (não o id).

🔎 **O web não chama `POST /anexo/confirmar`** (nenhuma ocorrência em `src/`): o upload termina no PUT da URL, e a confirmação fica para a tarefa `VerificacaoAnexos` do servidor ou para o primeiro `GET /anexo`. **O FMX deve chamar** `POST /anexo/confirmar` depois do PUT (o doc 01 recomenda). Outros cuidados do FMX no PUT pré-assinado: corpo **cru** com `Content-Length`, começar antes de **300 s**, não alterar a URL nem pôr `:443` no host configurado, e cachear por `identificador`, nunca pela URL (doc 01 §8).

Para exibir: `GET /anexo?identificador=` → `{url}` (pré-assinada; validade lida de `X-Amz-Date` + `X-Amz-Expires`; renovada 60 s antes de vencer; URL sem assinatura vale até falhar; erro de carga força renovação, no máximo 1 vez por minuto por anexo) — `composables/useAttachments.ts`.

### 1.8 Carregamento sob demanda

Chunks manuais no Vite: `sipjs`, `framework`, `highlightjs`, `markdown`, 🔎 `editor` (Tiptap/ProseMirror, `vite.config.ts:46-49`), `lottie`, `vendor-utils` (hash-wasm), `codemirror`. Componentes assíncronos: `SipDialerModal`, `SipIncomingCallModal`, `CodigoModal`, `AgendarMensagemModal`, 🔎 `MensagensAgendadasModal` (`MessageInput.vue:240`), `VisualizadorPdf`, `VisualizadorHtml`. Irrelevante para o FMX, mas indica o que é "pesado" e opcional.

---

## 2. Mapa de telas, rotas, painéis e navegação

### 2.1 Rotas (URL) — `composables/useHistoryNavigation.ts`

Não há vue-router. A URL é sincronizada manualmente com `history.pushState/replaceState` e o `popstate` restaura o estado.

| URL | Seção | Observação |
|---|---|---|
| `/` ou `/chat` | Chat sem conversa aberta | painel lateral aberto |
| `/chat/:conversaId` | Chat com conversa aberta | deep link aplicado após `iniciarSessao` |
| `/anexos`, `/anexos/:conversaId` | Página de anexos | |
| `/config/:aba` | Configurações | `aba` ∈ `usuario, dispositivos, permissoes, voip, cores, chamadas, sistema, acessos` (inválida → `usuario`) |
| `/chamadas` | Histórico de chamadas | |
| `/atividades` | Atividades | |
| `/ramal` | (válida no parser; o item da barra abre o discador em vez de navegar) | |
| `/chat-popup.html?conversa=:id` | Janela separada de uma conversa | entrada própria |

- O `history.state` guarda também a **âncora de rolagem** `{mensagemId, offset}` (atualizada por `replaceState` 200 ms após parar de rolar). Voltar/avançar restaura seção, conversa, aba e posição. Em **reload** a âncora é descartada (abre no fim ou na primeira não lida).
- Mudar só a âncora usa `replaceState`; mudar seção/conversa/aba usa `pushState`.

### 2.2 Barra de navegação (`components/NavBar.vue`)

Desktop: barra vertical à esquerda. Celular (< 768 px): barra horizontal no rodapé (50 px). O FMX segue o layout de desktop (§7.13).

| Ordem | Item | Ação | Indicadores |
|---|---|---|---|
| 1 | Avatar do usuário (ou inicial) | seção `config` | tooltip "Configurações"; se a imagem falha, re-resolve a URL |
| 2 | Chat | seção `chat` | — |
| 3 | Atividades | seção `atividades` | badge com `atividades.novas` (`99+` acima de 99) |
| 4 | Chamadas | seção `chamadas` | — |
| 5 | Anexos | seção `anexos` | — |
| 6 | Ramal | **abre o discador SIP** (não muda de seção) | só aparece se `sip.sipDisponivel` (config ativa); bolinha verde = registrado, amarela = conectando, vermelha = erro |

"Equipes" foi **removido** da barra em `bfb79d8`. Qualquer outra seção cai na tela "Em desenvolvimento".

### 2.3 Layout da seção Chat (`App.vue`)

```
[NavBar] [ChatSidebar (lista)] [main: CallBar? · ChatHeader · UploadIndicador · MessageList · MessageInput] [PainelGrupo?]
```

- 🔎 `PainelGrupo` ("Dados do grupo", CON-08) fica **à direita do chat**, dentro do layout a partir de 1024 px (`lg:static`) e **por cima** do chat (fixo à direita, com sombra) em janela menor; não aparece com a chamada cobrindo o app (`App.vue:165-172`).
- No celular só uma coluna aparece: lista **ou** conversa (`sidebarAberta`); botão de voltar no cabeçalho reabre a lista; tela vazia mostra "Selecione uma conversa." e (celular) botão "Ver conversas".
- Chamada de **vídeo** ativa e não minimizada cobre o app inteiro (`CallWindow` em `fixed inset-0`). Minimizada no desktop → janela flutuante arrastável/redimensionável; no celular → só a `CallBar` no topo, app utilizável.
- Chamada de **áudio** → só a `CallBar` (com controles) no topo da área do chat.

### 2.4 Painéis, modais e sobreposições

| Componente | Abre por | Conteúdo |
|---|---|---|
| `PesquisaAvancada` | lupa "Pesquisar em todos os chats" na lista | substitui a lista; pesquisa global |
| Menu da conversa (em `ChatSidebar`) | clique direito na conversa ou botão "Mais opções" | Fixar / Desafixar / Arquivar / Desarquivar |
| `UserInfoModal` | avatar na lista ou no cabeçalho (só conversa direta) | foto, nome, Email e Telefone (🔎 os dois com "Nao informado" se vazios), botão "Ver anexos" |
| `CreateGroupModal` | botão "Novo grupo" na lista | nome + seleção de contatos |
| 🔎 `PainelGrupo` (substitui o `GroupMembersModal`, apagado em `eaa8bac`) | avatar do grupo no cabeçalho (`title` "Dados do grupo") ou botão "Participantes e anexos"; os dois **alternam** abrir/fechar | "Dados do grupo": renomear, participantes (adicionar/remover) e anexos do grupo (CON-08) |
| `ForwardMessageModal` | ação Encaminhar | destinos (conversas e contatos) |
| `DetalheStatusMensagem` | hover 300 ms / clique no ✓ da própria mensagem | etapas de entrega |
| `MensagemAcoes` (menu + `EmojiPicker`) | 🔎 botão de **seta para baixo** (sem `title`) ao passar o mouse, clique direito na bolha (Ctrl + clique direito = só reações) | reações rápidas + ações |
| `DialogoConfirmacao` | Ocultar / cancelar agendada / encerrar votação / erros de download | diálogo do app |
| `AnexoPopup` | botão "Anexar" ("+") | Arquivo / Código / 🔎 **Votação** (só em grupo) |
| `EmojiPicker` (com abas Emojis/Figurinhas) | botão "Emoji" | |
| `CodigoModal` | Anexar → Código, ou colar texto > 10 linhas | editor CodeMirror |
| `AgendarMensagemModal` | botão relógio "Agendar mensagem" (aparece com conteúdo) | data + hora |
| 🔎 `MensagensAgendadasModal` | relógio com contador ao lado do microfone (campo vazio e agendadas na conversa) | "Mensagens agendadas": horário, resumo, "Cancelar" (§3.4, relógio de agendadas) |
| 🔎 `EnqueteModal` | "+" → "Votação" (só em grupo) | "Nova votação" (ENV-22) |
| 🔎 `EnqueteResumo` | revelar uma votação **oculta** (MSG-16) | resumo só de leitura: pergunta + contagem por opção |
| `MencaoDropdown` | digitar `@` | até 6 contatos |
| `BarraGravacao` | microfone | gravação de áudio |
| `ImageViewerModal` | clique em imagem/vídeo (chat, fila, anexos) | visualizador com galeria |
| `VisualizadorPdf`, `VisualizadorHtml` | botão "Abrir" em anexo PDF/HTML | |
| `IncomingCallModal` | evento 51 | atender / recusar / atender só assistindo |
| `VideoUpgradeModal` | evento 56 | Apenas assistir / Transmitir também |
| `AddUserToCallModal` (App) e modal interno do `CallWindow` | botão "Adicionar usuário" | contatos fora da chamada |
| `ChatChamada` | botão "Chat da chamada" no `CallWindow` | painel lateral (celular: por cima) |
| `SipDialerModal` | item Ramal da barra, ou chamada SIP recebida sendo conectada | discador flutuante arrastável |
| `SipIncomingCallModal` | INVITE SIP | atender / recusar |
| Overlay de arrastar arquivo | arrastar arquivos sobre a conversa | "Solte para enviar o arquivo" |
| Toast de erro | qualquer erro tratado no `App.vue` | topo, botão × |

### 2.5 Configurações (`components/ProfileSettingsModal.vue`, modo `inline`)

Título "Configuracoes" / "Preferencias da conta". Lista de abas à esquerda (celular: menu → sub-tela com botão voltar).

| Aba (id) | Título | Descrição exibida | Visibilidade |
|---|---|---|---|
| `usuario` | Usuario | Nome, email, avatar e senha | todos |
| `dispositivos` | Dispositivos | Sessao atual e perifericos locais | todos |
| `permissoes` | Permissoes | Notificacoes, microfone e camera | todos |
| `voip` | Voip | Configuracao SIP do usuario | todos |
| `cores` | Cores | Cores do sistema, salvas neste navegador | todos |
| `chamadas` | Chamadas | Qualidade do áudio, vídeo e tela | todos |
| `sistema` | Sistema | Configurações que valem para todos | só com permissão `parametros` |
| `acessos` | Acessos | Quem pode mexer no sistema e nas permissões | só com permissão `permissoes` |

Regra: link direto para aba restrita sem a permissão volta para `usuario` **depois** de as permissões carregarem. Fechar as configurações volta ao chat com a lista aberta e força reconexão do SIP (`sip.inicializarSessao(true)`).

---

## 3. Lista de funcionalidades (checklist de paridade)

Legenda dos campos: **Comportamento** (o que o usuário vê/faz), **API/WS** (rotas e eventos com campos), **Arquivos**, **Regras e casos de borda**.

### 3.1 AUT — Autenticação, sessão, perfil

**AUT-01 Login**
- Comportamento: tela com logo "Conversa", campos "Usuário" e "Senha", botão "Entrar" ("Entrando..."), link "Não tem conta? Criar conta". Foco inicial no usuário. Após sucesso pede permissão de notificação se ainda `default`.
- API: `POST /login {login, senha, dispositivo_id?}` → `{id, nome, email, telefone, avatar_identificador, token, dispositivo:{id,...}}` (sem o campo `login`; o cliente guarda o que foi digitado, `trim()`).
- 🔎 **O servidor não devolve `avatar_url` no login** (só `avatar_identificador`; doc 01 §2.1; `conversa/src/usuarios.ts:19-66`). O tipo do web declara o campo, e o web lê `response.avatar_url ?? null` e **resolve a URL depois**, com `GET /anexo?identificador=<avatar_identificador>` (`resolverAvatarUrl`, `stores/auth.ts:66-78,144-180`). O FMX deve fazer o mesmo: nunca esperar `avatar_url` no login.
- Arquivos: `components/LoginForm.vue`, `stores/auth.ts#login`.
- Regras: `dispositivo_id` salvo é reenviado para reaproveitar o dispositivo; resposta sem token → erro "Resposta de login invalida: token ausente".

**AUT-02 Cadastro**
- Comportamento: "Crie sua conta" com Nome, Usuário, E-mail, Senha (`minlength=4` no HTML), botão "Cadastrar"/"Cadastrando..."; sucesso mostra "Conta criada com sucesso!" e volta ao login após 1,5 s. Link "Já tem conta? Entrar".
- API: `PUT /usuario {nome, login, email, senha}`.
- Arquivos: `components/RegisterForm.vue`.

**AUT-03 Início de sessão resiliente** — ver §1.5 (401 → login; outro erro → mantém login e tenta a cada 5 s com toast "(tentando de novo...)"). Testes: `tests/unit/App.test.ts`.

**AUT-04 Registro de dispositivo e token de push**
- API: `PATCH /dispositivo {id, nome, modelo, versao_so, plataforma}` e `PATCH /dispositivo {id, token_fcm}`.
- Arquivos: `stores/auth.ts#detectarNavegador/registrarTokenFCM`.
- FMX: só o primeiro `PATCH`, com `plataforma: 'Windows'` e sem `token_fcm` (§1.6).

**AUT-05 Logout** — botão "Sair" (ícone) na aba Usuário. Local apenas (§1.5).

**AUT-06 Editar dados do perfil**
- Comportamento: seção "Dados do usuario" — Nome, Email, botão "Salvar dados"; mensagens "Preencha nome e email." / "Dados atualizados com sucesso.".
- API: `PATCH /usuario {id, nome, email}` (o tipo aceita também `telefone`, mas a tela não edita telefone).
- Arquivos: `ProfileSettingsModal.vue#salvarPerfil`.

**AUT-07 Alterar senha**
- Comportamento: "Senha atual", "Nova senha", "Confirmar nova senha", botão "Salvar senha".
- Validações no cliente: todos preenchidos ("Preencha todos os campos de senha."), nova ≥ 6 ("A nova senha deve ter pelo menos 6 caracteres."), confirmação igual ("A confirmacao da senha nao confere."). Sucesso: "Senha alterada com sucesso." e limpa os campos.
- API: `POST /alterar-senha {senha_atual, senha}` (o servidor confere a atual).

**AUT-08 Avatar (foto de perfil)**
- Comportamento: "Foto de perfil" — "Alterar foto" ("Enviando...") / "Remover"; prévia local + % de progresso sobre o avatar.
- Processamento: recorte quadrado central, 256×256, JPEG qualidade 0,85 (`utils/imageResize.ts`), nome `avatar.jpg`.
- API: upload (§1.7, tipo 2) → `PATCH /usuario {id, avatar_anexo_id}` → `GET /anexo?identificador=` para a URL. Remover: `PATCH /usuario {id, avatar_anexo_id: null}`.
- Regra: URL do avatar expira; ao falhar a `<img>` chama `auth.renovarAvatarExpirado(url)` (renova no máximo a cada 30 s, só se a URL que falhou for a atual).

**AUT-09 Permissões do sistema do usuário logado**
- API: `GET /usuario/permissoes` → `string[]` (códigos `parametros`, `permissoes`). Só controla visibilidade das abas Sistema/Acessos; o servidor confere em cada rota.

**AUT-10 Ver perfil de outro usuário** (`UserInfoModal.vue`)
- Abre ao clicar no avatar da conversa **direta** (lista ou cabeçalho). Mostra foto/inicial, nome, Email e Telefone (🔎 **"Nao informado" vale para os dois** quando vazios, não só para o Telefone — `UserInfoModal.vue:31,35`) e botão **"Ver anexos"** que leva a `/anexos/:conversaId`.
- Dados vêm de `GET /usuario/contatos` (fallback: dados da própria conversa).

### 3.2 CON — Conversas

**CON-01 Lista de conversas** (`components/ChatSidebar.vue`)
- API: `GET /conversas` → `Conversa[]` (`id, descricao, tipo, nome, destinatario_id, mensagem_id, ultima_mensagem, ultima_mensagem_texto, mensagens_sem_visualizar, avatar_url, fixada_ordem, arquivada_em`).
- Item: avatar (ou inicial — primeira letra, `Array.from` para não quebrar emoji), bolinha verde se o destinatário da direta está online, título (`descricao || nome || "Conversa #id"`), etiqueta "Grupo", ícone de alfinete se fixada, contador de não lidas (oculto em arquivadas), prévia `resumirTexto(ultima_mensagem_texto)` ou "Sem mensagens", três pontinhos animados se alguém digita, botões "Mais opções" e "Abrir em nova janela" (hover).
- Ordem: fixadas primeiro por `fixada_ordem`; depois por `mensagem_id` desc. Arquivadas numa seção recolhível no fim: botão "Arquivadas (N)".
- Prévia: menção `@[Nome](id)` vira `@Nome`; cada bloco de código vira `Código (linguagem)`; mensagem oculta aparece como o servidor mandar em `ultima_mensagem_texto` (o web recarrega a lista após ocultar para mostrar "Mensagem oculta").
- Recarregada em: nova mensagem, status de mensagem (WS 3), conversa atualizada (WS 40), envio de mensagem, leitura.

**CON-02 Filtro da lista e "Nova conversa"**
- Campo "Pesquisar..." filtra localmente por título e pela prévia. Com termo, as arquivadas aparecem junto com a etiqueta "Arquivada" e não há arraste.
- Abaixo, seção "Nova conversa" com contatos que **não** têm conversa direta, filtrados por nome/login/email; clicar cria/abre a conversa direta. 🔎 A seção **só aparece com termo digitado**: sem termo a lista de contatos é vazia (`ChatSidebar.vue:407-420`).

**CON-03 Fixar, desafixar e reordenar fixadas**
- Menu: "Fixar" (entra no fim das fixadas) / "Desafixar". Arrastar uma fixada sobre outra (metade de cima = antes, de baixo = depois) reordena; linha azul indica a posição. Sem mudança → não chama a API.
- API: `PATCH /conversa/fixadas {conversas: number[]}` — a lista completa na ordem; as que ficam de fora deixam de ser fixadas. Atualização otimista; erro → recarrega `GET /conversas`.
- Arquivos: `stores/chat.ts#fixarConversa/moverFixada/salvarFixadas`.

**CON-04 Arquivar / desarquivar**
- Menu: "Arquivar" / "Desarquivar". Arquivar tira das fixadas e fecha a notificação da conversa.
- Regra: arquivada **não toca som nem notifica**, mas as mensagens continuam chegando; o contador de não lidas não aparece nela.
- API: `PATCH /conversa/arquivada {conversa, arquivada}` → `{id, arquivada}`. Otimista; erro → recarrega.

**CON-05 Menu de contexto da conversa** — clique direito ou botão "Mais opções" (três pontos, no hover); posicionado no clique e recuado pelo tamanho real para não sair da janela; fecha com clique fora, Esc ou redimensionar. Itens conforme CON-03/04. Desktop: §7.4.

**CON-06 Conversa direta (obter ou criar)**
- Reaproveita a direta existente (`tipo=1 && destinatario_id`). Senão: `PUT /conversa {descricao:'', tipo:1}` → `PUT /conversa/usuario {conversa_id, usuario_id}` para o próprio usuário e para o contato → `GET /conversas`.
- Usada por: "Nova conversa", nome de membro na lista do cabeçalho do grupo (🔎 aberta ao passar o mouse no título, CON-09), clique numa menção, encaminhar para contato, responder no privado.

**CON-07 Criar grupo** (`CreateGroupModal.vue`)
- "Criar grupo": "Nome do grupo" (placeholder "Ex: Projeto Alpha"), "Selecionar usuários" com filtro "Filtrar contatos" (nome/login/email) e checkboxes; "Cancelar" / "Criar"; Esc cancela.
- Validações: "Informe o nome do grupo." / "Selecione ao menos um usuário.".
- API: `PUT /conversa {descricao, tipo:2}` → `PUT /conversa/usuario` para cada membro **incluindo o criador** (em paralelo, sem duplicar) → recarrega e abre o grupo.

**CON-08 Dados do grupo: nome, participantes e anexos** (`PainelGrupo.vue`) — 🆕 `eaa8bac`: substitui o modal "Gerenciar membros do grupo" (`GroupMembersModal.vue`, **apagado**). 🔎 Reescrito na revalidação: o corpo antigo descrevia o modal apagado ("Membros do grupo", select "Selecionar usuario", "Adicionar"/"Adicionando..." não existem mais).
- **Abertura:** pelo **avatar do grupo** no cabeçalho (`title` "Dados do grupo") ou pelo botão **"Participantes e anexos"** (ícone de pessoas, só em grupo). Os dois **alternam** abrir/fechar; o "×" (`title` "Fechar") fecha (`ChatHeader.vue:19-20,113-120`; `App.vue:129,165-172,369`).
- **Onde:** painel à direita do chat, 320 px (`sm:w-80`); dentro do layout a partir de 1024 px e **por cima** do chat em janela menor. Some quando a conversa ativa não é grupo, fora da seção Chat ou com a chamada cobrindo o app; **continua aberto** ao trocar de grupo (recarrega os dados do novo).
- **Parte de cima** (rola sozinha, até metade da altura):
  - título "Dados do grupo";
  - campo "Nome do grupo" + botão **"Renomear"** ("Salvando..."), habilitado só com nome não vazio e diferente do atual; sucesso "Grupo renomeado com sucesso.";
  - "**N participantes**" + botão **"Adicionar pessoas"**, que alterna uma caixa de busca "Buscar contato..." (com foco automático) entre os contatos **fora do grupo**, filtrados por nome. Clicar num contato adiciona ("Adicionando..." no item). Vazio: "Nenhum contato encontrado", ou "Todos os contatos já estão no grupo" se não sobra nenhum. Sucesso "Participante adicionado com sucesso.";
  - lista de participantes: foto (ou inicial), **bolinha verde** se online (PRE-01), nome, "(você)" no próprio usuário; botão **"Remover"** em vermelho, visível no hover da linha (ou com foco), nunca no próprio usuário ("Removendo..."; sucesso "Participante removido com sucesso."). Sem membros: "Nenhum membro";
  - erro numa faixa vermelha (mensagem do servidor, ou "Erro ao renomear o grupo" / "Erro ao adicionar" / "Erro ao remover"); sucesso numa faixa verde.
- **Parte de baixo:** "Anexos", com a mesma `AnexosLista` da página de Anexos (ANX-13), já filtrada pela conversa do grupo; abre a galeria ou a mensagem (MSG-06).
- **API:** `GET /conversa/usuarios?conversa=` (relido ao abrir e ao trocar de grupo) → `[{id (conversa_usuario_id), usuario_id, nome, avatar_url}]`; `PATCH /conversa {id, descricao}` → recarrega `GET /conversas`; `PUT /conversa/usuario {conversa_id, usuario_id}` e `DELETE /conversa/usuario?id=<conversa_usuario_id>` → relê os membros; `GET /anexos?conversa=<id>&…` (ANX-13).
- **Regras:** não há regra de administrador no cliente: todo membro vê "Renomear", "Adicionar pessoas" e "Remover". O servidor só aceita remover o **próprio** vínculo (`validarRemocaoConversaUsuario`, `conversa/src/autorizacao.ts:18-26`; pendência S15 do doc 08). Como o painel só mostra "Remover" nos **outros**, na prática todo "Remover" do painel volta com o erro de acesso negado do servidor, e não há como sair do grupo pela tela.
- FMX: painel (`TLayout`/frame) à direita do chat, com o mesmo comportamento; a lista de anexos reaproveita a da página de Anexos.

**CON-09 Cabeçalho da conversa** (`ChatHeader.vue`) — 🔎 corrigido na revalidação: não existe mais "Gerenciar membros" nem a "faixa de chips" de membros.
- Avatar: na direta, clicável → AUT-10; em grupo, clicável com `title` **"Dados do grupo"** → CON-08. Bolinha online (direta). Título `descricao || nome || "Conversa #id"`.
- Subtítulo em grupo: nomes dos membros separados por vírgula (some quando alguém digita/grava). **Ao passar o mouse no título** abre uma **lista suspensa** com foto (ou inicial) e nome de cada membro (até 192 px de altura, com rolagem); clicar num membro abre a conversa direta com ele (CON-06) (`ChatHeader.vue:30-67`).
- Indicador animado de digitando/gravando (ver ENV-15/ENV-16).
- Botões: "Chamada de voz", "Chamada de video", "Compartilhar tela" (escondidos durante chamada ou chamada recebida); em grupo, **"Participantes e anexos"** (abre/fecha o painel do CON-08; continua visível durante a chamada); pesquisa na conversa (desktop: campo inline "Pesquisar...", Enter pesquisa, × limpa; celular: botão "Pesquisar na conversa" que abre o painel "Pesquisar nesta conversa") (`ChatHeader.vue:19,52,59,70-128`).

**CON-10 Abrir conversa em nova janela (popup)** — 🔎 completado na revalidação (o que o popup não tem e a falta de canal com a janela principal).
- Botão "Abrir em nova janela" no hover de cada item da lista (telas ≥ 768 px) → `window.open('/chat-popup.html?conversa=<id>', 'chat-popup-<id>', 'width=900,height=700,left=…,top=…')`, **centralizada sobre a janela atual**; o nome `chat-popup-<id>` faz a mesma conversa reaproveitar a mesma janela (`App.vue:834-846`).
- O popup (`chat-popup.ts` → `ChatPopup.vue`) monta **outra instância do Pinia** (`chat-popup.ts:13-15`), aplica as cores personalizadas e chama `chat.inicializar()`: contatos, conversas, **WebSocket e polling próprios** e pedido de permissão de notificação. Mostra "Carregando conversa...", depois o cabeçalho (sem botão de voltar), indicador de upload, lista, campo, visualizador de imagens, pré-visualização e encaminhamento. Título da janela = `descricao || nome || 'Conversa'`. Sem sessão: "Sessao expirada. Faca login novamente."; id inválido ou ≤ 0: página só com "Conversa invalida."; conversa inexistente: "Conversa nao encontrada.".
- **O que não tem:** barra de navegação, lista de conversas, camada de arrastar (arquivo solto sobre o campo entra no ponto do mouse), `beforeunload`, tratamento de chamadas (o handler não é registrado: chamadas não tocam no popup). Os botões de ligar e o "Dados do grupo" **aparecem no cabeçalho, mas não têm efeito** (`ChatHeader.vue:90-109` emite os eventos; `ChatPopup.vue:16-19` não os escuta) — leitura de código, **não confirmado em execução**.
- **Nenhum canal com a janela principal** (sem `BroadcastChannel`, `postMessage` nem evento `storage`, exceto o das cores). As duas janelas são **duas conexões do mesmo usuário** e se sincronizam só pelo servidor: como o servidor não manda WS 2 ao próprio remetente nem WS 3 ao próprio leitor, mensagem enviada ou lida numa janela só aparece na outra quando algo a faz recarregar. As duas tratam o mesmo WS 2: o **som pode tocar duas vezes** e a notificação sai em dobro (a segunda substitui a primeira pela `tag`) — **não confirmado em execução**.
- FMX: janela do **mesmo processo**, com o mesmo WebSocket e o mesmo cache (§7.5).

**CON-11 Contatos**
- API: `GET /usuario/contatos` → `Contato[]` (`id, nome, login, email, telefone, avatar_url?`). Regra de avatar usada em várias telas: a lista de contatos pode não trazer foto → usa o `avatar_url` da conversa direta com o contato; o próprio usuário usa o avatar do perfil.

**CON-12 Deep link, histórico e âncora** — §2.1. Clique em notificação abre a conversa e **recarrega as mensagens** antes (as em memória não têm as que chegaram fechada).

**CON-13 Conversa atualizada em tempo real** — WS tipo 40 → `GET /conversas`.

### 3.3 MSG — Mensagens: exibição e leitura

**MSG-01 Carregamento e paginação bidirecional** (`stores/chat.ts`, `composables/useScrollManager.ts`)
- Abrir conversa: `GET /mensagens?conversa=X&mensagemreferencia=0&mensagensprevias=80&mensagensseguintes=0`. Mensagens otimistas ainda enviando são preservadas.
- Rolar para cima: prefetch quando chega a 1,5× a altura visível do topo; injeta ao chegar no topo, compensando a rolagem. `GET /mensagens?conversa=X&mensagemreferencia=<primeira salva>&mensagensprevias=60&mensagensseguintes=0`. Para quando volta vazio.
- Rolar para baixo (só depois de pular para uma mensagem antiga): `mensagensprevias=0&mensagensseguintes=60` a partir da última salva.
- Ordem: `coalesce(visivel_em, inserida)` e depois `id`; ids negativos (enviando) no fim (`utils/ordemMensagens.ts`). Referência de paginação sempre uma mensagem com id > 0.
- Indicadores: "Carregando mensagens", "Carregando mensagens anteriores", "Carregando mensagens seguintes".

**MSG-02 Separadores e agrupamento**
- Separador de dia com `toLocaleDateString('pt-BR', {weekday:'short', day, month, year})` (ex.: "seg., 05/10/2026").
- Em grupo, o nome do remetente aparece acima das bolhas recebidas; `mudouRemetente` controla o espaçamento.

**MSG-03 Indicador "Últimas" (não lidas)** (`MessageList.vue`)
- Linha "Últimas" inserida antes da primeira não lida. Regras:
  1. A posição é fixada na primeira aparição; novas mensagens não a movem.
  2. Fica enquanto a conversa está aberta (não some após ler); sai ao trocar de conversa.
  3. Se a janela perdeu o foco e chega mensagem nova, a linha passa para cima dessa mensagem.
  4. Mensagem nova com a janela focada e a rolagem a ≤ 500 px do fim não gera a linha.
  5. O auto-scroll não empurra a linha para fora da tela enquanto houver não lidas.
- Ao abrir conversa com não lidas: posiciona a primeira não lida no topo (margem 40 px); sem não lidas: rola ao fim e "gruda" no fim enquanto o conteúdo cresce (imagens, áudio, código).

**MSG-04 Marcar como visualizada**
- Só com a janela focada (`document.hasFocus()`; ao voltar o foco, reavalia). A cada rolagem/foco, cada mensagem de outro, ainda não visualizada, **totalmente visível** (ou com o fim visível) é marcada. FMX: "focada" = `Application.Active` e o form que mostra a conversa ativo e não minimizado (§7.11).
- API: `POST /mensagem/visualizar {conversa, mensagem}` — **uma chamada por mensagem**. Sucesso marca `visualizada=recebida=true`, desconta do contador da conversa (otimista); ao chegar a 0 fecha a notificação dessa conversa; recarrega `GET /conversas`. Falha não desconta.

**MSG-05 Botões de rolagem**
- Botão "Ir para o final" quando a > 1000 px do fim (se houve salto para mensagem antiga, recarrega as 80 últimas e vai ao fim sem animação).
- Botão flutuante "Há novas mensagens" quando chega mensagem e o usuário está longe do fim.

**MSG-06 Ir para uma mensagem**
- Se não está carregada: `GET /mensagens?conversa&mensagemreferencia=<id>&mensagensprevias=30&mensagensseguintes=30` (se não vier, tenta 120/120); **substitui** a lista e ativa paginação nos dois sentidos. Centraliza a mensagem e a destaca com anel amarelo por 1,2 s.
- Usado por: resultado de pesquisa, citação de resposta, atividade, "Abrir mensagem" nos anexos. Encaminhada de outra conversa abre a conversa de origem **se o usuário participa dela**.
- Erro: "Nao foi possivel localizar esta mensagem no contexto da conversa.".

**MSG-07 Classificação das bolhas** (`utils/classificarMensagem.ts`, por prioridade)

| Tipo | Componente | Condição |
|---|---|---|
| Excluida | `BolhaExcluida` | `excluida_em` preenchido (antes de tudo) |
| Chamada | `BolhaChamada` | conteúdo único tipo 6 |
| Imagem | `BolhaImagem` | conteúdo único tipo 2, sem referência |
| Enquete 🆕 | `BolhaEnquete` | conteúdo único tipo 8 (**com ou sem** referência; vem antes de Figurinha) |
| Figurinha | `BolhaFigurinha` | conteúdo único tipo 7, sem referência |
| Codigo | `BolhaCodigo` | texto único só com blocos de código, sem referência |
| Emoji | `BolhaEmoji` | texto único só com emojis, sem referência (fonte grande) |
| ComReferencia | `BolhaReferencia` | tem `mensagem_referencia.mensagem` |
| TextoCurto | `BolhaTextoCurto` | texto único, uma linha, ≤ 60 caracteres |
| Padrao | `BolhaPadrao` | demais |

Hora (`HH:MM`) dentro da bolha (`MensagemStatus.vue`), posição conforme variante (sobre a imagem com sombra radial, etc.).

**MSG-08 Ícone de status de entrega** (só nas próprias mensagens, fora da bolha; não em mensagem de chamada)
- `enviando` (relógio) → enviada (✓) → `recebida` (✓✓ cinza) → `visualizada` (✓✓ cor primária).

**MSG-09 Detalhe do status** (`DetalheStatusMensagem.vue`)
- Abre com o mouse parado 300 ms sobre o ✓ (ou clique/toque); sai ao tirar o mouse; o clique alterna (§7.4).
- API: `GET /mensagem/status/detalhe?id=<mensagemId>` → `[{usuario_id, nome, recebida, visualizada, reproduzida}]` (datas ou null).
- Direta: etapas "Enviada" (visivel_em ou inserida), "Recebida", "Visualizada", "Ouvida" (só áudio tipo 4/5), "Oculta" (se oculta); sem data → "Aguardando".
- Grupo: seções "Visualizada por (N)", "Recebida por (N)", "Aguardando (N)" com horário; linha "Oculta" no topo se oculta.
- Formato: hoje só `HH:MM`; outros dias `dd/MM HH:MM`. Erro: "Não foi possível carregar o status.".

**MSG-10 Atualização de status em tempo real**
- WS tipo 3 `{grupo: conversaId, mensagens: "12,13,14"}` → `GET /mensagem/status?conversa=X&mensagem=12,13,14` → `[{mensagem_id, recebida, visualizada, reproduzida, excluida_em}]` → atualiza na tela. Se algum id não está carregado e é a conversa ativa → recarrega as mensagens. Sempre recarrega `GET /conversas`.
- **Ocultar feito pelo autor em outro aparelho chega por aqui** (`excluida_em`).

**MSG-11 Links clicáveis** (`utils/formatters.ts#parseLinks`)
- Regex `https?://…` ou `www.…`; pontuação final `.,;:!?'` sai do link; `)` só sai se não fechar um `(` do próprio link. `www.` ganha `https://`. Abre em nova aba (`noopener`).

**MSG-12 Menções na mensagem**
- Formato no texto: `@[Nome](usuarioId)`. Renderizada como botão `@Nome` destacado; hover mostra cartão com foto e nome; clique abre a conversa direta com a pessoa (`MencaoLink.vue`).

**MSG-13 Mensagem de chamada** (`BolhaChamada.vue`)
- Conteúdo tipo 6 com JSON `{chamada_id, tipo, status, iniciada, finalizada, duracao, participantes:[{usuario_id, nome, status, duracao}]}`.
- Título "Chamada de audio|video" (+ " em grupo" se > 2 participantes). Direta: "<remetente> · mm:ss" ou status ("Recusada"=2, "Perdida"=5, "Cancelada"=6). Grupo: lista de participantes com duração ou status ("Perdida"=1, "Recusou"=2, "Desconectou"=5). Cores: verde encerrada (4), vermelho recusada/perdida. Sem menu de ações e sem status de entrega.

**MSG-14 Mensagem só de emojis** — fonte grande, sem fundo de bolha (`BolhaEmoji`).

**MSG-15 Blocos de código** (`MessageContent.vue`, `utils/codeBlocks.ts`)
- Detecção: abertura com 3+ crases + linguagem + quebra de linha; fechamento numa linha só de crases com pelo menos o mesmo tamanho; blocos internos com linguagem aninham; para `md/markdown` fecha na última linha de crases; crases coladas no fim também fecham.
- Cabeçalho com a linguagem (ou "code"), botão "Copiar" ("Copiado!" por 2 s).
- Destaque de sintaxe (highlight.js; aliases js/ts/py/sh/cs/delphi/md/html/xml/texto…).
- Bloco longo: recolhido em altura máxima (~240 px) com degradê e botão "Expandir código"/"Recolher código", re-medido quando muda de tamanho.
- Blocos ` ```md ` / ` ```markdown ` aparecem **formatados** (marked GFM + breaks, sanitizado, links em nova aba) e ` ```mermaid ` como **diagrama** (também dentro de Markdown); alternância "Visualizar" / "Código". O diagrama usa as cores do tema atual.

**MSG-16 Mensagem oculta** (antigo "excluída") — `BolhaExcluida.vue`
- Mostra "Mensagem oculta" + hora/status. Clique alterna revelar/ocultar o conteúdo original ("Mensagem oculta" continua no topo); clicar em controles do conteúdo (botões, links, áudio, vídeo, imagem) não alterna. Tooltip "Clique para ver o conteúdo" / "Clique para ocultar o conteúdo".
- Sem menu de ações e sem reações. Não entra na galeria do visualizador. Citações de mensagem oculta mostram "Mensagem oculta" sem o conteúdo.
- 🆕 `eaa8bac` Votação oculta: ao revelar, mostra o resumo só de leitura (`EnqueteResumo.vue`): "📊 <pergunta>" e cada opção com a contagem (tooltip com os nomes ou "Ninguém votou"); "Carregando votação..." / erro.

**MSG-17 Selo de mensagem agendada** (só o autor vê antes da hora) — 🆕 `7322e83`: **substituído** pela lista do relógio (ver §12); a agendada não aparece mais no chat antes da hora. A descrição abaixo é histórica.
- Acima da bolha: "Agendada para hoje HH:MM" / "amanhã HH:MM" / "dd/MM HH:MM". Some exatamente na hora (timer agendado, não espera o ciclo de 30 s — `useAgora.ts`).

**MSG-18 Modo conexão lenta**
- Com `navigator.connection.effectiveType` em `slow-2g`/`2g`: imagens mostram "Toque para abrir" e vídeos "Toque para carregar" antes de baixar (`useConexao.ts`). 🔎 Sem a API (Firefox, Safari) a conexão conta como rápida e nunca bloqueia (`composables/useConexao.ts:9-38`). No desktop a regra quase nunca dispara; para o FMX ver §7.10.

**MSG-19 Citação (resposta/encaminhada) na bolha** (`BolhaReferencia.vue`, `ReferenciaRecursiva.vue`) — 🆕 `7322e83`: dentro da citação, a encaminhada também não repete o que já aparece na citação de baixo (§12)
- Bloco com título: remetente (resposta) ou "Encaminhado de <remetente>" / "Encaminhado"; hora; conteúdos da original (imagens, áudio etc.), citação aninhada recursiva até profundidade 5. Clique no título vai para a original (MSG-06).
- Encaminhada: conteúdos próprios iguais aos da referência não são repetidos — só aparece o que foi acrescentado.

### 3.4 ENV — Mensagens: composição e ações

**ENV-01 Enviar texto** — 🆕 o campo agora é rico (ENV-21); só texto continua indo como antes (`MessageInput.vue`, `stores/chat.ts#enviarMensagemComConteudos`)
- Campo "Digite uma mensagem", 🔎 cresce até **40% da altura da janela** (`max-h-[40vh]`, com rolagem; o "120 px" do original está superado — `MessageInput.vue:375`). **Enter envia**; Shift+Enter quebra linha (hoje no editor Tiptap, `editor/pecas.ts:150-151`). Botões "Agendar mensagem" e "Enviar" aparecem quando há conteúdo (texto, peças ou resposta); sem conteúdo aparecem o microfone ("Gravar áudio") e, se houver agendadas na conversa, o relógio (ver "Relógio de agendadas" abaixo).
- Envio otimista: mensagem com `id = -Date.now()`, `enviando:true` aparece na hora; após `PUT /mensagem` troca pelo id do servidor; erro remove a otimista e mostra o erro acima do campo.
- API: `PUT /mensagem {conversa_id, conteudos:[{ordem, tipo, conteudo}], mensagem_referencia?:{tipo, origem_mensagem_id}, visivel_em?: ISO}` → `{id, conversa_id, usuario_id}`.
- Regras: texto `trim()`; pode enviar só a resposta (sem texto) — ver ENV-07. Após enviar, rola ao fim e recarrega a lista de conversas.

**ENV-02 Atalhos de emoji no texto** (`utils/emojiAtalhos.ts`)
- `:)`/`:-)`→🙂, `:D`/`:-D`→😃, `xD`/`XD`→😆, `;)`/`;-)`→😉, `:(`/`:-(`→🙁, `:'(`→😢, `:P`/`:p`→😛, `:O`/`:o`→😮, `:|`→😐, `:/`→😕, `:*`→😘, `<3`→❤️, `\o/`→🙌.
- Só como palavra solta (início/espaço antes e espaço/quebra depois, ou no fim ao enviar); nunca dentro de código (crases).
- 🔎 No editor Tiptap o atalho só vira emoji **ao digitar o espaço** depois dele, ou no **envio** (o último atalho do texto); a **quebra de linha não converte** (`editor/pecas.ts:116-137`; `MessageInput.vue:938-940`). A lista (20 atalhos) confere com `utils/emojiAtalhos.ts:5-40`.

**ENV-03 Seletor de emoji** (`EmojiPicker.vue`)
- Categorias "Populares", "Rostos", "Gestos", "Objetos" (listas fixas); tooltip com nome em português (`utils/emojiNomes.ts`). 🔎 Insere **no ponto do cursor** (o cursor é guardado quando o campo perde o foco — ENV-21) e devolve o foco.

**ENV-04 Figurinhas (Lottie)** — 🆕 com o campo **vazio** a figurinha é enviada na hora, sozinha; com algo escrito ela **entra no campo** no ponto do cursor e vai junto, na ordem (ENV-21)
- Aba "Figurinhas" no seletor do campo de mensagem (abre sempre em "Emojis"). Pacotes: **Básico** (coracao, sorriso, risada, estrela, feito, festa, sono, pontinhos), **Rostos** (piscadinha, apaixonado, beijo, legal, surpreso, triste, bravo), **Coisas** (joinha, fogo, coracao-partido, presente, bolo, balao, cafe, sol, chuva).
- Com o campo vazio, clicar **envia na hora**, sozinha (pode ir como resposta se houver resposta pendente); com algo escrito, entra no campo (ver o cabeçalho do item).
- Conteúdo tipo 7 com o identificador `pacote/nome`; animação em `/figurinhas/<pacote>/<nome>.json` (servida pela página, não pela API). Bolha 160 px; no picker 64 px; na resposta 120 px. Toca só quando visível; com "reduzir movimento" fica parada no quadro do meio. Falha → texto "Figurinha". Nome amigável em `nomeFigurinha()`.
- Arquivos: `utils/figurinhas.ts`, `FigurinhaLottie.vue`, `BolhaFigurinha.vue`, `public/figurinhas/**`, `scripts/gerar-figurinhas.ts`.

**ENV-05 Menções no campo** — 🔎 corrigido na revalidação: não existe mais a "camada de realce atrás do textarea"; a menção é um **nó Mention do Tiptap**.
- Digitar `@` + texto abre lista com até 6 contatos (nome/login); ↑/↓ navegam, Enter/Tab confirmam, Esc fecha; clique também (`MessageInput.vue:325-347`; `MencaoDropdown.vue:45-47`). Com a lista aberta, o **Enter confirma a menção** em vez de enviar.
- A busca aceita espaços depois do `@` (`allowSpaces`). A menção entra como uma **peça dentro da linha de texto** (`@Nome` destacado), apagada inteira pelo Backspace (`deleteTriggerWithBackspace`) — `editor/pecas.ts:75-91`.
- No envio vira `@[Nome](id)` (`blocosDoDocumento`). Texto colado com `@[Nome](id)` é convertido em menção com o id guardado. "@Ana" não casa com "@Anabela".
- Arquivos: `editor/pecas.ts#criarMencao`, `utils/mencoesTexto.ts`, `MencaoDropdown.vue`.

**ENV-06 Responder**
- Ação "Responder" → barra acima do campo com nome e resumo (`resumoMensagem`) e botão ×; foco no campo.
- Envio leva `mensagem_referencia {tipo:1, origem_mensagem_id}`. Mensagem otimista já mostra a citação.

**ENV-07 Responder no privado** (só em grupo, em mensagem de outro)
- Abre/cria a conversa direta com o remetente e deixa a mensagem como **encaminhada** pendente (barra "Encaminhando de <remetente>").
- No envio: `mensagem_referencia {tipo:2}` e os conteúdos da original vão **antes** do texto digitado (ordens 1..n, depois o texto).

**ENV-08 Encaminhar** (`ForwardMessageModal.vue`)
- "Encaminhar mensagem" / "Escolha uma conversa ou contato para receber esta mensagem." / "Mensagem selecionada" (resumo) / campo "Buscar destino" ("Nome da conversa ou contato").
- Destinos: todas as conversas exceto a de origem (rótulos "Grupo existente" / "Conversa direta existente", etiqueta "Conversa") + contatos sem conversa direta ("Novo chat direto"/email, etiqueta "Contato"). "Nenhum destino encontrado.".
- API: `PUT /mensagem` no destino com os conteúdos copiados (reordenados 1..n) e `mensagem_referencia {tipo:2, origem_mensagem_id}`; contato sem conversa → cria a direta antes. Depois abre o destino.

**ENV-09 Colar código e colar texto longo** (`MessageInput.vue#aoColarNoChat`, `utils/codeBlocks.ts`)
- Texto colado com **mais de 10 linhas** (`texto.trim().split('\n').length > 10`) → abre a janela "Inserir código" já preenchida, com linguagem detectada (`markdown` se há linha começando com ` ``` `; `texto` se é desenho ASCII; senão heurística). **Cancelar cola o texto como estava** (a janela é só sugestão); 🔎 fechar pelo "×" ou por **clique fora** também cola o texto cru (`MessageInput.vue:1022-1027`).
- Texto com cara de código (≥ 2 linhas, metade com cara de código + sinal forte; ou ≥ 50% desenho ASCII; ou ≥ 50% comandos de terminal) → 🔎 **entra já cercado**, numa linha própria, com a linguagem detectada (não entra cru para depois virar bloco). O Ctrl+Z desfaz a **colagem inteira** (não "volta ao texto cru") — `MessageInput.vue:1030-1036`.
- Cerca = uma crase a mais que a maior sequência de crases do código (mín. 3).
- Detecção de linguagem: JSON válido; regras para html, sql, pascal, csharp, typescript, python, javascript, css, bash; senão highlight.js (relevância ≥ 3) ou `texto`.
- Ordem completa da colagem (peças do próprio campo, arquivos, texto longo, código, texto comum) e a adaptação ao FMX: §7.3.

**ENV-10 Janela "Inserir código"** (`CodigoModal.vue`)
- Seletor de linguagem (`texto, javascript, typescript, python, sql, json, html, css, bash, csharp, pascal, markdown, mermaid` + a detectada, se fora da lista), editor CodeMirror (tema claro/escuro), placeholder "Cole ou escreva seu código aqui...", "Cancelar"/"Enviar", **Ctrl/Cmd+Enter envia**. Enviar **envia imediatamente** a mensagem com o bloco cercado (substitui o texto do campo, que fica limpo).
- 🔎 **Esc não fecha** a janela (não há tratamento). Ela fecha pelo "×", por "Cancelar" ou por clique fora (`CodigoModal.vue:2,6-7,36,43,80,161,167-170`). Para o FMX, recomenda-se Esc = Cancelar (§7.1).

**ENV-11 Colar imagem e arquivos** — 🔎 reescrito na revalidação: não é mais "imagem → fila de anexos" (a fila não existe desde `39d06f9`).
- **Qualquer arquivo** na área de transferência (não só imagem) entra como **peça no ponto do cursor** (ENV-21).
- Arquivo **sem nome** (captura de tela) ganha `print-<Date.now()>.<ext>`, com a extensão pelo mime (`png`, `jpg`, `webp`, `gif`, `bmp`; padrão `png`) — `MessageInput.vue:988-990`; `utils/formatters.ts:134-142`.
- **GIF copiado:** se veio um único arquivo de imagem e o HTML copiado tem `<img src="data:image/gif;base64,...">`, entra o GIF inteiro (animado) como `gif-<ms>.gif` (`MessageInput.vue:983-986`; `utils/copiarImagem.ts:38-49`).
- **Peças copiadas do próprio campo** colam como peças (copiar e colar uma peça a duplica); peça cujo arquivo o campo não tem mais é descartada (`MessageInput.vue:380-384,979-980`).

**ENV-12 Teclado do campo**
- Tab insere 4 espaços (Shift+Tab sai do campo, comportamento padrão do navegador).
- Qualquer letra digitada fora de um campo, sem modal por cima, foca o campo de mensagem no fim do texto e o caractere entra nele. 🔎 Ignora: evento já tratado, composição (IME), Meta, **Ctrl ou Alt sem AltGr**, foco em `INPUT`/`TEXTAREA`/`SELECT`/editável, Espaço com foco em botão ou link, e campo **coberto por modal** (testado com `elementFromPoint` no centro do campo) — `MessageInput.vue:1040-1057`; `editor/pecas.ts:152`.
- Campo recebe foco ao trocar de conversa e ao iniciar resposta.
- Lista completa de teclas e a adaptação ao FMX: §7.1.

**ENV-13 Agendar mensagem** (`AgendarMensagemModal.vue`) — 🆕 `7322e83`: depois de agendar, a mensagem vai para o relógio ao lado do microfone, não para o chat (§12)
- Botão "Agendar mensagem" (aparece com conteúdo). Modal "Agendar mensagem": "Data" (calendário próprio `DateInput`) e "Hora" (`HH:MM`); padrão **amanhã 08:00**.
- Validações: "Data/hora inválida", "O envio deve ser no mínimo 5 minutos no futuro", "O envio não pode ser mais de 1 ano no futuro". Botões "Cancelar" / "Agendar".
- Envia o conteúdo atual (texto + peças) com `visivel_em` em ISO (UTC). 🔎 O autor **não** a vê mais no chat com o selo (MSG-17, superado em `7322e83`): ela entra no **relógio de agendadas** ao lado do microfone (abaixo) e só aparece no chat na hora marcada; destinatários só depois.
- A validação de 5 minutos é feita pelo relógio do servidor: com o relógio do Windows adiantado ou atrasado, o FMX pode receber 400 — usar margem (doc 01).

**ENV-14 Cancelar mensagem agendada** — 🆕 `7322e83`: agora pela lista "Mensagens agendadas" do relógio (§12), com a mesma confirmação
- Hoje: botão "Cancelar" de cada linha da lista "Mensagens agendadas" (abaixo), com a confirmação de perigo "Cancelar mensagem agendada" / "Ela não será enviada." / "Cancelar envio" / "Voltar". (Antes de `7322e83`: a ação "Ocultar" da própria mensagem ainda futura, no chat, virava essa confirmação.)
- API: `DELETE /mensagem?id=` — para agendada não enviada a resposta **não** traz `excluida_em` e a mensagem é removida da lista.

**Relógio de agendadas e lista "Mensagens agendadas"** (`MessageInput.vue:134-146`, `MensagensAgendadasModal.vue`, `stores/chat.ts#agendadasAtivas`) — 🔎 sem ID próprio: complementa ENV-13 e ENV-14 e substitui o selo do MSG-17. Até a revalidação estava só na §12 (🆕 `7322e83`); o texto abaixo é o da §12, conferido no código.
- A mensagem agendada **não aparece no chat** antes da hora (`chat.ts#agendadasAtivas`, `MessageList.vue`). As agendadas são as mensagens **carregadas** da conversa aberta com `visivel_em` no futuro (o servidor só as devolve ao autor), em ordem de horário (`stores/chat.ts:106-110`).
- Com o campo **vazio**, um **relógio** ao lado do microfone mostra quantas há (contador no canto), com o título "1 mensagem agendada" ou "N mensagens agendadas"; com algo no campo, o relógio some (dão lugar a "Agendar mensagem" e "Enviar").
- O relógio abre **"Mensagens agendadas"** (`MensagensAgendadasModal.vue`), só da conversa aberta e em ordem de horário; "×" (`title` "Fechar") ou clique fora fecham. Cada linha tem:
  - o horário (`formatarPrazo`: "hoje 18:00", "amanhã 08:30", "12/10 18:00", com o ano se for outro);
  - o resumo do conteúdo (`resumoMensagem`), até 3 linhas;
  - "Cancelar" ("Cancelando..."), com a confirmação "Cancelar mensagem agendada" / "Ela não será enviada." / "Cancelar envio" / "Voltar" (ENV-14); em erro, a mensagem do servidor ou "Não foi possível cancelar", numa faixa vermelha.
- A lista **fecha sozinha** quando fica vazia (enviada na hora ou cancelada).
- Na hora marcada, a mensagem sai da lista e entra no chat, sem esperar a próxima leitura (`useAgora` agenda um temporizador para a próxima agendada).
- FMX: botão com contador ao lado do microfone, form/painel "Mensagens agendadas" e um `TTimer` ajustado para a próxima `visivel_em` (convertida de UTC para a hora local só na tela).

**ENV-15 Digitando** (`stores/chat.ts`)
- Envio: ao digitar texto não vazio, `POST /conversa/digitando {id: conversaId}`, no máximo 1 a cada 2,5 s (o último é adiado, não perdido). Ao enviar texto, reseta o throttle.
- Recepção: WS tipo 4 `{conversa_id, usuario_id}`; ignora o próprio; expira 4 s sem novo aviso; some quando chega mensagem daquela conversa.
- Exibição: lista (três pontinhos), cabeçalho e chip acima do campo (só se estiver no fim do chat; não durante gravação) + linha luminosa na borda do campo. Textos: direta "Digitando..."; grupo "Ana está digitando...", "Ana e Beto estão digitando...", "Ana, Beto e Caio estão digitando...", "Ana, Beto, Caio e outras N pessoas estão digitando...". Nome de quem não é contato: "Usuário #id".

**ENV-16 Gravando áudio (indicador)**
- Envio: ao começar a gravar e a cada 2,5 s durante a gravação, `POST /conversa/gravando {id}` (mesma regra de throttle).
- Recepção: WS tipo 5 `{conversa_id, usuario_id}`, expira 4 s. Cor vermelha; textos "Gravando áudio..." / "Ana está gravando áudio..." / "… estão gravando áudio...". Gravando tem prioridade sobre digitando na exibição.

**ENV-17 Reações**
- Menu de ações: linha 1 👍 ❤️ 😂 😮, linha 2 😢 👏 🔥 + "Mais emojis" (abre o seletor completo).
- Toggle: reagir de novo com o mesmo emoji remove. Atualização otimista; erro recarrega a conversa.
- Abaixo da bolha: chips `emoji contagem` (destacado se eu reagi; clicar alterna); tooltip lista quem reagiu com foto e hora (hoje `HH:MM`, senão `dd/MM HH:MM`).
- API: `PUT /mensagem/reacao {mensagem_id, emoji}` → `{mensagem_id, emoji, acao}`.
- 🆕 `eaa8bac` **Limite:** até **5 emojis diferentes por pessoa** na mesma mensagem. O web confere antes da reação otimista e mostra o diálogo "Não foi possível reagir" / "Você já reagiu com 5 emojis nesta mensagem." (o servidor confere de novo). Na bolha, **5 chips à mostra** e o resto num chip **"+N"** (destacado se eu reagi em algum); passar o mouse lista os demais (emoji, contagem, nomes) e clicar num deles alterna.
- WS tipo 7 `{conversa_id, mensagem_id, emoji, acao, usuario_id}` — `acao === 'remove'` remove; outro valor adiciona.
- Mensagem oculta não mostra reações.

**ENV-18 Ocultar mensagem** (ex-"Excluir", commit `51a0cd7`)
- Ação "Ocultar" só nas **próprias** mensagens não ocultas, **sem prazo**. Confirmação: título "Ocultar mensagem", texto "Ela continua na conversa, marcada como oculta.", botão "Ocultar" (perigo; foco inicial em "Cancelar").
- API: `DELETE /mensagem?id=` → com `excluida_em` (mensagem fica marcada em todas as listas em memória; recarrega `GET /conversas` para a prévia) ou sem (agendada → removida).
- Erro: aviso "Não foi possível ocultar".
- Os demais participantes recebem via WS 3 (MSG-10).

**ENV-19 Copiar**
- Ação "Copiar": se o menu foi aberto por clique direito **numa imagem**, copia aquela imagem; **no texto**, copia o texto; pelo botão (sem alvo): se a mensagem tem imagem copia a primeira imagem, senão todos os textos unidos por `\n`.
- Imagem é copiada como PNG (converte via canvas se não for PNG) — `utils/copiarImagem.ts`.

**ENV-20 Menu de ações da mensagem** (`MensagemAcoes.vue`) — 🆕 `7322e83`/`e8d82cb`: Ctrl + clique direito abre só as reações rápidas (com "mais emojis"); toque longo no celular abre o menu completo (§12)
- Abre pelo botão de ações ao passar o mouse na bolha (acompanha a rolagem em bolhas altas) ou clique direito na bolha. 🔎 O botão é uma **seta para baixo** (chevron), não "⋯", e **não tem `title`**; fica à esquerda da minha mensagem e à direita da de outro (`MensagemAcoes.vue:1-18`). Só para mensagens salvas (id > 0), não para chamada nem oculta. Abre abaixo do botão, ou acima se não couber, ou centralizado; um menu por vez; fecha com clique fora, Esc e 🔎 **qualquer rolagem** da lista (`MensagemAcoes.vue:330-332,390-396,422-427`).
- Itens, nesta ordem: reações rápidas (👍 ❤️ 😂 😮 / 😢 👏 🔥 + "Mais emojis"); **Responder**; **Responder no privado** (grupo e mensagem de outro); **Encaminhar**; **Copiar**; **Ocultar** (própria e não oculta, em vermelho).
- **Ctrl + clique direito** abre **só a barra de reações** (7 emojis + "Mais emojis"), centrada no ponto do clique, acima dele (ou abaixo, se não couber), com destaque no emoji em que eu já reagi; "Mais emojis" troca a barra pelo seletor completo junto dela. **Toque longo** (só toque: 500 ms, tolerância de 10 px) abre o menu completo e engole o clique ao soltar. Detalhes e adaptação ao FMX: §7.4.

(ENV-21 — campo de mensagem rico — e ENV-22 — criar votação — estão descritos na §10.)

**ENV-23 Rascunho por conversa** (`services/rascunhos.ts`, IndexedDB) — 🆕 `7322e83`. 🔎 Até a revalidação estava só como item de lista na §12; o texto abaixo é o da §12, conferido no código.
- Um rascunho **por usuário e conversa**, com o campo inteiro (texto, quebras de linha, menções e peças — hoje o **documento do editor** Tiptap), os **arquivos** (como `Blob`) e o "respondendo a..." ou encaminhando pendente.
- Gravado com um pequeno atraso a cada mudança (**400 ms** depois da última; `MessageInput.vue:579-588`); campo vazio **apaga** o rascunho.
- Restaurado ao voltar à conversa, **mesmo depois de fechar o navegador**; a resposta escolhida enquanto o rascunho era lido (ex.: "Responder no privado") fica no lugar da salva.
- Apagado ao enviar.
- Onde fica: IndexedDB `conversa-rascunhos`, loja `rascunhos`, chave `usuarioId:conversaId` (`services/rascunhos.ts:29-30,58-72`). Sem IndexedDB (ex.: aba anônima), fica sem rascunho, em silêncio.
- 🔎 O **logout não apaga** os rascunhos (§1.5, §13.3).
- FMX: guardar por usuário do Windows e por usuário do Conversa (ex.: pasta em `%LOCALAPPDATA%\Conversa\rascunhos\<usuario>\<conversa>`), com os arquivos copiados; restaurar ao abrir a conversa; apagar ao enviar e no logout.

### 3.5 ANX — Anexos e mídia

**ANX-01 Fila de anexos antes de enviar** — 🆕 **SUBSTITUÍDA pelo campo de mensagem rico (ENV-21)**: `useFilaArquivos.ts` e `FilaArquivosPreview.vue` foram removidos em `39d06f9`. A descrição abaixo é histórica. (`useFilaArquivos.ts`, `FilaArquivosPreview.vue`)
- Entradas: "Anexar" → "Arquivo" (seletor múltiplo, qualquer tipo), arrastar e soltar sobre a conversa (overlay "Solte para enviar o arquivo" / "Imagens mostrarao uma previa antes de enviar"), colar imagem.
- Imagens: miniaturas com nome e "Remover"; clicar abre no visualizador com galeria da fila. Outros: ícone, nome, tamanho (`B/KB/MB/GB`), duração (áudio; via metadata ou decodificação), botão Ouvir/Pausar (um por vez), "Remover".
- Enviar manda o texto + todos os arquivos numa só mensagem (ordem: [conteúdos encaminhados] → texto → figurinha → arquivos).

**ANX-02 Upload com deduplicação e progresso** — §1.7. Indicador (`UploadIndicador.vue`) com nome, barra e %, aparece só se após 2 s algum upload ainda está abaixo de 50%. Sair da página com upload ativo pede confirmação do navegador (`beforeunload`, 🔎 **só na janela principal**; o aviso é o padrão do navegador, sem texto do app — `App.vue:474-478,488`). Erro em qualquer upload cancela a mensagem inteira. FMX: `OnCloseQuery` com confirmação (§7.8).

**ANX-03 Tipo de conteúdo por arquivo**
- `image/*` → 2 (Imagem); `audio/*` → 4 (Audio); gravação → 5 (GravacaoAudio); demais → 3 (Arquivo). Vídeo é **Arquivo (3)** com extensão `mp4, webm, ogg, mov, m4v, mkv`. Extensão = parte após o último ponto, máx. 10 caracteres.

**ANX-04 Visualizador de imagens e vídeos** (`ImageViewerModal.vue`, `useImageViewer.ts`)
- Galeria = imagens e vídeos da conversa em ordem (exceto mensagens ocultas), com **legenda** = textos da mesma mensagem; miniaturas embaixo (setas de rolagem se > 10), item atual com anel.
- Imagem: zoom 10%–3000% (passo 0,1 abaixo de 1×, 0,2 até 3×, 0,5 até 8×, 1 acima), roda do mouse, arrastar com zoom, duplo clique volta a 100% animado, botões −/%/+, "Copiar imagem (Ctrl+C)", menu de clique direito "Copiar imagem", "Fechar".
- Vídeo: toca com controles nativos e autoplay; sem zoom/copiar.
- Teclas: Esc fecha, ←/→ navegam (exceto com o player em foco), +/=/− zoom, Ctrl+C copia.
- Overlay "Carregando imagem"/"Carregando vídeo".

**ANX-05 Vídeo na conversa** — prévia com o primeiro quadro (`url#t=0.1`) e ícone de play; clique abre no visualizador; botão "Baixar video".

**ANX-06 Visualizador de PDF** (`VisualizadorPdf.vue`)
- Botão "Abrir" em anexos `.pdf`. Páginas em canvas renderizadas sob demanda (perto da área visível), 100% = largura da tela (240–900 px); zoom 50%–300% passo 25%; botão "%" volta a ajustar à largura; indicador "página / total"; "Baixar"; "Fechar (Esc)". Mensagens "Carregando PDF..." / "Não foi possível abrir o PDF. Tente baixar o arquivo.".

**ANX-07 Visualizador de HTML isolado** (`VisualizadorHtml.vue`)
- Botão "Abrir" em `.html/.htm` (chat e página de Anexos). Baixa o HTML e mostra em `iframe srcdoc` com `sandbox="allow-scripts"` **sem** `allow-same-origin` e `referrerpolicy=no-referrer` (sem acesso ao token/cookies). "Carregando HTML..." / "Não foi possível abrir o HTML. Tente baixar o arquivo.".
- 🆕 `eaa8bac` Links `#...` rolam dentro do próprio documento (um script injetado logo depois do `<head>`); antes, no `srcdoc`, eles abriam o Conversa dentro do quadro.

**ANX-08 Markdown e Mermaid** — dentro de blocos de código (MSG-15). Não há visualizador de **arquivo** `.md` anexado (só para blocos no texto).

**ANX-09 Download** — "Download" em arquivos: busca a URL assinada, baixa como blob e dispara `<a download=nome>`; falha → abre a URL em nova aba; erro → aviso "Não foi possível baixar".

**ANX-10 Player de áudio** (`AudioPlayerArquivo.vue`, `AudioPlayerGravacao.vue`, `useAudioPlayer.ts`)
- Play/pause, barra de progresso com arraste (seek), duração/tempo `mm:ss`; arquivo mostra o nome; gravação mostra só o player. URL buscada só no primeiro play.
- Apenas **um áudio toca por vez** (`useAudioManager`).
- Áudio recebido **não ouvido** tem o botão verde; o primeiro play chama `POST /mensagem/reproduzir {conversa, mensagem}` (uma vez). 🔎 Nuance: o 1º play de **qualquer** áudio ainda não reproduzido chama a rota, inclusive áudio **próprio** (`composables/useAudioPlayer.ts:25-27,57-70`).
- Em bolha só de áudio, a hora/status fica dentro do player.

**ANX-11 Gravação de áudio** — 🆕 com o campo **vazio** a gravação é enviada na hora; com algo escrito ela **entra no campo** como peça e vai junto (ENV-21) (`useAudioRecording.ts`, `BarraGravacao.vue`, `MessageInput.vue`)
- Exige contexto seguro ("Para gravar áudio por navegador, use HTTPS (ou localhost).") e `MediaRecorder` ("Gravação de áudio não suportada neste navegador.").
- **Pressionar e segurar** o microfone ≥ 300 ms e soltar sobre o botão → para e **envia direto**. **Clique curto** (ou arrastar para fora do botão) → modo travado com a barra de gravação.
- Barra: "Descartar", ponto vermelho + tempo `m:ss`, forma de onda animada; "Pausar gravação" / "Continuar gravação"; pausado: "Ouvir gravação"/"Parar preview" com barra de progresso clicável (seek); "Enviar áudio".
- Arquivo: `audio-<timestamp>.webm|ogg` (mime do `MediaRecorder`), conteúdo **tipo 5**.

**ANX-12 Transcrição de áudio** (`TranscricaoAudio.vue`)
- Abaixo de áudios (tipo 4 e 5) já enviados. Estados (`StatusTranscricao`): 0 Nenhuma → botão "Transcrever"; 1 Processando → "Transcrevendo..." com consulta a cada 3 s; 2 Concluída → texto (ou "(nenhuma fala reconhecida)"); 3 Erro → botão "Não foi possível transcrever. Tentar de novo" + mensagem de erro.
- Estado inicial vem nos próprios conteúdos da mensagem (`transcricao_status`, `transcricao`).
- API: `PUT /anexo/transcricao {identificador}` e `GET /anexo/transcricao?identificador=` → `{status, texto, erro}`. Se o servidor não tem transcritor configurado (parâmetro `transcritor_url` vazio), o botão não funciona (ver CFG-07).

**ANX-13 Página de Anexos** (`AnexosPage.vue`, `AnexosLista.vue`) — 🆕 `eaa8bac`: a mesma `AnexosLista` aparece no painel "Dados do grupo" (CON-08), já com a conversa do grupo
- Sem conversa selecionada: campo "Buscar contato ou grupo..." e "Selecione um contato ou grupo para ver os anexos"; resultados com avatar, etiqueta "Grupo", prévia; "Nenhum resultado".
- Com conversa: chip da conversa com "Limpar selecao"; filtros de direção **Todos / Enviados / Recebidos** e de tipo **Todos / Imagens / Arquivos / Audios / Gravacoes**.
- Imagens em grade (lazy, "Erro" se falhar) com ações "Abrir mensagem" e "Baixar"; demais em lista: ícone/miniatura, nome ("Sem nome"), tamanho · data (hoje `HH:MM`, senão `dd/MM/aa`) · (sem conversa: nome da conversa), autor; ações "Abrir mensagem", "Baixar" e player nativo para áudios.
- Clique: imagem/vídeo → visualizador com a galeria dos itens carregados; HTML → visualizador isolado; outro arquivo → abre a URL.
- Paginação infinita: carrega mais quando faltam 80% da altura visível.
- API: `GET /anexos?conversa=&autor=&direcao=(enviados|recebidos|'')&tipos=2,3,4,5&antes=<anexo_id>&limite=60` → `AnexoItem[]` (`anexo_id, identificador, nome, extensao, tamanho, criado_em, tipo, mensagem_id, conversa_id, conversa_descricao, autor_id, autor_nome, url` — URL assinada com validade de 600 s).
- Entrada também pelo botão "Ver anexos" do perfil (AUT-10).

**ANX-14 URLs assinadas e renovação** — §1.7 (`useAttachments.ts`). Imagens com erro chamam `renovarAnexoUrl` (injeção `provide/inject`).

**ANX-15 Pré-visualização de imagem antes de enviar** (`ImagePreviewModal.vue`, `useImagePreview.ts`) — "Pré-visualização da imagem", "Cancelar"/"Enviar imagem", Enter confirma, Esc fecha. **Sem gatilho atual** (o evento `open-image-preview` não é emitido; imagens vão para a fila). Ver Anexo B.

### 3.6 PES — Pesquisa

**PES-01 Pesquisa na conversa**
- Campo "Pesquisar..." no cabeçalho (desktop) ou painel "Pesquisar nesta conversa" (celular); Enter pesquisa; × limpa.
- API: `GET /pesquisar?texto=<termo>&conversa=<id>` → `Mensagem[]` (o cliente ainda filtra por `conversa_id`).
- Resultados numa lista sob o cabeçalho (ordem invertida, mais recentes primeiro): "#<id> - <resumo>"; clique → MSG-06.

**PES-02 Pesquisa em todos os chats** (`PesquisaAvancada.vue`)
- Botão "Pesquisar em todos os chats" na lista (leva o termo do filtro). Campo "Pesquisar em todos os chats...", Enter pesquisa, "Cancelar".
- API: `GET /pesquisar?texto=<termo>&conversa=0`.
- Resultados agrupados por conversa (título + contagem), cada um com remetente, data `dd/MM/aa HH:mm` e resumo com o termo destacado (`<mark>`, sem diferenciar maiúsculas). "Pesquisando..." / "Nenhum resultado encontrado.". Clique abre a conversa e vai à mensagem.
- 🔎 **Achado de segurança no web:** o destaque usa `v-html` sobre o texto da mensagem **sem escapar HTML** (`destacarTermo` só escapa o termo para a regex) — `PesquisaAvancada.vue:50,103-108`; ver §13.3. **No FMX, não reproduzir:** desenhar o destaque com texto puro (ex.: `TTextLayout` com atributos por trecho), nunca interpretar o texto da mensagem como marcação.

### 3.7 CHA — Chamadas (WebRTC)

Arquivos centrais: `stores/call.ts`, `CallWindow.vue`, `components/CallBar.vue`, `IncomingCallModal.vue`, `VideoUpgradeModal.vue`, `composables/useCallPopup.ts`, `composables/useFalaChamada.ts`, `components/PonteiroTela.vue`, `components/ChatChamada.vue`. Detalhes de mídia em §5.

**CHA-01 Iniciar chamada de voz ou vídeo**
- Botões do cabeçalho. Direta: participantes `[eu, destinatário]`. Grupo: **todos os membros** da conversa (eu incluído) — não há escolha de participantes (o modal de escolha existe mas não é aberto; Anexo B).
- Pega mídia (vídeo sem câmera → só áudio; áudio sem microfone → erro "Nao foi possivel acessar o microfone"), estado `chamando`, `PUT /chamada/iniciar {tipo, usuarios:[{id}], conversa_id?}` (conversa ativa) → `Chamada`, e **já publica** a mídia no MediaMTX (WHIP) para quem atender assinar logo.
- Não inicia se já existe chamada ("Ja existe uma chamada em andamento").
- Som de chamando (`/chamando.mp3`, loop) até alguém atender. Se o navegador bloquear autoplay, toca no primeiro clique/tecla (no FMX não há bloqueio de autoplay: toca direto).

**CHA-02 Iniciar compartilhando a tela** — botão "Compartilhar tela" no cabeçalho: chamada de **vídeo** com a tela no lugar da câmera + microfone (+ som do sistema misturado, CHA-15).

**CHA-03 Chamada recebida**
- WS 51 `{chamada_id, usuario_id}` → `GET /chamada/dados?id=` → estado `recebendo`, toca `/toque.mp3` em loop, notificação do sistema "Chamada recebida" / "<nome> está ligando (Vídeo|Áudio)" (`tag: conversa-chamada`, `requireInteraction`), modal:
  - "Chamada recebida", "<nome> está ligando...", "Vídeo + Áudio" ou "Somente Áudio";
  - botões **Recusar** (vermelho) e **Atender** (verde); em vídeo, **"Atender só assistindo"** (entra com a câmera desligada e em tela única em quem ligou).
- **Sem resposta em 30 s** → recusa automática com `nao_atendeu` (vira chamada perdida nas atividades).
- Aviso 51 da própria chamada que eu fiz é ignorado. Aviso 51 de uma chamada em que já estou → só sincroniza peers.
- **Atenção FMX (sempre conectado):** o WS 51 vai a **todas** as conexões do usuário, e o temporizador de 30 s de cada cliente é independente. Um desktop aberto sem ninguém na frente **recusa a chamada por todos os aparelhos** do usuário depois de 30 s (`nao_atendeu` muda o participante para "recusou" e o WS 53 chega também aos outros aparelhos dele). Ver o doc 01 §15.1 e o doc 08 (S1/S2). Notificação, toque e foco no desktop: §7.8.

**CHA-04 Atender**
- Mídia: vídeo+áudio → só áudio → **sem mídia (somente recepção)**. `POST /chamada/entrar {id}` → `ativa`, cronômetro, publica (WHIP) se tem mídia, `GET /chamada/dados`, sincroniza peers (3 tentativas com espera crescente).
- Chamada de vídeo sem enviar vídeo (só assistindo, sem câmera, sem mídia) → pede **tela única** em quem ligou, já antes de conectar (aplicado quando o primeiro participante chega).
- Falha → desfaz tudo e mostra o erro.

**CHA-05 Recusar** — `POST /chamada/recusar {id, nao_atendeu?}`; para o toque.

**CHA-06 Ocupado** — chega 51 enquanto estou em chamada ou tocando → recusa automática com `nao_atendeu: true` sem tocar.

**CHA-07 Atendida/recusada em outro aparelho ou aba** — WS 54 (`UsuarioEntrou`) ou 53 (`UsuarioRecusou`) com o **meu** `usuario_id` enquanto estou `recebendo` (e não fui eu que atendi aqui) → para de tocar e volta a `inativo`.

**CHA-08 Chamadas pendentes** — ao conectar o WS (e no polling sem WS): `GET /chamadas/pendentes` → `[{id, tipo, status, criado_em, criado_por, conversa_id, ...}]`; a primeira: se criada há **> 25 s** → recusa com `nao_atendeu`; senão passa a tocar como CHA-03.

**CHA-09 Cancelar enquanto chama** — botão sair durante `chamando` → `POST /chamada/cancelar {id}`.

**CHA-10 Entrada dos outros e fim da chamada**
- WS 54 de outro: se eu estava `chamando` → `ativa` + cronômetro; se `ativa` → reanuncia minha tela (se compartilhando) e sincroniza peers.
- WS 55 (`UsuarioSaiu`) → desconecta o peer, `GET /chamada/dados`; **se não sobrou nenhum outro com status "Entrou"** → sai sozinho (`POST /chamada/sair`) e encerra.
- WS 53 de outro numa chamada de 2 pessoas em que o outro está "Recusou" → encerra.
- WS 52 (`ChamadaFinalizada`) → encerra tudo.
- Sair: `POST /chamada/sair {id}`. Existe também `POST /chamada/finalizar {id}` (encerra para todos) na store, **sem botão na UI**.
- A cada 4 s em chamada ativa, sincroniza peers com `GET /chamada/dados` (reconecta quem caiu ou está sem trilhas).

**CHA-11 Controles da chamada** — 🆕 `eaa8bac`: os liga/desliga (microfone, câmera, som, tela, chat, ponteiro) viraram **pílulas com ícone + chave** (verde ligada, cinza desligada; `role="switch"`, `aria-checked`), e a cor do botão não muda mais com o estado. Antes, 🆕 cores: microfone, câmera e som ficam **vermelhos quando desligados**; tela, chat e ponteiro ficam **azuis quando ligados**; os demais ficam neutros (`CallWindow.vue`, `CallControlButton.vue`)
- Microfone (liga/desliga a trilha), Câmera (só vídeo), Compartilhar tela (só vídeo), Chat da chamada (com contador de não lidas), Ponteiro (só quando alguém compartilha a tela), Áudio de saída (silencia os outros), Adicionar usuário (só `ativa`), Voltar ao grid (em destaque), Minimizar/Expandir, Sair (vermelho).
- Cabeçalho: indicador, "Chamando..." / "Em chamada" / "Encerrando...", duração `mm:ss` ou `hh:mm:ss`, "Vídeo"/"Áudio", "N pessoa(s)".
- Tiles: nome ("<eu> (você)"); sem vídeo → iniciais; erro de conexão em faixa vermelha (`erroMsg`, ex.: "Erro ao conectar com <nome>: …"; 404 de WHEP não vira erro, tenta de novo).

**CHA-12 Modos de exibição** (só vídeo, janela não flutuante) — **Grade** ("Todos os participantes lado a lado"), **Destaque** ("Um participante grande e os demais na lateral"), **Tela única** ("Só um participante, ocupando toda a área", setas "Participante anterior"/"Proximo participante"). Clique num tile destaca; clique no destaque volta à grade. Grade: 1 col (1), 2 col (2–4), 3 col (≤6), 4 col (mais) — 🔎 colunas **responsivas** (pela largura da janela do navegador): 2 pessoas = 1 coluna abaixo de 768 px e 2 a partir de `md`; 3–4 = 2; 5–6 = 2 / 3 a partir de `md`; mais de 6 = 2 / 3 (`md`) / 4 (`lg`, ≥ 1024 px) — `CallWindow.vue:520-526`. No FMX vale a coluna "larga" (desktop), reduzida se o form da chamada for estreito. Se o destacado sai em tela única, o pedido fica pendente e volta quando ele reconectar.

**CHA-13 Janela flutuante e barra** — vídeo minimizado no desktop: janela flutuante arrastável pelo cabeçalho e redimensionável pelas bordas/cantos. 🔎 Só para chamada de **vídeo** (áudio nunca flutua: só a `CallBar`); posição inicial no canto superior direito (`x = largura − 440`, `y = 16`), **420×350**, mínimo **320×240**, máximo **90%** da janela; arraste pelo cabeçalho mantém ao menos 100 px visíveis; bordas de 6 px e cantos de 12 px para redimensionar; na flutuante somem o seletor de modo, o painel e o botão do chat (`useDraggable.ts:5-19,35-41,63-64,85-87`; `CallWindow.vue:5-21,41,255,304,413-421`). FMX: `TForm` próprio com `StayOnTop` (§7.6). `CallBar` (áudio sempre; vídeo minimizado): status, duração, tipo, nº de pessoas, avatares (anel verde em quem fala); em áudio: microfone, saída, adicionar, botão "Vídeo" (upgrade) e sair; em vídeo: "Abrir chamada" e sair. No celular a chamada minimizada fica só na barra.

**CHA-14 Adicionar participante** — modal "Adicionar à chamada" com contatos que não estão na chamada ("Nenhum contato disponível para adicionar."), checkboxes, "Adicionar". API: `PUT /chamada/usuario {chamada_id, usuario_id}` (um por vez) → `GET /chamada/dados`.

**CHA-15 Compartilhar tela com áudio do sistema**
- `getDisplayMedia({video:true, audio:{restrictOwnAudio:true, suppressLocalAudioPlayback:false}, systemAudio:'include'})`.
- A trilha de vídeo da tela **substitui** a da câmera na publicação (`replaceTrack`); sem câmera (publicação só com áudio) republica e avisa com `POST /chamada/video`.
- Som do computador + microfone misturados num `AudioContext` numa trilha única que substitui a do microfone; mutar o microfone silencia só a voz. Parar (botão ou "parar compartilhamento" do navegador) restaura câmera (ou abre uma nova) e o microfone puro.
- Anuncia aos outros com sinal `{acao:'tela', ativa}` (CHA-17) e reanuncia para quem entra depois.
- `contentHint` e limites de envio pela prioridade (Nitidez: 15 fps, `maintain-resolution`; Fluidez: 30 fps, `maintain-framerate`).

**CHA-16 Troca de tipo áudio → vídeo**
- Botão "Vídeo" na barra de chamada de áudio: abre a câmera (sem câmera continua só recebendo vídeo), muda para vídeo, reconecta todos os peers e `POST /chamada/video {id}` (proteção contra clique duplo).
- Os outros recebem WS 56 (`VideoAtivado`): se já estão em vídeo → só reassinam quem republicou; senão modal "Vídeo ativado" / "<nome> ativou o vídeo" / "Deseja transmitir seu vídeo também?" com **"Apenas assistir"** (câmera desligada, tela única em quem ativou) e **"Transmitir também"**; sem resposta em **15 s** → "Apenas assistir".

**CHA-17 Ponteiro remoto** (commit `20d5b73`)
- Quem compartilha a tela avisa por WS 57 `{acao:'tela', ativa:true|false}`. Quem assiste vê o botão "Apontar na tela compartilhada"/"Desligar ponteiro" (só com tela remota; desliga sozinho quando não há mais telas).
- Ligado, o movimento do mouse sobre a imagem da tela envia `{acao:'ponteiro', alvo:<id de quem compartilha>, x, y}` com x/y de 0 a 1 **relativos à imagem do vídeo** (descontando faixas de `object-contain`), no máximo a cada 40 ms (o último sempre vai); sair da imagem envia `x:null, y:null`.
- Todos que veem aquela tela (inclusive quem compartilha, sobre o próprio vídeo local) desenham o ponteiro com o nome e uma cor por usuário (`id % 5`). Ponteiro parado some após 5 s; some quando a pessoa sai ou a tela para. Sinal de outra chamada é ignorado.

**CHA-18 Chat da chamada** — 🆕 na janela principal o painel virou o **chat completo** (CHA-24) (commit `20d5b73`)
- Painel "Chat da chamada" ao lado do vídeo (celular: por cima). Vazio: "As mensagens enviadas aqui ficam num grupo com quem está na chamada.".
- 🔎 **Modo simples, hoje sem uso:** só texto, anexos como "[Imagem]", "[Áudio]", "[Figurinha]", "[Arquivo]" (e "[Votação]"), mensagens ocultas não aparecem, campo "Mensagem", Enter envia e Shift+Enter quebra linha. Ele só existe com `completo=false`, ou seja, com `fecharAoEncerrar=true`, que nenhum uso atual passa (o app não abre mais janela popup de chamada) — código morto (`ChatChamada.vue:108-158`; `CallWindow.vue:254-258`; `App.vue:176,188`; Anexo B). **O FMX não precisa dele.**
- 🆕 `eaa8bac` Agora o grupo é criado no **primeiro clique no campo** (não mais na primeira mensagem): sem grupo, o painel mostra o aviso e um campo-botão "Digite uma mensagem" ("Abrindo o chat..."); o clique chama `PUT /chamada/chat`, abre o chat completo (CHA-24) e põe o cursor no campo. Erro aparece numa faixa vermelha.
- (Antes de `eaa8bac`) O grupo só é criado na **primeira mensagem**: `PUT /chamada/chat {id}` → `{conversa_id}` (idempotente; guardado em `chamada.conversa_chat_id`). Se outro criou, chega WS 57 `{acao:'chat', conversa_id}`. Quem entra depois passa a fazer parte (servidor).
- Envio: `PUT /mensagem` no grupo; recarrega `GET /mensagens?conversa=<grupo>&…80`. Painel aberto marca as recebidas como visualizadas. Botão do chat mostra o número de não lidas do grupo quando fechado.

**CHA-19 Indicador de fala** (`useFalaChamada.ts`)
- A cada 100 ms mede o RMS do microfone local e do áudio de cada participante (`AnalyserNode`, 1024 amostras); acima de **0,02** conta como fala; mantém marcado por **400 ms** depois de parar. Microfone mutado não conta.
- Exibição: anel verde nos avatares da `CallBar` e tooltip "Você está falando" / "<nome> está falando".

**CHA-20 Qualidade da chamada** (aba Configurações → Chamadas; `useConfigChamada.ts`) — ver CFG-06. Mudanças durante a chamada valem na hora (reabre o microfone para ruído/eco/ganho/qualidade; `applyConstraints` para resolução/fps; refaz parâmetros de envio).

**CHA-21 Somente recepção** — sem microfone nem câmera o tile local mostra "Somente recepção" e os botões "Ativar microfone" / "Ativar câmera" (abre a mídia e reconecta todos os peers para publicar).

**CHA-22 Histórico de chamadas** (`ChamadaHistorico.vue`)
- Título "Chamadas", abas **Todas** / **Perdidas** (status 5), filtro "Buscar contato" (local, pelo nome do outro participante), datas "De" e "Até" (calendário; formato `YYYY-MM-DD`; mudar recarrega).
- API: `GET /chamadas?participante=0&de=YYYY-MM-DD&ate=YYYY-MM-DD` → `ChamadaHistoricoItem[]` (`id, tipo, status, criado_em, criado_por, conversa_id, iniciada, finalizada, duracao, participantes:[{usuario_id, nome, status, duracao, avatar_url}]`).
- Agrupado por "Hoje"/"Ontem"/`dd/MM/aaaa`. Item: avatar do outro (grupo: "Grupo (N)"), seta efetuada/recebida (efetuada = `criado_por` sou eu), hora, "Video"/"Audio" · duração ou status ("Recusada", "Perdida", "Cancelada"), cor (vermelho perdida/recusada, cinza cancelada, verde demais).
- Clique abre a conversa da chamada; botão "Ligar novamente" inicia nova chamada do mesmo tipo com os mesmos participantes. Vazio: "Nenhuma chamada" / "Nenhuma chamada perdida".

**CHA-23 Áudio remoto estável** — o áudio de cada participante toca num `HTMLAudioElement` criado pela store (vive a chamada inteira); os `<video>` são sempre mudos. Evita perder áudio ao alternar janela flutuante/tela cheia. "Áudio de saída" muta esses elementos.

### 3.8 SIP — Telefonia SIP (ramal)

**SIP-01 Configuração do ramal** (aba Voip)
- "Configuracao de ramal" (etiqueta "Asterisk / VueSIP"): "Ramal SIP", "Usuario de autenticacao", "Senha SIP", "Nome de exibicao", "Dominio SIP", "Servidor WebSocket" (ex. `wss://pbx.exemplo.com:8089/ws`), checkbox "Configuracao SIP ativa para este usuario".
- Validação: "Preencha ao menos ramal, senha SIP, dominio e servidor WebSocket.". Botão "Criar configuracao SIP" / "Salvar configuracao SIP"; "Nenhuma alteracao para salvar."; mensagens de sucesso.
- API: `GET /sip` → `SipConfig` ou `{}` (sem ramal → null); `PUT /sip {sip_user, auth_user, sip_password, display_name, domain, ws_server, ativo}`; `PATCH /sip {id, ...só o que mudou}`.

**SIP-02 Registro automático**
- No início da sessão, ao montar a lista e ao fechar as Configurações (forçando reconexão): carrega `GET /sip`; se `ativo` → pede permissão de microfone, cria `UserAgent` (`sip:<sip_user>@<domain>`, transporte `ws_server`, auth `auth_user||sip_user` + senha, display name), `Registerer.register()`, espera até 10 s ("O ramal SIP nao concluiu o registro a tempo."). Inativo → encerra.
- Status: barra (bolinha), discador ("Sem configuracao", "Ramal inativo", "Registrado", "Conectando", "Conectado sem registro", "Falha na conexao", "Desconectado"). Erros: "Conexao WebSocket perdida.", "Falha na conexao WebSocket: …".

**SIP-03 Discador** (`SipDialerModal.vue`)
- Janela flutuante arrastável: "Ramal" + número do ramal (ou "Indisponivel"), "Status do ramal", campo "Digite o numero" (teclado de telefone), apagar último dígito, teclado 1–9/*/0/# com letras (ABC… e "+" no 0) e tom DTMF local (duas senoides 100 ms).
- 🔎 Caixa de **288 px** de largura, **centralizada** ao abrir, arrastável **pelo cabeçalho** e sempre dentro da janela; "×" fecha. **Não há atalho de teclado**: Enter não liga e as teclas numéricas fora do campo não discam (`SipDialerModal.vue:4,8-13,226-254`). FMX: §7.7.
- "Ligar" ("Conectando..." enquanto registra) → `INVITE sip:<numero>@<domain>` só áudio; "Discando..." + destino + tom de discagem sintetizado (3 bipes a cada 2 s); "Cancelar".
- Em chamada: "Chamada em andamento" + destino, mutar/desmutar, "Encerrar chamada"; teclas enviam **DTMF in-band** (`RTCDTMFSender.insertDTMF`, 100 ms, gap 70 ms).
- Falha antes de estabelecer: "Chamada não completada — destino indisponível ou ocupado."; fim de chamada estabelecida toca tom de ocupado (4 bipes 425 Hz).

**SIP-04 Chamada SIP recebida** (`SipIncomingCallModal.vue`)
- Modal "Chamada recebida" com nome (display name ou usuário da URI, "Desconhecido") e número; toque sintetizado (2 bipes 440 Hz a cada 3 s); "Recusar" / "Atender". Atender abre o discador mostrando "Conectando..." e depois a chamada.

**SIP-05 ICE do SIP** — antes de cada chamada SIP o cliente busca `GET /ice` e passa como `peerConnectionConfiguration` (commit `bc11b32`, removeu TURN fixo).

### 3.9 NOT — Notificações

**NOT-01 Som de mensagem** — `/notification.mp3` (fallback: bipe 880 Hz 0,5 s). Toca para mensagens de outros **exceto**: conversa ativa com a janela focada, conversas arquivadas. Toca mesmo com a janela focada (em outra conversa). **Um** som por lote (`stores/chat.ts:936-944`; `utils/sound.ts:4-48`).

**NOT-02 Notificação do sistema por conversa** (`utils/sound.ts`)
- Uma por conversa (agrupamento), com o conteúdo da **última** mensagem do lote: título = nome completo do remetente (pelos contatos), senão `remetente`, senão "Nova mensagem"; corpo = texto resumido (menção vira `@Nome`, código vira `Código (linguagem)`) ou "Imagem", "Gravacao de audio", "Audio", "Figurinha", 🔎 **"Votação"**, senão "Arquivo" (`stores/chat.ts:965-990`); ícone = avatar do contato/conversa ou `/logo.png`; `tag: conversa-<id>`, `renotify`, `requireInteraction` (fica até interagir), `silent` (o som é o do app).
- Criada pelo service worker quando registrado (clique foca a aba e abre a conversa, mesmo após recarregar); senão pela página (`new Notification`, com cuidado do `onclose` assíncrono).
- FMX: toast do Windows com o mesmo título e corpo (§7.8).

**NOT-03 Fechar notificação** — quando o contador de não lidas da conversa chega a 0 (leitura) e ao arquivar a conversa.

**NOT-04 Push em segundo plano (FCM)** — §1.6. Não se aplica ao FMX (sem FCM; §7.13).

**NOT-05 Notificação de chamada** — CHA-03 (tag `conversa-chamada`, fechada quando para de tocar). 🔎 Ela **não** é `silent` (`useCallPopup.ts:77-126`).

**NOT-06 Pedido de permissão** — no início da sessão e após o login; aba Permissões (CFG-04).

### 3.10 PRE — Presença

**PRE-01 Online/offline**
- `GET /contatos/online` → `number[]` a cada conexão do WS; WS 60 `{usuario_id, online:boolean}`.
- Bolinha verde no avatar da lista, do cabeçalho (direta), em "Nova conversa" e 🔎 na lista de participantes do painel "Dados do grupo" (CON-08; `PainelGrupo.vue:92`). Não há "visto por último" na UI (o campo `online_em` existe na lista de datas, sem uso visível).
- Atenção FMX: o servidor só manda presença de quem tem conversa **direta**, e um desktop conectado o dia todo deixa o usuário **"online" o tempo todo** (não existe "ausente") — doc 01 §15.1.

### 3.11 ATV — Atividades (commit `39d5af1`)

**ATV-01 Tela de atividades** (`AtividadesPage.vue`, `stores/atividades.ts`)
- Título "Atividades". Vazio: "Nenhuma atividade ainda." / "Reações, respostas, menções e chamadas perdidas aparecem aqui.".
- Agrupadas por "Hoje"/"Ontem"/`dd/MM/aaaa`. Item: avatar de quem fez com selo no canto (emoji da reação; "↩" resposta; "@" menção; "✆" chamada perdida), "**<autor>** <descrição>", "em <grupo>" (só em grupo), prévia entre aspas (texto ou "Imagem"/"Arquivo"/"Áudio"/"Figurinha"/🔎 "Votação"; a gravação também aparece como "Áudio"; não para chamada), hora `HH:MM`, bolinha "Nova".
- Descrições: Reação "reagiu <emoji> à sua mensagem"; Resposta "respondeu sua mensagem"; Menção "mencionou você"; Chamada perdida "ligou (chamada perdida)" ou "ligou (chamada de vídeo perdida)".
- Clique: com `mensagem_id` → abre a conversa na mensagem (MSG-06); sem (chamada perdida) → abre a conversa.
- Paginação: ao chegar a 200 px do fim, `GET /atividades?antes=<id da última>&limite=30`; fim quando volta < 30.
- API: `GET /atividades?antes=0&limite=30` → `Atividade[]` (`id, tipo (1 Reacao, 2 Resposta, 3 Mencao, 4 ChamadaPerdida), criado_em, nova, autor_id, autor_nome, autor_avatar_url, conversa_id, conversa_tipo, conversa_descricao, mensagem_id, conteudo_tipo, texto, chamada_id, chamada_tipo, emoji`).

**ATV-02 Contador de novas**
- Badge no item Atividades da barra (`99+`). Fonte: `GET /atividades/novas` → `{quantidade}` ao conectar o WS e a cada WS 61.
- Abrir a tela: carrega a lista e `POST /atividades/vistas` → `{vistas_em}`, zera o contador; os itens continuam destacados como "nova" enquanto a tela está aberta. Com a tela aberta, WS 61 recarrega e marca como visto; fechada, só atualiza o contador.

**ATV-03 Geração de "chamada perdida" pelo cliente** — toda recusa automática (30 s sem resposta, ocupado, pendente antiga > 25 s) envia `nao_atendeu: true` em `POST /chamada/recusar`, o que o servidor transforma em atividade de chamada perdida. **O FMX precisa fazer o mesmo** (com a ressalva do CHA-03 sobre o temporizador de 30 s num desktop sempre conectado).

### 3.12 CFG — Configurações, personalização e administração

**CFG-01 Abas e navegação** — §2.5 (celular: lista de abas → sub-tela com botão voltar).

**CFG-02 Tema escuro** — botão na aba Usuário ("Tema claro"/"Tema escuro"); padrão segue `prefers-color-scheme`; persistido em `theme`. Também aplicado no popup. FMX: padrão segue o tema do Windows (modo de aplicativo claro/escuro), com a mesma escolha manual gravada localmente.

**CFG-03 Dispositivos** — "Sessao atual" (etiqueta "Ativo"): Dispositivo, Modelo, Sistema, Plataforma (detectados localmente); "Dispositivos de midia" com "Atualizar lista" (enumera microfones, câmeras, saídas; etiquetas "Padrao"/"Comunicacao"). Sem API (não lista os outros dispositivos do usuário no servidor). 🔎 **Só lista: não há seleção** de microfone, câmera ou alto-falante em lugar nenhum do web (`getUserMedia` sem `deviceId`, sem `setSinkId`): chamadas e gravação usam sempre o dispositivo padrão do sistema (`ProfileSettingsModal.vue:199-272,720-776`). Escolher o dispositivo no FMX seria melhoria em relação ao web (§7.9).

**CFG-04 Permissões do navegador** — "Permissoes do navegador": Notificacoes, Microfone, Camera com status "Concedida"/"Negada"/"Nao solicitada"/"Indisponivel" e botão "Solicitar"; dica do cadeado na barra de endereço. FMX: permissões da Privacidade do Windows (§7.9).

**CFG-05 Cores personalizadas** (`ConfiguracaoCores.vue`, `useCoresPersonalizadas.ts`)
- Edita as cores do **tema atual** (claro e escuro separados), valem na hora, salvas no navegador (🔎 chave `conversa.cores`, sincronizada entre janelas pelo evento `storage` — `useCoresPersonalizadas.ts:142,206-207`). Grupos: Principal (primary 50–900), Superfícies (surface base, 50–900; escala invertida no escuro), Sucesso, Perigo, Informação, Alerta, Chamada (300–900 — janela de chamada escura nos dois temas). Cada tom com descrição de uso. Busca por variável ou uso; "Restaurar todas", "Restaurar grupo", "Voltar ao padrão" por cor.

**CFG-06 Qualidade das chamadas** (`ConfiguracaoChamadas.vue`) — salvo em `conversa.chamada`; "Restaurar padrão".
- Áudio: "Redução de ruído", "Cancelamento de eco", "Ganho automático do microfone" (padrão ligados); "Qualidade do áudio": Normal 32 kbps (padrão) / Alta 64 kbps / Música estéreo 128 kbps (estéreo vale na próxima chamada).
- Vídeo: Resolução 360p/720p/1080p (padrão 720p desktop, 360p celular); FPS 15/24/30 (padrão 24 desktop, 15 celular); Limite de banda Automático / Econômico 0,5 Mbps / Alto 3 Mbps.
- Tela: Prioridade Nitidez (padrão; até 15 fps) / Fluidez (até 30 fps).

**CFG-07 Sistema — parâmetros do servidor** (`ConfiguracaoSistema.vue`, permissão `parametros`)
- Aviso "Valem para todos os usuários e entram em vigor ao salvar, sem reiniciar o servidor.".
- Notificações (Firebase): "ID do projeto", "E-mail da conta de serviço", "Chave privada" ("(configurada)"/"(não configurada)"; nunca exibida; vazio mantém).
- Chamadas: "Forçar relay pelo TURN"; "Guardar as gravações por (dias)" (0 = para sempre, 0–36500).
- Transcrição: "Endereço do transcritor" (vazio desliga o Transcrever), "Idioma".
- Armazenamento: bucket só leitura.
- Salva **só o que mudou** (chave só se digitada); "Configurações salvas.".
- API: `GET /parametros` → `{fcm_project_id, fcm_client_email, fcm_private_key_configurada, turn_forcar_relay, transcritor_url, transcritor_idioma, gravacao_dias, s3_bucket}`; `PATCH /parametros {campos alterados, fcm_private_key?}` → mesmos campos.

**CFG-08 Acessos — permissões** (`ConfiguracaoAcessos.vue`, permissão `permissoes`)
- 🔎 Quando ninguém tem a permissão Acessos (`modo_aberto` da API), aparece o aviso — **não existe** o texto "Modo aberto" na tela; o texto exato é: "**Ninguém tem a permissão Acessos ainda:** todos os usuários podem mexer nas configurações e nas permissões. Marque Sistema e Acessos para quem deve cuidar disso; ao marcar Acessos para alguém, só passa a valer o que estiver marcado." (`ConfiguracaoAcessos.vue:6-9`). Marcar Acessos para alguém encerra o modo.
- "O que cada permissão libera" (nomes: `parametros` → "Sistema", `permissoes` → "Acessos"), busca "Buscar usuário" (nome/login), tabela usuário × permissão com checkboxes ("(você)").
- API: `GET /permissoes` → `{permissoes:[{codigo, descricao}], usuarios:[{id, nome, login, permissoes:[]}], modo_aberto}`; `PUT /permissao/usuario {usuario_id, codigo}`; `DELETE /permissao/usuario?usuario_id=&codigo=`. Recusa do servidor mostra o motivo e a caixa volta. Após cada mudança recarrega as próprias permissões (abas visíveis acompanham).

### 3.13 GER — Comportamentos gerais de UX

**GER-01 Toast de erro global** — faixa vermelha no topo com ×.
**GER-02 Faixa de conexão em tempo real** — §1.4.
**GER-03 Diálogo de confirmação próprio** (`DialogoConfirmacao.vue`, `useDialogo.ts`) — título, mensagem, "Cancelar"/"OK" (customizáveis), variante perigo (botão vermelho, foco em Cancelar), Esc cancela, clique fora cancela; modo aviso (só OK). Novo diálogo responde "não" ao anterior.
**GER-04 Arrastar e soltar arquivos** — camada "Solte para enviar o arquivo" sobre a conversa; os arquivos soltos entram **no campo** como peças (ENV-21), sem envio automático (ANX-01 é histórico). 🔎 A camada ainda diz "Imagens mostrarao uma previa antes de enviar", mas **não há mais prévia** (`App.vue:111-112,469-472`): o FMX não deve copiar essa frase. Detalhes: §7.2.
**GER-05 Menu de contexto nativo bloqueado** — exceto em campos de texto/conteúdo editável (clique direito abre os menus do app).
**GER-06 Seções não implementadas** — tela "Em desenvolvimento".
**GER-07 Avatares com fallback** — inicial do nome (primeira "letra" real, inclusive emoji); imagens que falham somem e fica a inicial.

### Contagem

🔎 Conferida na revalidação contra `e8d82cb`: **137 IDs**, sem lacuna nem duplicata. Os IDs não mudaram; só a apresentação da tabela (por grupo, com onde está cada item).

| Grupo | IDs | Qtde | Onde está descrito |
|---|---|---|---|
| AUT — Autenticação, sessão, perfil | AUT-01…10 | 10 | §3.1 |
| CON — Conversas | CON-01…13 | 13 | §3.2 |
| MSG — Exibição e leitura de mensagens | MSG-01…20 | 20 | §3.3; 🆕 MSG-20 (`39d06f9`) na §10 |
| ENV — Composição e ações sobre mensagens | ENV-01…23 | 23 | §3.4; 🆕 ENV-21 e ENV-22 (`39d06f9`) na §10; 🆕 ENV-23 (`7322e83`) na §3.4 (🔎 antes só na §12) |
| ANX — Anexos e mídia | ANX-01…15 | 15 | §3.5 |
| PES — Pesquisa | PES-01…02 | 2 | §3.6 |
| CHA — Chamadas WebRTC | CHA-01…24 | 24 | §3.7; 🆕 CHA-24 (`39d06f9`) na §10 |
| SIP — Telefonia SIP | SIP-01…05 | 5 | §3.8 |
| NOT — Notificações | NOT-01…06 | 6 | §3.9 |
| PRE — Presença | PRE-01 | 1 | §3.10 |
| ATV — Atividades | ATV-01…03 | 3 | §3.11 |
| CFG — Configurações e administração | CFG-01…08 | 8 | §3.12 |
| GER — UX geral | GER-01…07 | 7 | §3.13 |
| **Total** | | **137** | 132 até `bfb79d8` + 4 de `39d06f9` + 1 de `7322e83` |

Sem ID próprio (para não mudar a numeração compartilhada com o Android): o **relógio de agendadas** e a lista "Mensagens agendadas" (§3.4, junto de ENV-13/ENV-14) e os comportamentos de desktop da §7 (cada um aponta para o ID que complementa).

---

## 4. Todos os endpoints REST e eventos WebSocket

### 4.1 Endpoints REST (todos sob `/api`, Bearer token salvo onde indicado)

Fonte única: `src/services/conversaApi.ts` (+ `eden.ts`). "Params" = query string; "Body" = JSON.

🔎 Revalidado em `e8d82cb`: o web usa **63 rotas** da API (as 58 abaixo + as **5 de votação**, que faltavam: linhas 59–63), mais o PUT na URL pré-assinada. Nenhuma rota da tabela deixou de ser usada.

| # | Método | Rota | Params / Body | Resposta (campos usados) | Usado em |
|---|---|---|---|---|---|
| 1 | POST | `/login` | body `{login, senha, dispositivo_id?}` (sem token) | `{id, nome, email, telefone, avatar_identificador, token, dispositivo:{id, nome, modelo, versao_so, plataforma, ativo}}` — 🔎 **sem `avatar_url`** (AUT-01) | AUT-01 |
| 2 | PUT | `/usuario` | body `{nome, login, email, senha}` (sem token) | `{id, nome, login, email}` | AUT-02 |
| 3 | PATCH | `/dispositivo` | body `{id, nome?, modelo?, versao_so?, plataforma?, token_fcm?}` | — | AUT-04 |
| 4 | POST | `/alterar-senha` | body `{senha_atual, senha}` | — | AUT-07 |
| 5 | PATCH | `/usuario` | body `{id, nome?, email?, telefone?, avatar_anexo_id?: number\|null}` | — | AUT-06, AUT-08 |
| 6 | GET | `/usuario/contatos` | — | `Contato[]` | CON-11 |
| 7 | GET | `/contatos/online` | — | `number[]` | PRE-01 |
| 8 | GET | `/usuario/permissoes` | — | `string[]` | AUT-09 |
| 9 | GET | `/conversas` | — | `Conversa[]` | CON-01 |
| 10 | GET | `/conversa/usuarios` | `conversa` | `[{id, usuario_id, nome, avatar_url}]` | CON-08, CON-09, CHA-01 |
| 11 | PUT | `/conversa` | body `{descricao, tipo}` (1 direta, 2 grupo) | `{id, ...}` | CON-06, CON-07 |
| 12 | PATCH | `/conversa` | body `{id, descricao}` | — | CON-08 |
| 13 | PUT | `/conversa/usuario` | body `{conversa_id, usuario_id}` | `{id, conversa_id, usuario_id}` | CON-06/07/08 |
| 14 | DELETE | `/conversa/usuario` | `id` (= id do vínculo conversa_usuario) | — | CON-08 |
| 15 | PATCH | `/conversa/fixadas` | body `{conversas: number[]}` | `{conversas}` | CON-03 |
| 16 | PATCH | `/conversa/arquivada` | body `{conversa, arquivada}` | `{id, arquivada}` | CON-04 |
| 17 | POST | `/conversa/digitando` | body `{id}` | — | ENV-15 |
| 18 | POST | `/conversa/gravando` | body `{id}` | — | ENV-16 |
| 19 | GET | `/mensagens` | `conversa, mensagemreferencia, mensagensprevias, mensagensseguintes` | `Mensagem[]` | MSG-01, MSG-06, CHA-18 |
| 20 | GET | `/mensagens/novas` | `desde` (ISO ou '') | `[{conversa_id, mensagem_id, ate}]` | §1.4 |
| 21 | PUT | `/mensagem` | body `{conversa_id, conteudos:[{ordem, tipo, conteudo}], mensagem_referencia?:{tipo, origem_mensagem_id}, visivel_em?}` | `{id, conversa_id, usuario_id}` | ENV-01/04/06/07/08/13, CHA-18 |
| 22 | DELETE | `/mensagem` | `id` | `{..., excluida_em?}` | ENV-14, ENV-18 |
| 23 | PUT | `/mensagem/reacao` | body `{mensagem_id, emoji}` | `{mensagem_id, emoji, acao}` | ENV-17 |
| 24 | POST | `/mensagem/visualizar` | body `{conversa, mensagem}` | `{sucesso}` | MSG-04 |
| 25 | POST | `/mensagem/reproduzir` | body `{conversa, mensagem}` | `{sucesso}` | ANX-10 |
| 26 | GET | `/mensagem/status` | `conversa, mensagem` (ids separados por vírgula) | `[{conversa_id, mensagem_id, recebida, visualizada, reproduzida, excluida_em}]` | MSG-10 |
| 27 | GET | `/mensagem/status/detalhe` | `id` | `[{usuario_id, nome, recebida, visualizada, reproduzida}]` (datas) | MSG-09 |
| 28 | GET | `/pesquisar` | `texto, conversa` (0 = todas) | `Mensagem[]` | PES-01/02 |
| 29 | GET | `/anexo/existe` | `identificador` | `{id}` ou objeto sem `id` | §1.7 |
| 30 | PUT | `/anexo` | body `{identificador, tipo, nome, extensao, tamanho}` | `{id, upload_url}` | §1.7 |
| — | PUT | `<upload_url>` (MinIO, fora da API, sem Bearer) | corpo binário | 2xx | §1.7 |
| 31 | GET | `/anexo` | `identificador` | `{url}` | ANX-*, AUT-08 |
| 32 | GET | `/anexo/transcricao` | `identificador` | `{status, texto, erro}` | ANX-12 |
| 33 | PUT | `/anexo/transcricao` | body `{identificador}` | `{status, texto, erro}` | ANX-12 |
| 34 | GET | `/anexos` | `conversa, autor, direcao, tipos (csv), antes, limite` (0/'' = sem filtro) | `AnexoItem[]` | ANX-13 |
| 35 | PUT | `/chamada/iniciar` | body `{tipo, usuarios:[{id}], conversa_id?}` | `Chamada` | CHA-01 |
| 36 | POST | `/chamada/cancelar` | body `{id}` | `{id}` | CHA-09 |
| 37 | POST | `/chamada/entrar` | body `{id}` | `{id}` | CHA-04 |
| 38 | POST | `/chamada/recusar` | body `{id, nao_atendeu?: true}` | `{id}` | CHA-05/06/08, ATV-03 |
| 39 | POST | `/chamada/sair` | body `{id}` | `{id}` | CHA-10 |
| 40 | POST | `/chamada/finalizar` | body `{id}` | `{id}` | (store, sem botão) |
| 41 | GET | `/chamada/dados` | `id` | `Chamada {id, iniciada, finalizada, tipo, status, criado_em, criado_por, conversa_chat_id, usuarios:[{usuario_id, usuario_nome, status, adicionado_por, adicionado_por_nome, adicionado_em, entrou_em, saiu_em, recusou_em}]}` | CHA-* |
| 42 | PUT | `/chamada/chat` | body `{id}` | `{conversa_id}` | CHA-18 |
| 43 | PUT | `/chamada/usuario` | body `{chamada_id, usuario_id}` | `{id}` | CHA-14 |
| 44 | POST | `/chamada/video` | body `{id}` | — | CHA-15/16 |
| 45 | GET | `/chamadas/pendentes` | — | `ChamadaPendente[]` | CHA-08 |
| 46 | GET | `/chamadas` | `participante, de, ate` | `ChamadaHistoricoItem[]` | CHA-22 |
| 47 | GET | `/ice` | — | `{iceServers: RTCIceServer[], iceTransportPolicy}` | §5, SIP-05 |
| 48 | GET | `/sip` | — | `SipConfig` ou `{}` | SIP-01/02 |
| 49 | PUT | `/sip` | body `{sip_user, auth_user, sip_password, display_name, domain, ws_server, ativo}` | `SipConfig` | SIP-01 |
| 50 | PATCH | `/sip` | body `{id, ...campos}` | — | SIP-01 |
| 51 | GET | `/atividades` | `antes, limite` | `Atividade[]` | ATV-01 |
| 52 | GET | `/atividades/novas` | — | `{quantidade}` | ATV-02 |
| 53 | POST | `/atividades/vistas` | — | `{vistas_em}` | ATV-02 |
| 54 | GET | `/permissoes` | — | `PermissoesSistema` | CFG-08 |
| 55 | PUT | `/permissao/usuario` | body `{usuario_id, codigo}` | `{usuario_id, codigo}` | CFG-08 |
| 56 | DELETE | `/permissao/usuario` | `usuario_id, codigo` | `{usuario_id, codigo}` | CFG-08 |
| 57 | GET | `/parametros` | — | `ParametrosSistema` | CFG-07 |
| 58 | PATCH | `/parametros` | body `AlteracaoParametros` | `ParametrosSistema` | CFG-07 |
| 59 | PUT | `/enquete` 🔎 | body `{conversa_id, pergunta, opcoes: string[], multipla, encerra_em: ISO\|null}` | a mensagem criada `{id, conversa_id, usuario_id, enquete_id}` (o web recarrega mensagens e conversas) | ENV-22 |
| 60 | GET | `/enquete` 🔎 | `id` | `Enquete {id, conversa_id, mensagem_id, pergunta, multipla, criado_por, opcoes:[{id, texto, votantes:[{id, nome}]}], total_votantes, meus_votos, encerra_em, encerrada_em, encerrada, pode_encerrar, pode_alterar_prazo}` | MSG-20, MSG-16 |
| 61 | POST | `/enquete/votar` 🔎 | body `{enquete_id, opcoes: number[]}` (lista completa; vazia tira o voto) | `Enquete` | MSG-20 |
| 62 | POST | `/enquete/encerrar` 🔎 | body `{enquete_id}` | `Enquete` | MSG-20 |
| 63 | PATCH | `/enquete` 🔎 | body `{enquete_id, encerra_em: ISO\|null}` | `Enquete` | MSG-20 |

🔎 Fonte das rotas de votação: `services/conversaApi.ts:225-246`; tipo `Enquete` em `types/api.ts:311-331`; resposta do `PUT /enquete` em `conversa/src/enquetes.ts:42-47`.

🔎 **Rotas do servidor que o web não usa (6 das 69):** `DELETE /usuario`, `PUT /usuario/contato`, `DELETE /usuario/contato`, `PUT /dispositivo/usuario`, `DELETE /conversa` e `POST /anexo/confirmar`. Para o FMX, a única que **deve** ser usada mesmo sem uso no web é `POST /anexo/confirmar` (§1.7); as outras não têm tela no web e ficam fora da paridade.

Fora da API: `POST /webrtc/<caminho>/whip` e `POST /webrtc/<caminho>/whep` (MediaMTX, `Content-Type: application/sdp`, sem Bearer) — §5; `GET /figurinhas/<pacote>/<nome>.json` (estático da página); `/notification.mp3`, `/toque.mp3`, `/chamando.mp3`, `/logo.png` (estáticos).

### 4.2 Eventos WebSocket

Enum: `TipoEventoSocket` em `src/types/api.ts`. Mensagens são JSON.

**Enviados pelo cliente**

| tipo | Nome | Payload | Quando |
|---|---|---|---|
| 1 | (login) | `{tipo:1, token}` | `onopen` |
| 57 | SinalChamada | `{tipo:57, chamada_id, dados: SinalChamada}` | tela compartilhada, ponteiro (CHA-15/17) |

**Recebidos**

| tipo | Nome | Campos lidos | Ação no cliente |
|---|---|---|---|
| 2 | NovaMensagem | (nenhum) | `GET /mensagens/novas?desde=cursor` → notificações, lista, conversa ativa (§1.4) |
| 3 | StatusMensagem | `grupo` (conversa), `mensagens` ("1,2,3") | `GET /mensagem/status` → atualiza recebida/visualizada/reproduzida/excluida_em; recarrega conversas |
| 4 | Digitando | `conversa_id, usuario_id` | indicador 4 s |
| 5 | GravandoAudio | `conversa_id, usuario_id` | indicador 4 s |
| 7 | ReacaoMensagem | `conversa_id, mensagem_id, emoji, acao ('remove' ou outro), usuario_id` | atualiza a reação localmente (só se a mensagem está em memória) |
| 40 | ConversaAtualizada | — | `GET /conversas` |
| 51 | ChamadaRecebida | `chamada_id, usuario_id` | CHA-03/06 |
| 52 | ChamadaFinalizada | `chamada_id` | encerra |
| 53 | UsuarioRecusou | `chamada_id, usuario_id` | CHA-07/10 |
| 54 | UsuarioEntrou | `chamada_id, usuario_id` | CHA-07/10 |
| 55 | UsuarioSaiu | `chamada_id, usuario_id` | CHA-10 |
| 56 | VideoAtivado | `chamada_id, usuario_id` | CHA-16 |
| 57 | SinalChamada | `chamada_id, usuario_id, dados` | `dados.acao`: `'tela'` `{ativa}` · `'ponteiro'` `{alvo, x, y}` (x/y null = saiu) · `'chat'` `{conversa_id}`; ignora o próprio e de outra chamada |
| 60 | StatusUsuario | `usuario_id, online` | presença |
| 61 | NovaAtividade | — | ATV-02 |
| 62 🔎 | EnqueteAtualizada | `enquete_id` (o servidor manda também `conversa_id`) | relê `GET /enquete?id=` **só se a votação está no cache** (ou seja, na tela) — `stores/chat.ts:883-886`; `stores/enquetes.ts:37-39`. Vai a **todos** os membros, inclusive a quem votou (MSG-20) |

Eventos 51–57 só são tratados depois que o handler de chamada é registrado em `iniciarSessao` (o popup de chat não registra — chamadas não tocam no popup). Tipo 6 não existe no enum do cliente. 🔎 Com o 62, o enum `TipoEventoSocket` (`types/api.ts:29-46`) tem **16** eventos recebidos; o 62 faltava nesta tabela.

Para o FMX: o `tipo` enviado precisa ser **número JSON**; e, num desktop sempre conectado, o WS 2 pode chegar **repetido** (uma cópia por token FCM cadastrado do usuário — o cursor de `/mensagens/novas` deduplica as mensagens, mas som e notificação precisam de proteção própria) — doc 01 §6 e §15.

---

## 5. WebRTC / MediaMTX / WHIP / WHEP

Arquivo: `src/stores/call.ts`. Não há malha P2P: cada participante **publica uma única transmissão** no MediaMTX (WHIP) e **assina** a transmissão de cada outro participante (WHEP).

### 5.1 Endereços e nomes das transmissões

- Base: `${window.location.origin}${VITE_WEBRTC_PATH || '/webrtc'}` → `https://HOST/webrtc`.
- Sala: `call-<chamadaId>`; transmissão do usuário: `call-<chamadaId>-u-<usuarioId>` (caracteres fora de `[a-zA-Z0-9_-]` removidos).
- Publicar: `POST https://HOST/webrtc/call-<chamadaId>-u-<meuId>/whip` (corpo = SDP offer, `Content-Type: application/sdp`; resposta = SDP answer).
- Assinar: `POST https://HOST/webrtc/call-<chamadaId>-u-<outroId>/whep`.
- Sem trickle ICE: espera a coleta de candidatos terminar (até **5 s**, por causa da alocação TURN/TLS) antes de enviar o offer. Não usa `PATCH`/`DELETE` do WHIP/WHEP (o encerramento é só `pc.close()`).

### 5.2 Servidores ICE

- `GET /ice` a **cada nova RTCPeerConnection** (credenciais TURN temporárias) → `{iceServers, iceTransportPolicy}` (`relay` quando o parâmetro "Forçar relay pelo TURN" está ligado).
- Falha ou lista vazia → `VITE_STUN_URL` se configurado, senão nenhum.
- O mesmo `GET /ice` alimenta o SIP.

### 5.3 Publicação (WHIP)

- Uma `RTCPeerConnection` de envio (`pcPublicacaoLocal`) compartilhada por todos os peers.
- **No máximo uma trilha de áudio e uma de vídeo** (o MediaMTX recusa com 406 mais de uma de cada tipo) — usa a primeira trilha `live`.
- **Codec de vídeo (commit `dfeedbf`)**: `setCodecPreferences` no transceiver de vídeo ordenando `video/H264` primeiro, depois `video/VP9`, demais (VP8 etc.) por último — porque o MediaMTX **grava** as chamadas e não grava VP8. A chamada funciona mesmo sem H264/VP9 (só não grava).
- **Opus estéreo**: com a qualidade "Música", o SDP do offer recebe `stereo=1;sprop-stereo=1` no `a=fmtp` do Opus. Os offers de WHEP sempre pedem estéreo (para aceitar quem envia música).
- **Parâmetros de envio** (`sender.setParameters`): áudio `maxBitrate` 32k/64k/128k; vídeo `maxBitrate` conforme banda (Automático = sem limite, 500k, 3M) e `maxFramerate` = fps escolhido; com tela: 15 fps + `degradationPreference: maintain-resolution` (Nitidez) ou 30 fps + `maintain-framerate` (Fluidez).
- Captura: áudio `{echoCancellation, noiseSuppression, autoGainControl, channelCount: 2 se música senão 1}`; vídeo `{width/height ideal pela resolução (640×360, 1280×720, 1920×1080), frameRate {ideal, max}, facingMode:'user' em celular}`.
- **Quando publica**: logo após `PUT /chamada/iniciar` (quem liga), logo após `POST /chamada/entrar` (quem atende, se tem mídia), ao ativar microfone/câmera em "somente recepção", ao fazer upgrade para vídeo (republica), ao compartilhar tela sem câmera (republica + `POST /chamada/video`).
- **Recuperação**: `connectionState` `failed`/`disconnected` da publicação → fecha e republica, depois sincroniza peers (2 tentativas).

### 5.4 Assinatura (WHEP)

- Uma `RTCPeerConnection` de recepção por participante, transceivers `recvonly`: áudio sempre; vídeo só se a chamada é de vídeo.
- Tentativas enquanto o outro ainda não publicou: vídeo **40 × 1 s**, áudio **12 × 0,8 s**; esgotado → erro `WHEP erro: <status|timeout>`. 404 não aparece como erro para o usuário: tenta de novo na próxima sincronização (1,5 s depois).
- Trilhas recebidas vão para um `MediaStream` por peer; áudio toca num `HTMLAudioElement` dedicado (CHA-23); vídeos sempre mudos.
- Reconexão: `failed`/`disconnected` → fecha e reassina após 2 s; chamada de vídeo sem trilha de vídeo 5 s depois de conectar → reassina; sincronização periódica (4 s) com `GET /chamada/dados` reassina peers com conexão `failed/disconnected/closed`, sem áudio vivo ou (vídeo) sem vídeo vivo, e desconecta quem não está mais com status "Entrou" (3).
- Reassinar de propósito: ao receber `VideoAtivado` (56) já em vídeo.

### 5.5 Compartilhamento de tela

§3 CHA-15: a tela entra **no lugar da câmera** na mesma transmissão (não há segunda transmissão); por isso quem assiste não sabe que é tela — quem compartilha avisa por WS 57 `{acao:'tela', ativa}`. Áudio do sistema é mixado com o microfone (Web Audio) numa única trilha de áudio.

### 5.6 Canais de dados

**Não há `RTCDataChannel`.** Ponteiro remoto, aviso de tela compartilhada e aviso de criação do chat da chamada passam pelo **WebSocket da API** (tipo 57, repassado pelo servidor sem gravar). O chat da chamada é uma conversa de grupo comum (REST + eventos de mensagem).

### 5.7 Indicador de fala

Medido no cliente sobre as trilhas de áudio (local e recebidas) com `AnalyserNode` (CHA-19). Não usa `getStats`/`audioLevel` nem evento do servidor.

### 5.8 Gravação

O cliente não grava nada nem tem botão de gravar: o **MediaMTX grava** as transmissões (por isso a preferência de codec). A retenção é o parâmetro do sistema "Guardar as gravações por (dias)" (CFG-07). O web não lista nem reproduz gravações.

### 5.9 Estados e máquina da chamada (resumo)

```
inativo --(iniciar)--> chamando --(54 de outro)--> ativa
inativo --(51)--> recebendo --(atender)--> ativa
recebendo --(recusar | 30 s | 53/54 meus de outro aparelho)--> inativo
chamando --(cancelar)--> inativo
ativa --(sair | 52 | último outro saiu | recusa em direta)--> encerrando --> inativo
```

---

## 6. Regras de UX e textos exatos para replicar

### 6.1 Mensagens

| Situação | Texto exato |
|---|---|
| Campo de mensagem | "Digite uma mensagem" |
| Bolha oculta | "Mensagem oculta" (tooltip "Clique para ver o conteúdo" / "Clique para ocultar o conteúdo") |
| Citação de mensagem oculta | "Mensagem oculta" |
| Confirmação de ocultar | título "Ocultar mensagem", texto "Ela continua na conversa, marcada como oculta.", botões "Cancelar" / "Ocultar" (vermelho) |
| Confirmação de cancelar agendada | título "Cancelar mensagem agendada", texto "Ela não será enviada.", botões "Voltar" / "Cancelar envio" |
| Erro ao ocultar | título "Não foi possível ocultar" |
| Erro ao baixar | título "Não foi possível baixar" |
| Menu de ações | "Responder", "Responder no privado", "Encaminhar", "Copiar", "Ocultar"; reações 👍 ❤️ 😂 😮 / 😢 👏 🔥 + "Mais emojis" |
| Selo de agendada (histórico, MSG-17; 🔎 o código ainda existe mas não aparece — Anexo B) | "Agendada para hoje 14:30" / "Agendada para amanhã 08:00" / "Agendada para 12/10 08:00" |
| 🔎 Relógio de agendadas | `title` "1 mensagem agendada" / "N mensagens agendadas"; lista "Mensagens agendadas" com horário ("hoje 18:00", "amanhã 08:30", "12/10 18:00"), "Cancelar" / "Cancelando..."; erro "Não foi possível cancelar" |
| Indicador não lidas | "Últimas" |
| Botão flutuante | "Há novas mensagens"; botão "Ir para o final" |
| Lista vazia | "Selecione uma conversa." / "Ver conversas" (celular) / "Sem mensagens" (prévia) |
| Citação encaminhada | "Encaminhado de <nome>" ou "Encaminhado" |
| Barra de resposta | "<nome>" (resposta) / "Encaminhando de <nome>" (responder no privado) |
| Detalhe status (direta) | "Enviada", "Recebida", "Visualizada", "Ouvida", "Oculta", "Aguardando" |
| Detalhe status (grupo) | "Visualizada por (N)", "Recebida por (N)", "Aguardando (N)" |
| Digitando | "Digitando..." / "<nome> está digitando..." / "<a> e <b> estão digitando..." / "<a>, <b> e <c> estão digitando..." / "<a>, <b>, <c> e outras N pessoas estão digitando..." (idem "gravando áudio") |
| Código | "Copiar"/"Copiado!", "Expandir código"/"Recolher código", "Visualizar"/"Código" |
| Transcrição | "Transcrever", "Transcrevendo...", "(nenhuma fala reconhecida)", "Não foi possível transcrever. Tentar de novo" |
| Arquivo | "Abrir" (PDF/HTML), "Download", "Baixar video", "Toque para abrir" / "Toque para carregar" |
| Agendar | "Agendar mensagem", "Data", "Hora", "Cancelar", "Agendar"; erros "Data/hora inválida", "O envio deve ser no mínimo 5 minutos no futuro", "O envio não pode ser mais de 1 ano no futuro" |
| Resumos de conteúdo | notificação: "Imagem", "Gravacao de audio", "Audio", "Figurinha", 🔎 "Votação", "Arquivo" (título sem nome: "Nova mensagem"); resposta/encaminhar (`resumoMensagem`): texto, "Imagem", "Áudio", senão "Arquivo" (🔎 gravação, figurinha e votação caem em "Arquivo" na barra de resposta — `utils/formatters.ts:84-90`); citação na bolha (`messageReferences.ts`): texto, "Imagem", "Gravacao de audio", "Audio", "Figurinha", "Votação", "Arquivo"; código: "Código (linguagem)" |
| 🔎 Arrastar arquivo | "Solte para enviar o arquivo" (não copiar a segunda linha, "Imagens mostrarao uma previa antes de enviar", que está desatualizada — GER-04) |
| 🔎 Ações sem `title` no web | botão de ações da mensagem (seta para baixo) — no FMX, um `Hint` como "Mais ações" é melhoria, não paridade |

### 6.2 Conversas, chamadas, atividades

- Lista: "Pesquisar...", "Nova conversa", "Arquivadas (N)", etiquetas "Grupo" e "Arquivada", menu "Fixar"/"Desafixar"/"Arquivar"/"Desarquivar".
- Chamada recebida: "Chamada recebida", "<nome> está ligando...", "Vídeo + Áudio" / "Somente Áudio", "Atender só assistindo"; notificação "<nome> está ligando (Vídeo|Áudio)".
- Upgrade: "Vídeo ativado", "<nome> ativou o vídeo", "Deseja transmitir seu vídeo também?", "Apenas assistir", "Transmitir também".
- Janela da chamada: "Chamando...", "Em chamada", "Encerrando...", "N pessoa(s)", modos "Grade"/"Destaque"/"Tela única", "Somente recepção", "Ativar microfone", "Ativar câmera", "Chat da chamada", "Apontar na tela compartilhada"/"Desligar ponteiro", "Adicionar à chamada", "Abrir chamada", "Vídeo".
- Histórico: "Chamadas", "Todas", "Perdidas", "Buscar contato", "De", "Até", "Hoje", "Ontem", "Ligar novamente", "Nenhuma chamada", "Nenhuma chamada perdida".
- Bolha de chamada: "Chamada de audio|video[ em grupo]", status "Recusada", "Perdida", "Cancelada"; participantes "Perdida", "Recusou", "Desconectou".
- Atividades: ver ATV-01 (descrições exatas).

### 6.3 Regras de comportamento críticas

1. **Ocultar ≠ apagar**: a mensagem permanece, com `excluida_em`; só a agendada ainda não enviada some de vez. Só o autor oculta, sem prazo.
2. **Arquivada não notifica nem toca**, mas recebe mensagens; desarquivar não restaura a posição de fixada.
3. **Visualizar só o que está visível com o app em primeiro plano** (equivalente FMX: `Application.Active`, o form que mostra a conversa ativo e não minimizado, e o item totalmente visível — §7.11).
4. **Recusa automática sempre com `nao_atendeu: true`** (30 s tocando, ocupado, pendente > 25 s) — alimenta "chamada perdida".
5. **Chamada atendida/recusada em outro aparelho** (53/54 com meu id) deve parar de tocar.
6. **Um áudio por vez**; primeiro play de áudio recebido marca `reproduzir`.
7. **Throttle de digitando/gravando 2,5 s**, expiração 4 s.
8. **Ordenação** por `coalesce(visivel_em, inserida)`, id como desempate; otimistas no fim.
9. **Menções** enviadas como `@[Nome](id)`.
10. **Figurinha** com o campo vazio é enviada sozinha (conteúdo único tipo 7); 🔎 com algo escrito, entra no campo e vai junto, na ordem (ENV-04/ENV-21).
11. **Responder no privado** = encaminhada (tipo 2) com conteúdos da original antes do texto.
12. **Fixadas**: enviar a lista completa na ordem; ordem de exibição fixadas → recentes → arquivadas (seção recolhível).
13. **Sessão**: 401 → login; outros erros → manter login e tentar de novo a cada 5 s. No FMX, 401 = sessão vencida (token de 12 h): relogar com o mesmo `dispositivo_id`, sem laço (§1.5).
14. 🔎 **Agendada fica fora do chat** até a hora: só no relógio de agendadas (§3.4).
15. 🔎 **Votação** não pode ser encaminhada (o servidor recusa tipo 8 em `PUT /mensagem`): esconder "Encaminhar" para ela (MSG-20).

---

## 7. Comportamentos de desktop e adaptações para o cliente Windows (FMX)

No desktop quase tudo o que o web faz vale **literalmente** no FMX: popup de conversa, janela flutuante da chamada, clique direito e *hover*, arrastar e soltar, teclas, colar, aviso ao sair com upload e abas de configurações. O que muda é o mecanismo: toast do Windows em vez de service worker/FCM, `TForm` em vez de `window.open`, permissões da Privacidade do Windows em vez das do navegador, e nada de `navigator.connection`.

- Cada item traz o comportamento **exato** do web (arquivo:linha em `e8d82cb`, teclas, textos) e, na coluna ou linha **FMX**, como o cliente Windows deveria reproduzi-lo. Os textos estão como no código, inclusive sem acento onde o web não acentua.
- Estes comportamentos **não têm ID próprio** (§3, "Contagem"): cada subseção indica os IDs que complementa.
- Fonte: relatório de apoio `apoio/A7-validacao-servidor-web.md`, §3 (web em `e8d82cb`).

### 7.1 Atalhos de teclado (lista completa)

Complementa ENV-01, ENV-02, ENV-05, ENV-06, ENV-10, ENV-11, ENV-12, ENV-19, ENV-20, ENV-21, CON-01, CON-05, CON-07, GER-03, ANX-04, ANX-06, ANX-07, ANX-15, PES-01, PES-02, CHA-01, CHA-03, CHA-18 e MSG-16.

| Onde | Tecla | Comportamento exato no web | Evidência | FMX |
|---|---|---|---|---|
| Campo de mensagem (ENV-01, ENV-05) | **Enter** | Envia (`aoEnter → enviarMensagem()`). Com a lista de menção aberta, **confirma a menção** em vez de enviar | `editor/pecas.ts:150`; `MessageInput.vue:365`; `:342-345` | `OnKeyDown` do campo: `vkReturn` sem Shift → enviar (e `Key := 0`); com a lista de menção aberta → escolher |
| Campo (ENV-12) | **Shift+Enter** | Quebra de linha (`setHardBreak`) | `editor/pecas.ts:151` | Inserir `sLineBreak` |
| Campo (ENV-12) | **Tab** | Insere **4 espaços** | `editor/pecas.ts:152` | Tratar `vkTab` no `OnKeyDown` do campo inserindo 4 espaços (e `Key := 0`) |
| Campo (ENV-12) | **Shift+Tab** | Não tratado: o navegador tira o foco do campo | (ausência em `pecas.ts:148-154`) | Deixar a navegação padrão |
| Campo (ENV-21) | **Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z** | Desfazer/refazer do editor (extensão `UndoRedo`), inclusive peças | `MessageInput.vue:222,352` | Desfazer próprio do campo (o `TMemo` só tem um nível; para peças, pilha própria) |
| Campo (ENV-21) | **Backspace** | Apaga uma peça (anexo/figurinha/menção) como se fosse um caractere | `MessageInput.vue:101-102`; `pecas.ts:88` (`deleteTriggerWithBackspace`) | Idem no editor do FMX |
| Campo (ENV-02) | **Espaço** após `:)` etc. | Troca o atalho pelo emoji | `pecas.ts:116-137`; `utils/emojiAtalhos.ts` | Mesmo mapa (ENV-02) |
| Lista de menção (`@`) (ENV-05) | **↑ / ↓** | Move a seleção | `MessageInput.vue:338-341` | Idem |
| Lista de menção (ENV-05) | **Enter / Tab** | Confirma | `MessageInput.vue:342-345` | Idem |
| Lista de menção (ENV-05) | **Esc** | Fecha | `MessageInput.vue:334-337` | Idem |
| Qualquer lugar (ENV-12) | **Letra/número/símbolo** (tecla de 1 caractere) fora de campo | Foca o campo de mensagem **no fim** e o caractere entra nele. Ignora: evento já tratado, composição (IME), Meta, **Ctrl ou Alt sem AltGr**, foco em `INPUT/TEXTAREA/SELECT`/editável, Espaço com foco em botão/link, e campo **coberto por modal** (testado com `elementFromPoint` no centro do campo) | `MessageInput.vue:1040-1057` | `TForm.KeyPreview := True` + `OnKeyDown`/`OnKeyPress` do form: se `KeyChar <> #0`, sem Ctrl/Alt (exceto AltGr), sem controle de edição focado e sem diálogo aberto → `CampoMensagem.SetFocus`, cursor no fim e repassar o caractere |
| Troca de conversa / responder (ENV-12, ENV-06) | — | O campo recebe o foco | `App.vue:411-413`; `MessageInput.vue:930-932` | Idem |
| Janela "Inserir código" (ENV-10) | **Ctrl+Enter** (Cmd no Mac) | Envia a mensagem com o bloco | `CodigoModal.vue:167-170` | `OnKeyDown` do editor de código: `ssCtrl` + `vkReturn` |
| Janela "Inserir código" (ENV-10) | **Esc** | **Nada** (não há tratamento). Fecha pelo "×", "Cancelar" ou clique fora — e, se veio de colagem, cola o texto cru | `CodigoModal.vue:2,7,36`; `MessageInput.vue:1022-1027` | Recomendado: Esc = Cancelar (mesmo efeito) |
| Menu de ações da mensagem / barra de reações / seletor (ENV-20) | **Esc** | Fecha | `MensagemAcoes.vue:330-332` | `TPopupMenu` fecha com Esc nativamente. A biblioteca de menu própria do FMX atual (`lib/popupmenu`) não trata teclas (doc 05, GER-05): se for mantida, tratar o Esc |
| Menu da conversa (lista) (CON-05) | **Esc** | Fecha; também fecha com clique fora e ao redimensionar a janela | `ChatSidebar.vue:391-405` | Idem |
| Item da lista de conversas (com foco) (CON-01) | **Enter / Espaço** | Abre a conversa | `ChatSidebar.vue:74-75` | Idem |
| Diálogo de confirmação (GER-03) | **Esc** | Cancela. Enter aciona o botão com foco; o foco inicial vai para o botão principal, ou para **Cancelar** se a ação é destrutiva | `DialogoConfirmacao.vue:54-66` | `MessageDlg` com botão padrão = Cancelar nas destrutivas |
| Criar grupo (CON-07) | **Esc** | Cancela (listener global no `window`) | `CreateGroupModal.vue:68-73` | Esc fecha o form |
| Pré-visualização de imagem (sem gatilho hoje; ANX-15) | Enter / Esc | Confirma / fecha | `ImagePreviewModal.vue:39-48` | — |
| Visualizador de imagens/vídeos (ANX-04) | **Esc** | Fecha | `useImageViewer.ts:185` | Idem |
| Visualizador (ANX-04) | **← / →** | Item anterior/seguinte da galeria (exceto com o player de vídeo em foco, onde as setas avançam o vídeo) | `useImageViewer.ts:186-189` | Idem |
| Visualizador (ANX-04) | **+ / = / −** | Zoom (só imagem) | `useImageViewer.ts:190-192` | Idem |
| Visualizador (ANX-04, ENV-19) | **Ctrl+C** (ou Cmd+C) | Copia a imagem (PNG) | `useImageViewer.ts:193-196`; botão "Copiar imagem (Ctrl+C)" em `ImageViewerModal.vue:91` | `IFMXClipboardService.SetClipboard` com `TBitmapSurface` |
| Visualizador (ANX-04) | Roda / duplo clique / arrastar / clique direito | Zoom / volta a 100% animado / arrasta com zoom / menu "Copiar imagem" | `ImageViewerModal.vue:39-42,60` | Idem |
| Visualizador de PDF / HTML (ANX-06, ANX-07) | **Esc** | Fecha | `VisualizadorPdf.vue:154`; `VisualizadorHtml.vue:70` | Idem |
| Pesquisa no cabeçalho / pesquisa global (PES-01, PES-02) | **Enter** | Pesquisa | `ChatHeader.vue:79,140`; `PesquisaAvancada.vue:11` | Idem |
| Chat simples da chamada (antes de o grupo existir; modo hoje sem uso, CHA-18) | **Enter** (sem modificador) | Envia; Shift+Enter quebra linha | `ChatChamada.vue:80` | Idem |
| Bolha oculta (com foco) (MSG-16) | **Enter / Espaço** | Revela/oculta o conteúdo | `BolhaExcluida.vue:10-11` | Idem |
| Toque/chamada bloqueado pelo autoplay (CHA-01, CHA-03) | Qualquer tecla ou clique | Começa o som de toque | `useCallPopup.ts:45-55` | Não se aplica (o desktop toca direto) |
| Ctrl+C / Ctrl+V / Ctrl+X no texto (ENV-19, ENV-11) | — | Padrão do navegador (copiar seleção do chat; colar no campo — ver §7.3) | — | Padrão dos controles |

O web **não tem** atalhos globais para trocar de conversa, buscar (Ctrl+F), abrir o emoji ou ligar. Não há `Ctrl+Enter` no campo principal (só na janela de código), e o discador SIP não tem atalho (§7.7). Atalhos a mais no FMX são melhoria, não paridade.

### 7.2 Arrastar e soltar

Complementa GER-04, ENV-21 e CON-03.

**Arrastar arquivos para a conversa** (`composables/useDragAndDrop.ts`, `App.vue:89-114,467-472`):
- Ao entrar com **arquivos** (`dataTransfer.types` contém `Files`) na área da conversa (`<main>`), aparece uma camada por cima de tudo (inclusive do campo) com:
  - **"Solte para enviar o arquivo"**;
  - "Imagens mostrarao uma previa antes de enviar" (texto **antigo**: hoje não há prévia, a imagem vai direto para o campo — o FMX não deve copiar esta frase; GER-04).
- Um contador de `dragenter`/`dragleave` evita piscar. Arrastar uma **peça de dentro do campo** (mudar a ordem, `e8d82cb`) não mostra a camada (`editor/pecas.ts:38-40,155-164`; `useDragAndDrop.ts:8-10`).
- Ao soltar: os arquivos entram no **campo**, como peças, no ponto do cursor (`MessageInput.vue:653-656`). Nada é enviado sozinho. Sem conversa ativa, nada acontece (`App.vue:469-472`).
- Arquivo solto **direto sobre o campo** (sem a camada, ex.: no popup, que não tem a camada) entra **no ponto do mouse** (`MessageInput.vue:668-677`, `posAtCoords`).
- **FMX:** `OnDragOver`/`OnDragDrop` do painel da conversa com `Data.Files` (o FMX recebe arquivos do Explorer no Windows); mostrar um painel semitransparente com "Solte para enviar o arquivo"; inserir os arquivos no campo como peças. Sem envio automático. Arquivo solto sobre o campo entra no ponto do mouse; arrastar uma peça dentro do campo muda a ordem e não mostra o painel. A janela de conversa separada (§7.5) aceita soltar no campo.

**Arrastar dentro da lista de conversas** (CON-03): arrastar uma fixada sobre outra reordena (metade de cima = antes, de baixo = depois), com uma linha azul na posição; com termo no filtro não há arraste; sem mudança, a API não é chamada. **FMX:** literal, com o mouse (`OnMouseDown`/`OnMouseMove` ou `OnDragOver`/`OnDragDrop` dos itens) e a mesma linha de posição; `PATCH /conversa/fixadas` com a lista completa na ordem.

### 7.3 Colar imagem, arquivo, texto longo e código

Complementa ENV-09, ENV-10, ENV-11 e ENV-21.

**Colar** (`MessageInput.vue:975-1005`, ligado em `handlePaste`, `:377`), nesta ordem:
1. Colagem vinda do **próprio campo** (HTML com `data-pm-slice` e peças): o editor cola as peças como estão (`:979-980`). Peça cujo arquivo o campo não tem mais é descartada (`:380-384`).
2. **Arquivos** na área de transferência (qualquer tipo, não só imagem) → entram como peças no cursor. Arquivo **sem nome** (captura de tela) ganha **`print-<Date.now()>.<ext>`**, com a extensão pelo mime (`png`, `jpg`, `webp`, `gif`, `bmp`; o padrão é `png`) — `:988-990`; `utils/formatters.ts:134-142`. **Exceção GIF:** se veio um único arquivo de imagem e o HTML copiado tem `<img src="data:image/gif;base64,...">`, usa o GIF inteiro como `gif-<ms>.gif` (`:983-986`; `utils/copiarImagem.ts:38-49`).
3. Texto com **mais de 10 linhas** (`texto.trim().split('\n').length > 10`, `utils/codeBlocks.ts:167-169`) → abre a janela **"Inserir código"** já preenchida (`:995-998`, `sugerirCodigo` `:1011-1019`):
   - linguagem `markdown` se há linha começando com ```` ``` ````; `texto` se é desenho ASCII; senão a detectada (`:1014-1016`);
   - **"Cancelar"**, "×" ou clique fora **colam o texto como estava** (`:1022-1027`);
   - **"Enviar"** (ou Ctrl+Enter) **envia na hora** a mensagem só com o bloco cercado e **limpa o campo** (`:681-690`).
4. Texto **com cara de código** (`pareceCodigo`, `codeBlocks.ts:152-162`) — 2+ linhas com (≥ 50% desenho ASCII) ou (≥ 50% comandos de terminal) ou (≥ 2 linhas e ≥ 50% com cara de código **e** algum sinal forte) → entra **já cercado** com a linguagem detectada, numa linha própria (`MessageInput.vue:1030-1036`). Cerca = uma crase a mais que a maior sequência interna, mínimo 3 (`codeBlocks.ts:116-119`).
5. Outro texto → colado **sem formatação**; `@[Nome](id)` vira menção (`:1003`, `:457-474`).

**Janela "Inserir código"** (`CodigoModal.vue`, ENV-10): título "Inserir código"; seletor com `texto, javascript, typescript, python, sql, json, html, css, bash, csharp, pascal, markdown, mermaid` + a detectada se estiver fora (`:80-84`); placeholder "Cole ou escreva seu código aqui..." (`:161`); "Cancelar"/"Enviar". Atalhos: §7.1.

**FMX:** interceptar Ctrl+V (e o menu "Colar") no campo (`IFMXClipboardService`):
- se há bitmap → salvar PNG temporário `print-<ms>.png` e inserir como peça;
- se há lista de arquivos (CF_HDROP) → inserir cada arquivo (o serviço de área de transferência do FMX trata texto e imagem; a lista de arquivos vem da API do Windows, `DragQueryFile`);
- se é texto com > 10 linhas → abrir o form de código (mesmo comportamento de Cancelar/Enviar);
- se `pareceCodigo` → inserir cercado;
- senão, texto sem formatação, com `@[Nome](id)` virando menção.

Reaproveitar as mesmas expressões regulares de `codeBlocks.ts:138-148`. A exceção do GIF depende de ler o formato HTML da área de transferência: opcional no FMX.

### 7.4 Menu de contexto, hover e toque longo

Complementa ENV-17, ENV-19, ENV-20, MSG-09, MSG-12, CON-05, CON-10 e GER-05.

**Clique direito na bolha** (`MessageBubble.vue:23,261-273`; `MensagemAcoes.vue`):
- O menu nativo do navegador é **bloqueado** em todo o app, exceto em `INPUT`, `TEXTAREA` e editáveis (`App.vue:2,320-325`; GER-05).
- **Clique direito** → menu completo junto do botão de ações. Itens, nesta ordem (`MensagemAcoes.vue:30-112`):
  - reações rápidas 👍 ❤️ 😂 😮 / 😢 👏 🔥 + "Mais emojis" (`:196-197`, `:53-61`);
  - **Responder**;
  - **Responder no privado** (só em grupo e em mensagem de outro, `:74`);
  - **Encaminhar**;
  - **Copiar**;
  - **Ocultar** (só minha e não oculta, em vermelho, `:103`).
- O que é copiado depende de onde foi o clique: numa `<img>` copia **aquela imagem**; no texto (`[data-conteudo-texto]`) copia o texto; senão, a mensagem toda (`MessageBubble.vue:331-336`).
- **Ctrl + clique direito** → abre **só a barra de reações** (7 emojis + "Mais emojis"), **centrada no ponto do clique**, acima dele (ou abaixo, se não couber); o emoji em que eu já reagi fica destacado (`MessageBubble.vue:268-270`; `MensagemAcoes.vue:114-145,306-316`). "Mais emojis" troca a barra pelo seletor completo junto dela (`:319-328`). **Se aplica no desktop** e deve ser replicado.
- Sem menu: mensagens não salvas (id ≤ 0), de **chamada** e **ocultas** (`MessageBubble.vue:28`).

**Botão de ações** (`MensagemAcoes.vue:1-18`):
- aparece **só com o mouse sobre a bolha** (`group-hover/bubble`), ao lado dela: à **esquerda** da minha mensagem, à **direita** da de outro;
- em bolhas altas, **acompanha a rolagem** (`atualizarTopOffset`, `:411-420`);
- o ícone é uma **seta para baixo** (chevron), não "⋯", e **não tem `title`**;
- o menu abre **abaixo** do botão, ou **acima** se não couber, ou centralizado (`:228-257`); fica dentro da janela; um menu por vez (evento `fechar-menu-acoes`, `:270-279`);
- **fecha** com clique fora, Esc e **qualquer rolagem** da lista (`:390-396,422-427`).

**Toque longo** (`MessageBubble.vue:275-328`): só para `pointerType === 'touch'`. **500 ms**, tolerância de **10 px**; abre o menu completo e engole o clique ao soltar. Num desktop com tela de toque (Windows) também vale (§7.13).

**Hover:**
- **Detalhe de status** (MSG-09; só nas minhas mensagens, fora da bolha): com o mouse parado **300 ms** sobre o ✓/✓✓ abre o `DetalheStatusMensagem`; sai ao tirar o mouse; clique alterna (`MessageBubble.vue:57-65,244-251`). Textos (`DetalheStatusMensagem.vue:10,17,60-91`):
  - direta: "Enviada", "Recebida", "Visualizada", "Ouvida" (áudio), "Oculta", "Aguardando";
  - grupo: "Visualizada por", "Recebida por", "Aguardando";
  - erro: "Não foi possível carregar o status.".
- **Reações** (ENV-17):
  - chip `emoji contagem`; com o mouse em cima, tooltip com **foto (ou inicial), nome e hora** de cada pessoa — hora `HH:MM` se for hoje, senão `dd/MM HH:MM` (`MessageBubble.vue:122-157,359-364`);
  - **5 chips à mostra**; o resto num chip **"+N"** (`title` "Mais N reações"), que no hover lista emoji, contagem e nomes, e clicar alterna (`:160-189,385-386`).
- **Menção** (MSG-12): no hover, cartão com foto (ou inicial) e nome; clique abre a conversa direta com a pessoa (`MencaoLink.vue:3-20`).
- **Lista de conversas:** no hover (só em telas ≥ 768 px) aparecem os botões **"Mais opções"** (três pontos) e **"Abrir em nova janela"** (`ChatSidebar.vue:146-158`; CON-05, CON-10).

**Clique direito na conversa** (CON-05; `ChatSidebar.vue:72,350-358,363-380`): menu no ponto do clique, recuado para caber na janela. Itens: "Fixar"/"Desafixar" + "Arquivar" (conversa não arquivada) ou "Desarquivar" (arquivada).

**FMX:**
- `TPopupMenu` montado na hora no `OnMouseUp` (botão direito) da bolha, com `ssCtrl` decidindo entre o menu completo e a barra de reações (um `TPopup` com 8 botões, centrado em `Screen.MousePos`);
- botão de ações num `TLayout` que aparece no `OnMouseEnter` da bolha;
- detalhe de status com `TTimer` de 300 ms no `OnMouseEnter` do ícone;
- tooltips de reação e cartão de menção com `TPopup`/`TCalloutPanel` (o `Hint` simples não mostra foto);
- `Hint`/`ShowHint` para os `title` dos botões;
- nos campos de texto, manter o menu nativo (Copiar/Colar); no resto, só os menus do app (GER-05).

### 7.5 Janela popup de conversa (`chat-popup.html`)

Complementa CON-10.

- **Como abre:** botão "Abrir em nova janela" (hover do item da lista, `ChatSidebar.vue:153-158`) → `window.open('/chat-popup.html?conversa=<id>', 'chat-popup-<id>', 'width=900,height=700,left=…,top=…')`, **centrada sobre a janela atual** (`App.vue:834-846`). O nome `chat-popup-<id>` faz a mesma conversa reaproveitar a mesma janela.
- **Entrada:** `chat-popup.html` → `src/chat-popup.ts`. `conversa` inválida ou ≤ 0 → página só com "Conversa invalida." (`chat-popup.ts:10-11`). Cria **outra instância do Pinia** (`:13-15`) e aplica as cores personalizadas.
- **O que mostra** (`ChatPopup.vue`):
  - "Carregando conversa..." enquanto carrega;
  - `ChatHeader` com `popout` (sem o botão de voltar, `ChatHeader.vue:7`), indicador de upload, lista, campo, visualizador de imagens, pré-visualização e encaminhamento;
  - "Conversa nao encontrada." se a conversa não existe;
  - sem sessão: "Sessao expirada. Faca login novamente." (`:218-221`);
  - **título da janela** = `descricao || nome || 'Conversa'` (`:210-214`).
- **O que não tem:** barra de navegação, lista de conversas, camada de arrastar (`useDragAndDrop` não é usado), `beforeunload`, tratamento de chamadas (o handler de chamada não é registrado). Os botões de ligar e "Dados do grupo" **aparecem no cabeçalho, mas ninguém trata os eventos** (`ChatHeader.vue:90-109` emite `start-call`/`open-group-members`; `ChatPopup.vue:16-19` não os escuta) — **não confirmado em execução**.
- **Sincronização com a janela principal: não existe canal direto.** Não há `BroadcastChannel`, `postMessage` nem evento `storage` para o chat (busca em `src/`; o único `storage` é o das cores, `useCoresPersonalizadas.ts:206-207`).
  - O popup chama `chat.inicializar()` (`ChatPopup.vue:225`): carrega contatos e conversas, **abre o próprio WebSocket** e o próprio polling, e pede permissão de notificação (`stores/chat.ts:154-161`).
  - As duas janelas são **duas conexões do mesmo usuário** e se sincronizam **só pelo servidor**. Como o servidor não manda WS 2 ao próprio remetente nem WS 3 ao próprio leitor (doc 01), mensagem enviada ou lida numa janela só aparece na outra quando algo a faz recarregar.
  - Efeito colateral (lido do código, **não confirmado em execução**): as duas janelas tratam o mesmo WS 2. Cada uma toca o som e cria a notificação (a segunda substitui a primeira pela mesma `tag`, mas o **som toca duas vezes**). O popup só deixa de notificar a própria conversa quando **ele** tem o foco.
- **FMX:** abrir um `TForm` por conversa (reutilizar se já aberto; título = nome da conversa; 900×700 centrado no form principal), **no mesmo processo**, com **o mesmo WebSocket e o mesmo cache** do form principal. As duas janelas ficam sincronizadas de verdade e não há som/notificação em dobro. A regra de "conversa aberta e focada não notifica" deve considerar **qualquer** form que mostre a conversa e esteja ativo (§7.11). Chamadas continuam tratadas pelo form principal. Os botões de ligar e "Dados do grupo" do cabeçalho devem funcionar (encaminhando ao form principal) ou ser escondidos; não copiar a falha do web.

### 7.6 Janela flutuante da chamada

Complementa CHA-13 (e CHA-11, CHA-12, CHA-18).

**Janela flutuante da chamada** (`src/CallWindow.vue`, `composables/useDraggable.ts`, `App.vue:174-191,375-379,402-404`):
- **Só para chamada de vídeo** e em tela ≥ 768 px. Em vídeo não minimizado, a chamada cobre o app inteiro (`fixed inset-0`). O botão **"Minimizar"**/**"Expandir"** (`CallWindow.vue:363-364`) alterna. Chamada de **áudio** nunca flutua: só a `CallBar` no topo do chat.
- **Posição e tamanho iniciais:**
  - `x = innerWidth − 440`, `y = 16`, **420×350** px, ou seja, canto superior direito (`useDraggable.ts:5-14`);
  - mínimo **320×240**, máximo **90%** da janela (`:18-19,63-64`).
- **Arrastar:** pelo **cabeçalho** (cursor de mão), com captura do ponteiro; a janela fica ao menos 100 px dentro da área visível (`useDraggable.ts:35-41,85-87`; `CallWindow.vue:17-21`).
- **Redimensionar:** pelas 4 bordas (faixas de 6 px) e 4 cantos (12 px) (`CallWindow.vue:413-421`).
- Na flutuante **somem** o seletor de modo (Grade/Destaque/Tela única), o painel e o botão do chat da chamada (`CallWindow.vue:41,255,304`).
- Cabeçalho: "Chamando..." / "Em chamada" / "Encerrando...", duração, "Vídeo"/"Áudio", "N pessoa(s)" (`:22-38`).
- **FMX:** um `TForm` próprio da chamada:
  - `BorderStyle = None`, `FormStyle = StayOnTop`;
  - arraste pelo cabeçalho (`StartWindowDrag`) e redimensionamento pelas bordas;
  - posição inicial no canto superior direito **da tela** (pode até sair do form principal, o que o navegador não permite);
  - mesmos mínimo e máximo; mesmos itens ocultos.

### 7.7 Discador SIP

Complementa SIP-03 e SIP-04.

**Discador SIP** (`components/SipDialerModal.vue`):
- Abre pelo item **Ramal** da barra (só com SIP ativo) ou quando uma chamada SIP recebida está conectando (`App.vue:255,383-385`).
- Caixa de **288 px** de largura (`w-72`), **centralizada** ao abrir (`:226-233`); arrastável **pelo cabeçalho**, sempre dentro da janela (`:236-254`); "×" fecha.
- Conteúdo:
  - "Ramal" + `sip_user` (ou "Indisponivel");
  - "Status do ramal": "Sem configuracao", "Ramal inativo", "Registrado", "Conectando", "Conectado sem registro", "Falha na conexao", "Desconectado" (`:256-264`);
  - campo "Digite o numero" (`:39`).
- **Não há** atalho de teclado: Enter não liga e as teclas numéricas fora do campo não discam.
- **FMX:** `TForm` pequeno sem borda, `StayOnTop`, arrastável pelo cabeçalho, centrado no form principal ao abrir. Digitar no campo com o teclado numérico físico é o comportamento padrão do controle; Enter para ligar seria melhoria.

### 7.8 Notificações, sons, título/favicon e saída com upload

Complementa NOT-01 a NOT-06, CHA-03 e ANX-02.

**Mensagem nova** (`stores/chat.ts:904-1013`; `utils/sound.ts`):
- **Gatilho:** WS 2 (ou o polling de 8 s com o socket fora) → `GET /mensagens/novas?desde=<cursor>` → para cada conversa afetada, `GET /mensagens` (10 últimas) para ter o conteúdo (`chat.ts:905-933`).
- **Quem notifica** (`chat.ts:936-940`): mensagens que **não são minhas**, que **não** são da conversa ativa **com a janela focada** (`document.hasFocus()`), e de conversa **não arquivada**.
- **Som:** **um** `playNotificationSound()` por lote, com a janela focada ou não (`chat.ts:944`):
  - toca `/notification.mp3`;
  - se o `play()` falhar, um bipe senoidal de **880 Hz por 0,5 s** (`sound.ts:4-48`).
- **Notificação do sistema:** **uma por conversa**, com o conteúdo da **última** mensagem do lote (`chat.ts:955-990`):
  - **título:** nome completo do remetente (pelos contatos) → senão `remetente` (primeiro nome) → senão "Nova mensagem" (`:965`);
  - **corpo:** a partir do **primeiro conteúdo** — texto resumido (menção vira `@Nome`, código vira `Código (linguagem)`), "Imagem", "Gravacao de audio", "Audio", "Figurinha", "Votação", senão "Arquivo" (`:970-980`);
  - **ícone:** avatar do contato → avatar da conversa → `/logo.png` (`:968`);
  - **opções:** `tag: conversa-<id>`, `renotify: true` (repete o alerta ao substituir), `requireInteraction: true` (fica até interagir), `silent: true` (o som é o do app) (`sound.ts:185-193`, `:221-228`);
  - criada pelo service worker se registrado; senão pela página (`new Notification`, com o cuidado do `onclose` assíncrono, `sound.ts:197-253`).
- **Fecha quando:** o contador de não lidas da conversa chega a 0 depois de visualizar (`chat.ts:715-729`), e ao arquivar (`chat.ts:216`). Fecha as duas origens (`sound.ts:263-273`).
- **Clique:**
  - via service worker: foca a janela principal (exclui `/chat-popup`; prefere a focada, depois a visível) e manda `postMessage({tipo:'conversa-abrir', conversaId})`; o `App.vue` abre a conversa **recarregando as mensagens** (`public/firebase-messaging-sw.js:32-47`; `App.vue:481-485,716-724`);
  - via página: `window.focus()` + `selecionarConversa` (`sound.ts:232-237`; `chat.ts:986-989`).
- **Permissão:** pedida ao iniciar o chat (`chat.ts:160`) e logo depois do login, se ainda `default` (`LoginForm.vue:78-79`).

**Push em segundo plano (FCM web):**
- o service worker mostra `titulo`/`mensagem` com `icon:'/logo.png'`, `silent:true` e `tag conversa-<id>`, **sem** `requireInteraction` (`firebase-messaging-sw.js:17-28`);
- só chega com **nenhuma aba aberta** (regra do servidor: com qualquer conexão do usuário aberta não há push — doc 01 §15.1, doc 08 S2). Não se aplica ao FMX (§7.13).

**Chamada recebida** (`composables/useCallPopup.ts`):
- toque `/toque.mp3` em loop para quem recebe e `/chamando.mp3` em loop para quem liga (`:7-8,111-119`);
- notificação **"Chamada recebida"** / "**<nome> está ligando (Vídeo|Áudio)**" (nome = `usuario_nome` de quem ligou, ou "Alguém"), com `tag: conversa-chamada` e `requireInteraction: true` (**sem** `silent`), ícone `/logo.png` (`:77-97`);
- fechada quando para de tocar (`:120-126`);
- recusa automática após **30 s** tocando (`stores/call.ts:1529-1534`).

**Título da aba e favicon com contador: não existe.** `index.html:6` tem o título fixo "Conversa". O único `document.title` é o do popup (`ChatPopup.vue:212`). Não há `setAppBadge` nem troca de favicon (busca em `src/`).

**`beforeunload`:** só na janela principal. Com upload ativo (`temUploadAtivo`), chama `e.preventDefault()`, e o navegador mostra o aviso padrão dele, sem texto do app (`App.vue:474-478,488`; `composables/useUploadProgress.ts:33`). O indicador de upload só aparece se, **2 s** depois de começar, algum envio estiver abaixo de **50%** (`useUploadProgress.ts:13-30`).

**FMX:**
- **Toast do Windows** (`TNotificationCenter`, `System.Notification`) com `Name = 'conversa-<id>'`: cancelar e recriar para substituir, e cancelar pelo nome ao zerar as não lidas e ao arquivar. Mesmos título e corpo. Ícone: o do app (o toast do FMX não aceita a foto do contato sem WinRT direto). O `requireInteraction` não tem equivalente no `TNotificationCenter`; avaliar toast WinRT com cenário "reminder" ou aceitar que o toast vá para a Central de Ações.
- **Som:** tocar o mesmo `notification.mp3` uma vez por lote (`TMediaPlayer`, ou `PlaySound` com WAV) e o toast em silêncio.
- **Clique no toast** (`OnReceiveLocalNotification`): restaurar e trazer o form para a frente e abrir a conversa recarregando as mensagens.
- **"Janela focada"** = `Application.Active` e o form que mostra a conversa é o ativo, não minimizado (§7.11).
- **Chamada:** toast "Chamada recebida" + toque em loop + trazer o app para a frente (`FlashWindowEx`).
- **Extras opcionais** (o web não tem): contador no ícone da barra de tarefas (`ITaskbarList3.SetOverlayIcon`) e na bandeja. Título com contador também seria extra, não paridade.
- **Fechar o app com upload ativo:** `OnCloseQuery` com confirmação. Se o app vai para a bandeja ao fechar, o upload pode continuar.
- **Desktop sempre conectado:** o WS 2 pode chegar repetido (som e toast não podem repetir — §4.2), e o temporizador de 30 s da chamada recusa por todos os aparelhos do usuário (CHA-03).

### 7.9 Abas de configurações

Complementa CFG-01 a CFG-08 e SIP-01.

Títulos e descrições das abas (`components/ProfileSettingsModal.vue:432-445`, sem acento como no código): "Usuario — Nome, email, avatar e senha"; "Dispositivos — Sessao atual e perifericos locais"; "Permissoes — Notificacoes, microfone e camera"; "Voip — Configuracao SIP do usuario"; "Cores — Cores do sistema, salvas neste navegador"; "Chamadas — Qualidade do áudio, vídeo e tela"; "Sistema — Configurações que valem para todos" (só com `parametros`); "Acessos" (só com `permissoes`). **Usuario** (AUT-05 a AUT-08, CFG-02) e **Voip** (SIP-01) dependem só da API e de preferências locais e valem literalmente no FMX.

**Dispositivos** (CFG-03; `ProfileSettingsModal.vue:199-272,647-…,720-776`):
- **"Sessao atual"** ("Informacoes do navegador autenticado neste momento.", etiqueta "Ativo"): Dispositivo / Modelo / Sistema / Plataforma, detectados **localmente**, não lidos da API.
- **"Dispositivos de midia"** ("Lista local de microfones, cameras e saidas detectadas pelo navegador."):
  - botão "Atualizar lista" ("Atualizando...");
  - `enumerateDevices()` só com os que têm rótulo, tirando o sufixo `(xxxx:xxxx)`;
  - tipo "Microfone" / "Saida de audio" / "Camera";
  - etiquetas "Padrao" (`deviceId === 'default'`) e "Comunicacao" (`'communications'`);
  - vazio: "Nenhum dispositivo de midia foi identificado ainda. ...".
- **Não há seleção.** A aba **só lista**. O web nunca passa `deviceId` ao `getUserMedia` (`stores/call.ts:808,863,1164,1199,1286`) e não usa `setSinkId` (busca em `src/`): chamadas e gravação usam **sempre o dispositivo padrão do sistema**.
- **FMX:** listar com a API de áudio/vídeo usada (WASAPI/MMDevice, Media Foundation). Para a paridade basta listar. **Escolher** microfone/câmera/alto-falante seria uma **melhoria em relação ao web** (decisão de produto; se fizer, gravar a escolha nas configurações locais e aplicar na captura da chamada e da gravação). "Sessao atual" mostra o nome do computador, "Desktop", a versão do Windows e "Windows" (§1.6).

**Permissões** (CFG-04, NOT-06; `:274-308,550-637`): "Permissoes do navegador" ("Gerencie as permissoes necessarias para o funcionamento completo do aplicativo.").
- Itens:
  - "Notificacoes" — "Alertas de novas mensagens e chamadas recebidas";
  - "Microfone" — "Gravacao de audio e chamadas de voz";
  - "Camera" — "Chamadas de video".
- Status: "Concedida" / "Negada" / "Nao solicitada" / "Indisponivel"; botão "Solicitar" quando ainda não foi pedido.
- Dica do cadeado da barra de endereço.
- **FMX:** no Windows as permissões são da **Privacidade do sistema** (Configurações → Privacidade e segurança → Microfone/Câmera/Notificações). Mostrar o estado e um botão que abre `ms-settings:privacy-microphone`, `ms-settings:privacy-webcam` e `ms-settings:notifications`. Aplicativo Win32 clássico não tem prompt por app: o estado vem de "Permitir que aplicativos da área de trabalho acessem..." — **não confirmado** como o FMX lê isso. Sem a dica do cadeado.

**Cores** (CFG-05; `components/ConfiguracaoCores.vue`, `composables/useCoresPersonalizadas.ts`):
- grupos "Principal", "Superfícies", "Sucesso", "Perigo", "Informação", "Alerta", "Chamada" (`useCoresPersonalizadas.ts:29-140`), **separados por tema** (claro/escuro);
- salvos no `localStorage` `conversa.cores` (`:142,151,178`) e sincronizados entre janelas pelo evento `storage` (`:206-207`);
- busca "Buscar pela variável ou pelo uso (ex.: primary-600, mensagens)"; "Restaurar todas", "Restaurar grupo", "Voltar ao padrão" por cor.
- **FMX:** as cores do FMX são as de `docs/design/cores.md` (o Android usa as do FMX). Editar cores pode ser estilo/`TStyleBook` com sobreposições gravadas localmente. Baixo valor; no mínimo, tema claro/escuro (CFG-02). Com várias janelas no mesmo processo (§7.5), a troca vale para todas sem sincronização extra.

**Chamadas** (CFG-06, CHA-20; `components/ConfiguracaoChamadas.vue`, `composables/useConfigChamada.ts`):
- salvo no `localStorage` `conversa.chamada` (`:22`); "Restaurar padrão"; aviso "Estas opções valem para o que você **envia** nas chamadas e ficam salvas neste navegador. Durante uma chamada, as mudanças valem na hora.";
- **Áudio:** "Redução de ruído", "Cancelamento de eco", "Ganho automático do microfone" (ligados por padrão); "Qualidade do áudio": Normal 32 kbps (padrão) / Alta 64 kbps / Música 128 kbps estéreo ("O estéreo vale a partir da próxima chamada.") — `ConfiguracaoChamadas.vue:78-88`;
- **"Vídeo da câmera":** Resolução 360p/720p/1080p (padrão **720p** no desktop); "Quadros por segundo" 15/24/30 (padrão **24** no desktop); "Limite de banda" Automático / Econômico (0,5 Mbps) / Alto (3 Mbps) — `useConfigChamada.ts:26-37,52-58`;
- **"Compartilhamento de tela" → "Prioridade":** Nitidez (até 15 fps, padrão) / Fluidez (até 30 fps).
- **FMX:** mesmas opções e padrões de desktop, gravadas localmente. Redução de ruído, cancelamento de eco e ganho dependem do motor de captura (no navegador são `getUserMedia` constraints); confirmar com a pilha WebRTC do FMX.

**Sistema** e **Acessos** (CFG-07, CFG-08): dependem só da API (`GET/PATCH /parametros`, `GET /permissoes`, `PUT/DELETE /permissao/usuario`) e da permissão do usuário (`auth.temPermissao`). Valem literalmente no FMX. Textos exatos em CFG-07/CFG-08 (§3.12).

### 7.10 Conexão lenta (`navigator.connection`)

Complementa MSG-18.

- `composables/useConexao.ts:9-38`: lê `navigator.connection.effectiveType` e escuta o `change`. É **lenta** só com `slow-2g` ou `2g`. **Sem a API** (Firefox, Safari), considera **rápida**.
- Efeito (`components/MessageContent.vue:102-114,147-158,316-323`):
  - imagem e vídeo recebidos (sem `localUrl`) mostram uma caixa "**Toque para abrir**" (imagem) ou "**Toque para carregar**" (vídeo) e só baixam ao clicar;
  - depois de liberada, a imagem mostra "Carregando..." até carregar.
- **FMX:** no desktop a API não existe; o equivalente seria rede limitada ou tarifada (`NetworkInformation.GetInternetConnectionProfile().GetConnectionCost()` da WinRT, ou `INetworkCostManager`). Como no navegador desktop a regra quase nunca dispara, **pode ser omitida**, ou virar opção manual "baixar mídia só ao clicar" (nesse caso, "Clique para abrir"/"Clique para carregar" faria mais sentido que "Toque").

### 7.11 Regras de foco da janela (afetam leitura e indicador)

Complementa MSG-03, MSG-04 e NOT-01/NOT-02.

- **Visualizar** só marca com a janela focada: `validarMensagensCompletamenteVisiveis` sai se `!document.hasFocus()` (`composables/useScrollManager.ts:353-359`). Ao a janela voltar a ter foco, reavalia (`useScrollManager.ts:983`).
- **Linha "Últimas":** com a janela focada e a rolagem a ≤ 500 px do fim, mensagem nova **não** cria a linha (`MessageList.vue:366-369`). Ao perder o foco (`blur`), a próxima mensagem reposiciona a linha (`MessageList.vue:470`).
- **FMX:** usar `Application.Active` e o `OnActivate`/`OnDeactivate` do form que mostra a conversa, não só "o form existe". Minimizado ou na bandeja = sem foco. Com janelas de conversa separadas (§7.5), vale o form ativo que mostra a conversa; ao reativar um form, reavaliar a leitura (como o web faz ao voltar o foco).

### 7.12 Outras adaptações

Itens do web que dependem de bibliotecas ou APIs do navegador e precisam de um equivalente no FMX (o comportamento continua o descrito no ID).

| Item web | ID | No FMX |
|---|---|---|
| Visualizador de PDF (pdf.js) | ANX-06 | `TWebBrowser` (WebView2) com o PDF num arquivo temporário, ou o app padrão via `ShellExecute`; manter "Abrir", "Baixar" e os textos de erro |
| Visualizador de HTML isolado (`iframe srcdoc`, `sandbox="allow-scripts"` sem `allow-same-origin`) | ANX-07 | Abrir no **navegador padrão** a partir de um arquivo temporário, ou num **WebView2 isolado**: HTML carregado como texto (sem a origem do servidor), sem ponte JS, sem o token e sem os cookies da sessão. Links `#...` rolam dentro do documento (`eaa8bac`) |
| CodeMirror na janela "Inserir código" | ENV-10 | `TMemo` monoespaçado com o seletor de linguagem; destaque de sintaxe opcional |
| highlight.js, Markdown e Mermaid nos blocos de código | MSG-15, ANX-08 | Destaque por tokenizador simples com atributos de `TTextLayout`; Markdown com render próprio (Skia) ou WebView2 isolado; Mermaid em WebView2 isolado ou só o código ("Visualizar" opcional) |
| Figurinhas Lottie (`lottie-web`) | ENV-04 | `TSkAnimatedImage` (Skia4Delphi/Skottie), com os JSON embutidos como recurso ou baixados de `https://HOST/figurinhas/<pacote>/<nome>.json` (o servidor ainda não os serve — doc 08 S5) |
| Download com `<a download>` (falha → abre a URL em nova aba) | ANX-09 | `TSaveDialog` + baixar o **conteúdo** da URL assinada devolvida por `GET /anexo` (não o JSON da resposta); falha → abrir a URL no navegador padrão; erro "Não foi possível baixar" |
| Faixa "Conexao em tempo real indisponivel — usando atualizacao periodica" e polling de 8 s | GER-02, §1.4 | Literal: faixa no topo do form principal depois de 5 s sem socket; polling de 8 s só com o socket fora |
| `localStorage` (`conversa.token`, `conversa.user`, `conversa.deviceId`, `theme`, `conversa.cores`, `conversa.chamada`) e IndexedDB (rascunhos) | §1.2, ENV-23, CFG-02, CFG-05, CFG-06 | Arquivos locais por usuário do Windows (ex.: `%LOCALAPPDATA%\Conversa\`); token e credencial protegidos (DPAPI/Gerenciador de Credenciais, §1.5); `dispositivo_id` mantido no logout |
| Áudio do sistema no compartilhamento de tela (`getDisplayMedia` com `systemAudio:'include'`) | CHA-15 | WASAPI *loopback* misturado ao microfone numa trilha só; captura da tela por Windows.Graphics.Capture (ou a que o FMX já usa) |
| Ponteiro remoto (posição do mouse) | CHA-17 | Literal (há mouse): enviar `{acao:'ponteiro', alvo, x, y}` relativos à imagem do vídeo, no máximo a cada 40 ms; desenhar os ponteiros com nome e cor (`id % 5`) |
| Indicador de fala por `AnalyserNode` | CHA-19 | RMS do PCM do microfone e do áudio decodificado de cada participante (> 0,02, segura 400 ms), ou o `audioLevel` do `getStats()` se a pilha WebRTC expuser |
| `setCodecPreferences` H264/VP9 | §5.3 | **Obrigatório para a gravação:** oferecer H264 primeiro e VP9 em seguida na pilha WebRTC do FMX (o MediaMTX não grava VP8) |
| Áudio remoto num `HTMLAudioElement` por participante | CHA-23 | Um reprodutor por participante que vive a chamada inteira, independente do form (janela flutuante ou tela cheia) |
| Detecção do dispositivo pelo *user agent* | AUT-04, CFG-03 | Nome do computador (≤ 50), `modelo: 'Desktop'`, versão do Windows (ex.: `10.0.22621`, ≤ 15) e `plataforma: 'Windows'`, sem `token_fcm` (§1.6) |
| `conversa.apiBase` | §1.3, §1.4 | Base configurável; WebSocket e MediaMTX derivados da **mesma base** (`wss://host/ws/`, `https://host/webrtc/`), sem `:443` na URL (§1.7) |
| Seleção de texto bloqueada nas configurações | — | Literal: rótulos não selecionáveis |
| Tela "Em desenvolvimento" / Equipes | GER-06 | Não replicar: item não implementado não aparece (Equipes saiu do web em `bfb79d8`) |

### 7.13 O que não se aplica ao desktop

| Item web | Por que não se aplica | No FMX |
|---|---|---|
| **Toque longo** (500 ms, tolerância de 10 px) abre o menu completo da mensagem (ENV-20) | Só existe com `pointerType === 'touch'`: num desktop com mouse não dispara | Só em tela de toque: opcional, com o gesto `LongTap` do FMX abrindo o mesmo menu completo (§7.4) |
| **Layout < 768 px** (ex.: barra de navegação no rodapé, de 50 px; uma coluna, lista **ou** conversa; configurações em sub-tela; chamada minimizada só na barra; chat da chamada por cima) | É o layout de celular do web | O FMX segue o layout de desktop (barra vertical à esquerda, lista + conversa lado a lado). Janela estreita reduz colunas e painéis, sem trocar para o layout de celular |
| **FCM web e service worker** (`token_fcm` + VAPID, push com a aba fechada; NOT-04, §1.6) | O FMX não usa FCM | `PATCH /dispositivo` sem `token_fcm`; as mensagens chegam pelo WebSocket e a notificação é o toast local (§7.8). Atenção à regra do servidor (doc 01 §15.1, doc 08 S2) |
| **`navigator.connection`** (conexão lenta; MSG-18) | API de navegador, ausente no desktop | Omitir ou opção manual "baixar mídia só ao clicar" (§7.10) |
| **`beforeunload`** com upload ativo (ANX-02) | Evento de página do navegador | `OnCloseQuery` do form principal com confirmação (§7.8) |
| **Permissões do navegador** (prompt, cadeado da barra de endereço; CFG-04, NOT-06) | No Windows não há prompt por app Win32 | Estado da **Privacidade do Windows** e botões `ms-settings:` (§7.9) |
| Bloqueio de autoplay (som de toque só no primeiro clique/tecla; CHA-01, CHA-03) | Regra do navegador | O desktop toca direto (§7.1) |
| URL, `history.pushState` e voltar/avançar do navegador (§2.1, CON-12) | Não há barra de endereço | Navegação pelo estado dos forms; a conversa aberta por notificação vem do clique no toast (§7.8) |

---

## 8. Anexo A — Commits desde 2026-09-12 e o que tocaram

| Data | Commit | Assunto | Principais arquivos |
|---|---|---|---|
| 2026-10-06 | `bfb79d8` | Abas Sistema e Acessos nas configurações; Equipes sai da barra | `ConfiguracaoSistema.vue`, `ConfiguracaoAcessos.vue`, `ProfileSettingsModal.vue`, `NavBar.vue`, `auth.ts` (permissões), `conversaApi.ts`, `types/api.ts`, `useHistoryNavigation.ts` |
| 2026-10-05 | `39d5af1` | Tela de atividades, com contador de novas na barra | `AtividadesPage.vue`, `stores/atividades.ts`, `NavBar.vue`, `App.vue`, `call.ts` (`nao_atendeu`), `chat.ts` (WS 61), `eden.ts` (`vistas_em`) |
| 2026-10-05 | `51a0cd7` | Excluir mensagem vira "Ocultar" | `BolhaExcluida.vue`, `MensagemAcoes.vue`, `MessageList.vue`, `DetalheStatusMensagem.vue`, `BolhaReferencia.vue`, `ReferenciaRecursiva.vue`, `messageReferences.ts` |
| 2026-10-03 | `20d5b73` | Ponteiro remoto e chat na chamada; figurinhas Lottie | `call.ts`, `PonteiroTela.vue`, `ChatChamada.vue`, `CallWindow.vue`, `chat.ts` (`enviarSinalChamada`), `figurinhas.ts`, `FigurinhaLottie.vue`, `BolhaFigurinha.vue`, `EmojiPicker.vue`, `public/figurinhas/**` |
| 2026-10-03 | `c32209a` | Login volta sem F5 depois que o servidor reinicia; copiar imagem pelo menu | `App.vue` (`iniciarSessao`), `LoginForm.vue`, `eden.ts` ("Servidor indisponível"), `ImageViewerModal.vue` |
| 2026-10-02 | `466e79a` | Adiciona os vídeos ao visualizador | `useImageViewer.ts`, `ImageViewerModal.vue`, `MessageContent.vue`, `AnexosLista.vue`, `formatters.ts` |
| 2026-10-02 | `f83ecd1` | Mensagem excluída continua no chat; confirmação e menu de ações próprios | `BolhaExcluida.vue`, `DialogoConfirmacao.vue`, `useDialogo.ts`, `MensagemAcoes.vue`, `classificarMensagem.ts`, `chat.ts` |
| 2026-10-02 | `dfeedbf` | Publica o vídeo das chamadas em codec que o MediaMTX grava | `call.ts` (`preferirCodecsGravaveis`) |
| 2026-10-02 | `6b121f2` | Texto longo colado abre a janela de código; botão de expandir sempre aparece | `MessageInput.vue`, `CodigoModal.vue`, `MessageContent.vue`, `codeBlocks.ts` |
| 2026-09-30 | `fa6b4f7` | Corrige anexos sem assinatura, erros soltos de anexo e agendadas atrasadas | `useAttachments.ts`, `useAgora.ts`, `MessageList.vue` |
| 2026-09-30 | `48ae9d3` | Testes de componentes, composables e utilitários | `tests/unit/**` (549 testes na época) |
| 2026-09-30 | `bc11b32` | Sugere código ao colar texto longo; tira TURN fixo do SIP; detecta iPhone | `sip.ts` (ICE do backend), `auth.ts`, `codeBlocks.ts` |
| 2026-09-29 | `77c49d2` | Adiciona testes unitários | `tests/unit/**`, ajustes em stores |
| 2026-09-28 | `0c404fd` | Corrige status online, notificações e digitando; abre anexos HTML isolados | `chat.ts`, `VisualizadorHtml.vue`, `AnexosLista.vue`, `ImageViewerModal.vue` (legenda), `call.ts`/`CallWindow.vue` (tela única ao só assistir) |
| 2026-09-27 | `d9f9a97` | Move as conversas arquivadas para o fim do painel lateral | `ChatSidebar.vue` |
| 2026-09-26 | `4007600` | Migra para Bun e Eden; fixar, arquivar e indicador de fala | `eden.ts`, `conversaApi.ts`, `ChatSidebar.vue`, `CallBar.vue`, `useFalaChamada.ts`, `MessageInput.vue` (menção destacada, código colado), `MensagemAcoes.vue` (responder no privado, copiar conforme clique), `sound.ts` (notificação de chamada pelo SW) |
| 2026-09-25 | `1861d37` | Ajusta notificações, status e layout do chat | `DetalheStatusMensagem.vue`, `MessageBubble.vue`, `sound.ts`, `conversaApi.ts` |
| 2026-09-23 | `217ac04` | Adiciona áudio da máquina na transmissão de tela | `call.ts`, `ConfiguracaoChamadas.vue`, `useConfigChamada.ts`, `SeletorOpcoes.vue`, `ordemMensagens.ts` |
| 2026-09-22 | `cc18872` | Visualizadores de Markdown, Mermaid e PDF; ajustes no chat | `useMarkdown.ts`, `useMermaid.ts`, `VisualizadorPdf.vue`, `emojiAtalhos.ts`, `firebase-messaging-sw.js`, `toque.mp3`, `chamando.mp3`, `MessageList.vue` (indicador fixo) |
| 2026-09-18 | `3d764d1` | Ajusta chat, chamadas e adiciona personalização de cores | `ConfiguracaoCores.vue`, `useCoresPersonalizadas.ts`, `MessageInput.vue`, `CallBar.vue`, `call.ts` (tela sem webcam) |
| 2026-09-17 | `977fa55` | Corrige largura da mensagem de áudio transcrita | `TranscricaoAudio.vue` |
| 2026-09-17 | `05f12c2` | Anexos, avatares e chamadas; modos de exibição e transcrição | `CallWindow.vue` (modos), `TranscricaoAudio.vue`, `useAttachments.ts`, `call.ts` |
| 2026-09-15 | `24806ef` | Muda porta padrão do postgres | README |
| 2026-09-13 | `b203faf` | Ambiente de desenvolvimento e chamadas no celular | `App.vue`, `CallBar.vue`, `vite.config.ts` |
| 2026-09-12 | `75c011f` | Ambiente | `call.ts` (ICE via `/ice`), `conversaApi.ts`, `types/api.ts` |

Antes de 2026-09-12 (março–abril de 2026): base do chat, chamadas, encaminhamento, tema escuro, FCM, navbar, nova janela, SIP, status do usuário, pesquisa global, menções, histórico de chamadas, página de anexos e agendamento (`1b5be8d`, 2026-04-19).

---

## 9. Anexo B — Código morto / legado encontrado

Não replicar sem confirmar com o produto:

- `CallParticipantsModal.vue`: montado no `App.vue`, mas `modalParticipantesChamada` nunca vira `true` (chamada em grupo liga para todos os membros).
- `ImagePreviewModal.vue` / `useImagePreview.ts`: o `MessageInput` declara o evento `open-image-preview` mas não o emite; imagens vão para a fila (ANX-01).
- `ouvirMensagensForeground` (`services/firebase.ts`): sem uso.
- `chamadaFinalizar` / `POST /chamada/finalizar`: na store, sem botão.
- `auth.setApiBase`: sem UI.
- Evento `open-chat-with` do `ChatHeader`: não escutado (a conversa é aberta pela store mesmo assim).
- Dois modais de "Adicionar à chamada" (`AddUserToCallModal.vue` no App e o interno do `CallWindow.vue`) — mesmo comportamento.
- Rota `/ramal` reconhecida pelo parser de URL, mas o item da barra abre o discador.

---

## 10. Atualização de 2026-10-06 (noite) — commit `39d06f9`

Commit **`39d06f9`** — "Campo de mensagem rico, votação em grupo e chat completo na chamada" (35 arquivos, +1774/−684). Acompanha o commit do servidor `8031fa5` (doc 01 §10.13).

### ENV-21 🆕 Campo de mensagem rico (substitui a fila de anexos ANX-01)

- O `MessageInput` virou um `contenteditable` (`utils/editorRico.ts`, `utils/blocosEditor.ts`).
- **O que entra no ponto do cursor:**
  - imagem, vídeo, áudio, arquivo e figurinha entram como **peças** ("átomos"), cada uma **numa linha própria**: o texto depois do cursor desce para a linha de baixo, e o cursor vai para baixo da peça;
  - a menção também é uma peça, mas fica **dentro** da linha de texto.
- **Edição:** o **Backspace apaga uma peça como se fosse um caractere**. Imagens mostram miniatura com "×" no canto.
- **Como os arquivos entram:** seletor de arquivo, colar e **arrastar e soltar dentro do campo**.
- **No envio,** os conteúdos vão **na ordem em que aparecem no campo** (`extrairBlocos`):
  - cada trecho de texto entre peças vira um conteúdo tipo 1;
  - cada peça vira o seu tipo (2/3/4/5/7);
  - linhas vazias entre peças são descartadas;
  - menções viram `@[Nome](id)` dentro do texto.
  - Exemplo: [texto, imagem, texto, figurinha] → conteúdos ordem 1..4 nessa sequência.
- Mensagem só de texto: igual ao antes (ENV-01).
- **Figurinha** (ENV-04) e **gravação** (ANX-11) com o campo **vazio** são enviadas na hora, sozinhas; com algo escrito, entram como peça.
- **Emoji** entra no ponto do cursor (o cursor é guardado quando o campo perde o foco).
- **Placeholder:** "Digite uma mensagem". Altura máxima de 40% da tela, com rolagem.
- **Botão "+" (Anexar)** abre o `AnexoPopup` com: **Arquivo**, **Código** e (só em grupo) **Votação**.
- **Agendar** e **Enviar** aparecem quando há conteúdo; sem conteúdo aparece o microfone.
- **Para o cliente Windows (FMX):** é um campo de composição com peças (anexos, figurinhas, menções) intercaladas no texto. Hoje o FMX tem um `TMemo` e uma fila de anexos separada (o modelo antigo, ANX-01). Caminhos:
  - **editor por blocos** em FMX: blocos editáveis (texto ↔ peça) num `TLayout`/`TVertScrollBox` (ou desenhados com Skia), com a ordem preservada, Backspace apagando a peça, desfazer com peças, colar e soltar arquivos no ponto do cursor (§7.1–§7.3);
  - ou uma versão simplificada: **fila + texto**, enviados como [anexos…, texto] (perde a intercalação).
  - **Decisão de produto** (análoga à FC-416 do Android): ver ENV-21 no doc 05.

### ENV-22 🆕 Criar votação (enquete) — só em grupo

- **Entrada:** "+" → "Votação" (`EnqueteModal.vue`).
- **Textos da tela:** título "Nova votação"; campo "Pergunta" (placeholder "Ex.: Onde vamos almoçar?", máx. 300); "Opções" com 2 campos iniciais ("Opção 1", "Opção 2", máx. 200 cada), "+ Adicionar opção" até **12** e "×" para remover (só com mais de 2); checkbox "Permitir várias escolhas" / "Cada pessoa pode marcar mais de uma opção."
- **Botões:** "Cancelar" / "Criar votação" ("Criando..."). Fica habilitado com pergunta preenchida e ≥ 2 opções preenchidas.
- **API:** `PUT /enquete {conversa_id, pergunta, opcoes (só as preenchidas, trim), multipla}`.
- 🆕 `785bdef` **Data final (opcional):** checkbox "Definir data final" / "Depois dela ninguém vota mais. Dá para mudar ou encerrar antes pela votação." → campo de data e hora (sugestão: amanhã, na próxima hora cheia). Erros: "Informe a data e a hora", "A data final precisa estar no futuro", "A data final não pode passar de 1 ano"; com erro, "Criar votação" fica desabilitado. Vai como `encerra_em` (ISO).
  - Depois de criar, o web recarrega as mensagens e as conversas.
  - Erros do servidor aparecem na caixa vermelha: só grupo, opções repetidas etc.

### MSG-20 🆕 Bolha de votação (`BolhaEnquete.vue`, store `enquetes.ts`)

- **Classificação:** conteúdo único tipo 8 → `Enquete` (antes de Figurinha; vale **mesmo com referência**).
- **Carregamento:**
  - ao montar: `GET /enquete?id=<conteudo>`, com cache por id e leituras simultâneas deduplicadas;
  - enquanto carrega: "Carregando votação..."; em erro, a mensagem do erro.
- **Layout:**
  - nome do remetente (em grupo, se não é minha);
  - "📊 <pergunta>";
  - subtítulo "Escolha uma opção" / "Escolha uma ou mais opções".
- **Cada opção:**
  - marcador **círculo** (única) ou **quadrado** (múltipla) com ✓ quando marcada;
  - texto; contagem;
  - barra com `round(votos / total_votantes × 100)%` (na múltipla as barras podem somar mais de 100%, "como no WhatsApp");
  - nomes de quem votou abaixo (e no tooltip; "Ninguém votou ainda").
- **Rodapé:** "1 pessoa votou" / "N pessoas votaram" + hora/status da mensagem.
- **Votar:**
  - **única:** tocar em outra opção troca o voto; tocar na marcada tira o voto;
  - **múltipla:** marca e desmarca.
  - Envia sempre a lista completa: `POST /enquete/votar {enquete_id, opcoes}` → substitui a enquete no cache.
  - Os botões ficam desabilitados enquanto vota; em erro, mostra "Não foi possível votar".
- **Tempo real:** WS 62 `{enquete_id}` → relê `GET /enquete` **só se a enquete está no cache**, ou seja, na tela.
- 🆕 `785bdef` **Data final e encerramento:**
  - aberta com data: o subtítulo ganha "· encerra hoje 18:00" / "amanhã 08:30" / "12/10 18:00" (com o ano, se for outro);
  - quem criou vê "Definir data final" / "Alterar data final": um editor na bolha com "Data final", "Tirar data" (se tem), "Cancelar" e "Salvar" (`PATCH /enquete`; erro "Não foi possível mudar a data final");
  - quem criou a votação ou o grupo vê "Encerrar votação": confirmação de perigo "Encerrar votação" / "Depois de encerrada, ninguém vota mais e o resultado fica como está." / "Encerrar" (`POST /enquete/encerrar`; erro "Não foi possível encerrar a votação");
  - encerrada (pelo servidor, ou o prazo passou com a bolha aberta, na hora exata): "🔒 Votação encerrada <quando>", opções desabilitadas, a mais votada (ou as empatadas, com votos) em negrito com 🏆; os botões somem;
  - o resumo (`EnqueteResumo`) mostra "Votação encerrada".
- **Resumos:** "Votação" em prévias, notificações, atividades (`AtividadesPage`), citações (`messageReferences.ts`) e chat da chamada ("[Votação]").
- **Encaminhar:** o servidor recusa tipo 8 em `PUT /mensagem` (400). O web não esconde "Encaminhar" para enquete, então encaminhar dá erro. **No FMX: esconder "Encaminhar" para votação** (§6.3, regra 15).

### CHA-24 🆕 Chat completo na chamada

- **Onde:** só na janela principal, não na popup da chamada.
- **Quando:** com o grupo da chamada já criado, o painel "Chat da chamada" usa o **mesmo `MessageList` e `MessageInput` do chat**: anexos, respostas, reações, figurinhas, encaminhar, visualizador de imagens. O painel fica mais largo (`sm:w-96 lg:w-[28rem]`).
- **Conversa ativa:** enquanto o painel está aberto, a conversa do grupo da chamada vira a **conversa ativa**; ao fechar, volta a conversa anterior.
- **Antes da primeira mensagem** (o grupo ainda não existe), continua o painel simples, só de texto (CHA-18). A primeira mensagem cria o grupo (`PUT /chamada/chat`) e abre o modo completo.
- **Para o cliente Windows (FMX):** o "Chat da chamada" pode ser um **painel lateral** do form da chamada que reaproveita a própria tela de chat (o mesmo frame de lista + campo da conversa), com a conversa do grupo da chamada. Enquanto aberto, ela é a conversa ativa (regras de leitura e notificação, §7.8 e §7.11); ao fechar, volta a anterior. Na janela flutuante o painel e o botão do chat somem (§7.6).

### Outros ajustes do commit
- **Bolhas com vários conteúdos:** saiu o divisor entre conteúdos, e as imagens dentro da bolha padrão ou de referência ficam **sem moldura** (`imagemSemMoldura`).
- **Modais:** o encaminhamento passou a ficar por cima da janela da chamada (`z-50`).
- **Testes:** `tests/unit/enquetes.test.ts`, `blocosEditor.test.ts`, `entradaEAvatar.test.ts` (reescrito), `CallWindow.test.ts`.

## 11. Atualização de 2026-10-08 — commits `eaa8bac` e `785bdef`

Os dois commits são de 2026-10-07 (noite) e acompanham os do servidor `d4435db` (limite de reações) e `5cad911` (votação com data final), descritos no doc 01 §10.12, §10.13 e §20. Não há IDs novos: são mudanças em funcionalidades que já existiam (o total segue 136).

### `eaa8bac` — "Painel do grupo, limite de reações, votação oculta e chave na chamada"
- **CON-08 / ANX-13 — painel "Dados do grupo"** (`PainelGrupo.vue`, substitui o `GroupMembersModal.vue`):
  - abre à direita do chat (por cima, em tela pequena) pelo **avatar do grupo** no cabeçalho ("Dados do grupo") ou pelo botão "Participantes e anexos";
  - em cima: "Nome do grupo" + "Renomear" ("Salvando..."); "N participantes"; "Adicionar pessoas" abre uma busca ("Buscar contato...") entre os contatos fora do grupo ("Adicionando...", "Nenhum contato encontrado", "Todos os contatos já estão no grupo");
  - cada participante com foto, bolinha de online, "(você)" e "Remover" ("Removendo..."; o servidor só aceita remover o próprio vínculo, pendência S15);
  - embaixo: "Anexos" com a mesma lista e filtros da página de Anexos (ANX-13), abrindo a galeria ou a mensagem.
- **ENV-17 — limite de reações:** 5 emojis diferentes por pessoa (conferido antes da reação otimista); erro em diálogo "Não foi possível reagir"; 5 chips à mostra e o resto num "+N".
- **MSG-16 — votação oculta:** revelar mostra o resumo só de leitura (pergunta + contagem por opção).
- **ANX-07 — HTML:** links `#...` rolam dentro do documento.
- **CHA-11 — chave nos liga/desliga** da chamada (pílula com ícone + chave).
- **CHA-18 / CHA-24 — chat da chamada:** o grupo é criado no primeiro clique no campo, que já abre o chat completo.

### `785bdef` — "Votação com data final e opção de encerrar"
- **ENV-22:** data final opcional ao criar.
- **MSG-20:** "encerra …" no subtítulo; "Definir/Alterar data final" (quem criou); "Encerrar votação" (quem criou a votação ou o grupo), com confirmação; encerrada mostra "🔒 Votação encerrada …", destaca a mais votada com 🏆 e não aceita votos; o prazo que vence com a bolha aberta encerra na hora.

### Para o cliente Windows (FMX)
- **Reações (ENV-17):** limite de 5 emojis diferentes por pessoa, conferido antes da reação otimista (diálogo "Não foi possível reagir" / "Você já reagiu com 5 emojis nesta mensagem."); 5 chips à mostra e o resto num "+N" que, no *hover*, lista emoji, contagem e nomes, e alterna ao clicar (§7.4).
- **Votação (ENV-22, MSG-20):** data final na criação, editar/tirar a data, encerrar, estado encerrado e prazo vencendo com a bolha na tela (`TTimer` na hora exata); resumo da votação oculta (MSG-16).
- **Grupo (CON-08, ANX-13):** painel "Dados do grupo" à direita do chat, aberto pelo avatar do cabeçalho ou por "Participantes e anexos", com os anexos do grupo reaproveitando a lista da página de Anexos.
- **Chat da chamada (CHA-18, CHA-24):** criar o grupo no primeiro clique no campo (`PUT /chamada/chat`), não na primeira mensagem, e já abrir o chat completo no painel lateral (§10).
- **Chave nos controles da chamada (CHA-11):** pílulas com estado (ícone + chave, verde ligada, cinza desligada), como no web; a cor do botão não muda com o estado. Ver o estado no próprio controle importa mais no desktop, onde a chamada pode ficar numa janela flutuante pequena (§7.6).
- **HTML (ANX-07):** **se aplica**. Abrir no navegador padrão a partir de um arquivo temporário (os links `#...` já rolam dentro do documento) ou num WebView2 isolado, sem ponte JS e sem o token; nesse caso, garantir que `#...` role dentro do documento, como o web passou a fazer (§7.12).

## 12. Atualização de 2026-10-08 (noite) — commits `7322e83` e `e8d82cb`

Dois commits do web de 2026-10-08 (noite). No servidor só entrou `779c8ed` (o `iniciar-desenvolvimento.bat` também atualiza as dependências da API), sem mudança de contrato. Há **um ID novo**, ENV-23, e o total passa a **137**.

### `7322e83` — "Campo de mensagem: seleção, desfazer e rascunho; reações rápidas e agendadas"
- **MSG-17 / ENV-13 / ENV-14 — agendadas fora do chat:**
  - a mensagem agendada **não aparece no chat** antes da hora (`chat.ts#agendadasAtivas`, `MessageList.vue`);
  - com o campo **vazio**, um **relógio** ao lado do microfone mostra quantas há, com o título "1 mensagem agendada" ou "N mensagens agendadas"; com algo no campo, o relógio some;
  - o relógio abre "Mensagens agendadas" (`MensagensAgendadasModal.vue`), só da conversa aberta e em ordem de horário. Cada linha tem:
    - o horário (`formatarPrazo`: "hoje 18:00", "amanhã 08:30", "12/10 18:00", com o ano se for outro);
    - o resumo do conteúdo, até 3 linhas;
    - "Cancelar" ("Cancelando..."), com a confirmação "Cancelar mensagem agendada" / "Ela não será enviada." / "Cancelar envio" / "Voltar"; em erro, "Não foi possível cancelar";
  - a lista fecha sozinha quando fica vazia;
  - na hora marcada, a mensagem sai da lista e entra no chat, sem esperar a próxima leitura (`useAgora` na próxima agendada).
- **MSG-19 — encaminhada de encaminhada:** dentro da citação, os conteúdos que a encaminhada copiou da citação de baixo (já à mostra) não se repetem (`semCopiasDaReferencia`: tira uma cópia por igual `tipo:conteudo`, na mesma quantidade; resposta não copia nada).
- **ENV-23 🆕 — rascunho por conversa** (`services/rascunhos.ts`, IndexedDB):
  - um rascunho por usuário e conversa, com o campo (texto, menções, peças), os arquivos e o "respondendo a..." ou encaminhando;
  - gravado com um pequeno atraso a cada mudança; vazio apaga;
  - restaurado ao voltar à conversa, mesmo depois de fechar o navegador;
  - apagado ao enviar.
- **ENV-20 — menu:**
  - Ctrl + clique direito abre só a barra de reações rápidas, junto do clique;
  - toque longo no celular (500 ms, tolerância de 10 px) abre o menu completo e engole o clique ao soltar.
- Campo rico (ENV-21): a peça selecionada fica azul; Ctrl+Z/Ctrl+Y próprios. Copiar GIF leva a imagem inteira.

### `e8d82cb` — "Campo de mensagem no Tiptap; 'mais emojis' na barra de reações rápidas"
- **ENV-21:** o campo passa a ser um editor Tiptap (ProseMirror) no lugar do `contenteditable` feito à mão. Anexos e figurinhas são peças do editor; a peça pode ser arrastada para mudar a ordem, e copiar e colar uma peça a duplica. O rascunho guarda o documento do editor.
- **ENV-20:** a barra de reações rápidas ganha o botão da lista completa de emojis.

### Para o cliente Windows (FMX)
- **Agendadas (MSG-17, ENV-13, ENV-14):** seguir o modelo novo do web:
  - a agendada fica fora da lista do chat até a hora;
  - relógio com o número ao lado do microfone, com o campo vazio;
  - form ou painel "Mensagens agendadas" com horário, resumo e "Cancelar", e um `TTimer` para a próxima `visivel_em` (§3.4).
- **Citação (MSG-19):** aplicar `semCopiasDaReferencia` nos níveis aninhados.
- **Rascunho (ENV-23):** guardar no computador, por usuário e conversa, o campo (texto, menções, peças), os arquivos copiados e a resposta ou encaminhamento pendente; restaurar ao abrir a conversa; apagar ao enviar e no logout (o web não apaga no logout — §1.5).
- **Menu (ENV-20):** **Ctrl + clique direito se aplica** no desktop: abre só a barra de reações rápidas (7 emojis + "Mais emojis") centrada no ponto do clique; o clique direito sem Ctrl abre o menu completo, também com "Mais emojis". O toque longo só vale em tela de toque (§7.4, §7.13).
- **Tiptap (ENV-21):** detalhe interno do web (ProseMirror). Para o FMX vale o comportamento: peça arrastável para mudar a ordem, copiar e colar uma peça a duplica, Ctrl+Z/Ctrl+Y com peças, rascunho com o conteúdo do campo. A decisão de produto do ENV-21 (editor por blocos ou fila + texto, §10) continua valendo.

---

## 13. 🔎 Revalidação de 2026-10-08 contra `e8d82cb` (cópia para o FMX)

Conferência feita para esta cópia (relatório completo: `apoio/A7-validacao-servidor-web.md` §2 e §3). As correções foram aplicadas no corpo, marcadas com 🔎.

### 13.1 Contagem e método

- **137 IDs conferem**, sem lacuna nem duplicata: AUT 10, CON 13, MSG 20, ENV 23, ANX 15, PES 2, CHA 24, SIP 5, NOT 6, PRE 1, ATV 3, CFG 8, GER 7.
- **82 linhas (83 IDs) de todos os 13 grupos** foram conferidas com o código do web, junto com as seções gerais (§1, §2), os endpoints (§4.1) e os eventos (§4.2). A maioria bate, inclusive os textos sem acento e os tempos (30 s, 25 s, 15 s, 4 s, 3 s, 2,5 s, 80/60/30/120, `limite=60`).
- Os itens de desktop (ENV-09/11/12/20, CON-05/10, CHA-13, SIP-03, NOT-01/02, MSG-09/12/18, ANX-02/04, CFG-03 a 06, GER-04/05) foram conferidos linha a linha junto com a nova §7.

### 13.2 Correções aplicadas no corpo

| Onde | Correção |
|---|---|
| Cabeçalho, §8 | Cita `7322e83` e `e8d82cb` |
| §1.1, §1.2, §1.8 | Tiptap 3 no campo de mensagem; store `enquetes`; IndexedDB `conversa-rascunhos`; *chunk* `editor`; `MensagensAgendadasModal` assíncrono |
| §1.3 | `CAMPOS_DATA` com `encerra_em` e `encerrada_em`; corpo de erro em texto não-HTML volta como está |
| §1.5 | O logout **não apaga** os rascunhos do IndexedDB (achado W2, §13.3) |
| §1.6 | Os dois `PATCH /dispositivo` saem em sequência sem esperar um pelo outro |
| §1.7 | **O web não chama `POST /anexo/confirmar`** (o FMX deve chamar) |
| §2.4 | `PainelGrupo` (substitui o `GroupMembersModal`, apagado em `eaa8bac`), `MensagensAgendadasModal`, `EnqueteModal`, `EnqueteResumo`; `AnexoPopup` com "Votação"; botão de ações é uma seta para baixo, sem `title` |
| AUT-01 | O servidor não devolve `avatar_url` no login (só `avatar_identificador`) |
| AUT-10 | "Nao informado" vale para o e-mail e o telefone |
| CON-02 | "Nova conversa" só aparece com termo digitado |
| **CON-08** | Reescrito pelo `PainelGrupo` ("Dados do grupo": nome, participantes e anexos) |
| **CON-09** | Não existe mais "Gerenciar membros" nem a faixa de *chips*; os membros aparecem numa lista ao passar o mouse no título |
| CON-10 | O que o popup não tem e a **falta de canal** com a janela principal (som em dobro possível) |
| ENV-01 | O campo cresce até 40% da altura da janela (não 120 px); Enter/Shift+Enter em `editor/pecas.ts` |
| ENV-02 | No Tiptap, o atalho de emoji só converte ao digitar espaço ou no envio |
| **ENV-05** | Menção é um nó Mention do Tiptap (não há mais a camada de realce) |
| ENV-09 | Texto com cara de código já entra cercado; fechar "Inserir código" por clique fora cola o texto cru |
| ENV-10 | Esc não fecha a janela "Inserir código" |
| **ENV-11** | Qualquer arquivo colado entra como peça no cursor; `print-<ms>.<ext>`; GIF copiado vira `gif-<ms>.gif` |
| ENV-12 | Detalhes do "letra fora do campo foca o campo" (ignora Ctrl/Alt sem AltGr, Meta, IME, modal) |
| ENV-13 | A agendada vai para o relógio, não para o chat com selo |
| ENV-20 | Botão de ações em seta, sem `title`; fecha também ao rolar a lista |
| **ENV-21** | Arquivos `utils/editorRico.ts`/`blocosEditor.ts` apagados; hoje é Tiptap em `src/editor/` |
| ENV-23 e relógio de agendadas | Ganharam item próprio na §3.4 |
| CHA-12 | Colunas responsivas da grade |
| CHA-13 | Janela flutuante só em vídeo, 420×350, mínimo 320×240, máximo 90% |
| CHA-18/24 | O grupo do chat da chamada nasce no primeiro clique no campo; o modo simples é código morto |
| NOT-02 | Corpo também "Votação" |
| PRE-01 | Bolinha também no `PainelGrupo` |
| ATV-01 | Prévia "Votação"; gravação aparece como "Áudio" |
| CFG-03 | A aba "Dispositivos" **só lista**: o web não escolhe microfone, câmera nem saída |
| CFG-08 | O texto "Modo aberto" não existe; texto real do aviso de "Acessos" |
| GER-04 | A camada ainda diz "Imagens mostrarao uma previa antes de enviar", mas não há mais prévia |
| §4.1 | **+5 rotas de enquete**; o web usa 63 rotas da API; as 6 que não usa: `DELETE /usuario`, `PUT /usuario/contato`, `DELETE /usuario/contato`, `PUT /dispositivo/usuario`, `DELETE /conversa`, `POST /anexo/confirmar` |
| §4.2 | **+ evento 62** `EnqueteAtualizada` (relê `GET /enquete` só se a enquete está no cache) |
| §7 | **Reescrita para desktop** (atalhos, arrastar e soltar, colar, menus, janelas, notificações, abas de configurações, foco da janela) |
| §9 (Anexo B) | Selo "Agendada para …" e o modo simples do chat da chamada viraram código morto |
| §10–§12 | Orientações "Para o Android" trocadas por "Para o cliente Windows (FMX)" |

### 13.3 Achados no web e pontos não confirmados

**Achados no web** (registrados também no doc 08 §3 como W1–W4, para uma *issue* no `conversa-web`):
- **W1 — XSS armazenado na pesquisa global:** o destaque do termo usa `v-html` sobre o texto da mensagem **sem escapar o HTML** (`destacarTermo` só escapa o termo para a expressão regular) — `PesquisaAvancada.vue:50`, `:103-108`. No FMX, desenhar o destaque sem interpretar HTML.
- **W2 — Rascunhos sobrevivem ao logout:** o IndexedDB `conversa-rascunhos` não é limpo no `sair()`. No FMX, apagar os rascunhos no "Sair da conta".
- **W3 — O web não chama `POST /anexo/confirmar`** (funciona pela tarefa `VerificacaoAnexos` do servidor).
- **W4 — Textos sem acento** em várias telas ("Conexao em tempo real indisponivel", "Nao informado", "Configuracoes", "Gravacao de audio", "video"). O FMX usa a forma acentuada.

**Não confirmado** (lido no código, sem execução):
- som em dobro com o popup de conversa aberto e botões de chamada sem efeito no popup (CON-10);
- efeito real de `additionalProperties: false` declarado no OpenAPI vivo (campos extras removidos ou recusados) — o FMX não deve mandar campos extras;
- como um app Win32 lê o estado das permissões de microfone e câmera da Privacidade do Windows (§7.9).
