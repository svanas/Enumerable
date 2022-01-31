object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'NFT'
  ClientHeight = 729
  ClientWidth = 1008
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  DesignSize = (
    1008
    729)
  TextHeight = 15
  object edtAddress: TEdit
    Left = 8
    Top = 8
    Width = 911
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = '0x1820a996cd0cee1d3316d1e0e6ebc7b22796af86'
  end
  object btnRefresh: TButton
    Left = 925
    Top = 8
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Refresh'
    TabOrder = 1
    OnClick = btnRefreshClick
  end
  object LV: TListView
    Left = 8
    Top = 37
    Width = 992
    Height = 684
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
      end>
    LargeImages = IL
    SmallImages = IL
    TabOrder = 2
  end
  object IL: TImageList
    Left = 490
    Top = 350
  end
end
