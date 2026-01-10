// Eduardo/Daniel - 17/05/2025
unit Conversa.Proxy.Tipos;

interface

uses
  System.SysUtils,
  System.JSON.Serializers,
  REST.API;

type
  {$SCOPEDENUMS ON}
  TResposta<T> = record
    Status: TResponseStatus;
    Erro: String;
    Dados: T;
  end;

  TRespostaErro = TResposta<Integer>;

  TDispositivo = record
    id: Integer;
    nome: String;
    modelo: String;
    versao_so: String;
    plataforma: String;
    usuario_id: Integer;
  end;

  TRespostaDispositivo = TResposta<TDispositivo>;

  TRespostaLogin = record
    id: Integer;
    nome: String;
    email: String;
    telefone: String;
    token: String;
    dispositivo: TDispositivo;
  end;

  TContato = record
    id: Integer;
    nome: String;
    login: String;
    email: String;
    telefone: String;
  end;
  TContatos = TArray<TContato>;

  TConversa = record
    id: Integer;
    descricao: String;
    tipo: Integer;
    inserida: TDatetime;
    nome: String;
    destinatario_id: Integer;
    mensagem_id: Integer;
    ultima_mensagem: TDatetime;
    ultima_mensagem_texto: String;
    mensagens_sem_visualizar: Integer;
    usuarios: TContatos;
  end;
  TConversas = TArray<TConversa>;
  TRespostaConversa = TResposta<TConversa>;
  TRespostaConversas = TResposta<TConversas>;

  TReqUsuario = record
    nome: String;
    login: String;
    email: String;
    telefone: String;
    senha: String;
  end;

  TReqMensagemConteudo = record
    ordem: Integer;
    tipo: Integer;
    conteudo: String;
  end;

  TReqMensagem = record
//    [JsonIgnoreAttribute]
//    local_id: Integer;
    conversa_id: Integer;
    conteudos: TArray<TReqMensagemConteudo>;
  end;

  TRespostaDownloadAnexo = TResposta<TBytes>;

  TMensagemConteudo = record
    id: Integer;
    tipo: Integer;
    ordem: Integer;
    conteudo: String;
    nome: String;
    extensao: String;
  end;
  TMensagemConteudos = TArray<TMensagemConteudo>;
  TMensagem = record
//    local_id: Integer;
    id: Integer;
    remetente_id: Integer;
    remetente: String;
    conversa_id: Integer;
    inserida: TDateTime;
    alterada: TDateTime;
    recebida: Boolean;
    visualizada: Boolean;
    reproduzida: Boolean;
    conteudos: TMensagemConteudos;
  end;
  TMensagens = TArray<TMensagem>;
  TRespostaMensagem = TResposta<TMensagem>;
  TRespostaMensagens = TResposta<TMensagens>;

  TMensagemStatus = record
    conversa_id: Integer;
    mensagem_id: Integer;
    recebida: Boolean;
    visualizada: Boolean;
    reproduzida: Boolean;
  end;
  TMensagensStatus = TArray<TMensagemStatus>;
  TRespostaMensagensStatus = TResposta<TMensagensStatus>;

  TMensagemNova = record
    conversa_id: Integer;
    mensagem_id: Integer;
  end;
  TMensagensNovas = TArray<TMensagemNova>;
  TRespostaMensagensNovas = TResposta<TMensagensNovas>;

  TChamadaStatus = (
    Desconhecido = 0,
    Iniciada = 1,
    Recusada = 2,
    EmAndamento = 3,
    Finalizada = 4,
    Perdida = 5,
    Cancelada = 6
  );
  TChamadaTipo = (
    Desconhecido = 0,
    Simples = 1,
    Grupo = 2
  );
  TChamada = record
    id: Integer;
    iniciada: TDateTime;
    finalizada: TDateTime;
    conversa_id: Integer;
    status: TChamadaStatus;
    tipo: TChamadaTipo;
  end;
  TRespostaChamada = TResposta<TChamada>;

  TChamadaStatusUsuario = (
    Desconhecido = 0,
    Pendente = 1,
    Recusou = 2,
    Entrou = 3,
    Saiu = 4,
    Desconectou = 5
  );
  TChamadaDadosUsuario = record
    usuario_id: Integer;
    usuario_nome: string;
    status: TChamadaStatusUsuario;
    adicionado_por: Integer;
    adicinoado_em: TDateTime;
    recusou_em: TDateTime;
    entrou_em: TDateTime;
    saiu_em: TDateTime;
  end;
  TChamadaDados = record
    id: Integer;
    iniciada: TDateTime;
    finalizada: TDateTime;
    conversa_id: Integer;
    status: TChamadaStatus;
    tipo: TChamadaTipo;
    usuarios: TArray<TChamadaDadosUsuario>;
  end;
  TRespostaChamadaDados = TResposta<TChamadaDados>;

implementation

end.
