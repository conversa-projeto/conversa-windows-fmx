// Eduardo - 11/02/2024
unit Mensagem.Tipos;

interface

uses
  System.SysUtils,
  System.Generics.Collections, // Inclui a unidade para TList
  FMX.Graphics,
  FMX.Types; // Inclui a unidade FMX.Types para TFmxObject

{$SCOPEDENUMS ON}

type
  TLado = (Esquerdo, Direito);

  TMensagemConteudo = class
  private
    Fid: Integer;
    Ftipo: Integer;
    Fordem: Integer;
    Fconteudo: String;
  public
    class function New: TMensagemConteudo;
    property id: Integer read Fid write Fid;
    property tipo: Integer read Ftipo write Ftipo;
    property ordem: Integer read Fordem write Fordem;
    property conteudo: String read Fconteudo write Fconteudo;
  end;

  TMensagem = class
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
    Fconteudos: TObjectList<TMensagemConteudo>;
    FAoAtualizar: TProc<TMensagem>;
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
    function GetConteudos: TObjectList<TMensagemConteudo>;
    procedure SetConteudos(Value: TObjectList<TMensagemConteudo>);
    function GetVisualizada: Boolean;
    procedure SetVisualizada(const Value: Boolean);
    function GetNotificada: Boolean;
    procedure SetNotificada(const Value: Boolean);
    function GetRecebida: Boolean;
    procedure SetRecebida(const Value: Boolean);
    procedure DoAtualizar;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: TMensagem;
    property Id: Integer read GetId write SetId;
    property RemetenteId: Integer read GetRemetenteId write SetRemetenteId;
    property Remetente: String read GetRemetente write SetRemetente;
    property Lado: TLado read GetLado write SetLado;
    property ConversaId: Integer read GetConversaId write SetConversaId;
    property Alterada: TDateTime read GetAlterada write SetAlterada;
    property Inserida: TDateTime read GetInserida write SetInserida;
    property Exibida: Boolean read GetExibida write SetExibida;
    property Conteudos: TObjectList<TMensagemConteudo> read GetConteudos write SetConteudos;
    property Recebida: Boolean read GetRecebida write SetRecebida;
    property Visualizada: Boolean read GetVisualizada write SetVisualizada;
    property Notificada: Boolean read GetNotificada write SetNotificada;
    procedure VisualizarMensagem;
    procedure AoAtualizar(Value: TProc<TMensagem>);
  end;
  TMensagens = TArray<TMensagem>;

implementation

uses
  Conversa.Dados,
  Conversa.Log;

{ TMensagemConteudo }

class function TMensagemConteudo.New: TMensagemConteudo;
begin
  Result := TMensagemConteudo.Create;
end;

{ TMensagem }

constructor TMensagem.Create;
begin
  inherited;
  Fconteudos := TObjectList<TMensagemConteudo>.Create;
end;

destructor TMensagem.Destroy;
begin
  FreeAndNil(Fconteudos);
  inherited Destroy;
end;

class function TMensagem.New: TMensagem;
begin
  Result := TMensagem.Create;
end;

function TMensagem.GetId: Integer;
begin
  AddLog('Início: GetId');
  try
    Result := Fid;
  finally
    AddLog('Fim: GetId');
  end;
end;

procedure TMensagem.SetId(Value: Integer);
begin
  AddLog('Início: SetId');
  try
    Fid := Value;
  finally
    AddLog('Fim: SetId');
  end;
end;

function TMensagem.GetRemetenteId: Integer;
begin
  AddLog('Início: GetRemetenteId');
  try
    Result := Fremetente_id;
  finally
    AddLog('Fim: GetRemetenteId');
  end;
end;

procedure TMensagem.SetRemetenteId(Value: Integer);
begin
  AddLog('Início: SetRemetenteId');
  try
    Fremetente_id := Value;
  finally
    AddLog('Fim: SetRemetenteId');
  end;
end;

function TMensagem.GetRemetente: String;
begin
  AddLog('Início: GetRemetente');
  try
    Result := Fremetente;
  finally
    AddLog('Fim: GetRemetente');
  end;
end;

procedure TMensagem.SetRemetente(Value: String);
begin
  AddLog('Início: SetRemetente');
  try
    Fremetente := Value;
  finally
    AddLog('Fim: SetRemetente');
  end;
end;

function TMensagem.GetLado: TLado;
begin
  AddLog('Início: GetLado');
  try
    Result := Flado;
  finally
    AddLog('Fim: GetLado');
  end;
end;

procedure TMensagem.SetLado(Value: TLado);
begin
  AddLog('Início: SetLado');
  try
    Flado := Value;
  finally
    AddLog('Fim: SetLado');
  end;
end;

function TMensagem.GetConversaId: Integer;
begin
  AddLog('Início: GetConversaId');
  try
    Result := Fconversa_id;
  finally
    AddLog('Fim: GetConversaId');
  end;
end;

procedure TMensagem.SetConversaId(Value: Integer);
begin
  AddLog('Início: SetConversaId');
  try
    Fconversa_id := Value;
  finally
    AddLog('Fim: SetConversaId');
  end;
end;

function TMensagem.GetAlterada: TDateTime;
begin
  AddLog('Início: GetAlterada');
  try
    Result := Falterada;
  finally
    AddLog('Fim: GetAlterada');
  end;
end;

procedure TMensagem.SetAlterada(Value: TDateTime);
begin
  AddLog('Início: SetAlterada');
  try
    Falterada := Value;
  finally
    AddLog('Fim: SetAlterada');
  end;
end;

function TMensagem.GetInserida: TDateTime;
begin
  AddLog('Início: GetInserida');
  try
    Result := Finserida;
  finally
    AddLog('Fim: GetInserida');
  end;
end;

procedure TMensagem.SetInserida(Value: TDateTime);
begin
  AddLog('Início: SetInserida');
  try
    Finserida := Value;
  finally
    AddLog('Fim: SetInserida');
  end;
end;

function TMensagem.GetExibida: Boolean;
begin
  AddLog('Início: GetExibida');
  try
    Result := Fexibida;
  finally
    AddLog('Fim: GetExibida');
  end;
end;

procedure TMensagem.SetExibida(Value: Boolean);
begin
  AddLog('Início: SetExibida');
  try
    Fexibida := Value;
  finally
    AddLog('Fim: SetExibida');
  end;
end;

function TMensagem.GetConteudos: TObjectList<TMensagemConteudo>;
begin
  AddLog('Início: GetConteudos');
  try
    Result := Fconteudos;
  finally
    AddLog('Fim: GetConteudos');
  end;
end;

procedure TMensagem.SetConteudos(Value: TObjectList<TMensagemConteudo>);
begin
  AddLog('Início: SetConteudos');
  try
    Fconteudos := Value;
  finally
    AddLog('Fim: SetConteudos');
  end;
end;

function TMensagem.GetRecebida: Boolean;
begin
  AddLog('Início: GetRecebida');
  try
    Result := Frecebida;
  finally
    AddLog('Fim: GetRecebida');
  end;
end;

procedure TMensagem.SetRecebida(const Value: Boolean);
begin
  AddLog('Início: SetRecebida');
  try
    if Frecebida = Value then
      Exit;
    Frecebida := Value;
    DoAtualizar;
  finally
    AddLog('Fim: SetRecebida');
  end;
end;

function TMensagem.GetVisualizada: Boolean;
begin
  AddLog('Início: GetVisualizada');
  try
    Result := Fvisualizada;
  finally
    AddLog('Fim: GetVisualizada');
  end;
end;

procedure TMensagem.SetVisualizada(const Value: Boolean);
begin
  AddLog('Início: SetVisualizada');
  try
    if Fvisualizada = Value then
      Exit;
    Fvisualizada := Value;
    DoAtualizar;
  finally
    AddLog('Fim: SetVisualizada');
  end;
end;

function TMensagem.GetNotificada: Boolean;
begin
  AddLog('Início: GetNotificada');
  try
    Result := Fnotificada;
  finally
    AddLog('Fim: GetNotificada');
  end;
end;

procedure TMensagem.SetNotificada(const Value: Boolean);
begin
  AddLog('Início: SetNotificada');
  try
    Fnotificada := Value;
  finally
    AddLog('Fim: SetNotificada');
  end;
end;

procedure TMensagem.VisualizarMensagem;
begin
  AddLog('Início: VisualizarMensagem');
  try
    if not Fvisualizada then
    begin
      Fvisualizada := True;
      if Assigned(FAoAtualizar) then
        FAoAtualizar(Self);
    end;
  finally
    AddLog('Fim: VisualizarMensagem');
  end;
end;

procedure TMensagem.AoAtualizar(Value: TProc<TMensagem>);
begin
  AddLog('Início: AoAtualizar');
  try
    FAoAtualizar := Value;
  finally
    AddLog('Fim: AoAtualizar');
  end;
end;

procedure TMensagem.DoAtualizar;
begin
  if Assigned(FAoAtualizar) then
    FAoAtualizar(Self);
end;

end.

