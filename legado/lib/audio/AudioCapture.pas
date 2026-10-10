unit AudioCapture;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Winapi.Windows,
  Winapi.MMSystem,
  AudioTypes;

type
  TAudioCaptureThread = class(TThread)
  private
    FHWaveIn: HWAVEIN;
    FWaveFormat: TWaveFormatEx;
    FWaveHeaders: array[0..1] of TWaveHdr;
    FBuffers: array[0..1] of array[0..2047] of Byte;
    FBuffer: TAudioBuffer;
    FCriticalSection: TCriticalSection;
    FOnNewAudioData: TProc<TBytes>;
    FFinalizado: Boolean;

    procedure InitializeWaveFormat;
    procedure PrepareHeaders;
    procedure UnprepareHeaders;

  public
    constructor Create(Buffer: TAudioBuffer);
    destructor Destroy; override;

    procedure Execute; override;
    procedure StartCapture;
    procedure StopCapture;
    procedure Finalizar;

    property Finalizado: Boolean read FFinalizado;
    property OnNewAudioData: TProc<TBytes> read FOnNewAudioData write FOnNewAudioData;
  end;

implementation

procedure WaveInProc(hWaveIn: HWAVEIN; uMsg: UINT; dwInstance: DWORD_PTR; dwParam1: DWORD_PTR; dwParam2: DWORD_PTR); stdcall;
var
  CaptureThread: TAudioCaptureThread;
  WaveHdr: PWaveHdr;
  AudioData: TBytes;
begin
  CaptureThread := TAudioCaptureThread(dwInstance);

  case uMsg of
    WIM_DATA:
    begin
      WaveHdr := PWaveHdr(dwParam1);
      if Assigned(WaveHdr) and (WaveHdr.dwBytesRecorded > 0) then
      begin
        SetLength(AudioData, WaveHdr.dwBytesRecorded);
        Move(WaveHdr.lpData^, AudioData[0], WaveHdr.dwBytesRecorded);

        CaptureThread.FBuffer.Write(AudioData);

        if Assigned(CaptureThread.FOnNewAudioData) then
          CaptureThread.FOnNewAudioData(AudioData);

        if not CaptureThread.Finalizado then
          waveInAddBuffer(hWaveIn, WaveHdr, SizeOf(TWaveHdr));
      end;
    end;
  end;
end;

{ TAudioCaptureThread }

constructor TAudioCaptureThread.Create(Buffer: TAudioBuffer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBuffer := Buffer;
  FCriticalSection := TCriticalSection.Create;
  FFinalizado := False;
  InitializeWaveFormat;
end;

destructor TAudioCaptureThread.Destroy;
begin
  Finalizar;
  StopCapture;
  FCriticalSection.Free;
  inherited;
end;

procedure TAudioCaptureThread.Finalizar;
begin
  if FFinalizado then
    Exit;
  FFinalizado := True;
  Terminate;
end;

procedure TAudioCaptureThread.InitializeWaveFormat;
begin
  FillChar(FWaveFormat, SizeOf(FWaveFormat), 0);
  FWaveFormat.wFormatTag := WAVE_FORMAT_PCM;
  FWaveFormat.nChannels := 1;
  FWaveFormat.nSamplesPerSec := 44100;
  FWaveFormat.wBitsPerSample := 16;
  FWaveFormat.nBlockAlign := (FWaveFormat.nChannels * FWaveFormat.wBitsPerSample) div 8;
  FWaveFormat.nAvgBytesPerSec := FWaveFormat.nSamplesPerSec * FWaveFormat.nBlockAlign;
  FWaveFormat.cbSize := 0;
end;

procedure TAudioCaptureThread.PrepareHeaders;
var
  i: Integer;
begin
  for i := 0 to 1 do
  begin
    FillChar(FWaveHeaders[i], SizeOf(TWaveHdr), 0);
    FWaveHeaders[i].lpData := @FBuffers[i][0];
    FWaveHeaders[i].dwBufferLength := SizeOf(FBuffers[i]);
    waveInPrepareHeader(FHWaveIn, @FWaveHeaders[i], SizeOf(TWaveHdr));
    waveInAddBuffer(FHWaveIn, @FWaveHeaders[i], SizeOf(TWaveHdr));
  end;
end;

procedure TAudioCaptureThread.UnprepareHeaders;
var
  i: Integer;
begin
  for i := 0 to 1 do
  begin
    if FWaveHeaders[i].dwFlags and WHDR_PREPARED <> 0 then
      waveInUnprepareHeader(FHWaveIn, @FWaveHeaders[i], SizeOf(TWaveHdr));
  end;
end;

procedure TAudioCaptureThread.StartCapture;
var
  Result_Code: MMRESULT;
begin
  Result_Code := waveInOpen(@FHWaveIn, WAVE_MAPPER, @FWaveFormat, DWORD_PTR(@WaveInProc), DWORD_PTR(Self), CALLBACK_FUNCTION);

  if Result_Code <> MMSYSERR_NOERROR then
    raise Exception.Create('Erro ao abrir dispositivo de captura: ' + IntToStr(Result_Code));

  PrepareHeaders;

  Result_Code := waveInStart(FHWaveIn);
  if Result_Code <> MMSYSERR_NOERROR then
  begin
    UnprepareHeaders;
    waveInClose(FHWaveIn);
    raise Exception.Create('Erro ao iniciar captura: ' + IntToStr(Result_Code));
  end;
end;

procedure TAudioCaptureThread.StopCapture;
begin
  if FHWaveIn <> 0 then
  begin
    waveInStop(FHWaveIn);
    waveInReset(FHWaveIn);
    Sleep(100);
    UnprepareHeaders;
    waveInClose(FHWaveIn);
    FHWaveIn := 0;
  end;
end;

procedure TAudioCaptureThread.Execute;
begin
  StartCapture;

  while not FFinalizado do
    Sleep(50);

  StopCapture;
end;

end.
