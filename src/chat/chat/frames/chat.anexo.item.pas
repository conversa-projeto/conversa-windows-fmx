// Eduardo - 07/08/2024
unit chat.anexo.item;

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
  chat.base;

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
    constructor Create(AOwner: TVertScrollBox; sArquivo: String); reintroduce;
    property Arquivo: String read FArquivo;
    property OnRemoverClick: TNotifyEvent read GetOnRemoverClick write SetOnRemoverClick;
  end;

implementation

uses
  System.IOUtils;

{$R *.fmx}

constructor TChatAnexoItem.Create(AOwner: TVertScrollBox; sArquivo: String);
var
  bmp: TBitmap;
begin
  inherited Create(AOwner);
  AOwner.AddObject(Self);
  FArquivo := sArquivo;
  bmp := TBitmap.Create;
  try
    bmp.LoadFromFile(sArquivo);
    imgIcon.Bitmap.Assign(bmp);
  finally
    FreeAndNil(bmp);
  end;
  lbNome.Text := ExtractFileName(sArquivo);
  lbTamanho.Text := FormatFloat('#,##0.00', TFile.GetSize(sArquivo) / 1024 / 1024) +' MB';
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
