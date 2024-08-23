unit Conversa.Tela.Inicial.view;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  Winapi.Windows,
  Winapi.ShellAPI,
  Winapi.Messages,
  Fmx.Platform.Win,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  Conversa.FormularioBase,
  Conversa.Login,
  Conversa.Dados,
  FMX.Objects,
  FMX.Layouts,
  FMX.Ani,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  Conversa.Configuracoes,
  Conversa.Principal,
  Conversa.ModalView,
  Conversa.Visualizador.Midia,
  PascalStyleScript;

type
  TTelaInicial = class(TFormularioBase)
    tmrShow: TTimer;
    procedure FormShow(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    FOldHWND: HWND;
    TrayWnd: HWND;
    TrayIconData: TNotifyIconData;
    TrayIconAdded: Boolean;
    procedure TrayWndProc(var Message: TMessage);
    procedure Iniciar;
    procedure ExibirTelaPrincipal;

    procedure AdicionarTrayIcon;
    procedure RemoverTrayIcon;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure DoConversaClose; override;
  public
    ModalView: TModalView;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoConversaRestore; override;
  end;

var
  TelaInicial: TTelaInicial;

implementation

uses
  Conversa.Windows.Utils,
  Conversa.Conexao.AvisoInicioSistema,
  Conversa.Configurar.Conexao,
  Conversa.Notificacao,
  Conversa.Windows.UserActivity,
  Conversa.Eventos,
  Conversa.Chat.Listagem;

{$R *.fmx}

const
  WM_ICONTRAY = WM_USER + 1;

constructor TTelaInicial.Create(AOwner: TComponent);
begin
  inherited;
  AdicionarTrayIcon;
end;

destructor TTelaInicial.Destroy;
begin
  SalvarPosicaoFormulario(Self);
  RemoverTrayIcon;
  inherited;
end;

procedure TTelaInicial.CreateHandle;
begin
  inherited;
  // Resolve Problemas do FMX
  //   Mover ícone entre monitores na barra de tarefa | https://stackoverflow.com/questions/54184950/icon-on-the-taskbar-does-not-move-to-second-monitor
  //   Form aparecer no "Disponível para SNAP" | https://en.delphipraxis.net/topic/10601-firemonkey-form-not-included-in-also-snap-to-screen/
  // Referência
  //   https://stackoverflow.com/questions/63423266/whats-the-difference-between-setwindowlongptrgwl-hwndparent-and-setparent
  FOldHWND := SetWindowLongPtr(FormToHWND(Self), GWL_HWNDPARENT, 0);
  ShowWindow(Fmx.Platform.Win.ApplicationHWND, SW_HIDE);
end;

procedure TTelaInicial.DestroyHandle;
begin
  SetWindowLongPtr(FormToHWND(Self), GWL_HWNDPARENT, FOldHWND);
  inherited;
end;

procedure TTelaInicial.FormActivate(Sender: TObject);
begin
  inherited;
  if Assigned(Chats) and Assigned(Chats.Chat) then
    Chats.Chat.ValidarVisualizacao;
end;

procedure TTelaInicial.FormShow(Sender: TObject);
begin
  inherited;
  RestaurarPosicaoFormulario(Self);
  ModalView := TModalView.Create(lytClientForm);
  tmrShow.Enabled := True;
end;

procedure TTelaInicial.tmrShowTimer(Sender: TObject);
begin
  inherited;
  tmrShow.Enabled := False;
  Iniciar;
end;

procedure TTelaInicial.Iniciar;
begin
  if TConfigurarConexao.PrecisaConfigurar(Iniciar) then
    Exit;

  if TConexaoFalhaInicio.FalhaConexao(Iniciar) then
    Exit;

  TLogin.New(lytClientForm, ExibirTelaPrincipal);
end;

procedure TTelaInicial.DoConversaClose;
begin
  Close;
//  ShowWindow(FormToHWND(Self), SW_HIDE);
//  HideAppOnTaskbar;
end;

procedure TTelaInicial.DoConversaRestore;
var
  H: HWND;
begin
  H := FormToHWND(Self);

  if IsIconic(H) then
    ShowOnTaskBar
  else
  begin
    SetWindowPos(H, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    SetWindowPos(H, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  end;

  Self.Activate;
end;

procedure TTelaInicial.ExibirTelaPrincipal;
begin
  with TPrincipalView.New(lytClientForm) do
  begin
    lytTitleBarClient.Parent := Self.lytTitleBarClient;
    lytTitleBarClient.Align := TAlignLayout.Client;
    txtUserLetra.Text := Dados.FDadosApp.Usuario.Abreviatura;
  end;
  Dados.CarregarContatos;
  Dados.CarregarConversas;
  Dados.tmrAtualizarMensagens.Enabled := True;
end;

procedure TTelaInicial.AdicionarTrayIcon;
begin
  // https://stackoverflow.com/questions/20109686/fmx-trayicon-message-handling
  TrayWnd := AllocateHWnd(TrayWndProc);
  with TrayIconData do
  begin
    cbSize := SizeOf;
    Wnd := TrayWnd;
    uID := 1;
    uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    uCallbackMessage := WM_ICONTRAY;
    hIcon := GetClassLong(FmxHandleToHWND(self.Handle), GCL_HICONSM);
    StrPCopy(szTip, 'Conversa');
  end;
  Shell_NotifyIcon(NIM_ADD, @TrayIconData);
end;

procedure TTelaInicial.TrayWndProc(var Message: TMessage);
begin
  if Message.MSG = WM_ICONTRAY then
  begin
    if (Message.LParam = WM_LBUTTONDOWN) or (Message.LParam = WM_RBUTTONDOWN) then
    begin
      DoConversaRestore;
      Message.Result := 0;
    end;
  end
  else
    Message.Result := DefWindowProc(TrayWnd, Message.Msg, Message.WParam, Message.LParam);
end;

procedure TTelaInicial.RemoverTrayIcon;
begin
  if TrayIconAdded then
    Shell_NotifyIcon(NIM_DELETE, @TrayIconData);
  DeallocateHWnd(TrayWnd);
end;

end.
