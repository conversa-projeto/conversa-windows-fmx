unit Conversa.App.Composicao;

{ Composição manual dos serviços (D6 do doc 07): cria, liga e libera, nesta ordem.
  Nenhum serviço é global: quem precisa recebe a composição (ou o serviço) por parâmetro. }

interface

uses
  Conversa.Infra.Log,
  Conversa.Eventos.Barramento;

type
  TComposicao = class
  private
    FLogger: ILogger;
    FBarramento: TBarramento;
  public
    constructor Create;
    destructor Destroy; override;
    property Logger: ILogger read FLogger;
    property Barramento: TBarramento read FBarramento;
  end;

implementation

uses
  System.SysUtils,
  Conversa.Infra.Windows.Pastas,
  Conversa.Infra.Windows.Versao;

{ TComposicao }

constructor TComposicao.Create;
var
  LLogger: ILogger;
begin
  inherited Create;
  {$IFDEF DEBUG}
  FLogger := TLoggerArquivo.Create(TPastas.Logs, TNivelLog.Depuracao);
  {$ELSE}
  FLogger := TLoggerArquivo.Create(TPastas.Logs, TNivelLog.Info);
  {$ENDIF}
  LLogger := FLogger;
  FBarramento := TBarramento.Create(TDespachanteThreadPrincipal.Create,
    procedure(const AErro: Exception; const AEvento: string)
    begin
      LLogger.Erro('Barramento', 'Um assinante de ' + AEvento + ' falhou', AErro);
    end);
  FLogger.Info('App', 'Conversa ' + TVersaoApp.DoExecutavel.Completa + ' iniciado');
end;

destructor TComposicao.Destroy;
begin
  if Assigned(FLogger) then
    FLogger.Info('App', 'Encerrando');
  // Ordem inversa da criação: o barramento segura uma referência ao logger (no tratamento de erro).
  FreeAndNil(FBarramento);
  FLogger := nil;
  inherited;
end;

end.
