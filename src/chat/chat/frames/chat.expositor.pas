// Eduardo - 03/08/2024
unit chat.expositor;

interface

uses
  System.Types,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Layouts,
  chat.base,
  chat.ultima;

type
  TChatExpositor = class(TChatBase)
    sbxCentro: TVertScrollBox;
    scroll: TSmallScrollBar;
    procedure FrameResized(Sender: TObject);
    procedure FrameMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure sbxCentroViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
    procedure scrollChange(Sender: TObject);
  private
    FLarguraMaximaConteudo: Integer;
    FProximoBottom: Single;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    function GetBottom: Single;
    procedure SetBottom(const Value: Single);
  public
    OnScrollChange: TNotifyEvent;
    property LarguraMaximaConteudo: Integer read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property Bottom: Single read GetBottom write SetBottom;
    procedure AfterConstruction; override;
  end;

implementation

uses
  System.Math,
  FMX.Objects;

{$R *.fmx}

procedure TChatExpositor.AfterConstruction;
begin
  inherited;
  FProximoBottom := -1;
end;

procedure TChatExpositor.FrameResized(Sender: TObject);
begin
  sbxCentro.Width := Min(LarguraMaximaConteudo, Self.Width);
end;

procedure TChatExpositor.FrameMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  scroll.Value := scroll.Value - WheelDelta;
end;

procedure TChatExpositor.sbxCentroViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  scroll.Max := sbxCentro.ContentBounds.Height;
  scroll.ViewportSize := Self.Height;

  if FProximoBottom = -1 then
    scroll.Value := NewViewportPosition.Y
  else
  begin
    scroll.Value := scroll.Max - FProximoBottom;
    FProximoBottom := -1;
  end;
end;

procedure TChatExpositor.scrollChange(Sender: TObject);
begin
  sbxCentro.ViewportPosition := TPointF.Create(0, scroll.Value);
  if Assigned(OnScrollChange) then
    OnScrollChange(Sender);
end;

procedure TChatExpositor.SetLarguraMaximaConteudo(const Value: Integer);
begin
  FLarguraMaximaConteudo := Value;
  FrameResized(Self);
end;

function TChatExpositor.GetBottom: Single;
begin
  Result := Scroll.Max - Scroll.Value;
end;

procedure TChatExpositor.SetBottom(const Value: Single);
begin
  FProximoBottom := Value;
end;

end.
