unit Conversa.Chamada.Participante.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects,
  Conversa.Proxy.Tipos, FMX.Ani, FMX.Controls.Presentation, FMX.Layouts;

type
  TConversaChamadaParticipanteView = class(TFrame)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtAbreviatura: TText;
    lytInformacoes: TLayout;
    txtMensagem: TText;
    ColorAnimation1: TColorAnimation;
    txtNome: TText;
  private
    FUsuario: TChamadaDadosUsuario;
  public
    constructor Create(AOwner: TComponent; AUsuario: TChamadaDadosUsuario); reintroduce; overload;
  end;

implementation

{$R *.fmx}

{ TConversaChamadaParticipanteView }

constructor TConversaChamadaParticipanteView.Create(AOwner: TComponent; AUsuario: TChamadaDadosUsuario);
begin
  inherited Create(AOwner);
  FUsuario := AUsuario;
  txtNome.Text := AUsuario.usuario_nome;
//  txtNome.Text := 'Fulano'+ AUsuario.ID.ToString;
end;

end.
