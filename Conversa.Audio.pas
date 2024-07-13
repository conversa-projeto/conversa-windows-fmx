// Eduardo - 13/07/2024
unit Conversa.Audio;

interface

procedure PlayResource(ResourceID: String);

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  MMSystem;

procedure PlayResource(ResourceID: String);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      rs: TResourceStream;
    begin
      rs := TResourceStream.Create(HInstance, ResourceID, RT_RCDATA);
      try
        PlaySound(rs.Memory, 0, SND_SYNC or SND_MEMORY);
      finally
        FreeAndNil(rs);
      end;
    end
  ).Start;
end;

end.
