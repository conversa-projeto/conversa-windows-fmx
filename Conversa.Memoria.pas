// Eduardo - 13/07/2024
unit Conversa.Memoria;

interface

uses
  Mensagem.Tipos;

type
  TDadosConversa = record
  private
    FUltimaMensagem: Integer;
  public
    ID: Integer;
    Mensagens: TMensagens;
    procedure AdicionaMensagem(Mensagem: TMensagem);
  end;
  TPDadosConversa = ^TDadosConversa;

  TDadosApp = record
  private
    function ObtemConversa(const iConversa: Integer; var Conversa: TPDadosConversa): Boolean;
  public
    Conversas: TArray<TDadosConversa>;
    UltimaMensagemNotificada: Integer;
    function UltimaMensagemConversa(iConversa: Integer): Integer;
    procedure AdicionaMensagem(iConversa: Integer; Mensagem: TPMensagem);
    function Mensagens(iConversa: Integer; iInicio: Integer): TPMensagems;
    function ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TPMensagems;
    function MensagemSemVisualizar: Integer; overload;
    function MensagemSemVisualizar(iConversa: Integer): Integer; overload;
    function MensagensParaNotificar(iConversa: Integer): TPMensagems;
    function MensagensParaAtualizar(iConversa: Integer): String;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  Winapi.Windows,
  Conversa.Dados;

{ TDadosApp }

function TDadosApp.ObtemConversa(const iConversa: Integer; var Conversa: TPDadosConversa): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(Conversas) to High(Conversas) do
  begin
    if Conversas[I].ID = iConversa then
    begin
      Conversa := @Conversas[I];
      Exit(True);
    end;
  end;
end;

procedure TDadosApp.AdicionaMensagem(iConversa: Integer; Mensagem: TPMensagem);
var
  P: TPDadosConversa;
  Conversa: TDadosConversa;
begin
  if not ObtemConversa(iConversa, P) then
  begin
    Conversa := Default(TDadosConversa);
    Conversa.ID := iConversa;
    Conversas := Conversas + [Conversa];
    P := @Conversa;
  end;
  P.AdicionaMensagem(Mensagem^);
  if Mensagem.lado = TLado.Esquerdo then
    P.FUltimaMensagem := Max(Mensagem.id, P.FUltimaMensagem);
  UltimaMensagemNotificada := Max(Mensagem.id, UltimaMensagemNotificada);
end;

function TDadosApp.UltimaMensagemConversa(iConversa: Integer): Integer;
var
  P: TPDadosConversa;
begin
  if ObtemConversa(iConversa, P) then
    Result := P.FUltimaMensagem
  else
    Result := 0;
end;

function TDadosApp.MensagemSemVisualizar: Integer;
var
  Convera: TdadosConversa;
begin
  Result := 0;
  for Convera in Conversas do
    Inc(Result, MensagemSemVisualizar(Convera.ID));
end;

function TDadosApp.MensagemSemVisualizar(iConversa: Integer): Integer;
var
  Conversa: TPDadosConversa;
  Mensagem: TMensagem;
begin
  Result := 0;
  if ObtemConversa(iConversa, Conversa) then
    for Mensagem in Conversa.Mensagens do
      if (Mensagem.Lado <> TLado.Direito) and not Mensagem.visualizada then
        Inc(Result);
end;

function TDadosApp.Mensagens(iConversa: Integer; iInicio: Integer): TPMensagems;
var
  Conversa: TPDadosConversa;
  Mensagem: TMensagem;
begin
  Result := [];
  if not ObtemConversa(iConversa, Conversa) then Exit;
  for Mensagem in Conversa.Mensagens do
    if Mensagem.id >= iInicio then
      Result := Result + [@Mensagem];
end;

function TDadosApp.ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TPMensagems;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  Result := [];
  if not ObtemConversa(iConversa, Conversa) then Exit;

  for I := 0 to Pred(Length(Conversa.Mensagens)) do
  begin
    if ApenasPendente and Conversa.Mensagens[I].exibida then
      Continue;

    Conversa.Mensagens[I].exibida := True;
    Result := Result + [@Conversa.Mensagens[I]];
  end;
end;

function TDadosApp.MensagensParaAtualizar(iConversa: Integer): String;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  Result := '';
  if ObtemConversa(iConversa, Conversa) then
  for I := Pred(Length(Conversa.Mensagens)) downto 0 do
    if not Conversa.Mensagens[I].Visualizada or not Conversa.Mensagens[I].Recebida then
      Result := Result + IfThen(not Result.Trim.IsEmpty, ',') + Conversa.Mensagens[I].ID.ToString;
end;

function TDadosApp.MensagensParaNotificar(iConversa: Integer): TPMensagems;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  if not ObtemConversa(iConversa, Conversa) then Exit;
    Result := [];

  for I := Pred(Length(Conversa.Mensagens)) downto 0 do
  begin
    if Conversa.Mensagens[I].Notificada then
      Continue;

    Conversa.Mensagens[I].Notificada := True;
    Result := [@Conversa.Mensagens[I]] + Result;
  end;
end;

{ TDadosConversa }

procedure TDadosConversa.AdicionaMensagem(Mensagem: TMensagem);
var
  I: Integer;
begin
  for I := Low(Mensagens) to High(Mensagens) do
  begin
    if Mensagens[I].ID = Mensagem.id then
    begin
      if Mensagem.exibida and not Mensagens[I].exibida then
        Mensagens[I].exibida := True;
      Exit;
    end;
  end;
  Mensagens := Mensagens + [Mensagem];
  Dados.AtualizarContador;
end;

end.
