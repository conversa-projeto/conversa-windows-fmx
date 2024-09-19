// Eduardo - 18/09/2024
unit Conversa.Inicializacoes;

interface

procedure Iniciar;
procedure Finalizar;

implementation

uses
  System.SysUtils,
  PascalStyleScript,
  Conversa.Windows.Utils,
  Conversa.Configuracoes,
  Conversa.Notificacao,
  Conversa.Windows.UserActivity,
  Conversa.Windows.Overlay,
  Conversa.Log;

procedure Iniciar;
begin
  DefinirDiretorio;

  ReportMemoryLeaksOnShutdown := True;

  {$IFNDEF DEBUG}
  if IsApplicationAlreadyRunning then
    Exit;

  if ParamStr(1) <> '-inicializar' then
    InicializarComSO
  else
    Sleep(10_000);
  {$ENDIF}

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
