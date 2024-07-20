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
    Mensagens: TArray<TMensagem>;
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
    procedure AdicionaMensagem(iConversa: Integer; Mensagem: TMensagem);
    function Mensagens(iConversa, iInicio: Integer): TArray<TMensagem>;
  end;

implementation

uses
  System.Math;

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

procedure TDadosApp.AdicionaMensagem(iConversa: Integer; Mensagem: TMensagem);
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
  P.AdicionaMensagem(Mensagem);
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

function TDadosApp.Mensagens(iConversa: Integer; iInicio: Integer): TArray<TMensagem>;
var
  Conversa: TPDadosConversa;
  Mensagem: TMensagem;
begin
  Result := [];
  if not ObtemConversa(iConversa, Conversa) then Exit;
  for Mensagem in Conversa.Mensagens do
    if Mensagem.id >= iInicio then
      Result := Result + [Mensagem];
end;

{ TDadosConversa }
procedure TDadosConversa.AdicionaMensagem(Mensagem: TMensagem);
var
  I: Integer;
begin
  for I := Low(Mensagens) to High(Mensagens) do
    if Mensagens[I].ID = Mensagem.id then
      Exit;
  Mensagens := Mensagens + [Mensagem];
end;

end.
