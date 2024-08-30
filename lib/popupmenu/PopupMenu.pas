unit PopupMenu;

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
  FMX.Layouts,
  FMX.Objects,
  FMX.Ani,
  Popup, FMX.Effects;

type
  TPopupPosition = Popup.TPopupPosition;
  TPopupMenu = class(TPopup)
    lytItems: TLayout;
    rctFundo: TRectangle;
    ShadowEffect1: TShadowEffect;
  private
    FOwnerView: TPopupMenu;
    FSizeSave: TSizeF;
    FSelecionado: TFrame;
    procedure InternalAdd(Item: TFrame);
  protected
    ParentItem: TFrame;
    procedure InternalExibir(APos: TPointF); override;
  public
    class function New(AContainer: TFmxObject = nil): TPopupMenu;
    function Add(const ADescricao: String; AOnClick: TProc<TObject>): TPopupMenu; overload;
    function Add(const ADescricao: String; AMenu: TPopupMenu): TPopupMenu; overload;
    function Add(AItem: TFrame): TPopupMenu; overload;
    function AddSeparador: TPopupMenu;
    procedure Selecionar(const AItem: TFrame);
    procedure Ocultar; overload; override;
    procedure OcultarMenu(Force: Boolean; Cascade: Boolean); reintroduce; overload;
    function PodeOcultar: Boolean; override;
    procedure AtualizarLargura(NovaLargura: Single);
    function ExibindoSubMenu: Boolean;
    function IsMouseOver: Boolean;
    procedure Activate; override;
  end;

implementation

{$R *.fmx}

uses
  System.Math,
  Winapi.Windows,
  FMX.Platform.Win,
  PopupMenu.Item.Base,
  PopupMenu.Item,
  PopupMenu.Item.Separador;

type
  TPopupMenuH = class Helper for TPopupMenu
    function Selecionado: TPopupMenuItemBase;
  end;

{ TPopupMenu }

class function TPopupMenu.New(AContainer: TFmxObject = nil): TPopupMenu;
begin
  Sleep(1);
  Result := TPopupMenu.Create(AContainer);
  Result.FTarget := AContainer;
  Result.Name := 'TPopupMenu_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
  Result.CanFocus := True;
  Result.Visible := False;
  Result.Height := 6 + 20;
  Result.FSizeSave.Height := Result.Height;
  Result.FSizeSave.Width := Result.Width;
end;

function TPopupMenu.Add(const ADescricao: String; AOnClick: TProc<TObject>): TPopupMenu;
var
  Item: TPopupMenuItemFrame;
begin
  Result := Self;

  Item := TPopupMenuItemFrame.Create(lytItems);
  Item.Menu := Self;
  Item.txtDescricao.Text := ADescricao;
  Item.pthSub.Visible := False;
  Item.OnClick := AOnClick;

  InternalAdd(Item);
end;

function TPopupMenu.Add(const ADescricao: String; AMenu: TPopupMenu): TPopupMenu;
var
  Item: TPopupMenuItemFrame;
begin
  Result := Self;
  AMenu.Parent := Self;
  AMenu.FTarget := Self;
  AMenu.FOwnerView := Self;

  Item := TPopupMenuItemFrame.Create(lytItems);
  Item.Menu := Self;
  Item.SubMenu := AMenu;
  Item.txtDescricao.Text := ADescricao;
  Item.pthSub.Visible := True;
  AMenu.ParentItem := Item;
  InternalAdd(Item);
end;

procedure TPopupMenu.Activate;
begin
  inherited;
  if Assigned(ParentItem) then
    TPopupMenuItemBase(ParentItem).SetFocus;
end;

function TPopupMenu.Add(AItem: TFrame): TPopupMenu;
begin
  Result := Self;
  InternalAdd(AItem);
end;

function TPopupMenu.AddSeparador: TPopupMenu;
begin
  Result := Self;
  InternalAdd(TPopupMenuItemSeparador.Create(lytItems));
end;

procedure TPopupMenu.Ocultar;
begin
  if PodeOcultar then
    OcultarMenu(True, True);
end;

procedure TPopupMenu.OcultarMenu(Force: Boolean; Cascade: Boolean);
var
  I: Integer;
begin
   if not Force and not PodeOcultar then
    Exit;

  for I := 0 to Pred(lytItems.ControlsCount) do
    TPopupMenuItemBase(lytItems.Controls[I]).OcultarSub(True);

  Parent := FTarget;
  TAnimator.AnimateFloat(Self, 'Opacity', 0, 0.05);
  Visible := False;

//  if Cascade and Assigned(FOwnerView) then
//    FOwnerView.OcultarMenu(Force, Cascade);

  inherited Ocultar;
end;

function TPopupMenu.ExibindoSubMenu: Boolean;
begin
  Result := False;
  if Assigned(FSelecionado) and Assigned(Selecionado.SubMenu) then
    if Selecionado.SubMenu.Visible then
      Exit(True);
end;

procedure TPopupMenu.InternalAdd(Item: TFrame);
begin
  if Item.InheritsFrom(TPopupMenuItemBase) then
    TPopupMenuItemBase(Item).Menu := Self;

  Item.Parent := lytItems;
  Item.Align := TAlignLayout.Top;
  Sleep(1);
  Item.Name := 'TPopupMenuItemFrame_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
  Self.Height := Self.Height + Item.Height;
  FSizeSave.Height := Height;

  if lytItems.Controls.Count > 0 then
    Item.Position.Y := lytItems.Controls.Last.Position.Y + Self.Height + 100;
end;

procedure TPopupMenu.InternalExibir(APos: TPointF);
begin
  Opacity := 0;
  Visible := True;
  inherited;
  TAnimator.AnimateFloat(Self, 'Opacity', 1, 0.05);
  CanFocus := True;

  if (lytItems.ControlsCount > 0) and Assigned(lytItems.Controls[0]) and lytItems.Controls[0].InheritsFrom(TPopupMenuItemBase) then
    TPopupMenuItemBase(lytItems.Controls[0]).Selecionado := True;

  SetFocus;

end;

function TPopupMenu.IsMouseOver: Boolean;
begin
  Result := PtInRect(lytItems.LocalRect.Round, lytItems.ScreenToLocal(Screen.MousePos).Round);
end;

procedure TPopupMenu.AtualizarLargura(NovaLargura: Single);
begin
  if NovaLargura <= Self.Width then
    Exit;

  Self.Width := Round(NovaLargura) + 20;
  FSizeSave.Width := NovaLargura;
end;

function TPopupMenu.PodeOcultar: Boolean;
var
  I: Integer;
begin
  if not Visible then
    Exit(True);

  for I := 0 to Pred(lytItems.ControlsCount) do
    if Assigned(lytItems.Controls[I]) and lytItems.Controls[I].InheritsFrom(TPopupMenuItemBase) then
      if not TPopupMenuItemBase(lytItems.Controls[I]).PodeOcultar then
        Exit(False);

  Result := (not IsFocused) and not PtInRect(rctFundo.LocalRect.Round, rctFundo.ScreenToLocal(Screen.MousePos).Round);
end;

procedure TPopupMenu.Selecionar(const AItem: TFrame);
var
  Old: TFrame;
begin
  if FSelecionado = AItem then
    Exit;

  try
    Old := FSelecionado;
    FSelecionado := nil;

    if Assigned(Old) and Old.InheritsFrom(TPopupMenuItemBase) then
    begin
      if Assigned(TPopupMenuItemBase(Old).SubMenu) then
        TPopupMenuItemBase(Old).SubMenu.OcultarMenu(True, False);

      TPopupMenuItemBase(Old).Selecionado := False;
    end;

  finally
    FSelecionado := AItem;
  end;
end;

{ TPopupMenuH }

function TPopupMenuH.Selecionado: TPopupMenuItemBase;
begin
  Result := TPopupMenuItemBase(FSelecionado);
end;

end.
