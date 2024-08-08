unit Novo.Grupo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Conversa.FrameBase, FMX.Objects, FMX.Layouts, FMX.ListBox, Conversa.Dados,
  System.JSON,
  FMX.Controls.Presentation,
  FMX.Edit,
  Novo.Grupo.Usuario.Item;

type
  TNovoGrupo = class(TFrameBase)
    rctFundo: TRectangle;
    txtTitle: TText;
    lstContatos: TListBox;
    tmrCarregar: TTimer;
    lytgBotoes: TGridPanelLayout;
    rctBotaoCancelar: TRectangle;
    txtBotaoCancelar: TText;
    rctBotaoSalvar: TRectangle;
    txtBotaoSalvar: TText;
    rctNomeGrupo: TRectangle;
    edtNomeGrupo: TEdit;
    lytGrupo: TLayout;
    lytFoto: TLayout;
    crclFoto: TCircle;
    txtFoto: TText;
    lnSeparador: TLine;
    Line1: TLine;
    procedure tmrCarregarTimer(Sender: TObject);
    procedure rctBotaoCancelarClick(Sender: TObject);
    procedure rctBotaoSalvarClick(Sender: TObject);
  private
    procedure ValidarCriacao;
  public
    class procedure CriarGrupo;
  end;

var
  NovoGrupo: TNovoGrupo;

implementation

{$R *.fmx}

uses
  Conversa.Tela.Inicial.view,
  Conversa.Tipos;

{ TNovoGrupo }

class procedure TNovoGrupo.CriarGrupo;
begin
  TelaInicial.ModalView.Exibir(TNovoGrupo.Create(TelaInicial.lytClientForm));
end;

procedure TNovoGrupo.rctBotaoCancelarClick(Sender: TObject);
begin
  TelaInicial.ModalView.Ocultar;
end;

procedure TNovoGrupo.rctBotaoSalvarClick(Sender: TObject);
begin
  inherited;
  TRectangle(Sender).SetFocus;
  ValidarCriacao;
end;

procedure TNovoGrupo.tmrCarregarTimer(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  Dados.Contatos(
    procedure(jaContatos: TJSONArray)
    var
      Item: TListBoxItem;
    begin
      if Assigned(jaContatos) then
      begin
        for var joContato in  jaContatos do
        begin
          Item := TListBoxItem.Create(nil);
          Item.Text := '';
          Item.Height := 60;
          Item.Selectable := False;
          Item.ContatoItem := TNovoGrupoUsuarioItem.Create(Item, Dados.FDadosApp.Usuarios.GetOrAdd(joContato.GetValue<Integer>('id')));
          Item.ContatoItem.lblNome.Text := joContato.GetValue<String>('nome');
          Item.ContatoItem.Text1.Text := joContato.GetValue<String>('nome')[1];
          lstContatos.AddObject(Item);
        end;
      end;
    end
  );
end;

procedure TNovoGrupo.ValidarCriacao;
var
  I: Integer;
  Contatos: TArrayUsuarios;
  Conversa: TConversa;
  Contato: TUsuario;
begin
  Contatos := [Dados.FDadosApp.Usuario];

  if edtNomeGrupo.Text.Trim.IsEmpty then
    raise Exception.Create('Informe o nome do grupo')
  else
  for I := 0 to Pred(lstContatos.Count) do
    if TListBoxItem(lstContatos.ListItems[I]).Marcado then
      Contatos := Contatos + [TListBoxItem(lstContatos.ListItems[I]).ContatoItem.Usuario];

  if Length(Contatos) < 3 then
    raise Exception.Create('Selecione ao menos 2 contatos!');

  Conversa := TConversa.New(0).Tipo(TTipoConversa.Grupo).Descricao(edtNomeGrupo.Text);

  for Contato in Contatos do
    Conversa.AddUsuario(Contato);

  try
    Dados.NovoChat(Conversa);
    Dados.FDadosApp.Conversas.Add(Conversa);
    TelaInicial.ModalView.Ocultar;
  except
    FreeAndNil(Conversa);
  end;
end;

end.
