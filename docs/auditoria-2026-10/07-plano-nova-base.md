# 07 — Plano da nova base do cliente Windows (Delphi 12 / FireMonkey)

**Data:** 2026-10-08 · **Base:** docs 01–06 desta pasta e relatórios `apoio/A1`–`A7`.
**Objetivo:** um cliente Windows nativo, testável e distribuível, em paridade com o `conversa-web`, que tolere o servidor Bun/Elysia atual e reaja bem a mudanças futuras do contrato — sem perder o visual e as integrações de desktop que o FMX já tem.
**Status:** **proposta**. A decisão de recomeçar (ADR 0001) e a da pilha de mídia (ADR 0002) dependem do responsável pelo projeto.

---

## 1. Decisões estruturais

| # | Decisão | Escolha proposta | Motivo |
|---|---|---|---|
| D1 | Recomeçar ou evoluir | **Recomeçar o núcleo e o esqueleto; transplantar a interface *frame* a *frame*** | Doc 04 §8. Os defeitos críticos estão em tudo o que tem estado ou faz E/S; o visual é bom e aproveitável |
| D2 | Onde | **Mesmo repositório**, branch `nova-base` criada a partir da `chamada` depois da Etapa 0. O código atual vai para **`legado/`** (`git mv`, fora do build, referência para o transplante); a nova base nasce em `app/`, `core/`, `ui/`, `midia/`, `testes/`, `build/`. O app atual fica também na branch `legado/abril-2026` e na tag `legado-v1-final` | Histórico preservado; um só lugar para *issues* e docs (mesmo esquema do Android, que moveu `app/` para `app-legado/`) |
| D3 | Plataforma | **Só Win64**, Windows 10 (1809+) e 11 | As DLLs de mídia e o WebView2 são 64 bits; o WebSocket do WinHTTP exige Windows 8+; Windows 7/8 estão sem suporte |
| D4 | Interface | FMX, com os *frames* atuais transplantados e limpos; **tokens de cor** numa unit (`docs/design/cores.md` §7); textos em `resourcestring` alinhados ao web (doc 03 §6); componentes focáveis por teclado | Fim das cores e textos espalhados (#72, #90); acessibilidade (#71) |
| D5 | Arquitetura | Camadas `dominio` / `contrato` / `infra` / `aplicacao` / `ui`; *ViewModels*/*Presenters* sem E/S; **barramento tipado** que entrega na thread principal (a ideia do `TEventBase` atual, com multi-assinante, cancelamento e isolamento de exceção) | Testabilidade (#69); nada de objeto global |
| D6 | Injeção | Interfaces + **composição manual** no *bootstrap* (registro de serviços), sem biblioteca de terceiros | Simples, sem dependência nova; *fakes* nos testes |
| D7 | Serialização | DTOs explícitos (`System.JSON` + conversores próprios para datas ISO-8601 com `Z`, ids número/texto, campos ausentes), mapeadores DTO → domínio, **testes com *fixtures* JSON reais** | Contrato como fonte da verdade (doc 01); nunca deduzir do código legado |
| D8 | HTTP | `THTTPClient` (`System.Net.HttpClient`, WinHTTP/SChannel): TLS, *proxy* e certificados do Windows; UTF-8 explícito; *query* codificada por parâmetro; *timeouts*; repetição só em requisições idempotentes; 401 → evento "sessão expirada"; HTML do nginx → "Servidor indisponível" | Corrige #39; mantém o que já estava certo (validação de TLS) |
| D9 | Tempo real | **WebSocket do WinHTTP** (`WinHttpWebSocketCompleteUpgrade/Send/Receive/Close`) numa thread própria; máquina de estados com **geração** por conexão, *backoff* `min(30 s, 1 s × 2^n)` com *jitter*, *keepalive* do WinHTTP (30 s, no *handle* do WebSocket; o servidor não tem *ping* de aplicação — protótipo 0.7), ressincronização ao conectar, *polling* de 8 s com o socket fora | Corrige #2, #3, #5, #29 de uma vez; sem OpenSSL nem DLL extra. Alternativas: ICS (OpenSSL 3, gratuito) ou sgcWebSockets (comercial) |
| D10 | Persistência | **SQLite via FireDAC** (cache de conversas, mensagens, usuários, cursores, fila de envio, rascunhos) em `%LOCALAPPDATA%\Conversa`; configuração mínima em `%APPDATA%\Conversa` (JSON gravado de forma atômica) | Abre com o histórico, envio otimista, cursor de sincronização; dados no lugar certo (#68, #92). Confirmar que a edição do Delphi em uso inclui o driver SQLite do FireDAC |
| D11 | Sessão | **Só o token**, protegido com DPAPI (`CryptProtectData`, escopo do usuário); **nunca a senha** por padrão. Opção "Manter conectado" com a credencial em DPAPI **só se o responsável aprovar** (ADR 0001), enquanto o servidor não tiver *refresh token* (S13) | Corrige #6; o JWT de 12 h vence todo dia num app de bandeja (#4) |
| D12 | Notificações | Mensagens: **toast nativo do Windows** (com o *AppUserModelID* e atalho no Menu Iniciar), uma por conversa, com "Responder" e "Marcar como lida" se a API permitir; chamada recebida: **janela própria no topo** (botões grandes, toque em loop), como a atual. Contador na barra de tarefas e na bandeja | Respeita "não perturbe" e a Central de Notificações (#76); chamada precisa de destaque. Decisão final depois do protótipo da etapa 5 |
| D13 | Desktop × celular | Até o servidor ter S2/S18: **fechar o WebSocket ao bloquear a sessão, ao suspender e depois de N minutos ocioso**, mantendo *polling* REST nesse período; reabrir e ressincronizar ao voltar | Sem isso, o desktop sempre conectado deixa o celular sem push (#15) |
| D14 | Chamadas (mídia) | Interface `IMidiaChamada`; **protótipo antes de decidir** (etapa 0.5): A — WebView2 com o módulo de chamada do web (preferência); B — libwebrtc nativa (`webrtc-sdk`) com *shim* C; C — Pion + FFmpeg corrigido (plano de reserva) | §6. A pilha atual não tem cancelamento de eco, tem áudio quebrado e usa FFmpeg GPLv3 (#13, #14, #36–#38) |
| D15 | Gerenciador de chamadas | Escopo de aplicação, **dono único** das chamadas e da mídia, máquina de estados explícita, toda transição com teste | Corrige #7, #8, #30–#32, #61, #62 |
| D16 | Build e distribuição | **Licença com compilação por linha de comando** (Professional ou superior) — ou fluxo de build pelo IDE combinado com o responsável; `build/` com *scripts* que conferem o exe e o log (não confiam no código de saída do MSBuild); dependências obtidas com versão fixa e *hash*; instalador por usuário (Inno Setup ou MSIX), assinado; versão automática | #16; hoje nada disso existe |
| D17 | Qualidade | DUnitX (+ TestInsight no IDE); testes obrigatórios para parsers, mapeadores, máquina de estados da chamada, `SyncManager`, fila de envio, validação de identificador e sessão; FastMM em modo *full debug* nos testes; *logger* com fila, rotação e redação | 0 testes hoje |

---

## 2. Estrutura

```
conversa-windows-fmx/
├── app/                 Conversa.dpr (Win64) · Conversa.dproj · bootstrap e composição · TTelaPrincipal
├── core/
│   ├── dominio/         Conversa.Dominio.*  — records/classes imutáveis (Conversa, Mensagem, Conteudo, Usuario,
│   │                    Chamada, Atividade, Enquete…), enums do contrato, regras puras (classificação de bolhas,
│   │                    menções, blocos de código, ordenação). Sem FMX, sem rede.
│   ├── contrato/        DTOs + mapeadores DTO→domínio + conversores (datas, ids tolerantes); fixtures nos testes
│   ├── infra/
│   │   ├── http/        IConversaApi + TConversaApi (THTTPClient), EApiErro tipado
│   │   ├── tempo-real/  ITempoReal + TTempoRealWinHttp (thread própria, estados, geração, backoff, keepalive)
│   │   │                + TParserEventos (0–62 → eventos tipados)
│   │   ├── banco/       SQLite (FireDAC): conversas, mensagens, usuários, cursores, fila de envio, rascunhos;
│   │   │                migrações versionadas
│   │   ├── sessao/      TSessaoDPAPI (token; credencial só se aprovada)
│   │   ├── anexos/      TGerenciadorAnexos: upload em streaming p/ URL assinada + confirmar; download p/
│   │   │                temporário + validação + renomear; cache por identificador VALIDADO com cota/LRU;
│   │   │                Mark-of-the-Web ao salvar
│   │   ├── windows/     bandeja, barra de tarefas (contador), toast, instância única (mutex), inicialização com
│   │   │                o Windows, energia/sessão (suspender, bloquear), inatividade, DPI
│   │   └── log/         TLogger (fila + thread, rotação, redação de token/senha/conteúdo)
│   ├── aplicacao/       TSessaoServico, TConversasServico, TMensagensServico (envio otimista + fila), TSyncManager
│   │                    (ressincroniza ao conectar), TPresenca, TAtividades, TEnquetes, TGerenciadorChamadas
│   └── eventos/         TBarramento (multi-assinante, tipado, entrega na thread principal, cancelamento por
│                        IInterface, isolamento de exceção, "último valor")
├── midia/               IMidiaChamada → a implementação escolhida no ADR 0002
├── ui/                  frames transplantados + ViewModels/Presenters; Conversa.Cores (tokens); Conversa.Textos
│                        (resourcestring); componentes (Avatar, Diálogo de confirmação, Faixa de aviso, Lista virtual)
├── testes/              projeto DUnitX: parsers, mapeadores, máquina de estados, SyncManager, fila de envio, sessão;
│                        fakes de IConversaApi e ITempoReal; fixtures JSON do contrato
├── build/               scripts de build (Win64 Debug/Release), obtenção de dependências com hash, instalador
├── legado/              o app atual (fora do build), só para consulta e transplante
└── docs/
```

> Dá para começar com menos pastas e dividir depois; o que importa é a **separação de responsabilidades** (nenhuma E/S na UI, nenhum global).

---

## 3. Componentes centrais

### 3.1 Endereço do servidor

- Um campo só: **"Endereço do servidor"** (ex.: `https://conversa.empresa.com`, sem `/api` e sem `:443`). Dele derivam:
  - API: `<base>/api/`;
  - WebSocket: `wss://<host>[:porta]/ws/` (barra final obrigatória; `/ws` recebe 301, que o cliente não segue);
  - mídia: `<base>/webrtc/`.
- "Testar conexão": uma rota protegida sem token deve responder **401 com `{error}`** (prova que é um servidor Conversa); HTML = não é a API; erro de TLS = certificado não confiável (instruções do mkcert para desenvolvimento).
- Trocar de servidor = sair da conta. Primeira execução: assistente. Depois: aba "Servidor" nas Configurações (WIN-01).

### 3.2 Tempo real (`ITempoReal`)

```
estado: Desconectado → Conectando → Autenticando → Conectado → (queda) → Aguardando(backoff) → Conectando …
- conecta com sessão válida (e, até S2/S18, só com o usuário ativo: D13)
- ao abrir: {"tipo":1,"token":…} (número JSON); erro chega como tipo 0 → "sessão expirada"
- cada conexão tem uma geração; eventos de gerações antigas são descartados
- keepalive do WinHTTP a cada 30 s (WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL no handle do WebSocket); conexão
  morta = erro no Receive (na hora, se a outra ponta fecha; pelo TCP, se a rede some) — protótipo 0.7, 2026-10-09
- backoff min(30 s, 1 s × 2^n) + jitter; reconecta já ao voltar de suspensão/bloqueio/rede
- ao entrar em Conectado: SyncManager.Ressincronizar()
- com o socket fora por mais de 5 s: faixa "Conexão em tempo real indisponível — usando atualização periódica"
  e polling de 8 s (mensagens novas + chamadas pendentes)
- eventos → TParserEventos → TBarramento (thread principal)
```

### 3.3 Sincronização (`TSyncManager`)

Na (re)conexão e ao voltar do segundo plano, em paralelo e de forma idempotente:
1. `GET /mensagens/novas?desde=<cursor>` → para cada `{conversa_id, mensagem_id}`, buscar o que falta com referência = última mensagem **salva** → SQLite → avançar o cursor (`ate`, nunca para o futuro).
2. `GET /conversas` → SQLite (sempre adotando `mensagens_sem_visualizar` do servidor).
3. `GET /contatos/online` → presença.
4. `GET /atividades/novas` → contador.
5. `GET /chamadas/pendentes` → `TGerenciadorChamadas.AvaliarPendentes`.

O WS 2 (sem `conversa_id`, possivelmente duplicado) é só um **gatilho** de sincronização incremental, com *debounce* e uma busca por vez por conversa.

### 3.4 Envio (`TMensagensServico`)

- Mensagem otimista (id negativo, relógio) gravada no SQLite antes de qualquer rede; o texto nunca se perde.
- Fila persistente processada por uma thread: anexos primeiro (§3.5), depois `PUT /mensagem` com os conteúdos na ordem; troca do id negativo pelo real.
- Erro definitivo (4xx, ou N erros de servidor) → "falhou" com "Reenviar"/"Apagar"; sem rede, espera.

### 3.5 Anexos (`TGerenciadorAnexos`)

- **Upload:** SHA-256 em *streaming* → `PUT /anexo` (JSON) → se não existe, `PUT` em *streaming* na URL assinada (sem `Authorization`, em até 300 s, pedindo outra se vencer) → `POST /anexo/confirmar?identificador=`. Tipos 2/3/4/5 pelo conteúdo (gravação = 5).
- **Download:** `GET /anexo` → URL assinada (cache de URL até 1 min antes dos 600 s) → baixar para temporário → validar → renomear para `cache\<identificador validado>`; URL vencida → pedir outra uma vez.
- **Salvar:** copiar (nunca mover) para a pasta escolhida (padrão `Downloads\Conversa`), com Mark-of-the-Web e aviso para extensões perigosas.

### 3.6 Gerenciador de chamadas (`TGerenciadorChamadas`)

```
            ┌────────── Iniciar() ──────────┐
 Ocioso ────┤                               ▼
            │  WS51/pendente ──► Recebendo ──Atender()──► Conectando ──mídia ok──► EmAndamento
            │                     │  │ 30 s / ocupado → recusar(nao_atendeu)            │
            │                     │  └ 53/54 com meu id (outro aparelho) → Ocioso       │
            │                     └ Recusar() ─────────────────────────────► Encerrando ─► Ocioso
            └─► Chamando ──54 de outro──► EmAndamento ── 52 | Sair() | ninguém "Entrou" após 55 | 53 em 1:1 ─► Encerrando
                  └ Cancelar() / 45 s sem atender ───────────────────────────► Encerrando
```

- Fonte única dos eventos 51–57 e das pendentes; despacho numa vez única (como o JavaScript do web), conferindo a "geração" na volta de cada chamada de rede.
- Regras do web e do contrato: ocupado → `recusar {nao_atendeu:true}` sem tocar; 51 da própria chamada ou duplicado → ignorar; 51 da chamada atual (participante adicionado) → só sincronizar; pendente > 25 s → perdida; 55 → `GET /chamada/dados` → sair se ninguém mais "Entrou" (o servidor não manda 52); sincronização a cada 4 s; WS 56 → modal "Apenas assistir / Transmitir também" (15 s).
- `Encerrar()` idempotente: mídia → toque → notificações → janela → estado.
- **Toda transição com teste DUnitX** (inclusive eventos fora de ordem e duplicados).

### 3.7 Integração com o Windows

Bandeja com menu ("Abrir Conversa", "Não perturbe", "Sair do Conversa"); X fecha para a bandeja; "Sair da conta" separado; contador na barra de tarefas (sem vazar GDI) e na bandeja; `FlashWindowEx` em mensagem e em chamada; instância única por *mutex* com repasse de argumentos (protocolo `conversa://`); iniciar com o Windows (minimizado); `WM_POWERBROADCAST` e `WTSRegisterSessionNotification` (suspender, bloquear); DPI PerMonitorV2; vários monitores; janela de conversa separada no mesmo processo (CON-10); atalhos de teclado (doc 03 §7).

---

## 4. Janelas e navegação

```
Primeira execução ─► Servidor (assistente) ─► Login ─► Cadastro
                                     └───────► Tela principal (barra lateral):
                                                ├── Conversas ──► Chat(conversa, mensagem?) ──► Dados do grupo / Perfil do outro / Anexos
                                                │                    └──► Visualizador (imagens/vídeo/PDF)
                                                ├── Chamadas (histórico) ──► Chat
                                                ├── Atividades (contador) ──► Chat(mensagem)
                                                └── Configurações ──► Usuário / Servidor / Notificações e sons / Inicialização /
                                                                      Dispositivos / Privacidade do Windows / Chamadas /
                                                                      Sistema* / Acessos* / Voip / Sobre
Janelas próprias: chamada (flutuante, StayOnTop, arrastável), chamada recebida (no topo), conversa separada (CON-10),
visualizador (opcional em janela), discador SIP (etapa 9). Bandeja e toasts.
Entrada externa: argumentos / protocolo conversa://conversa/<id>?mensagem=<id> → instância já aberta.
```

---

## 5. O que transplantar do app atual

Tabela completa no doc 04 §8.3. Em resumo:

| Peça | Destino | Ajustes obrigatórios |
|---|---|---|
| *Frames* de lista, chat, editor, contatos, grupo, chamada, histórico, sobre, login | `ui/` | Tirar `Dados`/`TAPIConversa`; *ViewModel*; tokens de cor; textos centralizados; sem nomes por *timestamp* |
| Renderizador de mensagens (`chat.visualizador`, `chat.mensagem*`, `chat.conteudo.*`, separadores) | `ui/chat` | Lista virtual (#58); modelos imutáveis; formato pela `extensao` |
| Editor (`chat.editor*`) | `ui/chat` | Fila de envio; colar em `%TEMP%`; gravação em formato real |
| Notificações (`Conversa.Notificacao*`) | `ui/notificacoes` | Só para a chamada recebida (D12); fechar depois do *handler* |
| Barra de título (`Conversa.FormularioBase`) | `ui/base` | `SetWindowLongPtr`; cores do tema |
| Bandeja, instância única, posição da janela, contador, inatividade (`lib/windows/*`, partes da tela inicial) | `core/infra/windows` | Menu, *mutex*, `DeleteObject`, limiar de minutos |
| Menu (`lib/popupmenu`) | `ui/componentes` | Teclado; sem `Sleep` |
| Visualizador de imagem | `ui/visualizador` | Galeria; sem `FreeAndNil(Self)` |
| Tabela de emoji | `core/dominio` | — |
| Conversor de datas (`Conversa.Serializer`) | `core/contrato` | `null`; testes |
| Barramento (`Conversa.Evento.Base`, a ideia) | `core/eventos` | Multi-assinante, cancelamento, isolamento |
| Bancada WHIP/WHEP (`conversa-webrtc/*.view`) | `ferramentas/` | Fora do app |

**Não transplantar:** `Conversa.Dados`, `Conversa.Memoria`, `Conversa.Tipos`, `Conversa.Proxy*`, `REST.API`, `lib/bird-socket-client`, `lib/AES` + DCPcrypt, `Conversa.WMI`, `Conversa.Login` (lógica), `Conversa.Configuracoes`, `Conversa.Chamada` e a orquestração de `Conversa.Chamada.WebRTC`, `Conversa.Log`, `src/pss`, Skia vendorizado, `lib/tcp.pas`, `lib/audio`, todo o código morto (doc 04 #80), `teste/`.

---

## 6. Pilha de mídia das chamadas (ADR 0002 — decidir depois do protótipo)

| Opção | Como | Prós | Contras | Esforço (ordem de grandeza) |
|---|---|---|---|---|
| **A — WebView2 com o módulo de chamada do web** (preferência) | Janela de chamada FMX com um `TWebBrowser` em modo Edge (ou WebView4Delphi) carregando uma página do próprio servidor ("chamada embutida") que reaproveita `conversa-web/src/stores/call.ts`; ponte JS ↔ Delphi para sinalização, estado e token | **Paridade imediata e mantida pelo próprio web:** TURN, H264/VP9 gravável, **cancelamento de eco, supressão de ruído e ganho automático**, `getDisplayMedia` com seletor e indicador do sistema, ponteiro, chat, qualidade. H.264 licenciado no Edge. Runtime atualizado pela Microsoft. Nenhuma DLL de mídia nossa | Interface da chamada em HTML; depende do WebView2 Runtime (presente no Windows 10/11 atualizados; há instalador); ~150–300 MB por instância; **exige no web uma rota de chamada embutida** e passagem do token; conceder microfone/câmera à própria origem (`PermissionRequested` — confirmar no FMX do Delphi 12) | **2–4 semanas** |
| B — libwebrtc nativa | `webrtc-sdk/libwebrtc` (o mesmo usado pelo flutter-webrtc no Windows) + *shim* C para Delphi | Motor do Chrome (AEC3, NetEQ, GCC), interface 100% FMX, sem GPL | API C++ (precisa de *shim*); renderizar I420 no FMX; atualizar a libwebrtc periodicamente | **8–14 semanas** |
| C — Pion + FFmpeg (o atual, corrigido) | Corrigir ICE/TURN, áudio nos dois sentidos, *offsets*, threads; acrescentar AEC/NS/AGC (WebRTC APM ou DSP do Windows), *jitter buffer*, controle de banda; FFmpeg LGPL | Já existe um esqueleto; controle total | Na prática, **escrever um motor de VoIP**; dois *runtimes* (Go + Delphi); licenças; qualidade de áudio arriscada | **16–30+ semanas** |

**Protótipo (etapa 0.5 do `TODO.md`), antes de investir:** opção A com áudio nos dois sentidos via TURN entre o FMX e o web, em redes diferentes, com alto-falante (sem eco), e a gravação conferida no MediaMTX. Se A falhar (permissões, runtime, ponte), protótipo da B. A interface `IMidiaChamada` isola a escolha do resto do app.

**Em qualquer opção, o que fica em Delphi:** o gerenciador de chamadas (§3.6), toque, chamada recebida no topo, bandeja, barra de tarefas, atalhos, "ocupado", pendentes e histórico.

---

## 7. Fases

| Fase | Entrega demonstrável | Itens (doc 06) |
|---|---|---|
| **F0 Fundação** | Projeto Win64 vazio com tema, *logger*, configuração, sessão DPAPI, cliente HTTP tipado, WebSocket WinHTTP conectando **com reconexão**, SQLite, barramento, testes DUnitX rodando | FC-100…FC-115 |
| **F1 Sessão e conversas** | Servidor e login; lista de conversas viva (fixar, arquivar, presença, digitando); contatos; grupos; bandeja e "Sair" | FC-200…FC-215 |
| **F2 Mensagens núcleo** | Chat com lista virtual, paginação correta, envio otimista, status, oculta, bolha de chamada, "Últimas", *links*, digitando | FC-300…FC-316 |
| **F3 Anexos** | Enviar e receber imagens, áudios (gravação tipo 5), vídeos e arquivos; visualizador; PDF; transcrição; arrastar e soltar; colar | FC-400…FC-416 |
| **F4 Ações** | Menu (clique direito, Ctrl + clique direito, botão de ações), reações, responder, encaminhar, ocultar, menções, figurinhas, código/Markdown, agendar, votação, rascunho | FC-500…FC-520 |
| **F5 Notificações e Windows** | Toasts, sons, "não perturbe", contador, `FlashWindowEx`, iniciar com o Windows, instância única com *deep link*, desktop × celular (D13) | FC-600…FC-612 |
| **F6 Chamadas** | Gerenciador de chamadas + mídia do ADR 0002; recebida/efetuada, grupo, vídeo, tela por ação explícita, histórico | FC-700…FC-724 |
| **F7 Restante** | Atividades, pesquisa, perfil, configurações (inclusive Sistema e Acessos) | FC-800…FC-810 |
| **F8 Extras e distribuição** | Janela de conversa separada, SIP, cores, instalador assinado, atualização automática | FC-900…FC-908 |

**Corte para substituir o app atual:** fim da F6 com todos os P0.

---

## 8. Critérios de aceite globais

1. **Contrato:** todo DTO tem teste de desserialização com JSON real (*fixture* do doc 01 ou capturado do servidor de desenvolvimento).
2. **Segurança:** sem aceitar qualquer certificado; sem senha salva (salvo decisão explícita do ADR 0001, com DPAPI); sem token, senha ou conteúdo de mensagem em log; identificador de anexo validado; vídeo e tela nunca enviados sem ação explícita.
3. **Responsividade:** nenhuma E/S na thread principal (conferido com teste de servidor lento: a janela continua respondendo).
4. **Tempo real:** derrubar a API, suspender o PC e trocar de rede → reconecta sozinho e recupera o que perdeu, sem duplicar.
5. **Chamadas:** a matriz manual de testes de chamada passa, e a gravação aparece no servidor.
6. **Desktop:** bandeja com "Sair"; instância única; DPI e vários monitores; atalhos do doc 03 §7.
7. **Acessibilidade:** login → conversa → mensagem → atender chamada operável só pelo teclado e lido pelo Narrador (dentro do que o FMX permitir).
8. **Paridade:** doc 05 atualizado a cada fase, com evidência por item marcado ✅.

---

## 9. Riscos e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| Delphi Community sem compilação por linha de comando | Sem CI e sem trabalho autônomo de implementação nesta máquina | Licença Professional+ ou fluxo de build pelo IDE combinado (etapa 0.3); *scripts* prontos para quando houver licença |
| Servidor sem S2/S18 | Desktop conectado deixa o celular sem push | D13 (fechar o socket quando o usuário está longe) + pedir S2/S18 |
| Servidor sem *refresh token* (S13) | Login diário | D11; pedir S13 |
| Pilha de mídia | Maior risco técnico (eco, TURN, licença) | Protótipo cedo (etapa 0.5); `IMidiaChamada` |
| WebView2 indisponível em algum PC | Chamadas não funcionam | Instalador com o *bootstrapper* do WebView2; mensagem clara |
| Desempenho do FMX em listas longas | Chat lento | Lista virtual própria desde a F2 |
| Contrato em movimento (mudanças semanais) | Retrabalho | DTOs isolados + testes com *fixtures* + revisão semanal (`TODO.md`) |
| Licenças de terceiros (FFmpeg GPL, patentes H.264) | Distribuição bloqueada | ADR 0002; se ficar FFmpeg, build LGPL; avisos de terceiros no "Sobre" e no instalador |
| Volume (137 funcionalidades) | Prazo | P0 → P1 → P2; não perseguir P3 antes do corte |

---

## 10. Protótipos recomendados (antes de tudo)

1. **Build:** compilar um projeto Win64 vazio + um projeto DUnitX por linha de comando (ou registrar o fluxo pelo IDE). Sem isso, nada do resto pode ser verificado.
2. **Tempo real** (✅ 2026-10-09, `ferramentas/prototipo-ws/`, com as mesmas chamadas do WinHTTP em C#): um cliente WebSocket do WinHTTP conectando em `wss://localhost/ws/` com o certificado do mkcert, mandando `{tipo:1}`, recebendo um WS 2 enviado pelo web e sobrevivendo a 5 minutos ocioso (*ping*) e a `docker restart api`.
3. **Mídia:** opção A (§6) com áudio nos dois sentidos entre o FMX e o web, via TURN, sem eco, e a gravação conferida.
