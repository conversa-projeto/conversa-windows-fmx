// Eduardo - 03/08/2024
unit chat.mensagem.conteudo;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  chat.base;

type
  TTarget = record
    Width: Single;
    Height: Single;
  end;

  TChatConteudo = class(TChatBase)
  public
    function Target(Largura: Single): TTarget; virtual; abstract;
  end;

implementation

{$R *.fmx}

{ TConteudo }

end.
