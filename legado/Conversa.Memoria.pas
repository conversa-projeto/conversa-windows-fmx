// Eduardo - 13/07/2024
unit Conversa.Memoria;

interface

uses
  FMX.Types,
  System.Generics.Collections,
  Conversa.Tipos;

type

  TDadosApp = class
  private
  public
    Usuario: TUsuario;
    Usuarios: TUsuarios;
    Conversas: TConversas;


    UltimaMensagemNotificada: Integer;
    class function New: TDadosApp;
    constructor Create;
    destructor Destroy; override;

//    function UltimaMensagemConversa(iConversa: Integer): Integer;
//    procedure AdicionaMensagem(iConversa: Integer; Mensagem: TMensagem);
//    function Mensagens(iConversa: Integer; iInicio: Integer): TMensagens;
//    function ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TMensagens;
//    function MensagemSemVisualizar: Integer; overload;
//    function MensagemSemVisualizar(iConversa: Integer): Integer; overload;
//    function MensagensParaNotificar(iConversa: Integer): TMensagens;
//    function MensagensParaAtualizar(iConversa: Integer): String;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  Winapi.Windows,
  Conversa.Dados,
  Conversa.Log;

{ TDadosApp }

class function TDadosApp.New: TDadosApp;
begin
  Result := TDadosApp.Create;
end;

constructor TDadosApp.Create;
begin
  Conversas := TConversas.Create;
  Usuarios := TUsuarios.Create;
  inherited;
end;

destructor TDadosApp.Destroy;
begin
  FreeAndNil(Conversas);
  FreeAndNil(Usuarios);
end;

//procedure TDadosApp.AdicionaMensagem(iConversa: Integer; Mensagem: TMensagem);
//var
//  Conversa: TDadosConversa;
//begin
//  AddLog('Início: AdicionaMensagem');
//  try
//    if not ObtemConversa(iConversa, Conversa) then
//    begin
//      Conversa := TDadosConversa.New;
//      Conversa.ID := iConversa;
//      Conversas.Add(Conversa);
//    end;
//    Conversa.AdicionaMensagem(Mensagem);
//    if Mensagem.lado = TLado.Esquerdo then
//      Conversa.FUltimaMensagem := Max(Mensagem.id, Conversa.FUltimaMensagem);
//    UltimaMensagemNotificada := Max(Mensagem.id, UltimaMensagemNotificada);
//  finally
//    AddLog('Fim: AdicionaMensagem');
//  end;
//end;

//function TDadosApp.UltimaMensagemConversa(iConversa: Integer): Integer;
//var
//  P: TDadosConversa;
//begin
//  AddLog('Início: UltimaMensagemConversa');
//  try
//    if ObtemConversa(iConversa, P) then
//      Result := P.FUltimaMensagem
//    else
//      Result := 0;
//  finally
//    AddLog('Fim: UltimaMensagemConversa');
//  end;
//end;

//function TDadosApp.MensagemSemVisualizar: Integer;
//var
//  Convera: TConversa;
//begin
//  AddLog('Início: MensagemSemVisualizar');
//  try
//    Result := 0;
//    for Convera in Conversas do
//      Inc(Result, MensagemSemVisualizar(Convera.ID));
//  finally
//    AddLog('Fim: MensagemSemVisualizar');
//  end;
//end;

//function TDadosApp.MensagemSemVisualizar(iConversa: Integer): Integer;
//var
//  Mensagem: TMensagem;
//begin
//  AddLog('Início: MensagemSemVisualizar(Integer)');
//  try
//    Result := 0;
//    for Mensagem in Conversas.Get(iConversa).Mensagens do
//      if (Mensagem.Lado <> TLadoMensagem.Direito) and not Mensagem.visualizada then
//        Inc(Result);
//  finally
//    AddLog('Fim: MensagemSemVisualizar(Integer)');
//  end;
//end;

//function TDadosApp.Mensagens(iConversa: Integer; iInicio: Integer): TMensagens;
//var
//  Conversa: TDadosConversa;
//  Mensagem: TMensagem;
//begin
//  AddLog('Início: Mensagens');
//  try
//    Result := [];
//    if not ObtemConversa(iConversa, Conversa) then Exit;
//    for Mensagem in Conversa.Mensagens do
//      if Mensagem.id >= iInicio then
//        Result := Result + [Mensagem];
//  finally
//    AddLog('Fim: Mensagens');
//  end;
//end;

//function TDadosApp.ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TMensagens;
//var
//  Conversa: TDadosConversa;
//  I: Integer;
//begin
//  AddLog('Início: ExibirMensagem');
//  try
//    Result := [];
//    if not ObtemConversa(iConversa, Conversa) then Exit;
//    for I := 0 to Pred(Conversa.Mensagens.Count) do
//    begin
//      if ApenasPendente and Conversa.Mensagens[I].exibida then
//        Continue;
//      Conversa.Mensagens[I].exibida := True;
//      Result := Result + [Conversa.Mensagens[I]];
//    end;
//  finally
//    AddLog('Fim: ExibirMensagem');
//  end;
//end;

//function TDadosApp.MensagensParaAtualizar(iConversa: Integer): String;
//var
//  Conversa: TDadosConversa;
//  I: Integer;
//begin
//  AddLog('Início: MensagensParaAtualizar');
//  try
//    Result := '';
//    if ObtemConversa(iConversa, Conversa) then
//    for I := Pred(Conversa.Mensagens.Count) downto 0 do
//      if not Conversa.Mensagens[I].Visualizada or not Conversa.Mensagens[I].Recebida then
//        Result := Result + IfThen(not Result.Trim.IsEmpty, ',') + Conversa.Mensagens[I].ID.ToString;
//  finally
//    AddLog('Fim: MensagensParaAtualizar');
//  end;
//end;

//function TDadosApp.MensagensParaNotificar(iConversa: Integer): TMensagens;
//var
//  Conversa: TDadosConversa;
//  I: Integer;
//begin
//  AddLog('Início: MensagensParaNotificar');
//  try
//    if not ObtemConversa(iConversa, Conversa) then Exit;
//    Result := [];
//    for I := Pred(Conversa.Mensagens.Count) downto 0 do
//    begin
//      if Conversa.Mensagens[I].Notificada then
//        Continue;
//      Conversa.Mensagens[I].Notificada := True;
//      Result := [Conversa.Mensagens[I]] + Result;
//    end;
//  finally
//    AddLog('Fim: MensagensParaNotificar');
//  end;
//end;

//{ TDadosConversa }
//constructor TDadosConversa.Create;
//begin
//  inherited;
//  Mensagens := TObjectList<TMensagem>.Create;
//end;
//
//destructor TDadosConversa.Destroy;
//begin
//  FreeAndNil(Mensagens);
//  inherited;
//end;
//
//class function TDadosConversa.New: TDadosConversa;
//begin
//  Result := TDadosConversa.Create;
//end;
//
//procedure TDadosConversa.AdicionaMensagem(Mensagem: TMensagem);
//var
//  I: Integer;
//begin
//  AddLog('Início: AdicionaMensagem');
//  try
//    for I := 0 to Pred(Mensagens.Count) do
//    begin
//      if Mensagens[I].ID = Mensagem.id then
//      begin
//        if Mensagem.exibida and not Mensagens[I].exibida then
//          Mensagens[I].exibida := True;
//        Exit;
//      end;
//    end;
//    Mensagens.Add(Mensagem);
//    Dados.AtualizarContador;
//  finally
//    AddLog('Fim: AdicionaMensagem');
//  end;
//end;

end.
