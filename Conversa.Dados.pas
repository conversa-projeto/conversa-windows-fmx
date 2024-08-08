// Eduardo - 03/03/2024
unit Conversa.Dados;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.StrUtils,
  Data.DB,
  Datasnap.DBClient,
  FMX.Types,
  REST.API,
  Conversa.Tipos,
  Conversa.Memoria;

type
  TDados = class(TDataModule)
    tmrAtualizarMensagens: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure tmrAtualizarMensagensTimer(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FEventosNovasMensagens: TArray<TProc<Integer>>;
  public
    FDadosApp: TDadosApp;

    procedure Login(sLogin, sSenha: String);
    function ServerOnline: Boolean;
    procedure CarregarConversas;
    function ObterMensagens(iConversa: Integer): TArrayMensagens;
    function Mensagens(iConversa: Integer; iInicio: Integer): TArrayMensagens;
    procedure EnviarMensagem(Mensagem: TMensagem);
    function DownloadAnexo(sIdentificador: String): String;
    procedure Contatos(Proc: TProc<TJSONArray>);
    procedure NovoChat(var Conversa: TConversa);
    procedure ReceberNovasMensagens(Evento: TProc<Integer>);
    function UltimaMensagemNotificada: Integer;
    function ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TArrayMensagens;
    function MensagensSemVisualizar: Integer; overload;
//    function MensagemSemVisualizar(iConversa: Integer): Integer; overload;
    procedure AtualizarContador;
    function MensagensParaNotificar(iConversa: Integer): TArrayMensagens;
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
  Conversa.Windows.Overlay,
  Conversa.Eventos;

const
  PASTA_ANEXO = 'anexos';

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TAPIConversa }

constructor TAPIConversa.Create;
begin
  inherited;
  Host(Configuracoes.Host);
  if Assigned(Dados) and Assigned(Dados.FDadosApp) and Assigned(Dados.FDadosApp.Usuario) then
    if Dados.FDadosApp.Usuario.ID <> 0 then
      Headers(TJSONObject.Create.AddPair('uid', Dados.FDadosApp.Usuario.ID));
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
  TEvento.Adicionar(TTipoEvento.ContadorMensagemVisualizar, AtualizarContador);
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

    with Response.ToJSON do
      FDadosApp.Usuario :=
        FDadosApp.Usuarios.GetOrAdd(GetValue<Integer>('id'))
          .Nome(GetValue<String>('nome'))
          .Email(GetValue<String>('email'))
          .Telefone(GetValue<String>('telefone'));
  finally
    Free;
  end;
end;

//function TDados.MensagemSemVisualizar(iConversa: Integer): Integer;
//begin
//  Result := FDadosApp.MensagemSemVisualizar(iConversa);
//end;

function TDados.MensagensSemVisualizar: Integer;
begin
  Result := FDadosApp.Conversas.MensagensSemVisualizar;
end;

function TDados.Mensagens(iConversa: Integer; iInicio: Integer): TArrayMensagens;
begin
  Result := FDadosApp.Conversas.GetOrAdd(iConversa).Mensagens.GetList(iInicio);
  if Length(Result) = 0 then
    Result := ObterMensagens(iConversa);
end;

function TDados.MensagensParaNotificar(iConversa: Integer): TArrayMensagens;
begin
  Result := FDadosApp.Conversas.Get(iConversa).Mensagens.ParaNotificar;
end;

function TDados.ObterMensagens(iConversa: Integer): TArrayMensagens;
var
  Conversa: TConversa;
  Mensagem: TMensagem;
  MensagemConteudo: TConteudo;
begin
  Conversa := FDadosApp.Conversas.GetOrAdd(iConversa);
  with TAPIConversa.Create do
  try
    Route('mensagens');
    if Conversa.Mensagens.UltimaMensagemSincronizada = 0 then
      Query(TJSONObject.Create.AddPair('offsetanterior', 100))
    else
    begin
      Query(TJSONObject.Create.AddPair('mensagemreferencia', Conversa.Mensagens.UltimaMensagemSincronizada + 1));
      Query(TJSONObject.Create.AddPair('offsetposterior', 100));
    end;
    Query(TJSONObject.Create.AddPair('conversa', iConversa));
    Query(TJSONObject.Create.AddPair('usuario', FDadosApp.Usuario.ID));
    GET;
    Result := [];
    for var Item in Response.ToJSONArray do
    begin

      Mensagem := TMensagem.New(Item.GetValue<Integer>('id'))
        .Remetente(FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('remetente_id')))
        .Conversa(Conversa);

      if Mensagem.Remetente = FDadosApp.Usuario then
        Mensagem.Lado(TLadoMensagem.Direito)
      else
        Mensagem.Lado(TLadoMensagem.Esquerdo);


      if not (Item.FindValue('inserida') is TJSONNull) then
        Mensagem.Inserida(ISO8601ToDate(Item.GetValue<String>('inserida')));
      if not (Item.FindValue('alterada') is TJSONNull) then
        Mensagem.Alterada(ISO8601ToDate(Item.GetValue<String>('alterada')));

      Mensagem.Recebida(Item.GetValue<Boolean>('recebida'));
      Mensagem.Visualizada(Item.GetValue<Boolean>('visualizada'));

      if not Mensagem.Visualizada and (Mensagem.Lado = TLadoMensagem.Esquerdo) then
        Inc(Conversa.MensagemSemVisualizar);

      for var Conteudo in Item.GetValue<TJSONArray>('conteudos') do
      begin
        MensagemConteudo := TConteudo.New(Conteudo.GetValue<Integer>('id'));
        MensagemConteudo.Ordem(Conteudo.GetValue<Integer>('ordem'));
        MensagemConteudo.Tipo(TTipoConteudo(Conteudo.GetValue<Integer>('tipo')));
        case MensagemConteudo.Tipo of
          TTipoConteudo.Texto: MensagemConteudo.Conteudo(Conteudo.GetValue<String>('conteudo'));
          TTipoConteudo.Imagem: MensagemConteudo.conteudo(DownloadAnexo(Conteudo.GetValue<String>('conteudo')));
        end;
        Mensagem.conteudos.Add(MensagemConteudo);
      end;
      Conversa.Mensagens.Add(Mensagem);
      Result := Result + [Mensagem];
    end;
  finally
    Free;
  end;

  AtualizarContador;
end;

procedure TDados.CarregarConversas;
var
  Conversa: TConversa;
  bNova: Boolean;
begin
  with TAPIConversa.Create do
  try
    Route('conversas');
    GET;
    for var Item in Response.ToJSONArray do
    begin
      Conversa := FDadosApp.Conversas.Get(Item.GetValue<Integer>('id'));

      if not Assigned(Conversa) then
      begin
        bNova := True;
        Conversa := TConversa.New(Item.GetValue<Integer>('id'));
      end
      else
        bNova := False;

      Conversa.Descricao(Item.GetValue<String>('descricao'));
      Conversa.AddUsuario(FDadosApp.Usuario);
      Conversa.AddUsuario(FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('destinatario_id')).Nome(Item.GetValue<String>('nome')));
      Conversa.UltimaMensagem(Item.GetValue<String>('ultima_mensagem_texto'));
      Conversa.CriadoEm(ISO8601ToDate(Item.GetValue<String>('inserida')));

      if not Item.GetValue<String>('ultima_mensagem').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty then
        Conversa.UltimaMensagemData(ISO8601ToDate(Item.GetValue<String>('ultima_mensagem')));

      if bNova then
        FDadosApp.Conversas.Add(Conversa);

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
  Item: TConteudo;
  ss: TStringStream;
  sIdentificador: String;
  bEnviar: Boolean;
begin
  bEnviar := True;

  // enviar a mensagem
  oJSON := TJSONObject.Create;
  oJSON.AddPair('conversa_id', Mensagem.Conversa.ID);
  aConteudos := TJSONArray.Create;
  oJSON.AddPair('conteudos', aConteudos);

  for Item in Mensagem.conteudos do
  begin
    oConteudo := TJSONObject.Create;
    oConteudo.AddPair('ordem', Item.ordem);
    oConteudo.AddPair('tipo', Integer(Item.tipo));

    case Item.tipo of
      TTipoConteudo.Texto: // texto
      begin
        oConteudo.AddPair('conteudo', Item.conteudo);
      end;
      TTipoConteudo.Imagem: // imagem
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
    Mensagem.ID(Response.ToJSON.GetValue<Integer>('id'));
    Mensagem.Conversa.Mensagens.Add(Mensagem);
    //FDadosApp.AdicionaMensagem(Mensagem.ConversaId, Mensagem);
  finally
    Free;
  end;
end;

function TDados.ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TArrayMensagens;
var
  Conversa: TConversa;
begin
  Conversa := FDadosApp.Conversas.GetOrAdd(iConversa);

  if Conversa.Mensagens.UltimaMensagemSincronizada = 0 then
    ObterMensagens(iConversa);

  if ApenasPendente then
    Result := Conversa.Mensagens.ParaExibir
  else
    Result := Conversa.Mensagens.Items;
end;

procedure TDados.ReceberNovasMensagens(Evento: TProc<Integer>);
begin
  FEventosNovasMensagens := FEventosNovasMensagens + [Evento];
end;

procedure TDados.tmrAtualizarMensagensTimer(Sender: TObject);
var
  I: Integer;
  Conversa: TConversa;
  Mensagens: TArrayMensagens;
  sIDMensagens: String;
begin
  Dados.tmrAtualizarMensagens.Enabled := False;
  try
    with TAPIConversa.Create do
    try
      for Conversa in FDadosApp.Conversas.Items do
      begin
        Mensagens := Conversa.Mensagens.ParaAtualizar;
        if Length(Mensagens) = 0 then
          Continue;

        sIDMensagens := EmptyStr;
        for I := 0 to Pred(Length(Mensagens)) do
          sIDMensagens := sIDMensagens + IfThen(not sIDMensagens.Trim.IsEmpty, ',') + Mensagens[I].ID.ToString;

        Route('mensagem/status');
        Query(
          TJSONObject.Create
            .AddPair('conversa', Conversa.ID)
            .AddPair('mensagem', sIDMensagens)
            .AddPair('usuario', FDadosApp.Usuario.ID)
        );
        GET;
        for var Item in Response.ToJSONArray do
        begin
          for I := 0 to Pred(Length(Mensagens)) do
          begin
            if Mensagens[I].Id <> Item.GetValue<Integer>('mensagem_id') then
              Continue;

            Mensagens[I]
              .Recebida(Item.GetValue<Boolean>('recebida'))
              .Visualizada(Item.GetValue<Boolean>('visualizada'));
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

procedure TDados.NovoChat(var Conversa: TConversa);
var
  Usuario: TUsuario;
begin
  with TAPIConversa.Create do
  try
    Route('conversa');
    if Conversa.Descricao.Trim.IsEmpty then
      Body(TJSONObject.Create.AddPair('tipo', Integer(Conversa.Tipo)).AddPair('descricao', TJSONNull.Create))
    else
      Body(TJSONObject.Create.AddPair('tipo', Integer(Conversa.Tipo)).AddPair('descricao', Conversa.Descricao));

    PUT;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create('Falha ao inserir nova conversa');

    Conversa.ID(Response.ToJSON.GetValue<Integer>('id'));

    for Usuario in Conversa.Usuarios do
    begin
      Conversa.AddUsuario(Usuario);
      Route('conversa/usuario');
      Body(TJSONObject.Create.AddPair('conversa_id', Conversa.ID).AddPair('usuario_id', Usuario.ID));
      PUT;

      if Response.Status <> TResponseStatus.Sucess then
        raise Exception.Create('Falha ao inserir usuário em nova conversa');
    end;
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
  AtualizarContadorNotificacao(FDadosApp.Conversas.MensagensSemVisualizar);
end;

procedure TDados.VisualizarMensagem(Mensagem: TMensagem);
begin
  with TAPIConversa.Create do
  try
    Route('mensagem/visualizar');
    Query(
      TJSONObject.Create
        .AddPair('conversa', Mensagem.Conversa.ID)
        .AddPair('mensagem', Mensagem.Id)
        .AddPair('usuario', FDadosApp.Usuario.ID)
    );
    GET;
  finally
    Free;
  end;
end;

end.

