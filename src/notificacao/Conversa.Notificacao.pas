unit Conversa.Notificacao;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  FMX.Types;

type
  TMensagemNotificacao = record
  private
    FID: Integer;
    FUsuario: string;
    FMensagem: string;
  public
    class function New: TMensagemNotificacao; static;
    function ID: String; overload;
    function ID(const Value: Integer): TMensagemNotificacao; overload;
    function Usuario: String; overload;
    function Usuario(const Value: string): TMensagemNotificacao; overload;
    function Mensagem: String; overload;
    function Mensagem(const Value: string): TMensagemNotificacao; overload;
  end;

  TNotificacao = record
  private
    FView: TFmxObject;
    FChatId: Integer;
    FNome: string;
    FHora: TDateTime;
    FConteudo: TArray<TMensagemNotificacao>;
  public
    class function New: TNotificacao; static;
    function ChatId: Integer; overload;
    function ChatId(const AChatId: Integer): TNotificacao; overload;
    function Nome(const ANome: string): TNotificacao;
    function Hora(const AHora: TDateTime): TNotificacao;
    function Conteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao; overload;
    function AddConteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao; overload;
    function Conteudo(const Texto: string): TNotificacao; overload;
  end;

  TNotificacaoManager = class
  private
    FVisualizador: TFmxObject;
    FNotificacoes: TList<TNotificacao>;
    constructor Create;
    procedure AtualizarVisualizador;
    function InternalApresentar(ANotificacao: TNotificacao): TNotificacaoManager;
    function InternalFechar(ChatId: Integer): TNotificacaoManager;
  public
    destructor Destroy; override;
    class function Instance: TNotificacaoManager;
    class function Apresentar(Value: TNotificacao): TNotificacaoManager; overload;
    class function Fechar(ChatId: Integer): TNotificacaoManager;
    function Count: Integer;
    class procedure Finalizar;
  end;
implementation
uses
  Conversa.Notificacao.Visualizador,
  Conversa.Notificacao.Item,
  FMX.Forms;

var
  FInstance: TNotificacaoManager;

type
  TNotificacaoManagerH = class Helper for TNotificacaoManager
    function Visualizador: TNotificacaoVisualizador;
  end;

{ TNotificacaoManager }

function TNotificacaoManager.Count: Integer;
begin
  Result := FNotificacoes.Count;
end;

constructor TNotificacaoManager.Create;
begin
  FNotificacoes := TList<TNotificacao>.Create;
end;

destructor TNotificacaoManager.Destroy;
begin
  FreeAndNil(FNotificacoes);
  FreeAndNil(FVisualizador);
  inherited;
end;

class function TNotificacaoManager.Fechar(ChatId: Integer): TNotificacaoManager;
begin
  Result := Instance.InternalFechar(ChatId);
end;

class procedure TNotificacaoManager.Finalizar;
begin
  FreeAndNil(FInstance);
end;

class function TNotificacaoManager.Instance: TNotificacaoManager;
begin
  if Assigned(FInstance) then
    Exit(FInstance);

  Result := TNotificacaoManager.Create;
  FInstance := Result;
end;

class function TNotificacaoManager.Apresentar(Value: TNotificacao): TNotificacaoManager;
begin
  Result := Instance.InternalApresentar(Value);
end;

function TNotificacaoManager.InternalApresentar(ANotificacao: TNotificacao): TNotificacaoManager;
var
  I: Integer;
begin
  Result := Self;

  for I := 0 to Pred(FNotificacoes.Count) do
  begin
    if FNotificacoes[I].ChatId = ANotificacao.ChatId then
    begin
      FNotificacoes[I] := FNotificacoes[I].AddConteudo(ANotificacao.FConteudo);
      Exit;
    end;
  end;

  ANotificacao.FView := TNotificacaoItem.New(Visualizador);
  with TNotificacaoItem(ANotificacao.FView) do
  begin
    txtNome.Text := ANotificacao.FNome;
    txtHora.Text := TimeToStr(ANotificacao.FHora);
    AtualizarConteudo(ANotificacao.ChatId, ANotificacao.FConteudo);
  end;

  FNotificacoes.Add(ANotificacao);

  AtualizarVisualizador;
end;

function TNotificacaoManager.InternalFechar(ChatId: Integer): TNotificacaoManager;
var
  I: Integer;
begin
  Result := Self;
  for I := 0 to Pred(FNotificacoes.Count) do
  begin
    if FNotificacoes[I].ChatId = ChatId then
    begin
      FNotificacoes[I].FView.Free;
      FNotificacoes.Delete(I);
      Break;
    end;
  end;

  AtualizarVisualizador;
end;

procedure TNotificacaoManager.AtualizarVisualizador;
var
  I: Integer;
  Altura: Single;
begin
  Altura := 0;
  for I := 0 to Pred(FNotificacoes.Count) do
    if Assigned(FNotificacoes[I].FView) then
      Altura := Altura + TFrame(FNotificacoes[I].FView).Height;

  Visualizador.Exibir(Altura);
end;

{ TConteudo }

class function TMensagemNotificacao.New: TMensagemNotificacao;
begin
  Result := Default(TMensagemNotificacao);
end;

function TMensagemNotificacao.ID: String;
begin
  Result := Self.FUsuario;
end;

function TMensagemNotificacao.ID(const Value: Integer): TMensagemNotificacao;
begin
  Result := Self;
  Result.FID := Value;
end;

function TMensagemNotificacao.Usuario: String;
begin
  Result := Self.FUsuario;
end;

function TMensagemNotificacao.Usuario(const Value: string): TMensagemNotificacao;
begin
  Result := Self;
  Result.FUsuario := Value;
end;

function TMensagemNotificacao.Mensagem: String;
begin
  Result := Self.FMensagem;
end;

function TMensagemNotificacao.Mensagem(const Value: string): TMensagemNotificacao;
begin
  Result := Self;
  Result.FMensagem := Value;
end;

{ TNotificacao }

class function TNotificacao.New: TNotificacao;
begin
  Result := Default(TNotificacao);
end;

function TNotificacao.ChatId(const AChatId: Integer): TNotificacao;
begin
  Result := Self;
  Result.FChatId := AChatId;
end;

function TNotificacao.Nome(const ANome: string): TNotificacao;
begin
  Result := Self;
  Result.FNome := ANome;
  if Assigned(FView) then
    TNotificacaoItem(FView).txtNome.Text := Result.FNome;
end;

function TNotificacao.Hora(const AHora: TDateTime): TNotificacao;
begin
  Result := Self;
  Result.FHora := AHora;
  if Assigned(FView) then
    TNotificacaoItem(FView).txtHora.Text := TimeToStr(Result.FHora);
end;

function TNotificacao.Conteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao;
begin
  Result := Self;
  Result.FConteudo := AConteudo;

  if Assigned(FView) then
    TNotificacaoItem(FView).AtualizarConteudo(Result.ChatId, Result.FConteudo);
end;

function TNotificacao.AddConteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao;
begin
  Result := Self.Conteudo(Self.FConteudo + AConteudo);
end;

function TNotificacao.ChatId: Integer;
begin
  Result := FChatId;
end;

function TNotificacao.Conteudo(const Texto: string): TNotificacao;
begin
  Result := Self;
  SetLength(Result.FConteudo, Length(Result.FConteudo) + 1);
  Result.FConteudo[High(Result.FConteudo)] := TMensagemNotificacao.New.Mensagem(Texto);
end;

{ TNotificacaoManagerH }

function TNotificacaoManagerH.Visualizador: TNotificacaoVisualizador;
begin
  if not Assigned(FVisualizador) then
    FVisualizador := TNotificacaoVisualizador.Create(nil);

  Result := TNotificacaoVisualizador(FVisualizador);
end;

end.
