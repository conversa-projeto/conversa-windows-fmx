// Eduardo - 18/09/2024
unit Conversa.Inicializacoes;

interface

function Iniciar: Boolean;
procedure Finalizar;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  PascalStyleScript,
  Conversa.Windows.Utils,
  Conversa.Configuracoes,
  Conversa.Notificacao,
  Conversa.Windows.UserActivity,
  Conversa.Windows.Overlay,
  Conversa.Log;

function Iniciar: Boolean;
begin
  Result := True;

  {$IFDEF RELEASE}
  if IsApplicationAlreadyRunning then
    Exit(False);
  {$ENDIF}

  DefinirDiretorio;

  ReportMemoryLeaksOnShutdown := True;

  TConfiguracoes.Load;

  TPascalStyleScript.Start;

  AtualizarContadorNotificacao(0, True);
  IniciarMonitoramento;
end;

procedure Finalizar;
begin
  TNotificacaoManager.Finalizar;
  FinalizarMonitoramento;
  AtualizarContadorNotificacao(0, True);
  TPascalStyleScript.Stop;
  PararLog;
end;

end.
