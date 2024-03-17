// Eduardo - 03/03/2024
unit Conversa.Dados;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Data.DB,
  Datasnap.DBClient,
  REST.API;

type
  TDados = class(TDataModule)
    cdsConversas: TClientDataSet;
    cdsConversasid: TIntegerField;
    cdsConversasdescricao: TStringField;
    cdsConversasultima_mensagem: TDateTimeField;
    cdsMensagens: TClientDataSet;
    cdsMensagensid: TIntegerField;
    cdsMensagensinserida: TDateTimeField;
    cdsMensagensalterada: TDateTimeField;
    cdsMensagensremetente: TStringField;
    cdsMensagensremetente_id: TIntegerField;
    cdsConteudos: TClientDataSet;
    cdsMensagensconteudos: TDataSetField;
    cdsConteudosid: TIntegerField;
    cdsConteudosordem: TIntegerField;
    cdsConteudostipo: TIntegerField;
    cdsConteudosconteudo: TBlobField;
    procedure DataModuleCreate(Sender: TObject);
  private
    Fid: Integer;
    Fnome: String;
    Femail: String;
    Ftelefone: String;
  public
    property ID: Integer read Fid;
    procedure Login(sLogin, sSenha: String);
    procedure Conversas;
    procedure Mensagens(iConversa: Integer);
  end;

  TAPIConversa = class(TRESTAPI)
  public
    constructor Create;
    function InternalExecute: TRESTAPI; override;
  end;

var
  Dados: TDados;

const
  SERVIDOR = 'http://localhost:90';

implementation

uses
  System.DateUtils;

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TAPIConversa }

constructor TAPIConversa.Create;
begin
  inherited;
  Host(SERVIDOR);
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
  cdsMensagens.CreateDataSet;
end;

procedure TDados.Login(sLogin, sSenha: String);
begin
  with TAPIConversa.Create do
  try
    Host(SERVIDOR);
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

procedure TDados.Mensagens(iConversa: Integer);
begin
  with TAPIConversa.Create do
  try
    Host(SERVIDOR);
    Route('mensagens');
    Headers(TJSONObject.Create.AddPair('uid', Fid));
    Query(TJSONObject.Create.AddPair('conversa', iConversa));
    GET;

    cdsMensagens.EmptyDataSet;
    for var Item in Response.ToJSONArray do
    begin
      cdsMensagens.Append;
      cdsMensagens.FieldByName('id').AsInteger := Item.GetValue<Integer>('id');
      cdsMensagens.FieldByName('remetente_id').AsString := Item.GetValue<String>('remetente_id');
      cdsMensagens.FieldByName('remetente').AsString := Item.GetValue<String>('remetente');
      if not (Item.FindValue('inserida') is TJSONNull) then
        cdsMensagens.FieldByName('inserida').AsDateTime := ISO8601ToDate(Item.GetValue<String>('inserida'));
      if not (Item.FindValue('alterada') is TJSONNull) then
        cdsMensagens.FieldByName('alterada').AsDateTime := ISO8601ToDate(Item.GetValue<String>('alterada'));

      for var Conteudo in Item.GetValue<TJSONArray>('conteudos') do
      begin
        cdsConteudos.Append;
        cdsConteudos.FieldByName('id').AsInteger      := Conteudo.GetValue<Integer>('id');
        cdsConteudos.FieldByName('ordem').AsInteger   := Conteudo.GetValue<Integer>('ordem');
        cdsConteudos.FieldByName('tipo').AsInteger    := Conteudo.GetValue<Integer>('tipo');
        cdsConteudos.FieldByName('conteudo').AsString := Conteudo.GetValue<String>('conteudo');
      end;
    end;
  finally
    Free;
  end;
end;

procedure TDados.Conversas;
begin
  with TAPIConversa.Create do
  try
    Host(SERVIDOR);
    Headers(TJSONObject.Create.AddPair('uid', Fid));
    Route('conversas');
    GET;

    cdsConversas.EmptyDataSet;
    for var Item in Response.ToJSONArray do
    begin
      cdsConversas.Append;
      cdsConversas.FieldByName('id').AsInteger := Item.GetValue<Integer>('id');
      cdsConversas.FieldByName('descricao').AsString := Item.GetValue<String>('descricao');
      cdsConversas.FieldByName('ultima_mensagem').AsDateTime := ISO8601ToDate(Item.GetValue<String>('ultima_mensagem'));
    end;
  finally
    Free;
  end;
end;

end.
