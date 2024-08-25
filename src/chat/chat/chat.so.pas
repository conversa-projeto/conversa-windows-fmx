// Eduardo - 17/08/2024
unit chat.so;

interface

uses
  FMX.Forms,
  FMX.Memo;

function IsFormActive(Parent: TFrame): Boolean;
procedure ShowEmoji(m: TMemo);

implementation

uses
  System.SysUtils,
  System.Types,
  System.DateUtils,
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  FMX.Platform.Win,
{$ELSE}
{$ENDIF}
  FMX.Types,
  FMX.Controls;

{$IFDEF MSWINDOWS}
function IsFormActive(Parent: TFrame): Boolean;
var
  Last: TFmxObject;
  ParentForm: HWND;
  WindowsActiveForm: HWND;
begin
  Result := False;

  Last := Parent;
  while Assigned(Last) and Last.HasParent do
    Last := Last.Parent;

  if not Assigned(Last) or not Last.InheritsFrom(TForm) then
    Exit;

  ParentForm := FormToHWND(TForm(Last));
  if not IsWindowVisible(ParentForm) or not IsWindow(ParentForm) or not IsWindowEnabled(ParentForm) or IsIconic(ParentForm) then
    Exit;

  WindowsActiveForm := GetForegroundWindow;

  if not ((WindowsActiveForm = ParentForm) or (WindowsActiveForm = ApplicationHWND)) then
    Exit;

  Result := True;
end;

procedure ShowEmoji(m: TMemo);
const
  KEYEVENTF_KEYDOWN = 0;
var
  FEdit: HWND;
  Input: Array[0..3] of TInput;
  Inicio: TDateTime;
  AbsolutePos: TPointF;
  Scale: Single;
begin
  // Obtenha a posição absoluta do componente FMX
  AbsolutePos := m.LocalToAbsolute(PointF(0, 0));

  // Obtenha a escala (DPI) do monitor atual
  Scale := TWinWindowHandle(Application.MainForm.Handle).Scale;

  FEdit := CreateWindowEx(
    WS_EX_CLIENTEDGE,
    'EDIT',
    '',
    WS_CHILD or WS_VISIBLE or
    ES_LEFT or ES_AUTOHSCROLL,
    Round(AbsolutePos.X * Scale), Round(AbsolutePos.Y * Scale),
    1, 1,
    FormToHWND(Application.MainForm),
    0,
    HInstance,
    nil
  );
  try
    SetFocus(FEdit);

    ZeroMemory(@Input,sizeof(Input));

    Input[0].Itype := INPUT_KEYBOARD;
    Input[0].ki.wVk := VK_RWIN;
    Input[0].ki.dwFlags := KEYEVENTF_KEYDOWN;

    Input[1].Itype := INPUT_KEYBOARD;
    Input[1].ki.wVk := VK_OEM_PERIOD;
    Input[1].ki.dwFlags := KEYEVENTF_KEYDOWN;

    Input[2].Itype := INPUT_KEYBOARD;
    Input[2].ki.wVk := VK_OEM_PERIOD;
    Input[2].ki.dwFlags := KEYEVENTF_KEYUP;

    Input[3].Itype := INPUT_KEYBOARD;
    Input[3].ki.wVk := VK_RWIN;
    Input[3].ki.dwFlags := KEYEVENTF_KEYUP;

    SendInput(4, Input[0], sizeof(TInput));

    Inicio := Now;

    while IncMilliSecond(Inicio, 100) > Now do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;
  finally
    DestroyWindow(FEdit);
  end;

  m.SetFocus;
end;
{$ELSE}
function IsFormActive(Parent: TForm): Boolean;
begin
  Result := True;
end;

procedure ShowEmoji(m: TMemo);
begin
end;
{$ENDIF}

end.
