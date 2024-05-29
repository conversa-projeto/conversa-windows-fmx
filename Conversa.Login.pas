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
  FMX.Objects,
  Conversa.FrameBase;

type
  TLogin = class(TFrameBase)
    rtgCentro: TRectangle;
    edtSenha: TEdit;
    edtLogin: TEdit;
    btnLogin: TButton;
    rctFundo: TRectangle;
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
    with TLogin.Create(TComponent(AParent)) do
    begin
      Parent := AParent;
      FClose := pClose;
      Visible := True;
      Align := TAlignLayout.Client;
      edtLogin.SetFocus;
    end;
  end;
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

