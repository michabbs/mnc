unit main;
{$F+}


interface

 uses dos,crt;

 const MaxModeLength=7+2;
       ProgName='MiCHA Nodelist Converter';
       ProgOfficialName='MiCHA Nodelist Converter';
       ProgVersion='1.0á8-1';
       ProgDate='1997-2004';
       ProgCompany='MiCHA';
       ProgAuthor='Przemyslaw Kwiatkowski';
       ProgAuthorAddress='2:480/127';
       AtNetwork='@FidoNet';
       SystemName='MiCHA Mail System';
       ProgType='';
       Dft_CfgFile='mnc';
       Dft_TreeFile='tree.mnc';
       Dft_StatFile='mnc.sta';
       ProgramName=progname+' '+progversion;
       Obracanie:string[4]='-\|/';

 type flaga=^flgpointer;
      flgpointer=record
                   flaga:string[5];
                   rodzaj:byte;     {0=zwykla, 1=U,dodatkowa, 2=obie}
                   nastepny:flaga;
                 end;


 var nr:word; {nr linii konfiga}
     configfile:string;
     crcinfile:word; {crc w zawarte w pliku}
     kat_:dirstr; nazw_:namestr; rozsz_:extstr;
     haltno:byte;
     mode:string[maxmodelength]; {tryb pracy = paramstr(1)}
     cfg:text; {plik konfiguracyjny}
     firstparam:byte;
     addsemicolon:byte; {0 - no, 1 - yes, 2 - auto}
     separateflagu:byte; {0 - no, 1 - yes, 2 - nochange}
     killmanyu,dft_killmanyu:boolean;
     killlastu,dft_killlastu:boolean;

     cfgfile,dft_netname:string;
     dft_addsemicolon:byte;
     dft_force,dft_quiet,dft_curday:boolean;
     dft_daynumber,dft_text_for,dft_text_nodelist,dft_text_nwplist,dft_text_pointlist:string;

     Day:array[0..6] of string[20];
     Month:array[1..12] of string[20];

     killflaga,coordflaga,addflaga:flaga;

     daynumber,text_for,text_nodelist,text_nwplist,text_pointlist:string;
     withconfig:boolean;
     obr,obr1:byte; {Obracanie}
     obracac:boolean;


 function downcase(znak:char):char;
 function downstr(linia:string):string;
 function today:word;
 function plik999(nazwa:string):string;
 function strday(today:word):string;
 function coordinator(linia:string):boolean;
 procedure badparams(n:byte);
 procedure badline;
 procedure nowaflaga(var wskaznik:flaga; flag:string);
 procedure usunstare(var aktualny:flaga; org:flaga);
 procedure nodecrc(nazwa:string; crc:word);
 procedure AddInfoAndClose(var plik:text);
 procedure nazwapliku(nazwa:string);
 procedure porzadkuj(var linia,cmd,param:string);
 procedure obroc;
 procedure addfile(plik:string; var tofile:text);
 procedure writenode(var tofile:text; linia:string);



implementation

 function downcase(znak:char):char;
 begin
  if (ord(znak)>64) and (ord(znak)<91) then
    downcase:=chr(ord(znak)+32)
  else
    downcase:=znak;
 end;


 function downstr(linia:string):string;
  var i:byte;
     pom:string;
 begin
  pom:=linia;
  for i:=1 to length(pom) do
    pom[i]:=downcase(pom[i]);
  downstr:=pom;
 end;


 procedure badparams(n:byte);
 begin
  writeln('* Invalid parameter: ''',paramstr(n),'''');
  writeln('* Type ''MNC -?'' for help.');
  writeln;
  halt;
 end;


 procedure badline;
 begin
  writeln;
  writeln('* Bad line ',nr,' in ''',configfile,'''!');
  writeln('* Program aborted.');
  writeln;
  halt(5);
 end;


 function today:word;
  var rok,mies,dzien,dztyg:word;
      pom:word;
 begin
  getdate(rok,mies,dzien,dztyg);
  if mies=1 then pom:=dzien;
  if mies=2 then pom:=31+dzien;
  if mies=3 then pom:=31+28+dzien;
  if mies=4 then pom:=31+28+31+dzien;
  if mies=5 then pom:=31+28+31+30+dzien;
  if mies=6 then pom:=31+28+31+30+31+dzien;
  if mies=7 then pom:=31+28+31+30+31+30+dzien;
  if mies=8 then pom:=31+28+31+30+31+30+31+dzien;
  if mies=9 then pom:=31+28+31+30+31+30+31+31+dzien;
  if mies=10 then pom:=31+28+31+30+31+30+31+31+30+dzien;
  if mies=11 then pom:=31+28+31+30+31+30+31+31+30+31+dzien;
  if mies=12 then pom:=31+28+31+30+31+30+31+31+30+31+30+dzien;
  if ((rok div 4)*4=rok) and (mies>2) then inc(pom);
  today:=pom;
 end;


 function strday(today:word):string;
  var pom:string[3];
 begin
  str(today,pom);
  if today>999 then strday:='999'
  else if today<10 then strday:='00'+pom
  else if today<100 then strday:='0'+pom
  else strday:=pom;
 end;


 procedure nowaflaga(var wskaznik:flaga; flag:string);
  var flaga_tmp:flaga;
      ok:boolean;
 begin
  ok:=false;
  flaga_tmp:=wskaznik;
  while (flaga_tmp<>nil) and (not ok) do
    begin
      if flaga_tmp^.flaga=flag then ok:=true;
      flaga_tmp:=flaga_tmp^.nastepny;
    end;
  if not ok then
    begin
      new(flaga_tmp);
      flaga_tmp^.nastepny:=wskaznik;
      if copy(flag,1,2)='U,' then
        begin
          flaga_tmp^.rodzaj:=1;
          flaga_tmp^.flaga:=copy(flag,3,length(flag));
        end
      else if copy(flag,length(flag)-1,2)=',U' then
        begin
          flaga_tmp^.rodzaj:=0;
          flaga_tmp^.flaga:=copy(flag,1,length(flag)-2);
        end
      else
        begin
          flaga_tmp^.rodzaj:=2;
          flaga_tmp^.flaga:=flag;
        end;
      wskaznik:=flaga_tmp;
    end;
 end;


 procedure usunstare(var aktualny:flaga; org:flaga);
  var flaga_tmp:flaga;
 begin
  while aktualny<>org do
    begin
      flaga_tmp:=aktualny;
      aktualny:=aktualny^.nastepny;
      dispose(flaga_tmp);
    end;
 end;


 procedure nodecrc(nazwa:string; crc:word);
  var plik:file of byte;
      plik1:text;
      linia:string;
      pom,i,gdzie:byte;
      now,dziel:word;
 begin
  assign(plik1,nazwa);
  reset(plik1);
  readln(plik1,linia);
  close(plik1);
  gdzie:=length(linia)-5;

  assign(plik,nazwa);
  reset(plik);

  seek(plik,gdzie);
  now:=crc;
  dziel:=10000;
  for i:=1 to 5 do
    begin
      pom:=(now div dziel)+48;
      write(plik,pom);
      now:=now-(pom-48)*dziel;
      dziel:=dziel div 10;
    end;
  close(plik);
 end;


 procedure AddInfoAndClose(var plik:text);
 begin
  writeln(plik,';S');
  writeln(plik,';S You can file request the last version of ',progname,' from');
  writeln(plik,';S ',systemname,' (',progauthoraddress+atnetwork,')',
               #32:(52-length(systemname+progauthoraddress+atnetwork)),'Magic name: MNC');
  writeln(plik,';S');
  write(plik,#$1a);
  close(plik);
 end;


 {szukanie najnowszego pliku .999}
 {wynik = trzyliterowe rozszerzenie}
 function plik999(nazwa:string):string;
  var ext:string[3];
      juz:boolean;
      plik:searchrec; {pomocnicza nazwa pliku przy szukaniu}
      max,pom,pom2:integer;
 begin
  max:=-1;
  juz:=false;
  doserror:=0;
  findfirst(nazwa+'.*',anyfile,plik);

  repeat
   if (doserror=3) or (doserror=18) then
     juz:=true
   else
     begin
       val(copy(plik.name,pos('.',plik.name)+1,3),pom,pom2);
       if (pom2=0) and (pom>max) then max:=pom;
       findnext(plik);
     end;
  until juz;

  if max=-1 then max:=999;
  str(max,ext);
  if length(ext)=3 then plik999:=ext
  else if length(ext)=2 then plik999:='0'+ext
  else if length(ext)=1 then plik999:='00'+ext
  else plik999:='999';
 end;


 procedure nazwapliku(nazwa:string);
 begin
  textcolor(2);
  write('''',nazwa,'''');
  textcolor(7);
 end;


 procedure porzadkuj(var linia,cmd,param:string);
  var a,b,d:byte;
      c:integer;
      spacja:boolean;
      pom:string;
 begin
  cmd:='';
  param:='';
  if pos(';',linia)<>0 then
    linia:=copy(linia,1,pos(';',linia)-1);
  while linia[1]=' ' do
    linia:=copy(linia,2,length(linia));
  while linia[length(linia)]=' ' do
    linia:=copy(linia,1,length(linia)-1);

  if (pos(' ',linia)=0) and (length(linia)>0) then
    cmd:=downstr(linia);
  if pos(' ',linia)>0 then
    begin
      cmd:=downstr(copy(linia,1,pos(' ',linia)-1));
      if pos(' ',linia)<length(linia) then
        param:=copy(linia,pos(' ',linia)+1,length(linia));
      while param[1]=' ' do
        param:=copy(param,2,length(param));
    end;

  a:=1;
  while pos('%',copy(param,a,length(param)))<>0 do
    begin
      a:=pos('%',copy(param,a,length(param)))+a;
      if pos('%',copy(param,a,length(param)))<>0 then
        begin
          pom:=getenv(copy(param,a,pos('%',copy(param,a,length(param)))-1));
          if pom<>'' then
            begin
              param:=copy(param,1,a-2)+pom+copy(param,pos('%',copy(param,a,length(param)))+a,length(param));
              a:=a+length(pom)-1;
            end
          else
            begin
              val(copy(param,a,length(param)),b,c);
              d:=c;
              if c>1 then val(copy(param,a,c-1),b,c);
              if c=0 then
                begin
                  param:=copy(param,1,a-2)+paramstr(b-firstparam+3)+copy(param,a+d-1,length(param));
                end;
              a:=a+d-1;
            end;
        end
      else
        begin
          val(copy(param,a,length(param)),b,c);
          d:=c;
          if d=0 then
            begin
              param:=copy(param,1,a-2)+paramstr(b-firstparam+3);
              a:=length(param)+1;
            end
          else
            begin
              if c>1 then val(copy(param,a,c-1),b,c);
              if c=0 then
                begin
                  param:=copy(param,1,a-2)+paramstr(b-firstparam+3)+copy(param,a+d-1,length(param));
                end;
              a:=a+d-1;
            end;
        end;
    end;
 end;


 procedure obroc;
 var godzina,minuta,sekunda,setna:word;
 begin
  gettime(godzina,minuta,sekunda,setna);
  if (obr1<>sekunda) and obracac then
    begin
      obr1:=sekunda;
      gotoxy(wherex-1,wherey);
      write(obracanie[obr]);
      inc(obr);
      if obr=5 then obr:=1;
    end;
 end;


 procedure addfile(plik:string; var tofile:text);
  var toadd:text;
      linia:string;
 begin
  gotoxy(wherex-1,wherey);
  write(obracanie[obr]);

  assign(toadd,plik);
  reset(toadd);
  while not eof(toadd) do
    begin
      readln(toadd,linia);
      if (addsemicolon=1) or ((addsemicolon=2) and (linia[1]<>';')) then write(tofile,';');
      writeln(tofile,linia);
      obroc;
    end;
  close(toadd);
  gotoxy(wherex-1,wherey);
  write(' ');
 end;


 function coordinator(linia:string):boolean;
 var ok:boolean;
     flaga_tmp:flaga;
 begin
   ok:=false;
   flaga_tmp:=coordflaga;
   while flaga_tmp<>nil do
     begin
       if (pos(','+flaga_tmp^.flaga+',',linia)<>0) or
          (copy(linia,length(linia)-length(flaga_tmp^.flaga),length(flaga_tmp^.flaga)+1)=','+flaga_tmp^.flaga) then ok:=true;
       flaga_tmp:=flaga_tmp^.nastepny;
     end;
   coordinator:=ok;
 end;


 procedure killflg(flg:flaga; var linia:string);
 var l,m:string;
     tmp:string[3];
     i,j:byte;
     flag:string;
 begin
  flag:=flg^.flaga;
  tmp:='';
  j:=0;
  for i:=1 to 6 do j:=j+pos(',',copy(linia,j+1,length(linia)));
  l:=copy(linia,1,j);
  linia:=copy(linia,j+1,length(linia));
  j:=pos(',U',linia);
  if j<>0 then 
    begin
      if linia[j+2]=',' then 
        begin
          tmp:=',U,';
          m:=copy(linia,j+2,length(linia));
        end
      else
        begin
          tmp:=',U';
          m:=','+copy(linia,j+2,length(linia));
        end;
      linia:=copy(linia,1,j-1);
    end
  else
    m:='';

  if (flg^.rodzaj=0) or (flg^.rodzaj=2) then
    while (pos(','+flag,linia)<>0)
          and ((linia[pos(','+flag,linia)+length(flag)+1]=',')
          or (length(linia)<=pos(','+flag,linia)+length(flag))) do
      linia:=copy(linia,1,pos(','+flag,linia)-1)+copy(linia,pos(','+flag,linia)+length(flag)+1,length(linia));

  if (flg^.rodzaj=1) or (flg^.rodzaj=2) then
    while (pos(','+flag,m)<>0)
          and ((m[pos(','+flag,m)+length(flag)+1]=',')
          or (length(m)<=pos(','+flag,m)+length(flag))) do
      m:=copy(m,1,pos(','+flag,m)-1)+copy(m,pos(','+flag,m)+length(flag)+1,length(m));

  m:=tmp+copy(m,2,length(m));
  if m[length(m)]=',' then m:=copy(m,1,length(m)-1);
  linia:=l+linia+m;
 end;


 procedure addflg(flg:flaga; var linia:string);
 var l,m:string;
     i,j:byte;
     flag:string;
 begin
  flag:=flg^.flaga;
  j:=0;
  for i:=1 to 6 do j:=j+pos(',',copy(linia,j+1,length(linia)));
  l:=copy(linia,1,j);
  linia:=copy(linia,j+1,length(linia));
  j:=pos(',U',linia);
  if j<>0 then 
    begin
      m:=copy(linia,j,length(linia));
      linia:=copy(linia,1,j-1);
    end
  else
    m:='';

  if (flg^.rodzaj=1) then
    begin
      if ((pos(','+flag,m)=0) or (not ((m[pos(','+flag,m)+length(flag)+1]=',') or (length(m)<=pos(','+flag,m)+length(flag)))))
         and (not ((copy(m,1,length(flag)+2)=',U'+flag) and (m[length(flag)+3]=',') or (length(m)=length(flag)+2)))
        then m:=m+','+flag;
    end;

  if (flg^.rodzaj=0) or (flg^.rodzaj=2) then
    begin
      if (pos(','+flag,linia)=0) or not ((linia[pos(','+flag,linia)+length(flag)+1]=',')
         or (length(linia)<=pos(','+flag,linia)+length(flag)))
        then linia:=linia+','+flag;
    end;

  if copy(m,1,2)<>',U' then m:=',U'+m;
  linia:=l+linia+m;
 end;


 procedure writenode(var tofile:text; linia:string);
  var i:byte;
      flaga_tmp:flaga;
 begin

   flaga_tmp:=killflaga;
   while flaga_tmp<>nil do
     begin
       killflg(flaga_tmp,linia);
       flaga_tmp:=flaga_tmp^.nastepny;
     end;

   flaga_tmp:=addflaga;
   while flaga_tmp<>nil do
     begin
       addflg(flaga_tmp,linia);
       flaga_tmp:=flaga_tmp^.nastepny;
     end;

   if killmanyu and (pos(',U',linia)<>0) then
     repeat
       i:=pos(',U',linia);
       if pos(',U',copy(linia,i+1,length(linia)))<>0 then
         begin
           i:=i+pos(',U',copy(linia,i+1,length(linia)));
           if linia[i+2]=',' then
             linia:=copy(linia,1,i)+copy(linia,i+3,length(linia))
           else
             linia:=copy(linia,1,i)+copy(linia,i+2,length(linia));
           if i=length(linia) then linia:=copy(linia,1,length(linia)-1);
         end;
     until pos(',U',copy(linia,pos(',U',linia)+1,length(linia)))=0;

   if separateflagu=0 then
     if pos(',U,',linia)<>0 then linia:=copy(linia,1,pos(',U,',linia)+1)+copy(linia,pos(',U,',linia)+3,length(linia));
   if separateflagu=1 then
     if pos(',U',linia)<>0 then
       if (linia[pos(',U',linia)+2]<>',') and (pos(',U',linia)+2<>length(linia)) then
         linia:=copy(linia,1,pos(',U',linia)+1)+','+copy(linia,pos(',U',linia)+2,length(linia));

   if killlastu then
     while copy(linia,length(linia)-1,2)=',U' do linia:=copy(linia,1,length(linia)-2);

   writeln(tofile,linia);
   obroc;
 end;

begin
  killflaga:=nil;
  coordflaga:=nil;
  addflaga:=nil;
end.
