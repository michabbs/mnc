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


{-------------------------}
{ Reorganizacja nodelisty }
{-------------------------}
unit remake;
{$O+,F+}


interface
 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Remake'':   MNC recreates any fido-style nodelist or pointlist.');
  writeln;
  writeln('* Usage: MNC Remake -i<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - nodelist/pointlist');
  writeln('  -o<name>     - new nodelist/pointlist');
  writeln('  -s<name>     - text file to add at start of new nodelist/pointlist');
  writeln('  -e<name>     - text file to add at end of new nodelist/pointlist');
  writeln('  -n<netname>  - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d           - use current date in nodelist/pointlist');
  writeln('  -p           - pointlist will be processed (default nodelist)');
  writeln('  -c           - coordinators only');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  var inlist,outlist,toadd:text;
      killold,force,curday,pointlist:boolean;
      infile,outfile,startfile,endfile:string;
      netname:string;
      coordonly:byte; {0 - No, 1 - NoHubs, 2 - Yes, 3 - Hubs}
      c_hub:string;
      org_killflaga,org_coordflaga:flaga;
      org_addflaga:flaga;

  procedure readconfig;
   var linia,cmd,param:string;
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
           else if cmd='coordinatorsonly' then
             begin
               if downstr(param)='no' then coordonly:=0
               else if (downstr(param)='nohub') or (downstr(param)='nohubs') then coordonly:=1
               else if downstr(param)='yes' then coordonly:=2
               else if (downstr(param)='hub') or (downstr(param)='hubs') then coordonly:=3
               else badline;
             end
           else if cmd='coordinatorflag' then nowaflaga(coordflaga,param)
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
  begin;
   force:=dft_force;
   curday:=dft_curday;
   daynumber:=dft_daynumber;
   text_for:=dft_text_for;
   text_nodelist:=dft_text_nodelist;
   text_pointlist:=dft_text_pointlist;
   pointlist:=false;
   infile:='nul';
   outfile:='nul';
   startfile:='nul';
   endfile:='nul';
   netname:=dft_netname+' ';
   killold:=false;
   coordonly:=0;
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
         else if upcase(parametr[2])='C' then coordonly:=2
         else if upcase(parametr[2])='D' then curday:=true
         else if upcase(parametr[2])='F' then force:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;


   if netname=' ' then netname:='';

   if infile='nul' then
     begin
       writeln('* No infile(s) specified!');
       writeln;
       halt;
     end;

   if force then writeln('* Force mode.');

   if coordonly=3 then
     begin
       writeln('* Coordinators with hubs.');
       if netname='' then netname:='Coordinators With Hubs ';
     end;
   if coordonly=2 then
     begin
       writeln('* Coordinators only.');
       if netname='' then netname:='Coordinators Only ';
     end;
   if coordonly=1 then
     begin
       writeln('* Coordinators without hubs.');
       if netname='' then netname:='Coordinators Without Hubs ';
     end;

   getdate(rok,mies,dzien,dztyg);

   if not pointlist then write('* Old nodelist: ') else write('* Old pointlist: ');
   nazwapliku(infile);
   writeln;

   if (outfile='nul') or (outfile=infile) then
     begin
       assign(inlist,infile);
       outfile:=infile;
       infile:='00000000.MNC';
       repeat
         for i:=1 to 8 do infile[i]:=chr(random(9)+48);
       until fsearch(infile,'')='';
       if not force then
         begin
           write('* Overwrite ');
           if not pointlist then write('old nodelist') else write('old pointlist');
           write(' [Y/n] ?');
           ok:=false;
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
                           end;
           end;
         end;
       rename(inlist,infile);
       if not pointlist then write('* Old nodelist') else write('* Old pointlist');
       write(' temporary ranamed to ');
       nazwapliku(infile);
       writeln('.');
       killold:=true;
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

   assign(inlist,infile);
   assign(outlist,outfile);
   reset(inlist);
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
   writeln(outlist,';A (c) ',progdate,' ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);
   writeln;

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
   close(inlist);
   if killold then
     begin
       erase(inlist);
       if not pointlist then writeln('* Old nodelist deleted.') else writeln('* Old pointlist deleted.');
     end;
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(coordflaga,org_coordflaga);
   usunstare(addflaga,org_addflaga);
 end;


  procedure process;
   var linia:string;
       a,b,i:byte;

   procedure checkcoord;
   begin
     if coordinator(linia) then
       begin
         if (c_hub<>linia) and (c_hub<>'') and (coordonly<>3) and (coordonly<>1) then writenode(outlist,c_hub);
         writenode(outlist,linia);
         c_hub:='';
       end;
   end;

  begin
   if not pointlist then write('* Creating new nodelist...  ') else write('* Creating new pointlist...  ');

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
               c_hub:='';
               writeln(outlist,';');
               writenode(outlist,linia);
             end
           else if copy(linia,1,a-1)='Hub' then
             begin
               c_hub:=linia;
               if (coordonly=0) or (coordonly=3) then
                 begin
                   writenode(outlist,linia);
                   c_hub:='';
                 end
               else
                 checkcoord;
             end
           else if copy(linia,1,a-1)='Boss' then
             begin
               writeln(outlist,';');
               writenode(outlist,linia);
               writeln(outlist,';');
             end
           else if coordonly<>0 then
             checkcoord
           else
             writenode(outlist,linia);
         end;
     end;

   gotoxy(wherex-1,wherey);
   writeln(' Ok');
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Remake');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
