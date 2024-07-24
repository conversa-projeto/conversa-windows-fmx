// Eduardo - 03/03/2024
program Conversa;

{$R *.dres}

uses
  MidasLib,
  System.StartUpCopy,
  FMX.Forms,
  Conversa.Login in 'Conversa.Login.pas' {Login: TFrame},
  Conversa.Dados in 'Conversa.Dados.pas' {Dados: TDataModule},
  REST.API in 'REST.API.pas',
  Conversa.Tela.Inicial.view in 'Conversa.Tela.Inicial.view.pas' {TelaInicial},
  Conversa.Principal in 'src\principal\Conversa.Principal.pas' {PrincipalView: TFrame},
  Conversa.FormularioBase in 'src\base\Conversa.FormularioBase.pas' {FormularioBase},
  FMX.Platform.Win in 'src\fmx\FMX.Platform.Win.pas',
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
  Conversa.Windows.Overlay in 'lib\windows\Conversa.Windows.Overlay.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TDados, Dados);
  Application.CreateForm(TTelaInicial, TelaInicial);
  Application.Run;
end.
