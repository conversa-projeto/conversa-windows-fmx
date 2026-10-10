unit Conversa.Chamada.Listagem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.ListBox,
  REST.API,
  Conversa.FrameBase,
  Conversa.Chamada.Listagem.Item,
  Conversa.Eventos,
  Conversa.Proxy.Tipos;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    ChamadaItem: TConversaChamadaListagemItem;
  end;

  TConversaChamadaListagem = class(TFrameBase)
    rctFundo: TRectangle;
    txtTitle: TText;
    lstChamadas: TListBox;
    tmrCarregar: TTimer;
    procedure tmrCarregarTimer(Sender: TObject);
  private
    procedure CarregarChamadas(const Sender: TObject; const M: TObterChamadasHistorico);
    procedure OnChamadaClick(AChamada: TChamadaHistorico);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure Exibir;
  end;

var
  ConversaChamadaListagem: TConversaChamadaListagem;

implementation

{$R *.fmx}

uses
  Conversa.Tela.Inicial.view,
  Conversa.Proxy,
  Conversa.Chamada.Detalhe;

constructor TConversaChamadaListagem.Create(AOwner: TComponent);
begin
  inherited;
  TObterChamadasHistorico.Subscribe(CarregarChamadas);
end;

destructor TConversaChamadaListagem.Destroy;
begin
  TObterChamadasHistorico.Unsubscribe(CarregarChamadas);
  inherited;
end;

class procedure TConversaChamadaListagem.Exibir;
begin
  TelaInicial.ModalView.Exibir(TConversaChamadaListagem.Create(TelaInicial.lytClientForm));
end;

procedure TConversaChamadaListagem.tmrCarregarTimer(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  TAPIConversa.Chamadas;
end;

procedure TConversaChamadaListagem.CarregarChamadas(const Sender: TObject; const M: TObterChamadasHistorico);
var
  Resposta: TRespostaChamadasHistorico;
  Chamada: TChamadaHistorico;
  Item: TListBoxItem;
begin
  Resposta := M.Value;

  if Resposta.Status <> TResponseStatus.Sucess then
    Exit;

  lstChamadas.BeginUpdate;
  try
    lstChamadas.Clear;

    for Chamada in Resposta.Dados do
    begin
      Item := TListBoxItem.Create(nil);
      Item.Text := '';
      Item.Height := 60;
      Item.Selectable := False;
      Item.ChamadaItem := TConversaChamadaListagemItem.Create(Item, Chamada);
      Item.ChamadaItem.OnClick(OnChamadaClick);
      lstChamadas.AddObject(Item);
    end;
  finally
    lstChamadas.EndUpdate;
  end;
end;

procedure TConversaChamadaListagem.OnChamadaClick(AChamada: TChamadaHistorico);
begin
  TConversaChamadaDetalhe.Exibir(AChamada);
end;

end.
