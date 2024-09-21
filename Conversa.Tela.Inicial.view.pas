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
  Conversa.Eventos,
  PascalStyleScript;

type
  TTelaInicial = class(TFormularioBase)
    tmrShow: TTimer;
    rctAvisoConexao: TRectangle;
    txtAvisoConexao: TText;
    procedure FormShow(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
  private
    FOldHWND: HWND;
    TrayWnd: HWND;
    TrayIconData: TNotifyIconData;
    TrayIconAdded: Boolean;
    procedure TrayWndProc(var Message: Winapi.Messages.TMessage);
    procedure Iniciar;
    procedure ExibirTelaPrincipal;

    procedure AdicionarTrayIcon;
    procedure RemoverTrayIcon;
    procedure StatusConexao(const Sender: TObject; const M: Conversa.Eventos.TMessage);
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
  Conversa.Chat.Listagem;

{$R *.fmx}

const
  WM_ICONTRAY = WM_USER + 1;

constructor TTelaInicial.Create(AOwner: TComponent);
begin
  inherited;
  rctAvisoConexao.Visible := False;
  TMessageManager.DefaultManager.SubscribeToMessage(TEventoStatusConexao, StatusConexao);
  AdicionarTrayIcon;

  if (Configuracoes.Escala <> 0) and (Configuracoes.Escala <> lytClient.Scale.X) then
  begin
    lytClient.Scale.X := Configuracoes.Escala;
    lytClient.Scale.Y := Configuracoes.Escala;
  end;
end;

destructor TTelaInicial.Destroy;
begin
  SalvarPosicaoFormulario(Self);
  RemoverTrayIcon;
  TMessageManager.DefaultManager.Unsubscribe(TEventoStatusConexao, StatusConexao);
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

procedure TTelaInicial.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  if not (ssCtrl in Shift) then
    Exit;

  if WheelDelta > 0 then
  begin
    if lytClient.Scale.X > 1.5 then
      Exit;

    lytClient.Scale.X := lytClient.Scale.X + 0.1;
    lytClient.Scale.Y := lytClient.Scale.Y + 0.1;

    Width := Width + 10;
  end
  else
  begin
    if lytClient.Scale.X < 0.5 then
      Exit;

    lytClient.Scale.X := lytClient.Scale.X - 0.1;
    lytClient.Scale.Y := lytClient.Scale.Y - 0.1;

    Width := Width - 10;
  end;

  Configuracoes.Escala := lytClient.Scale.X;
  Configuracoes.Save;

  Application.ProcessMessages;
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
  {$IFDEF DEBUG}
  Close;
  {$ELSE}
  ShowWindow(FormToHWND(Self), SW_HIDE);
  {$ENDIF}
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

procedure TTelaInicial.TrayWndProc(var Message: Winapi.Messages.TMessage);
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

procedure TTelaInicial.StatusConexao(const Sender: TObject; const M: Conversa.Eventos.TMessage);
begin
  rctAvisoConexao.Visible := TEventoStatusConexao(M).Value <> 1;
end;

end.
