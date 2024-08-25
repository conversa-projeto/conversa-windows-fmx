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
    procedure SetLarguraMaximaConteudo(const Value: Integer);
  public
    OnScrollChange: TNotifyEvent;
    property LarguraMaximaConteudo: Integer read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
  end;

implementation

uses
  System.Math,
  FMX.Objects;

{$R *.fmx}

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
  scroll.Value := NewViewportPosition.Y;
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

end.
