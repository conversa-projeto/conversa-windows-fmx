{

Pendencia
  - Registrar Novos
  - CallBack
  - Registro de Propriedades

}
unit PascalStyleScript;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Serializers,
  System.JSON.Writers,
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  System.UIConsts,
  System.UITypes,
  FMX.Forms,
  FMX.Ani,
  FMX.Objects,
  FMX.Types;

type

  TPSSCor = record
  private
    Valor: String;
  public
    class operator Implicit(const Cor: TPSSCor): TAlphaColor;
    class operator Implicit(const Cor: TPSSCor): String;
    class operator Implicit(const Cor: TAlphaColor): TPSSCor;
    class operator Implicit(const Cor: String): TPSSCor;
  end;

  TJsonPSSCorConverter = class(TJsonConverter)
  public
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
  end;

  TPSSCorProp = record
    nome: String;
    [JsonConverterAttribute(TJsonPSSCorConverter)]
    valor: TPSSCor;
  end;
  TPSSCores = TArray<TPSSCorProp>;

  TCoresH = record Helper for TPSSCores
    function GetColor(const nome: string): TPSSCor;
  end;

  TPascalStyleScript = class
  private type

    TSchemaItemPropriedade = record
      nome: string;
      valor: string;
    end;
    TSchemaItem = record
      id: string;
      estado: Integer;
      propriedades: TArray<TSchemaItemPropriedade>;
      valor: string;
      function TryGetPropriedade(const Nome: String; out Value: String): Boolean;
      function GetPropriedade(const Nome: String): String;
      procedure SetPropriedade(const Nome, Valor: String);
    end;

    TPSSTema = record
      cores: TPSSCores;
    end;

    TPSSData = record
      tema: TPSSTema;
      schema: TArray<TSchemaItem>;
      function TryGetItem(const id: String; var Value: TSchemaItem): Boolean;
      function GetItem(const id: String): TSchemaItem;
      procedure SetItem(const id: String; Value: TSchemaItem);
    end;
  private
    FDefault: TPSSData;
    FData: TPSSData;
    FClassInstance: TDictionary<String, TArray<TFmxObject>>;
    constructor Create;
    procedure InternalLoad(const Data: TPSSData);
    procedure InternalApply;
    procedure LoadDefault;
    function LoadData(const FileName: String): TPSSData;
    procedure SaveData(const Data: TPSSData; const FileName: String);
    function GetDefaultColor(const Value: TAlphaColor): String;
    procedure Apply(const Classe: String; const Obj: TFmxObject);
//    function GetProp(Obj: TFmxObject; AName: String): TRttiObject;
    function Next(Obj: TFmxObject): Boolean;
  public
    class function Instance: TPascalStyleScript;
    class function New: TPascalStyleScript;
    destructor Destroy; override;
    procedure LoadFromFile(sFile: String);

    function RegisterInstance(const Value: TFmxObject; ClassName: String = ''): TPascalStyleScript;
  end;

implementation

const
  DefaultFile = 'tema/default.pss';

var
  FInstance: TPascalStyleScript;

{ TConversaPSS }

class function TPascalStyleScript.Instance: TPascalStyleScript;
begin
  Result := FInstance;
end;

class function TPascalStyleScript.New: TPascalStyleScript;
begin
  Result := TPascalStyleScript.Create;
end;

function TPascalStyleScript.Next(Obj: TFmxObject): Boolean;
var
  Value: TArray<TFmxObject>;
  ObjA: TFmxObject;
begin
  Result := True;
  for Value in FClassInstance.Values.ToArray do
    for ObjA in Value do
      if Assigned(ObjA) and (Pointer(ObjA) = Pointer(Obj)) then
        Exit(False);
end;

constructor TPascalStyleScript.Create;
begin
  LoadDefault;
  FClassInstance := TDictionary<String, TArray<TFmxObject>>.Create;
end;

destructor TPascalStyleScript.Destroy;
begin
  FreeAndNil(FClassInstance);
  inherited;
end;

procedure TPascalStyleScript.LoadDefault;
begin
  FDefault := LoadData(DefaultFile);
end;

procedure TPascalStyleScript.LoadFromFile(sFile: String);
begin
  InternalLoad(LoadData(sFile));
end;

//function TPascalStyleScript.GetProp(Obj: TFmxObject; AName: String): TRttiObject;
////var
////  T: TRttiType;
////  P: TRttiProperty;
//begin
////  Result := nil;
////  T := SharedContext.GetType(Obj.ClassInfo);
////  if not Assigned(T) then
////    Exit(nil);
////
////  for AName in AName.Split(['.']) do
////  begin
////    P := T.GetProperty(AName);
////    if not Assigned(P) then
////      Exit(nil);
////  end;
//end;

procedure TPascalStyleScript.Apply(const Classe: String; const Obj: TFmxObject);
var
  Item: TSchemaItem;
  id: string;
  sDefault: String;
  PropValue: String;
  ObjAux: TFmxObject;
//  P: TRttiProperty;
begin
  if not Assigned(Obj) then
    Exit;

  try
    if Obj.InheritsFrom(FMX.Objects.TRectangle) and not Trim(Obj.Name).IsEmpty then
    begin
      id := Classe +'.'+ String(Obj.Name);
      PropValue := EmptyStr;
      if not FDefault.TryGetItem(id, Item) then
      begin
        Item.id := id;
        Item.valor := EmptyStr;
        Item.estado := 0;

        FDefault.SetItem(id, Item);
      end;

      if not Item.TryGetPropriedade('fill.color', PropValue) then
      begin
        sDefault := GetDefaultColor(TRectangle(Obj).Fill.Color);
        if sDefault.Trim.IsEmpty then
          sDefault := AlphaColorToString(TRectangle(Obj).Fill.Color)
        else
          sDefault := '@cores.'+ sDefault;

        Item.SetPropriedade('fill.color', sDefault);
        FDefault.SetItem(id, Item);
      end;

      FData.TryGetItem(id, Item);

      Item.TryGetPropriedade('fill.color', PropValue);

      if PropValue.StartsWith('@cores.') then
        PropValue := FData.tema.cores.GetColor(PropValue.Replace('@cores.', ''));

      if PropValue.Trim.IsEmpty then
        Exit;

      TAnimator.AnimateColor(Obj, 'fill.color', TPSSCor(PropValue), 0.25, TAnimationType.InOut, TInterpolationType.Quadratic);
    end;
  finally
    if Assigned(Obj.Children) then
      for ObjAux in Obj.Children.ToArray do
        if Next(ObjAux) then
          Apply(Classe, ObjAux);
  end;
end;

procedure TPascalStyleScript.InternalApply;
var
  Classes: TPair<String, TArray<TFmxObject>>;
  Obj: TFmxObject;
begin
  try
    // Percorre a Lista de Classe
    for Classes in FClassInstance do
      for Obj in Classes.Value do
        Apply(Classes.Key, Obj);
  finally
    SaveData(FDefault, DefaultFile);
  end;
end;

procedure TPascalStyleScript.InternalLoad(const Data: TPSSData);
var
  Old: TPSSData;
begin
  Old := FData;
  try
    FData := Data;
    InternalApply;
  except
    InternalLoad(Old);
  end;
end;

function TPascalStyleScript.RegisterInstance(const Value: TFmxObject; ClassName: String = ''): TPascalStyleScript;
var
  arObjects: TArray<TFmxObject>;
begin
  Result := Self;

  if ClassName.Trim.IsEmpty then
    ClassName := Value.Name;

  FClassInstance.TryGetValue(ClassName, arObjects);

  arObjects := arObjects + [Value];

  FClassInstance.AddOrSetValue(ClassName, arObjects);
end;

function TPascalStyleScript.GetDefaultColor(const Value: TAlphaColor): String;
var
  p: TPSSCorProp;
begin
  for p in FDefault.tema.cores do
    if TAlphaColor(P.valor) = Value then
      Exit(p.nome);
end;

function TPascalStyleScript.LoadData(const FileName: String): TPSSData;
begin
  if not TFile.Exists(FileName) then
    raise Exception.Create('Arquivo de tema não encontrado!');

  with TStringStream.Create do
  try
    LoadFromFile(FileName);
    with TJsonSerializer.Create do
    try
      Populate<TPSSData>(DataString, Result);
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

procedure TPascalStyleScript.SaveData(const Data: TPSSData; const FileName: String);
begin
  with TJsonSerializer.Create do
  try
    with TStringStream.Create(Serialize<TPSSData>(Data)) do
    try
      SaveToFile(FileName);
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

{ TConversaPSS.TSchemaItem }

function TPascalStyleScript.TSchemaItem.TryGetPropriedade(const Nome: String; out Value: String): Boolean;
var
  p: TSchemaItemPropriedade;
begin
  Result := False;
  for p in propriedades do
  begin
    if not p.nome.ToLower.Equals(Nome.ToLower) then
      Continue;

    Value := p.valor;
    Exit(True);
  end;
end;

function TPascalStyleScript.TSchemaItem.GetPropriedade(const Nome: String): String;
begin
  if not TryGetPropriedade(Nome, Result) then
    raise Exception.Create('Propriedade não encontrada!');
end;

procedure TPascalStyleScript.TSchemaItem.SetPropriedade(const Nome, Valor: String);
var
  I: Integer;
begin
  for I := 0 to Pred(Length(propriedades)) do
  begin
    if propriedades[I].nome.ToLower.Equals(Nome.ToLower) then
    begin
      propriedades[I].valor := Valor;
      Exit;
    end;
  end;

  SetLength(propriedades, Succ(Length(propriedades)));
  propriedades[Pred(Length(propriedades))].nome := Nome;
  propriedades[Pred(Length(propriedades))].valor := valor;
end;

{ TConversaPSS.TPSSData }

function TPascalStyleScript.TPSSData.GetItem(const id: String): TSchemaItem;
begin
end;

function TPascalStyleScript.TPSSData.TryGetItem(const id: String; var Value: TSchemaItem): Boolean;
var
  R: TSchemaItem;
begin
  Result := False;
  for R in schema do
  begin
    if R.id <> id then
      Continue;

    Value := R;
    Exit(True);
  end;
end;

procedure TPascalStyleScript.TPSSData.SetItem(const id: String; Value: TSchemaItem);
var
  I: Integer;
begin
  for I := 0 to Pred(Length(schema)) do
  begin
    if schema[I].id.Equals(id) then
    begin
      schema[I] := Value;
      Exit;
    end;
  end;

  SetLength(schema, Succ(Length(schema)));
  schema[Pred(Length(schema))] := value;
end;

{ TCoresH }

function TCoresH.GetColor(const nome: string): TPSSCor;
var
  Value: TPSSCorProp;
begin
  Result := TAlphaColors.Null;
  for Value in Self do
    if Value.nome.ToLower.Equals(nome.ToLower) then
      Exit(Value.valor);
end;

{ TPSSCor }

class operator TPSSCor.Implicit(const Cor: TPSSCor): TAlphaColor;
begin
  Result := StringToAlphaColor(Cor.Valor);
end;

class operator TPSSCor.Implicit(const Cor: TAlphaColor): TPSSCor;
begin
  Result.Valor := AlphaColorToString(Cor);
end;

class operator TPSSCor.Implicit(const Cor: String): TPSSCor;
begin
  Result.Valor := Cor;
end;

class operator TPSSCor.Implicit(const Cor: TPSSCor): String;
begin
  Result := Cor.Valor;
end;

{ TJsonPSSCorConverter }

function TJsonPSSCorConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  Cor: TPSSCor;
begin
  Cor.Valor := AReader.Value.ToString;
  Result := TValue.From<TPSSCor>(TPSSCor(Cor));
end;

procedure TJsonPSSCorConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
begin
  inherited;
  AWriter.WriteValue(AValue.AsType<TPSSCor>.Valor);
end;

initialization
  FInstance := TPascalStyleScript.New;

finalization
  FreeAndNil(FInstance);

end.
