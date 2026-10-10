unit ImageViewerFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ExtCtrls, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, System.Math;

type
  TImageViewerFrame = class(TFrame)
    lytClient: TLayout;
    ivImageViewer: TImageViewer;
    procedure ivImageViewerDblClick(Sender: TObject);
    procedure ivImageViewerGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure ivImageViewerMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure sbZoomInClick(Sender: TObject);
    procedure sbZoomOutClick(Sender: TObject);
    procedure ivImageViewerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure ivImageViewerClick(Sender: TObject);
  private
    FScalePicture: Single;
    FMousePos: TpointF;
    FFullSize: Boolean;
    FLastScale: Single;
    procedure SetScalePicture(const Value: Single);
    procedure SetMousePos(const Value: TpointF);
    procedure SetFullSize(const Value: Boolean);
    procedure SetLastScale(const Value: Single);
    procedure HelpContenBounds(Sender: TObject; var CBounds: TRectF);
  public
    FecharViewer: TProc;
    constructor Create(AOwner: TComponent); override;

    procedure LoadFromFile(APath: String);
    procedure LoadFromBitmap(ABitmap: TBitmap);

    property ScalePicture: Single read FScalePicture write SetScalePicture;
    property MousePos: TpointF read FMousePos write SetMousePos;
    property FullSize: Boolean read FFullSize write SetFullSize;
    property LastScale: Single read FLastScale write SetLastScale;
  end;

implementation

{$R *.fmx}

uses FMX.InertialMovement;

type
  THelpImageView = class(TScrollBox);

{ TImageViewerFrame }

constructor TImageViewerFrame.Create(AOwner: TComponent);
begin
  inherited;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Show;
  BringToFront;

  FFullSize := False;
  ivImageViewer.OnCalcContentBounds := HelpContenBounds;
  ivImageViewer.AniCalculations.BoundsAnimation := True;
  ivImageViewer.AniCalculations.Animation := True;
  ivImageViewer.AniCalculations.Averaging := True;
  ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
end;

procedure TImageViewerFrame.HelpContenBounds(Sender: TObject; var CBounds: TRectF);
var
  H: TComponent;
  BR: TRectF;
  I: TImage;
  B: TRectangle;
begin
  I := nil;
  B := nil;
  for H in ivImageViewer do
  begin
    begin
      if H is TImage then
        I := TImage(H);
      if H is TRectangle then
        B := TRectangle(H);
    end;
  end;

  I.Position.Point := PointF(0, 0);
  with THelpImageView(ivImageViewer) do
    begin
      I.BoundsRect := RectF(0, 0, ivImageViewer.Bitmap.Width * ScalePicture,
                                  ivImageViewer.Bitmap.Height * ScalePicture);
      if (Content <> nil) and (ContentLayout <> nil) then
        begin
          if I.Width < ContentLayout.Width then
            I.Position.X := (ContentLayout.Width - I.Width) * 0.5;
          if I.Height < ContentLayout.Height then
            I.Position.Y := (ContentLayout.Height - I.Height) * 0.5;
        end;
      CBounds := System.Types.UnionRect(RectF(0, 0, 0, 0), I.BoundsRect);
      if ContentLayout <> nil then
        BR := System.Types.UnionRect(CBounds, ContentLayout.ClipRect)
      else
        BR := I.BoundsRect;
      B.SetBounds(BR.Left, BR.Top, BR.Width, BR.Height);
      if CBounds.IsEmpty then
        CBounds := BR;
    end;
end;

procedure TImageViewerFrame.ivImageViewerClick(Sender: TObject);
begin
//  if (FullSize or (ScalePicture = 1)) then
//    FecharViewer;
end;

procedure TImageViewerFrame.ivImageViewerDblClick(Sender: TObject);
begin
  FullSize := not FullSize;
end;

procedure TImageViewerFrame.ivImageViewerGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  LObj: IControl;
  S : Single;
begin
  LObj := Self.ObjectAtPoint(lytClient.LocalToScreen(EventInfo.Location));
  if not Assigned(LObj) then
    Exit;
  if (LObj is TImageViewerFrame) and (EventInfo.GestureID = igiPan) then
    ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
  if (LObj is TImageViewerFrame) and (EventInfo.GestureID = igiZoom) then
    begin
      ivImageViewer.AniCalculations.TouchTracking := [];
      if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
        ivImageViewer.Tag := EventInfo.Distance;
      if (not(TInteractiveGestureFlag.gfBegin in EventInfo.Flags)) and
         (not(TInteractiveGestureFlag.gfEnd in EventInfo.Flags)) then
        begin
          FMousePos := PointF(0.0, 0.0);
          ivImageViewer.AniCalculations.TouchTracking := [];
          S := ((EventInfo.Distance - ivImageViewer.Tag) * ScalePicture) / PointF(Self.Width, Self.Height).Length;
          ivImageViewer.Tag := EventInfo.Distance;
          ScalePicture := ScalePicture + S;
        end;
      if TInteractiveGestureFlag.gfEnd in EventInfo.Flags then
        ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
    end;
  if (LObj is TImageViewerFrame) and (EventInfo.GestureID = igiDoubleTap) then
    FullSize := not FullSize;
end;

procedure TImageViewerFrame.ivImageViewerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  MousePos := PointF(X, Y);
end;

procedure TImageViewerFrame.ivImageViewerMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  ScalePicture := ScalePicture + ((WheelDelta * ScalePicture) / PointF(Self.Width, Self.Height).Length);
end;

procedure TImageViewerFrame.LoadFromBitmap(ABitmap: TBitmap);
var
  SH, SW: Single;
begin
  ivImageViewer.Bitmap.Assign(ABitmap);
  SH := ivImageViewer.Height/ ivImageViewer.Bitmap.Height;
  SW := ivImageViewer.Width/ ivImageViewer.Bitmap.Width;
  if SW > SH then
    FScalePicture := SH
  else
    FScalePicture := SW;
  ScalePicture := FScalePicture;
  FLastScale := FScalePicture;
end;

procedure TImageViewerFrame.LoadFromFile(APath: String);
var
  SH, SW: Single;
begin
  ivImageViewer.Bitmap.LoadFromFile(APath);

  SH := ivImageViewer.Height/ ivImageViewer.Bitmap.Height;
  SW := ivImageViewer.Width/ ivImageViewer.Bitmap.Width;
  if SW > SH then
    FScalePicture := SH
  else
    FScalePicture := SW;
  ScalePicture := FScalePicture;
  FLastScale := FScalePicture;
end;

procedure TImageViewerFrame.sbZoomInClick(Sender: TObject);
begin
  if FullSize then
    begin
      FullSize := not FullSize;
      ScalePicture := 1.20;
    end
  else
    ScalePicture := ScalePicture + 0.20;
end;

procedure TImageViewerFrame.sbZoomOutClick(Sender: TObject);
begin
  if FullSize then
    begin
      FullSize := not FullSize;
      ScalePicture := 0.80;
    end
  else
    ScalePicture := ScalePicture - 0.20;
end;

procedure TImageViewerFrame.SetFullSize(const Value: Boolean);
begin
  if Value then
    begin
      LastScale := ScalePicture;
      ScalePicture := 1;
    end
  else
    ScalePicture := LastScale;
  FFullSize := Value;
end;

procedure TImageViewerFrame.SetLastScale(const Value: Single);
begin
  FLastScale := Value;
end;

procedure TImageViewerFrame.SetMousePos(const Value: TpointF);
begin
  FMousePos := Value;
end;

procedure TImageViewerFrame.SetScalePicture(const Value: Single);
var
  R: IAlignRoot;
  S: Single;
  P, E, C: TPointF;
begin
  if Assigned(ivImageViewer) and not ivImageViewer.Bitmap.IsEmpty then
    begin
      if FScalePicture <> Value then
        begin
          S := FScalePicture;
          FScalePicture := Value;
          if FScalePicture < 0.1 then
            FScalePicture := 0.1;
          if FScalePicture > 10 then
            FScalePicture := 10;
          //lbZoomInfo.Text := 'Zoom: ' + FloatToStrF(FScalePicture * 100, ffFixed, 4, 0) + '%';
          //tbZoom.Value := FScalePicture;
          S := FScalePicture / S;
          ivImageViewer.AniCalculations.Animation := False;
          ivImageViewer.BeginUpdate;
          C := PointF(ivImageViewer.ClientWidth, ivImageViewer.ClientHeight);
          if FMousePos.IsZero then
            P := C * 0.5
          else
            P := FMousePos;
          E := ivImageViewer.ViewportPosition;
          E := E + P;
          ivImageViewer.InvalidateContentSize;
          R := ivImageViewer;
          R.Realign;
          ivImageViewer.ViewportPosition := (E * S) - P;
          ivImageViewer.EndUpdate;
          ivImageViewer.AniCalculations.Animation := True;
          ivImageViewer.Repaint;
        end;
    end;
end;

end.
