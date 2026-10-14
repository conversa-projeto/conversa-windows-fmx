program ConversaTestes;

{ Testes da nova base (DUnitX, console Win64). Rodar sem argumentos executa tudo; o código de saída é 1 se
  algum teste falhar (o build\testar.cmd depende disso). }

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  Conversa.Infra.Log in '..\core\infra\log\Conversa.Infra.Log.pas',
  Conversa.Eventos.Barramento in '..\core\eventos\Conversa.Eventos.Barramento.pas',
  Conversa.Eventos.Tipos in '..\core\eventos\Conversa.Eventos.Tipos.pas',
  Conversa.Dominio.Endereco in '..\core\dominio\Conversa.Dominio.Endereco.pas',
  Conversa.Infra.Http in '..\core\infra\http\Conversa.Infra.Http.pas',
  Conversa.Infra.Api in '..\core\infra\http\Conversa.Infra.Api.pas',
  Conversa.Contrato.Json in '..\core\contrato\Conversa.Contrato.Json.pas',
  Conversa.Dominio.Modelos in '..\core\dominio\Conversa.Dominio.Modelos.pas',
  Conversa.Dominio.Chamadas in '..\core\dominio\Conversa.Dominio.Chamadas.pas',
  Conversa.Dominio.Anexos in '..\core\dominio\Conversa.Dominio.Anexos.pas',
  Conversa.Dominio.Enquetes in '..\core\dominio\Conversa.Dominio.Enquetes.pas',
  Conversa.Dominio.Sistema in '..\core\dominio\Conversa.Dominio.Sistema.pas',
  Conversa.Contrato.Mapeadores in '..\core\contrato\Conversa.Contrato.Mapeadores.pas',
  Conversa.Testes.Log in 'Conversa.Testes.Log.pas',
  Conversa.Testes.Barramento in 'Conversa.Testes.Barramento.pas',
  Conversa.Testes.Endereco in 'Conversa.Testes.Endereco.pas',
  Conversa.Testes.Api in 'Conversa.Testes.Api.pas',
  Conversa.Testes.Json in 'Conversa.Testes.Json.pas',
  Conversa.Testes.Fixtures in 'Conversa.Testes.Fixtures.pas',
  Conversa.Testes.Mapeadores in 'Conversa.Testes.Mapeadores.pas';

var
  Executor: ITestRunner;
  Resultados: IRunResults;
  RegistroConsole: ITestLogger;
  RegistroXml: ITestLogger;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    TDUnitX.CheckCommandLine;
    Executor := TDUnitX.CreateRunner;
    Executor.UseRTTI := True;
    Executor.FailsOnNoAsserts := True;
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      RegistroConsole := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      Executor.AddLogger(RegistroConsole);
    end;
    RegistroXml := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Executor.AddLogger(RegistroXml);
    RegistroConsole := nil;
    RegistroXml := nil;

    Resultados := Executor.Execute;
    Executor := nil;
    if not Resultados.AllPassed then
      System.ExitCode := EXIT_ERRORS;
    Resultados := nil;

    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Fim. Tecle <Enter> para sair.');
      System.Readln;
    end;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
end.
