object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Enumerable'
  ClientHeight = 714
  ClientWidth = 892
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  DesignSize = (
    892
    714)
  TextHeight = 15
  object edtAddress: TEdit
    Left = 8
    Top = 8
    Width = 795
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = '0xb49BD54A3A9367cf5412Ec6fF50A02e2b92eCB2F'
  end
  object btnRefresh: TButton
    Left = 809
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
    Width = 876
    Height = 669
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
