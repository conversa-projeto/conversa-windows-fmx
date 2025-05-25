// Daniel - 24/05/2025
unit Conversa.Serializer;

interface

uses
  System.JSON,
  System.JSON.Serializers,
  System.JSON.Types;

type

  {TODO -oDaniel -cMelhoria : Corrigir Serializer/Deserialize de NULL}
  TJsonSerializer<T> = class(System.JSON.Serializers.TJsonSerializer)
  public
    constructor Create; reintroduce; overload;
    class function FromStr(const AValue: String): T; overload;
    class function FromJSON(const AJson: TJSONObject): T; overload;
    class function ToJSON(const AValue: T): TJSONObject; overload;
    class function ToJSONArray(const AValue: T): TJSONArray; overload;
  end;

implementation

{ TJsonSerializer<T> }

constructor TJsonSerializer<T>.Create;
begin
  inherited;
  DateTimeZoneHandling := TJsonDateTimeZoneHandling.Utc;
end;

class function TJsonSerializer<T>.FromStr(const AValue: String): T;
begin
  with TJsonSerializer.Create do
  try
    Result := Deserialize<T>(AValue);
  finally
    Free;
  end;
end;

class function TJsonSerializer<T>.FromJSON(const AJson: TJSONObject): T;
begin
  Result := Self.FromStr(AJson.ToJSON);
end;

class function TJsonSerializer<T>.ToJSON(const AValue: T): TJSONObject;
begin
  with TJsonSerializer.Create do
  try
    Result := TJSONObject.ParseJSONValue(Serialize<T>(AValue)) as TJSONObject;
  finally
    Free;
  end;
end;

class function TJsonSerializer<T>.ToJSONArray(const AValue: T): TJSONArray;
begin
  with TJsonSerializer.Create do
  try
    Result := TJSONObject.ParseJSONValue(Serialize<T>(AValue)) as TJSONArray;
  finally
    Free;
  end;
end;

end.
