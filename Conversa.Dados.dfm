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
  end
end
