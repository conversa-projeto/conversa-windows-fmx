unit Conversa.Contatos.Listagem.Item;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Ani, FMX.Controls.Presentation, FMX.Objects,
  FMX.Layouts;

type
  TConversaContatoItem = class(TFrameBase)
    rctFundo: TRectangle;
    lytClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    Text1: TText;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    ColorAnimation1: TColorAnimation;
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
  end;

var
  ConversaContatoItem: TConversaContatoItem;

implementation

{$R *.fmx}

{ TConversaContatoItem }

constructor TConversaContatoItem.Create(AOwner: TComponent);
begin
  inherited;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
end;

end.
