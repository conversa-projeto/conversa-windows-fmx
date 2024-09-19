// \o/ Daniel - 2024-07-23
//
// Raymond Chen
//   https://devblogs.microsoft.com/oldnewthing/20130211-00/?p=5283
unit Conversa.Windows.Overlay;

interface

procedure AtualizarContadorNotificacao(const Quantidade: Integer; Force: Boolean = False);

implementation

uses
  Winapi.ActiveX,
  Winapi.CommCtrl,
  Winapi.ShlObj,
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Platform.Win,
  FMX.Types;

const
  CLSID_TaskbarList: TGUID = '{56FDF344-FD6D-11D0-958A-006097C9A090}';
  IID_ITaskbarList3: TGUID = '{C43DC798-95D1-4BEA-9030-BB99E2983A1A}';

type
  ITaskbarList = interface(IUnknown)
    ['{56FDF342-FD6D-11D0-958A-006097C9A090}']
    function HrInit: HResult; stdcall;
    function AddTab(hwnd: HWND): HResult; stdcall;
    function DeleteTab(hwnd: HWND): HResult; stdcall;
    function ActivateTab(hwnd: HWND): HResult; stdcall;
    function SetActiveAlt(hwnd: HWND): HResult; stdcall;
  end;

  ITaskbarList2 = interface(ITaskbarList)
    ['{602D4995-B13A-429B-A66E-1935E44F4317}']
    function MarkFullscreenWindow(hwnd: HWND; fFullscreen: BOOL): HResult; stdcall;
  end;

  ITaskbarList3 = interface(ITaskbarList2)
    ['{C43DC798-95D1-4BEA-9030-BB99E2983A1A}']
    function SetProgressValue(hwnd: HWND; ullCompleted: UInt64; ullTotal: UInt64): HResult; stdcall;
    function SetProgressState(hwnd: HWND; tbpFlags: Integer): HResult; stdcall;
    function RegisterTab(hwndTab: HWND; hwndMDI: HWND): HResult; stdcall;
    function UnregisterTab(hwndTab: HWND): HResult; stdcall;
    function SetTabOrder(hwndTab: HWND; hwndInsertBefore: HWND): HResult; stdcall;
    function SetTabActive(hwndTab: HWND; hwndMDI: HWND; tbatFlags: Integer): HResult; stdcall;
    function ThumbBarAddButtons(hwnd: HWND; cButtons: Cardinal; pButton: Pointer): HResult; stdcall;
    function ThumbBarUpdateButtons(hwnd: HWND; cButtons: Cardinal; pButton: Pointer): HResult; stdcall;
    function ThumbBarSetImageList(hwnd: HWND; himl: HIMAGELIST): HResult; stdcall;
    function SetOverlayIcon(hwnd: HWND; hIcon: HICON; pszDescription: LPCWSTR): HResult; stdcall;
    function SetThumbnailTooltip(hwnd: HWND; pszTip: LPCWSTR): HResult; stdcall;
    function SetThumbnailClip(hwnd: HWND; prcClip: PRect): HResult; stdcall;
  end;

var
  UltimaContagem: Integer = 0;

function BitmapToWinBitmap(const Bitmap: TBitmap): HBITMAP;
var
  BitmapData: TBitmapData;
  BitmapInfo: TBitmapInfo;
  DC: HDC;
  Bits: Pointer;
begin
  FillChar(BitmapInfo, SizeOf(BitmapInfo), 0);
  BitmapInfo.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
  BitmapInfo.bmiHeader.biWidth := Bitmap.Width;
  BitmapInfo.bmiHeader.biHeight := -Bitmap.Height; // Top-down DIB
  BitmapInfo.bmiHeader.biPlanes := 1;
  BitmapInfo.bmiHeader.biBitCount := 32;
  BitmapInfo.bmiHeader.biCompression := BI_RGB;

  DC := GetDC(0);
  try
    Result := CreateDIBSection(DC, BitmapInfo, DIB_RGB_COLORS, Bits, 0, 0);
    if Result <> 0 then
    begin
      if Bitmap.Map(TMapAccess.Read, BitmapData) then
      try
        Move(BitmapData.Data^, Bits^, Bitmap.Width * Bitmap.Height * 4); // Copiar os dados
      finally
        Bitmap.Unmap(BitmapData);
      end;
    end;
  finally
    ReleaseDC(0, DC);
  end;
end;

function CreateOverlayIcon(Count: Integer): HICON;
var
  Bitmap: TBitmap;
  IconInfo: TIconInfo;
  Text: string;
begin
  Bitmap := TBitmap.Create(32, 32);
  try
    Bitmap.Clear(TAlphaColors.Null);
    Bitmap.Canvas.BeginScene;
    try
      // Desenhar o ícone de base (aqui você pode desenhar o que quiser, exemplo, um círculo)
      Bitmap.Canvas.Fill.Color := TAlphaColors.Red;
      Bitmap.Canvas.FillEllipse(RectF(0, 0, 32, 32), 1);

      // Adicionar o contador no ícone
      if Count <= 9 then
        Text := IntToStr(Count)
      else
        Text := '9+';

      Bitmap.Canvas.Fill.Color := TAlphaColors.White;
      Bitmap.Canvas.Font.Family := 'Consolas';
      Bitmap.Canvas.Font.Size := 22;
      Bitmap.Canvas.FillText(RectF(0, 0, 32, 32), Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
    finally
      Bitmap.Canvas.EndScene;
    end;

    // Criar um HICON a partir do bitmap
    IconInfo.fIcon := True;
    IconInfo.xHotspot := 0;
    IconInfo.yHotspot := 0;
    IconInfo.hbmMask := BitmapToWinBitmap(Bitmap); // Máscara de bits
    IconInfo.hbmColor := BitmapToWinBitmap(Bitmap); // Bitmap de cores
    Result := CreateIconIndirect(IconInfo);
  finally
    Bitmap.Free;
  end;
end;

procedure SetTaskbarOverlayIcon(AIcon: HICON);
var
  TaskbarList: ITaskbarList3;
begin
  if Succeeded(CoCreateInstance(CLSID_TaskbarList, nil, CLSCTX_INPROC_SERVER, IID_ITaskbarList3, TaskbarList)) then
    TaskbarList.SetOverlayIcon(FormToHWND(FMX.Forms.Application.MainForm), AIcon, PChar('Notificações'));
end;

procedure AtualizarContadorNotificacao(const Quantidade: Integer; Force: Boolean = False);
var
  OverlayIcon: HICON;
begin
  if UltimaContagem <> Quantidade then
    UltimaContagem := Quantidade
  else
  if not Force then
    Exit;

  if Quantidade = 0 then
  begin
    SetTaskbarOverlayIcon(0);
    Exit;
  end;

  OverlayIcon := CreateOverlayIcon(Quantidade);

  if OverlayIcon = 0 then
    Exit;

  // Define o ícone de sobreposição na barra de tarefas
  SetTaskbarOverlayIcon(OverlayIcon);
  DestroyIcon(OverlayIcon); // Libera o ícone após o uso
end;

end.
