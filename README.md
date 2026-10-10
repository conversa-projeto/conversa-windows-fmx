# Conversa — cliente Windows (Delphi FMX)

Cliente Windows (Delphi 12 / FireMonkey) do **Conversa**, um serviço de mensagens instantâneas aberto: conversas diretas e em grupo, anexos, chamadas de áudio e vídeo, notificações e integração com o Windows (bandeja, barra de tarefas, iniciar com o Windows). Fala com o servidor [`conversa`](https://github.com/conversa-projeto/conversa) (Bun + Elysia) e busca paridade com o cliente web [`conversa-web`](https://github.com/conversa-projeto/conversa-web), que é a referência de comportamento.

> ⚠️ Este repositório é só o cliente. Ele precisa de um servidor Conversa.

## Estado atual: em reescrita (branch `nova-base`)

Em 2026-10-08 uma auditoria concluiu que o app atual, escrito para o antigo servidor Delphi e parado desde abril de 2026, não funciona mais com o servidor atual: anexos, "visualizada", membros de grupo, mensagens ocultas, tempo real e chamadas estão quebrados. A decisão foi **recomeçar o núcleo numa nova base Delphi FMX Win64 e transplantar a interface** ([ADR 0001](docs/adr/0001-nova-base.md), aceito em 2026-10-09).

- **Comece por:** [`docs/auditoria-2026-10/00-LEIAME.md`](docs/auditoria-2026-10/00-LEIAME.md)
- **O que fazer, passo a passo:** [`TODO.md`](TODO.md)
- **O que já foi feito:** [`docs/historico/indice.md`](docs/historico/indice.md)
- **Contrato do servidor (fonte da verdade):** [`docs/auditoria-2026-10/01-contrato-servidor-atual.md`](docs/auditoria-2026-10/01-contrato-servidor-atual.md)
- **Regras para quem trabalha no repositório (pessoas e agentes de IA):** [`CLAUDE.md`](CLAUDE.md)
- **App atual (legado):** branch `legado/abril-2026` e tag `legado-v1-final`; documentação antiga e *stashes* em [`docs/legado/`](docs/legado/LEIA.md) (desatualizada). **Não distribuir o app atual a novos usuários.**

## Como compilar

Requisitos:
- **Delphi 12 Athens** (testado com a 12.1) com FireMonkey, FireDAC (driver SQLite) e DUnitX.
- **Plataforma: Windows 64 bits (Win64)**, Windows 10 1809 ou mais novo. A nova base não tem alvo Win32.
- Para as chamadas, a mídia depende da decisão do [ADR 0002](docs/adr/0002-midia-chamadas.md) (preferência: WebView2, que já vem no Windows 10/11 atualizado).

Pelo IDE: abrir o projeto (`app/Conversa.dproj` na nova base), escolher **Win64** e **Debug**, e compilar. Os testes ficam em `testes/ConversaTestes.dproj` (console DUnitX).

Pela linha de comando (exige Delphi **Professional ou superior**; a edição Community não compila por linha de comando e o MSBuild sai com código 0 mesmo assim):

```bat
build\compilar.cmd
```

Os *scripts* de `build/` conferem o exe gerado e procuram erros no log, sem confiar no código de saída. Detalhes, dependências em tempo de execução e a lista de DLLs com *hash*: [`docs/desenvolvimento/servidor-de-dev.md`](docs/desenvolvimento/servidor-de-dev.md).

> **Licença do Delphi:** a edição Community tem limites de uso comercial (receita anual e número de desenvolvedores). Confira a licença antes de distribuir.

## Servidor de desenvolvimento

O servidor de desenvolvimento roda em contêineres (repositório `conversa`) e responde em **`https://localhost`**, com certificado do **mkcert**. Todos os caminhos ficam no mesmo endereço:

| Caminho | Uso |
|---|---|
| `/api/` | REST |
| `/ws/` | WebSocket (a barra final é obrigatória; `/ws` responde 301) |
| `/webrtc/` | MediaMTX: WHIP/WHEP |
| `/storage/` | anexos (URLs assinadas do MinIO) |

- No app, o "Endereço do servidor" é só `https://localhost` (sem `/api`); os outros caminhos são derivados dele.
- Para o Windows confiar no certificado, a CA do mkcert precisa estar no repositório de certificados do usuário (`mkcert -install`). **Nunca** desligue a validação de certificado no código.
- Contas de teste, o cliente web como "outro lado" e os limites de teste: [`docs/desenvolvimento/servidor-de-dev.md`](docs/desenvolvimento/servidor-de-dev.md).

## Documentação

| Pasta | Conteúdo |
|---|---|
| `docs/auditoria-2026-10/` | Auditoria, contrato do servidor, mudanças desde abril, inventário do web, auditoria do app atual, matriz de paridade, fila de correções, plano da nova base, pendências do servidor |
| `docs/historico/` | Registro de **toda** alteração, separado por fluxo |
| `docs/adr/` | Decisões de arquitetura |
| `docs/design/cores.md` | Paleta de cores (este app é a fonte das cores do Android) |
| `docs/contrato/openapi.json` | Contrato publicado pelo servidor (OpenAPI) |
| `docs/desenvolvimento/` | Servidor de desenvolvimento, build e dependências |
| `docs/legado/` | Documentação e *stashes* do app atual (só referência histórica) |

## Ecossistema

- [Servidor](https://github.com/conversa-projeto/conversa) — Bun + Elysia, Postgres, MinIO, MediaMTX, coturn
- [Cliente web](https://github.com/conversa-projeto/conversa-web) — Vue (referência de comportamento)
- [Cliente Android](https://github.com/conversa-projeto/conversa-android-kotlin) — Kotlin (nova base)
- [Cliente Windows](https://github.com/conversa-projeto/conversa-windows-fmx) — este repositório

## 💻 Quem contribui

<a href="https://github.com/conversa-projeto/conversa/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=conversa-projeto/conversa" />
</a>

## Licença

`Conversa` é um software gratuito e de código aberto licenciado sob a [MIT License](./LICENSE).
