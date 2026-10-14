unit Conversa.Infra.Log;

{ Logger da nova base (FC-113): fila + thread própria, níveis, rotação e redação.

  Regra do projeto: nunca registrar token, senha nem conteúdo de mensagem. Quem chama não deve passar
  esses dados; a redação (TRedacao) é só a rede de segurança. }

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections;

type
  {$SCOPEDENUMS ON}
  TNivelLog = (Depuracao, Info, Aviso, Erro);
  {$SCOPEDENUMS OFF}

  ILogger = interface
    ['{95ED2E99-8B02-4818-A6F4-CA1B2287BCF0}']
    procedure Registrar(ANivel: TNivelLog; const AOrigem, AMensagem: string);
    procedure Depuracao(const AOrigem, AMensagem: string);
    procedure Info(const AOrigem, AMensagem: string);
    procedure Aviso(const AOrigem, AMensagem: string);
    procedure Erro(const AOrigem, AMensagem: string; const AExcecao: Exception = nil);
  end;

  /// <summary>Remove dados sensíveis (token, senha, conteúdo) de um texto antes de ir para o log.</summary>
  TRedacao = record
    class function Redigir(const ATexto: string): string; static;
  end;

  /// <summary>Base com os atalhos por nível; as classes filhas só implementam Gravar.</summary>
  TLoggerBase = class abstract(TInterfacedObject, ILogger)
  private
    FNivelMinimo: TNivelLog;
  protected
    procedure Gravar(ANivel: TNivelLog; const ALinha: string); virtual; abstract;
  public
    constructor Create(ANivelMinimo: TNivelLog);
    procedure Registrar(ANivel: TNivelLog; const AOrigem, AMensagem: string);
    procedure Depuracao(const AOrigem, AMensagem: string);
    procedure Info(const AOrigem, AMensagem: string);
    procedure Aviso(const AOrigem, AMensagem: string);
    procedure Erro(const AOrigem, AMensagem: string; const AExcecao: Exception = nil);
    class function FormatarLinha(AQuando: TDateTime; ANivel: TNivelLog; const AOrigem, AMensagem: string): string; static;
    property NivelMinimo: TNivelLog read FNivelMinimo write FNivelMinimo;
  end;

  /// <summary>Descarta tudo (padrão quando ninguém configurou um logger).</summary>
  TLoggerNulo = class(TLoggerBase)
  protected
    procedure Gravar(ANivel: TNivelLog; const ALinha: string); override;
  public
    constructor Create;
  end;

  /// <summary>Guarda as linhas na memória (para os testes).</summary>
  TLoggerMemoria = class(TLoggerBase)
  private
    FLinhas: TStringList;
    FTrava: TCriticalSection;
  protected
    procedure Gravar(ANivel: TNivelLog; const ALinha: string); override;
  public
    constructor Create(ANivelMinimo: TNivelLog = TNivelLog.Depuracao);
    destructor Destroy; override;
    function Linhas: TArray<string>;
    function Contem(const ATrecho: string): Boolean;
  end;

  /// <summary>
  ///   Grava em arquivo numa thread própria. Um arquivo por dia (conversa-AAAAMMDD.log); passou do tamanho
  ///   máximo, o atual é renomeado com a hora. Mantém só os N arquivos mais novos. Se a fila encher, as linhas
  ///   excedentes são descartadas (o log nunca bloqueia quem chama).
  /// </summary>
  TLoggerArquivo = class(TLoggerBase)
  private
    FPasta: string;
    FTamanhoMaximo: Int64;
    FArquivosMantidos: Integer;
    FFila: TThreadedQueue<string>;
    FThread: TThread;
    FDescartadas: Integer;
  protected
    procedure Gravar(ANivel: TNivelLog; const ALinha: string); override;
  public
    constructor Create(const APasta: string; ANivelMinimo: TNivelLog = TNivelLog.Info;
      ATamanhoMaximo: Int64 = 5 * 1024 * 1024; AArquivosMantidos: Integer = 10);
    destructor Destroy; override;
    property Pasta: string read FPasta;
    property Descartadas: Integer read FDescartadas;
  end;

const
  NOMES_NIVEL: array[TNivelLog] of string = ('DEPURACAO', 'INFO', 'AVISO', 'ERRO');

implementation

uses
  System.Types,
  System.IOUtils,
  System.RegularExpressions;

const
  SENTINELA_FIM = #0'fim';

{ TRedacao }

class function TRedacao.Redigir(const ATexto: string): string;
begin
  Result := ATexto;
  if Result = '' then
    Exit;
  // JWT (três partes em base64url, a primeira começa com eyJ)
  Result := TRegEx.Replace(Result, 'eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}', '[token]');
  // Authorization: Bearer xxx
  Result := TRegEx.Replace(Result, '(bearer\s+)[A-Za-z0-9._~+/=-]+', '\1[token]', [roIgnoreCase]);
  // "chave": "valor" de campos sensíveis em JSON
  Result := TRegEx.Replace(Result,
    '"(senha|senha_atual|password|token|token_fcm|credential|conteudo|mensagem|texto)"\s*:\s*"(?:[^"\\]|\\.)*"',
    '"\1":"[omitido]"', [roIgnoreCase]);
  // token=xxx em URL
  Result := TRegEx.Replace(Result, '([?&]token=)[^&\s]+', '\1[omitido]', [roIgnoreCase]);
end;

{ TLoggerBase }

constructor TLoggerBase.Create(ANivelMinimo: TNivelLog);
begin
  inherited Create;
  FNivelMinimo := ANivelMinimo;
end;

class function TLoggerBase.FormatarLinha(AQuando: TDateTime; ANivel: TNivelLog; const AOrigem, AMensagem: string): string;
begin
  // Uma linha por registro: quebras de linha da mensagem viram " | " (a pilha de exceção continua legível).
  // Separadores entre aspas: o formato não depende das configurações regionais do Windows.
  Result := FormatDateTime('yyyy"-"mm"-"dd" "hh":"nn":"ss"."zzz', AQuando) + ' ' + NOMES_NIVEL[ANivel] + ' [' + AOrigem + '] ' +
    StringReplace(StringReplace(AMensagem, #13#10, ' | ', [rfReplaceAll]), #10, ' | ', [rfReplaceAll]);
end;

procedure TLoggerBase.Registrar(ANivel: TNivelLog; const AOrigem, AMensagem: string);
begin
  if Ord(ANivel) < Ord(FNivelMinimo) then
    Exit;
  try
    Gravar(ANivel, FormatarLinha(Now, ANivel, AOrigem, TRedacao.Redigir(AMensagem)));
  except
    // o log nunca derruba quem chama
  end;
end;

procedure TLoggerBase.Depuracao(const AOrigem, AMensagem: string);
begin
  Registrar(TNivelLog.Depuracao, AOrigem, AMensagem);
end;

procedure TLoggerBase.Info(const AOrigem, AMensagem: string);
begin
  Registrar(TNivelLog.Info, AOrigem, AMensagem);
end;

procedure TLoggerBase.Aviso(const AOrigem, AMensagem: string);
begin
  Registrar(TNivelLog.Aviso, AOrigem, AMensagem);
end;

procedure TLoggerBase.Erro(const AOrigem, AMensagem: string; const AExcecao: Exception);
var
  LTexto: string;
begin
  LTexto := AMensagem;
  if Assigned(AExcecao) then
  begin
    LTexto := LTexto + ' — ' + AExcecao.ClassName + ': ' + AExcecao.Message;
    if AExcecao.StackTrace <> '' then
      LTexto := LTexto + sLineBreak + AExcecao.StackTrace;
  end;
  Registrar(TNivelLog.Erro, AOrigem, LTexto);
end;

{ TLoggerNulo }

constructor TLoggerNulo.Create;
begin
  inherited Create(TNivelLog.Erro);
end;

procedure TLoggerNulo.Gravar(ANivel: TNivelLog; const ALinha: string);
begin
  // descarta
end;

{ TLoggerMemoria }

constructor TLoggerMemoria.Create(ANivelMinimo: TNivelLog);
begin
  inherited Create(ANivelMinimo);
  FLinhas := TStringList.Create;
  FTrava := TCriticalSection.Create;
end;

destructor TLoggerMemoria.Destroy;
begin
  FTrava.Free;
  FLinhas.Free;
  inherited;
end;

procedure TLoggerMemoria.Gravar(ANivel: TNivelLog; const ALinha: string);
begin
  FTrava.Enter;
  try
    FLinhas.Add(ALinha);
  finally
    FTrava.Leave;
  end;
end;

function TLoggerMemoria.Linhas: TArray<string>;
begin
  FTrava.Enter;
  try
    Result := FLinhas.ToStringArray;
  finally
    FTrava.Leave;
  end;
end;

function TLoggerMemoria.Contem(const ATrecho: string): Boolean;
var
  LLinha: string;
begin
  for LLinha in Linhas do
    if LLinha.Contains(ATrecho) then
      Exit(True);
  Result := False;
end;

{ TThreadLog }

type
  TThreadLog = class(TThread)
  private
    FFila: TThreadedQueue<string>;
    FPasta: string;
    FTamanhoMaximo: Int64;
    FArquivosMantidos: Integer;
    procedure Escrever(const ATexto: string);
    procedure LimparAntigos;
  protected
    procedure Execute; override;
  public
    constructor Create(AFila: TThreadedQueue<string>; const APasta: string; ATamanhoMaximo: Int64;
      AArquivosMantidos: Integer);
  end;

constructor TThreadLog.Create(AFila: TThreadedQueue<string>; const APasta: string; ATamanhoMaximo: Int64;
  AArquivosMantidos: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FFila := AFila;
  FPasta := APasta;
  FTamanhoMaximo := ATamanhoMaximo;
  FArquivosMantidos := AArquivosMantidos;
end;

procedure TThreadLog.Execute;
var
  LLinha: string;
  LLote: TStringBuilder;
  LFim: Boolean;
begin
  // Esta thread nunca usa Synchronize/Queue: o destrutor do logger espera por ela (WaitFor) na thread
  // principal, e uma entrega pendente poderia rodar dentro dele.
  NameThreadForDebugging('Conversa.Log');
  LFim := False;
  LLote := TStringBuilder.Create;
  try
    while not LFim do
    begin
      // Depois do DoShutDown, PopItem devolve wrSignaled com o item vazio (System.Generics.Collections):
      // toda linha real tem a data na frente, então vazio = fila desligada.
      if (FFila.PopItem(LLinha) <> TWaitResult.wrSignaled) or (LLinha = '') then
        Break;
      LLote.Clear;
      repeat
        if LLinha = SENTINELA_FIM then
        begin
          LFim := True;
          Break;
        end;
        LLote.Append(LLinha).Append(sLineBreak);
        // junta o que já está na fila num único acesso ao disco
        if FFila.QueueSize = 0 then
          Break;
        if (FFila.PopItem(LLinha) <> TWaitResult.wrSignaled) or (LLinha = '') then
        begin
          LFim := True;
          Break;
        end;
      until False;
      if LLote.Length > 0 then
        try
          Escrever(LLote.ToString);
        except
          // sem disco ou sem permissão: o app continua
        end;
    end;
  finally
    LLote.Free;
  end;
end;

procedure TThreadLog.Escrever(const ATexto: string);
var
  LArquivo: string;
  LBytes: TBytes;
  LFluxo: TFileStream;
begin
  ForceDirectories(FPasta);
  LArquivo := TPath.Combine(FPasta, 'conversa-' + FormatDateTime('yyyymmdd', Now) + '.log');
  if TFile.Exists(LArquivo) and (TFile.GetSize(LArquivo) > FTamanhoMaximo) then
  begin
    // conversa-AAAAMMDD.log -> conversa-AAAAMMDD-hhnnsszzz.log ('-' vem antes de '.' na comparação
    // ordinal, então a ordem continua cronológica; ver LimparAntigos)
    TFile.Move(LArquivo, Copy(LArquivo, 1, Length(LArquivo) - Length('.log')) + '-' +
      FormatDateTime('hhnnsszzz', Now) + '.log');
    LimparAntigos;
  end;
  LBytes := TEncoding.UTF8.GetBytes(ATexto);
  // fmShareDenyNone: uma segunda instância do app (antes da instância única, Etapa 1.16) também consegue
  // gravar, em vez de perder o lote em silêncio.
  if TFile.Exists(LArquivo) then
    LFluxo := TFileStream.Create(LArquivo, fmOpenReadWrite or fmShareDenyNone)
  else
  begin
    LFluxo := TFileStream.Create(LArquivo, fmCreate or fmShareDenyNone);
    LimparAntigos;
  end;
  try
    LFluxo.Seek(0, soEnd);
    if Length(LBytes) > 0 then
      LFluxo.WriteBuffer(LBytes[0], Length(LBytes));
  finally
    LFluxo.Free;
  end;
end;

procedure TThreadLog.LimparAntigos;
var
  LArquivos: TStringDynArray;
  I: Integer;
  LLista: TStringList;
begin
  LArquivos := TDirectory.GetFiles(FPasta, 'conversa-*.log');
  if Length(LArquivos) <= FArquivosMantidos then
    Exit;
  LLista := TStringList.Create;
  try
    // Comparação ordinal: a padrão (UseLocale) usa a ordenação de palavras do Windows, em que o hífen quase
    // não pesa e o arquivo "conversa-AAAAMMDD.log" ficaria antes dos pedaços do mesmo dia.
    LLista.UseLocale := False;
    LLista.CaseSensitive := True;
    for I := 0 to High(LArquivos) do
      LLista.Add(LArquivos[I]);
    LLista.Sort; // o nome começa pela data, então a ordem ordinal é a cronológica
    for I := 0 to LLista.Count - FArquivosMantidos - 1 do
      try
        TFile.Delete(LLista[I]);
      except
        // arquivo aberto por outro programa: fica para a próxima
      end;
  finally
    LLista.Free;
  end;
end;

{ TLoggerArquivo }

constructor TLoggerArquivo.Create(const APasta: string; ANivelMinimo: TNivelLog; ATamanhoMaximo: Int64;
  AArquivosMantidos: Integer);
begin
  inherited Create(ANivelMinimo);
  FPasta := APasta;
  FTamanhoMaximo := ATamanhoMaximo;
  FArquivosMantidos := AArquivosMantidos;
  // Fila de 4096 linhas; quem chama nunca espera (PushTimeout = 0); a thread espera sem limite.
  FFila := TThreadedQueue<string>.Create(4096, 0, INFINITE);
  FThread := TThreadLog.Create(FFila, FPasta, FTamanhoMaximo, FArquivosMantidos);
end;

destructor TLoggerArquivo.Destroy;
var
  LTentativas: Integer;
begin
  if Assigned(FThread) then
  begin
    // A fila não espera (PushTimeout = 0): com ela cheia, tentar a sentinela por até ~5 s para não perder o
    // fim do log; se não entrar, desligar a fila (a thread grava o que já está nela e sai).
    LTentativas := 0;
    while (FFila.PushItem(SENTINELA_FIM) <> TWaitResult.wrSignaled) and (LTentativas < 500) do
    begin
      Inc(LTentativas);
      Sleep(10);
    end;
    if LTentativas >= 500 then
      FFila.DoShutDown;
    FThread.WaitFor;
    FThread.Free;
  end;
  FFila.Free;
  inherited;
end;

procedure TLoggerArquivo.Gravar(ANivel: TNivelLog; const ALinha: string);
begin
  if FFila.PushItem(ALinha) <> TWaitResult.wrSignaled then
    TInterlocked.Increment(FDescartadas);
end;

end.
