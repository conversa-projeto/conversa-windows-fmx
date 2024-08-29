// Eduardo - 11/08/2024
unit chat.base;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Forms;

type
  TChatBase = class(TFrame)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

var
  FCount: Integer;

constructor TChatBase.Create(AOwner: TComponent);
begin
  inherited;
  Inc(FCount);
  Name := 'frm_'+ Self.ClassName + FCount.ToString;
end;

initialization
  FCount := 0;

end.
