// Eduardo/Daniel - 17/05/2025
unit Conversa.Proxy;

interface

uses
  REST.API,
  Conversa.Tipos;

type
  TUsuario = record
    function Contatos: TContatos;
  end;

  TMensagem = record
    procedure Visualizar(iConversa, iMensagem: Integer);
  end;

  TAPIConversa = record
  public
    class var Usuario: TUsuario;
    class var Mensagem: TMensagem;
    class function Login(sLogin, sSenha: String): TRespostaLogin; static;
    class procedure Conversas; static;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.JSON.Serializers,
  Conversa.Eventos;

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
  end;

{ TAPIInternal }

constructor TAPIInternal.Create;
begin
  inherited;
  Host('http://localhost:90');
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

{ TAPIConversa }

class function TAPIConversa.Login(sLogin, sSenha: String): TRespostaLogin;
begin
  with TAPIInternal.Create do
  try
    Route('login');
    Body(
      TJSONObject.Create
        .AddPair('login', sLogin)
        .AddPair('senha', sSenha)
    );
    POST;

    if Response.Status <> TResponseStatus.Sucess then
      raise Exception.Create(MensagemErro);

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

{ TUsuario }

function TUsuario.Contatos: TContatos;
begin
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

{ TMensagem }

procedure TMensagem.Visualizar(iConversa, iMensagem: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Evento: TRespostaErro;
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

        if Response.Status = TResponseStatus.Error then
        begin
          Evento.Status := Response.Status;
          Evento.Erro := MensagemErro;
          Evento.Dados := Response.StatusCode;
          TErroServidor.Send(Evento);
        end;
      finally
        Free;
      end;
    end
  ).Start;
end;

end.
