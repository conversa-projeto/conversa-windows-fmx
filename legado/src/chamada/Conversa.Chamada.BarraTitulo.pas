unit Conversa.Chamada.BarraTitulo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.Tipos,
  Conversa.FrameBase,
  FMX.Objects,
  FMX.Layouts;

type
  TConversaChamadaBarraTitulo = class(TFrameBase)
    rctFundo: TRectangle;
    lytFinalizarChamada: TLayout;
    pthFinalizarChamada: TPath;
    txtTempoLigacao: TText;
    lytAtenderChamada: TLayout;
    pthAtenderChamada: TPath;
    lytIconeChamada: TLayout;
    pthIconeChamada_Realizada: TPath;
    pthIconeChamada_Recebida: TPath;
    pthIconeChamada_Recusada: TPath;
    procedure lytAtenderChamadaClick(Sender: TObject);
    procedure lytFinalizarChamadaClick(Sender: TObject);
  private
    FStatus: TChamadaStatusLocal;
    FChamada: TObject;
    procedure SetStatus(const Value: TChamadaStatusLocal);
  public
    constructor Create(AOwner: TComponent; AChamada: TObject); reintroduce; overload;
    destructor Destroy; override;
    procedure Exibir;
    procedure Ocultar;
    property Status: TChamadaStatusLocal read FStatus write SetStatus;
  end;

implementation

{$R *.fmx}

uses
  Conversa.Chamada,
  Conversa.Tela.Inicial.view;

type
  TConversaChamadaBarraTituloH = class Helper for TConversaChamadaBarraTitulo
    function Chamada: TConversaChamada;
  end;

{ TChamadaBarraTitulo }

constructor TConversaChamadaBarraTitulo.Create(AOwner: TComponent; AChamada: TObject);
begin
  inherited Create(AOwner);
  Name := 'TConversaChamadaBarraTitulo_'+ FormatDateTime('yyyyymmddHHnnsszzzz', Now);
  FChamada := AChamada;
end;

destructor TConversaChamadaBarraTitulo.Destroy;
begin
  Sleep(0);
  inherited;
end;

procedure TConversaChamadaBarraTitulo.Exibir;
begin
  Parent := TelaInicial.lytTitleBarClient;
  Align := TAlignLayout.Center;
  Visible := True;
end;

procedure TConversaChamadaBarraTitulo.lytAtenderChamadaClick(Sender: TObject);
begin
  inherited;
  Chamada.Entrar;
end;

procedure TConversaChamadaBarraTitulo.lytFinalizarChamadaClick(Sender: TObject);
begin
  inherited;
//  case FStatus of
//    TMethod.Erro: ;
//    TMethod.Registrar: ;
//    TMethod.AtribuirIdentificador: ;
//    TMethod.AtribuirUDP: ;
//    TMethod.IniciarChamada: TConversaChamada.Instance.Cancelar;
//    TMethod.CancelarChamada: ;
//    TMethod.DestinatarioOcupado: ;
//    TMethod.ReceberChamada: TConversaChamada.Instance.Recusar;
//    TMethod.AtenderChamada: ;
//    TMethod.RetomarChamada: ;
//    TMethod.RecusarChamada: ;
//    TMethod.FinalizarChamada: ;
//    TMethod.ChamadasAtivas: ;
//    TMethod.FinalizarTodasChamadas: ;
//    TMethod.UsuarioDesconectado: ;
//  end;
end;

procedure TConversaChamadaBarraTitulo.Ocultar;
begin
  Self.Visible := False;
  Self.Parent := nil;
end;

procedure TConversaChamadaBarraTitulo.SetStatus(const Value: TChamadaStatusLocal);
begin
  FStatus := Value;
  pthIconeChamada_Realizada.Visible := FStatus in [TChamadaStatusLocal.IniciandoChamada];
  pthIconeChamada_Recebida.Visible := FStatus in [TChamadaStatusLocal.RecebentoChamada];
  pthIconeChamada_Recusada.Visible := FStatus in [TChamadaStatusLocal.ChamadaPerdida];

  case FStatus of
    TChamadaStatusLocal.IniciandoChamada:
    begin
      lytAtenderChamada.Visible := False;
    end;
    TChamadaStatusLocal.ChamadaEmAndamento:
    begin
      lytAtenderChamada.Visible := False;
    end;
    TChamadaStatusLocal.ChamadaFinalizada:
    begin
      lytAtenderChamada.Visible := False;
      lytFinalizarChamada.Visible := False;
      Self.Visible := False;
      Self.Hide;
    end;
  end;
end;

{ TConversaChamadaBarraTituloH }

function TConversaChamadaBarraTituloH.Chamada: TConversaChamada;
begin
  Result := TConversaChamada(FChamada);
end;

end.
