// Eduardo - 03/03/2024
unit Conversa.Principal;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.ListView.Types,
  FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  FMX.ListView,
  System.Rtti,
  System.Bindings.Outputs,
  Fmx.Bind.Editors,
  Data.Bind.EngExt,
  Fmx.Bind.DBEngExt,
  Data.Bind.Components,
  Data.Bind.DBScope,
  FMX.Objects,
  FMX.Layouts,
  Conversa.Conteudo;

type
  TPrincipal = class(TForm)
    blsDados: TBindingsList;
    bsrConversas: TBindSourceDB;
    lwConversas: TListView;
    LinkListControlToField1: TLinkListControlToField;
    lytConteudo: TLayout;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lwConversasChange(Sender: TObject);
  private
    FConteudos: TArray<TConteudo>;
  end;

var
  Principal: TPrincipal;

implementation

uses
  Conversa.Dados,
  Conversa.Login,
  Mensagem.Tipos,
  System.NetEncoding;

{$R *.fmx}

procedure TPrincipal.FormDestroy(Sender: TObject);
var
  Conteudo: TConteudo;
begin
  for Conteudo in FConteudos do
    Conteudo.Free;
end;

procedure TPrincipal.FormShow(Sender: TObject);
begin
  TLogin.New(Self, Dados.Conversas);
end;

function HexToBytes(const Hex: string): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(Hex) div 2);
  for I := 1 to Length(Hex) div 2 do
    Result[I - 1] := StrToInt('$'+ Copy(Hex, 2 * I - 1, 2));
end;

function DecodeHex(const HexStr: string): string;
var
  DecodedBytes: TBytes;
  AnsiStr: AnsiString;
begin
  // Remova o prefixo '\\x' se estiver presente
  if HexStr.StartsWith('\x') then
    DecodedBytes := HexToBytes(Copy(HexStr, 3, Length(HexStr) - 2))
  else
    DecodedBytes := HexToBytes(HexStr);

  // Decodifique os bytes em uma string Ansi
  SetString(AnsiStr, PAnsiChar(@DecodedBytes[0]), Length(DecodedBytes));
  Result := String(AnsiStr);
end;

procedure TPrincipal.lwConversasChange(Sender: TObject);
var
  Conteudo: TConteudo;
  bJaCriado: Boolean;
  Mensagem: TMensagem;
begin
  bJaCriado := False;
  for Conteudo in FConteudos do
  begin
    if lwConversas.ItemIndex <> Conteudo.ID then
      Conteudo.Visible := False
    else
    begin
      bJaCriado := True;
      Conteudo.Visible := True;
    end;
  end;

  if bJaCriado then
    Exit;

  Conteudo := TConteudo.Create(lytConteudo);
  Conteudo.ID := lwConversas.ItemIndex;
  FConteudos := FConteudos + [Conteudo];

  // Preencher dados
  Dados.Mensagens(Dados.cdsConversas.FieldByName('id').AsInteger);

  Dados.cdsMensagens.First;
  while not Dados.cdsMensagens.Eof do
  begin
    Mensagem := Default(TMensagem);
    Mensagem.ID := Dados.cdsMensagens.FieldByName('id').AsInteger;
    Mensagem.EnviadaEm := Dados.cdsMensagens.FieldByName('inserida').AsDateTime;
    if Dados.cdsMensagens.FieldByName('remetente_id').AsInteger = Dados.ID then
      Mensagem.Lado := TLado.Direito
    else
      Mensagem.Lado := TLado.Esquerdo;
    Mensagem.Remetente := Dados.cdsMensagens.FieldByName('remetente').AsString;

    Dados.cdsConteudos.First;
    while not Dados.cdsConteudos.Eof do
    begin
      case Dados.cdsConteudos.FieldByName('tipo').AsInteger of
        1: Mensagem.Texto := Trim(Mensagem.Texto + sLineBreak + DecodeHex(Dados.cdsConteudos.FieldByName('conteudo').AsString));
      end;
      Dados.cdsConteudos.Next;
    end;

    Conteudo.AdicionarMensagem(Mensagem);
    Dados.cdsMensagens.Next;
  end;
end;

end.
