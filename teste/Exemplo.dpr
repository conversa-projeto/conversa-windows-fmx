// Eduardo/Daniel - 17/05/2025
program Exemplo;

uses
  Vcl.Forms,
  Exemplo.Principal in 'Exemplo.Principal.pas' {Principal},
  Conversa.Evento.Base in 'Conversa.Evento.Base.pas',
  Conversa.Eventos in 'Conversa.Eventos.pas',
  REST.API in 'REST.API.pas',
  Conversa.Proxy in 'Conversa.Proxy.pas',
  Conversa.Proxy.Tipos in 'Conversa.Proxy.Tipos.pas',
  GenericSocket.Client in 'socket\GenericSocket.Client.pas',
  GenericSocket.Interfaces in 'socket\GenericSocket.Interfaces.pas',
  GenericSocket.Message in 'socket\GenericSocket.Message.pas',
  GenericSocket in 'socket\GenericSocket.pas',
  GenericSocket.Server in 'socket\GenericSocket.Server.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPrincipal, Principal);
  Application.Run;
end.
