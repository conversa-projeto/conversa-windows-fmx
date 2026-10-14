unit Conversa.Eventos.Tipos;

{ Eventos do app que passam pelo barramento (records pequenos e imutáveis). Os eventos do WebSocket ficam
  em Conversa.Contrato.Eventos (Etapa 1.12). }

interface

type
  /// <summary>Um 401 numa rota protegida: o token venceu (12 h) ou foi invalidado. A tela volta ao login.</summary>
  TEventoSessaoExpirada = record
    Rota: string;
    constructor Create(const ARota: string);
  end;

implementation

{ TEventoSessaoExpirada }

constructor TEventoSessaoExpirada.Create(const ARota: string);
begin
  Rota := ARota;
end;

end.
