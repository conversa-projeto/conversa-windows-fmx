// Eduardo - 17/08/2024
unit chat.so;

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  FMX.Platform.Win,
  Winapi.ShellAPI,
  Winapi.CommCtrl,
{$ENDIF}
  System.UITypes,
  FMX.Forms,
  FMX.Memo,
  FMX.Graphics,
  FMX.Surfaces;

function IsFormActive(Parent: TFrame): Boolean;
procedure ShowEmoji(m: TMemo);
function GetFileIconAsBitmap(const FileName: string): TBitmap;

implementation

uses
  System.SysUtils,
  System.Types,
  System.DateUtils,
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

function GetFileIconAsBitmap(const FileName: String): TBitmap;
var
  FileInfo: SHFILEINFOA;
  hIcon: Winapi.Windows.HICON;
  IconWidth: Integer;
  IconHeight: Integer;
  IconDC, MemDC: HDC;
  DIB: HBITMAP;
  BitmapInfo: Winapi.Windows.BITMAPINFO;
  BitmapBits: Pointer;
  Row: Integer;
  bitdata: TBitmapData;
begin
  Result := nil;
  // Obter o ícone do arquivo
  if SHGetFileInfoA(PAnsiChar(AnsiString(FileName)), 0, FileInfo, SizeOf(FileInfo),
    SHGFI_ICON or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES) <> 0 then
  begin
    hIcon := FileInfo.hIcon;
    if hIcon <> 0 then
    begin
      IconWidth := GetSystemMetrics(SM_CXSMICON);
      IconHeight := GetSystemMetrics(SM_CYSMICON);
      // Criar um DC compatível
      IconDC := CreateCompatibleDC(0);
      try
        // Configurar o BITMAPINFO para criar a seção DIB
        ZeroMemory(@BitmapInfo, SizeOf(BITMAPINFO));
        BitmapInfo.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
        BitmapInfo.bmiHeader.biWidth := IconWidth;
        BitmapInfo.bmiHeader.biHeight := -IconHeight;  // Negativo para top-down DIB
        BitmapInfo.bmiHeader.biPlanes := 1;
        BitmapInfo.bmiHeader.biBitCount := 32;  // 32 bits por pixel (RGBA)
        BitmapInfo.bmiHeader.biCompression := BI_RGB;
        // Criar a seção DIB e obter um ponteiro para os bits
        DIB := CreateDIBSection(IconDC, BitmapInfo, DIB_RGB_COLORS, BitmapBits, 0, 0);
        if DIB <> 0 then
        begin
          MemDC := CreateCompatibleDC(IconDC);
          try
            SelectObject(MemDC, DIB);
            // Desenhar o ícone no DC
            DrawIconEx(MemDC, 0, 0, hIcon, IconWidth, IconHeight, 0, 0, DI_NORMAL);
            // Criar o TBitmap do FireMonkey
            Result := TBitmap.Create(IconWidth, IconHeight);
            Result.Map(TMapAccess.Write, bitdata);
            try
              // Copiar as linhas de pixels do DIB para o TBitmap usando scanlines
              for Row := 0 to IconHeight - 1 do
              begin
                // Copiar a linha correspondente
                Move(Pointer(NativeInt(BitmapBits) + Row * IconWidth * 4)^, bitdata.GetScanline(Row)^, IconWidth * 4);
              end;
            finally
              Result.Unmap(bitdata);
            end;
          finally
            DeleteDC(MemDC);
            DeleteObject(DIB);
          end;
        end;
      finally
        DeleteDC(IconDC);
        DestroyIcon(hIcon);
      end;
    end;
  end;
end;

{$ELSE}
function IsFormActive(Parent: TForm): Boolean;
begin
  Result := True;
end;

procedure ShowEmoji(m: TMemo);
begin
end;

function GetFileIconAsBitmap(const FileName: string): TBitmap;
begin
end;
{$ENDIF}

end.
