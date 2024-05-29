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
  System.StrUtils,
  System.SysUtils,
  System.TypInfo,
  System.UIConsts,
  System.UITypes,
  FMX.Ani,
  FMX.Graphics,
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

    TPSSObject = record
      id: string;
      obj: TFmxObject;
      recursive: Boolean;
    end;
  private
    FDefault: TPSSData;
    FData: TPSSData;
    FObjects: TList<TPSSObject>;
    constructor Create;
    procedure InternalLoad(const Data: TPSSData);
    procedure InternalApply;
    procedure LoadDefault;
    function LoadData(const FileName: String): TPSSData;
    procedure SaveData(const Data: TPSSData; const FileName: String);
    function GetDefaultColor(const Value: TAlphaColor): String;
    procedure Apply(Inst: TPSSObject);
//    function GetProp(Obj: TFmxObject; AName: String): TRttiObject;
    function Next(Obj: TFmxObject): Boolean;
  public
    class function Instance: TPascalStyleScript;
    class function New: TPascalStyleScript;

    destructor Destroy; override;
    procedure LoadFromFile(sFile: String);

    function RegisterObject(const Value: TFmxObject; ID: String = ''; Recursive: Boolean = True): TPascalStyleScript;
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
  Value: TPSSObject;
begin
  Result := True;
  for Value in FObjects do
    if Assigned(Value.Obj) and (Pointer(Value.Obj) = Pointer(Obj)) then
      Exit(False);
end;

constructor TPascalStyleScript.Create;
begin
  LoadDefault;
  FObjects := TList<TPSSObject>.Create;
end;

destructor TPascalStyleScript.Destroy;
begin
  FreeAndNil(FObjects);
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

procedure TPascalStyleScript.Apply(Inst: TPSSObject);
var
  Item: TSchemaItem;
//  id: string;
  sDefault: String;
  PropValue: String;
  ObjAux: TFmxObject;
  InstAux: TPSSObject;
//  P: TRttiProperty;
begin
  if not Assigned(Inst.Obj) then
    Exit;

  try
    if Inst.obj.InheritsFrom(FMX.Objects.TShape) then
    begin
//      id := Inst.id +'.'+ String(Inst.obj.Name);
      PropValue := EmptyStr;
      if not FDefault.TryGetItem(Inst.id, Item) then
      begin
        Item.id := Inst.id;
        Item.valor := EmptyStr;
        Item.estado := 0;

        FDefault.SetItem(Inst.id, Item);
      end;

      if not Item.TryGetPropriedade('fill.color', PropValue) then
      begin
        sDefault := GetDefaultColor(TRectangle(Inst.obj).Fill.Color);
        if sDefault.Trim.IsEmpty then
          sDefault := AlphaColorToString(TRectangle(Inst.obj).Fill.Color)
        else
          sDefault := '@cores.'+ sDefault;

        Item.SetPropriedade('fill.color', sDefault);
        FDefault.SetItem(Inst.id, Item);
      end;

      if Length(FData.schema) > 0 then
        FData.TryGetItem(Inst.id, Item);

      Item.TryGetPropriedade('fill.color', PropValue);

      if Length(FData.tema.cores) > 0 then
      begin
        if PropValue.StartsWith('@cores.') then
          PropValue := FData.tema.cores.GetColor(PropValue.Replace('@cores.', ''));
      end
      else
      if PropValue.StartsWith('@cores.') then
        PropValue := FDefault.tema.cores.GetColor(PropValue.Replace('@cores.', ''));

      if PropValue.Trim.IsEmpty then
        Exit;

      TAnimator.AnimateColor(Inst.obj, 'fill.color', TPSSCor(PropValue), 0.25, TAnimationType.InOut, TInterpolationType.Quadratic);
    end;
//    if Inst.obj.InheritsFrom(FMX.Objects.TShape) and not Trim(Inst.obj.Name).IsEmpty and (TShape(Inst.obj).Stroke.Kind <> TBrushKind.None) then
//    begin
//      id := Inst.id;
//      PropValue := EmptyStr;
//      if not FDefault.TryGetItem(id, Item) then
//      begin
//        Item.id := id;
//        Item.valor := EmptyStr;
//        Item.estado := 0;
//
//        FDefault.SetItem(id, Item);
//      end;
//
//      if not Item.TryGetPropriedade('stroke.color', PropValue) then
//      begin
//        sDefault := GetDefaultColor(TRectangle(Obj).stroke.Color);
//        if sDefault.Trim.IsEmpty then
//          sDefault := AlphaColorToString(TRectangle(Obj).stroke.Color)
//        else
//          sDefault := '@cores.'+ sDefault;
//
//        Item.SetPropriedade('stroke.color', sDefault);
//        FDefault.SetItem(id, Item);
//      end;
//
//      FData.TryGetItem(id, Item);
//
//      Item.TryGetPropriedade('stroke.color', PropValue);
//
//      if PropValue.StartsWith('@cores.') then
//        PropValue := FData.tema.cores.GetColor(PropValue.Replace('@cores.', ''));
//
//      if PropValue.Trim.IsEmpty then
//        Exit;
//
//      TAnimator.AnimateColor(Obj, 'stroke.color', TPSSCor(PropValue), 0.25, TAnimationType.InOut, TInterpolationType.Quadratic);
//    end;
  finally
    if Inst.recursive and Assigned(Inst.obj.Children) then
    begin
      for ObjAux in Inst.obj.Children.ToArray do
      begin
        if Next(ObjAux) and not String(ObjAux.Name).Trim.IsEmpty then
        begin
          InstAux := Inst;
          InstAux.id := InstAux.id +'.'+ ObjAux.Name;
          InstAux.obj := ObjAux;
          Apply(InstAux);
        end;
      end;
    end;
  end;
end;

procedure TPascalStyleScript.InternalApply;
var
  Inst: TPSSObject;
begin
  try
    // Percorre a Lista de Classe
    for Inst in FObjects do
      Apply(Inst);
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

function TPascalStyleScript.RegisterObject(const Value: TFmxObject; ID: String = ''; Recursive: Boolean = True): TPascalStyleScript;
var
  obj: TPSSObject;
begin
  Result := Self;
  obj.id := IfThen(ID.Trim.IsEmpty, String(Value.Name), ID);
  obj.Obj := Value;
  obj.Recursive := Recursive;
  FObjects.Add(obj);
  Apply(obj);
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
  if not TryGetItem(id, Result) then
    raise Exception.Create('Item não encontrado!');
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
