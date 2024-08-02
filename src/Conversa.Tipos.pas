// 2024-08-01
// Daniel, Eduardo
unit Conversa.Tipos;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections;

type
  TUsuario = class;
  TUsuarios = class;
  TConversa = class;
  TConversas = class;
  TMensagem = class;
  TMensagens = class;
  TConteudo = class;

  TUsuariosArray = TArray<TUsuario>;
  TMensagensArray = TArray<TMensagem>;
  TConteudos = TArray<TConteudo>;
  TPConteudos = ^TConteudos;

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
  end;

  TConversa = class
  private
    FID: Integer;
    FDescricao: String;
    FUltimaMensagem: String;
    FUltimaMensagemData: TDateTime;
    FUsuarios: TUsuariosArray;
    FUltimaMensagemId: Integer;
    FMensagens: TMensagens;
    FMensagemSemVisualizar: Integer;
  public
    class function New(ID: Integer): TConversa;
    constructor Create;
    destructor Destroy; override;

    property Mensagens: TMensagens read FMensagens;
    property MensagemSemVisualizar: Integer read FMensagemSemVisualizar;

    function ID: Integer; overload;
    function ID(const Value: Integer): TConversa; overload;
    function Descricao: String; overload;
    function UltimaMensagem: String; overload;
    function UltimaMensagemData: TDateTime; overload;
    function Descricao(const Value: String): TConversa; overload;
    function UltimaMensagem(const Value: String): TConversa; overload;
    function UltimaMensagemData(const Value: TDateTime): TConversa; overload;
    function UltimaMensagemID: Integer; overload;
    function UltimaMensagemID(const Value: INteger): TConversa; overload;

    function Usuarios: TUsuariosArray;
    function AddUsuario(const Usuario: TUsuario): TConversa;

    function Destinatario: TUsuario;
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
    FAoAtualizar: TProc<TMensagem>;
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
    function Conversa(const Value: TConversa): TMensagem; overload;
    function Remetente(const Value: TUsuario): TMensagem; overload;
    function Lado(const Value: TLadoMensagem): TMensagem; overload;
    function Alterada(const Value: TDateTime): TMensagem; overload;
    function Inserida(const Value: TDateTime): TMensagem; overload;
    function Exibida(const Value: Boolean): TMensagem; overload;
    function Recebida(const Value: Boolean): TMensagem; overload;
    function Visualizada(const Value: Boolean): TMensagem; overload;
    function Notificada(const Value: Boolean): TMensagem; overload;
    function AoAtualizar(const Value: TProc<TMensagem>): TMensagem;
  end;

  TTipoConteudo = (Nenhum, Texto, Imagem);
  TConteudo = class
  private
    FID: Integer;
    FTipo: TTipoConteudo;
    FOrdem: Integer;
    FConteudo: String;
  public
    UltimaMensagemAdicionada: Integer;
    class function New(ID: Integer): TConteudo;
    function ID: Integer; overload;
    function Tipo: TTipoConteudo; overload;
    function Ordem: Integer; overload;
    function Conteudo: String; overload;
    function Tipo(const Value: TTipoConteudo): TConteudo; overload;
    function Ordem(const Value: Integer): TConteudo; overload;
    function Conteudo(const Value: String): TConteudo; overload;
  end;

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

  TConversas = class
  private
    FConversas: TArray<TConversa>;
  public
    destructor Destroy; override;
    procedure Add(const Conversa: TConversa);
    function Get(const ID: Integer): TConversa;
    function GetOrAdd(const ID: Integer): TConversa;
    function Items: TArray<TConversa>;
    function MensagensSemVisualizar: Integer;
    procedure Clear;
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
    function GetList(const Inicio: Integer): TMensagensArray; overload;
    procedure Clear;
    function Items: TArray<TMensagem>;
    function ParaExibir: TMensagensArray;
    function ParaNotificar: TMensagensArray;
    function ParaAtualizar: TMensagensArray;
  end;

  THConteudos = record Helper for TConteudos
  public
    procedure Add(const Conteudo: TConteudo); overload;
    procedure Add(const Conteudo: TConteudos); overload;
    function Get(const ID: Integer): TConteudo;
    function Count: Integer;
    procedure Clear;
  end;

implementation

uses
  Conversa.Dados;

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

{ TConversa }

class function TConversa.New(ID: Integer): TConversa;
begin
  Result := TConversa.Create;
  Result.FID := ID;
end;

constructor TConversa.Create;
begin
  FMensagens := TMensagens.Create(Self);
  FMensagemSemVisualizar := 0;
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

function TConversa.Descricao: String;
begin
  Result := FDescricao;
end;

function TConversa.Descricao(const Value: String): TConversa;
begin
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

function TConversa.Usuarios: TUsuariosArray;
begin
  Result := FUsuarios;
end;

function TConversa.AddUsuario(const Usuario: TUsuario): TConversa;
var
  I: Integer;
begin
  Result := Self;

  for I := 0 to Pred(Length(FUsuarios)) do
    if FUsuarios[I].ID = Usuario.ID then
      Exit;

  FUsuarios := FUsuarios + [Usuario];
end;

{ TMensagem }

class function TMensagem.New(ID: Integer): TMensagem;
begin
  Result := TMensagem.Create;
  Result.FID := ID;
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

function TMensagem.Visualizada(const Value: Boolean): TMensagem;
begin
  Result := Self;
  if FVisualizada = Value then
    Exit;


  if (FLado <> TLadoMensagem.Direito) and not FVisualizada and Value and Assigned(FConversa) then
    Dec(FConversa.FMensagemSemVisualizar);

  FVisualizada := Value;
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

function TMensagem.AoAtualizar(const Value: TProc<TMensagem>): TMensagem;
begin
  Result := Self;
  FAoAtualizar := Value;
end;

procedure TMensagem.DoAoAtualizar;
begin
  if Assigned(FAoAtualizar) then
    FAoAtualizar(Self);

  Dados.AtualizarContador;
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

{ TConversas }

destructor TConversas.Destroy;
begin
  Clear;
  inherited;
end;

procedure TConversas.Add(const Conversa: TConversa);
begin
  SetLength(FConversas, Length(FConversas) + 1);
  FConversas[High(FConversas)] := Conversa;
end;

function TConversas.Get(const ID: Integer): TConversa;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FConversas) do
  begin
    if FConversas[I].ID = ID then
    begin
      Result := FConversas[I];
      Exit;
    end;
  end;
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

function TConversas.Items: TArray<TConversa>;
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

procedure TConversas.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FConversas) do
    FConversas[I].Free;
  SetLength(FConversas, 0);
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
  SetLength(FMensagens, Length(FMensagens) + 1);
  FMensagens[High(FMensagens)] := Mensagem;

  if Mensagem.Visualizada then
    Inc(FConversa.FMensagemSemVisualizar);

  FUltimaMensagemSincronizada := Max(FUltimaMensagemSincronizada, Mensagem.ID);
end;

function TMensagens.Get(const ID: Integer): TMensagem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FMensagens) do
  begin
    if FMensagens[I].ID = ID then
    begin
      Result := FMensagens[I];
      Exit;
    end;
  end;
end;

function TMensagens.GetList(const Inicio: Integer): TMensagensArray;
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

function TMensagens.ParaExibir: TMensagensArray;
var
  Mensagem: TMensagem;
begin
  Result := [];
  for Mensagem in FMensagens do
    if not Mensagem.Exibida then
      Result := Result + [Mensagem.Exibida(True)];
end;

function TMensagens.ParaNotificar: TMensagensArray;
var
  Mensagem: TMensagem;
begin
  Result := [];
  for Mensagem in FMensagens do
    if not Mensagem.Notificada then
      Result := Result + [Mensagem];
end;

function TMensagens.ParaAtualizar: TMensagensArray;
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

{ THConteudos }

procedure THConteudos.Add(const Conteudo: TConteudo);
begin
  SetLength(Self, Length(Self) + 1);
  Self[High(Self)] := Conteudo;
end;

function THConteudos.Get(const ID: Integer): TConteudo;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(Self) do
  begin
    if Self[I].ID = ID then
    begin
      Result := Self[I];
      Exit;
    end;
  end;
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

end.

