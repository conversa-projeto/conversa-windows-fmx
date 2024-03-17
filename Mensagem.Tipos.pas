// Eduardo - 11/02/2024
unit Mensagem.Tipos;

interface

uses
  FMX.Graphics;

{$SCOPEDENUMS ON}

type
  TLado = (Direito, Esquerdo);

  TSelecaoAnexo = record
    Legenda: String;
    Arquivos: TArray<String>;
  end;

  TMensagem = record
    ID: Integer;
    EnviadaEm: TDateTime;
    Lado: TLado;
    Remetente: String;
    Texto: String;
    Anexo: TSelecaoAnexo;
  end;

implementation

end.
