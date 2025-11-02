unit Conversa.Chamada.Usuario.view;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects,
  Conversa.Proxy.Tipos, FMX.Layouts;

type
  TConversaChamadaUsuarioView = class(TFrame)
    tmrTempoDecorrido: TTimer;
    Layout1: TLayout;
    txtStatusChamada: TText;
    txtNome: TText;
    txtTempoDecorrido: TText;
    crclParticipante: TCircle;
    pthContatos: TPath;
    procedure tmrTempoDecorridoTimer(Sender: TObject);
  private
    FChamada: TObject;
    FUsuario: TChamadaDadosUsuario;
  public
    constructor Create(AOwner: TComponent; AChamada: TObject; AUsuario: TChamadaDadosUsuario); reintroduce; overload;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Chamada;

type
  TConversaChamadaUsuarioViewH = class Helper for TConversaChamadaUsuarioView
    function Chamada: TConversaChamada;
  end;

{ TConversaChamadaParticipanteView }

constructor TConversaChamadaUsuarioView.Create(AOwner: TComponent; AChamada: TObject; AUsuario: TChamadaDadosUsuario);
begin
  inherited Create(AOwner);
  FChamada := AChamada;
  FUsuario := AUsuario;
  txtNome.Text := AUsuario.usuario_nome;
  txtTempoDecorrido.Text := '';
end;

procedure TConversaChamadaUsuarioView.tmrTempoDecorridoTimer(Sender: TObject);
begin
  txtTempoDecorrido.Text := Chamada.TempoDecorrido;
end;

{ TConversaChamadaUsuarioViewH }

function TConversaChamadaUsuarioViewH.Chamada: TConversaChamada;
begin
  Result := TConversaChamada(FChamada);
end;

end.
