unit Conversa.Configuracoes;

interface

uses
  Winapi.Windows;

type
  TNotificacao = record
    Timeout: Integer;
  end;

  TConfiguracoes = record
    Host: String;
    Usuario: String;
    Senha: String;
    Notificacoes: TNotificacao;
    Escala: Single;
    DispositivoId: Integer;
    WindowPlacement: TWindowPlacement;
    class procedure Load; static;
    class procedure Save; static;
  end;

var
  Configuracoes: TConfiguracoes;
  PastaDados: String;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON.Serializers;

{ TConfiguracoes }

class procedure TConfiguracoes.Load;
begin
  PastaDados := TPath.Combine(TPath.GetHomePath, 'Conversa') + TPath.DirectorySeparatorChar;
  TDirectory.CreateDirectory(PastaDados);

  if not TFile.Exists(PastaDados +'conversa.json') then
    Exit;

  with TJsonSerializer.Create do
  try
    Populate<TConfiguracoes>(TFile.ReadAllText(PastaDados +'conversa.json'), Configuracoes);
  finally
    Free;
  end;

  if Configuracoes.Notificacoes.Timeout = 0 then
    Configuracoes.Notificacoes.Timeout := 5;
end;

class procedure TConfiguracoes.Save;
begin
  with TJsonSerializer.Create do
  try
    TFile.WriteAllText(PastaDados +'conversa.json', Serialize<TConfiguracoes>(Configuracoes));
  finally
    Free;
  end;
end;

end.
