// Eduardo - 21/08/2024
unit chat.separador.data;

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
  FMX.Objects,
  chat.base;

type
  TChatSeparadorData = class(TChatBase)
    rtgFundo: TRectangle;
    txtData: TText;
  private
    FData: TDate;
    function GetData: TDateTime; reintroduce;
    procedure SetData(const Value: TDateTime); reintroduce;
  public
    property Data: TDateTime read GetData write SetData;
  end;

implementation

{$R *.fmx}

uses
  System.StrUtils,
  System.DateUtils;

{ TFrameSeparadorData }

function TChatSeparadorData.GetData: TDateTime;
begin
  Result := FData;
end;

procedure TChatSeparadorData.SetData(const Value: TDateTime);
begin
  FData := Value;
  txtData.Text := FormatDateTime('dd/mm'+ IfThen(MonthsBetween(Now, Value) > 6, '/yyyy'), Value);
  rtgFundo.Width := txtData.Canvas.TextWidth(txtData.Text) + txtData.Margins.Left + txtData.Margins.Right;
end;

end.
