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


{----------------------------------------------}
{ œ†czenie nodelisty i pointlisty w jeden plik }
{----------------------------------------------}
unit combine;
{$O+,F+}


interface
 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Combine'':   MNC combines any fido-style nodelist and pointlist do 1 file.');
  writeln;
  writeln('* Usage: MNC Combine -i<name> -p<name> -o<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - nodelist');
  writeln('  -p<name>     - pointlist');
  writeln('  -o<name>     - new nodelist with points');
  writeln('  -s<name>     - text file to add at start of new nodelist');
  writeln('  -e<name>     - text file to add at end of new nodelist');
  writeln('  -n<netname>  - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d           - use current date in nodelist');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  var inlist,inplist,outlist,toadd:text;
      force,curday:boolean;
      infile,inpoint,outfile,startfile,endfile:string;
      netname:string;
      poz:longint;
      org_killflaga:flaga;
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
           if cmd='processnodelist' then
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
           else if cmd='processpointlist' then
             begin
               if inpoint<>'nul' then badline;
               if copy(param,length(param)-3,4)='.999' then
                 param:=copy(param,1,length(param)-3)+plik999(copy(param,1,length(param)-4));
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 inpoint:=fexpand(copy(param,1,length(param)))
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
   text_nwplist:=dft_text_nwplist;
   infile:='nul';
   inpoint:='nul';
   outfile:='nul';
   startfile:='nul';
   endfile:='nul';
   netname:=dft_netname+' ';
   addsemicolon:=dft_addsemicolon;
   killmanyu:=dft_killmanyu;
   killlastu:=dft_killlastu;
   obracac:=true;
   org_killflaga:=killflaga;
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
         else if upcase(parametr[2])='P' then
           begin
             if inpoint<>'nul' then badparams(i);
             if copy(parametr,length(parametr)-3,4)='.999' then
               parametr:=copy(parametr,1,length(parametr)-3)+plik999(copy(parametr,3,length(parametr)-6));
             if fsearch(copy(parametr,3,length(parametr)),'')<>'' then
               inpoint:=fexpand(copy(parametr,3,length(parametr)))
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
            outfile:=fexpand(copy(parametr,3,length(parametr)));
           end
         else if upcase(parametr[2])='N' then
           begin
            if netname<>dft_netname+' ' then badparams(i);
            netname:=copy(parametr,3,length(parametr))+' ';
            while pos('_',netname)<>0 do netname[pos('_',netname)]:=' ';
           end
         else if upcase(parametr[2])='D' then curday:=true
         else if upcase(parametr[2])='F' then force:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;

   if netname=' ' then netname:='';

   if (infile='nul') or (inpoint='nul') or (outfile='nul') or (outfile=infile) or (outfile=inpoint) then
     begin
       writeln('* No required parameter! Nodelist, pointlist and nodelist with points must be specified!');
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

   getdate(rok,mies,dzien,dztyg);

   write('* Nodelist: '); nazwapliku(infile); writeln;
   write('* Pointlist: '); nazwapliku(inpoint); writeln;

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

   write('* Nodelist with points ');
   nazwapliku(outfile);
   writeln(' will be created.');

   assign(inlist,infile);
   assign(inplist,inpoint);
   assign(outlist,outfile);
   reset(inlist);
   reset(inplist);
   rewrite(outlist);

   write(outlist,';A ',netname,text_nwplist);
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

   write('* Nodelist with points ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   close(inlist);
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(addflaga,org_addflaga);
  end;


  procedure process;
   type wezel=^boss;
        boss=record
               zone,net,node:word;
               poz:longint;
               nastepny:wezel;
             end;
   var j,k:word;
       zone,net,node:word;
       a,b,c,d,i:byte;
       linia:string;
       pom:integer;
       p1:word;
       p2,p3,min:longint;
       punkt,wierzcholek,poprzedni:wezel;

   procedure dodaj(zone,net,node:word; poz:longint);
    var poprzedni,nastepny:wezel;
   begin
     punkt:=wierzcholek;
     while punkt^.zone<zone do
       begin poprzedni:=punkt; punkt:=punkt^.nastepny; end;
     while (punkt^.zone=zone) and (punkt^.net<net) do
       begin poprzedni:=punkt; punkt:=punkt^.nastepny; end;
     while (punkt^.zone=zone) and (punkt^.net=net) and (punkt^.node<node) do
       begin poprzedni:=punkt; punkt:=punkt^.nastepny; end;

     punkt:=poprzedni;

     if punkt<>nil then
       begin
         poprzedni:=punkt;
         nastepny:=punkt^.nastepny;
       end
     else
       begin
         poprzedni:=nil;
         nastepny:=nil;
       end;
     new(punkt);
     punkt^.zone:=zone;
     punkt^.net:=net;
     punkt^.node:=node;
     punkt^.poz:=poz;
     punkt^.nastepny:=nastepny;
     if poprzedni<>nil then poprzedni^.nastepny:=punkt;
   end;

   procedure pozycja(pos:longint);
   var linia:string;
   begin
     if poz>pos then
       begin
         close(inplist);
         reset(inplist);
         poz:=0
       end;
     while poz<pos do
       begin
         readln(inplist,linia);
         inc(poz);
       end
   end;

   procedure dopiszpunkty(zone,net,node:word);
   var linia:string;
       a,b,i:byte;
   begin
     punkt:=wierzcholek;
     while (punkt^.zone<zone) and (punkt^.nastepny<>nil) do punkt:=punkt^.nastepny;
     while (punkt^.zone=zone) and (punkt^.net<net) and (punkt^.nastepny<>nil) do punkt:=punkt^.nastepny;
     while (punkt^.zone=zone) and (punkt^.net=net) and (punkt^.node<node) and (punkt^.nastepny<>nil) do punkt:=punkt^.nastepny;
     if (punkt^.zone=zone) and (punkt^.net=net) and (punkt^.node=node) then
       begin
         pozycja(punkt^.poz);
         repeat
           readln(inplist,linia);
           inc(poz);
           if linia[1]=',' then writenode(outlist,'Point'+linia);
         until (downstr(copy(linia,1,4))='boss') or eof(inplist);
       end;
   end;


  begin;
    write('* Combining nodelist and pointlist...  ');
    gotoxy(wherex-1,wherey);
    write(obracanie[obr]);

    new(punkt);
    wierzcholek:=punkt;
    punkt^.zone:=0;
    punkt^.net:=0;
    punkt^.node:=0;
    punkt^.poz:=0;
    punkt^.nastepny:=nil;

    poz:=0;
    while not eof(inplist) do
      begin
        readln(inplist,linia);
        inc(poz);
        if linia[1]<>';' then
          begin
            a:=pos(',',linia);
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
            if (copy(linia,1,a-1)='Boss') then
              begin
                b:=pos(':',linia);
                c:=pos('/',linia);
                d:=pos(',',copy(linia,c+1,length(linia)))+c;
                val(copy(linia,a+1,b-a-1),zone,pom);
                val(copy(linia,b+1,c-b-1),net,pom);
                if d=c then d:=length(linia)+c+1;
                val(copy(linia,c+1,d-c-1),node,pom);
                dodaj(zone,net,node,poz);
              end;
          end;
      end;

    zone:=0;
    net:=0;
    node:=0;

    while not eof(inlist) do
      begin
        readln(inlist,linia);
        if linia[1]<>';' then
          begin
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);

            if copy(linia,1,a-1)='Zone' then
              begin
                val(copy(linia,a+1,b-a-1),zone,pom);
                net:=zone;
                node:=0;
                writeln(outlist,';');
              end
            else if (copy(linia,1,a-1)='Region') or (copy(linia,1,a-1)='Host') then
              begin
                val(copy(linia,a+1,b-a-1),net,pom);
                node:=0;
                writeln(outlist,';');
              end
            else
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
              end;
            writenode(outlist,linia);
            dopiszpunkty(zone,net,node);
          end;
      end;

    punkt:=wierzcholek;
    while punkt^.zone<>0 do
      begin
        poprzedni:=punkt;
        punkt:=punkt^.nastepny;
        dispose(poprzedni);
      end;
    dispose(punkt);

    gotoxy(wherex-1,wherey);
    writeln(' Ok');
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Combine');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
