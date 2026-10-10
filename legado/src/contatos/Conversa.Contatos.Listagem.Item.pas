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
    procedure rctFundoClick(Sender: TObject);
  private
    { Private declarations }
    FUsuarioId: Integer;
    FOnAbrirChat: TProc<Integer, String>;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; AUsuarioId: Integer); reintroduce; overload;
    function OnAbrirChat(Value: TProc<Integer, String>): TConversaContatoItem;
  end;

implementation

{$R *.fmx}

{ TConversaContatoItem }

constructor TConversaContatoItem.Create(AOwner: TComponent; AUsuarioId: Integer);
begin
  inherited Create(AOwner);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  FUsuarioId := AUsuarioId;
end;

function TConversaContatoItem.OnAbrirChat(Value: TProc<Integer, String>): TConversaContatoItem;
begin
  Result := Self;
  FOnAbrirChat := Value;
end;

procedure TConversaContatoItem.rctFundoClick(Sender: TObject);
begin
  if Assigned(FOnAbrirChat) then
    FOnAbrirChat(FUsuarioId, lblNome.Text);
end;

end.
