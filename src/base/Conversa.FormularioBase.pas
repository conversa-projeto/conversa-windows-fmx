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
    function GetPSSClassName: String;
  protected
    procedure DoConversaRestore; virtual;
    procedure DoConversaClose; virtual;
    procedure DoConversaMaximize;
    procedure DoConversaMinimize;
  public
    constructor Create(AOwner: TComponent); override;
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

end.
