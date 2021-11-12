object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'NFT'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  PixelsPerInch = 96
  TextHeight = 15
  object edtAddress: TEdit
    Left = 8
    Top = 8
    Width = 273
    Height = 23
    TabOrder = 0
    Text = '0x1820a996cd0cee1d3316d1e0e6ebc7b22796af86'
  end
  object btnRefresh: TButton
    Left = 287
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Refresh'
    TabOrder = 1
    OnClick = btnRefreshClick
  end
end
