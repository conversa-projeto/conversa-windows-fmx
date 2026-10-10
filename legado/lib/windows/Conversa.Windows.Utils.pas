// Daniel - 2024-07-26
unit Conversa.Windows.Utils;

interface

uses
  FMX.Dialogs,
  FMX.Forms,
  Winapi.Messages;

const
  WM_RESTAURAR_CONVERSA = WM_USER + 1;
 
function IsControlKeyPressed: Boolean;
function IsApplicationAlreadyRunning: Boolean;
procedure SalvarPosicaoFormulario(Form: TForm);
procedure RestaurarPosicaoFormulario(Form: TForm);
procedure DefinirDiretorio;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.TlHelp32,
  Winapi.PsAPI,
  FMX.Platform.Win,
  System.Win.Registry,
  System.JSON,
  System.Types,
  System.Classes,
  Conversa.Configuracoes;

type
  TEnumData = record
    PID: DWORD;
    MainFormClassName: string;
    hWnd: HWND;
  end;
  PEnumData = ^TEnumData;

function GetProcessFileName(PID: DWORD): string;
var
  hProcess: THandle;
  FileName: array[0..MAX_PATH - 1] of Char;
begin
  Result := '';
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if hProcess <> 0 then
  try
    if GetModuleFileNameEx(hProcess, 0, FileName, MAX_PATH) > 0 then
      Result := FileName;
  finally
    CloseHandle(hProcess);
  end;
end;

function EnumWindowsProc(hWnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  PID: DWORD;
  pEnum: PEnumData;
  ClassName: array[0..255] of Char;
begin
  Result := True;
  pEnum := PEnumData(lParam);
  GetWindowThreadProcessId(hWnd, @PID);
  if PID = pEnum^.PID then
  begin
    GetClassName(hWnd, ClassName, 256);
    if string(ClassName) = pEnum^.MainFormClassName then
    begin
      pEnum^.hWnd := hWnd;
      Result := False;
    end;
  end;
end;

function GetMainFormHandleByPID(PID: DWORD; MainFormClassName: string): HWND;
var
  EnumData: TEnumData;
begin
  EnumData.PID := PID;
  EnumData.MainFormClassName := MainFormClassName;
  EnumData.hWnd := 0;
  EnumWindows(@EnumWindowsProc, LPARAM(@EnumData));
  Result := EnumData.hWnd;
end;

function IsApplicationAlreadyRunningInternal(out hWnd: HWND): Boolean;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  CurrentFileName: string;
  CurrentFilePath: string;
  CurrentPID: DWORD;
  ProcessName: string;
  ProcessFileName: string;
begin
  Result := False;
  hWnd := 0;
  CurrentFileName := ExtractFileName(ParamStr(0));
  CurrentFilePath := ParamStr(0);
  CurrentPID := GetCurrentProcessId;

  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;

  ProcessEntry.dwSize := SizeOf(TProcessEntry32);

  if Process32First(Snapshot, ProcessEntry) then
  begin
    repeat
      if ProcessEntry.th32ProcessID = CurrentPID then
        Continue;

      ProcessName := ProcessEntry.szExeFile;
      if not SameText(ProcessName, CurrentFileName) then
        Continue;

      ProcessFileName := GetProcessFileName(ProcessEntry.th32ProcessID);
      if ProcessFileName.Trim.IsEmpty then
        Continue;

      if SameText(ExtractFileDir(ProcessFileName), ExtractFileDir(CurrentFilePath)) then
      begin
        hWnd := GetMainFormHandleByPID(ProcessEntry.th32ProcessID, 'FMTTelaInicial');
        Result := True;
        Break;
      end;
    until not Process32Next(Snapshot, ProcessEntry);
  end;

  CloseHandle(Snapshot);
end;

procedure BringApplicationToFront(hWnd: HWND);
begin
  begin
  ShowWindow(hWnd, SW_RESTORE);
  ShowWindow(hWnd, SW_SHOW);
//  SetForegroundWindow(hWnd);
  SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  SetForegroundWindow(hWnd);
  //SwitchToThisWindow(hWnd, True);
  SendMessage(hWnd, WM_RESTAURAR_CONVERSA, 0, 0);
  end;
end;

function IsApplicationAlreadyRunning: Boolean;
var
  H: HWND;
begin
  Result := IsApplicationAlreadyRunningInternal(H);
  if Result then
    BringApplicationToFront(H);
end;

function IsControlKeyPressed: Boolean;
begin
  Result := GetKeyState(VK_CONTROL) < 0;
end;

procedure SalvarPosicaoFormulario(Form: TForm);
var
  WindowPlacement: TWindowPlacement;
  R: TRectF;
begin
  try
    WindowPlacement.Length := SizeOf(TWindowPlacement);
    if not GetWindowPlacement(FormToHWND(Form), @WindowPlacement) then
      Exit;

    Configuracoes.WindowPlacement := WindowPlacement;
    R := Form.Bounds;
    Configuracoes.WindowPlacement.rcNormalPosition.Left   := Round(R.Left * Form.Handle.Scale);
    Configuracoes.WindowPlacement.rcNormalPosition.Top    := Round(R.Top * Form.Handle.Scale);
    Configuracoes.WindowPlacement.rcNormalPosition.Right  := Round(R.Right * Form.Handle.Scale);
    Configuracoes.WindowPlacement.rcNormalPosition.Bottom := Round(R.Bottom * Form.Handle.Scale);

    TConfiguracoes.Save;
  except
  end;
end;

procedure RestaurarPosicaoFormulario(Form: TForm);
var
  WindowPlacement: TWindowPlacement;
begin
  WindowPlacement.Length := SizeOf(TWindowPlacement);
  WindowPlacement := Configuracoes.WindowPlacement;
  if WindowPlacement.rcNormalPosition.Right = 0 then
    WindowPlacement.rcNormalPosition.Right := 800;
  if WindowPlacement.rcNormalPosition.Bottom = 0 then
    WindowPlacement.rcNormalPosition.Bottom := 600;
  SetWindowPlacement(FormToHWND(Form), @WindowPlacement);
end;

procedure DefinirDiretorio;
begin
  SetCurrentDir(ExtractFileDir(ParamStr(0)));
end;

end.
