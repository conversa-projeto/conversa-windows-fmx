﻿// Eduardo - 10/08/2024
unit chat.visualizador;

interface

uses
  System.Classes,
  System.UITypes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  chat.tipos,
  chat.base,
  chat.expositor,
  chat.editor.entrada,
  chat.anexo,
  chat.ultima,
  chat.mensagem,
  chat.conteudo.texto,
  chat.conteudo.imagem,
  chat.conteudo.anexo,
  chat.separador.data,
  chat.separador.lidas,
  chat.ordenador;

type
  TChatVisualizador = class(TControl, IControl)
  strict private
    FMensagens: TDictionary<Integer, TChatMensagem>;
    FSeparadorData: TDictionary<TDate, TChatSeparadorData>;
    FSeparadorLidas: TChatSeparadorLidas;
  private
    Chat: TChatExpositor;
    Ultima: TChatUltima;
    FAoVisualizar: TEvento;
    FAoClicar: TEventoMouseDown;
    function GetCount: Integer;
    function GetVisivel(const ID: Integer): Boolean;
    procedure AoVisualizarInterno(Frame: TFrame);
    procedure ChatScrollChange(Sender: TObject);
    function GetLarguraMaximaConteudo: Integer;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    function GetMensagem(const ID: Integer): TChatMensagem;
    procedure AoClicarInterno(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AtualizaSeparadoresData;
    function ObtemTopMensagem(ID: Integer; Data: TDateTime; Max: Single): Single;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdicionarMensagem(ID: Integer; Usuario: String; Data: TDateTime; Conteudos: TArray<TConteudo>);
    procedure RemoverMensagem(ID: Integer);
    property LarguraMaximaConteudo: Integer read GetLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property Mensagem[const ID: Integer]: TChatMensagem read GetMensagem;
    property Visivel[const ID: Integer]: Boolean read GetVisivel;
    property Count: Integer read GetCount;
    procedure Posicionar(ID: Integer = -1);
    function Visiveis: TArray<Integer>;
    function Listar: TArray<Integer>;
    procedure ExibirSeparadorLidas(ID: Integer);
    procedure OcultarSeparadorLidas;
    property AoVisualizar: TEvento read FAoVisualizar write FAoVisualizar;
    property AoClicar: TEventoMouseDown read FAoClicar write FAoClicar;
  end;

implementation

uses
  System.SysUtils;

{ TChatVisualizador }

constructor TChatVisualizador.Create(AOwner: TComponent);
begin
  inherited;
  FMensagens := TDictionary<Integer, TChatMensagem>.Create;
  FSeparadorData := TDictionary<TDate, TChatSeparadorData>.Create;

  Chat := TChatExpositor.Create(Self);
  Self.AddObject(Chat);

  Ultima := TChatUltima.Create(Chat.scroll);
  Chat.AddObject(Ultima);

  Chat.OnScrollChange := ChatScrollChange;

  FSeparadorLidas := TChatSeparadorLidas.Create(Self);
end;

destructor TChatVisualizador.Destroy;
begin
  FreeAndNil(FMensagens);
  FreeAndNil(FSeparadorData);
  inherited;
end;

procedure TChatVisualizador.ChatScrollChange(Sender: TObject);
begin
  Ultima.Change;
end;

procedure TChatVisualizador.AdicionarMensagem(ID: Integer; Usuario: String; Data: TDateTime; Conteudos: TArray<TConteudo>);
var
  Item: TConteudo;
  frmMensagem: TChatMensagem;
  frmTexto: TChatConteudoTexto;
  frmImagem: TChatConteudoImagem;
  frmAnexo: TChatConteudoAnexo;
  iTop: Integer;
begin
  if FMensagens.ContainsKey(ID) then
    raise Exception.Create('Mensagem já inserida!');

  frmMensagem := TChatMensagem.Create(Self, ID);
  frmMensagem.Nome := Usuario;
  frmMensagem.DataEnvio := Data;
  frmMensagem.AoVisualizar := AoVisualizarInterno;
  frmMensagem.rtgFundo.OnMouseDown := AoClicarInterno;
  frmMensagem.txtNome.OnMouseDown := AoClicarInterno;
  frmMensagem.txtHora.OnMouseDown := AoClicarInterno;
  frmMensagem.pthStatus.OnMouseDown := AoClicarInterno;

  iTop := 0;
  for Item in Conteudos do
  begin
    case Item.Tipo of
      TTipo.Texto:
      begin
        frmTexto := TChatConteudoTexto.Create(Self);
        frmTexto.txtMensagem.Text := Item.Conteudo;
        frmMensagem.AddConteudo(frmTexto);
        frmTexto.Position.Y := iTop;
        Inc(iTop, Round(frmTexto.Height + frmTexto.txtMensagem.Margins.Top));

        frmTexto.OnMouseDown := AoClicarInterno;
        frmTexto.txtMensagem.OnMouseDown := AoClicarInterno;
      end;
      TTipo.Imagem:
      begin
        frmImagem := TChatConteudoImagem.Create(Self);
        frmImagem.imgImagem.Bitmap.LoadFromFile(Item.Conteudo);
        frmMensagem.AddConteudo(frmImagem);
        frmImagem.Position.Y := iTop;
        Inc(iTop, Round(frmImagem.Height + frmImagem.imgImagem.Margins.Top));

        frmImagem.OnMouseDown := AoClicarInterno;
        frmImagem.imgImagem.OnMouseDown := AoClicarInterno;
      end;
      TTipo.Arquivo:
      begin
        frmAnexo := TChatConteudoAnexo.Create(Self);
        frmAnexo.lbNome.Text := ExtractFileName(Item.Conteudo);
        frmMensagem.AddConteudo(frmAnexo);
        frmAnexo.Position.Y := iTop;
        Inc(iTop, Round(frmAnexo.Height + frmAnexo.Layout.Margins.Top));

        frmAnexo.OnMouseDown := AoClicarInterno;
        frmAnexo.Path.OnMouseDown := AoClicarInterno;
        frmAnexo.Layout.OnMouseDown := AoClicarInterno;
      end;
    end;
  end;

  Chat.sbxCentro.Content.AddObject(frmMensagem);
  FMensagens.Add(ID, frmMensagem);

  frmMensagem.Position.Y := ObtemTopMensagem(ID, Data, Chat.scroll.Max);

  AtualizaSeparadoresData;
end;

procedure TChatVisualizador.RemoverMensagem(ID: Integer);
begin
  Chat.sbxCentro.Content.RemoveObject(FMensagens[ID]);
  FreeAndNil(FMensagens[ID]);
  FMensagens.Remove(ID);

  AtualizaSeparadoresData;
end;

function TChatVisualizador.ObtemTopMensagem(ID: Integer; Data: TDateTime; Max: Single): Single;
var
  Item: TOrdenador;
  Itens: TArrayOrdenador;
begin
  Result := Max;

  for var Mensagem in FMensagens.Values do
  begin
    if Mensagem.ID = ID then
      Continue;

    Item := Default(TOrdenador);
    Item.ID := Mensagem.ID;
    Item.Top := Mensagem.Position.Y;
    Item.Height := Mensagem.Height;
    Item.Data := Mensagem.DataEnvio;
    Itens := Itens + [Item];
  end;

  Itens.Sort(TTipoOrdenacao.Data);

  for Item in Itens do
    if Data <= Item.Data then
      Exit(Item.Top - 1);
end;

procedure TChatVisualizador.ExibirSeparadorLidas(ID: Integer);
begin
  Chat.sbxCentro.Content.AddObject(FSeparadorLidas);
  FSeparadorLidas.Position.Y := FMensagens[ID].Position.Y - 1;
end;

procedure TChatVisualizador.OcultarSeparadorLidas;
begin
  Chat.sbxCentro.Content.RemoveObject(FSeparadorLidas);
end;

procedure TChatVisualizador.AtualizaSeparadoresData;
var
  Item: TOrdenador;
  Itens: TArrayOrdenador;
  Separador: TChatSeparadorData;
  Anterior: TDate;
  frmData: TChatSeparadorData;
begin
  for Separador in FSeparadorData.Values do
  begin
    Chat.sbxCentro.Content.RemoveObject(Separador);
    FreeAndNil(Separador);
  end;
  FSeparadorData.Clear;

  for var Mensagem in FMensagens.Values do
  begin
    Item := Default(TOrdenador);
    Item.ID := Mensagem.ID;
    Item.Top := Mensagem.Position.Y;
    Item.Height := Mensagem.Height;
    Item.Data := Mensagem.DataEnvio;
    Itens := Itens + [Item];
  end;

  Itens.Sort(TTipoOrdenacao.Data);

  Anterior := 0;
  for Item in Itens do
  begin
    if Trunc(Item.Data) <> Anterior then
    begin
      Anterior := Trunc(Item.Data);
      frmData := TChatSeparadorData.Create(Self);
      Chat.sbxCentro.Content.AddObject(frmData);
      frmData.Data := Anterior;
      FSeparadorData.Add(Anterior, frmData);
      frmData.Position.Y := FMensagens[Item.ID].Position.Y - 1;
    end;
  end;
end;

procedure TChatVisualizador.AoVisualizarInterno(Frame: TFrame);
begin
  if Assigned(AoVisualizar) then
    AoVisualizar(Frame);
end;

procedure TChatVisualizador.AoClicarInterno(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Item: TFmxObject;
begin
  if Assigned(AoClicar) then
  begin
    Item := Sender as TFmxObject;
    while Assigned(Item) do
    begin
      Item := Item.Parent;
      if Item is TChatMensagem then
        Break;
    end;
    AoClicar(Item as TFrame, Sender, Button, Shift, X, Y);
  end;
end;

procedure TChatVisualizador.Posicionar(ID: Integer = -1);
begin
  if ID = -1 then
    Chat.scroll.Value := Chat.scroll.Max - Chat.scroll.ViewportSize
  else
  begin
    if Visivel[ID] then
      Exit;

    if Chat.scroll.Value < FMensagens[ID].Position.Y then
      Chat.scroll.Value := FMensagens[ID].Position.Y - Chat.scroll.ViewportSize + FMensagens[ID].Size.Height
    else
      Chat.scroll.Value := FMensagens[ID].Position.Y;
  end;
end;

function TChatVisualizador.GetCount: Integer;
begin
  Result := FMensagens.Count;
end;

function TChatVisualizador.Visiveis: TArray<Integer>;
var
  I: Integer;
begin
  Result := [];
  for I in FMensagens.Keys do
    if Visivel[I] then
      Result := Result + [I];
end;

function TChatVisualizador.GetVisivel(const ID: Integer): Boolean;
begin
  if not Assigned(FMensagens[ID]) then
    Exit(False);

  Result :=
    (FMensagens[ID].Position.Y > Chat.scroll.Value) and
    (FMensagens[ID].Position.Y + FMensagens[ID].Size.Height < Chat.scroll.Value + Chat.scroll.ViewportSize);
end;

function TChatVisualizador.Listar: TArray<Integer>;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to Pred(Count) do
    Result := Result + [I];
end;

function TChatVisualizador.GetLarguraMaximaConteudo: Integer;
begin
  Result := Chat.LarguraMaximaConteudo;
end;

procedure TChatVisualizador.SetLarguraMaximaConteudo(const Value: Integer);
begin
  Chat.LarguraMaximaConteudo := Value;
end;

function TChatVisualizador.GetMensagem(const ID: Integer): TChatMensagem;
begin
  Result := FMensagens[ID];
end;

end.