// Eduardo - 11/02/2024
unit Mensagem.Tipos;

interface

uses
  FMX.Graphics;

{$SCOPEDENUMS ON}

type
  TLado = (Esquerdo, Direito);

  TMensagemConteudo = record
    id: Integer;
    tipo: Integer;
    ordem: Integer;
    conteudo: String
  end;

  TMensagem = record
    id: Integer;
    remetente_id: Integer;
    remetente: String;
    lado: TLado;
    conversa_id: Integer;
    alterada: TDateTime;
    inserida: TDateTime;
    exibida: Boolean;
    conteudos: TArray<TMensagemConteudo>;
  end;

implementation

end.
