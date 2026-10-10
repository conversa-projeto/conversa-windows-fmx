// Eduardo - 09/03/2024
unit Conversa.Conteudo;

interface

uses
  System.SysUtils,
  FMX.Types,
  Mensagem.Visualizador,
  Mensagem.Editor,
  Mensagem.Tipos,
  Mensagem.Anexo;

type
  TConteudo = class
  private
//    FItemIndex: Integer;
//    FConversa: Integer;
//    FUsuario: String;
//    FUsuarioID: Integer;
//    Visualizador: TVisualizador;
//    Editor: TEditor;
//    Anexo: TAnexo;
//    FVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
  public
    AoEnviarMensagem: TProc<TConteudo, TMensagem>;
    constructor Create(AOwner: TFmxObject);
    destructor Destroy; override;
//    property ItemIndex: Integer read FItemIndex write FItemIndex;
//    property Conversa: Integer read FConversa write FConversa;
//    property Usuario: String read FUsuario write FUsuario;
//    property UsuarioID: Integer read FUsuarioID write FUsuarioID;
//    property Visible: Boolean read FVisible write SetVisible;
    procedure AdicionarMensagem(Mensagem: TMensagem);
    procedure AdicionarMensagens(aMensagem: TArray<TMensagem>);
  end;

implementation

{ TConteudo }

constructor TConteudo.Create(AOwner: TFmxObject);
begin
//  Visualizador := TVisualizador.Create(AOwner);
//  Anexo := TAnexo.Create(AOwner);
//  Editor := TEditor.Create(AOwner);
//  Editor.ConfiguraAnexo(Anexo);
//  Editor.AdicionaMensagem(
//    procedure(Mensagem: TMensagem)
//    begin
//      Mensagem.inserida := Now;
//      Mensagem.lado := TLado.Direito;
//      Mensagem.remetente := Usuario;
//      Mensagem.conversa_id := Conversa;
//      Mensagem.remetente_id := FUsuarioID;
//      Visualizador.AdicionaMensagem(Mensagem);
//
//      if Assigned(AoEnviarMensagem) then
//        AoEnviarMensagem(Self, Mensagem);
//    end
//  );
end;

destructor TConteudo.Destroy;
begin
end;

procedure TConteudo.SetVisible(const Value: Boolean);
begin
//  FVisible := Value;
//  Visualizador.Visible := Value;
//  Editor.Visible := Value;
end;

procedure TConteudo.AdicionarMensagem(Mensagem: TMensagem);
begin
end;

procedure TConteudo.AdicionarMensagens(aMensagem: TArray<TMensagem>);
begin
end;

end.
