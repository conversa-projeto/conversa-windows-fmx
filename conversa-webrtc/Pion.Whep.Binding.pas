unit Pion.Whep.Binding;

interface

uses
  System.SysUtils;

const
  PION_DLL = 'pion_whep.dll';

type
  // handle identifica qual conexão gerou o frame/estado
  TVideoFrameCallback = procedure(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
  TAudioFrameCallback = procedure(Handle: Int32; Data: PByte; Size: Int32; TimestampMs: Int64); cdecl;
  TStateCallback      = procedure(Handle: Int32; State: Int32); cdecl;

  TWhepConnectionState = (
    wsDisconnected = 0,
    wsConnecting   = 1,
    wsConnected    = 2,
    wsFailed       = 3
  );

// Habilita (1) ou desabilita (0) o log em arquivo
// Por padrão o log começa desabilitado
procedure WhepSetLogEnabled(Enabled: Int32); cdecl; external PION_DLL;

// Inicializa callbacks (chamar uma vez)
function WhepInit(
  VideoCb: TVideoFrameCallback;
  AudioCb: TAudioFrameCallback;
  StateCb: TStateCallback
): Int32; cdecl; external PION_DLL;

// Conecta e retorna handle (>0) ou negativo em erro
// AuthType: 'Basic' (passar '' para sem autenticação)
// Username/Password: credenciais
function WhepConnect(WhepURL: PAnsiChar; AuthType: PAnsiChar;
  Username: PAnsiChar; Password: PAnsiChar): Int32; cdecl; external PION_DLL;

// Desconecta a conexão WHEP identificada pelo handle
function WhepDisconnect(Handle: Int32): Int32; cdecl; external PION_DLL;

// ── WHIP (envio) ─────────────────────────────────────────────────────────────

// Registra StateCallback para WHIP.
// Usar quando só se usa WHIP (sem recepção WHEP).
// Se WhepInit já foi chamado, não é necessário chamar WhipInit.
function WhipInit(StateCb: TStateCallback): Int32; cdecl; external PION_DLL;

// Conecta ao endpoint WHIP e retorna handle (>0) ou negativo em erro.
// SendVideo/SendAudio: 1 para habilitar, 0 para desabilitar.
// BLOQUEIA até ICE gathering + HTTP completarem — chamar em thread separada.
function WhipConnect(WhipURL: PAnsiChar; AuthType: PAnsiChar;
  Username: PAnsiChar; Password: PAnsiChar;
  SendVideo: Int32; SendAudio: Int32): Int32; cdecl; external PION_DLL;

// Envia frame H264 Annex-B (com start codes 00 00 00 01).
// DurationMs: duração em ms (ex: 33 para 30fps); 0 usa 33ms padrão.
// Retorna 0 em sucesso, negativo em erro.
function WhipSendVideo(Handle: Int32; Data: PByte; Size: Int32;
  DurationMs: Int32): Int32; cdecl; external PION_DLL;

// Envia payload Opus bruto.
// DurationMs: duração em ms (ex: 20); 0 usa 20ms padrão.
// Retorna 0 em sucesso, negativo em erro.
function WhipSendAudio(Handle: Int32; Data: PByte; Size: Int32;
  DurationMs: Int32): Int32; cdecl; external PION_DLL;

// Encerra a conexão WHIP identificada pelo handle.
function WhipDisconnect(Handle: Int32): Int32; cdecl; external PION_DLL;

implementation

end.
