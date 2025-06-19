unit u_insert_update;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  fpjson, jsonparser, fphttpclient;

type

  { TFInsertUpdate }

  TFInsertUpdate = class(TForm)
    BSimpan: TButton;
    ENama: TLabeledEdit;
    ENoHP: TLabeledEdit;
    EAlamat: TLabeledEdit;
    procedure BSimpanClick(Sender: TObject);
  private

  public

  end;

var
  FInsertUpdate: TFInsertUpdate;

implementation

uses uclient;

{$R *.lfm}

{ TFInsertUpdate }

procedure TFInsertUpdate.BSimpanClick(Sender: TObject);
var
  Data: TJSONData;
  http : TFPHTTPClient;
  Response : TStringStream;
begin

  if not (ENama.Text='') and not (ENoHP.Text='') and not (EAlamat.Text='') then
    begin

  if (BSimpan.Caption='Save Contact') then
     begin
          try
            http := TFPHTTPClient.Create(nil);
            Response := TStringStream.Create('');
            Data := GetJSON('{"nama" : "'+ENama.Text+'", "nohp" : "'+ENoHP.Text+'", "alamat" : "'+EAlamat.Text+'"}');
            http.FormPost('http://'+FClient.EIPAddress.Text+':'+FClient.EPort.Text+'/addcontact', Data.AsJSON, Response);

            if (Trim(Response.DataString)='SUCCESS!') then
               begin
                  MessageDlg('Save Contact Success!', mtInformation, [mbOK],0);
                  FClient.BGetData.Click;
               end;
          finally
            Response.Free;
            http.Free;
          end;
     end;

  if (BSimpan.Caption='Update Contact') then
     begin
           try
            http := TFPHTTPClient.Create(nil);
            Response := TStringStream.Create('');
            Data := GetJSON('{"id" : "'+FClient.id+'", "nama" : "'+ENama.Text+'", "nohp" : "'+ENoHP.Text+'", "alamat" : "'+EAlamat.Text+'"}');
            http.FormPost('http://'+FClient.EIPAddress.Text+':'+FClient.EPort.Text+'/updatecontact', Data.AsJSON, Response);

            if (Trim(Response.DataString)='SUCCESS!') then
               begin
                  MessageDlg('Update Contact Success!', mtInformation, [mbOK],0);
                  FClient.BGetData.Click;
               end;
          finally
            Response.Free;
            http.Free;
          end;
     end;

    end;
end;

end.

