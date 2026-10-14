unit Conversa.UI.Principal;

{ Janela principal. Por enquanto (Etapa 1.1) só mostra a versão; as telas entram nas etapas seguintes. }

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  Conversa.Infra.Log,
  Conversa.Eventos.Barramento;

type
  TTelaPrincipal = class(TForm)
    lblVersao: TLabel;
  private
    FLogger: ILogger;
    FBarramento: TBarramento;
  public
    /// <summary>Recebe os serviços da composição; chamado uma vez, logo depois de criar a janela.</summary>
    procedure Iniciar(const ALogger: ILogger; ABarramento: TBarramento);
    /// <summary>Solta os serviços (chamado depois do Application.Run, antes de a composição ser liberada).</summary>
    procedure Finalizar;
  end;

var
  TelaPrincipal: TTelaPrincipal;

implementation

uses
  Conversa.Infra.Windows.Versao,
  Conversa.UI.Textos;

{$R *.fmx}

{ TTelaPrincipal }

procedure TTelaPrincipal.Iniciar(const ALogger: ILogger; ABarramento: TBarramento);
begin
  FLogger := ALogger;
  FBarramento := ABarramento;
  Caption := SNomeDoApp;
  lblVersao.Text := Format(SNovaBaseEmConstrucao, [TVersaoApp.DoExecutavel.Curta]);
end;

procedure TTelaPrincipal.Finalizar;
begin
  FBarramento := nil;
  FLogger := nil;
end;

end.
