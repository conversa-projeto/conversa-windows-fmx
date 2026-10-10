unit FFmpeg.Binding;

interface

uses
  System.SysUtils;

const
  AVCODEC_DLL    = 'avcodec-62.dll';
  AVUTIL_DLL     = 'avutil-60.dll';
  SWSCALE_DLL    = 'swscale-9.dll';
  SWRESAMPLE_DLL = 'swresample-6.dll';

  // Pixel formats
  AV_PIX_FMT_YUV420P = 0;
  AV_PIX_FMT_BGRA    = 28;
  AV_PIX_FMT_BGR0    = 123; // GDI BitBlt entrega 32bpp BGR + 0-alpha

  // Sample formats
  AV_SAMPLE_FMT_S16  = 1;   // int16 interleaved
  AV_SAMPLE_FMT_FLT  = 3;   // float interleaved
  AV_SAMPLE_FMT_FLTP = 8;   // float planar (exigido pelo encoder Opus)

  // Codec IDs
  AV_CODEC_ID_H264 = 27;
  AV_CODEC_ID_OPUS = 86076;

  // swscale flags
  SWS_BILINEAR = 2;

  // av_opt flags
  AV_OPT_SEARCH_CHILDREN = 1;

  // Channel layouts (legacy mask, compatível com av_opt_set_int "in_channel_layout")
  AV_CH_LAYOUT_STEREO = $3; // front left + front right

type
  PAVCodec        = Pointer;
  PAVCodecContext = Pointer;
  PAVPacket       = Pointer;
  PAVFrame        = Pointer;
  PSwsContext     = Pointer;
  PSwrContext     = Pointer;

  // ── AVFrame helpers ────────────────────────────────────────────────────────
  // Offsets baseados em AVFrame FFmpeg 7.x Win64:
  //   data[8]          @ 0    (8 ptrs × 8 = 64 bytes)
  //   linesize[8]      @ 64   (8 ints × 4 = 32 bytes)
  //   extended_data    @ 96   (ptr, 8 bytes)
  //   width            @ 104  (int)
  //   height           @ 108  (int)
  //   nb_samples       @ 112  (int)
  //   format           @ 116  (int)
  //   sample_aspect_ratio @ 120 (AVRational 8 bytes, se key_frame removido em 7.x)
  //   pts              @ 128  (int64)
  TAVFrameHelper = record
    // Getters
    class function GetData(Frame: PAVFrame; PlaneIndex: Integer): PByte; static;
    class function GetLinesize(Frame: PAVFrame; PlaneIndex: Integer): Integer; static;
    class function GetWidth(Frame: PAVFrame): Integer; static;
    class function GetHeight(Frame: PAVFrame): Integer; static;
    class function GetFormat(Frame: PAVFrame): Integer; static;
    // Setters (para frames de encoding)
    class procedure SetWidth(Frame: PAVFrame; V: Integer); static;
    class procedure SetHeight(Frame: PAVFrame; V: Integer); static;
    class procedure SetNbSamples(Frame: PAVFrame; V: Integer); static;
    class procedure SetFormat(Frame: PAVFrame; V: Integer); static;
    class procedure SetPts(Frame: PAVFrame; V: Int64); static;
    class procedure SetData(Frame: PAVFrame; PlaneIndex: Integer; P: PByte); static;
    class procedure SetLinesize(Frame: PAVFrame; PlaneIndex: Integer; V: Integer); static;
  end;

  // ── AVCodecContext helpers (encoding) ──────────────────────────────────────
  // Offsets baseados em AVCodecContext FFmpeg 7.x Win64:
  //   av_class         @ 0   (ptr 8)
  //   log_level_offset @ 8   (int 4)
  //   codec_type       @ 12  (int 4)
  //   codec            @ 16  (ptr 8)
  //   codec_id         @ 24  (int 4) + tag @ 28 (int 4)
  //   priv_data        @ 32  (ptr 8)
  //   internal         @ 40  (ptr 8)
  //   opaque           @ 48  (ptr 8)
  //   bit_rate         @ 56  (int64 8)
  //   flags            @ 64  (int 4) + flags2 @ 68 (int 4)
  //   extradata        @ 72  (ptr 8) + extradata_size @ 80 (int 4)
  //   time_base        @ 84  (AVRational: num@84, den@88)  ← AVRational alinhado a 4, sem padding
  //   pkt_timebase     @ 92  (AVRational 8)
  //   framerate        @ 100 (AVRational 8)
  //   delay            @ 108 (int 4)
  //   width            @ 112 (int 4)
  //   height           @ 116 (int 4)
  //   coded_width      @ 120 (int 4) + coded_height @ 124 (int 4)
  //   gop_size         @ 128 (int 4)
  //   pix_fmt          @ 132 (int 4)
  //   max_b_frames     @ 136 (int 4)
  // Campos de áudio (sample_rate, ch_layout, sample_fmt): usar av_opt_set_int
  TAVCodecContextHelper = record
    class procedure SetBitRate(Ctx: PAVCodecContext; V: Int64); static;
    class procedure SetTimeBase(Ctx: PAVCodecContext; Num, Den: Integer); static;
    class procedure SetWidth(Ctx: PAVCodecContext; V: Integer); static;
    class procedure SetHeight(Ctx: PAVCodecContext; V: Integer); static;
    class procedure SetGopSize(Ctx: PAVCodecContext; V: Integer); static;
    class procedure SetPixFmt(Ctx: PAVCodecContext; V: Integer); static;
    class procedure SetMaxBFrames(Ctx: PAVCodecContext; V: Integer); static;
  end;

  // ── AVPacket helpers ───────────────────────────────────────────────────────
  // Offsets usados também por av_packet_set_data:
  //   data @ 24 (ptr 8)
  //   size @ 32 (int 4)
  TAVPacketHelper = record
    class function GetData(Pkt: PAVPacket): PByte; static;
    class function GetSize(Pkt: PAVPacket): Integer; static;
  end;

// === avcodec — decoder ===
function avcodec_find_decoder(id: Cardinal): PAVCodec; cdecl;
  external AVCODEC_DLL;

function avcodec_alloc_context3(codec: PAVCodec): PAVCodecContext; cdecl;
  external AVCODEC_DLL;

function avcodec_open2(ctx: PAVCodecContext; codec: PAVCodec; options: Pointer): Integer; cdecl;
  external AVCODEC_DLL;

function avcodec_send_packet(ctx: PAVCodecContext; pkt: PAVPacket): Integer; cdecl;
  external AVCODEC_DLL;

function avcodec_receive_frame(ctx: PAVCodecContext; frame: PAVFrame): Integer; cdecl;
  external AVCODEC_DLL;

procedure avcodec_free_context(var ctx: PAVCodecContext); cdecl;
  external AVCODEC_DLL;

function av_packet_alloc: PAVPacket; cdecl;
  external AVCODEC_DLL;

procedure av_packet_free(var pkt: PAVPacket); cdecl;
  external AVCODEC_DLL;

procedure av_packet_unref(pkt: PAVPacket); cdecl;
  external AVCODEC_DLL;

procedure av_packet_set_data(pkt: PAVPacket; data: PByte; size: Integer);

// === avcodec — encoder ===
function avcodec_find_encoder(id: Cardinal): PAVCodec; cdecl;
  external AVCODEC_DLL;

function avcodec_send_frame(ctx: PAVCodecContext; frame: PAVFrame): Integer; cdecl;
  external AVCODEC_DLL;

function avcodec_receive_packet(ctx: PAVCodecContext; pkt: PAVPacket): Integer; cdecl;
  external AVCODEC_DLL;

// === avutil ===
function av_frame_alloc: PAVFrame; cdecl;
  external AVUTIL_DLL;

procedure av_frame_free(var frame: PAVFrame); cdecl;
  external AVUTIL_DLL;

procedure av_frame_unref(frame: PAVFrame); cdecl;
  external AVUTIL_DLL;

function av_frame_get_buffer(frame: PAVFrame; align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_frame_make_writable(frame: PAVFrame): Integer; cdecl;
  external AVUTIL_DLL;

function av_image_get_buffer_size(pixFmt, width, height, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_image_fill_arrays(
  dstData: Pointer; dstLinesize: Pointer;
  src: PByte; pixFmt, width, height, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_malloc(size: NativeUInt): Pointer; cdecl;
  external AVUTIL_DLL;

procedure av_free(ptr: Pointer); cdecl;
  external AVUTIL_DLL;

procedure av_freep(ptr: Pointer); cdecl;
  external AVUTIL_DLL;

// === avutil — av_opt ===
function av_opt_set(obj: Pointer; name: PAnsiChar; val: PAnsiChar;
  search_flags: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_opt_set_int(obj: Pointer; name: PAnsiChar; val: Int64;
  search_flags: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_opt_get_int(obj: Pointer; name: PAnsiChar; search_flags: Integer;
  out val: Int64): Integer; cdecl;
  external AVUTIL_DLL;

// === avutil — samples ===
function av_samples_get_buffer_size(linesize: PInteger; nb_channels, nb_samples,
  sample_fmt, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

function av_samples_alloc(audio_data: PPointer; linesize: PInteger;
  nb_channels, nb_samples, sample_fmt, align: Integer): Integer; cdecl;
  external AVUTIL_DLL;

// === swscale ===
function sws_getContext(
  srcW, srcH, srcFormat,
  dstW, dstH, dstFormat: Integer;
  flags: Integer;
  srcFilter, dstFilter, param: Pointer): PSwsContext; cdecl;
  external SWSCALE_DLL;

function sws_scale(
  ctx: PSwsContext;
  srcSlice: Pointer; srcStride: Pointer;
  srcSliceY, srcSliceH: Integer;
  dst: Pointer; dstStride: Pointer): Integer; cdecl;
  external SWSCALE_DLL;

procedure sws_freeContext(ctx: PSwsContext); cdecl;
  external SWSCALE_DLL;

// === swresample ===
function swr_alloc: PSwrContext; cdecl;
  external SWRESAMPLE_DLL;

function swr_init(ctx: PSwrContext): Integer; cdecl;
  external SWRESAMPLE_DLL;

procedure swr_free(var ctx: PSwrContext); cdecl;
  external SWRESAMPLE_DLL;

function swr_convert(ctx: PSwrContext;
  out_data: PPointer; out_count: Integer;
  in_data: PPointer;  in_count: Integer): Integer; cdecl;
  external SWRESAMPLE_DLL;

implementation

procedure av_packet_set_data(pkt: PAVPacket; data: PByte; size: Integer);
var
  P: PByte;
begin
  // AVPacket layout (FFmpeg 7.x, Win64):
  // offset 24 = data (PByte)
  // offset 32 = size (int32)
  P := PByte(pkt);
  PPointer(@P[24])^ := data;
  PInteger(@P[32])^ := size;
end;

{ TAVFrameHelper }

class function TAVFrameHelper.GetData(Frame: PAVFrame; PlaneIndex: Integer): PByte;
var
  P: PByte;
begin
  P := PByte(Frame);
  Result := PPointer(@P[PlaneIndex * SizeOf(Pointer)])^;
end;

class function TAVFrameHelper.GetLinesize(Frame: PAVFrame; PlaneIndex: Integer): Integer;
var
  P: PByte;
begin
  P := PByte(Frame);
  Result := PInteger(@P[64 + PlaneIndex * SizeOf(Integer)])^;
end;

class function TAVFrameHelper.GetWidth(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  P := PByte(Frame);
  Result := PInteger(@P[104])^;
end;

class function TAVFrameHelper.GetHeight(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  P := PByte(Frame);
  Result := PInteger(@P[108])^;
end;

class function TAVFrameHelper.GetFormat(Frame: PAVFrame): Integer;
var
  P: PByte;
begin
  P := PByte(Frame);
  Result := PInteger(@P[116])^;
end;

class procedure TAVFrameHelper.SetWidth(Frame: PAVFrame; V: Integer);
var P: PByte;
begin P := PByte(Frame); PInteger(@P[104])^ := V; end;

class procedure TAVFrameHelper.SetHeight(Frame: PAVFrame; V: Integer);
var P: PByte;
begin P := PByte(Frame); PInteger(@P[108])^ := V; end;

class procedure TAVFrameHelper.SetNbSamples(Frame: PAVFrame; V: Integer);
var P: PByte;
begin P := PByte(Frame); PInteger(@P[112])^ := V; end;

class procedure TAVFrameHelper.SetFormat(Frame: PAVFrame; V: Integer);
var P: PByte;
begin P := PByte(Frame); PInteger(@P[116])^ := V; end;

class procedure TAVFrameHelper.SetPts(Frame: PAVFrame; V: Int64);
var P: PByte;
begin
  // pts @ 128 (FFmpeg 7.x: após SAR @ 120-127, key_frame removido)
  P := PByte(Frame);
  PInt64(@P[128])^ := V;
end;

class procedure TAVFrameHelper.SetData(Frame: PAVFrame; PlaneIndex: Integer; P: PByte);
var Base: PByte;
begin
  Base := PByte(Frame);
  PPointer(@Base[PlaneIndex * SizeOf(Pointer)])^ := P;
end;

class procedure TAVFrameHelper.SetLinesize(Frame: PAVFrame; PlaneIndex: Integer; V: Integer);
var P: PByte;
begin
  P := PByte(Frame);
  PInteger(@P[64 + PlaneIndex * SizeOf(Integer)])^ := V;
end;

{ TAVCodecContextHelper }

class procedure TAVCodecContextHelper.SetBitRate(Ctx: PAVCodecContext; V: Int64);
var P: PByte;
begin P := PByte(Ctx); PInt64(@P[56])^ := V; end;

class procedure TAVCodecContextHelper.SetTimeBase(Ctx: PAVCodecContext; Num, Den: Integer);
var P: PByte;
begin
  P := PByte(Ctx);
  PInteger(@P[84])^ := Num;
  PInteger(@P[88])^ := Den;
end;

class procedure TAVCodecContextHelper.SetWidth(Ctx: PAVCodecContext; V: Integer);
var P: PByte;
begin P := PByte(Ctx); PInteger(@P[112])^ := V; end;

class procedure TAVCodecContextHelper.SetHeight(Ctx: PAVCodecContext; V: Integer);
var P: PByte;
begin P := PByte(Ctx); PInteger(@P[116])^ := V; end;

class procedure TAVCodecContextHelper.SetGopSize(Ctx: PAVCodecContext; V: Integer);
var P: PByte;
begin P := PByte(Ctx); PInteger(@P[128])^ := V; end;

class procedure TAVCodecContextHelper.SetPixFmt(Ctx: PAVCodecContext; V: Integer);
var P: PByte;
begin P := PByte(Ctx); PInteger(@P[132])^ := V; end;

class procedure TAVCodecContextHelper.SetMaxBFrames(Ctx: PAVCodecContext; V: Integer);
var P: PByte;
begin P := PByte(Ctx); PInteger(@P[136])^ := V; end;

{ TAVPacketHelper }

class function TAVPacketHelper.GetData(Pkt: PAVPacket): PByte;
var P: PByte;
begin P := PByte(Pkt); Result := PPointer(@P[24])^; end;

class function TAVPacketHelper.GetSize(Pkt: PAVPacket): Integer;
var P: PByte;
begin P := PByte(Pkt); Result := PInteger(@P[32])^; end;

end.
