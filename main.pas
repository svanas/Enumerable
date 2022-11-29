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
    class function GetClient: IWeb3; static;
    procedure Refresh;
    procedure SetRunning(Value: Boolean);
    class procedure ShowError(const msg: string); overload;
    class procedure ShowError(const err: IError); overload;
    class procedure Synchronize(P: TThreadProcedure);
    property Running: Boolean read FRunning write SetRunning;
  public
    class property Client: IWeb3 read GetClient;
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
  VCL.Dialogs,
  VCL.Graphics,
  VCL.Imaging.JPEG,
  VCL.Imaging.PngImage,
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
  // web3
  web3.eth.erc721,
  web3.eth.types,
  web3.http,
  web3.json;

const
  IPFS_BASE = 'https://ipfs.io/ipfs/';

class function TfrmMain.GetClient: IWeb3;
begin
  Result := TWeb3.Create(BNB);
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

class procedure TfrmMain.ShowError(const msg: string);
begin
  Self.Synchronize(procedure
  begin
{$WARN SYMBOL_DEPRECATED OFF}
    MessageDlg(msg, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
{$WARN SYMBOL_DEPRECATED DEFAULT}
  end);
end;

class procedure TfrmMain.ShowError(const err: IError);
begin
  Self.ShowError(err.Message);
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
  const client = Self.Client;
  // resolve the token contract address
  TAddress.Create(client, edtAddress.Text, procedure(token: TAddress; err: IError)
  begin
    if Assigned(err) then
    begin
      Self.ShowError(err);
      EXIT;
    end;
    const erc721 = TERC721.Create(client, token);
    // enumerate over all the NFTs in this contract
    erc721.Enumerate(
      // foreach
      procedure(tokenId: BigInteger; next: TProc<Boolean>)
      begin
        erc721.TokenURI(tokenId, procedure(uri: string; err: IError)
        begin
          if Assigned(err) then
          begin
            Self.ShowError(err);
            next(not FClosing);
            EXIT;
          end;
          // get this NFT's metadata schema
          web3.http.get(uri.Replace('ipfs://', IPFS_BASE), [], procedure(schema: TJsonValue; err: IError)
          begin
            if Assigned(err) then
            begin
              Self.ShowError(err);
              next(not FClosing);
              EXIT;
            end;
            var LI: TListItem;
            Self.Synchronize(procedure
            begin
              LI := LV.Items.Add;
              LI.ImageIndex := -1;
              LI.Caption := web3.json.getPropAsStr(schema, 'name');
            end);
            // get the image associated with this NFT
            web3.http.get(web3.json.getPropAsStr(schema, 'image').Replace('ipfs://', IPFS_BASE), [], procedure(image: IHttpResponse; err: IError)
            begin
              if Assigned(err) then
              begin
                Self.ShowError(err);
                next(not FClosing);
                EXIT;
              end;
              const pic = TPicture.Create;
              try
                try
                  pic.LoadFromStream(image.ContentStream);
                  Self.Synchronize(procedure
                  begin
                    IL.Width  := Min(128, Max(IL.Width,  pic.Width));
                    IL.Height := Min(128, Max(IL.Height, pic.Height));
                    // add the picture to the ImageList
                    const bmp = TBitmap.Create;
                    try
                      bmp.SetSize(IL.Width, IL.Height);
                      bmp.Canvas.StretchDraw(Rect(0, 0, bmp.Width, bmp.Height), pic.Graphic);
                      LI.ImageIndex := IL.Add(bmp, nil);
                    finally
                      bmp.Free;
                    end;
                  end);
                  next(not FClosing);
                except
                  on E: Exception do
                  begin
                    Self.ShowError(E.message);
                    next(not FClosing);
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
        Self.ShowError(err);
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
