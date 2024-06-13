unit Conversa.WMI;
// https://theroadtodelphi.com/2010/12/01/accesing-the-wmi-from-pascal-code-delphi-oxygene-freepascal/
// https://theroadtodelphi.com/2011/08/02/reading-the-smbios-tables-using-delphi/
// https://theroadtodelphi.com/2010/11/28/be-careful-when-you-import-the-microsoft-wmiscripting-library/
// https://theroadtodelphi.com/2011/08/02/reading-the-smbios-tables-using-delphi/

interface

function GetWin32_BaseBoardInfo: String;

implementation

uses
  System.SysUtils,
  Winapi.ActiveX,
  System.Win.ComObj,
  System.Variants;//introduced in delphi 6, if you use a older version of delphi you just remove this

function VarArrayToStr(const vArray: variant): string;
  function _VarToStr(const V: variant): string;
  var
    Vt: integer;
  begin
    Vt := VarType(V);
    case Vt of
      varSmallint,varInteger  : Result := IntToStr(integer(V));
      varSingle, varDouble, varCurrency : Result := FloatToStr(Double(V));
      varDate     : Result := VarToStr(V);
      varOleStr   : Result := WideString(V);
      varBoolean  : Result := VarToStr(V);
      varVariant  : Result := VarToStr(Variant(V));
      varByte     : Result := char(byte(V));
      varString   : Result := String(V);
      varArray    : Result := VarArrayToStr(Variant(V));
    end;
  end;
var
  i : integer;
begin
  Result := '[';
  if (VarType(vArray) and VarArray) = 0 then
    Result := _VarToStr(vArray)
  else
    for i := VarArrayLowBound(vArray, 1) to VarArrayHighBound(vArray, 1) do
      if i=VarArrayLowBound(vArray, 1)  then
        Result := Result+_VarToStr(vArray[i])
      else
        Result := Result+'|'+_VarToStr(vArray[i]);

  Result := Result + ']';
end;

function VarStrNull(const V:OleVariant):string; //avoid problems with null strings
begin
  Result := '';
  if VarIsNull(V) then
    Exit;

  if VarIsArray(V) then
    Result:=VarArrayToStr(V)
  else
    Result:=VarToStr(V);
end;

function GetWMIObject(const objectName: String): IDispatch; //create the Wmi instance
var
  chEaten: Integer;
  BindCtx: IBindCtx;
  Moniker: IMoniker;
begin
  OleCheck(CreateBindCtx(0, bindCtx));
  OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
  OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
end;

//The Win32_BaseBoard class represents a base board (also known as a motherboard
//or system board).

function Internal_GetWin32_BaseBoardInfo: String;
var
  objWMIService : OLEVariant;
  colItems      : OLEVariant;
  colItem       : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;
begin
  objWMIService := GetWMIObject('winmgmts:\\localhost\root\CIMV2');
  colItems      := objWMIService.ExecQuery('SELECT * FROM Win32_BaseBoard','WQL',0);
  oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
  while oEnum.Next(1, colItem, iValue) = 0 do
  begin
    Result := VarStrNull(colItem.SerialNumber);
    colItem := Unassigned;
  end;
end;

function GetWin32_BaseBoardInfo: String;
begin;
  CoInitialize(nil);
  try
    Result := Internal_GetWin32_BaseBoardInfo;
  finally
    CoUninitialize;
  end;
end;

end.
