program TesteWebRTC;

uses
  System.StartUpCopy,
  FMX.Forms,
  Inicio.view in 'Inicio.view.pas' {Form1},
  FFmpeg.Binding in 'FFmpeg.Binding.pas',
  Pion.Whep.Binding in 'Pion.Whep.Binding.pas',
  Video.Decoder in 'Video.Decoder.pas',
  Audio.Player in 'Audio.Player.pas',
  Screen.Capture in 'Screen.Capture.pas',
  Mic.Capture in 'Mic.Capture.pas',
  Video.Encoder in 'Video.Encoder.pas',
  Audio.Encoder in 'Audio.Encoder.pas',
  Whip.view in 'Whip.view.pas' {FormWhip};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormWhip, FormWhip);
  Application.Run;
end.
