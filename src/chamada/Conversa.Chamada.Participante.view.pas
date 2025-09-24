unit Conversa.Chamada.Participante.view;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects,
  Conversa.Tipos;

type
  TConversaChamadaParticipanteView = class(TFrame)
    crclParticipante: TCircle;
    pthContatos: TPath;
    txtNome: TText;
  private
    FUsuario: TUsuario;
  public
    constructor Create(AOwner: TComponent; AUsuario: TUsuario); reintroduce; overload;
  end;

implementation

{$R *.fmx}

{ TConversaChamadaParticipanteView }

constructor TConversaChamadaParticipanteView.Create(AOwner: TComponent; AUsuario: TUsuario);
begin
  inherited Create(AOwner);
  FUsuario := AUsuario;
  txtNome.Text := AUsuario.Nome;
//  txtNome.Text := 'Fulano'+ AUsuario.ID.ToString;
end;

end.
