unit Conversa.Audio.Windows;

interface

uses
  System.Classes,
  System.Permissions,
  System.SysUtils,
  System.Threading,
  System.Types,
  IdGlobal,
{$IFDEF MSWINDOWS}
//  FMX.Media,
//  FMX.Media.Win,
  FMX.Consts,
  Winapi.Windows,
  Winapi.ActiveX,
  Winapi.DirectShow9,
{$ENDIF MSWINDOWS}
  Conversa.Audio;

type
  TAudioState = (Stopped, Playing);

  TAudioPlayStreamTypeH = record Helper for TAudioPlayStreamType
    function Get: Integer;
  end;

  TAudioCapture = class(Conversa.Audio.TAudioCapture)
  private
    FAddLog: TProc<String>;

    FMoniker: IMoniker;
    FBaseFilter: IBaseFilter;
    FGraphBuilder: IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMediaControl: IMediaControl;

//    FBytes: TJavaArray<Byte>;
    FStatus: TAudioState;
    FThread: ITask;
    FOnCapture: TProc<IAudioCapture>;
    FCallBackRequestPermissions: TAudioCaptureRequestPermission;
  public
    constructor Create(ProcAddLog: TProc<String>);
    destructor Destroy; override;
    function Start(OnCapture: TProc<IAudioCapture>): IAudioCapture; override;
    function Stop: IAudioCapture; override;
    function Read: IAudioCapture; override;
    function ToIdBytes: TIdBytes; override;
    function PermissionGranted: Boolean; override;
    procedure RequestPermissions(CallBack: TAudioCaptureRequestPermission); override;
  end;

//  TAudioPlay = class(Conversa.Audio.TAudioPlay)
//  private
//    FAddLog: TProc<String>;
//    FPlay: JAudioTrack;
//    FStatus: TAudioState;
//    FStreamType: TAudioPlayStreamType;
//    function InternalWrite(const ABytes: TJavaArray<Byte>): IAudioPlay;
//    function ChangeStatus(Status: TAudioState): IAudioPlay;
//    procedure CreateAudioPlay;
//  public
//    constructor Create(ProcAddLog: TProc<String>);
//    destructor Destroy; override;
//    function Start: IAudioPlay; override;
//    function Stop: IAudioPlay; override;
//    function StreamType(const Value: TAudioPlayStreamType): IAudioPlay; override;
//    function Write(const ABytes: TIdBytes): IAudioPlay; override;
//  end;

implementation

const
//  sampleRate: Integer = 11025;
  sampleRate: Integer = 44100;
//  sampleRate: Integer = 48000;

{ TAudioCapture }

constructor TAudioCapture.Create(ProcAddLog: TProc<String>);
var
//  channelConfig: Integer;
//  audioFormat: Integer;
//  minBufSize: Integer;
//  Moniker: IMoniker;
  DevEnum: ICreateDevEnum;
  Enum: IEnumMoniker;
//  Default: Boolean;
begin
  FAddLog := ProcAddLog;
  FStatus := TAudioState.Stopped;

  CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER, IID_ICreateDevEnum, DevEnum);

  if not Assigned(DevEnum) then
    raise Exception.Create('DevEnum');

  // audio devices
  DevEnum.CreateClassEnumerator(CLSID_AudioInputDeviceCategory, Enum, 0);

  if not Assigned(DevEnum) then
    raise Exception.Create('DevEnum');

  if Enum.Next(1, FMoniker, nil) <> S_OK then
    raise Exception.Create('Moniker');

//  channelConfig := TJAudioFormat.JavaClass.CHANNEL_IN_MONO;
//  audioFormat := TJAudioFormat.JavaClass.ENCODING_PCM_16BIT;
//  minBufSize := TJAudioRecord.JavaClass.getMinBufferSize(sampleRate, channelConfig, audioFormat);
//  FAddLog('TAudioCapture.Create.minBufSize : '+ minBufSize.ToString);
//
//  FBytes := TJavaArray<Byte>.Create(minBufSize);
//  FRecorder := TJAudioRecord.JavaClass.init(TJMediaRecorder_AudioSource.JavaClass.MIC, sampleRate, channelConfig, audioFormat, minBufSize);
end;

destructor TAudioCapture.Destroy;
begin
  Stop;
  FBytes.DisposeOf;
  inherited;
end;

function TAudioCapture.Start(OnCapture: TProc<IAudioCapture>): IAudioCapture;
var
  HR: HResult;
begin
  Result := Self;

  if FStatus = TAudioState.Playing then
    Exit;

  if FBaseFilter <> nil then
    Exit;

  HR := Self.FMoniker.BindToObject(nil, nil, IID_IBaseFilter, FBaseFilter);

  if Failed(HR) then
    raise Exception.Create('Cannot create the DirectShow capture filter');

  FOnCapture := OnCapture;

  // Create GraphBuilder
  HR := CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
  if Succeeded(HR) then
  begin
    HR := CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraphBuilder);
    if Succeeded(HR) then
    begin
      FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder);

      // Get IMediaControl
      FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
      HR := FGraphBuilder.AddFilter(FBaseFilter, 'Capture Filter');
      if Succeeded(HR) then
      begin
        HR := FCaptureGraphBuilder.SetOutputFileName(MEDIASUBTYPE_AVI, PChar(FFileName), ppf, sink);
        if Succeeded(HR) then
        begin
          HR := FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_CAPTURE, @MEDIATYPE_Audio, FBaseFilter, nil, ppf);
          if Succeeded(HR) then
          begin
            if FMediaControl <> nil then
            begin
              HR := FMediaControl.Run;
              FailedToRun := Failed(HR);
              if not FailedToRun then
                Exit; // Success
            end;
          end;
        end;
      end;
    end;
  end;
  FCaptureGraphBuilder := nil;
  FGraphBuilder := nil;
  FMediaControl := nil;

  if FailedToRun then
    raise ECaptureDeviceException.CreateRes(@SCannotRunDirectShowFilterGraph);


  (FRecorder as JAudioRecord).startRecording;
  FStatus := TAudioState.Playing;

  FThread := TTask.Run(
    procedure
    begin
      while FStatus = TAudioState.Playing do
        FOnCapture(Self);
    end
  );
end;

function TAudioCapture.Stop: IAudioCapture;
begin
  Result := Self;
  if FStatus = TAudioState.Stopped then
    Exit;

  (FRecorder as JAudioRecord).stop;
  FStatus := TAudioState.Stopped;
  FThread.Wait(500);
end;

function TAudioCapture.Read: IAudioCapture;
begin
  Result := Self;
//  FAddLog('TAudioCapture.Read - Start');
  (FRecorder as JAudioRecord).read(FBytes, 0, FBytes.Length{, TJAudioRecord.JavaClass.READ_NON_BLOCKING});
//  FAddLog('TAudioCapture.Read - End');
end;

function TAudioCapture.ToIdBytes: TIdBytes;
var
  Len: Integer;
begin
  Read;
  Len := FBytes.Length;
  SetLength(Result, Len);
  if Len > 0 then
    System.Move(FBytes.Data^, Result[0], Len);
end;

function TAudioCapture.PermissionGranted: Boolean;
begin
  Result := PermissionsService.IsPermissionGranted(JStringToString(TJManifest_permission.JavaClass.RECORD_AUDIO));
end;

procedure TAudioCapture.RequestPermissions(CallBack: TAudioCaptureRequestPermission);
begin
  FCallBackRequestPermissions := CallBack;
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.RECORD_AUDIO)],
    procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
    var
      Status: TPermissionStatus;
    begin
      Status := TPermissionStatus.Denied;
      if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
        Status := AGrantResults[0];

      FCallBackRequestPermissions(Status, Self);
    end
  );
end;

//{ TAudioPlay }
//
//constructor TAudioPlay.Create(ProcAddLog: TProc<String>);
//begin
//  FAddLog := ProcAddLog;
//  FStreamType := TAudioPlayStreamType.Call;
//  FStatus := TAudioState.Stopped;
//  CreateAudioPlay;
//end;
//
//destructor TAudioPlay.Destroy;
//begin
//  Stop;
//  inherited;
//end;
//
//procedure TAudioPlay.CreateAudioPlay;
//var
//  trackmin: Integer;
//begin
//  trackmin := TJAudioTrack.JavaClass.getMinBufferSize(
//    sampleRate,
//    TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
//    TJAudioFormat.JavaClass.ENCODING_PCM_16BIT
//  );
//
//  ChangeStatus(TAudioState.Stopped);
//
//  if Assigned(FPlay) then
//    FPlay.release;
//
//  FPlay := TJAudioTrack.JavaClass.init(
//    FStreamType.Get,
//    sampleRate,
//    TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
//    TJAudioFormat.JavaClass.ENCODING_PCM_16BIT,
//    trackmin,
//    TJAudioTrack.JavaClass.MODE_STREAM
//  );
//
//  ChangeStatus(TAudioState.Playing);
//end;
//
//function TAudioPlay.ChangeStatus(Status: TAudioState): IAudioPlay;
//begin
//  Result := Self;
//  if FStatus = Status then
//    Exit;
//
//  if not Assigned(FPlay) then
//    Exit;
//
//  case Status of
//    TAudioState.Playing : (FPlay as JAudioTrack).play;
//    TAudioState.Stopped : (FPlay as JAudioTrack).stop;
//  end;
//  FStatus := Status;
//end;
//
//function TAudioPlay.Start: IAudioPlay;
//begin
//  Result := ChangeStatus(TAudioState.Playing);
//end;
//
//function TAudioPlay.Stop: IAudioPlay;
//begin
//  Result := ChangeStatus(TAudioState.Stopped);
//end;
//
//function TAudioPlay.StreamType(const Value: TAudioPlayStreamType): IAudioPlay;
//begin
//  Result := Self;
//  if FStreamType = Value then
//    Exit;
//
//  FStreamType := Value;
//  CreateAudioPlay;
//end;
//
//function TAudioPlay.InternalWrite(const ABytes: TJavaArray<Byte>): IAudioPlay;
//begin
//  Result := Start;
//  if Assigned(FPlay) then
//    (FPlay AS JAudioTrack).write(ABytes, 0, ABytes.Length{, Androidapi.Jni.Media.TJAudioTrack.JavaClass.WRITE_NON_BLOCKING});
//end;
//
//function TAudioPlay.Write(const ABytes: TIdBytes): IAudioPlay;
//var
//  ja: TJavaArray<Byte>;
//begin
//  Result := Self;
//  ja := TJavaArray<Byte>.Create(Length(ABytes));
//  try
//    if Length(ABytes) > 0 then
//      System.Move(ABytes[0], ja.Data^, Length(ABytes));
//  finally
//    Result := InternalWrite(ja);
//  end;
//end;

{ TAudioPlayStreamTypeH }

function TAudioPlayStreamTypeH.Get: Integer;
begin
  if Self = TAudioPlayStreamType.Call then
    Result := TJAudioManager.JavaClass.STREAM_VOICE_CALL
  else
    Result := TJAudioManager.JavaClass.STREAM_MUSIC;
end;

end.
