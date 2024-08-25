// Eduardo - 25/08/2024
unit chat.ordenador;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults;

{$SCOPEDENUMS ON}

type
  TTipoOrdenacao = (Altura, Data);

  TOrdenador = record
    ID: Integer;
    Top: Single;
    Height: Single;
    Data: TDate;
  end;

  TOrdenadorComparer = class(TInterfacedObject, IComparer<TOrdenador>)
  private
    FTipo: TTipoOrdenacao;
  public
    constructor Create(Tipo: TTipoOrdenacao);
    function Compare(const Left, Right: TOrdenador): Integer;
  end;

  TArrayOrdenador = TArray<TOrdenador>;
  THArrayOrdenador = record helper for TArrayOrdenador
  public
    procedure Sort(Tipo: TTipoOrdenacao);
  end;

implementation

{ TOrdenadorComparer }

constructor TOrdenadorComparer.Create(Tipo: TTipoOrdenacao);
begin
  FTipo := Tipo;
end;

function TOrdenadorComparer.Compare(const Left, Right: TOrdenador): Integer;
var
  L: Double;
  R: Double;
begin
  case FTipo of
    TTipoOrdenacao.Altura:
    begin
      L := Left.Top;
      R := Right.Top;
    end;
    TTipoOrdenacao.Data:
    begin
      L := Left.Data;
      R := Right.Data
    end;
  else
    raise Exception.Create('Tipo não definido!');
  end;

  if L < R then
    Result := -1
  else
  if L > R then
    Result := 1
  else
    Result := 0;
end;

{ THArrayOrdenador }

procedure THArrayOrdenador.Sort(Tipo: TTipoOrdenacao);
var
  Comp: TOrdenadorComparer;
begin
  Comp := TOrdenadorComparer.Create(Tipo);
  try
    TArray.Sort<TOrdenador>(Self, Comp);
  finally
    FreeAndNil(Comp);
  end;
end;

end.
