unit Conversa.Chat.Listagem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Objects,

  Conversa.FrameBase,
  Conversa.Chat.Listagem.Item,
//  Conversa.Conteudo,
  Conversa.Dados,
  Conversa.Chat,
  FMX.Controls.Presentation,
  Mensagem.Tipos;

type
  TListBoxItem = class(FMX.ListBox.TListBoxItem)
  public
    ContatoItem: TConversasItemFrame;
  end;
  TChatListagem = class(TFrameBase)
    lytClient: TLayout;
    rctListaConversas: TRectangle;
    lstConversas: TListBox;
    lytViewClient: TLayout;
    rctFundo: TRectangle;
    Timer1: TTimer;
    lblAvisoConversa: TLabel;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FChats: TArray<TChat>;
    procedure btnAbrirChat(ChatID: Integer; sNome: String);
    procedure EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
  public
    { Public declarations }
    class function New(AOwner: TFmxObject): TChatListagem; static;
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

destructor TChatListagem.Destroy;
var
  Chat: TChat;
begin
  for Chat in FChats do
    Chat.Free;
  inherited;
end;

class function TChatListagem.New(AOwner: TFmxObject): TChatListagem;
begin
  Result := TChatListagem.Create(AOwner);
  Result.Align := TAlignLayout.Client;
  Result.Parent := AOwner;
  Result.lytClient.Visible := True;
  Result.Visible := True;
  Result.lytClient.Align := TAlignLayout.Client;
end;

procedure TChatListagem.Timer1Timer(Sender: TObject);
var
  Item: TListBoxItem;
begin
  Timer1.Enabled := False;
  Dados.Conversas;
  Dados.cdsConversas.First;
  while not Dados.cdsConversas.Eof do
  try
    Item := TListBoxItem.Create(nil);
    Item.Text := '';
    Item.Height := 60;
    Item.Selectable := False;
    //Item.Tag := Dados.cdsConversas.IGGetInt('id');

    Item.ContatoItem :=
      TConversasItemFrame.New(Item, Dados.cdsConversas.FieldByName('id').AsInteger)
        .Descricao(Dados.cdsConversas.FieldByName('descricao').AsString)
        .Mensagem(Dados.cdsConversas.FieldByName('ultima_mensagem_texto').AsString)
        .UltimaMensagem(Dados.cdsConversas.FieldByName('ultima_mensagem').AsDateTime)
        .OnClick(btnAbrirChat);

    lstConversas.AddObject(Item);
  finally
    Dados.cdsConversas.Next;
  end;
end;

procedure TChatListagem.EnviarMensagem(Conteudo: TChat; Mensagem: TMensagem);
begin
  Dados.EnviarMensagem(Mensagem);
end;

procedure TChatListagem.btnAbrirChat(ChatID: Integer; sNome: String);
var
  Chat: TChat;
  bJaCriado: Boolean;
begin
  bJaCriado := False;
  for Chat in FChats do
  begin
    if Chat.ID <> ChatID then
      Chat.Visible := False
    else
    begin
      bJaCriado := True;
      Chat.Visible := True;
    end;
  end;

  if bJaCriado then
    Exit;

  Chat := TChat.Create(lytViewClient);
  Chat.lblNome.Text := sNome;
  Chat.ID := ChatID;
  Chat.Usuario := Dados.Nome;
  Chat.UsuarioID := Dados.ID;
  Chat.AoEnviarMensagem := EnviarMensagem;
  Chat.AdicionarMensagens(Dados.Mensagens(ChatID));
end;

end.
