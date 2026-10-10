unit Conversa.Notificacao;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  FMX.Types,
  Conversa.Notificacao.Tipos;

type
  TTipoNotificacao = Conversa.Notificacao.Tipos.TTipoNotificacao;
  TMensagemNotificacao = Conversa.Notificacao.Tipos.TMensagemNotificacao;
  TNotificacaoChamadaDados = Conversa.Notificacao.Tipos.TNotificacaoChamadaDados;

  TNotificacao = record
  private
    FView: TFmxObject;
    FTipo: TTipoNotificacao;
    FChave: String;
    FChatId: Integer;
    FChamadaId: Integer;
    FNome: string;
    FHora: TDateTime;
    FConteudo: TArray<TMensagemNotificacao>;
    FChamadaDados: TNotificacaoChamadaDados;
    function GerarChave: String;
  public
    class function New: TNotificacao; static;
    function Tipo: TTipoNotificacao; overload;
    function Tipo(const ATipo: TTipoNotificacao): TNotificacao; overload;
    function Chave: String;
    function ChatId: Integer; overload;
    function ChatId(const AChatId: Integer): TNotificacao; overload;
    function ChamadaId: Integer; overload;
    function ChamadaId(const AChamadaId: Integer): TNotificacao; overload;
    function Nome(const ANome: string): TNotificacao;
    function Hora(const AHora: TDateTime): TNotificacao;
    function Conteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao; overload;
    function AddConteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao; overload;
    function Conteudo(const Texto: string): TNotificacao; overload;
    function ChamadaDados(const ADados: TNotificacaoChamadaDados): TNotificacao; overload;
    function ChamadaDados: TNotificacaoChamadaDados; overload;
  end;

  TNotificacaoManager = class
  private
    FVisualizador: TFmxObject;
    FNotificacoes: TDictionary<String, TNotificacao>;
    constructor Create;
    procedure AtualizarVisualizador;
    function InternalApresentar(ANotificacao: TNotificacao): TNotificacaoManager;
    function InternalFechar(const AChave: String): TNotificacaoManager;
  public
    destructor Destroy; override;
    class function Instance: TNotificacaoManager;
    class function Apresentar(Value: TNotificacao): TNotificacaoManager;
    class function Fechar(ATipo: TTipoNotificacao; AId: Integer): TNotificacaoManager;
    function Count: Integer;
    class procedure Finalizar;
  end;

implementation

uses
  Conversa.Notificacao.Visualizador,
  Conversa.Notificacao.Item.Base,
  Conversa.Notificacao.Item.Mensagem,
  Conversa.Notificacao.Item.Chamada,
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
  FNotificacoes := TDictionary<String, TNotificacao>.Create;
end;

destructor TNotificacaoManager.Destroy;
begin
  FreeAndNil(FNotificacoes);
  FreeAndNil(FVisualizador);
  inherited;
end;

class function TNotificacaoManager.Fechar(ATipo: TTipoNotificacao; AId: Integer): TNotificacaoManager;
begin
  Result := Instance.InternalFechar(GerarChaveNotificacao(ATipo, AId));
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
  Chave: String;
  NotifExistente: TNotificacao;
  ItemMensagem: TNotificacaoItemMensagem;
  ItemChamada: TNotificacaoItemChamada;
begin
  Result := Self;
  Chave := ANotificacao.GerarChave;

  if FNotificacoes.TryGetValue(Chave, NotifExistente) then
  begin
    if ANotificacao.Tipo = TTipoNotificacao.Mensagem then
    begin
      NotifExistente := NotifExistente.AddConteudo(ANotificacao.FConteudo);
      FNotificacoes[Chave] := NotifExistente;
      if Assigned(NotifExistente.FView) and (NotifExistente.FView is TNotificacaoItemMensagem) then
        TNotificacaoItemMensagem(NotifExistente.FView).AtualizarConteudo(
          NotifExistente.FChatId, NotifExistente.FConteudo);
    end;
    Exit;
  end;

  case ANotificacao.Tipo of
    TTipoNotificacao.Mensagem:
    begin
      ItemMensagem := TNotificacaoItemMensagem.New(Visualizador);
      ItemMensagem.txtNome.Text := ANotificacao.FNome;
      ItemMensagem.txtHora.Text := TimeToStr(ANotificacao.FHora);
      ItemMensagem.AtualizarConteudo(ANotificacao.FChatId, ANotificacao.FConteudo);
      ANotificacao.FView := ItemMensagem;
    end;
    TTipoNotificacao.Chamada:
    begin
      ItemChamada := TNotificacaoItemChamada.New(Visualizador);
      ItemChamada.Configurar(
        ANotificacao.FChamadaId,
        ANotificacao.FChamadaDados.Nome,
        ANotificacao.FChamadaDados.TipoChamada,
        ANotificacao.FChamadaDados.Descricao,
        ANotificacao.FChamadaDados.OnAtender,
        ANotificacao.FChamadaDados.OnRecusar
      );
      ANotificacao.FView := ItemChamada;
    end;
  end;

  ANotificacao.FChave := Chave;
  FNotificacoes.Add(Chave, ANotificacao);
  AtualizarVisualizador;
end;

function TNotificacaoManager.InternalFechar(const AChave: String): TNotificacaoManager;
var
  Notif: TNotificacao;
begin
  Result := Self;
  if FNotificacoes.TryGetValue(AChave, Notif) then
  begin
    if Assigned(Notif.FView) then
      Notif.FView.Free;
    FNotificacoes.Remove(AChave);
  end;
  AtualizarVisualizador;
end;

procedure TNotificacaoManager.AtualizarVisualizador;
var
  Notif: TNotificacao;
  Altura: Single;
begin
  Altura := 0;
  for Notif in FNotificacoes.Values do
    if Assigned(Notif.FView) then
      Altura := Altura + TNotificacaoItemBase(Notif.FView).GetAltura;

  Visualizador.Exibir(Altura);
end;

{ TNotificacao }

class function TNotificacao.New: TNotificacao;
begin
  Result := Default(TNotificacao);
  Result.FTipo := TTipoNotificacao.Mensagem;
end;

function TNotificacao.GerarChave: String;
begin
  case FTipo of
    TTipoNotificacao.Mensagem: Result := GerarChaveNotificacao(FTipo, FChatId);
    TTipoNotificacao.Chamada: Result := GerarChaveNotificacao(FTipo, FChamadaId);
  end;
end;

function TNotificacao.Tipo: TTipoNotificacao;
begin
  Result := FTipo;
end;

function TNotificacao.Tipo(const ATipo: TTipoNotificacao): TNotificacao;
begin
  Result := Self;
  Result.FTipo := ATipo;
end;

function TNotificacao.Chave: String;
begin
  Result := FChave;
end;

function TNotificacao.ChatId(const AChatId: Integer): TNotificacao;
begin
  Result := Self;
  Result.FChatId := AChatId;
end;

function TNotificacao.ChatId: Integer;
begin
  Result := FChatId;
end;

function TNotificacao.ChamadaId(const AChamadaId: Integer): TNotificacao;
begin
  Result := Self;
  Result.FChamadaId := AChamadaId;
end;

function TNotificacao.ChamadaId: Integer;
begin
  Result := FChamadaId;
end;

function TNotificacao.Nome(const ANome: string): TNotificacao;
begin
  Result := Self;
  Result.FNome := ANome;
  if Assigned(FView) and (FView is TNotificacaoItemMensagem) then
    TNotificacaoItemMensagem(FView).txtNome.Text := Result.FNome;
end;

function TNotificacao.Hora(const AHora: TDateTime): TNotificacao;
begin
  Result := Self;
  Result.FHora := AHora;
  if Assigned(FView) and (FView is TNotificacaoItemMensagem) then
    TNotificacaoItemMensagem(FView).txtHora.Text := TimeToStr(Result.FHora);
end;

function TNotificacao.Conteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao;
begin
  Result := Self;
  Result.FConteudo := AConteudo;
  if Assigned(FView) and (FView is TNotificacaoItemMensagem) then
    TNotificacaoItemMensagem(FView).AtualizarConteudo(Result.ChatId, Result.FConteudo);
end;

function TNotificacao.AddConteudo(const AConteudo: TArray<TMensagemNotificacao>): TNotificacao;
begin
  Result := Self.Conteudo(Self.FConteudo + AConteudo);
end;

function TNotificacao.Conteudo(const Texto: string): TNotificacao;
begin
  Result := Self;
  SetLength(Result.FConteudo, Length(Result.FConteudo) + 1);
  Result.FConteudo[High(Result.FConteudo)] := TMensagemNotificacao.New.Mensagem(Texto);
end;

function TNotificacao.ChamadaDados(const ADados: TNotificacaoChamadaDados): TNotificacao;
begin
  Result := Self;
  Result.FChamadaDados := ADados;
end;

function TNotificacao.ChamadaDados: TNotificacaoChamadaDados;
begin
  Result := FChamadaDados;
end;

{ TNotificacaoManagerH }

function TNotificacaoManagerH.Visualizador: TNotificacaoVisualizador;
begin
  if not Assigned(FVisualizador) then
    FVisualizador := TNotificacaoVisualizador.Create(nil);

  Result := TNotificacaoVisualizador(FVisualizador);
end;

end.
