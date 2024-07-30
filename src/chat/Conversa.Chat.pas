unit Conversa.Chat;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  System.Math,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  Conversa.Dados,
  Conversa.FrameBase,
  Mensagem.Visualizador,
  Mensagem.Editor,
  Mensagem.Tipos,
  Mensagem.Anexo,
  Conversa.Chat.Listagem.Item;

type
  TChat = class(TFrameBase)
    rctFundo: TRectangle;
    rctTitulo: TRectangle;
    lytTituloClient: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    imgFoto: TImage;
    lytInformacoes: TLayout;
    lblNome: TLabel;
    lytClient: TLayout;
    pthFotoDefault: TPath;
    procedure lblNomeClick(Sender: TObject);
  private
    FListagemItem: TConversasItemFrame;
    FID: Integer;
    FUsuario: String;
    FUsuarioID: Integer;
    FVisualizador: TVisualizador;
    Editor: TEditor;
    Anexo: TAnexo;
    FDestinatarioID: Integer;
    procedure SetUsuario(const Value: String);
    procedure SetDestinatarioID(const Value: Integer);
  public
    UltimaMensagem: Integer;
    AoEnviarMensagem: TProc<TChat, TPMensagem>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ListagemItem: TConversasItemFrame read FListagemItem write FListagemItem;
    property ID: Integer read FID write FID;
    property Usuario: String read FUsuario write SetUsuario;
    property UsuarioID: Integer read FUsuarioID write FUsuarioID;
    property DestinatarioID: Integer read FDestinatarioID write SetDestinatarioID;
    property Visualizador: TVisualizador read FVisualizador;
    procedure AdicionarMensagem(Mensagem: TPMensagem);
    procedure AdicionarMensagens(aMensagem: TPMensagems);
    procedure PosicionarUltima;
    procedure Limpar;
    procedure VisualizarTudo;
    procedure ValidarVisualizacao;
  end;

implementation

{$R *.fmx}

{ TChat }

procedure TChat.AdicionarMensagem(Mensagem: TPMensagem);
begin
  Visualizador.AdicionaMensagem(Mensagem);
end;

procedure TChat.AdicionarMensagens(aMensagem: TPMensagems);
var
  Mensagem: TPMensagem;
begin
  for Mensagem in aMensagem do
  begin
    UltimaMensagem := Max(UltimaMensagem, Mensagem.id);
    AdicionarMensagem(Mensagem);
  end;
  PosicionarUltima;
end;

constructor TChat.Create(AOwner: TComponent);
begin
  inherited;
  Sleep(1);
  Name := 'chat_'+ FormatDateTime('yyyymmddHHnnsszzz', Now);
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Visible := True;
  lytFoto.Visible := False;
  FVisualizador := TVisualizador.Create(lytClient);
  Anexo := TAnexo.Create(Self);
  lblNome.Visible := True;
  Editor := TEditor.Create(Self);
  Editor.ConfiguraAnexo(Anexo);
  Editor.AdicionaMensagem(
    procedure(Mensagem: TPMensagem)
    begin
      if FID = 0 then
      begin
        FID := Dados.NovoChat(FUsuarioID, FDestinatarioID);
        FListagemItem.ID := FID;
      end;
      Mensagem.inserida := Now;
      Mensagem.lado := TLado.Direito;
      Mensagem.remetente := Usuario;
      Mensagem.ConversaId := ID;
      Mensagem.RemetenteId := FUsuarioID;
//      Mensagem.Recebida := True;
//      Mensagem.Visualizada := True;
      if Assigned(AoEnviarMensagem) then
        AoEnviarMensagem(Self, Mensagem);
      Visualizador.PosicionarUltima;
    end
  );
end;

destructor TChat.Destroy;
begin
  Visualizador.Free;
  Editor.Free;
  Anexo.Free;
  inherited;
end;

procedure TChat.lblNomeClick(Sender: TObject);
begin
  ShowMessage(Dados.MensagemSemVisualizar(FID).ToString);
end;

procedure TChat.Limpar;
begin
  Visualizador.Limpar;
end;

procedure TChat.SetDestinatarioID(const Value: Integer);
begin
  FDestinatarioID := Value;
end;

procedure TChat.SetUsuario(const Value: String);
begin
  FUsuario := Value;
end;

procedure TChat.ValidarVisualizacao;
begin
  Visualizador.ValidarVisualizacao;
end;

procedure TChat.VisualizarTudo;
begin
//  Visualizador.VisualizarTudo;
end;

procedure TChat.PosicionarUltima;
begin
  Visualizador.PosicionarUltima;
end;

end.
