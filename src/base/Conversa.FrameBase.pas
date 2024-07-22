unit Conversa.FrameBase;

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
  PascalStyleScript;

type
  TFrameBase = class(TFrame)
  private
  protected
    function GetPSSClassName: String; virtual;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

{ TFrameBase }

constructor TFrameBase.Create(AOwner: TComponent);
begin
  inherited;
  TPascalStyleScript.Instance.RegisterObject(Self, GetPSSClassName);
end;

function TFrameBase.GetPSSClassName: String;
begin
  Result := ClassName.Substring(1);
end;

end.
