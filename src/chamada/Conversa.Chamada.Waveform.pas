unit Conversa.Chamada.Waveform;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Layouts,
  FMX.Graphics,
  AudioTypes;

type
  TWaveformView = class(TLayout)
  private
    FPath: TPath;
    FTimer: TTimer;
    FData: TWaveformData;
    FOwnsData: Boolean;
    FColor: TAlphaColor;
    procedure OnTimer(Sender: TObject);
    procedure Atualizar;
    procedure SetColor(const Value: TAlphaColor);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Vincular(AData: TWaveformData);
    procedure Iniciar;
    procedure Parar;
    property Color: TAlphaColor read FColor write SetColor;
    property Data: TWaveformData read FData;
  end;

implementation

{ TWaveformView }

constructor TWaveformView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := $FF00D26A;
  FOwnsData := True;
  FData := TWaveformData.Create;

  FPath := TPath.Create(Self);
  FPath.Parent := Self;
  FPath.Align := TAlignLayout.Client;
  FPath.Stroke.Color := FColor;
  FPath.Stroke.Thickness := 1.5;
  FPath.Fill.Kind := TBrushKind.None;
  FPath.HitTest := False;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 33;
  FTimer.Enabled := False;
  FTimer.OnTimer := OnTimer;
end;

destructor TWaveformView.Destroy;
begin
  FTimer.Enabled := False;
  if FOwnsData and Assigned(FData) then
    FData.Free;
  inherited;
end;

procedure TWaveformView.Vincular(AData: TWaveformData);
begin
  if FOwnsData and Assigned(FData) then
    FData.Free;
  FData := AData;
  FOwnsData := False;
end;

procedure TWaveformView.Iniciar;
begin
  FTimer.Enabled := True;
end;

procedure TWaveformView.Parar;
begin
  FTimer.Enabled := False;
end;

procedure TWaveformView.OnTimer(Sender: TObject);
begin
  if Assigned(FData) and (FData.MsSinceLastWrite > 40) then
    FData.AddSilence;
  Atualizar;
end;

procedure TWaveformView.Atualizar;
var
  Amps: TArray<Single>;
  I: Integer;
  X, Y, StepX, CenterY, MaxH: Single;
  PathData: TPathData;
begin
  if not Assigned(FData) then
    Exit;

  Amps := FData.GetAmplitudes;
  if Length(Amps) = 0 then
    Exit;

  PathData := TPathData.Create;
  try
    StepX := Width / (Length(Amps) - 1);
    CenterY := Height / 2;
    MaxH := (Height / 2) - 2;

    X := 0;
    Y := CenterY - (Amps[0] * MaxH);
    PathData.MoveTo(PointF(X, Y));

    for I := 1 to High(Amps) do
    begin
      X := I * StepX;
      Y := CenterY - (Amps[I] * MaxH);
      PathData.LineTo(PointF(X, Y));
    end;

    for I := High(Amps) downto 0 do
    begin
      X := I * StepX;
      Y := CenterY + (Amps[I] * MaxH);
      PathData.LineTo(PointF(X, Y));
    end;

    PathData.ClosePath;
    FPath.Data := PathData;
  finally
    PathData.Free;
  end;
end;

procedure TWaveformView.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  FPath.Stroke.Color := FColor;
end;

end.
