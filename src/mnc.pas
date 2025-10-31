{ MiCHA Nodelist Converter
  Copyright (c) 1997-2000 Przemyslaw Kwiatkowski

  Niniejszy program jest wolnym oprogramowaniem; mozesz go
  rozprowadzac dalej i/lub modyfikowac na warunkach GNU General
  Public License, wydanej przez Free Software Foundation - wedlug
  wersji 2-giej tej licencji lub ktorejs z pozniejszych.

  Niniejszy program rozpowszechniany jest z nadzieja, iz bedzie on
  uzyteczny - jednak BEZ JAKIEJKOLWIEK GWARANCJI, nawet domyslnej
  gwarancji PRZYDATNOSCI HANDLOWEJ albo PRZYDATNOSCI DO OKRESLONYCH
  ZASTOSOWAN. W celu uzyskania blizszych informacji - patrz:
  GNU General Public License.

  Z pewnoscia wraz z niniejszym programem otrzymales tez egzemplarz
  GNU General Public License; jesli nie - napisz do Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}

program Micha_Nodelist_Converter;
{$F+}

uses dos,crt,main,crc,overlay,
     split,update,remake,extract,sort,combine,create,stat,tree;
{$O split}
{$O update}
{$O remake}
{$O extract}
{$O sort}
{$O combine}
{$O create}
{$O stat}
{$O tree}

var withcontrol:boolean;
    godzina,minuta,sekunda,setna:word;


procedure help;
begin
 writeln('* Usage:  MNC [![ConfigFile]] -<ControlFile> [parameters (if required)]');
 writeln('          MNC [![ConfigFile]] <mode> [parameters]');
 writeln;
 writeln('<mode>:  Create  - Create new nodelist using segment-files');
 writeln('         Update  - Combine nodelist and nodediff to new nodelist');
 writeln('         Extract - Extract regional nodelist from any bigger nodelist');
 writeln('         Remake  - Recreate any nodelist or pointlist');
 writeln('         Split   - Convert nodelist with points to separate 2 files');
 writeln('         Combine - Combine nodelist and pointlist to 1 file');
 writeln('         Sort    - Sort any existing nodelist');
 writeln('         Stat    - Create nodelist''s statistics');
 writeln('         Tree    - Create routing-tree using nodelist');
 writeln('         Crc     - Calculate CRC of nodelist or pointlist');
 writeln;
 writeln('* Type ''MNC <mode>'' for help on [parameters].');
 writeln;
 halt(4);
end;


procedure config;
 var linia,cmd,param:string;
     i:byte;
     ok:boolean;
     flaga_tmp:flaga;
begin
 configfile:=fexpand(fsearch(configfile,''));
 assign(cfg,configfile);
 reset(cfg);
 nr:=0;
 write('* Reading main configuration file...  ');
 while not eof(cfg) do
   begin
     readln(cfg,linia);
     inc(nr);
     porzadkuj(linia,cmd,param);
     if cmd<>'' then
       begin
         if cmd='day0' then day[0]:=param
         else if cmd='day1' then day[1]:=param
         else if cmd='day2' then day[2]:=param
         else if cmd='day3' then day[3]:=param
         else if cmd='day4' then day[4]:=param
         else if cmd='day5' then day[5]:=param
         else if cmd='day6' then day[6]:=param
         else if cmd='month1' then month[1]:=param
         else if cmd='month2' then month[2]:=param
         else if cmd='month3' then month[3]:=param
         else if cmd='month4' then month[4]:=param
         else if cmd='month5' then month[5]:=param
         else if cmd='month6' then month[6]:=param
         else if cmd='month7' then month[7]:=param
         else if cmd='month8' then month[8]:=param
         else if cmd='month9' then month[9]:=param
         else if cmd='month10' then month[10]:=param
         else if cmd='month11' then month[11]:=param
         else if cmd='month12' then month[12]:=param
         else if cmd='networkname' then
           begin
             while pos('_',param)<>0 do param[pos('_',param)]:=' ';
             dft_netname:=param;
           end
         else if cmd='text_daynumber' then dft_daynumber:=param
         else if cmd='text_for' then dft_text_for:=param
         else if cmd='text_nwplist' then dft_text_nwplist:=param
         else if cmd='text_nodelist' then dft_text_nodelist:=param
         else if cmd='text_pointlist' then dft_text_pointlist:=param
         else if cmd='coordinatorflag' then nowaflaga(coordflaga,param)
         else if cmd='forcemode' then
           begin
             if downstr(param)='yes' then dft_force:=true
             else if downstr(param)='no' then dft_force:=false
             else badline;
           end
         else if cmd='speedmode' then
           begin
             if downstr(param)='yes' then dft_quiet:=true
             else if downstr(param)='no' then dft_quiet:=false
             else badline;
           end
         else if cmd='usecurrentdate' then
           begin
             if downstr(param)='yes' then dft_curday:=true
             else if downstr(param)='no' then dft_curday:=false
             else badline;
           end
         else if cmd='killmanyu' then
           begin
             if downstr(param)='yes' then dft_killmanyu:=true
             else if downstr(param)='no' then dft_killmanyu:=false
             else badline;
           end
         else if cmd='killlastu' then
           begin
             if downstr(param)='yes' then dft_killlastu:=true
             else if downstr(param)='no' then dft_killlastu:=false
             else badline;
           end
         else if cmd='addsemicolons' then
           begin
             if downstr(param)='no' then dft_addsemicolon:=0
             else if downstr(param)='yes' then dft_addsemicolon:=1
             else if downstr(param)='auto' then dft_addsemicolon:=2
             else badline;
           end
         else if cmd='separateflagu' then
           begin
             if downstr(param)='no' then separateflagu:=0
             else if downstr(param)='yes' then separateflagu:=1
             else if downstr(param)='nochange' then separateflagu:=2
             else badline;
           end
         else if cmd='killflag' then nowaflaga(killflaga,param)
         else if cmd='addflag' then nowaflaga(addflaga,param)
         else badline;
       end;
   end;
 close(cfg);
 writeln('Ok');
end;


procedure start;
begin
 clrscr;
 textbackground(7);
 textcolor(0);
 write('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
 write('บ',#32:78,'บบ',#32:78,'บ');
 write('ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');

 textcolor(1); gotoxy(3,2); write(ProgOfficialName);
 textcolor(4); gotoxy(71-length(ProgVersion),2); write('version ',ProgVersion);
 textcolor(0); gotoxy(3,3); write('(c) ',ProgDate,' ',ProgCompany,', ',ProgAuthor,', ',ProgAuthorAddress,AtNetwork);
 textcolor(8); gotoxy(72-(length(ProgType) div 2),3); write(ProgType);
 textbackground(0);
 textcolor(7);
 gotoxy(1,6);
end;


procedure czyhelp;
 var czy:boolean;
     i:byte;
begin
 if (paramcount<firstparam-1) or (mode='?') or (mode='/?') or (mode='-?')
   or (mode='-h') or (mode='/h') then help;
 if paramcount=firstparam-1 then
   if mode='update' then update.help
   else if mode='extract' then extract.help
   else if mode='remake' then remake.help
   else if mode='create' then create.help
   else if (mode='split') or (mode='convert') then split.help
   else if mode='crc' then crc.help
   else if (mode='sort') or (mode='qsort') then sort.help
   else if mode='stat' then stat.help
   else if mode='tree' then tree.help
   else if mode='combine' then combine.help;
 czy:=false;
 for i:=firstparam to paramcount do
   if (paramstr(i)='?') or (paramstr(i)='/?') or (paramstr(i)='-?')
     or (paramstr(i)='-h') or (paramstr(i)='/h') or (paramstr(i)='-H')
     or (paramstr(i)='/H') then czy:=true;
 if paramcount>1 then
   if (mode='update') and czy then update.help
   else if (mode='extract') and czy then extract.help
   else if (mode='remake') and czy then remake.help
   else if (mode='create') and czy then create.help
   else if ((mode='split') or (mode='convert')) and czy then split.help
   else if (mode='crc') and czy then crc.help
   else if ((mode='sort') or (mode='qsort')) and czy then sort.help
   else if (mode='stat') and czy then stat.help
   else if (mode='tree') and czy then tree.help
   else if (mode='combine') and czy then combine.help;
end;


procedure init;
 var i:byte;
     linia,cmd,param:string;
begin
 haltno:=0;
 obr1:=0;
 obr:=1;

 Day[0]:=('Sunday');
 Day[1]:=('Monday');
 Day[2]:=('Tuesday');
 Day[3]:=('Wednesday');
 Day[4]:=('Thursday');
 Day[5]:=('Friday');
 Day[6]:=('Saturday');
 Month[1]:=('January');
 Month[2]:=('February');
 Month[3]:=('March');
 Month[4]:=('April');
 Month[5]:=('May');
 Month[6]:=('June');
 Month[7]:=('July');
 Month[8]:=('August');
 Month[9]:=('September');
 Month[10]:=('October');
 Month[11]:=('November');
 Month[12]:=('December');
 dft_daynumber:='Day number';
 dft_text_for:='for';
 dft_text_nwplist:='Nodelist with points';
 dft_text_nodelist:='Nodelist';
 dft_text_pointlist:='Pointlist';
 dft_netname:='';
 dft_force:=false;
 dft_quiet:=false;
 dft_curday:=false;
 dft_addsemicolon:=2;
 dft_killmanyu:=false;
 dft_killlastu:=false;
 firstparam:=2;
 cfgfile:=dft_cfgfile;
 separateflagu:=2;
end;


procedure readcontrol;
begin
 configfile:=cfgfile;
 if fsearch(configfile,'')<>'' then configfile:=fsearch(configfile,'')
 else if fsearch(configfile+'.cfg','')<>'' then configfile:=fsearch(configfile+'.cfg','')
 else
   begin
     fsplit(paramstr(0),kat_,nazw_,rozsz_);
     if fsearch(kat_+configfile,'')<>'' then configfile:=fsearch(kat_+configfile,'')
     else if fsearch(kat_+configfile+'.cfg','')<>'' then configfile:=fsearch(kat_+configfile+'.cfg','');
   end;

 if fsearch(configfile,'')<>'' then
   config
 else if cfgfile<>dft_cfgfile then
   begin
     writeln('* Can''t open configuration file!');
     writeln;
     halt(5);
   end;
end;


procedure readcfg;
 var i:byte;
     linia,cmd,param,temp:string;
begin
 temp:=copy(mode,2,length(mode));
 nr:=0;

 if fsearch(temp,'')<>'' then configfile:=fsearch(temp,'')
 else if fsearch(temp+'.cfg','')<>'' then configfile:=fsearch(temp+'.cfg','')
 else
   begin
     fsplit(paramstr(0),kat_,nazw_,rozsz_);
     if fsearch(kat_+temp,'')<>'' then configfile:=fsearch(kat_+temp,'')
     else if fsearch(kat_+temp+'.cfg','')<>'' then configfile:=fsearch(kat_+temp+'.cfg','')
     else
       begin
         writeln('* Can''t open control file!');
         writeln;
         halt(5);
       end;
   end;
 writeln('* Opening control file...  ');
 writeln;
 configfile:=fexpand(configfile);
 assign(cfg,configfile);
 reset(cfg);
 mode:='';
 while mode='' do
   begin
     readln(cfg,linia);
     inc(nr);
     porzadkuj(linia,cmd,param);
     if eof(cfg) then mode:='[end]';
     if (cmd[1]='[') and (cmd[length(cmd)]=']') then mode:=cmd;
   end;
end;


procedure czastrwania;
var godzina1,minuta1,sekunda1,setna1:integer;

 procedure piszczas(godzina,minuta,sekunda,setna:word);
 begin
  textcolor(3); write(godzina:2);
  textcolor(7); write(':');
  textcolor(3); if minuta<10 then write('0',minuta:1) else write(minuta:2);
  textcolor(7); write(':');
  textcolor(3); if sekunda<10 then write('0',sekunda:1) else write(sekunda:2);
  textcolor(7); write('.');
  textcolor(3); if setna<10 then write('0',setna:1) else write(setna:2);
  textcolor(7);
 end;

begin
 write('      Start:  ');
 piszczas(godzina,minuta,sekunda,setna);
 godzina1:=godzina;
 minuta1:=minuta;
 sekunda1:=sekunda;
 setna1:=setna;
 gettime(godzina,minuta,sekunda,setna);
 write('     End:  ');
 piszczas(godzina,minuta,sekunda,setna);
 if godzina<godzina1 then
   godzina1:=24-godzina1+godzina
 else
   godzina1:=godzina-godzina1;
 if minuta<minuta1 then
   begin
     minuta1:=60-minuta1+minuta;
     dec(godzina1);
   end
 else
   minuta1:=minuta-minuta1;
 if sekunda<sekunda1 then
   begin
     sekunda1:=60-sekunda1+sekunda;
     dec(minuta1);
   end
 else
   sekunda1:=sekunda-sekunda1;
 if setna<setna1 then
   begin
     setna1:=100-setna1+setna;
     dec(sekunda1);
   end
 else
   setna1:=setna-setna1;
 write('     Active:  ');
 piszczas(godzina1,minuta1,sekunda1,setna1);
 writeln;
end;
{---------------------------------------------------------------------------}
{Tu zaczynamy!}

begin
 gettime(godzina,minuta,sekunda,setna);
 randomize;
 ovrinit(paramstr(0));
 ovrinitems;

 start;
 init;
 mode:=paramstr(1);

 if mode[1]='!' then
   begin
     if mode='!' then
         withcontrol:=false
     else
       begin
         withcontrol:=true;
         cfgfile:=copy(mode,2,length(mode));
       end;
     mode:=paramstr(firstparam);
     inc(firstparam);
   end
 else
   withcontrol:=true;

 if (mode[1]='-') or (mode[1]='/') then
   withconfig:=true
 else
   withconfig:=false;

 czyhelp;
 if withcontrol then
   readcontrol
 else
   writeln('* Configuration file skipped.');

 if withconfig then
   begin
     readcfg;
     while mode<>'[end]' do
       begin
         if mode='[update]' then update.letsgo
         else if mode='[create]' then create.letsgo
         else if (mode='[convert]') or (mode='[split]') then split.letsgo
         else if mode='[extract]' then extract.letsgo
         else if mode='[remake]' then remake.letsgo
         else if (mode='[sort]') or (mode='[qsort]') then sort.letsgo
         else if mode='[stat]' then stat.letsgo
         else if mode='[tree]' then tree.letsgo
         else if mode='[combine]' then combine.letsgo
         else badline;
       end;
     close(cfg);
   end
 else
   begin
     writeln;
     if mode='update' then update.letsgo
     else if mode='create' then create.letsgo
     else if (mode='split') or (mode='convert') then split.letsgo
     else if mode='crc' then crc.letsgo
     else if mode='extract' then extract.letsgo
     else if mode='remake' then remake.letsgo
     else if (mode='sort') or (mode='qsort') then sort.letsgo
     else if mode='stat' then stat.letsgo
     else if mode='tree' then tree.letsgo
     else if mode='combine' then combine.letsgo
     else
       begin
         gotoxy(1,wherey-1);
         writeln('* Syntax error!');
         writeln;
         help;
       end;
   end;
 czastrwania;
 writeln;
 writeln('Thanks for using MNC.');
 writeln;
 normvideo;
 halt(haltno);
end.
