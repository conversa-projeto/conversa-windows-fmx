unit Conversa.Infra.Http;

{ Transporte HTTP cru (FC-107, D8). A regra de negócio (erros com o campo "error", 401, repetição) fica em
  Conversa.Infra.Api, que fala com um ITransporteHttp: nos testes, um falso; no app, TTransporteHttpNet.

  TTransporteHttpNet usa THTTPClient (WinHTTP/SChannel): o certificado é validado pelo repositório do Windows,
  sem revogação (o WinHTTP não confere por padrão). NUNCA aceitar qualquer certificado (FC-106). }

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  System.Net.HttpClient;

type
  {$SCOPEDENUMS ON}
  TMetodoHttp = (Get, Post, Put, Patch, Delete);
  TFalhaDeConexao = (SemConexao, Tempo, Certificado, Outra);
  {$SCOPEDENUMS OFF}

  TCabecalho = record
    Nome: string;
    Valor: string;
    constructor Create(const ANome, AValor: string);
  end;

  TPedidoHttp = record
    Metodo: TMetodoHttp;
    Url: string;
    Cabecalhos: TArray<TCabecalho>;
    /// <summary>Texto do corpo (JSON), enviado em UTF-8. Vazio = sem corpo.</summary>
    Corpo: string;
  end;

  TRespostaHttp = record
    Status: Integer;
    /// <summary>Corpo decodificado como UTF-8.</summary>
    Corpo: string;
    TipoConteudo: string;
  end;

  /// <summary>Falha antes de existir uma resposta HTTP: rede, DNS, TLS ou tempo esgotado.</summary>
  EFalhaDeConexao = class(Exception)
  private
    FTipo: TFalhaDeConexao;
  public
    constructor Create(ATipo: TFalhaDeConexao; const AMensagem: string);
    property Tipo: TFalhaDeConexao read FTipo;
  end;

  ITransporteHttp = interface
    ['{AD28D03D-5328-4B82-9DA7-CB1D1EC6F9BB}']
    function Enviar(const APedido: TPedidoHttp): TRespostaHttp;
  end;

  /// <summary>
  ///   THTTPClient com um pequeno conjunto de clientes reaproveitados (cada um mantém a conexão aberta com o
  ///   servidor). Seguro para chamar de várias threads: cada chamada usa um cliente só seu.
  /// </summary>
  TTransporteHttpNet = class(TInterfacedObject, ITransporteHttp)
  private
    FTrava: TCriticalSection;
    FLivres: TStack<THTTPClient>;
    FAgente: string;
    FTempoConexaoMs: Integer;
    FTempoRespostaMs: Integer;
    function Pegar: THTTPClient;
    procedure Devolver(ACliente: THTTPClient);
  public
    constructor Create(const AAgente: string; ATempoConexaoMs: Integer = 10000; ATempoRespostaMs: Integer = 30000);
    destructor Destroy; override;
    function Enviar(const APedido: TPedidoHttp): TRespostaHttp;
    /// <summary>Classifica a mensagem de erro do WinHTTP (exposto para teste).</summary>
    class function ClassificarFalha(const AMensagem: string; AEhCertificado: Boolean): TFalhaDeConexao; static;
  end;

const
  NOMES_METODO: array[TMetodoHttp] of string = ('GET', 'POST', 'PUT', 'PATCH', 'DELETE');
  MAXIMO_CLIENTES_LIVRES = 6;

implementation

uses
  System.Classes,
  System.Net.URLClient;

{ TCabecalho }

constructor TCabecalho.Create(const ANome, AValor: string);
begin
  Nome := ANome;
  Valor := AValor;
end;

{ EFalhaDeConexao }

constructor EFalhaDeConexao.Create(ATipo: TFalhaDeConexao; const AMensagem: string);
begin
  inherited Create(AMensagem);
  FTipo := ATipo;
end;

{ TTransporteHttpNet }

constructor TTransporteHttpNet.Create(const AAgente: string; ATempoConexaoMs, ATempoRespostaMs: Integer);
begin
  inherited Create;
  FTrava := TCriticalSection.Create;
  FLivres := TStack<THTTPClient>.Create;
  FAgente := AAgente;
  FTempoConexaoMs := ATempoConexaoMs;
  FTempoRespostaMs := ATempoRespostaMs;
end;

destructor TTransporteHttpNet.Destroy;
begin
  if Assigned(FLivres) then
    while FLivres.Count > 0 do
      FLivres.Pop.Free;
  FLivres.Free;
  FTrava.Free;
  inherited;
end;

function TTransporteHttpNet.Pegar: THTTPClient;
begin
  Result := nil;
  FTrava.Enter;
  try
    if FLivres.Count > 0 then
      Result := FLivres.Pop;
  finally
    FTrava.Leave;
  end;
  if Assigned(Result) then
    Exit;
  Result := THTTPClient.Create;
  Result.ConnectionTimeout := FTempoConexaoMs;
  Result.SendTimeout := FTempoRespostaMs;
  Result.ResponseTimeout := FTempoRespostaMs;
  // A API nunca redireciona; seguir um 3xx poderia levar o token para outro endereço.
  Result.HandleRedirects := False;
  Result.UserAgent := FAgente;
  Result.Accept := 'application/json';
  Result.AcceptCharSet := 'utf-8';
end;

procedure TTransporteHttpNet.Devolver(ACliente: THTTPClient);
begin
  FTrava.Enter;
  try
    if FLivres.Count < MAXIMO_CLIENTES_LIVRES then
    begin
      FLivres.Push(ACliente);
      ACliente := nil;
    end;
  finally
    FTrava.Leave;
  end;
  ACliente.Free;
end;

class function TTransporteHttpNet.ClassificarFalha(const AMensagem: string; AEhCertificado: Boolean): TFalhaDeConexao;
begin
  // Códigos do WinHTTP que aparecem entre parênteses na mensagem da RTL
  if AEhCertificado or AMensagem.Contains('(12175)') or AMensagem.Contains('(12045)') or
     AMensagem.Contains('(12037)') or AMensagem.Contains('(12038)') or AMensagem.Contains('(12044)') then
    Result := TFalhaDeConexao.Certificado
  else if AMensagem.Contains('(12002)') then
    Result := TFalhaDeConexao.Tempo
  else if AMensagem.Contains('(12007)') or AMensagem.Contains('(12029)') or AMensagem.Contains('(12030)') or
          AMensagem.Contains('(12031)') or AMensagem.Contains('(12152)') then
    Result := TFalhaDeConexao.SemConexao
  else
    Result := TFalhaDeConexao.Outra;
end;

function TTransporteHttpNet.Enviar(const APedido: TPedidoHttp): TRespostaHttp;
var
  LCliente: THTTPClient;
  LPedido: IHTTPRequest;
  LResposta: IHTTPResponse;
  LCorpo: TBytesStream;
  LCabecalho: TCabecalho;
begin
  Result := Default(TRespostaHttp);
  LCorpo := nil;
  LCliente := Pegar;
  try
    try
      LPedido := LCliente.GetRequest(NOMES_METODO[APedido.Metodo], TURI.Create(APedido.Url));
      for LCabecalho in APedido.Cabecalhos do
        LPedido.SetHeaderValue(LCabecalho.Nome, LCabecalho.Valor);
      if APedido.Corpo <> '' then
      begin
        LCorpo := TBytesStream.Create(TEncoding.UTF8.GetBytes(APedido.Corpo));
        LPedido.SetHeaderValue('Content-Type', 'application/json; charset=utf-8');
        LPedido.SourceStream := LCorpo;
      end;
      LResposta := LCliente.Execute(LPedido);
      Result.Status := LResposta.StatusCode;
      Result.TipoConteudo := LResposta.HeaderValue['Content-Type'];
      Result.Corpo := LResposta.ContentAsString(TEncoding.UTF8);
    except
      on E: ENetHTTPCertificateException do
        raise EFalhaDeConexao.Create(TFalhaDeConexao.Certificado, E.Message);
      on E: ENetException do
        raise EFalhaDeConexao.Create(ClassificarFalha(E.Message, False), E.Message);
    end;
  finally
    LPedido := nil;
    LResposta := nil;
    LCorpo.Free;
    Devolver(LCliente);
  end;
end;

end.
