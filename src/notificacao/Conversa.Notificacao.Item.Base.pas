unit Conversa.Notificacao.Item.Base;

interface

uses
  System.Classes,
  System.SysUtils,
  FMX.Types,
  FMX.Controls,
  FMX.Forms;

type
  TNotificacaoItemBase = class(TFrame)
  protected
    FId: Integer;
  public
    procedure Fechar; virtual; abstract;
    function GetAltura: Single; virtual;
    property Id: Integer read FId write FId;
  end;

implementation

{$R *.fmx}

function TNotificacaoItemBase.GetAltura: Single;
begin
  Result := Self.Height;
end;

end.
