// Eduardo - 03/03/2024
program Conversa;

uses
  MidasLib,
  System.StartUpCopy,
  FMX.Forms,
  Conversa.Principal in 'Conversa.Principal.pas' {Principal},
  Conversa.Login in 'Conversa.Login.pas' {Login: TFrame},
  Conversa.Dados in 'Conversa.Dados.pas' {Dados: TDataModule},
  REST.API in 'REST.API.pas',
  Mensagem.Anexo in 'Mensagem.Anexo.pas',
  Mensagem.Editor in 'Mensagem.Editor.pas',
  Mensagem.Tipos in 'Mensagem.Tipos.pas',
  Mensagem.Visualizador in 'Mensagem.Visualizador.pas',
  Conversa.Conteudo in 'Conversa.Conteudo.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TDados, Dados);
  Application.CreateForm(TPrincipal, Principal);
  Application.Run;
end.
