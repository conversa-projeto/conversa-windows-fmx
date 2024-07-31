unit Conversa.Visualizador.Midia.Windows;

interface

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  Winapi.Messages,
  Winapi.Windows,
  Winapi.Dwmapi,
  FMX.Ani,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.Platform.Win,
  FMX.Types,
  PascalStyleScript,
  Conversa.Visualizador.Midia;

type
  TVisualizadorMidiaWindows = class(TForm)
  private
    procedure DoOnCloseView(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  protected
    procedure CreateHandle; override;
  public
    class procedure Exibir(View: TVisualizadorMidia);
  end;

implementation

uses
  FMX.Helpers.Win,
  FMX.Forms.Border.Win,
  Conversa.Notificacao.Visualizador,
  Conversa.Windows.Utils;


class procedure TVisualizadorMidiaWindows.Exibir(View: TVisualizadorMidia);
var
  Form: TVisualizadorMidiaWindows;
begin
  Form := TVisualizadorMidiaWindows.CreateNew(nil);
  Form.OnClose := Form.FormClose;
  Form.Transparency := True;
  Form.WindowState := TWindowState.wsMaximized;
  Form.BorderStyle := TFmxFormBorderStyle.None;
  View.lytTitleBar.Visible := False;
  View.Parent := Form;
  View.OnClose := Form.DoOnCloseView;
  Form.AddObject(View);
  Form.Show;
end;

procedure TVisualizadorMidiaWindows.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TVisualizadorMidiaWindows.CreateHandle;
var
  Wnd: HWND;
begin
  inherited;
  Wnd := FormToHWND(Self);
  // WS_EX_LAYERED é adicionado ao estilo da janela para permitir a transparência em janelas no Windows.
  // WS_EX_TOOLWINDOW é adicionado ao estilo da janela para torná-la uma janela de ferramenta, que não aparece na barra de tarefas.
  SetWindowLong(Wnd, GWL_EXSTYLE, GetWindowLong(Wnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_APPWINDOW);
end;

procedure TVisualizadorMidiaWindows.DoOnCloseView(Sender: TObject);
begin
  FreeAndNil(Self);
end;

end.
