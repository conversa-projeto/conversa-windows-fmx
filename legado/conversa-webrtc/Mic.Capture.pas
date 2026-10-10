unit Mic.Capture;

// Captura de microfone via waveIn (MMSystem).
// Configurado para 48kHz / 16-bit / estéreo — pronto para o encoder Opus.
// Pool de 4 buffers de 20ms cada (960 amostras estéreo = 3840 bytes).

interface

uses
  System.SysUtils, System.SyncObjs,
  Winapi.Windows, Winapi.MMSystem;

type
  // PCM: ponteiro para buffer S16 interleaved estéreo
  // Samples: número de amostras (não bytes; ex: 960 para 20ms @ 48kHz)
  TOnMicData = reference to procedure(PCM: PByte; Samples: Integer);

  TMicCapture = class
  private const
    BUFFER_COUNT  = 4;
    FRAME_SAMPLES = 960;  // 20ms @ 48kHz
  private
    FWaveIn:    HWAVEIN;
    FFormat:    TWaveFormatEx;
    FHeaders:   array[0..BUFFER_COUNT-1] of TWaveHdr;
    FBuffers:   array[0..BUFFER_COUNT-1] of TBytes;
    FOnData:    TOnMicData;
    FRunning:   Boolean;
    FSampleRate: Integer;
    FChannels:   Integer;
  public
    constructor Create(SampleRate: Integer = 48000; Channels: Integer = 2);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    property OnData: TOnMicData read FOnData write FOnData;
    property SampleRate: Integer read FSampleRate;
    property Channels:   Integer read FChannels;
  end;

implementation

// Callback chamado pelo sistema de áudio em thread de alta prioridade.
// NÃO chamar funções waveIn de bloqueio aqui exceto waveInAddBuffer.
procedure WaveInProc(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD_PTR;
  dwParam1, dwParam2: DWORD_PTR); stdcall;
var
  Capture: TMicCapture;
  Hdr:     PWaveHdr;
  Samples: Integer;
begin
  if uMsg <> WIM_DATA then Exit;

  Capture := TMicCapture(dwInstance);
  if not Capture.FRunning then Exit;

  Hdr     := PWaveHdr(dwParam1);
  Samples := Integer(Hdr.dwBytesRecorded) div (Capture.FChannels * 2); // 2 bytes por sample S16

  if (Hdr.dwBytesRecorded > 0) and Assigned(Capture.FOnData) then
    Capture.FOnData(PByte(Hdr.lpData), Samples);

  // Re-enfileira o buffer para continuar capturando
  waveInAddBuffer(hwi, Hdr, SizeOf(TWaveHdr));
end;

{ TMicCapture }

constructor TMicCapture.Create(SampleRate: Integer = 48000; Channels: Integer = 2);
begin
  inherited Create;
  FSampleRate := SampleRate;
  FChannels   := Channels;
  FRunning    := False;
  FWaveIn     := 0;

  FillChar(FFormat, SizeOf(FFormat), 0);
  FFormat.wFormatTag      := WAVE_FORMAT_PCM;
  FFormat.nChannels       := Channels;
  FFormat.nSamplesPerSec  := SampleRate;
  FFormat.wBitsPerSample  := 16;
  FFormat.nBlockAlign     := Channels * 2;
  FFormat.nAvgBytesPerSec := SampleRate * Channels * 2;
end;

destructor TMicCapture.Destroy;
begin
  Stop;
  inherited;
end;

procedure TMicCapture.Start;
var
  I:       Integer;
  BufSize: Integer;
  Ret:     MMRESULT;
begin
  if FRunning then Exit;

  BufSize := FRAME_SAMPLES * FChannels * 2; // bytes por buffer (20ms S16 stereo)

  Ret := waveInOpen(@FWaveIn, WAVE_MAPPER, @FFormat,
    DWORD_PTR(@WaveInProc), DWORD_PTR(Self), CALLBACK_FUNCTION);
  if Ret <> MMSYSERR_NOERROR then
    raise Exception.CreateFmt('waveInOpen falhou: %d', [Ret]);

  FRunning := True;

  // Prepara e enfileira os buffers
  for I := 0 to BUFFER_COUNT - 1 do
  begin
    SetLength(FBuffers[I], BufSize);
    FillChar(FHeaders[I], SizeOf(TWaveHdr), 0);
    FHeaders[I].lpData         := PAnsiChar(@FBuffers[I][0]);
    FHeaders[I].dwBufferLength := BufSize;
    waveInPrepareHeader(FWaveIn, @FHeaders[I], SizeOf(TWaveHdr));
    waveInAddBuffer(FWaveIn, @FHeaders[I], SizeOf(TWaveHdr));
  end;

  waveInStart(FWaveIn);
end;

procedure TMicCapture.Stop;
var
  I: Integer;
begin
  if not FRunning then Exit;
  FRunning := False;

  if FWaveIn <> 0 then
  begin
    waveInStop(FWaveIn);
    waveInReset(FWaveIn);
    for I := 0 to BUFFER_COUNT - 1 do
      waveInUnprepareHeader(FWaveIn, @FHeaders[I], SizeOf(TWaveHdr));
    waveInClose(FWaveIn);
    FWaveIn := 0;
  end;
end;

end.
