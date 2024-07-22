unit Conversa.ModalView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects;

type
  TModalView = class(TFrame)
    rctFundo: TRectangle;
    procedure rctFundoClick(Sender: TObject);
  private
    { Private declarations }
    FModalList: TArray<TFrame>;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure Exibir(const Value: TFrame);
    procedure Ocultar;
  end;

implementation

{$R *.fmx}

{ TModalView }

constructor TModalView.Create(AOwner: TComponent);
begin
  inherited;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Visible := False;
end;

procedure TModalView.Exibir(const Value: TFrame);
begin
  Visible := True;
  BringToFront;

  Value.Parent := rctFundo;
  Value.Align := TAlignLayout.Center;
  Value.BringToFront;

  if Length(FModalList) > 0 then
    FModalList[Pred(Length(FModalList))].Visible := False;

  SetLength(FModalList, Succ(Length(FModalList)));
  FModalList[Pred(Length(FModalList))] := Value;
end;

procedure TModalView.rctFundoClick(Sender: TObject);
begin
  Ocultar;
end;

procedure TModalView.Ocultar;
begin
  if Length(FModalList) > 0 then
  begin
    FModalList[Pred(Length(FModalList))].Visible := False;
    FModalList[Pred(Length(FModalList))].Free;
    SetLength(FModalList, Pred(Length(FModalList)));
  end;

  if Length(FModalList) = 0 then
    Visible := False;
end;

end.
