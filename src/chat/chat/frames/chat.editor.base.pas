unit chat.editor.base;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  chat.base,
  chat.tipos;

type
  {$SCOPEDENUMS ON}
  TTipoEditor = (Texto, Audio);
  TActionEditor = (EnviarMensagem, GravarMensagemAudio);

  TTarget = record
    Width: Single;
    Height: Single;
  end;

  TChatEditorBase = class(TChatBase)
  protected
    FEditor: TFrame;
  public
    constructor Create(AOwner: TComponent); reintroduce; overload;
    function TemConteudo: Boolean; virtual; abstract;
    procedure Limpar; virtual; abstract;
  end;

implementation

{$R *.fmx}

uses
  Chat.Editor;

{ TChatEditorBase }

constructor TChatEditorBase.Create(AOwner: TComponent);
begin
  inherited Create(TComponent(AOwner));
  FEditor := TFrame(AOwner);
  Parent := TChatEditor(FEditor).rtgEditor;
  Align := TAlignLayout.Bottom;
end;

end.
