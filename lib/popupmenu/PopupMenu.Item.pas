unit PopupMenu.Item;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Ani,
  Popup,
  PopupMenu,
  PopupMenu.Item.Base;

type
  TPopupMenuItemFrame = class(TPopupMenuItemBase)
    txtDescricao: TText;
    aniCorFundo: TColorAnimation;
    rctFundo: TRectangle;
    pthSub: TPath;
    tmrExibir: TTimer;
    procedure rctFundoMouseEnter(Sender: TObject);
    procedure rctFundoMouseLeave(Sender: TObject);
    procedure rctFundoClick(Sender: TObject);
    procedure txtDescricaoResized(Sender: TObject);
    procedure tmrExibirTimer(Sender: TObject);
  private
    FSelecionado: Boolean;
  protected
    procedure SetSelecionado(const Value: Boolean); override;
  public
    procedure ExibirSub; override;
    procedure OcultarSub(Force: Boolean); override;
    function PodeOcultar: Boolean; override;
    property Selecionado: Boolean read FSelecionado write SetSelecionado;
  end;

implementation

{$R *.fmx}

procedure TPopupMenuItemFrame.rctFundoClick(Sender: TObject);
begin
  if Assigned(SubMenu) then
    Exit;

  try
    Menu.OcultarMenu(True, True);
  finally
    if Assigned(OnClick) then
      OnClick(Self);
  end;
end;

procedure TPopupMenuItemFrame.rctFundoMouseEnter(Sender: TObject);
begin
  if Assigned(SubMenu) then
    tmrExibir.Enabled := True;

  Selecionado := True;
end;

procedure TPopupMenuItemFrame.rctFundoMouseLeave(Sender: TObject);
begin
  if Selecionado then
  begin
    // Se tem SubMenu, e está exibindo
    if Assigned(SubMenu) and SubMenu.IsMouseOver then
      Exit;

    // Se está com mouse sobre ele mesmo
    if PtInRect(rctFundo.LocalRect.Round, rctFundo.ScreenToLocal(Screen.MousePos).Round) then
      Exit;
  end;

  Selecionado := False;
end;

procedure TPopupMenuItemFrame.SetSelecionado(const Value: Boolean);
begin
  if Value then
  begin
    CanFocus := True;
    SetFocus;
  end;

  if FSelecionado = Value then
    Exit;

  FSelecionado := Value;

  if FSelecionado then
  begin
    aniCorFundo.Inverse := False;
    aniCorFundo.Start;
  end
  else
  begin
    aniCorFundo.Inverse := True;
    aniCorFundo.Start;
    OcultarSub(True);
  end;

  if Assigned(Menu) then
  begin
    if FSelecionado then
      Menu.Selecionar(Self)
    else
      Menu.Selecionar(nil)
  end;
end;

procedure TPopupMenuItemFrame.tmrExibirTimer(Sender: TObject);
begin
  ExibirSub;
end;

procedure TPopupMenuItemFrame.txtDescricaoResized(Sender: TObject);
begin
  if Assigned(Menu) then
    Menu.AtualizarLargura(txtDescricao.Width + rctFundo.Padding.Left + rctFundo.Padding.Right + IfThen(pthSub.Visible, pthSub.Width + 3));
end;

procedure TPopupMenuItemFrame.ExibirSub;
begin
  tmrExibir.Enabled := False;
  if Assigned(SubMenu) and not SubMenu.Visible then
    TPopup(SubMenu).Exibir(Self, [TPopupPosition.RightTop, TPopupPosition.RightBottom, TPopupPosition.LeftTop, TPopupPosition.LeftBottom]);
end;

procedure TPopupMenuItemFrame.OcultarSub(Force: Boolean);
begin
  tmrExibir.Enabled := False;
  if Assigned(SubMenu) and (Force or SubMenu.PodeOcultar) then
  begin
    SubMenu.OcultarMenu(True, False);
    Menu.Activate;
  end;
end;

function TPopupMenuItemFrame.PodeOcultar: Boolean;
begin
  if Assigned(SubMenu) and not SubMenu.PodeOcultar then
    Exit(False);

//  if IsFocused then
//    Exit(False);

  if PtInRect(rctFundo.LocalRect.Round, rctFundo.ScreenToLocal(Screen.MousePos).Round) then
    Exit(False);

  Result := True;
end;

end.
