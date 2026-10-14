unit Conversa.Dominio.Sistema;

{ Permissões, parâmetros do sistema e ramal SIP (doc 01 §13, §14).
  O ramal SIP traz a senha em texto puro: nunca registrar em log nem mostrar sem ação do usuário. }

interface

const
  PERMISSAO_PARAMETROS = 'parametros';
  PERMISSAO_PERMISSOES = 'permissoes';

type
  TPermissao = record
    Codigo: string;
    Descricao: string;
  end;

  TUsuarioPermissoes = record
    Id: Int64;
    Nome: string;
    Login: string;
    Permissoes: TArray<string>;
  end;

  /// <summary>GET /permissoes.</summary>
  TPainelPermissoes = record
    Permissoes: TArray<TPermissao>;
    Usuarios: TArray<TUsuarioPermissoes>;
    /// <summary>Ninguém tem "permissoes": todos podem tudo.</summary>
    ModoAberto: Boolean;
  end;

  /// <summary>GET/PATCH /parametros (a chave privada do Firebase nunca volta: só se está configurada).</summary>
  TParametros = record
    FcmProjectId: string;
    FcmClientEmail: string;
    FcmPrivateKeyConfigurada: Boolean;
    TurnForcarRelay: Boolean;
    TranscritorUrl: string;
    TranscritorIdioma: string;
    GravacaoDias: Integer;
    S3Bucket: string;
  end;

  /// <summary>GET /sip; Existe = False quando o servidor devolve {}.</summary>
  TRamalSip = record
    Existe: Boolean;
    Id: Int64;
    UsuarioId: Int64;
    SipUser: string;
    AuthUser: string;
    SipPassword: string;
    DisplayName: string;
    Domain: string;
    WsServer: string;
    Ativo: Boolean;
  end;

  TListaDePermissoes = record
    class function Contem(const ALista: TArray<string>; const ACodigo: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TListaDePermissoes.Contem(const ALista: TArray<string>; const ACodigo: string): Boolean;
var
  S: string;
begin
  for S in ALista do
    if SameText(S, ACodigo) then
      Exit(True);
  Result := False;
end;

end.
