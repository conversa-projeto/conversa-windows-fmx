unit AudioTypes;

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  TAudioBuffer = class
  private
    FBuffer: TBytes;
    FSize: Integer;
    FWritePos: Integer;
    FReadPos: Integer;
    FCount: Integer;
    FCriticalSection: TCriticalSection;
  public
    constructor Create(BufferSize: Integer);
    destructor Destroy; override;
    function Write(const Data: TBytes): Integer;
    function Read(var Data: TBytes; MaxSize: Integer): Integer;
    function Available: Integer;
    procedure Clear;
  end;

implementation

{ TAudioBuffer }

constructor TAudioBuffer.Create(BufferSize: Integer);
begin
  inherited Create;
  FSize := BufferSize;
  SetLength(FBuffer, FSize);
  FWritePos := 0;
  FReadPos := 0;
  FCount := 0;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TAudioBuffer.Destroy;
begin
  FCriticalSection.Free;
  inherited;
end;

function TAudioBuffer.Write(const Data: TBytes): Integer;
var
  i, WriteIndex: Integer;
begin
  Result := 0;
  if Length(Data) = 0 then
    Exit;

  FCriticalSection.Enter;
  try
    for i := 0 to Length(Data) - 1 do
    begin
      if FCount >= FSize then
        Break;  // Buffer cheio

      WriteIndex := FWritePos mod FSize;
      FBuffer[WriteIndex] := Data[i];
      FWritePos := (FWritePos + 1) mod FSize;
      Inc(FCount);
      Inc(Result);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TAudioBuffer.Read(var Data: TBytes; MaxSize: Integer): Integer;
var
  i, ReadIndex: Integer;
begin
  Result := 0;
  SetLength(Data, MaxSize);

  FCriticalSection.Enter;
  try
    for i := 0 to MaxSize - 1 do
    begin
      if FCount <= 0 then
        Break;  // Buffer vazio

      ReadIndex := FReadPos mod FSize;
      Data[i] := FBuffer[ReadIndex];
      FReadPos := (FReadPos + 1) mod FSize;
      Dec(FCount);
      Inc(Result);
    end;
  finally
    FCriticalSection.Leave;
  end;

  SetLength(Data, Result);
end;

function TAudioBuffer.Available: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FCount;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TAudioBuffer.Clear;
begin
  FCriticalSection.Enter;
  try
    FWritePos := 0;
    FReadPos := 0;
    FCount := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

end.
