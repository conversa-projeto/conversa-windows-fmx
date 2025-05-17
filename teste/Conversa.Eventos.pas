// Eduardo/Daniel - 17/05/2025
unit Conversa.Eventos;

interface

uses
  Conversa.Evento.Base,
  Conversa.Tipos;

type
  TObterConversas = class(TEventBase<TObterConversas, TRespostaConversas>);
  TErroServidor = class(TEventBase<TErroServidor, TRespostaErro>);

implementation

end.
