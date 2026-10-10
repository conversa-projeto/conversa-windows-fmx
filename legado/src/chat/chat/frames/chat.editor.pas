unit chat.editor;

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
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  FMX.VirtualKeyboard,
  FMX.Platform,
  chat.tipos,
  chat.editor.base,
  chat.editor.texto,
  chat.editor.anexo,
  chat.editor.audio;

type
  TChatEditor = class(TFrame)
    rtgFundo: TRectangle;
    rtgEditor: TRectangle;
    lytBotoesAction: TLayout;
    lytBAction: TLayout;
    pthEnviar: TPath;
    pthMicrofone: TPath;
    tmrAction: TTimer;
    procedure lytBActionMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure lytBActionMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure tmrActionTimer(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    FAction: TActionEditor;
    FActionDown: TDateTime;
    FTexto: TChatEditorTexto;
    FAnexo: TChatEditorAnexo;
    FAudio: TChatEditorAudio;
    FLarguraMaximaConteudo: Single;
    FAlturaMinimaEditor: Single;
    FAoEnviar: TEventoEnvio;
    procedure SetAction(const Action: TActionEditor);
    procedure ExecutarAcao;
    procedure SetLarguraMaximaConteudo(const Value: Single);
    procedure SetAlturaMinimaEditor(const Value: Single);
  public
    procedure AfterConstruction; override;
    procedure AtualizarAction;
    procedure SetEditor(const Tipo: TTipoEditor);
    procedure AdicionarAnexo(const Anexo: TFileSelected);
    procedure AtualizarRedimensionamento;
    procedure Enviar;
    procedure Limpar;
    property LarguraMaximaConteudo: Single read FLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property AlturaMinimaEditor: Single read FAlturaMinimaEditor write SetAlturaMinimaEditor;
    property AoEnviar: TEventoEnvio read FAoEnviar write FAoEnviar;
    function ExibindoTecladoVirtual: Boolean;
    function FocoEditorTexto: Boolean;
  end;

implementation

{$R *.fmx}

{ TChatEditor }

procedure TChatEditor.AfterConstruction;
begin
  inherited;
  SetAction(TActionEditor.GravarMensagemAudio);
  SetEditor(TTipoEditor.Texto);
  LarguraMaximaConteudo := 500;
  AlturaMinimaEditor := 46;
end;

procedure TChatEditor.SetAction(const Action: TActionEditor);
begin
  FAction := Action;
  pthEnviar.Visible := Action = TActionEditor.EnviarMensagem;
  pthMicrofone.Visible := Action = TActionEditor.GravarMensagemAudio;
end;

procedure TChatEditor.SetEditor(const Tipo: TTipoEditor);
begin
  if not Assigned(FTexto) and (Tipo = TTipoEditor.Texto) then
    FTexto := TChatEditorTexto.Create(Self);

  if not Assigned(FAudio) and (Tipo = TTipoEditor.Audio) then
    FAudio := TChatEditorAudio.Create(Self);

  // Deve ser alterado antes dos Editores, por algum motivo ainda desconhecido
  // ele faz ocultar o Editor de texto ao finalizar/cancelar um envio de áudio
  lytBotoesAction.Visible := Tipo <> TTipoEditor.Audio;

  if (Tipo = TTipoEditor.Texto) and Assigned(FTexto) and not FTexto.Visible then
    FTexto.Visible := True;

  if Assigned(FAudio) and (Tipo <> TTipoEditor.Audio) then
    FAudio.Visible := False
  else
  if (Tipo = TTipoEditor.Audio) and Assigned(FTexto) and FTexto.Visible and ExibindoTecladoVirtual then
  begin
    FAudio.Align := TAlignLayout.Top;
    FAudio.Visible := Tipo = TTipoEditor.Audio;
    FAudio.lytCapturaAudio.Margins.Bottom := -FAudio.lytCapturaAudio.Height;
  end
  else
  if (Tipo = TTipoEditor.Audio) then
  begin
    FTexto.Visible := False;
    FAudio.lytCapturaAudio.Margins.Bottom := 0;
    FAudio.Align := TAlignLayout.Bottom;
    FAudio.Visible := True;
  end;

  AtualizarRedimensionamento;
end;

procedure TChatEditor.AdicionarAnexo(const Anexo: TFileSelected);
begin
  if not Assigned(FAnexo) then
  begin
    FAnexo := TChatEditorAnexo.Create(Self);
    FAnexo.Align := TAlignLayout.MostTop;
  end;

  FAnexo.AdicionarItem(Anexo);

  AtualizarRedimensionamento;
end;

procedure TChatEditor.AtualizarAction;
begin
  if Assigned(FAnexo) and FAnexo.TemConteudo then
    SetAction(TActionEditor.EnviarMensagem)
  else if Assigned(FAudio) and FAudio.TemConteudo then
    SetAction(TActionEditor.EnviarMensagem)
  else if Assigned(FTexto) and FTexto.TemConteudo then
    SetAction(TActionEditor.EnviarMensagem)
  else
    SetAction(TActionEditor.GravarMensagemAudio)
end;

procedure TChatEditor.Enviar;
var
  Conteudos: TArray<TConteudo>;
begin
  if Assigned(FAoEnviar) then
  begin
    if Assigned(FAnexo) and FAnexo.TemConteudo then
      Conteudos := Conteudos + FAnexo.Conteudos;

    if Assigned(FAudio) and FAudio.TemConteudo then
      Conteudos := Conteudos + [FAudio.Conteudo];

    if Assigned(FTexto) and FTexto.TemConteudo then
      Conteudos := Conteudos + [FTexto.Conteudo];

    if Length(Conteudos) > 0 then
      FAoEnviar(Conteudos);
  end;

  Limpar;
  AtualizarAction;
  AtualizarRedimensionamento;
end;

procedure TChatEditor.Limpar;
begin
  if Assigned(FTexto) then
    FTexto.Limpar;

  if Assigned(FAnexo) then
    FAnexo.Limpar;

  if Assigned(FAudio) then
    FAudio.Limpar;
end;

procedure TChatEditor.lytBActionMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FActionDown := Now;

  if FAction = TActionEditor.GravarMensagemAudio then
    tmrAction.Interval := 250
  else
    tmrAction.Interval := 1000;

  tmrAction.Enabled := True;
end;

procedure TChatEditor.lytBActionMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  tmrAction.Enabled := False;
  if FAction = TActionEditor.EnviarMensagem then
    ExecutarAcao;
end;

procedure TChatEditor.tmrActionTimer(Sender: TObject);
begin
  tmrAction.Enabled := False;
  if FAction = TActionEditor.GravarMensagemAudio then
    ExecutarAcao;
end;

procedure TChatEditor.ExecutarAcao;
begin
  lytBotoesAction.Enabled := False;
  try
    case FAction of
      TActionEditor.EnviarMensagem:
        Enviar;
      TActionEditor.GravarMensagemAudio:
        begin
          SetEditor(TTipoEditor.Audio);
          FAudio.Iniciar;
        end;
    end;
  finally
    lytBotoesAction.Enabled := True;
  end;
end;

procedure TChatEditor.AtualizarRedimensionamento;
var
  NewHeight: Single;
begin
  NewHeight := 0;
  if (Self.Width <> rtgEditor.Width) or (FLarguraMaximaConteudo <> rtgEditor.Width) then
  begin
    if Self.Width <= FLarguraMaximaConteudo then
    begin
      rtgEditor.Corners := [];
      rtgEditor.Width := Self.Width;
    end
    else
    begin
      rtgEditor.Corners := [TCorner.TopLeft, TCorner.TopRight];
      rtgEditor.Width := FLarguraMaximaConteudo;
    end;
  end;

  if Assigned(FTexto) and FTexto.Visible then
  begin
    FTexto.AtualizarRedimensionamento(False);
    NewHeight := NewHeight + FTexto.Height;
  end;

  if Assigned(FAnexo) and FAnexo.Visible then
    NewHeight := NewHeight + FAnexo.Height;

  if Assigned(FAudio) and FAudio.Visible then
    NewHeight := NewHeight + FAudio.Height;

  lytBAction.Height := FAlturaMinimaEditor;
  Self.Height := Max(FAlturaMinimaEditor, NewHeight);
end;

function TChatEditor.FocoEditorTexto: Boolean;
begin
  if Assigned(FTexto) and FTexto.mmMensagem.CanFocus then
  begin
    FTexto.mmMensagem.SetFocus;
    Result := FTexto.mmMensagem.IsFocused;
  end
  else
    Result := False;
end;

procedure TChatEditor.FrameResize(Sender: TObject);
begin
  AtualizarRedimensionamento;
end;

procedure TChatEditor.SetLarguraMaximaConteudo(const Value: Single);
begin
  FLarguraMaximaConteudo := Value;
  AtualizarRedimensionamento;
end;

procedure TChatEditor.SetAlturaMinimaEditor(const Value: Single);
begin
  FAlturaMinimaEditor := Value;
  AtualizarRedimensionamento;
end;

function TChatEditor.ExibindoTecladoVirtual: Boolean;
var
  FService: IFMXVirtualKeyboardService;
begin
  TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(FService));
  Result := Assigned(FService) and (TVirtualKeyboardState.Visible in FService.VirtualKeyboardState);
end;

end.

