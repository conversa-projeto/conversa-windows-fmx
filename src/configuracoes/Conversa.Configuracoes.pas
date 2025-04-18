unit Conversa.Configuracoes;

interface

uses
  Winapi.Windows,
  System.SysUtils;

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
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.JSON.Serializers;

{ TConfiguracoes }

class procedure TConfiguracoes.Load;
begin
  PastaDados := TPath.GetHomePath + TPath.DirectorySeparatorChar +'Conversa'+ TPath.DirectorySeparatorChar;
  TDirectory.CreateDirectory(PastaDados);

  if not TFile.Exists(PastaDados +'conversa.json') then
    Exit;

  with TStringStream.Create do
  try
    LoadFromFile(PastaDados +'conversa.json');
    with TJsonSerializer.Create do
    try
      Populate<TConfiguracoes>(DataString, Configuracoes);
    finally
      Free;
    end;
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
    with TStringStream.Create(Serialize<TConfiguracoes>(Configuracoes)) do
    try
      SaveToFile(PastaDados +'conversa.json');
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

end.
