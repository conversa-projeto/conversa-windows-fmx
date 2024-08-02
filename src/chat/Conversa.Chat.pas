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
  Conversa.Tipos,
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
  private
    FListagemItem: TConversasItemFrame;
    FConversa: TConversa;
    FVisualizador: TVisualizador;
    Editor: TEditor;
    Anexo: TAnexo;
  public
    UltimaMensagem: Integer;
    AoEnviarMensagem: TProc<TChat, TMensagem>;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ListagemItem: TConversasItemFrame read FListagemItem write FListagemItem;
    property Conversa: TConversa read FConversa write FConversa;


    property Visualizador: TVisualizador read FVisualizador;
    procedure AdicionarMensagem(Mensagem: TMensagem);
    procedure AdicionarMensagens(aMensagem: TArrayMensagens);
    procedure PosicionarUltima;
    procedure Limpar;
    procedure VisualizarTudo;
    procedure ValidarVisualizacao;
  end;

implementation

{$R *.fmx}

{ TChat }

procedure TChat.AdicionarMensagem(Mensagem: TMensagem);
begin
  Visualizador.AdicionaMensagem(Mensagem);
end;

procedure TChat.AdicionarMensagens(aMensagem: TArrayMensagens);
var
  Mensagem: TMensagem;
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
    procedure(Mensagem: TMensagem)
    begin
      if Conversa.ID = 0 then
      begin
        Dados.NovoChat(FConversa);
        FListagemItem.ID := Conversa.ID;
      end;
      Mensagem
        .Inserida(Now)
        .Remetente(Dados.FDadosApp.Usuario)
        .Conversa(Conversa);

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

procedure TChat.Limpar;
begin
  Visualizador.Limpar;
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
