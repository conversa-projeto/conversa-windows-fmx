# Auditoria do cliente Windows (FMX) — outubro/2026 (LEIA PRIMEIRO)

**Data:** 2026-10-08
**Escopo:** `conversa-windows-fmx` (Delphi 12 / FireMonkey; branch `chamada`, HEAD `4759ba5` de 2026-04-26 + alterações *staged*), comparado ao servidor `conversa` (Bun + Elysia, HEAD `779c8ed`) e ao cliente web `conversa-web` (HEAD `e8d82cb`), que é a referência de comportamento.
**Método:**
- varredura em 8 frentes, com leitura integral do código próprio do FMX e conferência no código do servidor e do web (relatórios em `apoio/`);
- revalidação dos documentos de contrato (01) e de inventário do web (03) da auditoria do Android, copiados e adaptados para o desktop;
- tentativa de build real (bloqueada: o Delphi instalado é Community, sem compilação por linha de comando);
- nenhum código foi alterado; só a pasta `docs/` (e nela esta auditoria) foi criada.

O processo é o mesmo da auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo.

---

## Documentos desta pasta

| # | Arquivo | Para que serve |
|---|---|---|
| 00 | `00-LEIAME.md` | Este índice, o resumo executivo e a **decisão recomendada** |
| 01 | `01-contrato-servidor-atual.md` | **Fonte da verdade** do contrato do servidor: 69 rotas, WebSocket, push, anexos/MinIO, chamadas/MediaMTX, permissões, parâmetros e 54 "pegadinhas" (as 51–54 são de cliente desktop sempre conectado). Cópia datada do doc do Android, revalidada em `779c8ed` e reescrita para Windows |
| 02 | `02-mudancas-servidor-desde-abril.md` | O que mudou no servidor desde o servidor Delphi de abril, rota por rota do que o FMX usa, com as **quebras confirmadas** (Q1–Q14) |
| 03 | `03-inventario-web.md` | As **137 funcionalidades** do web (IDs AUT/CON/MSG/ENV/ANX/PES/CHA/SIP/NOT/PRE/ATV/CFG/GER), textos de UI, WebRTC e, na §7, os **comportamentos de desktop** (atalhos, arrastar e soltar, menus, janelas, notificações). Cópia datada do doc do Android, revalidada em `e8d82cb` |
| 04 | `04-auditoria-fmx.md` | Auditoria do app FMX: estado do repositório, build, arquitetura, telas, **103 problemas** (#1–#103) com severidade e `arquivo:linha`, métricas e avaliação "evoluir × recomeçar" |
| 05 | `05-matriz-paridade.md` | As 137 funcionalidades do web × o estado no FMX, com fase e prioridade, e os **33 requisitos exclusivos do desktop** (WIN-01–WIN-33) |
| 06 | `06-fila-de-correcoes.md` | **A fila de trabalho**, priorizada e numerada (FC-xxx), com dependências e critério de pronto |
| 07 | `07-plano-nova-base.md` | Arquitetura proposta (decisões D1–D17), estrutura, componentes centrais, o que transplantar, a decisão da pilha de mídia, fases, riscos e protótipos |
| 08 | `08-pendencias-servidor.md` | Pendências **no servidor** que afetam o desktop (S1–S16 reavaliadas, **S17–S24 novas**) e achados no web (W1–W4) |
| — | `apoio/` | Os 8 relatórios de varredura (A1–A7), com todas as evidências; o doc 04 aponta o item de origem de cada problema |

Outros documentos criados com esta auditoria:

| Caminho | O que é |
|---|---|
| `docs/adr/0001-nova-base.md` | Decisão proposta de recomeçar o núcleo (status **proposto**) |
| `docs/adr/0002-midia-chamadas.md` | Decisão proposta da pilha de mídia (status **proposto**, depende do protótipo) |
| `docs/design/cores.md` | A paleta do FMX (fonte das cores do Android) e a proposta de tokens em Delphi |
| `docs/contrato/openapi.json` | OpenAPI baixado do servidor de desenvolvimento (`/api/docs/json`, 69 operações) |
| `docs/desenvolvimento/servidor-de-dev.md` | Como rodar o FMX contra o servidor de desenvolvimento |
| `docs/historico/` | Histórico de alterações (índice por fluxo + um registro por alteração) |
| `TODO.md` (raiz) | O passo a passo do trabalho, por etapas |
| `CLAUDE.md` (raiz) | Instruções para quem trabalha no repositório |

Leitura sugerida: 00 → 04 (sumário e §8) → 06 → 07, consultando 01/03 como referência durante a implementação.

---

## Resumo executivo

### 1. O tamanho da defasagem

- O FMX parou em **abril de 2026**, escrito para o servidor Delphi. Desde então, o servidor foi **reescrito duas vezes** (Delphi/Horse → Node em 13/09 → Bun + Elysia em 26/09) e recebeu 26 commits; o web ganhou dezenas de funcionalidades.
- Os **caminhos** REST foram preservados, o que dá a falsa impressão de compatibilidade. Formatos, verbos, fluxos e a infraestrutura mudaram — e em alguns pontos (upload, "visualizar") o FMX já estava atrás **antes** de abril.
- Das **137 funcionalidades** do web, o FMX tem **1** íntegra, **40** parciais, **14** quebradas, **76** inexistentes e **6** que precisam de adaptação (doc 05).

### 2. O que está quebrado contra o servidor atual (doc 02)

| # | Quebra | Efeito para o usuário |
|---|---|---|
| Q1 | `GET /anexo` devolve `{url}`; o FMX grava esse JSON como se fosse o arquivo | **Imagens e áudios recebidos não aparecem**; uma imagem interrompe a exibição das mensagens mais antigas; o cache fica envenenado |
| Q2 | Upload no contrato antigo (bytes em `PUT /anexo`, `tipo` 0, sem MinIO nem confirmação) | **Anexo enviado chega vazio** aos outros (o remetente acha que foi) |
| Q3 | `GET /mensagem/visualizar` não existe (é `POST`) | Mensagens nunca ficam "visualizadas"; contador e notificações voltam a cada reinício |
| Q4 | `GET /conversa/dados` não existe | Membros de grupo nunca carregam; chamada em grupo falha (500) |
| Q5 | Histórico de chamadas com um modelo que o servidor não devolve | Lista de chamadas vazia |
| Q6 | Mensagem "excluída" agora é **ocultada** e continua vindo com o conteúdo | O FMX **mostra o conteúdo de mensagens ocultadas** |
| Q7 | Conteúdos tipo 5–8 não existem no FMX | **Áudios gravados no web**, resumo de chamada, figurinhas e votações aparecem vazios |
| Q8 | `/mensagens/novas` com parâmetro errado (`ultima` × `desde`) | Cada mensagem nova dispara N buscas "desde sempre"; alimenta a duplicação ("Mensagem já adicionada!") |
| Q9 | WebSocket: o HEAD usa a porta do servidor Delphi; a correção *staged* depende de OpenSSL 1.0.2, ausente | **Sem tempo real** no ambiente atual |
| Q10 | *Ping* vazio do servidor derruba o leitor do WebSocket (provável) | Tempo real cai ~2 min depois de abrir o app |
| Q11 | Chamadas sem TURN e com a base de mídia errada | **Chamadas mudas** |
| Q12 | Porta de desenvolvimento mudou (4430 → 443) | Não conecta "de fábrica" ao servidor de dev |
| Q13 | Gravação de áudio como tipo 4, com extensão `.mp3` sobre WAV | Classificação e formato errados nos outros clientes |
| Q14 | `PUT /chamada/iniciar` sem `tipo` e sem `conversa_id` | Sem resumo da chamada no chat; o fim da chamada é decidido errado |

### 3. O que está quebrado no próprio app (doc 04, críticos)

- **#1 Toda chamada transmite a tela inteira do usuário**, sem aviso, inclusive as de voz e antes de atenderem — e o servidor grava. Hoje só não vaza porque a mídia não conecta.
- **#2/#3 O WebSocket nunca reconecta** e provavelmente cai ~2 min depois de abrir; a faixa de "sem conexão" existe, mas nunca aparece.
- **#4 A sessão de 12 h vence em silêncio**: o app para de atualizar sem avisar, todo dia.
- **#5 TLS do WebSocket sem validar o certificado** (e com OpenSSL 1.0.2, sem suporte desde 2019, nem distribuído).
- **#6 A senha fica salva** com uma cifra cuja chave é o número de série da placa-mãe.
- **#7/#8 *Use-after-free* no ciclo de vida da chamada** e microfone/tela que podem continuar transmitindo depois de desligar.
- **#9/#10 Anexos** quebrados nos dois sentidos; **#11** mensagem duplicada lança erro e interrompe o lote.
- **#12–#14 Mídia de chamada:** sem TURN, áudio recebido inutilizável, áudio enviado provavelmente mudo.
- **#15 Desktop × celular:** com o app desktop conectado, o servidor **não manda push para nenhum outro aparelho do usuário** (regra do servidor). Corrigir a reconexão sem tratar isso deixa o celular sem push sempre que o PC estiver ligado.
- **#16 Build não reprodutível:** o `bin/Conversa.exe` é x86 e as DLLs de mídia são x64 (provavelmente nem abre); as DLLs (133 MB) estão fora do Git; o Delphi instalado é Community e **não compila por linha de comando**.

Além disso: quase toda a rede roda **na thread da interface** (a janela congela), erros do servidor são **silenciados**, há **0 testes**, um objeto global concentra cache, regras, rede e diálogos, e o commit mais importante (`4759ba5`, +8.486 linhas) **só existe nesta máquina**.

### 4. Decisão recomendada: **recomeçar o núcleo numa nova base Delphi FMX Win64 e transplantar a interface**

Nem remendar o atual, nem descartar o visual (ADR 0001, **proposto**):

1. **As quebras de contrato atingem o núcleo inteiro** (anexos, mensagens, tempo real, chamadas, sessão); a camada de dados precisa ser refeita de qualquer forma.
2. **Os defeitos críticos estão em tudo o que tem estado ou faz E/S** (sessão, HTTP, WebSocket, cache, envio, chamada, mídia). Corrigir no lugar significa reescrever essas peças mantendo o objeto global vivo e sem testes — o padrão que já produziu três gerações sobrepostas no código.
3. **A maior parte do produto ainda não existe** (76 funcionalidades); construí-las sobre um núcleo síncrono e global multiplica o custo.
4. **O visual é bom e aproveitável:** em FMX, os *frames*, o renderizador de mensagens, o editor, as notificações e as integrações com o Windows (cerca de 35–40% do código próprio) podem ser transplantados.
5. **A pilha de mídia precisa ser trocada** (sem cancelamento de eco, áudio quebrado, FFmpeg GPLv3): a recomendação é prototipar o **WebView2 com o módulo de chamada do web** (ADR 0002, **proposto**).

**O que NÃO fazer:**
- Não distribuir o app atual a novos usuários.
- Não "religar" o `src/Conversa.Proxy.Extras.pas` achando que está pronto (código morto com contratos errados).
- Não corrigir a reconexão do WebSocket sem tratar o #15 (D13 do doc 07).

**Enquanto a nova base não substitui o app atual,** o doc 06 traz um pacote opcional de remendos (Bloco B), só se alguém depende do app no dia a dia.

### 5. O que depende de você antes de começar

| # | Decisão | Recomendação |
|---|---|---|
| 1 | **Aceitar o ADR 0001** (recomeçar o núcleo, transplantar a interface; branch `nova-base`; código atual em `legado/`) | Aceitar |
| 2 | **Como compilar e testar:** o Delphi desta máquina é **12.1 Community**, sem compilação por linha de comando (o MSBuild sai com código 0 sem compilar). Sem licença Professional ou superior (ou um fluxo de build pelo IDE combinado), **não consigo compilar nem rodar testes** para executar o `TODO.md` de forma autônoma, como foi feito no Android | Licença com linha de comando; a licença Community também restringe uso comercial (avaliar) |
| 3 | **Senha:** não guardar (login uma vez por dia até o servidor ter *refresh token*) ou "Manter conectado" com DPAPI | Não guardar; pedir o S13 no servidor |
| 4 | **Desktop × celular:** fechar o WebSocket ao bloquear a sessão, ao suspender e depois de N minutos ocioso, enquanto o servidor não tem S2/S18 | Sim, N = 10 min configurável |
| 5 | **Publicar o `4759ba5`** (`git push` da `chamada`) e as branches/tags de preservação | Fazer já |
| 6 | **Pilha de mídia** (ADR 0002): autorizar o protótipo da opção A (precisa de uma rota de "chamada embutida" no `conversa-web`) | Autorizar |
| 7 | **Abrir as pendências no servidor** (S2/S18, S13, S4, S20…) e no web (W1, a pesquisa com `v-html` sem escapar) | Abrir |
| 8 | Fonte proprietário da Embarcadero no histórico público (`FMX.Platform.Win.pas`, 2024) | Decidir se reescreve o histórico |

### 6. Arquitetura-alvo (detalhe no doc 07)

- **App:** Delphi 12 FMX, **Win64**, Windows 10+; camadas `dominio`/`contrato`/`infra`/`aplicacao`/`ui`; interfaces e composição manual; barramento tipado com entrega na thread principal; *ViewModels* sem E/S.
- **Infra:** `THTTPClient` (WinHTTP) tipado; **WebSocket do WinHTTP** com reconexão, geração e *ping*; **SQLite** (FireDAC); token com **DPAPI**; anexos por URL assinada com cache validado; *logger* com redação; integração com o Windows (bandeja, contador, toast, instância única, energia/sessão).
- **Chamadas:** gerenciador com máquina de estados (dono único) + `IMidiaChamada` (opção A: WebView2 com o módulo do web).
- **Qualidade:** DUnitX; *scripts* de build que conferem o resultado; instalador por usuário assinado.

### 7. Dependências do servidor (detalhe no doc 08)

- **S2 + S18 — push e presença com o desktop conectado** (bloqueante): o servidor suprime o push de todos os aparelhos quando há qualquer WebSocket aberto.
- **S13 — renovação de sessão** (bloqueante para o desktop, que fica aberto mais de 12 h todo dia).
- **S4 — autenticação no MediaMTX** (agravada pela tela compartilhada) e **S20 — validar o identificador de anexo**.
- **S17 — eventos para as outras conexões do próprio usuário**, **S19 — recusa por tempo por um aparelho só**, **S22 — WS 2 sem duplicar**, **S23 — uma publicação por usuário**.

---

## Glossário rápido

- **WHIP/WHEP:** protocolos HTTP para publicar e assistir mídia WebRTC no MediaMTX (`/webrtc/call-<chamada>-u-<usuario>/whip|whep`).
- **"Ocultar":** o antigo "excluir mensagem". A mensagem fica com `excluida_em`, aparece como "Mensagem oculta", e o conteúdo continua disponível para revelar.
- **Atividades:** reações, respostas, menções e chamadas perdidas dirigidas ao usuário, com contador de novas (WS 61).
- **Sinal da chamada (WS 57):** mensagens efêmeras entre os participantes (tela compartilhada, ponteiro, chat da chamada).
- **DPAPI:** proteção de dados do Windows (`CryptProtectData`), por usuário: o arquivo só é lido pelo mesmo usuário na mesma máquina.
- **WebView2:** o motor do Edge embutido num app Windows (no FMX, `TWebBrowser` em modo Edge).
- **FC-xxx:** item da fila (doc 06). **#n:** problema da auditoria do FMX (doc 04). **Qn:** quebra contra o servidor (doc 02). **Sn:** pendência do servidor (doc 08). **WIN-nn:** requisito exclusivo do desktop (doc 05). **AUT-01 etc.:** funcionalidade do web (doc 03).
