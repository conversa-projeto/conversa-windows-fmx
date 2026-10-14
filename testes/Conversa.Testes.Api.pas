unit Conversa.Testes.Api;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Conversa.Infra.Http,
  Conversa.Infra.Api,
  Conversa.Eventos.Barramento;

type
  /// <summary>Transporte falso: devolve as respostas programadas, em ordem, e guarda os pedidos.</summary>
  TTransporteFalso = class(TInterfacedObject, ITransporteHttp)
  public type
    TPassoFalso = record
      Resposta: TRespostaHttp;
      Falha: Boolean;
      TipoFalha: TFalhaDeConexao;
    end;
  private
    FPassos: TList<TPassoFalso>;
    FPedidos: TList<TPedidoHttp>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Responder(AStatus: Integer; const ACorpo: string; const ATipoConteudo: string = 'application/json');
    procedure Falhar(ATipo: TFalhaDeConexao);
    function Enviar(const APedido: TPedidoHttp): TRespostaHttp;
    function Pedidos: TArray<TPedidoHttp>;
    function Pedido(AIndice: Integer): TPedidoHttp;
    function QuantidadeDePedidos: Integer;
  end;

  TSessaoFalsa = class(TInterfacedObject, IFonteDeSessao)
  private
    FToken: string;
  public
    constructor Create(const AToken: string);
    function EnderecoApi: string;
    function Token: string;
  end;

  [TestFixture]
  TTestesApi = class
  private
    FTransporte: TTransporteFalso;
    FRefTransporte: ITransporteHttp;
    FBarramento: TBarramento;
    FSessoesExpiradas: Integer;
    FAssinatura: IInterface;
    function NovaApi(const AToken: string = 'tok'): IConversaApi;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;

    [Test]
    procedure SucessoDevolveOCorpoEMandaOToken;
    [Test]
    procedure ParametrosSaoCodificados;
    [Test]
    procedure CorpoComAcentoEEmojiVaiInteiro;
    [Test]
    procedure Status401ProtegidaExpiraASessao;
    [Test]
    procedure Status401PublicaEhSoUmErro;
    [Test]
    procedure SemTokenNemChamaOServidor;
    [Test]
    procedure ErroJsonViraEApiErroComAMensagem;
    [Test]
    procedure ErroSemJsonViraRespostaInesperada;
    [Test]
    procedure Html502NoGetRepeteEDepoisDesiste;
    [Test]
    procedure Texto502DoDesenvolvimentoTambemEhIndisponivel;
    [Test]
    procedure Html502NoPostNaoRepete;
    [Test]
    procedure Html503EhMuitasTentativas;
    [Test]
    procedure Html413EhArquivoGrandeDemais;
    [Test]
    procedure FalhaDeRedeNoGetRepeteERecupera;
    [Test]
    procedure FalhaDeRedeNoPostNaoRepeteEUsaMensagemAmigavel;
    [Test]
    procedure CertificadoNaoRepete;
    [Test]
    procedure ClassificacaoDasFalhasDoWinHttp;
    [Test]
    procedure TesteDeServidorReconheceOConversa;
    [Test]
    procedure TesteDeServidorRecusaHtmlEOutrasRespostas;
    [Test]
    procedure TesteDeServidorCertificado;
  end;

implementation

uses
  Conversa.Dominio.Endereco,
  Conversa.Eventos.Tipos;

{ TTransporteFalso }

constructor TTransporteFalso.Create;
begin
  inherited Create;
  FPassos := TList<TPassoFalso>.Create;
  FPedidos := TList<TPedidoHttp>.Create;
end;

destructor TTransporteFalso.Destroy;
begin
  FPassos.Free;
  FPedidos.Free;
  inherited;
end;

procedure TTransporteFalso.Responder(AStatus: Integer; const ACorpo, ATipoConteudo: string);
var
  LPasso: TPassoFalso;
begin
  LPasso := Default(TPassoFalso);
  LPasso.Resposta.Status := AStatus;
  LPasso.Resposta.Corpo := ACorpo;
  LPasso.Resposta.TipoConteudo := ATipoConteudo;
  FPassos.Add(LPasso);
end;

procedure TTransporteFalso.Falhar(ATipo: TFalhaDeConexao);
var
  LPasso: TPassoFalso;
begin
  LPasso := Default(TPassoFalso);
  LPasso.Falha := True;
  LPasso.TipoFalha := ATipo;
  FPassos.Add(LPasso);
end;

function TTransporteFalso.Enviar(const APedido: TPedidoHttp): TRespostaHttp;
var
  LPasso: TPassoFalso;
begin
  FPedidos.Add(APedido);
  if FPassos.Count = 0 then
    raise EInvalidOpException.Create('Transporte falso sem resposta programada');
  LPasso := FPassos[0];
  FPassos.Delete(0);
  if LPasso.Falha then
    raise EFalhaDeConexao.Create(LPasso.TipoFalha, 'falha simulada (12029)');
  Result := LPasso.Resposta;
end;

function TTransporteFalso.Pedidos: TArray<TPedidoHttp>;
begin
  Result := FPedidos.ToArray;
end;

function TTransporteFalso.Pedido(AIndice: Integer): TPedidoHttp;
begin
  Result := FPedidos[AIndice];
end;

function TTransporteFalso.QuantidadeDePedidos: Integer;
begin
  Result := FPedidos.Count;
end;

{ TSessaoFalsa }

constructor TSessaoFalsa.Create(const AToken: string);
begin
  inherited Create;
  FToken := AToken;
end;

function TSessaoFalsa.EnderecoApi: string;
begin
  Result := 'https://servidor.test/api/';
end;

function TSessaoFalsa.Token: string;
begin
  Result := FToken;
end;

{ TTestesApi }

procedure TTestesApi.Preparar;
begin
  FTransporte := TTransporteFalso.Create;
  FRefTransporte := FTransporte;
  FBarramento := TBarramento.Create(TDespachanteImediato.Create);
  FSessoesExpiradas := 0;
  FAssinatura := FBarramento.Assinar<TEventoSessaoExpirada>(
    procedure(AEvento: TEventoSessaoExpirada)
    begin
      Inc(FSessoesExpiradas);
    end);
end;

procedure TTestesApi.Limpar;
begin
  FAssinatura := nil;
  FreeAndNil(FBarramento);
  FRefTransporte := nil;
  FTransporte := nil;
end;

function TTestesApi.NovaApi(const AToken: string): IConversaApi;
var
  LApi: TConversaApi;
begin
  LApi := TConversaApi.Create(FRefTransporte, TSessaoFalsa.Create(AToken), FBarramento, nil);
  LApi.EsperasMs := TArray<Integer>.Create(0, 0);
  Result := LApi;
end;

procedure TTestesApi.SucessoDevolveOCorpoEMandaOToken;
var
  LPedidos: TArray<TPedidoHttp>;
begin
  FTransporte.Responder(200, '[{"id":1}]');
  Assert.AreEqual('[{"id":1}]', NovaApi.Obter('/conversas', []));
  LPedidos := FTransporte.Pedidos;
  Assert.AreEqual(1, Integer(Length(LPedidos)));
  Assert.AreEqual('https://servidor.test/api/conversas', LPedidos[0].Url);
  Assert.AreEqual(1, Integer(Length(LPedidos[0].Cabecalhos)));
  Assert.AreEqual('Authorization', LPedidos[0].Cabecalhos[0].Nome);
  Assert.AreEqual('Bearer tok', LPedidos[0].Cabecalhos[0].Valor);
end;

procedure TTestesApi.ParametrosSaoCodificados;
var
  LUrl: string;
begin
  FTransporte.Responder(200, '[]');
  NovaApi.Obter('pesquisar', [TParametro.Texto('texto', 'café & leite=1+2'), TParametro.Numero('conversa', 0)]);
  LUrl := FTransporte.Pedido(0).Url;
  Assert.StartsWith('https://servidor.test/api/pesquisar?texto=', LUrl);
  Assert.DoesNotContain(LUrl, ' ');
  Assert.DoesNotContain(LUrl, 'é');
  Assert.Contains(LUrl, '%26');           // &
  Assert.Contains(LUrl, '%3D');           // =
  Assert.Contains(LUrl, '%2B');           // +
  Assert.EndsWith('&conversa=0', LUrl);
end;

procedure TTestesApi.CorpoComAcentoEEmojiVaiInteiro;
const
  CORPO = '{"conteudo":"Olá, São Paulo 😀"}';
begin
  FTransporte.Responder(200, '{"ok":true,"texto":"ação 😀"}');
  Assert.AreEqual('{"ok":true,"texto":"ação 😀"}', NovaApi.Enviar(TMetodoHttp.Put, 'mensagem', CORPO, []));
  Assert.AreEqual(CORPO, FTransporte.Pedido(0).Corpo);
  Assert.IsTrue(FTransporte.Pedido(0).Metodo = TMetodoHttp.Put);
end;

procedure TTestesApi.Status401ProtegidaExpiraASessao;
begin
  FTransporte.Responder(401, '{"error":"Token inválido ou expirado"}');
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Obter('conversas', []);
    end, ESessaoExpirada);
  Assert.AreEqual(1, FSessoesExpiradas);
  Assert.AreEqual(1, FTransporte.QuantidadeDePedidos, '401 não se repete');
end;

procedure TTestesApi.Status401PublicaEhSoUmErro;
var
  LMensagem: string;
begin
  FTransporte.Responder(401, '{"error":"Senha incorreta!"}');
  LMensagem := '';
  try
    NovaApi.EnviarPublico(TMetodoHttp.Post, 'login', '{"login":"a","senha":"b"}', []);
  except
    on E: EApiErro do
    begin
      Assert.IsFalse(E is ESessaoExpirada);
      Assert.AreEqual(401, E.Status);
      LMensagem := E.Message;
    end;
  end;
  Assert.AreEqual('Senha incorreta!', LMensagem);
  Assert.AreEqual(0, FSessoesExpiradas);
  Assert.AreEqual(0, Integer(Length(FTransporte.Pedido(0).Cabecalhos)), 'rota pública não leva token');
end;

procedure TTestesApi.SemTokenNemChamaOServidor;
begin
  Assert.WillRaise(
    procedure
    begin
      NovaApi('').Obter('conversas', []);
    end, ESessaoExpirada);
  Assert.AreEqual(0, FTransporte.QuantidadeDePedidos);
  Assert.AreEqual(1, FSessoesExpiradas);
end;

procedure TTestesApi.ErroJsonViraEApiErroComAMensagem;
var
  LStatus: Integer;
  LMensagem: string;
begin
  FTransporte.Responder(400, '{"error":"Campo \"conversa_id\" é obrigatório e não foi informado!"}');
  LStatus := 0;
  try
    NovaApi.Enviar(TMetodoHttp.Put, 'mensagem', '{}', []);
  except
    on E: EApiErro do
    begin
      LStatus := E.Status;
      LMensagem := E.Message;
    end;
  end;
  Assert.AreEqual(400, LStatus);
  Assert.AreEqual('Campo "conversa_id" é obrigatório e não foi informado!', LMensagem);
end;

procedure TTestesApi.ErroSemJsonViraRespostaInesperada;
var
  LMensagem: string;
begin
  FTransporte.Responder(500, 'isto não é json', 'text/plain');
  try
    NovaApi.Enviar(TMetodoHttp.Post, 'x', '', []);
  except
    on E: EApiErro do
      LMensagem := E.Message;
  end;
  Assert.AreEqual(Format(SRespostaInesperada, [500]), LMensagem);
end;

procedure TTestesApi.Html502NoGetRepeteEDepoisDesiste;
const
  HTML = '<html><head><title>502 Bad Gateway</title></head></html>';
begin
  FTransporte.Responder(502, HTML, 'text/html');
  FTransporte.Responder(502, HTML, 'text/html');
  FTransporte.Responder(502, HTML, 'text/html');
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Obter('conversas', []);
    end, EServidorIndisponivel);
  Assert.AreEqual(3, FTransporte.QuantidadeDePedidos, '1 tentativa + 2 repetições');
end;

procedure TTestesApi.Texto502DoDesenvolvimentoTambemEhIndisponivel;
begin
  FTransporte.Responder(502, 'Bad Gateway', 'text/plain');
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Enviar(TMetodoHttp.Post, 'mensagem/visualizar', '{}', []);
    end, EServidorIndisponivel);
end;

procedure TTestesApi.Html502NoPostNaoRepete;
begin
  FTransporte.Responder(502, '<html>502</html>', 'text/html');
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Enviar(TMetodoHttp.Post, 'mensagem/visualizar', '{}', []);
    end, EServidorIndisponivel);
  Assert.AreEqual(1, FTransporte.QuantidadeDePedidos);
end;

procedure TTestesApi.Html503EhMuitasTentativas;
var
  LMensagem: string;
begin
  FTransporte.Responder(503, '<html><body><h1>503 Service Temporarily Unavailable</h1></body></html>', 'text/html');
  try
    NovaApi.EnviarPublico(TMetodoHttp.Post, 'login', '{}', []);
  except
    on E: EMuitasTentativas do
      LMensagem := E.Message;
  end;
  Assert.AreEqual(SMuitasTentativas, LMensagem);
end;

procedure TTestesApi.Html413EhArquivoGrandeDemais;
begin
  FTransporte.Responder(413, '<html>413 Request Entity Too Large</html>', 'text/html');
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Enviar(TMetodoHttp.Put, 'mensagem', '{}', []);
    end, EArquivoGrandeDemais);
end;

procedure TTestesApi.FalhaDeRedeNoGetRepeteERecupera;
begin
  FTransporte.Falhar(TFalhaDeConexao.SemConexao);
  FTransporte.Falhar(TFalhaDeConexao.Tempo);
  FTransporte.Responder(200, '[]');
  Assert.AreEqual('[]', NovaApi.Obter('conversas', []));
  Assert.AreEqual(3, FTransporte.QuantidadeDePedidos);
end;

procedure TTestesApi.FalhaDeRedeNoPostNaoRepeteEUsaMensagemAmigavel;
var
  LMensagem: string;
  LTipo: TFalhaDeConexao;
begin
  FTransporte.Falhar(TFalhaDeConexao.SemConexao);
  LTipo := TFalhaDeConexao.Outra;
  try
    NovaApi.Enviar(TMetodoHttp.Post, 'mensagem/visualizar', '{}', []);
  except
    on E: EFalhaDeConexao do
    begin
      LMensagem := E.Message;
      LTipo := E.Tipo;
    end;
  end;
  Assert.AreEqual(1, FTransporte.QuantidadeDePedidos);
  Assert.IsTrue(LTipo = TFalhaDeConexao.SemConexao);
  Assert.AreEqual(SFalhaSemConexao, LMensagem);
end;

procedure TTestesApi.CertificadoNaoRepete;
begin
  FTransporte.Falhar(TFalhaDeConexao.Certificado);
  Assert.WillRaise(
    procedure
    begin
      NovaApi.Obter('conversas', []);
    end, EFalhaDeConexao);
  Assert.AreEqual(1, FTransporte.QuantidadeDePedidos);
end;

procedure TTestesApi.ClassificacaoDasFalhasDoWinHttp;
begin
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('Error sending data: (12002) The operation timed out', False) =
    TFalhaDeConexao.Tempo);
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('Error sending data: (12029) A connection with the server could not be established', False) =
    TFalhaDeConexao.SemConexao);
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('Error sending data: (12007) The server name or address could not be resolved', False) =
    TFalhaDeConexao.SemConexao);
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('Error sending data: (12175) A security error occurred', False) =
    TFalhaDeConexao.Certificado);
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('qualquer coisa', True) = TFalhaDeConexao.Certificado);
  Assert.IsTrue(TTransporteHttpNet.ClassificarFalha('qualquer coisa', False) = TFalhaDeConexao.Outra);
end;

procedure TTestesApi.TesteDeServidorReconheceOConversa;
var
  LResultado: TResultadoTesteServidor;
begin
  FTransporte.Responder(401, '{"error":"Token não informado"}');
  LResultado := TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://localhost'));
  Assert.IsTrue(LResultado = TResultadoTesteServidor.Ok);
  Assert.AreEqual('https://localhost/api/usuario/permissoes', FTransporte.Pedido(0).Url);
  Assert.AreEqual(0, Integer(Length(FTransporte.Pedido(0).Cabecalhos)), 'o teste vai sem token');
end;

procedure TTestesApi.TesteDeServidorRecusaHtmlEOutrasRespostas;
begin
  FTransporte.Responder(200, '<!doctype html><html></html>', 'text/html');
  Assert.IsTrue(TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://x')) =
    TResultadoTesteServidor.NaoEhConversa);
  FTransporte.Responder(401, '<html>401</html>', 'text/html');
  Assert.IsTrue(TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://x')) =
    TResultadoTesteServidor.NaoEhConversa);
  FTransporte.Falhar(TFalhaDeConexao.SemConexao);
  Assert.IsTrue(TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://x')) =
    TResultadoTesteServidor.Inacessivel);
  FTransporte.Falhar(TFalhaDeConexao.Tempo);
  Assert.IsTrue(TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://x')) =
    TResultadoTesteServidor.Tempo);
end;

procedure TTestesApi.TesteDeServidorCertificado;
begin
  FTransporte.Falhar(TFalhaDeConexao.Certificado);
  Assert.IsTrue(TTesteDeServidor.Testar(FRefTransporte, TEnderecoServidor.Interpretar('https://x')) =
    TResultadoTesteServidor.CertificadoNaoConfiavel);
  Assert.Contains(TTesteDeServidor.Mensagem(TResultadoTesteServidor.CertificadoNaoConfiavel), 'mkcert');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesApi);

end.
