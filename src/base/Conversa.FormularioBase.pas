unit Conversa.FormularioBase;

interface

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  Winapi.Messages,
  Winapi.Windows,
  FMX.Ani,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.Platform.Win,
  FMX.Types,
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
    procedure lytMaximizeButtonClick(Sender: TObject);
    procedure lytMinimizeButtonClick(Sender: TObject);
    procedure lytCloseButtonClick(Sender: TObject);
    procedure lytCloseButtonMouseEnter(Sender: TObject);
    procedure lytCloseButtonMouseLeave(Sender: TObject);
    procedure lytMaximizeButtonMouseEnter(Sender: TObject);
    procedure lytMaximizeButtonMouseLeave(Sender: TObject);
    procedure lytMinimizeButtonMouseEnter(Sender: TObject);
    procedure lytMinimizeButtonMouseLeave(Sender: TObject);
    procedure rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    FOldWndProc: Pointer;
    function GetPSSClassName: String;
    function SystemButton(pt: TPoint): Integer;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure DoConversaRestore; virtual;
    procedure DoConversaClose; virtual;
    procedure DoConversaMaximize;
    procedure DoConversaMinimize;
    procedure ShowOnTaskBar;
    procedure HideOfTaskBar;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  FMX.Helpers.Win,
  FMX.Forms.Border.Win,
  Conversa.Notificacao.Visualizador,
  Conversa.Windows.Utils;

{$R *.fmx}

procedure MinimizeApp;
var
  AnimationEnable: Boolean;

  function GetAnimation: Boolean;
  var
    Info: TAnimationInfo;
  begin
    Info.cbSize := SizeOf(TAnimationInfo);
    if SystemParametersInfo(SPI_GETANIMATION, Info.cbSize, @Info, 0) then
      Result := Info.iMinAnimate <> 0
    else
      Result := False;
  end;

  procedure SetAnimation(Value: Boolean);
  var
    Info: TAnimationInfo;
  begin
    Info.cbSize := SizeOf(TAnimationInfo);
    Info.iMinAnimate := Integer(BOOL(Value));
    SystemParametersInfo(SPI_SETANIMATION, Info.cbSize, @Info, 0);
  end;

  procedure MinimiseAllForms;
  var
    I: Integer;
    WindowHandle: HWND;
  begin
    for I := 0 to Screen.FormCount - 1 do
    begin
      if Screen.Forms[I].InheritsFrom(TNotificacaoVisualizador) then
      begin
        Sleep(00);
        Continue;
      end;
      WindowHandle := FormToHWND(Screen.Forms[I]);
      if IsWindowVisible(WindowHandle) then
        DefWindowProc(WindowHandle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    end;
  end;
begin
  AnimationEnable := GetAnimation;
  try
    SetAnimation(False);
    if Application.MainForm <> nil then
      MinimiseAllForms;
  finally
    SetAnimation(AnimationEnable);
  end;
end;

function WndProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Frm: TCommonCustomForm;
  Form: TFormularioBase;
  Message: TMessage;
  Wnd: Winapi.Windows.HWND;
  WindowPoint: TPoint;
  FormPoint: TPointF;
  ClientPoint: TPointF;
  Placement: TWindowPlacement;
  iSystemButton: Integer;
  function FormPxToDp(const AForm: TCommonCustomForm; const APoint: TPoint): TPointF;
  var
    LScale: Single;
  begin
    LScale := AForm.Handle.Scale;
    Result := (TPointF(APoint) / LScale).Round;
  end;
begin
  Frm := FMX.Platform.Win.FindWindow(hwnd);
  if not Assigned(Frm) or not Frm.InheritsFrom(TFormularioBase) then
    Exit(0);

  Form := TFormularioBase(Frm);
  Wnd := FormToHWND(Form);
  Message.Msg := uMsg;
  Message.WParam := wParam;
  Message.LParam := lParam;
  Message.Result := 0;
  Result := 0;
  case uMsg of
    WM_RESTAURAR_CONVERSA:
    begin
      Form.DoConversaRestore;
    end;
    WM_NCHITTEST,
    WM_NCACTIVATE,
    WM_NCADDUPDATERECT,
    WM_NCMOUSEMOVE,
    WM_NCLBUTTONDOWN,
    WM_NCLBUTTONUP,
    WM_NCCALCSIZE,
    WM_NCPAINT,
    WM_NCMOUSELEAVE:
    begin
      if Assigned(Form) and Form.InheritsFrom(TFormularioBase) then
      begin
        if uMsg in [WM_NCHITTEST, WM_NCLBUTTONDOWN, WM_NCLBUTTONUP] then
        begin
          WindowPoint := TWMNCHitTest(Message).Pos; // Form point in px
          FormPoint := FormPxToDp(Form, WindowPoint); // dp
          ClientPoint := Form.ScreenToClient(FormPoint);
          // Se não está maximizado, está identificando o local da interface, e está nas dimensões das bordas
          if not IsZoomed(Wnd) and (uMsg = WM_NCHITTEST) and (Abs(ClientPoint.Y) <= GetSystemMetrics(SM_CYFRAME)) then
          begin
            TWMNCHitTest(Message).Result := HTTOP;
            Form.lytMinimizeButtonMouseLeave(Form.lytMinimizeButton);
            Form.lytMaximizeButtonMouseLeave(Form.lytMaximizeButton);
            Form.lytCloseButtonMouseLeave(Form.lytCloseButton);
            Exit(HTTOP);
          end
          else
          begin
            iSystemButton := Form.SystemButton(ClientPoint.Round);
            if iSystemButton <> -1 then
            begin
              if Message.Msg = WM_NCLBUTTONUP then
              begin
                Exit(0);
              end;

              if Message.Msg = WM_NCLBUTTONDOWN then
              begin
                case iSystemButton of
                  0:
                  begin
                    if Form = Application.MainForm then
                      MinimizeApp
                    else
                      Form.DoConversaMinimize;
                  end;
                  1: Form.DoConversaMaximize;
                  2: Form.DoConversaClose;
                end;
                Form.lytMinimizeButtonMouseLeave(Form.lytMinimizeButton);
                Form.lytMaximizeButtonMouseLeave(Form.lytMaximizeButton);
                Form.lytCloseButtonMouseLeave(Form.lytCloseButton);
                Exit(0);
              end
              else
              begin
                case iSystemButton of
                  0:
                  begin
                    Form.lytMinimizeButtonMouseEnter(Form.lytMinimizeButton);
                    Form.lytMaximizeButtonMouseLeave(Form.lytMaximizeButton);
                    Form.lytCloseButtonMouseLeave(Form.lytCloseButton);
                    Exit(HTMINBUTTON);
                  end;
                  1:
                  begin
                    Form.lytMinimizeButtonMouseLeave(Form.lytMinimizeButton);
                    Form.lytMaximizeButtonMouseEnter(Form.lytMaximizeButton);
                    Form.lytCloseButtonMouseLeave(Form.lytCloseButton);
                    Exit(HTMAXBUTTON);
                  end;
                  2:
                  begin
                    Form.lytMinimizeButtonMouseLeave(Form.lytMinimizeButton);
                    Form.lytMaximizeButtonMouseLeave(Form.lytMaximizeButton);
                    Form.lytCloseButtonMouseEnter(Form.lytCloseButton);
                    Exit(HTCLOSE);
                  end;
                end;
              end;
            end;
            Form.lytMinimizeButtonMouseLeave(Form.lytMinimizeButton);
            Form.lytMaximizeButtonMouseLeave(Form.lytMaximizeButton);
            Form.lytCloseButtonMouseLeave(Form.lytCloseButton);
            Result := WMNCMessages(Form, uMsg, wParam, lParam);
          end;
        end
        else
        if uMsg = WM_NCCALCSIZE then
        begin
          with TWMNCCalcSize(Message).CalcSize_Params.rgrc[0] do
          begin
            Dec(Top, GetSystemMetrics(SM_CYCAPTION));
            Dec(Top, GetSystemMetrics(SM_CYFRAME));
            Dec(Top, GetSystemMetrics(SM_CXPADDEDBORDER));
            if IsZoomed(Wnd) then
              Inc(Top, 8)
            else
              Inc(Top, 1);
          end;
          Result := WMNCMessages(Form, uMsg, wParam, lParam);
        end
        else
          Result := WMNCMessages(Form, uMsg, wParam, lParam);
      end
      else
        Result := WMNCMessages(Form, uMsg, wParam, lParam);
    end;
    WM_WINDOWPOSCHANGED:
    begin
      Placement.Length := SizeOf(TWindowPlacement);
      GetWindowPlacement(hwnd, Placement);
      if (Application.MainForm <> nil) and (Form = Application.MainForm) and (Placement.showCmd = SW_SHOWMINIMIZED) then
      begin
        MinimizeApp;
        Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
      end
      else
       Result := CallWindowProc(Form.FOldWndProc, hwnd, uMsg, wParam, lParam);
    end;
  else
    Result := CallWindowProc(Form.FOldWndProc, hwnd, uMsg, wParam, lParam);
  end;
end;

function TFormularioBase.SystemButton(pt: TPoint): Integer;
var
  Buttons: TArray<TLayout>;
  I: Integer;
begin
  Buttons := [lytMinimizeButton, lytMaximizeButton, lytCloseButton];
  Result := -1;
  for I := 0 to 2 do
    if PtInRect(Buttons[I].AbsoluteRect.Round, pt) then
      Exit(I);
end;

constructor TFormularioBase.Create(AOwner: TComponent);
begin
  inherited;
  TPascalStyleScript.Instance.RegisterObject(Self, GetPSSClassName);
end;

procedure TFormularioBase.CreateHandle;
begin
  inherited;
  FOldWndProc := Pointer(SetWindowLong(WindowHandleToPlatform(Handle).Wnd, GWL_WNDPROC, LongInt(@WndProc)));
end;

procedure TFormularioBase.DestroyHandle;
begin
  SetWindowLong(WindowHandleToPlatform(Handle).Wnd, GWL_WNDPROC, LongInt(FOldWndProc));
  inherited;
end;

function TFormularioBase.GetPSSClassName: String;
begin
  Result := ClassName.Substring(1);
end;

procedure TFormularioBase.lytCloseButtonClick(Sender: TObject);
begin
  DoConversaClose;
end;

procedure TFormularioBase.lytCloseButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(lnClose1, 'Stroke.Color', TAlphaColors.White, 0.001);
  TAnimator.AnimateColor(lnClose2, 'Stroke.Color', TAlphaColors.White, 0.001);
  TAnimator.AnimateColor(rctClose, 'Fill.Color', TAlphaColors.Red, 0.001);
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

procedure TFormularioBase.rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    if ssDouble in Shift then
      SendMessage(FMX.Platform.Win.WindowHandleToPlatform(Handle).Wnd, WM_NCLBUTTONDBLCLK, HTCAPTION, 0)
    else
      SendMessage(FMX.Platform.Win.WindowHandleToPlatform(Handle).Wnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  end;
end;

procedure TFormularioBase.DoConversaMinimize;
begin
  Self.WindowState := TWindowState.wsMinimized;
end;

procedure TFormularioBase.DoConversaRestore;
begin
  //
end;

procedure TFormularioBase.DoConversaMaximize;
begin
  if Self.WindowState = TWindowState.wsNormal then
    Self.WindowState := TWindowState.wsMaximized
  else
    Self.WindowState := TWindowState.wsNormal;
end;

procedure TFormularioBase.DoConversaClose;
begin
  Self.Close;
end;

procedure TFormularioBase.ShowOnTaskBar;
var
  H: HWND;
begin
  H := FormToHWND(Self);
  SetWindowLongPtr(H, GWL_EXSTYLE, (GetWindowLong(H, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW) or WS_EX_APPWINDOW);
  ShowWindow(H, SW_SHOW);
end;

procedure TFormularioBase.HideOfTaskBar;
var
  H: HWND;
begin
  H := FormToHWND(Self);
  SetWindowLongPtr(H, GWL_EXSTYLE, (GetWindowLong(H, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW));
  ShowWindow(H, SW_SHOW);
end;

end.
