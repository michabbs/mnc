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


{-------------------------------------------------}
{ Tworzenie nowej nodelisty z plik¢w segmentowych }
{-------------------------------------------------}
unit create;
{$O+,F+}


interface

 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Create'':   MNC creates new nodelist or pointlist using segment-files.');
  writeln;
  writeln('* Usage: MNC Create -i<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - segment-files mask');
  writeln('  -o<name>     - new nodelist/pointlist');
  writeln('  -s<name>     - text file to add at start of new nodelist/pointlist');
  writeln('  -e<name>     - text file to add at end of new nodelist/pointlist');
  writeln('  -n<netname>  - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d           - use current date in nodelist/pointlist');
  writeln('  -p           - pointlist will be generated (default nodelist)');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  type pliczek=^nazwa_pliku;
       nazwa_pliku=record
                     name:string[128];
                     nastepny:pliczek;
                   end;

  var inlist,outlist,toadd:text;
      force,curday,pointlist:boolean;
      outfile,startfile,endfile:string;
      netname:string;
      sortby:byte;
      wierzcholek,segmencik:pliczek;
      org_killflaga:flaga;
      org_addflaga:flaga;

  procedure readconfig;
   var linia,cmd,param:string;
       poprzedni:pliczek;
       plik:searchrec;
  begin
   mode:='';
   while mode='' do
     begin
       readln(cfg,linia);
       inc(nr);
       porzadkuj(linia,cmd,param);
       if cmd<>'' then
         begin
           if (cmd='processfiles') or (cmd='processfile') then
             begin
               fsplit(fexpand(param),kat_,nazw_,rozsz_);
               findfirst(param,anyfile,plik);
               while (doserror<>18) and (doserror<>3) do
                 begin
                   if plik.name[1]<>'.' then
                     begin
                       segmencik^.name:=fexpand(kat_+plik.name);
                       poprzedni:=segmencik;
                       new(segmencik);
                       poprzedni^.nastepny:=segmencik;
                       segmencik^.name:='';
                       segmencik^.nastepny:=nil;
                     end;
                   findnext(plik);
                 end;
             end
           else if cmd='createfile' then
             begin
               if outfile<>'nul' then badline;
               if copy(param,length(param)-3,4)='.999' then
                 param:=copy(param,1,length(param)-3)+strday(today);
               if param<>'' then
                 outfile:=fexpand(copy(param,1,length(param)));
             end
           else if cmd='startinfo' then
             begin
               if startfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 startfile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='endinfo' then
             begin
               if endfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 endfile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='pointlist' then
             begin
               if downstr(param)='yes' then pointlist:=true
               else if downstr(param)='no' then pointlist:=false
               else badline;
             end
           else if cmd='forcemode' then
             begin
               if downstr(param)='yes' then force:=true
               else if downstr(param)='no' then force:=false
               else badline;
             end
           else if cmd='usecurrentdate' then
             begin
               if downstr(param)='yes' then curday:=true
               else if downstr(param)='no' then curday:=false
               else badline;
             end
           else if cmd='networkname' then
             begin
               while pos('_',param)<>0 do param[pos('_',param)]:=' ';
               netname:=param+' ';
             end
           else if cmd='addsemicolons' then
             begin
               if downstr(param)='no' then addsemicolon:=0
               else if downstr(param)='yes' then addsemicolon:=1
               else if downstr(param)='auto' then addsemicolon:=2
               else badline;
             end
           else if cmd='killmanyu' then
             begin
               if downstr(param)='yes' then killmanyu:=true
               else if downstr(param)='no' then killmanyu:=false
               else badline;
             end
           else if cmd='killlastu' then
             begin
               if downstr(param)='yes' then killlastu:=true
               else if downstr(param)='no' then killlastu:=false
               else badline;
             end
           else if cmd='sortby' then
             begin
               if downstr(param)='name' then sortby:=1
               else if downstr(param)='ext' then sortby:=2
               else if downstr(param)='no' then sortby:=0
               else badline;
             end
           else if cmd='addflag' then nowaflaga(addflaga,param)
           else if cmd='killflag' then nowaflaga(killflaga,param)
           else if (cmd[1]='[') and (cmd[length(cmd)]=']') then mode:=cmd
           else badline;
         end;
       if eof(cfg) then mode:='[end]';
     end;
  end;

  procedure init;
   var i,j:byte;
       pom:integer;
       parametr,linia:string;
       plik:searchrec;
       ok:boolean;
       atrybut:word;
       rok,mies,dzien,dztyg:word;
       poprzedni:pliczek;

  begin;
   force:=dft_force;
   curday:=dft_curday;
   daynumber:=dft_daynumber;
   text_for:=dft_text_for;
   text_nodelist:=dft_text_nodelist;
   text_pointlist:=dft_text_pointlist;
   pointlist:=false;
   outfile:='nul';
   startfile:='nul';
   endfile:='nul';
   netname:=dft_netname+' ';
   addsemicolon:=dft_addsemicolon;
   killmanyu:=dft_killmanyu;
   killlastu:=dft_killlastu;
   sortby:=0; {0-no,1-name,2-ext}
   org_killflaga:=killflaga;
   org_addflaga:=addflaga;

   new(segmencik);
   wierzcholek:=segmencik;
   segmencik^.nastepny:=nil;
   segmencik^.name:='';

   if withconfig then
     readconfig
   else
     for i:=firstparam to paramcount do
       begin
         parametr:=paramstr(i);
         if (parametr[1]<>'-') and (parametr[1]<>'/') then if parametr[1]='?' then help else badparams(i);
         if upcase(parametr[2])='I' then
           begin
             fsplit(fexpand(copy(parametr,3,length(parametr))),kat_,nazw_,rozsz_);
             findfirst(copy(parametr,3,length(parametr)),anyfile,plik);
             while (doserror<>18) and (doserror<>3) do
               begin
                 if plik.name[1]<>'.' then
                   begin
                     segmencik^.name:=fexpand(kat_+plik.name);
                     poprzedni:=segmencik;
                     new(segmencik);
                     poprzedni^.nastepny:=segmencik;
                     segmencik^.name:='';
                     segmencik^.nastepny:=nil;
                   end;
                 findnext(plik);
               end;
           end
         else if upcase(parametr[2])='S' then
           begin
             if startfile<>'nul' then badparams(i);
             if fsearch(copy(parametr,3,length(parametr)),'')<>'' then
               startfile:=fexpand(copy(parametr,3,length(parametr)))
             else
               begin
                 write('* File ');
                 nazwapliku(fexpand(copy(parametr,3,length(parametr))));
                 writeln(' doesn''t exist!');
                 writeln;
                 halt(2);
               end;
           end
         else if upcase(parametr[2])='E' then
           begin
             if endfile<>'nul' then badparams(i);
             if fsearch(copy(parametr,3,length(parametr)),'')<>'' then
               endfile:=fexpand(copy(parametr,3,length(parametr)))
             else
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
            if copy(parametr,length(parametr)-3,4)='.999' then
              parametr:=copy(parametr,1,length(parametr)-3)+strday(today);
            outfile:=fexpand(copy(parametr,3,length(parametr)));
           end
         else if upcase(parametr[2])='N' then
           begin
            if netname<>dft_netname+' ' then badparams(i);
            netname:=copy(parametr,3,length(parametr))+' ';
            while pos('_',netname)<>0 do netname[pos('_',netname)]:=' ';
           end
         else if upcase(parametr[2])='P' then pointlist:=true
         else if upcase(parametr[2])='D' then curday:=true
         else if upcase(parametr[2])='F' then force:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;


   if netname=' ' then netname:='';

   if segmencik=wierzcholek then
     begin
       writeln('* No segment-files specified!');
       writeln;
       halt;
     end;

   if force then writeln('* Force mode.');

   getdate(rok,mies,dzien,dztyg);

   writeln;

   if outfile='nul' then
     begin
       writeln('* No outfile specified!');
       writeln;
       halt(3);
     end;

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
                           writeln(' n');
                           writeln('* Program aborted.',#32:61);
                           writeln;
                           halt(1);
                         end;
           'y','Y',#13 : begin
                           ok:=true;
                           gotoxy(1,wherey);
                           assign(outlist,outfile);
                           getfattr(outlist,atrybut);
                           setfattr(outlist,0);
                           erase(outlist);
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
           assign(outlist,outfile);
           getfattr(outlist,atrybut);
           setfattr(outlist,0);
           erase(outlist);
           write('* File ');
           nazwapliku(outfile);
           write(' deleted.');
           if atrybut and readonly <> 0 then
             writeln(' (read only!)')
           else
             writeln;
         end;
     end;

   if not pointlist then write('* New nodelist ') else write('* New pointlist ');
   nazwapliku(outfile);
   writeln(' will be created.');

   assign(outlist,outfile);
   rewrite(outlist);

   write(outlist,';A ',netname);
   if not pointlist then
     write(outlist,text_nodelist)
   else
     write(outlist,text_pointlist);
   if curday=true then
     write(outlist,' ',text_for,' ',day[dztyg],', ',dzien,' ',month[mies],' ',rok,', ',daynumber,': ',today);
   writeln(outlist,', CRC: ?????');

   writeln(outlist,';A Created by ',programname);
   writeln(outlist,';A (c) ',progdate,', ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);

   if startfile<>'nul' then
     begin
       write('* Adding start-info...  ');
       writeln(outlist,';');
       addfile(startfile,outlist);
       writeln('Ok');
     end;
  end;


  procedure koniec;
   var crc:word;
       linia:string;
  begin
   writeln(outlist,';');

   if endfile<>'nul' then
     begin
       write('* Adding end-info...  ');
       addfile(endfile,outlist);
       writeln(outlist,';');
       writeln('Ok');
     end;

   addinfoandclose(outlist);

   write('* Calculating CRC...  ');
   crc:=liczcrc(outfile);
   nodecrc(outfile,crc);

   writeln('Ok');
   writeln;

   if not pointlist then write('* Nodelist ') else write('* Pointlist ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(addflaga,org_addflaga);
 end;


  procedure process;
   var linia:string;
       a,b,i,k:byte;
       plik:searchrec;
       files,nodes:longint;
       poprzedni:pliczek;

   procedure sortuj;
    var pom:string[12];
        a,b:byte;
        obracac:boolean;
        segmencik,poprzedni,najmniejszy,aktualny,pop,temp:pliczek;
        plik:string[128];

    function mniejsze(n1,n2:string):boolean;
     var juz,x:boolean;
         i:byte;
         a,b:string[12];
    begin
     fsplit(fexpand(n1),kat_,nazw_,rozsz_);
     a:=nazw_+rozsz_;
     fsplit(fexpand(n2),kat_,nazw_,rozsz_);
     b:=nazw_+rozsz_;

     juz:=false;
     x:=true;
     if sortby=2 then
       begin
         if pos('.',a)=0 then
           a:='   '+copy(a,1,pos('.',a))
         else
           a:=copy(a,pos('.',a)+1,length(a))+copy(a,1,pos('.',a));
         if pos('.',b)=0 then
           b:='   '+copy(b,1,pos('.',b))
         else
           b:=copy(b,pos('.',b)+1,length(b))+copy(b,1,pos('.',b));
       end;
     for i:=1 to 12 do
       if not juz then
         if ord(a[i])<ord(b[i]) then
           juz:=true
         else if ord(a[i])>ord(b[i]) then
           begin
             juz:=true;
             x:=false;
           end;
     mniejsze:=x;
    end;

   begin
     if sortby=1 then write('* Sorting filenames by name...  ');
     if sortby=2 then write('* Sorting filenames by extention...  ');
     obracac:=main.obracac;
     main.obracac:=true;
     write(obracanie[obr]);

     aktualny:=wierzcholek;
     temp:=nil;

     while aktualny^.nastepny<>nil do
       begin
         segmencik:=aktualny^.nastepny;
         plik:=aktualny^.name;
         najmniejszy:=nil;
         poprzedni:=aktualny;
         pop:=nil;

         while segmencik^.nastepny<>nil do
           begin
             if mniejsze(segmencik^.name,plik) then
               begin
                 pop:=poprzedni;
                 najmniejszy:=segmencik;
                 plik:=najmniejszy^.name;
               end;
             poprzedni:=segmencik;
             segmencik:=segmencik^.nastepny;
           end;

         if najmniejszy<>nil then
           begin
             pop^.nastepny:=najmniejszy^.nastepny;
             najmniejszy^.nastepny:=aktualny;
             if temp=nil then wierzcholek:=najmniejszy
             else temp^.nastepny:=najmniejszy;
             temp:=najmniejszy;
           end
         else
           begin
             temp:=aktualny;
             aktualny:=aktualny^.nastepny;
           end;
       end;

     writeln(#8,'Ok');
     main.obracac:=obracac;
   end;


  begin
   files:=0;
   nodes:=0;
   if sortby<>0 then sortuj;
   writeln;

   segmencik:=wierzcholek;

   while segmencik^.nastepny<>nil do
     begin
       writeln('* Adding segment: ',segmencik^.name,'  ');
       writeln;
       assign(inlist,segmencik^.name);
       reset(inlist);
       inc(files);
       while not eof(inlist) do
         begin
           readln(inlist,linia);
           if linia[1]<>';' then
             begin
               a:=pos(',',linia);
               b:=pos(',',copy(linia,a+1,length(linia)))+a;
               if a>1 then linia[1]:=upcase(linia[1]);
               if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
               if (copy(linia,1,a-1)='Zone') or (copy(linia,1,a-1)='Region') or (copy(linia,1,a-1)='Host') then
                 begin
                   writeln(outlist,';');
                   writenode(outlist,linia);
                 end
               else if copy(linia,1,a-1)='Boss' then
                 begin
                   writeln(outlist,';');
                   writenode(outlist,linia);
                   writeln(outlist,';');
                 end
               else
                 writenode(outlist,linia);
               inc(nodes);
             end;
           write('    Files: ');
           textcolor(14); write(files);
           textcolor(7);  write('     Nodes/Points: ');
           textcolor(14); write(nodes);
           textcolor(7);
           gotoxy(1,wherey);
         end;
       write(#32:79);
       gotoxy(1,wherey-1);
       close(inlist);
       segmencik:=segmencik^.nastepny;
     end;

   writeln;
   write('    Files: ');
   textcolor(14); write(files);
   textcolor(7);  write('     Nodes/Points: ');
   textcolor(14); write(nodes);
   textcolor(7);
   gotoxy(1,wherey);
   writeln;
   writeln;

    segmencik:=wierzcholek;
    while segmencik^.nastepny<>nil do
      begin
        poprzedni:=segmencik;
        segmencik:=segmencik^.nastepny;
        dispose(poprzedni);
      end;
    dispose(segmencik);
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Create');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
