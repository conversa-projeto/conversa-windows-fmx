object Dados: TDados
  OnCreate = DataModuleCreate
  Height = 385
  Width = 486
  object cdsConversas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 37
    Top = 16
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
    object cdsConversasdestinatario_id: TIntegerField
      FieldName = 'destinatario_id'
    end
  end
  object tmrAtualizarMensagens: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrAtualizarMensagensTimer
    Left = 155
    Top = 16
  end
end
