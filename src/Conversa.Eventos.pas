// Daniel, Eduardo - 01/08/2024
unit Conversa.Eventos;

interface

uses
  System.SysUtils,
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

//  TEvento = record
//  public
//    class procedure Adicionar(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0); static;
//    class procedure Executar(Tipo: TClass; ID: Integer = 0; Value: Integer = -1); static;
//    class procedure Remover(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0); static;
//  end;

implementation

uses
  System.Generics.Collections;

//class procedure TEvento.Adicionar(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0);
//begin
//  TMessageManager.DefaultManager.SubscribeToMessage(
//    Tipo,
//    procedure(const Sender: TObject; const M: TMessage)
//    begin
//      Proc((M as TEventoBase).Value);
//    end
//  );
//end;
//
//class procedure TEvento.Executar(Tipo: TClass; ID: Integer = 0; Value: Integer = -1);
//var
//  Evento: TEventoBase;
//begin
//  Evento := Tipo.Create as TEventoBase;
//  Evento.Create(Value);
//  TMessageManager.DefaultManager.SendMessage(nil, Evento);
//end;
//
//class procedure TEvento.Remover(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0);
//begin
//  TMessageManager.DefaultManager.Unsubscribe(Tipo, Proc);
//end;

//initialization
//  Gerenciadores := [];
//
//finalization
//  for var Item in Gerenciadores do
//    Item.Value.Free;

end.
