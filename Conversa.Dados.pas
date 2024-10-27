// Eduardo - 03/03/2024
unit Conversa.Dados;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.StrUtils,
  System.Generics.Collections,
  System.Messaging,
  Data.DB,
  Datasnap.DBClient,
  FMX.Types,
  REST.API,
  Conversa.Eventos,
  Conversa.Tipos,
  Conversa.Memoria,
  FMX.Dialogs;

type
  TDados = class(TDataModule)
    tmrAtualizarMensagens: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure tmrAtualizarMensagensTimer(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FEventosNovasMensagens: TArray<TProc<Integer>>;
  public
    FTokenJWT: String;
    FDadosApp: TDadosApp;

    procedure Login(sLogin, sSenha: String);
    function ServerOnline: Boolean;
    procedure CarregarContatos;
    procedure CarregarConversas;
    function ObterMensagens(iConversa: Integer; MensagemPrevia: Boolean = False): TArrayMensagens;
    function Mensagens(iConversa: Integer; iInicio: Integer; MensagemPrevia: Boolean = False): TArrayMensagens;
    procedure EnviarMensagem(Mensagem: TMensagem);
    function DownloadAnexo(sIdentificador: String): String;
    procedure Contatos(Proc: TProc<TJSONArray>);
    procedure NovoChat(var Conversa: TConversa);
    procedure ReceberNovasMensagens(Evento: TProc<Integer>);
    function UltimaMensagemNotificada: Integer;
    function ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TArrayMensagens;
    function MensagensSemVisualizar: Integer; overload;
    procedure AtualizarContador(const Sender: TObject; const M: TMessage);
    function MensagensParaNotificar(iConversa: Integer): TArrayMensagens;
    procedure VisualizarMensagem(Mensagem: TMensagem);
    procedure SalvarAnexo(const Mensagem: TMensagem; const Identificador: String);
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
  Conversa.Login;

const
  PASTA_ANEXO = 'anexos';
  QUANTIDADE_MENSAGENS_CARREGAMENTO = 50;

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TAPIConversa }

constructor TAPIConversa.Create;
begin
  inherited;
  Host(Configuracoes.Host);
  if Assigned(Dados) and not Dados.FTokenJWT.IsEmpty then
    Authorization(TAuthBearer.New(Dados.FTokenJWT));
end;

function TAPIConversa.InternalExecute: TRESTAPI;
var
  vJSON: TJSONValue;
begin
  Result := inherited;
  vJSON := Response.ToJSON;
  TMessageManager.DefaultManager.SendMessage(nil, TEventoStatusConexao.Create(IfThen(Response.Status = TResponseStatus.Sucess, 1, 0)));
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
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoContadorMensagemVisualizar, AtualizarContador);
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

    FTokenJWT := Response.ToJSON.GetValue<String>('token');
  finally
    Free;
  end;
end;

function TDados.MensagensSemVisualizar: Integer;
begin
  Result := FDadosApp.Conversas.MensagensSemVisualizar;
end;

function TDados.Mensagens(iConversa: Integer; iInicio: Integer; MensagemPrevia: Boolean = False): TArrayMensagens;
begin
  Result := FDadosApp.Conversas.GetOrAdd(iConversa).Mensagens.GetList(iInicio);
  if Length(Result) = 0 then
    Result := ObterMensagens(iConversa, MensagemPrevia);
end;

function TDados.MensagensParaNotificar(iConversa: Integer): TArrayMensagens;
begin
  Result := FDadosApp.Conversas.Get(iConversa).Mensagens.ParaNotificar;
end;

function TDados.ObterMensagens(iConversa: Integer; MensagemPrevia: Boolean = False): TArrayMensagens;
var
  Conversa: TConversa;
  Mensagem: TMensagem;
  MensagemConteudo: TConteudo;
  Remetente: TUsuario;
  MsgRef: Integer;
  IDMsg: Integer;
  Msgs: TArrayMensagens;
begin
  Conversa := FDadosApp.Conversas.Get(iConversa);

  // Melhorar aqui
  if not Assigned(Conversa) then
  begin
    CarregarConversas;
    Conversa := FDadosApp.Conversas.Get(iConversa);
  end;

  if Conversa.Usuarios.Count = 0 then
    Conversa.AddUsuario(FDadosApp.Usuario);

  with TAPIConversa.Create do
  try
    Route('mensagens');
    if MensagemPrevia then
    begin
      Msgs := Conversa.Mensagens.Items;
      MsgRef := Conversa.Mensagens.UltimaMensagemSincronizada;
      for IDMsg := Pred(Length(Msgs)) downto 0 do
        MsgRef := Min(Msgs[IDMsg].ID, MsgRef);

      if (MsgRef - 1) <= 0 then
        Exit;

      Query(TJSONObject.Create.AddPair('mensagemreferencia', MsgRef - 1));
      Query(TJSONObject.Create.AddPair('mensagensprevias', QUANTIDADE_MENSAGENS_CARREGAMENTO));
    end
    else
    if Conversa.Mensagens.UltimaMensagemSincronizada = 0 then
      Query(TJSONObject.Create.AddPair('mensagensprevias', QUANTIDADE_MENSAGENS_CARREGAMENTO))
    else
    begin
      Query(TJSONObject.Create.AddPair('mensagemreferencia', Conversa.Mensagens.UltimaMensagemSincronizada + 1));
      Query(TJSONObject.Create.AddPair('mensagensseguintes', QUANTIDADE_MENSAGENS_CARREGAMENTO));
    end;
    Query(TJSONObject.Create.AddPair('conversa', iConversa));
    Query(TJSONObject.Create.AddPair('usuario', FDadosApp.Usuario.ID));
    try
      GET;
    except
    end;

    if Response.Status <> TResponseStatus.Sucess then
      Exit;

    // Primeira execução
    if (Conversa.MensagemSemVisualizar > 0) and (Conversa.Mensagens.UltimaMensagemSincronizada = 0) then
      Conversa.MensagemSemVisualizar := 0;

    Result := [];
    for var Item in Response.ToJSONArray do
    begin
      Remetente := FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('remetente_id'));
      Conversa.AddUsuario(Remetente);

      Mensagem := TMensagem.New(Item.GetValue<Integer>('id'))
        .Remetente(FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('remetente_id')))
        .Conversa(Conversa);

      if Mensagem.Remetente = FDadosApp.Usuario then
        Mensagem.Lado(TLadoMensagem.Direito)
      else
        Mensagem.Lado(TLadoMensagem.Esquerdo);


      if not (Item.FindValue('inserida') is TJSONNull) then
        Mensagem.Inserida(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('inserida'))));
      if not (Item.FindValue('alterada') is TJSONNull) then
        Mensagem.Alterada(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('alterada'))));

      Mensagem.Recebida(Item.GetValue<Boolean>('recebida'));
      Mensagem.Visualizada(Item.GetValue<Boolean>('visualizada'));
      Mensagem.PrimeiraExibicao((Mensagem.Lado = TLadoMensagem.Esquerdo) and not Mensagem.Visualizada);

      for var Conteudo in Item.GetValue<TJSONArray>('conteudos') do
      begin
        MensagemConteudo := TConteudo.New(Conteudo.GetValue<Integer>('id'));
        MensagemConteudo.Ordem(Conteudo.GetValue<Integer>('ordem'));
        MensagemConteudo.Tipo(TTipoConteudo(Conteudo.GetValue<Integer>('tipo')));
        MensagemConteudo.Nome(Conteudo.GetValue<String>('nome', ''));
        MensagemConteudo.Extensao(Conteudo.GetValue<String>('extensao', ''));
        case MensagemConteudo.Tipo of
          TTipoConteudo.Texto: MensagemConteudo.Conteudo(Conteudo.GetValue<String>('conteudo'));
          TTipoConteudo.Imagem: MensagemConteudo.Conteudo(DownloadAnexo(Conteudo.GetValue<String>('conteudo')));
          TTipoConteudo.Arquivo: MensagemConteudo.Conteudo(Conteudo.GetValue<String>('conteudo'));
        end;
        Mensagem.conteudos.Add(MensagemConteudo);
      end;
      Conversa.Mensagens.Add(Mensagem);

      if not Mensagem.Visualizada and (Mensagem.Lado = TLadoMensagem.Esquerdo) then
        Inc(Conversa.MensagemSemVisualizar);

      Result := Result + [Mensagem];
    end;
  finally
    Free;
  end;

  AtualizarContador(nil, nil);
  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizarContadorConversa.Create(0));
end;

procedure TDados.CarregarContatos;
begin
  Contatos(
    procedure(jaContatos: TJSONArray)
    var
      I: Integer;
    begin
      for I := 0 to Pred(jaCOntatos.Count) do
      begin
        FDadosApp.Usuarios.Add(
          TUsuario.New(jaCOntatos[I].GetValue<Integer>('id'))
            .Nome(jaContatos[I].GetValue<String>('nome'))
            .Login(jaContatos[I].GetValue<String>('login'))
            .Email(jaContatos[I].GetValue<String>('email'))
            .Telefone(jaContatos[I].GetValue<String>('telefone'))
        );
      end;
    end
  );
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

      Conversa.Tipo(TTipoConversa(Item.GetValue<Integer>('tipo')));
      Conversa.Descricao(Item.GetValue<String>('descricao'));
      Conversa.AddUsuario(FDadosApp.Usuario);
      Conversa.AddUsuario(FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('destinatario_id')).Nome(Item.GetValue<String>('nome')));
      Conversa.UltimaMensagem(Item.GetValue<String>('ultima_mensagem_texto'));
      Conversa.CriadoEm(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('inserida'))));

      if not Item.GetValue<String>('ultima_mensagem').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty then
        Conversa.UltimaMensagemData(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('ultima_mensagem'))));

      if (Conversa.MensagemSemVisualizar = 0) and (not Item.GetValue<String>('mensagens_sem_visualizar').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty) then
        Conversa.MensagemSemVisualizar := StrToIntDef(Item.GetValue<String>('mensagens_sem_visualizar'), 0);

      if bNova then
        FDadosApp.Conversas.Add(Conversa);

      FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, Item.GetValue<Integer>('mensagem_id'));
    end;
  finally
    Free;
  end;
  AtualizarContador(nil, nil);
  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizarContadorConversa.Create(0));
end;

function TDados.DownloadAnexo(sIdentificador: String): String;
var
  sLocal: String;
begin
  if TFile.Exists(PastaDados + PASTA_ANEXO + PathDelim + sIdentificador) then
    Exit(PastaDados + PASTA_ANEXO + PathDelim + sIdentificador);

  with TAPIConversa.Create do
  try
    Route('anexo');
    Query(TJSONObject.Create.AddPair('identificador', sIdentificador));

    try
      GET;
    except
      Exit(EmptyStr);
    end;

    sLocal := PastaDados + PASTA_ANEXO;

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
  ss: TStringStream;
  sIdentificador: String;
  bEnviar: Boolean;
  iConteudo: Integer;
begin
  bEnviar := True;

  oJSON := TJSONObject.Create;
  oJSON.AddPair('conversa_id', Mensagem.Conversa.ID);
  aConteudos := TJSONArray.Create;
  oJSON.AddPair('conteudos', aConteudos);

  for iConteudo := 0 to Pred(Length(Mensagem.conteudos)) do
  begin
    oConteudo := TJSONObject.Create;
    oConteudo.AddPair('ordem', Mensagem.conteudos[iConteudo].ordem);
    oConteudo.AddPair('tipo', Integer(Mensagem.conteudos[iConteudo].tipo));

    case Mensagem.conteudos[iConteudo].tipo of
      TTipoConteudo.Texto:
      begin
        oConteudo.AddPair('conteudo', Mensagem.conteudos[iConteudo].conteudo);
      end;
      TTipoConteudo.Imagem, TTipoConteudo.Arquivo:
      begin
        ss := TStringStream.Create;
        try
          ss.LoadFromFile(Mensagem.conteudos[iConteudo].conteudo);

          sIdentificador := THashSHA2.GetHashString(ss);
          ss.Position := 0;
          ss.SaveToFile(PastaDados + PASTA_ANEXO + PathDelim + sIdentificador);
          Mensagem.conteudos[iConteudo].conteudo(PastaDados + PASTA_ANEXO + PathDelim + sIdentificador);
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
                  .AddPair('nome', Mensagem.conteudos[iConteudo].Nome)
                  .AddPair('extensao', Mensagem.conteudos[iConteudo].Extensao)
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

  Result := Conversa.Mensagens.ParaExibir(ApenasPendente);
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
        try
          GET;
        except
        end;

        if Response.Status <> TResponseStatus.Sucess then
          Exit;

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

      try
        GET;
      except
      end;

      if Response.Status <> TResponseStatus.Sucess then
        Exit;

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
    if Conversa.Tipo = TTipoConversa.Chat then
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

procedure TDados.AtualizarContador(const Sender: TObject; const M: TMessage);
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

procedure TDados.SalvarAnexo(const Mensagem: TMensagem; const Identificador: String);
var
  Cont: TConteudo;
  SaveDlg: TSaveDialog;
  Nome: String;
  Extensao: string;
  Localizou: Boolean;
begin
  Localizou := False;
  for Cont in Mensagem.Conteudos do
  begin
    if Cont.Conteudo = Identificador then
    begin
      Localizou := True;
      Nome := Cont.Nome;
      Extensao := Cont.Extensao.ToLower;
      Break;
    end;
  end;

  if not Localizou then
    raise Exception.Create('Anexo não encontrado!');


  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Title      := 'Salvar Arquivo';
    SaveDlg.InitialDir := TPath.GetDownloadsPath;
    SaveDlg.DefaultExt := Extensao;
    SaveDlg.Filter     := 'Arquivo|*.'+ Extensao;
    SaveDlg.FileName   := Nome +'.'+ Extensao;

    if SaveDlg.Execute then
    begin
      if TFile.Exists(SaveDlg.FileName) then
        TFile.Delete(SaveDlg.FileName);
      TFile.Move(DownloadAnexo(Identificador), SaveDlg.FileName);
    end;
  finally
    FreeAndNil(SaveDlg);
  end;
end;

end.
