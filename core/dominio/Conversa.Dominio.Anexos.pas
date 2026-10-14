unit Conversa.Dominio.Anexos;

{ Modelos de anexo (doc 01 §8). O identificador é o SHA-256 em hexadecimal (64 caracteres) do conteúdo;
  como vira nome de arquivo no cache, só é usado depois de validado (#26). }

interface

uses
  Conversa.Dominio.Modelos;

type
  /// <summary>Resposta de PUT /anexo. Sem o anexo: URL de UPLOAD (PUT, 300 s). Já existente: URL de DOWNLOAD
  /// (GET, 600 s), id em texto e sem upload_status (o mapeador já converte o id).</summary>
  TAnexoRegistrado = record
    Existe: Boolean;
    Id: Int64;
    Url: string;
    UploadStatus: Integer;
  end;

  /// <summary>GET /anexo/existe.</summary>
  TAnexoExistente = record
    Existe: Boolean;
    Id: Int64;
    Identificador: string;
    Tipo: TTipoConteudo;
    Tamanho: Int64;
    /// <summary>0 pendente, 1 concluído, 2 falhou.</summary>
    UploadStatus: Integer;
  end;

  /// <summary>Item de GET /anexos (galeria da conversa).</summary>
  TAnexoGaleria = record
    AnexoId: Int64;
    Identificador: string;
    Nome: string;
    Extensao: string;
    Tamanho: Int64;
    CriadoEm: TDateTime;
    Tipo: TTipoConteudo;
    MensagemId: Int64;
    ConversaId: Int64;
    ConversaDescricao: string;
    AutorId: Int64;
    AutorNome: string;
    Url: string;
  end;

  /// <summary>GET/PUT /anexo/transcricao.</summary>
  TTranscricao = record
    Status: TStatusTranscricao;
    Texto: string;
    Erro: string;
  end;

  TIdentificadorAnexo = record
    /// <summary>64 caracteres hexadecimais minúsculos (^[0-9a-f]{64}$). Nada fora disso vira caminho de arquivo.</summary>
    class function Valido(const AIdentificador: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TIdentificadorAnexo.Valido(const AIdentificador: string): Boolean;
var
  C: Char;
begin
  if Length(AIdentificador) <> 64 then
    Exit(False);
  for C in AIdentificador do
    if not CharInSet(C, ['0'..'9', 'a'..'f']) then
      Exit(False);
  Result := True;
end;

end.
