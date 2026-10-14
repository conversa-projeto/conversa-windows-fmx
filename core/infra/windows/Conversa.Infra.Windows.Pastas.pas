unit Conversa.Infra.Windows.Pastas;

{ Onde o app guarda cada coisa (#68, #92): nada na pasta do executável.
  - %APPDATA%\Conversa        configuração que acompanha o perfil do usuário (servidor, preferências);
  - %LOCALAPPDATA%\Conversa   dados da máquina: logs e, por usuário do Conversa, banco e cache. }

interface

type
  TPastas = record
    /// <summary>%LOCALAPPDATA%\Conversa</summary>
    class function DadosLocais: string; static;
    /// <summary>%APPDATA%\Conversa</summary>
    class function Configuracao: string; static;
    /// <summary>%LOCALAPPDATA%\Conversa\logs</summary>
    class function Logs: string; static;
    /// <summary>%LOCALAPPDATA%\Conversa\u&lt;id&gt; (banco e cache de um usuário do Conversa)</summary>
    class function DoUsuario(AUsuarioId: Int64): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

const
  NOME_APP = 'Conversa';

resourcestring
  SPastaDoWindowsIndisponivel = 'O Windows não informou a pasta de dados do usuário.';

// Sem a pasta do Windows, o resultado viraria o caminho relativo "Conversa" (dados na pasta atual): melhor falhar.
function ExigirPasta(const ABase: string): string;
begin
  if Trim(ABase) = '' then
    raise EInOutError.Create(SPastaDoWindowsIndisponivel);
  Result := TPath.Combine(ABase, NOME_APP);
end;

class function TPastas.DadosLocais: string;
begin
  // TPath.GetCachePath = CSIDL_LOCAL_APPDATA no Windows ('' se o SHGetFolderPath falhar)
  Result := ExigirPasta(TPath.GetCachePath);
end;

class function TPastas.Configuracao: string;
begin
  // TPath.GetHomePath = CSIDL_APPDATA (perfil móvel) no Windows ('' se falhar)
  Result := ExigirPasta(TPath.GetHomePath);
end;

class function TPastas.Logs: string;
begin
  Result := TPath.Combine(DadosLocais, 'logs');
end;

class function TPastas.DoUsuario(AUsuarioId: Int64): string;
begin
  if AUsuarioId <= 0 then
    raise EArgumentException.Create('Identificador de usuário inválido para a pasta de dados.');
  Result := TPath.Combine(DadosLocais, 'u' + IntToStr(AUsuarioId));
end;

end.
