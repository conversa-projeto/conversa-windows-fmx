> **Relatório de apoio da auditoria de 2026-10-08** — frente: validação dos docs 01 e 03 e comportamentos de desktop do web.
> É a varredura original, com todas as evidências. A consolidação está nos docs `00`–`08` desta pasta:
> - os números provisórios dos problemas (A1…, A3-01…, A4-01…, A5a-01…, A5b-01…, P1…) foram unificados como **#1–#103** no doc 04 (coluna "Origem");
> - as referências "doc 01/03/05/06/08" apontam para a auditoria do Android (`conversa-android-kotlin/docs/auditoria-2026-10/`), que serviu de modelo; as versões para o FMX dos docs 01 e 03 estão nesta pasta;
> - menções a "outro colega" ou "outra parte da auditoria" se referem às outras frentes (A1–A7).

# A7 — Validação dos docs 01 (contrato do servidor) e 03 (inventário do web) e comportamentos de desktop do web

> **Auditoria do cliente desktop `conversa-windows-fmx` (Delphi 12 / FireMonkey) — 2026-10-08.**
> Escopo desta parte: (1) validar `conversa-android-kotlin/docs/auditoria-2026-10/01-contrato-servidor-atual.md` contra o servidor `conversa` em **`779c8ed`**; (2) validar `03-inventario-web.md` contra `conversa-web` em **`e8d82cb`**; (3) levantar, com texto e tecla exatos, os comportamentos do web que são próprios de desktop; (4) analisar o servidor do ponto de vista de um cliente Windows **sempre conectado**.
>
> Método: leitura do código (`git` só leitura; nenhum arquivo dos repositórios foi alterado) e GETs sem efeito colateral no servidor de desenvolvimento local (`curl -sk https://localhost/...`). Referências `arquivo:linha` são relativas à raiz de cada repositório (`conversa/`, `conversa-web/`, `conversa-windows-fmx/`). Onde não houve como confirmar, está escrito **"não confirmado"**.
>
> Árvores de trabalho: `conversa` e `conversa-web` sem alterações rastreadas (só um `yarn.lock` não versionado em cada).

---

## Sumário

0. [Resumo executivo](#0-resumo-executivo)
1. [Doc 01 × servidor `779c8ed`](#1-doc-01--servidor-779c8ed)
2. [Doc 03 × web `e8d82cb`](#2-doc-03--web-e8d82cb)
3. [Comportamentos do web próprios de desktop (o que o FMX replica)](#3-comportamentos-do-web-próprios-de-desktop-o-que-o-fmx-replica)
4. [Servidor × cliente desktop sempre conectado](#4-servidor--cliente-desktop-sempre-conectado)
5. [Não confirmado / a verificar](#5-não-confirmado--a-verificar)

---

## 0. Resumo executivo

**Doc 01 (contrato):** o conteúdo está **correto no essencial** — as 69 rotas, métodos e autenticação batem com `src/rotas.ts`; a documentação viva (`GET /api/docs/json`) tem **55 caminhos / 69 operações**, o mesmo conjunto; o enum do WebSocket, os payloads dos eventos, o push, o registro de dispositivo, anexos, chamadas e enquetes conferem. As divergências são:

1. **`/ws` sem barra não "cai na página"**: o nginx responde **301 → `/ws/`** (verificado com `curl`). Corrigir §1.2 e a pegadinha 44.
2. **Rate limit do login em desenvolvimento é compartilhado por todos os clientes da rede** (todos chegam com o IP do gateway do Docker — comentário em `bin/nginx/nginx.conf:26-31`). Acrescentar em §1.2/§2.1/pegadinha 41.
3. **Números de linha desatualizados** em `rotas.ts` (+1 nas rotas 1–46 e +9 nas 47–64), `websocket.ts`, `mensagens.ts` e `enquetes.ts` — vêm de `7f670c3`/`8031fa5`. Tabela de correção em §1.1/§1.6.
4. Detalhes: linha 65 da §4 sem `encerra_em?`; §11.2 sem `"enquete"` em `ultima_mensagem_texto`; §13.2 diz `versao` "hoje 34" (é **36**); §16 diz "migrações 000–035" (é 000–036); cabeçalho não cita `779c8ed` (sem mudança de contrato).
5. Acréscimos úteis: `tipo` do WebSocket precisa ser **número JSON** (comparação estrita); um `tipo:1` recusado pode ser repetido **na mesma conexão**; a documentação viva agora declara `additionalProperties:false` em 17 corpos (efeito real não confirmado).
6. 14 trechos são específicos do Android (Kotlin, OkHttp, `network_security_config`, FCM/Doze, `onNewToken`, `JsonPrimitive`, `Instant.parse`, libwebrtc...). Texto equivalente para desktop Windows em §1.7.

**Doc 03 (inventário):** a contagem de **137 IDs confere**, sem lacuna nem duplicata. Dos **82 itens conferidos** (de todos os grupos), a maioria bate, inclusive textos sem acento e tempos (30 s, 25 s, 15 s, 4 s, 3 s, 2,5 s, 80/60/30/120, `limite=60`). As divergências estão onde `eaa8bac`/`e8d82cb` mudaram o web e o corpo do doc não acompanhou:
- **CON-08** descreve o modal apagado (hoje `PainelGrupo`);
- **CON-09** cita "Gerenciar membros", que não existe mais;
- **ENV-21** cita `utils/editorRico.ts`/`blocosEditor.ts`, apagados (hoje Tiptap em `src/editor/`);
- **ENV-01/02/05/09/11/20** com detalhes superados (40vh, menção como nó do editor, colagem de código já cercada, qualquer arquivo colado vira peça, botão em seta);
- **§4.1** sem as 5 rotas de enquete e **§4.2** sem o evento 62;
- **§1.3** `CAMPOS_DATA` sem `encerra_em`/`encerrada_em`; **§1.7** não diz que o web **não chama** `POST /anexo/confirmar`;
- **CFG-08** cita um texto "Modo aberto" que não existe;
- **AUT-01** espera `avatar_url` que o servidor não manda.
Achados de passagem no web: `v-html` sem escapar na pesquisa global (`PesquisaAvancada.vue:50,103-108`) e rascunhos que sobrevivem ao logout.

**Desktop (§3):** o web já tem quase tudo de desktop: Enter envia / Shift+Enter quebra / Tab = 4 espaços / letra fora do campo foca o campo / Esc fecha menus / Ctrl+Enter envia o código / Ctrl+Z/Y no campo / ←→ +/− Ctrl+C no visualizador; arrastar arquivos para a conversa ("Solte para enviar o arquivo"); colar imagem (`print-<ms>.<ext>`) e texto > 10 linhas (janela "Inserir código"); clique direito = menu completo, **Ctrl + clique direito = só reações**; hover de 300 ms no ✓ (detalhe de status); popup de conversa 900×700 com **WebSocket e store próprios, sem nenhum canal com a janela principal**; janela flutuante de chamada **só para vídeo** (420×350, mín. 320×240); discador SIP flutuante (288 px). **Não existe** contador no título da aba nem no favicon, nem seleção de microfone/câmera/alto-falante (a aba "Dispositivos" só lista).

**Servidor × desktop sempre conectado (§4):** confirmado em `src/notificacoes.ts:71` + `src/websocket.ts:131-133`: o push só é enviado se o usuário **não tiver nenhuma** conexão WebSocket — a regra é **por usuário, não por aparelho**. Com o FMX aberto o dia todo, **o celular (e o navegador fechado) do mesmo usuário não recebem push de mensagem nenhuma**, e o usuário aparece "online" o tempo todo. Mudança necessária no servidor: rastrear conexões **por dispositivo** (S2 do doc 08) e/ou um aviso de "ausente" do desktop. Outros pontos de servidor que afetam um cliente nativo: rate limit compartilhado, 413/503/502 em HTML, `Host` usado nas URLs assinadas e no TURN, JWT de 12 h sem renovação, pings de protocolo de payload vazio (o cliente WebSocket do FMX parece não tratar quadros de tamanho 0 — §4.4), eventos que **não chegam aos outros aparelhos do mesmo usuário** (leitura, envio, reação).

---

## 1. Doc 01 × servidor `779c8ed`

### 1.1 Rotas (§4) — contagem, métodos, autenticação

- **Contagem: 69** chamadas `.get/.post/.put/.patch/.delete` em `src/rotas.ts` (linhas 34–220). Públicas: `POST /login` (`rotas.ts:34`) e `PUT /usuario` (`rotas.ts:39`); todas as demais ficam depois do `.resolve(...)` que exige o token (`rotas.ts:43`). **Bate com o doc (2 públicas + 67 autenticadas).**
- `GET /ice` (`rotas.ts:212`) também exige token, mas é a única que **não** abre conexão de banco (`comOrigemPublica` direto, sem `comoUsuario`). Sem efeito para o cliente.
- **Documentação viva:** `curl -sk https://localhost/api/docs/json` → **55 caminhos, 69 operações** (GET/POST/PUT/PATCH/DELETE), exatamente o conjunto de `rotas.ts`. O `/ws/` não aparece no OpenAPI (é WebSocket). Cópia salva em `scratchpad/auditoria-fmx/openapi-a7.json`.
  - Diferença com a cópia do Android (`conversa-android-kotlin/docs/contrato/openapi.json`, commit `cda97f2`): mesmas 69 operações, mas o JSON vivo declara **`additionalProperties: false`** no corpo de 17 rotas (login, `PATCH /dispositivo`, digitando, gravando, `PUT /mensagem`, visualizar, reproduzir, chamada cancelar/entrar/sair/finalizar/chat/video e as 4 de enquete com corpo). O doc 01 §3 diz que "campos extras no corpo são ignorados". Com o Elysia 1.4.30 (`package.json:19`), o padrão `normalize` **remove** campos extras em vez de recusar (pelo que se sabe do Elysia) — **não confirmado** (seria preciso um POST). Recomendação para o FMX: **não enviar campos extras**.
- **Métodos e caminhos:** todos os 69 conferem com a tabela da §4.
- **Ordem no código:** as 5 rotas de enquete estão **no meio** de `rotas.ts` (linhas 171–177, entre `/chamada/finalizar` e `/usuario/permissoes`), não no fim. A tabela do doc as numera 65–69 por conveniência — tudo bem, só a referência de linha muda.

**Coluna "Ref. rota" desatualizada.** As linhas do doc são de `7f670c3`, antes do `import * as enquetes` (`rotas.ts:9`) e das 7 linhas de enquete. Regra: linhas 1–46 do doc **+1**; 47–64 **+9**; 65–69 sem número no doc.

| # doc | Rota | Doc diz | Atual |
|---|---|---|---|
| 1 | `POST /login` | 33 | **34** |
| 2 | `PUT /usuario` | 38 | 39 |
| 3 | `POST /alterar-senha` | 46 | 47 |
| 4 | `PATCH /dispositivo` | 51 | 52 |
| 5 | `PUT /dispositivo/usuario` | 53 | 54 |
| 6 | `PATCH /usuario` | 56 | 57 |
| 7 | `DELETE /usuario` | 58 | 59 |
| 8 | `PUT /usuario/contato` | 60 | 61 |
| 9 | `DELETE /usuario/contato` | 63 | 64 |
| 10 | `GET /usuario/contatos` | 65 | 66 |
| 11 | `GET /contatos/online` | 67 | 68 |
| 12 | `PUT /conversa` | 71 | 72 |
| 13 | `PATCH /conversa` | 73 | 74 |
| 14 | `DELETE /conversa` | 75 | 76 |
| 15 | `GET /conversas` | 77 | 78 |
| 16 | `PATCH /conversa/fixadas` | 79 | 80 |
| 17 | `PATCH /conversa/arquivada` | 82 | 83 |
| 18 | `GET /conversa/usuarios` | 85 | 86 |
| 19 | `PUT /conversa/usuario` | 88 | 89 |
| 20 | `DELETE /conversa/usuario` | 90 | 91 |
| 21 | `POST /conversa/digitando` | 92 | 93 |
| 22 | `POST /conversa/gravando` | 97 | 98 |
| 23 | `PUT /mensagem` | 104 | 105 |
| 24 | `DELETE /mensagem` | 106 | 107 |
| 25 | `GET /mensagens` | 108 | 109 |
| 26 | `POST /mensagem/visualizar` | 111 | 112 |
| 27 | `POST /mensagem/reproduzir` | 114 | 115 |
| 28 | `GET /mensagem/status` | 117 | 118 |
| 29 | `GET /mensagem/status/detalhe` | 120 | 121 |
| 30 | `GET /mensagens/novas` | 123 | 124 |
| 31 | `GET /pesquisar` | 127 | 128 |
| 32 | `PUT /mensagem/reacao` | 130 | 131 |
| 33 | `GET /anexo/existe` | 134 | 135 |
| 34 | `GET /anexo` | 136 | 137 |
| 35 | `PUT /anexo` | 138 | 139 |
| 36 | `POST /anexo/confirmar` | 140 | 141 |
| 37 | `GET /anexos` | 142 | 143 |
| 38 | `GET /anexo/transcricao` | 146 | 147 |
| 39 | `PUT /anexo/transcricao` | 149 | 150 |
| 40 | `PUT /chamada/iniciar` | 154 | 155 |
| 41 | `POST /chamada/cancelar` | 156 | 157 |
| 42 | `POST /chamada/entrar` | 158 | 159 |
| 43 | `POST /chamada/recusar` | 160 | 161 |
| 44 | `POST /chamada/sair` | 163 | 164 |
| 45 | `PUT /chamada/usuario` | 165 | 166 |
| 46 | `POST /chamada/finalizar` | 168 | 169 |
| 47 | `GET /usuario/permissoes` | 170 | **179** |
| 48 | `GET /permissoes` | 172 | 181 |
| 49 | `PUT /permissao/usuario` | 174 | 183 |
| 50 | `DELETE /permissao/usuario` | 177 | 186 |
| 51 | `GET /parametros` | 180 | 189 |
| 52 | `PATCH /parametros` | 182 | 191 |
| 53 | `GET /atividades` | 184 | 193 |
| 54 | `GET /atividades/novas` | 186 | 195 |
| 55 | `POST /atividades/vistas` | 188 | 197 |
| 56 | `PUT /chamada/chat` | 190 | 199 |
| 57 | `GET /chamada/dados` | 192 | 201 |
| 58 | `GET /chamadas/pendentes` | 194 | 203 |
| 59 | `GET /chamadas` | 196 | 205 |
| 60 | `POST /chamada/video` | 198 | 207 |
| 61 | `GET /ice` | 203 | 212 |
| 62 | `GET /sip` | 207 | 216 |
| 63 | `PUT /sip` | 209 | 218 |
| 64 | `PATCH /sip` | 211 | 220 |
| 65 | `PUT /enquete` | "rotas.ts (`8031fa5`)", `enquetes.ts:12-45` | `rotas.ts:171`; `enquetes.ts:13-48` |
| 66 | `GET /enquete` | `enquetes.ts:54-78` | `rotas.ts:173`; `enquetes.ts:114-137` (leitura em `lerEnquete`, 82-96) |
| 67 | `POST /enquete/votar` | `enquetes.ts:82-116` | `rotas.ts:175`; `enquetes.ts:141-167` |
| 68 | `POST /enquete/encerrar` | "`enquetes.ts` (`encerrarEnquete`)" | `rotas.ts:176`; `enquetes.ts:170-181` |
| 69 | `PATCH /enquete` | "`enquetes.ts` (`alterarPrazoEnquete`)" | `rotas.ts:177`; `enquetes.ts:184-196` |

Outras referências a `rotas.ts` no texto: §1.4 `rotas.ts:20-23` → **21-24**; §2.1 `33-36` → **34-37**, `:35` (claims) → **36**; §2.3 `:42` → **43**; §4 (prefixo) `:28` → **29**; §8.3 `134-136` → **135-137**.

Corpo da linha 65 (`PUT /enquete`): falta **`encerra_em?: string|null`** (`src/esquemas.ts:95`); está só na §10.13.

### 1.2 WebSocket (§6)

**Enum (§6.4) × `src/websocket.ts:4-23`: confere integralmente** — 0, 1, 2, 3, 4, 5, 7, 40, 51–57, 60, 61, 62 com os mesmos nomes; o 6 não existe; o 9 (erro de leitura) é enviado fora do enum (`websocket.ts:61-68`).

**Mensagens do cliente (§6.5): confere.** Só `tipo 1` (login) e `tipo 57` (sinal); o resto é ignorado.
- Acrescentar: a comparação é **estrita com número** (`mensagem.tipo === TipoMensagemSocket.SinalChamada`, `websocket.ts:71`; `mensagem.tipo !== TipoMensagemSocket.Login`, `:79`). `{"tipo":"1"}` (texto) é **ignorado em silêncio**. Para o Delphi: gerar `TJSONNumber`, nunca `TJSONString`.
- Acrescentar: o vínculo conexão→usuário só é gravado quando o token é aceito (`websocket.ts:90`). Um `tipo:1` recusado (resposta `tipo:0`) pode ser **repetido na mesma conexão** com outro token. Depois de aceito, um novo `tipo:1` é ignorado (`:79-81`), e o servidor não confere mais a validade do token.
- `tipo:57` antes do login é descartado em silêncio (`websocket.ts:72-76`).

**Payloads e emissores (§6.6): conferem.**

| tipo | Payload no código | Emissor (atual) | Doc |
|---|---|---|---|
| 0 | `{tipo, message}` | `websocket.ts:87` | ✔ |
| 2 | `{tipo, titulo, mensagem}` | `websocket.ts:135-137`; chamado por `notificacoes.ts:69` | ✔ (uma vez **por linha** da consulta usuário × `token_fcm` distinto, `notificacoes.ts:56-69` — explica o duplicado) |
| 3 | `{tipo, grupo, mensagens}` | `websocket.ts:139-141`; `notificacoes.ts:43-49` | ✔ |
| 4/5 | `{tipo, conversa_id, usuario_id}` | `websocket.ts:143-145`; `conversas.ts:238-241` | ✔ |
| 7 | `{tipo, conversa_id, mensagem_id, usuario_id, emoji, acao}` | `websocket.ts:147-149`; `mensagens.ts:761-765` | ✔ |
| 40 | `{tipo, conversa_id, usuario_id}` | `conversas.ts:233`, `chamadas.ts:258`, `:279` | ✔ |
| 51–56 | `{tipo, chamada_id, usuario_id}` | `websocket.ts:166-168`; `chamadas.ts:108,158,193-195,208-210,223,289,298,304` | ✔ |
| 57 | `{tipo, chamada_id, usuario_id, dados}` | `websocket.ts:162-164` (servidor), `:218-222` (repasse) | ✔ |
| 60 | `{tipo, usuario_id, online}` | `websocket.ts:230-243` | ✔ |
| 61 | `{tipo}` | `websocket.ts:157-159` | ✔ |
| 62 | `{tipo, enquete_id, conversa_id}` | `websocket.ts:152-154`; `enquetes.ts:99-105` (a todos os membros) | ✔ |
| 9 | `{tipo:9, message}` | `websocket.ts:61-68` | ✔ |

**Referências de linha desatualizadas em §1.2, §6 e §15** (o arquivo ganhou 1 linha no enum e 5 com `notificarEnquete`): `/ws/` está em `websocket.ts:56` (doc: 52-55/55); erros de leitura 61-68 (doc 60-68); login 83-90 (doc 83-88); segundo login 79-81 (doc 78-80); `enviar` 120-129 (doc 119-128); `usuarioConectado` 131-133 (doc 130-132); `notificarAtividade` 157-159 (doc 151-153); sinal do servidor 162-164 e repasse 218-222 (doc 156-158, 213-215); cache de participantes 170-199 (doc 164-221); `notificarContatosStatus` 230-243 (doc 223/224-237).

### 1.3 Push (§7.2) e registro do dispositivo (§7.3)

- **Payload (§7.2): confere.** `src/fcm.ts:30-36`: `{ token, data: { titulo, mensagem, conversa: String(conversa) }, webpush: { headers: { Urgency: 'high' } } }`; sem bloco `notification` nem `android`. Troca de `\n` na chave em `fcm.ts:13`. Referência do doc `fcm.ts:28-36` → **30-36** (28-29 é o comentário).
- **Texto (`mensagem`): confere.** `resumirTexto`/`textoConteudo` em `src/mensagens.ts:123-145` (tipo 8 → `enquete` em `:142`); junção com `" | "` em `:229`; agendada com áudio → `áudio` em **`:284`** (doc: 279); emissão em **`:217-230`** (doc: 212-225).
- **Quando (§7.1): confere.** `notificarNovaMensagemConversa` (`notificacoes.ts:52-76`) é chamada só por `mensagens.ts:229` (envio imediato) e `:285` (agendada que amadurece) — doc cita 222-225 e 264-283.
- **Plataforma (§7.3):** `plataforma` é **texto livre** (`opcional(texto)`, `src/esquemas.ts:32`); não há lista de valores. O web manda `'Web'` (`conversa-web/src/stores/auth.ts:128`). O exemplo do doc usa `"android"`.
- **Limites (§7.3): conferem** com `migracoes/002.sql:4-7` (`nome` 50, `modelo` 50, `versao_so` **15**, `plataforma` **15**) e `004.sql:2` (`token_fcm` 255). Acima do limite → 500 (erro do Postgres). Para Windows: `versao_so` como `10.0.22621` (10) cabe; `Windows 11 Pro 10.0.22621` (25) **não cabe**.
- **Handler: confere.** `src/usuarios.ts:76-90`: sem campo além de `id` devolve o eco do corpo **sem conferir o dono** (`:77-79`); com campos, confere o dono (403) e grava só `nome, modelo, versao_so, plataforma, token_fcm` (`:12`). `ativo` não é alterável por rota nenhuma.
- **Vários aparelhos (responde à dúvida S2.3 do doc 08):** o login só reaproveita o dispositivo enviado ou cria um novo (`usuarios.ts:47-60`); **não desativa os outros**. A consulta do push percorre todos os dispositivos ativos com token (`notificacoes.ts:56-66`). Web + celular + desktop coexistem.

### 1.4 Anexos (§8.2), chamadas (§9), enquetes (§10.13)

- **Anexos: confere.** `src/anexos.ts:30-31` (1 GiB; tipos 2–5), `:33-39` (existe), `:41-56` (GET 600 s), `:58-81` (PUT: existente → `id` **string** + URL **GET** 600 s; novo → `id` número + URL **PUT** 300 s + `upload_status:0`), `:83-95` (confirmar pela query). `src/minio.ts:33-46`: a URL é assinada com o host da requisição e ganha `/storage` fora da assinatura. Nenhuma linha mudou.
- **Chamadas: confere**, inclusive linhas (o arquivo não mudou desde `7f670c3`): `validarChamada` 404 (`chamadas.ts:70-82`), `iniciar` (`:88-110`, tipo padrão `:90`), `recusar` com `nao_atendeu` e WS 53 também a si (`:164-197`), `entrar` com WS 54 a si (`:199-212`), `sair` sem WS 52 (`:214-225`), chat (`:230-281`), regras de status (`:452-505`), resumo tipo 6 com datas `to_char` sem fuso (`:416-427`, `:507-560`), ICE (`:576-594`).
- **Enquetes: conferem** comportamento e mensagens de erro com `src/enquetes.ts` e as migrações:
  - `035.sql:3-29`: `enquete` (`pergunta` varchar 300), `enquete_opcao` (`texto` 200), `enquete_voto` com `unique (opcao_id, usuario_id)`;
  - `036.sql:33-35`: `encerra_em`, `encerrada_em`, `encerrada_por`;
  - criação só em grupo (`enquetes.ts:16-18`); pergunta e opções aparadas, ≥ 2 opções, sem repetição sem diferenciar maiúsculas (`:19-29`);
  - prazo cortado no minuto, ≥ agora+1 min, ≤ 1 ano (`:51-66`);
  - `encerrada` calculada na leitura (`:86`); `pode_encerrar`/`pode_alterar_prazo` (`:131-132`);
  - votar substitui o voto (`:158-163`) e recusa encerrada (`:143-145`); encerrar (`:170-181`) e prazo (`:184-196`) com as mensagens 403/400 do doc; WS 62 a **todos** os membros (`:99-105`).
  - Só as **referências de linha** do doc estão velhas (são de `8031fa5`).

### 1.5 Pegadinhas (§19) conferidas — 41 de 50, de todas as seções

| Nº | Seção | Resultado | Evidência (servidor `779c8ed`) |
|---|---|---|---|
| 1 | Nomes | ✔ (`iceServers`, `iceTransportPolicy` só no `/ice`) | `chamadas.ts:576-594` |
| 2 | Nomes | ✔ | `esquemas.ts:58-65` |
| 3 | Nomes | ✔ (`conversa` em `marcarStatus`/`arquivarConversa`; `id` em digitando; `grupo` no WS 3) | `esquemas.ts:47,66,41`; `websocket.ts:140` |
| 4 | Nomes | ✔ | `mensagens.ts:190-195,231` × `:603-618` |
| 5 | Nomes | ✔ (`destino_mensagem_id: referencia.origem_mensagem_id`) | `mensagens.ts:202` |
| 6 | Nomes | ✔ | `anexos.ts:65`; `rotas.ts:36`; `fcm.ts:33`; `websocket.ts:140` |
| 8 | Nomes | ✔ | `parametros.ts:19` |
| 9 | Datas | ✔ (JSON de `Date`; sessão UTC) | `banco.ts:16-25` |
| 10 | Datas | ✔ | `chamadas.ts:420-424` |
| 11 | Datas | ✔ (`de` como `::timestamp`, `ate` como `::date + 1`) | `chamadas.ts:440-441` |
| 12 | Datas | ✔ | `mensagens.ts:156-170` |
| 13 | Nulos | ✔ (chaves só quando existem) | `mensagens.ts:612,617` |
| 15 | Nulos | ✔ | `sip.ts:9-10`; `usuarios.ts:77-79` |
| 16 | Nulos | ✔ | `chamadas.ts:329`; `:332-389` (sem `conversa_id`) |
| 17 | Nulos | ✔ (nenhuma rota grava `alterada`; status 5 nunca gravado) | `chamadas.ts` inteiro |
| 18 | Comport. | ✔ (`excluida_em` + conteúdos completos) | `mensagens.ts:603-618`; `:306-314` |
| 19 | Comport. | ✔ (`inner join anexo`) | `mensagens.ts:441-442` (doc: 436-437) |
| 20 | Comport. | ✔ (`0 === 0`) | `mensagens.ts:575,613-615` |
| 21 | Comport. | ✔ (`limit 100`; marca todas as pendentes) | `mensagens.ts:536,540-551` (doc: 531, 535-546) |
| 22 | Comport. | ✔ | `mensagens.ts:623-634` |
| 23 | Comport. | ✔ (`order by ultima_mensagem desc`, nulos primeiro no Postgres) | `conversas.ts:176-177` |
| 24 | Comport. | ✔ — **acrescentar `"enquete"`** | `conversas.ts:126-133` |
| 25 | Comport. | ✔ | `usuarios.ts:142-144` |
| 26 | Comport. | ✔ | `conversas.ts:39-44` |
| 27 | Comport. | ✔ (FK sem cascade) | `conversas.ts:51-54`; `migracoes/000.sql:36,47,68` |
| 28 | Comport. | ✔ | `conversas.ts:243-246` |
| 29 | Comport. | ✔ (uma linha por usuário × `token_fcm` distinto) | `notificacoes.ts:56-69` |
| 30 | Comport. | ✔ | `notificacoes.ts:71`; `websocket.ts:131-133` |
| 31 | Comport. | ✔ (`enviarPush` só em `notificacoes.ts:73`) | `grep enviarPush src` |
| 32 | Comport. | ✔ | `fcm.ts:30-36` |
| 33 | Comport. | ✔ | `chamadas.ts:90,99-103` |
| 34 | Comport. | ✔ | `chamadas.ts:214-225` |
| 35 | Comport. | ✔ | `chamadas.ts:70-82` |
| 36 | Comport. | ✔ (`urls` string; 1 h; relay) | `chamadas.ts:587-592`; `bin/coturn/turnserver.conf` (`no-udp`, `no-tls`, `no-tcp-relay`) |
| 37 | Comport. | ✔ (`all_others` sem auth; anexo sem checagem) | `bin/mediamtx/mediamtx.docker.yml:26-38`; `anexos.ts:41-56` |
| 38 | Comport. | ✔ | `anexos.ts:63-66` |
| 39 | Comport. | ✔ | `rotas.ts:141` |
| 40 | Comport. | ✔ | `minio.ts:33-46`; `anexos.ts:55,65,80` |
| 41 | Comport. | ✔ — **acrescentar o IP compartilhado em dev** | `nginx.conf:24,26-31,74,97-100` |
| 42 | Comport. | ✔ (`extensao` 10, `emoji` 10, dispositivo 50/15) | `migracoes/001.sql:2`, `018.sql:6`, `002.sql:4-7` |
| 44 | Comport. | ✔ em parte — **`/ws` dá 301, não "cai na página"** | `curl -sk -i https://localhost/ws` → `301 Location: https://localhost/ws/` |
| 47 | Enquete | ✔ | `mensagens.ts:150-152` |
| 48 | Enquete | ✔ | `enquetes.ts:158-163` |
| 49 | Reação | ✔ (`LIMITE_REACOES_POR_PESSOA = 5`) | `mensagens.ts:728,744-748` |
| 50 | Enquete | ✔ (nenhuma tarefa trata prazo) | `tarefas.ts:97-104`; `enquetes.ts:86` |

Não conferidas a fundo: 7, 14, 43, 45, 46 (parcial: confirmadas a falta de refresh/logout/edição e de eventos de saída de membro e de fim de transcrição).

### 1.6 Divergências consolidadas do doc 01 e correção sugerida

| # | Onde | Divergência | Correção |
|---|---|---|---|
| D1 | Cabeçalho, §20 | Diz "último commit lido `5cad911`"; o HEAD é `779c8ed` | Acrescentar "`779c8ed` (só `bin/iniciar-desenvolvimento.bat`, sem mudança de contrato)" — `git show --stat 779c8ed` |
| D2 | §1.2 linha `/ws/`; pegadinha 44 | "`/ws` sem barra **não casa** com a `location` e cai na página" | "`/ws` sem barra recebe **301** para `/ws/` (redirecionamento automático do nginx para `location` com barra e `proxy_pass`). A maioria dos clientes WebSocket não segue redirecionamento: o handshake falha. Sempre usar `/ws/`." (verificado com `curl`) |
| D3 | §1.2 login, §2.1 tabela de erros, pegadinha 41 | Não diz que o limite é compartilhado | "Em desenvolvimento (sem borda) **todos os clientes chegam com o IP do gateway do Docker** (`nginx.conf:26-31`): os 10/min + rajada de 5 valem para **a rede inteira**. Em produção vale o IP real enviado pela borda em `X-Forwarded-For`." Também: o `X-Forwarded-For` vindo de 172.16.0.0/12 é aceito (`:29-31`) |
| D4 | §4 "Ref. rota" e §1.4, §2.1, §2.3, §8.3 | Linhas de `7f670c3` | Tabela da §1.1 deste relatório |
| D5 | §4 linha 65 | Corpo sem `encerra_em?` | Acrescentar `encerra_em?: string\|null` (`esquemas.ts:95`) |
| D6 | §1.2, §6.1–§6.7, §15 | Linhas de `websocket.ts` deslocadas | §1.2 deste relatório |
| D7 | §7.1, §7.2, §10.x | Linhas de `mensagens.ts` deslocadas (+5 depois da linha ~140) | Ex.: `limit 100` em 536; montagem de `MensagemResposta` 603-618; reações 727-768; agendada `áudio` 284 |
| D8 | §10.13 e §4 65–69 | Linhas de `enquetes.ts` de `8031fa5` | §1.1 deste relatório |
| D9 | §11.2 (`ultima_mensagem_texto`) | Lista imagem/figurinha/"" e omite enquete | Acrescentar `"enquete"` (tipo 8) — `conversas.ts:131` |
| D10 | §13.2 | `versao` "hoje `34`" | **36** (`migracoes.ts:29-37` grava o último arquivo; há até `036.sql`) |
| D11 | §16 | "migrações 000–035" | 000–036 (a própria tabela já cita `036.sql`) |
| D12 | §6.5 | Não diz que `tipo` é número estrito nem que o login recusado pode ser repetido | §1.2 deste relatório |
| D13 | §3 | "Campos extras são ignorados" | Acrescentar: o OpenAPI vivo declara `additionalProperties:false` em 17 corpos; efeito real não confirmado; não enviar extras |
| D14 | §7.3 | Exemplo `"plataforma": "android"`; não diz que o valor é livre | "Texto livre até 15 caracteres; o web usa `Web`" |
| D15 | §6.1 | "Em desenvolvimento local sem nginx: `ws://127.0.0.1:8080/ws/`" | Avisar que, sem o nginx, falta `X-Forwarded-Proto` e o `Host` vira `127.0.0.1:8080`: as URLs de MinIO/TURN saem erradas (`contexto.ts:9-12`). Usar sempre o nginx |

### 1.7 Trechos do doc 01 específicos do Android → texto para cliente desktop Windows

| Onde no doc 01 | Texto atual (Android) | Texto proposto (desktop Windows / FMX) |
|---|---|---|
| Título (linha 1) | "referência para o cliente Android Kotlin" | "referência para o cliente desktop Windows (Delphi 12 / FireMonkey)" |
| §1.3, pegadinha 45 | "O Android precisa confiar na CA raiz do mkcert (ex.: `network_security_config`...)" | "O certificado de desenvolvimento é do **mkcert**, com nomes `localhost`, `127.0.0.1` e o IP digitado no `bin/setup-cert.bat` (`:51`): o cliente precisa usar um desses nomes. Na máquina do servidor, o `mkcert -install` já põe a CA no repositório do Windows. Em outro PC, importar o `rootCA.pem` (pasta de `mkcert -CAROOT`) em **Autoridades de Certificação Raiz Confiáveis** do usuário atual (`certutil -user -addstore Root rootCA.pem`). O `TNetHTTPClient` (WinHTTP/SChannel) usa esse repositório. Bibliotecas com **OpenSSL** (Indy, usada pelo cliente WebSocket do FMX) **não usam**: precisam do PEM da CA e da verificação ligada. Nunca aceitar qualquer certificado. Em produção o certificado é público, na borda." |
| §2.1 `dispositivo_id` | "Id do dispositivo salvo no aparelho" | "Id do dispositivo salvo no computador, por usuário do Windows (ex.: `%APPDATA%\Conversa`), e reenviado em todo login" |
| §2.4 | "Regra prática para o Android: **401 = deslogar**" | "Regra prática para o desktop: **401 = sessão vencida**. O app fica aberto o dia todo e o token dura 12 h, então isso acontece todo dia: refazer o login (senha guardada com DPAPI/Gerenciador de Credenciais, ou pedir ao usuário), com `dispositivo_id`, sem laço (o login tem limite de taxa)" |
| §6.7 | "Recomendação para OkHttp: `pingInterval(30, SECONDS)`" | "No desktop: responder aos **pings de protocolo** do servidor, inclusive os de **payload vazio**, com pong (o Bun os envia sozinho, pelo que se sabe); reconectar com `min(30 s, 1 s × 2^n)`; com o socket fora, polling de 8 s de `/mensagens/novas` e `/chamadas/pendentes`; ao reconectar, a sequência da §6.7" |
| §7 (título e §7.1–§7.2) | Push FCM como canal do Android; "sujeita a atraso em **Doze**" | "**O desktop não usa FCM.** O dispositivo Windows fica com `token_fcm = null`; mensagens chegam pelo WebSocket (WS 2 → `GET /mensagens/novas`), e a notificação é um **toast local do Windows** (ver doc 03 NOT-01/02). O bloco `android`/Doze só afeta o celular. Atenção: enquanto o desktop estiver conectado, **os outros aparelhos do usuário não recebem push** (§4 deste relatório)" |
| §7.3 passos 2–4 | `PATCH /dispositivo` com `"plataforma": "android"` e `token_fcm`; "atualizar quando o Firebase renovar"; "para parar os pushes, `token_fcm: null`" | "`PATCH /api/dispositivo {id, nome: <nome do computador, ≤ 50>, modelo: 'Desktop', versao_so: <ex. 10.0.22621, ≤ 15>, plataforma: 'Windows'}` **sem `token_fcm`**. Não há token para renovar. "Sair": só fechar o WebSocket e apagar o token local (não há rota de logout)" |
| §9.10 | "No Android (libwebrtc), ordenar os codecs ... H264 primeiro" | "No desktop (pilha WebRTC nativa usada pelo FMX), publicar vídeo em **H264** (ou VP9); VP8 funciona, mas **não é gravado**" |
| §10.6 | "no Android, embutir as animações no app" | "No desktop, embutir os JSON Lottie (o `bin/web` de produção não tem `figurinhas/`) e animar com Skia (`TSkLottieAnimation`, Skia4Delphi), ou mostrar o texto `Figurinha`" |
| §10.7 | Exemplo com cerca ` ```kotlin ` | Exemplo neutro (` ```pascal `) |
| §15.1 | "Consequência para o Android: ... **não recebe push**. Fechar o socket ao ir para segundo plano ... reativa o push" | "Consequência para o desktop: o app fica conectado o dia todo (inclusive minimizado na bandeja), então o usuário aparece **online o tempo todo** e **nenhum aparelho dele recebe push de mensagem** enquanto o PC estiver ligado com o app aberto. Ver §4 deste relatório e S2 do doc 08" |
| §18 itens 2, 3, 15 | "Dispositivo/FCM ... `onNewToken`"; "Push de dados: montar a notificação localmente"; "(opcional no Android)" | 2: "Dispositivo: `PATCH /dispositivo` com nome/modelo/versão/plataforma, sem `token_fcm`"; 3: "Notificação: toast local a partir do WS 2 + `/mensagens/novas` (sem FCM)"; 15: "telas Sistema e Acessos conforme `/usuario/permissoes`, como no web" |
| §19 pegadinha 6 | "Use desserialização tolerante (ex.: `JsonPrimitive` → Long)" | "Leitura tolerante: aceitar `TJSONNumber` **ou** `TJSONString` e converter para `Int64`" |
| §19 pegadinha 7 | "cabe em Long" | "cabe em `Int64`" |
| §19 pegadinha 9 | "Parse com `Instant.parse`" | "Converter com `ISO8601ToDate(valor, False)` (`System.DateUtils`) para ter UTC e só converter para hora local na tela; nunca `StrToDateTime`" |
| §19 pegadinha 31 | "com o app morto/sem socket, o aparelho não toca" | "o desktop só toca com o app aberto (WS 51); com o app fechado não há como tocar; ao abrir, `GET /chamadas/pendentes` (o web recusa como perdida a pendente com mais de 25 s)" |
| §19 pegadinha 32 | "Push sem `android.priority`" | "Não se aplica ao desktop (sem FCM)" |

---

## 2. Doc 03 × web `e8d82cb`

Conferência por amostragem: **82 linhas (83 IDs) de todos os 13 grupos**, mais as seções gerais (§1.3–§1.7, §2.x, §4.1, §4.2) e a contagem. Os itens de desktop (ENV-09/11/12/20, CON-05/10, CHA-13, SIP-03, NOT-01/02, MSG-09/12/18, ANX-02/04, CFG-03..06, GER-04/05) foram conferidos linha a linha junto com a §3 deste relatório. Caminhos relativos a `conversa-web/src/`, salvo indicação.

### 2.1 Contagem e IDs

- **137 IDs conferem**, sem lacuna nem duplicata: AUT 10, CON 13, MSG 20, ENV 23, ANX 15, PES 2, CHA 24, SIP 5, NOT 6, PRE 1, ATV 3, CFG 8, GER 7 (`grep` dos cabeçalhos `**XXX-NN` e `### XXX-NN` no doc).
  - Os quatro de `39d06f9` (ENV-21, ENV-22, MSG-20, CHA-24) estão só na §10 do doc; o ENV-23 está só como item de lista na §12 (linha 1263), não na §3.4.
  - A linha 1222 ("o total segue 136") é histórica e está certa para aquele momento.
- O **cabeçalho** do doc (linha 3) ainda não cita `7322e83` nem `e8d82cb` (só a §12 os cita).

### 2.2 Itens conferidos

| ID | Confere? | Divergência | Evidência |
|---|---|---|---|
| AUT-01 | parcial | O doc (e o tipo do web) diz que o login devolve `avatar_url`; o servidor **não** devolve (só `avatar_identificador`; doc 01 §2.1). O web lê `response.avatar_url ?? null` e resolve a URL depois. Textos conferem | `components/LoginForm.vue:5,10,22,39,43-44,68,77-79`; `stores/auth.ts:144-157`; `conversa/src/usuarios.ts:19-66` |
| AUT-02 | sim | — | `RegisterForm.vue:6,11,21,32,43,49,62,66-67,96-97` |
| AUT-07 | sim | Textos sem acento conferem ("A confirmacao da senha nao confere.") | `ProfileSettingsModal.vue:175-193,869-890` |
| AUT-08 | sim | — | `ProfileSettingsModal.vue:68-99,781-832`; `utils/imageResize.ts:9-33` |
| AUT-10 | parcial | "Nao informado" vale também para o **Email**, não só Telefone | `UserInfoModal.vue:31,35,46`; `utils/userProfile.ts:17-34` |
| CON-01 | sim | Ordem: fixadas por `fixada_ordem`, depois `mensagem_id` desc; arquivadas também por `mensagem_id` desc | `ChatSidebar.vue:53,129-135,289-306` |
| CON-02 | parcial | "Nova conversa" só aparece **com termo digitado** (sem termo, a lista é vazia) | `ChatSidebar.vue:407-420` |
| CON-03 | sim | — | `stores/chat.ts:177-207`; `ChatSidebar.vue:62,316-340` |
| CON-05 | sim | Abre no ponto do clique, recua pelo tamanho real; fecha com clique fora, Esc e redimensionar | `ChatSidebar.vue:72,350-358,391-405` |
| CON-06 | sim | — | `stores/chat.ts:272-292` |
| CON-07 | sim | — | `CreateGroupModal.vue:4-21,42-43,72,114,119`; `stores/chat.ts:299-312` |
| CON-08 | **não** | O corpo descreve o `GroupMembersModal`, **apagado** em `eaa8bac` ("Membros do grupo", select "Selecionar usuario", "Adicionar"/"Adicionando..." não existem) | `components/PainelGrupo.vue:4-118`; `ChatHeader.vue:19,116` |
| CON-09 | **não** | Não existe mais "Gerenciar membros"; hoje há "Participantes e anexos" e o avatar com `title` "Dados do grupo". Os membros não ficam numa "faixa de chips": aparecem numa lista ao passar o mouse no título | `ChatHeader.vue:19,52,59,116` (nenhum "Gerenciar membros" em `src/`) |
| CON-10 | parcial | Confere a abertura (900×700, centrada, nome `chat-popup-<id>`) e os textos. Faltam: sem camada de arrastar, sem `beforeunload`, sem tratamento de chamada, botões de ligar e "Dados do grupo" **sem efeito** no popup, e **nenhum canal** com a janela principal (som e notificação podem sair em dobro) — §3.4 | `App.vue:834-846`; `chat-popup.ts:7-15`; `ChatPopup.vue:16-19,210-235`; `ChatHeader.vue:90-109` |
| MSG-01 | sim | 80/60/30/120 conferem | `stores/chat.ts:234,245,618-622`; `useScrollManager.ts:130,456,489,598` |
| MSG-03 | sim | — | `MessageList.vue:352-380,442-449,466-470,494-504` |
| MSG-04 | sim | — | `useScrollManager.ts:353-380`; `stores/chat.ts:671-734` |
| MSG-06 | sim | — | `stores/chat.ts:617-631`; `App.vue:827` |
| MSG-07 | sim | Ordem e condições batem | `utils/classificarMensagem.ts:26-71` |
| MSG-09 | sim | 300 ms; textos conferem | `MessageBubble.vue:57-65,244-251`; `DetalheStatusMensagem.vue:10,17,60-91` |
| MSG-12 | sim | — | `MencaoLink.vue:3-20` |
| MSG-13 | sim | — | `BolhaChamada.vue:20-24,84-99,139-146` |
| MSG-16 | sim | — | `BolhaExcluida.vue:8-82`; `EnqueteResumo.vue:4-16` |
| MSG-18 | sim | Sem a API (navegadores sem `navigator.connection`) nunca bloqueia | `composables/useConexao.ts:9-38`; `MessageContent.vue:102-158,316-323` |
| MSG-20 | sim | Nuance: "A data final precisa estar no futuro" exige ≥ 1 min (igual ao servidor) | `BolhaEnquete.vue`; `stores/enquetes.ts:12-39`; `utils/prazoEnquete.ts:2-22` |
| ENV-01 | parcial | "Cresce até 120 px" está superado: hoje **40vh**. Enter/Shift+Enter agora em `editor/pecas.ts` | `MessageInput.vue:375`; `editor/pecas.ts:150-151` |
| ENV-02 | parcial | Lista confere (20 atalhos). No Tiptap o atalho só vira emoji ao digitar **espaço** (quebra de linha não converte) ou no envio | `utils/emojiAtalhos.ts:5-40`; `editor/pecas.ts:116-137`; `MessageInput.vue:938-940` |
| ENV-05 | parcial | Não existe mais "camada de realce atrás do textarea": a menção é um nó Mention do Tiptap (`allowSpaces`). Confere: até 6 contatos, ↑/↓, Enter/Tab, Esc | `editor/pecas.ts:75-91`; `MencaoDropdown.vue:45-47`; `MessageInput.vue:325-347` |
| ENV-06 | sim | — | `MessageInput.vue:34-44,930-932`; `stores/chat.ts:327-330` |
| ENV-07 | sim | — | `stores/chat.ts:334-339,417-425` |
| ENV-09 | parcial | Texto com cara de código **já entra cercado** (não entra cru e depois vira bloco); Ctrl+Z desfaz a colagem inteira, não "volta ao texto cru". Fechar a janela "Inserir código" por clique fora também cola o texto cru | `MessageInput.vue:1022-1036`; `CodigoModal.vue:2` |
| ENV-10 | sim | Ctrl/Cmd+Enter; **Esc não fecha** | `CodigoModal.vue:6,36,43,80,161,167-170` |
| ENV-11 | parcial | Não é mais "imagem → fila": **qualquer** arquivo colado entra como peça no cursor; sem nome → `print-<ms>.<ext>`; GIF copiado vira `gif-<ms>.gif`; peças copiadas do próprio campo colam como peças | `MessageInput.vue:975-992`; `utils/copiarImagem.ts:38-49` |
| ENV-12 | sim | Detalhe: ignora Ctrl/Alt (exceto AltGr), Meta, IME, campo coberto por modal | `MessageInput.vue:1040-1057`; `editor/pecas.ts:152` |
| ENV-13 | parcial | "O autor vê na hora com o selo MSG-17" está superado (o 🆕 já avisa) | `AgendarMensagemModal.vue`; `MessageInput.vue:116-118,968-971` |
| ENV-15 | sim | 2,5 s e 4 s conferem; o aviso sai a qualquer mudança no campo não vazio, inclusive ao pôr uma peça | `stores/chat.ts:1063-1103`; `MessageInput.vue:407` |
| ENV-17 | sim | — | `MensagemAcoes.vue:196-198`; `stores/chat.ts:1175-1199`; `MessageBubble.vue:159-189,384-386` |
| ENV-18 | sim | — | `MensagemAcoes.vue:103`; `stores/chat.ts:602-616` |
| ENV-20 | parcial | O "botão ⋯" é uma **seta para baixo** (chevron) **sem `title`**; fecha também ao rolar a lista | `MensagemAcoes.vue:11-18,422-427` |
| ENV-21 | **não** | Cita `utils/editorRico.ts` e `utils/blocosEditor.ts`, **apagados** em `e8d82cb` (com `utils/historicoEditor.ts`); `extrairBlocos` virou `blocosDoDocumento`; teste `blocosEditor.test.ts` virou `editorTiptap.test.ts` | `git show --stat e8d82cb`; `editor/pecas.ts:47-71,145-154,171-205` |
| ENV-22 | sim | — | `EnqueteModal.vue`; `AnexoPopup.vue:22-23,55,62` |
| ENV-23 | sim | IndexedDB `conversa-rascunhos`, loja `rascunhos`, chave `usuarioId:conversaId`, gravação 400 ms após a mudança | `services/rascunhos.ts:29-30,58-72`; `MessageInput.vue:579-588` |
| ANX-02 | sim | 2 s / 50% / `beforeunload` conferem (só na janela principal) | `useUploadProgress.ts:13-30`; `App.vue:474-478,488` |
| ANX-03 | sim | — | `stores/chat.ts:466-467`; `utils/formatters.ts:100-103` |
| ANX-04 | sim | — | `useImageViewer.ts:183-197`; `ImageViewerModal.vue:39-42,60,91` |
| ANX-06 | sim | — | `VisualizadorPdf.vue` |
| ANX-10 | sim | Nuance: o 1º play de **qualquer** áudio ainda não reproduzido chama `/mensagem/reproduzir`, inclusive áudio próprio | `composables/useAudioPlayer.ts:25-27,57-70` |
| ANX-11 | sim | — | `useAudioRecording.ts`; `MessageInput.vue:824-838,870-912` |
| ANX-12 | sim | 3 s confere | `TranscricaoAudio.vue:4-55` |
| ANX-13 | sim | `limite=60` confere | `AnexosLista.vue`; `AnexosPage.vue` |
| PES-01 | sim | — | `ChatHeader.vue:78-79,139-140`; `stores/chat.ts:632-648` |
| PES-02 | sim | **Achado de segurança no web:** o destaque usa `v-html` sobre o texto da mensagem **sem escapar HTML** (`destacarTermo` só escapa o termo para a regex) | `PesquisaAvancada.vue:50,103-108` |
| CHA-03 | sim | 30 s confere | `stores/call.ts:1502-1538`; `useCallPopup.ts:77-97` |
| CHA-08 | sim | 25 s confere | `stores/call.ts:1660-1666` |
| CHA-10 | sim | 4 s confere | `stores/call.ts:158-166,720-731` |
| CHA-12 | parcial | Colunas responsivas: 2 pessoas = 1 coluna no celular e 2 a partir de `md`; 5–6 = 2/3; mais de 6 = 2/3/4 | `CallWindow.vue:481-483,522-526` |
| CHA-13 | sim | Só vídeo; 420×350 no canto superior direito; mín. 320×240; máx. 90% — §3.5 | `useDraggable.ts:5-19,63-64,85-87`; `CallWindow.vue:5-21,413-421` |
| CHA-16 | sim | 15 s confere | `stores/call.ts:1620-1645` |
| CHA-18/24 | parcial | A §10 ainda diz "a primeira mensagem cria o grupo"; na janela principal é o 1º clique no campo. O modo simples (`completo=false`) só existe com `fecharAoEncerrar=true`, que nenhum uso atual passa (o app não abre mais janela popup de chamada) — na prática é código morto. A expressão "não na popup da chamada" da §10 refere-se a uma janela que não existe mais | `ChatChamada.vue:108-158`; `CallWindow.vue:254-258`; `App.vue:176,188` |
| CHA-22 | sim | — | `ChamadaHistorico.vue` |
| SIP-01 | sim | — | `ProfileSettingsModal.vue:323-366` |
| SIP-02 | sim | 10 s confere | `stores/sip.ts:316-415` |
| SIP-03 | sim | 288 px, centralizado ao abrir, arrastável pelo cabeçalho; sem atalhos de teclado | `SipDialerModal.vue:4,8-13,226-254` |
| NOT-01 | sim | — | `stores/chat.ts:936-944`; `utils/sound.ts:4-48` |
| NOT-02 | parcial | Corpo também tem **"Votação"** (enquete) | `stores/chat.ts:965-990` |
| NOT-03 | sim | — | `stores/chat.ts:216,727-729` |
| NOT-05 | sim | A notificação de chamada **não** é `silent` | `useCallPopup.ts:77-126` |
| PRE-01 | parcial | A bolinha verde também aparece no PainelGrupo | `PainelGrupo.vue:92` |
| ATV-01 | parcial | Prévia também mostra "Votação"; gravação aparece como "Áudio" | `AtividadesPage.vue` |
| ATV-02 | sim | — | `stores/atividades.ts:18-75` |
| ATV-03 | sim | — | `stores/call.ts:1518-1535,1663-1665` |
| CFG-03 | sim | Só lista; **não há seleção** de dispositivo em lugar nenhum do web — §3.7 | `ProfileSettingsModal.vue:199-272,720-776` |
| CFG-04 | sim | — | `ProfileSettingsModal.vue:274-308,550-637` |
| CFG-05 | sim | Chave `conversa.cores`, sincronizada entre janelas pelo evento `storage` | `useCoresPersonalizadas.ts:29-142,206-207` |
| CFG-06 | sim | — | `useConfigChamada.ts:22-58`; `ConfiguracaoChamadas.vue:78-110` |
| CFG-07 | sim | — | `ConfiguracaoSistema.vue` |
| CFG-08 | parcial | Não existe o texto "Modo aberto"; o aviso é "**Ninguém tem a permissão Acessos ainda:** todos os usuários podem mexer nas configurações e nas permissões. Marque Sistema e Acessos para quem deve cuidar disso; ao marcar Acessos para alguém, só passa a valer o que estiver marcado." | `ConfiguracaoAcessos.vue:6-9` |
| GER-01 | sim | — | `App.vue:3-6` |
| GER-03 | sim | — | `DialogoConfirmacao.vue:50-69` |
| GER-04 | parcial | A camada ainda diz "Imagens mostrarao uma previa antes de enviar", mas não há mais prévia (o arquivo vai para o campo) | `App.vue:111-112,469-472` |
| GER-05 | sim | — | `App.vue:2,320-325` |
| GER-07 | sim | — | `utils/formatters.ts:64-71` |

### 2.3 Seções gerais, endpoints e eventos

- **§1.3 `CAMPOS_DATA`:** faltam **`encerra_em`** e **`encerrada_em`** (`services/eden.ts:8-32`). Nuance: um corpo de erro de texto não-HTML volta como está; só sem nada aproveitável vira `Erro HTTP <status>` (`eden.ts:76-87`). O resto (401, HTML → "Servidor indisponível", `{error}`/`{message}`) confere (`eden.ts:78-98`).
- **§1.4:** confere tudo — URL pelo host da página (`stores/chat.ts:736-741`), `onopen` (`:753-770`), backoff `min(30000, 1000*2^n)` (`:813`), polling 8 s só sem socket (`:1040-1052`), faixa após 5 s com o texto exato sem acento "Conexao em tempo real indisponivel — usando atualizacao periodica" (`App.vue:21,387-399`).
- **§1.5:** confere (5 s, `App.vue:504,539-541`; logout `:688-698`). Achado de privacidade: o logout **não apaga** os rascunhos do IndexedDB.
- **§1.6:** confere (`plataforma:'Web'`, `stores/auth.ts:92-129`; service worker, `public/firebase-messaging-sw.js:17-47`). Os dois `PATCH /dispositivo` saem em sequência sem esperar um pelo outro (`auth.ts:170-174`).
- **§1.7:** confere, mas acrescentar: **o web não chama `POST /anexo/confirmar`** (nenhuma ocorrência em `src/`; o upload termina no PUT da URL; a confirmação fica para a tarefa `VerificacaoAnexos` do servidor ou para o primeiro `GET /anexo`). O FMX deve chamar o confirmar (o doc 01 recomenda).
- **§2.1, §2.2, §2.5:** conferem, inclusive acentos (`useHistoryNavigation.ts:3-53`; `NavBar.vue`; `ProfileSettingsModal.vue:17-18,432-454`). URL desconhecida cai no chat.
- **§2.4:** ainda lista `GroupMembersModal`; faltam `PainelGrupo`, `MensagensAgendadasModal`, `EnqueteModal`, `EnqueteResumo`; o `AnexoPopup` tem também "Votação".
- **§1.1/§1.2/§1.8:** falta Tiptap 3 na stack; faltam a store `enquetes`, o IndexedDB `conversa-rascunhos`, o chunk `editor` (`vite.config.ts:46-49`) e o assíncrono `MensagensAgendadasModal` (`MessageInput.vue:240`).
- **§4.1:** o web usa **63** rotas da API (+ o PUT na URL pré-assinada). **Faltam as 5 de enquete**: `PUT /enquete` (body `{conversa_id, pergunta, opcoes, multipla, encerra_em}`), `GET /enquete?id=`, `POST /enquete/votar` (`{enquete_id, opcoes}`), `POST /enquete/encerrar` (`{enquete_id}`), `PATCH /enquete` (`{enquete_id, encerra_em}`) — `services/conversaApi.ts:225-246`. Nenhuma rota da tabela deixou de ser usada. Das 69 do servidor, as **6 que o web não usa** são: `DELETE /usuario`, `PUT /usuario/contato`, `DELETE /usuario/contato`, `PUT /dispositivo/usuario`, `DELETE /conversa` e `POST /anexo/confirmar` (lista de chamadas `api()...` em `services/conversaApi.ts`).
- **§4.2:** os 15 eventos batem com `TipoEventoSocket` (`types/api.ts:29-46`), mas **falta o 62 `EnqueteAtualizada`** (lê `enquete_id`; relê `GET /enquete` só se a enquete está no cache) — `stores/chat.ts:883-886`; `stores/enquetes.ts:37-39`.
- **Anexo B:** o selo "Agendada para …" continua em `MessageBubble.vue:7-15`, mas não aparece (o `MessageList.vue:427` filtra as agendadas) — código morto novo. O modo simples do `ChatChamada` também (ver CHA-18/24).

### 2.4 Funcionalidades do web sem ID próprio

| Funcionalidade | Situação no doc 03 |
|---|---|
| Relógio de agendadas + "Mensagens agendadas" (`MensagensAgendadasModal`) | Só na §12, pendurado em MSG-17/ENV-13/ENV-14 — pede ID próprio ou reescrita de ENV-13/14 |
| `PainelGrupo` | Só no cabeçalho de CON-08 e na §11; corpo de CON-08 errado |
| Arrastar peça no campo para mudar a ordem; copiar/colar peça duplica; gapcursor/dropcursor | Uma frase na §12 |
| Arrastar peça **não** mostra "Solte para enviar o arquivo"; arquivo solto no campo entra no ponto do mouse | Não descrito |
| Ctrl+Z/Ctrl+Y | Na §12 como "próprios"; hoje é o `UndoRedo` do Tiptap |
| Colar GIF animado | Uma frase na §12 |
| Ctrl + clique direito (só reações) e toque longo | Cobertos na §12 (ENV-20) |

### 2.5 O que muda ao adaptar o doc 03 para o FMX

- A **§7 do doc 03** ("Itens que não fazem sentido no Android") deve ser **reescrita para desktop**: quase tudo nela vale literalmente no FMX (popup, janela flutuante, clique direito/hover, arrastar e soltar, teclas, colar, beforeunload, abas de configurações). O que muda está na §3 deste relatório: toast do Windows em vez de service worker/FCM, `TForm` em vez de `window.open`, permissões da Privacidade do Windows, sem `navigator.connection`.
- Itens só de celular que não se aplicam ao FMX: toque longo (salvo tela de toque), layout < 768 px (barra no rodapé, uma coluna), FCM web.

---

## 3. Comportamentos do web próprios de desktop (o que o FMX replica)

Cada item traz o comportamento **exato** do web (arquivo:linha, teclas, textos) e como o FMX deveria reproduzi-lo. Os textos estão como no código, inclusive sem acento onde o web não acentua.

### 3.1 Atalhos de teclado (lista completa)

| Onde | Tecla | Comportamento exato no web | Evidência | FMX |
|---|---|---|---|---|
| Campo de mensagem | **Enter** | Envia (`aoEnter → enviarMensagem()`). Com a lista de menção aberta, **confirma a menção** em vez de enviar | `editor/pecas.ts:150`; `MessageInput.vue:365`; `:342-345` | `OnKeyDown` do campo: `vkReturn` sem Shift → enviar (e `Key := 0`); com a lista de menção aberta → escolher |
| Campo | **Shift+Enter** | Quebra de linha (`setHardBreak`) | `editor/pecas.ts:151` | Inserir `sLineBreak` |
| Campo | **Tab** | Insere **4 espaços** | `editor/pecas.ts:152` | `TMemo.WantTabs`/tratar `vkTab` inserindo 4 espaços |
| Campo | **Shift+Tab** | Não tratado: o navegador tira o foco do campo | (ausência em `pecas.ts:148-154`) | Deixar a navegação padrão |
| Campo | **Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z** | Desfazer/refazer do editor (extensão `UndoRedo`), inclusive peças | `MessageInput.vue:222,352` | Desfazer próprio do campo (o `TMemo` só tem um nível; para peças, pilha própria) |
| Campo | **Backspace** | Apaga uma peça (anexo/figurinha/menção) como se fosse um caractere | `MessageInput.vue:101-102`; `pecas.ts:88` (`deleteTriggerWithBackspace`) | Idem no editor do FMX |
| Campo | **Espaço** após `:)` etc. | Troca o atalho pelo emoji | `pecas.ts:116-137`; `utils/emojiAtalhos.ts` | Mesmo mapa (doc 03 ENV-02) |
| Lista de menção (`@`) | **↑ / ↓** | Move a seleção | `MessageInput.vue:338-341` | Idem |
| Lista de menção | **Enter / Tab** | Confirma | `MessageInput.vue:342-345` | Idem |
| Lista de menção | **Esc** | Fecha | `MessageInput.vue:334-337` | Idem |
| Qualquer lugar | **Letra/número/símbolo** (tecla de 1 caractere) fora de campo | Foca o campo de mensagem **no fim** e o caractere entra nele. Ignora: evento já tratado, composição (IME), Meta, **Ctrl ou Alt sem AltGr**, foco em `INPUT/TEXTAREA/SELECT`/editável, Espaço com foco em botão/link, e campo **coberto por modal** (testado com `elementFromPoint` no centro do campo) | `MessageInput.vue:1040-1057` | `TForm.KeyPreview := True` + `OnKeyDown`/`OnKeyPress` do form: se `KeyChar <> #0`, sem Ctrl/Alt (exceto AltGr), sem controle de edição focado e sem diálogo aberto → `CampoMensagem.SetFocus`, cursor no fim e repassar o caractere |
| Troca de conversa / responder | — | O campo recebe o foco | `App.vue:411-413`; `MessageInput.vue:930-932` | Idem |
| Janela "Inserir código" | **Ctrl+Enter** (Cmd no Mac) | Envia a mensagem com o bloco | `CodigoModal.vue:167-170` | `OnKeyDown` do editor de código: `ssCtrl` + `vkReturn` |
| Janela "Inserir código" | **Esc** | **Nada** (não há tratamento). Fecha pelo "×", "Cancelar" ou clique fora — e, se veio de colagem, cola o texto cru | `CodigoModal.vue:2,7,36`; `MessageInput.vue:1022-1027` | Recomendado: Esc = Cancelar (mesmo efeito) |
| Menu de ações da mensagem / barra de reações / seletor | **Esc** | Fecha | `MensagemAcoes.vue:330-332` | `TPopupMenu` fecha com Esc nativamente |
| Menu da conversa (lista) | **Esc** | Fecha; também fecha com clique fora e ao redimensionar a janela | `ChatSidebar.vue:391-405` | Idem |
| Item da lista de conversas (com foco) | **Enter / Espaço** | Abre a conversa | `ChatSidebar.vue:74-75` | Idem |
| Diálogo de confirmação | **Esc** | Cancela. Enter aciona o botão com foco; o foco inicial vai para o botão principal, ou para **Cancelar** se a ação é destrutiva | `DialogoConfirmacao.vue:54-66` | `MessageDlg` com botão padrão = Cancelar nas destrutivas |
| Criar grupo | **Esc** | Cancela (listener global no `window`) | `CreateGroupModal.vue:68-73` | Esc fecha o form |
| Pré-visualização de imagem (sem gatilho hoje) | Enter / Esc | Confirma / fecha | `ImagePreviewModal.vue:39-48` | — |
| Visualizador de imagens/vídeos | **Esc** | Fecha | `useImageViewer.ts:185` | Idem |
| Visualizador | **← / →** | Item anterior/seguinte da galeria (exceto com o player de vídeo em foco, onde as setas avançam o vídeo) | `useImageViewer.ts:186-189` | Idem |
| Visualizador | **+ / = / −** | Zoom (só imagem) | `useImageViewer.ts:190-192` | Idem |
| Visualizador | **Ctrl+C** (ou Cmd+C) | Copia a imagem (PNG) | `useImageViewer.ts:193-196`; botão "Copiar imagem (Ctrl+C)" em `ImageViewerModal.vue:91` | `IFMXClipboardService.SetClipboard` com `TBitmapSurface` |
| Visualizador | Roda / duplo clique / arrastar / clique direito | Zoom / volta a 100% animado / arrasta com zoom / menu "Copiar imagem" | `ImageViewerModal.vue:39-42,60` | Idem |
| Visualizador de PDF / HTML | **Esc** | Fecha | `VisualizadorPdf.vue:154`; `VisualizadorHtml.vue:70` | Idem |
| Pesquisa no cabeçalho / pesquisa global | **Enter** | Pesquisa | `ChatHeader.vue:79,140`; `PesquisaAvancada.vue:11` | Idem |
| Chat simples da chamada (antes de o grupo existir) | **Enter** (sem modificador) | Envia; Shift+Enter quebra linha | `ChatChamada.vue:80` | Idem |
| Bolha oculta (com foco) | **Enter / Espaço** | Revela/oculta o conteúdo | `BolhaExcluida.vue:10-11` | Idem |
| Toque/chamada bloqueado pelo autoplay | Qualquer tecla ou clique | Começa o som de toque | `useCallPopup.ts:45-55` | Não se aplica (o desktop toca direto) |
| Ctrl+C / Ctrl+V / Ctrl+X no texto | — | Padrão do navegador (copiar seleção do chat; colar no campo — ver §3.2) | — | Padrão dos controles |

O web **não tem** atalhos globais para trocar de conversa, buscar (Ctrl+F), abrir o emoji ou ligar. Não há `Ctrl+Enter` no campo principal (só na janela de código).

### 3.2 Arrastar e soltar, colar imagem, colar texto longo

**Arrastar arquivos para a conversa** (`composables/useDragAndDrop.ts`, `App.vue:89-114,467-472`):
- Ao entrar com **arquivos** (`dataTransfer.types` contém `Files`) na área da conversa (`<main>`), aparece uma camada por cima de tudo (inclusive do campo) com:
  - **"Solte para enviar o arquivo"**;
  - "Imagens mostrarao uma previa antes de enviar" (texto **antigo**: hoje não há prévia, a imagem vai direto para o campo — o FMX não deve copiar esta frase).
- Um contador de `dragenter`/`dragleave` evita piscar. Arrastar uma **peça de dentro do campo** (mudar a ordem) não mostra a camada (`editor/pecas.ts:38-40,155-164`; `useDragAndDrop.ts:8-10`).
- Ao soltar: os arquivos entram no **campo**, como peças, no ponto do cursor (`MessageInput.vue:653-656`). Nada é enviado sozinho. Sem conversa ativa, nada acontece (`App.vue:469-472`).
- Arquivo solto **direto sobre o campo** (sem a camada, ex.: no popup, que não tem a camada) entra **no ponto do mouse** (`MessageInput.vue:668-677`, `posAtCoords`).
- **FMX:** `OnDragOver`/`OnDragDrop` do painel da conversa com `Data.Files` (o FMX recebe arquivos do Explorer no Windows); mostrar um painel semitransparente com "Solte para enviar o arquivo"; inserir os arquivos no campo como peças. Sem envio automático.

**Colar** (`MessageInput.vue:975-1005`, ligado em `handlePaste`, `:377`):
1. Colagem vinda do **próprio campo** (HTML com `data-pm-slice` e peças): o editor cola as peças como estão (`:979-980`). Peça cujo arquivo o campo não tem mais é descartada (`:380-384`).
2. **Arquivos** na área de transferência (qualquer tipo, não só imagem) → entram como peças no cursor. Arquivo **sem nome** (captura de tela) ganha **`print-<Date.now()>.<ext>`**, com a extensão pelo mime (`png`, `jpg`, `webp`, `gif`, `bmp`; o padrão é `png`) — `:988-990`; `utils/formatters.ts:134-142`. **Exceção GIF:** se veio um único arquivo de imagem e o HTML copiado tem `<img src="data:image/gif;base64,...">`, usa o GIF inteiro como `gif-<ms>.gif` (`:983-986`; `utils/copiarImagem.ts:38-49`).
3. Texto com **mais de 10 linhas** (`texto.trim().split('\n').length > 10`, `utils/codeBlocks.ts:167-169`) → abre a janela **"Inserir código"** já preenchida (`:995-998`, `sugerirCodigo` `:1011-1019`):
   - linguagem `markdown` se há linha começando com ```` ``` ````; `texto` se é desenho ASCII; senão a detectada (`:1014-1016`);
   - **"Cancelar"**, "×" ou clique fora **colam o texto como estava** (`:1022-1027`);
   - **"Enviar"** (ou Ctrl+Enter) **envia na hora** a mensagem só com o bloco cercado e **limpa o campo** (`:681-690`).
4. Texto **com cara de código** (`pareceCodigo`, `codeBlocks.ts:152-162`) — 2+ linhas com (≥ 50% desenho ASCII) ou (≥ 50% comandos de terminal) ou (≥ 2 linhas e ≥ 50% com cara de código **e** algum sinal forte) → entra **já cercado** com a linguagem detectada, numa linha própria (`MessageInput.vue:1030-1036`). Cerca = uma crase a mais que a maior sequência interna, mínimo 3 (`codeBlocks.ts:116-119`).
5. Outro texto → colado **sem formatação**; `@[Nome](id)` vira menção (`:1003`, `:457-474`).

**Janela "Inserir código"** (`CodigoModal.vue`): título "Inserir código"; seletor com `texto, javascript, typescript, python, sql, json, html, css, bash, csharp, pascal, markdown, mermaid` + a detectada se estiver fora (`:80-84`); placeholder "Cole ou escreva seu código aqui..." (`:161`); "Cancelar"/"Enviar".

**FMX:** interceptar Ctrl+V (e o menu "Colar") no campo (`IFMXClipboardService`):
- se há bitmap → salvar PNG temporário `print-<ms>.png` e inserir como peça;
- se há lista de arquivos (CF_HDROP) → inserir cada arquivo;
- se é texto com > 10 linhas → abrir o form de código (mesmo comportamento de Cancelar/Enviar);
- se `pareceCodigo` → inserir cercado.
Reaproveitar as mesmas expressões regulares de `codeBlocks.ts:138-148`.

### 3.3 Menu de contexto, hover e toque longo

**Clique direito na bolha** (`MessageBubble.vue:23,261-273`; `MensagemAcoes.vue`):
- O menu nativo do navegador é **bloqueado** em todo o app, exceto em `INPUT`, `TEXTAREA` e editáveis (`App.vue:2,320-325`).
- **Clique direito** → menu completo junto do botão de ações. Itens, nesta ordem (`MensagemAcoes.vue:30-112`):
  - reações rápidas 👍 ❤️ 😂 😮 / 😢 👏 🔥 + "Mais emojis" (`:196-197`, `:53-61`);
  - **Responder**;
  - **Responder no privado** (só em grupo e em mensagem de outro, `:74`);
  - **Encaminhar**;
  - **Copiar**;
  - **Ocultar** (só minha e não oculta, em vermelho, `:103`).
- O que é copiado depende de onde foi o clique: numa `<img>` copia **aquela imagem**; no texto (`[data-conteudo-texto]`) copia o texto; senão, a mensagem toda (`MessageBubble.vue:331-336`).
- **Ctrl + clique direito** → abre **só a barra de reações** (7 emojis + "Mais emojis"), **centrada no ponto do clique**, acima dele (ou abaixo, se não couber); o emoji em que eu já reagi fica destacado (`MessageBubble.vue:268-270`; `MensagemAcoes.vue:114-145,306-316`). "Mais emojis" troca a barra pelo seletor completo junto dela (`:319-328`).
- Sem menu: mensagens não salvas (id ≤ 0), de **chamada** e **ocultas** (`MessageBubble.vue:28`).

**Botão de ações** (`MensagemAcoes.vue:1-18`):
- aparece **só com o mouse sobre a bolha** (`group-hover/bubble`), ao lado dela: à **esquerda** da minha mensagem, à **direita** da de outro;
- em bolhas altas, **acompanha a rolagem** (`atualizarTopOffset`, `:411-420`);
- o ícone é uma **seta para baixo** (chevron), não "⋯", e **não tem `title`**;
- o menu abre **abaixo** do botão, ou **acima** se não couber, ou centralizado (`:228-257`); fica dentro da janela; um menu por vez (evento `fechar-menu-acoes`, `:270-279`);
- **fecha** com clique fora, Esc e **qualquer rolagem** da lista (`:390-396,422-427`).

**Toque longo** (`MessageBubble.vue:275-328`): só para `pointerType === 'touch'`. **500 ms**, tolerância de **10 px**; abre o menu completo e engole o clique ao soltar. Num desktop com tela de toque (Windows) também vale.

**Hover:**
- **Detalhe de status** (só nas minhas mensagens, fora da bolha): com o mouse parado **300 ms** sobre o ✓/✓✓ abre o `DetalheStatusMensagem`; sai ao tirar o mouse; clique alterna (`MessageBubble.vue:57-65,244-251`). Textos (`DetalheStatusMensagem.vue:10,17,60-91`):
  - direta: "Enviada", "Recebida", "Visualizada", "Ouvida" (áudio), "Oculta", "Aguardando";
  - grupo: "Visualizada por", "Recebida por", "Aguardando";
  - erro: "Não foi possível carregar o status.".
- **Reações:**
  - chip `emoji contagem`; com o mouse em cima, tooltip com **foto (ou inicial), nome e hora** de cada pessoa — hora `HH:MM` se for hoje, senão `dd/MM HH:MM` (`MessageBubble.vue:122-157,359-364`);
  - **5 chips à mostra**; o resto num chip **"+N"** (`title` "Mais N reações"), que no hover lista emoji, contagem e nomes, e clicar alterna (`:160-189,385-386`).
- **Menção:** no hover, cartão com foto (ou inicial) e nome; clique abre a conversa direta com a pessoa (`MencaoLink.vue:3-20`).
- **Lista de conversas:** no hover (só em telas ≥ 768 px) aparecem os botões **"Mais opções"** (três pontos) e **"Abrir em nova janela"** (`ChatSidebar.vue:146-158`).

**Clique direito na conversa** (`ChatSidebar.vue:72,350-358,363-380`): menu no ponto do clique, recuado para caber na janela. Itens: "Fixar"/"Desafixar" + "Arquivar" (conversa não arquivada) ou "Desarquivar" (arquivada).

**FMX:**
- `TPopupMenu` montado na hora no `OnMouseUp` (botão direito) da bolha, com `ssCtrl` decidindo entre o menu completo e a barra de reações (um `TPopup` com 8 botões, centrado em `Screen.MousePos`);
- botão de ações num `TLayout` que aparece no `OnMouseEnter` da bolha;
- detalhe de status com `TTimer` de 300 ms no `OnMouseEnter` do ícone;
- tooltips de reação e cartão de menção com `TPopup`/`TCalloutPanel` (o `Hint` simples não mostra foto);
- `Hint`/`ShowHint` para os `title` dos botões.

### 3.4 Janela popup de conversa (`chat-popup.html`)

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
  - As duas janelas são **duas conexões do mesmo usuário** e se sincronizam **só pelo servidor**. Como o servidor não manda WS 2 ao próprio remetente nem WS 3 ao próprio leitor (§4.4), mensagem enviada ou lida numa janela só aparece na outra quando algo a faz recarregar.
  - Efeito colateral (lido do código, **não confirmado em execução**): as duas janelas tratam o mesmo WS 2. Cada uma toca o som e cria a notificação (a segunda substitui a primeira pela mesma `tag`, mas o **som toca duas vezes**). O popup só deixa de notificar a própria conversa quando **ele** tem o foco.
- **FMX:** abrir um `TForm` por conversa (reutilizar se já aberto; título = nome da conversa; 900×700 centrado no form principal), **no mesmo processo**, com **o mesmo WebSocket e o mesmo cache** do form principal. As duas janelas ficam sincronizadas de verdade e não há som/notificação em dobro. A regra de "conversa aberta e focada não notifica" deve considerar **qualquer** form que mostre a conversa e esteja ativo. Chamadas continuam tratadas pelo form principal.

### 3.5 Janela flutuante da chamada e discador SIP

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

**Discador SIP** (`components/SipDialerModal.vue`):
- Abre pelo item **Ramal** da barra (só com SIP ativo) ou quando uma chamada SIP recebida está conectando (`App.vue:255,383-385`).
- Caixa de **288 px** de largura (`w-72`), **centralizada** ao abrir (`:226-233`); arrastável **pelo cabeçalho**, sempre dentro da janela (`:236-254`); "×" fecha.
- Conteúdo:
  - "Ramal" + `sip_user` (ou "Indisponivel");
  - "Status do ramal": "Sem configuracao", "Ramal inativo", "Registrado", "Conectando", "Conectado sem registro", "Falha na conexao", "Desconectado" (`:256-264`);
  - campo "Digite o numero" (`:39`).
- **Não há** atalho de teclado: Enter não liga e as teclas numéricas fora do campo não discam.
- **FMX:** `TForm` pequeno sem borda, `StayOnTop`, arrastável pelo cabeçalho, centrado no form principal ao abrir.

### 3.6 Notificações, sons, título/favicon, saída com upload

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
- só chega com **nenhuma aba aberta** (regra do servidor, §4).

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
- **"Janela focada"** = `Application.Active` e o form que mostra a conversa é o ativo, não minimizado.
- **Chamada:** toast "Chamada recebida" + toque em loop + trazer o app para a frente (`FlashWindowEx`).
- **Extras opcionais** (o web não tem): contador no ícone da barra de tarefas (`ITaskbarList3.SetOverlayIcon`) e na bandeja.
- **Fechar o app com upload ativo:** `OnCloseQuery` com confirmação. Se o app vai para a bandeja ao fechar, o upload pode continuar.

### 3.7 Abas de configurações

Títulos e descrições das abas (`components/ProfileSettingsModal.vue:432-445`, sem acento como no código): "Usuario — Nome, email, avatar e senha"; "Dispositivos — Sessao atual e perifericos locais"; "Permissoes — Notificacoes, microfone e camera"; "Voip — Configuracao SIP do usuario"; "Cores — Cores do sistema, salvas neste navegador"; "Chamadas — Qualidade do áudio, vídeo e tela"; "Sistema — Configurações que valem para todos" (só com `parametros`); "Acessos" (só com `permissoes`).

**Dispositivos** (`ProfileSettingsModal.vue:199-272,647-…,720-776`):
- **"Sessao atual"** ("Informacoes do navegador autenticado neste momento.", etiqueta "Ativo"): Dispositivo / Modelo / Sistema / Plataforma, detectados **localmente**, não lidos da API.
- **"Dispositivos de midia"** ("Lista local de microfones, cameras e saidas detectadas pelo navegador."):
  - botão "Atualizar lista" ("Atualizando...");
  - `enumerateDevices()` só com os que têm rótulo, tirando o sufixo `(xxxx:xxxx)`;
  - tipo "Microfone" / "Saida de audio" / "Camera";
  - etiquetas "Padrao" (`deviceId === 'default'`) e "Comunicacao" (`'communications'`);
  - vazio: "Nenhum dispositivo de midia foi identificado ainda. ...".
- **Não há seleção.** A aba **só lista**. O web nunca passa `deviceId` ao `getUserMedia` (`stores/call.ts:808,863,1164,1199,1286`) e não usa `setSinkId` (busca em `src/`): chamadas e gravação usam **sempre o dispositivo padrão do sistema**.
- **FMX:** listar com a API de áudio/vídeo usada (WASAPI/MMDevice, Media Foundation). Para a paridade basta listar. **Escolher** microfone/câmera/alto-falante seria uma **melhoria em relação ao web** (decisão de produto; se fizer, gravar a escolha nas configurações locais e aplicar na captura da chamada e da gravação).

**Permissões** (`:274-308,550-637`): "Permissoes do navegador" ("Gerencie as permissoes necessarias para o funcionamento completo do aplicativo.").
- Itens:
  - "Notificacoes" — "Alertas de novas mensagens e chamadas recebidas";
  - "Microfone" — "Gravacao de audio e chamadas de voz";
  - "Camera" — "Chamadas de video".
- Status: "Concedida" / "Negada" / "Nao solicitada" / "Indisponivel"; botão "Solicitar" quando ainda não foi pedido.
- Dica do cadeado da barra de endereço.
- **FMX:** no Windows as permissões são da **Privacidade do sistema** (Configurações → Privacidade e segurança → Microfone/Câmera/Notificações). Mostrar o estado e um botão que abre `ms-settings:privacy-microphone`, `ms-settings:privacy-webcam` e `ms-settings:notifications`. Aplicativo Win32 clássico não tem prompt por app: o estado vem de "Permitir que aplicativos da área de trabalho acessem..." — **não confirmado** como o FMX lê isso.

**Cores** (`components/ConfiguracaoCores.vue`, `composables/useCoresPersonalizadas.ts`):
- grupos "Principal", "Superfícies", "Sucesso", "Perigo", "Informação", "Alerta", "Chamada" (`useCoresPersonalizadas.ts:29-140`), **separados por tema** (claro/escuro);
- salvos no `localStorage` `conversa.cores` (`:142,151,178`) e sincronizados entre janelas pelo evento `storage` (`:206-207`);
- busca "Buscar pela variável ou pelo uso (ex.: primary-600, mensagens)"; "Restaurar todas", "Restaurar grupo", "Voltar ao padrão" por cor.
- **FMX:** as cores do FMX são as de `docs/design/cores.md` (o Android usa as do FMX). Editar cores pode ser estilo/`TStyleBook` com sobreposições gravadas localmente. Baixo valor; no mínimo, tema claro/escuro.

**Chamadas** (`components/ConfiguracaoChamadas.vue`, `composables/useConfigChamada.ts`):
- salvo no `localStorage` `conversa.chamada` (`:22`); "Restaurar padrão"; aviso "Estas opções valem para o que você **envia** nas chamadas e ficam salvas neste navegador. Durante uma chamada, as mudanças valem na hora.";
- **Áudio:** "Redução de ruído", "Cancelamento de eco", "Ganho automático do microfone" (ligados por padrão); "Qualidade do áudio": Normal 32 kbps (padrão) / Alta 64 kbps / Música 128 kbps estéreo ("O estéreo vale a partir da próxima chamada.") — `ConfiguracaoChamadas.vue:78-88`;
- **"Vídeo da câmera":** Resolução 360p/720p/1080p (padrão **720p** no desktop); "Quadros por segundo" 15/24/30 (padrão **24** no desktop); "Limite de banda" Automático / Econômico (0,5 Mbps) / Alto (3 Mbps) — `useConfigChamada.ts:26-37,52-58`;
- **"Compartilhamento de tela" → "Prioridade":** Nitidez (até 15 fps, padrão) / Fluidez (até 30 fps).
- **FMX:** mesmas opções e padrões de desktop, gravadas localmente. Redução de ruído, cancelamento de eco e ganho dependem do motor de captura (no navegador são `getUserMedia` constraints); confirmar com a pilha WebRTC do FMX.

**Sistema** e **Acessos:** dependem só da API (`GET/PATCH /parametros`, `GET /permissoes`, `PUT/DELETE /permissao/usuario`) e da permissão do usuário (`auth.temPermissao`). Valem literalmente no FMX. Detalhes e textos na conferência do doc 03 (§2, CFG-07/08).

### 3.8 Conexão lenta (`navigator.connection`)

- `composables/useConexao.ts:9-38`: lê `navigator.connection.effectiveType` e escuta o `change`. É **lenta** só com `slow-2g` ou `2g`. **Sem a API** (Firefox, Safari), considera **rápida**.
- Efeito (`components/MessageContent.vue:102-114,147-158,316-323`):
  - imagem e vídeo recebidos (sem `localUrl`) mostram uma caixa "**Toque para abrir**" (imagem) ou "**Toque para carregar**" (vídeo) e só baixam ao clicar;
  - depois de liberada, a imagem mostra "Carregando..." até carregar.
- **FMX:** no desktop a API não existe; o equivalente seria rede limitada ou tarifada (`NetworkInformation.GetInternetConnectionProfile().GetConnectionCost()` da WinRT, ou `INetworkCostManager`). Como no navegador desktop a regra quase nunca dispara, **pode ser omitida**, ou virar opção manual "baixar mídia só ao clicar".

### 3.9 Regras de foco da janela (afetam leitura e indicador)

- **Visualizar** só marca com a janela focada: `validarMensagensCompletamenteVisiveis` sai se `!document.hasFocus()` (`composables/useScrollManager.ts:353-359`). Ao a janela voltar a ter foco, reavalia (`useScrollManager.ts:983`).
- **Linha "Últimas":** com a janela focada e a rolagem a ≤ 500 px do fim, mensagem nova **não** cria a linha (`MessageList.vue:366-369`). Ao perder o foco (`blur`), a próxima mensagem reposiciona a linha (`MessageList.vue:470`).
- **FMX:** usar `Application.Active` e o `OnActivate`/`OnDeactivate` do form que mostra a conversa, não só "o form existe". Minimizado ou na bandeja = sem foco.

---

## 4. Servidor × cliente desktop sempre conectado

### 4.1 A regra do push — confirmada

```ts
// src/notificacoes.ts:68-75
for (const { usuario_id, token_fcm, arquivada } of destinatarios) {
  notificarNovaMensagem(usuario_id, titulo, texto)
  // Quem arquivou a conversa não recebe push
  if (token_fcm && !arquivada && !usuarioConectado(usuario_id)) {
    enviarPush(token_fcm, titulo, texto, conversa).catch(() => {})
  }
}
```

```ts
// src/websocket.ts:131-133
export function usuarioConectado(usuarioId: number) {
  return (conexoes.get(usuarioId)?.size ?? 0) > 0
}
```

- `conexoes` é `Map<usuario, Set<Conexao>>` (`websocket.ts:31-32`): só por usuário, sem dispositivo. O login do WebSocket não carrega `dispositivo_id`, e o JWT também não (`rotas.ts:36`: só `sub`, `iss`, `iat`).
- O push é a **única** coisa que o servidor envia ao celular fora do socket (`enviarPush` só é chamado em `notificacoes.ts:73`). Chamadas, reações, menções, atividades e status nunca geram push.
- O teste é feito **na hora do envio de cada mensagem**, para o usuário inteiro: basta **uma** conexão autenticada em qualquer aparelho ou aba.

### 4.2 Efeito de um app desktop conectado o dia todo

Se o FMX fica conectado enquanto o PC está ligado (inclusive minimizado na bandeja, com a tela bloqueada ou com o usuário longe):

1. **O celular do mesmo usuário não recebe push de mensagem nenhuma** enquanto o desktop estiver conectado. O mesmo vale para o push do navegador com a aba fechada. Pior caso: o PC do escritório fica ligado com o app aberto, e o celular fica mudo a noite toda.
   - O app Android só tem socket em primeiro plano (doc 01 §15.1); em segundo plano depende 100% do push.
   - O Android novo **não teria como saber** que perdeu notificações: quando abre, sincroniza por `/mensagens/novas`, mas o aviso nunca veio.
2. **Presença:** o usuário aparece **online o tempo todo** para quem tem conversa direta com ele (WS 60 só na primeira conexão e no fechamento da última, `websocket.ts:97-100,111-115`). Não existe "ausente".
3. **Chamadas:** o WS 51 vai a **todas** as conexões do usuário (`websocket.ts:120-129`).
   - Desktop e celular (se este tiver socket aberto) tocam juntos. Atender num manda WS 54 também a si mesmo (`chamadas.ts:209-210`) e o outro para de tocar.
   - O **temporizador de 30 s** de cada cliente é independente: o primeiro a vencer chama `recusar` com `nao_atendeu:true`, que muda o participante para "recusou" no servidor e manda WS 53 a si mesmo (`chamadas.ts:164-197`). **O desktop sem ninguém na frente "recusa" a chamada por todos os aparelhos depois de 30 s.**
   - Com o celular sem socket, não há push de chamada (S1 do doc 08): ele não toca de jeito nenhum.
4. **Notificação duplicada:** se o usuário também tem web aberto ou outro desktop, cada um toca e notifica. E, se ele tem **N** tokens FCM cadastrados, **cada conexão recebe N cópias do WS 2** (`notificacoes.ts:56-69`, uma linha por token distinto). O desktop precisa tratar WS 2 repetido (o cursor de `/mensagens/novas` já deduplica as mensagens, mas o som e o toast podem repetir).
5. **Leitura em outro aparelho não chega:** `POST /mensagem/visualizar` avisa só **os outros membros** (`mensagens.ts:632` → `notificacoes.ts:43-49` exclui o próprio usuário). Ler no celular **não apaga** o toast nem o contador do desktop até a próxima recarga de `/conversas` (que acontece a cada WS 2/3/40). O mesmo vale para mensagem **enviada** pelo próprio usuário em outro aparelho (WS 2 vai só aos outros membros, `notificacoes.ts:56-66` com `cu.usuario_id <> ${usuario}`), reação própria (WS 7 só aos outros, `mensagens.ts:761-765`), fixar e arquivar (sem evento). **Exceção:** enquete (WS 62 vai a todos, inclusive a si).

### 4.3 O que precisaria mudar no servidor

(Complementa S1, S2, S3 e S13 do doc 08. Nada foi alterado.)

1. **Rastrear conexões por dispositivo** (S2.2). No login do WS, `{tipo:1, token, dispositivo_id}`, conferindo que o dispositivo é do usuário — ou um claim `dsp` no JWT emitido em `rotas.ts:36`. Guardar `Map<usuario, Map<dispositivo, Set<Conexao>>>` e expor `dispositivoConectado(id)`. Em `notificarNovaMensagemConversa`, selecionar `d.id, d.token_fcm` e enviar push a cada dispositivo **sem conexão própria**. `usuarioConectado` continua valendo para a presença.
2. **"Ausente" vindo do desktop:** uma mensagem cliente→servidor (ex.: `{tipo:63, ausente:true|false}`) que o desktop manda depois de N minutos sem entrada (`GetLastInputInfo`), ao bloquear a sessão (`WTSRegisterSessionNotification`/`WM_WTSSESSION_CHANGE`) ou ao suspender. O servidor trataria a conexão ausente como "não conectada" **para o push** (e opcionalmente avisaria os contatos com um estado "ausente" no WS 60).
   - Sem isso, mesmo com o item 1, o celular só recebe o que o desktop **não** recebeu — o que já resolve o caso "PC ligado no escritório", porque cada aparelho é considerado à parte.
3. **WS 2 uma vez por usuário:** separar o laço do evento (por usuário distinto) do laço do push (por dispositivo). Incluir `conversa_id` e `mensagem_id` no WS 2 e no push (S3).
4. **Avisar os outros aparelhos do próprio usuário:** enviar WS 3 também às **outras** conexões de quem marcou leitura, e WS 2/WS 7 às outras conexões do remetente. Isso mantém desktop e celular coerentes; hoje só a enquete faz isso.
5. **Push de chamada** (S1), com cancelamento, para dispositivos sem conexão.
6. **Recusa automática por um aparelho só:** avaliar um `POST /chamada/recusar` com `nao_atendeu` que **não** encerre o toque nos outros aparelhos do mesmo usuário enquanto algum ainda estiver tocando. Hoje o primeiro temporizador de 30 s decide por todos.
7. **Renovação de sessão** (S13): o desktop fica aberto mais de 12 h; sem refresh token ele precisa guardar a senha ou pedir login todo dia.

### 4.4 Outros pontos do servidor que afetam especificamente um cliente nativo Windows

| Ponto | Situação no servidor | Efeito no FMX / recomendação |
|---|---|---|
| **Rate limit do login** | `limit_req_zone $binary_remote_addr ... rate=10r/m` e `burst=5 nodelay` só em `location = /api/login` (`bin/nginx/nginx.conf:74,97-100`). Resposta padrão do nginx **503 em HTML**. Em dev, todos os clientes vêm do gateway do Docker (`:26-31`) | Nunca relogar em laço (ex.: 401 → login → 401...). Tratar 503 sem JSON como "aguarde e tente de novo" com espera crescente. Em dev, um laço de um desktop **bloqueia o login de todos** |
| **Tamanho do corpo** | `client_max_body_size 1m` no `http` (`:24`); `/storage/` 1024 MB, sem buffer de requisição (`:128-129`) | JSON > 1 MB (ex.: colar um log enorme como texto) → **413 em HTML**. Limitar o texto no cliente ou mandar como arquivo. Uploads grandes vão direto ao `/storage` |
| **Erros fora do JSON** | 413, 503 (limite), 502/504 (API fora) vêm do nginx em HTML; em dev, a página fora dá 502 texto (`desenvolvimento/pagina.conf:14-17`) | O cliente não pode supor `{error}` em todo erro: conferir `Content-Type` (o web troca HTML por "Servidor indisponível", doc 03 §1.3) |
| **CORS** | Nenhum `Access-Control-*` na API nem no nginx (GET com `Origin` → sem cabeçalho CORS). O MediaMTX responde `Access-Control-Allow-Origin: *` (verificado em `/webrtc/...`) | **Não afeta** HTTP nativo (`TNetHTTPClient`/Indy não aplicam CORS). Só importaria se o FMX carregasse uma página num `TWebBrowser`/WebView2 de **outra origem** chamando `/api` com `Authorization` — não é o caso hoje (o FMX usa WHEP nativo) |
| **Cabeçalhos usados** | `Host` é repassado (`proxy_set_header Host $http_host`, `:90`) e é com ele que a API monta as URLs do MinIO e o host do TURN (`src/contexto.ts:9-12`, `src/minio.ts:33-46`, `src/chamadas.ts:580-587`). `X-Forwarded-Proto` vem do nginx (`:35-38,93`). `Authorization: Bearer <token>` com **um** espaço (`split(' ')`, `autenticacao.ts:27-30`). Nada confere `Origin` nem `User-Agent` | Chamar sempre pelo **mesmo nome de host** que será usado no upload e no TURN, e que conste no certificado. **Não pôr a porta padrão na URL configurada** (`https://host:443`): a URL é assinada sem `:443` e, se o cliente mandar `Host: host:443`, o MinIO recusa a assinatura — dedução de `minio.ts:12-22`, **não confirmado em execução**. Não chamar `api:8080` direto (sem `X-Forwarded-Proto` e com `Host` interno, as URLs saem erradas) |
| **`/ws/` com barra** | `location /ws/` (`:109-114`); `/ws` → **301** (verificado) | Usar `wss://host/ws/` (o FMX já usa, `Conversa.Dados.pas:437`). O cliente WebSocket não segue redirecionamento |
| **Keepalive do WebSocket** | Sem ping de aplicação; `ws('/ws/', {...})` sem `idleTimeout`/`sendPings` (`websocket.ts:56`) → padrões do Bun (idle 120 s, pings automáticos de payload vazio — **não confirmado**, `node_modules` não está no host). nginx: 3600 s sem tráfego (`:111-112`) | O cliente precisa responder **pong** a pings de **tamanho 0**. O cliente WebSocket do FMX (`lib/bird-socket-client/Bird.Socket.Client.pas:568-579`) zera a posição quando o tamanho é 0 e depois **incrementa** (`Inc(LPosition)` fora do `if`). Um quadro vazio (ping/pong sem payload) parece **dessincronizar a leitura** e não gera pong (`:589-596` só roda com bytes no spool). Provável queda ou corrupção a cada ~2 min sem tráfego — **verificar com quem audita o FMX** |
| **JWT 12 h** | `exp: '12h'` (`autenticacao.ts:6`); o WS **não** revalida depois do login (`websocket.ts:79-81`) | Depois de 12 h o socket continua recebendo, mas toda chamada REST dá 401. Relogar com `dispositivo_id` (senão cria outro dispositivo `desconhecido`, `usuarios.ts:53-60`), sem laço. Ao reconectar o socket, mandar o token **novo** |
| **Dispositivo** | Texto livre, limites 50/50/15/15 (`002.sql:4-7`); acima → 500 | `plataforma: 'Windows'`, `versao_so` ≤ 15 (ex.: `10.0.22621`), `nome` = nome do PC truncado em 50, sem `token_fcm` |
| **Upload pré-assinado** | PUT válido por **300 s**, GET por 600 s (`anexos.ts:55,65,80`); `Content-Type` fora da assinatura; `/storage` tirado pelo nginx (`nginx.conf:127`) | Mandar o corpo **cru**, com `Content-Length` (S3 não aceita PUT pré-assinado sem tamanho; com chunked no MinIO — **não confirmado**). Começar o PUT antes de 300 s. Não alterar a URL. Cachear por `identificador`, nunca pela URL |
| **Relógio do PC** | Agendamento exige `visivel_em ≥ agora+5 min` e enquete `encerra_em ≥ agora+1 min` **pelo relógio do servidor** (`mensagens.ts:164`, `enquetes.ts:59`). O web decide "pendente antiga > 25 s" com `Date.now()` local contra `criado_em` (`conversa-web/src/stores/call.ts:1660-1663`) | Relógio do Windows adiantado ou atrasado gera 400 no agendamento e recusa indevida de chamada pendente. Usar margem e, se possível, estimar a diferença pelo cabeçalho `Date` das respostas |
| **TLS** | Dev: nginx 1.28 com o certificado mkcert (`desenvolvimento/servidor.conf:2-4`), nomes `localhost`, `127.0.0.1` e o IP digitado (`bin/setup-cert.bat:51`). HTTP na 443 → 301 (`:7`). Prod: TLS na borda | `TNetHTTPClient` confia pelo repositório do Windows. O cliente WebSocket (Indy/OpenSSL, `Bird.Socket.Client.pas:267-271`) **não** usa esse repositório e só oferece TLS 1.0–1.2. O nginx 1.28 aceita 1.2, e a verificação de certificado do Indy fica desligada se não for configurada (**confirmar no FMX**). Ligar a verificação com o PEM da CA do mkcert |
| **gzip** | `gzip on`, `gzip_proxied any`, tipos JSON (`nginx.conf:62-67`) | Só vem compactado se o cliente pedir `Accept-Encoding: gzip`. Se pedir, descompactar (`TNetHTTPClient.AutomaticDecompression`) |
| **Presença e contatos online** | `GET /contatos/online` e WS 60 só para quem tem conversa **direta** (`usuarios.ts:147-155`; `websocket.ts:230-243`) | Igual ao web. Desktop sempre conectado = sempre online (§4.2) |
| **Vários aparelhos** | Suportado; nenhum login desativa os outros (`usuarios.ts:47-64`) | Desktop + celular + web convivem, com as ressalvas de §4.2 |
| **MediaMTX** | Sem autenticação; só relay pelo coturn TCP (`bin/coturn/turnserver.conf`); gravação só de H264/VP9 (`bin/mediamtx/mediamtx.docker.yml:27-37`) | O desktop precisa de TURN sobre TCP/TLS com `iceTransportPolicy = relay` e de vídeo H264 ou VP9 para a chamada ser gravada |

---

## 5. Não confirmado / a verificar

1. Efeito real de `additionalProperties:false` no OpenAPI vivo (campos extras removidos ou recusados) — exige POST.
2. Padrões do Bun para o WebSocket (idle 120 s, pings automáticos de payload vazio): não estão no código do servidor e `node_modules` não está no host.
3. Tratamento de quadros WebSocket de tamanho 0 pelo `Bird.Socket.Client.pas` — leitura de código sugere falha; testar com o servidor de dev, uma conexão ociosa por mais de 2 min.
4. Assinatura do MinIO com `Host: host:443` explícito — dedução; testar só se o FMX permitir porta na URL.
5. PUT pré-assinado com `Transfer-Encoding: chunked` no MinIO.
6. Popup do web: som em dobro e botões de chamada sem efeito — leitura de código, não executado.
7. Como um app Win32 lê o estado das permissões de microfone/câmera do Windows (para a aba Permissões).
