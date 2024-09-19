unit Conversa.AES;

interface

function Encrypt(const Value: String): String;
function Decrypt(const Value: String): String;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  Prism.Crypto.AES,
  Conversa.WMI;

var
  IV: TBytes;
  MotherBoardSerial: String;

function Encrypt(const Value: String): String;
var
  Salt: String;
  ValueBytes, Key: TBytes;
begin
  if Value.Trim.IsEmpty then
    Exit(Value);

  if Length(IV) = 0 then
  begin
    IV := TEncoding.UTF8.GetBytes('1234567890123456');
    MotherBoardSerial := GetWin32_BaseBoardInfo;
  end;

  Salt := TGUID.NewGuid.ToString.Trim(['{', '}', ' ', '-']);
  Key  := TEncoding.UTF8.GetBytes(MotherBoardSerial + Salt);
  ValueBytes := TEncoding.UTF8.GetBytes(Value);
  Result := TNetEncoding.Base64.Encode(Salt +':'+ TNetEncoding.Base64.EncodeBytesToString(TAES.Encrypt(ValueBytes, Key, 256, IV, cmCBC, pmPKCS7)));
end;

function Decrypt(const Value: String): String;
var
  ValueDecode: String;
  Salt: String;
  ValueBytes, Key: TBytes;
begin
  if Value.Trim.IsEmpty then
    Exit(Value);

  if Length(IV) = 0 then
  begin
    IV := TEncoding.UTF8.GetBytes('1234567890123456');
    MotherBoardSerial := GetWin32_BaseBoardInfo;
  end;

  ValueDecode := TNetEncoding.Base64.Decode(Value);
  Salt := ValueDecode.Split([':'])[0];
  Key  := TEncoding.UTF8.GetBytes(MotherBoardSerial + Salt);
  ValueBytes := TNetEncoding.Base64.DecodeStringToBytes(ValueDecode.Substring(Salt.Length + 1));
  Result := TEncoding.UTF8.GetString(TAES.Decrypt(ValueBytes, Key, 256, IV, cmCBC, pmPKCS7));
end;

end.
