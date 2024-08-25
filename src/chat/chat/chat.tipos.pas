// Eduardo - 10/08/2024
unit chat.tipos;

interface

{$SCOPEDENUMS ON}

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Graphics,
  FMX.Forms;

type
  TLado = (Direito = Integer(TAlignLayout.Right), Esquerdo = Integer(TAlignLayout.Left));
  TStatus = (Pendente, Recebida, Visualizada);
  TTipo = (Texto, Imagem, Arquivo);
  TEvento = procedure(Frame: TFrame) of object;
  TEventoMouseDown = procedure(Frame: TFrame; Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single) of object;

  TConteudo = record
  public
    Tipo: TTipo;
    Conteudo: String;
    constructor Create(ATipo: TTipo; AConteudo: String);
  end;

  TEventoEnvio = procedure(Conteudos: TArray<TConteudo>) of object;

implementation

{ TConteudo }

constructor TConteudo.Create(ATipo: TTipo; AConteudo: String);
begin
  Tipo     := ATipo;
  Conteudo := AConteudo;
end;

end.
