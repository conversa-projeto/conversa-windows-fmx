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
  Mensagem.Anexo in 'src\chat\mensagem\Mensagem.Anexo.pas',
  Mensagem.Editor in 'src\chat\mensagem\Mensagem.Editor.pas',
  Mensagem.Tipos in 'src\chat\mensagem\Mensagem.Tipos.pas',
  Mensagem.Visualizador in 'src\chat\mensagem\Mensagem.Visualizador.pas',
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
  Conversa.Windows.UserActivity in 'lib\windows\Conversa.Windows.UserActivity.pas';

{$R *.res}
begin
  Application.Title := 'Conversa';
  {$IFNDEF DEBUG}
  if IsApplicationAlreadyRunning then
    Exit;

  InicializarComSO;
  {$ENDIF}

  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  AtualizarContadorNotificacao(0, True);
  Application.CreateForm(TDados, Dados);
  Application.CreateForm(TTelaInicial, TelaInicial);
  IniciarMonitoramento;
  Application.Run;
  TNotificacaoManager.Finalizar;
  FinalizarMonitoramento;
  AtualizarContadorNotificacao(0, True);
end.
