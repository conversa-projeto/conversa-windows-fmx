unit Conversa.DeviceInfo.Utils;

interface

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.WinSock;
  {$ENDIF}
  {$IFDEF ANDROID}
  Androidapi.JNI.JavaTypes, Androidapi.Helpers, Androidapi.JNI.Os,
  Androidapi.JNIBridge;
  {$ENDIF}
  {$IFDEF IOS}
  Macapi.Helpers, iOSapi.Foundation, iOSapi.UIKit;
  {$ENDIF}
  {$IFDEF MACOS}
  Macapi.CoreFoundation, Macapi.Helpers;
  {$ENDIF}

type
  TDeviceInfo = record
    DeviceName: String;
    Model: String;
    OSVersion: String;
    Platform: String;
  end;

function GetDeviceInfo: TDeviceInfo;

implementation

function GetDeviceInfo: TDeviceInfo;
begin
  Result.DeviceName := '';
  Result.OSVersion := '';
  Result.Platform := '';

  {$IFDEF MSWINDOWS}
  Result.Platform := 'Windows';

  // Obt�m o nome do computador
  var ComputerName: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  var Size: DWORD := MAX_COMPUTERNAME_LENGTH + 1;
  if GetComputerName(ComputerName, Size) then
    Result.DeviceName := ComputerName;

  // Obt�m a vers�o do Windows
  var OSVersionInfo: TOSVersionInfo;
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
  begin
    Result.OSVersion := Format('%d.%d.%d',
      [OSVersionInfo.dwMajorVersion,
       OSVersionInfo.dwMinorVersion,
       OSVersionInfo.dwBuildNumber]);
  end;
  {$ENDIF}

  {$IFDEF ANDROID}
  Result.Platform := 'Android';

  // Obt�m o nome do dispositivo Android
  var BuildObj := TJBuild.JavaClass;
  Result.DeviceName := JStringToString(BuildObj.MODEL);
  Result.Model := JStringToString(BuildObj.SOC_MANUFACTURER) +' '+ JStringToString(BuildObj.MODEL) +' ('+ JStringToString(BuildObj.DEVICE) +')';

  // Obt�m a vers�o do Android
  var VersionObj := TJBuild_VERSION.JavaClass;
  Result.OSVersion := JStringToString(VersionObj.RELEASE);
  {$ENDIF}

  {$IFDEF IOS}
  Result.Platform := 'iOS';

  // Obt�m o nome do dispositivo iOS
  var Device := TUIDevice.Wrap(TUIDevice.OCClass.currentDevice);
  Result.DeviceName := NSStrToStr(Device.name);

  // Obt�m a vers�o do iOS
  Result.OSVersion := NSStrToStr(Device.systemVersion);
  {$ENDIF}

  {$IFDEF MACOS}
  Result.Platform := 'macOS';

  // Obt�m o nome do host (Mac)
  var HostName: CFStringRef;
  HostName := CFHostGetName(nil);
  Result.DeviceName := CFStringToStr(HostName);

  // Obt�m a vers�o do macOS
  var VersionDict := CFDictionaryRef(CFBundleGetInfoDictionary(CFBundleGetMainBundle));
  var VersionStr := CFStringRef(CFDictionaryGetValue(VersionDict, kCFBundleVersionKey));
  Result.OSVersion := CFStringToStr(VersionStr);
  {$ENDIF}
end;

end.
