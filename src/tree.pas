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


{--------------------------------------------------}
{ Tworzenie drzewa na podstawie struktury nodelity }
{--------------------------------------------------}
unit tree;
{$O+,F+}


interface
 uses dos,crt,main;

 procedure letsgo;
 procedure help;



implementation

 procedure help;
 begin
  writeln('Mode ''Tree'':   MNC creates routing-tree using nodelist.');
  writeln;
  writeln('* Usage: MNC Tree -i<name> [other parameters]');
  writeln;
  writeln('* Available parameters:');
  writeln;
  writeln('  -i<name>     - nodelist');
  writeln('  -o<name>     - tree');
  writeln('  -f           - force mode');
  writeln;
  halt(4);
 end;



 procedure letsgo;

  type wezel=^boss;
       boss=record
              zone,net,node:word;
              nastepny,wbok:wezel;
            end;
       routeto=^exception;
       exception=record
                   zoneto,netto,nodeto,zonefrom,netfrom,nodefrom:word;
                   uplink,downlink:wezel;
                   nastepny:routeto;
                 end;

  var inlist,outlist:text;
      force:boolean;
      infile,outfile:string;
      poczroute,route:routeto;

  procedure readconfig;
   var linia,cmd,param:string;
       ok:boolean;
       i:byte;
       b,c,d:byte;
       pom:integer;
       poprzedniroute:routeto;
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
           else if cmd='route-to' then
             begin
               b:=pos(':',param);
               c:=pos('/',param);
               d:=pos(' ',param);
               val(copy(param,1,b-1),route^.zoneto,pom);
               val(copy(param,b+1,c-b-1),route^.netto,pom);
               val(copy(param,c+1,d-c-1),route^.nodeto,pom);
               param:=copy(param,d,length(param));
               while param[1]=' ' do param:=copy(param,2,length(param));
               b:=pos(':',param);
               c:=pos('/',param);
               val(copy(param,1,b-1),route^.zonefrom,pom);
               val(copy(param,b+1,c-b-1),route^.netfrom,pom);
               val(copy(param,c+1,length(param)),route^.nodefrom,pom);
               poprzedniroute:=route;
               new(route);
               route^.zoneto:=0;
               route^.netto:=0;
               route^.nodeto:=0;
               route^.zonefrom:=0;
               route^.netfrom:=0;
               route^.nodefrom:=0;
               route^.nastepny:=nil;
               route^.uplink:=nil;
               route^.downlink:=nil;
               poprzedniroute^.nastepny:=route;
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
       ok:boolean;
       atrybut:word;
       rok,mies,dzien,dztyg:word;
  begin
   force:=dft_force;
   infile:='nul';
   outfile:='nul';
   obracac:=true;
   new(route);
   poczroute:=route;
   route^.zoneto:=0;
   route^.netto:=0;
   route^.nodeto:=0;
   route^.zonefrom:=0;
   route^.netfrom:=0;
   route^.nodefrom:=0;
   route^.nastepny:=nil;
   route^.uplink:=nil;
   route^.downlink:=nil;

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

   if (outfile='nul') then outfile:=fexpand(dft_treefile);

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

   write('* Tree ');
   nazwapliku(outfile);
   writeln(' will be created.');

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

   write('* Tree ');
   nazwapliku(outfile);
   writeln(' created successfully.');
   close(inlist);

   writeln;
  end;

   function dodajhuba(nodes:wezel; zone,net,node:word; var linia:string):boolean;
    var poprzedni,nastepny:wezel;
        czytajlinie,juz:boolean;
        a,b,i:byte;
        pom:integer;
   begin
     nodes^.zone:=zone;
     nodes^.net:=net;
     nodes^.node:=node;
     poprzedni:=nodes;
     new(nodes);
     poprzedni^.wbok:=nodes;
     nodes^.nastepny:=nil;
     nodes^.wbok:=nil;
     nodes^.zone:=0;
     nodes^.net:=0;
     nodes^.node:=0;

    dodajhuba:=true;
    czytajlinie:=true;
    juz:=false;
    while (not eof(inlist)) and (not juz) do
      begin
        obroc;
        if czytajlinie then readln(inlist,linia);
        if linia[1]<>';' then
          begin
            czytajlinie:=true;
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);

            if (copy(linia,1,a-1)='Zone') or (copy(linia,1,a-1)='Region')
              or (copy(linia,1,a-1)='Host') or (copy(linia,1,a-1)='Hub') then
              begin
                juz:=true;
                dodajhuba:=false;
              end
            else
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
                nodes^.zone:=zone;
                nodes^.net:=net;
                nodes^.node:=node;
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end;
          end;
      end;
   end;

   function dodajnet(nodes:wezel; zone,net,node:word; var linia:string):boolean;
    var poprzedni,nastepny:wezel;
        czytajlinie,juz:boolean;
        a,b,i:byte;
        pom:integer;
   begin
     nodes^.zone:=zone;
     nodes^.net:=net;
     nodes^.node:=node;
     poprzedni:=nodes;
     new(nodes);
     poprzedni^.wbok:=nodes;
     nodes^.nastepny:=nil;
     nodes^.wbok:=nil;
     nodes^.zone:=0;
     nodes^.net:=0;
     nodes^.node:=0;

    dodajnet:=true;
    czytajlinie:=true;
    juz:=false;
    while (not eof(inlist)) and (not juz) do
      begin
        obroc;
        if czytajlinie then readln(inlist,linia);
        if linia[1]<>';' then
          begin
            czytajlinie:=true;
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);

            if (copy(linia,1,a-1)='Zone') or (copy(linia,1,a-1)='Region') or (copy(linia,1,a-1)='Host') then
              begin
                juz:=true;
                dodajnet:=false;
              end
            else if (copy(linia,1,a-1)='Hub') then
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
                czytajlinie:=dodajhuba(nodes,zone,net,node,linia);
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end
            else
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
                nodes^.zone:=zone;
                nodes^.net:=net;
                nodes^.node:=node;
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end;
          end;
      end;
   end;

   function dodajregion(nodes:wezel; zone,net,node:word; var linia:string):boolean;
    var poprzedni,nastepny:wezel;
        czytajlinie,juz:boolean;
        a,b,i:byte;
        pom:integer;
   begin
     nodes^.zone:=zone;
     nodes^.net:=net;
     nodes^.node:=node;
     poprzedni:=nodes;
     new(nodes);
     poprzedni^.wbok:=nodes;
     nodes^.nastepny:=nil;
     nodes^.wbok:=nil;
     nodes^.zone:=0;
     nodes^.net:=0;
     nodes^.node:=0;

    dodajregion:=true;
    czytajlinie:=true;
    juz:=false;
    while (not eof(inlist)) and (not juz) do
      begin
        obroc;
        if czytajlinie then readln(inlist,linia);
        if linia[1]<>';' then
          begin
            czytajlinie:=true;
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);

            if (copy(linia,1,a-1)='Zone') or (copy(linia,1,a-1)='Region') then
              begin
                juz:=true;
                dodajregion:=false;
              end
            else if (copy(linia,1,a-1)='Host') then
              begin
                val(copy(linia,a+1,b-a-1),net,pom);
                node:=0;
                czytajlinie:=dodajnet(nodes,zone,net,node,linia);
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end
            else
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
                nodes^.zone:=zone;
                nodes^.net:=net;
                nodes^.node:=node;
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end;
          end;
      end;
   end;

   function dodajstrefe(nodes:wezel; zone,net,node:word; var linia:string):boolean;
    var poprzedni,nastepny:wezel;
        czytajlinie,juz:boolean;
        a,b,i:byte;
        pom:integer;
   begin
     nodes^.zone:=zone;
     nodes^.net:=net;
     nodes^.node:=node;
     poprzedni:=nodes;
     new(nodes);
     poprzedni^.wbok:=nodes;
     nodes^.nastepny:=nil;
     nodes^.wbok:=nil;
     nodes^.zone:=0;
     nodes^.net:=0;
     nodes^.node:=0;

    dodajstrefe:=true;
    czytajlinie:=true;
    juz:=false;
    while (not eof(inlist)) and (not juz) do
      begin
        obroc;
        if czytajlinie then readln(inlist,linia);
        if linia[1]<>';' then
          begin
            czytajlinie:=true;
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);

            if copy(linia,1,a-1)='Zone' then
              begin
                juz:=true;
                dodajstrefe:=false;
              end
            else if (copy(linia,1,a-1)='Region') then
              begin
                val(copy(linia,a+1,b-a-1),net,pom);
                node:=0;
                czytajlinie:=dodajregion(nodes,zone,net,node,linia);
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end
            else
              begin
                val(copy(linia,a+1,b-a-1),node,pom);
                nodes^.zone:=zone;
                nodes^.net:=net;
                nodes^.node:=node;
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end;
          end;
      end;

   end;


  procedure dopisz(nodes:wezel; linia:string);
  var nastepny:wezel;
  begin
    while nodes^.nastepny<>nil do
      begin
        obroc;
        nastepny:=nodes^.nastepny;
        if nastepny^.nastepny=nil then write(outlist,linia,'À')
        else write(outlist,linia,'Ã');
        writeln(outlist,' ',nodes^.zone,':',nodes^.net,'/',nodes^.node);

          if nodes^.wbok<>nil then
            begin
              if nastepny^.nastepny=nil then
                begin
                  dopisz(nodes^.wbok,linia+'   ');
                end
              else
                begin
                  dopisz(nodes^.wbok,linia+'³  ');
                end;
            end;
        nodes:=nodes^.nastepny;
      end;
  end;


  procedure sort(var wierzcholek:wezel);
   var nodes,poprzedni,najmniejszy,aktualny,pop,temp:wezel;
       zone,net,node:word;
  begin
    obroc;
    aktualny:=wierzcholek;
    temp:=nil;

    while aktualny^.zone<>0 do
      begin
        nodes:=aktualny^.nastepny;
        zone:=aktualny^.zone;
        net:=aktualny^.net;
        node:=aktualny^.node;
        najmniejszy:=nil;
        poprzedni:=aktualny;
        pop:=nil;

        while nodes^.zone<>0 do
          begin
            if (nodes^.zone<zone) or ((nodes^.zone=zone) and (nodes^.net<net))
            or ((nodes^.zone=zone) and (nodes^.net=net) and (nodes^.node<node)) then
              begin
                pop:=poprzedni;
                najmniejszy:=nodes;
                zone:=najmniejszy^.zone;
                net:=najmniejszy^.net;
                node:=najmniejszy^.node;
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

    nodes:=wierzcholek;
    while nodes^.zone<>0 do
      begin
        if nodes^.wbok<>nil then sort(nodes^.wbok);
        nodes:=nodes^.nastepny;
      end;
  end;


  procedure skasujdrzewo(var wierzcholek:wezel);
   var nodes,poprzedni:wezel;
  begin
    nodes:=wierzcholek;
    while nodes^.zone<>0 do
      begin
        if nodes^.wbok<>nil then skasujdrzewo(nodes^.wbok);
        poprzedni:=nodes;
        nodes:=nodes^.nastepny;
        dispose(poprzedni);
      end;
    dispose(nodes);
  end;


  procedure process;
   var j,k:word;
       zone,net,node:word;
       a,b,c,d,i:byte;
       linia:string;
       pom:integer;
       p1:word;
       p2,p3,min:longint;
       nodes,wierzcholek,nastepny,poprzedni:wezel;
       czytajlinie,juz:boolean;

  begin;
    writeln;
    write('* Analyzing nodelist...  ');
    gotoxy(wherex-1,wherey);
    write(obracanie[obr]);

    new(nodes);
    wierzcholek:=nodes;
    nodes^.zone:=0;
    nodes^.net:=0;
    nodes^.node:=0;
    nodes^.nastepny:=nil;
    nodes^.wbok:=nil;

    zone:=0;
    net:=0;
    node:=0;

    czytajlinie:=true;
    while not eof(inlist) do
      begin
        obroc;
        if czytajlinie then readln(inlist,linia);
        if linia[1]<>';' then
          begin
            czytajlinie:=true;
            a:=pos(',',linia);
            b:=pos(',',copy(linia,a+1,length(linia)))+a;
            if a>1 then linia[1]:=upcase(linia[1]);
            if a>2 then for i:=2 to a-1 do linia[i]:=downcase(linia[i]);
            if copy(linia,1,a-1)='Zone' then
              begin
                val(copy(linia,a+1,b-a-1),zone,pom);
                net:=zone;
                node:=0;
                czytajlinie:=dodajstrefe(nodes,zone,net,node,linia);
                poprzedni:=nodes;
                new(nodes);
                poprzedni^.nastepny:=nodes;
                nodes^.nastepny:=nil;
                nodes^.wbok:=nil;
                nodes^.zone:=0;
                nodes^.net:=0;
                nodes^.node:=0;
              end;
          end;
      end;

    gotoxy(wherex-1,wherey);
    writeln(' Ok');

    write('* Sorting nodes...  ');
    sort(wierzcholek);
    gotoxy(wherex-1,wherey);
    writeln(' Ok');

    nodes:=wierzcholek;
    if nodes^.zone=0 then
      writeln('* Routing-tree is empty. (No nodes in nodelist.)')
    else
      begin
        write('* Creating routing-tree...  ');
        writeln(outlist,'Â');
        repeat
          obroc;
          nastepny:=nodes^.nastepny;
          if nastepny^.nastepny=nil then
            begin
              writeln(outlist,'À ',nodes^.zone,':',nodes^.net,'/',nodes^.node);
              dopisz(nodes^.wbok,'   ');
            end
          else
            begin
              writeln(outlist,'Ã ',nodes^.zone,':',nodes^.net,'/',nodes^.node);
              dopisz(nodes^.wbok,'³  ');
            end;
          nodes:=nodes^.nastepny;
        until nodes^.nastepny=nil;

        gotoxy(wherex-1,wherey);
        writeln(' Ok');
      end;
    writeln;

    skasujdrzewo(wierzcholek);
  end;


 begin
  write('--> Mode: ');
  textcolor(13); writeln('Tree');
  textcolor(7); writeln;
  if (paramcount=1) and (not withconfig) then help;
  init;
  process;
  koniec;
 end;


end.
