// Eduardo - 30/01/2024
unit Mensagem.Visualizador;

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShellAPI,
  {$ENDIF MSWINDOWS}
  System.Classes,
  System.Types,
  System.Math,
  System.UITypes,
  System.SysUtils,
  System.RegularExpressions,
  System.Generics.Collections,
  FMX.Ani,
  FMX.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Graphics,
  FMX.TextLayout,
  FMX.Platform,
  FMX.Clipboard,
  PascalStyleScript,
  Mensagem.Tipos;

type
  TItem = record
    Dados: TPMensagem;
    Mensagem: TLayout;
    Hora: TText;
  end;

  TTextLink = record
  public
    Range: TTextRange;
    Attribute: TTextAttribute;
    constructor Create(ARange: TTextRange; AAttribute: TTextAttribute);
  end;

  TText = class(FMX.Objects.TText)
  private
    Links: TArray<TTextLink>;
  protected
    procedure Click; override;
    procedure DblClick; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
  end;

  TVisualizador = class
  private
    FOwner: TFmxObject;
    FVisible: Boolean;
    lytConteudo: TLayout;
    sbxCentro: TVertScrollBox;
    scroll: TSmallScrollBar;
    rtgUltima: TRectangle;
    pthUltima: TPath;
    FWidth: Single;
    FConponentes: Integer;
    FItems: TArray<TItem>;
    procedure CriarControles;
    procedure NomearComponente(Componente: TControl);
    procedure Redimensionar(CentroWidth: Single; Altura: TLayout);
    procedure lytConteudoResized(Sender: TObject);
    procedure sbxCentroViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
    procedure scrollChange(Sender: TObject);
    procedure lytConteudoMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure rtgUltimaClick(Sender: TObject);
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(AOwner: TFmxObject);
    procedure AdicionaMensagem(Mensagem: TPMensagem);
    property Visible: Boolean read FVisible write SetVisible;
    procedure PosicionarUltima;
    procedure Limpar;
    procedure VisualizarTudo;
    procedure ValidarVisualizacao;
  end;

implementation

uses
  Conversa.Chat.Listagem;

const
  TamanhoMaximo = 700;

{ TVisualizador }

constructor TVisualizador.Create(AOwner: TFmxObject);
begin
  FOwner := AOwner;
  FConponentes := 0;
  FWidth := 0;
  FItems := [];
  CriarControles;
end;

procedure TVisualizador.CriarControles;
begin
  lytConteudo := TLayout.Create(FOwner);
  NomearComponente(lytConteudo);
  lytConteudo.Align := TAlignLayout.Client;
  lytConteudo.HitTest := True;
  lytConteudo.Size.Width := 550;
  lytConteudo.Size.Height := 550;
  lytConteudo.Size.PlatformDefault := False;
  lytConteudo.TabOrder := 1;
  lytConteudo.OnResized := lytConteudoResized;
  lytConteudo.OnMouseWheel := lytConteudoMouseWheel;
  lytConteudo.Margins.Bottom := 8;

  sbxCentro := TVertScrollBox.Create(lytConteudo);
  NomearComponente(sbxCentro);
  sbxCentro.Align := TAlignLayout.HorzCenter;
  sbxCentro.Position.X := 20;
  sbxCentro.Size.Width := 500;
  sbxCentro.Size.Height := 550;
  sbxCentro.Size.PlatformDefault := False;
  sbxCentro.TabOrder := 1;
  sbxCentro.ShowScrollBars := False;
  sbxCentro.OnViewportPositionChange := sbxCentroViewportPositionChange;

  scroll := TSmallScrollBar.Create(lytConteudo);
  NomearComponente(scroll);
  scroll.Align := TAlignLayout.Right;
  scroll.Max := 500;
  scroll.SmallChange := 0;
  scroll.Orientation := TOrientation.Vertical;
  scroll.Position.X := 540;
  scroll.Size.Width := 10;
  scroll.Size.Height := 550;
  scroll.Size.PlatformDefault := False;
  scroll.TabOrder := 2;
  scroll.OnChange := scrollChange;

  rtgUltima := TRectangle.Create(lytConteudo);
  NomearComponente(rtgUltima);
  rtgUltima.Anchors := [TAnchorKind.akRight, TAnchorKind.akBottom];
  rtgUltima.Opacity := 0.8;
  rtgUltima.Position.X := 0;
  rtgUltima.Position.Y := 0;
  rtgUltima.Size.Width := 45;
  rtgUltima.Size.Height := 45;
  rtgUltima.Size.PlatformDefault := False;
  rtgUltima.Visible := False;
  rtgUltima.XRadius := 10;
  rtgUltima.YRadius := 10;
  rtgUltima.OnClick := rtgUltimaClick;
  TPascalStyleScript.Instance.RegisterObject(rtgUltima, 'Chat.UltimaMensagem.Fundo');

  pthUltima := TPath.Create(lytConteudo);
  NomearComponente(pthUltima);
  pthUltima.Align := TAlignLayout.Center;
  pthUltima.Data.Data :=
    'M3.16495990753174,4.49746990203857 '+
    'L10.5275001525879,21.0071983337402 '+
    'C11.1177997589111,22.3308982849121 12.8822002410889,22.3308982849121 13.4724998474121,21.0071983337402 '+
    'L20.8349990844727,4.49746894836426 '+
    'C21.5020999908447,3.00162887573242 20.0208988189697,1.45005893707275 18.6330986022949,2.19098901748657 '+
    'L12.729398727417,5.3430290222168 '+
    'C12.2701988220215,5.58817911148071 11.7297983169556,5.58817911148071 11.2705984115601,5.3430290222168 '+
    'L5.36688852310181,2.19098901748657 '+
    'C3.97913837432861,1.45006895065308 2.49788856506348,3.00162887573242 3.16495847702026,4.49746894836426 '+
    'Z ';
  pthUltima.Fill.Color := TAlphaColors.Gainsboro;
  pthUltima.Size.Width := 20;
  pthUltima.Size.Height := 20;
  pthUltima.Size.PlatformDefault := False;
  pthUltima.WrapMode := TPathWrapMode.Fit;
  pthUltima.OnClick := rtgUltimaClick;
  TPascalStyleScript.Instance.RegisterObject(rtgUltima, 'Chat.UltimaMensagem.Icone');

  lytConteudo.AddObject(sbxCentro);
  lytConteudo.AddObject(scroll);
  rtgUltima.AddObject(pthUltima);
  lytConteudo.AddObject(rtgUltima);
  FOwner.AddObject(lytConteudo);
end;

procedure TVisualizador.AdicionaMensagem(Mensagem: TPMensagem);
var
  lytAltura: TLayout;
  lytLargura: TLayout;
  rtgFundo: TRectangle;
  lbNome: TText;
  lytConteudoMensagem: TLayout;
  lbHora: TText;
  txtTexto: TText;
  imgImagem: TImage;
  bmp: TBitmap;
  I: Integer;
  Item: TItem;
begin
  lytAltura := TLayout.Create(lytConteudo);
  NomearComponente(lytAltura);
  lytAltura.Align := TAlignLayout.Top;
  lytAltura.Margins.Top := 5;
  lytAltura.Margins.Bottom := 5;
  lytAltura.Position.Y := High(Integer);
  lytAltura.Size.Width := 500;
  lytAltura.Size.Height := 262;
  lytAltura.Size.PlatformDefault := False;
  lytAltura.TabOrder := 1;

  lytLargura := TLayout.Create(lytConteudo);
  NomearComponente(lytLargura);
  if Mensagem.Lado = TLado.Esquerdo then
    lytLargura.Align := TAlignLayout.Left
  else
    lytLargura.Align := TAlignLayout.Right;
  lytLargura.Margins.Left := 10;
  lytLargura.Margins.Right := 10;
  lytLargura.Position.X := 10;
  lytLargura.Size.Width := 383;
  lytLargura.Size.Height := 262;
  lytLargura.Size.PlatformDefault := False;
  lytLargura.TabOrder := 0;

  rtgFundo := TRectangle.Create(lytConteudo);
  NomearComponente(rtgFundo);
  rtgFundo.Align := TAlignLayout.Client;
  rtgFundo.Size.Width := 383;
  rtgFundo.Size.Height := 262;
  rtgFundo.Size.PlatformDefault := False;
  rtgFundo.XRadius := 5;
  rtgFundo.YRadius := 5;

  if Mensagem.Lado = TLado.Esquerdo then
  begin
    rtgFundo.Fill.Color := $FFEDEDED;
    rtgFundo.Stroke.Kind := TBrushKind.None;
    TPascalStyleScript.Instance.RegisterObject(rtgFundo, 'Mensagem.Fundo');
  end
  else
  begin
    rtgFundo.Fill.Color := $FFCFE7FF;//$FFBFDFFF;//$FFE7F3FF;
    rtgFundo.Stroke.Kind := TBrushKind.None;
    TPascalStyleScript.Instance.RegisterObject(rtgFundo, 'Mensagem.Fundo.Usuario');
  end;
  lbNome := TText.Create(lytConteudo);
  NomearComponente(lbNome);
  lbNome.Align := TAlignLayout.Top;
  lbNome.Margins.Left := 10;
  lbNome.Position.X := 10;
  lbNome.Size.Width := 373;
  lbNome.Size.Height := 22;
  lbNome.Size.PlatformDefault := False;
//  if Mensagem.Lado = TLado.Esquerdo then
//  begin
//    lbNome.Text := Mensagem.Remetente;
//    if Mensagem.Remetente.IsEmpty then
//      lbNome.Size.Height := 5;
//  end
//  else
//  begin
    lbNome.Text := EmptyStr;
    lbNome.Size.Height := 5;
//  end;
  TPascalStyleScript.Instance.RegisterObject(lbNome, 'Mensagem.NomeUsuario');

  lytConteudoMensagem := TLayout.Create(lytConteudo);
  NomearComponente(lytConteudoMensagem);
  lytConteudoMensagem.Align := TAlignLayout.Client;
  lytConteudoMensagem.Margins.Left := 15;
  lytConteudoMensagem.Margins.Right := 15;
  lytConteudoMensagem.Size.Width := 353;
  lytConteudoMensagem.Size.Height := 218;
  lytConteudoMensagem.Size.PlatformDefault := False;
  lbHora := TText.Create(lytConteudo);
  NomearComponente(lbHora);
  lbHora.Align := TAlignLayout.Bottom;
  lbHora.Margins.Right := 10;
  lbHora.Position.Y := 240;
  lbHora.Size.Width := 373;
  lbHora.Size.Height := 22;
  lbHora.Size.PlatformDefault := False;
  lbHora.TextSettings.HorzAlign := TTextAlign.Trailing;
  lbHora.Text := FormatDateTime('hh:nn', Mensagem.inserida);
  TPascalStyleScript.Instance.RegisterObject(lbHora, 'Mensagem.DataHora');

  for I := 0 to Pred(Length(Mensagem.Conteudos)) do
  begin
    case Mensagem.Conteudos[I].Tipo of
      1: // texto
      begin
        txtTexto := TText.Create(lytConteudo);
        NomearComponente(txtTexto);
        txtTexto.Align := TAlignLayout.Top;
        txtTexto.Size.Width := 276;
        txtTexto.Size.Height := 17;
        txtTexto.Size.PlatformDefault := False;
        txtTexto.Text := Mensagem.Conteudos[I].conteudo;
        txtTexto.TextSettings.HorzAlign := TTextAlign.Leading;
        txtTexto.TextSettings.VertAlign := TTextAlign.Leading;

        // Pinta hiperlink
        var Matches := TRegEx.Matches(txtTexto.Text, '(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])');
        for var J := 0 to Pred(Matches.Count) do
        begin
          var Fonte := TFont.Create;
          Fonte.Assign(txtTexto.Font);
          Fonte.Style := Fonte.Style + [TFontStyle.fsUnderline];
          txtTexto.Links := txtTexto.Links + [TTextLink.Create(TTextRange.Create(Pred(Matches.Item[J].Index), Matches.Item[J].Length), TTextAttribute.Create(Fonte, TAlphaColorF.Create(0, 0, 238 / 255).ToAlphaColor))];
          txtTexto.Layout.AddAttribute(txtTexto.Links[Pred(Length(txtTexto.Links))].Range, txtTexto.Links[Pred(Length(txtTexto.Links))].Attribute);
        end;

        lytConteudoMensagem.AddObject(txtTexto);
        TPascalStyleScript.Instance.RegisterObject(txtTexto, 'Mensagem.Conteudo.Texto');
      end;
      2: // imagem
      begin
        imgImagem := TImage.Create(lytConteudo);
        NomearComponente(imgImagem);
        bmp := TBitmap.Create;
        try
          bmp.LoadFromFile(Mensagem.Conteudos[I].conteudo);
          imgImagem.MultiResBitmap.Add.Bitmap.Assign(bmp);
        finally
          FreeAndNil(bmp);
        end;
        imgImagem.Align := TAlignLayout.Top;
        if (Length(Mensagem.Conteudos) > 1) and (I >= 1) then
          imgImagem.Margins.Top := 5;
        imgImagem.Size.Width := 353;
        imgImagem.Size.Height := 217;
        imgImagem.Size.PlatformDefault := False;
        lytConteudoMensagem.AddObject(imgImagem);
      end;
    end;
  end;

  rtgFundo.AddObject(lytConteudoMensagem);
  rtgFundo.AddObject(lbNome);
  rtgFundo.AddObject(lbHora);
  lytLargura.AddObject(rtgFundo);
  lytAltura.AddObject(lytLargura);
  sbxCentro.Content.AddObject(lytAltura);
  // Posiciona a mensagem no fim
  lytAltura.Position.Y := scroll.Max;
  Item.Dados := Mensagem;
  Item.Mensagem := lytAltura;
  Item.Hora := lbHora;
  FItems := FItems + [Item];
  Redimensionar(sbxCentro.Width, lytAltura);
end;

procedure TVisualizador.NomearComponente(Componente: TControl);
begin
  Inc(FConponentes);
  Componente.Name := Copy(Componente.ClassName, 2) + FConponentes.ToString +'_'+ FormatDateTime('yyyymmddhhnnsszzz', Now);
end;

procedure TVisualizador.Redimensionar(CentroWidth: Single; Altura: TLayout);
var
  TamanhoTexto: TRectF;
  Largura: TLayout;
  Fundo: TRectangle;
  Conteudo: TLayout;
  Texto: TText;
  Imagem: TImage;
  I: Integer;
  iMaximaLargura: Single;
  iSomaAltura: Single;
  iMargem: Single;
begin
  Largura := Altura.Controls[0] as TLayout;
  Fundo := Largura.Controls[0] as TRectangle;
  Conteudo := Fundo.Controls[0] as TLayout;

  iMaximaLargura := 0;
  iSomaAltura := 0;
  iMargem := Conteudo.Margins.Left + Conteudo.Margins.Right;

  CentroWidth := CentroWidth - (Largura.Margins.Left + Largura.Margins.Right);

  for I := 0 to Pred(Conteudo.ControlsCount) do
  begin
    if Conteudo.Controls[I] is TText then
    begin
      Texto := Conteudo.Controls[I] as TText;
      TamanhoTexto := RectF(0, 0, CentroWidth - iMargem, 10000);
      Texto.Canvas.MeasureText(TamanhoTexto, Texto.Text, True, [], TTextAlign.Center, TTextAlign.Leading);
      iMaximaLargura := Max(iMaximaLargura, Min(TamanhoTexto.Width, CentroWidth));
      Texto.Height := TamanhoTexto.Bottom;
      iSomaAltura := iSomaAltura + TamanhoTexto.Bottom;
    end
    else
    if Conteudo.Controls[I] is TImage then
    begin
      Imagem := Conteudo.Controls[I] as TImage;
      Imagem.Height := Max(100, (Min(CentroWidth - iMargem, Imagem.Bitmap.Width) * Imagem.Bitmap.Height) / Imagem.Bitmap.Width);
      iMaximaLargura := Max(iMaximaLargura, Min(CentroWidth - iMargem, Imagem.Bitmap.Width));
      iSomaAltura := iSomaAltura + Imagem.Height + Imagem.Margins.Top + Imagem.Margins.Bottom;
    end;
  end;

  for I := 0 to Pred(Fundo.ControlsCount) do
  begin
    if not Assigned(Fundo.Controls[I]) or not Fundo.Controls[I].Visible then
      Continue;
    if Fundo.Controls[I] is TText then
    begin
      iSomaAltura := iSomaAltura + TText(Fundo.Controls[I]).Height;
      TamanhoTexto := RectF(0, 0, CentroWidth - iMargem, 10000);
      TText(Fundo.Controls[I]).BeginUpdate;
      try
        TText(Fundo.Controls[I]).Canvas.MeasureText(TamanhoTexto, TText(Fundo.Controls[I]).Text, True, [], TTextAlign.Trailing, TTextAlign.Center);
      finally
        TText(Fundo.Controls[I]).EndUpdate;
      end;
      iMaximaLargura := Max(iMaximaLargura, TamanhoTexto.Height);
    end;
  end;
  Largura.Width := iMaximaLargura + iMargem;
  Altura.Height := iSomaAltura;
end;

procedure TVisualizador.rtgUltimaClick(Sender: TObject);
begin
  // Posiciona na última mensagem
  TAnimator.AnimateFloat(scroll, 'Value', scroll.Max - scroll.ViewportSize, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
  TAnimator.AnimateFloat(rtgUltima, 'Position.Y', lytConteudo.Height + rtgUltima.Height + 8 + 5, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TVisualizador.sbxCentroViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  // Atualiza a posição da scroll
  scroll.Max := sbxCentro.ContentBounds.Height;
  scroll.ViewportSize := lytConteudo.Height;
  scroll.Value := NewViewportPosition.Y;
  ValidarVisualizacao;
end;

procedure TVisualizador.scrollChange(Sender: TObject);
begin
  // Atualiza a visão
  sbxCentro.ViewportPosition := TPointF.Create(0, scroll.Value);

  // Define o posicionamento do botão de ir para última mensagem
  if not rtgUltima.Visible then
  begin
    rtgUltima.Visible := True;
    rtgUltima.Position.X := lytConteudo.Width - rtgUltima.Width - scroll.Width - 8;
    rtgUltima.Position.Y := lytConteudo.Height - rtgUltima.Height - 8;
  end;

  // Exibe botão para ir até a última mensagem
  if (scroll.Value < (scroll.Max - scroll.ViewportSize - 300)) then
  begin
    // Exibe
    if rtgUltima.Position.Y = (lytConteudo.Height + rtgUltima.Height + 8) then
      TAnimator.AnimateFloat(rtgUltima, 'Position.Y', lytConteudo.Height - rtgUltima.Height - 8, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
  end
  else
  begin
    // Oculta
    if rtgUltima.Position.Y = (lytConteudo.Height - rtgUltima.Height - 8) then
      TAnimator.AnimateFloat(rtgUltima, 'Position.Y', lytConteudo.Height + rtgUltima.Height + 8, 0.5, TAnimationType.InOut, TInterpolationType.Cubic);
  end;
end;

procedure TVisualizador.lytConteudoMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  // HitTest = True, para funcionar
  scroll.Value := scroll.Value - WheelDelta;
end;

procedure TVisualizador.lytConteudoResized(Sender: TObject);
var
  I: Integer;
begin
  // Abaixo do tamanho máximo começa a reduzir o conteúdo
  sbxCentro.Width := Min(TamanhoMaximo, lytConteudo.Width);

  // Se mudou a largura
  if FWidth <> sbxCentro.Width then
  begin
    if (FWidth < TamanhoMaximo) or (sbxCentro.Width < TamanhoMaximo) then
    begin
      FWidth := sbxCentro.Width;

      // Redimenciona as mensagens
      for I := 0 to Pred(sbxCentro.Content.ControlsCount) do
        if sbxCentro.Content.Controls[I] is TLayout then
          Redimensionar(FWidth, TLayout(sbxCentro.Content.Controls[I]));
    end;
  end;
end;

procedure TVisualizador.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  lytConteudo.Visible := Value;
end;

procedure TVisualizador.PosicionarUltima;
begin
  rtgUltimaClick(rtgUltima);
end;

procedure TVisualizador.Limpar;
begin
  FItems := [];
  FConponentes := 0;
  FWidth := 0;
  FreeAndNil(lytConteudo);
  CriarControles;
end;

procedure TVisualizador.ValidarVisualizacao;
var
  I: Integer;
begin
  if not Chats.IsFormActive then
    Exit;

  for I := Pred(Length(FItems)) downto 0 do
  begin
    if FItems[I].Dados.Visualizada then
      Continue;

    if InRange(FItems[I].Mensagem.Position.Y, scroll.Value, scroll.Value + lytConteudo.Height) then
    begin
      FItems[I].Dados.Visualizada := True;
      with TColorAnimation.Create(FItems[I].Hora) do
      begin
        TAnimator.StopPropertyAnimation(FItems[I].Hora, 'TextSettings.FontColor');
        Parent := FItems[I].Hora;
        AnimationType := TAnimationType.In;
        Interpolation := TInterpolationType.Linear;
        Duration := Duration;
        PropertyName := 'TextSettings.FontColor';
        StartFromCurrent := True;
        StopValue := TAlphaColors.Blue;
        Delay := 2;
        Start;
      end;
    end;
  end;
end;

procedure TVisualizador.VisualizarTudo;
begin
  for var I := Pred(Length(FItems)) downto 0 do
    FItems[I].Dados.Visualizada := True;
end;

{ TText }

procedure TText.Click;
var
  srv: IFMXMouseService;
  P: TPointF;
  CaretPos: Integer;
  I: Integer;
  sLink: String;
begin
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

procedure TText.DblClick;
var
  svc: IFMXExtendedClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, svc) then
    svc.SetText(Text);
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

{ TTextLink }

constructor TTextLink.Create(ARange: TTextRange; AAttribute: TTextAttribute);
begin
  Range := ARange;
  Attribute := AAttribute;
end;

end.
