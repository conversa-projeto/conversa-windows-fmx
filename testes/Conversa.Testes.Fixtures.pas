unit Conversa.Testes.Fixtures;

{ Lê os JSON de testes\fixtures (respostas do servidor: exemplos do doc 01 e capturas higienizadas do servidor
  de desenvolvimento). A pasta é procurada subindo a partir do executável (bin\Win64\Debug -> raiz). }

interface

function LerFixture(const ANome: string): string;

implementation

uses
  System.SysUtils,
  System.IOUtils;

var
  PastaEncontrada: string;

function PastaDasFixtures: string;
var
  LDir: string;
  LCandidata: string;
  I: Integer;
begin
  if PastaEncontrada <> '' then
    Exit(PastaEncontrada);
  LDir := ExtractFilePath(ParamStr(0));
  for I := 0 to 8 do
  begin
    LCandidata := TPath.Combine(LDir, 'testes\fixtures');
    if TDirectory.Exists(LCandidata) then
    begin
      PastaEncontrada := LCandidata;
      Exit(PastaEncontrada);
    end;
    LDir := ExtractFilePath(ExcludeTrailingPathDelimiter(LDir));
    if LDir = '' then
      Break;
  end;
  raise EFileNotFoundException.Create('Pasta testes\fixtures não encontrada a partir de ' + ParamStr(0));
end;

function LerFixture(const ANome: string): string;
begin
  Result := TFile.ReadAllText(TPath.Combine(PastaDasFixtures, ANome), TEncoding.UTF8);
end;

end.
