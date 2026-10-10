# 06 — Fila de correções e implementação (FC)

**Data:** 2026-10-08 · **Premissa:** recomendação do doc 04 §8 e do doc 07 (nova base Delphi FMX Win64, interface transplantada), **sujeita à aprovação do ADR 0001**. O app atual só recebe higiene e, opcionalmente, os remendos do Bloco B.

## Como ler

- Cada item tem um ID `FC-nnn`, prioridade (**P0** bloqueia substituir o app atual · **P1** paridade essencial · **P2** paridade completa · **P3** opcional), dependências e um **critério de pronto (CP)** verificável.
- Referências cruzadas:
  - `#n` = problema da auditoria do FMX (doc 04);
  - `Qn` = quebra contra o servidor (doc 02 §10);
  - `AUT-01` etc. = funcionalidade do web (docs 03/05); `WIN-nn` = requisito exclusivo do desktop (doc 05);
  - `Sn` = pendência do servidor (doc 08); `§x` = seção do contrato (doc 01); `Dn` = decisão do plano (doc 07 §1).
- A ordem dentro de cada bloco é a ordem sugerida. O passo a passo detalhado de cada item está no `TODO.md`.
- Marque `[x]` ao concluir e anote o commit.
- **Os IDs FC são do FMX:** a numeração segue a mesma divisão por blocos do Android (para facilitar a comparação), mas os itens não são os mesmos.

---

## Bloco A — Decisão, preservação e higiene do repositório (fazer primeiro)

- [ ] **FC-001 · P0 · Decisões do responsável.**
  - ADR 0001 (recomeçar o núcleo e transplantar a interface — doc 07 D1/D2), com as decisões abertas: senha salva ou não (D11), desktop × celular enquanto o servidor não tem S2/S18 (D13), nome da branch e estrutura (D2).
  - **Como compilar e testar:** licença com compilação por linha de comando (Professional ou superior) ou fluxo de build pelo IDE combinado (D16, #16). Sem isso, a implementação não pode ser verificada nesta máquina.
  - **CP:** ADR 0001 com status "aceito"; decisão sobre o build registrada no histórico.
- [ ] **FC-002 · P0 · Preservar tudo o que existe.**
  - Commitar as alterações *staged* (URL do WebSocket e comentário do WebRTC) num commit próprio na `chamada`: elas já compilaram (doc 04 §2.3) e estão certas para o servidor atual.
  - Criar a branch `legado/abril-2026` e a tag anotada `legado-v1-final` nesse commit.
  - Guardar os **27 *stashes*** sem perda: tag `legado/stash-NN` para cada um + patch de texto em `docs/legado/stashes/NN.patch` (sem binários).
  - Guardar o commit exclusivo da `alteracao-base` numa tag (`legado/alteracao-base`).
  - **CP:** `git status` limpo; 27 tags `legado/stash-*`; patches conferidos (sem segredos).
- [ ] **FC-003 · P0 · Publicar o que só existe nesta máquina** (#93).
  - `git push` da `chamada` (o `4759ba5`, +8.486 linhas, já foi enviado em 2026-10-08; faltam os commits da auditoria e o do *staged*), da `legado/abril-2026` e das tags.
  - **CP:** branch e tags no `origin`. ⛔ O push é feito pelo responsável.
- [ ] **FC-004 · P0 · `.gitignore`** (#93).
  - Acrescentar: `*.dll` (com exceção explícita para o que for decidido versionar), `bin/Conversa/`, `bin/clipboard/`, `bin/dcu/`, `bin/dcp/`, `Android64/`, `Win32/`, `Win64/`, `__astcache/`, `*.log`, `log.txt`, `.claude/`, `*.deployproj`, `Serializer/`.
  - Liberar `docs/**` das regras `*.json` e `*.png` (o `docs/contrato/openapi.json` está ignorado hoje).
  - **CP:** `git status` mostra só o que deve ser versionado; `git check-ignore docs/contrato/openapi.json` não acusa nada.
- [ ] **FC-005 · P1 · Arquivar a documentação antiga.**
  - Mover para `docs/legado/` (com `git mv`): `docs/ALTERACOES_TCP_RECONEXAO.md`, `docs/waveform-spec.md`, `src/notificacao/refatoracao_notificacao.md`, `conversa-webrtc/whep-viewer-spec.md`; versionar `docs/todo.md` lá também (revisão de junho, ainda útil quanto ao cliente).
  - `docs/legado/LEIA.md`: aviso de desatualizado + mapa dos *stashes* e de onde está o código legado.
  - **CP:** nenhum doc antigo fora de `docs/legado/`.
- [ ] **FC-006 · P1 · README e "como compilar"** (#103).
  - O que é o app, estado ("em reescrita", se o ADR for aceito), links para a auditoria; Delphi 12 Win64; dependências em tempo de execução e de onde vêm; servidor de desenvolvimento (`docs/desenvolvimento/servidor-de-dev.md`); mkcert.
  - **CP:** um clone limpo, seguindo o README, chega a um exe que abre (no legado: Win64 + DLLs; na nova base: o que existir).
- [ ] **FC-007 · P0 · `CLAUDE.md`, histórico e ADRs no repositório.** Criados por esta auditoria; commitar (`docs: auditoria de 2026-10, histórico e CLAUDE.md`).
  - **CP:** commit feito; hash anotado no histórico.
- [ ] **FC-008 · P2 · Branches e histórico.**
  - Apagar `keen-buck` e `vigorous-lichterman` (já contidas na `chamada`) e `alteracao-base` (depois da tag do FC-002); `git gc`.
  - Decidir sobre o fonte proprietário `src/fmx/FMX.Platform.Win.pas` no histórico público (#94): reescrever o histórico (quebra clones) ou não.
  - **CP:** decisão registrada. ⛔ Apagar branch e reescrever histórico só com autorização.

## Bloco B — Remendos no app ATUAL (OPCIONAL)

> **Só faça este bloco se alguém usa o app atual no dia a dia até a nova base ficar pronta.** Cada item é pequeno e isolado. Mesmo corrigido, o app atual **não deve ser distribuído a novos usuários** (doc 04 §8). Os remendos ficam na branch `legado/abril-2026`.

- [ ] **FC-020 · P0\* · Nada de vídeo automático** (#1): `PublicarLocalNaSala(ChamadaId, MeuId, False, True)` em `src/chamada/Conversa.Chamada.pas:502`.
- [ ] **FC-021 · P0\* · Parar de salvar a senha** (#6): tirar o `Encrypt`/login automático de `Conversa.Login.pas:68-73`, `:82`; apagar `Senha` dos `conversa.json` existentes na primeira execução.
- [ ] **FC-022 · P0\* · Identificador de anexo validado** (#26): `^[0-9a-f]{64}$` em `DownloadAnexo` e `SalvarAnexo`; `TFile.Copy` em vez de `Move`.
- [ ] **FC-023 · P0\* · Visualizar com `POST`** (#18, Q3): `src/Conversa.Proxy.pas:723-744` com corpo `{conversa, mensagem}`.
- [ ] **FC-024 · P0\* · Mensagem oculta** (#17, Q6): ler `excluida_em` e mostrar "Mensagem oculta".
- [ ] **FC-025 · P0\* · Download pela URL assinada** (#9, Q1) e limpeza do cache envenenado.
- [ ] **FC-026 · P0\* · Upload pelo fluxo novo** (#10, Q2): JSON → PUT na URL → `confirmar`, antes do `PUT /mensagem`.
- [ ] **FC-027 · P0\* · `/conversa/usuarios`** no lugar de `/conversa/dados` (#23, Q4).
- [ ] **FC-028 · P0\* · `/mensagens/novas?desde=`** (#19, Q8) e *upsert* sem reanexar conteúdos (#11).
- [ ] **FC-029 · P0\* · Tipos 5–8** (#22): marcador ("Gravação de áudio", "Chamada", "Figurinha", "📊 Votação") em vez de bolha vazia; tolerar tipo desconhecido.
- [ ] **FC-030 · P0\* · WebSocket mínimo** (#2, #3, #5): OpenSSL na pasta do app com `IdOpenSSLSetLibPath`, `VerifyMode := [sslvrfPeer]` com conferência do host, só TLS 1.2; tratar quadro de tamanho 0 no Bird; reconexão simples (fora da thread da UI, reenviando `{tipo:1}`).
- [ ] **FC-031 · P1\* · Pequenos** : `Continue` nas notificações (#42); relatório de vazamento só em Debug (#67); `DeleteObject` no contador (#41); menu "Sair" na bandeja (#27); `SetWindowLongPtr` (#28).
- [ ] **FC-032 · P1\* · Build do legado** (#16): fixar Win64; documentar como obter as DLLs (versões e *hashes*); `sk4d.dll` x64.

**CP do bloco:** checklist manual — login, conversas, texto, imagem enviada e recebida (nos dois sentidos com o web), "visualizada" no web, mensagem oculta, reconexão depois de `docker restart api`, chamada sem tela automática.

---

## Bloco C — Nova base: Fundação (F0)

> Detalhes no doc 07. Cada item produz código **com testes**.

- [ ] **FC-100 · P0 · Projeto novo** (D1–D3).
  - Branch `nova-base`; código atual em `legado/` (`git mv`, fora do build); `app/Conversa.dpr` **Win64**; Windows 10 1809+; manifesto próprio (PerMonitorV2, `asInvoker`, `supportedOS`, nome); versão automática; saída por `$(Platform)\$(Config)`; nenhum `taskkill` no *PreBuild*.
  - **CP:** compila e abre uma janela vazia; o exe declara a versão certa.
- [ ] **FC-101 · P0 · Estrutura** (doc 07 §2): `core/dominio`, `core/contrato`, `core/infra/*`, `core/aplicacao`, `core/eventos`, `ui/`, `midia/`, `testes/`, `build/`.
  - **CP:** `core/dominio` e `core/aplicacao` não usam FMX nem rede (conferido nos `uses`).
- [ ] **FC-102 · P0 · Build e testes** (D16, D17).
  - Projeto DUnitX em `testes/`; *scripts* em `build/` que compilam Win64 Debug/Release e **conferem o exe e o log** (não confiam no código de saída do MSBuild); TestInsight no IDE.
  - **CP:** os testes rodam (linha de comando, se houver licença; senão pelo IDE, com o resultado registrado). ⛔ Depende do FC-001.
- [ ] **FC-103 · P0 · Barramento de eventos** (D5): multi-assinante, tipado, entrega na thread principal, cancelamento por `IInterface`, isolamento de exceção, "último valor".
  - **CP:** testes de entrega, ordem, cancelamento e exceção em assinante.
- [ ] **FC-104 · P0 · Design** (#72, #90, GER-01, GER-03, GER-07).
  - `ui/Conversa.Cores` com os tokens de `docs/design/cores.md` §7 (claro; escuro como proposta, desligado); `ui/Conversa.Textos` (`resourcestring`, textos do web acentuados); componentes `Avatar` (foto ou inicial pelo grafema, cor estável), `DialogoConfirmacao` (variante perigo, foco em Cancelar, Esc/Enter), `FaixaAviso` (não modal), estados Carregando/Vazio/Erro.
  - **CP:** tela de exemplo com todos os componentes; nenhuma cor nem texto literal fora dessas units.
- [ ] **FC-105 · P0 · Endereço do servidor** (doc 07 §3.1, WIN-01, #70).
  - Um campo só; derivação de `/api/`, `/ws/` e `/webrtc/`; "Testar conexão" (401 com `{error}` = é um Conversa); assistente da primeira execução e aba "Servidor".
  - **CP:** testes da derivação (`https://x` → `wss://x/ws/`; `http://x:8080` → `ws://x:8080/ws/`; barra final; sem `:443`); trocar o servidor muda HTTP, WebSocket e mídia sem reiniciar.
- [ ] **FC-106 · P0 · TLS** (#5, WIN-02): só a validação do Windows (WinHTTP/SChannel); proibido aceitar qualquer certificado; guia do mkcert em `docs/desenvolvimento/servidor-de-dev.md`.
  - **CP:** conecta ao servidor de desenvolvimento com a CA do mkcert instalada; recusa um certificado não confiável com mensagem clara.
- [ ] **FC-107 · P0 · Cliente HTTP tipado** (D8, #39, #24, #25).
  - `IConversaApi` sobre `THTTPClient`; UTF-8; *query* codificada; *timeouts*; repetição só em idempotentes; `EApiErro` (status, mensagem do `{error}`); 401 → "sessão expirada" (rotas públicas não disparam); HTML do nginx → "Servidor indisponível"; 503 do login → "Muitas tentativas".
  - **CP:** testes com um servidor HTTP falso local: sucesso, 401, `{error}`, HTML 502, 503, *timeout*, JSON inválido, acentos e emoji de ida e volta.
- [ ] **FC-108 · P0 · Modelos do contrato** (D7, doc 01).
  - DTOs e mapeadores de login, conversa, mensagem completa (§10.2), conteúdo de chamada (datas sem fuso, §9.8), status (booleanos × datas), anexo (os dois formatos do `PUT /anexo`), chamada (dados, pendentes **sem `usuarios`**, histórico), ICE (camelCase), atividade, permissões, parâmetros, SIP, enquete; conversores de data (ISO com `Z` → UTC) e de id (número ou texto).
  - **CP:** um teste de desserialização por DTO com *fixture* JSON real.
- [ ] **FC-109 · P0 · Banco local** (D10, #68).
  - SQLite pelo FireDAC em `%LOCALAPPDATA%\Conversa`: conversas, mensagens, conteúdos, reações, usuários, atividades, histórico de chamadas, fila de envio, rascunhos, cursores; migrações versionadas.
  - **CP:** inserir e ler cada entidade; migração da versão 1 para a 2 testada quando ela existir. Confirmar que a edição do Delphi tem o driver SQLite do FireDAC (senão, SQLite estático alternativo).
- [ ] **FC-110 · P0 · Sessão segura** (D11, #6, WIN-23).
  - Token com DPAPI; `dispositivo_id` **por usuário** (mapa login → id); **nunca a senha** (salvo decisão do ADR 0001); configuração gravada de forma atômica (#92).
  - **CP:** fechar e abrir o app mantém a sessão; o arquivo não tem o token em texto; outro usuário do Windows não consegue ler a sessão.
- [ ] **FC-111 · P0 · Tempo real** (D9, doc 07 §3.2, #2, #3, #5, #29).
  - `ITempoReal` sobre o WebSocket do WinHTTP numa thread própria; estados, geração, *backoff* com *jitter*, *ping* de 30 s; `{tipo:1}` (número) a cada abertura; tipo 0 → "sessão expirada"; `TParserEventos` com todos os tipos (0, 2, 3, 4, 5, 7, 9, 40, 51–57, 60, 61, 62) e `Desconhecido`; envio só de 1 e 57.
  - **CP:** testes do parser (um *payload* real por tipo) e da máquina de estados; no servidor de desenvolvimento: `docker restart api` → reconecta sozinho; 5 minutos ocioso → continua recebendo; nunca dois sockets abertos.
- [ ] **FC-112 · P0 · Sincronização** (doc 07 §3.3, #19, #20, #44).
  - `TSyncManager.Ressincronizar` ao conectar e ao voltar do segundo plano: `mensagens/novas` com cursor `desde`, `conversas`, `contatos/online`, `atividades/novas`, `chamadas/pendentes`; WS 2 como gatilho com *debounce*; uma busca por conversa por vez.
  - **CP:** derrubar a rede por 2 minutos, mandar mensagens pelo web e religar → tudo aparece, sem duplicar.
- [ ] **FC-113 · P0 · *Logger* e diagnóstico** (#84, WIN-21): fila + thread, níveis, rotação, redação (token, senha, conteúdo) por padrão; exceções não tratadas registradas com pilha; relatório de vazamento só em Debug (#67).
  - **CP:** teste de redação; log em `%LOCALAPPDATA%\Conversa\logs`.
- [ ] **FC-114 · P0 · Regra "nenhuma E/S na thread da interface"** (#24, WIN-29): serviços assíncronos com cancelamento; *ViewModels* só recebem estado pelo barramento.
  - **CP:** com um servidor que demora 30 s para responder, a janela continua respondendo e mostra "carregando".
- [ ] **FC-115 · P0 · Base de janela e Windows** (#28, #79, WIN-09, WIN-10, WIN-25).
  - Barra de título própria transplantada com `SetWindowLongPtr`; instância única por *mutex* (sessão do Windows) com repasse de argumentos (`WM_COPYDATA`); PerMonitorV2; posição salva conferindo se o monitor existe.
  - **CP:** abrir duas vezes traz a janela existente; arrastar entre monitores com escalas diferentes mantém o tamanho certo.

## Bloco D — Sessão, conversas, contatos, presença (F1)

- [ ] **FC-200 · P0 · Login** (AUT-01, #4, #46): textos do web ("Usuário", "Senha", "Entrar"/"Entrando..."), assíncrono, erro inline, `dispositivo_id` reenviado, `trim()`.
  - **CP:** login, fechar o app, reabrir → entra direto (pela sessão salva, sem senha).
- [ ] **FC-201 · P0 · Dispositivo** (AUT-04, #86): `PATCH /dispositivo {id, nome, modelo, versao_so, plataforma:"Windows"}` a cada início de sessão; `versao_so` por `RtlGetVersion` (≤ 15), nome do computador (≤ 50), modelo pelo WMI (≤ 50); sem `token_fcm`.
  - **CP:** linha do dispositivo conferida no banco de desenvolvimento.
- [ ] **FC-202 · P0 · Sessão resiliente e saída** (AUT-03, AUT-05, #4).
  - 401 em qualquer lugar → tela de login com "Sua sessão expirou. Entre novamente." (ou relogin silencioso, se aprovado no ADR); outros erros mantêm a sessão e tentam de novo a cada 5 s ("… (tentando de novo...)").
  - "Sair da conta": encerra chamada, fecha o WebSocket, limpa notificações, contador, cache e banco do usuário, mantém o `dispositivo_id`.
  - **CP:** depois de sair, nenhuma notificação chega; depois de invalidar o token no servidor, o app avisa e volta ao login.
- [ ] **FC-203 · P1 · Cadastro** (AUT-02): "Crie sua conta", limites (nome 100, login 50, e-mail 100), e-mail duplicado (500 do Postgres hoje, S7) → "E-mail já cadastrado".
- [ ] **FC-204 · P0 · Lista de conversas** (CON-01, #42, #83).
  - Do banco local; ordem (fixadas por `fixada_ordem`, depois as demais); título `descricao || nome || "Conversa #id"`; prévia como o web (`@Nome`, `Código (linguagem)`, "Sem mensagens", resumo por tipo — nunca caminho de arquivo); contador oculto em arquivadas; hora (hoje `HH:mm`, "Ontem", `dd/MM/aa` — comparando a **data**, #82); bolinha online; "Grupo"; alfinete; pontinhos de digitando; lista virtual.
  - **CP:** comparação lado a lado com o web nos casos do doc 03 CON-01.
- [ ] **FC-205 · P0 · Lista em tempo real** (CON-13): WS 2, 3 e 40, envio e leitura atualizam sem *spinner*; conversa que o usuário deixou sai da lista.
- [ ] **FC-206 · P1 · Filtro e "Nova conversa"** (CON-02): "Pesquisar..." (Ctrl+F/Ctrl+K), arquivadas com etiqueta, seção "Nova conversa" com contatos sem direta.
- [ ] **FC-207 · P1 · Fixar, desafixar, reordenar** (CON-03): menu + arrastar com linha indicadora; `PATCH /conversa/fixadas` com a lista inteira, otimista, com *rollback*.
- [ ] **FC-208 · P1 · Arquivar** (CON-04): `PATCH /conversa/arquivada`; sem som, notificação nem contador; seção "Arquivadas (N)".
- [ ] **FC-209 · P1 · Menu da conversa** (CON-05): clique direito, botão "⋯" no *hover*, Shift+F10/tecla Menu, Esc.
- [ ] **FC-210 · P0 · Contatos e conversa direta** (CON-06, CON-11, #60, #74): sem o próprio usuário; reaproveitar a direta (`tipo=1 && destinatario_id`); senão criar (`PUT /conversa` → `PUT /conversa/usuario` para mim e para o contato); falha parcial com aviso (S8).
- [ ] **FC-211 · P1 · Criar grupo** (CON-07): textos e regra do web (≥ 1 usuário, "Criar grupo", "Nome do grupo"); abrir o grupo criado.
- [ ] **FC-212 · P1 · Dados do grupo** (CON-08): painel à direita aberto pelo avatar do grupo: renomear, participantes com bolinha e "(você)", adicionar, "Sair do grupo" (só o próprio vínculo, S15), anexos do grupo (FC-809).
- [ ] **FC-213 · P1 · Presença** (PRE-01, #45): `contatos/online` + WS 60; bolinha na lista, no cabeçalho, nos contatos e no painel do grupo.
- [ ] **FC-214 · P1 · Faixa "sem conexão em tempo real"** (GER-02): depois de 5 s fora, "Conexão em tempo real indisponível — usando atualização periódica", com "Tentar agora".
- [ ] **FC-215 · P0 · Bandeja e encerramento** (WIN-03, WIN-04, #27).
  - Menu da bandeja ("Abrir Conversa", "Não perturbe", "Sair do Conversa"); X fecha para a bandeja (configurável; aviso na primeira vez); Alt+F4 = X; `NIM_DELETE` ao sair; recriar no `TaskbarCreated`; dica com o número de não lidas.
  - **CP:** sair pelo menu encerra o processo e o ícone some; reiniciar o Explorer não perde o ícone.

## Bloco E — Mensagens: núcleo (F2)

- [ ] **FC-300 · P0 · Tela de chat e cabeçalho** (CON-09, #23): avatar clicável, bolinha, subtítulo (membros / digitando / gravando), membros por `GET /conversa/usuarios`, "Chamada de voz", "Chamada de vídeo", "Participantes e anexos", "Pesquisar na conversa".
- [ ] **FC-301 · P0 · Carregar e paginar** (MSG-01, #20, #21): `GET /mensagens` com referência = primeira/última salva; descartar a repetida; parar quando vier menos que o pedido (máximo 100); preservar a âncora ao inserir no topo; "Carregando mensagens…".
  - **CP:** rolar até o início de uma conversa com 1.000+ mensagens sem travar nem pular.
- [ ] **FC-302 · P0 · Modelo de mensagem completo** (doc 01 §10.2): `excluida_em`, `visivel_em`, `mensagem_referencia` recursiva, `reacoes`, conteúdos 1–8 com `transcricao_*`.
- [ ] **FC-303 · P0 · Classificação das bolhas** (MSG-07, #22): mesma ordem de `classificarMensagem.ts`, testes portados do web.
- [ ] **FC-304 · P0 · Mensagem oculta** (MSG-16, #17, Q6).
- [ ] **FC-305 · P0 · Bolha de chamada** (MSG-13): JSON tipo 6 (datas sem fuso), textos e cores do web, "Ligar de novo".
- [ ] **FC-306 · P0 · Separadores e remetente** (MSG-02, #100): "Hoje"/"Ontem"/"seg., 05/10/2026" com `TFormatSettings` pt-BR; nome só nas recebidas de grupo, quando muda o remetente.
- [ ] **FC-307 · P0 · Enviar texto** (ENV-01, #47): otimista com fila (doc 07 §3.4); Enter envia, Shift+Enter quebra, Tab = 4 espaços; "Digite uma mensagem"; erro visível com "Reenviar"/"Apagar".
  - **CP:** enviar com a API fora → a mensagem sai sozinha quando ela volta, sem duplicar.
- [ ] **FC-308 · P0 · Marcar como visualizada** (MSG-04, #18, #53, Q3): `POST` só para mensagens de outros, totalmente visíveis, com a janela ativa; desconta o contador depois do sucesso; fecha a notificação ao zerar.
- [ ] **FC-309 · P0 · Status de entrega** (MSG-08, MSG-10): relógio/✓/✓✓/✓✓ cor primária; WS 3 → `GET /mensagem/status` (agregado: só nas minhas), inclusive `excluida_em`.
- [ ] **FC-310 · P1 · "Últimas" e botões de rolagem** (MSG-03, MSG-05): as 5 regras do web; "Ir para o final"; "Há novas mensagens"; rolar ao fim só se perto do fim.
- [ ] **FC-311 · P1 · *Links*** (MSG-11, #56): regras de `parseLinks`, `www.`, abrir no navegador com `TURI` (só `http`/`https`).
- [ ] **FC-312 · P1 · Digitando e gravando** (ENV-15, ENV-16, #45): envio a cada 2,5 s (o último adiado), recepção com expiração de 4 s, textos do web.
- [ ] **FC-313 · P2 · Mensagem só de emojis** (MSG-14): fonte grande, sem fundo, detecção por *code point*.
- [ ] **FC-314 · P0 · Abrir conversa por *link*/notificação** (CON-12): recarregar as mensagens; `?mensagem=` vai à mensagem (FC-505).
- [ ] **FC-315 · P0 · Marcador da votação** (MSG-20): até a F4, a bolha tipo 8 mostra "📊 Votação" + "Abra a votação no web" (nunca vazia).
- [ ] **FC-316 · P1 · Teclado do chat** (ENV-12, doc 03 §7): letra digitada fora do campo vai para o campo; Esc fecha painéis; foco no campo ao trocar de conversa.

## Bloco F — Anexos e mídia (F3)

- [ ] **FC-400 · P0 · Upload** (ANX-02, #10, #54, Q2): SHA-256 em *streaming* → `PUT /anexo` (JSON) → `PUT` na URL assinada (*streaming*, sem `Authorization`, renovando se vencer) → `POST /anexo/confirmar?identificador=`; tudo dentro da fila de envio; progresso na bolha.
  - **CP:** um arquivo de 200 MB sobe sem estourar a memória; o mesmo arquivo de novo não sobe.
- [ ] **FC-401 · P0 · Anexar arquivos** (ANX-01, #51): seletor de arquivos múltiplo; fila na ordem escolhida; miniaturas; remover; erro em qualquer upload cancela a mensagem inteira.
- [ ] **FC-402 · P0 · Tipos de conteúdo** (ANX-03): imagem 2, áudio 4, **gravação 5**, resto 3 (vídeo = 3 com extensão), por MIME/assinatura; extensão ≤ 10.
- [ ] **FC-403 · P0 · URLs assinadas e cache** (ANX-14, #9, #26, Q1): `GET /anexo` → `{url}`; cache por identificador **validado**; download para temporário + validação + renomear; limpeza do cache antigo envenenado na primeira execução.
- [ ] **FC-404 · P0 · Imagens** (ANX-04, #98): bolha (hora sobre a imagem), visualizador com galeria da conversa (sem ocultas), zoom (roda, duplo clique, +/−), ←/→, legenda, "Copiar imagem (Ctrl+C)", Esc.
- [ ] **FC-405 · P0 · Áudio** (ANX-10, #57): *player* único, `mm:ss`, verde até ouvir, `POST /mensagem/reproduzir` no primeiro *play*, para ao sair da conversa e ao entrar em chamada; toca Opus/WebM do web.
- [ ] **FC-406 · P0 · Gravação** (ANX-11, #57, Q13): segurar ≥ 300 ms e soltar envia; clique curto trava; barra com "Descartar", "Pausar gravação", "Ouvir gravação", "Enviar áudio"; formato real; tipo 5; `audio-<timestamp>.<ext>`; "gravando" a cada 2,5 s.
- [ ] **FC-407 · P0 · Baixar e salvar** (ANX-09, #55): `Downloads\Conversa` (ou "Salvar como"), copiar (nunca mover), Mark-of-the-Web, aviso para extensões perigosas, "Abrir" e "Abrir pasta".
- [ ] **FC-408 · P1 · Vídeo** (ANX-05): primeiro quadro na bolha, reprodução no visualizador.
- [ ] **FC-409 · P1 · Transcrição** (ANX-12): "Transcrever", consulta a cada 3 s, esconder o botão se o servidor não tiver transcritor (S10).
- [ ] **FC-410 · P1 · Arrastar e soltar** (GER-04, WIN-17): soltar do Explorer sobre a conversa ("Solte para enviar o arquivo") e sobre o campo; colar arquivos copiados no Explorer (`CF_HDROP`).
- [ ] **FC-411 · P1 · Colar** (ENV-11, ENV-09, #52): imagem → `print-<ms>.png` no temporário; texto com mais de 10 linhas → "Inserir código"; texto com cara de código → cercado; Ctrl+V, Shift+Insert e menu.
- [ ] **FC-412 · P2 · PDF** (ANX-06): visualizador (WebView2 com o PDF local) ou abrir com o app padrão.
- [ ] **FC-413 · P3 · HTML** (ANX-07): abrir no navegador padrão a partir de arquivo temporário.
- [ ] **FC-414 · P3 · Rede tarifada** (MSG-18): "Clique para carregar" mídia grande em rede tarifada (opcional).
- [ ] **FC-415 · P1 · Campo de mensagem rico** (ENV-21): texto e peças intercalados, enviados na ordem (depende do FC-416).
- [ ] **FC-416 · P1 · Decisão de produto: campo completo × simplificado** (ADR): recomendação: começar com fila + texto (enviado como [anexos…, texto]) e evoluir depois; mensagens intercaladas recebidas são exibidas certo de qualquer forma.

## Bloco G — Ações sobre mensagens (F4)

- [ ] **FC-500 · P0 · Menu de ações** (ENV-20): clique direito = menu completo; **Ctrl + clique direito = só reações**; botão de ações (seta) no *hover*; itens na ordem do web; sem menu para chamada, oculta e mensagem sem id real; sem "Encaminhar" em votação (FC-518).
- [ ] **FC-501 · P0 · Reações** (ENV-17): `PUT /mensagem/reacao` otimista; chips com contagem, destaque se eu reagi, *tooltip* de quem reagiu (foto, nome, hora); limite de **5 emojis por pessoa** ("Você já reagiu com 5 emojis nesta mensagem."); 5 chips + "+N"; WS 7.
- [ ] **FC-502 · P0 · Responder** (ENV-06): barra acima do campo; `mensagem_referencia {tipo:1, origem_mensagem_id}`; a otimista já mostra a citação.
- [ ] **FC-503 · P0 · Ocultar** (ENV-18): confirmação exata do web (foco em "Cancelar"); agendada futura → "Cancelar mensagem agendada".
- [ ] **FC-504 · P1 · Citação recursiva** (MSG-19): até 5 níveis; "Encaminhado de <nome>"; não repetir conteúdos (`semCopiasDaReferencia`).
- [ ] **FC-505 · P1 · Ir para a mensagem** (MSG-06): contexto 30/30 (senão 120/120), centralizar e destacar 1,2 s; erro "Não foi possível localizar esta mensagem no contexto da conversa.".
- [ ] **FC-506 · P1 · Encaminhar** (ENV-08): "Encaminhar mensagem" com busca (conversas + contatos sem direta); `tipo:2`; conteúdos reordenados 1..n.
- [ ] **FC-507 · P1 · Copiar** (ENV-19, #49): texto (com seleção parcial) e imagem (PNG).
- [ ] **FC-508 · P1 · Menções** (ENV-05, MSG-12): "@" abre até 6 contatos (↑/↓, Enter/Tab, Esc); `@[Nome](id)` no envio; render `@Nome` com cartão no *hover* e clique que abre a direta; testes portados de `mencoesTexto.ts`.
- [ ] **FC-509 · P1 · Figurinhas** (ENV-04, #87): os 24 JSON embutidos como recurso; Skia/Skottie **do Delphi**; seletor por pacote; tipo 7 `pacote/nome`; bolha de 160 px; animar só visível.
- [ ] **FC-510 · P1 · Código e Markdown** (MSG-15): porte de `codeBlocks.ts` com testes; cabeçalho com a linguagem, "Copiar"/"Copiado!", destaque de sintaxe, "Expandir código"/"Recolher código"; Markdown renderizado.
- [ ] **FC-511 · P2 · Mermaid**: WebView2 isolado com mermaid.js embutido, ou mostrar o código.
- [ ] **FC-512 · P2 · Responder no privado** (ENV-07).
- [ ] **FC-513 · P2 · Detalhe do status** (MSG-09): *hover* de 300 ms no ✓ (e clique): direta "Enviada/Recebida/Visualizada/Ouvida/Oculta/Aguardando"; grupo "Visualizada por (N)"…; aqui os campos são **datas**.
- [ ] **FC-514 · P2 · Agendar** (ENV-13, ENV-14, MSG-17): "Agendar mensagem" (padrão amanhã 08:00; ≥ 5 min; ≤ 1 ano); relógio com o número ao lado do microfone e lista "Mensagens agendadas" com "Cancelar".
- [ ] **FC-515 · P2 · Extras do campo** (ENV-02, ENV-03, ENV-10): atalhos `:)` → 🙂 (fora de código); seletor de emoji próprio (sem `SendInput`); janela "Inserir código" (Ctrl+Enter envia).
- [ ] **FC-516 · P1 · Bolha de votação** (MSG-20): `GET /enquete` com cache; votar com a lista completa; WS 62; data final, encerrar, 🏆; votação oculta revelada como resumo.
- [ ] **FC-517 · P1 · Criar votação** (ENV-22): "Nova votação" a partir do "+" (só em grupo), com data final opcional.
- [ ] **FC-518 · P1 · Esconder "Encaminhar" em votação** (o servidor recusa com 400).
- [ ] **FC-519 · P1 · Rascunho por conversa** (ENV-23, #48): texto, menções, anexos e resposta pendente no banco local; restaurar ao abrir; apagar ao enviar; **apagar no "Sair da conta"** (o web não apaga, doc 08 W2).
- [ ] **FC-520 · P2 · Encaminhada de encaminhada** (MSG-19): na citação aninhada, não repetir o que a citação de baixo já mostra.

## Bloco H — Notificações e integração com o Windows (F5)

- [ ] **FC-600 · P0 · Decidir e prototipar: toast nativo × janela própria** (D12, WIN-05, #76): AUMID e atalho no Menu Iniciar; teste com "não perturbe" e tela cheia.
- [ ] **FC-601 · P0 · Notificação de mensagem** (NOT-02, #42): uma por conversa, título = remetente (ou "Nova mensagem"), corpo = resumo do web por tipo ("Imagem", "Gravação de áudio", "Áudio", "Figurinha", "Votação", "Arquivo", `@Nome`, `Código (linguagem)`), avatar, `HH:mm`; clique abre a conversa recarregando.
- [ ] **FC-602 · P0 · Quando notificar e tocar** (NOT-01): nada na conversa aberta com a janela ativa; nada em arquivadas; um som por lote; com o usuário ausente, a notificação espera.
- [ ] **FC-603 · P1 · Fechar a notificação** (NOT-03): ao zerar o contador da conversa (inclusive leitura em outro aparelho, S17), ao arquivar e ao abrir.
- [ ] **FC-604 · P1 · Ações na notificação**: "Responder" e "Marcar como lida" (se o mecanismo escolhido permitir).
- [ ] **FC-605 · P1 · Sons** (WIN-06): mensagem, toque e chamando (mesmos arquivos do web) como recursos; mudo global e por conversa; dispositivo de saída.
- [ ] **FC-606 · P2 · "Não perturbe"** (WIN-07): modo do app com prazo + respeito ao "Não incomodar" do Windows (`SHQueryUserNotificationState`).
- [ ] **FC-607 · P1 · Iniciar com o Windows** (WIN-08): opção (padrão ligado no instalador), abrindo minimizado na bandeja.
- [ ] **FC-608 · P1 · Barra de tarefas** (WIN-11, WIN-15, #41): contador (sem arquivadas, sem vazar GDI), descrição acessível ("3 mensagens não lidas"), `FlashWindowEx` em mensagem nova e contínuo em chamada recebida.
- [ ] **FC-609 · P0 · Desktop × celular** (D13, #15, S2/S18): fechar o WebSocket ao bloquear a sessão (`WTS_SESSION_LOCK`), ao suspender (`PBT_APMSUSPEND`) e depois de N minutos ocioso (configurável), com *polling* REST nesse período; reabrir e ressincronizar ao voltar.
  - **CP:** com o desktop aberto e a sessão bloqueada, uma mensagem gera push no celular; ao desbloquear, o desktop recupera tudo. Remover quando o servidor tiver S2/S18.
- [ ] **FC-610 · P1 · Protocolo `conversa://`** (WIN-28, CON-12): registrar o protocolo; `conversa://conversa/<id>?mensagem=<id>` abre na instância aberta.
- [ ] **FC-611 · P2 · Inatividade** (WIN-14, #75): limiar de minutos, sem *poll* de 100 ms; não marcar como visualizada com o usuário ausente.
- [ ] **FC-612 · P1 · Privacidade do Windows** (CFG-04, NOT-06): estado do acesso a microfone, câmera e notificações, com botões que abrem `ms-settings:privacy-microphone`, `ms-settings:privacy-webcam` e `ms-settings:notifications`.

## Bloco I — Chamadas (F6)

- [ ] **FC-700 · P0 · Protótipo e ADR 0002 da pilha de mídia** (D14, doc 07 §6): opção A (WebView2 com o módulo de chamada do web) primeiro; B (libwebrtc) se A falhar; C (Pion + FFmpeg corrigido) como reserva.
  - **CP:** áudio nos dois sentidos FMX ↔ web via TURN, em redes diferentes, com alto-falante e **sem eco**; gravação conferida no MediaMTX; ADR 0002 aceito.
- [ ] **FC-701 · P0 · Gerenciador de chamadas** (doc 07 §3.6, D15, #7, #8, #30, #32, #61, #62): escopo de aplicação, dono único, máquina de estados, geração, encerrar idempotente.
  - **CP:** testes de **todas** as transições (inclusive eventos fora de ordem e duplicados).
- [ ] **FC-702 · P0 · ICE/TURN e endereço da mídia** (#12, Q11): na pilha nativa, `GET /api/ice` a cada conexão, `relay`, *gathering* ≤ 5 s, base `<servidor>/webrtc`; no WebView2, a própria página faz isso (conferir).
- [ ] **FC-703 · P0 · Publicar e assinar com robustez** (#31): retentativas de WHEP (áudio 12 × 0,8 s, vídeo 40 × 1 s), sincronização a cada 4 s, republicar e reassinar em falha.
- [ ] **FC-704 · P0 · Mídia correta** (#13, #14, #35–#38, #63–#65): codec gravável (H264/VP9) e Opus; cancelamento de eco, supressão de ruído e ganho automático; licenças em ordem. Em grande parte resolvido pela escolha do FC-700.
- [ ] **FC-705 · P0 · Iniciar** (CHA-01, #62, #23, Q14): botões "Chamada de voz"/"Chamada de vídeo"; `PUT /chamada/iniciar {tipo, usuarios (com o próprio), conversa_id}`; membros por `/conversa/usuarios`; som de chamando; "Já existe uma chamada em andamento"; desfazer em erro.
- [ ] **FC-706 · P0 · Chamada recebida** (CHA-03, #61): janela no topo sem roubar o teclado ("<nome> está ligando...", "Vídeo + Áudio"/"Somente Áudio"), toque em loop, `FlashWindowEx`; 30 s → `recusar {nao_atendeu:true}`; "×" só esconde.
- [ ] **FC-707 · P0 · Atender e recusar** (CHA-04, CHA-05): fallback vídeo+áudio → só áudio → só recepção; "Atender só assistindo"; um único `POST /chamada/recusar`.
- [ ] **FC-708 · P0 · Ocupado** (CHA-06, #32): 51 durante outra chamada → recusar com `nao_atendeu` sem tocar; 51 da chamada atual → só sincronizar.
- [ ] **FC-709 · P0 · Atendida/recusada em outro aparelho** (CHA-07, #30): 53/54 com o meu id enquanto toca → parar e voltar a ocioso, sem REST.
- [ ] **FC-710 · P0 · Pendentes** (CHA-08): ao conectar, ao reconectar e ao voltar da suspensão; > 25 s → perdida; resposta sem `usuarios`.
- [ ] **FC-711 · P0 · Cancelar e sair** (CHA-09): comandos únicos para janela, barra de título e botões da miniatura da barra de tarefas.
- [ ] **FC-712 · P0 · Eventos da chamada ativa** (CHA-10): 54 → assinar; 55 → `GET /chamada/dados` → sair se ninguém mais "Entrou"; 53 em 1:1 e 52 → encerrar.
- [ ] **FC-713 · P0 · Áudio e dispositivos** (CHA-11, CHA-23, WIN-30, #96): microfone (mute por *flag*), saída, escolha de dispositivos lembrada, seguir o dispositivo de comunicação padrão, reagir a fone conectado/desconectado; parar áudio de mensagem ao entrar em chamada.
- [ ] **FC-714 · P0 · Janela e controles** (CHA-11, CHA-13, #61): janela flutuante (StayOnTop opcional, arrastável, redimensionável, mínimo 320×240), cabeçalho ("Chamando..."/"Em chamada"/"Encerrando...", duração `mm:ss`, tipo, pessoas), pílulas com estado (vermelhas quando desligadas), atalhos, botões na miniatura da barra de tarefas, indicador clicável que reabre a janela.
- [ ] **FC-715 · P0 · Histórico** (CHA-22, #33, Q5): `ChamadaHistoricoItem`; "Todas"/"Perdidas" (perdida = recebida em que eu não entrei); busca por contato; período; "Hoje"/"Ontem"/data; "Ligar novamente".
- [ ] **FC-716 · P1 · Vídeo** (CHA-12, CHA-16): câmera; grade (1–4 colunas)/destaque/tela única; "Ativar vídeo" (`POST /chamada/video`); WS 56 → "Apenas assistir / Transmitir também" (15 s).
- [ ] **FC-717 · P1 · Adicionar participante** (CHA-14): "Adicionar à chamada"; `PUT /chamada/usuario` um por vez.
- [ ] **FC-718 · P2 · Compartilhar a tela por ação explícita** (CHA-02, CHA-15, #1): seletor de monitor/janela, indicador permanente, anúncio pelo WS 57 `{acao:"tela"}`; áudio do sistema opcional.
- [ ] **FC-719 · P2 · Chat da chamada** (CHA-18, CHA-24): grupo criado no primeiro clique no campo; painel lateral reaproveitando a tela de chat.
- [ ] **FC-720 · P2 · Indicador de fala** (CHA-19, #66): nível > 0,02, segura 400 ms, anel verde.
- [ ] **FC-721 · P2 · Somente recepção** (CHA-21): entrar sem dispositivos; "Ativar microfone"/"Ativar câmera".
- [ ] **FC-722 · P2 · Tela e ponteiro remotos** (CHA-17): a tela compartilhada em destaque, ponteiros com nome e cor; enviar o ponteiro pelo mouse.
- [ ] **FC-723 · P2 · Qualidade da chamada** (CHA-20, CFG-06): opções e padrões de desktop do web (720p, 24 fps; Opus 32/64/128).
- [ ] **FC-724 · P1 · Matriz de testes manuais de chamada**: `docs/testes/chamadas.md` (rede, suspensão, bloqueio, Bluetooth, fone, 1:1, grupo de 4, upgrade, adicionar, atender em outro aparelho, gravação).

## Bloco J — Atividades, pesquisa, perfil, configurações (F7)

- [ ] **FC-800 · P1 · Atividades** (ATV-01, ATV-02): item "Atividades" com contador (`99+`); `GET /atividades` paginado; WS 61; `POST /atividades/vistas`; textos do web.
- [ ] **FC-801 · P1 · Pesquisa** (PES-01, PES-02): na conversa (Ctrl+F) e em todos os chats (Ctrl+Shift+F); resultados agrupados; termo destacado **escapando o texto** (o web tem o bug W1, doc 08).
- [ ] **FC-802 · P1 · Perfil** (AUT-06, AUT-07, AUT-08): nome/e-mail (`PATCH /usuario {id, …}`), senha (`POST /alterar-senha {senha_atual, senha}`, mínimo 6), avatar (256×256 JPEG 85% → upload → `avatar_anexo_id`).
- [ ] **FC-803 · P1 · Perfil de outro usuário** (AUT-10): foto, nome, "E-mail", "Telefone" ("Não informado"), "Ver anexos", "Ligar".
- [ ] **FC-804 · P1 · Configurações** (CFG-01): janela/painel (Ctrl+,) com as abas do web + Servidor, Notificações e sons, Inicialização, Sobre.
- [ ] **FC-805 · P2 · Tema** (CFG-02, WIN-13): claro / escuro / seguir o Windows (`AppsUseLightTheme` + `WM_SETTINGCHANGE`), em todas as janelas.
- [ ] **FC-806 · P2 · Dispositivos** (CFG-03): sessão atual e lista de microfones, saídas e câmeras, com escolha (melhoria em relação ao web).
- [ ] **FC-807 · P1 · Atalhos de teclado** (WIN-12): Ctrl+F, Ctrl+Shift+F, Ctrl+K/N, Ctrl+Shift+N, Alt+↑/↓, Ctrl+,, Esc, atalhos da chamada; tabela no "Sobre".
- [ ] **FC-808 · P2 · Sistema e Acessos** (CFG-07, CFG-08, AUT-09): visíveis conforme `GET /usuario/permissoes`.
- [ ] **FC-809 · P2 · Anexos da conversa** (ANX-13): filtros, grade, paginação; também no painel do grupo.
- [ ] **FC-810 · P2 · Zoom e formatos** (WIN-27, WIN-33): Ctrl+= / Ctrl+− / Ctrl+0 e Ctrl+roda sem mudar o tamanho da janela; datas sempre em pt-BR.

## Bloco K — Extras e distribuição (F8)

- [ ] **FC-900 · P2 · Janela de conversa separada** (CON-10, WIN-16): mesmo processo, mesmo WebSocket e banco; 900×700; posição lembrada; "conversa aberta e focada" considera qualquer janela.
- [ ] **FC-901 · P2 · Configuração SIP** (SIP-01): aba "Voip".
- [ ] **FC-902 · P3 · Telefonia SIP** (SIP-02…05): protótipo (pilha nativa sobre WSS ou WebView2 com `sip.js`); discador flutuante.
- [ ] **FC-903 · P3 · Cores personalizadas** (CFG-05).
- [ ] **FC-904 · P1 · Instalador** (WIN-18): por usuário, sem administrador; atalho no Menu Iniciar (AUMID); WebView2 *bootstrapper* (se a opção A); dependências; desinstalação limpa.
- [ ] **FC-905 · P2 · Atualização automática** (WIN-19, S24).
- [ ] **FC-906 · P2 · Versão e assinatura de código** (WIN-20, #85).
- [ ] **FC-907 · P2 · Avisos de terceiros** (WIN-32, #36): "Sobre" e instalador.
- [ ] **FC-908 · P3 · Jump List** (WIN-28): "Nova conversa", "Sair".

## Bloco L — Qualidade transversal (contínuo)

- [ ] **FC-950 · P0 · Testes:** unitários de parsers (WS, datas, código, menções, classificação), mapeadores, máquina de estados da chamada, `SyncManager`, fila de envio, validação de identificador; meta ≥ 70% no `core`.
- [ ] **FC-951 · P0 · Acessibilidade** (WIN-22, #71): componentes focáveis, navegação por teclado, foco visível, `Hint` em todos os ícones, contraste AA, teste com o Narrador.
- [ ] **FC-952 · P0 · Segurança:** nada de token/senha/conteúdo em log; identificador validado; Mark-of-the-Web; `SetDefaultDllDirectories` e DLLs carregadas por caminho completo; vídeo/tela só por ação explícita.
- [ ] **FC-953 · P1 · Diagnóstico:** "Copiar diagnóstico" e "Abrir pasta de logs" no "Sobre".
- [ ] **FC-954 · P1 · Matriz de testes manuais do desktop:** Windows 10 e 11; 100/125/150/200%; vários monitores; suspender/bloquear; servidor fora; instalação limpa.
- [ ] **FC-955 · P1 · Dados locais** (WIN-31, #68): cota e limpeza do cache; nada na pasta do exe.

## Bloco M — Itens que dependem do servidor (ver doc 08)

| FC | Depende de | Por quê |
|---|---|---|
| FC-609, FC-111 | **S2 + S18** | Sem isso, o desktop conectado deixa o celular sem push; o FC-609 é o paliativo |
| FC-110, FC-202 | **S13** (*refresh token*) | Sem isso, login diário (ou senha guardada) |
| FC-700–FC-704 | **S4** (autenticação no MediaMTX) | Privacidade da mídia (e da tela compartilhada) |
| FC-403 | **S20** (validar identificador) e S4 | Defesa em profundidade; participação em `GET /anexo` |
| FC-603, FC-205 | **S17** | Leitura e envio em outro aparelho do mesmo usuário |
| FC-706 | **S19** | A recusa por tempo de um aparelho não deveria encerrar o toque dos outros |
| FC-111 | **S21**, **S22** | *Keepalive* documentado; WS 2 sem duplicar |
| FC-210, FC-211 | S8 | Criação de conversa atômica |
| FC-308 | S9 | Visualizar em lote |
| FC-905 | S24 | Onde publicar a versão do desktop |
| FC-700 (opção A) | **Web:** rota de "chamada embutida" no `conversa-web` | A página do WebView2 precisa existir no servidor |

---

## Ordem macro e estimativa grosseira (1 desenvolvedor Delphi experiente)

| Etapa | Blocos | Estimativa |
|---|---|---|
| 0 | A (+ B se necessário) + protótipos (build, WebSocket WinHTTP, mídia) | 1 semana (+ 1–2 semanas com o B) |
| 1 | C (fundação) | 2–3 semanas |
| 2 | D + E (conversas + mensagens núcleo) | 3–4 semanas |
| 3 | F (anexos) | 2–3 semanas |
| 4 | H (notificações e Windows) | 1–2 semanas |
| 5 | I (chamadas, P0/P1) | 3–6 semanas (depende do ADR 0002; a opção A é a mais curta) |
| 6 | G (ações) | 2–3 semanas |
| 7 | J (atividades, pesquisa, configurações) | 2 semanas |
| 8 | K + P2/P3 restantes | sob demanda |

**Marco "substitui o app atual":** todos os P0 dos blocos C–I. Ordem de grandeza: **~14–20 semanas**.

**Marco "paridade essencial com o web":** + todos os P1. Ordem de grandeza: **~20–26 semanas**.

> As estimativas são ordens de grandeza para planejamento, não compromisso. Elas assumem a licença de build resolvida, o protótipo de mídia bem-sucedido na opção A e S2/S13 caminhando no servidor em paralelo.
