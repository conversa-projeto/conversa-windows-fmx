unit Conversa.Audio;

interface

uses
  System.Permissions,
  System.SysUtils,
  IdGlobal;

type
  IAudioCapture = interface;

  TAudioCaptureRequestPermission = TProc<TPermissionStatus, IAudioCapture>;

  TAudioPlayStreamType = (Call, Music);

  IAudioCapture = interface
    ['{91232CA1-8876-4AB3-A163-46E2933AFF6A}']
    function Start(OnCapture: TProc<IAudioCapture>): IAudioCapture;
    function Stop: IAudioCapture;
    function Read: IAudioCapture;
    function ToIdBytes: TIdBytes;
    function PermissionGranted: Boolean;
    procedure RequestPermissions(CallBack: TAudioCaptureRequestPermission);
  end;

  TAudioCapture = class(TInterfacedObject, IAudioCapture)
  public
    class function New(ProcAddLog: TProc<String>): IAudioCapture;
    function Start(OnCapture: TProc<IAudioCapture>): IAudioCapture; virtual; abstract;
    function Stop: IAudioCapture; virtual; abstract;
    function Read: IAudioCapture; virtual; abstract;
    function ToIdBytes: TIdBytes; virtual; abstract;
    function PermissionGranted: Boolean; virtual;
    procedure RequestPermissions(CallBack: TAudioCaptureRequestPermission); virtual; abstract;
  end;

  IAudioPlay = interface
    ['{0B6B47DB-BA5B-40A3-A103-0CBB5C1DA296}']
    function Start: IAudioPlay;
    function Stop: IAudioPlay;
    function StreamType(const Value: TAudioPlayStreamType): IAudioPlay;
    function Write(const ABytes: TIdBytes): IAudioPlay;
  end;

  TAudioPlay = class(TInterfacedObject, IAudioPlay)
  public
    class function New(ProcAddLog: TProc<String>): IAudioPlay;
    function Start: IAudioPlay; virtual; abstract;
    function Stop: IAudioPlay; virtual; abstract;
    function StreamType(const Value: TAudioPlayStreamType): IAudioPlay; virtual; abstract;
    function Write(const ABytes: TIdBytes): IAudioPlay; virtual; abstract;
  end;

implementation

uses
//  FMX.Media
{$IFDEF MSWINDOWS}
  Conversa.Audio.Windows
{$ENDIF MSWINDOWS}
{$IFDEF ANDROID}
  Chamada.Audio.Android
{$ENDIF ANDROID}
;

{ TAudioCapture }

class function TAudioCapture.New(ProcAddLog: TProc<String>): IAudioCapture;
begin
  {$IFDEF ANDROID}
  Result := Chamada.Audio.Android.TAudioCapture.Create(ProcAddLog);
  {$ENDIF ANDROID}
end;

function TAudioCapture.PermissionGranted: Boolean;
begin
  Result := True;
end;

{ TAudioPlay }

class function TAudioPlay.New(ProcAddLog: TProc<String>): IAudioPlay;
begin
  {$IFDEF ANDROID}
  Result := Chamada.Audio.Android.TAudioPlay.Create(ProcAddLog);
  {$ENDIF ANDROID}
end;

end.
