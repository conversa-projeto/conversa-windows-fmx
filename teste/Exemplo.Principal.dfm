object Principal: TPrincipal
  Left = 0
  Top = 0
  Caption = 'Principal'
  ClientHeight = 407
  ClientWidth = 594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object btnLogin: TButton
    Left = 23
    Top = 23
    Width = 72
    Height = 24
    Caption = 'Login'
    TabOrder = 0
    OnClick = btnLoginClick
  end
  object edtLogin: TEdit
    Left = 101
    Top = 24
    Width = 116
    Height = 21
    TabOrder = 1
  end
  object btnConversas: TButton
    Left = 23
    Top = 53
    Width = 72
    Height = 24
    Caption = 'Conversas'
    TabOrder = 2
    OnClick = btnConversasClick
  end
  object btnContatos: TButton
    Left = 23
    Top = 83
    Width = 72
    Height = 24
    Caption = 'Contatos'
    TabOrder = 3
    OnClick = btnContatosClick
  end
  object edtConversas: TEdit
    Left = 101
    Top = 54
    Width = 116
    Height = 21
    TabOrder = 4
  end
  object edtContatos: TEdit
    Left = 101
    Top = 84
    Width = 116
    Height = 21
    TabOrder = 5
  end
  object btnVisualizada: TButton
    Left = 20
    Top = 113
    Width = 75
    Height = 25
    Caption = 'Visualizada'
    TabOrder = 6
    OnClick = btnVisualizadaClick
  end
end
