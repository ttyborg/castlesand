object Form1: TForm1
  Left = 282
  Top = 194
  Caption = 'Form1'
  ClientHeight = 529
  ClientWidth = 673
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 152
    Top = 8
    Width = 512
    Height = 512
  end
  object Button2: TButton
    Left = 8
    Top = 8
    Width = 137
    Height = 33
    Caption = 'RVOSimulator.Create'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 8
    Top = 144
    Width = 137
    Height = 33
    Caption = 'Step'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = Button3Click
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 1
    OnTimer = Button3Click
    Left = 168
    Top = 24
  end
end