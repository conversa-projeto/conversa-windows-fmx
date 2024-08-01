unit Conversa.Visualizador.Midia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, Conversa.FrameBase, FMX.Ani;

type
  TVisualizadorMidia = class(TFrameBase)
    rctFundo: TRectangle;
    lytControlesBottom: TLayout;
    lytControlesBotoes: TLayout;
    lytControleEsquerda: TLayout;
    lytControleDireita: TLayout;
    Circle1: TCircle;
    Circle2: TCircle;
    lytMedia: TLayout;
    Path1: TPath;
    Path2: TPath;
    lytTitleBar: TLayout;
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
    imgImagem: TImage;

    procedure lytCloseButtonMouseEnter(Sender: TObject);
    procedure lytCloseButtonMouseLeave(Sender: TObject);
    procedure lytMaximizeButtonMouseEnter(Sender: TObject);
    procedure lytMaximizeButtonMouseLeave(Sender: TObject);
    procedure lytMinimizeButtonMouseEnter(Sender: TObject);
    procedure lytMinimizeButtonMouseLeave(Sender: TObject);
    procedure imgImagemMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure imgImagemMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure imgImagemMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure imgImagemMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure lytMediaMouseLeave(Sender: TObject);
    procedure lytMediaMouseEnter(Sender: TObject);
  private
    { Private declarations }
    FTelaCheia: Boolean;
    FIsDragging: Boolean;
    FMoveu: Boolean;
    FStartPoint: TPointF;
    procedure ExibirTelaCheia;
    procedure DoOnClose;
    procedure ResetZoom;
    procedure ConstrainImagePosition;
  public
    OnClose: TNotifyEvent;
    StoredWheelDelta: Extended;
    constructor Create(AOwner: TComponent); override;
    class procedure Exibir(bmp: TBitmap);
  end;

implementation

{$R *.fmx}

uses
  {$IFDEF MSWINDOWS}
  Conversa.Visualizador.Midia.Windows,
  {$ELSE}
  Macapi.AppKit;
  {$ENDIF}
  Conversa.Utils,
  Conversa.Tela.Inicial.view;

{ TVisualizadorMidia }

constructor TVisualizadorMidia.Create(AOwner: TComponent);
begin
  inherited;
  StoredWheelDelta := 0;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  FTelaCheia := False;
  lytControleDireita.Visible := False;
  lytControleEsquerda.Visible := False;
  lytControlesBottom.Visible := False;

  FIsDragging := False;
  imgImagem.WrapMode := TImageWrapMode.Fit;
  ResetZoom;
end;

procedure TVisualizadorMidia.DoOnClose;
begin
  if Assigned(OnClose) then
    OnClose(Self)
  else
    FreeAndNil(Self);
end;

class procedure TVisualizadorMidia.Exibir(bmp: TBitmap);
begin
  with TVisualizadorMidia.Create(TelaInicial.lytClientForm) do
  begin
    imgImagem.Bitmap.Assign(bmp);
    ResetZoom;
    if IsControlKeyPressed then
      ExibirTelaCheia
    else
    begin
      lytTitleBar.Visible := False;
    end;
  end;
end;

procedure TVisualizadorMidia.ExibirTelaCheia;
begin
  {$IFDEF MSWINDOWS}
  FTelaCheia := True;
  TVisualizadorMidiaWindows.Exibir(Self);
  {$ENDIF MSWINDOWS}
end;

procedure TVisualizadorMidia.lytCloseButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(lnClose1, 'Stroke.Color', TAlphaColors.White, 0.001);
  TAnimator.AnimateColor(lnClose2, 'Stroke.Color', TAlphaColors.White, 0.001);
  TAnimator.AnimateColor(rctClose, 'Fill.Color', TAlphaColors.Red, 0.001);
end;

procedure TVisualizadorMidia.lytCloseButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(lnClose1, 'Stroke.Color', TAlphaColors.Black, 0.001);
  TAnimator.AnimateColor(lnClose2, 'Stroke.Color', TAlphaColors.Black, 0.001);
  TAnimator.AnimateColor(rctClose, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.lytMaximizeButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMaximize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.lytMaximizeButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMaximize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.lytMediaMouseEnter(Sender: TObject);
begin
  inherited;
  FMoveu := False;
  FIsDragging := False;
end;

procedure TVisualizadorMidia.lytMediaMouseLeave(Sender: TObject);
begin
  inherited;
  FIsDragging := False;
  FMoveu := False;
end;

procedure TVisualizadorMidia.lytMinimizeButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.lytMinimizeButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.ResetZoom;
var
  AspectRatio: Single;
begin
  // Calcula a razão de aspecto original da imagem
  AspectRatio := imgImagem.Bitmap.Width / imgImagem.Bitmap.Height;

  // Ajusta o tamanho da imagem para se ajustar ao lytMedia mantendo a proporção
  if lytMedia.Width / lytMedia.Height > AspectRatio then
  begin
    imgImagem.Width := lytMedia.Height * AspectRatio;
    imgImagem.Height := lytMedia.Height;
  end
  else
  begin
    imgImagem.Width := lytMedia.Width;
    imgImagem.Height := lytMedia.Width / AspectRatio;
  end;

  // Define a posição da imagem para centralizá-la no lytMedia
  imgImagem.Position.X := (lytMedia.Width - imgImagem.Width) / 2;
  imgImagem.Position.Y := (lytMedia.Height - imgImagem.Height) / 2;
end;

procedure TVisualizadorMidia.imgImagemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    FIsDragging := True;
    FStartPoint := PointF(X, Y);
//    imgImagem.SetFocus;
//    SetCapture(Handle); // Captura o mouse para garantir que o arrasto continue
  end;
end;

procedure TVisualizadorMidia.imgImagemMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FIsDragging then
  begin
    FMoveu := True;
    imgImagem.Position.X := imgImagem.Position.X + (X - FStartPoint.X);
    imgImagem.Position.Y := imgImagem.Position.Y + (Y - FStartPoint.Y);
    FStartPoint := PointF(X, Y);
    ConstrainImagePosition; // Constrange a posição da imagem para ficar dentro dos limites
  end;
end;

procedure TVisualizadorMidia.imgImagemMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    FIsDragging := False;
    ReleaseCapture; // Libera a captura do mouse

    if not FMoveu then
    begin
      Visible := False;
      DoOnClose;
    end;

    FMoveu := False;
  end;
end;

procedure TVisualizadorMidia.imgImagemMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
const
  ZoomFactor = 1.1;
var
  MousePos: TPointF;
  ImagePos: TPointF;
  OldWidth, OldHeight: Single;
  NewWidth, NewHeight: Single;
  Zoom: Single;
begin
  // Posições do mouse em relação ao Layout
  MousePos := lytMedia.ScreenToLocal(Screen.MousePos);

  // Posições relativas do mouse na imagem
  ImagePos := PointF(MousePos.X - imgImagem.Position.X, MousePos.Y - imgImagem.Position.Y);

  // Fator de zoom
  if WheelDelta > 0 then
    Zoom := ZoomFactor
  else
    Zoom := 1 / ZoomFactor;

  // Dimensões antigas e novas da imagem
  OldWidth := imgImagem.Width;
  OldHeight := imgImagem.Height;
  NewWidth := OldWidth * Zoom;
  NewHeight := OldHeight * Zoom;

  // Atualiza largura e altura da imagem
  imgImagem.Width := NewWidth;
  imgImagem.Height := NewHeight;

  // Ajusta a posição da imagem para manter o ponto do mouse na mesma posição relativa
  imgImagem.Position.X := imgImagem.Position.X + (ImagePos.X * (1 - Zoom));
  imgImagem.Position.Y := imgImagem.Position.Y + (ImagePos.Y * (1 - Zoom));

  ConstrainImagePosition; // Constrange a posição da imagem para ficar dentro dos limites

  Handled := True;
end;

procedure TVisualizadorMidia.ConstrainImagePosition;
begin
  // Constrain the image position to make sure it stays within the bounds of the layout
  if imgImagem.Width > lytMedia.Width then
  begin
    if imgImagem.Position.X > 0 then
      imgImagem.Position.X := 0
    else if imgImagem.Position.X < lytMedia.Width - imgImagem.Width then
      imgImagem.Position.X := lytMedia.Width - imgImagem.Width;
  end
  else
  begin
    imgImagem.Position.X := (lytMedia.Width - imgImagem.Width) / 2;
  end;

  if imgImagem.Height > lytMedia.Height then
  begin
    if imgImagem.Position.Y > 0 then
      imgImagem.Position.Y := 0
    else if imgImagem.Position.Y < lytMedia.Height - imgImagem.Height then
      imgImagem.Position.Y := lytMedia.Height - imgImagem.Height;
  end
  else
  begin
    imgImagem.Position.Y := (lytMedia.Height - imgImagem.Height) / 2;
  end;
end;

end.
