// Eduardo - 11/02/2024
unit Mensagem.Tipos;

interface

uses
  FMX.Graphics;

{$SCOPEDENUMS ON}

type
  TLado = (Direito, Esquerdo);

  TMensagemConteudo = record
    Tipo: Integer;
    Dados: String;
  end;

  TMensagem = record
    ID: Integer;
    EnviadaEm: TDateTime;
    Lado: TLado;
    Remetente: String;
    Conteudos: TArray<TMensagemConteudo>;
  end;

implementation

end.
