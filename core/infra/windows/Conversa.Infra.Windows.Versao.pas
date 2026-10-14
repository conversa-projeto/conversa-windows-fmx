unit Conversa.Infra.Windows.Versao;

{ Versão do executável, lida do recurso VERSIONINFO (o que o Windows mostra em Propriedades > Detalhes). }

interface

type
  TVersaoApp = record
    Maior: Word;
    Menor: Word;
    Revisao: Word;
    Compilacao: Word;
    /// <summary>Versão do próprio executável; zeros se o recurso não existir.</summary>
    class function DoExecutavel: TVersaoApp; static;
    class function DoArquivo(const ACaminho: string): TVersaoApp; static;
    /// <summary>"0.1.0"</summary>
    function Curta: string;
    /// <summary>"0.1.0.123"</summary>
    function Completa: string;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows;

{ TVersaoApp }

class function TVersaoApp.DoArquivo(const ACaminho: string): TVersaoApp;
var
  LTamanho: DWORD;
  LIgnorado: DWORD;
  LDados: TBytes;
  LBloco: Pointer;
  LTamanhoBloco: UINT;
  LInfo: PVSFixedFileInfo;
begin
  Result := Default(TVersaoApp);
  LTamanho := GetFileVersionInfoSize(PChar(ACaminho), LIgnorado);
  if LTamanho = 0 then
    Exit;
  SetLength(LDados, LTamanho);
  if not GetFileVersionInfo(PChar(ACaminho), 0, LTamanho, @LDados[0]) then
    Exit;
  if not VerQueryValue(@LDados[0], PChar('\'), LBloco, LTamanhoBloco) then
    Exit;
  if LTamanhoBloco < SizeOf(TVSFixedFileInfo) then
    Exit;
  LInfo := PVSFixedFileInfo(LBloco);
  Result.Maior := Word(LInfo^.dwFileVersionMS shr 16);
  Result.Menor := Word(LInfo^.dwFileVersionMS and $FFFF);
  Result.Revisao := Word(LInfo^.dwFileVersionLS shr 16);
  Result.Compilacao := Word(LInfo^.dwFileVersionLS and $FFFF);
end;

class function TVersaoApp.DoExecutavel: TVersaoApp;
begin
  Result := DoArquivo(ParamStr(0));
end;

function TVersaoApp.Curta: string;
begin
  Result := Format('%d.%d.%d', [Maior, Menor, Revisao]);
end;

function TVersaoApp.Completa: string;
begin
  Result := Format('%d.%d.%d.%d', [Maior, Menor, Revisao, Compilacao]);
end;

end.
