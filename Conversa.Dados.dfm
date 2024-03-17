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
  object cdsMensagens: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 200
    Top = 24
    object cdsMensagensid: TIntegerField
      FieldName = 'id'
    end
    object cdsMensagensremetente_id: TIntegerField
      FieldName = 'remetente_id'
    end
    object cdsMensagensremetente: TStringField
      FieldName = 'remetente'
      Size = 100
    end
    object cdsMensagensinserida: TDateTimeField
      FieldName = 'inserida'
    end
    object cdsMensagensalterada: TDateTimeField
      FieldName = 'alterada'
    end
    object cdsMensagensconteudos: TDataSetField
      FieldName = 'conteudos'
    end
  end
  object cdsConteudos: TClientDataSet
    Aggregates = <>
    DataSetField = cdsMensagensconteudos
    Params = <>
    Left = 344
    Top = 24
    object cdsConteudosid: TIntegerField
      FieldName = 'id'
    end
    object cdsConteudosordem: TIntegerField
      FieldName = 'ordem'
    end
    object cdsConteudostipo: TIntegerField
      FieldName = 'tipo'
    end
    object cdsConteudosconteudo: TBlobField
      FieldName = 'conteudo'
    end
  end
end
