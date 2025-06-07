// Daniel - 24/05/2025
unit Conversa.Serializer;

interface

uses
  System.JSON,
  System.JSON.Serializers,
  System.JSON.Types;

type

  TJsonSerializer = class(System.JSON.Serializers.TJsonSerializer)
    constructor Create; reintroduce; overload;
  end;

  {TODO -oDaniel -cMelhoria : Corrigir Serializer/Deserialize de NULL}
  TJsonSerializer<T> = class(TJsonSerializer)
  public
    class function FromStr(const AValue: String): T; overload;
    class function FromJSON(const AJson: TJSONObject): T; overload;
    class function ToJSON(const AValue: T): TJSONObject; overload;
    class function ToJSONArray(const AValue: T): TJSONArray; overload;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON.Readers,
  System.JSON.Writers,
  System.TypInfo,
  System.Rtti;

type
  TDateTimeConverter = class(TJsonConverter)
  private
    class var FConverter: TDateTimeConverter;
  public
    class constructor Create;
    class destructor Destroy;
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue; const ASerializer: System.JSON.Serializers.TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: System.JSON.Serializers.TJsonSerializer); override;
  end;

{ TDateTimeConverter }

class constructor TDateTimeConverter.Create;
begin
  FConverter := TDateTimeConverter.Create;
end;

class destructor TDateTimeConverter.Destroy;
begin
  FreeAndNil(FConverter);
end;

function TDateTimeConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  // Verifica se é um TDateTime (tkFloat para tipos de data)
  Result :=
    (ATypeInf = TypeInfo(TDateTime)) or
    (ATypeInf = TypeInfo(TDate)) or
    (ATypeInf = TypeInfo(TTime));
end;

function TDateTimeConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue; const ASerializer: System.JSON.Serializers.TJsonSerializer): TValue;
var
  DtValue: TDateTime;
begin
  // Se for um TJSONNull, retorna zero para o datetime
  if AReader.TokenType = TJsonToken.Null then
    Result := 0.0
  else
  begin
    DtValue := TTimeZone.Local.ToLocalTime(ISO8601ToDate(AReader.Value.AsString));

    if (ATypeInf = TypeInfo(TDate)) then
      Result := TDate(DtValue)
    else
    if (ATypeInf = TypeInfo(TTime)) then
      Result := TTime(DtValue)
    else
      Result := TDateTime(DtValue);
  end;
end;

procedure TDateTimeConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: System.JSON.Serializers.TJsonSerializer);
var
  DtValue: TDateTime;
begin
  DtValue := AValue.AsExtended;
  if DtValue = 0 then
    AWriter.WriteNull // Escreve NULL se TDateTime for 0
  else
  begin
    if (AValue.TypeInfo = TypeInfo(TDate)) then
      AWriter.WriteValue(TDateTime(TDate(DtValue)))
    else
    if (AValue.TypeInfo = TypeInfo(TTime)) then
      AWriter.WriteValue(TDatetime(TTime(DtValue)))
    else
      AWriter.WriteValue(TDateTime(DtValue))
  end;
end;

{ TJsonSerializer<T> }

constructor TJsonSerializer.Create;
begin
  inherited;
  DateTimeZoneHandling := TJsonDateTimeZoneHandling.Utc;
  Converters.Add(TJsonConverter(TDateTimeConverter.FConverter));
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
