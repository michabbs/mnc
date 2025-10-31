{ Ten plik stanowi czesc projektu: MiCHA Nodelist Converter
  Copyright (c) 1997-2000 Przemyslaw Kwiatkowski

  MiCHA Nodelist Converter jest wolnym oprogramowaniem; mozesz go
  rozprowadzac dalej i/lub modyfikowac na warunkach GNU General
  Public License, wydanej przez Free Software Foundation - wedlug
  wersji 2-giej tej licencji lub ktorejs z pozniejszych.

  MiCHA Nodelist Converter rozpowszechniany jest z nadzieja, iz bedzie
  on uzyteczny - jednak BEZ JAKIEJKOLWIEK GWARANCJI, nawet domyslnej
  gwarancji PRZYDATNOSCI HANDLOWEJ albo PRZYDATNOSCI DO OKRESLONYCH
  ZASTOSOWAN. W celu uzyskania blizszych informacji - patrz:
  GNU General Public License.

  Z pewnoscia wraz z niniejszym programem otrzymales tez egzemplarz
  GNU General Public License; jesli nie - napisz do Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}


{--------------}
{ Liczenie CRC }
{--------------}
unit crc;
{$F+}


interface

 uses dos,crt,main;

 function LiczCrc(nazwa:string):word;
 procedure letsgo;
 procedure help;



implementation


 procedure help;
 begin
  writeln('Mode ''Crc'':   MNC calculates and checks CRC of nodelist(s) and/or pointlist(s).');
  writeln;
  writeln('* Usage: MNC Crc <filename> [<filename>...]');
  writeln;
  halt(4);
 end;



 function CRC16(inpbyte:byte; oldCRC:word):word;
  var i,temp:word;
 begin
  temp:=oldCRC;
  for i:=1 to 8 do
     if (temp and $8000)=$8000 then
       begin
         temp:=temp shl 1;
         temp:=temp xor $1021;
       end
     else
       begin
         temp:=temp shl 1;
       end;
  CRC16:=temp xor inpbyte;
 end;


 function LiczCrc(nazwa:string):word;
  var plik:text;
      crc:word;
      i:byte;
      linia:string;
      dlug:byte;
      obracac:boolean;

  procedure addcrc(linia:string);
   var i:byte;
  begin
   for i:=1 to length(linia) do crc:=crc16(ord(linia[i]),crc);
   crc:=crc16(13,crc);
   crc:=crc16(10,crc);
  end;

 begin
  obracac:=main.obracac;
  main.obracac:=true;
  gotoxy(wherex-1,wherey);
  write(obracanie[obr]);

  crc:=0;
  assign(plik,nazwa);
  reset(plik);
  readln(plik,linia);

  crcinfile:=0;
  if (ord(linia[length(linia)])>=ord('0')) and (ord(linia[length(linia)])<=ord('9')) then
    begin
      dlug:=length(linia);
      while (ord(linia[dlug-1])>=ord('0')) and (ord(linia[dlug-1])<=ord('9')) do dec(dlug);
      for i:=dlug to length(linia) do
        crcinfile:=crcinfile*10+ord(linia[i])-48;
    end;

  while not eof(plik) do
    begin
      readln(plik,linia);
      addcrc(linia);
      obroc;
    end;
  close(plik);
  crc:=crc16(0,crc);
  crc:=crc16(0,crc);

  gotoxy(wherex-1,wherey);
  write(' ');
  main.obracac:=obracac;
  LiczCrc:=crc;
 end;



 procedure letsgo;
  var crc:word;
      i:byte;
      plik:text;
      linia:string;

 begin
  if (paramcount=1) then help;
  if (paramstr(2)='?') or (paramstr(2)='/?') or (paramstr(2)='-?') then help;
  if (paramstr(2)='-h') or (paramstr(2)='-H') or (paramstr(2)='/h') or (paramstr(2)='/H') then help;

  for i:=firstparam to paramcount do
  begin
    fsplit(fexpand(paramstr(i)),kat_,nazw_,rozsz_);
    if fsearch(paramstr(i),'')='' then
      begin
        write('* File ');
        nazwapliku(kat_+nazw_+rozsz_);
        writeln(' doesn''t exist!');
      end
    else
      begin
        write('* Calculating CRC...  ');
        crc:=liczcrc(paramstr(i));
        gotoxy(1,wherey);
        write('* CRC of ');
        nazwapliku(nazw_+rozsz_);
        write(' = ',crc);

        if crc=crcinfile then
          writeln('  Ok')
        else
          begin
            textcolor(13);
            write('  CRC ERROR!!!');
            textcolor(7);
            writeln('  (CRC in file: ',crcinfile,')',#7);
            inc(haltno);
          end;
      end;
  end;
  writeln;
 end;


end.
