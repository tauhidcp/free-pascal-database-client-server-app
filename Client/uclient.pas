unit uclient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, fpjson, jsonparser, fphttpclient, u_insert_update;

type

  { TFClient }

  TFClient = class(TForm)
    BGetData: TButton;
    BInsertData: TButton;
    BUpdateData: TButton;
    BDeleteData: TButton;
    BBrowse: TButton;
    BUpload: TButton;
    BDownload: TButton;
    EFile: TEdit;
    GroupBox1: TGroupBox;
    EIPAddress: TLabeledEdit;
    EPort: TLabeledEdit;
    OpenFile: TOpenDialog;
    Panel1: TPanel;
    GridContact: TStringGrid;
    procedure BBrowseClick(Sender: TObject);
    procedure BDownloadClick(Sender: TObject);
    procedure BGetDataClick(Sender: TObject);
    procedure BDeleteDataClick(Sender: TObject);
    procedure BInsertDataClick(Sender: TObject);
    procedure BUpdateDataClick(Sender: TObject);
    procedure BUploadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GridContactSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure UploadFile(AFileName:String);
    procedure DownloadFile(URLFile:String;NamaHasil:String);
  private

  public
  id, nama, nohp, alamat : String;
  Upload : Boolean;

  end;

var
  FClient: TFClient;

implementation

{$R *.lfm}

{ TFClient }

procedure TFClient.BGetDataClick(Sender: TObject);
var
  Contact : AnsiString;
  j : integer;
  ParsedArray: TJSONArray;
  Item: TJSONObject;
begin

  try
      Contact := TFPHTTPClient.SimpleGet('http://'+EIPAddress.Text+':'+EPort.Text+'/contactlist');
      ParsedArray := TJSONArray(GetJSON(Contact));
      GridContact.ColWidths[0]:=10;
      GridContact.RowCount := ParsedArray.Count+1;

      for j := 0 to ParsedArray.Count - 1 do
      begin
        Item := ParsedArray.Objects[j];
        GridContact.Cells[1,j+1] := Item.Get('id','');
        GridContact.Cells[2,j+1] := Item.Get('nama','');
        GridContact.Cells[3,j+1] := Item.Get('nohp','');
        GridContact.Cells[4,j+1] := Item.Get('alamat','');
      end;

  finally
    ParsedArray.Free;
  end;
end;

procedure TFClient.BBrowseClick(Sender: TObject);
begin
  if (OpenFile.Execute) then
      begin
       if not (OpenFile.FileName='') then
           EFile.Text:=OpenFile.FileName;
      end;
end;

procedure TFClient.BDownloadClick(Sender: TObject);
var
  namahasil,urlfile:String;
begin
  if (Upload=True) then
      begin
       namahasil   := ExtractFilePath(Application.ExeName)+'/'+StringReplace(ExtractFileName(OpenFile.FileName),' ','-',[rfReplaceAll, rfIgnoreCase]);
       urlfile     := 'http://'+EIPAddress.Text+':'+EPort.Text+'/uploads/'+StringReplace(ExtractFileName(OpenFile.FileName),' ','-',[rfReplaceAll, rfIgnoreCase]);
       DownloadFile(urlfile,namahasil);
       MessageDlg('Download File Success!', mtInformation, [mbOK],0);
      end else
      MessageDlg('Upload File First Before Download!', mtWarning, [mbOK],0);
end;

procedure TFClient.BDeleteDataClick(Sender: TObject);
var
  hapus : AnsiString;
begin
   if not (id='') and not (nama='') then
    begin
      if MessageDlg('Hapus Data', 'Hapus data "'+nama+'" ini?', mtConfirmation, [mbYes, mbNo],0) = mrYes then
         begin
          try
            hapus := TFPHTTPClient.SimpleGet('http://'+EIPAddress.Text+':'+EPort.Text+'/deletecontact?id='+id);
            if (Trim(hapus)='SUCCESS!') then
               begin
                  MessageDlg('Hapus Contact Success!', mtInformation, [mbOK],0);
                  BGetData.Click;
               end;
          finally
          end;
         end;
    end else
    MessageDlg('Select Data First Before Delete!', mtWarning, [mbOK],0);
end;

procedure TFClient.BInsertDataClick(Sender: TObject);
begin
with FInsertUpdate do
begin
 ENama.Text:='';
 ENoHP.Text:='';
 EAlamat.Text:='';
 Caption:='Insert Contact';
 BSimpan.Caption:='Save Contact';
 ShowModal;
end;
end;

procedure TFClient.BUpdateDataClick(Sender: TObject);
begin
if not (id='') and not (nama='') then
    begin
      with FInsertUpdate do
      begin
           ENama.Text:=nama;
           ENoHP.Text:=nohp;
           EAlamat.Text:=alamat;
           BSimpan.Caption:='Update Contact';
           Caption:='Update Contact';
           ShowModal;
      end;
    end else
      MessageDlg('Select Data First Before Update!', mtWarning, [mbOK],0);
end;

procedure TFClient.BUploadClick(Sender: TObject);
begin
  if not (EFile.Text='') then
      begin
           if FileExists(EFile.Text) then
               UploadFile(EFile.Text);
      end else
      MessageDlg('Select File First Before Upload!', mtWarning, [mbOK],0);
end;

procedure TFClient.FormCreate(Sender: TObject);
begin
  Upload:=False;
end;

procedure TFClient.GridContactSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
id   := GridContact.Cells[1,aRow];
nama := GridContact.Cells[2,aRow];
nohp := GridContact.Cells[3,aRow];
alamat := GridContact.Cells[4,aRow];
end;

procedure TFClient.UploadFile(AFileName: String);
var
  Client: TFPHTTPClient;
  Boundary, CRLF: string;
  Request: TMemoryStream;
  FileStream: TFileStream;
  FileName: string;
  Header: string;
  EndBoundary: string;
  Respon : TStringStream;
begin

    try

      Randomize;
      Boundary := '----Boundary' + IntToStr(Random(1000000));
      CRLF := #13#10;
      FileName := ExtractFileName(AFileName);
      Respon := TStringStream.Create('');
      Request := TMemoryStream.Create;
      FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
      Client := TFPHTTPClient.Create(nil);

      Header := '--' + Boundary + CRLF +
                'Content-Disposition: form-data; name="document"; filename="' + FileName + '"' + CRLF +
                'Content-Type: application/octet-stream' + CRLF + CRLF;

      Request.Write(Pointer(Header)^, Length(Header));

      // File content
      Request.CopyFrom(FileStream, FileStream.Size);
      Request.Write(Pointer(CRLF)^, Length(CRLF));

      // Final boundary
      EndBoundary := '--' + Boundary + '--' + CRLF;
      Request.Write(Pointer(EndBoundary)^, Length(EndBoundary));

      // Send request
      Client.AddHeader('Content-Type', 'multipart/form-data; boundary=' + Boundary);
      Request.Position := 0;
      Client.RequestBody := Request;
      Client.Post('http://'+EIPAddress.Text+':'+EPort.Text+'/uploadfile',Respon);

      if (Trim(Respon.DataString)='SUCCESS!') then
         begin
            MessageDlg('Upload File Success!', mtInformation, [mbOK],0);
            BGetData.Click;
            Upload:=True;
         end;

    finally
      Client.Free;
      FileStream.Free;
      Request.Free;
      Respon.Free;
   end;
end;

procedure TFClient.DownloadFile(URLFile:String;NamaHasil:String);
var
  HttpClient: TFPHttpClient;
  Stream: TFileStream;
  URL, OutputFile: string;
begin
  URL := URLFile;
  OutputFile := NamaHasil;
  try
    HttpClient := TFPHttpClient.Create(nil);
    Stream := TFileStream.Create(OutputFile, fmCreate);
    try
      HttpClient.Get(URL, Stream);
    finally
      Stream.Free;
    end;
  except
  end;
  HttpClient.Free;
end;

end.

