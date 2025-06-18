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
    GroupBox1: TGroupBox;
    EIPAddress: TLabeledEdit;
    EPort: TLabeledEdit;
    Panel1: TPanel;
    GridContact: TStringGrid;
    procedure BGetDataClick(Sender: TObject);
    procedure BDeleteDataClick(Sender: TObject);
    procedure BInsertDataClick(Sender: TObject);
    procedure BUpdateDataClick(Sender: TObject);
    procedure GridContactSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
  private

  public
  id, nama, nohp, alamat : String;

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
              if (hapus='SUCCESS!') then
                  BGetDataClick(Sender);
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

procedure TFClient.GridContactSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
id   := GridContact.Cells[1,aRow];
nama := GridContact.Cells[2,aRow];
nohp := GridContact.Cells[3,aRow];
alamat := GridContact.Cells[4,aRow];
end;

end.

