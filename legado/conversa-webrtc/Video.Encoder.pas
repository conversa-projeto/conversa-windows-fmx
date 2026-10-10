unit Video.Encoder;

// Encoder H264 via FFmpeg (libx264).
// Recebe frames BGR0 (32bpp, saída do GDI BitBlt), converte para YUV420P
// via swscale e entrega pacotes H264 Annex-B via OnPacket.
//
// Requer avcodec-62.dll compilado com --enable-libx264.

interface

uses
  System.SysUtils, System.SyncObjs,
  FFmpeg.Binding;

type
  // Data: bytes H264 Annex-B | Size: tamanho em bytes | DurationMs: duração do frame
  TOnVideoPacket = reference to procedure(Data: PByte; Size, DurationMs: Integer);

  TVideoEncoder = class
  private
    FCodecCtx:  PAVCodecContext;
    FFrame:     PAVFrame;
    FPacket:    PAVPacket;
    FSwsCtx:    PSwsContext;
    FLock:      TCriticalSection;
    FOnPacket:  TOnVideoPacket;

    FWidth:     Integer;
    FLastW:     Integer;
    FLastH:     Integer;
    FHeight:    Integer;
    FFps:       Integer;
    FDurationMs:Integer;
    FPts:       Int64;

    procedure RebuildSwsContext(SrcW, SrcH: Integer);
  public
    constructor Create(Width, Height, Fps: Integer; BitRateKbps: Integer = 2000);
    destructor Destroy; override;

    // BGRA/BGR0: ponteiro para W*H*4 bytes, top-down
    procedure FeedFrame(BGR0: PByte; W, H: Integer);

    property OnPacket: TOnVideoPacket read FOnPacket write FOnPacket;
  end;

implementation

{ TVideoEncoder }

constructor TVideoEncoder.Create(Width, Height, Fps: Integer; BitRateKbps: Integer = 2000);
var
  Codec: PAVCodec;
begin
  inherited Create;
  FLock       := TCriticalSection.Create;
  FWidth      := Width;
  FHeight     := Height;
  FFps        := Fps;
  FDurationMs := 1000 div Fps;
  FPts        := 0;
  FLastW      := 0;
  FLastH      := 0;

  Codec := avcodec_find_encoder(AV_CODEC_ID_H264);
  if Codec = nil then
    raise Exception.Create('H264 encoder não encontrado. Verifique se avcodec-62.dll inclui libx264.');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Falha ao alocar contexto do encoder H264');

  // Parâmetros via struct (TAVCodecContextHelper — offsets FFmpeg 7.x Win64)
  TAVCodecContextHelper.SetWidth(FCodecCtx, Width);
  TAVCodecContextHelper.SetHeight(FCodecCtx, Height);
  TAVCodecContextHelper.SetGopSize(FCodecCtx, Fps);      // 1 keyframe por segundo
  TAVCodecContextHelper.SetMaxBFrames(FCodecCtx, 0);     // sem B-frames (baixa latência)
  TAVCodecContextHelper.SetPixFmt(FCodecCtx, AV_PIX_FMT_YUV420P);
  TAVCodecContextHelper.SetTimeBase(FCodecCtx, 1, Fps);  // time_base = 1/fps

  // Parâmetros via av_opt (portable + libx264-specific)
  av_opt_set_int(FCodecCtx, 'b', BitRateKbps * 1000, 0);
  av_opt_set(FCodecCtx, 'preset', 'ultrafast', AV_OPT_SEARCH_CHILDREN);
  av_opt_set(FCodecCtx, 'tune',   'zerolatency', AV_OPT_SEARCH_CHILDREN);

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Falha ao abrir encoder H264. Verifique suporte a libx264.');

  // Frame de trabalho YUV420P
  FFrame := av_frame_alloc;
  if FFrame = nil then
    raise Exception.Create('Falha ao alocar AVFrame de vídeo');

  TAVFrameHelper.SetWidth(FFrame, Width);
  TAVFrameHelper.SetHeight(FFrame, Height);
  TAVFrameHelper.SetFormat(FFrame, AV_PIX_FMT_YUV420P);
  if av_frame_get_buffer(FFrame, 0) < 0 then
    raise Exception.Create('Falha ao alocar buffer do AVFrame de vídeo');

  FPacket := av_packet_alloc;
  if FPacket = nil then
    raise Exception.Create('Falha ao alocar AVPacket de vídeo');
end;

destructor TVideoEncoder.Destroy;
begin
  if FSwsCtx <> nil then sws_freeContext(FSwsCtx);
  if FFrame   <> nil then av_frame_free(FFrame);
  if FPacket  <> nil then av_packet_free(FPacket);
  if FCodecCtx <> nil then avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TVideoEncoder.RebuildSwsContext(SrcW, SrcH: Integer);
begin
  if FSwsCtx <> nil then
  begin
    sws_freeContext(FSwsCtx);
    FSwsCtx := nil;
  end;

  // BGR0 (32bpp GDI) → YUV420P
  FSwsCtx := sws_getContext(
    SrcW, SrcH, AV_PIX_FMT_BGR0,
    FWidth, FHeight, AV_PIX_FMT_YUV420P,
    SWS_BILINEAR, nil, nil, nil);

  FLastW := SrcW;
  FLastH := SrcH;
end;

procedure TVideoEncoder.FeedFrame(BGR0: PByte; W, H: Integer);
var
  SrcData:   array[0..3] of PByte;
  SrcStride: array[0..3] of Integer;
  DstData:   array[0..3] of PByte;
  DstStride: array[0..3] of Integer;
  Ret:       Integer;
  Callback:  TOnVideoPacket;
  PktData:   PByte;
  PktSize:   Integer;
begin
  FLock.Enter;
  try
    if (W <> FLastW) or (H <> FLastH) then
      RebuildSwsContext(W, H);

    if FSwsCtx = nil then Exit;

    if av_frame_make_writable(FFrame) < 0 then Exit;

    // Configura ponteiros de origem (BGR0 single-plane)
    SrcData[0] := BGR0;
    SrcData[1] := nil;
    SrcData[2] := nil;
    SrcData[3] := nil;
    SrcStride[0] := W * 4;  // 4 bytes por pixel
    SrcStride[1] := 0;
    SrcStride[2] := 0;
    SrcStride[3] := 0;

    // Configura ponteiros de destino (YUV420P triplanar)
    DstData[0]   := TAVFrameHelper.GetData(FFrame, 0);
    DstData[1]   := TAVFrameHelper.GetData(FFrame, 1);
    DstData[2]   := TAVFrameHelper.GetData(FFrame, 2);
    DstData[3]   := nil;
    DstStride[0] := TAVFrameHelper.GetLinesize(FFrame, 0);
    DstStride[1] := TAVFrameHelper.GetLinesize(FFrame, 1);
    DstStride[2] := TAVFrameHelper.GetLinesize(FFrame, 2);
    DstStride[3] := 0;

    sws_scale(FSwsCtx, @SrcData[0], @SrcStride[0], 0, H, @DstData[0], @DstStride[0]);

    TAVFrameHelper.SetPts(FFrame, FPts);
    Inc(FPts);

    Ret := avcodec_send_frame(FCodecCtx, FFrame);
    if Ret < 0 then Exit;

    Callback := FOnPacket;

    while True do
    begin
      av_packet_unref(FPacket);
      Ret := avcodec_receive_packet(FCodecCtx, FPacket);
      if Ret < 0 then Break;

      PktData := TAVPacketHelper.GetData(FPacket);
      PktSize := TAVPacketHelper.GetSize(FPacket);

      if Assigned(Callback) and (PktSize > 0) then
        Callback(PktData, PktSize, FDurationMs);
    end;
  finally
    FLock.Leave;
  end;
end;

end.
