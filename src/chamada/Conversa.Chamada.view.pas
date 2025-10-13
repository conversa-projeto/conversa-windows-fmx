unit Conversa.Chamada.view;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Objects,
  FMX.Layouts,
  FMX.Platform.Win,
  Conversa.Proxy.Tipos,
  Conversa.Tipos,
  Conversa.FormularioBase,
  Conversa.Chamada.Usuario.view,
  Conversa.Chamada.Usuarios.Listagem,
  FMX.ListBox;

type
  {$SCOPEDENUMS ON}
  TAudioStatus = (Desconhecido, Indisposivel, Desativado, Ativo);
  TVideoStatus = (Desconhecido, Indisposivel, Desativado, Ativo);
  TConversaChamadaView = class(TFormularioBase)
    rtgBarraInferior: TRectangle;
    lytUsuarios: TLayout;
    lytBotoes: TLayout;
    crclAudio: TCircle;
    pthMicrofoneAtivo: TPath;
    pthMicrofoneDesativado: TPath;
    pthMicrofoneAlerta: TPath;
    crclVideo: TCircle;
    pthVideoAtivo: TPath;
    pthVideoDesativado: TPath;
    pthVideoAlerta: TPath;
    crclFinalizarChamada: TCircle;
    pthFinalizarChamada: TPath;
    crclAtenderChamada: TCircle;
    pthAtenderChamada: TPath;
    txtStatusChamada: TText;
    procedure crclFinalizarChamadaClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure crclAtenderChamadaClick(Sender: TObject);
  private
    FChamada: TObject;
    FOldHWND: HWND;
    FAudioStatus: TAudioStatus;
    FVideoStatus: TVideoStatus;
    FUsuario: TConversaChamadaUsuarioView;
    FListaUsuarios: TConversaChamadaUsuariosListagem;
    FStatus: TStatusChamada;
    procedure SetAudioStatus(const Value: TAudioStatus);
    procedure SetVideoStatus(const Value: TVideoStatus);
    procedure SetStatus(const Value: TStatusChamada);
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
  public
    constructor Create(AOwner: TComponent; AChamada: TObject); reintroduce; overload;
    property AudioStatus: TAudioStatus read FAudioStatus write SetAudioStatus;
    property VideoStatus: TVideoStatus read FVideoStatus write SetVideoStatus;
    property Status: TStatusChamada read FStatus write SetStatus;
    procedure AtualizarListaParticipante;
  end;

var
  ConversaChamadaView: TConversaChamadaView;

implementation

uses
  Conversa.Dados,
  Conversa.Chamada;

{$R *.fmx}

type
  TConversaChamadaViewH = class helper for TConversaChamadaView
    function Chamada: TConversaChamada;
  end;


procedure TConversaChamadaView.crclAtenderChamadaClick(Sender: TObject);
begin
  Chamada.Entrar;
end;

procedure TConversaChamadaView.crclFinalizarChamadaClick(Sender: TObject);
begin
  inherited;
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(100);
      TThread.Synchronize(
        nil,
        procedure
        begin
          Chamada.Sair;
        end
      );
    end
  ).Start;
end;

constructor TConversaChamadaView.Create(AOwner: TComponent; AChamada: TObject);
begin
  inherited Create(Application);
  FChamada := AChamada;

  AudioStatus := TAudioStatus.Indisposivel;
  VideoStatus := TVideoStatus.Indisposivel;
end;

procedure TConversaChamadaView.CreateHandle;
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

procedure TConversaChamadaView.DestroyHandle;
begin
  SetWindowLongPtr(FormToHWND(Self), GWL_HWNDPARENT, FOldHWND);
  inherited;
end;

procedure TConversaChamadaView.AtualizarListaParticipante;
var
  Usuarios : TArray<TChamadaDadosUsuario>;
  Usuario: TChamadaDadosUsuario;
begin
  Usuarios := Chamada.GetUsuarios;

  if (Length(Usuarios) = 2) then
  begin
    if Assigned(FUsuario) then
      FreeAndNil(FUsuario);

    for Usuario in Usuarios do
    begin
      if Usuario.usuario_id = Dados.FDadosApp.Usuario.ID then
        Continue;

      FUsuario := TConversaChamadaUsuarioView.Create(lytUsuarios, Usuario);
      FUsuario.Parent := lytUsuarios;
      FUsuario.Align := TAlignLayout.Client;
      FUsuario.Visible := True;
    end;
  end
  else
  begin
    if not Assigned(FListaUsuarios) then
      FListaUsuarios := TConversaChamadaUsuariosListagem.Create(lytUsuarios, FChamada);

    FListaUsuarios.AtualizarListaUsuarios;
  end;
end;

procedure TConversaChamadaView.FormDestroy(Sender: TObject);
begin
  inherited;
  //
end;

procedure TConversaChamadaView.SetAudioStatus(const Value: TAudioStatus);
begin
  FAudioStatus := Value;
  pthMicrofoneAlerta.Visible := Value in [TAudioStatus.Desconhecido, TAudioStatus.Indisposivel];
  pthMicrofoneAtivo.Visible := Value in [TAudioStatus.Ativo];
  pthMicrofoneDesativado.Visible := Value in [TAudioStatus.Desativado];
end;

procedure TConversaChamadaView.SetStatus(const Value: TStatusChamada);
begin
  FStatus := Value;
  case FStatus of
    TStatusChamada.Desconhecido: ;
    TStatusChamada.IniciandoChamada:
    begin
      crclAtenderChamada.Visible := False;
      crclFinalizarChamada.Visible := True;
      crclAudio.Visible := True;
      crclVideo.Visible := False;
      lytBotoes.Width := crclVideo.AbsoluteWidth * 2;
      txtStatusChamada.Text := 'Iniciando...';
    end;
    TStatusChamada.RecebentoChamada:
    begin
      crclAtenderChamada.Visible := True;
      crclFinalizarChamada.Visible := True;
      crclAudio.Visible := False;
      crclVideo.Visible := False;
      lytBotoes.Width := crclVideo.AbsoluteWidth * 2;
      txtStatusChamada.Text := 'Recebendo Chamada';
    end;
    TStatusChamada.ChamadaEmAndamento:
    begin
      crclAtenderChamada.Visible := False;
      crclFinalizarChamada.Visible := True;
      crclAudio.Visible := True;
      crclVideo.Visible := True;
      lytBotoes.Width := crclVideo.AbsoluteWidth * 3;
      txtStatusChamada.Text := 'Em Andamento...';
    end;
    TStatusChamada.ChamadaFinalizada:
    begin
      crclAtenderChamada.Visible := False;
      crclFinalizarChamada.Visible := False;
      crclAudio.Visible := False;
      crclVideo.Visible := False;
      lytBotoes.Width := 0;
      Self.Hide;
    end;
    TStatusChamada.ChamadaPerdida:
    begin
      crclAtenderChamada.Visible := False;
      crclFinalizarChamada.Visible := False;
      crclAudio.Visible := False;
      crclVideo.Visible := False;
      lytBotoes.Width := crclVideo.AbsoluteWidth * 2;
    end;
  end;
end;

procedure TConversaChamadaView.SetVideoStatus(const Value: TVideoStatus);
begin
  FVideoStatus := Value;
  pthVideoAlerta.Visible := Value in [TVideoStatus.Desconhecido, TVideoStatus.Indisposivel];
  pthVideoAtivo.Visible := Value in [TVideoStatus.Ativo];
  pthVideoDesativado.Visible := Value in [TVideoStatus.Desativado];
end;

{ TConversaChamadaViewH }

function TConversaChamadaViewH.Chamada: TConversaChamada;
begin
  Result := TConversaChamada(FChamada);
end;

end.
