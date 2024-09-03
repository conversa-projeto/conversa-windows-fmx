// 2024-08-01
// Daniel, Eduardo
unit Conversa.Tipos;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Messaging;

type
  TUsuario = class;
  TUsuarios = class;
  TConversa = class;
  TConversas = class;
  TMensagem = class;
  TMensagens = class;
  TConteudo = class;

  TArrayUsuarios = TArray<TUsuario>;
  TArrayConversas = TArray<TConversa>;
  TArrayMensagens = TArray<TMensagem>;
  TConteudos = TArray<TConteudo>;
  TPConteudos = ^TConteudos;

  TUsuarios = class
  private
    FUsuarios: TArray<TUsuario>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Usuario: TUsuario);
    function Get(const ID: Integer): TUsuario;
    function GetOrAdd(const ID: Integer): TUsuario;
    procedure Clear;
  end;

  TUsuario = class
  private
    FID: Integer;
    FNome: String;
    FLogin: String;
    FEmail: String;
    FTelefone: String;
  public
    class function New(ID: Integer): TUsuario;
    function ID: Integer; overload;
    function Nome: String; overload;
    function Login: String; overload;
    function Email: String; overload;
    function Telefone: String; overload;
    function Nome(const Value: String): TUsuario; overload;
    function Login(const Value: String): TUsuario; overload;
    function Email(const Value: String): TUsuario; overload;
    function Telefone(const Value: String): TUsuario; overload;
    function Abreviatura: String;
  end;

  TConversas = class
  private
    FConversas: TArrayConversas;
  public
    destructor Destroy; override;
    procedure Add(const Conversa: TConversa);
    function Get(const ID: Integer): TConversa;
    function GetOrAdd(const ID: Integer): TConversa;
    function FromDestinatario(const ID: Integer): TConversa;
    function Items: TArrayConversas;
    function MensagensSemVisualizar: Integer;
    procedure Clear;
  end;

  TTipoConversa = (Chat = 1, Grupo = 2);
  TConversa = class
  private
    FID: Integer;
    FTipo: TTipoConversa;
    FDescricao: String;
    FUltimaMensagem: String;
    FUltimaMensagemData: TDateTime;
    FUsuarios: TArrayUsuarios;
    FUltimaMensagemId: Integer;
    FMensagens: TMensagens;
    FCriadoEm: TDateTime;
  public
    MensagemSemVisualizar: Integer;
    class function New(ID: Integer): TConversa;
    constructor Create;
    destructor Destroy; override;
    property Mensagens: TMensagens read FMensagens;
    function ID: Integer; overload;
    function ID(const Value: Integer): TConversa; overload;
    function Tipo: TTipoConversa; overload;
    function Tipo(const Value: TTipoConversa): TConversa; overload;
    function Descricao: String; overload;
    function UltimaMensagem: String; overload;
    function UltimaMensagemData: TDateTime; overload;
    function Descricao(const Value: String): TConversa; overload;
    function UltimaMensagem(const Value: String): TConversa; overload;
    function UltimaMensagemData(const Value: TDateTime): TConversa; overload;
    function UltimaMensagemID: Integer; overload;
    function UltimaMensagemID(const Value: INteger): TConversa; overload;
    function CriadoEm: TDateTime; overload;
    function CriadoEm(const Value: TDateTime): TConversa; overload;
    function Usuarios: TArrayUsuarios;
    function AddUsuario(const Usuario: TUsuario): TConversa;
    function Destinatario: TUsuario;
  end;

  TMensagens = class
  private
    FConversa: TConversa;
    FMensagens: TArray<TMensagem>;
    FUltimaMensagemSincronizada: Integer;
    constructor Create(Owner: TConversa);
  public
    destructor Destroy; override;
    property UltimaMensagemSincronizada: Integer read FUltimaMensagemSincronizada;
    procedure Add(const Mensagem: TMensagem);
    function Get(const ID: Integer): TMensagem; overload;
    function GetList(const Inicio: Integer): TArrayMensagens; overload;
    procedure Clear;
    function Items: TArray<TMensagem>;
    function ParaExibir(const ApenasPendente: Boolean): TArrayMensagens;
    function ParaNotificar: TArrayMensagens;
    function ParaAtualizar: TArrayMensagens;
  end;

  TLadoMensagem = (Esquerdo, Direito);
  TMensagem = class
  private
    FID: Integer;
    FConversa: TConversa;
    FRemetente: TUsuario;
    FLado: TLadoMensagem;
    FAlterada: TDateTime;
    FInserida: TDateTime;
    FExibida: Boolean;
    FRecebida: Boolean;
    FVisualizada: Boolean;
    FNotificada: Boolean;
    FPrimeiraExibicao: Boolean;
    procedure DoAoAtualizar;
  public
    Conteudos: TConteudos;
    class function New(ID: Integer): TMensagem;
    destructor Destroy; override;
    function ID: Integer; overload;
    function ID(const Value: Integer): TMensagem; overload;
    function Conversa: TConversa; overload;
    function Remetente: TUsuario; overload;
    function Lado: TLadoMensagem; overload;
    function Alterada: TDateTime; overload;
    function Inserida: TDateTime; overload;
    function Exibida: Boolean; overload;
    function Recebida: Boolean; overload;
    function Visualizada: Boolean; overload;
    function Notificada: Boolean; overload;
    function PrimeiraExibicao: Boolean; overload;
    function Conversa(const Value: TConversa): TMensagem; overload;
    function Remetente(const Value: TUsuario): TMensagem; overload;
    function Lado(const Value: TLadoMensagem): TMensagem; overload;
    function Alterada(const Value: TDateTime): TMensagem; overload;
    function Inserida(const Value: TDateTime): TMensagem; overload;
    function Exibida(const Value: Boolean): TMensagem; overload;
    function Recebida(const Value: Boolean): TMensagem; overload;
    function Visualizada(const Value: Boolean; const Sincronizar: Boolean = False): TMensagem; overload;
    function Notificada(const Value: Boolean): TMensagem; overload;
    function PrimeiraExibicao(const Value: Boolean): TMensagem; overload;
    function DescricaoSimples: String;
  end;

  TTipoConteudo = (Nenhum, Texto, Imagem, Arquivo);
  TConteudo = class
  private
    FID: Integer;
    FTipo: TTipoConteudo;
    FOrdem: Integer;
    FConteudo: String;
    FNome: String;
    FExtensao: String;
  public
    UltimaMensagemAdicionada: Integer;
    class function New(ID: Integer): TConteudo;
    function ID: Integer; overload;
    function Tipo: TTipoConteudo; overload;
    function Ordem: Integer; overload;
    function Conteudo: String; overload;
    function Nome: String; overload;
    function Nome(const Value: String): TConteudo; overload;
    function Extensao: String; overload;
    function Extensao(const Value: String): TConteudo; overload;
    function Tipo(const Value: TTipoConteudo): TConteudo; overload;
    function Ordem(const Value: Integer): TConteudo; overload;
    function Conteudo(const Value: String): TConteudo; overload;
  end;

  THConteudos = record Helper for TConteudos
  public
    procedure Add(const Conteudo: TConteudo); overload;
    procedure Add(const Conteudo: TConteudos); overload;
    function Get(const ID: Integer): TConteudo;
    function Count: Integer;
    procedure Clear;
  end;

  THArrayConversas = record Helper for TArrayConversas
    function OrdemAtualizacao: TArrayConversas;
  end;

  THArrayMensagens = record Helper for TArrayMensagens
    function OrdemTempo: TArrayMensagens;
  end;

  THArrayUsuarios = record Helper for TArrayUsuarios
    function Count: Integer;
  end;

implementation

uses
  Conversa.Dados,
  Conversa.Eventos;

{ TUsuarios }

constructor TUsuarios.Create;
begin
  //
end;

destructor TUsuarios.Destroy;
begin
  Clear;
  inherited;
end;

procedure TUsuarios.Add(const Usuario: TUsuario);
begin
  FUsuarios := FUsuarios + [Usuario];
end;

function TUsuarios.Get(const ID: Integer): TUsuario;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FUsuarios) do
  begin
    if FUsuarios[I].ID = ID then
    begin
      Result := FUsuarios[I];
      Exit;
    end;
  end;
end;

function TUsuarios.GetOrAdd(const ID: Integer): TUsuario;
begin
  Result := Get(ID);
  if not Assigned(Result) then
  begin
    Result := TUsuario.New(ID);
    Add(Result);
  end;
end;

procedure TUsuarios.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FUsuarios) do
    FUsuarios[I].Free;
  SetLength(FUsuarios, 0);
end;

{ TUsuario }

class function TUsuario.New(ID: Integer): TUsuario;
begin
  Result := TUsuario.Create;
  Result.FID := ID;
end;

function TUsuario.ID: Integer;
begin
  Result := FID;
end;

function TUsuario.Nome: String;
begin
  Result := FNome;
end;

function TUsuario.Nome(const Value: String): TUsuario;
begin
  FNome := Value;
  Result := Self;
end;

function TUsuario.Login: String;
begin
  Result := FLogin;
end;

function TUsuario.Login(const Value: String): TUsuario;
begin
  FLogin := Value;
  Result := Self;
end;

function TUsuario.Email: String;
begin
  Result := FEmail;
end;

function TUsuario.Email(const Value: String): TUsuario;
begin
  FEmail := Value;
  Result := Self;
end;

function TUsuario.Telefone: String;
begin
  Result := FTelefone;
end;

function TUsuario.Telefone(const Value: String): TUsuario;
begin
  FTelefone := Value;
  Result := Self;
end;

function TUsuario.Abreviatura: String;
begin
  Result := EmptyStr;
  if not FNome.Trim.Isempty then
    Result := FNome[1];
end;

{ TConversas }

destructor TConversas.Destroy;
begin
  Clear;
  inherited;
end;

procedure TConversas.Add(const Conversa: TConversa);
var
  C: TConversa;
begin
  C := Get(Conversa.ID);
  if not Assigned(C) then
  begin
    SetLength(FConversas, Length(FConversas) + 1);
    FConversas[High(FConversas)] := Conversa;
  end;

  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizacaoListaConversa.Create(0));
end;

function TConversas.Get(const ID: Integer): TConversa;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FConversas) do
    if FConversas[I].ID = ID then
      Exit(FConversas[I]);
end;

function TConversas.GetOrAdd(const ID: Integer): TConversa;
begin
  Result := Get(ID);
  if not Assigned(Result) then
  begin
    Result := TConversa.New(ID);
    Add(Result);
  end;
end;

function TConversas.Items: TArrayConversas;
begin
  Result := FConversas;
end;

function TConversas.MensagensSemVisualizar: Integer;
var
  Conversa: TConversa;
begin
  Result := 0;
  for Conversa in FConversas do
    Inc(Result, Conversa.MensagemSemVisualizar);
end;

function TConversas.FromDestinatario(const ID: Integer): TConversa;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FConversas) do
    if (FConversas[I].Tipo = TTipoConversa.Chat) and (FConversas[I].Destinatario.ID = ID) then
      Exit(FConversas[I]);
end;

procedure TConversas.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FConversas) do
    FConversas[I].Free;
  SetLength(FConversas, 0);
end;

{ TConversa }

class function TConversa.New(ID: Integer): TConversa;
begin
  Result := TConversa.Create;
  Result.FID := ID;
end;

constructor TConversa.Create;
begin
  FMensagens := TMensagens.Create(Self);
  MensagemSemVisualizar := 0;
end;

function TConversa.CriadoEm(const Value: TDateTime): TConversa;
begin
  Result := Self;
  FCriadoEm := Value;
end;

function TConversa.CriadoEm: TDateTime;
begin
  Result := FCriadoEm;
end;

destructor TConversa.Destroy;
begin
  FreeAndNil(FMensagens);
  inherited;
end;

function TConversa.ID: Integer;
begin
  Result := FID;
end;

function TConversa.ID(const Value: Integer): TConversa;
begin
  if FID <> 0 then
    raise Exception.Create('Impossível alterar ID de conversa que já tem ID!');

  FID := Value;
  Result := Self;
end;

function TConversa.Tipo: TTipoConversa;
begin
  Result := FTipo;
end;

function TConversa.Tipo(const Value: TTipoConversa): TConversa;
begin
  Result := Self;
  FTipo := Value;
end;

function TConversa.Descricao: String;
var
  D: TUsuario;
begin
  if not FDescricao.Trim.IsEmpty then
    Exit(FDescricao);

  D := Destinatario;
  if (FTipo = TTipoConversa.Chat) and Assigned(D) then
    Result := D.Nome;
end;

function TConversa.Descricao(const Value: String): TConversa;
begin
  if FTipo = TTipoConversa.Chat then
    FDescricao := EmptyStr
  else
    FDescricao := Value;

  Result := Self;
end;

function TConversa.UltimaMensagem: String;
begin
  Result := FUltimaMensagem;
end;

function TConversa.UltimaMensagem(const Value: String): TConversa;
begin
  FUltimaMensagem := Value;
  Result := Self;
end;

function TConversa.UltimaMensagemData: TDateTime;
begin
  Result := FUltimaMensagemData;
end;

function TConversa.UltimaMensagemData(const Value: TDateTime): TConversa;
begin
  FUltimaMensagemData := Value;
  Result := Self;
end;

function TConversa.UltimaMensagemID(const Value: INteger): TConversa;
begin
  FUltimaMensagemID := Value;
  Result := Self;
end;

function TConversa.UltimaMensagemID: Integer;
begin
  Result := FUltimaMensagemID;
end;

function TConversa.Destinatario: TUsuario;
begin
  for Result in FUsuarios do
    if Result <> Dados.FDadosApp.Usuario then
      Exit;

  Result := nil;
end;

function TConversa.Usuarios: TArrayUsuarios;
begin
  Result := FUsuarios;
end;

function TConversa.AddUsuario(const Usuario: TUsuario): TConversa;
var
  I: Integer;
begin
  Result := Self;

  // Valida se já tem
  for I := 0 to Pred(Length(FUsuarios)) do
    if FUsuarios[I].ID = Usuario.ID then
      Exit;

  FUsuarios := FUsuarios + [Usuario];
end;

{ TMensagens }

constructor TMensagens.Create(Owner: TConversa);
begin
  FConversa := Owner;
  FUltimaMensagemSincronizada := 0;
end;

destructor TMensagens.Destroy;
begin
  Clear;
  inherited;
end;

procedure TMensagens.Add(const Mensagem: TMensagem);
begin
  FMensagens := FMensagens + [Mensagem];
  FUltimaMensagemSincronizada := Max(FUltimaMensagemSincronizada, Mensagem.ID);


  if Assigned(FConversa) then
  begin
    if FConversa.UltimaMensagemID < Mensagem.ID then
    begin
      FConversa.UltimaMensagemData(Mensagem.Inserida);
      FConversa.UltimaMensagem(Mensagem.DescricaoSimples);
      FConversa.UltimaMensagemID(Mensagem.ID);
      TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizacaoListaConversa.Create(0));
    end;
  end;
end;

function TMensagens.Get(const ID: Integer): TMensagem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FMensagens) do
    if FMensagens[I].ID = ID then
      Exit(FMensagens[I]);
end;

function TMensagens.GetList(const Inicio: Integer): TArrayMensagens;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to High(FMensagens) do
    if FMensagens[I].ID >= Inicio then
      Result := Result + [FMensagens[I]];
end;

function TMensagens.Items: TArray<TMensagem>;
begin
  Result := FMensagens;
end;

function TMensagens.ParaExibir(const ApenasPendente: Boolean): TArrayMensagens;
var
  Mensagem: TMensagem;
begin
  Result := [];
  for Mensagem in FMensagens do
    if not ApenasPendente or not Mensagem.Exibida then
      Result := Result + [Mensagem.Exibida(True)];
end;

function TMensagens.ParaNotificar: TArrayMensagens;
var
  Mensagem: TMensagem;
begin
  Result := [];
  for Mensagem in FMensagens do
    if not Mensagem.Notificada and (Mensagem.Lado = TLadoMensagem.Esquerdo) then
      Result := Result + [Mensagem];
end;

function TMensagens.ParaAtualizar: TArrayMensagens;
var
  Mensagem: TMensagem;
begin
  Result := [];
  for Mensagem in FMensagens do
    if Mensagem.Lado = TLadoMensagem.Direito then
      if not Mensagem.Recebida or not Mensagem.Visualizada then
        Result := Result + [Mensagem];
end;

procedure TMensagens.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FMensagens) do
    FMensagens[I].Free;
  SetLength(FMensagens, 0);
end;

{ TMensagem }

class function TMensagem.New(ID: Integer): TMensagem;
begin
  Result := TMensagem.Create;
  Result.FID := ID;
  Result.FExibida := False;
end;

destructor TMensagem.Destroy;
begin
  Conteudos.Clear;
  inherited;
end;

function TMensagem.ID: Integer;
begin
  Result := FID;
end;

function TMensagem.ID(const Value: Integer): TMensagem;
begin
  if FID <> 0 then
    raise Exception.Create('Impossível alterar ID de mensagem que já tem ID!');

  FID := Value;
  Result := Self;
end;

function TMensagem.Conversa: TConversa;
begin
  Result := FConversa;
end;

function TMensagem.Conversa(const Value: TConversa): TMensagem;
begin
  FConversa := Value;
  Result := Self;
end;

function TMensagem.Remetente: TUsuario;
begin
  Result := FRemetente;
end;

function TMensagem.Remetente(const Value: TUsuario): TMensagem;
begin
  FRemetente := Value;
  Result := Self;
end;

function TMensagem.Lado: TLadoMensagem;
begin
  Result := FLado;
end;

function TMensagem.Lado(const Value: TLadoMensagem): TMensagem;
begin
  FLado := Value;
  Result := Self;
end;

function TMensagem.Alterada: TDateTime;
begin
  Result := FAlterada;
end;

function TMensagem.Alterada(const Value: TDateTime): TMensagem;
begin
  FAlterada := Value;
  Result := Self;
end;

function TMensagem.Inserida: TDateTime;
begin
  Result := FInserida;
end;

function TMensagem.Inserida(const Value: TDateTime): TMensagem;
begin
  FInserida := Value;
  Result := Self;
end;

function TMensagem.Exibida: Boolean;
begin
  Result := FExibida;
end;

function TMensagem.Exibida(const Value: Boolean): TMensagem;
begin
  if Value and (not FExibida) and FPrimeiraExibicao then
    PrimeiraExibicao(not FExibida);

  FExibida := Value;
  Result := Self;
end;

function TMensagem.Recebida: Boolean;
begin
  Result := FRecebida;
end;

function TMensagem.Recebida(const Value: Boolean): TMensagem;
begin
  Result := Self;
  if FRecebida = Value then
    Exit;

  FRecebida := Value;
  DoAoAtualizar;
end;

function TMensagem.Visualizada: Boolean;
begin
  Result := FVisualizada;
end;

function TMensagem.Visualizada(const Value: Boolean; const Sincronizar: Boolean = False): TMensagem;
begin
  Result := Self;
  if FVisualizada then
    Exit;

  if FVisualizada = Value then
    Exit;

  if (FLado = TLadoMensagem.Esquerdo) and not FVisualizada then
    if Assigned(FConversa) and (FConversa.MensagemSemVisualizar > 0) then
      Dec(FConversa.MensagemSemVisualizar);

  FVisualizada := Value;

  if (Lado = TLadoMensagem.Esquerdo) and Sincronizar then
    Dados.VisualizarMensagem(Self);

  DoAoAtualizar;
end;

function TMensagem.Notificada: Boolean;
begin
  Result := FNotificada;
end;

function TMensagem.Notificada(const Value: Boolean): TMensagem;
begin
  Result := Self;
  if FNotificada = Value then
    Exit;

  FNotificada := Value;
end;

function TMensagem.PrimeiraExibicao: Boolean;
begin
  Result := FPrimeiraExibicao;
end;

function TMensagem.PrimeiraExibicao(const Value: Boolean): TMensagem;
begin
  FPrimeiraExibicao := Value;
  Result := Self;
end;

function TMensagem.DescricaoSimples: String;
begin
  if Remetente = Dados.FDadosApp.Usuario then
    Result := 'Você: '
  else
  if Assigned(FRemetente) and Assigned(FConversa) and (FConversa.Tipo = TTipoConversa.Grupo) then
    Result := Remetente.Nome +': '
  else
    Result := EmptyStr;

  if Length(Conteudos) = 0 then
    Exit;

  case Conteudos[0].Tipo of
    TTipoConteudo.Texto :  Result := Result + Conteudos[0].Conteudo;
    TTipoConteudo.Imagem:  Result := Result +'📷 Imagem';
    TTipoConteudo.Arquivo: Result := Result +'📦 Arquivo';
  end;
end;

procedure TMensagem.DoAoAtualizar;
begin
  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizacaoMensagem.Create(FID));
  TMessageManager.DefaultManager.SendMessage(nil, TEventoContadorMensagemVisualizar.Create(0));
  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizarContadorConversa.Create(0));
end;

{ THConteudos }

procedure THConteudos.Add(const Conteudo: TConteudo);
begin
  Self := Self + [Conteudo];
end;

function THConteudos.Get(const ID: Integer): TConteudo;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(Self) do
    if Self[I].ID = ID then
      Exit(Self[I]);
end;

procedure THConteudos.Add(const Conteudo: TConteudos);
begin
  Self := Self + Conteudo;
end;

procedure THConteudos.Clear;
var
  I: Integer;
begin
  for I := 0 to High(Self) do
    Self[I].Free;
  SetLength(Self, 0);
end;

function THConteudos.Count: Integer;
begin
  Result := Length(Self);
end;

{ TConteudo }

class function TConteudo.New(ID: Integer): TConteudo;
begin
  Result := TConteudo.Create;
  Result.FID := ID;
end;

function TConteudo.ID: Integer;
begin
  Result := FID;
end;

function TConteudo.Tipo: TTipoConteudo;
begin
  Result := FTipo;
end;

function TConteudo.Tipo(const Value: TTipoConteudo): TConteudo;
begin
  FTipo := Value;
  Result := Self;
end;

function TConteudo.Ordem: Integer;
begin
  Result := FOrdem;
end;

function TConteudo.Ordem(const Value: Integer): TConteudo;
begin
  FOrdem := Value;
  Result := Self;
end;

function TConteudo.Conteudo: String;
begin
  Result := FConteudo;
end;

function TConteudo.Conteudo(const Value: String): TConteudo;
begin
  FConteudo := Value;
  Result := Self;
end;

function TConteudo.Nome: String;
begin
  Result := FNome;
end;

function TConteudo.Nome(const Value: String): TConteudo;
begin
  FNome := Value;
  Result := Self;
end;

function TConteudo.Extensao: String;
begin
  Result := FExtensao;
end;

function TConteudo.Extensao(const Value: String): TConteudo;
begin
  FExtensao := Value;
  Result := Self;
end;

{ THArrayConversas }

function THArrayConversas.OrdemAtualizacao: TArrayConversas;
begin
  // Copiar o array para a variável de resultado
  Result := Self;

  // Ordenar o array pela data da última mensagem (FUltimaMensagemData) em ordem decrescente
  TArray.Sort<TConversa>(Result, TComparer<TConversa>.Construct(
    function(const Anterior, Atual: TConversa): Integer
    begin
      if (Atual.FUltimaMensagemData = 0) and (Anterior.FUltimaMensagemData <> 0) then
        Result := CompareValue(Atual.FCriadoEm, Anterior.FUltimaMensagemData)
      else
      if (Atual.FUltimaMensagemData = 0) and (Anterior.FUltimaMensagemData = 0) then
        Result := CompareValue(Atual.FCriadoEm, Anterior.FCriadoEm)
      else
        Result := CompareValue(Atual.FUltimaMensagemData, Anterior.FUltimaMensagemData);
    end
  ));
end;


{ THArrayUsuarios }

function THArrayUsuarios.Count: Integer;
begin
  Result := Length(Self);
end;

{ THArrayMensagens }

function THArrayMensagens.OrdemTempo: TArrayMensagens;
begin
  // Copiar o array para a variável de resultado
  Result := Self;

  // Ordenar o array pela data da última mensagem (FUltimaMensagemData) em ordem decrescente
  TArray.Sort<TMensagem>(Result, TComparer<TMensagem>.Construct(
    function(const Anterior, Atual: TMensagem): Integer
    begin
//      if (Atual.Alterada = 0) and (Anterior.Alterada <> 0) then
//        Result := CompareValue(Atual.FCriadoEm, Anterior.FUltimaMensagemData)
//      else
      if (Atual.Alterada = 0) and (Anterior.Alterada = 0) then
        Result := CompareValue(Atual.Inserida, Anterior.Inserida)
      else
        Result := CompareValue(Atual.Alterada, Anterior.Alterada);
    end
  ));
end;

end.

