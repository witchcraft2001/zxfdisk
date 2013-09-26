#pragma hdrstop
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#pragma argsused
#include <malloc.h>
#include <dos.h>
#include <ctype.h>
#include <string.h>
unsigned char data[300000];
 
int main()
{
 int i,j;
 int rootSects, firstData, absSector, rootBegin, rootshuf;
 struct  // BOOT SECTOR
 {
   char bootcom[3];
   long long oem;
   short kolvo_bait_sec;
   char kolvo_sec_clast;
   short kolvo_reser_sec;
   char kolvo_copy_fat;
   short kolvo_32b;
   short kolvo_sec_obsh;
   char drive_type;
   short kolvo_sec_1fatcopy;
   short kolvo_sec_onroad;
   short kolvo_poverh;
   int kolvo_hidden_sec;
   int kolvo_sec_obsh2;
   char nuber_cddrive;
   char zero;
   char priznak;
   int number_log_disc;
   char disc_mark[11];
   char fat12[8];
 } *boot;
 
   typedef struct _FTIME_ // element ROOT
{
  unsigned sec : 5, min : 6, hour : 5;
} FTIME;
typedef struct _FDATE_
{
  unsigned day : 5, month : 4, year : 7;
} FDATE;
 struct FITEM
{
  char name[8];
  char ext[3];
  char attr;
  char reserved[10];
  FTIME time;
  FDATE date;
  unsigned cluster_nu;
  unsigned long size;
} *FITEM;
 
 
 
  FILE *fi;                               // OPEN FILE
  if ((fi=fopen("FAT16.img", "rb"))==0)
  {
   printf ("error open");
 
   getch();
   return 1;
  }
   fread(data,sizeof(data),1,fi);
   boot=(void *)(data+0);
 
                   // printf BOOT DATA
   fclose(fi);
   rootSects = boot->kolvo_32b * 32 / boot->kolvo_bait_sec;
   firstData = boot->kolvo_reser_sec + boot->kolvo_sec_1fatcopy * boot->kolvo_copy_fat + rootSects;
   rootBegin = boot->kolvo_reser_sec + boot->kolvo_sec_1fatcopy * boot->kolvo_copy_fat;
   //FAT_buf_siz = boot->kolvo_sec_1fatcopy * boot->kolvo_bait_sec;
   j = boot->kolvo_reser_sec;
   rootshuf = rootBegin * 512;
   printf("File system - %.8s\n",boot->fat12);
   printf("RecCec %d\n",boot->kolvo_reser_sec);
   printf("Rootsiz %d\n",boot->kolvo_32b);
   printf("BAIT SEC %d\n",boot->kolvo_bait_sec);
   printf("FAt size %d\n",boot->kolvo_sec_1fatcopy);
   printf("FATcnt %d\n",boot->kolvo_copy_fat);
   printf("Clust size %d\n",boot->kolvo_sec_clast);
   printf("rootSects %i\n",rootSects);
   printf("firstData %i\n",firstData);
   printf("rootBegin nomer pervogo sectora root %i\n",rootBegin);
   //printf("FAT_buf_siz %i\n",FAT_buf_siz);
   printf("NOMER PERVOGO SECTORA FAT %i\n",j);
   printf("smeshenie root %i\n",rootshuf);
 
                 // printf ROOT DATA
 
   printf("\n--------------ROOT-----------------\n");
   printf("\n NAME     ATR    DATE      TIME ");
   printf("\n ----     ---    ----      ---- ");
 
  for(i=0;i<7168;i+=32)
  {
  FITEM=(void *)(data + 12800+i);
  if (FITEM->attr!=0x0F)
  {
  if (FITEM->name[0]=='\0')
   {break;
   }
   printf("\n %.8s %02X   %02d-%02d-%02d   %02d:%02d:%02d\n",FITEM->name, FITEM->attr, FITEM->date.day, FITEM->date.month, FITEM->date.year+1980, FITEM->time.hour, FITEM->time.min, FITEM->time.sec*2);
   }
  }
 
 
   getch();
}