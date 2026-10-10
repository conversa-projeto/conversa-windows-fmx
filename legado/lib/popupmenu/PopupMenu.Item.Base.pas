unit PopupMenu.Item.Base;

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
  PopupMenu;

type
  TPopupMenuItemBase = class(TFrame)
  protected
    FSelecionado: Boolean;
    procedure SetSelecionado(const Value: Boolean); virtual;
  public
    OnClick: TProc<TObject>;
    Menu: TPopupMenu;
    SubMenu: TPopupMenu;

    procedure ExibirSub; virtual;
    procedure OcultarSub(Force: Boolean); virtual;
    function PodeOcultar: Boolean; virtual;
    property Selecionado: Boolean read FSelecionado write SetSelecionado;
  end;

implementation

{$R *.fmx}

{ TPopupMenuItemBase }

procedure TPopupMenuItemBase.ExibirSub;
begin
  // Implementar se necessário
end;

procedure TPopupMenuItemBase.OcultarSub(Force: Boolean);
begin
  // Implementar se necessário
end;

function TPopupMenuItemBase.PodeOcultar: Boolean;
begin
  Result := True;
end;

procedure TPopupMenuItemBase.SetSelecionado(const Value: Boolean);
begin
  FSelecionado := Value;
  Menu.Selecionar(Self);
end;

end.
