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
  FMX.Forms,
  FMX.Ani,
  FMX.Graphics,
  FMX.Objects,
  FMX.Types,
  FMX.Controls,
  FMX.Edit;

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

  TPSSFonte = record
    Family: String;
    Size: Integer;
    Syle: String;
  end;
  TPSSFonteProp = record
    nome: String;
    valor: TPSSFonte;
  end;
  TPSSFontes = TArray<TPSSFonteProp>;

  TPascalStyleScript = class
  private type
    TPSSTipoKind = (Classe, Propriedade);
    TPSSTipo = record
      Tipo: TPSSTipoKind;
      TypeInfo: PTypeInfo;
      Properties: TArray<string>;
    end;
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
      fontes: TPSSFontes;
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
    TPSSProperty = record
      Owner: TObject;
      RttiProp: TRttiProperty;
      function GetValue: TValue;
      function GetValor: string;
    end;
  private
    FClasses: TArray<TPSSTipo>;
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
//    function GetDefaultFont(const Value: TFont): String;
    procedure Apply(Inst: TPSSObject);
    //function GetRttiProperty(obj: TObject; propName: string): TRttiProperty;
    function GetRttiProperty(obj: TObject; propName: string): TPSSProperty;
    function Next(Obj: TFmxObject): Boolean;

    procedure RegisterTipo<T>(const Tipo: TPSSTipoKind; const Propriedades: TArray<string>); overload;

    function GetClassFromTypeInfo(TypeInfo: PTypeInfo): TClass;
    function PropriedadesDisponiveis(Value: TFmxObject): TArray<String>;
  public
    class function Instance: TPascalStyleScript;
    class procedure Start;
    class procedure Stop;
    destructor Destroy; override;
    procedure LoadFromFile(sFile: String);
    function RegisterObject(const Value: TFmxObject; ID: String = ''; Recursive: Boolean = True): TPascalStyleScript;
    procedure SaveDefault;
  end;

implementation
const
  DefaultFile = '.\tema\default.pss';
  DefaultTemaCores = '@cores';

var
  FInstance: TPascalStyleScript;

{ TConversaPSS }

class function TPascalStyleScript.Instance: TPascalStyleScript;
begin
  Result := FInstance;
end;

class procedure TPascalStyleScript.Start;
begin
  FInstance := TPascalStyleScript.Create;
end;

class procedure TPascalStyleScript.Stop;
begin
  FreeAndNil(FInstance);
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
  // Registro da classe TShape com suas propriedades de estilo
  //RegisterTipo<TShape>(TPSSTipoKind.Classe, ['Fill.Color', 'Stroke.Color']);
  RegisterTipo<TBrush>(TPSSTipoKind.Propriedade, ['Color']);
  RegisterTipo<TStrokeBrush>(TPSSTipoKind.Propriedade, ['Color', 'Kind']);
  // Registro da classe que possui TextSettings
  RegisterTipo<TTextSettings>(TPSSTipoKind.Propriedade, ['FontColor', 'Font.Size', 'Font.Family']);
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

//function TPascalStyleScript.GetRttiProperty(obj: TObject; propName: string): TRttiProperty;
//var
//  asNames: TArray<String>;
//  ctx: TRttiContext;
//  objType: TRttiType;
//  rpPropriedade: TRttiProperty;
//  i: Integer;
//begin
//  Result := nil;
//  // Obtém o contexto RTTI para o tipo do objeto
//  objType := ctx.GetType(obj.ClassType);
//  asNames := propName.Split(['.']);
//  for I := 0 to Pred(Length(asNames)) do
//  begin
//    // Obtém a propriedade pelo nome atual
//    rpPropriedade := objType.GetProperty(asNames[I]);
//    if not Assigned(rpPropriedade) then
//      Exit(nil);
//
//    // Se for a última parte do nome, finaliza
//    if I = Pred(Length(asNames)) then
//      Exit(rpPropriedade);
//
//    // Se não for uma classe, finaliza sem encontrar
//    if rpPropriedade.PropertyType.TypeKind <> tkClass then
//      Exit(nil);
//
//    // Obtém o tipo da classe para continuar navegando
//    objType := rpPropriedade.PropertyType;
//  end;
//end;

function TPascalStyleScript.GetRttiProperty(obj: TObject; propName: string): TPSSProperty;
var
  asNames: TArray<String>;
  ctx: TRttiContext;
  objType: TRttiType;
  rpProp: TRttiProperty;
  i: Integer;
begin
  Result.Owner := nil;
  Result.RttiProp := nil;
  // Obtém o contexto RTTI para o tipo do objeto
  objType := ctx.GetType(obj.ClassType);
  asNames := propName.Split(['.']);
  for i := 0 to High(asNames) do
  begin
    // Obtém a propriedade pelo nome atual
    rpProp := objType.GetProperty(asNames[i]);
    if not Assigned(rpProp) then
      Exit;
    // Salva o objeto atual como o dono da propriedade
    Result.Owner := obj;
    Result.RttiProp := rpProp;
    // Se for a última parte do nome, finaliza
    if i = High(asNames) then
      Exit;
    // Se não for uma classe, finaliza sem encontrar
    if rpProp.PropertyType.TypeKind <> tkClass then
      Exit;
    // Obtém o tipo da classe para continuar navegando
    objType := rpProp.PropertyType;
    // Atualiza o objeto atual para a próxima propriedade
    obj := rpProp.GetValue(obj).AsObject;
  end;
end;

procedure TPascalStyleScript.Apply(Inst: TPSSObject);
var
  sPropName: String;
  PSSProp: TPSSProperty;
  PropValue: String;
  Item: TSchemaItem;
  sDefault: String;
  ObjAux: TFmxObject;
  InstAux: TPSSObject;
  I: Integer;
  Value: TValue;
  titypeInfo: PTypeInfo;
  tibaseTypeInfo: PTypeInfo;
  iSetValue: Integer;
begin
  if not Assigned(Inst.Obj) then Exit;
  try
    // Localiza ou Cria o Objeto na lista default
    if not FDefault.TryGetItem(Inst.id, Item) then
    begin
      Item.id := Inst.id;
      Item.valor := EmptyStr;
      Item.estado := 0;
      FDefault.SetItem(Inst.id, Item);
    end;
    for sPropName in PropriedadesDisponiveis(Inst.obj) do
    begin
      PropValue := EmptyStr;
      PSSProp   := GetRttiProperty(Inst.obj, sPropName);
      if Assigned(PSSProp.RttiProp) then
      begin
        // Obtém o valor padrão da PSSProp
        if PSSProp.RttiProp.PropertyType.Handle = TypeInfo(TAlphaColor) then
        begin
          if not Item.TryGetPropriedade(sPropName, PropValue) then
          begin
            sDefault := GetDefaultColor(TAlphaColor(PSSProp.GetValue.AsInteger));
            if sDefault.Trim.IsEmpty then
              sDefault := AlphaColorToString(TAlphaColor(PSSProp.GetValue.AsInteger));
            Item.SetPropriedade(sPropName, sDefault);
            FDefault.SetItem(Inst.id, Item);
          end;

          if Length(FData.schema) > 0 then
            FData.TryGetItem(Inst.id, Item);

          Item.TryGetPropriedade(sPropName, PropValue);

          if Length(FData.tema.cores) > 0 then
          begin
            if PropValue.StartsWith(DefaultTemaCores +'.') then
              PropValue := FData.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));
          end
          else
          if PropValue.StartsWith(DefaultTemaCores +'.') then
            PropValue := FDefault.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));

          if PropValue.Trim.IsEmpty then
            Continue;

          TAnimator.AnimateColor(Inst.obj, sPropName, TPSSCor(PropValue), 0.25, TAnimationType.InOut, TInterpolationType.Quadratic);
        end
        else
        if (PSSProp.RttiProp.PropertyType.TypeKind in [tkEnumeration]) then
        begin
          if not Item.TryGetPropriedade(sPropName, PropValue) then
          begin
            //sDefault := GetDefaultFont(PSSProp.GetValue.AsObject);
            if sDefault.Trim.IsEmpty then
              sDefault := AlphaColorToString(TAlphaColor(PSSProp.GetValue.AsInteger));
            Item.SetPropriedade(sPropName, sDefault);
            FDefault.SetItem(Inst.id, Item);
          end;

          if Length(FData.schema) > 0 then
            FData.TryGetItem(Inst.id, Item);

          Item.TryGetPropriedade(sPropName, PropValue);

          if Length(FData.tema.cores) > 0 then
          begin
            if PropValue.StartsWith(DefaultTemaCores +'.') then
              PropValue := FData.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));
          end
          else
          if PropValue.StartsWith(DefaultTemaCores +'.') then
            PropValue := FDefault.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));

          if PropValue.Trim.IsEmpty then
            Continue;


          I := GetEnumValue(PSSProp.RttiProp.PropertyType.Handle, PropValue);
          Value := TValue.FromOrdinal(PSSProp.RttiProp.PropertyType.Handle, I);
          PSSProp.RttiProp.SetValue(PSSProp.Owner, Value);
        end
        else
        if (PSSProp.RttiProp.PropertyType.TypeKind in [tkString, tkUString]) then
        begin
          if not Item.TryGetPropriedade(sPropName, PropValue) then
          begin
            //sDefault := GetDefaultFont(PSSProp.GetValue.AsObject);
            if sDefault.Trim.IsEmpty then
              sDefault := AlphaColorToString(TAlphaColor(PSSProp.GetValue.AsInteger));
            Item.SetPropriedade(sPropName, sDefault);
            FDefault.SetItem(Inst.id, Item);
          end;

          if Length(FData.schema) > 0 then
            FData.TryGetItem(Inst.id, Item);

          Item.TryGetPropriedade(sPropName, PropValue);

          if Length(FData.tema.cores) > 0 then
          begin
            if PropValue.StartsWith(DefaultTemaCores +'.') then
              PropValue := FData.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));
          end
          else
          if PropValue.StartsWith(DefaultTemaCores +'.') then
            PropValue := FDefault.tema.cores.GetColor(PropValue.Replace(DefaultTemaCores +'.', ''));

          if PropValue.Trim.IsEmpty then
            Continue;

          PSSProp.RttiProp.SetValue(PSSProp.Owner, PropValue);
        end;
      end;
    end;
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
    SaveDefault;
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

function TPascalStyleScript.GetClassFromTypeInfo(TypeInfo: PTypeInfo): TClass;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
begin
  Result := nil;
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.GetType(TypeInfo);
    if RttiType is TRttiInstanceType then
      Result := TRttiInstanceType(RttiType).MetaclassType;
  finally
    RttiContext.Free;
  end;
end;

function TPascalStyleScript.PropriedadesDisponiveis(Value: TFmxObject): TArray<String>;
var
  asProps: TArray<String>;
  PSSTipo: TPSSTipo;
  sProp: String;
  function GetProps(TypeIn: PTypeInfo; sPath: String = ''): TArray<String>;
  var
    RttiContext: TRttiContext;
    RttiType: TRttiType;
    RttiProp: TRttiProperty;
    PropName: String;
  begin
    Result := [];
    RttiContext := TRttiContext.Create;
    try
      RttiType := RttiContext.GetType(TypeIn);
      for RttiProp in RttiType.GetDeclaredProperties do
      begin
        if ((RttiProp.PropertyType.TypeKind = tkClass) and (RttiProp.PropertyType.Handle = PSSTipo.TypeInfo)) or
           ((RttiProp.PropertyType.TypeKind = tkClass) and RttiProp.ClassType.InheritsFrom(GetClassFromTypeInfo(PSSTipo.TypeInfo))) or
           ((RttiProp.PropertyType.TypeKind = tkInterface) and (RttiProp.PropertyType.Handle = PSSTipo.TypeInfo)) then
          for PropName in PSSTipo.Properties do
            Result := Result + [sPath + RttiProp.Name +'.'+ PropName];
      end;
    finally
      RttiContext.Free;
    end;
  end;
begin
  Result := [];
  asProps := [];
  for PSSTipo in FClasses do
  begin
    if PSSTipo.Tipo = TPSSTipoKind.Classe then
    begin
      if ((PSSTipo.TypeInfo.Kind = tkClass) and Value.InheritsFrom(GetClassFromTypeInfo(PSSTipo.TypeInfo))) or
         ((PSSTipo.TypeInfo.Kind = tkInterface) and Supports(Value, PSSTipo.TypeInfo.TypeData.GUID)) then
        asProps := TArray.Concat<String>([asProps, PSSTipo.Properties]);
    end
    else
      asProps := asProps + GetProps(Value.ClassType.ClassInfo);
  end;
  for sProp in asProps do
    if IndexStr(sProp, Result) = -1 then
      Result := Result + [sProp];
end;

function TPascalStyleScript.RegisterObject(const Value: TFmxObject; ID: String = ''; Recursive: Boolean = True): TPascalStyleScript;
var
  obj: TPSSObject;
  sPropName: String;
  PSSProp: TPSSProperty;
  PropValue: TValue;
  schemaItem: TSchemaItem;
  sValue: String;
  I: Integer;
begin
  Result := Self;
  Exit;
  if not Assigned(Value) then
    raise Exception.Create('Objeto não criado!');
  obj.id := IfThen(ID.Trim.IsEmpty, String(Value.Name), ID);
  obj.Obj := Value;
  obj.Recursive := Recursive;
  FObjects.Add(obj);
  // Verifica se o ID já existe em FDefault
  if not FDefault.TryGetItem(obj.id, schemaItem) then
  begin
    schemaItem.id := obj.id;
    schemaItem.estado := 1;
  end;
  try
    // Itera pelas propriedades da classe para obter os valores padrão
    for sPropName in PropriedadesDisponiveis(Value) do
    begin
      if schemaItem.TryGetPropriedade(sPropName, sValue) then
        Continue;
      PSSProp := GetRttiProperty(Value, sPropName);
      if Assigned(PSSProp.RttiProp) then
      begin
        // Obtém o valor padrão da PSSProp
        PropValue := PSSProp.GetValue;
        if PSSProp.RttiProp.PropertyType.Handle = TypeInfo(TAlphaColor) then
        begin
          sValue := GetDefaultColor(TAlphaColor(PropValue.AsInteger));
          if sValue.Trim.IsEmpty then
            sValue := TPSSCor(TAlphaColor(PropValue.AsInteger));
          schemaItem.SetPropriedade(sPropName, sValue)
        end
        else // Armazena o valor padrão na estrutura de dados FDefault
          schemaItem.SetPropriedade(sPropName, PropValue.ToString);
      end;
    end;
  finally
    if Length(schemaItem.propriedades) > 0 then
      FDefault.SetItem(obj.id, schemaItem);
  end;
  // Se Recursive for True e o objeto tiver filhos, registra recursivamente os filhos
  if Recursive and Assigned(Value.Children) and (Value.ChildrenCount > 0) then
    for I := 0 to Value.ChildrenCount - 1 do
      if Assigned(Value.Children[I]) and not Trim(Value.Children[I].Name).IsEmpty then
        RegisterObject(Value.Children[I], obj.id + '.' + Value.Children[I].Name, Recursive);
  Apply(obj);
end;

//function TPascalStyleScript.RegisterObject(const Value: TFmxObject; ID: String = ''; Recursive: Boolean = True): TPascalStyleScript;
//var
//  obj: TPSSObject;
//begin
//  Result := Self;
//  obj.id := IfThen(ID.Trim.IsEmpty, String(Value.Name), ID);
//  obj.Obj := Value;
//  obj.Recursive := Recursive;
//  FObjects.Add(obj);
//  Apply(obj);
//end;

function TPascalStyleScript.GetDefaultColor(const Value: TAlphaColor): String;
var
  p: TPSSCorProp;
begin
  for p in FDefault.tema.cores do
    if TAlphaColor(P.valor) = Value then
      Exit(DefaultTemaCores +'.'+ p.nome);
end;

//function TPascalStyleScript.GetDefaultFont(const Value: TFont): String;
//var
//  p: TPSSFonteProp;
//begin
//  for p in FDefault.tema.fontes do
//    if P.valor.Family.Equals(Value.Family) and (P.valor.Size = Value.Size) then
//      Exit(DefaultTemaCores +'.'+ p.nome);
//end;

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

procedure TPascalStyleScript.SaveDefault;
begin
  SaveData(FDefault, DefaultFile);
end;

procedure TPascalStyleScript.RegisterTipo<T>(const Tipo: TPSSTipoKind; const Propriedades: TArray<string>);
var
  PSSClasse: TPSSTipo;
begin
  // Configurar a estrutura TPSSClasse com o nome da classe e propriedades
  PSSClasse.Tipo := Tipo;
  PSSClasse.TypeInfo := TypeInfo(T);
  PSSClasse.Properties := Propriedades;
  // Adicionar a classe configurada ao array FClasses
  SetLength(FClasses, Length(FClasses) + 1);
  FClasses[High(FClasses)] := PSSClasse;
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

{ TPascalStyleScript.TPSSProperty }

function TPascalStyleScript.TPSSProperty.GetValor: string;
begin
  //
end;

function TPascalStyleScript.TPSSProperty.GetValue: TValue;
begin
  Result := Self.RttiProp.GetValue(Self.Owner);
end;

end.
