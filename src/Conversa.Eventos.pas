// Daniel, Eduardo - 01/08/2024
unit Conversa.Eventos;

interface

uses
  Conversa.Evento.Base,
  Conversa.Proxy.Tipos,
  Conversa.Tipos,
  System.Generics.Collections,
  System.Messaging;

type
  TMessageManager = System.Messaging.TMessageManager;
  TMessage = System.Messaging.TMessage;
  TEventoBase = class(TMessage<Integer>);
  TEventoAtualizacaoMensagem = class(TEventoBase);
  TEventoContadorMensagemVisualizar = class(TEventoBase);
  TEventoAtualizacaoListaConversa = class(TEventoBase);
  TEventoAtualizarContadorConversa = class(TEventoBase);
  TEventoMudancaStatusUsuarioSO = class(TEventoBase);
  TEventoStatusConexao = class(TEventoBase);

  // Novos eventos — adicionados 2026-04-21 para alinhamento com backend/web
  TEventoUsuarioDigitando = class(TMessage<TPair<Integer, Integer>>); // (conversa_id, usuario_id)
  TEventoUsuarioGravandoAudio = class(TMessage<TPair<Integer, Integer>>);
  TEventoStatusUsuario = class(TMessage<TPair<Integer, Boolean>>); // (usuario_id, online)
  TEventoConversaAtualizada = class(TMessage<Integer>); // conversa_id
  TEventoChamadaVideoAtivado = class(TMessage<TPair<Integer, Integer>>); // (chamada_id, usuario_id)

  // Payload de reacao em mensagem
  TPayloadReacao = record
    ConversaId: Integer;
    MensagemId: Integer;
    UsuarioId: Integer;
    Emoji: String;
    Acao: String; // "add" ou "remove"
  end;
  TEventoReacaoMensagem = class(TMessage<TPayloadReacao>);

  TObterConversas = class(TEventBase<TObterConversas, TRespostaConversas>);
  TObterDadosConversa = class(TEventBase<TObterDadosConversa, TRespostaConversa>);
  TErroServidor = class(TEventBase<TErroServidor, TRespostaErro>);
  TDownloadAnexo = class(TEventBase<TDownloadAnexo, TRespostaDownloadAnexo>);
  TObterMensagens = class(TEventBase<TObterMensagens, TRespostaMensagens>);
  TObterMensagensStatus = class(TEventBase<TObterMensagensStatus, TRespostaMensagensStatus>);
  TObterMensagensNovas = class(TEventBase<TObterMensagensNovas, TRespostaMensagensNovas>);

  TExibirMensagem = class(TEventBase<TExibirMensagem, TArrayMensagens>);
  TEnvioMensagem = class(TEventBase<TEnvioMensagem, TRespostaMensagem>);

  TObterChamadasHistorico = class(TEventBase<TObterChamadasHistorico, TRespostaChamadasHistorico>);

implementation

end.
