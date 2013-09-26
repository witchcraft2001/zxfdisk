unit Unit1;
 
interface
 
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;
 
type
  TBootSectorRec = packed record //Заголовок загрузочного сектора (62 байта)
    abJmpCode       : array [1..3] of byte; //Инструкция Jmp на начало кода
    abOem           : array [1..8] of char; //Название фирмы-производителя операционной системы и версия
    wSectSize       : word; //Байтов в секторе, для дискеты 512
    bClustSects     : byte; //Секторов в кластере
    wResSects       : word; //число зарезервированных секторов на диске, включая загрузочный сектор
    bFatCnt         : byte; //Число таблиц FAT (обычно 2, основная и дублирующая)
    wRootEntries    : word; //Максимальное число 32-байтовых записей DirEntryRec в корневом каталоге
    wTotSects       : word; //Общее число секторов на носителе. Значение 0000h означает, что раздел объёмом выше, чем 32МБ. Тогда значение надо считывать с lBigTotSects.
    bMedia          : byte; //Media Descriptor. F8h - жёсткий диск, остальные знаения (F0, F9, FA, FB, FC, FD, FE, FF) означают формат гибкого диска (количество сторон и секторов на дорожке).
    wFatSects       : word; //Число секторов на одну таблицу размещения файлов (FAT)
    wSectsPerTrk    : word; //Число секторов на один трек (цилиндр)
    wHeads          : word; //Число записывающих/считывающих головок
    lHidSects       : Longword; //Скрытые сектора
    lBigTotSects    : Longword; //32-bit число секторов на разделе большем, чем 32МБ
    bDrvNo          : byte; //80h - первый жесткий диск (используется внутри MS-DOS)
    res1            : byte; //Зарезервировано
    bExtBootSig     : byte; //Дополнительная подпись, всегда равна 29h
    lSerNo          : Longword; //Volume Serial Number
    abVolLabel      : array [1..11] of char; //Метка тома, 11 символов, дополненых пробелами, если необходимо
    abFileSysID     : array [1..8] of char; //Название файловой системы (FAT12 или FAT16)
  end;
 
  TDirEntryRec = packed record //Структура файла или каталога
    case integer of
    0:(
      abName         : array [1..8] of char;  //Имя файла, выровненное влево, остаток заполнен пробелами (20h). Самый первый символ имени имеет особое значение: 0 - Запись еще не использовалась, 5 - Первый символ 0E5h, 2Eh - Это ссылка на каталог (.=сам, ..=родитель), E5h - Запись удалена
      abExt          : array [1..3] of char;  //Расширение, выровненное влево, остаток заполнен пробелами
      bAttr          : byte;  //Атрибуты (Биты: 0 - Read-only, 1 - Hidden (Невидимый), 2    - System (Системный), 3 - Volume label entry, 4 - subDirectory entry (подкаталог), 5 - Archive (1=file has not been backed up) Устанавливается дла архивации файла, 6,7 - зарезервированы)
      NTReserved     : byte;  //зарезервировано для Windows NT
      CreateTimeTenth: byte;  //десятые доли времени создания
      CreateTime     : word;  //время создания
      CreateDate     : word;  //Дата создания
      LastAccessDate : word;  //дата последнего доступа
      FirstClusterHi : word;  //старшее слово номера кластера
      WriteTime      : word;     //Время изменения (Биты: 0..3 - Cекунды/2 (0-29), 4..10 - Минуты (0-59), 11..15 - Часы (0-23))
      WriteDate      : word;     //Дата изменения (Биты: 0..6   - Год от 1980 (0-127), 7..10 - Месяц (1-12), 11..15 - День (1-31))
      wClstrNo       : word;     //Номер кластера начала файла в FAT
      lSize          : longint;  //Длинна файла до 4ГБ
    );
    1:(
      lfn_Sequence   : byte;    // номер дескриптора
      lfn_Name1      : array [1..5] of WCHAR; // первая часть имени
      lfn_Attributes : byte;    // атрибуты
      lfn_LongEntryType : byte; // признак расширенного атрибута (всегда 0)
      lfn_Checksum   : byte;    // контрольная сумма имени
      lfn_Name2      : array [1..6] of WCHAR; // вторая часть имени
      lfn_Reserved   : word;    // зарезервировано
      lfn_Name3      : array [1..2] of WCHAR; // третья часть имени
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
    function RecToStr(const Buf; Size: integer): string; //Извлечь короткое имя
    function RecToWStr(DirEntry: TDirEntryRec): WideString; //Извлечь длинное имя
    function NextCluster(N: word): word; //Вытаскивает из FAT таблицы указатель на следующий кластер
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
  Button1.Caption:='Открыть файл .IMG';
  Button1.Width:=150;
  OpenDialog1.Filter:='Image FAT (*.img)|*.img';
  ListView1.ViewStyle:=vsReport;
  with ListView1.Columns.Add do Caption:='Name';
  with ListView1.Columns.Add do Caption:='ID';
  with ListView1.Columns.Add do Caption:='Size';
  with ListView1.Columns.Add do Caption:='Cluster';
  ListView1.Column[0].Width:=120;
  ListView1.Clear;
  FatMask:=$FFFF; //Если FAT16
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
      Stream.Read(BootSec, SizeOf(TBootSectorRec)); //Считать заголовок загрузочного сектора
      SetLength(FAT,BootSec.wFatSects*BootSec.wSectSize); //Выделить память под FAT таблицу
      FATaddr:=BootSec.wResSects*BootSec.wSectSize; //Начало первой FAT таблицы
      Stream.Position:=FATaddr;
      Stream.Read(Pointer(FAT)^,BootSec.wFatSects*BootSec.wSectSize);
      S:=RecToStr(BootSec.abFileSysID,Length(BootSec.abFileSysID)); //Определить файловую систему (FAT12 или FAT16)
      if SameText(S,'FAT12') then FatMask:=$FFF;
      LoadDirFromStream(Stream,0);
    finally
      Stream.Free;
    end;
  end;
end;
 
function TForm1.RecToStr(const Buf; Size: integer): string; //Извлечь короткое имя
begin
  SetString(Result,PChar(@Buf),Size);
  Result:=TrimRight(Result);
end;
 
function TForm1.RecToWStr(DirEntry: TDirEntryRec): WideString; //Извлечь длинное имя
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
  SetLength(DirEntries,0); //Освободить память под массивом
end;
 
function TForm1.NextCluster(N: word): word;
var
  b: byte;
  i: integer;
begin
  b:=4; //Количество полубайт в одной записи таблицы
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
  ClusterSize:=BootSec.bClustSects*BootSec.wSectSize; //Размер кластера в байтах
  DirEntriesRootAddr:=FATaddr+BootSec.wFatSects*BootSec.bFatCnt*BootSec.wSectSize; //Позиция начала корневого каталога в потоке
  DirEntriesRootSize:=SizeOf(TDirEntryRec)*BootSec.wRootEntries; //Размер корневой области файлов
  ClustersBegin:=DirEntriesRootAddr+DirEntriesRootSize;
  EntriesInCluster:=ClusterSize div SizeOf(TDirEntryRec);
  if ClusterN=0 then begin
    SetLength(DirEntries,BootSec.wRootEntries); //Выделить память массиву под имена файлов и папок
    Stream.Position:=DirEntriesRootAddr; //Сместиться по образу для чтения списка файлов
    Stream.Read(Pointer(DirEntries)^,DirEntriesRootSize); //Считать список файлов
  end else begin
    while ClusterN<>($FFFF and FatMask) do begin
      DirEntriesAddr:=ClustersBegin+(longword(ClusterN)-2)*ClusterSize; //Позиция кластера со списком файлов в подкаталоге
      SetLength(DirEntries,(Count+1)*EntriesInCluster); //Увеличить память массиву под список файлов на 1 кластер
      Stream.Position:=DirEntriesAddr; //Сместиться по образу для чтения списка файлов
      PDirAddr:=@DirEntries[Count*EntriesInCluster];
      Stream.Read(PDirAddr^,ClusterSize); //Считать список файлов с очередного кластера
      inc(Count);
      ClusterN:=NextCluster(ClusterN);
    end;
  end;
  i:=0;
  while (DirEntries[i].abName[1]<>#0)and(i<Length(DirEntries)) do inc(i); //Искать конец списка файлов
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
  wS:=''; //Инициализация строки длинного имени (она в Unicode)
  For i:=0 to Entries-1 do begin
    if DirEntries[i].bAttr=$0F then begin // $0F - противоречивый атрибут, значит длинное имя
      wS:=wS+RecToWStr(DirEntries[i]); //Считать часть длинного имени из записи
    end else begin //Всякое длинное имя заканчивается нормальной записью, в ней также имеется сокращённое имя в формате 8.3
      S:=RecToStr(DirEntries[i].abName,Length(DirEntries[i].abName)); //Имя файла в формате 8.3
      Sext:=RecToStr(DirEntries[i].abExt,Length(DirEntries[i].abExt)); //Расширение файла в формате 8.3
      If Sext<>'' then S:=S+'.'+Sext;
      if wS='' then wS:=S; //Если не было длинного имени, то выводить короткое имя, иначе длинное имя оставить
      if (DirEntries[i].bAttr and $10)>0 then Sdir:='Dir' //Проверим атрибут (Каталог или нет)
        else Sdir:='File';
      ListItem1:=ListView1.Items.Add; //Добавим строку в ListView
      ListItem1.Caption:=wS; //Первая колонка - имя файла
      ListItem1.SubItems.Add(Sdir); //Вторая колонка - тип файла
      ListItem1.SubItems.Add(IntToStr(DirEntries[i].lSize)); //Третья колонка - размер файла
      ListItem1.SubItems.Add(IntToStr(DirEntries[i].wClstrNo)); //Третья колонка - размер файла
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