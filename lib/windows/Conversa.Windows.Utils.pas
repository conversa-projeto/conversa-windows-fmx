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
procedure InicializarComSO;
procedure RemoveInicializacaoSO;
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
  System.Classes;

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

procedure InicializarComSO;
var
  Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False);
      Reg.WriteString(Application.Title, '"'+ ParamStr(0) +'" -inicializar');
      Reg.CloseKey;
    finally
      FreeAndNil(Reg);
    end;
  except
  end;
end;

procedure RemoveInicializacaoSO;
var
  Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      Reg.Openkey('Software\Microsoft\Windows\CurrentVersion\Run', False);
      if Reg.ValueExists(Application.Title) then
        Reg.DeleteValue(Application.Title);
      Reg.CloseKey;
    finally
      FreeAndNil(Reg);
    end;
  except
  end;
end;

function IsControlKeyPressed: Boolean;
begin
  Result := GetKeyState(VK_CONTROL) < 0;
end;

procedure SalvarPosicaoFormulario(Form: TForm);
var
  WindowPlacement: TWindowPlacement;
  JSONObject: TJSONObject;
  R: TRectF;
begin
  try
    // Obter o posicionamento atual da janela
    WindowPlacement.Length := SizeOf(TWindowPlacement);
    if not GetWindowPlacement(FormToHWND(Form), @WindowPlacement) then
      Exit;

    JSONObject := TJSONObject.Create;
    try
      JSONObject.AddPair('Flags', TJSONNumber.Create(WindowPlacement.Flags));
      JSONObject.AddPair('ShowCmd', TJSONNumber.Create(WindowPlacement.ShowCmd));
      JSONObject.AddPair('MinPositionX', TJSONNumber.Create(WindowPlacement.ptMinPosition.X));
      JSONObject.AddPair('MinPositionY', TJSONNumber.Create(WindowPlacement.ptMinPosition.Y));
      JSONObject.AddPair('MaxPositionX', TJSONNumber.Create(WindowPlacement.ptMaxPosition.X));
      JSONObject.AddPair('MaxPositionY', TJSONNumber.Create(WindowPlacement.ptMaxPosition.Y));
      R := Form.Bounds;
      JSONObject.AddPair('NormalPositionLeft', TJSONNumber.Create(Round(R.Left * Form.Handle.Scale)));
      JSONObject.AddPair('NormalPositionTop', TJSONNumber.Create(Round(R.Top * Form.Handle.Scale)));
      JSONObject.AddPair('NormalPositionRight', TJSONNumber.Create(Round(R.Right * Form.Handle.Scale)));
      JSONObject.AddPair('NormalPositionBottom', TJSONNumber.Create(Round(R.Bottom * Form.Handle.Scale)));

      with TStringStream.Create(JSONObject.ToString) do
      try
        SaveToFile(ExtractFilePath(ParamStr(0)) + 'FormPos.json');
      finally
        Free;
      end;
    finally
      JSONObject.Free;
    end;
  except
  end;
end;

procedure RestaurarPosicaoFormulario(Form: TForm);
var
  WindowPlacement: TWindowPlacement;
  JSONObject: TJSONObject;
  function FormPxToDp(const AForm: TCommonCustomForm; const APoint: TPoint): TPointF;
  var
    LScale: Single;
  begin
    LScale := AForm.Handle.Scale;
    Result := (TPointF(APoint) / LScale).Round;
  end;
begin
  if not FileExists(ExtractFilePath(ParamStr(0)) + 'FormPos.json') then
    Exit;
  with TStringStream.Create do
  try
    LoadFromFile(ExtractFilePath(ParamStr(0)) + 'FormPos.json');
    JSONObject := TJSONObject.ParseJSONValue(DataString) as TJSONObject;
  finally
    Free;
  end;
  if Assigned(JSONObject) then
  try
    WindowPlacement.Length := SizeOf(TWindowPlacement);
    WindowPlacement.Flags := JSONObject.GetValue<Integer>('Flags', 0);
    WindowPlacement.ShowCmd := JSONObject.GetValue<Integer>('ShowCmd', SW_SHOWNORMAL);
    WindowPlacement.ptMinPosition.X := JSONObject.GetValue<Integer>('MinPositionX', 0);
    WindowPlacement.ptMinPosition.Y := JSONObject.GetValue<Integer>('MinPositionY', 0);
    WindowPlacement.ptMaxPosition.X := JSONObject.GetValue<Integer>('MaxPositionX', 0);
    WindowPlacement.ptMaxPosition.Y := JSONObject.GetValue<Integer>('MaxPositionY', 0);
    WindowPlacement.rcNormalPosition.Left := JSONObject.GetValue<Integer>('NormalPositionLeft', 0);
    WindowPlacement.rcNormalPosition.Top := JSONObject.GetValue<Integer>('NormalPositionTop', 0);
    WindowPlacement.rcNormalPosition.Right := JSONObject.GetValue<Integer>('NormalPositionRight', 800);  // Valor padrão
    WindowPlacement.rcNormalPosition.Bottom := JSONObject.GetValue<Integer>('NormalPositionBottom', 600);  // Valor padrão
    SetWindowPlacement(FormToHWND(Form), @WindowPlacement);
  finally
    JSONObject.Free;
  end;
end;

procedure DefinirDiretorio;
begin
  SetCurrentDir(ExtractFileDir(ParamStr(0)));
end;

end.
