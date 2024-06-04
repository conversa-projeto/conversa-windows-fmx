object Dados: TDados
  OnCreate = DataModuleCreate
  Height = 577
  Width = 729
  PixelsPerInch = 144
  object cdsConversas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 56
    Top = 24
    object cdsConversasid: TIntegerField
      FieldName = 'id'
    end
    object cdsConversasdescricao: TStringField
      FieldName = 'descricao'
      Size = 100
    end
    object cdsConversasultima_mensagem: TDateTimeField
      FieldName = 'ultima_mensagem'
    end
    object cdsConversasultima_mensagem_texto: TStringField
      FieldName = 'ultima_mensagem_texto'
      Size = 100
    end
  end
  object tmrAtualizarMensagens: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrAtualizarMensagensTimer
    Left = 232
    Top = 24
  end
end
