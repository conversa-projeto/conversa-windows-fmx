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
    imgImagem: TImage;
    lytControles: TLayout;
    aniExibir: TFloatAnimation;
    aniOcultar: TFloatAnimation;
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
    procedure imgImagemClick(Sender: TObject);

    procedure lytCloseButtonMouseEnter(Sender: TObject);
    procedure lytCloseButtonMouseLeave(Sender: TObject);
    procedure lytMaximizeButtonMouseEnter(Sender: TObject);
    procedure lytMaximizeButtonMouseLeave(Sender: TObject);
    procedure lytMinimizeButtonMouseEnter(Sender: TObject);
    procedure lytMinimizeButtonMouseLeave(Sender: TObject);
  private
    { Private declarations }
    procedure ExibirTelaCheia;
    procedure DoOnClose;
  public
    OnClose: TNotifyEvent;
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
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  lytControleDireita.Visible := False;
  lytControleEsquerda.Visible := False;
  lytControlesBottom.Visible := False;
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
    if IsControlKeyPressed then
      ExibirTelaCheia;
  end;
end;

procedure TVisualizadorMidia.imgImagemClick(Sender: TObject);
begin
  Visible := False;
  DoOnClose;
end;

procedure TVisualizadorMidia.ExibirTelaCheia;
begin
  {$IFDEF MSWINDOWS}
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

procedure TVisualizadorMidia.lytMinimizeButtonMouseEnter(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0.1).ToAlphaColor, 0.001);
end;

procedure TVisualizadorMidia.lytMinimizeButtonMouseLeave(Sender: TObject);
begin
  TAnimator.AnimateColor(rctMinimize, 'Fill.Color', TAlphaColorF.Create(255, 255, 255, 0).ToAlphaColor, 0.001);
end;

end.
