unit Conversa.Chat;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  //Conversa.Conteudo,
  Conversa.Dados,
  Conversa.FrameBase,

  Mensagem.Visualizador,
  Mensagem.Editor,
  Mensagem.Tipos,
  Mensagem.Anexo;

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
    lblInformacao1: TLabel;
    lytClient: TLayout;
    pthFotoDefault: TPath;
  private
    { Private declarations }
    FID: Integer;
    FUsuario: String;
    FUsuarioID: Integer;
    Visualizador: TVisualizador;
    Editor: TEditor;
    Anexo: TAnexo;
  public
    { Public declarations }
    AoEnviarMensagem: TProc<TChat, TMensagem>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ID: Integer read FID write FID;
    property Usuario: String read FUsuario write FUsuario;
    property UsuarioID: Integer read FUsuarioID write FUsuarioID;

    procedure AdicionarMensagem(Mensagem: TMensagem);
    procedure AdicionarMensagens(aMensagem: TArray<TMensagem>);
  end;

var
  Chat: TChat;

implementation

{$R *.fmx}

{ TChat }

procedure TChat.AdicionarMensagem(Mensagem: TMensagem);
begin
  Visualizador.AdicionaMensagem(Mensagem);
end;

procedure TChat.AdicionarMensagens(aMensagem: TArray<TMensagem>);
var
  Mensagem: TMensagem;
begin
  for Mensagem in aMensagem do
    AdicionarMensagem(Mensagem);
end;

constructor TChat.Create(AOwner: TComponent);
begin
  inherited;
  Parent := TFmxObject(AOwner);
  Align := TAlignLayout.Client;
  Visible := True;
  Visualizador := TVisualizador.Create(lytClient);
  Anexo := TAnexo.Create(Self);
  Editor := TEditor.Create(Self);
  Editor.ConfiguraAnexo(Anexo);
  Editor.AdicionaMensagem(
    procedure(Mensagem: TMensagem)
    begin
      Mensagem.inserida := Now;
      Mensagem.lado := TLado.Direito;
      Mensagem.remetente := Usuario;
      Mensagem.conversa_id := ID;
      Mensagem.remetente_id := FUsuarioID;
      Visualizador.AdicionaMensagem(Mensagem);

      if Assigned(AoEnviarMensagem) then
        AoEnviarMensagem(Self, Mensagem);
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

end.
