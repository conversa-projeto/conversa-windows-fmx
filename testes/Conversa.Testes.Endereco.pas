unit Conversa.Testes.Endereco;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesEndereco = class
  public
    [Test]
    procedure HttpsDerivaApiWebSocketEMidia;
    [Test]
    procedure HttpComPortaDerivaWsComPorta;
    [Test]
    procedure PortaPadraoNaoAparece;
    [Test]
    procedure BarraFinalECaminhoApiSaoAceitos;
    [Test]
    procedure SemEsquemaAssumeHttps;
    [Test]
    procedure HostVaiParaMinusculasEEspacosSaem;
    [Test]
    procedure Ipv6ComPorta;
    [Test]
    procedure PortaEfetiva;
    [Test]
    procedure EntradasInvalidas;
    [Test]
    procedure TentarInterpretarNaoLanca;
  end;

implementation

uses
  System.SysUtils,
  Conversa.Dominio.Endereco;

procedure TTestesEndereco.HttpsDerivaApiWebSocketEMidia;
var
  E: TEnderecoServidor;
begin
  E := TEnderecoServidor.Interpretar('https://x');
  Assert.AreEqual('https://x', E.Base);
  Assert.AreEqual('https://x/api/', E.Api);
  Assert.AreEqual('wss://x/ws/', E.WebSocket);
  Assert.AreEqual('https://x/webrtc/', E.WebRtc);
  Assert.IsTrue(E.Seguro);
end;

procedure TTestesEndereco.HttpComPortaDerivaWsComPorta;
var
  E: TEnderecoServidor;
begin
  E := TEnderecoServidor.Interpretar('http://x:8080');
  Assert.AreEqual('http://x:8080', E.Base);
  Assert.AreEqual('http://x:8080/api/', E.Api);
  Assert.AreEqual('ws://x:8080/ws/', E.WebSocket);
  Assert.IsFalse(E.Seguro);
end;

procedure TTestesEndereco.PortaPadraoNaoAparece;
begin
  Assert.AreEqual('https://x', TEnderecoServidor.Interpretar('https://x:443').Base);
  Assert.AreEqual('wss://x/ws/', TEnderecoServidor.Interpretar('https://x:443/').WebSocket);
  Assert.AreEqual('http://x', TEnderecoServidor.Interpretar('http://x:80').Base);
  Assert.AreEqual('https://x:80', TEnderecoServidor.Interpretar('https://x:80').Base);
end;

procedure TTestesEndereco.BarraFinalECaminhoApiSaoAceitos;
begin
  Assert.AreEqual('https://localhost', TEnderecoServidor.Interpretar('https://localhost/').Base);
  Assert.AreEqual('https://localhost', TEnderecoServidor.Interpretar('https://localhost/api').Base);
  Assert.AreEqual('https://localhost', TEnderecoServidor.Interpretar('https://localhost/api/').Base);
  Assert.AreEqual('https://localhost:4430', TEnderecoServidor.Interpretar('https://localhost:4430/api/').Base);
  Assert.AreEqual('https://localhost/api/', TEnderecoServidor.Interpretar('https://localhost//').Api);
end;

procedure TTestesEndereco.SemEsquemaAssumeHttps;
begin
  Assert.AreEqual('https://conversa.empresa.com', TEnderecoServidor.Interpretar('conversa.empresa.com').Base);
  Assert.AreEqual('wss://192.168.0.10/ws/', TEnderecoServidor.Interpretar('192.168.0.10').WebSocket);
end;

procedure TTestesEndereco.HostVaiParaMinusculasEEspacosSaem;
begin
  Assert.AreEqual('https://conversa.empresa.com', TEnderecoServidor.Interpretar('  HTTPS://Conversa.Empresa.COM/  ').Base);
end;

procedure TTestesEndereco.Ipv6ComPorta;
var
  E: TEnderecoServidor;
begin
  E := TEnderecoServidor.Interpretar('https://[::1]:8443');
  Assert.AreEqual('[::1]', E.Host);
  Assert.AreEqual('wss://[::1]:8443/ws/', E.WebSocket);
end;

procedure TTestesEndereco.PortaEfetiva;
begin
  Assert.AreEqual(443, TEnderecoServidor.Interpretar('https://x').Porta);
  Assert.AreEqual(80, TEnderecoServidor.Interpretar('http://x').Porta);
  Assert.AreEqual(8443, TEnderecoServidor.Interpretar('https://x:8443').Porta);
end;

procedure TTestesEndereco.EntradasInvalidas;
const
  INVALIDAS: array[0..9] of string = ('', '   ', 'ftp://x', 'https://x/outro', 'https://x/api/v2', 'https://x:99999',
    'https://x:abc', 'https://x?y=1', 'https://usuario@x', 'https://');
var
  LTexto: string;
begin
  for LTexto in INVALIDAS do
    Assert.WillRaise(
      procedure
      begin
        TEnderecoServidor.Interpretar(LTexto);
      end, EEnderecoInvalido, 'deveria recusar: "' + LTexto + '"');
end;

procedure TTestesEndereco.TentarInterpretarNaoLanca;
var
  E: TEnderecoServidor;
begin
  Assert.IsFalse(TEnderecoServidor.TentarInterpretar('ftp://x', E));
  Assert.IsTrue(E.Vazio);
  Assert.AreEqual('', E.Api);
  Assert.IsTrue(TEnderecoServidor.TentarInterpretar('https://x', E));
  Assert.IsFalse(E.Vazio);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesEndereco);

end.
