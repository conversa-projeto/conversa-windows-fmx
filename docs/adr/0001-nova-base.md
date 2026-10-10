# ADR 0001 — Recomeçar o núcleo do cliente Windows numa nova base Delphi FMX

- **Status:** **aceito** em 2026-10-09 (FC-001). O responsável autorizou o início ("Pode iniciar… Prossiga sozinho, assim como foi o desenvolvimento do Android, depois eu faço um build geral") e delegou as decisões abertas, fechadas abaixo pela recomendação da auditoria; qualquer uma pode ser revista por ele.
- **Data:** 2026-10-08
- **Base:** `docs/auditoria-2026-10/00-LEIAME.md`, `04-auditoria-fmx.md` §8 e `07-plano-nova-base.md`

## Contexto
- O cliente FMX parou em abril de 2026, escrito para o servidor Delphi. O servidor foi reescrito (Node → Bun/Elysia) e mudou formatos e fluxos: anexos por URL assinada do MinIO, exclusão lógica ("ocultar"), TURN obrigatório para a mídia, novos eventos (57, 61, 62), enquetes.
- Contra o servidor atual, o FMX só faz login, lista conversas e contatos, cria conversa e grupo e troca **texto**. Quebram anexos, "visualizada", membros de grupo, histórico de chamadas, mensagem oculta, conteúdos tipo 5–8 e toda a mídia de chamada (doc 02, Q1–Q14).
- Das 137 funcionalidades do web, 1 está íntegra no FMX, 54 parciais ou quebradas e 76 não existem (doc 05).
- Os defeitos críticos estão no núcleo (doc 04, #1–#16):
  - toda chamada transmite a tela inteira sem aviso;
  - o WebSocket nunca reconecta, provavelmente cai em ~2 min, não valida o certificado e depende de OpenSSL 1.0.2 ausente;
  - a sessão de 12 h vence em silêncio; a senha fica salva com cifra reversível;
  - *use-after-free* no ciclo de vida da chamada; anexos quebrados nos dois sentidos;
  - quase toda a rede roda na thread da interface;
  - build não reprodutível (exe x86 × DLLs x64; Delphi Community sem linha de comando).
- Não há camadas, testes nem injeção; um objeto global concentra cache, regras, rede e diálogos; ~11% do código está morto.
- Ao mesmo tempo, a **interface é boa** (é a referência visual do Android novo) e as integrações com o Windows têm valor.

## Decisão
Construir uma **nova base Delphi FMX Win64** para o núcleo e **transplantar a interface *frame* a *frame***:
- camadas `dominio` / `contrato` / `infra` / `aplicacao` / `ui`, interfaces e composição manual, barramento tipado com entrega na thread principal;
- `THTTPClient` (WinHTTP) tipado; WebSocket do WinHTTP com reconexão, geração e *ping*; SQLite (FireDAC); token com DPAPI; *logger* com redação;
- gerenciador de chamadas com máquina de estados; mídia atrás de `IMidiaChamada` (decisão no ADR 0002);
- DUnitX; *scripts* de build que conferem o resultado; instalador por usuário.

Detalhe: `docs/auditoria-2026-10/07-plano-nova-base.md`.

**Onde:** mesmo repositório, branch `nova-base` (criada a partir da `chamada` depois da Etapa 0); o código atual vai para `legado/` (fora do build) e fica também na branch `legado/abril-2026` e na tag `legado-v1-final`.

## Decisões abertas (fechadas em 2026-10-09)
> As quatro foram fechadas pela recomendação da auditoria, com a delegação do responsável. O texto original fica logo abaixo, como referência.

- **Senha → não guardar.** O app guarda só o token (DPAPI). Quando o token vence (12 h), pede o login de novo. "Manter conectado" fica de fora até o servidor ter *refresh token* (S13, pedido na Etapa 0.9).
- **Desktop × celular → sim, N = 10 minutos, configurável.** Enquanto o servidor não tiver S2/S18, o WebSocket fecha ao bloquear a sessão, ao suspender e depois de 10 minutos sem uso, com *polling* REST nesse período (FC-609, Etapa 5.6).
- **Build → pelo IDE, feito pelo responsável.**
  - A edição instalada (12.1 Community) não compila por linha de comando.
  - O `DelphiLSP` fora do IDE também exige licença Professional ou superior. Testado em 2026-10-09: respondeu "A valid license was not found" e não publicou diagnósticos.
  - Por isso o código é escrito e revisado sem compilar:
    - toda API usada é conferida no fonte do Delphi (`Studio\23.0\source`);
    - os `uses` passam por um verificador próprio (`ferramentas/verificar-uses`).
  - O responsável compila no IDE ("build geral") e devolve os erros. As correções entram com registro no histórico.
  - Os *scripts* `build/compilar.cmd` e `build/testar.cmd` ficam prontos para quando houver licença.
- **Branch → `nova-base`**, criada a partir da `chamada` depois da preservação (Etapa 0.2), com a estrutura do doc 07 §2.

### Texto original das decisões abertas
1. **Senha:** não guardar (pedir o login quando o token vencer, uma vez por dia, até o servidor ter *refresh token* — S13) **ou** "Manter conectado" com a credencial protegida por DPAPI. Recomendação: não guardar, e priorizar o S13 no servidor.
2. **Desktop × celular** (enquanto o servidor não tem S2/S18): fechar o WebSocket ao bloquear a sessão, ao suspender e depois de N minutos ocioso (com *polling* REST nesse período). Recomendação: sim, com N = 10 minutos, configurável.
3. **Build:** licença com compilação por linha de comando (Professional ou superior) **ou** fluxo de build pelo IDE combinado. Sem um dos dois, a implementação não pode ser verificada de forma autônoma.

## Alternativas descartadas
- **Evoluir o código atual endpoint por endpoint:** mexeria em tudo o que tem estado ou faz E/S, sem testes, mantendo o objeto global vivo durante a transição — o mesmo padrão que já produziu três gerações sobrepostas no código.
- **Trocar de tecnologia** (ex.: Electron/Tauri reaproveitando o web): fora das premissas aceitas (o cliente continua em Delphi FMX).
- **Só remendar e distribuir o atual:** inviável (privacidade da chamada, reconexão, sessão, build, licenças).

## Consequências
- O app atual fica congelado; remendos só se alguém depender dele (doc 06, Bloco B).
- O trabalho segue o `TODO.md`, e cada alteração é registrada em `docs/historico/`.
- Algumas funcionalidades dependem do servidor: S2/S18 (push com o desktop conectado), S13 (renovação de sessão), S4 (autenticação da mídia).
- Ordem de grandeza: ~14–20 semanas até substituir o app atual (doc 06).
