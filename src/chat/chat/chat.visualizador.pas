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
  chat.editor,
  chat.ultima,
  chat.mensagem,
  chat.conteudo.texto,
  chat.conteudo.imagem,
  chat.conteudo.anexo,
  chat.conteudo.mensagem.audio,
  chat.separador.data,
  chat.separador.lidas,
  chat.ordenador,
  chat.emoji;

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
    FAoClicarDownloadAnexo: TEventoMouseDown;
    FAoChegarLimite: TEventoLimite;
    function GetCount: Integer;
    function GetVisivel(const ID: Integer): Boolean;
    procedure AoVisualizarInterno(Frame: TFrame);
    procedure ChatScrollChange(Sender: TObject);
    function GetLarguraMaximaConteudo: Integer;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    function GetMensagem(const ID: Integer): TChatMensagem;
    procedure AoClicarInterno(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AoClicarDownloadAnexoInterno(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    function ObtemTopMensagem(ID: Integer; Data: TDateTime; Max: Single): Single;
    function GetBottom: Single;
    procedure SetBottom(const Value: Single);
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
    procedure ExibirSeparadoresData;
    procedure OcultarSeparadoresData;
    property Bottom: Single read GetBottom write SetBottom;
    property AoVisualizar: TEvento read FAoVisualizar write FAoVisualizar;
    property AoClicar: TEventoMouseDown read FAoClicar write FAoClicar;
    property AoClicarDownloadAnexo: TEventoMouseDown read FAoClicarDownloadAnexo write FAoClicarDownloadAnexo;
    property AoChegarLimite: TEventoLimite read FAoChegarLimite write FAoChegarLimite;
  end;

implementation

uses
  System.SysUtils,
  System.Types;

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

  if Assigned(AoChegarLimite) then
    if Chat.scroll.Value = 0 then
      AoChegarLimite(TLimite.Superior)
    else
    if Chat.scroll.Value = Chat.scroll.Max - Chat.scroll.ViewportSize then
      AoChegarLimite(TLimite.Inferior);
end;

procedure TChatVisualizador.AdicionarMensagem(ID: Integer; Usuario: String; Data: TDateTime; Conteudos: TArray<TConteudo>);
var
  Item: TConteudo;
  frmMensagem: TChatMensagem;
  frmTexto: TChatConteudoTexto;
  frmImagem: TChatConteudoImagem;
  frmAnexo: TChatConteudoAnexo;
  frmMsgAudio: TChatConteudoMensagemAudio;
  iTop: Integer;
begin
  {TODO -oDaniel -cValidar : Inclusão Repetida}
  if FMensagens.ContainsKey(ID) then
  begin
    Sleep(0);
    Exit;
  end;
    //raise Exception.Create('Mensagem já inserida!');

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

        if TEmojiItem.SoEmoji(Item.Conteudo) then
          frmTexto.txtMensagem.TextSettings.Font.Size := 30;

        frmMensagem.AddConteudo(frmTexto);
        frmTexto.Position.Y := iTop;
        Inc(iTop, Round(frmTexto.Height + frmTexto.txtMensagem.Margins.Top));

        frmTexto.OnMouseDown := AoClicarInterno;
        frmTexto.txtMensagem.OnMouseDown := AoClicarInterno;
      end;
      TTipo.Imagem:
      begin
        if FileExists(Item.Conteudo) then
        begin
          frmImagem := TChatConteudoImagem.Create(Self);
          frmImagem.LoadFromFile(Item.Conteudo);
          frmMensagem.AddConteudo(frmImagem);
          frmImagem.Position.Y := iTop;
          Inc(iTop, Round(frmImagem.Height + frmImagem.ImageMargins.Top));
          frmImagem.OnMouseDown := AoClicarInterno;
        end
        else
        begin
          frmTexto := TChatConteudoTexto.Create(Self);
          frmTexto.txtMensagem.Text := 'Erro: Imagem não encontrada!';
          frmMensagem.AddConteudo(frmTexto);
          frmTexto.Position.Y := iTop;
          Inc(iTop, Round(frmTexto.Height + frmTexto.txtMensagem.Margins.Top));
          frmTexto.OnMouseDown := AoClicarInterno;
          frmTexto.txtMensagem.OnMouseDown := AoClicarInterno;
        end;
      end;
      TTipo.Arquivo:
      begin
        frmMensagem.HeightContents := [TChatMensagemHeightContent.Nome];
        frmAnexo := TChatConteudoAnexo.Create(Self);
        frmAnexo.Identificador := Item.Conteudo;

        if Item.Nome.Trim.IsEmpty then
          frmAnexo.lbNome.Text := ExtractFileName(Item.Conteudo)
        else
        if Item.Extensao.Trim.IsEmpty then
          frmAnexo.lbNome.Text := Item.Nome
        else
          frmAnexo.lbNome.Text := Item.Nome +'.'+ Item.Extensao;
        frmMensagem.AddConteudo(frmAnexo);
        frmMensagem.lytBottom.Parent := frmAnexo.lytDados;
        frmAnexo.lbTamanho.Parent := frmMensagem.lytBottom;
        frmAnexo.Position.Y := iTop;
        Inc(iTop, Round(frmAnexo.Height + frmAnexo.lytDados.Margins.Top));
        frmAnexo.OnMouseDown := AoClicarInterno;
        frmAnexo.Path.OnMouseDown := AoClicarInterno;
        frmAnexo.lytDados.OnMouseDown := AoClicarInterno;
        frmAnexo.lytDownload.OnMouseDown := AoClicarDownloadAnexoInterno;
      end;
      TTipo.MensagemAudio:
      begin
        frmMensagem.HeightContents := [TChatMensagemHeightContent.Nome];
        frmMsgAudio := TChatConteudoMensagemAudio.Create(Self);
        frmMsgAudio.SetFile(Item.Conteudo);
        frmMensagem.AddConteudo(frmMsgAudio);
        frmMensagem.lytBottom.Parent := frmMsgAudio.lytDados;
        frmMsgAudio.txtInformacoes.Parent := frmMensagem.lytBottom;
        frmMsgAudio.Position.Y := iTop;
        Inc(iTop, Round(frmMsgAudio.Height + frmMsgAudio.lytDados.Margins.Top));
      end;
    end;
  end;

  Chat.sbxCentro.Content.AddObject(frmMensagem);
  FMensagens.Add(ID, frmMensagem);

  frmMensagem.Position.Y := ObtemTopMensagem(ID, Data, Chat.scroll.Max);
end;

procedure TChatVisualizador.RemoverMensagem(ID: Integer);
begin
  Chat.sbxCentro.Content.RemoveObject(FMensagens[ID]);
  FreeAndNil(FMensagens[ID]);
  FMensagens.Remove(ID);
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
var
  Separador: TChatSeparadorData;
begin
  Chat.sbxCentro.Content.AddObject(FSeparadorLidas);

  if FSeparadorData.TryGetValue(Trunc(FMensagens[ID].DataEnvio), Separador) and (Separador.Position.Y + Separador.Height + 10 > FMensagens[ID].Position.Y) then
    FSeparadorLidas.Position.Y := Separador.Position.Y - 1
  else
    FSeparadorLidas.Position.Y := FMensagens[ID].Position.Y - 1;
end;

procedure TChatVisualizador.OcultarSeparadorLidas;
begin
  Chat.sbxCentro.Content.RemoveObject(FSeparadorLidas);
end;

procedure TChatVisualizador.ExibirSeparadoresData;
var
  Item: TOrdenador;
  Itens: TArrayOrdenador;
  Separador: TChatSeparadorData;
  Ultima: TDate;
begin
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

  Ultima := 0;
  for Item in Itens do
  begin
    if Ultima = Trunc(Item.Data) then
      Continue;

    Ultima := Trunc(Item.Data);

    if FSeparadorData.TryGetValue(Ultima, Separador) then
    begin
      if Separador.Position.Y > FMensagens[Item.ID].Position.Y then
        Separador.Position.Y := FMensagens[Item.ID].Position.Y - 1;
    end
    else
    begin
      Separador := TChatSeparadorData.Create(Self);
      Chat.sbxCentro.Content.AddObject(Separador);
      Separador.Data := Ultima;
      FSeparadorData.Add(Ultima, Separador);
      Separador.Position.Y := FMensagens[Item.ID].Position.Y - 1;
    end;
  end;
end;

procedure TChatVisualizador.OcultarSeparadoresData;
var
  Separador: TPair<TDate, TChatSeparadorData>;
begin
  for Separador in FSeparadorData.ToArray do
  begin
    Chat.sbxCentro.Content.RemoveObject(Separador.Value);
    FreeAndNil(Separador.Value);
    FSeparadorData.Remove(Separador.Key);
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

procedure TChatVisualizador.AoClicarDownloadAnexoInterno(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Item: TFmxObject;
begin
  if Assigned(FAoClicarDownloadAnexo) then
  begin
    Item := Sender as TFmxObject;
    while Assigned(Item) do
    begin
      Item := Item.Parent;
      if Item is TChatMensagem then
        Break;
    end;
    AoClicarDownloadAnexo(Item as TFrame, Sender, Button, Shift, X, Y);
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

function TChatVisualizador.GetBottom: Single;
begin
  Result := Chat.Bottom;
end;

procedure TChatVisualizador.SetBottom(const Value: Single);
begin
  Chat.Bottom := Value;
end;

end.
