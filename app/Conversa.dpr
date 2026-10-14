program Conversa;

{ Cliente Windows do Conversa — nova base (ADR 0001). Só Win64. }

uses
  System.StartUpCopy,
  FMX.Forms,
  Conversa.Infra.Log in '..\core\infra\log\Conversa.Infra.Log.pas',
  Conversa.Eventos.Barramento in '..\core\eventos\Conversa.Eventos.Barramento.pas',
  Conversa.Infra.Windows.Pastas in '..\core\infra\windows\Conversa.Infra.Windows.Pastas.pas',
  Conversa.Infra.Windows.Versao in '..\core\infra\windows\Conversa.Infra.Windows.Versao.pas',
  Conversa.App.Composicao in 'Conversa.App.Composicao.pas',
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
  Conversa.UI.Textos in '..\ui\Conversa.UI.Textos.pas',
  Conversa.UI.Principal in '..\ui\Conversa.UI.Principal.pas' {TelaPrincipal},
  Conversa.UI.Cores in '..\ui\Conversa.UI.Cores.pas';

{$R *.res}

var
  Composicao: TComposicao;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Composicao := TComposicao.Create;
  try
    Application.CreateForm(TTelaPrincipal, TelaPrincipal);
    // No FMX, CreateForm antes do Run só registra a classe; a janela nasce em RealCreateForms
    // (FMX.Forms, TApplication.CreateForm). Criar agora para entregar os serviços antes do Run.
    Application.RealCreateForms;
    TelaPrincipal.Iniciar(Composicao.Logger, Composicao.Barramento);
    Application.Run;
    // A janela só é destruída no fim do processo (DoneApplication), depois da composição: ela solta as
    // referências aos serviços aqui, antes de eles serem liberados.
    TelaPrincipal.Finalizar;
  finally
    Composicao.Free;
  end;
end.
