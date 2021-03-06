# Общие сведения

<img src="https://github.com/witchcraft2001/zxfdisk/blob/master/screenshots/ATM/atm_backup.png"/>

<img src="https://github.com/witchcraft2001/zxfdisk/blob/master/screenshots/sshot000003.png"/>

   Данная программа предназначена для создания и редактирования
таблицы разделов на жестком диске.
   В полной мере поддерживаются все первичные разделы, а так же
расширенные (extended) типов 0x05 и 0x0f, которые создаются
стандартными средствами MS-DOS/Windows.

   Программа собирается для различных платформ: Profi, ATM2,
ZX128, Sprinter. Отличие заключается в драйвере консоли,
встроенным драйвером IDE, а так же в комплектации драйверов IDE
на диске.
   В данный момент имеются драйвера для наиболее встречающихся
на просторах exСССР клонов ZX-Spectrum: NemoIDE, Profi, SMUC
(медленная версия, доступ через точки входа в ПЗУ TR-DOS),ATM2.
Внутренний драйвер поддерживает стандартный для целевой платформы контроллер IDE:
   * ZX128 - NemoIDE;
   * Profi - Profi IDE;
   * ATM2 - ATM2;
   
   Так же на дискете с программой расположены драйвера для других
контроллеров.
   * Sprinter - Sprinter IDE (в комплекте с этой сборкой дополнительные
драйвера не поставляются, т.к. на Sprinter-е использовался лишь встроенный
на материнской плате контроллер IDE).

# Управление

   Управление в программе осуществляется с помощью горячих клавиш. На
каждом этапе работы на экран выводится подсказка в виде:
```
   [U] - Dump sector,
```
   где в квадратных скобках, выделенных желтым цветом, указана
клавиша, которая запустит команду, в данном случае нажатие клавиши
"U" приведет к выводу дампа сектора.

# Выбор драйвера

   После запуска программы появляется диалог выбора драйвера
контроллера IDE. Пользователю необходимо ввести номер драйвера
и нажать Enter для продолжения. В случае отсутсвия драйверов на
дискете с программой, будет использоваться встроенный драйвер.
После загрузки и проверки драйвера производится поиск жестких
дисков, если не обнаружено ни одного привода, то предлагается
выбрать другой драйвер IDE.

# Список дисководов

   При успешном завершении поиска дисководов список найденных
дисководов выводится на экран, пользователю предлагается выбрать
один из дисководов для продолжения работы:

```
   Select device: [1] - Master, [2] - Slave
```

   Если обнаружен только один дисковод, программа активирует
его, о чем информирует пользователя:

```
   Selected MASTER (SLAVE) device.
   Press any key to continue...
```

и ожидается нажатие любой кнопки.

# Просмотр и редактирование таблицы разделов

...

# Просмотр дампа секторов

Пользователю будет предложено ввести номер раздела, первый
сектор которого будет отображен на экране. Если будет введен
номер "0", либо пустая строка, то будет отображен самый первый
сектор жесткого диска.

В самом верху экрана отображен номер текущего сектора.
Далее следует дамп информации, разделенный на 3 области -
смещение от начала сектора, отображение информации в шестнадцатеричном
виде, ASCII-вид.
Т.к. информация всего сектора не помещается на экране, она
разделена на две страницы. Между страницами переключиться можно
с помощью клавиш "1" и "2".

Снизу отображена подсказка по командам:

```
  [1] - First page (Первая страница дампа сектора)
  [2] - Second page (Вторая страница дампа сектора)
  [P] - Prev. sector (Предыдущий сектор)
  [N] - Next sector (Следующий сектор)
  [Q] - Quit (Возврат в предыдущее меню)
```

# Создание резервной копии таблицы разделов

   Программа позволяет сохранить структуру разделов диска на
дискету, с целью последующего восстановления.
   Файл резервной копии таблицы разделов с расширением "mbr"
создается на дискете в приводе, с которого была загружена
программа. Для предотвращения возможной порчи таблицы разделов
на жестком диске при операции восстановления, в файл записываются
параметры жесткого диска - его модель, серийный номер,
геометрия, а затем таблица разделов. Формат файла описан ниже.

## Формат файла резервной копии:
```
+0      10      "partitions"
+10     1       "0" - версия файла
+11     40      Модель жесткого диска
+51     20      Серийный номер
+71     2       Количество дорожек у привода
+73     1       количество головок
+74     1       количество секторов
+75     4       Total number of user addressable sectors
+79     1       Количество записей о разделах (N)
+80     N*32    Собственно сами записи
```

## Структура записей:
```
+0      4       Номер сектора, относительно начала диска, в
                котором находится данная запись (для MBR==0)
+4      1       Номер записи в текущей таблице
+5      16      Partition Table Entry
+21     11      Метка тома, если определена
```

# Восстановление таблицы разделов

   Имеется возможность восстановить испорченную таблицу
разделов из файла резервной копии. При выборе данной команды
на экран выводится список файлов *.mbr, находящихся на текущей
дискете. Для выбора нужного файла необходимо ввести его номер.
После этого программа сверяет параметры жесткого диска, с
которого была сохранена данная копия, с параметрами выбранного
жесткого диска, в случае различия - выводится сообщение об
ошибке. Если параметры совпадают, то данные считываются в буфер
отложенных операций. Для применения отложенных операций
необходимо выполнить соответствующую команду.

# Благодарности

   Хочу выразить благодарность следующим людям за содействие в
разработке данной программы:
**Northwood**, **solegstar**, **savelij**, **deathsoft**, **Vadim**, **BlackCat**,
**Palsw**, **Prusak**.
