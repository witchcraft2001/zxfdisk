unit Unit1;
 
interface
 
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;
 
type
  TBootSectorRec = packed record //��������� ������������ ������� (62 �����)
    abJmpCode       : array [1..3] of byte; //���������� Jmp �� ������ ����
    abOem           : array [1..8] of char; //�������� �����-������������� ������������ ������� � ������
    wSectSize       : word; //������ � �������, ��� ������� 512
    bClustSects     : byte; //�������� � ��������
    wResSects       : word; //����� ����������������� �������� �� �����, ������� ����������� ������
    bFatCnt         : byte; //����� ������ FAT (������ 2, �������� � �����������)
    wRootEntries    : word; //������������ ����� 32-�������� ������� DirEntryRec � �������� ��������
    wTotSects       : word; //����� ����� �������� �� ��������. �������� 0000h ��������, ��� ������ ������� ����, ��� 32��. ����� �������� ���� ��������� � lBigTotSects.
    bMedia          : byte; //Media Descriptor. F8h - ������ ����, ��������� ������� (F0, F9, FA, FB, FC, FD, FE, FF) �������� ������ ������� ����� (���������� ������ � �������� �� �������).
    wFatSects       : word; //����� �������� �� ���� ������� ���������� ������ (FAT)
    wSectsPerTrk    : word; //����� �������� �� ���� ���� (�������)
    wHeads          : word; //����� ������������/����������� �������
    lHidSects       : Longword; //������� �������
    lBigTotSects    : Longword; //32-bit ����� �������� �� ������� �������, ��� 32��
    bDrvNo          : byte; //80h - ������ ������� ���� (������������ ������ MS-DOS)
    res1            : byte; //���������������
    bExtBootSig     : byte; //�������������� �������, ������ ����� 29h
    lSerNo          : Longword; //Volume Serial Number
    abVolLabel      : array [1..11] of char; //����� ����, 11 ��������, ���������� ���������, ���� ����������
    abFileSysID     : array [1..8] of char; //�������� �������� ������� (FAT12 ��� FAT16)
  end;
 
  TDirEntryRec = packed record //��������� ����� ��� ��������
    case integer of
    0:(
      abName         : array [1..8] of char;  //��� �����, ����������� �����, ������� �������� ��������� (20h). ����� ������ ������ ����� ����� ������ ��������: 0 - ������ ��� �� ��������������, 5 - ������ ������ 0E5h, 2Eh - ��� ������ �� ������� (.=���, ..=��������), E5h - ������ �������
      abExt          : array [1..3] of char;  //����������, ����������� �����, ������� �������� ���������
      bAttr          : byte;  //�������� (����: 0 - Read-only, 1 - Hidden (���������), 2    - System (���������), 3 - Volume label entry, 4 - subDirectory entry (����������), 5 - Archive (1=file has not been backed up) ��������������� ��� ��������� �����, 6,7 - ���������������)
      NTReserved     : byte;  //��������������� ��� Windows NT
      CreateTimeTenth: byte;  //������� ���� ������� ��������
      CreateTime     : word;  //����� ��������
      CreateDate     : word;  //���� ��������
      LastAccessDate : word;  //���� ���������� �������
      FirstClusterHi : word;  //������� ����� ������ ��������
      WriteTime      : word;     //����� ��������� (����: 0..3 - C������/2 (0-29), 4..10 - ������ (0-59), 11..15 - ���� (0-23))
      WriteDate      : word;     //���� ��������� (����: 0..6   - ��� �� 1980 (0-127), 7..10 - ����� (1-12), 11..15 - ���� (1-31))
      wClstrNo       : word;     //����� �������� ������ ����� � FAT
      lSize          : longint;  //������ ����� �� 4��
    );
    1:(
      lfn_Sequence   : byte;    // ����� �����������
      lfn_Name1      : array [1..5] of WCHAR; // ������ ����� �����
      lfn_Attributes : byte;    // ��������
      lfn_LongEntryType : byte; // ������� ������������ �������� (������ 0)
      lfn_Checksum   : byte;    // ����������� ����� �����
      lfn_Name2      : array [1..6] of WCHAR; // ������ ����� �����
      lfn_Reserved   : word;    // ���������������
      lfn_Name3      : array [1..2] of WCHAR; // ������ ����� �����
    );
  end;
  TDirEntryRecArray = array of TDirEntryRec;
 
type
  TForm1 = class(TForm)
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    ListView1: TListView;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure LoadDirFromStream(Stream: TStream; ClusterN: word);
    procedure GetDirEntries(Stream: TStream; var DirEntries: TDirEntryRecArray; ClusterN: word; var Entries: integer);
    procedure PrintFileList(DirEntries: TDirEntryRecArray; Entries: integer);
    function RecToStr(const Buf; Size: integer): string; //������� �������� ���
    function RecToWStr(DirEntry: TDirEntryRec): WideString; //������� ������� ���
    function NextCluster(N: word): word; //����������� �� FAT ������� ��������� �� ��������� �������
  public
    { Public declarations }
  end;
 
var
  Form1: TForm1;
  BootSec: TBootSectorRec;
  FATaddr: longword;
  FileName: String;
  FatMask: word;
  FAT: array of byte;
 
implementation
 
{$R *.dfm}
 
procedure TForm1.FormCreate(Sender: TObject);
begin
  Button1.Caption:='������� ���� .IMG';
  Button1.Width:=150;
  OpenDialog1.Filter:='Image FAT (*.img)|*.img';
  ListView1.ViewStyle:=vsReport;
  with ListView1.Columns.Add do Caption:='Name';
  with ListView1.Columns.Add do Caption:='ID';
  with ListView1.Columns.Add do Caption:='Size';
  with ListView1.Columns.Add do Caption:='Cluster';
  ListView1.Column[0].Width:=120;
  ListView1.Clear;
  FatMask:=$FFFF; //���� FAT16
end;
 
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SetLength(FAT,0);
end;
 
procedure TForm1.Button1Click(Sender: TObject);
var
  Stream: TStream;
  S: string;
begin
  if OpenDialog1.Execute then begin
    FileName:=OpenDialog1.FileName;
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      Stream.Read(BootSec, SizeOf(TBootSectorRec)); //������� ��������� ������������ �������
      SetLength(FAT,BootSec.wFatSects*BootSec.wSectSize); //�������� ������ ��� FAT �������
      FATaddr:=BootSec.wResSects*BootSec.wSectSize; //������ ������ FAT �������
      Stream.Position:=FATaddr;
      Stream.Read(Pointer(FAT)^,BootSec.wFatSects*BootSec.wSectSize);
      S:=RecToStr(BootSec.abFileSysID,Length(BootSec.abFileSysID)); //���������� �������� ������� (FAT12 ��� FAT16)
      if SameText(S,'FAT12') then FatMask:=$FFF;
      LoadDirFromStream(Stream,0);
    finally
      Stream.Free;
    end;
  end;
end;
 
function TForm1.RecToStr(const Buf; Size: integer): string; //������� �������� ���
begin
  SetString(Result,PChar(@Buf),Size);
  Result:=TrimRight(Result);
end;
 
function TForm1.RecToWStr(DirEntry: TDirEntryRec): WideString; //������� ������� ���
var i: integer;
    wC: WCHAR;
begin
  Result:='';
  For i:=1 to Length(DirEntry.lfn_Name1) do begin
    wC:=DirEntry.lfn_Name1[i];
    if wC=#0 then Exit;
    Result:=Result+wC;
  end;
  For i:=1 to Length(DirEntry.lfn_Name2) do begin
    wC:=DirEntry.lfn_Name2[i];
    if wC=#0 then Exit;
    Result:=Result+wC;
  end;
  For i:=1 to Length(DirEntry.lfn_Name3) do begin
    wC:=DirEntry.lfn_Name3[i];
    if wC=#0 then Exit;
    Result:=Result+wC;
  end;
end;
 
procedure TForm1.LoadDirFromStream(Stream: TStream; ClusterN: word);
var
  DirEntries: TDirEntryRecArray;
  Entries: integer;
begin
  GetDirEntries(Stream,DirEntries,ClusterN,Entries);
  PrintFileList(DirEntries,Entries);
  SetLength(DirEntries,0); //���������� ������ ��� ��������
end;
 
function TForm1.NextCluster(N: word): word;
var
  b: byte;
  i: integer;
begin
  b:=4; //���������� �������� � ����� ������ �������
  if FatMask=$FFF then b:=3;
  i:=(N*b) div 2;
  Result:=FAT[i]+FAT[i+1]*256;
  if FatMask=$FFF then
    if (N mod 2)<>0 then Result:=Result shr 4;
  Result:=Result and FatMask;
end;
 
procedure TForm1.GetDirEntries(Stream: TStream; var DirEntries: TDirEntryRecArray;
  ClusterN: word; var Entries: integer);
var
  i: Integer;
  DirEntriesAddr, ClustersBegin: longword;
  DirEntriesRootAddr, DirEntriesRootSize: longword;
  ClusterSize, EntriesInCluster: longword;
  Count: longword;
  PDirAddr: PByteArray;
begin
  Count:=0;
  ClusterSize:=BootSec.bClustSects*BootSec.wSectSize; //������ �������� � ������
  DirEntriesRootAddr:=FATaddr+BootSec.wFatSects*BootSec.bFatCnt*BootSec.wSectSize; //������� ������ ��������� �������� � ������
  DirEntriesRootSize:=SizeOf(TDirEntryRec)*BootSec.wRootEntries; //������ �������� ������� ������
  ClustersBegin:=DirEntriesRootAddr+DirEntriesRootSize;
  EntriesInCluster:=ClusterSize div SizeOf(TDirEntryRec);
  if ClusterN=0 then begin
    SetLength(DirEntries,BootSec.wRootEntries); //�������� ������ ������� ��� ����� ������ � �����
    Stream.Position:=DirEntriesRootAddr; //���������� �� ������ ��� ������ ������ ������
    Stream.Read(Pointer(DirEntries)^,DirEntriesRootSize); //������� ������ ������
  end else begin
    while ClusterN<>($FFFF and FatMask) do begin
      DirEntriesAddr:=ClustersBegin+(longword(ClusterN)-2)*ClusterSize; //������� �������� �� ������� ������ � �����������
      SetLength(DirEntries,(Count+1)*EntriesInCluster); //��������� ������ ������� ��� ������ ������ �� 1 �������
      Stream.Position:=DirEntriesAddr; //���������� �� ������ ��� ������ ������ ������
      PDirAddr:=@DirEntries[Count*EntriesInCluster];
      Stream.Read(PDirAddr^,ClusterSize); //������� ������ ������ � ���������� ��������
      inc(Count);
      ClusterN:=NextCluster(ClusterN);
    end;
  end;
  i:=0;
  while (DirEntries[i].abName[1]<>#0)and(i<Length(DirEntries)) do inc(i); //������ ����� ������ ������
  Entries:=i;
end;
 
procedure TForm1.PrintFileList(DirEntries: TDirEntryRecArray;
  Entries: integer);
var
  i: Integer;
  S,Sext,Sdir: string;
  wS: WideString;
  ListItem1: TListItem;
begin
  ListView1.Clear;
  wS:=''; //������������� ������ �������� ����� (��� � Unicode)
  For i:=0 to Entries-1 do begin
    if DirEntries[i].bAttr=$0F then begin // $0F - �������������� �������, ������ ������� ���
      wS:=wS+RecToWStr(DirEntries[i]); //������� ����� �������� ����� �� ������
    end else begin //������ ������� ��� ������������� ���������� �������, � ��� ����� ������� ����������� ��� � ������� 8.3
      S:=RecToStr(DirEntries[i].abName,Length(DirEntries[i].abName)); //��� ����� � ������� 8.3
      Sext:=RecToStr(DirEntries[i].abExt,Length(DirEntries[i].abExt)); //���������� ����� � ������� 8.3
      If Sext<>'' then S:=S+'.'+Sext;
      if wS='' then wS:=S; //���� �� ���� �������� �����, �� �������� �������� ���, ����� ������� ��� ��������
      if (DirEntries[i].bAttr and $10)>0 then Sdir:='Dir' //�������� ������� (������� ��� ���)
        else Sdir:='File';
      ListItem1:=ListView1.Items.Add; //������� ������ � ListView
      ListItem1.Caption:=wS; //������ ������� - ��� �����
      ListItem1.SubItems.Add(Sdir); //������ ������� - ��� �����
      ListItem1.SubItems.Add(IntToStr(DirEntries[i].lSize)); //������ ������� - ������ �����
      ListItem1.SubItems.Add(IntToStr(DirEntries[i].wClstrNo)); //������ ������� - ������ �����
//      Memo1.Lines.Add(wS+#9+Sdir+#9+IntToStr(Files[i].lSize)+#9+IntToStr(Files[i].wClstrNo));
      wS:='';
    end;
  end;
end;
 
procedure TForm1.ListView1DblClick(Sender: TObject);
var
  Stream: TStream;
  S: string;
begin
  if ListView1.Items.Count=0 then Exit;
  if ListView1.Selected.SubItems[0]<>'Dir' then Exit;
  S:=ListView1.Selected.SubItems.Strings[2];
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadDirFromStream(Stream,StrToInt(S));
  finally
    Stream.Free;
  end;
 
end;
 
 
 
end.