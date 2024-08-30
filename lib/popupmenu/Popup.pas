unit Popup;

interface

uses
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.Types,
  FMX.Ani;

type
  TPopupPosition = (
    BottomLeft,
    BottomRight,
    RightTop,
    RightBottom,
    LeftTop,
    LeftBottom,
    TopLeft,
    TopRight
  );
  TPopupPositionH = record Helper for TPopupPosition
    function Calc(ASource, ATarget: TRectF): TRectF;
  end;

  TPopupPositions = TArray<TPopupPosition>;
  TPopupPositionsH = record Helper for TPopupPositions
    function Fix: TPopupPositions;
  end;

  TPopup = class(TFrame)
  private
    FView: TFmxObject;
    function FixRect(ARect, AArea: TRectF): TRectF;
  protected
    FTarget: TFmxObject;
    function PodeOcultar: Boolean; virtual;
    function FixPoint(APos: TPointF; ARect: TRectF): TPointF;

    procedure InternalExibir(APos: TPointF); virtual;
  public
    class function New(ATarget: TFmxObject): TPopup;
    destructor Destroy; override;

    procedure Exibir(ATarget: TControl); overload; virtual;
    procedure Exibir(ATarget: TControl; APosition: TPopupPosition); overload; virtual;
    procedure Exibir(ATarget: TControl; APosition: TPopupPositions); overload; virtual;

    procedure Exibir(ATarget: TRectF); overload; virtual;
    procedure Exibir(ATarget: TRectF; APosition: TPopupPosition); overload; virtual;
    procedure Exibir(ATarget: TRectF; APositions: TPopupPositions); overload; virtual;
    procedure Exibir(APos: TPointF); overload; virtual;

    procedure Ocultar; virtual;
    procedure Activate; virtual;
  end;

implementation

{$R *.fmx}

uses
  Winapi.Windows,
  FMX.Platform.Win;

type
  TWindowsView = class(TForm)
  private
    PopupMenu: TPopup;
    FreeOnClose: Boolean;
    procedure FormDeactivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CreateHandle; override;
    procedure Exibir;
    destructor Destroy; override;
  end;

{ TWindowsView }

procedure TWindowsView.CreateHandle;
//var
//  Wnd: HWND;
begin
  inherited;
  FreeOnClose := True;
//  Wnd := WindowHandleToPlatform(Handle).Wnd;
//  // WS_EX_LAYERED é adicionado ao estilo da janela para permitir a transparência em janelas no Windows.
//  SetWindowLong(Wnd, GWL_EXSTYLE, GetWindowLong(Wnd, GWL_EXSTYLE) or WS_EX_LAYERED);
//  // WS_CAPTION e WS_THICKFRAME são removidos para eliminar a borda do formulário.
//  SetWindowLong(Wnd, GWL_STYLE, GetWindowLong(Wnd, GWL_STYLE) and not (WS_CAPTION or WS_THICKFRAME));
end;

destructor TWindowsView.Destroy;
begin
  if Assigned(PopupMenu) then
  begin
    PopupMenu.FView := nil;
    PopupMenu.Ocultar;
  end;
  inherited;
end;

procedure TWindowsView.Exibir;
begin
  Height := 10;
  Width := 10;
  Show;
//  WindowState := TWindowState.wsMaximized;
end;

procedure TWindowsView.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FreeOnClose then
    Action := TCloseAction.caFree;
end;

procedure TWindowsView.FormDeactivate(Sender: TObject);
begin
//  if Assigned(PopupMenu) then
//  begin
//    if not PopupMenu.PodeOcultar then
//      Exit;
//
//    FreeOnClose := False;
//    PopupMenu.FView := nil;
//    PopupMenu.Ocultar;
//  end;
//
//  FreeOnClose := True;
//  Close;
end;

{ TPopup }

class function TPopup.New(ATarget: TFmxObject): TPopup;
begin
  Sleep(1); // Para mudar o millisegundo do nome
  Result := TPopup.Create(Application);
  Result.Name := 'TPopup_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
  Result.Parent := ATarget;
  Result.FTarget := ATarget;
end;

procedure TPopup.Ocultar;
begin
  Parent := FTarget;
  if Assigned(FView) then
  begin
    TWindowsView(FView).PopupMenu := nil;
    TWindowsView(FView).OnDeactivate := nil;
    TWindowsView(FView).FreeOnClose := False;
    FreeAndNil(FView);
  end;
end;

destructor TPopup.Destroy;
begin
  if Assigned(FView) then
  begin
    TWindowsView(FView).OnDeactivate := nil;
    TWindowsView(FView).FreeOnClose := False;
    FreeAndNil(FView);
  end;
  inherited;
end;

function TPopup.FixPoint(APos: TPointF; ARect: TRectF): TPointF;
begin
  //
end;

function TPopup.FixRect(ARect, AArea: TRectF): TRectF;
begin
  Result := ARect;

  // Ajusta o lado esquerdo de ARect se estiver fora do limite esquerdo de AArea
  if Result.Left < AArea.Left then
    Result.Offset(AArea.Left - Result.Left, 0);

  // Ajusta o lado direito de ARect se estiver fora do limite direito de AArea
  if Result.Right > AArea.Right then
    Result.Offset(AArea.Right - Result.Right, 0);

  // Ajusta o topo de ARect se estiver fora do limite superior de AArea
  if Result.Top < AArea.Top then
    Result.Offset(0, AArea.Top - Result.Top);

  // Ajusta a parte inferior de ARect se estiver fora do limite inferior de AArea
  if Result.Bottom > AArea.Bottom then
    Result.Offset(0, AArea.Bottom - Result.Bottom);
end;

procedure TPopup.Exibir(ATarget: TControl; APosition: TPopupPositions);
var
  R: TRectF;
begin
  R := ATarget.LocalRect;
  R.SetLocation(ATarget.LocalToScreen(R.TopLeft));
  Exibir(R, APosition);
end;

procedure TPopup.Exibir(ATarget: TControl);
var
  R: TRectF;
begin
  R := ATarget.LocalRect;
  R.SetLocation(ATarget.LocalToScreen(R.TopLeft));
  Exibir(R, []);
end;

procedure TPopup.Exibir(ATarget: TControl; APosition: TPopupPosition);
var
  R: TRectF;
begin
  R := ATarget.LocalRect;
  R.SetLocation(ATarget.LocalToScreen(R.TopLeft));
  Exibir(R, [APosition]);
end;

procedure TPopup.Exibir(ATarget: TRectF);
begin
  Exibir(ATarget, []);
end;

procedure TPopup.Exibir(ATarget: TRectF; APosition: TPopupPosition);
begin
  Exibir(ATarget, [APosition]);
end;

procedure TPopup.Exibir(ATarget: TRectF; APositions: TPopupPositions);
var
  Dis: TDisplay;
  Posi: TPopupPosition;
  PopupRect: TRectF;
  I: Integer;
begin
  // Obtém o monitor utilizando o TopLeft do Alvo
  Dis := Screen.DisplayFromPoint(ATarget.TopLeft);
  for Posi in APositions.Fix do
  begin
    // Onde ficará o Popup
    PopupRect := Posi.Calc(Self.LocalRect, ATarget);
    for I := 0 to Pred(Screen.DisplayCount) do
    begin
      if Dis.Workarea.Contains(PopupRect) then
      begin
        Exibir(PopupRect.TopLeft);
        Exit;
      end;
    end;
  end;

  raise Exception.Create('Não foi possível Exibir!');
end;

procedure TPopup.Exibir(APos: TPointF);
var
  R: TRectF;
  Dis: TDisplay;
begin
  Dis := Screen.DisplayFromPoint(APos);
  R := Self.LocalRect;
  R.SetLocation(APos);
  R := FixRect(R, Dis.Workarea);
  InternalExibir(R.TopLeft.Round);
end;

procedure TPopup.InternalExibir(APos: TPointF);
begin
  Sleep(1);
  // Cria uma nova instância da janela pop-up
  FView := TWindowsView.CreateNew(Application);
  with TWindowsView(FView) do
  begin
    FormStyle := TFormStyle.Popup;
    Name := 'TPopup_TWindowsView_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
    PopupMenu := Self;
    Transparency := True;
    OnDeactivate := FormDeactivate;
    OnClose := FormClose;
    Exibir;
    // Define a largura e altura do Popup com base no Frame
    Width := Round(Self.Width);
    Height := Round(Self.Height);
    Left := APos.Round.X;
    Top :=  APos.Round.Y;
  end;
  // Define o parent do Popup para a nova janela criada
  Parent := FView;
end;

function TPopup.PodeOcultar: Boolean;
begin
  Result := True;
end;

procedure TPopup.Activate;
begin
  if Assigned(FView) then
    TWindowsView(FView).Activate;
end;

{ TPopupPositionH }

function TPopupPositionH.Calc(ASource, ATarget: TRectF): TRectF;
var
  Referencia: TPointF;
begin
  Result := ASource;

  case Self of
    LeftTop, TopLeft        : Referencia := PointF(ATarget.Left, ATarget.Top);
    LeftBottom, BottomLeft  : Referencia := PointF(ATarget.Left, ATarget.Bottom);
    RightTop, TopRight      : Referencia := PointF(ATarget.Right, ATarget.Top);
    RightBottom, BottomRight: Referencia := PointF(ATarget.Right, ATarget.Bottom);
  end;

  // Corrigir X
  case Self of
    LeftTop, LeftBottom  : Referencia.X := Referencia.X - ASource.Width;
    TopRight, BottomRight: Referencia.X := Referencia.X - ASource.Width;
    TopLeft, BottomLeft  : ; // Não precisa corrigir
  end;

  // Corrigir Y
  case Self of
    LeftBottom, TopLeft, TopRight, RightBottom : Referencia.Y := Referencia.Y - ASource.Height;
    LeftTop, RightTop, BottomLeft, BottomRight: ; // Não precisa corrigir
  end;

  Result.SetLocation(Referencia);
end;

{ TPopupPositionsH }

function TPopupPositionsH.Fix: TPopupPositions;
var
  I: Integer;
  bContem: Boolean;
  Item: TPopupPosition;
begin
  Result := Self;
  for I := Integer(Low(TPopupPosition)) to Integer(High(TPopupPosition)) do
  begin
    bContem := False;
    for Item in Result do
    begin
      if Integer(Item) = I then
      begin
        bContem := True;
        Break;
      end;
    end;
    if bContem then
      Continue;

    Result := Result + [TPopupPosition(I)];
  end;
end;

end.
