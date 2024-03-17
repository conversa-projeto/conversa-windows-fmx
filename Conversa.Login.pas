// Eduardo - 03/03/2024
unit Conversa.Login;

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
  FMX.Controls.Presentation,
  FMX.Edit,
  FMX.Objects;

type
  TLogin = class(TFrame)
    rtgCentro: TRectangle;
    edtSenha: TEdit;
    edtLogin: TEdit;
    btnLogin: TButton;
    rtgFundo: TRectangle;
    Image1: TImage;
    procedure edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure btnLoginClick(Sender: TObject);
  private
    FClose: TProc;
  public
    class procedure New(AParent: TFmxObject; pClose: TProc);
  end;

implementation

uses
  Conversa.Dados;

var
  Login: TLogin;

{$R *.fmx}

{ TLogin }

class procedure TLogin.New(AParent: TFmxObject; pClose: TProc);
begin
  if not Assigned(Login) then
  begin
    Login := TLogin.Create(Application);
    Login.Parent := AParent;
  end;

  Login.FClose := pClose;
  Login.Visible := True;
  Login.edtLogin.SetFocus;
end;

procedure TLogin.edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    btnLogin.OnClick(btnLogin);
end;

procedure TLogin.btnLoginClick(Sender: TObject);
begin
  Dados.Login(edtLogin.Text, edtSenha.Text);
  FClose;
  Visible := False;
end;

end.

