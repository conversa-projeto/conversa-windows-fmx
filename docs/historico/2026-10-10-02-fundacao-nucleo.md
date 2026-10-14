# 2026-10-10 · 02 · Fundação: projeto Win64, barramento, logger, HTTP, contrato e testes

- **Fluxo:** Fundação (etapa 1)
- **Tipo:** código (sem compilar; ver "Como foi verificado") / documentação
- **Itens:** `TODO.md` 1.1–1.9 e parte da 1.14; FC-100…FC-108, FC-113; D3–D8, D17 (doc 07)
- **Branch:** `nova-base`
- **Commits:** — (preencher)

## Contexto
Primeiro bloco de código da nova base (ADR 0001). Sem compilação por linha de comando nesta máquina, o código é escrito e revisado sem compilar; o responsável compila no IDE ("build geral").

## O que foi feito
- **Projeto do app** (`app/`):
  - `Conversa.dpr`/`.dproj`: FMX, só Win64; saída `bin\Win64\<config>`; DCUs em `bin\dcu\Win64\<config>\app`; sem *PreBuild*; VersionInfo pt-BR (1046), versão 0.1.0; ícone em `app/recursos/`;
  - `Conversa.manifest` próprio: PerMonitorV2, `asInvoker`, controles comuns v6, caminhos longos, Windows 10/11;
  - `Conversa.App.Composicao.pas`: composição manual (logger + barramento), sem serviço global;
  - janela principal mínima (`ui/Conversa.UI.Principal`), com a versão.
- **Testes** (`testes/`):
  - `ConversaTestes.dpr`/`.dproj`: DUnitX em console Win64; código de saída 1 se algo falhar;
  - testes: 9 de log, 13 de barramento, 10 de endereço, 20 de API, 9 de JSON e datas (26 execuções com os casos parametrizados) e 21 de mapeadores;
  - `testes/fixtures/`: 31 JSON (exemplos do doc 01 com os casos difíceis e capturas higienizadas do servidor de desenvolvimento, só contas de teste).
- **Build** (`build/compilar.cmd`, `build/testar.cmd`): apagam o exe antes, conferem se nasceu um novo e procuram erro no log. Testado aqui: na Community, detectam "does not support command line compiling" e saem com erro (sem falso sucesso).
- **Núcleo** (`core/`):
  - `eventos/Conversa.Eventos.Barramento`: assinar por tipo, publicar de qualquer thread, entrega sempre pela fila da thread principal (ou na hora, nos testes), cancelamento por `IInterface`, isolamento de exceção, "último valor";
  - `eventos/Conversa.Eventos.Tipos`: `TEventoSessaoExpirada`;
  - `infra/log/Conversa.Infra.Log`: `TLoggerArquivo` (fila + thread, arquivo por dia, rotação por tamanho, nunca bloqueia quem chama) e `TRedacao` (JWT, Bearer, senha/token/conteúdo em JSON, `token=` em URL);
  - `infra/windows`: `TPastas` (`%APPDATA%\Conversa`, `%LOCALAPPDATA%\Conversa`, por usuário) e `TVersaoApp`;
  - `dominio/Conversa.Dominio.Endereco`: o endereço do servidor e o que deriva dele (API, WebSocket, mídia);
  - `infra/http/Conversa.Infra.Http`: transporte sobre `THTTPClient`, com clientes reaproveitados e falhas classificadas (sem conexão, tempo, certificado);
  - `infra/http/Conversa.Infra.Api`:
    - mensagens de erro do campo "error" ou pelo status do nginx (HTML ou texto);
    - 401 publica a sessão expirada;
    - repetição só em GET;
    - rotas públicas sem token;
    - "Testar conexão" (`TTesteDeServidor`);
  - `contrato/Conversa.Contrato.Json`: leitura tolerante (`null`/ausente = padrão; id em número ou texto) e `TDatas` (ISO-8601 → UTC, com e sem fuso, frações, espaço no lugar do `T`);
  - `dominio/Conversa.Dominio.{Modelos,Chamadas,Anexos,Enquetes,Sistema}` e `contrato/Conversa.Contrato.Mapeadores`: todos os DTOs da 1.9.
- **UI:** `ui/Conversa.UI.Cores` (83 *tokens* da §7 do `cores.md`, claro e escuro proposto) e `ui/Conversa.UI.Textos`.
- **Repositório:**
  - `.gitattributes`: CRLF no checkout de `.pas/.dpr/.dproj/.fmx/.cmd/.manifest/.ps1`; binários marcados;
  - `docs/contrato/openapi.json` atualizado;
  - `CLAUDE.md`: armadilhas, nomes de units e regra dos projetos.
- **Verificador:** novas regras (BOM, `{` dentro de comentário, `.dpr` × `.dproj`, unit do projeto que não está no `.dpr`).
- **Doc 01:**
  - D16: a pegadinha 9 dizia `ISO8601ToDate(x, False)` para UTC, mas `False` devolve hora local (conferido no `AdjustDateTime` da RTL);
  - D13: o OpenAPI do mesmo servidor agora declara `additionalProperties:false` em 2 corpos, não 17.

## Como foi verificado
- **Verificador** (`ferramentas/verificar-uses`): 28 fontes, 0 erros (uses, blocos, métodos × implementação, projetos, BOM).
  - Pegou dois erros reais durante o trabalho:
    - `{error}` dentro do comentário de cabeçalho de duas units (o resto do comentário virava código);
    - `CharInSet` sem `System.SysUtils`.
- **Revisão independente 1** (logger, barramento, app, projetos, testes), conferida contra o fonte da RTL/FMX. Corrigido:
  - **A1 — o app daria violação de acesso ao abrir:** no FMX, `CreateForm` antes do `Run` só registra a classe (`FMX.Forms`, `TApplication.CreateForm`). Agora há `Application.RealCreateForms` antes do `Iniciar`;
  - **A2 — laço infinito no fim do log:** depois do `DoShutDown`, `PopItem` devolve `wrSignaled` com o item vazio. Agora o vazio encerra a thread;
  - **A3 — acentos corrompidos:** os fontes estavam em UTF-8 **sem BOM**, e o compilador os leria em ANSI (1252). Todos têm BOM agora, e o verificador acusa a falta;
  - **B1–B9:**
    - ordem de destruição (a janela solta os serviços em `Finalizar`);
    - ordenação ordinal dos logs;
    - estado do barramento enfileirado sob a trava (sem inversão) e estado "vazio" entregue;
    - regra de threads do cancelamento;
    - formatos de data fixos;
    - pasta do Windows vazia vira erro;
    - nota de reentrância no destrutor;
    - log compartilhado entre instâncias;
  - **C1–C2:** `Integer(Length(...))` e `<T>()` nos testes.
- **Revisão independente 2** (HTTP, API, endereço, JSON, domínio, mapeadores, testes): ver abaixo.
- `build/compilar.cmd` rodado de verdade: detectou a Community e saiu com erro.
- *Fixtures* reais: conferidas por *script* (13 conversas, 1 fixada e 1 arquivada; histórico só com status finais; atividades dos tipos 1 a 4) e higienizadas (credencial do TURN trocada; nenhum token ou URL assinada).
- `grep`: nenhuma unit de `core/dominio` usa `FMX.*` ou `System.Net.*`; nenhum `OnValidateServerCertificate` nem OpenSSL.

## Decisões
- **Sem camada de DTO separada:** os mapeadores leem o JSON direto para os records de domínio (mesma tolerância, metade do código).
- **Enums de domínio:** começam em 0 e são contíguos, então `Ord` = código do servidor. Código novo vira `Desconhecido`, com o número original em `TipoBruto` (#22).
- **`mensagem_referencia`:** a cadeia recursiva vira uma lista de níveis (`Referencias[0]` é a referenciada direta).
- **Duração nula = -1**; data nula = 0.
- **Testes de HTTP** com transporte falso (`ITransporteHttp`). O teste contra servidor real fica para quando houver build.
- **Fonte:** UTF-8 com BOM e CRLF; não usar `with`.

## Pendências / próximos passos
- ⛔ Compilar e rodar os testes no IDE (responsável).
- Etapa 1 restante:
  - 1.5 componentes (Avatar, diálogo, faixa, estados, barra de título);
  - 1.6 configuração e tela Servidor;
  - 1.10 banco, 1.11 sessão, 1.12 tempo real, 1.13 sincronização;
  - 1.14 exceções não tratadas;
  - 1.15 serviços assíncronos;
  - 1.16 instância única.
