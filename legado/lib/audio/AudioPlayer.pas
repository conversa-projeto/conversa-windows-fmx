unit AudioPlayer;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.MMSystem,
  AudioTypes;

type
  TAudioPlayerThread = class(TThread)
  private
    FHWaveOut: HWAVEOUT;
    FWaveFormat: TWaveFormatEx;
    FBuffer: TAudioBuffer;
    FIsPlaying: Boolean;
    FWaveHeaders: array[0..7] of TWaveHdr;
    FBuffers: array[0..7] of array[0..2047] of Byte;
    FCurrentHeader: Integer;
    FFinalizado: Boolean;

    procedure InitializeWaveFormat;
    procedure PrepareHeaders;
    procedure UnprepareHeaders;

  public
    constructor Create(Buffer: TAudioBuffer);
    destructor Destroy; override;

    procedure Execute; override;
    procedure StartPlayback;
    procedure StopPlayback;
    procedure Finalizar;

    property Finalizado: Boolean read FFinalizado;
    property IsPlaying: Boolean read FIsPlaying;
  end;

implementation

procedure WaveOutProc(hWaveOut: HWAVEOUT; uMsg: UINT; dwInstance: DWORD_PTR; dwParam1: DWORD_PTR; dwParam2: DWORD_PTR); stdcall;
begin
  case uMsg of
    WOM_DONE:
    begin
      // Buffer foi reproduzido, pode ser reutilizado
    end;
  end;
end;

{ TAudioPlayerThread }

constructor TAudioPlayerThread.Create(Buffer: TAudioBuffer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBuffer := Buffer;
  FIsPlaying := False;
  FCurrentHeader := 0;
  FFinalizado := False;
  InitializeWaveFormat;
end;

destructor TAudioPlayerThread.Destroy;
begin
  Finalizar;
  StopPlayback;
  inherited;
end;

procedure TAudioPlayerThread.Finalizar;
begin
  if FFinalizado then
    Exit;
  FFinalizado := True;
  Terminate;
end;

procedure TAudioPlayerThread.InitializeWaveFormat;
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

procedure TAudioPlayerThread.PrepareHeaders;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    FillChar(FWaveHeaders[i], SizeOf(TWaveHdr), 0);
    FWaveHeaders[i].lpData := @FBuffers[i][0];
    FWaveHeaders[i].dwBufferLength := SizeOf(FBuffers[i]);
    waveOutPrepareHeader(FHWaveOut, @FWaveHeaders[i], SizeOf(TWaveHdr));
  end;
end;

procedure TAudioPlayerThread.UnprepareHeaders;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if FWaveHeaders[i].dwFlags and WHDR_PREPARED <> 0 then
      waveOutUnprepareHeader(FHWaveOut, @FWaveHeaders[i], SizeOf(TWaveHdr));
  end;
end;

procedure TAudioPlayerThread.StartPlayback;
var
  Result_Code: MMRESULT;
begin
  Result_Code := waveOutOpen(@FHWaveOut, WAVE_MAPPER, @FWaveFormat, DWORD_PTR(@WaveOutProc), DWORD_PTR(Self), CALLBACK_FUNCTION);

  if Result_Code <> MMSYSERR_NOERROR then
    raise Exception.Create('Erro ao abrir dispositivo de reprodução: ' + IntToStr(Result_Code));

  PrepareHeaders;
  FIsPlaying := True;
end;

procedure TAudioPlayerThread.StopPlayback;
begin
  if (FHWaveOut <> 0) and FIsPlaying then
  begin
    FIsPlaying := False;
    waveOutReset(FHWaveOut);
    Sleep(100);
    UnprepareHeaders;
    waveOutClose(FHWaveOut);
    FHWaveOut := 0;
  end;
end;

procedure TAudioPlayerThread.Execute;
var
  AudioData: TBytes;
  BytesRead: Integer;
  BufferedEnough: Boolean;
  NextPlayTime: Int64;
  CurrentTime: Int64;
  SleepTime: Integer;
const
  MIN_BUFFER_START = 8192;
  MIN_BUFFER_RUNNING = 4096;
  PLAY_INTERVAL = 23;
begin
  timeBeginPeriod(1);
  try
    StartPlayback;

    BufferedEnough := False;
    while not FFinalizado and not BufferedEnough do
    begin
      if FBuffer.Available >= MIN_BUFFER_START then
        BufferedEnough := True
      else
        Sleep(10);
    end;

    NextPlayTime := GetTickCount64;

    while not FFinalizado and FIsPlaying do
    begin
      CurrentTime := GetTickCount64;

      if (CurrentTime >= NextPlayTime) and (FBuffer.Available >= MIN_BUFFER_RUNNING) then
      begin
        BytesRead := FBuffer.Read(AudioData, SizeOf(FBuffers[FCurrentHeader]));

        if BytesRead > 0 then
        begin
          Move(AudioData[0], FBuffers[FCurrentHeader][0], BytesRead);
          FWaveHeaders[FCurrentHeader].dwBufferLength := BytesRead;
          waveOutWrite(FHWaveOut, @FWaveHeaders[FCurrentHeader], SizeOf(TWaveHdr));
          FCurrentHeader := (FCurrentHeader + 1) mod 8;
          NextPlayTime := NextPlayTime + PLAY_INTERVAL;

          if CurrentTime > NextPlayTime + 100 then
            NextPlayTime := CurrentTime + PLAY_INTERVAL;
        end;
      end;

      CurrentTime := GetTickCount64;
      SleepTime := Integer(NextPlayTime - CurrentTime);

      if SleepTime > 0 then
      begin
        if SleepTime > 50 then
          SleepTime := 50;
        Sleep(SleepTime);
      end
      else
        Sleep(1);
    end;

    StopPlayback;
  finally
    timeEndPeriod(1);
  end;
end;

end.
