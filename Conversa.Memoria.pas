// Eduardo - 13/07/2024
unit Conversa.Memoria;

interface

type
  TDadosMensagem = record
  public
    ID: Integer;
  end;

  TDadosConversa = record
  private
    FUltimaMensagem: Integer;
  public
    ID: Integer;
    Mensagens: TArray<TDadosMensagem>;
    procedure AdicionaMensagem(iMensagem: Integer);
  end;

  TPDadosConversa = ^TDadosConversa;

  TDadosApp = record
  private
    FUltimaMensagem: Integer;
    function ObtemConversa(const iConversa: Integer; var Conversa: TPDadosConversa): Boolean;
  public
    Conversas: TArray<TDadosConversa>;
    function UltimaMensagem: Integer; overload;
    function UltimaMensagem(iConversa: Integer): Integer; overload;
    procedure AdicionaMensagem(iConversa, iMensagem: Integer);
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

procedure TDadosApp.AdicionaMensagem(iConversa, iMensagem: Integer);
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

  P.AdicionaMensagem(iMensagem);

  P.FUltimaMensagem := Max(iMensagem, P.FUltimaMensagem);
  FUltimaMensagem := Max(iMensagem, FUltimaMensagem);
end;

function TDadosApp.UltimaMensagem(iConversa: Integer): Integer;
var
  P: TPDadosConversa;
begin
  if ObtemConversa(iConversa, P) then
    Result := P.FUltimaMensagem
  else
    Result := 0;
end;

function TDadosApp.UltimaMensagem: Integer;
begin
  Result := FUltimaMensagem;
end;

{ TDadosConversa }

procedure TDadosConversa.AdicionaMensagem(iMensagem: Integer);
var
  I: Integer;
  Mensagem: TDadosMensagem;
begin
  for I := Low(Mensagens) to High(Mensagens) do
    if Mensagens[I].ID = iMensagem then
      Exit;

  Mensagem := Default(TDadosMensagem);
  Mensagem.ID := iMensagem;
  Mensagens := Mensagens + [Mensagem];
end;

end.
