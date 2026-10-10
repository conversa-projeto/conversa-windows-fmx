# 08 — Pendências no servidor (`conversa`) que afetam o cliente Windows

**Data:** 2026-10-08 · **Servidor lido:** `conversa` em `779c8ed` · **Origem:** relatórios `apoio/A3` (§8), `apoio/A4` (§10), `apoio/A7` (§4) e a lista S1–S16 da auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/08-pendencias-servidor.md`).

> **Nenhuma alteração foi feita no servidor.** Esta lista serve para planejar o trabalho no repositório `conversa`.
>
> **Numeração compartilhada:** S1–S16 são as pendências já abertas pela auditoria do Android (mesmos números, para não duplicar). Esta auditoria acrescenta **S17–S24** e reavalia as anteriores do ponto de vista de um cliente desktop que **fica conectado o dia todo**. As novas também valem para o Android e devem ser copiadas para o doc 08 de lá (pendência registrada no `TODO.md`, etapa 0.6).
>
> **Bloqueante** = impede uma funcionalidade P0 do desktop ou torna a correção de um P0 do cliente prejudicial a outro cliente.

---

## 1. As pendências do Android (S1–S16) vistas do desktop

| S | Tema | Situação no servidor | Impacto no desktop | Prioridade para o desktop |
|---|---|---|---|---|
| S1 | Push de chamada | Não existe; chamada só por WS 51 | O desktop não usa FCM: com o app aberto (na bandeja) ele toca pelo WS; com o app **fechado** não há como tocar em nenhum desktop. Afeta o desktop indiretamente: sem S1, o **celular** do usuário não toca, e o desktop vira o único aparelho que avisa | Média |
| **S2** | Entrega do push de mensagem (por usuário × por aparelho; `android.priority`) | `notificacoes.ts:71` suprime o push se o usuário tiver **qualquer** WebSocket aberto (`websocket.ts:131-133`) | **Bloqueante.** Um desktop sempre conectado (bandeja, tela bloqueada, de noite no escritório, até com o JWT vencido) faz o celular e o web em segundo plano **não receberem push nenhum**. Hoje é mascarado porque o WebSocket do FMX cai e não volta (doc 04 #2/#3); corrigir a reconexão sem S2 piora o celular. Ver §2 | **Alta (bloqueante)** |
| S3 | Eventos e push sem contexto (`conversa_id`, `mensagem_id`) | WS 2 = `{titulo, mensagem}` | O desktop precisa de `GET /mensagens/novas` a cada WS 2 para saber de onde veio; o WS 2 chega **duplicado** (um por aparelho com `token_fcm` do destinatário — ver S22) | Média |
| **S4** | Segurança: `GET /anexo` sem checar participação; **MediaMTX sem autenticação**; `mensagem_referencia` sem checar acesso | Igual ao Android | **Agravado no desktop:** o FMX atual publica a **tela inteira** em toda chamada (doc 04 #1), num caminho previsível (`call-<id>-u-<uid>`) que qualquer usuário logado pode assistir. Mesmo depois de corrigir o #1, compartilhar tela é um recurso do desktop (CHA-02/CHA-15) | **Alta** |
| S5 | Figurinhas não servidas | `bin/web` sem `figurinhas/` | O desktop embute os 24 JSON (como o Android) | Baixa |
| S6 | `DELETE /conversa` quebra (FK) | 500 | O FMX tem o método (morto); não usar | Baixa |
| S7 | Erros 500 com texto do Postgres | Tamanhos e duplicidades sem tratamento | O desktop precisa adivinhar ("E-mail já cadastrado"); `versao_so`/`plataforma` acima de 15 caracteres → 500 (o FMX respeita hoje) | Média |
| S8 | Criação de conversa não atômica | `PUT /conversa` + N × `PUT /conversa/usuario` | O FMX já deixa grupos órfãos quando um membro falha (doc 04 #60) | Média |
| S9 | Visualizar uma mensagem por vez | `POST /mensagem/visualizar {conversa, mensagem}` | Uma conversa com 200 não lidas gera 200 requisições | Média |
| S10 | Descobrir recursos (transcrição, SIP, gravação, versão da API) | Não existe | O desktop esconderia "Transcrever" e "Ramal" sem precisar errar antes | Baixa |
| S11 | `tipo` da chamada ambíguo; criador precisa se incluir; sem WS 52 ao terminar por saídas | Igual | O FMX decide o fim da chamada pelo tipo e erra (doc 04 #62); grupo só com o criador → 500 | Média |
| S12 | OpenAPI sem esquemas de resposta; sem CHANGELOG da API | O `/api/docs/json` vivo já declara `additionalProperties:false` em 17 corpos | Os DTOs do desktop são escritos à mão (como no Android) | Média |
| **S13** | JWT de 12 h sem renovação | `exp: '12h'`, sem *refresh* nem *logout* | **Bloqueante no desktop:** o app fica aberto mais de 12 h **todo dia**. Sem *refresh token*, o desktop precisa guardar a senha (DPAPI) para relogar sozinho ou pedir login diariamente. Hoje o FMX salva a senha de forma insegura (doc 04 #6) | **Alta** |
| S14 | Limite de login por IP | `limit_req` 10/min + rajada 5 (`bin/nginx/nginx.conf:74`, `:97-100`) | **Em desenvolvimento, todos os clientes chegam com o IP do gateway do Docker** (`nginx.conf:26-31`): um desktop relogando em laço bloqueia o login de todos. A resposta é 503 em HTML | Média |
| S15 | Remover participante do grupo | Só o próprio vínculo | Igual ao Android | Baixa |
| S16 | Prévia sem o tipo do conteúdo (`ultima_mensagem_texto` vazio para arquivo/áudio/chamada; não lista `"enquete"`) | Igual | Igual ao Android | Baixa |

---

## 2. Novas pendências (S17–S24)

### S17 · Eventos para as **outras** conexões do próprio usuário

- **Hoje:**
  - `POST /mensagem/visualizar` avisa só os **outros** membros (`conversa/src/mensagens.ts:632` → `conversa/src/notificacoes.ts:43-49`, que exclui o próprio usuário);
  - o WS 2 de uma mensagem vai aos outros membros (`notificacoes.ts:56-66`, `cu.usuario_id <> remetente`);
  - a reação (WS 7) vai só aos outros (`mensagens.ts:761-765`);
  - fixar e arquivar não geram evento.
  - **Exceção:** a enquete (WS 62) vai a todos, inclusive a si.
- **Efeito:** ler no celular **não apaga** a notificação nem o contador do desktop; uma mensagem enviada pelo celular não aparece no desktop até outro evento forçar a busca; fixar/arquivar no web não muda o desktop até recarregar `/conversas`.
- **Proposta:** enviar WS 3 também às **outras** conexões de quem marcou a leitura, e WS 2/WS 7 às outras conexões do remetente; um evento de "conversa alterada" (pode ser o 40) para fixar/arquivar. Os clientes já recarregam por esses eventos.

### S18 · Presença ativa por conexão ("ausente")

- **Hoje:** não existe "ausente" nem "visto por último" (doc 01 §15.1). Uma conexão aberta = online, e o push dos outros aparelhos é suprimido (S2).
- **Efeito:** com o desktop na bandeja e o usuário longe, ele aparece online o dia todo e o celular fica mudo.
- **Proposta (complementa S2):** uma mensagem cliente → servidor, por exemplo `{tipo:63, ativo:true|false}`, que o desktop manda depois de N minutos sem entrada (`GetLastInputInfo`), ao bloquear a sessão (`WTS_SESSION_LOCK`) e ao suspender. Uma conexão "inativa" não conta para suprimir push e pode aparecer como "ausente" no WS 60.
- **Enquanto não existir:** o cliente desktop fecha o socket nessas situações e mantém *polling* REST (doc 04 #15). É um paliativo: o usuário fica sem tempo real no PC enquanto está longe, o que é aceitável.

### S19 · Recusa automática por um aparelho só

- **Hoje:** o temporizador de 30 s de **cada** cliente que está tocando chama `POST /chamada/recusar {nao_atendeu:true}`; o primeiro a vencer marca o participante como "recusou" e manda WS 53 a si mesmo (`conversa/src/chamadas.ts:164-197`), e todos os aparelhos param de tocar.
- **Efeito:** um desktop sem ninguém na frente "recusa" a chamada por todos os aparelhos do usuário depois de 30 s, mesmo que o celular ainda pudesse ser atendido.
- **Proposta:** a recusa por tempo (`nao_atendeu`) de um aparelho não encerra o toque dos outros enquanto algum ainda estiver tocando; ou o servidor controla o tempo de toque (ex.: 45 s) e manda o "perdida" uma vez.

### S20 · Validar o identificador nos conteúdos de anexo (tipos 2/3/4/5)

- **Hoje:** `PUT /mensagem` só valida o `conteudo` da figurinha (tipo 7, `conversa/src/mensagens.ts:179-181`). Para anexos, aceita qualquer texto.
- **Efeito:** um cliente malicioso manda `conteudo = ..\..\..\<caminho>`; um cliente que usa o identificador como nome de arquivo (o FMX atual, doc 04 #26) cria pastas e arquivos fora do cache.
- **Proposta:** exigir o formato do identificador (`^[0-9a-f]{64}$`) e que o anexo exista (o servidor já omite o conteúdo sem registro em `anexo`, doc 01 §19.19 — validar na entrada é melhor). Os clientes validam de qualquer jeito (defesa em profundidade).

### S21 · Opções explícitas de *keepalive* do WebSocket

- **Hoje:** `Elysia().ws('/ws/', { message, close })` sem `idleTimeout` nem `sendPings` (`conversa/src/websocket.ts:56`); valem os padrões do Bun (pela documentação: 120 s ocioso e *pings* automáticos de carga vazia — **não confirmado no código**). O nginx tem 3600 s em `/ws/`.
- **Efeito:** clientes com implementação própria de WebSocket (o Bird do FMX, doc 04 #3) quebram com o *ping* vazio; o comportamento depende da versão do Bun.
- **Proposta:** declarar `idleTimeout` e `sendPings` no código e documentar no contrato (doc 01 §6.7); opcionalmente um *ping* de aplicação (ex.: `{tipo:64}` → `{tipo:65}`) para clientes que não tratam quadros de controle.

### S22 · WS 2 uma vez por conexão

- **Hoje:** `notificarNovaMensagemConversa` percorre usuário × `token_fcm` distinto e chama `notificarNovaMensagem` em cada linha (`conversa/src/notificacoes.ts:56-69`): quem tem N aparelhos com token recebe **N cópias do WS 2 em cada conexão**.
- **Efeito:** buscas duplicadas e, no FMX atual, o diálogo "Mensagem já adicionada!" (doc 04 #11); som e notificação podem repetir.
- **Proposta:** separar o laço do evento (por usuário distinto) do laço do push (por dispositivo); incluir `conversa_id` e `mensagem_id` (S3) para deduplicar.

### S23 · Uma publicação por usuário em cada chamada (`overridePublisher`)

- **Hoje:** o caminho de mídia é `call-<chamada>-u-<usuario>`; o MediaMTX usa o padrão `overridePublisher: yes` (não sobrescrito em `bin/mediamtx/mediamtx.docker.yml`).
- **Efeito:** se o usuário atende num aparelho e depois publica de outro (o FMX atual ignora o "atendida em outro aparelho", doc 04 #30), o segundo **derruba a mídia** do primeiro.
- **Proposta:** documentar no contrato que só um aparelho do usuário publica por chamada (o servidor já manda WS 54 a si mesmo); opcionalmente recusar `/chamada/entrar` repetido do mesmo usuário enquanto ele estiver "Entrou" em outro aparelho, ou incluir o dispositivo no caminho.

### S24 · Onde o desktop descobre a versão nova (atualização automática)

- **Hoje:** o servidor não expõe a versão do cliente desktop nem um lugar para baixar o instalador.
- **Proposta:** um arquivo estático servido pelo nginx (ex.: `/downloads/windows/versao.json` com versão, URL do instalador e *hash*), ou um campo em `/api/recursos` (S10). Necessário para WIN-19 (doc 05). Baixa prioridade.

---

## 3. Achados no cliente web durante a revalidação (para o repositório `conversa-web`)

Encontrados de passagem ao conferir o doc 03 (relatório `apoio/A7` §0 e §2.2). Não afetam o FMX, mas valem uma *issue* no web:

| # | Achado | Evidência | Risco |
|---|---|---|---|
| W1 | A pesquisa global destaca o termo com `v-html` **sem escapar** o texto da mensagem (`destacarTermo` só escapa o termo para a regex) | `conversa-web/src/components/PesquisaAvancada.vue:50`, `:103-108` | XSS armazenado: uma mensagem com HTML é renderizada na pesquisa de quem buscar um termo que ela contém |
| W2 | O logout não apaga os rascunhos do IndexedDB (`conversa-rascunhos`) | `conversa-web/src/services/rascunhos.ts`; `App.vue:688-698` | Num computador compartilhado, o próximo usuário do navegador pode ver o rascunho do anterior (a chave inclui o id do usuário, mas os dados ficam no disco) |
| W3 | O web nunca chama `POST /anexo/confirmar` (o upload termina no PUT da URL assinada; a confirmação fica para a tarefa `VerificacaoAnexos` do servidor ou para o primeiro `GET /anexo`) | Nenhuma ocorrência em `conversa-web/src/` | Funcional; o desktop deve chamar o confirmar, como recomenda o contrato |
| W4 | Textos sem acento em várias telas ("Conexao em tempo real indisponivel", "Nao informado", "Configuracoes", "Gravacao de audio", "video") | `conversa-web/src/App.vue:21`; `UserInfoModal.vue`; `ProfileSettingsModal.vue`; `stores/chat.ts:975` | Cosmético; o desktop usa a forma acentuada (doc 03 §6) |

---

## 4. Prioridade sugerida no servidor (visão do desktop)

| Ordem | Itens | Por quê |
|---|---|---|
| 1 | **S2 + S18** | Sem isso, consertar o tempo real do desktop deixa o celular sem push. É a dependência que define como o desktop se conecta |
| 2 | **S13** | O desktop fica aberto mais de 12 h todo dia; sem *refresh token*, ou guarda a senha ou pede login diariamente |
| 3 | **S4** (MediaMTX com autenticação) + **S20** | Privacidade e segurança (tela compartilhada, anexos) |
| 4 | S17, S19, S22, S23 | Coerência entre aparelhos do mesmo usuário |
| 5 | S21, S3, S7, S8, S9, S11 | Robustez para todos os clientes |
| 6 | S1, S5, S6, S10, S12, S14, S15, S16, S24 | Higiene e evolução |
