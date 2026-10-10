# Refatoração do Sistema de Notificação

## Objetivo
Generalizar o sistema de notificação para suportar múltiplos tipos (Mensagem, Chamada).

---

## Tarefas

### 1. Criar unit de tipos (NOVA)
- [x] `Conversa.Notificacao.Tipos.pas`
  - [x] `{$SCOPEDENUMS ON}`
  - [x] `TTipoNotificacao = (Mensagem, Chamada)`
  - [x] `TMensagemNotificacao` record
  - [x] `TNotificacaoChamadaDados` record
  - [x] `GerarChaveNotificacao()` function

### 2. Criar classe base
- [x] `Conversa.Notificacao.Item.Base.pas`
  - [x] `TNotificacaoItemBase = class(TFrame)`
  - [x] Método abstrato `procedure Fechar;`
  - [x] Método virtual `function GetAltura: Single;`
  - [x] Propriedade `Id: Integer`

### 3. Renomear item de mensagem
- [x] `Conversa.Notificacao.Item.pas` → `Conversa.Notificacao.Item.Mensagem.pas`
- [x] `Conversa.Notificacao.Item.fmx` → `Conversa.Notificacao.Item.Mensagem.fmx`
- [x] Renomear classe `TNotificacaoItem` → `TNotificacaoItemMensagem`
- [x] Herdar de `TNotificacaoItemBase`
- [x] Implementar `Fechar`

### 4. Criar item de chamada
- [x] `Conversa.Notificacao.Item.Chamada.pas`
- [x] `Conversa.Notificacao.Item.Chamada.fmx`
- [x] `TNotificacaoItemChamada = class(TNotificacaoItemBase)`
  - [x] Campos: Nome, TipoChamada, Descricao
  - [x] Botão Atender (verde)
  - [x] Botão Recusar (vermelho)
  - [x] Callbacks: `FOnAtender: TProc<Integer>`, `FOnRecusar: TProc<Integer>`
  - [x] Sem auto-fechamento

### 5. Modificar manager principal
- [x] `Conversa.Notificacao.pas`
  - [x] Usar `Conversa.Notificacao.Tipos`
  - [x] Modificar `TNotificacao`:
    - [x] `FTipo: TTipoNotificacao`
    - [x] `FChave: String` (chave: `MSG_123`, `CALL_456`)
    - [x] `FChamadaDados: TNotificacaoChamadaDados`
    - [x] Métodos fluent: `Tipo()`, `Chave()`, `ChamadaDados()`
  - [x] Modificar `TNotificacaoManager`:
    - [x] `TDictionary<String, TNotificacao>` ao invés de `TList`
    - [x] `InternalApresentar`: factory para criar view por tipo
    - [x] `InternalFechar`: buscar por chave genérica
    - [x] `Fechar(ATipo: TTipoNotificacao; AId: Integer)`

### 6. Limpeza (PENDENTE)
- [ ] Remover arquivos antigos após validação:
  - [ ] `Conversa.Notificacao.Item.pas`
  - [ ] `Conversa.Notificacao.Item.fmx`

---

## Estrutura Final

```
notificacao/
├── Conversa.Notificacao.Tipos.pas              (tipos e constantes)
├── Conversa.Notificacao.pas                    (manager + TNotificacao)
├── Conversa.Notificacao.Visualizador.pas       (janela container)
├── Conversa.Notificacao.Item.Base.pas          (classe base)
├── Conversa.Notificacao.Item.Mensagem.pas      (item de mensagem)
├── Conversa.Notificacao.Item.Mensagem.fmx
├── Conversa.Notificacao.Item.Chamada.pas       (item de chamada)
└── Conversa.Notificacao.Item.Chamada.fmx
```

---

## Uso

### Notificação de Mensagem
```pascal
TNotificacaoManager.Apresentar(
  TNotificacao.New
    .Tipo(TTipoNotificacao.Mensagem)
    .ChatId(123)
    .Nome('João')
    .Hora(Now)
    .Conteudo('Olá!')
);

// Fechar
TNotificacaoManager.Fechar(TTipoNotificacao.Mensagem, 123);
```

### Notificação de Chamada
```pascal
var
  Dados: TNotificacaoChamadaDados;
begin
  Dados.Nome := 'Maria';
  Dados.TipoChamada := 'Chamada de vídeo';
  Dados.Descricao := 'Recebendo chamada...';
  Dados.OnAtender := procedure(Id: Integer) begin AtenderChamada(Id); end;
  Dados.OnRecusar := procedure(Id: Integer) begin RecusarChamada(Id); end;

  TNotificacaoManager.Apresentar(
    TNotificacao.New
      .Tipo(TTipoNotificacao.Chamada)
      .ChamadaId(456)
      .ChamadaDados(Dados)
  );
end;

// Fechar
TNotificacaoManager.Fechar(TTipoNotificacao.Chamada, 456);
```
