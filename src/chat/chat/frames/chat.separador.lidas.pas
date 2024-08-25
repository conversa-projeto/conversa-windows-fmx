// Eduardo - 25/08/2024
unit chat.separador.lidas;

interface

uses
  System.Types,
  System.Classes,
  FMX.Controls,
  FMX.Objects,
  chat.base, FMX.Types;

type
  TChatSeparadorLidas = class(TChatBase)
    rtgFundo: TRectangle;
    txtMensagem: TText;
  end;

implementation

{$R *.fmx}

end.
