﻿// Eduardo - 03/03/2024
unit Conversa.Principal.OLD;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.ListView.Types,
  FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  FMX.ListView,
  System.Rtti,
  System.Bindings.Outputs,
  Fmx.Bind.Editors,
  Data.Bind.EngExt,
  Fmx.Bind.DBEngExt,
  Data.Bind.Components,
  Data.Bind.DBScope,
  FMX.Objects,
  FMX.Layouts,
  Conversa.Conteudo,
  Mensagem.Tipos;

type
  TPrincipalOLD = class(TForm)
    blsDados: TBindingsList;
    bsrConversas: TBindSourceDB;
    lwConversas: TListView;
    LinkListControlToField1: TLinkListControlToField;
    lytConteudo: TLayout;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lwConversasChange(Sender: TObject);
  private
    FConteudos: TArray<TConteudo>;
    procedure EnviarMensagem(Conteudo: TConteudo; Mensagem: TMensagem);
  end;

var
  PrincipalOLD: TPrincipalOLD;

implementation

uses
  Conversa.Dados,
  Conversa.Login,
  System.NetEncoding;

{$R *.fmx}

procedure TPrincipalOLD.FormDestroy(Sender: TObject);
var
  Conteudo: TConteudo;
begin
  for Conteudo in FConteudos do
    Conteudo.Free;
end;

procedure TPrincipalOLD.FormShow(Sender: TObject);
begin
  TLogin.New(
    Self,
    procedure
    begin
      Dados.Conversas;
      lwConversasChange(lwConversas);
    end
  );
end;

procedure TPrincipalOLD.EnviarMensagem(Conteudo: TConteudo; Mensagem: TMensagem);
begin
  Dados.EnviarMensagem(Mensagem);
end;

procedure TPrincipalOLD.lwConversasChange(Sender: TObject);
var
  Conteudo: TConteudo;
  bJaCriado: Boolean;
begin
  bJaCriado := False;
  for Conteudo in FConteudos do
  begin
    if lwConversas.ItemIndex <> Conteudo.ItemIndex then
      Conteudo.Visible := False
    else
    begin
      bJaCriado := True;
      Conteudo.Visible := True;
    end;
  end;

  if bJaCriado then
    Exit;

  Conteudo := TConteudo.Create(lytConteudo);
  Conteudo.ItemIndex := lwConversas.ItemIndex;
  Conteudo.Conversa := Dados.cdsConversas.FieldByName('id').AsInteger;
  Conteudo.Usuario := Dados.Nome;
  Conteudo.UsuarioID := Dados.ID;
  Conteudo.AoEnviarMensagem := EnviarMensagem;
  FConteudos := FConteudos + [Conteudo];

  Conteudo.AdicionarMensagens(Dados.Mensagens(Dados.cdsConversas.FieldByName('id').AsInteger));
end;

end.
