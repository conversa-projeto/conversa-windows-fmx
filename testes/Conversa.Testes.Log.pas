unit Conversa.Testes.Log;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesLog = class
  public
    [Test]
    procedure RedacaoTiraOJwt;
    [Test]
    procedure RedacaoTiraOBearer;
    [Test]
    procedure RedacaoTiraSenhaTokenEConteudoDoJson;
    [Test]
    procedure RedacaoTiraOTokenDaUrl;
    [Test]
    procedure RedacaoMantemTextoComum;
    [Test]
    procedure LinhaFormatadaNuncaQuebra;
    [Test]
    procedure NivelMinimoFiltra;
    [Test]
    procedure ErroIncluiAClasseEAMensagemDaExcecao;
    [Test]
    procedure ArquivoRecebeTudoAteODestrutor;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Conversa.Infra.Log;

const
  JWT_DE_EXEMPLO = 'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6MSwibm9tZSI6IkEifQ.c2VncmVkby1hc3NpbmF0dXJh';

{ TTestesLog }

procedure TTestesLog.RedacaoTiraOJwt;
var
  LSaida: string;
begin
  LSaida := TRedacao.Redigir('login ok, token=' + JWT_DE_EXEMPLO + ' fim');
  Assert.DoesNotContain(LSaida, JWT_DE_EXEMPLO);
  Assert.Contains(LSaida, '[token]');
  Assert.Contains(LSaida, 'fim');
end;

procedure TTestesLog.RedacaoTiraOBearer;
var
  LSaida: string;
begin
  LSaida := TRedacao.Redigir('Authorization: Bearer abc.def-123');
  Assert.DoesNotContain(LSaida, 'abc.def-123');
  Assert.Contains(LSaida, 'Bearer [token]');
end;

procedure TTestesLog.RedacaoTiraSenhaTokenEConteudoDoJson;
var
  LSaida: string;
begin
  LSaida := TRedacao.Redigir(
    '{"login":"ana","senha":"segredo \"com aspas\"","token":"abc","conteudo":"oi, tudo bem?","tipo":1}');
  Assert.DoesNotContain(LSaida, 'segredo');
  Assert.DoesNotContain(LSaida, 'abc');
  Assert.DoesNotContain(LSaida, 'tudo bem');
  Assert.Contains(LSaida, '"login":"ana"');
  Assert.Contains(LSaida, '"senha":"[omitido]"');
  Assert.Contains(LSaida, '"tipo":1');
end;

procedure TTestesLog.RedacaoTiraOTokenDaUrl;
var
  LSaida: string;
begin
  LSaida := TRedacao.Redigir('GET /api/x?conversa=3&token=abcdef&b=1');
  Assert.DoesNotContain(LSaida, 'abcdef');
  Assert.Contains(LSaida, 'conversa=3');
  Assert.Contains(LSaida, '&b=1');
end;

procedure TTestesLog.RedacaoMantemTextoComum;
begin
  Assert.AreEqual('Conexão aberta em 25 ms', TRedacao.Redigir('Conexão aberta em 25 ms'));
  Assert.AreEqual('', TRedacao.Redigir(''));
end;

procedure TTestesLog.LinhaFormatadaNuncaQuebra;
var
  LLinha: string;
begin
  LLinha := TLoggerBase.FormatarLinha(EncodeDate(2026, 10, 10), TNivelLog.Aviso, 'Teste', 'um' + sLineBreak + 'dois'#10'três');
  Assert.DoesNotContain(LLinha, #13);
  Assert.DoesNotContain(LLinha, #10);
  Assert.Contains(LLinha, 'AVISO [Teste] um | dois | três');
  Assert.IsTrue(LLinha.StartsWith('2026-10-10 00:00:00.000'), LLinha);
end;

procedure TTestesLog.NivelMinimoFiltra;
var
  LLogger: TLoggerMemoria;
  LRef: ILogger;
begin
  LLogger := TLoggerMemoria.Create(TNivelLog.Aviso);
  LRef := LLogger;
  LRef.Depuracao('T', 'depuração');
  LRef.Info('T', 'informação');
  LRef.Aviso('T', 'aviso');
  LRef.Erro('T', 'erro');
  Assert.AreEqual(2, Integer(Length(LLogger.Linhas)));
  Assert.IsTrue(LLogger.Contem('aviso'));
  Assert.IsTrue(LLogger.Contem('erro'));
  Assert.IsFalse(LLogger.Contem('informação'));
end;

procedure TTestesLog.ErroIncluiAClasseEAMensagemDaExcecao;
var
  LLogger: TLoggerMemoria;
  LRef: ILogger;
  LExcecao: Exception;
begin
  LLogger := TLoggerMemoria.Create;
  LRef := LLogger;
  LExcecao := EArgumentException.Create('valor inválido');
  try
    LRef.Erro('T', 'Falhou', LExcecao);
  finally
    LExcecao.Free;
  end;
  Assert.IsTrue(LLogger.Contem('Falhou — EArgumentException: valor inválido'), String.Join(sLineBreak, LLogger.Linhas));
end;

procedure TTestesLog.ArquivoRecebeTudoAteODestrutor;
var
  LPasta: string;
  LRef: ILogger;
  LArquivos: TArray<string>;
  LTexto: string;
  I: Integer;
begin
  LPasta := TPath.Combine(TPath.GetTempPath, 'conversa-testes-log-' + TGUID.NewGuid.ToString);
  try
    LRef := TLoggerArquivo.Create(LPasta, TNivelLog.Depuracao);
    for I := 1 to 200 do
      LRef.Info('T', 'linha ' + IntToStr(I));
    LRef.Erro('T', '{"senha":"nao-pode-aparecer"}');
    LRef := nil; // o destrutor espera a fila esvaziar

    LArquivos := TDirectory.GetFiles(LPasta, 'conversa-*.log');
    Assert.AreEqual(1, Integer(Length(LArquivos)));
    LTexto := TFile.ReadAllText(LArquivos[0], TEncoding.UTF8);
    Assert.Contains(LTexto, 'linha 1' + sLineBreak);
    Assert.Contains(LTexto, 'linha 200' + sLineBreak);
    Assert.DoesNotContain(LTexto, 'nao-pode-aparecer');
  finally
    if TDirectory.Exists(LPasta) then
      TDirectory.Delete(LPasta, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesLog);

end.
