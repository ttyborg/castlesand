object Form1: TForm1
  Left = 192
  Top = 107
  Width = 361
  Height = 292
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 88
    Top = 24
    Width = 163
    Height = 25
    Caption = 'Resample 640 > 512'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 88
    Top = 56
    Width = 161
    Height = 25
    Caption = 'Exclude Common From Set'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 88
    Top = 120
    Width = 161
    Height = 25
    Caption = 'Compress file ZLibEx'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 88
    Top = 152
    Width = 161
    Height = 25
    Caption = 'Decompress file ZLibEx'
    TabOrder = 3
    OnClick = Button4Click
  end
  object OpenDialog1: TOpenDialog
    Left = 16
    Top = 24
  end
end
