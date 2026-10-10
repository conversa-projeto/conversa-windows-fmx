unit Conversa.Log;

interface

procedure PararLog;
procedure AddLog(const Msg: String);

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Conversa.Configuracoes;

var
  I: Integer = -1;
  LogFile: TextFile;

procedure PararLog;
begin
  if TTextRec(LogFile).Handle <> 0 then
    CloseFile(LogFile);
end;

procedure AddLog(const Msg: String);
begin
  if I = -1 then
  begin
    I := 0;
    AssignFile(LogFile, PastaDados +'log.txt');
    Rewrite(LogFile);
  end;

  Inc(I);
  Writeln(LogFile, I.ToString.PadLeft(10, ' ') +' | '+ FormatDateTime('yyyy-mm-dd HH:nn:ss.zzz', Now) +' | ' + TThread.Current.ThreadID.ToString.PadLeft(10, ' ') +' | '+ Msg);
end;

end.
