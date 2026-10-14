unit Conversa.Eventos.Barramento;

{ Barramento de eventos tipado (FC-103, D5 do doc 07).

  - Assinar<T>: o manipulador recebe todo evento do tipo T publicado depois. A assinatura devolve um
    IInterface: soltar a referência cancela (nenhuma entrega acontece depois disso, mesmo já na fila).
  - Publicar<T>: pode ser chamado de qualquer thread. A entrega é feita pelo despachante: na thread principal
    (app) ou na hora (testes). Com o despachante da thread principal, a entrega SEMPRE passa pela fila, também
    quando se publica da própria thread principal: nenhum assinante roda dentro de quem publicou.
  - PublicarEstado<T>: além de entregar, guarda o valor como "último"; quem assinar depois recebe o atual.
  - Exceção num assinante não impede os outros: vai para o AoErro (o logger, na composição do app).
  - Threads: publicar e assinar, de qualquer uma. Soltar as assinaturas e destruir o barramento, só na thread
    principal (o cancelamento lê o barramento sem trava; a ordem de encerramento do app garante isso). }

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.SyncObjs,
  System.Generics.Collections;

type
  /// <summary>Executa a entrega dos eventos.</summary>
  IDespachante = interface
    ['{266B77AD-893A-4233-A2C8-D2309F411F3D}']
    procedure Despachar(const AAcao: TProc);
  end;

  /// <summary>Entrega na thread principal, sempre pela fila (TThread.ForceQueue).</summary>
  TDespachanteThreadPrincipal = class(TInterfacedObject, IDespachante)
  public
    procedure Despachar(const AAcao: TProc);
  end;

  /// <summary>Entrega na hora, na thread de quem publicou (testes).</summary>
  TDespachanteImediato = class(TInterfacedObject, IDespachante)
  public
    procedure Despachar(const AAcao: TProc);
  end;

  TAoErroDeAssinante = reference to procedure(const AErro: Exception; const AEvento: string);
  TEntregaDeValor = reference to procedure(const AValor: TValue);

  TBarramento = class;

  /// <summary>Uso interno do barramento (precisa estar na interface por causa dos métodos genéricos).</summary>
  IAssinaturaInterna = interface
    ['{AF010825-8F90-40B8-B257-4A13E95BAF48}']
    function Ativa: Boolean;
    function TipoEvento: PTypeInfo;
    procedure Entregar(const AValor: TValue);
    /// <summary>Cancelada por quem assinou: para de receber e sai do barramento.</summary>
    procedure Cancelar;
    /// <summary>O barramento foi destruído: para de receber e esquece o barramento.</summary>
    procedure Desligar;
  end;

  /// <summary>Uso interno do barramento.</summary>
  TAssinaturaInterna = class(TInterfacedObject, IAssinaturaInterna)
  private
    FTipo: PTypeInfo;
    FEntrega: TEntregaDeValor;
    FAtiva: Integer;
    FBarramento: TBarramento;
  public
    constructor Create(ABarramento: TBarramento; ATipo: PTypeInfo; const AEntrega: TEntregaDeValor);
    function Ativa: Boolean;
    function TipoEvento: PTypeInfo;
    procedure Entregar(const AValor: TValue);
    procedure Cancelar;
    procedure Desligar;
  end;

  /// <summary>O que quem assina recebe: soltar a referência cancela a assinatura.</summary>
  TTokenDeAssinatura = class(TInterfacedObject)
  private
    FInterna: IAssinaturaInterna;
  public
    constructor Create(const AInterna: IAssinaturaInterna);
    destructor Destroy; override;
  end;

  TBarramento = class
  private
    FTrava: TCriticalSection;
    FAssinaturas: TObjectDictionary<PTypeInfo, TList<IAssinaturaInterna>>;
    FEstados: TDictionary<PTypeInfo, TValue>;
    FDespachante: IDespachante;
    FAoErro: TAoErroDeAssinante;
    function Registrar(ATipo: PTypeInfo; const AEntrega: TEntregaDeValor): IAssinaturaInterna;
    procedure PublicarValor(ATipo: PTypeInfo; const AValor: TValue; AGuardarEstado: Boolean);
    procedure Entregar(const AAssinaturas: TArray<IAssinaturaInterna>; const AValor: TValue; ATipo: PTypeInfo);
  public
    constructor Create(const ADespachante: IDespachante; const AAoErro: TAoErroDeAssinante = nil);
    destructor Destroy; override;

    function Assinar<T>(const AManipulador: TProc<T>): IInterface;
    procedure Publicar<T>(const AEvento: T);
    procedure PublicarEstado<T>(const AEstado: T);
    function TentarObterEstado<T>(out AEstado: T): Boolean;
    function QuantidadeDeAssinantes<T>: Integer;

    /// <summary>Uso interno (cancelamento de uma assinatura).</summary>
    procedure Remover(const AAssinatura: IAssinaturaInterna);
  end;

implementation

uses
  System.Classes;

{ TDespachanteThreadPrincipal }

procedure TDespachanteThreadPrincipal.Despachar(const AAcao: TProc);
var
  LAcao: TProc;
begin
  LAcao := AAcao;
  TThread.ForceQueue(nil,
    procedure
    begin
      LAcao();
    end);
end;

{ TDespachanteImediato }

procedure TDespachanteImediato.Despachar(const AAcao: TProc);
begin
  AAcao();
end;

{ TAssinaturaInterna }

constructor TAssinaturaInterna.Create(ABarramento: TBarramento; ATipo: PTypeInfo; const AEntrega: TEntregaDeValor);
begin
  inherited Create;
  FBarramento := ABarramento;
  FTipo := ATipo;
  FEntrega := AEntrega;
  FAtiva := 1;
end;

function TAssinaturaInterna.Ativa: Boolean;
begin
  Result := TInterlocked.CompareExchange(FAtiva, 0, 0) = 1;
end;

function TAssinaturaInterna.TipoEvento: PTypeInfo;
begin
  Result := FTipo;
end;

procedure TAssinaturaInterna.Entregar(const AValor: TValue);
begin
  if Ativa then
    FEntrega(AValor);
end;

procedure TAssinaturaInterna.Cancelar;
var
  LBarramento: TBarramento;
begin
  TInterlocked.Exchange(FAtiva, 0);
  LBarramento := FBarramento;
  FBarramento := nil;
  if Assigned(LBarramento) then
    LBarramento.Remover(Self);
end;

procedure TAssinaturaInterna.Desligar;
begin
  TInterlocked.Exchange(FAtiva, 0);
  FBarramento := nil;
end;

{ TTokenDeAssinatura }

constructor TTokenDeAssinatura.Create(const AInterna: IAssinaturaInterna);
begin
  inherited Create;
  FInterna := AInterna;
end;

destructor TTokenDeAssinatura.Destroy;
begin
  if Assigned(FInterna) then
    FInterna.Cancelar;
  FInterna := nil;
  inherited;
end;

{ TBarramento }

constructor TBarramento.Create(const ADespachante: IDespachante; const AAoErro: TAoErroDeAssinante);
begin
  inherited Create;
  FTrava := TCriticalSection.Create;
  FAssinaturas := TObjectDictionary<PTypeInfo, TList<IAssinaturaInterna>>.Create([doOwnsValues]);
  FEstados := TDictionary<PTypeInfo, TValue>.Create;
  FDespachante := ADespachante;
  if not Assigned(FDespachante) then
    FDespachante := TDespachanteThreadPrincipal.Create;
  FAoErro := AAoErro;
end;

destructor TBarramento.Destroy;
var
  LLista: TList<IAssinaturaInterna>;
  LAssinatura: IAssinaturaInterna;
begin
  FTrava.Enter;
  try
    for LLista in FAssinaturas.Values do
      for LAssinatura in LLista do
        LAssinatura.Desligar;
    FAssinaturas.Clear;
    FEstados.Clear;
  finally
    FTrava.Leave;
  end;
  FAssinaturas.Free;
  FEstados.Free;
  FTrava.Free;
  inherited;
end;

function TBarramento.Registrar(ATipo: PTypeInfo; const AEntrega: TEntregaDeValor): IAssinaturaInterna;
var
  LLista: TList<IAssinaturaInterna>;
  LEstado: TValue;
begin
  Result := TAssinaturaInterna.Create(Self, ATipo, AEntrega);
  FTrava.Enter;
  try
    if not FAssinaturas.TryGetValue(ATipo, LLista) then
    begin
      LLista := TList<IAssinaturaInterna>.Create;
      FAssinaturas.Add(ATipo, LLista);
    end;
    LLista.Add(Result);
    // O estado atual é entregue ainda com a trava: um PublicarEstado concorrente só enfileira depois dele,
    // e quem assina nunca recebe o novo antes do antigo. TryGetValue (e não TValue.IsEmpty): um estado
    // "vazio" (nil, array vazio) também é estado.
    if FEstados.TryGetValue(ATipo, LEstado) then
      Entregar(TArray<IAssinaturaInterna>.Create(Result), LEstado, ATipo);
  finally
    FTrava.Leave;
  end;
end;

procedure TBarramento.Remover(const AAssinatura: IAssinaturaInterna);
var
  LLista: TList<IAssinaturaInterna>;
begin
  FTrava.Enter;
  try
    if FAssinaturas.TryGetValue(AAssinatura.TipoEvento, LLista) then
      LLista.Remove(AAssinatura);
  finally
    FTrava.Leave;
  end;
end;

procedure TBarramento.PublicarValor(ATipo: PTypeInfo; const AValor: TValue; AGuardarEstado: Boolean);
var
  LLista: TList<IAssinaturaInterna>;
  LCopia: TArray<IAssinaturaInterna>;
begin
  // Enfileira com a trava (ver Registrar). A trava é reentrante (seção crítica do Windows): com o despachante
  // imediato, um assinante que publica de dentro da entrega não trava.
  FTrava.Enter;
  try
    if AGuardarEstado then
      FEstados.AddOrSetValue(ATipo, AValor);
    if FAssinaturas.TryGetValue(ATipo, LLista) then
      LCopia := LLista.ToArray
    else
      LCopia := nil;
    if Length(LCopia) > 0 then
      Entregar(LCopia, AValor, ATipo);
  finally
    FTrava.Leave;
  end;
end;

procedure TBarramento.Entregar(const AAssinaturas: TArray<IAssinaturaInterna>; const AValor: TValue; ATipo: PTypeInfo);
var
  LAssinaturas: TArray<IAssinaturaInterna>;
  LValor: TValue;
  LAoErro: TAoErroDeAssinante;
  LNome: string;
begin
  // Só variáveis locais entram na closure: a entrega pode acontecer depois de o barramento ser destruído
  // (as assinaturas já estarão desligadas e nada é entregue).
  LAssinaturas := AAssinaturas;
  LValor := AValor;
  LAoErro := FAoErro;
  LNome := GetTypeName(ATipo);
  FDespachante.Despachar(
    procedure
    var
      LAssinatura: IAssinaturaInterna;
    begin
      for LAssinatura in LAssinaturas do
        try
          LAssinatura.Entregar(LValor);
        except
          on E: Exception do
            if Assigned(LAoErro) then
              try
                LAoErro(E, LNome);
              except
                // quem trata o erro também não pode derrubar a entrega
              end;
        end;
    end);
end;

function TBarramento.Assinar<T>(const AManipulador: TProc<T>): IInterface;
var
  LManipulador: TProc<T>;
begin
  LManipulador := AManipulador;
  Result := TTokenDeAssinatura.Create(Registrar(PTypeInfo(TypeInfo(T)),
    procedure(const AValor: TValue)
    begin
      LManipulador(AValor.AsType<T>);
    end));
end;

procedure TBarramento.Publicar<T>(const AEvento: T);
begin
  PublicarValor(PTypeInfo(TypeInfo(T)), TValue.From<T>(AEvento), False);
end;

procedure TBarramento.PublicarEstado<T>(const AEstado: T);
begin
  PublicarValor(PTypeInfo(TypeInfo(T)), TValue.From<T>(AEstado), True);
end;

function TBarramento.TentarObterEstado<T>(out AEstado: T): Boolean;
var
  LValor: TValue;
begin
  FTrava.Enter;
  try
    Result := FEstados.TryGetValue(PTypeInfo(TypeInfo(T)), LValor);
  finally
    FTrava.Leave;
  end;
  if Result then
    AEstado := LValor.AsType<T>
  else
    AEstado := Default(T);
end;

function TBarramento.QuantidadeDeAssinantes<T>: Integer;
var
  LLista: TList<IAssinaturaInterna>;
begin
  FTrava.Enter;
  try
    if FAssinaturas.TryGetValue(PTypeInfo(TypeInfo(T)), LLista) then
      Result := LLista.Count
    else
      Result := 0;
  finally
    FTrava.Leave;
  end;
end;

end.
