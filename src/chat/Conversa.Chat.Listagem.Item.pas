unit Conversa.Chat.Listagem.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts,


  System.StrUtils,
  System.DateUtils,

  Conversa.FrameBase;

type
  TConversasItemFrame = class(TFrameBase)
    rctFundo: TRectangle;
    lhSeparador: TLine;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    imgFoto: TImage;
    Text1: TText;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    lytB: TLayout;
    lblInformacao1: TLabel;
    lblUltimaMensagem: TLabel;
    procedure lblUltimaMensagemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure rctFundoClick(Sender: TObject);
  private
    { Private declarations }
    FID: Integer;
    FUltimaMensagem: TDateTime;
    FOnClick: TProc<Integer>;
//    FNextUpdateDateTime: TDateTime;
    function ConversaFormatDateTime(Value: TDateTime): String;
  public
    { Public declarations }
    class function New(AOwner: TComponent; AID: Integer): TConversasItemFrame; static;
    function ID: Integer;
    function Descricao(Value: string): TConversasItemFrame;
    function Mensagem(Value: string): TConversasItemFrame;
    function UltimaMensagem(Value: TDateTime): TConversasItemFrame;
    function OnClick(Value: TProc<Integer>): TConversasItemFrame;
  end;

implementation

{$R *.fmx}

class function TConversasItemFrame.New(AOwner: TComponent; AID: Integer): TConversasItemFrame;
begin
  Result := TConversasItemFrame.Create(AOwner);
  Result.Parent := TFmxObject(AOwner);
  Result.Align := TAlignLayout.Client;
  Result.FID := AID;
  //Result.ID := AID;
end;

function TConversasItemFrame.OnClick(Value: TProc<Integer>): TConversasItemFrame;
begin
  Result := Self;
  FOnClick := Value;
end;

procedure TConversasItemFrame.rctFundoClick(Sender: TObject);
begin
  FOnClick(FID);
end;

function TConversasItemFrame.Descricao(Value: string): TConversasItemFrame;
begin
  Result := Self;
  lblNome.Text := Value;
end;

function TConversasItemFrame.ID: Integer;
begin
  Result := FID;
end;

procedure TConversasItemFrame.lblUltimaMensagemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
//  if FNextUpdateDateTime > Now then
//  lblUltimaMensagem.OnPaint := nil;
//  try
//    if DaysBetween(FUltimaMensagem, Now) > 0 then
//    begin
//      lblUltimaMensagem.Text := ConversaFormatDateTime(FUltimaMensagem);
//    end;
//  finally
//    lblUltimaMensagem.OnPaint := lblUltimaMensagemPaint;
//  end;
end;

function TConversasItemFrame.Mensagem(Value: string): TConversasItemFrame;
begin
  Result := Self;
  lblInformacao1.Text := Value;
end;

function TConversasItemFrame.UltimaMensagem(Value: TDateTime): TConversasItemFrame;
begin
  Result := Self;
  FUltimaMensagem := Value;
  lblUltimaMensagem.Text := ConversaFormatDateTime(FUltimaMensagem);
end;

function TConversasItemFrame.ConversaFormatDateTime(Value: TDateTime): String;
var
  Between: Int64;
begin
  Between := SecondsBetween(Value, Now);
  if Between = 0 then
    Exit('agora');

  if Between <= SecsPerMin then
    Exit(Between.ToString +' segundo'+ IfThen(Between = 1, '', 's') +' atr�s');

  Between := MinutesBetween(Value, Now);
  if Between <= MinsPerHour then
    Exit(Between.ToString +' minuto'+ IfThen(Between = 1, '', 's') +' atr�s');

  Between := HoursBetween(Value, Now);
  if Between <= HoursPerDay then
    Exit(Between.ToString +' hora'+ IfThen(Between = 1, '', 's') +' atr�s');

  Between := DaysBetween(Value, Now);
  if Between = 1 then
    Exit('ontem')
  else
  if YearOf(Value) = YearOf(Now) then
    Exit(FormatDateTime(FormatSettings.ShortDateFormat.Replace('y', '').Trim([FormatSettings.DateSeparator]), Value))
  else
    Exit(DateToStr(Value))
end;

end.