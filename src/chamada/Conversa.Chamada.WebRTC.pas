(*----------------------------------------------------------------------------------------------------------------------
Conversa.Chamada.WebRTC

Integracao de chamadas Conversa com WebRTC via pion_whep.dll, em paridade com:
  - Android: com.conversa.conversa.data.webrtc.WebRTCManager (Kotlin + google-webrtc)
  - Web: conversa-web/src/stores/call.ts (WebRTC nativo do browser)

Arquitetura em mesh, compativel com MediaMTX:
  - txHandle: WhipConnect para call-{chamadaId}-u-{meuUid}/whip (publico minha midia)
  - rxHandles: WhepConnect para cada peer call-{chamadaId}-u-{peerId}/whep (assino mídia dele)

Encoders em tempo real (H264 + Opus) via FFmpeg — ver arquivos adaptados do exemplo em
  conversa-windows-fmx/conversa-webrtc/.

Arquivos que DEVEM ser copiados do exemplo para o projeto antes de usar:
  - Pion.Whep.Binding.pas   (cdecl bindings do pion_whep.dll)
  - FFmpeg.Binding.pas      (bindings FFmpeg)
  - Video.Decoder.pas       (H264 -> BGRA)
  - Video.Encoder.pas       (BGRA -> H264 Annex-B)
  - Audio.Encoder.pas       (PCM -> Opus)
  - Audio.Player.pas        (Opus -> PCM + WASAPI)
  - Screen.Capture.pas      (OU Camera.Capture.pas no futuro)
  - Mic.Capture.pas         (waveIn)
  - bin/*.dll               (pion_whep.dll + FFmpeg dlls)

Eventos WS 51-56 continuam sendo tratados pela camada de Conversa.Eventos.pas; esta
unit se limita a orquestrar WHIP/WHEP em resposta aos eventos.

Autor: Migracao automatica 2026-04-21
----------------------------------------------------------------------------------------------------------------------*)
unit Conversa.Chamada.WebRTC;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  FMX.Graphics, FMX.Objects,
  Conversa.Log,
  // Dependencias copiadas do exemplo conversa-webrtc/
  Pion.Whep.Binding,
  Video.Decoder, Video.Encoder,
  Audio.Encoder, Audio.Player,
  Screen.Capture, Mic.Capture;

type
  TWebRTCPeer = class
    UsuarioId: Integer;
    Handle: Int32;          // handle retornado por WhepConnect
    Decoder: TVideoDecoder;
    AudioPlayer: TAudioPlayer;
    ImgRenderer: TImage;    // TImage FMX onde o video eh renderizado
    destructor Destroy; override;
  end;

  TOnPeerAdicionadoProc = reference to procedure(Peer: TWebRTCPeer);
  TOnPeerRemovidoProc = reference to procedure(UsuarioId: Integer);
  TOnErroProc = reference to procedure(const Msg: String);

  TConversaWebRTC = class
  private
    class var FInstance: TConversaWebRTC;
    var
    FLock:          TCriticalSection;
    FMediaMtxBase:  String;       // ex: 'http://192.168.2.4:8889'
    FAuthUser:      AnsiString;
    FAuthPass:      AnsiString;
    FChamadaId:     Integer;
    FMeuUsuarioId:  Integer;
    // TX (meu stream local publicado via WHIP)
    FTxHandle:      Int32;
    FVideoEncoder:  TVideoEncoder;
    FAudioEncoder:  TAudioEncoder;
    FScreenCapture: TScreenCapture;
    FMicCapture:    TMicCapture;
    // RX (peers remotos)
    FPeers: TObjectDictionary<Integer, TWebRTCPeer>;

    FOnPeerAdicionado: TOnPeerAdicionadoProc;
    FOnPeerRemovido:   TOnPeerRemovidoProc;
    FOnErro:           TOnErroProc;

    procedure InicializarCallbacks;
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TConversaWebRTC;

    property MediaMtxBase: String read FMediaMtxBase write FMediaMtxBase;
    property OnPeerAdicionado: TOnPeerAdicionadoProc read FOnPeerAdicionado write FOnPeerAdicionado;
    property OnPeerRemovido: TOnPeerRemovidoProc read FOnPeerRemovido write FOnPeerRemovido;
    property OnErro: TOnErroProc read FOnErro write FOnErro;

    /// Publica minha midia na sala via WHIP (POST call-{chamadaId}-u-{myId}/whip)
    /// EnviarVideo/EnviarAudio: 1=sim, 0=nao. Retorna True em caso de sucesso.
    function PublicarLocalNaSala(ChamadaId, MeuUsuarioId: Integer;
      EnviarVideo, EnviarAudio: Boolean): Boolean;

    /// Assina stream de um peer via WHEP. Renderizar video no ImgTarget.
    function AssinarDePeer(PeerId: Integer; ImgTarget: TImage): Boolean;

    /// Desconecta um peer especifico (chama WhepDisconnect e libera recursos)
    procedure DesconectarPeer(PeerId: Integer);

    /// Encerra a chamada inteira (fecha WHIP + todos os WHEP)
    procedure Desligar;

    /// Captura de tela iniciada/parada
    procedure AlternarCompartilhamentoTela(Ativo: Boolean);

    /// Mute/unmute microfone local (local-only, nao renegocia WHIP)
    procedure AlternarMicrofone(Mutado: Boolean);
  end;

/// Callbacks C dispatcher (registrados em WhepInit)
procedure GlobalVideoCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure GlobalAudioCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
procedure GlobalStateCallback(Handle: Int32; State: Int32); cdecl;

implementation

{ TWebRTCPeer }

destructor TWebRTCPeer.Destroy;
begin
  if Handle > 0 then
    WhepDisconnect(Handle);
  FreeAndNil(Decoder);
  FreeAndNil(AudioPlayer);
  // ImgRenderer pertence a UI — nao liberar aqui
  inherited;
end;

{ TConversaWebRTC }

constructor TConversaWebRTC.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FPeers := TObjectDictionary<Integer, TWebRTCPeer>.Create([doOwnsValues]);
  FTxHandle := 0;
  FChamadaId := 0;
  FMeuUsuarioId := 0;
  InicializarCallbacks;
end;

destructor TConversaWebRTC.Destroy;
begin
  Desligar;
  FreeAndNil(FPeers);
  FreeAndNil(FLock);
  inherited;
end;

class function TConversaWebRTC.Instance: TConversaWebRTC;
begin
  if FInstance = nil then
    FInstance := TConversaWebRTC.Create;
  Result := FInstance;
end;

procedure TConversaWebRTC.InicializarCallbacks;
begin
  // Registra callbacks globais. Basta uma vez por processo.
  WhepInit(@GlobalVideoCallback, @GlobalAudioCallback, @GlobalStateCallback);
end;

function TConversaWebRTC.PublicarLocalNaSala(ChamadaId, MeuUsuarioId: Integer;
  EnviarVideo, EnviarAudio: Boolean): Boolean;
var
  URL: String;
  Ret: Int32;
  SendVid, SendAud: Int32;
begin
  Result := False;
  FChamadaId := ChamadaId;
  FMeuUsuarioId := MeuUsuarioId;

  URL := Format('%s/call-%d-u-%d/whip', [FMediaMtxBase, ChamadaId, MeuUsuarioId]);
  SendVid := Ord(EnviarVideo);
  SendAud := Ord(EnviarAudio);

  // WhipConnect BLOQUEIA — chamar em thread (ou aceitar bloqueio breve)
  Ret := WhipConnect(
    PAnsiChar(AnsiString(URL)),
    PAnsiChar(AnsiString('')), // sem auth Basic por padrao
    PAnsiChar(FAuthUser),
    PAnsiChar(FAuthPass),
    SendVid,
    SendAud);

  if Ret <= 0 then
  begin
    if Assigned(FOnErro) then
      FOnErro(Format('WhipConnect falhou (%d) em %s', [Ret, URL]));
    Exit;
  end;

  FTxHandle := Ret;

  // Cria encoders + capturers e conecta pipelines
  if EnviarVideo then
  begin
    FVideoEncoder := TVideoEncoder.Create(1280, 720, 30, 2000);
    FScreenCapture := TScreenCapture.Create;

    FVideoEncoder.OnPacket := procedure(Data: PByte; Size, DurationMs: Integer)
    begin
      if FTxHandle > 0 then
        WhipSendVideo(FTxHandle, Data, Size, DurationMs);
    end;

    FScreenCapture.OnFrame := procedure(Data: PByte; W, H: Integer)
    begin
      if Assigned(FVideoEncoder) then
        FVideoEncoder.FeedFrame(Data, W, H);
    end;

    FScreenCapture.Start(30);
  end;

  if EnviarAudio then
  begin
    FAudioEncoder := TAudioEncoder.Create;
    FMicCapture := TMicCapture.Create(48000, 2);

    FAudioEncoder.OnPacket := procedure(Data: PByte; Size: Integer)
    begin
      if FTxHandle > 0 then
        WhipSendAudio(FTxHandle, Data, Size, 20);
    end;

    FMicCapture.OnData := procedure(PCM: PByte; Samples: Integer)
    begin
      if Assigned(FAudioEncoder) then
        FAudioEncoder.FeedPCM(PCM, Samples);
    end;

    FMicCapture.Start;
  end;

  Result := True;
end;

function TConversaWebRTC.AssinarDePeer(PeerId: Integer; ImgTarget: TImage): Boolean;
var
  Peer: TWebRTCPeer;
  URL:  String;
  Ret:  Int32;
begin
  Result := False;
  if FChamadaId = 0 then Exit;

  FLock.Enter;
  try
    if FPeers.ContainsKey(PeerId) then Exit(True); // ja assinado
  finally
    FLock.Leave;
  end;

  URL := Format('%s/call-%d-u-%d/whep', [FMediaMtxBase, FChamadaId, PeerId]);

  Ret := WhepConnect(
    PAnsiChar(AnsiString(URL)),
    PAnsiChar(AnsiString('')),
    PAnsiChar(FAuthUser),
    PAnsiChar(FAuthPass));

  if Ret <= 0 then
  begin
    if Assigned(FOnErro) then
      FOnErro(Format('WhepConnect falhou (%d) em %s', [Ret, URL]));
    Exit;
  end;

  Peer := TWebRTCPeer.Create;
  Peer.UsuarioId   := PeerId;
  Peer.Handle      := Ret;
  Peer.Decoder     := TVideoDecoder.Create;
  Peer.AudioPlayer := TAudioPlayer.Create;
  Peer.ImgRenderer := ImgTarget;

  // Conecta OnFrame do decoder. ATENCAO: capturar apenas PeerId (value type)
  // e refazer lookup no dict sob lock no Queue — caso contrario use-after-free
  // se DesconectarPeer liberar o objeto entre o FeedData e o Queue.
  Peer.Decoder.OnFrame := procedure(BGRA: PByte; W, H, Stride: Integer)
  var
    Copy: TBytes;
    CapturedPeerId: Integer;
  begin
    CapturedPeerId := PeerId;
    SetLength(Copy, H * Stride);
    Move(BGRA^, Copy[0], H * Stride);
    TThread.Queue(nil, procedure
    var
      PeerAtual: TWebRTCPeer;
      Bmp: TBitmap;
      BmpData: TBitmapData;
      Y: Integer;
    begin
      if TConversaWebRTC.FInstance = nil then Exit;
      TConversaWebRTC.FInstance.FLock.Enter;
      try
        if not TConversaWebRTC.FInstance.FPeers.TryGetValue(CapturedPeerId, PeerAtual) then Exit;
        if not Assigned(PeerAtual.ImgRenderer) then Exit;
        Bmp := PeerAtual.ImgRenderer.Bitmap;
        if (Bmp.Width <> W) or (Bmp.Height <> H) then
          Bmp.SetSize(W, H);
        if Bmp.Map(TMapAccess.Write, BmpData) then
        try
          for Y := 0 to H - 1 do
            Move(Copy[Y * Stride],
                 (PByte(NativeUInt(BmpData.Data) + NativeUInt(Y * BmpData.Pitch)))^,
                 W * 4);
        finally
          Bmp.Unmap(BmpData);
        end;
        PeerAtual.ImgRenderer.Repaint;
      finally
        TConversaWebRTC.FInstance.FLock.Leave;
      end;
    end);
  end;

  FLock.Enter;
  try
    FPeers.AddOrSetValue(PeerId, Peer);
  finally
    FLock.Leave;
  end;

  if Assigned(FOnPeerAdicionado) then FOnPeerAdicionado(Peer);
  Result := True;
end;

procedure TConversaWebRTC.DesconectarPeer(PeerId: Integer);
begin
  FLock.Enter;
  try
    if FPeers.ContainsKey(PeerId) then
    begin
      FPeers.Remove(PeerId); // doOwnsValues dispara Destroy -> WhepDisconnect
      if Assigned(FOnPeerRemovido) then FOnPeerRemovido(PeerId);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TConversaWebRTC.Desligar;
var
  Key: Integer;
begin
  // Para capturas primeiro
  if Assigned(FScreenCapture) then
  begin
    FScreenCapture.OnFrame := nil;
    FScreenCapture.Stop;
    FreeAndNil(FScreenCapture);
  end;
  if Assigned(FMicCapture) then
  begin
    FMicCapture.OnData := nil;
    FMicCapture.Stop;
    FreeAndNil(FMicCapture);
  end;
  FreeAndNil(FVideoEncoder);
  FreeAndNil(FAudioEncoder);

  // Fecha WHIP
  if FTxHandle > 0 then
  begin
    WhipDisconnect(FTxHandle);
    FTxHandle := 0;
  end;

  // Fecha todos os WHEP
  FLock.Enter;
  try
    for Key in FPeers.Keys.ToArray do
      FPeers.Remove(Key);
  finally
    FLock.Leave;
  end;

  FChamadaId := 0;
end;

procedure TConversaWebRTC.AlternarCompartilhamentoTela(Ativo: Boolean);
begin
  // Placeholder: trocar Screen.Capture por outro modo (janela/area)
  // ou pausar o capturer atual.
  if Assigned(FScreenCapture) then
  begin
    if Ativo then FScreenCapture.Start(30)
    else FScreenCapture.Stop;
  end;
end;

procedure TConversaWebRTC.AlternarMicrofone(Mutado: Boolean);
begin
  // Nao remove o track no WHIP (evita renegociacao), apenas para/pausa captura local.
  if Assigned(FMicCapture) then
  begin
    if Mutado then FMicCapture.Stop
    else FMicCapture.Start;
  end;
end;

{ Callbacks globais — invocados de goroutines Go, NAO main thread }

procedure GlobalVideoCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
var
  Peer: TWebRTCPeer;
  Pair: TPair<Integer, TWebRTCPeer>;
begin
  if TConversaWebRTC.FInstance = nil then Exit;
  TConversaWebRTC.FInstance.FLock.Enter;
  try
    Peer := nil;
    for Pair in TConversaWebRTC.FInstance.FPeers do
      if Pair.Value.Handle = Handle then begin Peer := Pair.Value; Break; end;
  finally
    TConversaWebRTC.FInstance.FLock.Leave;
  end;
  if (Peer <> nil) and Assigned(Peer.Decoder) then
    Peer.Decoder.FeedData(Data, Size);
end;

procedure GlobalAudioCallback(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
var
  Peer: TWebRTCPeer;
  Pair: TPair<Integer, TWebRTCPeer>;
begin
  if TConversaWebRTC.FInstance = nil then Exit;
  TConversaWebRTC.FInstance.FLock.Enter;
  try
    Peer := nil;
    for Pair in TConversaWebRTC.FInstance.FPeers do
      if Pair.Value.Handle = Handle then begin Peer := Pair.Value; Break; end;
  finally
    TConversaWebRTC.FInstance.FLock.Leave;
  end;
  if (Peer <> nil) and Assigned(Peer.AudioPlayer) then
    Peer.AudioPlayer.FeedData(Data, Size);
end;

procedure GlobalStateCallback(Handle: Int32; State: Int32); cdecl;
const
  Estados: array[0..3] of String = ('Desconectado', 'Conectando', 'Conectado', 'Falhou');
var
  Inst: TConversaWebRTC;
begin
  if (State >= Low(Estados)) and (State <= High(Estados)) then
    AddLog(Format('WebRTC handle=%d state=%s', [Handle, Estados[State]]))
  else
    AddLog(Format('WebRTC handle=%d state=%d', [Handle, State]));

  if State = 3 then
  begin
    Inst := TConversaWebRTC.FInstance;
    if (Inst <> nil) and Assigned(Inst.FOnErro) then
      Inst.FOnErro(Format('WebRTC handle=%d falhou', [Handle]));
  end;
end;

initialization

finalization
  FreeAndNil(TConversaWebRTC.FInstance);

end.
