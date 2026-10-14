unit Conversa.Testes.Json;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesJson = class
  public
    [Test]
    [TestCase('API com Z e ms', '2026-10-06T12:00:00.123Z,2026-10-06 12:00:00.123')]
    [TestCase('tipo 6 sem fuso', '2026-10-06T12:00:05,2026-10-06 12:00:05.000')]
    [TestCase('espaço no lugar do T', '2026-10-06 12:00:05,2026-10-06 12:00:05.000')]
    [TestCase('sem segundos', '2026-10-06T12:00Z,2026-10-06 12:00:00.000')]
    [TestCase('só data', '2026-10-06,2026-10-06 00:00:00.000')]
    [TestCase('offset -03:00', '2026-10-07T09:00:00-03:00,2026-10-07 12:00:00.000')]
    [TestCase('offset +0530', '2026-10-07T09:00:00+0530,2026-10-07 03:30:00.000')]
    [TestCase('offset +02', '2026-10-07T09:00:00+02,2026-10-07 07:00:00.000')]
    [TestCase('6 casas decimais', '2026-10-06T12:00:00.123456Z,2026-10-06 12:00:00.123')]
    [TestCase('1 casa decimal', '2026-10-06T12:00:00.5Z,2026-10-06 12:00:00.500')]
    [TestCase('vira o dia', '2026-12-31T23:30:00-01:00,2027-01-01 00:30:00.000')]
    procedure DataIsoValida(const AEntrada, AEsperadoUtc: string);
    [Test]
    [TestCase('vazia', '')]
    [TestCase('texto', 'ontem')]
    [TestCase('mês 13', '2026-13-01T00:00:00Z')]
    [TestCase('dia 31 em setembro', '2026-09-31')]
    [TestCase('hora 24', '2026-10-06T24:00:00Z')]
    [TestCase('sobra texto', '2026-10-06T12:00:00Zxyz')]
    [TestCase('fuso torto', '2026-10-06T12:00:00+3')]
    [TestCase('separador errado', '2026/10/06')]
    procedure DataIsoInvalida(const AEntrada: string);
    [Test]
    procedure ParaIsoNoFormatoDaApi;
    [Test]
    procedure IdNumeroOuTexto;
    [Test]
    procedure AusenteENullUsamOPadrao;
    [Test]
    procedure BooleanosTolerantes;
    [Test]
    procedure DatasNoLeitor;
    [Test]
    procedure ListasDeInteirosETextos;
    [Test]
    procedure LerObjetoOuListaRecusaOutraCoisa;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  Conversa.Contrato.Json;

function Formatar(AData: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd" "hh":"nn":"ss"."zzz', AData);
end;

procedure TTestesJson.DataIsoValida(const AEntrada, AEsperadoUtc: string);
var
  LData: TDateTime;
begin
  Assert.IsTrue(TDatas.TentarLerIso(AEntrada, LData), 'deveria aceitar: ' + AEntrada);
  Assert.AreEqual(AEsperadoUtc, Formatar(LData));
end;

procedure TTestesJson.DataIsoInvalida(const AEntrada: string);
var
  LData: TDateTime;
begin
  Assert.IsFalse(TDatas.TentarLerIso(AEntrada, LData), 'deveria recusar: ' + AEntrada);
  Assert.IsTrue(LData = 0);
end;

procedure TTestesJson.ParaIsoNoFormatoDaApi;
var
  LData: TDateTime;
begin
  LData := EncodeDateTime(2026, 10, 6, 9, 5, 7, 42);
  Assert.AreEqual('2026-10-06T09:05:07.042Z', TDatas.ParaIso(LData));
  Assert.IsTrue(TDatas.TentarLerIso(TDatas.ParaIso(LData), LData));
  Assert.AreEqual('2026-10-06 09:05:07.042', Formatar(LData));
end;

procedure TTestesJson.IdNumeroOuTexto;
var
  LObj: TJSONObject;
  L: TLeitorJson;
begin
  LObj := TJson.LerObjeto('{"a":5,"b":"7","c":"x","d":12.0,"e":9007199254740993,"f":-3}');
  try
    L := TLeitorJson.Create(LObj);
    Assert.AreEqual(Int64(5), L.Inteiro('a'));
    Assert.AreEqual(Int64(7), L.Inteiro('b'));
    Assert.AreEqual(Int64(-1), L.Inteiro('c', -1));
    Assert.AreEqual(Int64(12), L.Inteiro('d'));
    Assert.AreEqual(Int64(9007199254740993), L.Inteiro('e'));
    Assert.AreEqual(Int64(-3), L.Inteiro('f'));
  finally
    LObj.Free;
  end;
end;

procedure TTestesJson.AusenteENullUsamOPadrao;
var
  LObj: TJSONObject;
  L: TLeitorJson;
begin
  LObj := TJson.LerObjeto('{"nulo":null,"texto":"oi","num":3}');
  try
    L := TLeitorJson.Create(LObj);
    Assert.IsFalse(L.Tem('nulo'));
    Assert.IsFalse(L.Tem('ausente'));
    Assert.IsTrue(L.Tem('texto'));
    Assert.AreEqual('padrão', L.Texto('nulo', 'padrão'));
    Assert.AreEqual('', L.Texto('ausente'));
    Assert.AreEqual('3', L.Texto('num'));
    Assert.AreEqual(Int64(0), L.Inteiro('nulo'));
    Assert.IsNull(L.Objeto('texto'));
    Assert.IsNull(L.Lista('ausente'));
  finally
    LObj.Free;
  end;
end;

procedure TTestesJson.BooleanosTolerantes;
var
  LObj: TJSONObject;
  L: TLeitorJson;
begin
  LObj := TJson.LerObjeto('{"a":true,"b":false,"c":1,"d":0,"e":"true","f":"1","g":"x"}');
  try
    L := TLeitorJson.Create(LObj);
    Assert.IsTrue(L.Booleano('a'));
    Assert.IsFalse(L.Booleano('b', True));
    Assert.IsTrue(L.Booleano('c'));
    Assert.IsFalse(L.Booleano('d', True));
    Assert.IsTrue(L.Booleano('e'));
    Assert.IsTrue(L.Booleano('f'));
    Assert.IsFalse(L.Booleano('g'));
    Assert.IsTrue(L.Booleano('ausente', True));
  finally
    LObj.Free;
  end;
end;

procedure TTestesJson.DatasNoLeitor;
var
  LObj: TJSONObject;
  L: TLeitorJson;
begin
  LObj := TJson.LerObjeto('{"a":"2026-10-06T12:00:00.123Z","b":null,"c":"inválida","d":123}');
  try
    L := TLeitorJson.Create(LObj);
    Assert.AreEqual('2026-10-06 12:00:00.123', Formatar(L.DataUtc('a')));
    Assert.IsTrue(L.DataUtc('b') = 0);
    Assert.IsTrue(L.DataUtc('c') = 0);
    Assert.IsTrue(L.DataUtc('d') = 0);
    Assert.IsTrue(L.DataUtc('ausente') = 0);
  finally
    LObj.Free;
  end;
end;

procedure TTestesJson.ListasDeInteirosETextos;
var
  LObj: TJSONObject;
  L: TLeitorJson;
  LInteiros: TArray<Int64>;
  LTextos: TArray<string>;
begin
  LObj := TJson.LerObjeto('{"ids":[1,"2",null,"x",3],"cods":["parametros",1,"permissoes"]}');
  try
    L := TLeitorJson.Create(LObj);
    LInteiros := L.Inteiros('ids');
    Assert.AreEqual(3, Integer(Length(LInteiros)));
    Assert.AreEqual(Int64(1), LInteiros[0]);
    Assert.AreEqual(Int64(2), LInteiros[1]);
    Assert.AreEqual(Int64(3), LInteiros[2]);
    LTextos := L.Textos('cods');
    // 1 é número: TJSONNumber herda de TJSONString e também vira texto
    Assert.AreEqual(3, Integer(Length(LTextos)));
    Assert.AreEqual('parametros', LTextos[0]);
    Assert.AreEqual('permissoes', LTextos[2]);
  finally
    LObj.Free;
  end;
end;

procedure TTestesJson.LerObjetoOuListaRecusaOutraCoisa;
begin
  Assert.WillRaise(
    procedure
    begin
      TJson.LerObjeto('[1,2]').Free;
    end, EContratoInvalido);
  Assert.WillRaise(
    procedure
    begin
      TJson.LerLista('{"a":1}').Free;
    end, EContratoInvalido);
  Assert.WillRaise(
    procedure
    begin
      TJson.LerObjeto('<html>').Free;
    end, EContratoInvalido);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesJson);

end.
