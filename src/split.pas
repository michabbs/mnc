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


{-------------------------------------------------------------------}
{ Konwersja nodelisty z punktami na odzieln† nodelist‘ i pointlist‘ }
{-------------------------------------------------------------------}
unit split;
{$O+,F+}


interface

 uses dos,crt,main,crc;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Split'':   MNC converts fido-style nodelist(s) with points to separate');
  writeln('                  nodelist and unsorted pointlist.');
  writeln;
  writeln('* Usage: MNC Split -i<name> [-i...] -o<name> -p<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - nodelist with points');
  writeln('  -o<name>     - new nodelist');
  writeln('  -p<name>     - new pointlist');
  writeln('  -n<netname>  - name of your network (i.e. ''FidoNet_Region_48'')');
  writeln('  -d           - use current date in nodelist and pointlist');
  writeln('  -f           - force mode');
  writeln('  -s           - speed mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  type pliczek=^nazwa_pliku;
       nazwa_pliku=record
                     name:string[128];
                     nastepny:pliczek;
                   end;

  var zone,net,node:string;               {adres przetwarzanego w‘z’a}
      wejscie,nodelist,pointlist,toadd:text;
      linia:string;                       {aktualnie przetwarzana linia wejsciowa}
      czypisac:boolean;                   {czy zapisa‡ lini‘ komentarza?}
      a,b:byte;                           {pozycje przecink¢w w linii wejžciowej}
      bylboss:boolean;                    {czy boss ju§ by’ w poitližcie?}
      zones,regions,nets,nodes,points:longint;  {ilož‡ przetworzonych w‘z’¢w itp.}
      nodefile,pointfile,netname:string;
      nstartfile,nendfile,pstartfile,pendfile:string;
      quiet:boolean;
      force,curday:boolean;
      wierzcholek,segmencik,poprzedni:pliczek;
      pliknr:word;
      org_killflaga:flaga;
      org_addflaga:flaga;

  procedure readconfig;
   var linia,cmd,param:string;
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
           if cmd='processfile' then
             begin
               if copy(param,length(param)-3,4)='.999' then
                 param:=copy(param,1,length(param)-3)+plik999(copy(param,1,length(param)-4));
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 begin
                   segmencik^.name:=fexpand(copy(param,1,length(param)));
                   poprzedni:=segmencik;
                   new(segmencik);
                   poprzedni^.nastepny:=segmencik;
                   segmencik^.name:='';
                   segmencik^.nastepny:=nil;
                 end
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='createnodelist' then
             begin
               if nodefile<>'nul' then badline;
               if param<>'' then
                 nodefile:=fexpand(copy(param,1,length(param)));
             end
           else if cmd='createpointlist' then
             begin
               if pointfile<>'nul' then badline;
               if param<>'' then
                 pointfile:=fexpand(copy(param,1,length(param)));
             end
           else if cmd='nodeliststartinfo' then
             begin
               if nstartfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 nstartfile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='nodelistendinfo' then
             begin
               if nendfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 nendfile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='pointliststartinfo' then
             begin
               if pstartfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 pstartfile:=fexpand(copy(param,1,length(param)))
               else
                 begin
                   write('* File ');
                   nazwapliku(fexpand(copy(param,1,length(param))));
                   writeln(' doesn''t exist!');
                   writeln;
                   halt(2);
                 end;
             end
           else if cmd='pointlistendinfo' then
             begin
               if pendfile<>'nul' then badline;
               if fsearch(copy(param,1,length(param)),'')<>'' then
                 pendfile:=fexpand(copy(param,1,length(param)))
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
           else if cmd='speedmode' then
             begin
               if downstr(param)='yes' then quiet:=true
               else if downstr(param)='no' then quiet:=false
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


  procedure zmienne;                  {pocz†tkowe wartožci zmiennych}
  begin
   czypisac:=true;
   bylboss:=false;
   zone:='0';
   net:='0';
   node:='0';
   zones:=0;
   regions:=0;
   nets:=0;
   nodes:=0;
   points:=0;
   pliknr:=0;
  end;


  procedure init;
   var i,j:byte;
       parametr:string;
       znak:char;
       ok,odstep:boolean;
       plik:searchrec;           {pomocnicza nazwa pliku przy szukaniu}
       atrybut:word;
       rok,mies,dzien,dztyg:word;
  begin
   quiet:=dft_quiet;
   curday:=dft_curday;
   daynumber:=dft_daynumber;
   text_for:=dft_text_for;
   text_nodelist:=dft_text_nodelist;
   text_pointlist:=dft_text_pointlist;
   netname:=dft_netname+' ';
   nodefile:='nul';
   pointfile:='nul';
   nstartfile:='nul';
   nendfile:='nul';
   pstartfile:='nul';
   pendfile:='nul';
   force:=dft_force;
   addsemicolon:=dft_addsemicolon;
   killmanyu:=dft_killmanyu;
   killlastu:=dft_killlastu;
   obracac:=false;
   org_killflaga:=killflaga;
   org_addflaga:=addflaga;

   new(segmencik);
   wierzcholek:=segmencik;
   segmencik^.name:='';
   segmencik^.nastepny:=nil;

   if withconfig then
     readconfig
   else
     for i:=firstparam to paramcount do
       begin
         parametr:=paramstr(i);
         if (parametr[1]<>'-') and (parametr[1]<>'/') then if parametr[1]='?' then help else badparams(i);
         if upcase(parametr[2])='I' then
             begin
               if copy(parametr,length(parametr)-3,4)='.999' then
                 parametr:=copy(parametr,1,length(parametr)-3)+plik999(copy(parametr,3,length(parametr)-6));
               if fsearch(copy(parametr,3,length(parametr)),'')<>'' then
                 begin
                   segmencik^.name:=fexpand(copy(parametr,3,length(parametr)));
                   poprzedni:=segmencik;
                   new(segmencik);
                   poprzedni^.nastepny:=segmencik;
                   segmencik^.name:='';
                   segmencik^.nastepny:=nil;
                 end
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
            if nodefile<>'nul' then badparams(i);
            nodefile:=fexpand(copy(parametr,3,length(parametr)));
           end
         else if upcase(parametr[2])='P' then
           begin
            if pointfile<>'nul' then badparams(i);
            pointfile:=fexpand(copy(parametr,3,length(parametr)));
           end
         else if upcase(parametr[2])='N' then
           begin
            if netname<>dft_netname+' ' then badparams(i);
            netname:=copy(parametr,3,length(parametr))+' ';
            while pos('_',netname)<>0 do netname[pos('_',netname)]:=' ';
           end
         else if upcase(parametr[2])='D' then curday:=true
         else if upcase(parametr[2])='F' then force:=true
         else if upcase(parametr[2])='S' then quiet:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;

   if wierzcholek^.nastepny=nil then
     begin
       writeln('* No infile(s) specified!');
       writeln;
       halt;
     end;

   if force then writeln('* Force mode.');
   if quiet then
     begin
       writeln('* Speed mode.');
       obracac:=true;
     end;

   if netname=' ' then netname:='';

   if curday then
     begin
       getdate(rok,mies,dzien,dztyg);
       write('* Current date will be used. (');
       textcolor(2);
       write(day[dztyg],', ',dzien,' ',month[mies],' ',rok);
       textcolor(7);
       writeln(')');
     end;

   if force=false then
     begin
       odstep:=false;
       if fsearch(nodefile,'')<>'' then
         begin
           odstep:=true;
           write('* File ');
           nazwapliku(nodefile);
           write(' already exists!  ');
           ok:=false;
           write('Overwrite [Y/n] ?');
           while (ok=false) and (nodefile<>'nul') do
           case readkey of
             'n','N',#27 : begin
                             gotoxy(1,wherey);
                             write('* File ');
                             nazwapliku(nodefile);
                             writeln(' will be skipped.',#32:18);
                             nodefile:='nul';
                           end;
             'y','Y',#13 : begin
                             ok:=true;
                             gotoxy(1,wherey);
                             assign(nodelist,nodefile);
                             getfattr(nodelist,atrybut);
                             setfattr(nodelist,0);
                             erase(nodelist);
                             write('* File ');
                             nazwapliku(nodefile);
                             write(' deleted.');
                             if atrybut and readonly <> 0 then
                               writeln(' (read only!)',#32:13)
                             else
                               writeln(#32:26);
                           end;
           end;
         end;

       if fsearch(pointfile,'')<>'' then
         begin
           odstep:=true;
           write('* File ');
           nazwapliku(pointfile);
           write(' already exists!  ');
           ok:=false;
           write('Overwrite [Y/n] ?');
           while (ok=false) and (pointfile<>'nul') do
           case readkey of
             'n','N',#27 : begin
                             gotoxy(1,wherey);
                             write('* File ');
                             nazwapliku(pointfile);
                             writeln(' will be skipped.',#32:18);
                             pointfile:='nul';
                           end;
             'y','Y',#13 : begin
                             ok:=true;
                             gotoxy(1,wherey);
                             assign(pointlist,pointfile);
                             getfattr(pointlist,atrybut);
                             setfattr(pointlist,0);
                             erase(pointlist);
                             write('* File ');
                             nazwapliku(pointfile);
                             write(' deleted.');
                             if atrybut and readonly <> 0 then
                               writeln(' (read only!)',#32:13)
                             else
                               writeln(#32:26);
                           end;
           end;
         end;
       if odstep=true then writeln;
     end
   else
     begin
       odstep:=false;
       if fsearch(nodefile,'')<>'' then
         begin
           odstep:=true;
           assign(nodelist,nodefile);
           getfattr(nodelist,atrybut);
           setfattr(nodelist,0);
           erase(nodelist);
           write('* File ');
           nazwapliku(nodefile);
           write(' deleted.');
           if atrybut and readonly <> 0 then
             writeln(' (read only!)')
           else
             writeln;
         end;
       if fsearch(pointfile,'')<>'' then
         begin
           odstep:=true;
           assign(pointlist,pointfile);
           getfattr(pointlist,atrybut);
           setfattr(pointlist,0);
           erase(pointlist);
           write('* File ');
           nazwapliku(pointfile);
           write(' deleted.');
           if atrybut and readonly <> 0 then
             writeln(' (read only!)')
           else
             writeln;
         end;
       if odstep then writeln;
     end;

   if (nodefile='nul') and (pointfile='nul') then
     begin
       writeln('* No outfile specified!');
       writeln;
       halt(3);
     end;

   assign(nodelist,nodefile);
   assign(pointlist,pointfile);
   rewrite(nodelist);
   rewrite(pointlist);

   write(nodelist,';A ',netname,text_nodelist);
   if curday then write(nodelist,' ',text_for,' ',day[dztyg],', ',dzien,' ',month[mies],' ',rok,', ',daynumber,': ',today);
   writeln(nodelist,', CRC: ?????');
   writeln(nodelist,';A Created by ',programname);
   writeln(nodelist,';A (c) ',progdate,' ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);

   if nstartfile<>'nul' then
     begin
       write('* Adding start-info to nodelist...  ');
       writeln(nodelist,';');
       addfile(nstartfile,nodelist);
       writeln('Ok');
     end;

   write(pointlist,';A ',netname,text_pointlist);
   if curday then write(pointlist,' ',text_for,' ',day[dztyg],', ',dzien,' ',month[mies],' ',rok,', ',daynumber,': ',today);
   writeln(pointlist,', CRC: ?????');
   writeln(pointlist,';A Created by ',programname);
   writeln(pointlist,';A (c) ',progdate,' ',progcompany,', ',progauthor,', ',progauthoraddress+atnetwork);

   if pstartfile<>'nul' then
     begin
       write('* Adding start-info to pointlist...  ');
       writeln(pointlist,';');
       addfile(pstartfile,pointlist);
       writeln('Ok');
     end;
  end;


  procedure przecinki;
   var i:byte;
  begin
   a:=pos(',',linia);                             {ustalenie pozycji przecink¢w}
   b:=pos(',',copy(linia,a+1,length(linia)))+a;   {w linii wejžciowej}
   if a>1 then linia[1]:=upcase(linia[1]);
   if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
  end;


  procedure point;           {zapis do pointlisty}
  begin
   if bylboss=false then
     begin
       writeln(pointlist,';');
       writeln(pointlist,'Boss,',zone,':',net,'/',node);
       writeln(pointlist,';');
       bylboss:=true;
     end;
   writenode(pointlist,copy(linia,a,length(linia)));
   inc(points);
  end;


  procedure statystyka;
  begin
   write('Files: ');
   textcolor(14); write(pliknr);
   textcolor(7);  write('   Zones: ');
   textcolor(14); write(zones);
   textcolor(7);  write('   Regions: ');
   textcolor(14); write(regions);
   textcolor(7);  write('   Nets: ');
   textcolor(14); write(nets);
   textcolor(7);  write('   Nodes: ');
   textcolor(14); write(nodes);
   textcolor(7);  write('   Points: ');
   textcolor(14); writeln(points);
   textcolor(7);
   gotoxy(1,wherey-1);
  end;


  procedure wejscienext;                   {otwieranie kolejnych plik¢w}
  begin
   inc(pliknr);
   assign(wejscie,segmencik^.name);
   reset(wejscie);
   write('* Processing nodelist: ',segmencik^.name,'  ');
   if not quiet then
     begin
       writeln;
       write(#32:80);
       gotoxy(1,wherey);
     end;
   segmencik:=segmencik^.nastepny;
  end;


  procedure process;
  begin
   segmencik:=wierzcholek;
   repeat
    wejscienext;       {czy otworzy‡ nast‘pny plik?}
    while eof(wejscie)=false do
     begin
      if not quiet then statystyka;
      readln(wejscie,linia);

      if (linia[1]=';') or (linia='') then
        begin
          if czypisac=true then writeln(nodelist,';');
          czypisac:=false;
        end
      else
        begin
          czypisac:=true;
          przecinki;
          if a=1 then
            begin
              node:=copy(linia,a+1,b-a-1);
              writenode(nodelist,linia);
              inc(nodes);
              bylboss:=false;
            end
          else
            begin
              if copy(linia,1,a-1)='Point' then
                point
              else
                begin
                  writenode(nodelist,linia);
                  node:=copy(linia,a+1,b-a-1);
                  bylboss:=false;
                  if copy(linia,1,a-1)='Zone' then
                    begin
                      zone:=copy(linia,a+1,b-a-1);
                      net:=zone;
                      node:='0';
                      inc(zones);
                    end;
                  if (copy(linia,1,a-1)='Region') or (copy(linia,1,a-1)='Host') then
                    begin
                      net:=copy(linia,a+1,b-a-1);
                      node:='0';
                      if copy(linia,1,a-1)='Region' then inc(regions) else inc(nets);
                    end;
                end;
            end;
        end;
     end;
    close(wejscie);
    if not quiet then
      gotoxy(1,wherey-1)
    else
      begin
        gotoxy(wherex-1,wherey);
        writeln(' Ok');
      end;
   until segmencik^.nastepny=nil;
  end;


  procedure koniec;
   var crc:word;
  begin
   if not quiet then
     begin
       writeln;
       writeln;
       writeln;
     end;

   if czypisac=true then writeln(nodelist,';');
   if nendfile<>'nul' then
     begin
       write('* Adding end-info to nodelist...  ');
       addfile(nendfile,nodelist);
       writeln(nodelist,';');
       writeln('Ok');
     end;
   addinfoandclose(nodelist);

   writeln(pointlist,';');
   if pendfile<>'nul' then
     begin
       write('* Adding end-info to pointlist...  ');
       addfile(pendfile,pointlist);
       writeln(pointlist,';');
       writeln('Ok');
     end;
   addinfoandclose(pointlist);

   if nodefile<>'nul' then
     begin
       write('* Calculating CRC of nodelist...  ');
       crc:=liczcrc(nodefile);
       nodecrc(nodefile,crc);
       writeln('Ok');
     end;
   if pointfile<>'nul' then
     begin
       write('* Calculating CRC of pointlist...  ');
       crc:=liczcrc(pointfile);
       nodecrc(pointfile,crc);
       writeln('Ok');
     end;

   writeln;
   if nodefile<>'nul' then
     begin
       write('* Nodelist ');
       nazwapliku(nodefile);
       writeln(' created successfully.');
     end;
   if pointfile<>'nul' then
     begin
       write('* Pointlist ');
       nazwapliku(pointfile);
       writeln(' created successfully.');
     end;
   writeln;

   usunstare(killflaga,org_killflaga);
   usunstare(addflaga,org_addflaga);

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
  textcolor(13); writeln('Split');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  zmienne;
  process;
  koniec;
 end;


end.
