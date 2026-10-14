unit Conversa.Testes.Mapeadores;

{ Um teste de desserialização por DTO, com fixture (TODO 1.9). }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesMapeadores = class
  public
    [Test]
    procedure Login;
    [Test]
    procedure ConversasReaisDoServidorDeDesenvolvimento;
    [Test]
    procedure ConversasCasosDificeis;
    [Test]
    procedure MensagemTextoComEmoji;
    [Test]
    procedure MensagemComReferenciaEmDoisNiveisEReacoes;
    [Test]
    procedure MensagemOcultaAgendadaEGravacao;
    [Test]
    procedure MensagemDeChamadaEResumo;
    [Test]
    procedure TiposNovosNaoQuebram;
    [Test]
    procedure MensagemEnviadaUsaUsuarioId;
    [Test]
    procedure StatusEDetalhe;
    [Test]
    procedure NovasMensagens;
    [Test]
    procedure AtividadesReaisECasos;
    [Test]
    procedure Anexos;
    [Test]
    procedure DadosDaChamadaEPendentes;
    [Test]
    procedure HistoricoRealDeChamadas;
    [Test]
    procedure ResumoDeChamadaInvalidoNaoLanca;
    [Test]
    procedure Ice;
    [Test]
    procedure Enquete;
    [Test]
    procedure PermissoesParametrosESip;
    [Test]
    procedure ContatosMembrosEOnline;
    [Test]
    procedure FormatoErradoLancaContratoInvalido;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  Conversa.Contrato.Json,
  Conversa.Contrato.Mapeadores,
  Conversa.Dominio.Modelos,
  Conversa.Dominio.Chamadas,
  Conversa.Dominio.Anexos,
  Conversa.Dominio.Enquetes,
  Conversa.Dominio.Sistema,
  Conversa.Testes.Fixtures;

function Iso(AData: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd" "hh":"nn":"ss"."zzz', AData);
end;

procedure TTestesMapeadores.Login;
var
  U: TUsuarioLogado;
begin
  U := TMapeador.UsuarioLogado(LerFixture('login.json'));
  Assert.AreEqual(Int64(7), U.Id);
  Assert.AreEqual('Ana Souza', U.Nome);
  Assert.AreEqual('', U.Telefone);
  Assert.AreEqual('', U.AvatarIdentificador);
  Assert.AreEqual(Int64(12), U.DispositivoId);
  Assert.StartsWith('eyJ', U.Token);
end;

procedure TTestesMapeadores.ConversasReaisDoServidorDeDesenvolvimento;
var
  L: TArray<TConversa>;
  C: TConversa;
  LFixadas, LArquivadas: Integer;
begin
  L := TMapeador.Conversas(LerFixture('conversas.json'));
  Assert.AreEqual(13, Integer(Length(L)));
  LFixadas := 0;
  LArquivadas := 0;
  for C in L do
  begin
    Assert.IsTrue(C.Id > 0);
    Assert.IsTrue(C.Tipo in [TTipoConversa.Direta, TTipoConversa.Grupo]);
    Assert.AreNotEqual('', C.Titulo);
    if C.Fixada then
      Inc(LFixadas);
    if C.Arquivada then
      Inc(LArquivadas);
  end;
  Assert.AreEqual(1, LFixadas);
  Assert.AreEqual(1, LArquivadas);
end;

procedure TTestesMapeadores.ConversasCasosDificeis;
var
  L: TArray<TConversa>;
begin
  L := TMapeador.Conversas(LerFixture('conversas-casos.json'));
  Assert.AreEqual(3, Integer(Length(L)));
  Assert.AreEqual('Bruno Lima', L[0].Titulo);
  Assert.IsTrue(L[0].Tipo = TTipoConversa.Direta);
  Assert.AreEqual(Int64(8), L[0].DestinatarioId);
  Assert.AreEqual(1, L[0].FixadaOrdem);
  Assert.AreEqual(3, L[0].MensagensSemVisualizar);
  Assert.AreEqual('2026-10-06 12:00:00.123', Iso(L[0].UltimaMensagemEm));
  Assert.AreEqual('oi @[Ana](7)', L[0].UltimaMensagemTexto);
  // grupo sem descrição, sem mensagem, arquivado
  Assert.AreEqual('Conversa #43', L[1].Titulo);
  Assert.IsTrue(L[1].Tipo = TTipoConversa.Grupo);
  Assert.IsTrue(L[1].Arquivada);
  Assert.IsFalse(L[1].Fixada);
  Assert.IsTrue(L[1].UltimaMensagemEm = 0);
  Assert.AreEqual(Int64(0), L[1].DestinatarioId);
  Assert.AreEqual('enquete', L[2].UltimaMensagemTexto);
end;

procedure TTestesMapeadores.MensagemTextoComEmoji;
var
  L: TArray<TMensagem>;
begin
  L := TMapeador.Mensagens(LerFixture('mensagens.json'));
  Assert.AreEqual(6, Integer(Length(L)));
  Assert.AreEqual(Int64(99), L[0].Id);
  Assert.AreEqual('Bruno', L[0].Remetente);
  Assert.AreEqual(1, Integer(Length(L[0].Conteudos)));
  Assert.IsTrue(L[0].Conteudos[0].Tipo = TTipoConteudo.Texto);
  Assert.AreEqual('Olá, tudo bem? 😀', L[0].Conteudos[0].Conteudo);
  Assert.IsFalse(L[0].TemReferencia);
  Assert.AreEqual(0, Integer(Length(L[0].Reacoes)));
end;

procedure TTestesMapeadores.MensagemComReferenciaEmDoisNiveisEReacoes;
var
  M: TMensagem;
begin
  M := TMapeador.Mensagens(LerFixture('mensagens.json'))[1];
  Assert.AreEqual(Int64(7), M.RemetenteId);
  Assert.IsTrue(M.TipoReferencia = TTipoReferencia.Resposta);
  Assert.AreEqual(2, Integer(Length(M.Referencias)));
  Assert.IsTrue(M.Referencias[0].Existe);
  Assert.AreEqual(Int64(99), M.Referencias[0].Id);
  Assert.AreEqual('Bruno', M.Referencias[0].Remetente);
  Assert.AreEqual('Olá, tudo bem? 😀', M.Referencias[0].Conteudos[0].Conteudo);
  Assert.IsTrue(M.Referencias[1].TipoReferencia = TTipoReferencia.Encaminhada);
  Assert.AreEqual(Int64(9), M.Referencias[1].ConversaId);
  Assert.IsTrue(M.Referencias[1].Oculta);
  // conteúdos: texto + imagem
  Assert.AreEqual(2, Integer(Length(M.Conteudos)));
  Assert.IsTrue(M.Conteudos[1].Tipo = TTipoConteudo.Imagem);
  Assert.IsTrue(M.Conteudos[1].EhAnexo);
  Assert.AreEqual('jpg', M.Conteudos[1].Extensao);
  Assert.IsTrue(TIdentificadorAnexo.Valido(M.Conteudos[1].Conteudo));
  // reações
  Assert.AreEqual(1, Integer(Length(M.Reacoes)));
  Assert.AreEqual('👍', M.Reacoes[0].Emoji);
  Assert.AreEqual(2, M.Reacoes[0].Quantidade);
  Assert.IsTrue(M.Reacoes[0].Reagiu);
  Assert.AreEqual(2, Integer(Length(M.Reacoes[0].Usuarios)));
  Assert.AreEqual('Bruno Lima', M.Reacoes[0].Usuarios[0].Nome);
  Assert.AreEqual('2026-10-06 12:01:00.000', Iso(M.Reacoes[0].Usuarios[0].ReagidoEm));
end;

procedure TTestesMapeadores.MensagemOcultaAgendadaEGravacao;
var
  L: TArray<TMensagem>;
begin
  L := TMapeador.Mensagens(LerFixture('mensagens.json'));
  // oculta: o servidor ainda manda o texto original; quem esconde é a tela
  Assert.IsTrue(L[2].Oculta);
  Assert.AreEqual('texto original de uma mensagem oculta', L[2].Conteudos[0].Conteudo);
  // agendada: a data efetiva é visivel_em
  Assert.AreEqual('2026-10-07 09:00:00.000', Iso(L[3].DataEfetiva));
  Assert.AreEqual('2026-10-06 12:10:00.000', Iso(L[3].Inserida));
  Assert.IsTrue(L[3].Conteudos[0].Tipo = TTipoConteudo.Gravacao);
  Assert.IsTrue(L[3].Conteudos[0].TranscricaoStatus = TStatusTranscricao.Concluida);
  Assert.AreEqual('bom dia a todos', L[3].Conteudos[0].Transcricao);
  Assert.AreEqual('webm', L[3].Conteudos[0].Extensao);
end;

procedure TTestesMapeadores.MensagemDeChamadaEResumo;
var
  M: TMensagem;
  R: TResumoChamada;
begin
  M := TMapeador.Mensagens(LerFixture('mensagens.json'))[4];
  Assert.IsTrue(M.Conteudos[0].Tipo = TTipoConteudo.Chamada);
  R := TMapeador.ResumoChamada(M.Conteudos[0].Conteudo);
  Assert.IsTrue(R.Valido);
  Assert.AreEqual(Int64(10), R.ChamadaId);
  Assert.IsFalse(R.EhVideo);
  Assert.IsTrue(R.Status = TStatusChamada.Encerrada);
  Assert.AreEqual(125, R.Duracao);
  // datas do resumo vêm sem fuso e sem milissegundos (UTC)
  Assert.AreEqual('2026-10-06 12:00:05.000', Iso(R.Iniciada));
  Assert.AreEqual('2026-10-06 12:02:10.000', Iso(R.Finalizada));
  Assert.AreEqual(2, Integer(Length(R.Participantes)));
  Assert.AreEqual(-1, R.Participantes[0].Duracao);
  Assert.AreEqual(120, R.Participantes[1].Duracao);
  Assert.IsTrue(R.Participantes[1].Status = TStatusParticipante.Entrou);
  Assert.IsFalse(R.EmGrupo);
end;

procedure TTestesMapeadores.TiposNovosNaoQuebram;
var
  M: TMensagem;
begin
  M := TMapeador.Mensagens(LerFixture('mensagens.json'))[5];
  Assert.AreEqual(3, Integer(Length(M.Conteudos)));
  Assert.IsTrue(M.Conteudos[0].Tipo = TTipoConteudo.Enquete);
  Assert.AreEqual('42', M.Conteudos[0].Conteudo);
  Assert.IsTrue(M.Conteudos[1].Tipo = TTipoConteudo.Desconhecido);
  Assert.AreEqual(9, M.Conteudos[1].TipoBruto);
  Assert.IsTrue(M.Conteudos[2].Tipo = TTipoConteudo.Figurinha);
  Assert.AreEqual('basico/coracao', M.Conteudos[2].Conteudo);
end;

procedure TTestesMapeadores.MensagemEnviadaUsaUsuarioId;
var
  O: TJSONObject;
  M: TMensagem;
begin
  O := TJson.LerObjeto(LerFixture('mensagem-enviada.json'));
  try
    M := TMapeador.Mensagem(O);
  finally
    O.Free;
  end;
  Assert.AreEqual(Int64(106), M.Id);
  Assert.AreEqual(Int64(7), M.RemetenteId);
  Assert.AreEqual(0, Integer(Length(M.Conteudos)));
  Assert.IsTrue(M.TemReferencia);
  Assert.IsTrue(M.TipoReferencia = TTipoReferencia.Resposta);
  Assert.IsFalse(M.Referencias[0].Existe, 'a resposta do PUT não traz a mensagem referenciada');
end;

procedure TTestesMapeadores.StatusEDetalhe;
var
  S: TArray<TStatusMensagem>;
  D: TArray<TStatusDestinatario>;
begin
  S := TMapeador.StatusMensagens(LerFixture('mensagem-status.json'));
  Assert.AreEqual(2, Integer(Length(S)));
  Assert.AreEqual(Int64(101), S[0].MensagemId);
  Assert.IsTrue(S[0].Visualizada);
  Assert.IsFalse(S[0].Reproduzida);
  Assert.IsTrue(S[0].ExcluidaEm = 0);
  Assert.IsTrue(S[1].ExcluidaEm <> 0);
  D := TMapeador.StatusDetalhe(LerFixture('mensagem-status-detalhe.json'));
  Assert.AreEqual(2, Integer(Length(D)));
  Assert.AreEqual('2026-10-06 12:03:00.000', Iso(D[0].Visualizada));
  Assert.IsTrue(D[0].Reproduzida = 0);
  Assert.IsTrue(D[1].Recebida = 0);
end;

procedure TTestesMapeadores.NovasMensagens;
var
  N: TArray<TNovaMensagem>;
begin
  N := TMapeador.NovasMensagens(LerFixture('mensagens-novas.json'));
  Assert.AreEqual(2, Integer(Length(N)));
  Assert.AreEqual(Int64(42), N[0].ConversaId);
  Assert.AreEqual(Int64(105), N[0].MensagemId);
  Assert.AreEqual('2026-10-06 12:20:00.123', Iso(N[0].Ate));
end;

procedure TTestesMapeadores.AtividadesReaisECasos;
var
  A: TArray<TAtividade>;
  X: TAtividade;
begin
  A := TMapeador.Atividades(LerFixture('atividades.json'));
  Assert.IsTrue(Length(A) > 0);
  for X in A do
  begin
    Assert.IsTrue(X.Id > 0);
    Assert.IsTrue(X.Tipo <> TTipoAtividade.Desconhecida);
    Assert.IsTrue(X.CriadoEm <> 0);
  end;
  A := TMapeador.Atividades(LerFixture('atividades-casos.json'));
  Assert.AreEqual(2, Integer(Length(A)));
  Assert.IsTrue(A[0].Tipo = TTipoAtividade.Reacao);
  Assert.AreEqual('😂', A[0].Emoji);
  Assert.IsTrue(A[0].Nova);
  Assert.IsTrue(A[0].ConversaTipo = TTipoConversa.Direta);
  Assert.AreEqual('', A[0].ConversaDescricao);
  Assert.IsTrue(A[1].Tipo = TTipoAtividade.ChamadaPerdida);
  Assert.AreEqual(Int64(10), A[1].ChamadaId);
  Assert.AreEqual(Int64(0), A[1].MensagemId);
  Assert.IsTrue(A[1].ConteudoTipo = TTipoConteudo.Desconhecido);
  Assert.AreEqual(3, TMapeador.QuantidadeDeAtividades(LerFixture('atividades-novas.json')));
end;

procedure TTestesMapeadores.Anexos;
var
  R: TAnexoRegistrado;
  E: TAnexoExistente;
  G: TArray<TAnexoGaleria>;
  T: TTranscricao;
begin
  R := TMapeador.AnexoRegistrado(LerFixture('anexo-put-novo.json'));
  Assert.IsFalse(R.Existe);
  Assert.AreEqual(Int64(5), R.Id);
  Assert.AreEqual(0, R.UploadStatus);
  Assert.Contains(R.Url, 'X-Amz-Signature');
  R := TMapeador.AnexoRegistrado(LerFixture('anexo-put-existente.json'));
  Assert.IsTrue(R.Existe);
  Assert.AreEqual(Int64(5), R.Id, 'id em texto também vira número');
  Assert.AreEqual(-1, R.UploadStatus, 'sem upload_status no existente');
  E := TMapeador.AnexoExistente(LerFixture('anexo-existe.json'));
  Assert.IsTrue(E.Existe);
  Assert.IsTrue(E.Tipo = TTipoConteudo.Arquivo);
  Assert.AreEqual(1, E.UploadStatus);
  Assert.StartsWith('https://', TMapeador.UrlDoAnexo(LerFixture('anexo-url.json')));
  G := TMapeador.Galeria(LerFixture('anexos.json'));
  Assert.AreEqual(1, Integer(Length(G)));
  Assert.AreEqual('relatório.pdf', G[0].Nome);
  Assert.AreEqual(Int64(2048), G[0].Tamanho);
  Assert.AreEqual('', G[0].Url);
  T := TMapeador.Transcricao(LerFixture('transcricao.json'));
  Assert.IsTrue(T.Status = TStatusTranscricao.Concluida);
  Assert.AreEqual('bom dia a todos', T.Texto);
end;

procedure TTestesMapeadores.DadosDaChamadaEPendentes;
var
  D: TDadosChamada;
  P: TParticipanteChamada;
  L: TArray<TChamadaPendente>;
begin
  D := TMapeador.DadosChamada(LerFixture('chamada-dados.json'));
  Assert.AreEqual(Int64(10), D.Id);
  Assert.IsTrue(D.EhVideo);
  Assert.IsTrue(D.Status = TStatusChamada.Pendente);
  Assert.AreEqual(Int64(0), D.ConversaChatId);
  Assert.AreEqual(2, Integer(Length(D.Participantes)));
  Assert.IsTrue(D.Participante(7, P));
  Assert.IsTrue(P.Status = TStatusParticipante.Entrou);
  Assert.AreEqual('Ana Souza', P.Nome);
  Assert.IsFalse(D.Participante(99, P));
  Assert.AreEqual(1, D.QuantosEntraram());
  Assert.AreEqual(0, D.QuantosEntraram(7));
  L := TMapeador.ChamadasPendentes(LerFixture('chamadas-pendentes.json'));
  Assert.AreEqual(1, Integer(Length(L)));
  Assert.AreEqual(Int64(0), L[0].ConversaId, 'conversa_id nulo chega como 0');
  Assert.IsTrue(L[0].EhVideo);
end;

procedure TTestesMapeadores.HistoricoRealDeChamadas;
var
  L: TArray<TChamadaHistorico>;
  H: TChamadaHistorico;
begin
  L := TMapeador.HistoricoDeChamadas(LerFixture('chamadas-historico.json'));
  Assert.IsTrue(Length(L) > 0);
  for H in L do
  begin
    Assert.IsTrue(H.Id > 0);
    // o histórico só traz chamadas finalizadas: recusada, encerrada, desconectada ou cancelada
    Assert.IsTrue(H.Status in [TStatusChamada.Recusada, TStatusChamada.Encerrada, TStatusChamada.Desconectada,
      TStatusChamada.Cancelada], 'status ' + IntToStr(Ord(H.Status)));
    Assert.IsTrue(Length(H.Participantes) > 0);
    Assert.IsTrue(H.CriadoEm <> 0);
  end;
end;

procedure TTestesMapeadores.ResumoDeChamadaInvalidoNaoLanca;
begin
  Assert.IsFalse(TMapeador.ResumoChamada('').Valido);
  Assert.IsFalse(TMapeador.ResumoChamada('{').Valido);
  Assert.IsFalse(TMapeador.ResumoChamada('[1,2]').Valido);
  Assert.IsFalse(TMapeador.ResumoChamada('texto qualquer').Valido);
  Assert.AreEqual(-1, TMapeador.ResumoChamada('{').Duracao);
end;

procedure TTestesMapeadores.Ice;
var
  C: TConfiguracaoIce;
begin
  C := TMapeador.ConfiguracaoIce(LerFixture('ice.json'));
  Assert.IsTrue(C.SoRelay);
  Assert.AreEqual(1, Integer(Length(C.Servidores)));
  Assert.AreEqual(1, Integer(Length(C.Servidores[0].Urls)));
  Assert.AreEqual('turn:localhost:3478?transport=tcp', C.Servidores[0].Urls[0]);
  Assert.AreNotEqual('', C.Servidores[0].Usuario);
  Assert.AreNotEqual('', C.Servidores[0].Credencial);
  C := TMapeador.ConfiguracaoIce(LerFixture('ice-lista.json'));
  Assert.IsFalse(C.SoRelay);
  Assert.AreEqual(2, Integer(Length(C.Servidores[0].Urls)));
end;

procedure TTestesMapeadores.Enquete;
var
  E: TEnquete;
begin
  E := TMapeador.Enquete(LerFixture('enquete.json'));
  Assert.AreEqual('Onde vamos almoçar?', E.Pergunta);
  Assert.IsFalse(E.Multipla);
  Assert.AreEqual(2, Integer(Length(E.Opcoes)));
  Assert.AreEqual('Ana Souza', E.Opcoes[0].Votantes[0].Nome);
  Assert.AreEqual(1, E.TotalVotantes);
  Assert.AreEqual(100, E.Porcentagem(0));
  Assert.AreEqual(0, E.Porcentagem(1));
  Assert.AreEqual(0, E.Porcentagem(5));
  Assert.IsTrue(E.VoteiEm(1));
  Assert.IsFalse(E.VoteiEm(2));
  Assert.IsTrue(E.PodeEncerrar);
  // a data final passou -> encerrada, mesmo com "encerrada": false (o servidor não avisa)
  Assert.IsFalse(E.EstaEncerrada(EncodeDateTime(2026, 10, 9, 17, 59, 0, 0)));
  Assert.IsTrue(E.EstaEncerrada(EncodeDateTime(2026, 10, 9, 18, 0, 0, 0)));
end;

procedure TTestesMapeadores.PermissoesParametrosESip;
var
  LMinhas: TArray<string>;
  LPainel: TPainelPermissoes;
  LParametros: TParametros;
  LSip: TRamalSip;
begin
  LMinhas := TMapeador.MinhasPermissoes(LerFixture('usuario-permissoes.json'));
  Assert.IsTrue(TListaDePermissoes.Contem(LMinhas, PERMISSAO_PARAMETROS));
  Assert.IsTrue(TListaDePermissoes.Contem(LMinhas, PERMISSAO_PERMISSOES));
  LPainel := TMapeador.PainelPermissoes(LerFixture('permissoes.json'));
  Assert.IsFalse(LPainel.ModoAberto);
  Assert.AreEqual(2, Integer(Length(LPainel.Permissoes)));
  Assert.AreEqual(2, Integer(Length(LPainel.Usuarios)));
  Assert.AreEqual(0, Integer(Length(LPainel.Usuarios[1].Permissoes)));
  LParametros := TMapeador.Parametros(LerFixture('parametros.json'));
  Assert.IsTrue(LParametros.TurnForcarRelay);
  Assert.IsTrue(LParametros.FcmPrivateKeyConfigurada);
  Assert.AreEqual(90, LParametros.GravacaoDias);
  Assert.AreEqual('chat', LParametros.S3Bucket);
  LSip := TMapeador.RamalSip(LerFixture('sip-vazio.json'));
  Assert.IsFalse(LSip.Existe);
  LSip := TMapeador.RamalSip(LerFixture('sip.json'));
  Assert.IsTrue(LSip.Existe);
  Assert.AreEqual('1001', LSip.SipUser);
  Assert.AreEqual('', LSip.AuthUser);
  Assert.AreEqual('wss://pbx.test:8089/ws', LSip.WsServer);
end;

procedure TTestesMapeadores.ContatosMembrosEOnline;
var
  C: TArray<TContato>;
  M: TArray<TMembro>;
  O: TArray<Int64>;
begin
  C := TMapeador.Contatos(LerFixture('contatos.json'));
  Assert.AreEqual(2, Integer(Length(C)));
  Assert.AreEqual('', C[0].Telefone);
  Assert.AreEqual('11 90000-0000', C[1].Telefone);
  M := TMapeador.Membros(LerFixture('membros.json'));
  Assert.AreEqual(Int64(31), M[0].VinculoId);
  Assert.AreEqual(Int64(7), M[0].UsuarioId);
  O := TMapeador.IdsOnline(LerFixture('contatos-online.json'));
  Assert.AreEqual(2, Integer(Length(O)));
  Assert.AreEqual(Int64(8), O[0]);
  Assert.AreEqual(Int64(9), O[1], 'id em texto também vira número');
end;

procedure TTestesMapeadores.FormatoErradoLancaContratoInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TMapeador.Conversas('{"error":"x"}');
    end, EContratoInvalido);
  Assert.WillRaise(
    procedure
    begin
      TMapeador.UsuarioLogado('[]');
    end, EContratoInvalido);
  Assert.WillRaise(
    procedure
    begin
      TMapeador.Mensagens('<html>502</html>');
    end, EContratoInvalido);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesMapeadores);

end.
