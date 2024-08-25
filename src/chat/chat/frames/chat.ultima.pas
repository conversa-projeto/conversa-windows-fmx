// Eduardo - 07/08/2024
unit chat.ultima;

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
  FMX.Ani,
  chat.base;

type
  TChatUltima = class(TChatBase)
    rtgUltima: TRectangle;
    pthUltima: TPath;
    procedure FrameClick(Sender: TObject);
  private const
    MARGEM = 5;
    ABAIXO = 30;
  private
    FScroll: TScrollBar;
    FAlvo: Single;
    function PosicaoExibicao: TPoint;
    function PosicaoOculta: TPoint;
  public
    procedure Change;
    constructor Create(AScroll: TScrollBar); reintroduce;
  end;

implementation

{$R *.fmx}

constructor TChatUltima.Create(AScroll: TScrollBar);
var
  Pos: TPoint;
begin
  inherited Create(AScroll);
  FScroll := AScroll;
  FAlvo := 0;
  Pos := PosicaoOculta;
  Self.Position.X := Pos.X;
  Self.Position.Y := Pos.Y;
  Self.Anchors := [TAnchorKind.akRight, TAnchorKind.akBottom];
end;

procedure TChatUltima.Change;
var
  Pos: TPoint;
begin
  if FScroll.Value < (FScroll.Max - FScroll.ViewportSize - 300) then
    Pos := PosicaoExibicao
  else
    Pos := PosicaoOculta;

  if Pos.Y = FAlvo then
    Exit;
  
  FAlvo := Pos.Y;
  
  Self.Position.X := Pos.X;
  TAnimator.AnimateFloat(Self, 'Position.Y', Pos.Y, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TChatUltima.FrameClick(Sender: TObject);
begin
  TAnimator.AnimateFloat(FScroll, 'Value', FScroll.Max - FScroll.ViewportSize, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
end;

function TChatUltima.PosicaoExibicao: TPoint;
begin
  Result := TPoint.Create(
    Round(FScroll.Position.X - Self.Width - MARGEM),
    Round(FScroll.Position.Y + FScroll.Size.Height - Self.Height - MARGEM)
  );
end;

function TChatUltima.PosicaoOculta: TPoint;
begin
  Result := TPoint.Create(
    Round(FScroll.Position.X - Self.Width - MARGEM),
    Round(FScroll.Position.Y + FScroll.Size.Height + ABAIXO)
  );
end;

end.
