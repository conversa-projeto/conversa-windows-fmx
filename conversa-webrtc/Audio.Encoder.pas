unit Audio.Encoder;

// Encoder Opus via FFmpeg.
// Recebe PCM S16 interleaved estéreo 48kHz (saída do waveIn),
// acumula amostras até ter um frame completo (tipicamente 960 = 20ms),
// converte S16 → FLTP via swresample e entrega pacotes Opus via OnPacket.

interface

uses
  System.SysUtils, System.SyncObjs,
  FFmpeg.Binding;

type
  TOnAudioPacket = reference to procedure(Data: PByte; Size: Integer);

  TAudioEncoder = class
  private const
    SAMPLE_RATE  = 48000;
    CHANNELS     = 2;
    BITRATE      = 128000;
  private
    FCodecCtx:   PAVCodecContext;
    FFrame:      PAVFrame;
    FPacket:     PAVPacket;
    FSwrCtx:     PSwrContext;
    FLock:       TCriticalSection;
    FOnPacket:   TOnAudioPacket;

    FFrameSize:  Integer;   // amostras por frame (lido do encoder após open)
    FSampleFmt:  Integer;   // formato negociado (esperado: FLTP=8)

    // Buffers FLTP planar (canal esquerdo / direito separados)
    FBufL:       TBytes;    // float, FFrameSize amostras
    FBufR:       TBytes;    // float, FFrameSize amostras

    // Buffer de acúmulo S16 interleaved
    FAccum:      TBytes;    // S16 interleaved, capacidade dinâmica
    FAccumSamples: Integer; // amostras acumuladas (não bytes)

    procedure EncodeAccumulated;
  public
    constructor Create;
    destructor Destroy; override;

    // PCM: S16 interleaved estéreo | Samples: número de amostras (pares L+R)
    procedure FeedPCM(PCM: PByte; Samples: Integer);

    property OnPacket: TOnAudioPacket read FOnPacket write FOnPacket;
    property FrameSize: Integer read FFrameSize;
  end;

implementation

{ TAudioEncoder }

constructor TAudioEncoder.Create;
var
  Codec:     PAVCodec;
  FrameSize: Int64;
  SampleFmt: Int64;
begin
  inherited Create;
  FLock         := TCriticalSection.Create;
  FAccumSamples := 0;

  Codec := avcodec_find_encoder(AV_CODEC_ID_OPUS);
  if Codec = nil then
    raise Exception.Create('Opus encoder não encontrado em avcodec-62.dll');

  FCodecCtx := avcodec_alloc_context3(Codec);
  if FCodecCtx = nil then
    raise Exception.Create('Falha ao alocar contexto do encoder Opus');

  // Configuração via av_opt — evita precisar de offsets de struct para campos de áudio
  av_opt_set_int(FCodecCtx, 'ar', SAMPLE_RATE, 0);
  av_opt_set_int(FCodecCtx, 'ac', CHANNELS, 0);        // seta channels + ch_layout stereo
  av_opt_set_int(FCodecCtx, 'b',  BITRATE,   0);
  // Solicitar FLTP; o encoder pode ignorar e usar outro — lemos abaixo
  av_opt_set(FCodecCtx, 'sample_fmt', 'fltp', 0);

  if avcodec_open2(FCodecCtx, Codec, nil) < 0 then
    raise Exception.Create('Falha ao abrir encoder Opus');

  // Lê os parâmetros efetivos após open
  FrameSize := 0;
  SampleFmt := AV_SAMPLE_FMT_FLTP;
  av_opt_get_int(FCodecCtx, 'frame_size', 0, FrameSize);
  av_opt_get_int(FCodecCtx, 'sample_fmt', 0, SampleFmt);

  if FrameSize <= 0 then
    FrameSize := 960; // fallback: 20ms @ 48kHz

  FFrameSize := Integer(FrameSize);
  FSampleFmt := Integer(SampleFmt);

  // Aloca buffers FLTP planar (um float por amostra por canal)
  SetLength(FBufL, FFrameSize * SizeOf(Single));
  SetLength(FBufR, FFrameSize * SizeOf(Single));

  // Configura swresample: S16 interleaved → FLTP planar (mesmo SR, canais)
  FSwrCtx := swr_alloc;
  if FSwrCtx = nil then
    raise Exception.Create('Falha ao alocar contexto swresample');

  av_opt_set_int(FSwrCtx, 'in_sample_rate',   SAMPLE_RATE,        0);
  av_opt_set_int(FSwrCtx, 'out_sample_rate',  SAMPLE_RATE,        0);
  av_opt_set_int(FSwrCtx, 'in_sample_fmt',    AV_SAMPLE_FMT_S16,  0);
  av_opt_set_int(FSwrCtx, 'out_sample_fmt',   AV_SAMPLE_FMT_FLTP, 0);
  av_opt_set_int(FSwrCtx, 'in_channel_layout',  AV_CH_LAYOUT_STEREO, 0);
  av_opt_set_int(FSwrCtx, 'out_channel_layout', AV_CH_LAYOUT_STEREO, 0);

  if swr_init(FSwrCtx) < 0 then
    raise Exception.Create('Falha ao inicializar swresample');

  // Frame de trabalho (reusado a cada encode)
  FFrame := av_frame_alloc;
  if FFrame = nil then
    raise Exception.Create('Falha ao alocar AVFrame de áudio');

  // nb_samples e format são setados em EncodeAccumulated antes de cada envio
  // data[0..1] serão apontados manualmente para FBufL/FBufR (sem av_frame_get_buffer)

  FPacket := av_packet_alloc;
  if FPacket = nil then
    raise Exception.Create('Falha ao alocar AVPacket de áudio');

  // Pré-aloca buffer de acúmulo para 4 frames
  SetLength(FAccum, FFrameSize * CHANNELS * SizeOf(SmallInt) * 4);
end;

destructor TAudioEncoder.Destroy;
begin
  if FSwrCtx  <> nil then swr_free(FSwrCtx);
  if FFrame   <> nil then av_frame_free(FFrame);
  if FPacket  <> nil then av_packet_free(FPacket);
  if FCodecCtx <> nil then avcodec_free_context(FCodecCtx);
  FLock.Free;
  inherited;
end;

procedure TAudioEncoder.FeedPCM(PCM: PByte; Samples: Integer);
var
  NeedBytes: Integer;
  HaveBytes: Integer;
begin
  FLock.Enter;
  try
    NeedBytes := Samples * CHANNELS * SizeOf(SmallInt);
    HaveBytes := FAccumSamples * CHANNELS * SizeOf(SmallInt);

    // Expande buffer de acúmulo se necessário
    if HaveBytes + NeedBytes > Length(FAccum) then
      SetLength(FAccum, HaveBytes + NeedBytes + FFrameSize * CHANNELS * SizeOf(SmallInt));

    Move(PCM^, FAccum[HaveBytes], NeedBytes);
    Inc(FAccumSamples, Samples);

    while FAccumSamples >= FFrameSize do
      EncodeAccumulated;
  finally
    FLock.Leave;
  end;
end;

procedure TAudioEncoder.EncodeAccumulated;
var
  FrameBytes: Integer;
  InPtr:      PByte;
  OutPtrs:    array[0..1] of PByte;
  PtrL, PtrR: PByte;
  Ret:        Integer;
  Callback:   TOnAudioPacket;
  PktData:    PByte;
  PktSize:    Integer;
begin
  // EncodeAccumulated é sempre chamado com FAccumSamples >= FFrameSize
  FrameBytes := FFrameSize * CHANNELS * SizeOf(SmallInt);
  InPtr      := @FAccum[0];
  PtrL       := @FBufL[0];
  PtrR       := @FBufR[0];

  // Converte S16 interleaved → FLTP planar via swresample
  OutPtrs[0] := PtrL;
  OutPtrs[1] := PtrR;
  swr_convert(FSwrCtx, @OutPtrs[0], FFrameSize, @InPtr, FFrameSize);

  // Aponta data do frame para os buffers planar (sem av_frame_get_buffer)
  TAVFrameHelper.SetNbSamples(FFrame, FFrameSize);
  TAVFrameHelper.SetFormat(FFrame, AV_SAMPLE_FMT_FLTP);
  TAVFrameHelper.SetData(FFrame, 0, PtrL);
  TAVFrameHelper.SetData(FFrame, 1, PtrR);
  TAVFrameHelper.SetLinesize(FFrame, 0, FFrameSize * SizeOf(Single));
  TAVFrameHelper.SetLinesize(FFrame, 1, FFrameSize * SizeOf(Single));

  Ret := avcodec_send_frame(FCodecCtx, FFrame);
  if Ret >= 0 then
  begin
    Callback := FOnPacket;
    while True do
    begin
      av_packet_unref(FPacket);
      Ret := avcodec_receive_packet(FCodecCtx, FPacket);
      if Ret < 0 then Break;

      PktData := TAVPacketHelper.GetData(FPacket);
      PktSize := TAVPacketHelper.GetSize(FPacket);

      if Assigned(Callback) and (PktSize > 0) then
        Callback(PktData, PktSize);
    end;
  end;

  // Desloca o buffer de acúmulo (remove o frame que acabou de ser codificado)
  Dec(FAccumSamples, FFrameSize);
  if FAccumSamples > 0 then
    Move(FAccum[FrameBytes], FAccum[0], FAccumSamples * CHANNELS * SizeOf(SmallInt));
end;

end.
