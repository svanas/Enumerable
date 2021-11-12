program NFT;

uses
  Vcl.Forms,
  main in 'main.pas' {frmMain},
  common in 'common.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
