// 2024-08-01
// Daniel, Eduardo
unit Conversa.Eventos;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  TTipoEvento = (AtualizacaoMensagem, ContadorMensagemVisualizar, AtualizacaoListaConversa);

  TEvento = record
  private
    FTipo: TTipoEvento;
    FID: Integer;
    FProc: TProc;
  public
    class procedure Adicionar(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0); static;
    class procedure Executar(Tipo: TTipoEvento; ID: Integer = 0); static;
    class procedure Remover(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0); static;
  end;

implementation

var
  Eventos: TThreadList<TEvento>;

class procedure TEvento.Adicionar(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0);
var
  Evento: TEvento;
begin
  Evento.FID := ID;
  Evento.FTipo := Tipo;
  Evento.FProc := Proc;
  Eventos.Add(Evento);
end;

class procedure TEvento.Executar(Tipo: TTipoEvento; ID: Integer = 0);
var
  Evento: TEvento;
begin
  with Eventos.LockList do
  try
    for Evento in ToArray do
      if (Evento.FTipo = Tipo) and (Evento.FID = ID) then
        Evento.FProc();
  finally
    Eventos.UnlockList;
  end;
end;

class procedure TEvento.Remover(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0);
var
  I: Integer;
  Evs: TList<TEvento>;
begin
  Evs := Eventos.LockList;
  try
    for I := 0 to Pred(Evs.Count) do
      if (Evs[I].FTipo = Tipo) and (Evs[I].FID = ID) and ((@Evs.ToArray[I].FProc) = @Proc) then
        Evs.Remove(Evs[I]);
  finally
    Eventos.UnlockList;
  end;
end;

initialization
  Eventos := TThreadList<TEvento>.Create;

finalization
  FreeAndNil(Eventos);

end.
