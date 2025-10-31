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


{------------------------------------------}
{ Kombinacja nodelisty i pliku r¢§nicowego }
{------------------------------------------}
unit update;
{$O+,F+}


interface

 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Update'':   MNC combines fido-style nodelist and nodediff (difference');
  writeln('                 file) to new nodelist.');
  writeln;
  writeln('* Usage: MNC Update -i<filename> -d<filename> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<filename> - old nodelist');
  writeln('  -d<filename> - difference file');
  writeln('  -o<filename> - new nodelist');
  writeln('  -f           - force mode');
  writeln('  -s           - speed mode');
  writeln('  -e           - delete old nodelist when done');
  writeln('  -b           - delete old nodediff when done');
  writeln;
  halt(4);
 end;


 procedure letsgo;

  var wejscie,diff,wyjscie:text;    {przetwarzane pliki}
      lines,commands,added,deleted:longint;
      infile,difffile,outfile:string;     {nazwy plik¢w}
      quiet,crcadd,force,diff999,deleteafter,deletediff:boolean;
      atrybut:word; {atrybut pliku}

  {szukanie najstarszego pliku nowszego od ile}
  {wynik = trzyliterowe rozszerzenie}
  function min999(nazwa:string; ile:integer):string;
   var ext:string[3];
       juz:boolean;
       plik:searchrec; {pomocnicza nazwa pliku przy szukaniu}
       min,pom,pom2:integer;
  begin
   min:=1000;
   juz:=false;
   doserror:=0;
   findfirst(nazwa+'.*',anyfile,plik);

   repeat
    if (doserror=3) or (doserror=18) then
      juz:=true
    else
      begin
        val(copy(plik.name,pos('.',plik.name)+1,3),pom,pom2);
        if (pom2=0) and (pom<min) and (pom>ile) then min:=pom;
        findnext(plik);
      end;
   until juz;

   if min=1000 then min:=999;
   str(min,ext);
   if length(ext)=3 then min999:=ext
   else if length(ext)=2 then min999:='0'+ext
   else if length(ext)=1 then min999:='00'+ext
   else min999:='999';
  end;

  procedure readconfig;
   var linia,cmd,param:string;
       pom,pom1:integer;
  begin
   mode:='';
   while mode='' do
     begin
       readln(cfg,linia);
       inc(nr);
       porzadkuj(linia,cmd,param);
       if cmd<>'' then
         begin
           if cmd='processfile' then
             begin
               if infile<>'nul' then badline;
               if copy(param,length(param)-3,4)='.999' then
                 param:=copy(param,1,length(param)-3)+plik999(copy(param,1,length(param)-4));
               if fsearch(param,'')<>'' then
                 infile:=fexpand(param)
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(param));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='processdiff' then
             begin
              if difffile<>'nul' then badline;
              difffile:=fexpand(param);
              if copy(difffile,length(difffile)-3,4)='.999' then
                 begin
                   diff999:=true;
                   fsplit(infile,kat_,nazw_,rozsz_);
                   val(copy(rozsz_,2,3),pom,pom1);
                   if pom1=0 then
                     difffile:=copy(difffile,1,length(difffile)-3)+min999(copy(difffile,3,length(difffile)-6),pom);
                 end;
              if fsearch(difffile,'')='' then
                begin
                  write('* File ');
                  nazwapliku(fexpand(param));
                  writeln(' doesn''t exist!');
                  writeln;
                  halt(2);
                end;
             end
           else if cmd='createfile' then
             begin
               if outfile<>'nul' then badline;
               if param<>'' then
                 outfile:=fexpand(param);
             end
           else if cmd='deleteold' then
             begin
               if downstr(param)='yes' then deleteafter:=true
               else if downstr(param)='no' then deleteafter:=false
               else badline;
             end
           else if cmd='deletediff' then
             begin
               if downstr(param)='yes' then deletediff:=true
               else if downstr(param)='no' then deletediff:=false
               else badline;
             end
           else if cmd='forcemode' then
             begin
               if downstr(param)='yes' then force:=true
               else if downstr(param)='no' then force:=false
               else badline;
             end
           else if cmd='speedmode' then
             begin
               if downstr(param)='yes' then quiet:=true
               else if downstr(param)='no' then quiet:=false
               else badline;
             end
           else if (cmd[1]='[') and (cmd[length(cmd)]=']') then mode:=cmd
           else badline;
         end;
       if eof(cfg) then mode:='[end]';
     end;
  end;

  procedure init;
   var i,j:byte;
       parametr:string;
       plik:searchrec;
       ok:boolean;
       pom,pom1:integer;
  begin;
   deleteafter:=false;
   deletediff:=false;
   quiet:=dft_quiet;
   force:=dft_force;
   diff999:=false;
   outfile:='nul';
   difffile:='nul';
   infile:='nul';

   if withconfig then
     readconfig
   else
     for i:=firstparam to paramcount do
       begin
         parametr:=paramstr(i);
         if (parametr[1]<>'-') and (parametr[1]<>'/') then if parametr[1]='?' then help else badparams(i);
         if upcase(parametr[2])='I' then
           begin
             if infile<>'nul' then badparams(i);
             if copy(parametr,length(parametr)-3,4)='.999' then
               parametr:=copy(parametr,1,length(parametr)-3)+plik999(copy(parametr,3,length(parametr)-6));
             if fsearch(copy(parametr,3,length(parametr)),'')<>'' then
               infile:=fexpand(copy(parametr,3,length(parametr)))
             else
               begin
                 write('* File ');
                 nazwapliku(copy(parametr,3,length(parametr)));
                 writeln(' doesn''t exist!');
                 writeln;
                 halt(2);
               end;
           end
         else if upcase(parametr[2])='D' then
           begin
            if difffile<>'nul' then badparams(i);
            difffile:=fexpand(copy(parametr,3,length(parametr)));

              if copy(difffile,length(difffile)-3,4)='.999' then
                 begin
                   diff999:=true;
                   fsplit(infile,kat_,nazw_,rozsz_);
                   val(copy(rozsz_,2,3),pom,pom1);
                   if pom1=0 then
                     difffile:=copy(difffile,1,length(difffile)-3)+min999(copy(difffile,3,length(difffile)-6),pom);
                 end;
              if fsearch(difffile,'')='' then
                begin
                  write('* File ');
                  nazwapliku(fexpand(copy(parametr,3,length(parametr))));
                  writeln(' doesn''t exist!');
                  writeln;
                  halt(2);
                end;
           end
         else if upcase(parametr[2])='O' then
           begin
            if outfile<>'nul' then badparams(i);
            outfile:=fexpand(copy(parametr,3,length(parametr)));
           end
         else if upcase(parametr[2])='F' then force:=true
         else if upcase(parametr[2])='S' then quiet:=true
         else if upcase(parametr[2])='E' then deleteafter:=true
         else if upcase(parametr[2])='B' then deletediff:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;


   if (infile='nul') or (difffile='nul') then
     begin
       writeln('* No infile(s) specified!');
       writeln;
       halt;
     end;

   if outfile='nul' then
     begin
       fsplit(fexpand(infile),kat_,nazw_,rozsz_);
       outfile:=kat_+nazw_;
       fsplit(fexpand(difffile),kat_,nazw_,rozsz_);
       outfile:=outfile+rozsz_;
     end;

   if quiet then writeln('* Speed mode.');
   if force then writeln('* Force mode.');
  end;

  procedure inicjuj;
  var ok:boolean;
  begin
   write('* New nodelist ');
   nazwapliku(outfile);
   writeln(' will be created.');

   if force=false then
     if fsearch(outfile,'')<>'' then
       begin
         write('* File ');
         nazwapliku(outfile);
         write(' already exists!  ');
         ok:=false;
         write('Overwrite [Y/n] ?');
         while (ok=false) and (outfile<>'nul') do
         case readkey of
           'n','N',#27 : begin
                           outfile:='nul';
                           gotoxy(1,wherey);
                           writeln(#32:77);
                           gotoxy(1,wherey-1);
                         end;
           'y','Y',#13 : begin
                           ok:=true;
                           gotoxy(1,wherey);
                           assign(wyjscie,outfile);
                           getfattr(wyjscie,atrybut);
                           setfattr(wyjscie,0);
                           erase(wyjscie);
                           write('* File ');
                           nazwapliku(outfile);
                           write(' deleted.');
                           if atrybut and readonly <> 0 then
                             writeln(' (read only!)',#32:14)
                           else
                             writeln(#32:26);
                         end;
         end;
       end
     else
   else
     begin
       if fsearch(outfile,'')<>'' then
         begin
           assign(wyjscie,outfile);
           getfattr(wyjscie,atrybut);
           setfattr(wyjscie,0);
           erase(wyjscie);
           write('* File ');
           nazwapliku(outfile);
           write(' deleted.');
           if atrybut and readonly <> 0 then
             writeln(' (read only!)')
           else
             writeln;
         end;
     end;

   assign(wejscie,infile);
   assign(diff,difffile);
   assign(wyjscie,outfile);
   reset(wejscie);
   reset(diff);
   rewrite(wyjscie);

   commands:=0;
   added:=0;
   deleted:=0;
   lines:=0;
  end;


  procedure badfile;
  begin
   writeln('* Bad nodelist or nodediff file!');
   close(wyjscie);
   erase(wyjscie);
   write('* Bad file ');
   nazwapliku(outfile);
   writeln(' deleted.');
   writeln;
   halt;
  end;


  procedure sprawdz;
   var linia1,linia2:string;
  begin
   write('* Processing nodelist: ');
   textcolor(2); writeln('''',infile,'''');
   textcolor(7); write('* Processing nodediff: ');
   textcolor(2); writeln('''',difffile,'''');
   textcolor(7);

   if eof(diff) or eof(wejscie) then badfile;
   readln(wejscie,linia1);
   readln(diff,linia2);
   if linia1<>linia2 then badfile;
   close(wejscie);
   reset(wejscie);
  end;


  procedure statystyka;
  begin
   write('Commands: ');
   textcolor(14); write(commands);
   textcolor(7);  write('          Lines: ');
   textcolor(14); write(lines);
   textcolor(7);  write('   Deleted: ');
   textcolor(14); write(deleted);
   textcolor(7);  write('   Added: ');
   textcolor(14); writeln(added);
   textcolor(7);
   gotoxy(1,wherey-1);
  end;


  procedure zostaw(ile:integer);
   var i:integer;
       linia:string;
  begin
   for i:=1 to ile do
     begin
       readln(wejscie,linia);
       writeln(wyjscie,linia);
       inc(lines);
       if not quiet then statystyka;
     end;
  end;

  procedure del(ile:integer);
   var i:integer;
       linia:string;
  begin
   for i:=1 to ile do
     begin
       readln(wejscie,linia);
       inc(deleted);
       if not quiet then statystyka;
     end;
  end;

  procedure add(ile:integer);
   var i:integer;
       linia:string;
  begin
   for i:=1 to ile do
     begin
       readln(diff,linia);
       writeln(wyjscie,linia);
       inc(added);
       inc(lines);
       if not quiet then statystyka;
     end;
  end;


  procedure killplik(nazwa:string);  {wejscie: plik do skasowania}
   var plik:file;
       ok:boolean;
  begin
   fsplit(fexpand(nazwa),kat_,nazw_,rozsz_);
   assign(plik,nazwa);
   getfattr(plik,atrybut);
   write('* Do you want to delete ');
   if atrybut and readonly <> 0 then
     write('read only ');
   write('file ');
   nazwapliku(nazw_+rozsz_);
   write(' [y/N] ?');
   ok:=false;
   while ok=false do
   case readkey of
     'n','N',#13 : begin
                     ok:=true;
                     gotoxy(1,wherey);
                     writeln(#32:79);
                     gotoxy(1,wherey-1);
                   end;
     'y','Y' : begin
                 ok:=true;
                 writeln('y');
                 setfattr(plik,0);
                 erase(plik);
                 gotoxy(1,wherey-1); write('* File ');
                 nazwapliku(nazwa);
                 write(' deleted.  ');
                 if atrybut and readonly <> 0 then
                   writeln('(read only)',#32:5)
                 else
                   writeln(#32:16);
               end;
   end;
  end;

  procedure koniec;
   var crc:word;
       linia:string;
       ok,ok1:boolean;
       plik:file;
  begin
   close(wejscie);
   write(wyjscie,#$1a);
   close(wyjscie);
   close(diff);

   if not quiet then
     begin
       statystyka;
       writeln;
       writeln;
     end;
   write('* Nodelist ');
   nazwapliku(outfile);
   writeln(' created.   ');
   write('* Calculating CRC...  ');
   crc:=LiczCrc(outfile);
   gotoxy(3,wherey);
   write('CRC = ');
   textcolor(2); write(crc);
   textcolor(7);
   if crc=crcinfile then
     begin
       writeln('  Ok.        ');
       if deleteafter then
         begin
           getfattr(wejscie,atrybut);
           if atrybut and readonly = 0 then
             begin
               erase(wejscie);
               write('* Old nodelist ');
               nazwapliku(infile);
               writeln(' deleted.');
             end
           else
             begin
               if force then
                 begin
                   write('* Old nodelist ');
                   nazwapliku(infile);
                   writeln(' not deleted. (read only)');
                 end
               else
                 killplik(infile);
             end;
         end
       else
         if not force then killplik(infile);
       if deletediff then
         begin
           getfattr(diff,atrybut);
           if atrybut and readonly = 0 then
             begin
               erase(diff);
               write('* Old nodediff ');
               nazwapliku(difffile);
               writeln(' deleted.');
             end
           else
             begin
               if force then
                 begin
                   write('* Old nodediff ');
                   nazwapliku(difffile);
                   writeln(' not deleted. (read only)');
                 end
               else
                 killplik(difffile);
             end;
         end
       else
         if not force then killplik(difffile);
     end
   else
     begin
       textcolor(13); writeln('   CRC ERROR!!!',#7); textcolor(7);
       if not force then
         begin
          fsplit(fexpand(outfile),kat_,nazw_,rozsz_);
          assign(plik,outfile);
          write('* Do you want to delete ');
          write('file ');
          nazwapliku(nazw_+rozsz_);
          write(' [Y/n] ?');
          ok1:=false;
          while ok1=false do
          case readkey of
            'n','N',#27 : begin
                            ok1:=true;
                            gotoxy(1,wherey);
                            writeln(#32:79);
                            gotoxy(1,wherey-1);
                          end;
            'y','Y',#13 : begin
                            ok1:=true;
                            writeln('y');
                            erase(plik);
                            gotoxy(1,wherey-1); write('* File ');
                            nazwapliku(outfile);
                            writeln(' deleted.  ',#32:16);
                          end;
          end;
         end
       else
         begin
           erase(wyjscie);
           write('* Bad file ');
           nazwapliku(outfile);
           writeln(' deleted.');
           writeln;
         end;
       diff999:=false;
     end;
   writeln;
  end;

  procedure process;
   var liniadiff:string;
       ile:integer;
       pom:integer;
  begin;
   writeln;
   if quiet then write('* Creating new nodelist...  ');
   while eof(diff)=false do
    begin
     inc(commands);
     readln(diff,liniadiff);
     if liniadiff[1]='D' then
       begin
         val(copy(liniadiff,2,length(liniadiff)),ile,pom);
         if pom<>0 then badfile;
         del(ile);
       end
     else if liniadiff[1]='A' then
       begin
         val(copy(liniadiff,2,length(liniadiff)),ile,pom);
         if pom<>0 then badfile;
         add(ile);
       end
     else if liniadiff[1]='C' then
       begin
         val(copy(liniadiff,2,length(liniadiff)),ile,pom);
         if pom<>0 then badfile;
         zostaw(ile);
       end
     else badfile;
    end;
   if quiet then
     begin
       gotoxy(1,wherey);
       write(#32:79);
       gotoxy(1,wherey);
     end;
  end;


  procedure nextdiff;
   var pom,pom1:integer;
  begin
   infile:=outfile;
   fsplit(infile,kat_,nazw_,rozsz_);
   val(copy(rozsz_,2,3),pom,pom1);
   if pom1=0 then
     difffile:=copy(difffile,1,length(difffile)-3)+min999(copy(difffile,3,length(difffile)-6),pom);
   fsplit(fexpand(infile),kat_,nazw_,rozsz_);
   outfile:=kat_+nazw_;
   fsplit(fexpand(difffile),kat_,nazw_,rozsz_);
   outfile:=outfile+rozsz_;
   if rozsz_='.999' then
     diff999:=false;
  end;



 begin
  write('--> Mode: ');
  textcolor(13); writeln('Update');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  repeat
   inicjuj;
   if outfile<>'nul' then
     begin
       sprawdz;
       process;
       koniec;
       if diff999 then nextdiff;
     end
   else
     begin
       writeln('* Program aborted.');
       writeln;
     end;
  until (not diff999) or (outfile='nul');
 end;


end.
