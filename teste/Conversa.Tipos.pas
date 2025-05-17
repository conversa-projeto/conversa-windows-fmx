// Eduardo/Daniel - 17/05/2025
unit Conversa.Tipos;

interface

uses
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

implementation

end.
