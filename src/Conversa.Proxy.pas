﻿// Eduardo/Daniel - 17/05/2025
unit Conversa.Proxy;

interface

uses
  System.Classes,
  System.SysUtils,
  REST.API,
  Conversa.Proxy.Tipos;

type
  TDispositivoProxy = record
    function Incluir(DeviceInfo: TDispositivo): TRespostaDispositivo;
    procedure Alterar(DeviceInfo: TDispositivo);
    procedure Usuario(DispositivoID: Integer);
  end;

  TContato = record
    procedure Incluir(Contato: Integer);
    procedure Excluir(ID: Integer);
  end;

  TUsuario = record
    Contato: TContato;
    procedure Incluir(Usuario: TReqUsuario);
    procedure Alterar(Usuario: TReqUsuario);
    procedure Excluir(ID: Integer);
    function Contatos: TContatos;
  end;

  TConversaUsuario = record
    procedure Incluir(Conversa, Usuario: Integer);
    procedure Excluir(ID: Integer);
  end;

  TConversa = record
    class var Usuario: TConversaUsuario;
    function Incluir(sDescricao: String; iTipo: Integer): TRespostaConversa;
    procedure Alterar(ID: Integer; sDescricao: String; iTipo: Integer);
    procedure Excluir(ID: Integer);
  end;

  TMensagem = record
    function Incluir(Mensagem: TReqMensagem): TRespostaMensagem;
    procedure Excluir(ID: Integer);
    procedure Visualizar(iConversa, iMensagem: Integer);
    procedure Status(iConversa: Integer; sMensagensId: String);
  end;

  TAnexo = record
    function Existe(sIdentificador: String): Boolean;
    function Download(sIdentificador: String): TRespostaDownloadAnexo;
    procedure Incluir(iTipo: Integer; sNome, sExtensao: String; aConteudo: TStringStream);
  end;

  TAPIConversa = record
  public
    class var Usuario: TUsuario;
    class var Mensagem: TMensagem;
    class var Dispositivo: TDispositivoProxy;
    class var Conversa: TConversa;
    class var Anexo: TAnexo;
    class function Login(sLogin, sSenha: String; Dispositivo: Integer): TRespostaLogin; static;
    class procedure Conversas; static;
    class procedure Mensagens(Conversa, MensagemReferencia, MensagensPrevias, MensagensSeguintes: Integer); static;
    class procedure MensagensNovas(UltimaMensagem: Integer); static;
  end;

implementation

uses
  System.JSON,
  System.JSON.Serializers,
  System.DateUtils,
  Conversa.Configuracoes,
  Conversa.Eventos,
  Conversa.Serializer;

type
  TAPIInternal = class(TRESTAPI)
  private
    class var FToken: String;
  private
    FMensagemErro: String;
  public
    constructor Create;
    property MensagemErro: String read FMensagemErro;
    function InternalExecute: TRESTAPI; override;
    procedure Tentativa(iQuantidade: Integer);
    procedure ValidarErro(Response: TResponse);
  end;

{ TAPIInternal }

constructor TAPIInternal.Create;
begin
  inherited;
  Host(Configuracoes.Host);

  if not FToken.IsEmpty then
    Authorization(TAuthBearer.New(FToken));
  FMensagemErro := EmptyStr;
end;

function TAPIInternal.InternalExecute: TRESTAPI;
var
  vJSON: TJSONValue;
begin
  Result := inherited InternalExecute;

  vJSON := Response.ToJSON;
  if Response.Status <> TResponseStatus.Sucess then
  begin
    if Assigned(vJSON) and Assigned(vJSON.FindValue('error')) then
      FMensagemErro := vJSON.GetValue<String>('error')
    else
      FMensagemErro := Response.ToString;
  end;
end;

procedure TAPIInternal.Tentativa(iQuantidade: Integer);
begin
  for var I := 1 to iQuantidade do
  begin
    InternalExecute;

    // Success: sai do loop
    // Unknown: erro de rede e deve, tentar novamente
    // Erro...: erro do servidor não adianta tentar novamente
    if Response.Status <> TResponseStatus.Unknown then
      Break;

    if I <> iQuantidade then
      Sleep(I * I * 1000);
  end;
end;

procedure TAPIInternal.ValidarErro(Response: TResponse);
var
  Evento: TRespostaErro;
begin
  if Response.Status = TResponseStatus.Sucess then
    Exit;

  Evento := Default(TRespostaErro);
  Evento.Status := Response.Status;
  Evento.Erro := MensagemErro;
  Evento.Dados := Response.StatusCode;
  TErroServidor.Send(Evento);
  Abort;
end;

{ TAPIConversa }

class function TAPIConversa.Login(sLogin, sSenha: String; Dispositivo: Integer): TRespostaLogin;
begin
  with TAPIInternal.Create do
  try
    Route('login');
    Body(
      TJSONObject.Create
        .AddPair('login', sLogin)
        .AddPair('senha', sSenha)
        .AddPair('dispositivo_id', Dispositivo)
    );
    POST;

    if Response.Status <> TResponseStatus.Sucess then
    begin
      if Trunc(Response.StatusCode div 100) = 4 then
      begin
        if FMensagemErro.Contains('Seção Encerrada!') then
          Configuracoes.DispositivoId := 0;

        Configuracoes.Senha := EmptyStr;
        Configuracoes.Save;
      end;

      raise Exception.Create(MensagemErro);
    end;

    with TJsonSerializer.Create do
    try
      Result := Deserialize<TRespostaLogin>(Response.ToString);
    finally
      Free;
    end;

    FToken := Result.token;
  finally
    Free;
  end;
end;

class procedure TAPIConversa.Conversas;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Resposta: TRespostaConversas;
    begin
      with TAPIInternal.Create do
      try
        Route('conversas');
        GET;

        Resposta.Status := Response.Status;

        if Response.Status = TResponseStatus.Sucess then
        begin
          with TJsonSerializer.Create do
          try
            Resposta.Dados := Deserialize<TConversas>(Response.ToString);
          finally
            Free;
          end;
        end;

        TObterConversas.Send(Resposta);
      finally
        Free;
      end;
    end
  ).Start;
end;

class procedure TAPIConversa.Mensagens(Conversa, MensagemReferencia, MensagensPrevias, MensagensSeguintes: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Resposta: TRespostaMensagens;
    begin
      with TAPIInternal.Create do
      try
        Query(
          TJSONObject.Create
            .AddPair('conversa', Conversa)
            .AddPair('mensagemreferencia', MensagemReferencia)
            .AddPair('mensagensprevias', MensagensPrevias)
            .AddPair('mensagensseguintes', MensagensSeguintes)
        );
        Route('mensagens');
        GET;

        Resposta.Status := Response.Status;
        Resposta.Erro := MensagemErro;

        if Response.Status = TResponseStatus.Sucess then
        begin
          Resposta.Dados := TJsonSerializer<TMensagens>.FromStr(Response.ToString);
//          with TJsonSerializer.Create do
//          try
//            Resposta.Dados := Deserialize<TMensagens>(Response.ToString);
//          finally
//            Free;
//          end;
        end;

        TObterMensagens.Send(Resposta);
      finally
        Free;
      end;
    end
  ).Start;
end;

class procedure TAPIConversa.MensagensNovas(UltimaMensagem: Integer);
var
  Resposta: TRespostaMensagensNovas;
begin
  with TAPIInternal.Create do
  try
    Query(TJSONObject.Create.AddPair('ultima', UltimaMensagem));
    Route('mensagens/novas');
    GET;

    Resposta.Status := Response.Status;
    Resposta.Erro := MensagemErro;

    if Response.Status = TResponseStatus.Sucess then
    begin
      with TJsonSerializer.Create do
      try
        Resposta.Dados := Deserialize<TMensagensNovas>(Response.ToString);
      finally
        Free;
      end;
    end;

    TObterMensagensNovas.Send(Resposta);
  finally
    Free;
  end;
end;

{ TUsuario }

procedure TUsuario.Incluir(Usuario: TReqUsuario);
var
  oUsuario: TJSONObject;
begin
  with TAPIInternal.Create do
  try
    with TJsonSerializer.Create do
    try
      oUsuario := TJSONObject.ParseJSONValue(Serialize<TReqUsuario>(Usuario)) as TJSONObject;
    finally
      Free;
    end;

    Route('usuario');
    Body(oUsuario);
    PUT;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TUsuario.Alterar(Usuario: TReqUsuario);
var
  oUsuario: TJSONObject;
begin
  with TAPIInternal.Create do
  try
    with TJsonSerializer.Create do
    try
      oUsuario := TJSONObject.ParseJSONValue(Serialize<TReqUsuario>(Usuario)) as TJSONObject;
    finally
      Free;
    end;

    Route('usuario');
    Body(oUsuario);
    PATCH;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TUsuario.Excluir(ID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('usuario');
    Query(TJSONObject.Create.AddPair('id', ID));
    DELETE;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

function TUsuario.Contatos: TContatos;
begin
  {TODO -oDaniel -cEventos : Refatorar usuario/contatos para utilizar eventos}
  with TAPIInternal.Create do
  try
    Route('usuario/contatos');
    GET;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create(MensagemErro);

    with TJsonSerializer.Create do
    try
      Result := Deserialize<TContatos>(Response.ToString);
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

procedure TMensagem.Visualizar(iConversa, iMensagem: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      with TAPIInternal.Create do
      try
        Route('mensagem/visualizar');
        Query(
          TJSONObject.Create
            .AddPair('conversa', iConversa)
            .AddPair('mensagem', iMensagem)
        );
        Method(TRESTMethod.GET);
        Tentativa(5);
        ValidarErro(Response);
      finally
        Free;
      end;
    end
  ).Start;
end;

{ TDispositivo }

function TDispositivoProxy.Incluir(DeviceInfo: TDispositivo): TRespostaDispositivo;
begin
  with TAPIInternal.Create do
  try
    Route('dispositivo');
    Body(
      TJSONObject.Create
        .AddPair('nome', DeviceInfo.nome)
        .AddPair('modelo', DeviceInfo.modelo)
        .AddPair('versao_so', DeviceInfo.versao_so)
        .AddPair('plataforma', DeviceInfo.plataforma)
    );
    PUT;
    ValidarErro(Response);
    Result.Status := Response.Status;

    if Result.Status <> TResponseStatus.Sucess then
      Result.Erro := Response.ToString;

    with TJsonSerializer.Create do
    try
      Result.Dados := Deserialize<TDispositivo>(Response.ToString);
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

procedure TDispositivoProxy.Alterar(DeviceInfo: TDispositivo);
begin
  with TAPIInternal.Create do
  try
    Route('dispositivo');
      Body(
        TJSONObject.Create
          .AddPair('id', DeviceInfo.id)
          .AddPair('nome', DeviceInfo.nome)
          .AddPair('modelo', DeviceInfo.modelo)
          .AddPair('versao_so', DeviceInfo.versao_so)
          .AddPair('plataforma', DeviceInfo.plataforma)
      );
    PATCH;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TDispositivoProxy.Usuario(DispositivoID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('dispositivo/usuario');
    Query(TJSONObject.Create.AddPair('dispositivo_id', DispositivoID));
    PUT;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

{ TContato }

procedure TContato.Incluir(Contato: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('usuario/contato');
    Query(TJSONObject.Create.AddPair('relacionamento_id', Contato));
    PUT;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TContato.Excluir(ID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('usuario/contato');
    Query(TJSONObject.Create.AddPair('id', ID));
    DELETE;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

{ TConversa }

function TConversa.Incluir(sDescricao: String; iTipo: Integer): TRespostaConversa;
begin
  with TAPIInternal.Create do
  try
    Route('conversa');
    Body(
      TJSONObject.Create
        .AddPair('descricao', sDescricao)
        .AddPair('tipo', iTipo)
        .AddPair('inserida', DateToISO8601(Now))
    );
    PUT;
    ValidarErro(Response);

    Result.Status := Response.Status;
    with TJsonSerializer.Create do
    try
      Result.Dados := Deserialize<Conversa.Proxy.Tipos.TConversa>(Response.ToString);
    finally
      Free;
    end;
  finally
    Free;
  end;
end;

procedure TConversa.Alterar(ID: Integer; sDescricao: String; iTipo: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('conversa');
    Body(
      TJSONObject.Create
        .AddPair('id', ID)
        .AddPair('descricao', sDescricao)
        .AddPair('tipo', iTipo)
    );
    PATCH;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TConversa.Excluir(ID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('conversa');
    Query(TJSONObject.Create.AddPair('id', ID));
    DELETE;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

{ TConversaUsuario }

procedure TConversaUsuario.Incluir(Conversa, Usuario: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('conversa/usuario');
    Body(
      TJSONObject.Create
        .AddPair('conversa_id', Conversa)
        .AddPair('usuario_id', Usuario)
    );
    PUT;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

procedure TConversaUsuario.Excluir(ID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('conversa/usuario');
    Query(TJSONObject.Create.AddPair('id', ID));
    DELETE;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

{ TMensagem }

function TMensagem.Incluir(Mensagem: TReqMensagem): TRespostaMensagem;
var
  oMensagem: TJSONObject;
begin
  with TAPIInternal.Create do
  try
    with TJsonSerializer.Create do
    try
      oMensagem := TJSONObject.ParseJSONValue(Serialize<TReqMensagem>(Mensagem)) as TJSONObject;
    finally
      Free;
    end;

    Route('mensagem');
    Body(oMensagem);
    PUT;
    ValidarErro(Response);
    Result.Status := Response.Status;
    Result.Erro := MensagemErro;
    Result.Dados := TJsonSerializer<Conversa.Proxy.Tipos.TMensagem>.FromStr(Response.ToString);
  finally
    Free;
  end;
end;

procedure TMensagem.Status(iConversa: Integer; sMensagensId: String);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Resposta: TRespostaMensagensStatus;
    begin
      with TAPIInternal.Create do
      try
        Route('mensagem/status');
        Query(
          TJSONObject.Create
            .AddPair('conversa', iConversa)
            .AddPair('mensagem', sMensagensId)
        );
        GET;

        Resposta := Default(TRespostaMensagensStatus);
        Resposta.Status := Response.Status;
        Resposta.Erro := MensagemErro;
        if Resposta.Status = TResponseStatus.Sucess then
        begin
          with TJsonSerializer.Create do
          try
            Resposta.Dados := Deserialize<TMensagensStatus>(Response.ToString);
          finally
            Free;
          end;
        end;

        TObterMensagensStatus.Send(Resposta);
      finally
        Free;
      end;
    end
  ).Start;
end;

procedure TMensagem.Excluir(ID: Integer);
begin
  with TAPIInternal.Create do
  try
    Route('mensagem');
    Query(TJSONObject.Create.AddPair('id', ID));
    DELETE;
    ValidarErro(Response);
  finally
    Free;
  end;
end;

{ TAnexo }

function TAnexo.Existe(sIdentificador: String): Boolean;
begin
  with TAPIInternal.Create do
  try
    Route('anexo/existe');
    Query(TJSONObject.Create.AddPair('identificador', sIdentificador));
    GET;
    ValidarErro(Response);
    Result := Response.ToJSON.GetValue<Boolean>('existe');
  finally
    Free;
  end;
end;

function TAnexo.Download(sIdentificador: String): TRespostaDownloadAnexo;
begin
//  TThread.CreateAnonymousThread(
//    procedure
//    var
//      Resposta: TRespostaDownloadAnexo;
//    begin
      with TAPIInternal.Create do
      try
        Route('anexo');
        Query(TJSONObject.Create.AddPair('identificador', sIdentificador));
        GET;

        Result := Default(TRespostaDownloadAnexo);
        Result.Status := Response.Status;
        Result.Erro := MensagemErro;
        if Result.Status = TResponseStatus.Sucess then
          Result.Dados := Response.ToStream.Bytes;
//        TDownloadAnexo.Send(Resposta);
      finally
        Free;
      end;
//    end
//  ).Start;
end;

procedure TAnexo.Incluir(iTipo: Integer; sNome, sExtensao: String; aConteudo: TStringStream);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      with TAPIInternal.Create do
      try
        Route('anexo');
        Headers(
          TJSONObject.Create
            .AddPair('Content-Type', 'application/octet-stream')
        );
        Query(
          TJSONObject.Create
            .AddPair('tipo', iTipo)
            .AddPair('nome', sNome)
            .AddPair('extensao', sExtensao)
        );
        Body(TStream(aConteudo));
        PUT;
        ValidarErro(Response);
      finally
        Free;
      end;
    end
  ).Start;
end;

end.
