unit uSQLite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, db, sqldb, SQLite3Conn;

const
DATABASE : string = 'dbcontact.db';

type
  TDataContact = record
  id,nama,alamat,nohp : Array of String;
end;

var
  QContact 	: TSQLQuery;
  QInsert 	: TSQLQuery;
  QUpdate 	: TSQLQuery;
  QDelete 	: TSQLQuery;
  Contact   	: TDataContact;
  Transaction   : TSQLTransaction;
  Conn          : TSQLite3Connection;

procedure CreateDBConn;
function getKoneksi:TSQLite3Connection;
function DataContact:TDataContact;
function DeleteData(id:string):Boolean;
function InsertData(Data:TDataContact):Boolean;
function UpdateData(Data:TDataContact):Boolean;
procedure CloseDBCon;

implementation

procedure CreateDBConn;
begin
  Conn := TSQLite3Connection.Create(nil);
  Transaction := TSQLTransaction.Create(nil);
  QUpdate := TSQLQuery.Create(nil);
  QInsert := TSQLQuery.Create(nil);
  QDelete := TSQLQuery.Create(nil);
end;

function getKoneksi: TSQLite3Connection;
begin
  Result:=nil;
  try
    Conn.DatabaseName := ExtractFilePath(Application.ExeName)+'/'+DATABASE;
    Conn.Transaction  := Transaction;
    Conn.Connected    := True;
    Conn.Open;
  except
    Result:=nil;
  end;
  Result:=Conn;
end;

function DataContact:TDataContact;
var
  i:integer;
begin
  try
   QContact := TSQLQuery.Create(nil);
   QContact.PacketRecords:=-1; // get all record
    with QContact do
    begin
    Close;
    SQL.Clear;
    DataBase := getKoneksi;
    SQL.Text := 'select * from tcontact order by id asc';
    Open;
    First;
    SetLength(Contact.id, QContact.RecordCount);
    SetLength(Contact.nama, QContact.RecordCount);
    SetLength(Contact.alamat, QContact.RecordCount);
    SetLength(Contact.nohp, QContact.RecordCount);
    for i := 0 to QContact.RecordCount-1 do begin
       Contact.id[i] 	:= FieldByName('id').AsString;
       Contact.nama[i]	:= FieldByName('nama').AsString;
       Contact.nohp[i] 	:= FieldByName('nomorhp').AsString;
       Contact.alamat[i]:= FieldByName('alamat').AsString;
   Next;
   end;
    end;
  except
  end;
Result:=Contact;
end;

function DeleteData(id: string): Boolean;
begin
Result:=False;
try
 QDelete.SQL.Clear;
 QDelete.DataBase := getKoneksi;
 QDelete.SQL.Text := 'delete from tcontact where id='+QuotedStr(id);
 QDelete.ExecSQL;
 Transaction.Commit;
except
  Result:=False;
end;
Result:=True;
end;

function InsertData(Data: TDataContact): Boolean;
begin
Result:=False;
try
 QInsert.SQL.Clear;
 QInsert.DataBase := getKoneksi;
 QInsert.SQL.Text := 'insert into tcontact (nama,nomorhp,alamat) values ('+QuotedStr(Data.nama[0])+','+QuotedStr(Data.nohp[0])+','+QuotedStr(Data.alamat[0])+')';
 QInsert.ExecSQL;
 Transaction.Commit;
except
  Result:=False;
end;
Result:=True;
end;

function UpdateData(Data: TDataContact): Boolean;
begin
Result:=False;
try
 QUpdate.SQL.Clear;
 QUpdate.DataBase := getKoneksi;
 QUpdate.SQL.Text := 'update tcontact set nama='+QuotedStr(Data.nama[0])+',nomorhp='+QuotedStr(Data.nohp[0])+',alamat='+QuotedStr(Data.alamat[0])+' where id='+QuotedStr(Data.id[0]);
 QUpdate.ExecSQL;
 Transaction.Commit;
except
  Result:=False;
end;
Result:=True;
end;

procedure CloseDBCon;
begin
QInsert.Free;
QUpdate.Free;
QDelete.Free;
QContact.Free;
Transaction.Free;
Conn.Free;
end;

end.

