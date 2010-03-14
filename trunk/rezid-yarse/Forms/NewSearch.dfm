object FNewSearch: TFNewSearch
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Nouvelle Recherche'
  ClientHeight = 524
  ClientWidth = 579
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 579
    Height = 524
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
    object gbMainSearch: TGroupBox
      Left = 0
      Top = 0
      Width = 579
      Height = 97
      Align = alTop
      Caption = 'Options de Recherche'
      TabOrder = 0
      object leSearchTerm: TLabeledEdit
        Left = 16
        Top = 48
        Width = 433
        Height = 21
        EditLabel.Width = 161
        EditLabel.Height = 13
        EditLabel.Caption = 'Entrez un argument de recherche'
        TabOrder = 0
        Text = 'LOL'
        OnKeyDown = leSearchTermKeyDown
        OnKeyUp = leSearchTermKeyDown
      end
    end
    object pOkCancel: TPanel
      Left = 0
      Top = 449
      Width = 579
      Height = 56
      Align = alBottom
      BevelInner = bvRaised
      BevelOuter = bvLowered
      TabOrder = 1
      object bOK: TButton
        Left = 16
        Top = 15
        Width = 105
        Height = 25
        Caption = 'Ok'
        Default = True
        Enabled = False
        TabOrder = 0
        OnClick = bOKClick
      end
    end
    object StatusBar1: TStatusBar
      Left = 0
      Top = 505
      Width = 579
      Height = 19
      Panels = <
        item
          Text = 'Ready'
          Width = 50
        end>
    end
    object lbInformation: TListBox
      Left = 0
      Top = 347
      Width = 579
      Height = 102
      Align = alBottom
      ItemHeight = 13
      Items.Strings = (
        'Pr'#234't')
      TabOrder = 3
    end
    object gbSearchInNamesOrPath: TGroupBox
      Left = 0
      Top = 97
      Width = 579
      Height = 48
      Align = alTop
      Caption = 'Options de Recherche Avanc'#233'e'
      TabOrder = 4
      object rbSearchInNames: TRadioButton
        Left = 16
        Top = 19
        Width = 210
        Height = 17
        Caption = 'Rechercher dans les noms (plus rapide)'
        Checked = True
        TabOrder = 0
        TabStop = True
      end
      object rbSearchInFullPath: TRadioButton
        Left = 256
        Top = 19
        Width = 209
        Height = 17
        Caption = 'Rerchercher dans les chemins entiers'
        TabOrder = 1
      end
    end
    object gbSearchWhat: TGroupBox
      Left = 0
      Top = 145
      Width = 579
      Height = 190
      Align = alTop
      Caption = 'Filtres de type de fichier'
      TabOrder = 5
      object iVideoFiles: TImage
        Left = 66
        Top = 95
        Width = 16
        Height = 16
        Transparent = True
      end
      object iAllFiles: TImage
        Left = 18
        Top = 24
        Width = 16
        Height = 16
        Transparent = True
      end
      object iAudioFiles: TImage
        Left = 66
        Top = 118
        Width = 16
        Height = 16
        Transparent = True
      end
      object iFolders: TImage
        Left = 18
        Top = 46
        Width = 16
        Height = 16
        Transparent = True
      end
      object iImages: TImage
        Left = 66
        Top = 141
        Width = 16
        Height = 16
        Transparent = True
      end
      object cbFileVideo: TCheckBox
        Left = 88
        Top = 94
        Width = 97
        Height = 17
        Caption = 'Fichiers Vid'#233'o'
        TabOrder = 0
        OnClick = cbFileFolderClick
      end
      object cbFileAudio: TCheckBox
        Left = 88
        Top = 117
        Width = 97
        Height = 17
        Caption = 'Fichiers Audio'
        TabOrder = 1
        OnClick = cbFileFolderClick
      end
      object cbFileImage: TCheckBox
        Left = 88
        Top = 140
        Width = 97
        Height = 17
        Caption = 'Fichiers Image'
        TabOrder = 2
        OnClick = cbFileFolderClick
      end
      object rbEveryFiles: TRadioButton
        Left = 40
        Top = 23
        Width = 145
        Height = 17
        Caption = 'Tous les fichiers et dossiers'
        Checked = True
        TabOrder = 3
        TabStop = True
        OnClick = cbFileFolderClick
      end
      object rbFileFolders: TRadioButton
        Left = 40
        Top = 46
        Width = 113
        Height = 17
        Caption = 'Dossiers'
        TabOrder = 4
        OnClick = cbFileFolderClick
      end
      object rbCustom: TRadioButton
        Left = 40
        Top = 71
        Width = 113
        Height = 17
        Caption = 'Personalis'#233':'
        TabOrder = 5
        OnClick = cbFileFolderClick
      end
    end
  end
  object SysIco_Small: TImageList
    ShareImages = True
    Left = 488
    Top = 168
  end
  object SysIco_Big: TImageList
    Height = 32
    ShareImages = True
    Width = 32
    Left = 424
    Top = 168
  end
end
