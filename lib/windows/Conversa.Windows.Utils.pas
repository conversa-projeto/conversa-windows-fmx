// Daniel - 2024-07-26
unit Conversa.Windows.Utils;

interface

function IsApplicationAlreadyRunning: Boolean;
procedure BringApplicationToFront;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.TlHelp32,
  Winapi.PsAPI,
  FMX.Forms;

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

function IsApplicationAlreadyRunning: Boolean;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  CurrentFileName: string;
  CurrentFilePath: string;
  CurrentPID: DWORD;

  ProcessName: String;
  ProcessFileName: String;
begin
  Result := False;
  CurrentFileName := ExtractFileName(ParamStr(0));
  CurrentFilePath := GetCurrentDir;
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

      if SameText(ExtractFileDir(ProcessFileName), CurrentFilePath) then
      begin
        Result := True;
        Break;
      end;
    until not Process32Next(Snapshot, ProcessEntry);
  end;

  CloseHandle(Snapshot);
end;

procedure BringApplicationToFront;
var
  h: HWND;
begin
  // Assumindo que a janela principal da aplicação tem um título único
  h := FindWindow(nil, PChar(Application.Title));
  if h <> 0 then
  begin
    if IsIconic(h) then
      ShowWindow(h, SW_RESTORE)
    else
      SetForegroundWindow(h);
  end;
end;


end.
