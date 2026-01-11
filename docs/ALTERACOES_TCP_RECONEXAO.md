# Alterações para Reconexão TCP e Remoção de Sleep

## Objetivo
Eliminar o `Sleep(3000)` no cliente e implementar reconexão automática com tolerância a quedas de conexão de até 5 segundos.

---

## 1. Alterações no Cliente TCP (lib/tcp.pas)

### 1.1 Novos Estados de Conexão ✅
Criar enum `TTCPClientState` com os estados:
- **Disconnected**: Sem conexão ativa
- **Connecting**: Tentando estabelecer conexão inicial
- **Connected**: Conexão ativa e funcional
- **Reconnecting**: Conexão perdida, tentando reconectar

### 1.2 Novos Callbacks ✅
- **OnConnected**: Disparado quando conexão é estabelecida (inicial ou reconexão)
- **OnDisconnected**: Disparado quando conexão é perdida
- **OnStateChanged**: Disparado quando o estado muda (opcional, para debug/UI)

### 1.3 Novo Método de Conexão ✅
Criar método `SetConnectionParams` ou `Connect` que recebe:
- Host e Porta (já existentes)
- Dados de registro (bytes a enviar automaticamente após conectar)
- Callback de conexão estabelecida

### 1.4 Lógica de Reconexão com Backoff ✅
Quando a conexão cair:
1. Mudar estado para `Reconnecting`
2. Disparar `OnDisconnected`
3. Tentar reconectar com backoff exponencial:
   - 1ª tentativa: imediata
   - 2ª tentativa: 500ms
   - 3ª tentativa: 1000ms
   - 4ª tentativa: 2000ms
   - 5ª+ tentativas: 5000ms (máximo)
4. Ao reconectar com sucesso:
   - Reenviar dados de registro automaticamente
   - Mudar estado para `Connected`
   - Disparar `OnConnected`

### 1.5 Heartbeat (Ping/Pong) ✅
- Cliente envia ping a cada 2 segundos quando conectado
- Se não receber pong em 3 segundos, considera conexão morta
- Tipo de mensagem: `[2]` para ping, `[3]` para pong

---

## 2. Alterações no Servidor TCP (rest/src/tcp/tcp.pas)

### 2.1 Heartbeat (Pong) ✅
- Ao receber mensagem tipo `[2]` (ping), responder imediatamente com `[3]` (pong)
- Nenhum processamento adicional necessário

### 2.2 Detecção de Timeout ✅
- Se não receber ping de um cliente em 10 segundos, considerar cliente desconectado
- Disparar `OnClientDisconnect` e limpar recursos

---

## 3. Alterações no Servidor de Chamadas (rest/src/conversa/conversa.chamada.pas)

### 3.1 Tratamento de Mensagens de Heartbeat ✅
- Adicionar case para tipo `2` (ping) no `OnServerReceive`
- Responder com pong através do servidor TCP
- Ignorar no processamento de áudio

### 3.2 Limpeza de Clientes Desconectados ✅
- No `DisconnectClient`, além de remover da lista de chamadas:
  - Remover do `MapaClientes`
  - Notificar outros participantes via WebSocket (opcional)

---

## 4. Alterações na Chamada do Cliente (src/chamada/Conversa.Chamada.pas)

### 4.1 Remoção do Sleep(3000) ✅
Remover completamente a linha `Sleep(3000)` do método `ConectarTCPAudio`.

### 4.2 Novo Fluxo de Conexão ✅
O método `ConectarTCPAudio` passará a:
1. Criar instância do `TTCPClient`
2. Configurar dados de registro: `[0] + IntToBytes(Usuario.ID)`
3. Configurar callback `OnConnected` que:
   - Inicia as threads de captura e reprodução de áudio
   - Atualiza estado da UI se necessário
4. Configurar callback `OnDisconnected` que:
   - Pausa temporariamente o envio de áudio
   - Exibe indicador visual de reconexão (opcional)
5. Chamar método de conexão

### 4.3 Tratamento de Reconexão Durante Chamada ✅
- Áudio capturado durante reconexão: descartar (não acumular)
- Áudio recebido: buffer existente continua funcionando
- Se reconexão demorar mais de 5s: considerar chamada perdida

### 4.4 Ajuste no Início das Threads de Áudio ✅
Mover o `FCaptureThread.Start` e `FPlayerThread.Start` para dentro do callback `OnConnected`, garantindo que só iniciam após conexão estabelecida.

---

## 5. Protocolo de Mensagens TCP (Atualizado)

| Tipo | Direção | Descrição |
|------|---------|-----------|
| `0`  | Cliente → Servidor | Registro: `[0][ID_Usuario:4bytes]` |
| `1`  | Cliente → Servidor | Áudio: `[1][ID_Chamada:4bytes][Dados]` |
| `1`  | Servidor → Cliente | Áudio: `[ID_Remetente:4bytes][ID_Chamada:4bytes][Dados]` |
| `2`  | Cliente → Servidor | Ping (heartbeat) |
| `3`  | Servidor → Cliente | Pong (resposta heartbeat) |

---

## 6. Fluxo de Eventos - Conexão Normal

```
Cliente                          Servidor
   |                                |
   |------ TCP Connect ------------>|
   |                                |
   |------ [0][UserID] ------------>| (Registro)
   |                                |
   |<----- OnConnected -------------|
   |                                |
   |------ [2] -------------------->| (Ping)
   |<----- [3] ---------------------| (Pong)
   |                                |
   |------ [1][ChamadaID][Audio] -->| (Áudio)
   |<----- [RemetenteID][...]------| (Áudio de outros)
```

---

## 7. Fluxo de Eventos - Reconexão

```
Cliente                          Servidor
   |                                |
   |~~~ Conexão Perdida ~~~~~~~~~~~|
   |                                |
   |<----- OnDisconnected ---------|
   |                                |
   | (backoff: 0ms)                 |
   |------ TCP Connect ------------>| FALHA
   |                                |
   | (backoff: 500ms)               |
   |------ TCP Connect ------------>| FALHA
   |                                |
   | (backoff: 1000ms)              |
   |------ TCP Connect ------------>| OK
   |                                |
   |------ [0][UserID] ------------>| (Re-registro automático)
   |                                |
   |<----- OnConnected -------------|
   |                                |
   | (Continua normalmente)         |
```

---

## 8. Arquivos Modificados

### Cliente (conversa-windows-fmx)
- `lib/tcp.pas` - Alterações principais no TTCPClient ✅
- `src/chamada/Conversa.Chamada.pas` - Remoção do Sleep e novo fluxo ✅

### Servidor (conversa/rest)
- `src/tcp/tcp.pas` - Heartbeat e timeout de clientes ✅
- `src/conversa/conversa.chamada.pas` - Tratamento de ping/pong ✅

---

## 9. Considerações de Implementação

### Thread Safety
- O callback `OnConnected` será chamado da thread do TCP, usar `TThread.Queue` ou `TThread.Synchronize` se precisar atualizar UI
- Os dados de registro devem ser armazenados de forma thread-safe

### Ordem de Operações
1. Primeiro implementar alterações no servidor (heartbeat)
2. Depois implementar alterações no cliente
3. Testar com servidor antigo (cliente deve funcionar, apenas sem heartbeat)
4. Testar cenários de queda de conexão

### Testes Recomendados
- Desconectar cabo de rede por 2s e reconectar
- Desconectar cabo de rede por 4s e reconectar
- Desconectar cabo de rede por 6s (deve falhar)
- Matar processo do servidor e reiniciar em 3s
- Iniciar cliente antes do servidor estar disponível
