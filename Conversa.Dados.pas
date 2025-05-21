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

  Conversa.Proxy,
  Conversa.Proxy.Tipos,

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
    procedure ObterConversas(const Sender: TObject; const M: TObterConversas);
    procedure EventoObterMensagens(const Sender: TObject; const M: TObterMensagens);
    procedure ObterMensagensNovas(const Sender: TObject;
      const M: TObterMensagensNovas);
    procedure ObterMensagensStatus(const Sender: TObject;
      const M: TObterMensagensStatus);
  public
    FTokenJWT: String;
    FDadosApp: TDadosApp;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Login(sLogin, sSenha: String);
    function ServerOnline: Boolean;
    procedure CarregarContatos;
    procedure CarregarConversas;
    procedure ObterMensagens(iConversa: Integer; MensagemPrevia: Boolean = False);
    function Mensagens(iConversa: Integer; iInicio: Integer; MensagemPrevia: Boolean = False): TArrayMensagens;
    procedure EnviarMensagem(Mensagem: TMensagem);
    function DownloadAnexo(sIdentificador: String): String;
//    procedure Contatos(Proc: TProc<TJSONArray>);
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
  Conversa.Login,
  Conversa.DeviceInfo.Utils;

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

constructor TDados.Create(AOwner: TComponent);
begin
  inherited;
  TObterConversas.Subscribe(ObterConversas);
  TObterMensagens.Subscribe(EventoObterMensagens);
  TObterMensagensNovas.Subscribe(ObterMensagensNovas);
  TObterMensagensStatus.Subscribe(ObterMensagensStatus);
end;

destructor TDados.Destroy;
begin
  TObterMensagensStatus.Unsubscribe(ObterMensagensStatus);
  TObterMensagensNovas.Unsubscribe(ObterMensagensNovas);
  TObterMensagens.Unsubscribe(EventoObterMensagens);
  TObterConversas.Unsubscribe(ObterConversas);
  inherited;
end;

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
var
  Dispositivo: Conversa.Proxy.Tipos.TDispositivo;
begin
  with Conversa.Proxy.TAPIConversa.Login(sLogin, sSenha) do
    FDadosApp.Usuario :=
      FDadosApp.Usuarios.GetOrAdd(id)
        .Nome(nome)
        .Email(email)
        .Telefone(telefone);

  FTokenJWT := Conversa.Proxy.TAPIConversa.TokenJWT;

  if Configuracoes.DispositivoId = 0 then
  begin
    Dispositivo := Default(Conversa.Proxy.Tipos.TDispositivo);
    with GetDeviceInfo do
    begin
      Dispositivo.nome := DeviceName;
      Dispositivo.modelo := Model;
      Dispositivo.versao_so := OSVersion;
      Dispositivo.plataforma := Platform;
      Dispositivo.usuario_id := FDadosApp.Usuario.ID;
    end;
    Configuracoes.DispositivoId := Conversa.Proxy.TAPIConversa.Dispositivo.Incluir(Dispositivo).Dados.id;
    Configuracoes.Save;
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
    ObterMensagens(iConversa, MensagemPrevia);
end;

function TDados.MensagensParaNotificar(iConversa: Integer): TArrayMensagens;
begin
  Result := FDadosApp.Conversas.Get(iConversa).Mensagens.ParaNotificar;
end;

procedure TDados.ObterMensagens(iConversa: Integer; MensagemPrevia: Boolean);
var
  ObjConversa: TConversa;
  MsgRef: Integer;
  IDMsg: Integer;
  Msgs: TArrayMensagens;
begin
  ObjConversa := FDadosApp.Conversas.Get(iConversa);
  // Melhorar aqui
  if not Assigned(ObjConversa) then
  begin
    CarregarConversas;
    ObjConversa := FDadosApp.Conversas.Get(iConversa);
  end;

  if ObjConversa.Usuarios.Count = 0 then
    ObjConversa.AddUsuario(FDadosApp.Usuario);

  if MensagemPrevia then
  begin
    Msgs := ObjConversa.Mensagens.Items;
    MsgRef := ObjConversa.Mensagens.UltimaMensagemSincronizada;
    for IDMsg := Pred(Length(Msgs)) downto 0 do
      MsgRef := Min(Msgs[IDMsg].ID, MsgRef);

    if (MsgRef - 1) <= 0 then
      Exit;

    Conversa.Proxy.TAPIConversa.Mensagens(iConversa, MsgRef, QUANTIDADE_MENSAGENS_CARREGAMENTO, 0);
  end
  else
  if ObjConversa.Mensagens.UltimaMensagemSincronizada = 0 then
    Conversa.Proxy.TAPIConversa.Mensagens(iConversa, 0, QUANTIDADE_MENSAGENS_CARREGAMENTO, 0)
  else
    Conversa.Proxy.TAPIConversa.Mensagens(iConversa, ObjConversa.Mensagens.UltimaMensagemSincronizada + 1, 0, QUANTIDADE_MENSAGENS_CARREGAMENTO)
end;

procedure TDados.EventoObterMensagens(const Sender: TObject; const M: TObterMensagens);
var
  ObjConversa: TConversa;
  Msg: Conversa.Proxy.Tipos.TMensagem;
  Remetente: Conversa.Tipos.TUsuario;
  Mensagem: TMensagem;
  Ctd: Conversa.Proxy.Tipos.TMensagemConteudo;
  MensagemConteudo: TConteudo;
  MsgsEvento: TArrayMensagens;
begin
  if M.Value.Status <> TResponseStatus.Sucess then
    Exit;

  for Msg in M.Value.Dados do
  begin
    ObjConversa := FDadosApp.Conversas.Get(Msg.conversa_id);
    Remetente := FDadosApp.Usuarios.GetOrAdd(Msg.remetente_id);
    ObjConversa.AddUsuario(Remetente);

    Mensagem := ObjConversa.Mensagens.Get(Msg.id);

    if not Assigned(Mensagem) then
      Mensagem := TMensagem.New(Msg.id)
        .Remetente(FDadosApp.Usuarios.GetOrAdd(msg.remetente_id))
        .Conversa(ObjConversa);

    if Mensagem.Remetente = FDadosApp.Usuario then
      Mensagem.Lado(TLadoMensagem.Direito)
    else
      Mensagem.Lado(TLadoMensagem.Esquerdo);


    if Msg.inserida <> 0 then
      Mensagem.Inserida(TTimeZone.Local.ToLocalTime(Msg.inserida));
    if Msg.alterada <> 0 then
      Mensagem.Alterada(TTimeZone.Local.ToLocalTime(Msg.alterada));

    Mensagem.Recebida(Msg.recebida);
    Mensagem.Visualizada(Msg.visualizada);
    Mensagem.PrimeiraExibicao((Mensagem.Lado = TLadoMensagem.Esquerdo) and not Mensagem.Visualizada);

    for Ctd in Msg.conteudos do
    begin
      MensagemConteudo := TConteudo.New(Ctd.id);
      MensagemConteudo.Ordem(Ctd.ordem);

      if not (Ctd.tipo in [1,2,3]) then
        Sleep(0);

      MensagemConteudo.Tipo(TTipoConteudo(Ctd.tipo));
      MensagemConteudo.Nome(Ctd.nome);
      MensagemConteudo.Extensao(Ctd.extensao);
      case MensagemConteudo.Tipo of
        TTipoConteudo.Texto: MensagemConteudo.Conteudo(Ctd.conteudo);
        TTipoConteudo.Imagem: MensagemConteudo.Conteudo(DownloadAnexo(Ctd.conteudo));
        TTipoConteudo.Arquivo: MensagemConteudo.Conteudo(Ctd.conteudo);
        TTipoConteudo.MensagemAudio: MensagemConteudo.Conteudo(DownloadAnexo(Ctd.conteudo));
      end;
      Mensagem.conteudos.Add(MensagemConteudo);
    end;
    ObjConversa.Mensagens.Add(Mensagem);

    if not Mensagem.Visualizada and (Mensagem.Lado = TLadoMensagem.Esquerdo) then
      Inc(ObjConversa.MensagemSemVisualizar);

    if not Mensagem.Exibida then
      MsgsEvento := MsgsEvento + [Mensagem];
  end;

  TExibirMensagem.Send(MsgsEvento);

  AtualizarContador(nil, nil);
  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizarContadorConversa.Create(0));
end;

procedure TDados.CarregarContatos;
var
  Contato: Conversa.Proxy.Tipos.TContato;
begin
  for Contato in Conversa.Proxy.TAPIConversa.Usuario.Contatos do
  begin
    FDadosApp.Usuarios.Add(
      TUsuario.New(Contato.id)
        .Nome(Contato.nome)
        .Login(Contato.login)
        .Email(Contato.email)
        .Telefone(Contato.telefone)
    );
  end;
end;

procedure TDados.CarregarConversas;
//var
//  Conversa: TConversa;
//  bNova: Boolean;
begin
  Conversa.Proxy.TApiConversa.Conversas;
//  with TAPIConversa.Create do
//  try
//    Route('conversas');
//    GET;
//    for var Item in Response.ToJSONArray do
//    begin
//      Conversa := FDadosApp.Conversas.Get(Item.GetValue<Integer>('id'));
//
//      if not Assigned(Conversa) then
//      begin
//        bNova := True;
//        Conversa := TConversa.New(Item.GetValue<Integer>('id'));
//      end
//      else
//        bNova := False;
//
//      Conversa.Tipo(TTipoConversa(Item.GetValue<Integer>('tipo')));
//      Conversa.Descricao(Item.GetValue<String>('descricao'));
//      Conversa.AddUsuario(FDadosApp.Usuario);
//      Conversa.AddUsuario(FDadosApp.Usuarios.GetOrAdd(Item.GetValue<Integer>('destinatario_id')).Nome(Item.GetValue<String>('nome')));
//      Conversa.UltimaMensagem(Item.GetValue<String>('ultima_mensagem_texto'));
//      Conversa.CriadoEm(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('inserida'))));
//
//      if not Item.GetValue<String>('ultima_mensagem').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty then
//        Conversa.UltimaMensagemData(TTimeZone.Local.ToLocalTime(ISO8601ToDate(Item.GetValue<String>('ultima_mensagem'))));
//
//      if (Conversa.MensagemSemVisualizar = 0) and (not Item.GetValue<String>('mensagens_sem_visualizar').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty) then
//        Conversa.MensagemSemVisualizar := StrToIntDef(Item.GetValue<String>('mensagens_sem_visualizar'), 0);
//
//      if bNova then
//        FDadosApp.Conversas.Add(Conversa);
//
//      FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, Item.GetValue<Integer>('mensagem_id'));
//    end;
//  finally
//    Free;
//  end;
//  AtualizarContador(nil, nil);
//  TMessageManager.DefaultManager.SendMessage(nil, TEventoAtualizarContadorConversa.Create(0));
end;

procedure TDados.ObterConversas(const Sender: TObject; const M: TObterConversas);
var
  prxConversa: Conversa.Proxy.Tipos.TConversa;
  Conversa: TConversa;
  bNova: Boolean;
begin
  if M.Value.Status <> TResponseStatus.Sucess then
    Exit;

  for prxConversa in M.Value.Dados do
  begin
    Conversa := FDadosApp.Conversas.Get(prxConversa.id);

    if not Assigned(Conversa) then
    begin
      bNova := True;
      Conversa := TConversa.New(prxConversa.id);
    end
    else
      bNova := False;

    Conversa.Tipo(TTipoConversa(prxConversa.tipo));
    Conversa.Descricao(prxConversa.descricao);
    Conversa.AddUsuario(FDadosApp.Usuario);
    Conversa.AddUsuario(FDadosApp.Usuarios.GetOrAdd(prxConversa.destinatario_id).Nome(prxConversa.nome));
    Conversa.UltimaMensagem(prxConversa.ultima_mensagem_texto);
    Conversa.CriadoEm(TTimeZone.Local.ToLocalTime(prxConversa.inserida));

    if prxConversa.ultima_mensagem <> 0 then
      Conversa.UltimaMensagemData(TTimeZone.Local.ToLocalTime(prxConversa.ultima_mensagem));

    if (Conversa.MensagemSemVisualizar = 0) and (prxConversa.mensagens_sem_visualizar <> 0) then
      Conversa.MensagemSemVisualizar := prxConversa.mensagens_sem_visualizar;

    if bNova then
      FDadosApp.Conversas.Add(Conversa);

    FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, prxConversa.mensagem_id);
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
      TTipoConteudo.Imagem, TTipoConteudo.Arquivo, TTipoConteudo.MensagemAudio:
      begin
        if not TDirectory.Exists(PastaDados + PASTA_ANEXO + PathDelim) then
          TDirectory.CreateDirectory(PastaDados + PASTA_ANEXO + PathDelim);

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
  ObjConversa: TConversa;
  Mensagens: TArrayMensagens;
  sIDMensagens: String;
begin
  Dados.tmrAtualizarMensagens.Enabled := False;
  try
    for ObjConversa in FDadosApp.Conversas.Items do
    begin
      Mensagens := ObjConversa.Mensagens.ParaAtualizar;
      if Length(Mensagens) = 0 then
        Continue;

      sIDMensagens := EmptyStr;
      for I := 0 to Pred(Length(Mensagens)) do
        sIDMensagens := sIDMensagens + IfThen(not sIDMensagens.Trim.IsEmpty, ',') + Mensagens[I].ID.ToString;

      Conversa.Proxy.TAPIConversa.Mensagem.Status(ObjConversa.ID, sIDMensagens);
    end;

    Conversa.Proxy.TAPIConversa.MensagensNovas(FDadosApp.UltimaMensagemNotificada);
  finally
    Dados.tmrAtualizarMensagens.Enabled := True;
  end;
end;

function TDados.UltimaMensagemNotificada: Integer;
begin
  Result := FDadosApp.UltimaMensagemNotificada;
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
  Conversa.Proxy.TAPIConversa.Mensagem.Visualizar(Mensagem.Conversa.ID, Mensagem.ID);
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

procedure TDados.ObterMensagensStatus(const Sender: TObject; const M: TObterMensagensStatus);
var
  MsgStatus: TMensagemStatus;
  Cvs: TConversa;
  Msg: TMensagem;
begin
  if M.Value.Status <> TResponseStatus.Sucess then
    Exit;

  for MsgStatus in M.Value.Dados do
  begin
    Cvs := FDadosApp.Conversas.Get(MsgStatus.conversa_id);
    if not Assigned(Cvs) then
      Continue;

    Msg := Cvs.Mensagens.Get(MsgStatus.mensagem_id);
    if not Assigned(Msg) then
      Continue;

    Msg
      .Recebida(MsgStatus.recebida)
      .Visualizada(MsgStatus.visualizada);
  end;
end;

procedure TDados.ObterMensagensNovas(const Sender: TObject; const M: TObterMensagensNovas);
var
  MsgNova: TMensagemNova;
begin
  if M.Value.Status <> TResponseStatus.Sucess then
    Exit;

  for MsgNova in M.Value.Dados do
  begin
    FDadosApp.UltimaMensagemNotificada := Max(FDadosApp.UltimaMensagemNotificada, MsgNova.mensagem_id);
    ObterMensagens(MsgNova.conversa_id, False);
  end;
end;

end.
