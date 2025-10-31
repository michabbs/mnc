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


{----------------------}
{ Sortowanie nodelisty }
{----------------------}
unit sort;
{$O+,F+}


interface
 uses dos,crt,main,crc,tpxms;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Sort'':   MNC sorts any fido-style nodelist. XMS required.');
  writeln;
  writeln('* Usage: MNC Sort -i<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - old nodelist');
  writeln('  -o<name>     - new nodelist');
  writeln('  -s<name>     - text file to add at start of new nodelist');
  writeln('  -e<name>     - text file to add at end of new nodelist');
  writeln('  -n<netname>  - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d           - use current date in nodelist');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  type wezel=^boss;
       boss=record
              nr:word;
              poz,next:longint;
              nastepny:wezel;
            end;

  var inlist,outlist,toadd:text;
      killold,force,curday:boolean;
      infile,outfile,startfile,endfile:string;
      netname:string;
      totalnodes,maxlength:longint;
      handle:word;
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
   infile:='nul';
   outfile:='nul';
   startfile:='nul';
   endfile:='nul';
   netname:=dft_netname+' ';
   killold:=false;
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

   if infile='nul' then
     begin
       writeln('* No infile(s) specified!');
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

   write('* Old nodelist: ');
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
           write('old nodelist [Y/n] ?');
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
       write('* Old nodelist temporary ranamed to ');
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

   write('* New nodelist ');
   nazwapliku(outfile);
   writeln(' will be created.');

   assign(inlist,infile);
   assign(outlist,outfile);
   rewrite(outlist);

   write(outlist,';A ',netname,text_nodelist);
   if curday=true then
     write(outlist,' ',text_for,' ',day[dztyg],', ',dzien,' ',month[mies],' ',rok,', ',daynumber,': ',today);
   writeln(outlist,', CRC: ?????');

   writeln(outlist,';A Created by ',programname);
   writeln(outlist,';A (c) ',progdate,' ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);

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

   write('* Nodelist ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   if killold then
     begin
       erase(inlist);
       writeln('* Old nodelist deleted.');
     end;
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(addflaga,org_addflaga);
  end;


  procedure sort(var wierzcholek:wezel);
   var nodes,poprzedni,najmniejszy,aktualny,pop,temp:wezel;
       nr:word;
  begin
    obroc;
    aktualny:=wierzcholek;
    temp:=nil;

    while aktualny^.nr<>0 do
      begin
        nodes:=aktualny^.nastepny;
        nr:=aktualny^.nr;
        najmniejszy:=nil;
        poprzedni:=aktualny;
        pop:=nil;

        while nodes^.nr<>0 do
          begin
            if nodes^.nr<nr then
              begin
                pop:=poprzedni;
                najmniejszy:=nodes;
                nr:=najmniejszy^.nr;
              end;
            poprzedni:=nodes;
            nodes:=nodes^.nastepny;
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
  end;


  procedure czytajplik;
   var plik:file;
       bufor:array[0..255] of byte;
       wynik:word;
       linia:string;
       i:longint;
  begin
   write('* Analyzing nodelist...  ');
   obroc;
   reset(inlist);
   totalnodes:=0;
   maxlength:=0;
   while not eof(inlist) do
     begin
       readln(inlist,linia);
       if linia[1]<>';' then
         begin
           inc(totalnodes);
           if length(linia)>maxlength then maxlength:=length(linia);
         end;
       obroc;
     end;
   close(inlist);
   inc(maxlength);
   gotoxy(wherex-1,wherey);
   writeln(' ',totalnodes,' nodes');

   handle:=AllocExtMemBlockXMS(((totalnodes*maxlength) div 1024)+1);
   if xmsresult=0 then
     begin
       writeln('* XMS not available! (required: ',((totalnodes*maxlength) div 1024)+1,'kB)');
       halt(1);
     end
   else
     writeln('* ',((totalnodes*maxlength) div 1024)+1,'kB of XMS allocated.');

   write('* Moving nodelist into memory...  ');
   obroc;
   reset(inlist);
   for i:=1 to totalnodes do
     begin
       repeat
         readln(inlist,linia);
       until linia[1]<>';';
       przenies.length:=maxlength;
       przenies.sourcehandle:=0;
       przenies.sourceoffset:=seg(linia)*65536+ofs(linia);
       przenies.desthandle:=handle;
       przenies.destoffset:=(i-1)*maxlength;
       MoveExtMemBlockXMS(przenies);
       obroc;
     end;
   close(inlist);
   gotoxy(wherex-1,wherey);
   writeln(' Ok');
  end;


  function readline(poz:longint):string;
   var i:longint;
       linia:string;
  begin
   przenies.length:=maxlength;
   przenies.sourcehandle:=handle;
   przenies.sourceoffset:=(poz-1)*maxlength;
   przenies.desthandle:=0;
   przenies.destoffset:=seg(linia)*65536+ofs(linia);
   MoveExtMemBlockXMS(przenies);
   readline:=linia;
  end;


  procedure piszpunkt(pos:longint);
   var linia:string;
  begin
   writenode(outlist,readline(pos));
  end;


  procedure sortujwezly(startpos,endpos:longint; pisz:boolean);
   var linia:string;
       a,b,i:byte;
       pom:integer;
       j:longint;
       nodes,wierzcholek,poprzedni:wezel;
  begin
   if pisz then
     writenode(outlist,readline(startpos))
   else
     dec(startpos);

   new(nodes);
   wierzcholek:=nodes;
   poprzedni:=nil;
   nodes^.nr:=0;
   nodes^.poz:=0;
   nodes^.next:=0;

   for j:=startpos+1 to endpos do
     begin
       linia:=readline(j);
       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           nodes^.poz:=j;
           val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
           poprzedni:=nodes;
           new(nodes);
           poprzedni^.nastepny:=nodes;
           nodes^.nr:=0;
           nodes^.poz:=0;
           nodes^.next:=0;
         end;
     end;

    if wierzcholek^.nr<>0 then
      begin
        sort(wierzcholek);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            piszpunkt(nodes^.poz);
            nodes:=nodes^.nastepny;
          end;
      end;

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure sortujhub(startpos,endpos:longint; pisz:boolean);
   var linia:string;
       a,b,i:byte;
       pom:integer;
       min,j:longint;
       nodes,wierzcholek,poprzedni:wezel;
  begin
   if pisz then
     writenode(outlist,readline(startpos))
   else
     dec(startpos);

   new(nodes);
   wierzcholek:=nodes;
   poprzedni:=nil;
   nodes^.nr:=0;
   nodes^.poz:=0;
   nodes^.next:=0;

   for j:=startpos+1 to endpos do
     begin
       linia:=readline(j);
       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if (copy(linia,1,a-1)<>'Point') then
             begin
               nodes^.poz:=j;
               if poprzedni<>nil then poprzedni^.next:=j-1;
               val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
               poprzedni:=nodes;
               new(nodes);
               poprzedni^.nastepny:=nodes;
               nodes^.nr:=0;
               nodes^.poz:=0;
               nodes^.next:=0;
             end;
         end;
     end;

    if wierzcholek^.nr<>0 then
      begin
        poprzedni^.next:=endpos;
        min:=wierzcholek^.poz-1;
        sort(wierzcholek);

        if startpos+1<=min then
          sortujwezly(startpos+1,min,false);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            sortujwezly(nodes^.poz,nodes^.next,true);
            nodes:=nodes^.nastepny;
          end;
      end
   else
     sortujwezly(startpos+1,endpos,false);

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure sortujnet(startpos,endpos:longint);
   var linia:string;
       a,b,i:byte;
       pom:integer;
       min,j:longint;
       nodes,wierzcholek,poprzedni:wezel;
  begin
   linia:=readline(startpos);
   writeln(outlist,';');
   writenode(outlist,linia);

   new(nodes);
   wierzcholek:=nodes;
   poprzedni:=nil;
   nodes^.nr:=0;
   nodes^.poz:=0;
   nodes^.next:=0;

   for j:=startpos+1 to endpos do
     begin
       linia:=readline(j);
       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if (copy(linia,1,a-1)='Hub') then
             begin
               nodes^.poz:=j;
               if poprzedni<>nil then poprzedni^.next:=j-1;
               val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
               poprzedni:=nodes;
               new(nodes);
               poprzedni^.nastepny:=nodes;
               nodes^.nr:=0;
               nodes^.poz:=0;
               nodes^.next:=0;
             end;
         end;
     end;

    if wierzcholek^.nr<>0 then
      begin
        poprzedni^.next:=endpos;
        min:=wierzcholek^.poz-1;
        sort(wierzcholek);

        if startpos+1<=min then
          sortujhub(startpos+1,min,false);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            sortujhub(nodes^.poz,nodes^.next,true);
            nodes:=nodes^.nastepny;
          end;
      end
   else
     sortujhub(startpos+1,endpos,false);

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure sortujregion(startpos,endpos:longint);
   var linia:string;
       a,b,i:byte;
       pom:integer;
       min,j:longint;
       nodes,wierzcholek,poprzedni:wezel;
  begin
   linia:=readline(startpos);
   writeln(outlist,';');
   writenode(outlist,linia);

   new(nodes);
   wierzcholek:=nodes;
   poprzedni:=nil;
   nodes^.nr:=0;
   nodes^.poz:=0;
   nodes^.next:=0;

   for j:=startpos+1 to endpos do
     begin
       linia:=readline(j);
       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if (copy(linia,1,a-1)='Host') then
             begin
               nodes^.poz:=j;
               if poprzedni<>nil then poprzedni^.next:=j-1;
               val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
               poprzedni:=nodes;
               new(nodes);
               poprzedni^.nastepny:=nodes;
               nodes^.nr:=0;
               nodes^.poz:=0;
               nodes^.next:=0;
             end;
         end;
     end;

    if wierzcholek^.nr<>0 then
      begin
        poprzedni^.next:=endpos;
        min:=wierzcholek^.poz-1;
        sort(wierzcholek);

        if startpos+1<=min then
          sortujhub(startpos+1,min,false);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            sortujnet(nodes^.poz,nodes^.next);
            nodes:=nodes^.nastepny;
          end;
      end
   else
     sortujhub(startpos+1,endpos,false);

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure sortujstrefe(startpos,endpos:longint);
   var linia:string;
       a,b,i:byte;
       pom:integer;
       min,j:longint;
       nodes,wierzcholek,poprzedni:wezel;
  begin
   linia:=readline(startpos);
   writeln(outlist,';');
   writenode(outlist,linia);

   new(nodes);
   wierzcholek:=nodes;
   poprzedni:=nil;
   nodes^.nr:=0;
   nodes^.poz:=0;
   nodes^.next:=0;

   for j:=startpos+1 to endpos do
     begin
       linia:=readline(j);
       if linia[1]<>';' then
         begin
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if (copy(linia,1,a-1)='Region') then
             begin
               nodes^.poz:=j;
               if poprzedni<>nil then poprzedni^.next:=j-1;
               val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
               poprzedni:=nodes;
               new(nodes);
               poprzedni^.nastepny:=nodes;
               nodes^.nr:=0;
               nodes^.poz:=0;
               nodes^.next:=0;
             end;
         end;
     end;

    if wierzcholek^.nr<>0 then
      begin
        poprzedni^.next:=endpos;
        min:=wierzcholek^.poz-1;
        sort(wierzcholek);

        if startpos+1<=min then
          sortujhub(startpos+1,min,false);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            sortujregion(nodes^.poz,nodes^.next);
            nodes:=nodes^.nastepny;
          end;
      end
   else
     sortujhub(startpos+1,endpos,false);

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure process;
   var a,b,i:byte;
       linia:string;
       pom:integer;
       nodes,wierzcholek,poprzedni:wezel;
       j:longint;
  begin
    writeln;
    czytajplik;

    write('* Creating new nodelist...  ');
    gotoxy(wherex-1,wherey);
    write(obracanie[obr]);

    new(nodes);
    wierzcholek:=nodes;
    poprzedni:=nil;
    nodes^.nr:=0;
    nodes^.poz:=0;
    nodes^.next:=0;

    for j:=1 to totalnodes do
      begin
        linia:=readline(j);
        if linia[1]<>';' then
          begin
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
            if (copy(linia,1,a-1)='Zone') then
              begin
                nodes^.poz:=j;
                if poprzedni<>nil then poprzedni^.next:=j-1;
                val(copy(linia,a+1,b-a-1),nodes^.nr,pom);
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nr:=0;
                nodes^.poz:=0;
                nodes^.next:=0;
              end;
          end;
      end;

    if wierzcholek^.nr<>0 then
      begin
        poprzedni^.next:=totalnodes;
        sort(wierzcholek);

        nodes:=wierzcholek;
        while nodes^.nr<>0 do
          begin
            sortujstrefe(nodes^.poz,nodes^.next);
            nodes:=nodes^.nastepny;
          end;
      end;

    nodes:=wierzcholek;
    while nodes^.nr<>0 do
      begin
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);

    FreeExtMemBlockXMS(handle);

    gotoxy(wherex-1,wherey);
    writeln(' Ok');
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Sort');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
