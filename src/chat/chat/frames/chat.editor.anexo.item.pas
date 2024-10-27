// Eduardo - 07/08/2024
unit chat.editor.anexo.item;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.Objects,
  FMX.Layouts,
  chat.base,
  Chat.Editor.Base,
  chat.tipos;

type
  TChatAnexoItem = class(TChatBase)
    imgIcon: TImage;
    Layout: TLayout;
    lbTamanho: TLabel;
    lbNome: TLabel;
    pthRemover: TPath;
    lytRemover: TLayout;
    rtgFundo: TRectangle;
    procedure lytRemoverClick(Sender: TObject);
  private
    FArquivo: String;
    FOnRemover: TNotifyEvent;
    function GetOnRemoverClick: TNotifyEvent;
    procedure SetOnRemoverClick(const Value: TNotifyEvent);
  public
    constructor Create(AOwner: TVertScrollBox; Anexo: TFileSelected); reintroduce;
    property Arquivo: String read FArquivo;
    property OnRemoverClick: TNotifyEvent read GetOnRemoverClick write SetOnRemoverClick;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  chat.so;

{$R *.fmx}

constructor TChatAnexoItem.Create(AOwner: TVertScrollBox; Anexo: TFileSelected);
var
  bmp: TBitmap;
begin
  inherited Create(AOwner);
  AOwner.AddObject(Self);
  FArquivo := Anexo.Path;
  if IndexStr(ExtractFileExt(FArquivo).Replace('.', EmptyStr).ToLower, ['bmp', 'jpg', 'png', 'gif']) >= 0 then
  begin
    if Assigned(Anexo.Data) then
      imgIcon.Bitmap.LoadFromStream(Anexo.Data)
    else
      imgIcon.Bitmap.LoadFromFile(FArquivo);
  end
  else
  begin
    bmp := GetFileIconAsBitmap(FArquivo);
    try
      imgIcon.Bitmap.Assign(bmp);
    finally
      FreeAndNil(bmp);
    end;
  end;
  lbNome.Text := ExtractFileName(FArquivo);
  if Assigned(Anexo.Data) then
    lbTamanho.Text := FormatFloat('#,##0.00', Anexo.Data.Size / 1024 / 1024) +' MB'
  else
    lbTamanho.Text := FormatFloat('#,##0.00', TFile.GetSize(FArquivo) / 1024 / 1024) +' MB';
end;

function TChatAnexoItem.GetOnRemoverClick: TNotifyEvent;
begin
  Result := FOnRemover;
end;

procedure TChatAnexoItem.SetOnRemoverClick(const Value: TNotifyEvent);
begin
  FOnRemover := Value;
end;

procedure TChatAnexoItem.lytRemoverClick(Sender: TObject);
begin
  if Assigned(FOnRemover) then
    FOnRemover(Self);
end;

end.
