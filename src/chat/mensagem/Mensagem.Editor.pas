// Eduardo - 11/02/2024
unit Mensagem.Editor;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Types,
  System.Math,
  FMX.Memo,
  FMX.Types,
  FMX.Layouts,
  FMX.Graphics,
  FMX.Objects,
  FMX.Dialogs,
  FMX.Controls,
  PascalStyleScript,
  Mensagem.Tipos,
  Mensagem.Anexo;

type
  TEditor = class
  private
    FVisible: Boolean;
    lytMensagem: TLayout;
    rtgMensagem: TRectangle;
    mmMensagem: TMemo;
    txtMensagem: TText;
    lytAnexo: TLayout;
    pthAnexo: TPath;
    lytCarinha: TLayout;
    pthCarinha: TPath;
    lytEnviar: TLayout;
    pthEnviar: TPath;
    OpenDialog: TOpenDialog;
    FAdicionar: TProc<TMensagem>;
    FAnexo: TAnexo;
    FAguardandoAnexo: Boolean;
    procedure mmMensagemChangeTracking(Sender: TObject);
    procedure lytAnexoClick(Sender: TObject);
    procedure lytCarinhaClick(Sender: TObject);
    procedure lytEnviarClick(Sender: TObject);
    procedure mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lytMensagemResized(Sender: TObject);
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(AOwner: TFmxObject);
    procedure ConfiguraAnexo(Anexo: TAnexo);
    procedure AdicionaMensagem(Adicionar: TProc<TMensagem>);
    property Visible: Boolean read FVisible write SetVisible;
  end;

implementation

{ TPrevia }

constructor TEditor.Create(AOwner: TFmxObject);
begin 
  lytMensagem := TLayout.Create(AOwner);
  lytMensagem.Align := TAlignLayout.Bottom;
  lytMensagem.Position.Y := 440;
  lytMensagem.Size.Width := 640;
  lytMensagem.Size.Height := 40;
  lytMensagem.Size.PlatformDefault := False;
  lytMensagem.OnResized := lytMensagemResized;

  OpenDialog := TOpenDialog.Create(lytMensagem);
  OpenDialog.Filter := 'Todos|*.*';
  OpenDialog.Options := [TOpenOption.ofHideReadOnly, TOpenOption.ofAllowMultiSelect, TOpenOption.ofEnableSizing, TOpenOption.ofDontAddToRecent];
  OpenDialog.Title := 'Selecionar';

  rtgMensagem := TRectangle.Create(lytMensagem);
  rtgMensagem.Align := TAlignLayout.Client;
  rtgMensagem.Size.Width := 640;
  rtgMensagem.Size.Height := 40;
  rtgMensagem.Size.PlatformDefault := False;
  rtgMensagem.Stroke.Kind := TBrushKind.None;
  rtgMensagem.Fill.Color := TAlphaColors.Gainsboro;

  TPascalStyleScript.Instance.RegisterObject(rtgMensagem, 'Mensagem.Editor.Fundo');

  mmMensagem := TMemo.Create(rtgMensagem);
  mmMensagem.Touch.InteractiveGestures := [TInteractiveGesture.Pan, TInteractiveGesture.LongTap, TInteractiveGesture.DoubleTap];
  mmMensagem.CheckSpelling := True;
  mmMensagem.DataDetectorTypes := [TDataDetectorType.PhoneNumber, TDataDetectorType.Link, TDataDetectorType.Address, TDataDetectorType.CalendarEvent];
  mmMensagem.TextSettings.WordWrap := True;
  mmMensagem.OnChangeTracking := mmMensagemChangeTracking;
  mmMensagem.OnKeyDown := mmMensagemKeyDown;
  mmMensagem.Align := TAlignLayout.Client;
  mmMensagem.Margins.Left := 15;
  mmMensagem.Margins.Top := 10;
  mmMensagem.Margins.Right := 15;
  mmMensagem.Margins.Bottom := 10;
  mmMensagem.Size.Width := 520;
  mmMensagem.Size.Height := 20;
  mmMensagem.Size.PlatformDefault := False;
  mmMensagem.TabOrder := 0;

  txtMensagem := TText.Create(mmMensagem);
  txtMensagem.Align := TAlignLayout.Left;
  txtMensagem.Size.Width := 65;
  txtMensagem.Size.Height := 16;
  txtMensagem.Size.PlatformDefault := False;
  txtMensagem.Text := 'Mensagem';
  txtMensagem.TextSettings.FontColor := $FF545454;
  txtMensagem.TextSettings.HorzAlign := TTextAlign.Leading;
  txtMensagem.HitTest := False;

  lytAnexo := TLayout.Create(rtgMensagem);
  lytAnexo.Align := TAlignLayout.Left;
  lytAnexo.HitTest := True;
  lytAnexo.Size.Width := 41;
  lytAnexo.Size.Height := 40;
  lytAnexo.Size.PlatformDefault := False;
  lytAnexo.OnClick := lytAnexoClick;

  pthAnexo := TPath.Create(lytAnexo);
  pthAnexo.Align := TAlignLayout.Client;
  pthAnexo.Data.Data :=
    'M284.56201171875,164.180999755859 '+
    'L270.325012207031,178.259994506836 '+
    'C267.966003417969,180.593002319336 264.140991210938,180.593002319336 261.782012939453,178.259994506836 '+
    'C259.423004150391,175.927993774414 259.423004150391,172.14599609375 261.782012939453,169.813003540039 '+
    'L274.596008300781,157.141006469727 '+
    'C276.167999267578,155.585998535156 278.717987060547,155.585998535156 280.290985107422,157.141006469727 '+
    'C281.863006591797,158.695999145508 281.863006591797,161.218002319336 280.290985107422,162.772003173828 '+
    'L267.476989746094,175.444000244141 '+
    'C266.691009521484,176.22200012207 265.415985107422,176.22200012207 264.628997802734,175.444000244141 '+
    'C263.842987060547,174.667007446289 263.842987060547,173.406005859375 264.628997802734,172.628005981445 '+
    'L276.019989013672,161.365005493164 '+
    'L274.596008300781,159.957000732422 '+
    'L263.205993652344,171.220993041992 '+
    'C261.632995605469,172.774993896484 261.632995605469,175.296997070313 263.205993652344,176.852996826172 '+
    'C264.778015136719,178.406997680664 267.328002929688,178.406997680664 268.901000976563,176.852005004883 '+
    'L281.713989257813,164.180999755859 '+
    'C284.072998046875,161.848999023438 284.074005126953,158.065002441406 281.714996337891,155.733001708984 '+
    'C279.355010986328,153.399993896484 275.531005859375,153.399993896484 273.171997070313,155.733001708984 '+
    'L259.64599609375,169.108001708984 '+
    'L259.696014404297,169.156997680664 '+
    'C257.238006591797,172.281005859375 257.454986572266,176.796997070313 260.358001708984,179.667999267578 '+
    'C263.261993408203,182.539001464844 267.828002929688,182.753997802734 270.986999511719,180.322998046875 '+
    'L271.036010742188,180.371994018555 '+
    'L285.985992431641,165.589004516602 '+
    'L284.56201171875,164.180999755859 ';
  pthAnexo.Fill.Color := TAlphaColors.Gainsboro;
  pthAnexo.HitTest := False;
  pthAnexo.Margins.Left := 14;
  pthAnexo.Margins.Top := 5;
  pthAnexo.Margins.Right := 8;
  pthAnexo.Margins.Bottom := 5;
  pthAnexo.Size.Width := 19;
  pthAnexo.Size.Height := 30;
  pthAnexo.Size.PlatformDefault := False;
  pthAnexo.Stroke.Kind := TBrushKind.None;
  pthAnexo.WrapMode := TPathWrapMode.Fit;
  TPascalStyleScript.Instance.RegisterObject(pthAnexo, 'Mensagem.Editor.Anexo');

  lytCarinha := TLayout.Create(rtgMensagem);
  lytCarinha.Align := TAlignLayout.Left;
  lytCarinha.HitTest := True;
  lytCarinha.Position.X := 41;
  lytCarinha.Size.Width := 35;
  lytCarinha.Size.Height := 40;
  lytCarinha.Size.PlatformDefault := False;
  lytCarinha.TabOrder := 2;
  lytCarinha.OnClick := lytCarinhaClick;

  pthCarinha := TPath.Create(lytCarinha);
  pthCarinha.Align := TAlignLayout.Client;
  pthCarinha.Data.Data :=
    'M248,8 '+
    'C111,8 0,119 0,256 '+
    'C0,393 111,504 248,504 '+
    'C385,504 496,393 496,256 '+
    'C496,119 385,8 248,8 '+
    'Z '+
    'M248,456 '+
    'C137.699996948242,456 48,366.299987792969 48,256 '+
    'C48,145.700012207031 137.699996948242,56 248,56 '+
    'C358.299987792969,56 448,145.699996948242 448,256 '+
    'C448,366.299987792969 358.299987792969,456 248,456 '+
    'Z '+
    'M168,240 '+
    'C185.699996948242,240 200,225.699996948242 200,208 '+
    'C200,190.300003051758 185.699996948242,176 168,176 '+
    'C150.300003051758,176 136,190.300003051758 136,208 '+
    'C136,225.699996948242 150.300003051758,240 168,240 '+
    'Z '+
    'M328,240 '+
    'C345.700012207031,240 360,225.699996948242 360,208 '+
    'C360,190.300003051758 345.700012207031,176 328,176 '+
    'C310.299987792969,176 296,190.300003051758 296,208 '+
    'C296,225.699996948242 310.299987792969,240 328,240 '+
    'Z '+
    'M332,312.600006103516 '+
    'C311.200012207031,337.600006103516 280.5,352 248,352 '+
    'C215.5,352 184.800003051758,337.700012207031 164,312.600006103516 '+
    'C155.5,302.399993896484 140.300003051758,301.100006103516 130.199996948242,309.5 '+
    'C120,318 118.699996948242,333.100006103516 127.099998474121,343.299987792969 '+
    'C157.100006103516,379.299987792969 201.199996948242,399.899993896484 248,399.899993896484 '+
    'C294.799987792969,399.899993896484 338.899993896484,379.299987792969 368.899993896484,343.299987792969 '+
    'C377.399993896484,333.099975585938 376,318 365.799987792969,309.5 '+
    'C355.699981689453,301.100006103516 340.5,302.399993896484 332,312.600006103516 '+
    'Z ';
  pthCarinha.Fill.Color := TAlphaColors.Gainsboro;
  pthCarinha.HitTest := False;
  pthCarinha.Margins.Left := 8;
  pthCarinha.Margins.Top := 5;
  pthCarinha.Margins.Right := 8;
  pthCarinha.Margins.Bottom := 5;
  pthCarinha.Size.Width := 19;
  pthCarinha.Size.Height := 30;
  pthCarinha.Size.PlatformDefault := False;
  pthCarinha.Stroke.Kind := TBrushKind.None;
  pthCarinha.WrapMode := TPathWrapMode.Fit;
  TPascalStyleScript.Instance.RegisterObject(pthCarinha, 'Mensagem.Editor.Emoji');

  lytEnviar := TLayout.Create(rtgMensagem);
  lytEnviar.Align := TAlignLayout.Right;
  lytEnviar.HitTest := True;
  lytEnviar.Position.X := 605;
  lytEnviar.Size.Width := 35;
  lytEnviar.Size.Height := 40;
  lytEnviar.Size.PlatformDefault := False;
  lytEnviar.TabOrder := 1;
  lytEnviar.OnClick := lytEnviarClick;

  pthEnviar := TPath.Create(lytEnviar);
  pthEnviar.Align := TAlignLayout.Client;
  pthEnviar.Data.Data :=
    'M3.5,14.9899997711182 '+
    'L7.4557900428772,12 '+
    'L4,12 '+
    'L2.02268004417419,4.13538980484009 '+
    'C2.01110005378723,4.08930015563965 2.00192999839783,4.0424599647522 2.00045990943909,3.99497008323669 '+
    'C1.97810995578766,3.27396988868713 2.77208995819092,2.7736599445343 3.46028995513916,3.10387992858887 '+
    'L22,12 '+
    'L3.46028995513916,20.8960990905762 '+
    'C2.77982997894287,21.2226009368896 1.99597001075745,20.7371997833252 2.00002002716064,20.0293006896973 '+
    'C2.00038003921509,19.965799331665 2.01454997062683,19.9032001495361 2.03295993804932,19.8425006866455 '+
    'L3.5,15 ';
  pthEnviar.Fill.Color := TAlphaColors.Gainsboro;
  pthEnviar.HitTest := False;
  pthEnviar.Margins.Left := 8;
  pthEnviar.Margins.Top := 5;
  pthEnviar.Margins.Right := 8;
  pthEnviar.Margins.Bottom := 5;
  pthEnviar.Size.Width := 19;
  pthEnviar.Size.Height := 30;
  pthEnviar.Size.PlatformDefault := False;
  pthEnviar.Stroke.Kind := TBrushKind.None;
  pthEnviar.WrapMode := TPathWrapMode.Fit;
  TPascalStyleScript.Instance.RegisterObject(pthEnviar, 'Mensagem.Editor.Enviar');

  lytMensagem.AddObject(rtgMensagem);
  rtgMensagem.AddObject(lytAnexo);
  rtgMensagem.AddObject(lytCarinha);
  rtgMensagem.AddObject(mmMensagem);
  rtgMensagem.AddObject(lytEnviar);
  lytAnexo.AddObject(pthAnexo);
  lytCarinha.AddObject(pthCarinha);
  lytEnviar.AddObject(pthEnviar);
  mmMensagem.AddObject(txtMensagem);
  AOwner.AddObject(lytMensagem);

  mmMensagem.NeedStyleLookup;
  mmMensagem.ApplyStyleLookup;
  mmMensagem.StylesData['background.Source'] := nil;
end;

procedure TEditor.ConfiguraAnexo(Anexo: TAnexo);
begin
  FAnexo := Anexo;
end;

procedure TEditor.lytAnexoClick(Sender: TObject);
begin
  if not Assigned(FAnexo) then
    raise Exception.Create('Anexo não definido!');

  {TODO -oEduardo -cVisual : Escurecer fundo}

  FAguardandoAnexo := True;

  FAnexo.SelecionarAnexo(
    procedure(Selecionados: TArray<TMensagemConteudo>)
    var
      Mensagem: TMensagem;
    begin
      Mensagem := Default(TMensagem);
      Mensagem.Conteudos := Selecionados;
      FAdicionar(Mensagem);
    end
  );

  FAnexo.CancelarAnexo(
    procedure
    begin
      FAguardandoAnexo := False;
    end
  );
end;

procedure TEditor.lytCarinhaClick(Sender: TObject);
begin
  //
end;

procedure TEditor.lytEnviarClick(Sender: TObject);
var
  Conteudo: TMensagemConteudo;
  Mensagem: TMensagem;
  sMensagem: String;
begin
  sMensagem := mmMensagem.Lines.Text.Trim;
  if sMensagem.IsEmpty then
    Exit;
  Mensagem := Default(TMensagem);
  Conteudo := Default(TMensagemConteudo);
  Conteudo.tipo := 1; // 1-Texto
  Conteudo.conteudo := sMensagem;
  Mensagem.Conteudos := [Conteudo];
  mmMensagem.Lines.Clear;
  FAdicionar(Mensagem);
end;

procedure TEditor.lytMensagemResized(Sender: TObject);
var
  TamanhoTexto: TRectF;
  cHeight: Single;
begin
  if mmMensagem.Width < 50 then
    Exit;

  TamanhoTexto := RectF(0, 0, mmMensagem.Width, 10000);
  mmMensagem.Canvas.MeasureText(TamanhoTexto, mmMensagem.Lines.Text, True, [], TTextAlign.Center, TTextAlign.Leading);
  cHeight := TamanhoTexto.Bottom + mmMensagem.Margins.Top + mmMensagem.Margins.Bottom;
  if cHeight > 40 then
    cHeight := cHeight + 5;
  lytMensagem.Height := Min(212, Max(40, cHeight));
  mmMensagem.ShowScrollBars := lytMensagem.Height > 200;
end;

procedure TEditor.mmMensagemChangeTracking(Sender: TObject);
begin
  txtMensagem.Visible := mmMensagem.Lines.Text.IsEmpty;
  lytMensagemResized(lytMensagem);
end;

procedure TEditor.mmMensagemKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkReturn) and (Shift = []) then
  begin
    Key := 0;
    KeyChar := #0;
    lytEnviarClick(lytEnviar);
  end;
end;

procedure TEditor.AdicionaMensagem(Adicionar: TProc<TMensagem>);
begin
  FAdicionar := Adicionar;
end;

procedure TEditor.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  lytMensagem.Visible := Value;
  FAnexo.Layout.Visible := Value and FAguardandoAnexo;
end;

end.
