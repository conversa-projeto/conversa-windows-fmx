unit Conversa.Chamada.Usuarios.Listagem.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Controls.Presentation, FMX.Objects,
  FMX.Layouts,
  Conversa.Proxy.Tipos, Conversa.FrameBase;

type
  TConversaChamadaUsuariosListItem = class(TFrame)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtAbreviatura: TText;
    lytInformacoes: TLayout;
    txtStatus: TText;
    ColorAnimation1: TColorAnimation;
    txtNome: TText;
  public
    Usuario: TChamadaDadosUsuario;
    constructor Create(AOwner: TComponent; AUsuario: TChamadaDadosUsuario); reintroduce; overload;
  end;

implementation

{$R *.fmx}

{ TConversaChamadaUsuariosListItem }

constructor TConversaChamadaUsuariosListItem.Create(AOwner: TComponent; AUsuario: TChamadaDadosUsuario);
begin
  inherited Create(AOwner);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Usuario := AUsuario;
  txtNome.Text := AUsuario.usuario_nome;
//  txtNome.Text := 'Fulano'+ AUsuario.ID.ToString;
end;

end.
