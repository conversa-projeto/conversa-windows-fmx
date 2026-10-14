unit Conversa.Contrato.Json;

{ Leitura tolerante do JSON do servidor (FC-108; D7 do doc 07; doc 01 §19).

  - Campo ausente ou null = valor padrão (o servidor omite mensagem_referencia/reacoes e manda null em datas).
  - Ids: número ou texto (PUT /anexo com existe:true devolve "id" como string) -> Int64.
  - Datas: ISO-8601 em UTC. A API manda "2026-10-06T12:00:00.123Z"; o resumo de chamada (tipo 6) manda
    "2026-10-06T12:00:05" sem fuso, que também é UTC. TDatas aceita os dois e mais: espaço no lugar do T,
    0 a 9 casas decimais, Z, +hh:mm, +hhmm, +hh. Data inválida vira "sem data" (0), nunca exceção.
  - No Delphi 12 TJSONNumber herda de TJSONString: testar TJSONNumber antes. }

interface

uses
  System.SysUtils,
  System.JSON;

type
  EContratoInvalido = class(Exception);

  TDatas = record
    /// <summary>ISO-8601 -> TDateTime em UTC. Sem fuso = UTC. False se inválida.</summary>
    class function TentarLerIso(const ATexto: string; out AUtc: TDateTime): Boolean; static;
    /// <summary>UTC -> "AAAA-MM-DDTHH:MM:SS.zzzZ" (o formato da API).</summary>
    class function ParaIso(AUtc: TDateTime): string; static;
    class function UtcParaLocal(AUtc: TDateTime): TDateTime; static;
    class function LocalParaUtc(ALocal: TDateTime): TDateTime; static;
    class function AgoraUtc: TDateTime; static;
  end;

  /// <summary>Lê campos de um TJSONObject sem lançar por ausência, null ou tipo diferente.</summary>
  TLeitorJson = record
  private
    FObjeto: TJSONObject;
    function Valor(const ACampo: string): TJSONValue;
  public
    constructor Create(AObjeto: TJSONObject);
    /// <summary>O campo existe e não é null.</summary>
    function Tem(const ACampo: string): Boolean;
    function Texto(const ACampo: string; const APadrao: string = ''): string;
    /// <summary>Número ou texto numérico -> Int64.</summary>
    function Inteiro(const ACampo: string; APadrao: Int64 = 0): Int64;
    function Numero(const ACampo: string; APadrao: Double = 0): Double;
    /// <summary>true/false, número (0 = falso) ou texto ("true", "1").</summary>
    function Booleano(const ACampo: string; APadrao: Boolean = False): Boolean;
    /// <summary>Data ISO em UTC; 0 se ausente, null ou inválida.</summary>
    function DataUtc(const ACampo: string): TDateTime;
    /// <summary>Objeto do campo (pertence ao JSON de origem: não liberar); nil se ausente ou de outro tipo.</summary>
    function Objeto(const ACampo: string): TJSONObject;
    /// <summary>Lista do campo (pertence ao JSON de origem: não liberar); nil se ausente ou de outro tipo.</summary>
    function Lista(const ACampo: string): TJSONArray;
    /// <summary>Lista de inteiros (números ou textos); itens inválidos são ignorados.</summary>
    function Inteiros(const ACampo: string): TArray<Int64>;
    function Textos(const ACampo: string): TArray<string>;
    property ObjetoJson: TJSONObject read FObjeto;
  end;

  TJson = record
    /// <summary>Faz o parse de um texto que tem de ser objeto. Quem chama libera.</summary>
    class function LerObjeto(const ATexto: string): TJSONObject; static;
    /// <summary>Faz o parse de um texto que tem de ser lista. Quem chama libera.</summary>
    class function LerLista(const ATexto: string): TJSONArray; static;
    /// <summary>Converte um valor JSON (número ou texto numérico) para Int64.</summary>
    class function ComoInteiro(AValor: TJSONValue; out AInteiro: Int64): Boolean; static;
    /// <summary>Monta "[1,2,3]".</summary>
    class function ListaDeInteiros(const AValores: array of Int64): TJSONArray; static;
  end;

resourcestring
  SJsonInvalido = 'Resposta do servidor em formato inesperado.';

implementation

uses
  System.DateUtils;

{ TDatas }

class function TDatas.TentarLerIso(const ATexto: string; out AUtc: TDateTime): Boolean;
var
  S: string;
  N, I: Integer;
  LAno, LMes, LDia, LHora, LMinuto, LSegundo, LMilissegundo: Word;
  LData, LHorario: TDateTime;
  LOffsetMin: Integer;
  LSinal: Integer;
  LOffH, LOffM: Integer;
  LFracao: string;

  function Digitos(APos, AQtd: Integer; out AValor: Word): Boolean;
  var
    K: Integer;
    V: Integer;
  begin
    Result := False;
    AValor := 0;
    if APos + AQtd - 1 > N then
      Exit;
    V := 0;
    for K := APos to APos + AQtd - 1 do
    begin
      if not CharInSet(S[K], ['0'..'9']) then
        Exit;
      V := V * 10 + (Ord(S[K]) - Ord('0'));
    end;
    AValor := Word(V);
    Result := True;
  end;

  function DigitosInt(APos, AQtd: Integer; out AValor: Integer): Boolean;
  var
    W: Word;
  begin
    Result := Digitos(APos, AQtd, W);
    AValor := W;
  end;

begin
  AUtc := 0;
  Result := False;
  S := Trim(ATexto);
  N := Length(S);
  // AAAA-MM-DD
  if (N < 10) or not Digitos(1, 4, LAno) or (S[5] <> '-') or not Digitos(6, 2, LMes) or (S[8] <> '-') or
     not Digitos(9, 2, LDia) then
    Exit;
  if not TryEncodeDate(LAno, LMes, LDia, LData) then
    Exit;
  LHora := 0;
  LMinuto := 0;
  LSegundo := 0;
  LMilissegundo := 0;
  LOffsetMin := 0;
  I := 11;
  if N >= 11 then
  begin
    if not CharInSet(S[11], ['T', 't', ' ']) then
      Exit;
    // HH:MM
    if not Digitos(12, 2, LHora) or (N < 16) or (S[14] <> ':') or not Digitos(15, 2, LMinuto) then
      Exit;
    I := 17;
    // :SS
    if (I <= N) and (S[I] = ':') then
    begin
      if not Digitos(I + 1, 2, LSegundo) then
        Exit;
      I := I + 3;
      // fração: .123 ou ,123 (0 a 9 dígitos; só os 3 primeiros contam)
      if (I <= N) and CharInSet(S[I], ['.', ',']) then
      begin
        Inc(I);
        LFracao := '';
        while (I <= N) and CharInSet(S[I], ['0'..'9']) do
        begin
          LFracao := LFracao + S[I];
          Inc(I);
        end;
        if (LFracao = '') or (Length(LFracao) > 9) then
          Exit;
        LFracao := Copy(LFracao + '00', 1, 3);
        LMilissegundo := Word(StrToInt(LFracao));
      end;
    end;
    // fuso
    if I <= N then
    begin
      if CharInSet(S[I], ['Z', 'z']) then
        Inc(I)
      else if CharInSet(S[I], ['+', '-']) then
      begin
        if S[I] = '-' then
          LSinal := -1
        else
          LSinal := 1;
        if not DigitosInt(I + 1, 2, LOffH) then
          Exit;
        I := I + 3;
        LOffM := 0;
        if (I <= N) and (S[I] = ':') then
        begin
          if not DigitosInt(I + 1, 2, LOffM) then
            Exit;
          I := I + 3;
        end
        else if (I + 1 <= N) and CharInSet(S[I], ['0'..'9']) then
        begin
          if not DigitosInt(I, 2, LOffM) then
            Exit;
          I := I + 2;
        end;
        if (LOffH > 23) or (LOffM > 59) then
          Exit;
        LOffsetMin := LSinal * (LOffH * 60 + LOffM);
      end
      else
        Exit;
    end;
    if I <= N then
      Exit; // sobrou texto
    if not TryEncodeTime(LHora, LMinuto, LSegundo, LMilissegundo, LHorario) then
      Exit;
    LData := LData + LHorario;
  end;
  AUtc := IncMinute(LData, -LOffsetMin);
  Result := True;
end;

class function TDatas.ParaIso(AUtc: TDateTime): string;
begin
  // literais entre aspas: nada depende das configurações regionais do Windows
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', AUtc);
end;

class function TDatas.UtcParaLocal(AUtc: TDateTime): TDateTime;
begin
  if AUtc = 0 then
    Exit(0);
  Result := TTimeZone.Local.ToLocalTime(AUtc);
end;

class function TDatas.LocalParaUtc(ALocal: TDateTime): TDateTime;
begin
  if ALocal = 0 then
    Exit(0);
  Result := TTimeZone.Local.ToUniversalTime(ALocal);
end;

class function TDatas.AgoraUtc: TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(Now);
end;

{ TLeitorJson }

constructor TLeitorJson.Create(AObjeto: TJSONObject);
begin
  FObjeto := AObjeto;
end;

function TLeitorJson.Valor(const ACampo: string): TJSONValue;
begin
  if not Assigned(FObjeto) then
    Exit(nil);
  Result := FObjeto.GetValue(ACampo);
  if Assigned(Result) and Result.Null then
    Result := nil;
end;

function TLeitorJson.Tem(const ACampo: string): Boolean;
begin
  Result := Assigned(Valor(ACampo));
end;

function TLeitorJson.Texto(const ACampo, APadrao: string): string;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if V is TJSONString then // inclui TJSONNumber (herda de TJSONString)
    Result := V.Value
  else if V is TJSONBool then
    Result := V.Value
  else
    Result := APadrao;
end;

function TLeitorJson.Inteiro(const ACampo: string; APadrao: Int64): Int64;
begin
  if not TJson.ComoInteiro(Valor(ACampo), Result) then
    Result := APadrao;
end;

function TLeitorJson.Numero(const ACampo: string; APadrao: Double): Double;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if V is TJSONNumber then
    Exit(TJSONNumber(V).AsDouble);
  if not ((V is TJSONString) and TryStrToFloat(V.Value, Result, TFormatSettings.Invariant)) then
    Result := APadrao;
end;

function TLeitorJson.Booleano(const ACampo: string; APadrao: Boolean): Boolean;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if V is TJSONBool then
    Result := TJSONBool(V).AsBoolean
  else if V is TJSONNumber then
    Result := TJSONNumber(V).AsDouble <> 0
  else if V is TJSONString then
    Result := SameText(V.Value, 'true') or (V.Value = '1')
  else
    Result := APadrao;
end;

function TLeitorJson.DataUtc(const ACampo: string): TDateTime;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if (V is TJSONString) and not (V is TJSONNumber) and TDatas.TentarLerIso(V.Value, Result) then
    Exit;
  Result := 0;
end;

function TLeitorJson.Objeto(const ACampo: string): TJSONObject;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if V is TJSONObject then
    Result := TJSONObject(V)
  else
    Result := nil;
end;

function TLeitorJson.Lista(const ACampo: string): TJSONArray;
var
  V: TJSONValue;
begin
  V := Valor(ACampo);
  if V is TJSONArray then
    Result := TJSONArray(V)
  else
    Result := nil;
end;

function TLeitorJson.Inteiros(const ACampo: string): TArray<Int64>;
var
  L: TJSONArray;
  I: Integer;
  X: Int64;
begin
  Result := nil;
  L := Lista(ACampo);
  if not Assigned(L) then
    Exit;
  for I := 0 to L.Count - 1 do
    if TJson.ComoInteiro(L.Items[I], X) then
      Result := Result + [X];
end;

function TLeitorJson.Textos(const ACampo: string): TArray<string>;
var
  L: TJSONArray;
  I: Integer;
begin
  Result := nil;
  L := Lista(ACampo);
  if not Assigned(L) then
    Exit;
  for I := 0 to L.Count - 1 do
    if L.Items[I] is TJSONString then
      Result := Result + [L.Items[I].Value];
end;

{ TJson }

class function TJson.LerObjeto(const ATexto: string): TJSONObject;
var
  V: TJSONValue;
begin
  V := TJSONObject.ParseJSONValue(ATexto);
  if V is TJSONObject then
    Exit(TJSONObject(V));
  V.Free;
  raise EContratoInvalido.Create(SJsonInvalido);
end;

class function TJson.LerLista(const ATexto: string): TJSONArray;
var
  V: TJSONValue;
begin
  V := TJSONObject.ParseJSONValue(ATexto);
  if V is TJSONArray then
    Exit(TJSONArray(V));
  V.Free;
  raise EContratoInvalido.Create(SJsonInvalido);
end;

class function TJson.ComoInteiro(AValor: TJSONValue; out AInteiro: Int64): Boolean;
var
  D: Double;
begin
  AInteiro := 0;
  if not Assigned(AValor) or AValor.Null then
    Exit(False);
  if AValor is TJSONNumber then
  begin
    // AsInt64 lê o texto do número; um "12.0" também precisa virar 12
    if TryStrToInt64(AValor.Value, AInteiro) then
      Exit(True);
    D := TJSONNumber(AValor).AsDouble;
    if (Frac(D) = 0) and (Abs(D) < 9.0E18) then
    begin
      AInteiro := Trunc(D);
      Exit(True);
    end;
    Exit(False);
  end;
  if AValor is TJSONString then
    Exit(TryStrToInt64(Trim(AValor.Value), AInteiro));
  Result := False;
end;

class function TJson.ListaDeInteiros(const AValores: array of Int64): TJSONArray;
var
  V: Int64;
begin
  Result := TJSONArray.Create;
  for V in AValores do
    Result.Add(V);
end;

end.
