# TODO — Cliente Windows Conversa (Delphi 12 / FireMonkey)

> **Como usar:** cada linha é **uma ação concreta**, pequena (de 5 min a 2 h), que dá para marcar como feita.
> **Ao concluir:** marcar `[x]` **assim que terminar o item** e, quando houver, anotar o commit ao lado (`✔ abc1234`).
> As linhas **Teste:** provam que a seção terminou. Só passe para a seção seguinte com elas marcadas.
> Itens bloqueados: deixar `[ ]` e acrescentar `⛔ motivo` na mesma linha.
> **Referências:**
> - `FC-xxx` = item da fila (`docs/auditoria-2026-10/06-fila-de-correcoes.md`)
> - `#n` = problema da auditoria do FMX (`04`)
> - `Qn` = quebra contra o servidor (`02` §10)
> - `§x` = contrato do servidor (`01`)
> - `AUT-01` etc. = funcionalidade do web (`03`/`05`); `WIN-nn` = requisito do desktop (`05`)
> - `Sn` = pendência do servidor (`08`); `Dn` = decisão do plano (`07` §1)
>
> **Ordem:** seguir as etapas na ordem. Dentro de cada etapa, a ordem das linhas é a sugerida.
> **Estado em 2026-10-08:** auditoria concluída (docs 00–08, ADRs propostos). **Nada de código foi alterado.** As etapas 1 em diante dependem do ADR 0001 aceito e de conseguir compilar (0.1 e 0.4).

---

## Etapa 0 — Decisões, preservação e preparação do repositório

### 0.1 Decisões do responsável (FC-001)
- [ ] Ler `docs/auditoria-2026-10/00-LEIAME.md` (resumo e §5 "O que depende de você")
- [ ] Decidir o ADR 0001 (recomeçar o núcleo, transplantar a interface); se aceito, mudar o status para "aceito" em `docs/adr/0001-nova-base.md`
- [ ] Decidir a **senha** (D11): não guardar (recomendado) ou "Manter conectado" com DPAPI; registrar no ADR 0001
- [ ] Decidir **desktop × celular** (D13): fechar o WebSocket ao bloquear/suspender/ocioso (recomendado, N = 10 min); registrar no ADR 0001
- [ ] Decidir **como compilar e testar** (D16): licença com compilação por linha de comando (Professional ou superior) ou fluxo pelo IDE; registrar no histórico
- [ ] Decidir o nome da branch da nova base (proposta: `nova-base`) e a estrutura (`legado/` + `app/`, `core/`, `ui/`, `midia/`, `testes/`, `build/`)
- [ ] Registrar as decisões em `docs/historico/` (fluxo "Planejamento e documentação")
- [ ] **Teste:** ADR 0001 com status "aceito" (ou "recusado", com o motivo e o novo rumo)

### 0.2 Salvar tudo o que existe (FC-002)
- [ ] Conferir em que branch estou: `git branch --show-current` (deve ser `chamada`)
- [ ] Ver o que está pendente: `git status` (esperado: *staged* em `Conversa.Dados.pas` e `src/chamada/Conversa.Chamada.WebRTC.pas`; não rastreados: DLLs em `bin/` e `docs/todo.md`; os docs da auditoria já foram commitados em `6d53c23`)
- [ ] Commitar **só** as alterações *staged* num commit próprio: `git commit -m "Usa wss://host/ws/ no WebSocket (servidor atual) e atualiza o cabeçalho do WebRTC"` (elas compilaram no IDE em 2026-06-27; doc 04 §1.2)
- [ ] Criar a branch de preservação nesse commit: `git branch legado/abril-2026 HEAD`
- [ ] Criar a tag anotada: `git tag -a legado-v1-final legado/abril-2026 -m "Estado final do app FMX antes da nova base"`
- [ ] Criar a pasta: `mkdir -p docs/legado/stashes`
- [ ] Listar os *stashes*: `git stash list` (esperado: **27**)
- [ ] Guardar cada *stash* sem perda numa tag: `git tag legado/stash-NN stash@{N}` (00…26)
- [ ] Exportar cada *stash* como patch de texto, sem binários (`*.dll`, `*.exe`, `*.dcu`, `*.res`, imagens): `docs/legado/stashes/NN.patch`
- [ ] Conferir os patches: sem senhas, tokens nem chaves (os *stashes* `{11}`/`{12}`/`{14}` têm logs e marcador do Syncthing — conferir)
- [ ] Guardar o commit exclusivo da `alteracao-base` (`a8dcfe8`): `git tag legado/alteracao-base a8dcfe8`
- [ ] **Teste:** 27 patches na pasta, 27 tags `legado/stash-*`, tag `legado/alteracao-base`, `git status` sem nada *staged*

### 0.3 Publicar (FC-003)
- [ ] Enviar `chamada` (inclui o `4759ba5`, +8.486 linhas, que **só existe nesta máquina**, e os commits da auditoria a partir do `6d53c23`), `legado/abril-2026`, `legado-v1-final`, `legado/alteracao-base` e as tags dos *stashes* ⛔ o push é feito pelo responsável:
  `git push origin chamada legado/abril-2026 legado-v1-final legado/alteracao-base` e `git push origin "refs/tags/legado/stash-*"`
- [ ] Decidir se a `main` avança para a `chamada` (o branch padrão do GitHub está 14 meses atrás) ⛔ decisão do responsável
- [ ] **Teste:** branch e tags aparecem no GitHub

### 0.4 Build (FC-001, D16, #16)
- [ ] Registrar a edição do Delphi em uso (hoje: 12.1 Athens Community, sem linha de comando) e a decisão de 0.1
- [ ] Se houver licença com linha de comando: rodar `msbuild Conversa.dproj /t:Build /p:Config=Debug /p:Platform=Win64` e conferir o exe e o log (o código de saída não basta)
- [ ] Se não houver: testar `bds.exe -b` numa **cópia** do repositório (pode regravar o `.dproj`) e registrar se funciona ⛔ precisa de autorização para abrir o IDE
- [ ] Montar a `bin/` do legado em Win64 (doc `desenvolvimento/servidor-de-dev.md` §5): `pion_whep.dll`, FFmpeg 8.x x64, `sk4d.dll` x64 de `Studio\23.0\bin64`, `bin/tema/default.pss`
- [ ] Anotar a versão e o SHA-256 de cada DLL em `docs/desenvolvimento/servidor-de-dev.md`
- [ ] **Teste:** um exe Win64 do legado abre e faz login no servidor de desenvolvimento (`https://localhost/api/`) ⛔ teste de interface feito pelo responsável

### 0.5 `.gitignore` (FC-004)
- [ ] Acrescentar `*.dll` (exceções explícitas só para o que for decidido versionar)
- [ ] Acrescentar `bin/Conversa/`, `bin/clipboard/`, `bin/dcu/`, `bin/dcp/`
- [ ] Acrescentar `Android64/`, `Win32/`, `Win64/`, `__astcache/`
- [ ] Acrescentar `*.log`, `log.txt`, `.claude/`, `*.deployproj`, `Serializer/`
- [ ] Liberar a documentação: `!docs/**/*.json` e `!docs/**/*.png` (hoje o `docs/contrato/openapi.json` está ignorado)
- [ ] Limpar o `conversa-webrtc/.gitignore` (copiado de outro projeto: regras `LOJAS/MD006/…`)
- [ ] **Teste:** `git status` mostra só o que deve ser versionado; `git check-ignore docs/contrato/openapi.json` não acusa nada

### 0.6 Documentação (FC-005, FC-006, FC-007)
- [ ] Mover para `docs/legado/` (com `git mv`): `docs/ALTERACOES_TCP_RECONEXAO.md`, `docs/waveform-spec.md`, `src/notificacao/refatoracao_notificacao.md`, `conversa-webrtc/whep-viewer-spec.md`
- [ ] Mover `docs/todo.md` (não versionado) para `docs/legado/revisao-docs-2026-06.md` e versionar
- [ ] Criar `docs/legado/LEIA.md` (aviso de desatualizado + mapa dos *stashes* com data e branch de origem + onde está o código legado)
- [ ] Reescrever o `README.md`: o que é o app, "em reescrita" (se o ADR for aceito), links para os docs, ecossistema (servidor, web, Android Kotlin)
- [ ] README → "Como compilar" (Delphi 12, Win64, dependências, licença)
- [ ] README → "Servidor de desenvolvimento" (`https://localhost`, mkcert, link para `docs/desenvolvimento/servidor-de-dev.md`)
- [x] Commitar a auditoria: `docs: auditoria de 2026-10 (docs 00–08, apoio, ADRs, cores, contrato), histórico, CLAUDE.md e TODO` ✔ 6d53c23 (antecipado a pedido do responsável, antes da 0.2; o *staged* ficou intacto; `openapi.json` com `git add -f` até a 0.5)
- [x] Preencher os hashes no histórico (commit seguinte) ✔ commit seguinte ao 6d53c23 (`docs: hash da auditoria no histórico e no TODO`)
- [ ] **Teste:** nenhum doc antigo fora de `docs/legado/`; um clone limpo, seguindo o README, sabe como compilar

### 0.7 Protótipo de tempo real (doc 07 §10, D9)
- [ ] Projeto descartável `ferramentas/prototipo-ws` (console Win64): WebSocket do WinHTTP (`WinHttpWebSocketCompleteUpgrade`)
- [ ] Conectar em `wss://localhost/ws/` (a CA do mkcert já está no repositório do usuário nesta máquina)
- [ ] Login: `POST https://localhost/api/login` com `teste.android.a` (senha em `../conversa-android-kotlin/docs/desenvolvimento/emulador.md`); logar **só o tamanho** do token
- [ ] Enviar `{"tipo":1,"token":"…"}` (`tipo` como número JSON)
- [ ] Mandar uma mensagem pelo web (usuário B) e conferir o WS 2 no console
- [ ] Ficar 5 minutos ocioso (*ping*) e conferir que a conexão continua
- [ ] `docker restart api` e conferir que o protótipo reconecta com *backoff*
- [ ] Anotar: tempo de conexão, comportamento do *ping*, erros; registrar no histórico
- [ ] **Teste:** WS 2 recebido depois de 5 minutos ocioso e depois de reiniciar a API ⛔ depende de 0.4 (compilar)

### 0.8 Protótipo da mídia de chamada (FC-700, ADR 0002)
- [ ] Combinar com o web uma rota de "chamada embutida" (página só com o módulo de chamada de `src/stores/call.ts`, recebendo token e chamada) ⛔ mudança no `conversa-web`, com aprovação
- [ ] Protótipo FMX: janela com `TWebBrowser` em modo Edge (WebView2) carregando a página
- [ ] Conceder microfone e câmera à própria origem sem aviso (API de permissões do WebView2) — conferir no FMX do Delphi 12
- [ ] Ponte JS ↔ Delphi: iniciar/atender/sair, estado (chamando, em chamada, encerrando), erro
- [ ] Chamada FMX ↔ web (Chrome de teste) em áudio, via TURN
- [ ] Testar com alto-falante: o outro lado **não** pode ouvir eco
- [ ] Vídeo da câmera nos dois sentidos
- [ ] Conferir a gravação no MediaMTX (`docker run --rm -v conversa-gravacoes:/g:ro alpine ls -R /g`)
- [ ] Se A falhar: protótipo da opção B (libwebrtc) e registrar o motivo
- [ ] Escrever o resultado no ADR 0002 e mudar o status
- [ ] **Teste:** os 6 critérios do ADR 0002 passam

### 0.9 Pedidos ao servidor e ao web (doc 08) — ⛔ abrir *issues* depende de aprovação do responsável
- [ ] S2 + S18 — push e presença por aparelho; sinal de "ausente" do desktop
- [ ] S13 — *refresh token*
- [ ] S4 — autenticação no MediaMTX; checar participação em `GET /anexo` e em `mensagem_referencia`
- [ ] S20 — validar o identificador nos conteúdos de anexo
- [ ] S17, S19, S22, S23 — coerência entre aparelhos do mesmo usuário
- [ ] S21 — opções explícitas de *keepalive* do WebSocket
- [ ] S24 — onde publicar a versão do desktop
- [ ] Web: W1 (pesquisa com `v-html` sem escapar), W2 (rascunhos depois do logout), W4 (acentos)
- [ ] Copiar S17–S24 para o doc 08 do Android (`conversa-android-kotlin/docs/auditoria-2026-10/08-pendencias-servidor.md`) ⛔ outro repositório: com autorização

### 0.10 Limpeza do histórico (FC-008) — ⛔ só com autorização
- [ ] Apagar as branches `keen-buck` e `vigorous-lichterman` (já contidas na `chamada`)
- [ ] Apagar a `alteracao-base` (depois da tag do 0.2)
- [ ] `git gc` (2.795 objetos soltos)
- [ ] Decidir sobre o fonte proprietário `src/fmx/FMX.Platform.Win.pas` no histórico público (#94)
- [ ] Apagar do disco os restos ignorados (`Android64/` 211 MB, `.dcu`/`.o` espalhados 57 MB, `Serializer/`, `api/`, `bin/bin-2/`, `bin/dcp/`) — a critério do responsável (`__history/` são cópias de segurança do IDE)

---

## Etapa 1 — Fundação da nova base

> Depende do ADR 0001 aceito (0.1) e de conseguir compilar (0.4). Detalhe de arquitetura no doc 07.

### 1.1 Projeto (FC-100)
- [ ] Criar a branch `nova-base` a partir da `chamada` (depois da Etapa 0)
- [ ] Mover o app atual para `legado/` com `git mv` (fonte, `.fmx`, `lib/`, `src/`, `conversa-webrtc/`, `.dproj`/`.dpr`), fora do build
- [ ] Criar `app/Conversa.dpr` + `app/Conversa.dproj`: FMX, **só Win64**, Windows 10 1809+
- [ ] Manifesto próprio: PerMonitorV2, `asInvoker`, `supportedOS` do Windows 10/11, nome e descrição
- [ ] Saída por `$(Platform)\$(Config)` (`bin\Win64\Debug`, `bin\Win64\Release`), `.dcu` em pasta própria
- [ ] *PreBuild* sem `taskkill`
- [ ] Versão automática (data/tag) e *locale* pt-BR (1046) no VersionInfo
- [ ] **Teste:** compila e abre uma janela vazia; o exe mostra a versão certa

### 1.2 Estrutura (FC-101)
- [ ] Criar as pastas `core/dominio`, `core/contrato`, `core/infra/{http,tempo-real,banco,sessao,anexos,windows,log}`, `core/aplicacao`, `core/eventos`, `ui/`, `midia/`, `testes/`, `build/`
- [ ] Convenção de nomes de units (`Conversa.Dominio.*`, `Conversa.Contrato.*`, `Conversa.Infra.*`, `Conversa.Aplicacao.*`, `Conversa.UI.*`)
- [ ] **Teste:** nenhuma unit de `core/dominio` e `core/aplicacao` usa `FMX.*` nem `System.Net.*` (conferir os `uses`)

### 1.3 Build e testes (FC-102)
- [ ] Projeto DUnitX em `testes/ConversaTestes.dproj` (Win64, console)
- [ ] TestInsight no IDE (opcional)
- [ ] `build/compilar.cmd`: `rsvars` + `msbuild` Win64 Debug/Release; confere a data do exe e procura `error`/`Fatal` no log (não confia no código de saída)
- [ ] `build/testar.cmd`: compila e roda os testes, devolvendo erro se algum falhar
- [ ] **Teste:** os testes rodam (linha de comando ou IDE, conforme 0.4) ⛔ depende de 0.4

### 1.4 Barramento de eventos (FC-103)
- [ ] `TBarramento`: assinar por tipo, publicar de qualquer thread, entregar na thread principal (fila)
- [ ] Assinatura devolve `IInterface` (cancela ao liberar)
- [ ] Exceção num assinante não impede os outros (vai para o *logger*)
- [ ] "Último valor" para estados (quem assina depois recebe o atual)
- [ ] **Teste:** testes de ordem, cancelamento, exceção e publicação de outra thread

### 1.5 Design (FC-104)
- [ ] `ui/Conversa.Cores.pas` com os tokens de `docs/design/cores.md` §7 (claro; escuro como proposta, desligado)
- [ ] `ui/Conversa.Textos.pas` (`resourcestring`): textos do web acentuados (doc 03 §6)
- [ ] Componente `Avatar` (foto; senão a inicial pelo primeiro grafema; cor estável por id) (GER-07)
- [ ] `DialogoConfirmacao` (título, mensagem, Cancelar/OK; variante perigo com foco em Cancelar; Esc/Enter) (GER-03)
- [ ] `FaixaAviso` não modal com "×" para erros (GER-01)
- [ ] Estados `Carregando`, `Vazio`, `Erro` (com "Tentar de novo")
- [ ] Botões focáveis por Tab, com foco visível e `Hint` (WIN-22)
- [ ] Transplantar a barra de título própria (`legado/src/base/Conversa.FormularioBase.*`) com `SetWindowLongPtr` (#28) e as cores dos tokens
- [ ] **Teste:** tela de exemplo com todos os componentes; nenhuma cor nem texto literal fora das units de tokens e textos

### 1.6 Endereço do servidor (FC-105)
- [ ] `TEnderecoServidor`: a partir de `https://host[:porta]` derivar `api` (`/api/`), `ws` (`wss://…/ws/`) e `webrtc` (`/webrtc/`)
- [ ] Testes: `https://x` → `wss://x/ws/`; `http://x:8080` → `ws://x:8080/ws/`; barra final sempre; sem `:443`; com e sem barra no fim da entrada
- [ ] Guardar o endereço na configuração (`%APPDATA%\Conversa\configuracao.json`, gravação atômica)
- [ ] Tela "Servidor": campo "Endereço do servidor", "Testar conexão", "Salvar"
- [ ] "Testar conexão": rota protegida sem token deve dar 401 com `{error}`; mensagens para certificado não confiável, host inacessível, não é um Conversa, sem conexão
- [ ] Assistente da primeira execução; trocar de servidor = sair da conta
- [ ] **Teste:** trocar o endereço em tempo de execução muda HTTP, WebSocket e mídia sem reiniciar

### 1.7 TLS (FC-106)
- [ ] Busca no código novo: nenhum `OnValidateServerCertificate` que aceite tudo, nenhum OpenSSL
- [ ] **Teste:** conecta a `https://localhost` (CA do mkcert instalada); um certificado não confiável é recusado com mensagem clara

### 1.8 Cliente HTTP (FC-107)
- [ ] `IConversaApi` + `TConversaApi` sobre `THTTPClient` (um por serviço, reaproveitado)
- [ ] UTF-8 explícito em corpo e resposta; `Content-Type: application/json`
- [ ] *Query* montada com `TNetEncoding.URL` por parâmetro
- [ ] *Timeouts* explícitos (conexão e resposta)
- [ ] Repetição com espera só em GET e em rotas idempotentes
- [ ] `EApiErro` com status e a mensagem de `{error}`
- [ ] 401 → evento "sessão expirada" (rotas públicas marcadas não disparam)
- [ ] HTML do nginx (502/503/504/413) → "Servidor indisponível" / "Muitas tentativas. Aguarde um minuto e tente de novo." / "Arquivo grande demais"
- [ ] O token só vai para `<base>/api/` (nunca para as URLs assinadas do MinIO)
- [ ] **Teste:** servidor HTTP falso local: sucesso, 401, `{error}`, HTML 502, 503, *timeout*, JSON inválido, acentos e emoji de ida e volta

### 1.9 Modelos do contrato (FC-108)
- [ ] Atualizar `docs/contrato/openapi.json` (`GET https://localhost/api/docs/json`) e conferir as 69 operações
- [ ] *Fixtures* JSON em `testes/fixtures/` a partir do doc 01 e de respostas reais do servidor de desenvolvimento (sem dados pessoais)
- [ ] Conversor de data: ISO-8601 com `Z` → UTC; tolerante (sem `Z`, com espaço); hora local só na tela
- [ ] Conversor de id tolerante (número ou texto → `Int64`)
- [ ] DTO login: `{id, nome, email, telefone, avatar_identificador, dispositivo{…}, token}`
- [ ] DTO conversa (§11.2: `fixada_ordem`, `arquivada_em`, `mensagens_sem_visualizar`…)
- [ ] DTO mensagem (§10.2: `excluida_em`, `visivel_em`, `mensagem_referencia` recursiva e opcional, `reacoes` opcional, conteúdos 1–8 com `transcricao_*`)
- [ ] DTO conteúdo de chamada (tipo 6, datas sem fuso, §9.8)
- [ ] DTOs de status (`/mensagem/status` booleanos; `/mensagem/status/detalhe` datas)
- [ ] DTOs de anexo (`PUT /anexo` nos dois formatos; `GET /anexo` → `{url}`; `/anexos`)
- [ ] DTOs de chamada (dados; pendentes **sem `usuarios`**; histórico `ChamadaHistoricoItem`)
- [ ] DTO ICE (camelCase: `iceServers`, `iceTransportPolicy`, `urls`, `username`, `credential`)
- [ ] DTOs de atividade, permissões, parâmetros, SIP, contatos, membros
- [ ] DTO `Enquete` (com `encerra_em`, `encerrada_em`, `encerrada`, `pode_encerrar`, `pode_alterar_prazo`)
- [ ] Mapeadores DTO → domínio em `core/contrato`
- [ ] **Teste:** um teste de desserialização por DTO com *fixture*

### 1.10 Banco local (FC-109)
- [ ] Confirmar que a edição do Delphi tem o driver SQLite do FireDAC (senão, decidir a alternativa e registrar)
- [ ] Banco em `%LOCALAPPDATA%\Conversa\<usuario>\conversa.db`
- [ ] Tabelas: conversa, mensagem, conteudo, reacao, usuario, atividade, chamada_historico, envio_pendente, rascunho, cursor
- [ ] Migrações versionadas (tabela de versão)
- [ ] **Teste:** inserir e ler cada entidade (banco em memória)

### 1.11 Sessão (FC-110)
- [ ] `TSessaoDPAPI`: token, id do usuário, nome e `dispositivo_id` com `CryptProtectData` (escopo do usuário)
- [ ] `dispositivo_id` por login (mapa login → id), mantido ao sair da conta
- [ ] **Nunca** salvar a senha (salvo decisão do ADR 0001)
- [ ] Configuração gravada de forma atômica (temporário + renomear) (#92)
- [ ] **Teste:** fechar e reabrir mantém a sessão; o arquivo não tem o token em texto; outro usuário do Windows não lê a sessão

### 1.12 Tempo real (FC-111)
- [ ] `TParserEventos`: todos os tipos (0, 2, 3, 4, 5, 7, 9, 40, 51–57, 60, 61, 62) e `Desconhecido`
- [ ] Testes do parser com um *payload* real de cada tipo (§6.6)
- [ ] `TTempoRealWinHttp` numa thread própria (dona única do socket)
- [ ] Estados `Desconectado` / `Conectando` / `Autenticando` / `Conectado` / `Aguardando`
- [ ] Geração por conexão; eventos de gerações antigas descartados
- [ ] Ao abrir: `{"tipo":1,"token":…}` (número JSON); tipo 0 → "sessão expirada"
- [ ] *Ping* a cada 30 s; sem resposta em 10 s = conexão morta
- [ ] *Backoff* `min(30 s, 1 s × 2^n)` com *jitter*
- [ ] Reconectar já ao voltar de suspensão (`PBT_APMRESUMEAUTOMATIC`) e quando a rede volta
- [ ] `EnviarSinal(chamada, dados)` → `{tipo:57, chamada_id, dados}`
- [ ] Nenhum log de quadro com token ou conteúdo
- [ ] **Teste:** testes da máquina de estados; no servidor de desenvolvimento, `docker restart api` → reconecta sozinho; 5 min ocioso → continua recebendo; nunca dois sockets

### 1.13 Sincronização (FC-112)
- [ ] `TSyncManager.Ressincronizar` ao conectar e ao voltar do segundo plano
- [ ] `GET /mensagens/novas?desde=<cursor>` → buscar o que falta por conversa (referência = última salva) → banco → avançar o cursor (nunca para o futuro)
- [ ] `GET /conversas` → banco (sempre adotando `mensagens_sem_visualizar`)
- [ ] `GET /contatos/online` → presença
- [ ] `GET /atividades/novas` → contador
- [ ] `GET /chamadas/pendentes` → gerenciador de chamadas (etapa 6)
- [ ] WS 2 como gatilho com *debounce* de 300 ms; uma busca por conversa por vez (sem "Mensagem já adicionada!")
- [ ] *Polling* de 8 s (mensagens novas + pendentes) só com o socket fora
- [ ] **Teste:** desligar a rede por 2 minutos, mandar mensagens pelo web, religar → tudo aparece, sem duplicar

### 1.14 *Logger* e diagnóstico (FC-113)
- [ ] `TLogger` com fila e thread própria, níveis, rotação, em `%LOCALAPPDATA%\Conversa\logs`
- [ ] Redação por padrão (token, senha, conteúdo de mensagem)
- [ ] Exceções não tratadas registradas com a pilha
- [ ] `ReportMemoryLeaksOnShutdown` só em Debug
- [ ] **Teste:** teste de redação

### 1.15 Nada de E/S na interface (FC-114)
- [ ] Serviços assíncronos com `TCancellationToken`; *ViewModels* recebem estado só pelo barramento
- [ ] **Teste:** com um servidor que demora 30 s, a janela continua respondendo e mostra "carregando"

### 1.16 Base de janela e Windows (FC-115)
- [ ] Instância única por *mutex* `Local\Conversa-<usuário>`; a segunda instância traz a janela e repassa os argumentos (`WM_COPYDATA`)
- [ ] `RegisterWindowMessage` para as mensagens próprias (nada de `WM_USER+1` duplicado)
- [ ] Posição e tamanho da janela salvos; ao restaurar, conferir se o monitor ainda existe
- [ ] **Teste:** abrir duas vezes traz a janela existente; arrastar entre monitores com escalas diferentes mantém o tamanho certo

---

## Etapa 2 — Sessão, conversas, contatos e presença

### 2.1 Login e entrada (FC-200, AUT-01)
- [ ] Decisão de abertura: sem servidor → Servidor; sem sessão → Login; com sessão → Principal
- [ ] Tela Login (transplantar o visual de `legado/Conversa.Login.fmx`): "Usuário", "Senha", "Entrar"/"Entrando...", "Não tem conta? Criar conta", servidor atual com "Trocar"
- [ ] `POST /api/login {login, senha, dispositivo_id?}` em segundo plano; `trim()` no login
- [ ] Erro inline; 503 do nginx → "Muitas tentativas. Aguarde um minuto e tente de novo."; resposta sem token → "Resposta de login inválida: token ausente."
- [ ] **Teste:** logar, fechar o app, abrir → entra direto (pela sessão, sem senha)

### 2.2 Dispositivo (FC-201, AUT-04)
- [ ] A cada início de sessão: `PATCH /dispositivo {id, nome, modelo, versao_so, plataforma:"Windows"}` (sem `token_fcm`)
- [ ] `versao_so` por `RtlGetVersion` (≤ 15), nome do computador (≤ 50), modelo pelo WMI em segundo plano (≤ 50)
- [ ] **Teste:** conferir a linha do dispositivo no banco de desenvolvimento

### 2.3 Sessão expirada e saída (FC-202, AUT-03, AUT-05)
- [ ] 401 em qualquer lugar → limpar a sessão → Login com "Sua sessão expirou. Entre novamente."
- [ ] Outros erros na abertura mantêm a sessão e tentam de novo a cada 5 s ("… (tentando de novo...)")
- [ ] "Sair da conta": encerrar chamada, fechar o WebSocket, limpar notificações, contador, banco, cache e rascunhos do usuário; manter o `dispositivo_id`
- [ ] **Teste:** depois de sair, mensagens do web não geram notificação; invalidar o token no servidor → o app avisa e volta ao login

### 2.4 Cadastro (FC-203, AUT-02)
- [ ] Tela "Crie sua conta": Nome, Usuário, E-mail, Senha (≥ 4); limites 100/50/100
- [ ] `PUT /api/usuario {nome, login, email, senha}` (rota pública)
- [ ] E-mail duplicado (500 do Postgres, S7) → "E-mail já cadastrado."
- [ ] Sucesso → "Conta criada com sucesso!" → Login com o usuário preenchido

### 2.5 Tela principal e navegação
- [ ] Tela principal com barra lateral (transplantar `legado/src/principal/*`): Conversas, Chamadas, Atividades (contador), Configurações; avatar do usuário
- [ ] Abrir conversa por argumento/protocolo `conversa://conversa/<id>?mensagem=<id>` (sem sessão: abre depois do login)

### 2.6 Lista de conversas (FC-204, FC-205, CON-01, CON-13)
- [ ] Repositório: banco como fonte; `GET /conversas` para atualizar
- [ ] Ordem: fixadas por `fixada_ordem`, depois as demais (sem mensagem por último)
- [ ] Título: `descricao || nome || "Conversa #id"`
- [ ] Item (transplantar `legado/src/chat/Conversa.Chat.Listagem.Item.*`): avatar com bolinha (direta), título, "Grupo", alfinete, contador (oculto em arquivadas, "99+"), hora
- [ ] Prévia: porte de `resumirTexto` (`@Nome`, `Código (linguagem)`), resumo por tipo, "Sem mensagens"; nunca caminho de arquivo (#42)
- [ ] Hora: hoje `HH:mm`, "Ontem", `dd/MM/aa` — comparando a **data**, com `TFormatSettings` pt-BR (#82)
- [ ] Pontinhos de digitando na conversa
- [ ] Lista virtual (sem um *frame* por item carregado de uma vez)
- [ ] Atualizar sem *spinner* em WS 2, 3 e 40, ao enviar e ao ler; tirar da lista a conversa que o usuário deixou
- [ ] **Teste:** comparar lado a lado com o web nos casos do doc 03 CON-01

### 2.7 Filtro e "Nova conversa" (FC-206, CON-02)
- [ ] Campo "Pesquisar..." (Ctrl+F/Ctrl+K): filtra por título e prévia, sem acento e sem maiúscula
- [ ] Com termo, mostrar também as arquivadas (etiqueta "Arquivada")
- [ ] Seção "Nova conversa" com contatos sem conversa direta (só com termo digitado, como o web)

### 2.8 Menu da conversa, fixar e arquivar (FC-207, FC-208, FC-209)
- [ ] Clique direito, botão "⋯" no *hover*, Shift+F10/tecla Menu → "Fixar"/"Desafixar", "Arquivar"/"Desarquivar"
- [ ] Fixar: `PATCH /conversa/fixadas {conversas:[ids na ordem]}`, otimista, com *rollback* por `GET /conversas`
- [ ] Reordenar fixadas arrastando (linha indicadora)
- [ ] Arquivar: `PATCH /conversa/arquivada {conversa, arquivada}`; desfixar; cancelar a notificação
- [ ] Seção recolhível "Arquivadas (N)"; arquivada sem som nem notificação

### 2.9 Contatos e conversa direta (FC-210, CON-06, CON-11)
- [ ] `GET /usuario/contatos` **sem o próprio usuário**
- [ ] "Obter ou criar direta": procurar `tipo=1 && destinatario_id`; senão `PUT /conversa {descricao:"", tipo:1}` → `PUT /conversa/usuario` para mim → para o contato → `GET /conversas` → abrir
- [ ] Falha no meio → aviso + log com o id da conversa incompleta (S8)

### 2.10 Grupos (FC-211, FC-212, CON-07, CON-08)
- [ ] "Criar grupo" (transplantar o visual de `legado/src/novo/grupo/*`): "Nome do grupo", "Filtrar contatos", ≥ 1 usuário ("Selecione ao menos um usuário."), "Criar"
- [ ] `PUT /conversa {descricao, tipo:2}` → `PUT /conversa/usuario` para cada membro **e para mim** → abrir o grupo
- [ ] Painel "Dados do grupo" (avatar do grupo no cabeçalho ou "Participantes e anexos"): nome com "Renomear", participantes com bolinha e "(você)", "Adicionar pessoas", "Sair do grupo" (só o próprio vínculo, S15), anexos do grupo (etapa 8)
- [ ] Renomear: `PATCH /conversa {id, descricao}` → "Grupo renomeado com sucesso."

### 2.11 Presença e conexão (FC-213, FC-214, PRE-01, GER-02)
- [ ] `TPresenca`: `GET /contatos/online` + WS 60
- [ ] Bolinha na lista, no cabeçalho, nos contatos e no painel do grupo
- [ ] Faixa "Conexão em tempo real indisponível — usando atualização periódica" depois de 5 s desconectado, com "Tentar agora"
- [ ] **Teste:** abrir e fechar o web com outro usuário → a bolinha acende e apaga no desktop

### 2.12 Bandeja e encerramento (FC-215, WIN-03, WIN-04)
- [ ] Ícone na bandeja com menu: "Abrir Conversa", "Não perturbe" (etapa 5), "Sair do Conversa"
- [ ] Clique simples abre; dica com o número de não lidas
- [ ] X fecha para a bandeja (configurável); aviso "O Conversa continua aberto na bandeja" na primeira vez; Alt+F4 = X
- [ ] "Sair do Conversa" encerra de verdade (sai da chamada, fecha o WebSocket); `NIM_DELETE` ao sair
- [ ] Recriar o ícone no `TaskbarCreated`
- [ ] **Teste:** sair pelo menu encerra o processo e o ícone some; reiniciar o Explorer não perde o ícone

---

## Etapa 3 — Mensagens (núcleo)

### 3.1 Tela de chat (FC-300, CON-09)
- [ ] Transplantar o visual de `legado/src/chat/Conversa.Chat.*` e `legado/src/chat/chat/**`
- [ ] Cabeçalho: avatar (clique → perfil na direta, "Dados do grupo" no grupo), título, bolinha (direta), subtítulo (membros / digitando / gravando)
- [ ] Membros do grupo por `GET /conversa/usuarios?conversa=` (#23, Q4)
- [ ] Botões "Chamada de voz", "Chamada de vídeo" (etapa 6), "Pesquisar na conversa" (etapa 8), "Participantes e anexos"

### 3.2 Carregar e paginar (FC-301, MSG-01)
- [ ] Abrir: `GET /mensagens?conversa=X&mensagemreferencia=0&mensagensprevias=80&mensagensseguintes=0`
- [ ] Mostrar o banco antes da rede
- [ ] Anteriores: referência = a mais antiga **salva**, `mensagensprevias=60`; descartar a repetida; parar quando vierem menos que o pedido
- [ ] Seguintes (depois de um salto): referência = a mais nova salva, `mensagensseguintes=60`
- [ ] Uma requisição por vez por conversa e direção
- [ ] Ordem: `coalesce(visivel_em, inserida)`, depois `id`; ids negativos (enviando) no fim
- [ ] Preservar a âncora ao inserir no topo (a tela não pula, #21)
- [ ] "Carregando mensagens anteriores…"
- [ ] **Teste:** rolar até o início de uma conversa com 1.000+ mensagens sem travar nem pular

### 3.3 Classificação e bolhas (FC-302, FC-303, MSG-07)
- [ ] Modelo de mensagem completo (doc 01 §10.2)
- [ ] Porte de `classificarMensagem.ts`: oculta > chamada > imagem > enquete > figurinha > código > emoji > com referência > texto curto > padrão
- [ ] Testes copiando os casos do web
- [ ] Bolha padrão e bolha curta (≤ 60 caracteres, hora ao lado)
- [ ] Marcadores para imagem, figurinha, código e citação (preenchidos nas etapas seguintes); tipo desconhecido nunca quebra (#22)
- [ ] Marcador da votação: "📊 Votação" + "Abra a votação no web" (FC-315)

### 3.4 Mensagem oculta (FC-304, MSG-16)
- [ ] `excluida_em` → bolha "Mensagem oculta"; clique alterna revelar/ocultar (*tooltips* do web)
- [ ] Sem menu e sem reações; fora do visualizador; citação mostra "Mensagem oculta"

### 3.5 Bolha de chamada (FC-305, MSG-13)
- [ ] Ler o JSON do tipo 6 (datas sem fuso; JSON inválido → nulo)
- [ ] "Chamada de áudio"/"Chamada de vídeo" (+ " em grupo"); direta: "<remetente> · mm:ss" ou o status; grupo: participantes com duração ou status
- [ ] Cores do FMX (encerrada × recusada/perdida); sem status de entrega; clique → ligar de novo (etapa 6)

### 3.6 Separadores e hora (FC-306, MSG-02)
- [ ] "Hoje"/"Ontem"/"seg., 05/10/2026" pela data efetiva
- [ ] Grupo: primeiro nome do remetente acima das recebidas, só quando muda o remetente (#100)
- [ ] Hora `HH:mm` a partir do UTC, no fuso local

### 3.7 Enviar texto (FC-307, ENV-01)
- [ ] Mensagem otimista com id negativo e relógio, gravada no banco
- [ ] Fila de envio (`envio_pendente`) processada numa thread; `PUT /mensagem {conversa_id, conteudos:[{ordem:1, tipo:1, conteudo}]}` → trocar pelo id real
- [ ] Erro definitivo (4xx ou N erros do servidor) → "falhou" com "Reenviar"/"Apagar"; sem rede, espera
- [ ] O campo só limpa depois de gravar no banco
- [ ] Enter envia; Shift+Enter quebra; Tab = 4 espaços; placeholder "Digite uma mensagem"
- [ ] **Teste:** enviar com a API fora (`docker stop api`) → a mensagem sai sozinha quando ela volta, sem duplicar

### 3.8 Lida e status (FC-308, FC-309, MSG-04, MSG-08, MSG-10)
- [ ] Detectar mensagens de outros **totalmente** visíveis, com a janela ativa e não minimizada (#53)
- [ ] `POST /mensagem/visualizar {conversa, mensagem}` numa fila serial (lote quando houver S9)
- [ ] Descontar o contador depois do sucesso; ao zerar, fechar a notificação da conversa
- [ ] Ícone de status nas minhas: relógio → ✓ → ✓✓ → ✓✓ cor primária; ⚠ se falhou
- [ ] WS 3 → `GET /mensagem/status?conversa=&mensagem=` → aplicar só nas minhas (status agregado); `excluida_em` em todas
- [ ] Id do WS 3 que não está no banco → buscar as seguintes da conversa
- [ ] **Teste:** ler no web → o ✓✓ do desktop muda sem recarregar; ler no desktop → o web mostra "Visualizada"

### 3.9 "Últimas", botões de rolagem e *links* (FC-310, FC-311, MSG-03, MSG-05, MSG-11)
- [ ] Linha "Últimas" com as 5 regras do web (fixada ao abrir; fica até sair; com a janela sem foco, sobe para a mensagem nova)
- [ ] Abrir com a primeira não lida no topo; sem não lidas, no fim
- [ ] "Ir para o final" longe do fim; "Há novas mensagens" quando chegar mensagem longe do fim
- [ ] Rolar ao fim sozinho só se estava perto do fim
- [ ] *Links* com as regras de `parseLinks` (`www.` ganha `https://`); abrir no navegador só `http`/`https` (#56)

### 3.10 Digitando e gravando (FC-312, ENV-15, ENV-16)
- [ ] Ao digitar texto: `POST /conversa/digitando {id}`, no máximo 1 a cada 2,5 s (o último adiado)
- [ ] Receber WS 4/5; ignorar o meu; expirar em 4 s; sumir ao chegar mensagem
- [ ] Textos do web ("Digitando...", "Ana está digitando...", "Ana e Beto estão digitando...", "… e outras N pessoas…"; "Gravando áudio..." com prioridade)

### 3.11 Abrir por *link* e teclado (FC-314, FC-316, CON-12, ENV-12)
- [ ] Abrir pela notificação ou por `conversa://` → recarregar as mensagens; `?mensagem=` vai à mensagem (7.5)
- [ ] Letra digitada fora do campo vai para o campo (regras do web, doc 03 §7.1)
- [ ] Foco no campo ao trocar de conversa; Esc fecha painéis

---

## Etapa 4 — Anexos e mídia

### 4.1 Upload (FC-400, ANX-02)
- [ ] SHA-256 em *streaming* (`THashSHA2` por blocos, sem carregar o arquivo inteiro) (#54)
- [ ] `PUT /anexo {identificador, tipo, nome (≤ 255), extensao (≤ 10, minúscula), tamanho}`; acima de 1 GiB nem começa
- [ ] Resposta "não existe" → URL assinada de upload (vale 300 s)
- [ ] Resposta "já existe" → `id` (texto) + URL de leitura → pular o upload
- [ ] `PUT` do arquivo na URL assinada em *streaming* (`TFileStream`), sem `Authorization`, com `Content-Length` e progresso
- [ ] `POST /anexo/confirmar?identificador=` (na *query*)
- [ ] URL vencida (403 do MinIO) → pedir outra uma vez
- [ ] Tudo dentro da fila de envio (sobrevive a fechar o app); identificador gravado assim que sobe
- [ ] **Teste:** um arquivo de 200 MB sobe sem estourar a memória; o mesmo arquivo de novo não sobe

### 4.2 Anexar e enviar (FC-401, FC-402, ANX-01, ANX-03)
- [ ] Botão "Anexar" ("+") → seletor de arquivos múltiplo (transplantar o visual da fila de `legado/src/chat/chat/frames/chat.editor.anexo*`)
- [ ] Fila acima do campo na **ordem escolhida** (#51): miniatura (imagem), ícone + nome + tamanho (B/KB/MB/GB), "Remover"
- [ ] Tipo por MIME/assinatura: `image/*` → 2; `audio/*` → 4; gravação → **5**; resto → 3 (vídeo = 3 com extensão)
- [ ] Ordem dos conteúdos: [encaminhados] → texto → figurinha → arquivos (até a decisão do FC-416)
- [ ] Erro em qualquer upload cancela a mensagem inteira (como o web)
- [ ] Barra de envio na bolha otimista (nome e progresso)

### 4.3 URLs assinadas e cache (FC-403, ANX-14)
- [ ] `GET /anexo?identificador=` → `{url}`; cache da URL até 1 min antes dos 600 s
- [ ] Validar o identificador (`^[0-9a-f]{64}$`) antes de qualquer uso como nome de arquivo (#26)
- [ ] Download para temporário → validar (tamanho; assinatura do tipo) → renomear para `cache\<identificador>` em `%LOCALAPPDATA%`
- [ ] Imagem/arquivo com URL vencida → pedir outra e tentar uma vez
- [ ] Na primeira execução da nova base, ignorar o cache do app antigo (envenenado com JSON, #9)
- [ ] Cota e limpeza do cache (LRU) (FC-955)

### 4.4 Imagens e vídeos (FC-404, FC-408, ANX-04, ANX-05)
- [ ] Bolha de imagem (proporção preservada, hora sobre a imagem; com texto, bolha padrão)
- [ ] Visualizador (transplantar `legado/src/visualizadormidia/*`, sem `FreeAndNil(Self)`): galeria da conversa (sem ocultas), miniaturas, ←/→, roda e duplo clique para zoom, +/−, legenda, "Copiar imagem (Ctrl+C)", Esc
- [ ] GIF/WebP/SVG pelo Skia do Delphi, decidindo pela `extensao` do conteúdo (#87)
- [ ] Vídeo na bolha: primeiro quadro + play; reprodução no visualizador
- [ ] "Baixar", "Abrir com…", "Copiar"

### 4.5 Áudio (FC-405, ANX-10)
- [ ] *Player* único: um áudio por vez; para ao sair da conversa e ao entrar em chamada
- [ ] Bolha de áudio: play/pause, barra com arraste, `mm:ss` (#57); nome do arquivo (tipo 4) ou só o *player* (tipo 5)
- [ ] Tocar as gravações Opus/WebM do web (conferir o decodificador escolhido)
- [ ] Download sob demanda no primeiro *play*
- [ ] Áudio de outro não ouvido: destaque verde; primeiro *play* → `POST /mensagem/reproduzir {conversa, mensagem}`

### 4.6 Gravação de áudio (FC-406, ANX-11, ENV-16)
- [ ] Segurar o microfone ≥ 300 ms e soltar → envia; menos de 1 s descarta com aviso
- [ ] Clique curto (ou arrastar para cima) → modo travado com "Descartar", tempo, "Pausar gravação"/"Continuar gravação", "Ouvir gravação", "Enviar áudio"
- [ ] Arrastar para o lado → cancelar
- [ ] Formato real e declarado (Opus/WebM ou M4A/AAC), `audio-<timestamp>.<ext>`, **tipo 5**
- [ ] `POST /conversa/gravando {id}` a cada 2,5 s
- [ ] Sem microfone ou com o acesso bloqueado na Privacidade do Windows → mensagem clara com atalho para `ms-settings:privacy-microphone`
- [ ] Trocar de conversa para a gravação (#48)

### 4.7 Arquivos, download e abrir (FC-407, ANX-09)
- [ ] Bolha de arquivo: ícone pela extensão (`SHGetFileInfoW`, #98), nome, "Baixar"/"Abrir" (sem o "10 KB" falso, #50)
- [ ] Baixar: para `Downloads\Conversa` (ou "Salvar como"), nome sanitizado (sem `..`, separadores), **copiar** do cache (nunca mover)
- [ ] Mark-of-the-Web (`Zone.Identifier`) no arquivo salvo; aviso para `.exe/.bat/.cmd/.lnk/.js/.vbs/.ps1/.msi`
- [ ] Aviso "Salvo em Downloads\Conversa" com "Abrir" e "Abrir pasta"

### 4.8 Transcrição (FC-409, ANX-12)
- [ ] Abaixo dos áudios (4 e 5): estado inicial de `transcricao_status`/`transcricao`
- [ ] "Transcrever" → `PUT /anexo/transcricao {identificador}`; "Transcrevendo…" → `GET` a cada 3 s
- [ ] Resultado em todas as mensagens com o mesmo anexo; "(nenhuma fala reconhecida)"; erro com "Tentar de novo"
- [ ] Esconder o botão se o servidor não tiver transcritor (400 de configuração; S10)

### 4.9 Arrastar, soltar e colar (FC-410, FC-411, GER-04, ENV-11, ENV-09)
- [ ] Arrastar arquivos do Explorer sobre a conversa → camada "Solte para enviar o arquivo" → entram na fila
- [ ] Soltar sobre o campo → entram na fila
- [ ] Colar (Ctrl+V, Shift+Insert, menu): imagem → `print-<ms>.png` no temporário; arquivos copiados no Explorer (`CF_HDROP`); texto com mais de 10 linhas → "Inserir código"; texto com cara de código → cercado
- [ ] Temporários apagados depois do envio (#52)

### 4.10 Extras de mídia (FC-412, FC-413, FC-414)
- [ ] PDF: visualizador (WebView2 com o arquivo local) ou o app padrão
- [ ] HTML: abrir no navegador padrão a partir de arquivo temporário
- [ ] Rede tarifada: "Clique para carregar" (opcional)

### 4.11 Campo de mensagem rico (FC-415, FC-416, ENV-21)
- [ ] Escrever o ADR com a decisão: **simplificado** (fila + texto, enviado como [anexos…, texto]) agora × **completo** (blocos intercalados, igual ao web) ⛔ decisão do responsável
- [ ] Simplificado: faixa de peças acima do campo na ordem de inserção; envio = peças + texto por último
- [ ] Completo: modelo de blocos (texto ↔ peça); inserir peça no cursor; Backspace no início do bloco remove a peça anterior; envio na ordem
- [ ] Figurinha e gravação com o campo vazio vão na hora; com algo escrito, entram como peça
- [ ] **Teste:** enviar [texto, imagem, texto, figurinha] e conferir a mesma ordem no web

---

## Etapa 5 — Notificações e integração com o Windows

### 5.1 Mecanismo (FC-600, D12, WIN-05)
- [ ] Protótipo do toast nativo (FMX `TNotificationCenter` ou WinRT): AppUserModelID e atalho no Menu Iniciar
- [ ] Testar com "não perturbe", tela cheia e a Central de Notificações
- [ ] Decidir: mensagens por toast nativo; chamada recebida por janela própria no topo (transplantar `legado/src/notificacao/Conversa.Notificacao.Item.Chamada.*`, fechando pelo gerenciador depois do *handler*, #7)
- [ ] Registrar a decisão (ADR ou histórico)

### 5.2 Notificação de mensagem (FC-601, FC-602, NOT-01, NOT-02)
- [ ] `TSyncManager` avisa as conversas com mensagem nova de outra pessoa → `TNotificador`
- [ ] Uma notificação por conversa (substituída a cada lote): título = remetente (ou "Nova mensagem"), corpo = resumo do web por tipo, avatar, `HH:mm`
- [ ] Regras: nada com a conversa aberta e a janela ativa; nada em arquivadas; um som por lote; com o usuário ausente, a notificação espera
- [ ] Clique → restaurar a janela e abrir a conversa recarregando
- [ ] **Teste:** app na bandeja + mensagem pelo web → notificação; clique abre a conversa certa

### 5.3 Fechar e agir (FC-603, FC-604, NOT-03)
- [ ] Fechar ao zerar o contador da conversa, ao arquivar e ao abrir a conversa
- [ ] Ações "Responder" (entra na fila de envio) e "Marcar como lida" (se o mecanismo permitir)

### 5.4 Sons, "não perturbe", inicialização (FC-605, FC-606, FC-607, WIN-06, WIN-07, WIN-08)
- [ ] Sons de mensagem, toque e chamando (os mesmos arquivos do web) como recursos, tocados fora da thread da interface
- [ ] Mudo global e por conversa
- [ ] "Não perturbe" no menu da bandeja (com prazo) + respeito ao "Não incomodar" do Windows (`SHQueryUserNotificationState`)
- [ ] "Iniciar com o Windows" (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, com `--minimizado`), desligável

### 5.5 Barra de tarefas (FC-608, WIN-11, WIN-15)
- [ ] Contador sobre o ícone (transplantar `legado/lib/windows/Conversa.Windows.Overlay.pas` com `DeleteObject`, #41), sem arquivadas, "99+"
- [ ] Descrição acessível ("3 mensagens não lidas")
- [ ] `FlashWindowEx` em mensagem nova com a janela sem foco; contínuo em chamada recebida

### 5.6 Desktop × celular (FC-609, D13, #15)
- [ ] `WTSRegisterSessionNotification`: ao bloquear a sessão, fechar o WebSocket e passar ao *polling*; ao desbloquear, reconectar e ressincronizar
- [ ] `WM_POWERBROADCAST`: ao suspender, fechar; ao voltar, reconectar
- [ ] Inatividade (`GetLastInputInfo`, sem *poll* de 100 ms): depois de N minutos (padrão 10, configurável), fechar; ao voltar, reconectar
- [ ] **Teste:** com o desktop aberto e a sessão bloqueada, uma mensagem gera push no celular (app Android); ao desbloquear, o desktop recupera tudo ⛔ depende do FCM no Android/servidor
- [ ] Remover este paliativo quando o servidor tiver S2/S18

### 5.7 Protocolo e privacidade (FC-610, FC-612, WIN-28, CFG-04)
- [ ] Registrar o protocolo `conversa://` (por usuário); repassar à instância aberta
- [ ] Tela "Privacidade do Windows": estado de microfone, câmera e notificações, com botões para `ms-settings:`

---

## Etapa 6 — Chamadas

> Depende do protótipo e do ADR 0002 (0.8).

### 6.1 Gerenciador de chamadas (FC-701)
- [ ] `IChamadasApi` (as rotas do §9.2) para o gerenciador (interface, para os testes usarem um falso)
- [ ] Estados `Ocioso`, `Chamando`, `Recebendo`, `Conectando`, `EmAndamento`, `Encerrando`; despacho numa vez única; geração conferida na volta de cada chamada de rede
- [ ] Estado publicado no barramento: chamada, participantes, tipo, quem ligou, mídia local, microfone, câmera, duração, modo de exibição
- [ ] Única fonte dos eventos 51–57 e das pendentes; liga o "WebSocket sempre ligado durante a chamada" (sem o paliativo do 5.6)
- [ ] `Encerrar()` idempotente: mídia → toque → notificações → janela → estado
- [ ] Testes de **todas** as transições (51 duplicado, 51 depois do 52, o meu 54 durante o atender, 52 durante o entrar, desligar durante o iniciar, 55 sem 52, pendente repetida…)

### 6.2 Mídia (FC-702, FC-703, FC-704, ADR 0002)
- [ ] Implementar `IMidiaChamada` com a opção escolhida (A: janela WebView2 com a página de chamada embutida e a ponte; B: libwebrtc)
- [ ] ICE: `GET /api/ice` a cada conexão, `relay`, *gathering* ≤ 5 s (na opção A, conferir que a página faz)
- [ ] Retentativas de WHEP (áudio 12 × 0,8 s, vídeo 40 × 1 s); sincronização a cada 4 s; republicar e reassinar em falha
- [ ] Codec gravável (H264/VP9) e Opus; cancelamento de eco, supressão de ruído e ganho automático
- [ ] Vídeo **desligado por padrão**; tela só por ação explícita (#1)
- [ ] **Teste:** a gravação aparece no MediaMTX

### 6.3 Iniciar (FC-705, CHA-01)
- [ ] Botões "Chamada de voz" e "Chamada de vídeo" no cabeçalho; "Ligar de novo" na bolha de chamada e no histórico
- [ ] Participantes: direta = [eu, outro]; grupo = `GET /conversa/usuarios` (todos, inclusive eu)
- [ ] `PUT /chamada/iniciar {tipo, usuarios:[{id}], conversa_id}` → publicar
- [ ] Janela "Chamando..." + som de chamando em loop
- [ ] "Já existe uma chamada em andamento"; desfazer se a API falhar
- [ ] Cancelar enquanto chama: `POST /chamada/cancelar {id}`; 45 s sem atender → cancelar

### 6.4 Chamada recebida (FC-706, FC-707, CHA-03, CHA-04, CHA-05)
- [ ] WS 51 → `GET /chamada/dados?id=` → `Recebendo`
- [ ] Janela no topo sem roubar o teclado: "<nome> está ligando...", "Vídeo + Áudio"/"Somente Áudio", "Recusar", "Atender", "Atender só assistindo" (vídeo)
- [ ] Toque em loop (só para ao atender, recusar, encerrar remoto, outro aparelho ou 30 s); `FlashWindowEx`
- [ ] 30 s sem resposta → `POST /chamada/recusar {id, nao_atendeu:true}`
- [ ] Atender: mídia vídeo+áudio → só áudio → só recepção → `POST /chamada/entrar {id}` → publicar → assinar os outros
- [ ] Recusar: **um** `POST /chamada/recusar {id}`; "×" só esconde

### 6.5 Regras automáticas (FC-708, FC-709, FC-710)
- [ ] 51 durante outra chamada ou toque → `recusar {nao_atendeu:true}` sem tocar
- [ ] 51 da minha própria chamada ou duplicado → ignorar; 51 da chamada atual (participante adicionado) → só sincronizar
- [ ] 53/54 com o **meu** `usuario_id` enquanto toca → parar e voltar a `Ocioso`, sem REST
- [ ] Ao conectar, reconectar e voltar da suspensão: `GET /chamadas/pendentes` (sem `usuarios`); > 25 s → `recusar {nao_atendeu:true}`; senão, tocar

### 6.6 Durante a chamada (FC-711, FC-712, CHA-09, CHA-10)
- [ ] 54 de outro: se `Chamando` → `EmAndamento` + cronômetro; assinar quem entrou
- [ ] 55: remover o *peer* → `GET /chamada/dados` → se ninguém mais "Entrou", sair (`POST /chamada/sair`; o servidor não manda 52)
- [ ] 53 em 1:1 → encerrar; 52 → encerrar
- [ ] A cada 4 s em `EmAndamento`: `GET /chamada/dados` e reconectar quem caiu
- [ ] "Sair da chamada" único para janela, barra e miniatura da barra de tarefas

### 6.7 Áudio e dispositivos (FC-713, CHA-11, CHA-23, WIN-30)
- [ ] Microfone (mute por *flag*, sem fechar o dispositivo), saída de áudio, câmera
- [ ] Escolha de microfone, saída e câmera lembrada; seguir o dispositivo de comunicação padrão; reagir a fone conectado/desconectado
- [ ] Parar qualquer áudio de mensagem ao entrar em chamada

### 6.8 Janela e controles (FC-714, CHA-11, CHA-13)
- [ ] Janela flutuante (arrastável pelo cabeçalho, redimensionável, mínimo 320×240, "Sempre no topo" opcional), no monitor da janela principal
- [ ] Cabeçalho: "Chamando..."/"Em chamada"/"Encerrando...", duração `mm:ss`/`hh:mm:ss` (atualizada a cada 1 s), tipo, "N pessoas"
- [ ] Controles: microfone, câmera, saída, tela, adicionar, chat, sair; vermelhos quando desligados (cores do FMX); `Hint` e estado lido pelo Narrador
- [ ] Atalhos (ex.: Ctrl+D microfone, Ctrl+E câmera); botões na miniatura da barra de tarefas (`ThumbBarAddButtons`)
- [ ] Indicador na janela principal ("Toque para voltar à chamada", com a duração) que reabre a janela
- [ ] **Teste:** atender e desligar só pelo teclado

### 6.9 Histórico de chamadas (FC-715, CHA-22)
- [ ] `GET /chamadas?participante=0&de=&ate=` → `ChamadaHistoricoItem` (sem filtro 25, com período até 250)
- [ ] Abas "Todas"/"Perdidas" (perdida = recebida em que eu não entrei; o status 5 nunca é gravado)
- [ ] Busca por contato; período
- [ ] Agrupar "Hoje"/"Ontem"/`dd/MM/aaaa` pelo dia local
- [ ] Item (transplantar o visual de `legado/src/chamada/Conversa.Chamada.Listagem.Item.*`): avatar ("Grupo (N)"), seta efetuada/recebida, hora, "Vídeo"/"Áudio" · duração ou status, cores do FMX
- [ ] Clique → abrir a conversa; "Ligar novamente"

### 6.10 Vídeo (FC-716, CHA-12, CHA-16)
- [ ] Câmera (padrão de desktop do web: 720p, 24 fps)
- [ ] Grade (1/2/3/4 colunas), destaque, tela única; duplo clique destaca; F11 tela cheia
- [ ] "Ativar vídeo" → `POST /chamada/video {id}` (proteger contra clique duplo)
- [ ] WS 56: já em vídeo → reassinar; senão, "<nome> ativou o vídeo" com "Apenas assistir"/"Transmitir também" (15 s → "Apenas assistir")

### 6.11 Extras de chamada (FC-717 a FC-723)
- [ ] Adicionar participante: "Adicionar à chamada" → `PUT /chamada/usuario` um por vez
- [ ] Compartilhar a tela por ação explícita: seletor de monitor/janela, indicador permanente, WS 57 `{acao:"tela"}`
- [ ] Chat da chamada: grupo criado no primeiro clique no campo (`PUT /chamada/chat`, WS 57 `{acao:"chat"}`); painel lateral com a tela de chat
- [ ] Indicador de fala (> 0,02, segura 400 ms) → anel verde
- [ ] Somente recepção: "Ativar microfone"/"Ativar câmera"
- [ ] Tela e ponteiro remotos (WS 57): tela em destaque; ponteiros com nome e cor; enviar o ponteiro pelo mouse
- [ ] Qualidade (aba "Chamadas"): ruído, eco, ganho, 32/64/128 kbps, resolução, fps, banda, prioridade da tela

### 6.12 Matriz de testes manuais (FC-724)
- [ ] Criar `docs/testes/chamadas.md` com a matriz (rede, suspensão, bloqueio, Bluetooth, fone, 1:1, grupo de 4, upgrade, adicionar, atender em outro aparelho, gravação)
- [ ] Rodar a matriz contra o servidor de desenvolvimento com o outro lado no web

---

## Etapa 7 — Ações sobre mensagens

### 7.1 Menu de ações (FC-500, ENV-20)
- [ ] Clique direito na bolha → reações rápidas 👍 ❤️ 😂 😮 😢 👏 🔥 + "Mais emojis" + "Responder", "Responder no privado" (grupo, de outro), "Encaminhar", "Copiar", "Ocultar" (minha)
- [ ] **Ctrl + clique direito** → só a barra de reações, centrada no clique
- [ ] Botão de ações (seta) ao passar o mouse, ao lado da bolha; fecha com clique fora, Esc e rolagem
- [ ] Sem menu para chamada, oculta e mensagem sem id real; sem "Encaminhar" em votação

### 7.2 Reações (FC-501, ENV-17)
- [ ] `PUT /mensagem/reacao {mensagem_id, emoji}` (alterna), otimista
- [ ] Chips abaixo da bolha (emoji + contagem; destaque se eu reagi; clique alterna); *tooltip* com foto, nome e hora de quem reagiu
- [ ] No máximo 5 emojis diferentes por pessoa ("Você já reagiu com 5 emojis nesta mensagem.")
- [ ] 5 chips à mostra + "+N" (com a lista dos demais)
- [ ] WS 7 (relê a mensagem, se estiver no banco); seletor completo de emoji (≤ 10 *code points*)

### 7.3 Responder (FC-502, ENV-06)
- [ ] "Responder" no menu (e atalho); barra acima do campo com nome, resumo e "×"
- [ ] `mensagem_referencia {tipo:1, origem_mensagem_id}`; a otimista já mostra a citação; a gravação também responde

### 7.4 Ocultar (FC-503, ENV-18, ENV-14)
- [ ] Confirmação: "Ocultar mensagem" / "Ela continua na conversa, marcada como oculta." / "Ocultar" (perigo) / "Cancelar"
- [ ] `DELETE /mensagem?id=` → com `excluida_em`: oculta; sem: removida (agendada)
- [ ] Agendada futura: "Cancelar mensagem agendada" / "Ela não será enviada." / "Cancelar envio" / "Voltar"

### 7.5 Citação e ir para a mensagem (FC-504, FC-505, FC-520, MSG-19, MSG-06)
- [ ] Bloco de citação (remetente · hora, ou "Encaminhado de <nome>"; conteúdos da original); recursivo até 5 níveis
- [ ] Encaminhada não repete conteúdos iguais (`semCopiasDaReferencia`), inclusive nos níveis aninhados
- [ ] Clique na citação → ir para a original: buscar o contexto (30/30, senão 120/120), centralizar, destacar 1,2 s; de outra conversa (se participo) → abrir aquela conversa
- [ ] Erro → "Não foi possível localizar esta mensagem no contexto da conversa."

### 7.6 Encaminhar, copiar e responder no privado (FC-506, FC-507, FC-512)
- [ ] "Encaminhar mensagem" com busca (conversas exceto a de origem + contatos sem direta)
- [ ] `PUT /mensagem` no destino com os conteúdos copiados (1..n) e `{tipo:2, origem_mensagem_id}`; contato sem conversa → criar a direta
- [ ] Copiar: texto (com seleção parcial) e imagem (PNG) (#49)
- [ ] "Responder no privado": abrir/criar a direta com o remetente, com a mensagem pendente como encaminhada

### 7.7 Menções (FC-508, ENV-05, MSG-12)
- [ ] "@" + texto → até 6 contatos/membros (↑/↓, Enter/Tab, Esc)
- [ ] Inserir "@Nome" destacado; guardar o id; no envio, `@[Nome](id)` ("@Ana" não casa com "@Anabela")
- [ ] Render `@[Nome](id)` → `@Nome` com cartão no *hover* e clique que abre a direta
- [ ] Testes portados de `mencoesTexto.ts`

### 7.8 Figurinhas (FC-509, ENV-04)
- [ ] Embutir os 24 JSON de `conversa-web/public/figurinhas/**` como recurso (o servidor não serve, S5)
- [ ] Seletor por pacote no "+"; clique envia tipo 7 `pacote/nome`
- [ ] Bolha de 160 px com Skottie (Skia do Delphi); animar só visível; falha → "Figurinha"

### 7.9 Código e Markdown (FC-510, FC-511, MSG-15)
- [ ] Porte de `codeBlocks.ts` com testes
- [ ] Bloco de código: cabeçalho com a linguagem, "Copiar" → "Copiado!", destaque de sintaxe (tokenizador próprio), recolher acima de ~240 px ("Expandir código"/"Recolher código")
- [ ] ` ```md ` → Markdown renderizado, com "Visualizar"/"Código"
- [ ] ` ```mermaid ` → WebView2 isolado com mermaid.js embutido, ou só o código (P2)

### 7.10 Detalhe de status e agendamento (FC-513, FC-514)
- [ ] *Hover* de 300 ms (e clique) no ✓ → `GET /mensagem/status/detalhe?id=` (datas): direta "Enviada/Recebida/Visualizada/Ouvida/Oculta/Aguardando"; grupo "Visualizada por (N)", "Recebida por (N)", "Aguardando (N)"
- [ ] "Agendar mensagem" (data e hora; padrão amanhã 08:00; ≥ 5 min; ≤ 1 ano) → `visivel_em` em ISO UTC
- [ ] Agendadas fora do chat: relógio com o número ao lado do microfone; "Mensagens agendadas" com horário, resumo e "Cancelar"; na hora, entra no chat

### 7.11 Pequenos extras (FC-515, FC-519)
- [ ] Atalhos `:)` → 🙂 (tabela do `emojiAtalhos.ts`), só como palavra solta e fora de código
- [ ] Seletor de emoji próprio (a tabela `legado/src/chat/chat/chat.emoji.pas`), sem `SendInput`
- [ ] "Inserir código" (linguagem + texto monoespaçado; Ctrl+Enter envia; Esc cancela)
- [ ] Rascunho por conversa (texto com menções, anexos, resposta pendente) no banco; restaurar ao abrir; apagar ao enviar e no "Sair da conta"

### 7.12 Votação (FC-516, FC-517, FC-518, MSG-20, ENV-22)
- [ ] Repositório de enquetes com cache por id e leituras simultâneas deduplicadas; WS 62 relê só o que está em cache/na tela
- [ ] Bolha: "Carregando votação..."; "📊 <pergunta>"; "Escolha uma opção"/"Escolha uma ou mais opções"; círculo ou quadrado + ✓; contagem; barra `round(votos / total_votantes × 100)%`; nomes dos votantes; "1 pessoa votou"/"N pessoas votaram"
- [ ] Votar: `POST /enquete/votar {enquete_id, opcoes:[lista completa]}`; desabilitar durante o voto; erro "Não foi possível votar"
- [ ] Data final: "· encerra hoje 18:00"; "Definir/Alterar data final", "Tirar data" (`PATCH /enquete`); "Encerrar votação" com confirmação (`POST /enquete/encerrar`); encerrada: "🔒 Votação encerrada <quando>", 🏆 na mais votada
- [ ] Votação oculta revelada → resumo só de leitura
- [ ] Criar: "+" → "Votação" (só em grupo) → "Nova votação" (Pergunta ≤ 300, Opções 2–12 ≤ 200, "Permitir várias escolhas", "Definir data final") → `PUT /enquete`
- [ ] **Teste:** criar no desktop, votar no web → a barra atualiza no desktop sem recarregar

---

## Etapa 8 — Atividades, pesquisa, perfil e configurações

### 8.1 Atividades (FC-800, ATV-01, ATV-02)
- [ ] Item "Atividades" na barra lateral: `GET /atividades?antes=0&limite=30`, paginação, "Hoje"/"Ontem"/data
- [ ] Item: avatar com selo, "**autor** descrição", "em <grupo>", prévia, hora, "Nova"; clique → mensagem ou conversa
- [ ] Contador: `GET /atividades/novas` ao conectar e a cada WS 61 (`99+`); abrir → `POST /atividades/vistas`
- [ ] Vazio: "Nenhuma atividade ainda." / "Reações, respostas, menções e chamadas perdidas aparecem aqui."

### 8.2 Pesquisa (FC-801, PES-01, PES-02)
- [ ] Na conversa (Ctrl+F): `GET /pesquisar?texto=&conversa=<id>` → resultados → ir para a mensagem
- [ ] Global (Ctrl+Shift+F): `GET /pesquisar?texto=&conversa=0`, agrupado por conversa, termo destacado **sem interpretar HTML**
- [ ] "Pesquisando…" / "Nenhum resultado encontrado."

### 8.3 Perfil (FC-802, FC-803, AUT-06, AUT-07, AUT-08, AUT-10)
- [ ] Nome e e-mail → `PATCH /usuario {id, nome, email}` → "Dados atualizados com sucesso."
- [ ] Senha: atual, nova (≥ 6), confirmação → `POST /alterar-senha {senha_atual, senha}`; mensagens do web (acentuadas)
- [ ] Avatar: seletor de arquivo (ou arrastar) → recorte quadrado 256×256 → JPEG 85% → upload → `PATCH /usuario {id, avatar_anexo_id}`; remover → `null`
- [ ] Perfil de outro usuário: foto, nome, "E-mail", "Telefone" ("Não informado"), "Ver anexos", "Ligar"

### 8.4 Configurações (FC-804 a FC-810)
- [ ] Janela/painel "Configurações" (Ctrl+,): Usuário, Servidor, Notificações e sons, Inicialização, Dispositivos, Privacidade do Windows, Chamadas, Voip, Sistema*, Acessos*, Sobre
- [ ] Tema: claro / escuro / seguir o Windows (`AppsUseLightTheme` + `WM_SETTINGCHANGE`)
- [ ] Dispositivos: sessão atual + microfones, saídas e câmeras, com escolha
- [ ] Atalhos de teclado e a tabela no "Sobre" (WIN-12)
- [ ] `GET /usuario/permissoes` → mostrar Sistema (`parametros`) e Acessos (`permissoes`) só para quem tem
- [ ] Sistema: `GET/PATCH /parametros` (Firebase, forçar relay, dias de gravação, transcritor), só o que mudou
- [ ] Acessos: `GET /permissoes` → tabela usuário × permissão com busca; `PUT`/`DELETE /permissao/usuario`; aviso real do web
- [ ] Zoom (Ctrl+= / Ctrl+− / Ctrl+0 e Ctrl+roda) sem mudar o tamanho da janela; formatos pt-BR fixos
- [ ] "Sobre": versão, data do build, servidor conectado, licenças de terceiros, "Copiar diagnóstico", "Abrir pasta de logs"

### 8.5 Anexos da conversa (FC-809, ANX-13)
- [ ] "Ver anexos" (perfil e painel do grupo): `GET /anexos?conversa=&direcao=&tipos=2,3,4,5&antes=&limite=60`
- [ ] Filtros Todos/Enviados/Recebidos e Todos/Imagens/Arquivos/Áudios/Gravações; grade de imagens; lista dos demais; "Abrir mensagem", "Baixar"; paginação

---

## Etapa 9 — Extras e distribuição (avaliar antes de fazer)

- [ ] Janela de conversa separada (CON-10, WIN-16): mesmo processo, mesmo WebSocket e banco, 900×700, posição lembrada
- [ ] Ramal SIP — configuração: `GET /sip`; `PUT /sip` (se não existe) ou `PATCH /sip {id, …}`
- [ ] Ramal SIP — protótipo: pilha nativa sobre WSS ou WebView2 com `sip.js`; discador flutuante; integração com a chamada recebida
- [ ] Cores personalizadas (CFG-05)
- [ ] Instalador por usuário (Inno Setup ou MSIX): atalho no Menu Iniciar (AUMID), WebView2 *bootstrapper* (se a opção A), dependências, "Iniciar com o Windows", desinstalação limpa
- [ ] Versão automática e assinatura de código (exe, DLLs e instalador)
- [ ] Atualização automática (S24)
- [ ] Avisos de licenças de terceiros no "Sobre" e no instalador
- [ ] Jump List ("Nova conversa", "Sair")

---

## Qualidade (fazer junto, ao longo de tudo)

- [ ] Testes unitários: parsers (WS, datas, código, menções, classificação), mapeadores, gerenciador de chamadas, `SyncManager`, fila de envio, validação de identificador, sessão (FC-950)
- [ ] Meta de cobertura: ≥ 70% no `core`
- [ ] Acessibilidade: navegação por teclado, foco visível, `Hint` em todos os ícones, contraste AA, teste com o Narrador (FC-951)
- [ ] Segurança: nada de token/senha/conteúdo em log; identificador validado; Mark-of-the-Web; `SetDefaultDllDirectories` e DLLs por caminho completo; vídeo/tela só por ação explícita (FC-952)
- [ ] Diagnóstico: "Copiar diagnóstico" e "Abrir pasta de logs" (FC-953)
- [ ] Matriz de testes manuais do desktop: Windows 10 e 11; 100/125/150/200%; vários monitores; suspender/bloquear; servidor fora; instalação limpa (FC-954)
- [ ] Dados locais: cota e limpeza do cache; nada na pasta do exe (FC-955)
- [ ] FastMM em modo *full debug* nos testes; relatório de vazamento só em Debug

---

## Opcional — Remendos no app ATUAL (só se alguém depende dele até a nova base ficar pronta)

> Na branch `legado/abril-2026`. Mesmo corrigido, o app atual **não deve ser distribuído a novos usuários**.

- [ ] Nada de vídeo automático: `PublicarLocalNaSala(ChamadaId, MeuId, False, True)` (`src/chamada/Conversa.Chamada.pas:502`) (FC-020, #1)
- [ ] Parar de salvar a senha e de entrar sozinho (`Conversa.Login.pas:68-73`, `:82`); apagar `Senha` dos `conversa.json` existentes (FC-021, #6)
- [ ] Validar o identificador de anexo; `TFile.Copy` em vez de `Move` (FC-022, #26)
- [ ] `POST /mensagem/visualizar` com corpo (FC-023, Q3)
- [ ] `excluida_em` → "Mensagem oculta" (FC-024, Q6)
- [ ] Download pela URL assinada + limpar o cache envenenado (FC-025, Q1)
- [ ] Upload pelo fluxo novo, antes do `PUT /mensagem` (FC-026, Q2)
- [ ] `/conversa/usuarios` no lugar de `/conversa/dados` (FC-027, Q4)
- [ ] `/mensagens/novas?desde=` e *upsert* sem reanexar (FC-028, Q8, #11)
- [ ] Marcadores para os tipos 5–8 e tolerância a tipo desconhecido (FC-029, Q7)
- [ ] WebSocket mínimo: OpenSSL na pasta do app + verificação + quadro de tamanho 0 + reconexão fora da UI (FC-030, #2, #3, #5)
- [ ] `Continue` nas notificações; vazamento só em Debug; `DeleteObject`; "Sair" na bandeja; `SetWindowLongPtr` (FC-031)
- [ ] Win64 fixo e dependências documentadas (FC-032)
- [ ] **Teste:** login, texto, imagem nos dois sentidos com o web, "visualizada" no web, mensagem oculta, reconexão depois de `docker restart api`, chamada sem tela automática

---

## Revisão periódica
- [ ] Marcar o que foi feito neste TODO (com o commit)
- [ ] Atualizar `docs/auditoria-2026-10/05-matriz-paridade.md`
- [ ] Ver se o servidor mudou: `git -C ../conversa log --since="1 week ago" --oneline`; se mudou o contrato → atualizar os docs 01/02, as *fixtures* e o OpenAPI
- [ ] Ver se o web ganhou funcionalidade nova: `git -C ../conversa-web log --since="1 week ago" --oneline` → acrescentar aqui e no doc 03
- [ ] Conferir as pendências do servidor (doc 08): o que foi resolvido libera itens com ⛔ (ex.: S2/S18 → remover o paliativo do 5.6)
