unit Conversa.Notificacao.Visualizador;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Platform.Win,
  Winapi.Windows,
  FMX.Controls.Presentation,
  FMX.Edit,
  System.Math,
  Winapi.Messages,
  Conversa.Notificacao;

type
  TNotificacaoVisualizador = class(TForm)
  protected
    procedure CreateHandle; override;
  public
    procedure Exibir(const Altura: Single);
    procedure Ocultar;
    procedure AtualizarPosicao(iAltura: Single);
  end;

implementation

{$R *.fmx}

procedure TNotificacaoVisualizador.Exibir(const Altura: Single);
begin
  if Altura = 0 then
  begin
    Ocultar;
    Exit;
  end;
  AtualizarPosicao(Altura);
  // Exibir sem Recebor Foco
  ShowWindow(WindowHandleToPlatform(Handle).Wnd, SW_SHOWNOACTIVATE);
end;

procedure TNotificacaoVisualizador.Ocultar;
begin
  ShowWindow(WindowHandleToPlatform(Handle).Wnd, SW_HIDE);
end;

procedure TNotificacaoVisualizador.CreateHandle;
var
  Wnd: HWND;
begin
  inherited;
  Wnd := WindowHandleToPlatform(Handle).Wnd;
  // WS_EX_LAYERED é adicionado ao estilo da janela para permitir a transparência em janelas no Windows.
  SetWindowLong(Wnd, GWL_EXSTYLE, GetWindowLong(Wnd, GWL_EXSTYLE) or WS_EX_LAYERED);
  // WS_CAPTION e WS_THICKFRAME são removidos para eliminar a borda do formulário.
  SetWindowLong(Wnd, GWL_STYLE, GetWindowLong(Wnd, GWL_STYLE) and not (WS_CAPTION or WS_THICKFRAME));
end;

procedure TNotificacaoVisualizador.AtualizarPosicao(iAltura: Single);
var
  WorkArea: TRectF;
  ScreenHeight: Single;
  DesiredHeight: Single;
  Height: Single;
  Width: Integer;
  Left: Integer;
  Top: Integer;

  function FormPxToDp(const APoint: Single): Integer;
  var
    LScale: Single;
  begin
    LScale := Self.Handle.Scale;
    Result := Round(Single(APoint * LScale));
  end;
begin
  WorkArea := Screen.WorkAreaRect;
  ScreenHeight := WorkArea.Bottom - WorkArea.Top;
  DesiredHeight := ScreenHeight * 0.75;
  DesiredHeight := Min(DesiredHeight, iAltura);
  // Define a altura desejada (75% da altura do monitor) e a largura
  Height := Round(DesiredHeight);
  Width := 250; // Defina a largura desejada do formulário
  // Posiciona no canto inferior direito, sem sobrepor a barra de tarefas
  Left := Round(WorkArea.Right - Width - 10);
  Top := Round(WorkArea.Bottom - Height - 10);
  SetWindowPos(WindowHandleToPlatform(Handle).Wnd, HWND_TOPMOST, FormPxToDp(Left), FormPxToDp(Top), FormPxToDp(Width), FormPxToDp(Height), SWP_NOACTIVATE);
end;

end.
