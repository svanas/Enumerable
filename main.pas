unit main;

interface

uses
  // Delphi
  System.Classes,
  VCL.Controls,
  VCL.Forms,
  VCL.StdCtrls,
  // web3
  web3;

type
  TfrmMain = class(TForm)
    edtAddress: TEdit;
    btnRefresh: TButton;
    procedure btnRefreshClick(Sender: TObject);
  private
    function GetChain: TChain;
  public
    property Chain: TChain read GetChain;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
  // web3
  web3.eth.erc721,
  web3.eth.types,
  // project
  common;

function TfrmMain.GetChain: TChain;
begin
  Result := Mainnet;
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
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
            // ToDo: get this NFT's metadata schema
          end);
        end);
    end);
  end);
end;

end.
