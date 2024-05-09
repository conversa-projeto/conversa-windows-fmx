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
    FID: Integer;
    FUsuario: String;
    Visualizador: TVisualizador;
    Editor: TEditor;
    Anexo: TAnexo;
    FVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(AOwner: TFmxObject);
    destructor Destroy; override;
    property ID: Integer read FID write FID;
    property Usuario: String read FUsuario write FUsuario;
    property Visible: Boolean read FVisible write SetVisible;
    procedure AdicionarMensagem(Mensagem: TMensagem);
  end;

implementation

{ TConteudo }

constructor TConteudo.Create(AOwner: TFmxObject);
begin
  Visualizador := TVisualizador.Create(AOwner);
  Anexo := TAnexo.Create(AOwner);
  Editor := TEditor.Create(AOwner);
  Editor.ConfiguraAnexo(Anexo);
  Editor.AdicionaMensagem(
    procedure(Mensagem: TMensagem)
    begin
      Mensagem.EnviadaEm := Now;
      Mensagem.Lado := TLado.Direito;
      Mensagem.Remetente := Usuario;
      Visualizador.AdicionaMensagem(Mensagem);
    end
  );
end;

destructor TConteudo.Destroy;
begin
  Visualizador.Free;
  Editor.Free;
  Anexo.Free;
end;

procedure TConteudo.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  Visualizador.Visible := Value;
  Editor.Visible := Value;
end;

procedure TConteudo.AdicionarMensagem(Mensagem: TMensagem);
begin
  Visualizador.AdicionaMensagem(Mensagem);
end;

end.
