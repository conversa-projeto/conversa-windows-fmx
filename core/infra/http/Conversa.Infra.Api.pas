unit Conversa.Infra.Api;

{ Cliente da API do Conversa (FC-107; doc 01 §2–§3; D8 do doc 07).

  - Todo erro do servidor é um JSON com o campo "error"; o nginx responde HTML (503 no limite de login, 413 com
    corpo acima de 1 MB, 502/504 com a API fora).
  - 401 numa rota protegida = sessão vencida: publica TEventoSessaoExpirada e lança ESessaoExpirada.
    Rotas públicas (login, cadastro) usam EnviarPublico: sem token, e o 401 é só um erro ("Senha incorreta!").
  - Repetição com espera só em GET (Obter), em falha de rede ou 502/503/504.
  - O token só vai para <endereço>/api/ (as URLs assinadas do MinIO usam outro caminho, sem token).
  - O log registra método, caminho (sem a consulta, que pode ter texto do usuário), status e tempo. Nunca o
    corpo nem o token. }

interface

uses
  System.SysUtils,
  Conversa.Infra.Http,
  Conversa.Infra.Log,
  Conversa.Eventos.Barramento,
  Conversa.Dominio.Endereco;

type
  TParametro = record
    Nome: string;
    Valor: string;
    class function Texto(const ANome, AValor: string): TParametro; static;
    class function Numero(const ANome: string; AValor: Int64): TParametro; static;
  end;

  /// <summary>Erro devolvido pelo servidor (status HTTP + mensagem pronta para a tela).</summary>
  EApiErro = class(Exception)
  private
    FStatus: Integer;
  public
    constructor Create(AStatus: Integer; const AMensagem: string);
    property Status: Integer read FStatus;
  end;
  ESessaoExpirada = class(EApiErro);
  EServidorIndisponivel = class(EApiErro);
  EMuitasTentativas = class(EApiErro);
  EArquivoGrandeDemais = class(EApiErro);

  /// <summary>De onde a API tira o endereço e o token a cada chamada (os dois mudam em tempo de execução).</summary>
  IFonteDeSessao = interface
    ['{250DEE33-DD6F-46C6-9220-E390C429DCA8}']
    /// <summary>"https://host/api/" ou vazio (sem servidor configurado)</summary>
    function EnderecoApi: string;
    /// <summary>JWT atual ou vazio (sem sessão)</summary>
    function Token: string;
  end;

  IConversaApi = interface
    ['{12580890-B769-42B3-B4D3-626C6280D729}']
    /// <summary>GET numa rota protegida; devolve o corpo (JSON). Repete em falha de rede e 502/503/504.</summary>
    function Obter(const ARota: string; const AParametros: array of TParametro): string;
    /// <summary>POST/PUT/PATCH/DELETE numa rota protegida, com corpo JSON (pode ser vazio). Não repete.</summary>
    function Enviar(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string; const AParametros: array of TParametro): string;
    /// <summary>Rota pública (login, cadastro): sem token; 401 não é "sessão expirada". Não repete.</summary>
    function EnviarPublico(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string; const AParametros: array of TParametro): string;
  end;

  TConversaApi = class(TInterfacedObject, IConversaApi)
  private
    FTransporte: ITransporteHttp;
    FSessao: IFonteDeSessao;
    FBarramento: TBarramento;
    FLogger: ILogger;
    FEsperasMs: TArray<Integer>;
    function MontarUrl(const ARota: string; const AParametros: array of TParametro): string;
    function Executar(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string; const AParametros: array of TParametro;
      AProtegida, APodeRepetir: Boolean): string;
    procedure TratarErro(AMetodo: TMetodoHttp; const ARota: string; const AResposta: TRespostaHttp; AProtegida: Boolean);
  public
    /// <summary>ABarramento e ALogger podem ser nil (testes).</summary>
    constructor Create(const ATransporte: ITransporteHttp; const ASessao: IFonteDeSessao; ABarramento: TBarramento;
      const ALogger: ILogger);
    function Obter(const ARota: string; const AParametros: array of TParametro): string;
    function Enviar(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string; const AParametros: array of TParametro): string;
    function EnviarPublico(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string; const AParametros: array of TParametro): string;
    /// <summary>Mensagem do {"error": ...}; vazio se o corpo não for esse JSON.</summary>
    class function ExtrairMensagemDeErro(const ACorpo: string): string; static;
    class function PareceHtml(const AResposta: TRespostaHttp): Boolean; static;
    class function MensagemDeFalha(ATipo: TFalhaDeConexao): string; static;
    /// <summary>Esperas entre as repetições do GET (padrão 500 ms e 1500 ms; os testes zeram).</summary>
    property EsperasMs: TArray<Integer> read FEsperasMs write FEsperasMs;
  end;

  {$SCOPEDENUMS ON}
  TResultadoTesteServidor = (Ok, CertificadoNaoConfiavel, Inacessivel, Tempo, NaoEhConversa);
  {$SCOPEDENUMS OFF}

  /// <summary>"Testar conexão" da tela Servidor (doc 07 §3.1).</summary>
  TTesteDeServidor = record
    /// <summary>Uma rota protegida chamada sem token tem de responder 401 com {"error": ...}.</summary>
    class function Testar(const ATransporte: ITransporteHttp; const AEndereco: TEnderecoServidor): TResultadoTesteServidor; static;
    class function Mensagem(AResultado: TResultadoTesteServidor): string; static;
  end;

resourcestring
  SSessaoExpirada = 'Sua sessão expirou. Entre novamente.';
  SServidorIndisponivel = 'Servidor indisponível. Tente de novo em instantes.';
  SMuitasTentativas = 'Muitas tentativas. Aguarde um minuto e tente de novo.';
  SArquivoGrandeDemais = 'Arquivo grande demais.';
  SRespostaInesperada = 'Resposta inesperada do servidor (HTTP %d).';
  SSemServidor = 'Nenhum servidor configurado.';
  SFalhaSemConexao = 'Sem conexão com o servidor.';
  SFalhaTempo = 'O servidor demorou para responder.';
  SFalhaCertificado = 'O certificado do servidor não é confiável.';
  SFalhaOutra = 'Não foi possível falar com o servidor.';
  STesteOk = 'Conectado ao servidor Conversa.';
  STesteCertificado = 'O certificado do servidor não é confiável. Em desenvolvimento, instale a CA do mkcert ' +
    '(docs/desenvolvimento/servidor-de-dev.md).';
  STesteInacessivel = 'Servidor inacessível. Confira o endereço e a rede.';
  STesteTempo = 'O servidor não respondeu a tempo.';
  STesteNaoEhConversa = 'Esse endereço responde, mas não é um servidor Conversa.';

implementation

uses
  System.JSON,
  System.NetEncoding,
  System.Diagnostics,
  Conversa.Eventos.Tipos;

{ TParametro }

class function TParametro.Texto(const ANome, AValor: string): TParametro;
begin
  Result.Nome := ANome;
  Result.Valor := AValor;
end;

class function TParametro.Numero(const ANome: string; AValor: Int64): TParametro;
begin
  Result.Nome := ANome;
  Result.Valor := IntToStr(AValor);
end;

{ EApiErro }

constructor EApiErro.Create(AStatus: Integer; const AMensagem: string);
begin
  inherited Create(AMensagem);
  FStatus := AStatus;
end;

{ TConversaApi }

constructor TConversaApi.Create(const ATransporte: ITransporteHttp; const ASessao: IFonteDeSessao;
  ABarramento: TBarramento; const ALogger: ILogger);
begin
  inherited Create;
  FTransporte := ATransporte;
  FSessao := ASessao;
  FBarramento := ABarramento;
  FLogger := ALogger;
  FEsperasMs := TArray<Integer>.Create(500, 1500);
end;

function TConversaApi.MontarUrl(const ARota: string; const AParametros: array of TParametro): string;
var
  LBase: string;
  LRota: string;
  I: Integer;
begin
  LBase := FSessao.EnderecoApi;
  if LBase = '' then
    raise EApiErro.Create(0, SSemServidor);
  if not LBase.EndsWith('/') then
    LBase := LBase + '/';
  LRota := ARota;
  while LRota.StartsWith('/') do
    LRota := LRota.Substring(1);
  Result := LBase + LRota;
  for I := 0 to High(AParametros) do
  begin
    if I = 0 then
      Result := Result + '?'
    else
      Result := Result + '&';
    Result := Result + TNetEncoding.URL.Encode(AParametros[I].Nome) + '=' + TNetEncoding.URL.Encode(AParametros[I].Valor);
  end;
end;

class function TConversaApi.ExtrairMensagemDeErro(const ACorpo: string): string;
var
  LJson: TJSONValue;
  LErro: TJSONValue;
begin
  Result := '';
  LJson := TJSONObject.ParseJSONValue(ACorpo);
  if not Assigned(LJson) then
    Exit;
  try
    if LJson is TJSONObject then
    begin
      LErro := TJSONObject(LJson).GetValue('error');
      if Assigned(LErro) and not LErro.Null then
        Result := LErro.Value;
    end;
  finally
    LJson.Free;
  end;
end;

class function TConversaApi.PareceHtml(const AResposta: TRespostaHttp): Boolean;
begin
  Result := AResposta.TipoConteudo.ToLower.Contains('text/html') or AResposta.Corpo.TrimLeft.StartsWith('<');
end;

class function TConversaApi.MensagemDeFalha(ATipo: TFalhaDeConexao): string;
begin
  case ATipo of
    TFalhaDeConexao.SemConexao: Result := SFalhaSemConexao;
    TFalhaDeConexao.Tempo: Result := SFalhaTempo;
    TFalhaDeConexao.Certificado: Result := SFalhaCertificado;
  else
    Result := SFalhaOutra;
  end;
end;

procedure TConversaApi.TratarErro(AMetodo: TMetodoHttp; const ARota: string; const AResposta: TRespostaHttp;
  AProtegida: Boolean);
var
  LMensagem: string;
begin
  if (AResposta.Status = 401) and AProtegida then
  begin
    if Assigned(FBarramento) then
      FBarramento.Publicar<TEventoSessaoExpirada>(TEventoSessaoExpirada.Create(ARota));
    raise ESessaoExpirada.Create(401, SSessaoExpirada);
  end;
  LMensagem := ExtrairMensagemDeErro(AResposta.Corpo);
  if LMensagem <> '' then
    raise EApiErro.Create(AResposta.Status, LMensagem);
  // Sem o JSON da API: é o nginx (HTML; em desenvolvimento, o 502 vem em texto puro — doc 01, pegadinha 54).
  case AResposta.Status of
    413: raise EArquivoGrandeDemais.Create(413, SArquivoGrandeDemais);
    503: raise EMuitasTentativas.Create(503, SMuitasTentativas);
    502, 504: raise EServidorIndisponivel.Create(AResposta.Status, SServidorIndisponivel);
  else
    raise EApiErro.Create(AResposta.Status, Format(SRespostaInesperada, [AResposta.Status]));
  end;
end;

function TConversaApi.Executar(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string;
  const AParametros: array of TParametro; AProtegida, APodeRepetir: Boolean): string;
var
  LPedido: TPedidoHttp;
  LResposta: TRespostaHttp;
  LToken: string;
  LTentativa: Integer;
  LRepetir: Boolean;
  LRelogio: TStopwatch;
begin
  LPedido := Default(TPedidoHttp);
  LPedido.Metodo := AMetodo;
  LPedido.Url := MontarUrl(ARota, AParametros);
  LPedido.Corpo := ACorpoJson;
  if AProtegida then
  begin
    LToken := FSessao.Token;
    if LToken = '' then
    begin
      if Assigned(FBarramento) then
        FBarramento.Publicar<TEventoSessaoExpirada>(TEventoSessaoExpirada.Create(ARota));
      raise ESessaoExpirada.Create(401, SSessaoExpirada);
    end;
    LPedido.Cabecalhos := TArray<TCabecalho>.Create(TCabecalho.Create('Authorization', 'Bearer ' + LToken));
  end;

  LResposta := Default(TRespostaHttp);
  LTentativa := 0;
  LRelogio := TStopwatch.StartNew;
  repeat
    LRepetir := False;
    try
      LResposta := FTransporte.Enviar(LPedido);
    except
      on E: EFalhaDeConexao do
      begin
        if Assigned(FLogger) then
          FLogger.Aviso('Api', NOMES_METODO[AMetodo] + ' /' + ARota + ' falhou: ' + E.Message);
        if APodeRepetir and (LTentativa < Length(FEsperasMs)) and
           (E.Tipo in [TFalhaDeConexao.SemConexao, TFalhaDeConexao.Tempo]) then
          LRepetir := True
        else
          raise EFalhaDeConexao.Create(E.Tipo, MensagemDeFalha(E.Tipo));
      end;
    end;
    if not LRepetir and APodeRepetir and (LTentativa < Length(FEsperasMs)) and
       ((LResposta.Status = 502) or (LResposta.Status = 503) or (LResposta.Status = 504)) then
      LRepetir := True;
    if LRepetir then
    begin
      if FEsperasMs[LTentativa] > 0 then
        Sleep(FEsperasMs[LTentativa]);
      Inc(LTentativa);
    end;
  until not LRepetir;

  if Assigned(FLogger) then
    FLogger.Depuracao('Api', Format('%s /%s -> %d em %d ms', [NOMES_METODO[AMetodo], ARota, LResposta.Status,
      LRelogio.ElapsedMilliseconds]));

  if (LResposta.Status >= 200) and (LResposta.Status < 300) then
    Result := LResposta.Corpo
  else
  begin
    Result := '';
    TratarErro(AMetodo, ARota, LResposta, AProtegida);
  end;
end;

function TConversaApi.Obter(const ARota: string; const AParametros: array of TParametro): string;
begin
  Result := Executar(TMetodoHttp.Get, ARota, '', AParametros, True, True);
end;

function TConversaApi.Enviar(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string;
  const AParametros: array of TParametro): string;
begin
  Result := Executar(AMetodo, ARota, ACorpoJson, AParametros, True, False);
end;

function TConversaApi.EnviarPublico(AMetodo: TMetodoHttp; const ARota, ACorpoJson: string;
  const AParametros: array of TParametro): string;
begin
  Result := Executar(AMetodo, ARota, ACorpoJson, AParametros, False, False);
end;

{ TTesteDeServidor }

class function TTesteDeServidor.Testar(const ATransporte: ITransporteHttp;
  const AEndereco: TEnderecoServidor): TResultadoTesteServidor;
var
  LPedido: TPedidoHttp;
  LResposta: TRespostaHttp;
begin
  LPedido := Default(TPedidoHttp);
  LPedido.Metodo := TMetodoHttp.Get;
  LPedido.Url := AEndereco.Api + 'usuario/permissoes';
  try
    LResposta := ATransporte.Enviar(LPedido);
  except
    on E: EFalhaDeConexao do
      case E.Tipo of
        TFalhaDeConexao.Certificado: Exit(TResultadoTesteServidor.CertificadoNaoConfiavel);
        TFalhaDeConexao.Tempo: Exit(TResultadoTesteServidor.Tempo);
      else
        Exit(TResultadoTesteServidor.Inacessivel);
      end;
  end;
  if (LResposta.Status = 401) and not TConversaApi.PareceHtml(LResposta) and
     (TConversaApi.ExtrairMensagemDeErro(LResposta.Corpo) <> '') then
    Result := TResultadoTesteServidor.Ok
  else
    Result := TResultadoTesteServidor.NaoEhConversa;
end;

class function TTesteDeServidor.Mensagem(AResultado: TResultadoTesteServidor): string;
begin
  case AResultado of
    TResultadoTesteServidor.Ok: Result := STesteOk;
    TResultadoTesteServidor.CertificadoNaoConfiavel: Result := STesteCertificado;
    TResultadoTesteServidor.Inacessivel: Result := STesteInacessivel;
    TResultadoTesteServidor.Tempo: Result := STesteTempo;
  else
    Result := STesteNaoEhConversa;
  end;
end;

end.
