// Eduardo - 03/03/2024
program Conversa;

{$R *.dres}

uses
  MidasLib,
  System.StartUpCopy,
  FMX.Forms,
  System.SysUtils,
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
  Conversa.Log in 'Conversa.Log.Pas',
  Conversa.Visualizador.Midia in 'src\visualizadormidia\Conversa.Visualizador.Midia.pas' {VisualizadorMidia: TFrame},
  Conversa.Visualizador.Midia.Windows in 'src\visualizadormidia\Conversa.Visualizador.Midia.Windows.pas',
  Conversa.Eventos in 'src\Conversa.Eventos.pas',
  Novo.Grupo.Usuario.Item in 'src\novo\grupo\Novo.Grupo.Usuario.Item.pas' {NovoGrupoUsuarioItem: TFrame},
  Novo.Grupo in 'src\novo\grupo\Novo.Grupo.pas' {NovoGrupo: TFrame},
  ImageViewerFrame in 'src\visualizadormidia\ImageViewerFrame.pas' {ImageViewerFrame: TFrame},
  Conversa.Inicializacoes in 'Conversa.Inicializacoes.pas',
  Conversa.Proxy in 'src\Conversa.Proxy.pas',
  Conversa.Proxy.Tipos in 'src\Conversa.Proxy.Tipos.pas',
  Conversa.Evento.Base in 'src\Conversa.Evento.Base.pas',
  Conversa.Serializer in 'src\Conversa.Serializer.pas',
  Conversa.Loading.Pontos.frame in 'src\Conversa.Loading.Pontos.frame.pas' {ConversaLoadingPontosFrame: TFrame};

{$R *.res}
begin
  Application.Title := 'Conversa';

  if not Iniciar then
    Exit;

  try
    Application.Initialize;
    Application.CreateForm(TDados, Dados);
  try
      Application.CreateForm(TTelaInicial, TelaInicial);
      Application.Run;
    finally
      FreeAndNil(Dados);
    end;
  finally
    Finalizar;
  end;
end.
