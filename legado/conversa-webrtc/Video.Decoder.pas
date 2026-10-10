unit Video.Decoder;

interface

uses
  System.SysUtils, System.SyncObjs, FFmpeg.Binding;

type
  TOnVideoFrame = reference to procedure(BGRA: PByte; Width, Height, Stride: Integer);

  TVideoDecoder = class
  private
    FCodecCtx: PAVCodecContext;
    FPacket: PAVPacket;
    FFrame: PAVFrame;
    FFrameBGRA: PAVFrame;
    FSwsCtx: PSwsContext;
    FBGRABuffer: TBytes;
    FLastWidth: Integer;
    FLastHeight: Integer;
    FLock: TCriticalSection;
    FOnFrame: TOnVideoFrame;

    procedure InitSwsContext(Width, Height: Integer);
    procedure DecodeAndDeliver(Data: PByte; Size: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure FeedData(Data: PByte; Size: Integer);

    property OnFrame: TOnVideoFrame read FOnFrame write FOnFrame;
  end;

implementation

constructor TVideoDecoder.Create;
var
  Codec: PAVCodec;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastWidth := 0;
  FLastHeight := 0;

  Codec := avcodec_find_decoder(AV_CODEC_ID_H264);
  if Codec = nil then
    raise Exception.Create('H264 decoder not found in FFmpeg');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Failed to allocate codec context');

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Failed to open H264 codec');

  FPacket := av_packet_alloc;
  FFrame := av_frame_alloc;
  FFrameBGRA := av_frame_alloc;
end;

destructor TVideoDecoder.Destroy;
begin
  if FSwsCtx <> nil then
    sws_freeContext(FSwsCtx);
  if FFrame <> nil then
    av_frame_free(FFrame);
  if FFrameBGRA <> nil then
    av_frame_free(FFrameBGRA);
  if FPacket <> nil then
    av_packet_free(FPacket);
  if FCodecCtx <> nil then
    avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TVideoDecoder.InitSwsContext(Width, Height: Integer);
begin
  if FSwsCtx <> nil then
    sws_freeContext(FSwsCtx);

  FSwsCtx := sws_getContext(
    Width, Height, AV_PIX_FMT_YUV420P,
    Width, Height, AV_PIX_FMT_BGRA,
    SWS_BILINEAR,
    nil, nil, nil
  );

  SetLength(FBGRABuffer, Width * Height * 4);
  FLastWidth := Width;
  FLastHeight := Height;
end;

procedure TVideoDecoder.FeedData(Data: PByte; Size: Integer);
begin
  FLock.Enter;
  try
    DecodeAndDeliver(Data, Size);
  finally
    FLock.Leave;
  end;
end;

procedure TVideoDecoder.DecodeAndDeliver(Data: PByte; Size: Integer);
var
  Ret: Integer;
  W, H: Integer;
  SrcData: array[0..3] of PByte;
  SrcStride: array[0..3] of Integer;
  DstData: array[0..3] of PByte;
  DstStride: array[0..3] of Integer;
begin
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

    W := TAVFrameHelper.GetWidth(FFrame);
    H := TAVFrameHelper.GetHeight(FFrame);

    if (W <> FLastWidth) or (H <> FLastHeight) then
      InitSwsContext(W, H);

    if FSwsCtx = nil then
      Continue;

    // Source YUV420P
    SrcData[0] := TAVFrameHelper.GetData(FFrame, 0);
    SrcData[1] := TAVFrameHelper.GetData(FFrame, 1);
    SrcData[2] := TAVFrameHelper.GetData(FFrame, 2);
    SrcData[3] := nil;

    SrcStride[0] := TAVFrameHelper.GetLinesize(FFrame, 0);
    SrcStride[1] := TAVFrameHelper.GetLinesize(FFrame, 1);
    SrcStride[2] := TAVFrameHelper.GetLinesize(FFrame, 2);
    SrcStride[3] := 0;

    // Destination BGRA
    DstData[0] := @FBGRABuffer[0];
    DstData[1] := nil;
    DstData[2] := nil;
    DstData[3] := nil;

    DstStride[0] := W * 4;
    DstStride[1] := 0;
    DstStride[2] := 0;
    DstStride[3] := 0;

    sws_scale(FSwsCtx, @SrcData[0], @SrcStride[0], 0, H, @DstData[0], @DstStride[0]);

    if Assigned(FOnFrame) then
      FOnFrame(@FBGRABuffer[0], W, H, W * 4);
  end;
end;

end.
