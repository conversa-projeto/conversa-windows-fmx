unit AudioMixer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Winapi.Windows,
  Winapi.MMSystem,
  AudioTypes;

type
  TClientAudioStream = class
    ClientID: Integer;
    Buffer: TAudioBuffer;
    WaveformData: TWaveformData;
  end;

  TAudioMixerThread = class(TThread)
  private
    FClientStreams: TList<TClientAudioStream>;
    FOutputBuffer: TAudioBuffer;
    FOnCheckActive: TFunc<Boolean>;
    FFinalizado: Boolean;
  public
    constructor Create(AClientStreams: TList<TClientAudioStream>; AOutputBuffer: TAudioBuffer; AOnCheckActive: TFunc<Boolean>);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Finalizar;
    property Finalizado: Boolean read FFinalizado;
  end;

implementation

{ TAudioMixerThread }

constructor TAudioMixerThread.Create(
  AClientStreams: TList<TClientAudioStream>;
  AOutputBuffer: TAudioBuffer;
  AOnCheckActive: TFunc<Boolean>
);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FClientStreams := AClientStreams;
  FOutputBuffer := AOutputBuffer;
  FOnCheckActive := AOnCheckActive;
  FFinalizado := False;
end;

destructor TAudioMixerThread.Destroy;
begin
  Finalizar;
  inherited;
end;

procedure TAudioMixerThread.Finalizar;
begin
  if FFinalizado then
    Exit;
  FFinalizado := True;
  Terminate;
end;

procedure TAudioMixerThread.Execute;
var
  MixedData: TBytes;
  ClientData: array of TBytes;
  i, j: Integer;
  Sample: SmallInt;
  MixedSample: Integer;
  ChunkSize: Integer;
  MaxBufferThreshold: Integer;
  ActiveClients: Integer;
  NextProcessTime: Int64;
  CurrentTime: Int64;
  SleepTime: Integer;
  ProcessInterval: Integer;
begin
  // Aumenta precis�o do timer para 1ms
  timeBeginPeriod(1);
  try
    // Aguarda estar ativo
    while not FFinalizado do
    begin
      if Assigned(FOnCheckActive) and FOnCheckActive() then
        Break;
      Sleep(10);
    end;

    ChunkSize := 2048; // 23ms de �udio a 44.1kHz
    MaxBufferThreshold := ChunkSize * 10; // ~230ms
    ProcessInterval := 23; // ms entre processamentos
    NextProcessTime := GetTickCount64;

    while not FFinalizado do
    begin
      CurrentTime := GetTickCount64;

      // S� processa se chegou a hora
      if CurrentTime >= NextProcessTime then
      begin
        SetLength(MixedData, ChunkSize);
        SetLength(ClientData, FClientStreams.Count);
        ActiveClients := 0;

        // L� dados de clientes que t�m dados SUFICIENTES
        for i := 0 to FClientStreams.Count - 1 do
        begin
          if FClientStreams[i].Buffer.Available >= ChunkSize then
          begin
            FClientStreams[i].Buffer.Read(ClientData[i], ChunkSize);
            Inc(ActiveClients);
          end
          else if FClientStreams[i].Buffer.Available > MaxBufferThreshold then
          begin
            var Discard: TBytes;
            FClientStreams[i].Buffer.Read(Discard, ChunkSize);
            if FClientStreams[i].Buffer.Available >= ChunkSize then
            begin
              FClientStreams[i].Buffer.Read(ClientData[i], ChunkSize);
              Inc(ActiveClients);
            end;
          end
          else
            SetLength(ClientData[i], 0);
        end;

        // S� processa se houver pelo menos 1 cliente ativo
        if ActiveClients > 0 then
        begin
          // Mixa os samples (16-bit PCM)
          for j := 0 to (ChunkSize div 2) - 1 do
          begin
            MixedSample := 0;
            ActiveClients := 0;

            for i := 0 to Length(ClientData) - 1 do
            begin
              if Length(ClientData[i]) >= (j + 1) * 2 then
              begin
                Sample := PSmallInt(@ClientData[i][j * 2])^;
                MixedSample := MixedSample + Sample;
                Inc(ActiveClients);
              end;
            end;

            if ActiveClients > 0 then
              MixedSample := MixedSample div ActiveClients;

            if MixedSample > 32767 then
              MixedSample := 32767
            else if MixedSample < -32768 then
              MixedSample := -32768;

            PSmallInt(@MixedData[j * 2])^ := SmallInt(MixedSample);
          end;

          // Envia para o buffer de reprodu��o
          FOutputBuffer.Write(MixedData);

          // Agenda pr�ximo processamento
          NextProcessTime := NextProcessTime + ProcessInterval;

          // Se atrasou muito (>100ms), ressincroniza
          if CurrentTime > NextProcessTime + 100 then
            NextProcessTime := CurrentTime + ProcessInterval;
        end
        else
          // Sem dados - agenda pr�ximo check
          NextProcessTime := CurrentTime + 10;
      end;

      // Calcula quanto tempo esperar at� pr�ximo processamento
      CurrentTime := GetTickCount64;
      SleepTime := Integer(NextProcessTime - CurrentTime);

      if SleepTime > 0 then
      begin
        if SleepTime > 50 then
          SleepTime := 50; // Limita sleep m�ximo
        Sleep(SleepTime);
      end
      else
        Sleep(1); // Yield m�nimo
    end;
  finally
        // Restaura precis�o normal do timer
    timeEndPeriod(1);
  end;
end;

end.
