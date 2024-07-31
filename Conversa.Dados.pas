// Eduardo - 03/03/2024
unit Conversa.Dados;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Data.DB,
  Datasnap.DBClient,
  FMX.Types,
  REST.API,
  Mensagem.Tipos,
  Conversa.Memoria;

type
  TDados = class(TDataModule)
    tmrAtualizarMensagens: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure tmrAtualizarMensagensTimer(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    Fid: Integer;
    Fnome: String;
    Femail: String;
    Ftelefone: String;
    FEventosNovasMensagens: TArray<TProc<Integer>>;
    FDadosApp: TDadosApp;
  public
    property ID: Integer read Fid;
    property Nome: String read Fnome;
    procedure Login(sLogin, sSenha: String);
    function ServerOnline: Boolean;
    procedure CarregarConversas;
    function Conversas: TArray<TDadosConversa>;
    function Conversa(ID: Integer): TDadosConversa;
    function ObterMensagens(iConversa: Integer): TMensagens;
    function Mensagens(iConversa: Integer; iInicio: Integer): TMensagens;
    procedure EnviarMensagem(Mensagem: TMensagem);
    function DownloadAnexo(sIdentificador: String): String;
    procedure Contatos(Proc: TProc<TJSONArray>);
    function NovoChat(remetente_id, destinatario_id: Integer): Integer;
    procedure ReceberNovasMensagens(Evento: TProc<Integer>);
    function UltimaMensagemNotificada: Integer;
    function ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TMensagens;
    function MensagemSemVisualizar: Integer; overload;
    function MensagemSemVisualizar(iConversa: Integer): Integer; overload;
    procedure AtualizarContador;
    function MensagensParaNotificar(iConversa: Integer): TMensagens;
    procedure VisualizarMensagem(Mensagem: TMensagem);
  end;

  TAPIConversa = class(TRESTAPI)
  public
    constructor Create;
    function InternalExecute: TRESTAPI; override;
  end;

var
  Dados: TDados;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

uses
  System.IOUtils,
  System.DateUtils,
  System.Hash,
  System.Math,
  Conversa.Configuracoes,
  Conversa.Notificacao,
  Conversa.Windows.Overlay;

const
  PASTA_ANEXO = 'anexos';

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TAPIConversa }

constructor TAPIConversa.Create;
begin
  inherited;
  Host(Configuracoes.Host);
  if Dados.ID <> 0 then
    Headers(TJSONObject.Create.AddPair('uid', Dados.ID));
end;

function TAPIConversa.InternalExecute: TRESTAPI;
var
  vJSON: TJSONValue;
begin
  Result := inherited;
  vJSON := Response.ToJSON;
  if Response.Status <> TResponseStatus.Sucess then
  begin
    if Assigned(vJSON) and Assigned(vJSON.FindValue('error')) then
      raise Exception.Create(vJSON.GetValue<String>('error'))
    else
      raise Exception.Create(Response.ToString);
  end;
end;

{ TDados }

procedure TDados.DataModuleCreate(Sender: TObject);
begin
  FDadosApp := TDadosApp.New;
end;

procedure TDados.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FDadosApp);
end;

procedure TDados.Login(sLogin, sSenha: String);
begin
  with TAPIConversa.Create do
  try
    Route('login');
    Body(
      TJSONObject.Create
        .AddPair('login', sLogin)
        .AddPair('senha', sSenha)
    );
    POST;
    Fid := Response.ToJSON.GetValue<Integer>('id');
    Fnome := Response.ToJSON.GetValue<String>('nome');
    Femail := Response.ToJSON.GetValue<String>('email');
    Ftelefone := Response.ToJSON.GetValue<String>('telefone');
  finally
    Free;
  end;
end;

function TDados.MensagemSemVisualizar(iConversa: Integer): Integer;
begin
  Result := FDadosApp.MensagemSemVisualizar(iConversa);
end;

function TDados.MensagemSemVisualizar: Integer;
begin
  Result := FDadosApp.MensagemSemVisualizar;
end;

function TDados.Mensagens(iConversa: Integer; iInicio: Integer): TMensagens;
begin
  Result := FDadosApp.Mensagens(iConversa, iInicio);
  if Length(Result) = 0 then
    Result := ObterMensagens(iConversa);
end;

function TDados.MensagensParaNotificar(iConversa: Integer): TMensagens;
begin
  Result := FDadosApp.MensagensParaNotificar(iConversa);
end;

function TDados.ObterMensagens(iConversa: Integer): TMensagens;
var
  Mensagem: TMensagem;
  MensagemConteudo: TMensagemConteudo;
  Conversa: TDadosConversa;
begin
  with TAPIConversa.Create do
  try
    Route('mensagens');
    Query(TJSONObject.Create.AddPair('ultima', FDadosApp.UltimaMensagemConversa(iConversa)));
    Query(TJSONObject.Create.AddPair('conversa', iConversa));
    Query(TJSONObject.Create.AddPair('usuario', ID));
    GET;
    Result := [];
    for var Item in Response.ToJSONArray do
    begin
      Mensagem := TMensagem.New;
      Mensagem.id := Item.GetValue<Integer>('id');
      Mensagem.RemetenteId := Item.GetValue<Integer>('remetente_id');
      Mensagem.remetente := Item.GetValue<String>('remetente');
      Mensagem.ConversaId := Item.GetValue<Integer>('conversa_id');
      if Mensagem.RemetenteId = Dados.ID then
        Mensagem.lado := TLado.Direito
      else
        Mensagem.lado := TLado.Esquerdo;
      if not (Item.FindValue('inserida') is TJSONNull) then
        Mensagem.inserida := ISO8601ToDate(Item.GetValue<String>('inserida'));
      if not (Item.FindValue('alterada') is TJSONNull) then
        Mensagem.alterada := ISO8601ToDate(Item.GetValue<String>('alterada'));
      if Mensagem.Id = 842 then
        Sleep(0);
      Mensagem.Recebida := Item.GetValue<Boolean>('recebida');
      Mensagem.Visualizada := Item.GetValue<Boolean>('visualizada');
      for var Conteudo in Item.GetValue<TJSONArray>('conteudos') do
      begin
        MensagemConteudo := TMensagemConteudo.New;
        MensagemConteudo.id := Conteudo.GetValue<Integer>('id');
        MensagemConteudo.ordem := Conteudo.GetValue<Integer>('ordem');
        MensagemConteudo.tipo := Conteudo.GetValue<Integer>('tipo');
        case MensagemConteudo.Tipo of
          1: MensagemConteudo.conteudo := Conteudo.GetValue<String>('conteudo');                // 1-Texto
          2: MensagemConteudo.conteudo := DownloadAnexo(Conteudo.GetValue<String>('conteudo')); // 2-Imagem
        end;
        Mensagem.conteudos.Add(MensagemConteudo);
      end;
      FDadosApp.AdicionaMensagem(iConversa, Mensagem);
      Result := Result + [Mensagem];
    end;
  finally
    Free;
  end;
end;

procedure TDados.CarregarConversas;
var
  Conversa: TDadosConversa;
begin
  with TAPIConversa.Create do
  try
    Route('conversas');
    GET;
    for var Item in Response.ToJSONArray do
    begin
      if not FDadosApp.ObtemConversa(Item.GetValue<Integer>('id'), Conversa) then
      begin
        Conversa := TDadosConversa.New;
        Conversa.ID := Item.GetValue<Integer>('id');
        FDadosApp.Conversas.Add(Conversa);
      end;
      Conversa.Descricao := Item.GetValue<String>('descricao');
      Conversa.UltimaMensagem := Item.GetValue<String>('ultima_mensagem_texto');
      Conversa.Destinatario := Item.GetValue<String>('nome');
      Conversa.DestinatarioId := Item.GetValue<Integer>('destinatario_id');
      if not Item.GetValue<String>('ultima_mensagem').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty then
        Conversa.UltimaMensagemData := ISO8601ToDate(Item.GetValue<String>('ultima_mensagem'));
      FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, Item.GetValue<Integer>('mensagem_id'));
    end;
  finally
    Free;
  end;
end;

function TDados.DownloadAnexo(sIdentificador: String): String;
var
  sLocal: String;
begin
  if TFile.Exists(PASTA_ANEXO + PathDelim + sIdentificador) then
    Exit(PASTA_ANEXO + PathDelim + sIdentificador);

  with TAPIConversa.Create do
  try
    Route('anexo');
    Query(TJSONObject.Create.AddPair('identificador', sIdentificador));
    GET;

    sLocal := ExtractFilePath(ParamStr(0)) + PASTA_ANEXO;

    if not TDirectory.Exists(sLocal) then
      TDirectory.CreateDirectory(sLocal);

    Result := sLocal + PathDelim + sIdentificador;

    Response.ToStream.SaveToFile(Result);
  finally
    Free;
  end;
end;

procedure TDados.EnviarMensagem(Mensagem: TMensagem);
var
  oJSON: TJSONObject;
  aConteudos: TJSONArray;
  oConteudo: TJSONObject;
  Item: TMensagemConteudo;
  ss: TStringStream;
  sIdentificador: String;
  bEnviar: Boolean;
begin
  bEnviar := True;

  // enviar a mensagem
  oJSON := TJSONObject.Create;
  oJSON.AddPair('conversa_id', Mensagem.ConversaId);
  aConteudos := TJSONArray.Create;
  oJSON.AddPair('conteudos', aConteudos);

  for Item in Mensagem.conteudos do
  begin
    oConteudo := TJSONObject.Create;
    oConteudo.AddPair('ordem', Item.ordem);
    oConteudo.AddPair('tipo', Item.tipo);

    case Item.tipo of
      1: // texto
      begin
        oConteudo.AddPair('conteudo', Item.conteudo);
      end;
      2: // imagem
      begin
        ss := TStringStream.Create;
        try
          ss.LoadFromFile(Item.conteudo);

          sIdentificador := THashSHA2.GetHashString(ss);
          oConteudo.AddPair('conteudo', sIdentificador);

          // verifica se já não existe no servidor
          with TAPIConversa.Create do
          try
            Route('anexo/existe');
            Query(TJSONObject.Create.AddPair('identificador', sIdentificador));
            GET;
            bEnviar := not Response.ToJSON.GetValue<Boolean>('existe');
          finally
            Free;
          end;

          // faz o envio
          if bEnviar then
          begin
            with TAPIConversa.Create do
            try
              Route('anexo');
              Headers(
                TJSONObject.Create
                  .AddPair('Content-Type', 'application/octet-stream')
              );
              Body(ss);
              PUT;
            finally
              Free;
            end;
          end;
        finally
          if not bEnviar then
            FreeAndNil(ss);
        end;
      end;
    end;
    aConteudos.Add(oConteudo);
  end;

  with TAPIConversa.Create do
  try
    Route('mensagem');
    Body(oJSON);
    PUT;
    Mensagem.id := Response.ToJSON.GetValue<Integer>('id');
    FDadosApp.AdicionaMensagem(Mensagem.ConversaId, Mensagem);
  finally
    Free;
  end;
end;

function TDados.ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TMensagens;
begin
  if FDadosApp.UltimaMensagemConversa(iConversa) = 0 then
    ObterMensagens(iConversa);
  Result := FDadosApp.ExibirMensagem(iConversa, ApenasPendente);
end;

procedure TDados.ReceberNovasMensagens(Evento: TProc<Integer>);
begin
  FEventosNovasMensagens := FEventosNovasMensagens + [Evento];
end;

procedure TDados.tmrAtualizarMensagensTimer(Sender: TObject);
var
  I: Integer;
  Conversa: TDadosConversa;
  sMsgID: String;
begin
  Dados.tmrAtualizarMensagens.Enabled := False;
  try
    with TAPIConversa.Create do
    try
      for Conversa in FDadosApp.Conversas do
      begin
        sMsgID := FDadosApp.MensagensParaAtualizar(Conversa.ID);
        if sMsgID.Trim.IsEmpty then
          Continue;

        Route('mensagem/status');
        Query(
          TJSONObject.Create
            .AddPair('conversa', Conversa.ID)
            .AddPair('mensagem', sMsgID)
            .AddPair('usuario', ID)
        );
        GET;
        for var Item in Response.ToJSONArray do
        begin
          for I := 0 to Pred(Conversa.Mensagens.Count) do
          begin
            if Conversa.Mensagens[I].Id <> Item.GetValue<Integer>('mensagem_id') then
              Continue;
            Conversa.Mensagens[I].Recebida := Item.GetValue<Boolean>('recebida');
            Conversa.Mensagens[I].Visualizada := Item.GetValue<Boolean>('visualizada');
          end;
        end;
      end;
      Route('mensagens/novas');
      Query(TJSONObject.Create.AddPair('ultima', FDadosApp.UltimaMensagemNotificada));
      GET;
      for var Item in Response.ToJSONArray do
      begin
        FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, Item.GetValue<Integer>('mensagem_id'));
        for I := 0 to Pred(Length(FEventosNovasMensagens)) do
        begin
          try
            ObterMensagens(Item.GetValue<Integer>('conversa_id'));
          except
          end;
          FEventosNovasMensagens[I](Item.GetValue<Integer>('conversa_id'));
        end;
      end;
    finally
      Free;
    end;
  finally
    Dados.tmrAtualizarMensagens.Enabled := True;
  end;
end;

function TDados.UltimaMensagemNotificada: Integer;
begin
  Result := FDadosApp.UltimaMensagemNotificada;
end;

procedure TDados.Contatos(Proc: TProc<TJSONArray>);
begin
  with TAPIConversa.Create do
  try
    Route('usuario/contatos');
    GET;
    Proc(Response.ToJSONArray);
  finally
    Free;
  end;
end;

function TDados.Conversa(ID: Integer): TDadosConversa;
begin
  FDadosApp.ObtemConversa(ID, Result);
end;

function TDados.Conversas: TArray<TDadosConversa>;
begin
  Result := FDadosApp.Conversas.ToArray;
end;

function TDados.NovoChat(remetente_id, destinatario_id: Integer): Integer;
begin
  with TAPIConversa.Create do
  try
    Route('conversa');
    Body(TJSONObject.Create.AddPair('descricao', TJSONNull.Create));
    PUT;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create('Falha ao inserir nova conversa');

    Result := Response.ToJSON.GetValue<Integer>('id');

    Route('conversa/usuario');
    Body(TJSONObject.Create.AddPair('conversa_id', Result).AddPair('usuario_id', remetente_id));
    PUT;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create('Falha ao inserir nova conversa');

    Route('conversa/usuario');
    Body(TJSONObject.Create.AddPair('conversa_id', Result).AddPair('usuario_id', destinatario_id));
    PUT;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create('Falha ao inserir nova conversa');
  finally
    Free;
  end;
end;

function TDados.ServerOnline: Boolean;
begin
  try
    with TAPIConversa.Create do
    try
      Route('status');
      GET;
      Result := True;
    finally
      Free;
    end;
  except
    Result := False;
  end;
end;

procedure TDados.AtualizarContador;
begin
  AtualizarContadorNotificacao(FDadosApp.MensagemSemVisualizar);
end;

procedure TDados.VisualizarMensagem(Mensagem: TMensagem);
begin
  with TAPIConversa.Create do
  try
    Route('mensagem/visualizar');
    Query(
      TJSONObject.Create
        .AddPair('conversa', Mensagem.ConversaId)
        .AddPair('mensagem', Mensagem.Id)
        .AddPair('usuario', ID)
    );
    GET;
  finally
    Free;
  end;
end;

end.

