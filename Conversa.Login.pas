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
  Conversa.FrameBase, FMX.Layouts;

type
  TLogin = class(TFrameBase)
    edtUsuario: TEdit;
    rctFundo: TRectangle;
    lytCenter: TLayout;
    rctUsuario: TRectangle;
    rctSenha: TRectangle;
    edtSenha: TEdit;
    lytBotaoEntrar: TLayout;
    rctBotaoEntrar: TRectangle;
    txtBotaoEntrar: TText;
    procedure edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure rctBotaoEntrarClick(Sender: TObject);
    procedure edtUsuarioKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
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
      edtUsuario.SetFocus;
    end;
  end;
end;

procedure TLogin.rctBotaoEntrarClick(Sender: TObject);
begin
  Dados.Login(edtUsuario.Text, edtSenha.Text);
  FClose;
  Visible := False;
end;

procedure TLogin.edtUsuarioKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key in [vkReturn, vkTab] then
  begin
    edtSenha.SetFocus;
    Key := vkNone;
  end;
end;

procedure TLogin.edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    rctBotaoEntrar.OnClick(rctBotaoEntrar);
end;

end.

