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
  Conversa.Dados,
  Conversa.Log;

{ TDadosApp }

function TDadosApp.ObtemConversa(const iConversa: Integer; var Conversa: TPDadosConversa): Boolean;
var
  I: Integer;
begin
  AddLog('Início: ObtemConversa');
  try
    Result := False;
    for I := Low(Conversas) to High(Conversas) do
    begin
      if Conversas[I].ID = iConversa then
      begin
        Conversa := @Conversas[I];
        Exit(True);
      end;
    end;
  finally
    AddLog('Fim: ObtemConversa');
  end;
end;

procedure TDadosApp.AdicionaMensagem(iConversa: Integer; Mensagem: TPMensagem);
var
  P: TPDadosConversa;
  Conversa: TDadosConversa;
begin
  AddLog('Início: AdicionaMensagem');
  try
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
  finally
    AddLog('Fim: AdicionaMensagem');
  end;
end;

function TDadosApp.UltimaMensagemConversa(iConversa: Integer): Integer;
var
  P: TPDadosConversa;
begin
  AddLog('Início: UltimaMensagemConversa');
  try
    if ObtemConversa(iConversa, P) then
      Result := P.FUltimaMensagem
    else
      Result := 0;
  finally
    AddLog('Fim: UltimaMensagemConversa');
  end;
end;

function TDadosApp.MensagemSemVisualizar: Integer;
var
  Convera: TDadosConversa;
begin
  AddLog('Início: MensagemSemVisualizar');
  try
    Result := 0;
    for Convera in Conversas do
      Inc(Result, MensagemSemVisualizar(Convera.ID));
  finally
    AddLog('Fim: MensagemSemVisualizar');
  end;
end;

function TDadosApp.MensagemSemVisualizar(iConversa: Integer): Integer;
var
  Conversa: TPDadosConversa;
  Mensagem: TMensagem;
begin
  AddLog('Início: MensagemSemVisualizar(Integer)');
  try
    Result := 0;
    if ObtemConversa(iConversa, Conversa) then
      for Mensagem in Conversa.Mensagens do
        if (Mensagem.Lado <> TLado.Direito) and not Mensagem.visualizada then
          Inc(Result);
  finally
    AddLog('Fim: MensagemSemVisualizar(Integer)');
  end;
end;

function TDadosApp.Mensagens(iConversa: Integer; iInicio: Integer): TPMensagems;
var
  Conversa: TPDadosConversa;
  Mensagem: TMensagem;
begin
  AddLog('Início: Mensagens');
  try
    Result := [];
    if not ObtemConversa(iConversa, Conversa) then Exit;
    for Mensagem in Conversa.Mensagens do
      if Mensagem.id >= iInicio then
        Result := Result + [@Mensagem];
  finally
    AddLog('Fim: Mensagens');
  end;
end;

function TDadosApp.ExibirMensagem(iConversa: Integer; ApenasPendente: Boolean): TPMensagems;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  AddLog('Início: ExibirMensagem');
  try
    Result := [];
    if not ObtemConversa(iConversa, Conversa) then Exit;

    for I := 0 to Pred(Length(Conversa.Mensagens)) do
    begin
      if ApenasPendente and Conversa.Mensagens[I].exibida then
        Continue;

      Conversa.Mensagens[I].exibida := True;
      Result := Result + [@Conversa.Mensagens[I]];
    end;
  finally
    AddLog('Fim: ExibirMensagem');
  end;
end;

function TDadosApp.MensagensParaAtualizar(iConversa: Integer): String;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  AddLog('Início: MensagensParaAtualizar');
  try
    Result := '';
    if ObtemConversa(iConversa, Conversa) then
    for I := Pred(Length(Conversa.Mensagens)) downto 0 do
      if not Conversa.Mensagens[I].Visualizada or not Conversa.Mensagens[I].Recebida then
        Result := Result + IfThen(not Result.Trim.IsEmpty, ',') + Conversa.Mensagens[I].ID.ToString;
  finally
    AddLog('Fim: MensagensParaAtualizar');
  end;
end;

function TDadosApp.MensagensParaNotificar(iConversa: Integer): TPMensagems;
var
  Conversa: TPDadosConversa;
  I: Integer;
begin
  AddLog('Início: MensagensParaNotificar');
  try
    if not ObtemConversa(iConversa, Conversa) then Exit;
    Result := [];

    for I := Pred(Length(Conversa.Mensagens)) downto 0 do
    begin
      if Conversa.Mensagens[I].Notificada then
        Continue;

      Conversa.Mensagens[I].Notificada := True;
      Result := [@Conversa.Mensagens[I]] + Result;
    end;
  finally
    AddLog('Fim: MensagensParaNotificar');
  end;
end;

{ TDadosConversa }

procedure TDadosConversa.AdicionaMensagem(Mensagem: TMensagem);
var
  I: Integer;
begin
  AddLog('Início: AdicionaMensagem');
  try
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
  finally
    AddLog('Fim: AdicionaMensagem');
  end;
end;

end.

