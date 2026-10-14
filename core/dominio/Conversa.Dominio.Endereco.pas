unit Conversa.Dominio.Endereco;

{ Endereço do servidor (FC-105; doc 07 §3.1; doc 01 §1.2).

  O usuário informa um campo só, "Endereço do servidor" (ex.: https://conversa.empresa.com). Dele derivam:
    - API:       <base>/api/
    - WebSocket: wss://<host>[:porta]/ws/   (barra final obrigatória: /ws recebe 301, que o cliente não segue)
    - mídia:     <base>/webrtc/
  Tolerâncias na entrada: espaços, barra no fim, "/api" ou "/api/" no fim (o app atual pedia o endereço com
  /api), esquema omitido (assume https), porta padrão explícita (:443 em https, :80 em http). }

interface

uses
  System.SysUtils;

type
  EEnderecoInvalido = class(Exception);

  TEnderecoServidor = record
  private
    FEsquema: string; // 'https' ou 'http'
    FHost: string;    // minúsculo; IPv6 entre colchetes
    FPorta: Integer;  // 0 = porta padrão do esquema
    function Autoridade: string;
  public
    /// <summary>Interpreta o que o usuário digitou. Lança EEnderecoInvalido com a mensagem para a tela.</summary>
    class function Interpretar(const ATexto: string): TEnderecoServidor; static;
    class function TentarInterpretar(const ATexto: string; out AEndereco: TEnderecoServidor): Boolean; static;
    /// <summary>"https://host[:porta]" (sem barra no fim): o que se guarda na configuração e se mostra.</summary>
    function Base: string;
    /// <summary>"https://host[:porta]/api/"</summary>
    function Api: string;
    /// <summary>"wss://host[:porta]/ws/" (ou ws:// com http)</summary>
    function WebSocket: string;
    /// <summary>"https://host[:porta]/webrtc/"</summary>
    function WebRtc: string;
    function Host: string;
    /// <summary>Porta efetiva (443/80 quando não informada).</summary>
    function Porta: Integer;
    function Seguro: Boolean;
    function Vazio: Boolean;
  end;

resourcestring
  SEnderecoVazio = 'Informe o endereço do servidor.';
  SEnderecoEsquemaInvalido = 'O endereço deve começar com https:// (ou http://).';
  SEnderecoHostInvalido = 'Endereço do servidor inválido.';
  SEnderecoPortaInvalida = 'Porta inválida no endereço do servidor.';
  SEnderecoComCaminho = 'Informe só o endereço do servidor, sem caminho (ex.: https://conversa.empresa.com).';

implementation

{ TEnderecoServidor }

class function TEnderecoServidor.Interpretar(const ATexto: string): TEnderecoServidor;
var
  LTexto: string;
  LPos: Integer;
  LAutoridade: string;
  LCaminho: string;
  LPortaTexto: string;
  LPortaNum: Integer;
  LFecha: Integer;
  I: Integer;
begin
  Result := Default(TEnderecoServidor);
  LTexto := Trim(ATexto);
  if LTexto = '' then
    raise EEnderecoInvalido.Create(SEnderecoVazio);

  // esquema
  LPos := Pos('://', LTexto);
  if LPos > 0 then
  begin
    Result.FEsquema := LowerCase(Copy(LTexto, 1, LPos - 1));
    LTexto := Copy(LTexto, LPos + 3, MaxInt);
  end
  else
    Result.FEsquema := 'https';
  if (Result.FEsquema <> 'https') and (Result.FEsquema <> 'http') then
    raise EEnderecoInvalido.Create(SEnderecoEsquemaInvalido);

  // consulta e fragmento não fazem sentido aqui
  if (Pos('?', LTexto) > 0) or (Pos('#', LTexto) > 0) then
    raise EEnderecoInvalido.Create(SEnderecoComCaminho);

  // autoridade x caminho
  LPos := Pos('/', LTexto);
  if LPos > 0 then
  begin
    LAutoridade := Copy(LTexto, 1, LPos - 1);
    LCaminho := Copy(LTexto, LPos, MaxInt);
  end
  else
  begin
    LAutoridade := LTexto;
    LCaminho := '';
  end;
  // tolerância: "/", "/api", "/api/" (e repetições de barra no fim)
  while (LCaminho <> '') and (LCaminho[Length(LCaminho)] = '/') do
    Delete(LCaminho, Length(LCaminho), 1);
  if SameText(LCaminho, '/api') then
    LCaminho := '';
  if LCaminho <> '' then
    raise EEnderecoInvalido.Create(SEnderecoComCaminho);
  if (LAutoridade = '') or (Pos('@', LAutoridade) > 0) then
    raise EEnderecoInvalido.Create(SEnderecoHostInvalido);

  // host e porta (IPv6 entre colchetes)
  LPortaTexto := '';
  if LAutoridade[1] = '[' then
  begin
    LFecha := Pos(']', LAutoridade);
    if LFecha = 0 then
      raise EEnderecoInvalido.Create(SEnderecoHostInvalido);
    Result.FHost := LowerCase(Copy(LAutoridade, 1, LFecha));
    if LFecha < Length(LAutoridade) then
    begin
      if LAutoridade[LFecha + 1] <> ':' then
        raise EEnderecoInvalido.Create(SEnderecoHostInvalido);
      LPortaTexto := Copy(LAutoridade, LFecha + 2, MaxInt);
    end;
  end
  else
  begin
    LPos := Pos(':', LAutoridade);
    if LPos > 0 then
    begin
      Result.FHost := LowerCase(Copy(LAutoridade, 1, LPos - 1));
      LPortaTexto := Copy(LAutoridade, LPos + 1, MaxInt);
    end
    else
      Result.FHost := LowerCase(LAutoridade);
    if Result.FHost = '' then
      raise EEnderecoInvalido.Create(SEnderecoHostInvalido);
    for I := 1 to Length(Result.FHost) do
      if not CharInSet(Result.FHost[I], ['a'..'z', '0'..'9', '.', '-', '_']) and (Ord(Result.FHost[I]) < 128) then
        raise EEnderecoInvalido.Create(SEnderecoHostInvalido);
  end;

  if LPortaTexto <> '' then
  begin
    if not TryStrToInt(LPortaTexto, LPortaNum) or (LPortaNum < 1) or (LPortaNum > 65535) then
      raise EEnderecoInvalido.Create(SEnderecoPortaInvalida);
    // porta padrão explícita vira "sem porta", para comparar endereços e não mostrar :443
    if ((Result.FEsquema = 'https') and (LPortaNum = 443)) or ((Result.FEsquema = 'http') and (LPortaNum = 80)) then
      Result.FPorta := 0
    else
      Result.FPorta := LPortaNum;
  end;
end;

class function TEnderecoServidor.TentarInterpretar(const ATexto: string; out AEndereco: TEnderecoServidor): Boolean;
begin
  try
    AEndereco := Interpretar(ATexto);
    Result := True;
  except
    on EEnderecoInvalido do
    begin
      AEndereco := Default(TEnderecoServidor);
      Result := False;
    end;
  end;
end;

function TEnderecoServidor.Autoridade: string;
begin
  Result := FHost;
  if FPorta <> 0 then
    Result := Result + ':' + IntToStr(FPorta);
end;

function TEnderecoServidor.Base: string;
begin
  if Vazio then
    Exit('');
  Result := FEsquema + '://' + Autoridade;
end;

function TEnderecoServidor.Api: string;
begin
  if Vazio then
    Exit('');
  Result := Base + '/api/';
end;

function TEnderecoServidor.WebSocket: string;
begin
  if Vazio then
    Exit('');
  if Seguro then
    Result := 'wss://' + Autoridade + '/ws/'
  else
    Result := 'ws://' + Autoridade + '/ws/';
end;

function TEnderecoServidor.WebRtc: string;
begin
  if Vazio then
    Exit('');
  Result := Base + '/webrtc/';
end;

function TEnderecoServidor.Host: string;
begin
  Result := FHost;
end;

function TEnderecoServidor.Porta: Integer;
begin
  if FPorta <> 0 then
    Result := FPorta
  else if Seguro then
    Result := 443
  else
    Result := 80;
end;

function TEnderecoServidor.Seguro: Boolean;
begin
  Result := FEsquema = 'https';
end;

function TEnderecoServidor.Vazio: Boolean;
begin
  Result := FHost = '';
end;

end.
