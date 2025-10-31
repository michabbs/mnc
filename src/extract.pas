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


{---------------------------------}
{ Tworzenie regionalnej nodelisty }
{---------------------------------}
unit extract;
{$O+,F+}


interface

 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Extract'':   MNC extracts regional nodelist from any bigger nodelist.');
  writeln;
  writeln('* Usage: MNC Extract -i<name> -o<name> -r<zone>:<reg> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>       - nodelist');
  writeln('  -o<name>       - regional nodelist');
  writeln('  -r<zone>:<reg> - region  (You can specify more than one ''-r'' paramater.)');
  writeln('  -s<name>       - text file to add at start of regional nodelist');
  writeln('  -e<name>       - text file to add at end of regional nodelist');
  writeln('  -n<netname>    - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d             - use current date in nodelist');
  writeln('  -c             - coordinators only');
  writeln('  -f             - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  var nodelist,regionlist,toadd:text;
      force,allnodes,curday:boolean;
      infile,outfile,startfile,endfile,netname:string;
      totalnodes,regionnodes:longint;
      zone,region:array[1..50] of word;
      licznik:byte;
      coord,withhubs:boolean;
      coordonly:byte; {0 - No, 1 - NoHubs, 2 - Yes, 3 - Hubs}
      c_hub:string;
      org_killflaga,org_coordflaga:flaga;
      org_addflaga:flaga;

  procedure readconfig;
   var linia,cmd,param:string;
       j:byte;
       pom:integer;
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
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 infile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='createfile' then
             begin
               if outfile<>'nul' then badline;
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
           else if cmd='coordinatorsonly' then
             begin
               if downstr(param)='no' then coordonly:=0
               else if (downstr(param)='nohub') or (downstr(param)='nohubs') then coordonly:=1
               else if downstr(param)='yes' then coordonly:=2
               else if (downstr(param)='hub') or (downstr(param)='hubs') then coordonly:=3
               else badline;
             end
           else if cmd='coordinatorflag' then nowaflaga(coordflaga,param)
           else if cmd='region' then
             begin
               j:=pos(':',param);
               if (j=0) or (j=length(param)) or (j=1) then badline;
               if licznik>49 then
                 begin
                   writeln('* Too many regions!');
                   writeln;
                   halt;
                 end;
               inc(licznik);
               val(copy(param,1,j-1),zone[licznik],pom);
               val(copy(param,j+1,length(param)),region[licznik],pom);
               if (zone[licznik]=0) and (zone[licznik]=0) then allnodes:=true;
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
           else if cmd='killflag' then nowaflaga(killflaga,param)
           else if cmd='addflag' then nowaflaga(addflaga,param)
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
  begin
   force:=dft_force;
   curday:=dft_curday;
   daynumber:=dft_daynumber;
   text_for:=dft_text_for;
   text_nodelist:=dft_text_nodelist;
   allnodes:=false;
   outfile:='nul';
   infile:='nul';
   startfile:='nul';
   endfile:='nul';
   licznik:=0;
   if dft_netname='' then dft_netname:='Regional';
   netname:=dft_netname+' ';
   coordonly:=0;
   c_hub:='';
   addsemicolon:=dft_addsemicolon;
   killmanyu:=dft_killmanyu;
   killlastu:=dft_killlastu;
   obracac:=true;
   org_killflaga:=killflaga;
   org_coordflaga:=coordflaga;
   org_addflaga:=addflaga;

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
         else if upcase(parametr[2])='N' then
           begin
            if netname<>dft_netname+' ' then badparams(i);
            netname:=copy(parametr,3,length(parametr))+' ';
            while pos('_',netname)<>0 do netname[pos('_',netname)]:=' ';
           end
         else if upcase(parametr[2])='D' then curday:=true
         else if upcase(parametr[2])='C' then coordonly:=2
         else if upcase(parametr[2])='F' then force:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else if upcase(parametr[2])='R' then
           begin
             j:=pos(':',parametr);
             if (j=0) or (j=length(parametr)) or (j=3) then badparams(i);
             if licznik>49 then
               begin
                 writeln('* Too many parameters!');
                 writeln;
                 halt;
               end;
             inc(licznik);
             val(copy(parametr,3,j-3),zone[licznik],pom);
             val(copy(parametr,j+1,length(parametr)),region[licznik],pom);
             if (zone[licznik]=0) and (zone[licznik]=0) then allnodes:=true;
           end
         else badparams(i);
       end;


   if licznik=0 then
     begin
       writeln('* No region specified!');
       writeln;
       halt;
     end;

   fsplit(fexpand(outfile),kat_,nazw_,rozsz_);
   if rozsz_='.999' then
     begin
       outfile:=kat_+nazw_;
       fsplit(fexpand(infile),kat_,nazw_,rozsz_);
       outfile:=outfile+rozsz_;
     end;

   if force then writeln('* Force mode.');

   if coordonly=3 then
     begin
       writeln('* Coordinators with hubs.');
       if netname='Regional ' then netname:='Regional Coordinators With Hubs ';
     end;
   if coordonly=2 then
     begin
       writeln('* Coordinators only.');
       if netname='Regional ' then netname:='Regional Coordinators Only ';
     end;
   if coordonly=1 then
     begin
       writeln('* Coordinators without hubs.');
       if netname='Regional ' then netname:='Regional Coordinators Without Hubs ';
     end;

   if curday then
     begin
       getdate(rok,mies,dzien,dztyg);
       write('* Current date will be used. (');
       textcolor(2);
       write(day[dztyg],', ',dzien,' ',month[mies],' ',rok);
       textcolor(7);
       writeln(')');
     end;

   write('* Old nodelist: ');
   nazwapliku(infile);
   writeln;
   write('* Regional nodelist ');
   nazwapliku(outfile);
   writeln(' will be created.');

   if not force then
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
                           assign(regionlist,outfile);
                           getfattr(regionlist,atrybut);
                           setfattr(regionlist,0);
                           erase(regionlist);
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
           assign(regionlist,outfile);
           getfattr(regionlist,atrybut);
           setfattr(regionlist,0);
           erase(regionlist);
           write('* File ');
           nazwapliku(outfile);
           write(' deleted.');
           if atrybut and readonly <> 0 then
             writeln(' (read only!)')
           else
             writeln;
         end;
     end;

   if outfile='nul' then
     begin
       writeln('* No outfile specified!');
       writeln;
       halt(3);
     end;

   if startfile<>'nul' then
     begin
       write('* File ');
       nazwapliku(startfile);
       writeln(' will be added at start.');
     end;

   if endfile<>'nul' then
     begin
       write('* File ');
       nazwapliku(endfile);
       writeln(' will be added at end.');
     end;

   assign(nodelist,infile);
   assign(regionlist,outfile);
   reset(nodelist);
   rewrite(regionlist);

   fsplit(infile,kat_,nazw_,rozsz_);
   write(regionlist,';A ',netname,text_nodelist);
   if curday then write(regionlist,' ',text_for,' ',day[dztyg],', ',dzien,' ',month[mies],' ',rok,', ',daynumber,': ',today);
   writeln(regionlist,', CRC: ?????');
   writeln(regionlist,';A Extracted from ''',nazw_+rozsz_,''' by ',programname);
   writeln(regionlist,';A (c) ',progdate,' ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);
   writeln(regionlist,';');
   writeln;

   if startfile<>'nul' then
     begin
       write('* Adding start-info...  ');
       addfile(startfile,regionlist);
       writeln(regionlist,';');
       writeln('Ok');
     end;

   totalnodes:=0;
   regionnodes:=0;
  end;


  function regionok(z,r:word):boolean;
   var i:byte;
       pom:boolean;
  begin
    pom:=false;
    for i:=1 to licznik do
      if (((region[i]=r) or (region[i]=0)) and (zone[i]=z)) or allnodes then pom:=true;
    regionok:=pom;
  end;


  function zoneok(a:word):boolean;
   var i:byte;
       pom:boolean;
  begin
    pom:=false;
    for i:=1 to licznik do
      if (zone[i]=a) or allnodes then pom:=true;
    zoneok:=pom;
  end;


  function checkcoord(linia:string):boolean;
   var a,b,i:byte;
  begin
   if coordonly<>0 then
     begin
       a:=pos(',',linia);
       b:=pos(',',copy(linia,a+1,length(linia)))+a;
       if a>1 then linia[1]:=upcase(linia[1]);
       if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
       if (copy(linia,1,a-1)='Host') then
         begin
           checkcoord:=true;
           c_hub:='';
         end
       else if (copy(linia,1,a-1)='Hub') then
         begin
           if coordonly=3 then
             checkcoord:=true
           else
             begin
               checkcoord:=false;
               c_hub:=linia;
               if coordinator(linia) then
                 begin
                   checkcoord:=true;
                   c_hub:='';
                 end;
             end;
         end
       else
         if coordinator(linia) then
           begin
             if (c_hub<>linia) and (c_hub<>'') and (coordonly<>0) and (coordonly<>1) then writenode(regionlist,c_hub);
             checkcoord:=true;
           end
       else
         checkcoord:=false
     end
   else
     checkcoord:=true;
  end;


  procedure process;
   var linia:string;
       strefa:word;
       pom:integer;
       a,b,i:byte;
       czytaj,srednik:boolean;

   procedure piszstrefe(var linia:string);
    var koniecstrefy,pisac,czytaj:boolean;
        a,b,i:byte;
        pom:integer;
        reg:word;

    procedure piszregion(var linia:string);
     var juz,odstep:boolean;
         a,b,i:byte;
    begin
     if srednik then
       begin
         writeln(regionlist,';');
         srednik:=false;
       end;

     writenode(regionlist,linia);

     odstep:=true;
     juz:=true;
     while (not eof(nodelist)) and juz do
       begin
         readln(nodelist,linia);
         a:=pos(',',linia);
         b:=pos(',',copy(linia,a+1,length(linia)))+a;
         if a>1 then linia[1]:=upcase(linia[1]);
         if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
         if (copy(linia,1,a-1)='Region') or (copy(linia,1,a-1)='Zone') then
           juz:=false
         else
           if (linia[1]<>';') then
             if checkcoord(linia) then
               begin
                 writenode(regionlist,linia);
                 odstep:=true;
               end
             else
           else
             begin
               if odstep then writeln(regionlist,';');
               odstep:=false;
             end;
       end;
    end;

   begin
    writenode(regionlist,linia);
    koniecstrefy:=true;

    czytaj:=true;
    pisac:=true;
    while (not eof(nodelist)) and koniecstrefy do
      begin
        if czytaj then
          readln(nodelist,linia)
        else
          czytaj:=true;

        if linia[1]<>';' then
          begin
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
            if copy(linia,1,a-1)='Region' then
              begin
                pisac:=false;
                val(copy(linia,a+1,b-a-1),reg,pom);
                if regionok(strefa,reg) then
                  begin
                    piszregion(linia);
                    czytaj:=false;
                  end;
              end
            else if copy(linia,1,a-1)='Zone' then koniecstrefy:=false
            else if pisac and checkcoord(linia) then writenode(regionlist,linia);
          end;

      end;
   end;

  begin
   write('* Extracting nodes...  ');
   gotoxy(wherex-1,wherey);
   write(obracanie[obr]);

   czytaj:=true;
   srednik:=false;
   while not eof(nodelist) do
     begin
       if czytaj then
         readln(nodelist,linia)
       else
         czytaj:=true;

       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if copy(linia,1,a-1)='Zone' then
             begin
               val(copy(linia,a+1,b-a-1),strefa,pom);
               if zoneok(strefa) then
                 begin
                   if srednik then writeln(regionlist,';');
                   srednik:=true;
                   piszstrefe(linia);
                   czytaj:=false;
                 end;
             end;
         end;
     end;
   if srednik then writeln(regionlist,';');

   gotoxy(wherex-1,wherey);
   writeln(' Ok');
  end;


  procedure koniec;
   var crc:word;
       linia:string;
  begin
   close(nodelist);

   if endfile<>'nul' then
     begin
       write('* Adding end-info...  ');
       addfile(endfile,regionlist);
       writeln(regionlist,';');
       writeln('Ok');
     end;

   addinfoandclose(regionlist);

   write('* Calculating CRC...  ');
   crc:=liczcrc(outfile);
   nodecrc(outfile,crc);

   writeln('Ok');
   writeln;
   write('* Regional nodelist ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(coordflaga,org_coordflaga);
   usunstare(addflaga,org_addflaga);
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Extract');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
