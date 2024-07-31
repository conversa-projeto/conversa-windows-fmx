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
  Conversa.Conversas.Listagem,
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
    Button1: TButton;
    procedure FormShow(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    TrayWnd: HWND;
    TrayIconData: TNotifyIconData;
    TrayIconAdded: Boolean;
    procedure TrayWndProc(var Message: TMessage);
    procedure Iniciar;
    procedure ExibirTelaPrincipal;

    procedure AdicionarTrayIcon;
    procedure RemoverTrayIcon;
  protected
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
  Conversa.Conexao.AvisoInicioSistema,
  Conversa.Configurar.Conexao,
  Conversa.Notificacao,
  Conversa.Chat.Listagem;

{$R *.fmx}

const
  WM_ICONTRAY = WM_USER + 1;

procedure HideAppOnTaskbar;
var
  hAppWnd: HWND;
  ExStyle: LongInt;
begin
  hAppWnd := Fmx.Platform.Win.ApplicationHWND;
  ShowWindow(hAppWnd, SW_HIDE);
  ExStyle := GetWindowLongPtr(hAppWnd, GWL_EXSTYLE);
  SetWindowLongPtr(hAppWnd, GWL_EXSTYLE, (ExStyle and not WS_EX_APPWINDOW) or WS_EX_TOOLWINDOW);
end;

procedure ShowAppOnTaskbar;
var
  hAppWnd: HWND;
  ExStyle: LongInt;
begin
  hAppWnd := FMX.Platform.Win.ApplicationHWND;
  if IsWindowVisible(hAppWnd) then
    Exit; // Se a janela já estiver visível, não faz nada

  ShowWindow(hAppWnd, SW_HIDE); // Oculta a janela temporariamente para aplicar as alterações
  ExStyle := GetWindowLongPtr(hAppWnd, GWL_EXSTYLE);
  SetWindowLongPtr(hAppWnd, GWL_EXSTYLE, (ExStyle and not WS_EX_TOOLWINDOW) or WS_EX_APPWINDOW);
  ShowWindow(hAppWnd, SW_SHOW); // Mostra a janela novamente
end;

procedure TTelaInicial.Button1Click(Sender: TObject);
begin
  inherited;
  TVisualizadorMidia.Exibir(nil);
end;

constructor TTelaInicial.Create(AOwner: TComponent);
begin
  inherited;
//  Button1.Visible := False;
  AdicionarTrayIcon;
end;

destructor TTelaInicial.Destroy;
begin
  RemoverTrayIcon;
  inherited;
end;

procedure TTelaInicial.FormActivate(Sender: TObject);
begin
  inherited;
  ShowAppOnTaskbar;
  if Assigned(Chats) and Assigned(Chats.Chat) then
    Chats.Chat.ValidarVisualizacao;
end;

procedure TTelaInicial.FormShow(Sender: TObject);
begin
  inherited;
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
begin
  ShowAppOnTaskbar;
  ShowWindow(FormToHWND(Self), SW_SHOW);
  BringToFront;
end;

procedure TTelaInicial.ExibirTelaPrincipal;
begin
  with TPrincipalView.New(lytClientForm) do
  begin
    lytTitleBarClient.Parent := Self.lytTitleBarClient;
    lytTitleBarClient.Align := TAlignLayout.Client;
    txtUserLetra.Text := Dados.Nome[1];
  end;
  Dados.Conversas;
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
