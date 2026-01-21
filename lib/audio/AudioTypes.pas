unit AudioTypes;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Winapi.Windows;

type
  TWaveformData = class
  private
    FAmplitudes: array[0..299] of Single;
    FWritePos: Integer;
    FLastWriteTick: Cardinal;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddSamples(const Data: TBytes);
    procedure AddSilence;
    function GetAmplitudes: TArray<Single>;
    function MsSinceLastWrite: Cardinal;
    procedure Clear;
  end;

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

{ TWaveformData }

constructor TWaveformData.Create;
var
  I: Integer;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FWritePos := 0;
  FLastWriteTick := GetTickCount;
  for I := 0 to High(FAmplitudes) do
    FAmplitudes[I] := 0;
end;

destructor TWaveformData.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TWaveformData.AddSamples(const Data: TBytes);
var
  I, SampleCount: Integer;
  Sample: SmallInt;
  MaxAmp: Single;
begin
  if Length(Data) < 2 then
    Exit;

  SampleCount := Length(Data) div 2;
  MaxAmp := 0;

  for I := 0 to SampleCount - 1 do
  begin
    Sample := PSmallInt(@Data[I * 2])^;
    if Abs(Sample) > MaxAmp then
      MaxAmp := Abs(Sample);
  end;

  FLock.Enter;
  try
    FAmplitudes[FWritePos] := MaxAmp / 32768;
    FWritePos := (FWritePos + 1) mod 300;
    FLastWriteTick := GetTickCount;
  finally
    FLock.Leave;
  end;
end;

procedure TWaveformData.AddSilence;
begin
  FLock.Enter;
  try
    FAmplitudes[FWritePos] := 0;
    FWritePos := (FWritePos + 1) mod 300;
    FLastWriteTick := GetTickCount;
  finally
    FLock.Leave;
  end;
end;

function TWaveformData.MsSinceLastWrite: Cardinal;
begin
  Result := GetTickCount - FLastWriteTick;
end;

function TWaveformData.GetAmplitudes: TArray<Single>;
var
  I, Idx: Integer;
begin
  SetLength(Result, 300);
  FLock.Enter;
  try
    for I := 0 to 299 do
    begin
      Idx := (FWritePos + I) mod 300;
      Result[I] := FAmplitudes[Idx];
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TWaveformData.Clear;
var
  I: Integer;
begin
  FLock.Enter;
  try
    for I := 0 to High(FAmplitudes) do
      FAmplitudes[I] := 0;
    FWritePos := 0;
  finally
    FLock.Leave;
  end;
end;

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
