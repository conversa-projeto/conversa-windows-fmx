unit Conversa.Dominio.Modelos;

{ Modelos de domínio: sessão, contatos, conversas, mensagens, status e atividades (doc 01 §2, §10, §11, §12).

  - Records imutáveis na prática: quem lê não altera; o repositório monta um novo.
  - Datas em UTC (TDateTime); 0 = sem data (null no servidor).
  - Os enums começam em 0 e são contíguos: Ord(valor) = código do servidor. Código desconhecido vira
    Desconhecido e o número original fica em TipoBruto (o app nunca quebra com tipo novo, #22).
  - mensagem_referencia é recursiva no servidor (até 5 níveis); aqui vira uma lista de níveis:
    Referencias[0] é a mensagem referenciada; Referencias[1], a que ela referencia; e assim por diante. }

interface

type
  {$SCOPEDENUMS ON}
  TTipoConteudo = (Desconhecido, Texto, Imagem, Arquivo, Audio, Gravacao, Chamada, Figurinha, Enquete);
  TTipoConversa = (Desconhecida, Direta, Grupo);
  TTipoReferencia = (Nenhuma, Resposta, Encaminhada);
  TStatusTranscricao = (Nenhuma, Processando, Concluida, Erro);
  TTipoAtividade = (Desconhecida, Reacao, Resposta, Mencao, ChamadaPerdida);
  {$SCOPEDENUMS OFF}

  TCodigos = record
    class function TipoConteudo(ACodigo: Int64): TTipoConteudo; static;
    class function TipoConversa(ACodigo: Int64): TTipoConversa; static;
    class function TipoReferencia(ACodigo: Int64): TTipoReferencia; static;
    class function StatusTranscricao(ACodigo: Int64): TStatusTranscricao; static;
    class function TipoAtividade(ACodigo: Int64): TTipoAtividade; static;
  end;

  /// <summary>Resposta do POST /login (§2.1). Não vem login nem avatar_url.</summary>
  TUsuarioLogado = record
    Id: Int64;
    Nome: string;
    Email: string;
    Telefone: string;
    AvatarIdentificador: string;
    DispositivoId: Int64;
    Token: string;
  end;

  TDispositivo = record
    Id: Int64;
    Nome: string;
    Modelo: string;
    VersaoSo: string;
    Plataforma: string;
    Ativo: Boolean;
  end;

  /// <summary>GET /usuario/contatos (todos os usuários, sem avatar).</summary>
  TContato = record
    Id: Int64;
    Nome: string;
    Login: string;
    Email: string;
    Telefone: string;
  end;

  /// <summary>GET /conversa/usuarios. VinculoId é o conversa_usuario.id (usado para sair do grupo).</summary>
  TMembro = record
    VinculoId: Int64;
    UsuarioId: Int64;
    Nome: string;
    AvatarUrl: string;
  end;

  /// <summary>Item de GET /conversas (§11.2).</summary>
  TConversa = record
    Id: Int64;
    Descricao: string;
    Tipo: TTipoConversa;
    TipoBruto: Integer;
    Inserida: TDateTime;
    /// <summary>Só em direta: o outro membro.</summary>
    Nome: string;
    DestinatarioId: Int64;
    AvatarUrl: string;
    UltimaMensagemId: Int64;
    UltimaMensagemEm: TDateTime;
    /// <summary>Cru: "Mensagem oculta", texto com @[Nome](id), "imagem", "figurinha", "enquete" ou "".</summary>
    UltimaMensagemTexto: string;
    MensagensSemVisualizar: Integer;
    /// <summary>1 = primeira; 0 = não fixada.</summary>
    FixadaOrdem: Integer;
    ArquivadaEm: TDateTime;
    /// <summary>descricao || nome || "Conversa #id" (como o web).</summary>
    function Titulo: string;
    function Fixada: Boolean;
    function Arquivada: Boolean;
  end;

  TConteudo = record
    Id: Int64;
    Ordem: Integer;
    Tipo: TTipoConteudo;
    TipoBruto: Integer;
    /// <summary>Texto (1), identificador do anexo (2–5), JSON (6), pacote/nome (7) ou id da enquete (8).</summary>
    Conteudo: string;
    Nome: string;
    Extensao: string;
    TranscricaoStatus: TStatusTranscricao;
    Transcricao: string;
    function EhAnexo: Boolean;
  end;

  TUsuarioReacao = record
    UsuarioId: Int64;
    Nome: string;
    ReagidoEm: TDateTime;
    AvatarUrl: string;
  end;

  TReacao = record
    Emoji: string;
    Quantidade: Integer;
    Reagiu: Boolean;
    Usuarios: TArray<TUsuarioReacao>;
  end;

  /// <summary>Um nível de mensagem_referencia (MensagemResumida).</summary>
  TMensagemResumida = record
    /// <summary>Como a mensagem anterior da cadeia aponta para esta (resposta ou encaminhamento).</summary>
    TipoReferencia: TTipoReferencia;
    /// <summary>False quando a referenciada não existe mais (o servidor omite "mensagem").</summary>
    Existe: Boolean;
    Id: Int64;
    ConversaId: Int64;
    Remetente: string;
    Inserida: TDateTime;
    ExcluidaEm: TDateTime;
    Conteudos: TArray<TConteudo>;
    function Oculta: Boolean;
  end;

  /// <summary>MensagemResposta de GET /mensagens, /pesquisar (§10.2).</summary>
  TMensagem = record
    Id: Int64;
    RemetenteId: Int64;
    /// <summary>Só o primeiro nome.</summary>
    Remetente: string;
    ConversaId: Int64;
    Inserida: TDateTime;
    VisivelEm: TDateTime;
    ExcluidaEm: TDateTime;
    Recebida: Boolean;
    Visualizada: Boolean;
    Reproduzida: Boolean;
    Conteudos: TArray<TConteudo>;
    Referencias: TArray<TMensagemResumida>;
    Reacoes: TArray<TReacao>;
    /// <summary>coalesce(visivel_em, inserida): a data que ordena e que aparece na tela.</summary>
    function DataEfetiva: TDateTime;
    /// <summary>"Ocultar" é exclusão lógica: o servidor ainda manda o conteúdo original; a tela esconde.</summary>
    function Oculta: Boolean;
    function TemReferencia: Boolean;
    function TipoReferencia: TTipoReferencia;
  end;

  /// <summary>GET /mensagem/status: booleanos agregados de todos os destinatários.</summary>
  TStatusMensagem = record
    ConversaId: Int64;
    MensagemId: Int64;
    Recebida: Boolean;
    Visualizada: Boolean;
    Reproduzida: Boolean;
    ExcluidaEm: TDateTime;
  end;

  /// <summary>GET /mensagem/status/detalhe (só o autor): datas por destinatário.</summary>
  TStatusDestinatario = record
    UsuarioId: Int64;
    Nome: string;
    Recebida: TDateTime;
    Visualizada: TDateTime;
    Reproduzida: TDateTime;
  end;

  /// <summary>Item de GET /mensagens/novas: o cursor avança para Ate.</summary>
  TNovaMensagem = record
    ConversaId: Int64;
    MensagemId: Int64;
    Ate: TDateTime;
  end;

  /// <summary>Item de GET /atividades (§12).</summary>
  TAtividade = record
    Id: Int64;
    Tipo: TTipoAtividade;
    TipoBruto: Integer;
    CriadoEm: TDateTime;
    Nova: Boolean;
    AutorId: Int64;
    AutorNome: string;
    AutorAvatarUrl: string;
    ConversaId: Int64;
    ConversaTipo: TTipoConversa;
    ConversaDescricao: string;
    MensagemId: Int64;
    ConteudoTipo: TTipoConteudo;
    /// <summary>Primeiro texto da mensagem, numa linha, menções como @Nome, até 120 caracteres.</summary>
    Texto: string;
    ChamadaId: Int64;
    ChamadaTipo: Integer;
    Emoji: string;
  end;

implementation

uses
  System.SysUtils;

{ TCodigos }

class function TCodigos.TipoConteudo(ACodigo: Int64): TTipoConteudo;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TTipoConteudo))) then
    Result := TTipoConteudo(ACodigo)
  else
    Result := TTipoConteudo.Desconhecido;
end;

class function TCodigos.TipoConversa(ACodigo: Int64): TTipoConversa;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TTipoConversa))) then
    Result := TTipoConversa(ACodigo)
  else
    Result := TTipoConversa.Desconhecida;
end;

class function TCodigos.TipoReferencia(ACodigo: Int64): TTipoReferencia;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TTipoReferencia))) then
    Result := TTipoReferencia(ACodigo)
  else
    Result := TTipoReferencia.Nenhuma;
end;

class function TCodigos.StatusTranscricao(ACodigo: Int64): TStatusTranscricao;
begin
  if (ACodigo >= 0) and (ACodigo <= Ord(High(TStatusTranscricao))) then
    Result := TStatusTranscricao(ACodigo)
  else
    Result := TStatusTranscricao.Nenhuma;
end;

class function TCodigos.TipoAtividade(ACodigo: Int64): TTipoAtividade;
begin
  if (ACodigo >= 1) and (ACodigo <= Ord(High(TTipoAtividade))) then
    Result := TTipoAtividade(ACodigo)
  else
    Result := TTipoAtividade.Desconhecida;
end;

{ TConversa }

function TConversa.Titulo: string;
begin
  if Trim(Descricao) <> '' then
    Result := Trim(Descricao)
  else if Trim(Nome) <> '' then
    Result := Trim(Nome)
  else
    Result := 'Conversa #' + IntToStr(Id);
end;

function TConversa.Fixada: Boolean;
begin
  Result := FixadaOrdem > 0;
end;

function TConversa.Arquivada: Boolean;
begin
  Result := ArquivadaEm <> 0;
end;

{ TConteudo }

function TConteudo.EhAnexo: Boolean;
begin
  Result := Tipo in [TTipoConteudo.Imagem, TTipoConteudo.Arquivo, TTipoConteudo.Audio, TTipoConteudo.Gravacao];
end;

{ TMensagemResumida }

function TMensagemResumida.Oculta: Boolean;
begin
  Result := ExcluidaEm <> 0;
end;

{ TMensagem }

function TMensagem.DataEfetiva: TDateTime;
begin
  if VisivelEm <> 0 then
    Result := VisivelEm
  else
    Result := Inserida;
end;

function TMensagem.Oculta: Boolean;
begin
  Result := ExcluidaEm <> 0;
end;

function TMensagem.TemReferencia: Boolean;
begin
  Result := Length(Referencias) > 0;
end;

function TMensagem.TipoReferencia: TTipoReferencia;
begin
  if Length(Referencias) > 0 then
    Result := Referencias[0].TipoReferencia
  else
    Result := TTipoReferencia.Nenhuma;
end;

end.
