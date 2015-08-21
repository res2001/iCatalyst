@echo off
for /f "tokens=* delims=" %%a in ('gethwnd.exe') do set "conhwnd=%%a"
cscript //nologo //E:JScript browseforfolder.js %conhwnd%
