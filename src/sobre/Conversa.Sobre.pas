unit Conversa.Sobre;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.StdCtrls,
  Conversa.FrameBase;

type
  TConversaSobre = class(TFrameBase)
    rctFundo: TRectangle;
    txtNomeApp: TText;
    txtVersao: TText;
    txtDataBuild: TText;
  public
    class procedure Exibir;
  end;

implementation

{$R *.fmx}

uses
  Winapi.Windows,
  System.IOUtils,
  Conversa.Tela.Inicial.view;

function GetAppVersion: String;
var
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedInfo: PVSFixedFileInfo;
  InfoSize: UINT;
begin
  Result := '0.0.0.0';
  Size := GetFileVersionInfoSize(PChar(ParamStr(0)), Handle);
  if Size = 0 then Exit;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(ParamStr(0)), Handle, Size, Buffer) then Exit;
  if not VerQueryValue(Buffer, '\', Pointer(FixedInfo), InfoSize) then Exit;
  Result := Format('%d.%d.%d.%d', [
    HiWord(FixedInfo.dwFileVersionMS),
    LoWord(FixedInfo.dwFileVersionMS),
    HiWord(FixedInfo.dwFileVersionLS),
    LoWord(FixedInfo.dwFileVersionLS)
  ]);
end;

function GetBuildDate: String;
begin
  Result := FormatDateTime('dd/mm/yyyy HH:nn:ss', TFile.GetLastWriteTime(ParamStr(0)));
end;

class procedure TConversaSobre.Exibir;
var
  Frame: TConversaSobre;
begin
  Frame := TConversaSobre.Create(TelaInicial.lytClientForm);
  Frame.txtVersao.Text := 'Versão: ' + GetAppVersion;
  Frame.txtDataBuild.Text := 'Build: ' + GetBuildDate;
  TelaInicial.ModalView.Exibir(Frame);
end;

end.
