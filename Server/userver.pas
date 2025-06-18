unit userver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  http_service; // HTTP Request

type
  { TFServer }

  TFServer = class(TForm)
    BStart: TButton;
    EPort: TLabeledEdit;
    MemoInfo: TMemo;
    Panel1: TPanel;
    procedure BStartClick(Sender: TObject);
    procedure MemoInfoKeyPress(Sender: TObject; var Key: char);

  private
   Server : THTTP_Service;

  end;

var
  FServer: TFServer;


implementation

{$R *.lfm}

{ TFServer }

procedure TFServer.BStartClick(Sender: TObject);
begin
  if BStart.Caption='Start HTTP' then
    begin
      Server := THTTP_Service.Create(StrToInt(EPort.Text));
      Server.Start;
      MemoInfo.Lines.Add('Server is READY at http://localhost:'+EPort.Text);
      BStart.Caption:='Stop HTTP';
    end else
    if BStart.Caption='Stop HTTP' then
    begin
      BStart.Caption:='Start HTTP';
      Server.StopHTTP;
      Server.Terminate;
      Server.Free;
      MemoInfo.Lines.Add('Server STOP!');
    end;
end;

procedure TFServer.MemoInfoKeyPress(Sender: TObject; var Key: char);
begin
  key:=#0;
end;



end.

