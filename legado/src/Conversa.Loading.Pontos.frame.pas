unit Conversa.Loading.Pontos.frame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Ani, FMX.Objects;

type
  TConversaLoadingPontosFrame = class(TFrame)
    lytgCentro: TGridLayout;
    crclA: TCircle;
    aniA: TColorAnimation;
    crclB: TCircle;
    aniB: TColorAnimation;
    crclC: TCircle;
    aniC: TColorAnimation;
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure Start;
    procedure Stop;
  end;

implementation

{$R *.fmx}

{ TConversaLoadingPontosFrame }

constructor TConversaLoadingPontosFrame.Create(AOwner: TComponent);
begin
  inherited;
  Stop;
end;

procedure TConversaLoadingPontosFrame.Start;
begin
  aniA.Start;
  aniB.Start;
  aniC.Start;
end;

procedure TConversaLoadingPontosFrame.Stop;
begin
  aniA.Stop;
  aniB.Stop;
  aniC.Stop;
end;

end.
