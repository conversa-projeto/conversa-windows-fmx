unit Conversa.FrameBase;

interface

uses
  Winapi.Windows,
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
  FMX.Platform.Win,
  PascalStyleScript;

type
  TFrameBase = class(TFrame)
  private
  protected
    function GetPSSClassName: String; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    function IsFormActive: Boolean;
  end;

implementation

{$R *.fmx}

{ TFrameBase }

constructor TFrameBase.Create(AOwner: TComponent);
begin
  inherited;
  TPascalStyleScript.Instance.RegisterObject(Self, GetPSSClassName);
end;

function TFrameBase.GetPSSClassName: String;
begin
  Result := ClassName.Substring(1);
end;

function IsWindowFocused(Handle: HWND): Boolean;
begin
  Result := (GetForegroundWindow = Handle);
end;

function TFrameBase.IsFormActive: Boolean;
var
  Last: TFmxObject;
  ParentForm: HWND;
  WindowsActiveForm: HWND;
begin
  Result := False;

  Last := Parent;
  while Assigned(Last) and Last.HasParent do
    Last := Last.Parent;

  if not Assigned(Last) or not Last.InheritsFrom(TForm) then Exit;
  ParentForm := FormToHWND(TForm(Last));
  if not IsWindowVisible(ParentForm) then Exit;
  if not IsWindow(ParentForm) then Exit;
  if not IsWindowEnabled(ParentForm) then Exit;
  if IsIconic(ParentForm) then Exit;

  WindowsActiveForm := GetForegroundWindow;
  if not ((WindowsActiveForm = ParentForm) or (WindowsActiveForm = ApplicationHWND)) then
    Exit;

  Result := True;
end;

end.
