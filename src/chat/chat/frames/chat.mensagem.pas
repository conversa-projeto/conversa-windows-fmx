// Eduardo - 03/08/2024
unit chat.mensagem;

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Objects,
  FMX.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.Forms,
  FMX.Graphics,
  FMX.Ani,
  chat.tipos,
  chat.so,
  chat.base,
  chat.mensagem.conteudo;

type
  TChatMensagem = class(TChatBase)
    lytLargura: TLayout;
    rtgFundo: TRectangle;
    txtNome: TText;
    lytBottom: TLayout;
    txtHora: TText;
    pthStatus: TPath;
    procedure FrameResized(Sender: TObject);
    procedure FramePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    FID: Integer;
    FConteudos: TArray<TChatConteudo>;
    FStatus: TStatus;
    FNome: String;
    FDataEnvio: TDateTime;
    FNomeVisivel: Boolean;
    FVisualizada: Boolean;
    FAoVisualizar: TEvento;
    function GetLado: TLado;
    procedure SetLado(const Value: TLado);
    procedure SetStatus(const Value: TStatus);
    procedure SetNomeVisivel(const Value: Boolean);
    function GetNomeVisivel: Boolean;
    procedure SetNome(const Value: String);
    procedure SetVisualizada(const Value: Boolean);
    function CorFundo(const Value: TLado): TAlphaColor;
    procedure SetDataEnvio(const Value: TDateTime);
  public
    constructor Create(AOwner: TComponent; AID: Integer); reintroduce;
    procedure AfterConstruction; override;
    property ID: Integer read FID;
    property Lado: TLado read GetLado write SetLado;
    property Status: TStatus read FStatus write SetStatus;
    property Nome: String read FNome write SetNome;
    property DataEnvio: TDateTime read FDataEnvio write SetDataEnvio;
    property NomeVisivel: Boolean read GetNomeVisivel write SetNomeVisivel;
    property Visualizada: Boolean read FVisualizada write SetVisualizada;
    property AoVisualizar: TEvento read FAoVisualizar write FAoVisualizar;
    procedure AddConteudo(Conteudo: TChatConteudo);
    procedure Piscar(Cor: TAlphaColor; Tempo: Single = 0.2);
  end;

implementation

uses
  System.Math,
  System.SysUtils;

{$R *.fmx}

constructor TChatMensagem.Create(AOwner: TComponent; AID: Integer);
begin
  inherited Create(AOwner);
  FID := AID;
end;

procedure TChatMensagem.AfterConstruction;
begin
  inherited;
  FNomeVisivel := True;
  FVisualizada := False;
end;

function TChatMensagem.GetLado: TLado;
begin
  Result := TLado(lytLargura.Align);
end;

function TChatMensagem.CorFundo(const Value: TLado): TAlphaColor;
begin
  case Value of
    TLado.Direito:  Result := $FFCFE7FF;
    TLado.Esquerdo: Result := $FFEDEDED;
  else
    Result := 0;
  end;
end;

procedure TChatMensagem.SetDataEnvio(const Value: TDateTime);
begin
  FDataEnvio := Value;
  txtHora.Text := FormatDateTime('hh:nn', Value);
end;

procedure TChatMensagem.SetLado(const Value: TLado);
begin
  lytLargura.Align := TAlignLayout(Value);

  SetStatus(Status);

  case Value of
    TLado.Direito:
    begin
      Self.Margins.Left  := 30;
      Self.Margins.Right := 0;
    end;
    TLado.Esquerdo:
    begin
      Self.Margins.Left  := 0;
      Self.Margins.Right := 30;
    end;
  end;

  rtgFundo.Fill.Color := CorFundo(Value);
end;

procedure TChatMensagem.SetStatus(const Value: TStatus);
begin
  FStatus := Value;

  case Lado of
    TLado.Direito:
    begin
      case Value of
      TStatus.Pendente:
      begin
        pthStatus.Data.Data := 'M382,-240 L154,-468 L211,-525 L382,-354 L749,-721 L806,-664 L382,-240 Z';
        pthStatus.Fill.Color := TAlphaColors.Gray;
        pthStatus.Size.Width := 10;
        pthStatus.Size.Height := 10;
      end;
      TStatus.Recebida:
      begin
        pthStatus.Data.Data :=
          'M268,-240 L42,-466 L99,-522 L269,-352 L325,-296 L268,-240 Z M494,-240 L268,-466 '+
          'L324,-523 L494,-353 L862,-721 L918,-664 L494,-240 Z M494,-466 L437,-522 L635,-720 L692,-664 L494,-466 Z';
        pthStatus.Fill.Color := TAlphaColors.Gray;
        pthStatus.Size.Width := 14;
        pthStatus.Size.Height := 14;
      end;
      TStatus.Visualizada:
      begin
        pthStatus.Data.Data :=
          'M268,-240 L42,-466 L99,-522 L269,-352 L325,-296 L268,-240 Z M494,-240 L268,-466 '+
          'L324,-523 L494,-353 L862,-721 L918,-664 L494,-240 Z M494,-466 L437,-522 L635,-720 L692,-664 L494,-466 Z';
        pthStatus.Fill.Color := $FF007DFF;
        pthStatus.Size.Width := 14;
        pthStatus.Size.Height := 14;
      end;
    end;
    end;
    TLado.Esquerdo:
    begin
      pthStatus.Data.Data := '';
      pthStatus.Size.Width := 1;
    end;
  end;
end;

function TChatMensagem.GetNomeVisivel: Boolean;
begin
  Result := FNomeVisivel;
end;

procedure TChatMensagem.SetNome(const Value: String);
begin
  FNome := Value;
  SetNomeVisivel(FNomeVisivel);
end;

procedure TChatMensagem.SetNomeVisivel(const Value: Boolean);
begin
  FNomeVisivel := Value;
  if FNomeVisivel then
  begin
    txtNome.Text := FNome;
    txtNome.Height := 22;
  end
  else
  begin
    txtNome.Text := '';
    txtNome.Height := 5;
  end;

  FrameResized(Self);
end;

procedure TChatMensagem.SetVisualizada(const Value: Boolean);
begin
  FVisualizada := Value;
  if Assigned(AoVisualizar) then
    AoVisualizar(Self);
end;

procedure TChatMensagem.AddConteudo(Conteudo: TChatConteudo);
begin
  FConteudos := FConteudos + [Conteudo];
  rtgFundo.AddObject(Conteudo);
end;

procedure TChatMensagem.Piscar(Cor: TAlphaColor; Tempo: Single);
begin
  rtgFundo.Fill.Color := Cor;
  TAnimator.StopPropertyAnimation(rtgFundo, 'Fill.Color');
  TAnimator.AnimateColor(rtgFundo, 'Fill.Color', CorFundo(Lado), Tempo, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TChatMensagem.FrameResized(Sender: TObject);
var
  Target: TTarget;
  Conteudo: TChatConteudo;
  iSomaAltura: Single;
  iMaxLargura: Single;
  Largura: Single;
begin
  if Length(FConteudos) = 0 then
    Exit;

  iSomaAltura := 0;
  iMaxLargura := 0;

  Largura := Self.Width - lytLargura.Margins.Left - lytLargura.Margins.Right;

  for Conteudo in FConteudos do
  begin
    Target := Conteudo.Target(Largura);
    iSomaAltura := iSomaAltura + Target.Height;
    iMaxLargura := Max(iMaxLargura, Min(Target.Width, Largura));
    Conteudo.Height := Target.Height;
  end;

  if txtNome.Visible then
  begin
    iSomaAltura := iSomaAltura + txtNome.Height;
    iMaxLargura := Max(iMaxLargura, txtNome.Canvas.TextWidth(txtNome.Text) + txtNome.Margins.Left + txtNome.Margins.Right);
  end;

  iMaxLargura := Max(iMaxLargura, lytBottom.Margins.Left + lytBottom.Margins.Right + txtHora.Canvas.TextWidth(txtHora.Text) + pthStatus.Width);

  iSomaAltura := iSomaAltura + txtHora.Height;

  lytLargura.Width := iMaxLargura;
  Self.Height := iSomaAltura;
end;

procedure TChatMensagem.FramePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  inherited;
  if not Visualizada {$IFDEF MSWINDOWS} and IsFormActive(Self) {$ENDIF} then
    Visualizada := True;
end;

end.
