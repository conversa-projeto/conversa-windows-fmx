// Daniel - 2024-08-20
unit Conversa.Windows.UserActivity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Messaging,
  FMX.Forms,
  Winapi.Windows,
  Conversa.Eventos;

type
  TStatusUsuarioSO = (Desconhecido, Ativo, Inativo);

procedure IniciarMonitoramento;
procedure FinalizarMonitoramento;

var
  StatusUsuarioSO: TStatusUsuarioSO;

implementation

var
  MonitorTask: ITask;
  MonitoramentoAtivo: Boolean = False;
  ThreadStatusUsuarioSO: TStatusUsuarioSO;

const
  SleepInterval = 100;           // Intervalo de monitoramento (em milissegundos)
  InactiveThreshold = 1000;       // Tempo para considerar o usuário inativo (em milissegundos)
  ActiveThreshold = 1000;         // Tempo para considerar o usuário ativo novamente (em milissegundos)

procedure MonitorActivity;
var
  LastInputInfo: TLastInputInfo;
  IdleTime, CurrentTime: DWORD;
begin
  LastInputInfo.cbSize := SizeOf(TLastInputInfo);

  // Obtém a última entrada do usuário
  if GetLastInputInfo(LastInputInfo) then
  begin
    CurrentTime := GetTickCount;
    IdleTime := CurrentTime - LastInputInfo.dwTime;

    if (IdleTime >= InactiveThreshold) and (ThreadStatusUsuarioSO <> TStatusUsuarioSO.Inativo) then
    begin
      try
        TThread.Synchronize(
          nil,
          procedure
          begin
            StatusUsuarioSO := TStatusUsuarioSO.Inativo;
            TMessageManager.DefaultManager.SendMessage(nil, TEventoMudancaStatusUsuarioSO.Create(0));
          end
        );
        ThreadStatusUsuarioSO := TStatusUsuarioSO.Inativo;
      except
      end;
    end
    // Verifica se o usuário voltou a ficar ativo
    else
    if (IdleTime <= ActiveThreshold) and (ThreadStatusUsuarioSO <> TStatusUsuarioSO.Ativo)  then
    begin
      try
        TThread.Synchronize(
          nil,
          procedure
          begin
            StatusUsuarioSO := TStatusUsuarioSO.Ativo;
            TMessageManager.DefaultManager.SendMessage(nil, TEventoMudancaStatusUsuarioSO.Create(0));
          end
        );
        ThreadStatusUsuarioSO := TStatusUsuarioSO.Ativo;
      except
      end;
    end;
  end;
end;

procedure IniciarMonitoramento;
begin
  if MonitoramentoAtivo then
    Exit;

  MonitoramentoAtivo := True;

  MonitorTask := TTask.Run(
    procedure
    begin
      Sleep(1000); // Aguarda 1 Segundo para ativar o ApplicationState
      while MonitoramentoAtivo and (ApplicationState = TApplicationState.Running) do
      begin
        MonitorActivity;
        TThread.Sleep(SleepInterval);
      end;
    end
  );
end;

procedure FinalizarMonitoramento;
begin
  MonitoramentoAtivo := False;
  if Assigned(MonitorTask) then
    MonitorTask.Wait;
end;

end.

