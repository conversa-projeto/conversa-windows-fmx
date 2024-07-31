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
  Conversa.Dados,
  Conversa.Log;


procedure AddLog(Msg: String);
begin
end;

{ TPMensagemH }

function TMensagemH.GetId: Integer;
begin
  AddLog('Início: GetId');
  try
    Result := Self.Fid;
  finally
    AddLog('Fim: GetId');
  end;
end;

procedure TMensagemH.SetId(Value: Integer);
begin
  AddLog('Início: SetId');
  try
    Self.Fid := Value;
  finally
    AddLog('Fim: SetId');
  end;
end;

function TMensagemH.GetRemetenteId: Integer;
begin
  AddLog('Início: GetRemetenteId');
  try
    Result := Self.Fremetente_id;
  finally
    AddLog('Fim: GetRemetenteId');
  end;
end;

procedure TMensagemH.SetRemetenteId(Value: Integer);
begin
  AddLog('Início: SetRemetenteId');
  try
    Self.Fremetente_id := Value;
  finally
    AddLog('Fim: SetRemetenteId');
  end;
end;

function TMensagemH.GetRemetente: String;
begin
  AddLog('Início: GetRemetente');
  try
    Result := Self.Fremetente;
  finally
    AddLog('Fim: GetRemetente');
  end;
end;

procedure TMensagemH.SetRemetente(Value: String);
begin
  AddLog('Início: SetRemetente');
  try
    Self.Fremetente := Value;
  finally
    AddLog('Fim: SetRemetente');
  end;
end;

function TMensagemH.GetLado: TLado;
begin
  AddLog('Início: GetLado');
  try
    Result := Self.Flado;
  finally
    AddLog('Fim: GetLado');
  end;
end;

procedure TMensagemH.SetLado(Value: TLado);
begin
  AddLog('Início: SetLado');
  try
    Self.Flado := Value;
  finally
    AddLog('Fim: SetLado');
  end;
end;

function TMensagemH.GetConversaId: Integer;
begin
  AddLog('Início: GetConversaId');
  try
    Result := Self.Fconversa_id;
  finally
    AddLog('Fim: GetConversaId');
  end;
end;

procedure TMensagemH.SetConversaId(Value: Integer);
begin
  AddLog('Início: SetConversaId');
  try
    Self.Fconversa_id := Value;
  finally
    AddLog('Fim: SetConversaId');
  end;
end;

function TMensagemH.GetAlterada: TDateTime;
begin
  AddLog('Início: GetAlterada');
  try
    Result := Self.Falterada;
  finally
    AddLog('Fim: GetAlterada');
  end;
end;

procedure TMensagemH.SetAlterada(Value: TDateTime);
begin
  AddLog('Início: SetAlterada');
  try
    Self.Falterada := Value;
  finally
    AddLog('Fim: SetAlterada');
  end;
end;

function TMensagemH.GetInserida: TDateTime;
begin
  AddLog('Início: GetInserida');
  try
    Result := Self.Finserida;
  finally
    AddLog('Fim: GetInserida');
  end;
end;

procedure TMensagemH.SetInserida(Value: TDateTime);
begin
  AddLog('Início: SetInserida');
  try
    Self.Finserida := Value;
  finally
    AddLog('Fim: SetInserida');
  end;
end;

function TMensagemH.GetExibida: Boolean;
begin
  AddLog('Início: GetExibida');
  try
    Result := Self.Fexibida;
  finally
    AddLog('Fim: GetExibida');
  end;
end;

procedure TMensagemH.SetExibida(Value: Boolean);
begin
  AddLog('Início: SetExibida');
  try
    Self.Fexibida := Value;
  finally
    AddLog('Fim: SetExibida');
  end;
end;

function TMensagemH.GetConteudos: TArray<TMensagemConteudo>;
begin
  AddLog('Início: GetConteudos');
  try
    Result := Self.Fconteudos;
  finally
    AddLog('Fim: GetConteudos');
  end;
end;

procedure TMensagemH.SetConteudos(Value: TArray<TMensagemConteudo>);
begin
  AddLog('Início: SetConteudos');
  try
    Self.Fconteudos := Value;
  finally
    AddLog('Fim: SetConteudos');
  end;
end;

function TMensagemH.GetRecebida: Boolean;
begin
  AddLog('Início: GetRecebida');
  try
    Result := Self.FRecebida;
  finally
    AddLog('Fim: GetRecebida');
  end;
end;

procedure TMensagemH.SetRecebida(const Value: Boolean);
begin
  AddLog('Início: SetRecebida');
  try
    if Frecebida = Value then
      Exit;

    Self.Frecebida := Value;
    DoAtualizar;
  finally
    AddLog('Fim: SetRecebida');
  end;
end;

function TMensagemH.GetVisualizada: Boolean;
begin
  AddLog('Início: GetVisualizada');
  try
    Result := Self.Fvisualizada;
  finally
    AddLog('Fim: GetVisualizada');
  end;
end;

procedure TMensagemH.SetVisualizada(const Value: Boolean);
begin
  AddLog('Início: SetVisualizada');
  try
    if Fvisualizada = Value then
      Exit;

    Self.Fvisualizada := Value;
    DoAtualizar;
  finally
    AddLog('Fim: SetVisualizada');
  end;
end;

function TMensagemH.GetNotificada: Boolean;
begin
  AddLog('Início: GetNotificada');
  try
    Result := Self.Fnotificada;
  finally
    AddLog('Fim: GetNotificada');
  end;
end;

procedure TMensagemH.SetNotificada(const Value: Boolean);
begin
  AddLog('Início: SetNotificada');
  try
    Self.Fnotificada := Value;
  finally
    AddLog('Fim: SetNotificada');
  end;
end;

procedure TMensagemH.VisualizarMensagem;
begin
  AddLog('Início: VisualizarMensagem');
  try
    if Visualizada then
      Exit;

    Self.Visualizada := True;
    Dados.AtualizarContador;
    Dados.VisualizarMensagem(@Self);
  finally
    AddLog('Fim: VisualizarMensagem');
  end;
end;

procedure TMensagemH.AoAtualizar(Value: TProc<TPMensagem>);
begin
  AddLog('Início: AoAtualizar');
  try
    Self.FAoAtualizar := Self.FAoAtualizar + [Value];
  finally
    AddLog('Fim: AoAtualizar');
  end;
end;

procedure TMensagemH.DoAtualizar;
var
  Proc: TProc<TPMensagem>;
begin
  AddLog('Início: DoAtualizar');
  try
    if Length(FAoAtualizar) > 0 then
      for Proc in FAoAtualizar do
        if Assigned(Proc) then
          Proc(@Self);
  finally
    AddLog('Fim: DoAtualizar');
  end;
end;

end.

