object Dados: TDados
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 578
  Width = 729
  PixelsPerInch = 144
  object tmrAtualizarMensagens: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrAtualizarMensagensTimer
    Left = 233
    Top = 24
  end
end
