// Eduardo - 11/02/2024
unit Mensagem.Tipos;

interface

uses
  System.SysUtils,
  FMX.Graphics;

{$SCOPEDENUMS ON}

type
  TLado = (Esquerdo, Direito);

  TMensagemConteudo = record
    id: Integer;
    tipo: Integer;
    ordem: Integer;
    conteudo: String
  end;

  TPMensagem = ^TMensagem;
  TMensagem = record
  private
    Fid: Integer;
    Fremetente_id: Integer;
    Fremetente: String;
    Flado: TLado;
    Fconversa_id: Integer;
    Falterada: TDateTime;
    Finserida: TDateTime;
    Fexibida: Boolean;
    Frecebida: Boolean;
    Fvisualizada: Boolean;
    Fnotificada: Boolean;
    Fconteudos: TArray<TMensagemConteudo>;
    FAoAtualizar: TArray<TProc<TPMensagem>>;
  end;
  TMensagens = TArray<TMensagem>;

  TMensagemH = record helper for TMensagem
  private
    function GetId: Integer;
    procedure SetId(Value: Integer);
    function GetRemetenteId: Integer;
    procedure SetRemetenteId(Value: Integer);
    function GetRemetente: String;
    procedure SetRemetente(Value: String);
    function GetLado: TLado;
    procedure SetLado(Value: TLado);
    function GetConversaId: Integer;
    procedure SetConversaId(Value: Integer);
    function GetAlterada: TDateTime;
    procedure SetAlterada(Value: TDateTime);
    function GetInserida: TDateTime;
    procedure SetInserida(Value: TDateTime);
    function GetExibida: Boolean;
    procedure SetExibida(Value: Boolean);
    function GetConteudos: TArray<TMensagemConteudo>;
    procedure SetConteudos(Value: TArray<TMensagemConteudo>);
    function GetVisualizada: Boolean;
    procedure SetVisualizada(const Value: Boolean);
    function GetNotificada: Boolean;
    procedure SetNotificada(const Value: Boolean);
    function GetRecebida: Boolean;
    procedure SetRecebida(const Value: Boolean);
    procedure DoAtualizar;
  public
    property Id: Integer read GetId write SetId;
    property RemetenteId: Integer read GetRemetenteId write SetRemetenteId;
    property Remetente: String read GetRemetente write SetRemetente;
    property Lado: TLado read GetLado write SetLado;
    property ConversaId: Integer read GetConversaId write SetConversaId;
    property Alterada: TDateTime read GetAlterada write SetAlterada;
    property Inserida: TDateTime read GetInserida write SetInserida;
    property Exibida: Boolean read GetExibida write SetExibida;
    property Conteudos: TArray<TMensagemConteudo> read GetConteudos write SetConteudos;
    property Recebida: Boolean read GetRecebida write SetRecebida;
    property Visualizada: Boolean read GetVisualizada write SetVisualizada;
    property Notificada: Boolean read GetNotificada write SetNotificada;
    procedure VisualizarMensagem;
    procedure AoAtualizar(Value: TProc<TPMensagem>);
  end;
  TPMensagems = TArray<TPMensagem>;

implementation

uses
  Conversa.Dados;

{ TPMensagemH }

function TMensagemH.GetId: Integer;
begin
  Result := Self.Fid;
end;

procedure TMensagemH.SetId(Value: Integer);
begin
  Self.Fid := Value;
end;

function TMensagemH.GetRemetenteId: Integer;
begin
  Result := Self.Fremetente_id;
end;

procedure TMensagemH.SetRemetenteId(Value: Integer);
begin
  Self.Fremetente_id := Value;
end;

function TMensagemH.GetRemetente: String;
begin
  Result := Self.Fremetente;
end;

procedure TMensagemH.SetRemetente(Value: String);
begin
  Self.Fremetente := Value;
end;

function TMensagemH.GetLado: TLado;
begin
  Result := Self.Flado;
end;

procedure TMensagemH.SetLado(Value: TLado);
begin
  Self.Flado := Value;
end;

function TMensagemH.GetConversaId: Integer;
begin
  Result := Self.Fconversa_id;
end;

procedure TMensagemH.SetConversaId(Value: Integer);
begin
  Self.Fconversa_id := Value;
end;

function TMensagemH.GetAlterada: TDateTime;
begin
  Result := Self.Falterada;
end;

procedure TMensagemH.SetAlterada(Value: TDateTime);
begin
  Self.Falterada := Value;
end;

function TMensagemH.GetInserida: TDateTime;
begin
  Result := Self.Finserida;
end;

procedure TMensagemH.SetInserida(Value: TDateTime);
begin
  Self.Finserida := Value;
end;

function TMensagemH.GetExibida: Boolean;
begin
  Result := Self.Fexibida;
end;

procedure TMensagemH.SetExibida(Value: Boolean);
begin
  Self.Fexibida := Value;
end;

function TMensagemH.GetConteudos: TArray<TMensagemConteudo>;
begin
  Result := Self.Fconteudos;
end;

procedure TMensagemH.SetConteudos(Value: TArray<TMensagemConteudo>);
begin
  Self.Fconteudos := Value;
end;

function TMensagemH.GetRecebida: Boolean;
begin
  Result := Self.FRecebida;
end;

procedure TMensagemH.SetRecebida(const Value: Boolean);
begin
  if Frecebida = Value then
    Exit;

  Self.Frecebida := Value;
  DoAtualizar;
end;

function TMensagemH.GetVisualizada: Boolean;
begin
  Result := Self.Fvisualizada;
end;

procedure TMensagemH.SetVisualizada(const Value: Boolean);
begin
  if Fvisualizada = Value then
    Exit;

  Self.Fvisualizada := Value;
  DoAtualizar;
end;

function TMensagemH.GetNotificada: Boolean;
begin
  Result := Self.Fnotificada;
end;

procedure TMensagemH.SetNotificada(const Value: Boolean);
begin
  Self.Fnotificada := Value;
end;

procedure TMensagemH.VisualizarMensagem;
begin
  if Visualizada then
    Exit;

  Self.Visualizada := True;
  Dados.AtualizarContador;
  Dados.VisualizarMensagem(@Self);
end;

procedure TMensagemH.AoAtualizar(Value: TProc<TPMensagem>);
begin
  Self.FAoAtualizar := Self.FAoAtualizar + [Value];
end;

procedure TMensagemH.DoAtualizar;
var
  Proc: TProc<TPMensagem>;
begin
  try
    if Length(FAoAtualizar) > 0 then
      for Proc in FAoAtualizar do
        if Assigned(Proc) then
          Proc(@Self);
  except
    Sleep(0);
  end;
end;

end.
