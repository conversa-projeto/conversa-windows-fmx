// Eduardo - 04/08/2024
unit chat.conteudo.imagem;

interface

uses
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  FMX.Skia,
  chat.mensagem.conteudo;

type
  TChatConteudoImagem = class(TChatConteudo)
  private
    FComponente: TControl;
    FWidth: Single;
    FHeight: Single;
    function GetImageMargins: TBounds;
  public
    function Target(Largura: Single): TTarget; override;
    procedure LoadFromFile(sFile: String);
    property ImageMargins: TBounds read GetImageMargins;
    property ImageWidth: Single read FWidth;
    property ImageHeight: Single read FHeight;
    function Bitmap: TBitmap;
  end;

implementation

uses
  System.Math,
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.UITypes,
  System.IOUtils;

{$R *.fmx}

{ TConteudoImagem }

function TChatConteudoImagem.GetImageMargins: TBounds;
begin
  Result := FComponente.Margins;
end;

procedure TChatConteudoImagem.LoadFromFile(sFile: String);
var
  SkImage: ISkImage;
  ss: TStringStream;
  Buff: TBytes;
  sTipo: String;
begin
  sTipo := ExtractFileExt(sFile);
  if sTipo.Trim.IsEmpty then
  begin
    ss := TStringStream.Create;
    try
      ss.LoadFromFile(sFile);
      ss.Position := 0;
      SetLength(Buff, 4);
      ss.Read(Buff, 4);
      if (Buff[1] = Ord('P')) and (Buff[2] = Ord('N')) and (Buff[3] = Ord('G')) then
        sTipo := 'png'
      else
      if (Buff[0] = Ord('G')) and (Buff[1] = Ord('I')) and (Buff[2] = Ord('F')) then
        sTipo := 'gif'
      else
      if (Buff[1] = Ord('B')) and (Buff[2] = Ord('M')) then
        sTipo := 'bmp'
    finally
      FreeAndNil(ss);
    end;
  end;
  sTipo := sTipo.ToLower;

  if MatchStr(sTipo.Replace('.', '').ToLower, ['lottie', 'tgs', 'gif', 'webp', 'svg']) then
  begin
    if sTipo.Equals('.svg') then
    begin
      FComponente := TSkSvg.Create(Self);
      TSkSvg(FComponente).Svg.Source := TFile.ReadAllText(sFile);
      FWidth  := TSkSvg(FComponente).Svg.OriginalSize.Width;
      FHeight := TSkSvg(FComponente).Svg.OriginalSize.Height;
    end
    else
    begin
      FComponente := TSkAnimatedImage.Create(Self);
      TSkAnimatedImage(FComponente).LoadFromFile(sFile);
      SkImage := TSkImage.MakeFromEncoded(TSkAnimatedImage(FComponente).Source.Data);
      FWidth  := SkImage.Width;
      FHeight := SkImage.Height;
    end;
  end
  else
  begin
    FComponente := TImage.Create(Self);
    TImage(FComponente).Bitmap.LoadFromFile(sFile);
    FWidth  := TImage(FComponente).Bitmap.Width;
    FHeight := TImage(FComponente).Bitmap.Height;
  end;

  FComponente.HitTest := False;
  FComponente.Align := TAlignLayout.Client;
  FComponente.Cursor := crHandPoint;
  FComponente.Margins.Top := 3;
  FComponente.Size.PlatformDefault := False;
  Self.AddObject(FComponente);
end;

function TChatConteudoImagem.Bitmap: TBitmap;
begin
  Result := nil;
  if FComponente.InheritsFrom(TImage) then
    Result := TImage(FComponente).Bitmap;
end;

function TChatConteudoImagem.Target(Largura: Single): TTarget;
var
  Proporcao: Single;
begin
  Proporcao := Min(Largura / ImageWidth, Max(30, ImageHeight) / ImageHeight);
  Result.Width := Max(100, Round(ImageWidth * Proporcao));
  Result.Height := Round(ImageHeight * Proporcao);
end;

end.
