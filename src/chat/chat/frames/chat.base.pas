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

constructor TChatBase.Create(AOwner: TComponent);
begin
  inherited;
  Name := 'frm'+ Copy(Self.ClassName, 2) + FormatDateTime('ddhhnnsszzz', Now);
  Sleep(1);
end;

end.
