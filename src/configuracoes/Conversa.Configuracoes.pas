unit Conversa.Configuracoes;

interface

uses
  System.SysUtils;

type

  TConversaConfiguracoes = class
  private
    constructor Create;
  public
    Tema: String;
    class function Instance: TConversaConfiguracoes;
  end;

implementation

var
  FInstance: TConversaConfiguracoes;

{ TConversaConfiguracoes }

constructor TConversaConfiguracoes.Create;
begin
  Tema := '';
end;

class function TConversaConfiguracoes.Instance: TConversaConfiguracoes;
begin
  Result := FInstance;
end;

initialization
  FInstance := TConversaConfiguracoes.Create;

finalization
  FreeAndNil(FInstance);

end.
