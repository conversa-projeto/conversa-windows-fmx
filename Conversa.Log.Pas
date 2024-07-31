unit Conversa.Log;

interface

procedure AddLog(const Msg: String);

implementation

uses
  System.SysUtils,
  System.Classes;

var
  I: Integer;
  LogFile: TextFile;

procedure AddLog(const Msg: String);
begin
  Inc(I);
  Writeln(
    LogFile,
    I.ToString.PadLeft(10, ' ') +' | '+ FormatDateTime('yyyy-mm-dd HH:nn:ss.zzz', Now) +' | ' + TThread.Current.ThreadID.ToString.PadLeft(10, ' ') +' | '+ Msg
  );
end;

initialization
  I := 0;
  AssignFile(LogFile, '.\log.txt');
  Rewrite(LogFile);

finalization
  CloseFile(LogFile);

end.
