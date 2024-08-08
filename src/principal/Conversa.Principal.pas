unit Conversa.Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.MultiView, FMX.Layouts, FMX.Objects,

  Conversa.FrameBase,
  Conversa.Chat.Listagem;

type
  TPrincipalView = class(TFrameBase)
    lytClient: TLayout;
    rctMenuLateral: TRectangle;
    rctBotaoContatos: TRectangle;
    txtBotaoContatos: TText;
    pthContatos: TPath;
    lytTitleBarClient: TLayout;
    lytProfileView: TLayout;
    Circle1: TCircle;
    txtUserLetra: TText;
    rctBotaoNovoGrupo: TRectangle;
    txtBotaoNovoGrupo: TText;
    pthBotaoNovoGrupo: TPath;
    procedure Layout2Click(Sender: TObject);
    procedure rctBotaoContatosClick(Sender: TObject);
    procedure rctBotaoNovoGrupoClick(Sender: TObject);
  public
    class function New(AOwner: TFmxObject): TPrincipalView;
    procedure Criar;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Tela.Inicial.view,
  Conversa.Contatos,
  Novo.Grupo;

class function TPrincipalView.New(AOwner: TFmxObject): TPrincipalView;
begin
  Result := TPrincipalView.Create(AOwner);
  Result.Parent := AOwner;
  Result.Align := TAlignLayout.Client;
//  Result.lytClient.Visible := True;
  Result.Visible := True;
//  Result.lytClient.Align := TAlignLayout.Client;
  Result.Criar;
end;

procedure TPrincipalView.rctBotaoContatosClick(Sender: TObject);
begin
  TConversaContatos.ExibirContatos;
end;

procedure TPrincipalView.rctBotaoNovoGrupoClick(Sender: TObject);
begin
  TNovoGrupo.CriarGrupo;
end;

procedure TPrincipalView.Criar;
begin
  TChatListagem.New(lytClient);
end;

procedure TPrincipalView.Layout2Click(Sender: TObject);
begin
//  DesktopView.client
//  if DesktopView. then
//    DesktopView.SetBounds(Screen.WorkAreaRect);


//  if DesktopView.WindowState = TWindowState.wsMaximized then
//    DesktopView.WindowState := TWindowState.wsNormal
//  else
//  if DesktopView.WindowState = TWindowState.wsNormal then
//    DesktopView.WindowState := TWindowState.wsMaximized;
end;

end.
