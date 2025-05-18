// Eduardo/Daniel - 17/05/2025
unit Conversa.Evento.Base;

interface

uses
  System.Classes,
  System.Messaging,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading;

type
  TEventListenerMethodBase<T> = procedure (const Sender: TObject; const M: T) of object;

  TEventBase<T, T2> = class(TMessage<T2>)
  private class var
    FManager: TMessageManager;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Subscribe(const Method: TEventListenerMethodBase<T>);
    class procedure Unsubscribe(const Method: TEventListenerMethodBase<T>);
    class procedure Send(Value: T2);
  end;

implementation

{ TEventoBase }

class constructor TEventBase<T, T2>.Create;
begin
  FManager := TMessageManager.Create;
end;

class destructor TEventBase<T, T2>.Destroy;
begin
  FreeAndNil(FManager);
end;

class procedure TEventBase<T, T2>.Subscribe(const Method: TEventListenerMethodBase<T>);
begin
  TMonitor.Enter(FManager);
  try
    TEventBase<T, T2>.FManager.SubscribeToMessage(TClass(Self), TMessageListenerMethod(Method));
  finally
    TMonitor.Exit(FManager);
  end;
end;

class procedure TEventBase<T, T2>.Unsubscribe(const Method: TEventListenerMethodBase<T>);
begin
  TMonitor.Enter(FManager);
  try
    TEventBase<T, T2>.FManager.Unsubscribe(TClass(Self), TMessageListenerMethod(Method));
  finally
    TMonitor.Exit(FManager);
  end;
end;

class procedure TEventBase<T, T2>.Send(Value: T2);
begin
  TThread.ForceQueue(
    nil,
    procedure
    begin
      TMonitor.Enter(FManager);
      try
        FManager.SendMessage(FManager, Self.Create(Value), True);
      finally
        TMonitor.Exit(FManager);
      end;
    end
  );
end;

end.

