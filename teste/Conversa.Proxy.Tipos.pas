// Eduardo/Daniel - 17/05/2025
unit Conversa.Proxy.Tipos;

interface

uses
  System.SysUtils,
  REST.API;

type
  TResposta<T> = record
    Status: TResponseStatus;
    Erro: String;
    Dados: T;
  end;

  TRespostaErro = TResposta<Integer>;

  TRespostaLogin = record
    id: Integer;
    nome: String;
    email: String;
    telefone: String;
    token: String;
  end;

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
  end;
  TConversas = TArray<TConversa>;
  TRespostaConversas = TResposta<TConversas>;

  TContato = record
    id: Integer;
    nome: String;
    login: String;
    email: String;
    telefone: String;
  end;

  TContatos = TArray<TContato>;

  TDeviceInfo = record
    DeviceName: String;
    Model: String;
    OSVersion: String;
    Platform: String;
  end;

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
    conversa_id: Integer;
    inserida: TDateTime;
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
  TMensagem = record
    id: Integer;
    remetente_id: Integer;
    remetente: String;
    conversa_id: Integer;
    inserida: TDateTime;
    alterada: TDateTime;
    recebida: Boolean;
    visualizada: Boolean;
    reproduzida: Boolean;
    conteudos: TArray<TMensagemConteudo>;
  end;
  TMensagens = TArray<TMensagem>;
  TRespostaMensagens = TResposta<TMensagens>;

  TMensagemStatus = record
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

implementation

end.
