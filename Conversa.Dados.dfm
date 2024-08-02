object Dados: TDados
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 385
  Width = 486
  object tmrAtualizarMensagens: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrAtualizarMensagensTimer
    Left = 155
    Top = 16
  end
end
