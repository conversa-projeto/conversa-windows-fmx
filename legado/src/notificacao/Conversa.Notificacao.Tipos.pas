unit Conversa.Notificacao.Tipos;

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

type
  TTipoNotificacao = (Mensagem, Chamada);

  TMensagemNotificacao = record
  private
    FID: Integer;
    FUsuario: string;
    FMensagem: string;
  public
    class function New: TMensagemNotificacao; static;
    function ID: String; overload;
    function ID(const Value: Integer): TMensagemNotificacao; overload;
    function Usuario: String; overload;
    function Usuario(const Value: string): TMensagemNotificacao; overload;
    function Mensagem: String; overload;
    function Mensagem(const Value: string): TMensagemNotificacao; overload;
  end;

  TNotificacaoChamadaDados = record
    Nome: String;
    TipoChamada: String;
    Descricao: String;
    OnAtender: TProc<Integer>;
    OnRecusar: TProc<Integer>;
  end;

function GerarChaveNotificacao(ATipo: TTipoNotificacao; AId: Integer): String;

implementation

function GerarChaveNotificacao(ATipo: TTipoNotificacao; AId: Integer): String;
const
  Prefixos: array[TTipoNotificacao] of String = ('MSG_', 'CALL_');
begin
  Result := Prefixos[ATipo] + AId.ToString;
end;

{ TMensagemNotificacao }

class function TMensagemNotificacao.New: TMensagemNotificacao;
begin
  Result := Default(TMensagemNotificacao);
end;

function TMensagemNotificacao.ID: String;
begin
  Result := Self.FUsuario;
end;

function TMensagemNotificacao.ID(const Value: Integer): TMensagemNotificacao;
begin
  Result := Self;
  Result.FID := Value;
end;

function TMensagemNotificacao.Usuario: String;
begin
  Result := Self.FUsuario;
end;

function TMensagemNotificacao.Usuario(const Value: string): TMensagemNotificacao;
begin
  Result := Self;
  Result.FUsuario := Value;
end;

function TMensagemNotificacao.Mensagem: String;
begin
  Result := Self.FMensagem;
end;

function TMensagemNotificacao.Mensagem(const Value: string): TMensagemNotificacao;
begin
  Result := Self;
  Result.FMensagem := Value;
end;

end.
