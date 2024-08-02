// 2024-08-01
// Daniel, Eduardo
unit Conversa.Eventos;

interface

uses
  System.SysUtils;

type
  TTipoEvento = (AtualizacaoMensagem, ContadorMensagemVisualizar);

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
  Eventos: TArray<TEvento>;

class procedure TEvento.Adicionar(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0);
var
  Evento: TEvento;
begin
  Evento.FID := ID;
  Evento.FTipo := Tipo;
  Evento.FProc := Proc;
  Eventos := Eventos + [Evento];
end;

class procedure TEvento.Executar(Tipo: TTipoEvento; ID: Integer = 0);
var
  Evento: TEvento;
begin
  for Evento in Eventos do
    if (Evento.FTipo = Tipo) and (Evento.FID = ID) then
      Evento.FProc();
end;

class procedure TEvento.Remover(Tipo: TTipoEvento; Proc: TProc; ID: Integer = 0);
var
  I: Integer;
begin
  for I := 0 to Pred(Length(Eventos)) do
    if (Eventos[I].FTipo = Tipo) and (Eventos[I].FID = ID) and (@Eventos[I].FProc = @Proc) then
      Delete(Eventos, I, 1);
end;

end.
