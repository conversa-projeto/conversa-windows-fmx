unit Conversa.Testes.Barramento;

interface

uses
  DUnitX.TestFramework,
  Conversa.Eventos.Barramento;

type
  TEventoTeste = record
    Valor: Integer;
    constructor Create(AValor: Integer);
  end;

  TOutroEvento = record
    Texto: string;
  end;

  [TestFixture]
  TTestesBarramento = class
  private
    FBarramento: TBarramento;
    FErros: TArray<string>;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;

    [Test]
    procedure EntregaAoAssinante;
    [Test]
    procedure TiposDiferentesNaoSeMisturam;
    [Test]
    procedure VariosAssinantesNaOrdemDaAssinatura;
    [Test]
    procedure EventosChegamNaOrdemDePublicacao;
    [Test]
    procedure SoltarAReferenciaCancela;
    [Test]
    procedure ExcecaoNumAssinanteNaoImpedeOsOutros;
    [Test]
    procedure EstadoChegaAQuemAssinaDepois;
    [Test]
    procedure EventoComumNaoFicaGuardado;
    [Test]
    procedure EstadoMaisRecenteSubstituiOAnterior;
    [Test]
    procedure PublicadoDeOutraThreadChegaNaThreadPrincipal;
    [Test]
    procedure PublicadoNaThreadPrincipalNaoRodaDentroDeQuemPublicou;
    [Test]
    procedure CanceladoDepoisDeEnfileiradoNaoRecebe;
    [Test]
    procedure BarramentoDestruidoComEntregaNaFilaNaoQuebra;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics;

{ TEventoTeste }

constructor TEventoTeste.Create(AValor: Integer);
begin
  Valor := AValor;
end;

/// Processa a fila da thread principal até a condição valer ou o tempo acabar.
function EsperarFila(const ACondicao: TFunc<Boolean>; ATempoMs: Integer = 3000): Boolean;
var
  LRelogio: TStopwatch;
begin
  LRelogio := TStopwatch.StartNew;
  repeat
    CheckSynchronize(10);
    if ACondicao() then
      Exit(True);
  until LRelogio.ElapsedMilliseconds > ATempoMs;
  Result := ACondicao();
end;

{ TTestesBarramento }

procedure TTestesBarramento.Preparar;
begin
  FErros := nil;
  FBarramento := TBarramento.Create(TDespachanteImediato.Create,
    procedure(const AErro: Exception; const AEvento: string)
    begin
      FErros := FErros + [AEvento + ': ' + AErro.Message];
    end);
end;

procedure TTestesBarramento.Limpar;
begin
  FreeAndNil(FBarramento);
end;

procedure TTestesBarramento.EntregaAoAssinante;
var
  LRecebido: Integer;
  LAssinatura: IInterface;
begin
  LRecebido := 0;
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LRecebido := AEvento.Valor;
    end);
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(42));
  Assert.AreEqual(42, LRecebido);
end;

procedure TTestesBarramento.TiposDiferentesNaoSeMisturam;
var
  LContagem: Integer;
  LAssinatura: IInterface;
  LOutro: TOutroEvento;
begin
  LContagem := 0;
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      Inc(LContagem);
    end);
  LOutro.Texto := 'outro';
  FBarramento.Publicar<TOutroEvento>(LOutro);
  Assert.AreEqual(0, LContagem);
end;

procedure TTestesBarramento.VariosAssinantesNaOrdemDaAssinatura;
var
  LOrdem: string;
  LA, LB: IInterface;
begin
  LOrdem := '';
  LA := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LOrdem := LOrdem + 'A';
    end);
  LB := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LOrdem := LOrdem + 'B';
    end);
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1));
  Assert.AreEqual('AB', LOrdem);
  Assert.AreEqual(2, FBarramento.QuantidadeDeAssinantes<TEventoTeste>());
end;

procedure TTestesBarramento.EventosChegamNaOrdemDePublicacao;
var
  LValores: string;
  LAssinatura: IInterface;
  I: Integer;
begin
  LValores := '';
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LValores := LValores + IntToStr(AEvento.Valor);
    end);
  for I := 1 to 5 do
    FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(I));
  Assert.AreEqual('12345', LValores);
end;

procedure TTestesBarramento.SoltarAReferenciaCancela;
var
  LContagem: Integer;
  LAssinatura: IInterface;
begin
  LContagem := 0;
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      Inc(LContagem);
    end);
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1));
  LAssinatura := nil;
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(2));
  Assert.AreEqual(1, LContagem);
  Assert.AreEqual(0, FBarramento.QuantidadeDeAssinantes<TEventoTeste>());
end;

procedure TTestesBarramento.ExcecaoNumAssinanteNaoImpedeOsOutros;
var
  LSegundoRecebeu: Boolean;
  LA, LB: IInterface;
begin
  LSegundoRecebeu := False;
  LA := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      raise EInvalidOpException.Create('falha de propósito');
    end);
  LB := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LSegundoRecebeu := True;
    end);
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1));
  Assert.IsTrue(LSegundoRecebeu);
  Assert.AreEqual(1, Integer(Length(FErros)));
  Assert.Contains(FErros[0], 'falha de propósito');
  Assert.Contains(FErros[0], 'TEventoTeste');
end;

procedure TTestesBarramento.EstadoChegaAQuemAssinaDepois;
var
  LRecebido: Integer;
  LAssinatura: IInterface;
  LEstado: TEventoTeste;
begin
  FBarramento.PublicarEstado<TEventoTeste>(TEventoTeste.Create(7));
  LRecebido := 0;
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LRecebido := AEvento.Valor;
    end);
  Assert.AreEqual(7, LRecebido);
  Assert.IsTrue(FBarramento.TentarObterEstado<TEventoTeste>(LEstado));
  Assert.AreEqual(7, LEstado.Valor);
end;

procedure TTestesBarramento.EventoComumNaoFicaGuardado;
var
  LContagem: Integer;
  LAssinatura: IInterface;
  LEstado: TEventoTeste;
begin
  FBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(3));
  LContagem := 0;
  LAssinatura := FBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      Inc(LContagem);
    end);
  Assert.AreEqual(0, LContagem);
  Assert.IsFalse(FBarramento.TentarObterEstado<TEventoTeste>(LEstado));
  Assert.AreEqual(0, LEstado.Valor);
end;

procedure TTestesBarramento.EstadoMaisRecenteSubstituiOAnterior;
var
  LEstado: TEventoTeste;
begin
  FBarramento.PublicarEstado<TEventoTeste>(TEventoTeste.Create(1));
  FBarramento.PublicarEstado<TEventoTeste>(TEventoTeste.Create(2));
  Assert.IsTrue(FBarramento.TentarObterEstado<TEventoTeste>(LEstado));
  Assert.AreEqual(2, LEstado.Valor);
end;

procedure TTestesBarramento.PublicadoDeOutraThreadChegaNaThreadPrincipal;
var
  LBarramento: TBarramento;
  LAssinatura: IInterface;
  LRecebido: Integer;
  LThreadDaEntrega: TThreadID;
begin
  LBarramento := TBarramento.Create(TDespachanteThreadPrincipal.Create);
  try
    LRecebido := 0;
    LThreadDaEntrega := 0;
    LAssinatura := LBarramento.Assinar<TEventoTeste>(
      procedure(AEvento: TEventoTeste)
      begin
        LRecebido := AEvento.Valor;
        LThreadDaEntrega := TThread.CurrentThread.ThreadID;
      end);
    TThread.CreateAnonymousThread(
      procedure
      begin
        LBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(99));
      end).Start;
    Assert.IsTrue(EsperarFila(
      function: Boolean
      begin
        Result := LRecebido = 99;
      end), 'o evento não chegou');
    Assert.IsTrue(LThreadDaEntrega = MainThreadID, 'a entrega não aconteceu na thread principal');
    LAssinatura := nil;
  finally
    LBarramento.Free;
  end;
end;

procedure TTestesBarramento.PublicadoNaThreadPrincipalNaoRodaDentroDeQuemPublicou;
var
  LBarramento: TBarramento;
  LAssinatura: IInterface;
  LRecebido: Boolean;
begin
  LBarramento := TBarramento.Create(TDespachanteThreadPrincipal.Create);
  try
    LRecebido := False;
    LAssinatura := LBarramento.Assinar<TEventoTeste>(
      procedure(AEvento: TEventoTeste)
      begin
        LRecebido := True;
      end);
    LBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1));
    Assert.IsFalse(LRecebido, 'a entrega aconteceu dentro do Publicar');
    Assert.IsTrue(EsperarFila(
      function: Boolean
      begin
        Result := LRecebido;
      end), 'o evento não chegou');
    LAssinatura := nil;
  finally
    LBarramento.Free;
  end;
end;

procedure TTestesBarramento.CanceladoDepoisDeEnfileiradoNaoRecebe;
var
  LBarramento: TBarramento;
  LAssinatura: IInterface;
  LRecebido: Boolean;
begin
  LBarramento := TBarramento.Create(TDespachanteThreadPrincipal.Create);
  try
    LRecebido := False;
    LAssinatura := LBarramento.Assinar<TEventoTeste>(
      procedure(AEvento: TEventoTeste)
      begin
        LRecebido := True;
      end);
    LBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1)); // fica na fila
    LAssinatura := nil;                                          // cancela antes da entrega
    EsperarFila(
      function: Boolean
      begin
        Result := False;
      end, 200);
    Assert.IsFalse(LRecebido);
  finally
    LBarramento.Free;
  end;
end;

procedure TTestesBarramento.BarramentoDestruidoComEntregaNaFilaNaoQuebra;
var
  LBarramento: TBarramento;
  LAssinatura: IInterface;
  LRecebido: Boolean;
begin
  LBarramento := TBarramento.Create(TDespachanteThreadPrincipal.Create);
  LRecebido := False;
  LAssinatura := LBarramento.Assinar<TEventoTeste>(
    procedure(AEvento: TEventoTeste)
    begin
      LRecebido := True;
    end);
  LBarramento.Publicar<TEventoTeste>(TEventoTeste.Create(1)); // fica na fila
  LBarramento.Free;                                            // destruído antes da entrega
  EsperarFila(
    function: Boolean
    begin
      Result := False;
    end, 200);
  LAssinatura := nil; // soltar a assinatura depois do barramento destruído também não pode quebrar
  Assert.IsFalse(LRecebido);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesBarramento);

end.
