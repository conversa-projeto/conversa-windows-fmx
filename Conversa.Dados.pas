// Eduardo - 03/03/2024
unit Conversa.Dados;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Vcl.ExtCtrls,
  Data.DB,
  Datasnap.DBClient,
  REST.API,
  Mensagem.Tipos;

type
  TDados = class(TDataModule)
    cdsConversas: TClientDataSet;
    cdsConversasid: TIntegerField;
    cdsConversasdescricao: TStringField;
    cdsConversasultima_mensagem: TDateTimeField;
    tmrAtualizarMensagens: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure tmrAtualizarMensagensTimer(Sender: TObject);
  private
    Fid: Integer;
    Fnome: String;
    Femail: String;
    Ftelefone: String;
  public
    property ID: Integer read Fid;
    property Nome: String read Fnome;
    procedure Login(sLogin, sSenha: String);
    procedure Conversas;
    function Mensagens(iConversa: Integer): TArray<TMensagem>;
    procedure EnviarMensagem(Mensagem: TMensagem);
    function DownloadAnexo(sIdentificador: String): String;
  end;

  TAPIConversa = class(TRESTAPI)
  public
    constructor Create;
    function InternalExecute: TRESTAPI; override;
  end;

var
  Dados: TDados;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.Hash,
  Conversa.Configuracoes;

const
//  SERVIDOR = 'http://localhost:90';
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
  cdsConversas.CreateDataSet;
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

function TDados.Mensagens(iConversa: Integer): TArray<TMensagem>;
var
  Mensagem: TMensagem;
  MensagemConteudo: TMensagemConteudo;
begin
  with TAPIConversa.Create do
  try
    Route('mensagens');
    Query(TJSONObject.Create.AddPair('ultima', 0)); // implementar depois o controle de ultima mensagem de cada conversa
    Query(TJSONObject.Create.AddPair('conversa', iConversa));
    GET;

    Result := [];
    for var Item in Response.ToJSONArray do
    begin
      Mensagem := Default(TMensagem);
      Mensagem.id := Item.GetValue<Integer>('id');
      Mensagem.remetente_id := Item.GetValue<Integer>('remetente_id');
      Mensagem.remetente := Item.GetValue<String>('remetente');
      Mensagem.conversa_id := Item.GetValue<Integer>('conversa_id');
      if Mensagem.remetente_id = Dados.ID then
        Mensagem.lado := TLado.Direito
      else
        Mensagem.lado := TLado.Esquerdo;
      if not (Item.FindValue('inserida') is TJSONNull) then
        Mensagem.inserida := ISO8601ToDate(Item.GetValue<String>('inserida'));
      if not (Item.FindValue('alterada') is TJSONNull) then
        Mensagem.alterada := ISO8601ToDate(Item.GetValue<String>('alterada'));

      for var Conteudo in Item.GetValue<TJSONArray>('conteudos') do
      begin
        MensagemConteudo := Default(TMensagemConteudo);
        MensagemConteudo.id := Conteudo.GetValue<Integer>('id');
        MensagemConteudo.ordem := Conteudo.GetValue<Integer>('ordem');
        MensagemConteudo.tipo := Conteudo.GetValue<Integer>('tipo');
        case MensagemConteudo.Tipo of
          1: MensagemConteudo.conteudo := Conteudo.GetValue<String>('conteudo');                // 1-Texto
          2: MensagemConteudo.conteudo := DownloadAnexo(Conteudo.GetValue<String>('conteudo')); // 2-Imagem
        end;
        Mensagem.conteudos := Mensagem.conteudos + [MensagemConteudo];
      end;

      Result := Result + [Mensagem];
    end;
  finally
    Free;
  end;
end;

procedure TDados.Conversas;
begin
  with TAPIConversa.Create do
  try
    Route('conversas');
    GET;

    cdsConversas.EmptyDataSet;
    for var Item in Response.ToJSONArray do
    begin
      cdsConversas.Append;
      cdsConversas.FieldByName('id').AsInteger := Item.GetValue<Integer>('id');
      cdsConversas.FieldByName('descricao').AsString := Item.GetValue<String>('descricao');
      cdsConversas.FieldByName('ultima_mensagem_texto').AsString := Item.GetValue<String>('ultima_mensagem_texto');
      if not Item.GetValue<String>('ultima_mensagem').ToLower.Replace('null', '').ToUpper.Trim.IsEmpty then

      cdsConversas.FieldByName('ultima_mensagem').AsDateTime := ISO8601ToDate(Item.GetValue<String>('ultima_mensagem'));
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
  oJSON.AddPair('conversa_id', Mensagem.conversa_id);
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
  finally
    Free;
  end;
end;

procedure TDados.tmrAtualizarMensagensTimer(Sender: TObject);
begin
  Dados.tmrAtualizarMensagens.Enabled := False;
  try
    with TAPIConversa.Create do
    try
      Route('mensagens/novas');
      Query(TJSONObject.Create.AddPair('ultima', 0)); // obter a ultima mensagem de todas as conversas
      GET;
      // retorna a lista das converas que tiveram mensagens adicionadas
      // se tiver alguma coisa, exibir na lista de conversas um icone para informar
    finally
      Free;
    end;
  finally
    Dados.tmrAtualizarMensagens.Enabled := True;
  end;
end;

end.
