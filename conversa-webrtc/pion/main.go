package main

/*
#include <stdint.h>
#include <stdlib.h>

// handle identifica qual conexão gerou o frame/estado
typedef void (*VideoFrameCallback)(int32_t handle, uint8_t* data, int32_t size, int64_t timestamp_ms);
typedef void (*AudioFrameCallback)(int32_t handle, uint8_t* data, int32_t size, int64_t timestamp_ms);
typedef void (*StateCallback)(int32_t handle, int32_t state);

static void callVideoCallback(VideoFrameCallback cb, int32_t handle, uint8_t* data, int32_t size, int64_t ts) {
    if (cb) cb(handle, data, size, ts);
}
static void callAudioCallback(AudioFrameCallback cb, int32_t handle, uint8_t* data, int32_t size, int64_t ts) {
    if (cb) cb(handle, data, size, ts);
}
static void callStateCallback(StateCallback cb, int32_t handle, int32_t state) {
    if (cb) cb(handle, state);
}
*/
import "C"

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"
	"unsafe"

	"github.com/pion/webrtc/v4"
	"github.com/pion/webrtc/v4/pkg/media"
)

// === Log ===

var (
	logFile    *os.File
	logMu      sync.Mutex
	logEnabled bool = false // desabilitado por padrão
)

func initLog() {
	logMu.Lock()
	defer logMu.Unlock()
	if logFile != nil {
		return
	}
	exePath, err := os.Executable()
	var logPath string
	if err != nil {
		logPath = "C:\\pion_whep.log"
	} else {
		logPath = filepath.Join(filepath.Dir(exePath), "pion_whep.log")
	}
	f, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		f, _ = os.OpenFile("C:\\pion_whep.log", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	}
	logFile = f
	if logFile != nil {
		fmt.Fprintf(logFile, "[%s] === pion_whep iniciado | log: %s ===\n",
			time.Now().Format("2006-01-02 15:04:05.000"), logPath)
		logFile.Sync()
	}
}

func logf(format string, args ...interface{}) {
	if !logEnabled {
		return
	}
	logMu.Lock()
	defer logMu.Unlock()
	if logFile == nil {
		return
	}
	fmt.Fprintf(logFile, "[%s] %s\n",
		time.Now().Format("2006-01-02 15:04:05.000"),
		fmt.Sprintf(format, args...))
	logFile.Sync()
}

// === Estado global ===

var (
	mu            sync.Mutex
	connections   = make(map[int32]*webrtc.PeerConnection) // WHEP
	whipConns     = make(map[int32]*whipConn)              // WHIP
	nextHandle    int32 = 1
	videoCallback C.VideoFrameCallback
	audioCallback C.AudioFrameCallback
	stateCallback C.StateCallback
)

// whipConn agrupa PeerConnection + tracks de envio
type whipConn struct {
	pc         *webrtc.PeerConnection
	videoTrack *webrtc.TrackLocalStaticSample // nil se sendVideo=0
	audioTrack *webrtc.TrackLocalStaticSample // nil se sendAudio=0
}

func notifyState(handle, state int32) {
	states := map[int32]string{0: "disconnected", 1: "connecting", 2: "connected", 3: "failed"}
	logf("[handle=%d] notifyState: %d (%s)", handle, state, states[state])
	C.callStateCallback(stateCallback, C.int32_t(handle), C.int32_t(state))
}

// === Exports comuns ===

// WhepSetLogEnabled habilita (1) ou desabilita (0) o log em arquivo.
//
//export WhepSetLogEnabled
func WhepSetLogEnabled(enabled C.int32_t) {
	logEnabled = enabled != 0
	if logEnabled {
		initLog()
		logf("Log habilitado")
	}
}

// WhepInit registra os callbacks para recepção (WHEP).
//
//export WhepInit
func WhepInit(videoCb C.VideoFrameCallback, audioCb C.AudioFrameCallback, stateCb C.StateCallback) C.int32_t {
	mu.Lock()
	defer mu.Unlock()
	videoCallback = videoCb
	audioCallback = audioCb
	stateCallback = stateCb
	logf("WhepInit OK")
	return 0
}

// WhipInit registra o StateCallback para envio (WHIP).
// Alternativa ao WhepInit quando só se usa WHIP (sem recepção).
//
//export WhipInit
func WhipInit(stateCb C.StateCallback) C.int32_t {
	mu.Lock()
	defer mu.Unlock()
	stateCallback = stateCb
	logf("WhipInit OK")
	return 0
}

// === WHEP — Recepção ===

// WhepConnect retorna o handle (>0) em caso de sucesso, ou valor negativo em erro.
// authType: "Basic" ou "" para sem autenticação.
//
//export WhepConnect
func WhepConnect(whepURL *C.char, authType *C.char, username *C.char, password *C.char) C.int32_t {
	mu.Lock()
	url    := C.GoString(whepURL)
	auth   := C.GoString(authType)
	user   := C.GoString(username)
	pass   := C.GoString(password)
	handle := nextHandle
	nextHandle++
	mu.Unlock()

	logf("[handle=%d] WhepConnect: url=%s authType=%s user=%s", handle, url, auth, user)
	notifyState(handle, 1)

	config := webrtc.Configuration{ICEServers: []webrtc.ICEServer{}}

	m := &webrtc.MediaEngine{}
	if err := m.RegisterDefaultCodecs(); err != nil {
		logf("[handle=%d] RegisterDefaultCodecs erro: %v", handle, err)
		notifyState(handle, 3)
		return -1
	}

	api := webrtc.NewAPI(webrtc.WithMediaEngine(m))
	pc, err := api.NewPeerConnection(config)
	if err != nil {
		logf("[handle=%d] NewPeerConnection erro: %v", handle, err)
		notifyState(handle, 3)
		return -1
	}

	mu.Lock()
	connections[handle] = pc
	mu.Unlock()

	pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
		logf("[handle=%d] OnTrack: kind=%s codec=%s", handle, track.Kind(), track.Codec().MimeType)
		if track.Kind() == webrtc.RTPCodecTypeVideo {
			go readVideoTrack(handle, track)
		} else if track.Kind() == webrtc.RTPCodecTypeAudio {
			go readAudioTrack(handle, track)
		}
	})

	pc.OnConnectionStateChange(func(state webrtc.PeerConnectionState) {
		logf("[handle=%d] OnConnectionStateChange: %s", handle, state)
		switch state {
		case webrtc.PeerConnectionStateConnected:
			notifyState(handle, 2)
		case webrtc.PeerConnectionStateFailed:
			notifyState(handle, 3)
		case webrtc.PeerConnectionStateDisconnected:
			notifyState(handle, 0)
		case webrtc.PeerConnectionStateClosed:
			notifyState(handle, 0)
		}
	})

	_, err = pc.AddTransceiverFromKind(webrtc.RTPCodecTypeVideo, webrtc.RTPTransceiverInit{
		Direction: webrtc.RTPTransceiverDirectionRecvonly,
	})
	if err != nil {
		logf("[handle=%d] AddTransceiverVideo erro: %v", handle, err)
		notifyState(handle, 3)
		return -2
	}

	_, err = pc.AddTransceiverFromKind(webrtc.RTPCodecTypeAudio, webrtc.RTPTransceiverInit{
		Direction: webrtc.RTPTransceiverDirectionRecvonly,
	})
	if err != nil {
		logf("[handle=%d] AddTransceiverAudio erro: %v", handle, err)
		notifyState(handle, 3)
		return -3
	}

	offer, err := pc.CreateOffer(nil)
	if err != nil {
		logf("[handle=%d] CreateOffer erro: %v", handle, err)
		notifyState(handle, 3)
		return -4
	}

	if err = pc.SetLocalDescription(offer); err != nil {
		logf("[handle=%d] SetLocalDescription erro: %v", handle, err)
		notifyState(handle, 3)
		return -5
	}

	logf("[handle=%d] Aguardando ICE gathering...", handle)
	<-webrtc.GatheringCompletePromise(pc)
	logf("[handle=%d] ICE gathering completo", handle)

	req, err := http.NewRequest("POST", url, bytes.NewReader([]byte(pc.LocalDescription().SDP)))
	if err != nil {
		logf("[handle=%d] NewRequest erro: %v", handle, err)
		notifyState(handle, 3)
		return -6
	}
	req.Header.Set("Content-Type", "application/sdp")

	switch auth {
	case "Basic":
		if user != "" {
			req.SetBasicAuth(user, pass)
			logf("[handle=%d] usando Basic Auth: user=%s", handle, user)
		}
	default:
		if auth != "" {
			logf("[handle=%d] authType desconhecido: %s — ignorando", handle, auth)
		}
	}

	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		logf("[handle=%d] HTTP POST erro: %v", handle, err)
		notifyState(handle, 3)
		return -6
	}
	defer resp.Body.Close()

	logf("[handle=%d] HTTP POST resposta: status=%d", handle, resp.StatusCode)

	if resp.StatusCode != 201 && resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		logf("[handle=%d] HTTP POST falhou: body=%s", handle, string(body))
		notifyState(handle, 3)
		return -7
	}

	answerBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		logf("[handle=%d] ReadAll answer erro: %v", handle, err)
		notifyState(handle, 3)
		return -8
	}

	logf("[handle=%d] SDP answer recebido (%d bytes)", handle, len(answerBytes))

	if err = pc.SetRemoteDescription(webrtc.SessionDescription{
		Type: webrtc.SDPTypeAnswer,
		SDP:  string(answerBytes),
	}); err != nil {
		logf("[handle=%d] SetRemoteDescription erro: %v", handle, err)
		notifyState(handle, 3)
		return -9
	}

	logf("[handle=%d] WhepConnect OK", handle)
	return C.int32_t(handle)
}

//export WhepDisconnect
func WhepDisconnect(handle C.int32_t) C.int32_t {
	h := int32(handle)
	logf("[handle=%d] WhepDisconnect chamado", h)

	mu.Lock()
	pc, ok := connections[h]
	if ok {
		delete(connections, h)
	}
	mu.Unlock()

	if pc != nil {
		logf("[handle=%d] Fechando PeerConnection", h)
		pc.Close()
		logf("[handle=%d] PeerConnection fechada", h)
	}

	notifyState(h, 0)
	return 0
}

// === WHIP — Envio ===

// WhipConnect abre uma conexão WHIP para envio de vídeo e/ou áudio.
// sendVideo/sendAudio: 1 para habilitar, 0 para desabilitar.
// Bloqueia até ICE gathering + handshake HTTP completarem.
//
//export WhipConnect
func WhipConnect(whipURL *C.char, authType *C.char, username *C.char, password *C.char,
	sendVideo C.int32_t, sendAudio C.int32_t) C.int32_t {

	mu.Lock()
	url    := C.GoString(whipURL)
	auth   := C.GoString(authType)
	user   := C.GoString(username)
	pass   := C.GoString(password)
	hasVideo := sendVideo != 0
	hasAudio := sendAudio != 0
	handle := nextHandle
	nextHandle++
	mu.Unlock()

	logf("[handle=%d] WhipConnect: url=%s video=%v audio=%v", handle, url, hasVideo, hasAudio)
	notifyState(handle, 1)

	config := webrtc.Configuration{ICEServers: []webrtc.ICEServer{}}

	m := &webrtc.MediaEngine{}
	if err := m.RegisterDefaultCodecs(); err != nil {
		logf("[handle=%d] RegisterDefaultCodecs erro: %v", handle, err)
		notifyState(handle, 3)
		return -1
	}

	api := webrtc.NewAPI(webrtc.WithMediaEngine(m))
	pc, err := api.NewPeerConnection(config)
	if err != nil {
		logf("[handle=%d] NewPeerConnection erro: %v", handle, err)
		notifyState(handle, 3)
		return -1
	}

	conn := &whipConn{pc: pc}

	if hasVideo {
		conn.videoTrack, err = webrtc.NewTrackLocalStaticSample(
			webrtc.RTPCodecCapability{MimeType: webrtc.MimeTypeH264},
			"video", "pion-whip",
		)
		if err != nil {
			logf("[handle=%d] NewTrackLocalStaticSample video erro: %v", handle, err)
			pc.Close()
			notifyState(handle, 3)
			return -2
		}
		if _, err = pc.AddTrack(conn.videoTrack); err != nil {
			logf("[handle=%d] AddTrack video erro: %v", handle, err)
			pc.Close()
			notifyState(handle, 3)
			return -4
		}
	}

	if hasAudio {
		conn.audioTrack, err = webrtc.NewTrackLocalStaticSample(
			webrtc.RTPCodecCapability{MimeType: webrtc.MimeTypeOpus},
			"audio", "pion-whip",
		)
		if err != nil {
			logf("[handle=%d] NewTrackLocalStaticSample audio erro: %v", handle, err)
			pc.Close()
			notifyState(handle, 3)
			return -3
		}
		if _, err = pc.AddTrack(conn.audioTrack); err != nil {
			logf("[handle=%d] AddTrack audio erro: %v", handle, err)
			pc.Close()
			notifyState(handle, 3)
			return -4
		}
	}

	pc.OnConnectionStateChange(func(state webrtc.PeerConnectionState) {
		logf("[handle=%d] WHIP OnConnectionStateChange: %s", handle, state)
		switch state {
		case webrtc.PeerConnectionStateConnected:
			notifyState(handle, 2)
		case webrtc.PeerConnectionStateFailed:
			notifyState(handle, 3)
		case webrtc.PeerConnectionStateDisconnected:
			notifyState(handle, 0)
		case webrtc.PeerConnectionStateClosed:
			notifyState(handle, 0)
		}
	})

	offer, err := pc.CreateOffer(nil)
	if err != nil {
		logf("[handle=%d] CreateOffer erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -5
	}

	if err = pc.SetLocalDescription(offer); err != nil {
		logf("[handle=%d] SetLocalDescription erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -6
	}

	logf("[handle=%d] WHIP aguardando ICE gathering...", handle)
	<-webrtc.GatheringCompletePromise(pc)
	logf("[handle=%d] WHIP ICE gathering completo", handle)

	req, err := http.NewRequest("POST", url, bytes.NewReader([]byte(pc.LocalDescription().SDP)))
	if err != nil {
		logf("[handle=%d] NewRequest erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -7
	}
	req.Header.Set("Content-Type", "application/sdp")

	if auth == "Basic" && user != "" {
		req.SetBasicAuth(user, pass)
		logf("[handle=%d] WHIP usando Basic Auth: user=%s", handle, user)
	}

	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		logf("[handle=%d] HTTP POST erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -7
	}
	defer resp.Body.Close()

	logf("[handle=%d] WHIP HTTP POST resposta: status=%d", handle, resp.StatusCode)

	if resp.StatusCode != 201 && resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		logf("[handle=%d] WHIP HTTP POST falhou: body=%s", handle, string(body))
		pc.Close()
		notifyState(handle, 3)
		return -8
	}

	answerBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		logf("[handle=%d] ReadAll answer erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -9
	}

	logf("[handle=%d] WHIP SDP answer recebido (%d bytes)", handle, len(answerBytes))

	if err = pc.SetRemoteDescription(webrtc.SessionDescription{
		Type: webrtc.SDPTypeAnswer,
		SDP:  string(answerBytes),
	}); err != nil {
		logf("[handle=%d] SetRemoteDescription erro: %v", handle, err)
		pc.Close()
		notifyState(handle, 3)
		return -10
	}

	mu.Lock()
	whipConns[handle] = conn
	mu.Unlock()

	logf("[handle=%d] WhipConnect OK", handle)
	return C.int32_t(handle)
}

// WhipSendVideo envia um frame H264 Annex-B para o servidor.
// durationMs: duração do frame em ms; 0 usa 33ms (≈30fps).
//
//export WhipSendVideo
func WhipSendVideo(handle C.int32_t, data *C.uint8_t, size C.int32_t, durationMs C.int32_t) C.int32_t {
	h := int32(handle)

	mu.Lock()
	conn, ok := whipConns[h]
	mu.Unlock()

	if !ok || conn.videoTrack == nil {
		return -1
	}

	dur := time.Duration(durationMs) * time.Millisecond
	if dur <= 0 {
		dur = 33 * time.Millisecond
	}

	payload := C.GoBytes(unsafe.Pointer(data), C.int(size))

	if err := conn.videoTrack.WriteSample(media.Sample{
		Data:     payload,
		Duration: dur,
	}); err != nil {
		logf("[handle=%d] WhipSendVideo erro: %v", h, err)
		return -2
	}
	return 0
}

// WhipSendAudio envia um payload Opus bruto para o servidor.
// durationMs: duração em ms; 0 usa 20ms (padrão Opus).
//
//export WhipSendAudio
func WhipSendAudio(handle C.int32_t, data *C.uint8_t, size C.int32_t, durationMs C.int32_t) C.int32_t {
	h := int32(handle)

	mu.Lock()
	conn, ok := whipConns[h]
	mu.Unlock()

	if !ok || conn.audioTrack == nil {
		return -1
	}

	dur := time.Duration(durationMs) * time.Millisecond
	if dur <= 0 {
		dur = 20 * time.Millisecond
	}

	payload := C.GoBytes(unsafe.Pointer(data), C.int(size))

	if err := conn.audioTrack.WriteSample(media.Sample{
		Data:     payload,
		Duration: dur,
	}); err != nil {
		logf("[handle=%d] WhipSendAudio erro: %v", h, err)
		return -2
	}
	return 0
}

// WhipDisconnect encerra a conexão WHIP identificada pelo handle.
//
//export WhipDisconnect
func WhipDisconnect(handle C.int32_t) C.int32_t {
	h := int32(handle)
	logf("[handle=%d] WhipDisconnect chamado", h)

	mu.Lock()
	conn, ok := whipConns[h]
	if ok {
		delete(whipConns, h)
	}
	mu.Unlock()

	if conn != nil {
		conn.pc.Close()
		logf("[handle=%d] WHIP PeerConnection fechada", h)
	}

	notifyState(h, 0)
	return 0
}

// === H264 Depacketizer (WHEP) ===

type h264Depacketizer struct {
	fuBuffer []byte
}

var startCode = []byte{0, 0, 0, 1}

func (d *h264Depacketizer) process(payload []byte) []byte {
	if len(payload) == 0 {
		return nil
	}
	naluType := payload[0] & 0x1F

	switch {
	case naluType >= 1 && naluType <= 23:
		out := make([]byte, 4+len(payload))
		copy(out, startCode)
		copy(out[4:], payload)
		return out

	case naluType == 24: // STAP-A
		var out []byte
		data := payload[1:]
		for len(data) > 2 {
			size := int(data[0])<<8 | int(data[1])
			data = data[2:]
			if size <= 0 || size > len(data) {
				break
			}
			out = append(out, startCode...)
			out = append(out, data[:size]...)
			data = data[size:]
		}
		return out

	case naluType == 28: // FU-A
		if len(payload) < 2 {
			return nil
		}
		fuHeader := payload[1]
		startBit := fuHeader&0x80 != 0
		endBit   := fuHeader&0x40 != 0
		naluHeaderByte := (payload[0] & 0xE0) | (fuHeader & 0x1F)

		if startBit {
			d.fuBuffer = []byte{naluHeaderByte}
		}
		if len(d.fuBuffer) == 0 {
			return nil
		}
		d.fuBuffer = append(d.fuBuffer, payload[2:]...)
		if endBit {
			out := make([]byte, 4+len(d.fuBuffer))
			copy(out, startCode)
			copy(out[4:], d.fuBuffer)
			d.fuBuffer = nil
			return out
		}
		return nil
	}
	return nil
}

func readVideoTrack(handle int32, track *webrtc.TrackRemote) {
	logf("[handle=%d] readVideoTrack iniciado", handle)
	depkt := &h264Depacketizer{}
	frameCount := 0

	for {
		pkt, _, err := track.ReadRTP()
		if err != nil {
			logf("[handle=%d] readVideoTrack encerrado: %v", handle, err)
			return
		}

		frameData := depkt.process(pkt.Payload)
		if frameData == nil {
			continue
		}

		frameCount++
		if frameCount <= 5 || frameCount%300 == 0 {
			logf("[handle=%d] video frame #%d: %d bytes", handle, frameCount, len(frameData))
		}

		cData := C.CBytes(frameData)
		C.callVideoCallback(videoCallback, C.int32_t(handle),
			(*C.uint8_t)(cData), C.int32_t(len(frameData)), C.int64_t(0))
		C.free(cData)
	}
}

func readAudioTrack(handle int32, track *webrtc.TrackRemote) {
	logf("[handle=%d] readAudioTrack iniciado: codec=%s", handle, track.Codec().MimeType)
	buf := make([]byte, 4096)
	frameCount := 0

	for {
		n, _, err := track.Read(buf)
		if err != nil {
			logf("[handle=%d] readAudioTrack encerrado: %v", handle, err)
			return
		}
		if n == 0 {
			continue
		}

		frameCount++
		if frameCount <= 5 || frameCount%300 == 0 {
			logf("[handle=%d] audio frame #%d: %d bytes", handle, frameCount, n)
		}

		data := make([]byte, n)
		copy(data, buf[:n])

		cData := C.CBytes(data)
		C.callAudioCallback(audioCallback, C.int32_t(handle),
			(*C.uint8_t)(cData), C.int32_t(n), C.int64_t(0))
		C.free(cData)
	}
}

func main() {}
