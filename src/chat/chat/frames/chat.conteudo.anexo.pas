// Eduardo - 04/08/2024
unit chat.conteudo.anexo;

interface

uses
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Layouts,
  chat.mensagem.conteudo;

type
  TChatConteudoAnexo = class(TChatConteudo)
    Path: TPath;
    Layout: TLayout;
    lbTamanho: TLabel;
    lbNome: TLabel;
  public
    function Target(Largura: Single): TTarget; override;
  end;

implementation

{$R *.fmx}

{ TAnexo }

function TChatConteudoAnexo.Target(Largura: Single): TTarget;
begin
  Result.Width := 250;
  Result.Height := 20;
end;

end.
