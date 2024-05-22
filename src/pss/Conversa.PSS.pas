unit Conversa.PSS;

interface

uses
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  FMX.Ani,
  FMX.Types;

type
  TConversaPSS = class
  private type
    TConversaPSSClassObject = record
    private
      FObject: TFmxObject;
      FCallBack: TProc<TJSONObject>;
    end;
  private
    FData: TJSONValue;

    FClasses: TDictionary<String, TArray<TConversaPSSClassObject>>;

    procedure InternalLoad(const Data: TJSONValue);
    constructor Create;
  public
    class function Instance: TConversaPSS;
    class function New: TConversaPSS;
    destructor Destroy; override;
    procedure LoadFromFile(sFile: String);

    function RegisterClass(const Value: TFmxObject; CallBack: TProc<TJSONObject> = nil; ClassName: String = ''): TConversaPSS;
  end;

implementation

var
  FInstance: TConversaPSS;

{ TConversaPSS }

class function TConversaPSS.Instance: TConversaPSS;
begin
  Result := FInstance;
end;

class function TConversaPSS.New: TConversaPSS;
begin
  Result := TConversaPSS.Create;
end;

constructor TConversaPSS.Create;
begin
  FData := TJSONValue(TJSONObject.Create);
  FClasses := TDictionary<String, TArray<TConversaPSSClassObject>>.Create;
end;

destructor TConversaPSS.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FClasses);
  inherited;
end;

procedure TConversaPSS.LoadFromFile(sFile: String);
begin
  if not TFile.Exists(sFile) then
    raise Exception.Create('Arquivo de tema não encontrado!');

  with TStringStream.Create do
  try
    LoadFromFile(sFile);
    InternalLoad(TJSONObject.ParseJSONValue(DataString));
  finally
    Free;
  end;
end;

procedure TConversaPSS.InternalLoad(const Data: TJSONValue);
var
  Old: TJSONValue;
  jo: TJSONObject;

  KV: TPair<String, TArray<TConversaPSSClassObject>>;
  Obj: TConversaPSSClassObject;

  sObjName: String;
  sPropName: String;

  sValue: String;
begin
  if not Assigned(Data) then
    raise Exception.Create('Arquivo de tema inválido!');

  Old := FData;
  try
    FData := Data;
    try
      for KV in FClasses do
      begin
        if not FData.TryGetValue<TJSONObject>('classes.'+ KV.Key, jo) then
          Continue;
  //        raise Exception.Create('Arquivo de tema incompleto!');

        if not jo.TryGetValue<String>('rctFundo.fill.Color', sValue) then
          raise Exception.Create('Error Message');

        for Obj in KV.Value do
        begin
          for var jv in jo do
          begin
            sObjName := jv.JsonString.Value.Split(['.'])[0];
            sPropName := jv.JsonString.Value.Replace(sObjName, '').Trim(['.']).ToLower;
            sObjName := sObjName.Split([':'])[0];

            if sPropName.Equals('fill.color') then
            begin
              if not FData.TryGetValue<String>('tema.'+ jv.JsonValue.Value, sValue) then
                sValue := jv.JsonValue.Value;

              TAnimator.AnimateColor(
                TFmxObject(Obj.FObject.FindComponent(sObjName)),
                sPropName,
                ('$'+ sValue.Replace('null', '00000000').Replace('#', '').PadLeft(8, 'F')).ToInt64,
                0.5
              );
            end;
          end;
        end;
      end;
    finally
      FreeAndNil(Old);
    end;
  except
    InternalLoad(Old);
  end;
end;

function TConversaPSS.RegisterClass(const Value: TFmxObject; CallBack: TProc<TJSONObject> = nil; ClassName: String = ''): TConversaPSS;
var
  arObjects: TArray<TConversaPSSClassObject>;
  Obj: TConversaPSSClassObject;
begin
  Result := Self;

  if ClassName.Trim.IsEmpty then
    ClassName := Value.Name;

  FClasses.TryGetValue(ClassName, arObjects);

  Obj.FObject := Value;
  Obj.FCallBack := CallBack;

  arObjects := arObjects + [Obj];

  FClasses.AddOrSetValue(ClassName, arObjects);
end;

initialization
  FInstance := TConversaPSS.New;

finalization
  FreeAndNil(FInstance);

end.
