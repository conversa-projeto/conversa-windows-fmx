// Daniel, Eduardo - 01/08/2024
unit Conversa.Eventos;

interface

uses
  Conversa.Evento.Base,
  Conversa.Proxy.Tipos,
  Conversa.Tipos,
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

  TObterConversas = class(TEventBase<TObterConversas, TRespostaConversas>);
  TErroServidor = class(TEventBase<TErroServidor, TRespostaErro>);
  TDownloadAnexo = class(TEventBase<TDownloadAnexo, TRespostaDownloadAnexo>);
  TObterMensagens = class(TEventBase<TObterMensagens, TRespostaMensagens>);
  TObterMensagensStatus = class(TEventBase<TObterMensagensStatus, TRespostaMensagensStatus>);
  TObterMensagensNovas = class(TEventBase<TObterMensagensNovas, TRespostaMensagensNovas>);

  TExibirMensagem = class(TEventBase<TExibirMensagem, TArrayMensagens>);

implementation

end.
