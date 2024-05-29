unit Conversa.FormularioBase;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Objects,
  FMX.Layouts,
  FMX.Ani,
  System.Math,
  System.StrUtils,
  Winapi.Messages,
  Winapi.Windows,
  PascalStyleScript;

type
  TFormularioBase = class(TForm)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytClientForm: TLayout;
    lytBotoesSistema: TLayout;
    lytCloseButton: TLayout;
    rctClose: TRectangle;
    lytClose: TLayout;
    lnClose1: TLine;
    lnClose2: TLine;
    lytMaximizeButton: TLayout;
    rctMaximize: TRectangle;
    lytMaximize: TLayout;
    rctMazimize2: TRectangle;
    rctMaximize1: TRectangle;
    lytMinimizeButton: TLayout;
    rctMinimize: TRectangle;
    lytMinimize: TLayout;
    lnMinimize: TLine;
    lytLogo: TLayout;
    imgLogo: TImage;
    lytTitleBarClient: TLayout;
    rctTitleBar: TRectangle;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lytMaximizeButtonClick(Sender: TObject);
    procedure lytMinimizeButtonClick(Sender: TObject);
    procedure lytCloseButtonClick(Sender: TObject);
    procedure rctTitleBarDblClick(Sender: TObject);
    procedure lytCloseButtonMouseEnter(Sender: TObject);
    procedure lytCloseButtonMouseLeave(Sender: TObject);
    procedure lytMaximizeButtonMouseEnter(Sender: TObject);
    procedure lytMaximizeButtonMouseLeave(Sender: TObject);
    procedure lytMinimizeButtonMouseEnter(Sender: TObject);
    procedure lytMinimizeButtonMouseLeave(Sender: TObject);
    procedure rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure rctTitleBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure rctTitleBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
  private
    { Private declarations }
    FMaximized: Boolean;
    FOldBounds: TRectF;
    FDraging: Boolean;
    FTitleDragingClick: Boolean;
    FMouseDown: TPointF;
    FMouseDownBounds: TRectF;
    FMouseDownOriginal: TPointF;
  protected
    function WndProc_NCHITTEST(var Message: TMessage): LRESULT; virtual;
    function GetPSSClassName: String; virtual;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure DoConversaClose;
    procedure DoConversaMaximize;
    procedure DoConversaMinimize;
  end;

implementation

{$R *.fmx}

constructor TFormularioBase.Create(AOwner: TComponent);
begin
  inherited;
  TPascalStyleScript.Instance.RegisterObject(Self, GetPSSClassName);
end;

function TFormularioBase.GetPSSClassName: String;
begin
  Result := ClassName.Substring(1);
end;

procedure TFormularioBase.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkEscape:
    begin
      if FDraging then
      begin
        //FMaximized := not FMaximized;
        FTitleDragingClick := False;
        FDraging := False;
//        Self.ReleaseCapture;

        if FMaximized then
          DoConversaMaximize;
      end;
    end;
  end;
end;

procedure TFormularioBase.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  rfNot: TRect;
begin
  rfNot := GetBounds;
  rfNot.SetLocation(0, 0);
  rfNot.Inflate(-5, -5);
  if not PtInRect(rfNot, PointF(X, Y).Round) then
  begin
    Sleep(0);
  end;
end;

procedure TFormularioBase.FormResize(Sender: TObject);
begin
  if not FMaximized then
    FOldBounds := Self.GetBoundsF;
//  UpdateResizeState;
end;

procedure TFormularioBase.FormShow(Sender: TObject);
begin
  FMaximized := False;
  FOldBounds := Self.GetBoundsF;
end;

procedure TFormularioBase.lytCloseButtonClick(Sender: TObject);
begin
  DoConversaClose;
end;

procedure TFormularioBase.lytCloseButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(lnClose1, 'Stroke.Color', TAlphaColors.Red, 0.001);
  TAnimator.AnimateColor(lnClose2, 'Stroke.Color', TAlphaColors.Red, 0.001);
  TAnimator.AnimateColor(rctClose, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.lytCloseButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(lnClose1, 'Stroke.Color', TAlphaColors.Black, 0.001);
  TAnimator.AnimateColor(lnClose2, 'Stroke.Color', TAlphaColors.Black, 0.001);
  TAnimator.AnimateColor(rctClose, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.lytMaximizeButtonClick(Sender: TObject);
begin
  DoConversaMaximize;
end;

procedure TFormularioBase.lytMaximizeButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMaximize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.lytMaximizeButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMaximize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.lytMinimizeButtonClick(Sender: TObject);
begin
  DoConversaMinimize;
end;

procedure TFormularioBase.lytMinimizeButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.lytMinimizeButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TFormularioBase.rctTitleBarDblClick(Sender: TObject);
begin
  DoConversaMaximize;
end;

procedure TFormularioBase.rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FMouseDownOriginal := PointF(X, Y);
  FMouseDown := rctTitleBar.LocalToScreen(FMouseDownOriginal);
  FMouseDownBounds := Self.GetBoundsF;

  if (Button = TMouseButton.mbLeft) and not (ssDouble in Shift) then
    FTitleDragingClick := True;
end;

procedure TFormularioBase.rctTitleBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  ptAtual: TPointF;
  P: TPointF;
begin
  if FTitleDragingClick or FDraging then
  begin
    FTitleDragingClick := False;
    if not FDraging then
    begin
      FDraging := True;
      ptAtual := rctTitleBar.LocalToScreen(PointF(X, Y));
      P := PointF(
        ptAtual.X + (ptAtual.X - FMouseDown.X) - Round(GetBoundsF.Width * (FMouseDownOriginal.X / FMouseDownBounds.Width)),
        ptAtual.Y + (ptAtual.Y - FMouseDown.Y) - Round(GetBoundsF.Height * (FMouseDownOriginal.Y / FMouseDownBounds.Height))
      );
      SetBoundsF(P.X, P.Y, FOldBounds.Width, FOldBounds.Height);
      //FMaximized := False;
      //UpdateResizeState;
      P := PointF(
        Round(GetBoundsF.Width * (FMouseDownOriginal.X / FMouseDownBounds.Width)),
        Round(GetBoundsF.Height * (FMouseDownOriginal.Y / FMouseDownBounds.Height))
      );
      Self.MouseDown(TMouseButton.mbLeft, [], P.X, P.Y);
      Self.StartWindowDrag;
    end;
  end;
end;

procedure TFormularioBase.rctTitleBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FTitleDragingClick := False;
  if FDraging then
  begin
    FOldBounds := Self.GetBoundsF;
    FDraging := False;
    FMaximized := Self.WindowState = TWindowState.wsMaximized;
  end;
end;

//procedure TFormularioBase.UpdateResizeState;
//begin
//
//end;

procedure TFormularioBase.DoConversaMinimize;
begin
  Self.WindowState := TWindowState.wsMinimized;
end;

procedure TFormularioBase.DoConversaMaximize;
begin
  if Self.WindowState = TWindowState.wsNormal then
  begin
    FOldBounds := Self.GetBoundsF;
    FMaximized := True;
    Self.WindowState := TWindowState.wsMaximized;
  end
  else
  begin
    Self.WindowState := TWindowState.wsNormal;
    FMaximized := False;
  end;
end;

procedure TFormularioBase.DoConversaClose;
begin
  Self.Close;
end;

function TFormularioBase.WndProc_NCHITTEST(var Message: TMessage): LRESULT;
var
  WindowPoint: TPoint;
  FormPoint: TPointF;
  ClientPoint: TPointF;

  function FormPxToDp(const AForm: TCommonCustomForm; const APoint: TPointF): TPointF;
  var
    LScale: Single;
  begin
    LScale := AForm.Handle.Scale;
    Result := (TPointF(APoint) / LScale).Round;
  end;

begin
  Result := 0;
  WindowPoint := TWMNCHitTest(Message).Pos; // Form point in px
  FormPoint := FormPxToDp(Self, WindowPoint); // dp
  ClientPoint := Self.ScreenToClient(FormPoint);

  if (Message.Msg = WM_NCHITTEST) and ((FormPoint.Y - Self.Top) <= 5) then
    Exit(HTTOP);

//  if PtInRect(lytCloseButton.AbsoluteRect.Round, ClientPoint.Round) then
//    Exit(HTCLOSE);

//  if lytTitleBar.IsMouseOver then
//    Exit(HTCAPTION);

  if PtInRect(lytMaximizeButton.AbsoluteRect.Round, ClientPoint.Round) then
  begin
    case Message.Msg of
      WM_NCLBUTTONDOWN: DoConversaMaximize;
      WM_NCLBUTTONUP: Exit(0);
    else
      Exit(HTMAXBUTTON);
    end;
  end;
end;

end.
