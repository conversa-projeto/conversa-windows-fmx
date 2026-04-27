unit Screen.Capture;

// Captura a tela principal via GDI (BitBlt) e entrega frames BGR0 (32bpp).
// "BGR0" = 3 bytes BGR + 1 byte zero (mesmo que BGRA mas alpha sempre=0).
// Compatível com AV_PIX_FMT_BGR0 do FFmpeg.

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  Winapi.Windows;

type
  TOnScreenFrame = reference to procedure(Data: PByte; W, H: Integer);

  TScreenCapture = class
  private
    FThread:   TThread;
    FLock:     TCriticalSection;
    FOnFrame:  TOnScreenFrame;
    FFps:      Integer;
    FRunning:  Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(Fps: Integer = 30);
    procedure Stop;

    property OnFrame: TOnScreenFrame read FOnFrame write FOnFrame;
    property Fps:     Integer        read FFps;
  end;

implementation

{ TScreenCapture }

constructor TScreenCapture.Create;
begin
  inherited Create;
  FLock    := TCriticalSection.Create;
  FRunning := False;
  FFps     := 30;
end;

destructor TScreenCapture.Destroy;
begin
  Stop;
  FLock.Free;
  inherited;
end;

procedure TScreenCapture.Start(Fps: Integer = 30);
begin
  Stop;
  FFps     := Fps;
  FRunning := True;

  FThread := TThread.CreateAnonymousThread(procedure
  var
    ScreenDC:  HDC;
    MemDC:     HDC;
    Bmp:       HBITMAP;
    OldBmp:    HGDIOBJ;
    W, H:      Integer;
    Buf:       TBytes;
    Bmi:       TBitmapInfo;
    FrameMs:   Integer;
    T0:        Cardinal;
    Elapsed:   Integer;
    Callback:  TOnScreenFrame;
  begin
    FrameMs := 1000 div FFps;
    W       := GetSystemMetrics(SM_CXSCREEN);
    H       := GetSystemMetrics(SM_CYSCREEN);

    ScreenDC := GetDC(0);
    MemDC    := CreateCompatibleDC(ScreenDC);
    Bmp      := CreateCompatibleBitmap(ScreenDC, W, H);
    OldBmp   := SelectObject(MemDC, Bmp);

    SetLength(Buf, W * H * 4);

    FillChar(Bmi, SizeOf(Bmi), 0);
    with Bmi.bmiHeader do
    begin
      biSize        := SizeOf(TBitmapInfoHeader);
      biWidth       := W;
      biHeight      := -H;  // negativo = top-down (linha 0 = topo)
      biPlanes      := 1;
      biBitCount    := 32;
      biCompression := BI_RGB;
    end;

    while FRunning do
    begin
      T0 := GetTickCount;

      // Captura a tela para o MemDC
      BitBlt(MemDC, 0, 0, W, H, ScreenDC, 0, 0, SRCCOPY);

      // Extrai os pixels para Buf
      GetDIBits(MemDC, Bmp, 0, H, @Buf[0], Bmi, DIB_RGB_COLORS);

      // Entrega para quem estiver inscrito
      FLock.Enter;
      try
        Callback := FOnFrame;
      finally
        FLock.Leave;
      end;

      if Assigned(Callback) then
        Callback(@Buf[0], W, H);

      // Throttle para manter FPS alvo
      Elapsed := Integer(GetTickCount - T0);
      if Elapsed < FrameMs then
        Sleep(FrameMs - Elapsed);
    end;

    SelectObject(MemDC, OldBmp);
    DeleteObject(Bmp);
    DeleteDC(MemDC);
    ReleaseDC(0, ScreenDC);
  end);

  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TScreenCapture.Stop;
begin
  if not FRunning then Exit;
  FRunning := False;
  if FThread <> nil then
  begin
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
end;

end.
