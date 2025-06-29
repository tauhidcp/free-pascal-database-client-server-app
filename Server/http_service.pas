unit http_service;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
{$IFDEF UNIX}cthreads, cmem,{$ENDIF}
 fphttpapp, httpdefs, httproute, fpjson, fphttp, jsonparser,
 uSQLite;

Type

    { THTTP_Service }

    THTTP_Service = class(TThread)
    private
    protected
      procedure Execute; override;
    public
      property Terminated;
      Constructor Create(Sport:Integer);
      procedure StopHTTP;

    end;

  var
  httpapp : THTTPApplication;

implementation

uses userver;

{ THTTP_Service }

procedure ContactList(aRequest : TRequest; aResponse : TResponse);
var
  JsonArray: TJSONArray;
  jObject : TJSONObject;
  i : integer;
begin
  try
    JsonArray := TJSONArray.Create;
    for i := 0 to Length(DataContact.id)-1 do
    begin
      jObject := TJSONObject.Create;
      jObject.Strings['id'] := DataContact.id[i];
      jObject.Strings['nama'] := DataContact.nama[i];
      jObject.Strings['nohp'] := DataContact.nohp[i];
      jObject.Strings['alamat'] := DataContact.alamat[i];
      JsonArray.Add(jObject);
    end;
    aResponse.Content := JsonArray.AsJSON;
    aResponse.ContentType := 'application/json';
    aResponse.SendContent;
    FServer.MemoInfo.Lines.Add('[Client] Get Contact...');
  finally
    jObject.Free;
    //JsonArray.Free; // error if free
  end;
end;

procedure addContact(aRequest : TRequest; aResponse : TResponse);
var
  Data: TJSONData;
  Contact : TDataContact;
begin
  if ARequest.Method = 'POST' then
  begin

    // set array length
    SetLength(Contact.id, 1);
    SetLength(Contact.nama, 1);
    SetLength(Contact.nohp, 1);
    SetLength(Contact.alamat, 1);

    try
      Data := GetJSON(ARequest.Content);
      Contact.nama[0] := Data.FindPath('nama').AsString;
      Contact.nohp[0] := Data.FindPath('nohp').AsString;
      Contact.alamat[0] := Data.FindPath('alamat').AsString;

      if (InsertData(Contact)=True) then
         aResponse.Content := 'SUCCESS!'
       else
        aResponse.Content := 'FAILED!';

      aResponse.ContentType := 'text/plain';
      aResponse.SendContent;
      FServer.MemoInfo.Lines.Add('[Client] Insert Contact...');
    finally
      Data.Free;
    end;
  end;
end;

procedure updateContact(aRequest : TRequest; aResponse : TResponse);
var
  Data: TJSONData;
  Contact : TDataContact;
begin
  if ARequest.Method = 'POST' then
  begin

    // set array length
    SetLength(Contact.id, 1);
    SetLength(Contact.nama, 1);
    SetLength(Contact.nohp, 1);
    SetLength(Contact.alamat, 1);

    try
      Data := GetJSON(ARequest.Content);
      Contact.id[0] := Data.FindPath('id').AsString;
      Contact.nama[0] := Data.FindPath('nama').AsString;
      Contact.nohp[0] := Data.FindPath('nohp').AsString;
      Contact.alamat[0] := Data.FindPath('alamat').AsString;

      if (UpdateData(Contact)=True) then
         aResponse.Content := 'SUCCESS!'
       else
        aResponse.Content := 'FAILED!';

      aResponse.ContentType := 'text/plain';
      aResponse.SendContent;
      FServer.MemoInfo.Lines.Add('[Client] Update Contact...');
    finally
      Data.Free;
    end;
  end;
end;

procedure deleteContact(aRequest : TRequest; aResponse : TResponse);
var
  id : string;
begin
  if ARequest.Method = 'GET' then
  begin
    id := ARequest.QueryFields.Values['id'];

    if (DeleteData(id)=True) then
       aResponse.Content := 'SUCCESS!'
     else
      aResponse.Content := 'FAILED!';

    aResponse.ContentType := 'text/plain';
    aResponse.SendContent;
    FServer.MemoInfo.Lines.Add('[Client] Delete Contact...');
  end;
end;

procedure uploadFile(aRequest : TRequest; aResponse : TResponse);
var
  UploadField: TUploadedFile;
  i: integer;
  SavePath:String;
begin
  if ARequest.Method = 'POST' then
  begin

      if aRequest.Files.Count > 0 then
      begin

        for i := 0 to aRequest.Files.Count - 1 do
        begin

          UploadField := TUploadedFile(ARequest.Files.Items[i]);
          SavePath := 'uploads' + DirectorySeparator + ExtractFileName(StringReplace(UploadField.FileName,' ','-',[rfReplaceAll, rfIgnoreCase]));
          ForceDirectories(ExtractFilePath(SavePath));

          if Assigned(UploadField.Stream) then
            begin
              UploadField.Stream.Position := 0;
              with TFileStream.Create(SavePath, fmCreate) do
              try
                CopyFrom(UploadField.Stream, UploadField.Stream.Size);
              finally
                Free;
              end;
            end;

          end;

          aResponse.Content := 'SUCCESS!';
        end else
        aResponse.Content := 'FAILED!';

      aResponse.ContentType := 'text/plain';
      aResponse.SendContent;
      FServer.MemoInfo.Lines.Add('[Client] Upload File...');
  end;
end;

procedure Home(aRequest : TRequest; aResponse : TResponse);
var
  FilePath: String;
  FileStream: TFileStream;
begin
   if ARequest.URI.StartsWith('/uploads/') then  // check if client access the uploads directory
  begin
    FilePath := 'uploads' + DirectorySeparator + ExtractFileName(ARequest.URI);
    if FileExists(FilePath) then
    begin
      FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
      try
        AResponse.ContentStream := FileStream;
        AResponse.ContentType := 'application/octet-stream';
        AResponse.SendContent;
      except
        on E: Exception do
        begin
          FileStream.Free;
          AResponse.Code := 500;
          AResponse.Content := 'Error serving file: ' + E.Message;
          aResponse.SendContent;
        end;
      end;
      FServer.MemoInfo.Lines.Add('[Client] Download File...');
    end else
    begin
      aResponse.Content := 'File Tidak ada!';
      aResponse.ContentType := 'text/plain';
      aResponse.SendContent;
    end;
  end else
  begin
    aResponse.Content := 'Welcome, this is default route HTTP Server App :)';
    aResponse.ContentType := 'text/plain';
    aResponse.SendContent;
  end;
end;

procedure THTTP_Service.Execute;
begin
  httpapp.Run;
end;

constructor THTTP_Service.Create(SPort:Integer);
begin
  CreateDBConn;
  httpapp := THTTPApplication.Create(nil);
  httpapp.Port := SPort;
  if (HTTPRouter.RouteCount=0) then // check route if not exist register
  begin
       HTTPRouter.RegisterRoute('/contactlist', @contactList);
       HTTPRouter.RegisterRoute('/addcontact', @addContact);
       HTTPRouter.RegisterRoute('/updatecontact', @updateContact);
       HTTPRouter.RegisterRoute('/deletecontact', @deleteContact);
       HTTPRouter.RegisterRoute('/uploadfile', @uploadFile);
       HTTPRouter.RegisterRoute('/home', @Home, true); // default route
  end;
  httpapp.Threaded := True;
  httpapp.Initialize;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure THTTP_Service.StopHTTP;
begin
 httpapp.Terminate;
 CloseDBCon;
end;



end.

