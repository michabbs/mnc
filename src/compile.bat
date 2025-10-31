@echo off
call bpc main.pas
call bpc tpxms.pas
call bpc crc.pas
call bpc split.pas
call bpc extract.pas
call bpc remake.pas
call bpc sort.pas
call bpc update.pas
call bpc combine.pas
call bpc create.pas
call bpc stat.pas
call bpc tree.pas
call bpc mnc.pas
copy/b mnc.exe+mnc.ovr
del mnc.ovr
