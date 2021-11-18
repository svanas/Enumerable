unit common;

interface

uses
  // web3
  web3;

type
  TGateway = (Infura, Alchemy);

function GetClient(chain: TChain; gateway: TGateway): TWeb3;

procedure ShowError(const msg: string); overload;
procedure ShowError(const err: IError; chain: TChain); overload;

procedure OpenURL(const URL: string);
procedure OpenTransaction(chain: TChain; tx: TTxHash);

implementation

uses
  // Delphi
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  VCL.Dialogs,
  WinAPI.ShellAPI,
  WinAPI.Windows,
  // web3
  web3.eth.alchemy,
  web3.eth.infura,
  web3.eth.tx,
  web3.http.throttler,
  web3.json.rpc.https;

function GetApiKey(gateway: TGateway): string;
const
  API_KEY_NAME: array[TGateway] of string = (
    'MY_INFURA_API_KEY', // Infura
    'MY_ALCHEMY_API_KEY' // Alchemy
  );

  function API_KEY_FILE: string;
  begin
    Result := TPath.GetHomePath + TPath.DirectorySeparatorChar + API_KEY_NAME[gateway] + '.TXT';
  end;

var
  SEI: TShellExecuteInfo;
begin
  Result := '';

  if TFile.Exists(API_KEY_FILE) then
    Result := Trim(TFile.ReadAllText(API_KEY_FILE))
  else
    TFile.Create(API_KEY_FILE).Free;

  if Result <> '' then
    EXIT;

  FillChar(SEI, SizeOf(SEI), 0);
  with SEI do
  begin
    cbSize := SizeOf(SEI);
    fMask := SEE_MASK_NOCLOSEPROCESS;
    lpFile := PChar(API_KEY_FILE);
    nShow := SW_SHOW;
  end;

  if not ShellExecuteEx(@SEI) then
    EXIT;

  try
    WaitForSingleObject(SEI.hProcess, INFINITE);
  finally
    CloseHandle(SEI.hProcess);
  end;

  Result := GetApiKey(gateway);
end;

function GetClient(chain: TChain; gateway: TGateway): TWeb3;

  function endpoint: string;
  begin
    case gateway of
      Infura:
        Result := web3.eth.infura.endpoint(chain, HTTPS, GetApiKey(Infura));
      Alchemy:
        Result := web3.eth.alchemy.endpoint(chain, HTTPS, GetApiKey(Alchemy));
    end;
  end;

  function CreateProtocol(rps: TReqPerSec): IJsonRpc;
  begin
    if rps > 0 then
      Result := TJsonRpcHttps.Create(TThrottler.Create(rps))
    else
      Result := TJsonRpcHttps.Create;
  end;

const
  REQUESTS_PER_SECOND: array[TGateway] of TReqPerSec = (
    10, // Infura
    0   // Alchemy
  );
begin
  Result := TWeb3.Create(
    chain,
    endpoint,
    CreateProtocol(REQUESTS_PER_SECOND[gateway])
  );
end;

procedure ShowError(const msg: string);
begin
  TThread.Synchronize(nil, procedure
  begin
{$WARN SYMBOL_DEPRECATED OFF}
    MessageDlg(msg, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
{$WARN SYMBOL_DEPRECATED DEFAULT}
  end);
end;

procedure ShowError(const err: IError; chain: TChain);
var
  txError: ITxError;
begin
  if Supports(err, ISignatureDenied) then
    EXIT;
  TThread.Synchronize(nil, procedure
  begin
{$WARN SYMBOL_DEPRECATED OFF}
    if Supports(err, ITxError, txError) then
    begin
      if MessageDlg(
        Format(
          '%s. Would you like to view this transaction on etherscan?',
          [err.Message]
        ),
        TMsgDlgType.mtError, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0
      ) = mrYes then
        OpenTransaction(chain, txError.Hash);
      EXIT;
    end;
    MessageDlg(err.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
{$WARN SYMBOL_DEPRECATED DEFAULT}
  end);
end;

procedure OpenURL(const URL: string);
begin
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
end;

procedure OpenTransaction(chain: TChain; tx: TTxHash);
begin
  OpenURL(chain.BlockExplorerURL + '/tx/' + string(tx));
end;

end.
