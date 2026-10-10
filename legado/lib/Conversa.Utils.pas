unit Conversa.Utils;

interface

{$IFDEF MSWINDOWS}
uses
   Conversa.Windows.Utils;
{$ELSE}
uses
  Macapi.AppKit;
{$ENDIF}

function IsControlKeyPressed: Boolean;

implementation

function IsControlKeyPressed: Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := Conversa.Windows.Utils.IsControlKeyPressed;
{$ELSE}
  Result := False;
{$ENDIF}
end;

end.
