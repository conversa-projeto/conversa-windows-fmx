// Eduardo - 04/08/2024
unit chat.editor.entrada;

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
  FMX.Memo.Types,
  FMX.Objects,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo,
  chat.base;

type
  TChatEditorEntrada = class(TChatBase)
    rtgFundo: TRectangle;
    rtgMensagem: TRectangle;
    mmMensagem: TMemo;
    txtMensagem: TText;
    lytCarinha: TLayout;
    pthCarinha: TPath;
    lytAnexo: TLayout;
    pthAnexo: TPath;
    lytEnviar: TLayout;
    pthEnviar: TPath;
    procedure FrameResized(Sender: TObject);
    procedure mmMensagemChangeTracking(Sender: TObject);
    procedure mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    FLarguraMaximaConteudo: Integer;
    function GetAoAnexoClick: TNotifyEvent;
    procedure SetAoAnexoClick(const Value: TNotifyEvent);
    function GetAoEmojiClick: TNotifyEvent;
    procedure SetAoEmojiClick(const Value: TNotifyEvent);
    function GetAoEnviarClick: TNotifyEvent;
    procedure SetAoEnviarClick(const Value: TNotifyEvent);
    procedure SetLarguraMaximaConteudo(const Value: Integer);
  public
    procedure AfterConstruction; override;
    property LarguraMaximaConteudo: Integer read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property AoAnexoClick: TNotifyEvent read GetAoAnexoClick write SetAoAnexoClick;
    property AoEmojiClick: TNotifyEvent read GetAoEmojiClick write SetAoEmojiClick;
    property AoEnviarClick: TNotifyEvent read GetAoEnviarClick write SetAoEnviarClick;
  end;

implementation

uses
  System.Math;

{$R *.fmx}

{ TEditor }

procedure TChatEditorEntrada.AfterConstruction;
begin
  inherited;
  mmMensagem.NeedStyleLookup;
  mmMensagem.ApplyStyleLookup;
  mmMensagem.StylesData['background.Source'] := nil;
end;

procedure TChatEditorEntrada.FrameResized(Sender: TObject);
var
  TamanhoTexto: TRectF;
  cHeight: Single;
begin
  rtgMensagem.Width := Min(LarguraMaximaConteudo, Self.Width);

  if Self.Width > LarguraMaximaConteudo then
    rtgMensagem.Corners := [TCorner.TopLeft, TCorner.TopRight]
  else
    rtgMensagem.Corners := [];

  if not Assigned(mmMensagem.Canvas) then
    Exit;

  if mmMensagem.Width < 50 then
    Exit;

  TamanhoTexto := RectF(0, 0, mmMensagem.ContentSize.Width, 10000);
  mmMensagem.Canvas.MeasureText(TamanhoTexto, mmMensagem.Lines.Text, True, [], TTextAlign.Center, TTextAlign.Leading);
  cHeight := TamanhoTexto.Bottom + mmMensagem.Margins.Top + mmMensagem.Margins.Bottom;

  if cHeight > 40 then
    cHeight := cHeight + 5;
  Self.Height := Min(212, Max(40, cHeight));
  mmMensagem.ShowScrollBars := Self.Height > 200;
end;

procedure TChatEditorEntrada.mmMensagemChangeTracking(Sender: TObject);
begin
  txtMensagem.Visible := mmMensagem.Lines.Text.IsEmpty;
  FrameResized(Self);
end;

procedure TChatEditorEntrada.mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkReturn) and (Shift = []) then
  begin
    Key := 0;
    KeyChar := #0;
    if Assigned(lytEnviar.OnClick) then
      lytEnviar.OnClick(lytEnviar);
  end;
end;

procedure TChatEditorEntrada.SetLarguraMaximaConteudo(const Value: Integer);
begin
  FLarguraMaximaConteudo := Value;
  FrameResized(Self);
end;

function TChatEditorEntrada.GetAoAnexoClick: TNotifyEvent;
begin
  Result := lytAnexo.OnClick;
end;

procedure TChatEditorEntrada.SetAoAnexoClick(const Value: TNotifyEvent);
begin
  lytAnexo.OnClick := Value;
end;

function TChatEditorEntrada.GetAoEmojiClick: TNotifyEvent;
begin
  Result := lytCarinha.OnClick;
end;

procedure TChatEditorEntrada.SetAoEmojiClick(const Value: TNotifyEvent);
begin
  lytCarinha.OnClick := Value;
end;

function TChatEditorEntrada.GetAoEnviarClick: TNotifyEvent;
begin
  Result := lytEnviar.OnClick;
end;

procedure TChatEditorEntrada.SetAoEnviarClick(const Value: TNotifyEvent);
begin
  lytEnviar.OnClick := Value;
end;

end.
