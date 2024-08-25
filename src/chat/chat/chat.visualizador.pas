// Eduardo - 10/08/2024
unit chat.visualizador;

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  System.Generics.Collections,
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
  chat.separador.data;

type
  TChatVisualizador = class(TControl, IControl)
  strict private
    FMensagens: TDictionary<Integer, TChatMensagem>;
    FSeparadorData: TDictionary<TDate, TChatSeparadorData>;
  private
    Chat: TChatExpositor;
    Ultima: TChatUltima;
    FAoVisualizar: TEvento;
    function GetCount: Integer;
    function GetVisivel(const ID: Integer): Boolean;
    procedure AoVisualizarInterno(Frame: TFrame);
    procedure ChatScrollChange(Sender: TObject);
    function GetLarguraMaximaConteudo: Integer;
    procedure SetLarguraMaximaConteudo(const Value: Integer);
    function GetMensagem(const ID: Integer): TChatMensagem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdicionarMensagem(ID: Integer; Usuario: String; Data: TDateTime; Conteudos: TArray<TConteudo>; PosTop: Single = -1);
    procedure RemoverMensagem(ID: Integer);
    procedure AdicionarSeparadorData(Data: TDate; PosTop: Single);
    procedure RemoveSeparadorData(Data: TDate);
    property LarguraMaximaConteudo: Integer read GetLarguraMaximaConteudo write SetLarguraMaximaConteudo;
    property Mensagem[const ID: Integer]: TChatMensagem read GetMensagem;
    property Visivel[const ID: Integer]: Boolean read GetVisivel;
    property Count: Integer read GetCount;
    procedure Posicionar(ID: Integer = -1);
    function Visiveis: TArray<Integer>;
    function Listar: TArray<Integer>;
    property AoVisualizar: TEvento read FAoVisualizar write FAoVisualizar;
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

procedure TChatVisualizador.AdicionarMensagem(ID: Integer; Usuario: String; Data: TDateTime; Conteudos: TArray<TConteudo>; PosTop: Single = -1);
var
  Item: TConteudo;
  frmMensagem: TChatMensagem;
  frmTexto: TChatConteudoTexto;
  frmImagem: TChatConteudoImagem;
  frmAnexo: TChatConteudoAnexo;
begin
  if FMensagens.ContainsKey(ID) then
    raise Exception.Create('Mensagem já inserida!');

  frmMensagem := TChatMensagem.Create(Self, ID);
  frmMensagem.Nome := Usuario;
  frmMensagem.txtHora.Text := FormatDateTime('hh:nn', Data);
  frmMensagem.AoVisualizar := AoVisualizarInterno;

  for Item in Conteudos do
  begin
    case Item.Tipo of
      TTipo.Texto:
      begin
        frmTexto := TChatConteudoTexto.Create(Self);
        frmTexto.txtMensagem.Text := Item.Conteudo;
        frmMensagem.AddConteudo(frmTexto);
      end;
      TTipo.Imagem:
      begin
        frmImagem := TChatConteudoImagem.Create(Self);
        frmImagem.imgImagem.Bitmap.LoadFromFile(Item.Conteudo);
        frmMensagem.AddConteudo(frmImagem);
      end;
      TTipo.Arquivo:
      begin
        frmAnexo := TChatConteudoAnexo.Create(Self);
        frmAnexo.lbNome.Text := ExtractFileName(Item.Conteudo);
        frmMensagem.AddConteudo(frmAnexo);
      end;
    end;
  end;

  Chat.sbxCentro.Content.AddObject(frmMensagem);
  FMensagens.Add(ID, frmMensagem);

  if PosTop = -1 then
    frmMensagem.Position.Y := Chat.scroll.Max
  else
    frmMensagem.Position.Y := PosTop;
end;

procedure TChatVisualizador.RemoverMensagem(ID: Integer);
begin
  Chat.sbxCentro.Content.RemoveObject(FMensagens[ID]);
  FreeAndNil(FMensagens[ID]);
  FMensagens.Remove(ID);
end;

procedure TChatVisualizador.AdicionarSeparadorData(Data: TDate; PosTop: Single);
var
  frmData: TChatSeparadorData;
begin
  if FSeparadorData.ContainsKey(Data) then
    Exit;
//    raise Exception.Create('Separador de data já inserido!');

  frmData := TChatSeparadorData.Create(Self);
  Chat.sbxCentro.Content.AddObject(frmData);
  frmData.Data := Data;
  FSeparadorData.Add(Data, frmData);
  frmData.Position.Y := PosTop;
end;

procedure TChatVisualizador.RemoveSeparadorData(Data: TDate);
begin
  if not FSeparadorData.ContainsKey(Data) then
    Exit;
  Chat.sbxCentro.Content.RemoveObject(FSeparadorData.Items[Data]);
  FreeAndNil(FSeparadorData.Items[Data]);
  FSeparadorData.Remove(Data);
end;

procedure TChatVisualizador.AoVisualizarInterno(Frame: TFrame);
begin
  if Assigned(AoVisualizar) then
    AoVisualizar(Frame);
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
begin
  Result := FMensagens.Keys.ToArray;
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
