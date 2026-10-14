unit Conversa.UI.Cores;

{ Tokens de cor do Conversa (FC-104; docs/design/cores.md §7). Nenhuma cor fora desta unit.

  - Nomes pelo PAPEL (BolhaPropria, não AzulClaro), os mesmos do Android (cores.md §7.7), em PascalCase.
  - CoresClaro = o visual do app atual (valores da §4 do cores.md; a origem de cada um está na §7.2).
  - CoresEscuro = PROPOSTA, desligada até a aprovação (cores.md §7.5 e §9, pergunta 9).
  - Os tokens "só do desktop" (barra de título, popup, bandeja) estão com o valor de hoje; a troca pelos
    tokens sugeridos depende da §9, pergunta 15.
  - Uma constante de record lista os campos na ordem da declaração: mexer nos dois temas juntos. }

interface

uses
  System.UITypes,
  System.Messaging;

type
  {$SCOPEDENUMS ON}
  TConversaTema = (Claro, Escuro);
  {$SCOPEDENUMS OFF}

  TConversaCores = record
    // Base (Material 3 no Android)
    Primaria: TAlphaColor;
    SobrePrimaria: TAlphaColor;
    Fundo: TAlphaColor;
    Superficie: TAlphaColor;
    Topo: TAlphaColor;
    MenuLateral: TAlphaColor;
    TextoPrimario: TAlphaColor;
    TextoSecundario: TAlphaColor;
    TextoTitulo: TAlphaColor;
    Divisor: TAlphaColor;
    Erro: TAlphaColor;
    SobreErro: TAlphaColor;
    TextoAvisoConexao: TAlphaColor;
    // Tokens do app (ConversaCores no Android)
    BolhaPropria: TAlphaColor;
    BolhaOutro: TAlphaColor;
    TextoBolhaPropria: TAlphaColor;
    TextoBolhaOutro: TAlphaColor;
    HoraBolha: TAlphaColor;
    StatusEntregue: TAlphaColor;
    StatusLida: TAlphaColor;
    Link: TAlphaColor;
    LinkVisitado: TAlphaColor;
    BadgeNaoLidas: TAlphaColor;
    TextoBadge: TAlphaColor;
    ItemSelecionado: TAlphaColor;
    ItemPressionado: TAlphaColor;
    DivisorLista: TAlphaColor;
    SeparadorNaoLidas: TAlphaColor;
    SeparadorData: TAlphaColor;
    CampoEntrada: TAlphaColor;
    TextoCampo: TAlphaColor;
    IconeAcao: TAlphaColor;
    IconeNeutro: TAlphaColor;
    IconeDiscreto: TAlphaColor;
    AvatarFundo: TAlphaColor;
    AvatarLetra: TAlphaColor;
    TextoTerciario: TAlphaColor;
    Digitando: TAlphaColor;
    GravandoAudio: TAlphaColor;
    FundoBotaoGravacao: TAlphaColor;
    ChamadaFundo: TAlphaColor;
    ChamadaBarraInferior: TAlphaColor;
    ChamadaBotao: TAlphaColor;
    ChamadaIconeBotao: TAlphaColor;
    ChamadaEncerrar: TAlphaColor;
    ChamadaAtender: TAlphaColor;
    ChamadaAlerta: TAlphaColor;
    ChamadaEmAndamento: TAlphaColor;
    Waveform: TAlphaColor;
    ChamadaRealizada: TAlphaColor;
    ChamadaRecebida: TAlphaColor;
    ChamadaPerdida: TAlphaColor;
    NotificacaoFundo: TAlphaColor;
    NotificacaoAvatar: TAlphaColor;
    NotificacaoHora: TAlphaColor;
    NotificacaoAvatarChamada: TAlphaColor;
    BotaoRecusar: TAlphaColor;
    BotaoAtender: TAlphaColor;
    AvisoConexao: TAlphaColor;
    SelecaoCheck: TAlphaColor;
    OverlayModal: TAlphaColor;
    FundoVisualizadorMidia: TAlphaColor;
    Online: TAlphaColor;
    // Só do desktop
    BarraTitulo: TAlphaColor;
    IconeBarraTitulo: TAlphaColor;
    BotaoFecharHover: TAlphaColor;
    BotaoJanelaHover: TAlphaColor;
    PopupFundo: TAlphaColor;
    PopupItemHover: TAlphaColor;
    PopupBorda: TAlphaColor;
    Sombra: TAlphaColor;
    NomePainelConteudo: TAlphaColor;
    TextoSecundarioDetalhe: TAlphaColor;
    RotuloDetalhe: TAlphaColor;
    IconeIrUltima: TAlphaColor;
    IconeRemoverAnexo: TAlphaColor;
    BotaoSalvarHover: TAlphaColor;
    TextoBotaoLegado: TAlphaColor;
    LoadingPontoA: TAlphaColor;
    LoadingPontoB: TAlphaColor;
    NotificacaoTipoChamada: TAlphaColor;
    BandejaContador: TAlphaColor;
    TextoBandeja: TAlphaColor;
  end;

  /// <summary>Enviada por TCores.DefinirTema; as telas reaplicam as cores.</summary>
  TMensagemTemaAlterado = class(TMessage);

const
  CoresClaro: TConversaCores = (
    Primaria:                 $FF007DFF; // chat.editor.fmx:53
    SobrePrimaria:            $FFFFFFFF; // Conversa.Chat.Listagem.Item.fmx:109
    Fundo:                    $FFF5F5F5; // Conversa.FormularioBase.fmx:7
    Superficie:               $FFFFFFFF; // Conversa.Chat.Listagem.fmx:22
    Topo:                     $FFF0F0F0; // Conversa.Chat.fmx:13
    MenuLateral:              $FFC8C8C8; // Conversa.Principal.fmx:13
    TextoPrimario:            $FF141414; // Conversa.Chat.Listagem.Item.fmx:66
    TextoSecundario:          $FF646464; // Conversa.Chat.Listagem.Item.fmx:85
    TextoTitulo:              $FF333333; // Conversa.Chamada.Detalhe.fmx:63
    Divisor:                  $FFDBDBDB; // Novo.Grupo.fmx:191
    Erro:                     $FFE53935; // Conversa.Notificacao.Item.Chamada.fmx:170
    SobreErro:                $FFFFFFFF;
    TextoAvisoConexao:        $FF410002; // proposta (o app atual usa branco)
    BolhaPropria:             $FFCFE7FF; // chat.mensagem.pas:101
    BolhaOutro:               $FFEDEDED; // chat.mensagem.pas:102
    TextoBolhaPropria:        $FF000000;
    TextoBolhaOutro:          $FF000000;
    HoraBolha:                $80000000; // chat.mensagem.fmx:50,53 (preto 50%)
    StatusEntregue:           $FF808080; // chat.mensagem.pas:147,156
    StatusLida:               $FF007DFF; // chat.mensagem.pas:165
    Link:                     $FF0000EE; // chat.conteudo.texto.pas:172
    LinkVisitado:             $FF551A8B; // chat.conteudo.texto.pas:106
    BadgeNaoLidas:            $FF007DFF; // Conversa.Chat.Listagem.Item.fmx:92
    TextoBadge:               $FFFFFFFF; // Conversa.Chat.Listagem.Item.fmx:109
    ItemSelecionado:          $FFE3F1FF; // Conversa.Chat.Listagem.Item.pas:126
    ItemPressionado:          $FFE6E6E6; // Conversa.Chat.Listagem.Item.fmx:131
    DivisorLista:             $32000000; // Conversa.Chat.Listagem.fmx:2527
    SeparadorNaoLidas:        $FFB0C4DE; // chat.separador.lidas.fmx:7
    SeparadorData:            $FFE0E0E0; // chat.separador.data.fmx:5
    CampoEntrada:             $FFE0E0E0; // chat.editor.fmx:13
    TextoCampo:               $FF545454; // chat.editor.texto.fmx:161
    IconeAcao:                $FF007DFF; // editor (enviar, microfone, emoji, anexo)
    IconeNeutro:              $FF000000; // menu lateral, chamada
    IconeDiscreto:            $FF808080; // Conversa.Chat.fmx:170
    AvatarFundo:              $FFF5F5F5; // crclFoto
    AvatarLetra:              $FF007DFF; // Conversa.Chat.Listagem.Item.fmx:45
    TextoTerciario:           $FF9E9E9E; // Conversa.Chamada.Listagem.Item.fmx:276
    Digitando:                $FF808080; // Conversa.Chat.fmx:212
    GravandoAudio:            $FFFF0000; // chat.editor.audio.pas:173
    FundoBotaoGravacao:       $FFB0C4DE; // chat.editor.audio.fmx:31,95
    ChamadaFundo:             $FFF5F5F5;
    ChamadaBarraInferior:     $FFE0E0E0; // Conversa.Chamada.view.fmx:16
    ChamadaBotao:             $FFFFFFFF; // Conversa.Chamada.view.fmx:33
    ChamadaIconeBotao:        $FF000000; // Conversa.Chamada.view.fmx:71
    ChamadaEncerrar:          $FFD44242; // Conversa.Chamada.view.fmx:295
    ChamadaAtender:           $FF008000; // Conversa.Chamada.view.fmx:348
    ChamadaAlerta:            $FFFF0000; // Conversa.Chamada.view.fmx:164
    ChamadaEmAndamento:       $FF85FF85; // Conversa.Chamada.BarraTitulo.fmx:6
    Waveform:                 $FF00D26A; // Conversa.Chamada.Waveform.pas:45
    ChamadaRealizada:         $FF007DFF; // Conversa.Chamada.Detalhe.pas:130
    ChamadaRecebida:          $FF00C853; // Conversa.Chamada.Detalhe.pas:135
    ChamadaPerdida:           $FFFF5252; // Conversa.Chamada.Detalhe.pas:139
    NotificacaoFundo:         $FF007FFF; // Conversa.Notificacao.Item.fmx:8
    NotificacaoAvatar:        $FF1B8DFF; // Conversa.Notificacao.Item.fmx:100
    NotificacaoHora:          $FFADD8E6; // Conversa.Notificacao.Item.fmx:155
    NotificacaoAvatarChamada: $FF4CAF50; // Conversa.Notificacao.Item.Chamada.fmx:93
    BotaoRecusar:             $FFE53935; // Conversa.Notificacao.Item.Chamada.fmx:170
    BotaoAtender:             $FF43A047; // Conversa.Notificacao.Item.Chamada.fmx:193
    AvisoConexao:             $FFF08080; // Conversa.Tela.Inicial.view.fmx:2471
    SelecaoCheck:             $FF00FF00; // Novo.Grupo.Usuario.Item.fmx:97 (sugerido #43A047, §9)
    OverlayModal:             $64000000; // Conversa.ModalView.fmx:7
    FundoVisualizadorMidia:   $C8000000; // Conversa.Visualizador.Midia.fmx:5
    Online:                   $FF43A047; // PROVISÓRIO: não existe no app atual (§9, pergunta 1)
    BarraTitulo:              $FFC8C8C8; // Conversa.FormularioBase.fmx:39,136
    IconeBarraTitulo:         $FF000000; // Conversa.FormularioBase.pas:345-353
    BotaoFecharHover:         $FFFF0000; // Conversa.FormularioBase.pas:347
    BotaoJanelaHover:         $1AFFFFFF; // Conversa.FormularioBase.pas:364,379
    PopupFundo:               $FFFFFAFA; // PopupMenu.Item.fmx:5
    PopupItemHover:           $FFF5F5F5; // PopupMenu.Item.fmx:18-19
    PopupBorda:               $FFDCDCDC; // PopupMenu.fmx:17
    Sombra:                   $FF000000; // PopupMenu.fmx:32
    NomePainelConteudo:       $FF696969; // Conversa.Conteudo.fmx:137
    TextoSecundarioDetalhe:   $FF666666; // Conversa.Chamada.Detalhe.fmx:74
    RotuloDetalhe:            $FF999999; // Conversa.Chamada.Detalhe.fmx:92
    IconeIrUltima:            $FFC0C0C0; // chat.ultima.fmx:24
    IconeRemoverAnexo:        $FF4B4B4B; // chat.anexo.item.fmx:111
    BotaoSalvarHover:         $FFE6F2FF; // Conversa.Configurar.Conexao.pas:85
    TextoBotaoLegado:         $FF007FFF; // Conversa.Configurar.Conexao.fmx:142
    LoadingPontoA:            $FF000000; // Conversa.Loading.Pontos.frame.fmx:16
    LoadingPontoB:            $FF0000FF; // Conversa.Loading.Pontos.frame.fmx:29
    NotificacaoTipoChamada:   $FFD3D3D3; // Conversa.Notificacao.Item.Chamada.fmx:142
    BandejaContador:          $FFFF0000; // lib/windows/Conversa.Windows.Overlay.pas:111
    TextoBandeja:             $FFFFFFFF  // lib/windows/Conversa.Windows.Overlay.pas:120
  );

  // PROPOSTA: o app atual não tem modo escuro (base: bin/tema/escuro.pss e o escuro do Android).
  CoresEscuro: TConversaCores = (
    Primaria:                 $FF007DFF;
    SobrePrimaria:            $FFFFFFFF;
    Fundo:                    $FF323232; // escuro.pss "fundo"
    Superficie:               $FF3C3C3C; // escuro.pss "fundo_claro_1"
    Topo:                     $FF323232;
    MenuLateral:              $FF282828; // escuro.pss "fundo_escuro"
    TextoPrimario:            $FFF0F0F0;
    TextoSecundario:          $FFB4B4B4;
    TextoTitulo:              $FFF0F0F0;
    Divisor:                  $FF464646;
    Erro:                     $FFEF5350;
    SobreErro:                $FFFFFFFF;
    TextoAvisoConexao:        $FFFFDAD6;
    BolhaPropria:             $FF16406B;
    BolhaOutro:               $FF3C3C3C;
    TextoBolhaPropria:        $FFF0F0F0;
    TextoBolhaOutro:          $FFF0F0F0;
    HoraBolha:                $99FFFFFF;
    StatusEntregue:           $FF9E9E9E;
    StatusLida:               $FF4DA3FF;
    Link:                     $FF8AB4F8;
    LinkVisitado:             $FFC58AF9;
    BadgeNaoLidas:            $FF007DFF;
    TextoBadge:               $FFFFFFFF;
    ItemSelecionado:          $FF2B3A4A;
    ItemPressionado:          $FF464646;
    DivisorLista:             $33FFFFFF;
    SeparadorNaoLidas:        $FF3A4A5E;
    SeparadorData:            $FF464646;
    CampoEntrada:             $FF464646;
    TextoCampo:               $FFDCDCDC;
    IconeAcao:                $FF007DFF;
    IconeNeutro:              $FFF0F0F0;
    IconeDiscreto:            $FF9E9E9E;
    AvatarFundo:              $FF464646;
    AvatarLetra:              $FF4DA3FF;
    TextoTerciario:           $FF8C8C8C;
    Digitando:                $FF9E9E9E;
    GravandoAudio:            $FFFF5252;
    FundoBotaoGravacao:       $FF3A4A5E;
    ChamadaFundo:             $FF282828;
    ChamadaBarraInferior:     $FF3C3C3C;
    ChamadaBotao:             $FF464646;
    ChamadaIconeBotao:        $FFF0F0F0;
    ChamadaEncerrar:          $FFD44242;
    ChamadaAtender:           $FF43A047;
    ChamadaAlerta:            $FFFF5252;
    ChamadaEmAndamento:       $FF2E7D32;
    Waveform:                 $FF00D26A;
    ChamadaRealizada:         $FF4DA3FF;
    ChamadaRecebida:          $FF00C853;
    ChamadaPerdida:           $FFFF5252;
    NotificacaoFundo:         $FF007FFF;
    NotificacaoAvatar:        $FF1B8DFF;
    NotificacaoHora:          $FFADD8E6;
    NotificacaoAvatarChamada: $FF4CAF50;
    BotaoRecusar:             $FFE53935;
    BotaoAtender:             $FF43A047;
    AvisoConexao:             $FF8C1D18;
    SelecaoCheck:             $FF66BB6A;
    OverlayModal:             $64000000;
    FundoVisualizadorMidia:   $C8000000;
    Online:                   $FF43A047;
    BarraTitulo:              $FF282828; // sugestão: igual a MenuLateral
    IconeBarraTitulo:         $FFF0F0F0; // sugestão: IconeNeutro
    BotaoFecharHover:         $FFFF0000;
    BotaoJanelaHover:         $1AFFFFFF;
    PopupFundo:               $FF3C3C3C; // sugestão: Superficie
    PopupItemHover:           $FF323232; // sugestão: Fundo
    PopupBorda:               $FF464646; // sugestão: Divisor
    Sombra:                   $FF000000;
    NomePainelConteudo:       $FFB4B4B4; // sugestão: TextoSecundario
    TextoSecundarioDetalhe:   $FFB4B4B4; // sugestão: TextoSecundario
    RotuloDetalhe:            $FF8C8C8C; // sugestão: TextoTerciario
    IconeIrUltima:            $FFC0C0C0; // a definir
    IconeRemoverAnexo:        $FF4B4B4B; // a definir
    BotaoSalvarHover:         $FF2B3A4A; // sugestão: ItemSelecionado
    TextoBotaoLegado:         $FF007DFF; // sugestão: Primaria
    LoadingPontoA:            $FFF0F0F0; // sugestão: IconeNeutro
    LoadingPontoB:            $FF007DFF; // sugestão: Primaria
    NotificacaoTipoChamada:   $FFD3D3D3;
    BandejaContador:          $FFFF0000;
    TextoBandeja:             $FFFFFFFF
  );

type
  TCores = record
  private
    class var FTema: TConversaTema;
  public
    /// <summary>Cores do tema em uso.</summary>
    class function Atual: TConversaCores; static;
    class function Tema: TConversaTema; static;
    /// <summary>Troca o tema e avisa as telas (TMensagemTemaAlterado). O escuro só depois de aprovado.</summary>
    class procedure DefinirTema(ATema: TConversaTema); static;
  end;

/// <summary>Atalho: Cores.ItemSelecionado.</summary>
function Cores: TConversaCores;

implementation

{ TCores }

class function TCores.Atual: TConversaCores;
begin
  if FTema = TConversaTema.Escuro then
    Result := CoresEscuro
  else
    Result := CoresClaro;
end;

class function TCores.Tema: TConversaTema;
begin
  Result := FTema;
end;

class procedure TCores.DefinirTema(ATema: TConversaTema);
begin
  if ATema = FTema then
    Exit;
  FTema := ATema;
  TMessageManager.DefaultManager.SendMessage(nil, TMensagemTemaAlterado.Create);
end;

function Cores: TConversaCores;
begin
  Result := TCores.Atual;
end;

end.
