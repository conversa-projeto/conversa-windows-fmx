unit Conversa.Visualizador.Midia.Windows;

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
  Winapi.Dwmapi,
  FMX.Ani,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.Platform.Win,
  FMX.Types,
  PascalStyleScript,
  Conversa.Visualizador.Midia;

type
  TVisualizadorMidiaWindows = class(TForm)
  private
    FView: TVisualizadorMidia;
    FOldWndProc: Pointer;
    function GetPSSClassName: String;
    function SystemButton(pt: TPoint): Integer;
    procedure DoOnCloseView(Sender: TObject);

    procedure lytMaximizeButtonClick(Sender: TObject);
    procedure lytMinimizeButtonClick(Sender: TObject);
    procedure lytCloseButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure DoConversaRestore; virtual;
    procedure DoConversaClose; virtual;
    procedure DoConversaMaximize;
    procedure DoConversaMinimize;
    procedure rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  public
    constructor Create(AOwner: TComponent); override;
    class procedure Exibir(View: TVisualizadorMidia);
  end;

implementation

uses
  FMX.Helpers.Win,
  FMX.Forms.Border.Win,
  Conversa.Notificacao.Visualizador,
  Conversa.Windows.Utils;


function WndProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Frm: TCommonCustomForm;
  Form: TVisualizadorMidiaWindows;
  Message: TMessage;
  Wnd: Winapi.Windows.HWND;
  WindowPoint: TPoint;
  FormPoint: TPointF;
  ClientPoint: TPointF;
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
  if not Assigned(Frm) or not Frm.InheritsFrom(TVisualizadorMidiaWindows) then
    Exit(0);

  Form := TVisualizadorMidiaWindows(Frm);
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
      if Assigned(Form) and Form.InheritsFrom(TVisualizadorMidiaWindows) then
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
            Form.FView.lytMinimizeButtonMouseLeave(Form.FView.lytMinimizeButton);
            Form.FView.lytMaximizeButtonMouseLeave(Form.FView.lytMaximizeButton);
            Form.FView.lytCloseButtonMouseLeave(Form.FView.lytCloseButton);
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
                  0: Form.DoConversaMinimize;
                  1: Form.DoConversaMaximize;
                  2: Form.DoConversaClose;
                end;
                Form.FView.lytMinimizeButtonMouseLeave(Form.FView.lytMinimizeButton);
                Form.FView.lytMaximizeButtonMouseLeave(Form.FView.lytMaximizeButton);
                Form.FView.lytCloseButtonMouseLeave(Form.FView.lytCloseButton);
                Exit(0);
              end
              else
              begin
                case iSystemButton of
                  0:
                  begin
                    Form.FView.lytMinimizeButtonMouseEnter(Form.FView.lytMinimizeButton);
                    Form.FView.lytMaximizeButtonMouseLeave(Form.FView.lytMaximizeButton);
                    Form.FView.lytCloseButtonMouseLeave(Form.FView.lytCloseButton);
                    Exit(HTMINBUTTON);
                  end;
                  1:
                  begin
                    Form.FView.lytMinimizeButtonMouseLeave(Form.FView.lytMinimizeButton);
                    Form.FView.lytMaximizeButtonMouseEnter(Form.FView.lytMaximizeButton);
                    Form.FView.lytCloseButtonMouseLeave(Form.FView.lytCloseButton);
                    Exit(HTMAXBUTTON);
                  end;
                  2:
                  begin
                    Form.FView.lytMinimizeButtonMouseLeave(Form.FView.lytMinimizeButton);
                    Form.FView.lytMaximizeButtonMouseLeave(Form.FView.lytMaximizeButton);
                    Form.FView.lytCloseButtonMouseEnter(Form.FView.lytCloseButton);
                    Exit(HTCLOSE);
                  end;
                end;
              end;
            end;
            Form.FView.lytMinimizeButtonMouseLeave(Form.FView.lytMinimizeButton);
            Form.FView.lytMaximizeButtonMouseLeave(Form.FView.lytMaximizeButton);
            Form.FView.lytCloseButtonMouseLeave(Form.FView.lytCloseButton);
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
//    WM_WINDOWPOSCHANGED:
//    begin
//      Placement.Length := SizeOf(TWindowPlacement);
//      GetWindowPlacement(hwnd, Placement);
//      if (Application.MainForm <> nil) and (Form = Application.MainForm) and (Placement.showCmd = SW_SHOWMINIMIZED) then
//      begin
//        MinimizeApp;
//        Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
//      end
//      else
//       Result := CallWindowProc(Form.FOldWndProc, hwnd, uMsg, wParam, lParam);
//    end;
  else
    Result := CallWindowProc(Form.FOldWndProc, hwnd, uMsg, wParam, lParam);
  end;
end;

class procedure TVisualizadorMidiaWindows.Exibir(View: TVisualizadorMidia);
var
  Form: TVisualizadorMidiaWindows;
begin
  Form := TVisualizadorMidiaWindows.CreateNew(nil);
  Form.Transparency := True;
  Form.FView := View;


//  View.rctFundo.Fill.Color := TAlphaColors.Null;

  // Configura botões
  View.lytMinimizeButton.OnClick := Form.lytMinimizeButtonClick;
  View.lytMaximizeButton.OnClick := Form.lytMaximizeButtonClick;
  View.lytCloseButton.OnClick := Form.lytCloseButtonClick;
  View.lytTitleBar.Visible := False;

  View.Parent := Form;
  View.OnClose := Form.DoOnCloseView;

  Form.WindowState := TWindowState.wsMaximized;
  Form.BorderStyle := TFmxFormBorderStyle.None;
  Form.Show;
end;

function TVisualizadorMidiaWindows.SystemButton(pt: TPoint): Integer;
var
  Buttons: TArray<TLayout>;
  I: Integer;
begin
  Buttons := [FView.lytMinimizeButton, FView.lytMaximizeButton, FView.lytCloseButton];
  Result := -1;
  for I := 0 to 2 do
    if PtInRect(Buttons[I].AbsoluteRect.Round, pt) then
      Exit(I);
end;

constructor TVisualizadorMidiaWindows.Create(AOwner: TComponent);
begin
  inherited;
  TPascalStyleScript.Instance.RegisterObject(Self, GetPSSClassName);
  OnClose := FormClose;
end;

procedure TVisualizadorMidiaWindows.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TVisualizadorMidiaWindows.CreateHandle;
var
  Wnd: HWND;
  dwmWindowCornerPreference: DWORD;
begin
  inherited;
  Wnd := FormToHWND(Self);
  // WS_EX_LAYERED é adicionado ao estilo da janela para permitir a transparência em janelas no Windows.
  // WS_EX_TOOLWINDOW é adicionado ao estilo da janela para torná-la uma janela de ferramenta, que não aparece na barra de tarefas.
  SetWindowLong(Wnd, GWL_EXSTYLE, GetWindowLong(Wnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_APPWINDOW);

//  dwmWindowCornerPreference := DWMWCP_ROUND;
//  DwmSetWindowAttribute(wnd, DWMWA_WINDOW_CORNER_PREFERENCE, @dwmWindowCornerPreference, SizeOf(dwmWindowCornerPreference));

//  FOldWndProc := Pointer(SetWindowLong(Wnd, GWL_WNDPROC, LongInt(@WndProc)));
end;

procedure TVisualizadorMidiaWindows.DestroyHandle;
begin
//  SetWindowLong(WindowHandleToPlatform(Handle).Wnd, GWL_WNDPROC, LongInt(FOldWndProc));
  inherited;
end;

function TVisualizadorMidiaWindows.GetPSSClassName: String;
begin
  Result := ClassName.Substring(1);
end;

procedure TVisualizadorMidiaWindows.lytCloseButtonClick(Sender: TObject);
begin
  DoConversaClose;
end;

procedure TVisualizadorMidiaWindows.lytMaximizeButtonClick(Sender: TObject);
begin
  DoConversaMaximize;
end;

procedure TVisualizadorMidiaWindows.lytMinimizeButtonClick(Sender: TObject);
begin
  DoConversaMinimize;
end;

procedure TVisualizadorMidiaWindows.rctTitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    if ssDouble in Shift then
      SendMessage(FMX.Platform.Win.WindowHandleToPlatform(Handle).Wnd, WM_NCLBUTTONDBLCLK, HTCAPTION, 0)
    else
      SendMessage(FMX.Platform.Win.WindowHandleToPlatform(Handle).Wnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  end;
end;

procedure TVisualizadorMidiaWindows.DoConversaMinimize;
begin
  Self.WindowState := TWindowState.wsMinimized;
end;

procedure TVisualizadorMidiaWindows.DoConversaRestore;
begin
  //
end;

procedure TVisualizadorMidiaWindows.DoOnCloseView(Sender: TObject);
begin
  DoConversaClose;
end;

procedure TVisualizadorMidiaWindows.DoConversaMaximize;
begin
  if Self.WindowState = TWindowState.wsNormal then
    Self.WindowState := TWindowState.wsMaximized
  else
    Self.WindowState := TWindowState.wsNormal;
end;

procedure TVisualizadorMidiaWindows.DoConversaClose;
begin
  FreeAndNil(Self);
end;

end.
