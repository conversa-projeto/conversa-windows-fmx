// Eduardo - 03/08/2024
unit chat.conteudo.texto;

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShellAPI,
  {$ENDIF MSWINDOWS}
  System.Types,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  FMX.TextLayout,
  chat.mensagem.conteudo;

type
  TTextLink = record
  public
    Font: TFont;
    Range: TTextRange;
    Attribute: TTextAttribute;
    constructor Create(ARange: TTextRange; AAttribute: TTextAttribute);
  end;

  TText = class(FMX.Objects.TText)
  private
    FontLink: TFont;
    Links: TArray<TTextLink>;
    function GetNewText: String;
    procedure SetNewText(const Value: String);
  protected
    procedure Click; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Text: String read GetNewText write SetNewText;
  end;

  TChatConteudoTexto = class(TChatConteudo)
    txtMensagem: TText;
  public
    function Target(Largura: Single): TTarget; override;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.RegularExpressions,
  FMX.Platform,
  FMX.Clipboard,
  FMX.Ani;

{$R *.fmx}

{ TText }

constructor TText.Create(AOwner: TComponent);
begin
  inherited;
  FontLink := TFont.Create;
  FontLink.Assign(Self.Font);
  FontLink.Style := Self.Font.Style + [TFontStyle.fsUnderline];
end;

destructor TText.Destroy;
begin
  FreeAndNil(FontLink);
  inherited;
end;

procedure TText.Click;
var
  srv: IFMXMouseService;
  P: TPointF;
  CaretPos: Integer;
  I: Integer;
  sLink: String;
begin
  inherited;

  if Length(Links) = 0 then
    Exit;

  if not TPlatformServices.Current.SupportsPlatformService(IFMXMouseService, IInterface(srv)) then
    Exit;

  P := Self.ScreenToLocal(srv.GetMousePos);
  CaretPos := Layout.PositionAtPoint(TPointF.Create(P.X, P.Y));

  for I := 0 to Pred(Length(Links)) do
  begin
    if Links[I].Range.InRange(CaretPos) then
    begin
      sLink := Copy(Text, Succ(Links[I].Range.Pos), Links[I].Range.Length);

      Self.Canvas.BeginScene;
      Self.Layout.BeginUpdate;
      try
        Links[I].Attribute.Color := TAlphaColorF.Create(85 / 255, 26 / 255, 139 / 255).ToAlphaColor;
        Self.Layout.AddAttribute(Links[I].Range, Links[I].Attribute);
      finally
        Self.Layout.EndUpdate;
        Self.Canvas.EndScene;
      end;
      Self.Repaint;

      Break;
    end;
  end;

  if not sLink.IsEmpty then
  begin
    {$IFDEF MSWINDOWS}
    ShellExecute(0, 'OPEN', PChar(sLink), '', '', SW_SHOWNORMAL);
    {$ENDIF MSWINDOWS}
    {$IFDEF POSIX}
    _system(PAnsiChar('open '+ AnsiString(sLink)));
    {$ENDIF POSIX}
  end;
end;

procedure TText.MouseMove(Shift: TShiftState; X, Y: Single);
var
  CaretPos: Integer;
  I: Integer;
  cr: TCursor;
begin
  inherited;

  cr := crDefault;
  try
    if Length(Links) = 0 then
      Exit;
    CaretPos := Layout.PositionAtPoint(TPointF.Create(X, Y));
    for I := 0 to Pred(Length(Links)) do
    begin
      if Links[I].Range.InRange(CaretPos) then
      begin
        cr := crHandPoint;
        Break;
      end;
    end;
  finally
    if Self.Cursor <> cr then
      Self.Cursor := cr;
  end;
end;

function TText.GetNewText: string;
begin
  Result := inherited Text;
end;

procedure TText.SetNewText(const Value: string);
var
  I: Integer;
  Matches: TMatchCollection;
begin
  inherited Text := Value.Replace('&', '&&');

  // Pinta hiperlink
  Matches := TRegEx.Matches(Value, '(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])');
  for I := 0 to Pred(Matches.Count) do
  begin
    Links := Links + [TTextLink.Create(TTextRange.Create(Pred(Matches.Item[I].Index), Matches.Item[I].Length), TTextAttribute.Create(FontLink, TAlphaColorF.Create(0, 0, 238 / 255).ToAlphaColor))];
    Layout.AddAttribute(Links[Pred(Length(Links))].Range, Links[Pred(Length(Links))].Attribute);
  end;
end;

{ TTextLink }

constructor TTextLink.Create(ARange: TTextRange; AAttribute: TTextAttribute);
begin
  Range := ARange;
  Attribute := AAttribute;
end;

{ TConteudoTexto }

function TChatConteudoTexto.Target(Largura: Single): TTarget;
var
  TamanhoTexto: TRectF;
  Anterior: Single;
  Correta: Single;
begin
  TamanhoTexto := RectF(0, 0, Largura - (Self.Margins.Left + Self.Margins.Right), 10000);

  Anterior := txtMensagem.Canvas.Font.Size;
  Correta := txtMensagem.TextSettings.Font.Size;

  if Anterior = Correta then
    txtMensagem.Canvas.MeasureText(TamanhoTexto, txtMensagem.Text, True, [], TTextAlign.Center, TTextAlign.Leading)
  else
  begin
    txtMensagem.Canvas.Font.Size := Correta;
    txtMensagem.Canvas.MeasureText(TamanhoTexto, txtMensagem.Text, True, [], TTextAlign.Center, TTextAlign.Leading);
    txtMensagem.Canvas.Font.Size := Anterior;
  end;

  Result.Width := TamanhoTexto.Width + Self.Margins.Left + Self.Margins.Right;
  Result.Height := TamanhoTexto.Bottom;
end;

end.
