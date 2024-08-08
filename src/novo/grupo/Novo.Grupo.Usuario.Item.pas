unit Novo.Grupo.Usuario.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Ani, FMX.Controls.Presentation, FMX.Objects,
  FMX.Layouts,
  FMX.ListBox,
  Conversa.Tipos;

type
  TNovoGrupoUsuarioItem = class(TFrameBase)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    Text1: TText;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    ColorAnimation1: TColorAnimation;
    lytCheck: TLayout;
    pthUncheck: TPath;
    pthChecked: TPath;
    procedure rctFundoClick(Sender: TObject);
  private
    { Private declarations }
    FCheck: Boolean;
    FOnClick: TProc;
    procedure SetCheck(const Value: Boolean);
  public
    { Public declarations }
    Usuario: TUsuario;
    constructor Create(AOwner: TComponent; AUsuario: TUsuario); reintroduce; overload;
    property OnClick: TProc read FOnClick write FOnClick;
    property Check: Boolean read FCheck write SetCheck;
  end;
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    Marcado: Boolean;
    ContatoItem: TNovoGrupoUsuarioItem;
  end;

implementation

{$R *.fmx}

{ TNovoGrupoUsuarioItem }

constructor TNovoGrupoUsuarioItem.Create(AOwner: TComponent; AUsuario: TUsuario);
begin
  inherited Create(AOwner);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Usuario := AUsuario;
  Check := False;
end;

procedure TNovoGrupoUsuarioItem.rctFundoClick(Sender: TObject);
begin
  Check := not Check;
  SetFocus;
end;

procedure TNovoGrupoUsuarioItem.SetCheck(const Value: Boolean);
begin
  FCheck := Value;
  pthUncheck.Visible := not Value;
  pthChecked.Visible := Value;
  TListBoxItem(Parent).Marcado := Value;
  if Assigned(FOnClick) then
    FOnClick;
end;

end.
