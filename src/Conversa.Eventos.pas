// Daniel, Eduardo - 01/08/2024
unit Conversa.Eventos;

interface

uses
  System.SysUtils,
  System.Messaging;

type
  TEventoBase = class(TMessage<Integer>);
  TEventoAtualizacaoMensagem = class(TEventoBase);
  TEventoContadorMensagemVisualizar = class(TEventoBase);
  TEventoAtualizacaoListaConversa = class(TEventoBase);
  TEventoAtualizarContadorConversa = class(TEventoBase);
  TEventoMudancaStatusUsuarioSO = class(TEventoBase);

  TEvento = record
  public
    class procedure Adicionar(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0); static;
    class procedure Executar(Tipo: TClass; ID: Integer = 0; Value: Integer = -1); static;
    class procedure Remover(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0); static;
  end;

implementation

uses
  System.Generics.Collections;

var
  Gerenciadores: TArray<TPair<Integer, TMessageManager>>;

class procedure TEvento.Adicionar(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0);
var
  Gerenciador: TMessageManager;
begin
  Gerenciador := nil;
  for var Item in Gerenciadores do
  begin
    if Item.Key <> ID then
      Continue;
    Gerenciador := Item.Value;
    Break;
  end;

  if not Assigned(Gerenciador) then
  begin
    Gerenciador := TMessageManager.Create;
    Gerenciadores := Gerenciadores + [TPair<Integer, TMessageManager>.Create(ID, Gerenciador)];
  end;

  Gerenciador.SubscribeToMessage(
    Tipo,
    procedure(const Sender: TObject; const M: TMessage)
    begin
      Proc((M as TEventoBase).Value);
    end
  );
end;

class procedure TEvento.Executar(Tipo: TClass; ID: Integer = 0; Value: Integer = -1);
var
  Evento: TEventoBase;
begin
  for var Item in Gerenciadores do
  begin
    if Item.Key <> ID then
      Continue;

    Evento := Tipo.Create as TEventoBase;
    Evento.Create(Value);

    Item.Value.SendMessage(nil, Evento);
    Exit;
  end;
end;

class procedure TEvento.Remover(Tipo: TClass; Proc: TProc<Integer>; ID: Integer = 0);
var
  I: Integer;
begin
  for I := 0 to Pred(Length(Gerenciadores)) do
  begin
    if Gerenciadores[I].Key = ID then
    begin
      Gerenciadores[I].Value.Free;
      Delete(Gerenciadores, I, 1);
      Exit;
    end;
  end;
end;

initialization
  Gerenciadores := [];

finalization
  for var Item in Gerenciadores do
    Item.Value.Free;

end.
