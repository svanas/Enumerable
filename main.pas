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
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FClosing: Boolean;
    FRunning: Boolean;
    function GetChain: TChain;
    procedure Refresh;
    procedure SetRunning(Value: Boolean);
    class procedure Synchronize(P: TThreadProcedure);
    property Running: Boolean read FRunning write SetRunning;
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
  IPFS_DOT_IO     = 'https://ipfs.io/ipfs/';
  CLOUDFLARE_IPFS = 'https://cloudflare-ipfs.com/ipfs/';

function TfrmMain.GetChain: TChain;
begin
  Result := Ethereum;
end;

procedure TfrmMain.SetRunning(Value: Boolean);
begin
  if Value <> FRunning then
  begin
    FRunning := Value;
    if not(FRunning) and FClosing then
      Self.Synchronize(procedure
      begin
        Self.Close;
      end);
  end;
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
  Running := True;
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
    // enumerate over all the NFTs in this contract
    erc721.Enumerate(
      // foreach
      procedure(tokenId: BigInteger; next: TProc)
      begin
        erc721.TokenURI(tokenId, procedure(const uri: string; err: IError)
        begin
          if Assigned(err) then
          begin
            common.ShowError(err, Self.Chain);
            next;
            EXIT;
          end;
          // get this NFT's metadata schema
          web3.http.get(uri.Replace('ipfs://', IPFS_DOT_IO).Replace(CLOUDFLARE_IPFS, IPFS_DOT_IO), [], procedure(schema: TJsonObject; err: IError)
          begin
            if Assigned(err) then
            begin
              common.ShowError(err, Self.Chain);
              next;
              EXIT;
            end;
            var LI: TListItem;
            Self.Synchronize(procedure
            begin
              LI := LV.Items.Add;
              LI.Caption := web3.json.getPropAsStr(schema, 'name');
            end);
            // get the image associated with this NFT
            web3.http.get(web3.json.getPropAsStr(schema, 'image').Replace('ipfs://', IPFS_DOT_IO).Replace(CLOUDFLARE_IPFS, IPFS_DOT_IO), [], procedure(image: IHttpResponse; err: IError)
            begin
              if Assigned(err) then
              begin
                common.ShowError(err, Self.Chain);
                next;
                EXIT;
              end;
              var pic := TPicture.Create;
              try
                try
                  pic.LoadFromStream(image.ContentStream);
                  Self.Synchronize(procedure
                  begin
                    IL.Width  := Max(IL.Width,  pic.Width);
                    IL.Height := Max(IL.Height, pic.Height);
                  end);
                  // add the picture to the ImageList
                  var bmp := TBitmap.Create;
                  try
                    bmp.Assign(pic.Graphic);
                    Self.Synchronize(procedure
                    begin
                      LI.ImageIndex := IL.Add(bmp, nil);
                    end)
                  finally
                    bmp.Free;
                  end;
                  next;
                except
                  on E: Exception do
                  begin
                    common.ShowError(E.message);
                    next;
                  end;
                end;
              finally
                pic.Free;
              end;
            end);
          end);
        end);
      end,
      // error
      procedure(err: IError)
      begin
        common.ShowError(err, Self.Chain);
      end,
      // done
      procedure
      begin
        Running := False;
      end
    );
  end);
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  Self.Refresh;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FClosing := True;
  CanClose := not Running;
end;

end.
