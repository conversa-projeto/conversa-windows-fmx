﻿unit Notificacao.Visualizador;

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
  Notificacao;

type
  TNotificacaoVisualizador = class(TForm)
  private
//    FOldWndProc: Pointer;
//    FNew: Pointer;
  protected
    procedure CreateHandle; override;
//    procedure DestroyHandle; override;
  public
    procedure Exibir;
    procedure AtualizarPosicao(iAltura: Single);
  end;

implementation

{$R *.fmx}

//var
//  prevWndProc: Pointer;

//function WndProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
//var
//  Frm: TCommonCustomForm;
////  Message: TMessage;
//begin
////  Message.Msg := uMsg;
////  Message.WParam := wParam;
////  Message.LParam := lParam;
////  Message.Result := 0;
////  if (Message.Msg = WM_MOVING) or (Message.Msg = WM_WINDOWPOSCHANGING) then
////    Exit(0);
////
////  if uMsg = WM_SYSCOMMAND then
////    if (wParam = SC_MINIMIZE) then
////      Exit(0);
//
//  Frm := FMX.Platform.Win.FindWindow(hwnd);
//  if Assigned(Frm) and Frm.InheritsFrom(TNotificacaoVisualizador) then
//    TNotificacaoVisualizador(Frm).AtualizarPosicao(Frm.Height);
//
//  Result := CallWindowProc(prevWndProc, hwnd, uMsg, wParam, lParam);
//end;

procedure TNotificacaoVisualizador.Exibir;
begin
  // Exibir sem Recebor Foco
  ShowWindow(WindowHandleToPlatform(Handle).Wnd, SW_SHOWNOACTIVATE);
  AtualizarPosicao(Height);
end;

procedure TNotificacaoVisualizador.CreateHandle;
var
  Wnd: HWND;
begin
  inherited;
//  prevWndProc := Pointer(SetWindowLong(WindowHandleToPlatform(Handle).Wnd, GWL_WNDPROC, LongInt(@WndProc)));
  Wnd := WindowHandleToPlatform(Handle).Wnd;
  // WS_EX_LAYERED é adicionado ao estilo da janela para permitir a transparência em janelas no Windows.
  // WS_EX_TOOLWINDOW é adicionado ao estilo da janela para torná-la uma janela de ferramenta, que não aparece na barra de tarefas.
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
  //Screen.DesktopRect
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
  Winapi.Windows.SetParent(WindowHandleToPlatform(Handle).Wnd, GetDesktopWindow);
end;

//procedure TNotificacaoVisualizador.DestroyHandle;
//begin
////  SetWindowLong(WindowHandleToPlatform(Handle).Wnd, GWL_WNDPROC, LongInt(prevWndProc));
//  inherited;
//end;

end.