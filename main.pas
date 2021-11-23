unit main;

interface

uses
  // Delphi
  System.Classes,
  System.ImageList,
  VCL.ComCtrls,
  VCL.Controls,
  VCL.Forms,
  VCL.ImgList,
  VCL.StdCtrls,
  // web3
  web3;

type
  TfrmMain = class(TForm)
    edtAddress: TEdit;
    btnRefresh: TButton;
    IL: TImageList;
    LV: TListView;
    procedure btnRefreshClick(Sender: TObject);
  private
    function GetChain: TChain;
    procedure Refresh;
    class procedure Synchronize(P: TThreadProcedure);
  public
    property Chain: TChain read GetChain;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  // Delphi
  System.JSON,
  System.Math,
  System.Net.HttpClient,
  System.SysUtils,
  VCL.Graphics,
  VCL.Imaging.JPEG,
  VCL.Imaging.PngImage,
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
  // web3
  web3.eth.erc721,
  web3.eth.types,
  web3.http,
  web3.json,
  // project
  common;

const
  IPFS_GATEWAY = 'https://ipfs.io/ipfs/';

function TfrmMain.GetChain: TChain;
begin
  Result := Mainnet;
end;

class procedure TfrmMain.Synchronize(P: TThreadProcedure);
begin
  if TThread.CurrentThread.ThreadID = MainThreadId then
    P
  else
    TThread.Synchronize(nil, procedure
    begin
      P
    end);
end;

procedure TfrmMain.Refresh;
begin
  Self.Synchronize(procedure
  begin
    LV.Clear;
    IL.Clear;
  end);
  var client := common.GetClient(Self.Chain, Alchemy);
  // resolve the token contract address
  TAddress.New(client, edtAddress.Text, procedure(token: TAddress; err: IError)
  begin
    if Assigned(err) then
    begin
      common.ShowError(err, Self.Chain);
      EXIT;
    end;
    var erc721 := TERC721.Create(client, token);
    // get number of NFTs tracked by this contract
    erc721.TotalSupply(procedure(totalSupply: BigInteger; err: IError)
    begin
      if Assigned(err) then
      begin
        common.ShowError(err, Self.Chain);
        EXIT;
      end;
      // enumerate over all the NFTs in this contract
      for var I := 0 to Pred(totalSupply.AsInteger) do
        erc721.TokenByIndex(I, procedure(tokenId: BigInteger; err: IError)
        begin
          if Assigned(err) then
          begin
            common.ShowError(err, Self.Chain);
            EXIT;
          end;
          erc721.TokenURI(tokenId, procedure(const uri: string; err: IError)
          begin
            if Assigned(err) then
            begin
              common.ShowError(err, Self.Chain);
              EXIT;
            end;
            // get this NFT's metadata schema
            web3.http.get(uri.Replace('ipfs://', IPFS_GATEWAY), procedure(schema: TJsonObject; err: IError)
            begin
              if Assigned(err) then
              begin
                common.ShowError(err, Self.Chain);
                EXIT;
              end;
              Self.Synchronize(procedure
              begin
                var LI := LV.Items.Add;
                LI.Caption := web3.json.getPropAsStr(schema, 'name');
                // get the image associated with this NFT
                web3.http.get(web3.json.getPropAsStr(schema, 'image').Replace('ipfs://', IPFS_GATEWAY), procedure(image: IHttpResponse; err: IError)
                begin
                  if Assigned(err) then
                  begin
                    common.ShowError(err, Self.Chain);
                    EXIT;
                  end;
                  Self.Synchronize(procedure
                  begin
                    var pic := TPicture.Create;
                    try
                      try
                        pic.LoadFromStream(image.ContentStream);
                        // add the picture to the ImageList
                        IL.Width  := Max(IL.Width,  pic.Width);
                        IL.Height := Max(IL.Height, pic.Height);
                        var bmp := TBitmap.Create;
                        try
                          bmp.Assign(pic.Graphic);
                          LI.ImageIndex := IL.Add(bmp, nil);
                        finally
                          bmp.Free;
                        end;
                      except
                        on E: Exception do common.ShowError(e.Message);
                      end;
                    finally
                      pic.Free;
                    end;
                  end)
                end);
              end);
            end);
          end);
        end);
    end);
  end);
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  Self.Refresh;
end;

end.
