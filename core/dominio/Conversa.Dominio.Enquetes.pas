unit Conversa.Dominio.Enquetes;

{ Votação em grupo (doc 01 §10.13). O servidor não avisa quando a data final passa: EstaEncerrada compara
  encerra_em com a hora atual (pegadinha 50). }

interface

type
  TVotante = record
    Id: Int64;
    Nome: string;
  end;

  TOpcaoEnquete = record
    Id: Int64;
    Texto: string;
    Votantes: TArray<TVotante>;
  end;

  TEnquete = record
    Id: Int64;
    ConversaId: Int64;
    MensagemId: Int64;
    Pergunta: string;
    Multipla: Boolean;
    CriadoPor: Int64;
    EncerraEm: TDateTime;
    EncerradaEm: TDateTime;
    Encerrada: Boolean;
    PodeEncerrar: Boolean;
    PodeAlterarPrazo: Boolean;
    Opcoes: TArray<TOpcaoEnquete>;
    /// <summary>Pessoas distintas (na múltipla, as porcentagens podem somar mais de 100%).</summary>
    TotalVotantes: Integer;
    MeusVotos: TArray<Int64>;
    /// <summary>Encerrada no servidor ou com a data final já vencida.</summary>
    function EstaEncerrada(AAgoraUtc: TDateTime): Boolean;
    function VoteiEm(AOpcaoId: Int64): Boolean;
    /// <summary>round(votos / total_votantes × 100), como o web.</summary>
    function Porcentagem(AOpcaoIndice: Integer): Integer;
  end;

implementation

{ TEnquete }

function TEnquete.EstaEncerrada(AAgoraUtc: TDateTime): Boolean;
begin
  Result := Encerrada or ((EncerraEm <> 0) and (EncerraEm <= AAgoraUtc));
end;

function TEnquete.VoteiEm(AOpcaoId: Int64): Boolean;
var
  V: Int64;
begin
  for V in MeusVotos do
    if V = AOpcaoId then
      Exit(True);
  Result := False;
end;

function TEnquete.Porcentagem(AOpcaoIndice: Integer): Integer;
begin
  if (TotalVotantes <= 0) or (AOpcaoIndice < 0) or (AOpcaoIndice > High(Opcoes)) then
    Exit(0);
  Result := Round(Length(Opcoes[AOpcaoIndice].Votantes) / TotalVotantes * 100);
end;

end.
