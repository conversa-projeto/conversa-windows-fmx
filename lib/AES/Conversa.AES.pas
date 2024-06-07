unit Conversa.AES;

interface

function Encrypt(const Value: String): String;
function Decrypt(const Value: String): String;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
//  System.Classes,
//  System.JSON,
//  System.IOUtils,
//  System.JSON.Serializers,
  System.Variants,
  Winapi.ActiveX,
  System.Win.ComObj,
  Prism.Crypto.AES;
var
  IV: TBytes;
  MotherBoardSerial: String;

function GetMotherBoardSerial:String;
var
  objWMIService : OLEVariant;
  colItems      : OLEVariant;
  colItem       : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;

  function GetWMIObject(const objectName: String): IDispatch;
  var
    chEaten: Integer;
    BindCtx: IBindCtx;
    Moniker: IMoniker;
  begin
    OleCheck(CreateBindCtx(0, bindCtx));
    OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
    OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
  end;

begin
  Result:='';
  objWMIService := GetWMIObject('winmgmts:\\localhost\root\cimv2');
  colItems      := objWMIService.ExecQuery('SELECT SerialNumber FROM Win32_BaseBoard','WQL',0);
  oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
  if oEnum.Next(1, colItem, iValue) = 0 then
  Result:=VarToStr(colItem.SerialNumber);
end;

function Encrypt(const Value: String): String;
var
  Salt: String;
  ValueBytes, Key: TBytes;
begin
  if Value.Trim.IsEmpty then
    Exit(Value);

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
  ValueDecode := TNetEncoding.Base64.Decode(Value);
  Salt := ValueDecode.Split([':'])[0];
  Key  := TEncoding.UTF8.GetBytes(MotherBoardSerial + Salt);
  ValueBytes := TNetEncoding.Base64.DecodeStringToBytes(ValueDecode.Substring(Salt.Length + 1));
  Result := TEncoding.UTF8.GetString(TAES.Decrypt(ValueBytes, Key, 256, IV, cmCBC, pmPKCS7));
end;

initialization
  IV := TEncoding.UTF8.GetBytes('1234567890123456'); // 16 bytes
  MotherBoardSerial := GetMotherBoardSerial;

end.
