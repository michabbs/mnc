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


{--------------------------------}
{ Tworzenie statystyki nodelisty }
{--------------------------------}
unit stat;
{$O+,F+}


interface
 uses dos,crt,main;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Stat'':   MNC creates nodelist''s statistics.');
  writeln;
  writeln('* Usage: MNC Stat -i<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - nodelist');
  writeln('  -o<name>     - statistics');
  writeln('  -m<size>     - left margin');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  var inlist,outlist,toadd:text;
      force:boolean;
      infile,outfile:string;
      rozmiar:longint;
      leftmargin:byte;

  procedure readconfig;
   var linia,cmd,param:string;
       i,k:byte;
       ok:boolean;
       l:integer;
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
           else if cmd='forcemode' then
             begin
               if downstr(param)='yes' then force:=true
               else if downstr(param)='no' then force:=false
               else badline;
             end
           else if cmd='leftmargin' then
             begin
               val(param,k,l);
               if l=0 then leftmargin:=k
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
       pom:integer;
       parametr,linia:string;
       plik:searchrec;
       pliczek:file of byte;
       ok:boolean;
       atrybut:word;
       rok,mies,dzien,dztyg:word;
       k:byte;
       l:integer;
  begin;
   force:=dft_force;
   leftmargin:=11;
   infile:='nul';
   outfile:='nul';
   obracac:=true;

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
         else if upcase(parametr[2])='M' then
           begin
               val(copy(parametr,3,length(parametr)),k,l);
               if l=0 then leftmargin:=k
               else badparams(i);
           end
         else if upcase(parametr[2])='F' then force:=true
         else if (upcase(parametr[2])='H') or (parametr[2]='?') then help
         else badparams(i);
       end;

   if infile='nul' then
     begin
       writeln('* No infile specified!');
       writeln;
       halt;
     end;

   if force then writeln('* Force mode.');

   if (outfile='nul') then outfile:=fexpand(dft_statfile);

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

   write('* Processing nodelist ');
   nazwapliku(infile);
   writeln('.');

   write('* Statistics ');
   nazwapliku(outfile);
   writeln(' will be created.');

   assign(pliczek,infile);
   reset(pliczek);
   rozmiar:=filesize(pliczek);
   close(pliczek);

   assign(inlist,infile);
   assign(outlist,outfile);
   reset(inlist);
   rewrite(outlist);
  end;


  procedure koniec;
   var crc:word;
       linia:string;
  begin
   close(outlist);

   write('* Statistics ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   close(inlist);

   writeln;
 end;


  function pisz5(a:word):string;
   var pom:string[5];
  begin
   str(a,pom);
   if a<10 then pisz5:='    '+pom
   else if a<100 then pisz5:='   '+pom
   else if a<1000 then pisz5:='  '+pom
   else if a<10000 then pisz5:=' '+pom
   else pisz5:=pom;
  end;

  function procent(a,b:real):string;
   var c,d:byte;
       pom1,pom2:string[2];
  begin
   if a=b then procent:='  100'
   else if a=0 then procent:='    0'
   else
     begin
       c:=round(int(100*a/b));
       d:=round(int(frac(100*a/b)*100));
       if int(frac(10000*a/b)*10)>=5 then inc(d);
       if d=100 then
         begin
           d:=0;
           inc(c);
         end;
       if c=100 then
         begin
           c:=99;
           d:=99;
         end;
       if (c=0) and (d=0) then d:=1;
       str(c,pom1);
       str(d,pom2);
       if (c=0) and (d=0) then procent:=' 0.01'
       else if (c<10) and (d<10) then procent:=' '+pom1+'.0'+pom2
       else if (c<10) and (d>=10) then procent:=' '+pom1+'.'+pom2
       else if (c>=10) and (d<10) then procent:=pom1+'.0'+pom2
       else procent:=pom1+'.'+pom2;
     end;
  end;


  procedure process;
   var linia,tmp,pom:string;
       a,b,i,j:byte;
       rok,mies,dzien,dztyg:word;
       godzina,minuta,sekunda,setna:word;

       total,zones,regions,hosts,hubs,downed,hold,private:word;
       ic,zc,rc,nc,zec,rec,nec:word;
       xa,xb,xc,xp,xr,xw,xx,xother:word;
       b9600,b2400,b1200,b300:word;
       cm,mo,lo:word;

  begin
   writeln;
   write('* Analyzing nodelist...  ');

   total:=0;
   zones:=0;
   regions:=0;
   hosts:=0;
   hubs:=0;
   downed:=0;
   hold:=0;
   private:=0;
   ic:=0;
   zc:=0;
   rc:=0;
   nc:=0;
   zec:=0;
   rec:=0;
   nec:=0;
   xa:=0;
   xb:=0;
   xc:=0;
   xp:=0;
   xr:=0;
   xw:=0;
   xx:=0;
   xother:=0;
   b9600:=0;
   b2400:=0;
   b1200:=0;
   b300:=0;
   cm:=0;
   mo:=0;
   lo:=0;

   while not eof(inlist) do
     begin
       readln(inlist,linia);
       if linia[1]<>';' then
         begin
           inc(total);
           a:=pos(',',linia);
           b:=pos(',',copy(linia,a+1,length(linia)))+a;
           if a>1 then linia[1]:=upcase(linia[1]);
           if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
           if (copy(linia,1,a-1)='Zone') then inc(zones)
           else if (copy(linia,1,a-1)='Region') then inc(regions)
           else if (copy(linia,1,a-1)='Host') then inc(hosts)
           else if copy(linia,1,a-1)='Hub' then inc(hubs)
           else if copy(linia,1,a-1)='Down' then inc(downed)
           else if copy(linia,1,a-1)='Hold' then inc(hold)
           else if copy(linia,1,a-1)='Pvt' then inc(private);

           j:=0;
           for i:=1 to 6 do j:=j+pos(',',copy(linia,j+1,length(linia)));
           tmp:=copy(linia,j+1,length(linia))+',';

           if copy(tmp,1,4)='9600' then inc(b9600)
           else if copy(tmp,1,4)='2400' then inc(b2400)
           else if copy(tmp,1,4)='1200' then inc(b1200)
           else if copy(tmp,1,3)='300' then inc(b300);

           if pos(',IC,',tmp)<>0 then inc(ic);
           if pos(',ZC,',tmp)<>0 then inc(zc);
           if pos(',RC,',tmp)<>0 then inc(rc);
           if pos(',NC,',tmp)<>0 then inc(nc);
           if pos(',ZEC,',tmp)<>0 then inc(zec);
           if pos(',REC,',tmp)<>0 then inc(rec);
           if pos(',NEC,',tmp)<>0 then inc(nec);
           if pos(',CM,',tmp)<>0 then inc(cm);
           if pos(',MO,',tmp)<>0 then inc(mo);
           if pos(',LO,',tmp)<>0 then inc(lo);

           if pos(',XA,',tmp)<>0 then inc(xa)
           else if pos(',XB,',tmp)<>0 then inc(xb)
           else if pos(',XC,',tmp)<>0 then inc(xc)
           else if pos(',XP,',tmp)<>0 then inc(xp)
           else if pos(',XR,',tmp)<>0 then inc(xr)
           else if pos(',XW,',tmp)<>0 then inc(xw)
           else if pos(',XX,',tmp)<>0 then inc(xx)
           else inc(xother);
         end;
       obroc;
     end;

   gotoxy(wherex-1,wherey);
   writeln(' Ok');
   write('* Creating statistics...  ');

   fsplit(fexpand(infile),kat_,nazw_,rozsz_);
   pom:=nazw_+rozsz_;
   while length(pom)<12 do pom:=' '+pom;
   writeln(outlist,#32:leftmargin,'             ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
   writeln(outlist,#32:leftmargin,'ÚÄÄÄÄÄÄÄÄÄÄÄÄ´ Statistics for: ',pom,' ÃÄÄÄÄÄÄÄÄÄÄÄÄ¿');
   write(  outlist,#32:leftmargin,'³            ÀÄ´ Created: ');

   getdate(rok,mies,dzien,dztyg);
   gettime(godzina,minuta,sekunda,setna);
   rok:=rok-(rok div 100)*100;
   if rok<10 then write(outlist,'0');
   write(outlist,rok,'.');
   if mies<10 then write(outlist,'0');
   write(outlist,mies,'.');
   if dzien<10 then write(outlist,'0');
   write(outlist,dzien,' ');

   if godzina=0 then write(outlist,'12:')
   else if godzina<10 then write(outlist,' ',godzina,':')
   else if godzina<13 then write(outlist,godzina,':')
   else if godzina<22 then write(outlist,' ',godzina-12,':')
   else write(outlist,godzina-12,':');

   if minuta<10 then write(outlist,'0');
   write(outlist,minuta);
   if godzina<12 then write(outlist,'a') else write(outlist,'p');
   writeln(outlist,' ÃÄÙ            ³');

   writeln(outlist,#32:leftmargin,'³                                                        ³');
   writeln(outlist,#32:leftmargin,'³                                                        ³');
   writeln(outlist,#32:leftmargin,'³',#32:4,'Nodes: ',pisz5(total),#32:17,'Size: ',rozmiar:9,' bytes  ³');
   writeln(outlist,#32:leftmargin,'³                                                        ³');
   writeln(outlist,#32:leftmargin,'³',#32:4,'Zones: ',pisz5(zones),' (',procent(zones,total),' %)',
                   #32:9,'XA: ',pisz5(xa),' (',procent(xa,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:2,'Regions: ',pisz5(regions),' (',procent(regions,total),' %)',
                   #32:9,'XB: ',pisz5(xb),' (',procent(xb,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:4,'Hosts: ',pisz5(hosts),' (',procent(hosts,total),' %)',
                   #32:9,'XC: ',pisz5(xc),' (',procent(xc,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:5,'Hubs: ',pisz5(hubs),' (',procent(hubs,total),' %)',
                   #32:9,'XP: ',pisz5(xp),' (',procent(xp,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:35,'XR: ',pisz5(xr),' (',procent(xr,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:3,'Downed: ',pisz5(downed),' (',procent(downed,total),' %)',
                   #32:9,'XW: ',pisz5(xw),' (',procent(xw,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:5,'Hold: ',pisz5(hold),' (',procent(hold,total),' %)',
                   #32:9,'XX: ',pisz5(xx),' (',procent(xx,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:2,'Private: ',pisz5(private),' (',procent(private,total),' %)',
                   #32:6,'Other: ',pisz5(xother),' (',procent(xother,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³                                                        ³');
   writeln(outlist,#32:leftmargin,'³',#32:7,'IC: ',pisz5(ic),' (',procent(ic,total),' %)',
                   #32:7,'9600: ',pisz5(b9600),' (',procent(b9600,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:7,'ZC: ',pisz5(zc),' (',procent(zc,total),' %)',
                   #32:7,'2400: ',pisz5(b2400),' (',procent(b2400,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:7,'RC: ',pisz5(rc),' (',procent(rc,total),' %)',
                   #32:7,'1200: ',pisz5(b1200),' (',procent(b1200,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:7,'NC: ',pisz5(nc),' (',procent(nc,total),' %)',
                   #32:8,'300: ',pisz5(b300),' (',procent(b300,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³                                                        ³');
   writeln(outlist,#32:leftmargin,'³',#32:6,'ZEC: ',pisz5(zec),' (',procent(zec,total),' %)',
                   #32:9,'CM: ',pisz5(cm),' (',procent(cm,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:6,'REC: ',pisz5(rec),' (',procent(rec,total),' %)',
                   #32:9,'MO: ',pisz5(mo),' (',procent(mo,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³',#32:6,'NEC: ',pisz5(nec),' (',procent(nec,total),' %)',
                   #32:9,'LO: ',pisz5(lo),' (',procent(lo,total),' %)  ³');
   writeln(outlist,#32:leftmargin,'³                                                        ³');

   writeln(outlist,#32:leftmargin,'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');

   gotoxy(wherex-1,wherey);
   writeln(' Ok');
   writeln;
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Stat');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;

end.
