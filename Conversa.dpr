// Eduardo - 03/03/2024
program Conversa;

{$R *.dres}

uses
  MidasLib,
  System.StartUpCopy,
  FMX.Forms,
  Conversa.Tipos in 'src\Conversa.Tipos.pas',
  Conversa.Login in 'Conversa.Login.pas' {Login: TFrame},
  Conversa.Dados in 'Conversa.Dados.pas' {Dados: TDataModule},
  REST.API in 'REST.API.pas',
  Conversa.Tela.Inicial.view in 'Conversa.Tela.Inicial.view.pas' {TelaInicial},
  Conversa.Principal in 'src\principal\Conversa.Principal.pas' {PrincipalView: TFrame},
  Conversa.FormularioBase in 'src\base\Conversa.FormularioBase.pas' {FormularioBase},
  PascalStyleScript in 'src\pss\PascalStyleScript.pas',
  Conversa.Configuracoes in 'src\configuracoes\Conversa.Configuracoes.pas',
  Conversa.FrameBase in 'src\base\Conversa.FrameBase.pas' {FrameBase: TFrame},
  Conversa.Chat in 'src\chat\Conversa.Chat.pas' {Chat: TFrame},
  Conversa.Chat.Listagem in 'src\chat\Conversa.Chat.Listagem.pas' {ChatListagem: TFrame},
  Conversa.Chat.Listagem.Item in 'src\chat\Conversa.Chat.Listagem.Item.pas' {ConversasItemFrame: TFrame},
  Conversa.AES in 'lib\AES\Conversa.AES.pas',
  Conversa.Configurar.Conexao in 'src\configuracoes\Conversa.Configurar.Conexao.pas' {ConfigurarConexao: TFrame},
  Conversa.Contatos in 'src\contatos\Conversa.Contatos.pas' {ConversaContatos: TFrame},
  Conversa.Contatos.Listagem.Item in 'src\contatos\Conversa.Contatos.Listagem.Item.pas' {ConversaContatoItem: TFrame},
  Conversa.ModalView in 'src\principal\Conversa.ModalView.pas' {ModalView: TFrame},
  Conversa.WMI in 'Conversa.WMI.pas',
  Conversa.Conexao.AvisoInicioSistema in 'src\conexao\Conversa.Conexao.AvisoInicioSistema.pas' {ConexaoFalhaInicio: TFrame},
  Conversa.Memoria in 'Conversa.Memoria.pas',
  Conversa.Audio in 'Conversa.Audio.pas',
  Conversa.Notificacao.Item in 'src\notificacao\Conversa.Notificacao.Item.pas' {NotificacaoItem: TFrame},
  Conversa.Notificacao in 'src\notificacao\Conversa.Notificacao.pas',
  Conversa.Notificacao.Visualizador in 'src\notificacao\Conversa.Notificacao.Visualizador.pas' {NotificacaoVisualizador},
  Conversa.Windows.Overlay in 'lib\windows\Conversa.Windows.Overlay.pas',
  Conversa.Windows.Utils in 'lib\windows\Conversa.Windows.Utils.pas',
  Conversa.Log in 'Conversa.Log.Pas',
  Conversa.Utils in 'lib\Conversa.Utils.pas',
  Conversa.Visualizador.Midia in 'src\visualizadormidia\Conversa.Visualizador.Midia.pas' {VisualizadorMidia: TFrame},
  Conversa.Visualizador.Midia.Windows in 'src\visualizadormidia\Conversa.Visualizador.Midia.Windows.pas',
  Conversa.Eventos in 'src\Conversa.Eventos.pas',
  Novo.Grupo.Usuario.Item in 'src\novo\grupo\Novo.Grupo.Usuario.Item.pas' {NovoGrupoUsuarioItem: TFrame},
  Novo.Grupo in 'src\novo\grupo\Novo.Grupo.pas' {NovoGrupo: TFrame},
  Conversa.Windows.UserActivity in 'lib\windows\Conversa.Windows.UserActivity.pas',
  ImageViewerFrame in 'src\visualizadormidia\ImageViewerFrame.pas' {ImageViewerFrame: TFrame},
  chat.ordenador in 'src\chat\chat\chat.ordenador.pas',
  chat.so in 'src\chat\chat\chat.so.pas',
  chat.tipos in 'src\chat\chat\chat.tipos.pas',
  chat.visualizador in 'src\chat\chat\chat.visualizador.pas',
  chat.expositor in 'src\chat\chat\frames\chat.expositor.pas' {ChatExpositor: TFrame},
  chat.mensagem.conteudo in 'src\chat\chat\frames\chat.mensagem.conteudo.pas' {ChatConteudo: TFrame},
  chat.mensagem in 'src\chat\chat\frames\chat.mensagem.pas' {ChatMensagem: TFrame},
  chat.separador.data in 'src\chat\chat\frames\chat.separador.data.pas' {ChatSeparadorData: TFrame},
  chat.separador.lidas in 'src\chat\chat\frames\chat.separador.lidas.pas' {ChatSeparadorLidas: TFrame},
  chat.ultima in 'src\chat\chat\frames\chat.ultima.pas' {ChatUltima: TFrame},
  chat.emoji in 'src\chat\chat\chat.emoji.pas',
  Popup in 'lib\popupmenu\Popup.pas' {Popup: TFrame},
  PopupMenu.Item.Action.Container in 'lib\popupmenu\PopupMenu.Item.Action.Container.pas',
  PopupMenu.Item.Base in 'lib\popupmenu\PopupMenu.Item.Base.pas' {PopupMenuItemBase: TFrame},
  PopupMenu.Item in 'lib\popupmenu\PopupMenu.Item.pas' {PopupMenuItemFrame: TFrame},
  PopupMenu.Item.Separador in 'lib\popupmenu\PopupMenu.Item.Separador.pas' {PopupMenuItemSeparador: TFrame},
  PopupMenu in 'lib\popupmenu\PopupMenu.pas' {PopupMenu: TFrame},
  System.Skia.API in 'src\chat\chat\skia\System.Skia.API.pas',
  System.Skia in 'src\chat\chat\skia\System.Skia.pas',
  FMX.Skia.Canvas.GL in 'src\chat\chat\skia\FMX\FMX.Skia.Canvas.GL.pas',
  FMX.Skia.Canvas.Metal in 'src\chat\chat\skia\FMX\FMX.Skia.Canvas.Metal.pas',
  FMX.Skia.Canvas in 'src\chat\chat\skia\FMX\FMX.Skia.Canvas.pas',
  FMX.Skia in 'src\chat\chat\skia\FMX\FMX.Skia.pas',
  Conversa.Inicializacoes in 'Conversa.Inicializacoes.pas',
  chat.base in 'src\chat\chat\frames\chat.base.pas' {ChatBase: TFrame},
  chat.conteudo.anexo in 'src\chat\chat\frames\chat.conteudo.anexo.pas' {ChatConteudoAnexo: TFrame},
  chat.conteudo.imagem in 'src\chat\chat\frames\chat.conteudo.imagem.pas' {ChatConteudoImagem: TFrame},
  chat.conteudo.mensagem.audio in 'src\chat\chat\frames\chat.conteudo.mensagem.audio.pas' {ChatConteudoMensagemAudio: TFrame},
  chat.conteudo.texto in 'src\chat\chat\frames\chat.conteudo.texto.pas' {ChatConteudoTexto: TFrame},
  chat.editor.anexo.item in 'src\chat\chat\frames\chat.editor.anexo.item.pas' {ChatAnexoItem: TFrame},
  chat.editor.anexo in 'src\chat\chat\frames\chat.editor.anexo.pas' {ChatEditorAnexo: TFrame},
  chat.editor.audio in 'src\chat\chat\frames\chat.editor.audio.pas' {ChatEditorAudio: TFrame},
  chat.editor.base in 'src\chat\chat\frames\chat.editor.base.pas' {ChatEditorBase: TFrame},
  chat.editor in 'src\chat\chat\frames\chat.editor.pas' {ChatEditor: TFrame},
  chat.editor.texto in 'src\chat\chat\frames\chat.editor.texto.pas' {ChatEditorTexto: TFrame},
  chat.selectfile in 'src\chat\chat\chat.selectfile.pas';

{$R *.res}
begin
  Application.Title := 'Conversa';

  if not Iniciar then
    Exit;

  Application.Initialize;
  Application.CreateForm(TDados, Dados);
  Application.CreateForm(TTelaInicial, TelaInicial);
  Application.Run;
  Finalizar;
end.
