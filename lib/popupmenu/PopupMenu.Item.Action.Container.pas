unit PopupMenu.Item.Action.Container;

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
  FMX.Objects,
  PopupMenu,
  PopupMenu.Item.Base,
  FMX.Layouts, FMX.Effects;

type
  TPopupMenuActions = class(TPopupMenu)
  private
    { Private declarations }
  public
    { Public declarations }
    class function New: TPopupMenuActions;
  end;

var
  PopupMenuActions: TPopupMenuActions;

implementation

{$R *.fmx}

{ TPopupMenuItemActions }

class function TPopupMenuActions.New: TPopupMenuActions;
begin
  Result := TPopupMenuActions.Create(nil);
end;

end.
