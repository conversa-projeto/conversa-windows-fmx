unit Conversa.Log;

interface

procedure AddLog(const Msg: String);

implementation

uses
  System.Types,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Threading;

var
  I: Integer;
  Sync: IReadWriteSync;
  FLock: TObject;

procedure InternalAddLog(const Msg: String; const DataHora: TDateTime; const ThreID: Cardinal);
begin
  Sync.BeginWrite;
  try
    Inc(I);
    try
      with TStringList.Create do
      try
        if TFile.Exists('.\log.txt') then
          LoadFromFile('.\log.txt');

        Insert(
          0,
          I.ToString.PadLeft(10, ' ') +' | '+
          FormatDateTime('yyyy-mm-dd HH:nn:ss.zzz', DataHora) +' | ' +
          ThreID.ToString.PadLeft(10, ' ') +' | ' +
          Msg
        );
        SaveToFile('.\log.txt');
        Sleep(1);
      finally
        Free;
      end;
    finally
    end;
  finally
    Sync.EndWrite;
  end;
end;

procedure AddLog(const Msg: String);
begin
  (procedure(const Msg: String; const DataHora: TDateTime; const ThreID: Cardinal)
   begin
     TTask.Run(
       procedure
       begin
         (procedure(const Msg: String; const DataHora: TDateTime; const ThreID: Cardinal)
          begin
            InternalAddLog(Msg, DataHora, ThreID)
          end
         )(Msg, DataHora, ThreId)
       end
     );
   end
  )(Msg, Now, TThread.Current.ThreadID)
end;

initialization
  I := 0;
  Sync := TMREWSync.Create;
  FLock := TObject.Create;

finalization
  FreeAndNil(FLock);

end.
