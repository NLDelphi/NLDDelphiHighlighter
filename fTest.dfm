object Form1: TForm1
  Left = 207
  Top = 135
  Width = 828
  Height = 544
  Caption = 'Wat een mooi form toch weer. (Design by GolezTrol)'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 431
    Top = 54
    Width = 3
    Height = 444
    Cursor = crHSplit
  end
  object mSource: TMemo
    Left = 0
    Top = 54
    Width = 431
    Height = 444
    Align = alLeft
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'psComment:'
      '// Simple comment (//) will end on end of line'
      '  if Data[Ptr] = #13 then'
      '    State := psUnknown;'
      'psBlockComment1:'
      '// BlockComment { will end on }'
      '  if Data[Ptr] = '#39'}'#39' then'
      '  begin'
      '    State := psUnknown;'
      '    Inc(Ptr); // Include this character in color'
      '  end;'
      'psBlockComment2:'
      '// BlockComment (* will end on *)'
      '  if (Data[Ptr] = '#39'*'#39') and (Data[Ptr+1] = '#39')'#39') then'
      '  begin'
      '    State := psUnknown;'
      '    Inc(Ptr, 2); // Include these characters in color'
      '  end;')
    ParentFont = False
    TabOrder = 0
  end
  object mTarget: TMemo
    Left = 434
    Top = 54
    Width = 386
    Height = 444
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object pToolbar: TPanel
    Left = 0
    Top = 0
    Width = 820
    Height = 54
    Align = alTop
    TabOrder = 2
    object lSource: TLabel
      Left = 7
      Top = 38
      Width = 160
      Height = 13
      Caption = 'Plak hieronder je Delphi broncode'
    end
    object lTarget: TLabel
      Left = 678
      Top = 38
      Width = 133
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Hieronder komt het resultaat'
    end
    object lColor: TLabel
      Left = 7
      Top = 10
      Width = 64
      Height = 13
      Caption = 'Color scheme'
    end
    object btnHighlight: TButton
      Left = 231
      Top = 5
      Width = 75
      Height = 23
      Caption = 'Highlight'
      Default = True
      TabOrder = 0
      OnClick = btnHighlightClick
    end
    object ProgressBar1: TProgressBar
      Left = 448
      Top = 16
      Width = 363
      Height = 16
      Anchors = [akLeft, akTop, akRight]
      Min = 0
      Max = 100
      TabOrder = 1
    end
    object cbColor: TComboBox
      Left = 81
      Top = 6
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 2
      Items.Strings = (
        'pDefault'
        'pClassic'
        'pTwilight'
        'pOcean'
        'pLightweight'
        'pGolezTrol')
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 498
    Width = 820
    Height = 19
    Panels = <>
    SimplePanel = False
  end
end
