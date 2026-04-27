unit Audio.Player;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes,
  Winapi.Windows, Winapi.MMSystem,
  FFmpeg.Binding;

type
  TAudioPlayer = class
  private
    FCodecCtx: PAVCodecContext;
    FPacket: PAVPacket;
    FFrame: PAVFrame;
    FLock: TCriticalSection;

    // waveOut
    FWaveOut: HWAVEOUT;
    FWaveFormat: TWaveFormatEx;
    FIsOpen: Boolean;

    // Pool de buffers
    FHeaders: array[0..7] of TWaveHdr;
    FBuffers: array[0..7] of TBytes;
    FCurrentHeader: Integer;

    procedure OpenWaveOut(SampleRate, Channels: Integer);
    procedure CloseWaveOut;
    procedure WriteAudioData(PCM: PByte; Size: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure FeedData(Data: PByte; Size: Integer);
  end;

implementation

const
  AUDIO_BUFFER_SIZE = 8192;

constructor TAudioPlayer.Create;
var
  Codec: PAVCodec;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FIsOpen := False;
  FCurrentHeader := 0;

  Codec := avcodec_find_decoder(AV_CODEC_ID_OPUS);
  if Codec = nil then
    raise Exception.Create('Opus decoder not found in FFmpeg');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Failed to allocate audio codec context');

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Failed to open Opus codec');

  FPacket := av_packet_alloc;
  FFrame := av_frame_alloc;
end;

destructor TAudioPlayer.Destroy;
begin
  CloseWaveOut;
  if FFrame <> nil then
    av_frame_free(FFrame);
  if FPacket <> nil then
    av_packet_free(FPacket);
  if FCodecCtx <> nil then
    avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TAudioPlayer.OpenWaveOut(SampleRate, Channels: Integer);
var
  I: Integer;
begin
  if FIsOpen then
    Exit;

  FillChar(FWaveFormat, SizeOf(FWaveFormat), 0);
  FWaveFormat.wFormatTag := WAVE_FORMAT_PCM;
  FWaveFormat.nChannels := Channels;
  FWaveFormat.nSamplesPerSec := SampleRate;
  FWaveFormat.wBitsPerSample := 16;
  FWaveFormat.nBlockAlign := Channels * 2;
  FWaveFormat.nAvgBytesPerSec := SampleRate * Channels * 2;

  if waveOutOpen(@FWaveOut, WAVE_MAPPER, @FWaveFormat, 0, 0, CALLBACK_NULL) = MMSYSERR_NOERROR then
  begin
    FIsOpen := True;

    for I := 0 to High(FHeaders) do
    begin
      SetLength(FBuffers[I], AUDIO_BUFFER_SIZE);
      FillChar(FHeaders[I], SizeOf(TWaveHdr), 0);
      FHeaders[I].lpData := @FBuffers[I][0];
      FHeaders[I].dwBufferLength := AUDIO_BUFFER_SIZE;
    end;
  end;
end;

procedure TAudioPlayer.CloseWaveOut;
begin
  if FIsOpen then
  begin
    waveOutReset(FWaveOut);
    waveOutClose(FWaveOut);
    FIsOpen := False;
  end;
end;

procedure TAudioPlayer.WriteAudioData(PCM: PByte; Size: Integer);
var
  Hdr: PWaveHdr;
begin
  if not FIsOpen then
    Exit;

  if Size > AUDIO_BUFFER_SIZE then
    Size := AUDIO_BUFFER_SIZE;

  Hdr := @FHeaders[FCurrentHeader];

  // Esperar se o buffer ainda está em uso
  if (Hdr.dwFlags and WHDR_DONE) <> 0 then
    waveOutUnprepareHeader(FWaveOut, Hdr, SizeOf(TWaveHdr));

  Move(PCM^, FBuffers[FCurrentHeader][0], Size);
  Hdr.dwBufferLength := Size;

  waveOutPrepareHeader(FWaveOut, Hdr, SizeOf(TWaveHdr));
  waveOutWrite(FWaveOut, Hdr, SizeOf(TWaveHdr));

  FCurrentHeader := (FCurrentHeader + 1) mod Length(FHeaders);
end;

procedure TAudioPlayer.FeedData(Data: PByte; Size: Integer);
var
  Ret: Integer;
  PCMData: PByte;
  PCMSize: Integer;
begin
  FLock.Enter;
  try
    av_packet_set_data(FPacket, Data, Size);

    Ret := avcodec_send_packet(FCodecCtx, FPacket);
    if Ret < 0 then
      Exit;

    while True do
    begin
      av_frame_unref(FFrame);
      Ret := avcodec_receive_frame(FCodecCtx, FFrame);
      if Ret < 0 then
        Break;

      PCMData := TAVFrameHelper.GetData(FFrame, 0);

      if not FIsOpen then
        OpenWaveOut(48000, 2); // Opus padrão

      // nb_samples no offset 112 (FFmpeg 7.x Win64), stereo 16-bit
      PCMSize := PInteger(PByte(FFrame) + 112)^ * 2 * 2;

      WriteAudioData(PCMData, PCMSize);
    end;
  finally
    FLock.Leave;
  end;
end;

end.
