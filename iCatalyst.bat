@echo off

::Lorents & Res2001 2010-2015

setlocal enabledelayedexpansion
set "name=Image Catalyst"
set "version=2.5"
if "%~1" equ "thrd" call:threadwork %4 %5 "%~2" "%~3" & exit /b
if "%~1" equ "updateic" call:icupdate & exit /b
if "%~1" equ "" call:helpmsg & exit /b
title %name% %version%
set "fullname=%~0"
set "scrpath=%~dp0"
set "sconfig=%scrpath%Tools\"
set "scripts=%scrpath%Tools\scripts\"
set "tmppath=%TEMP%\iCatalyst\"
set "errortimewait=30"
set "iclock=%TEMP%ic.lck"
set "LOG=%scrpath%\iCatalyst"
set "runic="
call:runic "%name% %version%"
if defined runic (
	cls
	title [Waiting] %name% %version%
	1>&2 echo.-------------------------------------------------------------------------------
	1>&2 echo. Attention: running %runic% of %name%.
	1>&2 echo.
	1>&2 echo. Press Enter to continue.
	1>&2 echo.-------------------------------------------------------------------------------
	1>nul pause
	cls
)
set "LOG=%LOG%%runic%"
if not defined runic if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
set "apps=%~dp0Tools\apps\"
PATH %apps%;%PATH%
set "nofile="
set "num=0"
for %%a in (
	"%sconfig%config.ini"
	"%apps%advdef.exe"
	"%apps%deflopt.exe"
	"%apps%dlgmsgbox.exe"
	"%apps%gifsicle.exe"
	"%apps%jpegstripper.exe"
	"%apps%jpginfo.exe"
	"%apps%jpegtran.exe"
	"%apps%pngwolfzopfli.exe"
	"%apps%truepng.exe"
	"%scripts%filter.js"
	"%scripts%update.js"
) do (
	if not exist "%%~a" (
		set /a "num+=1"
		if !num! gtr 20 set "nofile=!nofile!..." & goto:filelisterr
		set "nofile=!nofile!"%%~a" "
	)
)

:filelisterr
if defined nofile (
	cls
	title [Error] %name% %version%
	if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	1>&2 echo.-------------------------------------------------------------------------------
	1>&2 echo. Application can not get access to files:
	1>&2 echo.
	for %%j in (%nofile%) do 1>&2 echo. - %%~j
	1>&2 echo.
	1>&2 echo. Check access to files and try again.
	1>&2 echo.-------------------------------------------------------------------------------
	call:dopause & exit /b
)

:settemp
set "rnd=%random%"
if not exist "%tmppath%%rnd%\" (
	set "tmppath=%tmppath%%rnd%"
	1>nul 2>&1 md "%tmppath%%rnd%" || (
		call:errormsg "Can not create temporary folder:^|%tmppath%%rnd%!"
		exit /b
	)
) else (
	goto:settemp
)
for %%a in (JPG PNG GIF) do (
	set "ImageNum%%a=0"
	set "TotalNum%%a=0"
	set "TotalNumErr%%a=0"
	set "TotalSize%%a=0"
	set "STotalSize%%a=0"
	set "ImageSize%%a=0"
	set "SImageSize%%a=0"
	set "change%%a=0"
	set "perc%%a=0"
	set "step%%a=10"
)
set "png="
set "jpeg="
set "gif="
set "perr="
set "stime="
set "ftime="
set "updateurl=http://x128.ho.ua/update.ini"
set "configpath=%~dp0\Tools\config.ini"
set "logfile=%tmppath%\Images"
set "iculog=%tmppath%\icu.log"
set "iculck=%tmppath%\icu.lck"
set "countPNG=%tmppath%\countpng"
set "countJPG=%tmppath%\countjpg"
set "countGIF=%tmppath%\countgif"
set "filelist=%tmppath%\filelist"
::For Images with characters
set "filelisterr=%tmppath%\filerr"
::For Images are already optimized
set "filelisterr1=%tmppath%\filerr1"
::For Images are not supported
set "filelisterr2=%tmppath%\filerr2"
::For Images are not found
set "filelisterr3=%tmppath%\filerr3"
::Table size
set "TFN=29"
::restrictions
set "BYTECONV=1000000"

set "thread=" & set "updatecheck=" & set "outdir=" & set "nooutfolder="
set "jpegtags=" & set "xtreme=" & set "advanced=" & set "pngtags=" & set "giftags="
call:readini "%configpath%"
call:sethread %thread%
set "updatecheck=%update%" & set "update="
if /i "%giftags%" equ "true" (set "giftags=--no-comments --no-extensions --no-names") else (set "giftags=")
call set "outdir=%outdir%"
call:paramcontrol %*
if defined perr (
	cls
	title [Error] %name% %version%
	if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	1>&2 echo.-------------------------------------------------------------------------------
	1>&2 echo. Unknown value of setting %perr%.
	call:helpmsg & exit /b
)
if "%png%" equ "0" if "%jpeg%" equ "0" if "%gif%" equ "0" goto:endsetcounters
set "oparam="
if not defined jpeg if not defined png if not defined gif (
	set "oparam=/JPG:1 /PNG:1 /GIF:1"
)
if /i "%outdir%" equ "false" (set "outdir=" & set "nooutfolder=yes") else if /i "%outdir%" equ "true" set "outdir="
if not defined nooutfolder if not defined outdir (
	cls
	title [Loading] %name% %version%
	for /f "tokens=* delims=" %%a in ('dlgmsgbox "Image Catalyst" "Folder3" " " "Select the folder to save images. Click 'Cancel' to replace the original image in the optimized." ') do set "outdir=%%~a"
)
if defined outdir (
	if "!outdir:~-1!" neq "\" set "outdir=!outdir!\"
	if not exist "!outdir!" (
		1>nul 2>&1 md "!outdir!" || (
		call:errormsg "Can not create folder for optimized files: !outdir!"
		exit /b
		)
	)
	for /f "tokens=* delims=" %%a in ("!outdir!") do set outdirparam="/Outdir:%%~a"
) else (
	set "outdirparam="
)
cls
title [Loading] %name% %version%
echo.-------------------------------------------------------------------------------
echo. Loading. Please wait...
echo.-------------------------------------------------------------------------------
cscript //nologo //E:JScript "%scripts%filter.js" %oparam% %outdirparam% %* 1>"%filelist%" 2>"%filelisterr%"

:setcounters
if exist "%filelist%" (
	if "%png%" neq "0" for /f "tokens=*" %%a in ('findstr /i /e ".png"  "%filelist%" ^| find /i /c ".png" 2^>nul') do set /a "TotalNumPNG+=%%a"
	if "%jpeg%" neq "0" for /f "tokens=*" %%a in ('findstr /i /e ".jpg"  "%filelist%" ^| find /i /c ".jpg" 2^>nul') do set /a "TotalNumJPG+=%%a"
	if "%jpeg%" neq "0" for /f "tokens=*" %%a in ('findstr /i /e ".jpe"  "%filelist%" ^| find /i /c ".jpe" 2^>nul') do set /a "TotalNumJPG+=%%a"
	if "%jpeg%" neq "0" for /f "tokens=*" %%a in ('findstr /i /e ".jpeg" "%filelist%" ^| find /i /c ".jpeg" 2^>nul') do set /a "TotalNumJPG+=%%a"
	if "%gif%" neq "0" for /f "tokens=*" %%a in ('findstr /i /e ".gif"  "%filelist%" ^| find /i /c ".gif" 2^>nul') do set /a "TotalNumGIF+=%%a"
)
if %TotalNumPNG% gtr 0 (if not defined png call:png) else set "png=0"
if %TotalNumJPG% gtr 0 (if not defined jpeg call:jpeg) else set "jpeg=0"
if %TotalNumGIF% gtr 0 (if not defined gif call:gif) else set "gif=0"
if exist "%filelisterr%" (
	if defined png  for /f "tokens=3 delims=:" %%a in ('findstr /i /e ".png"  "%filelisterr%" ^| find /i /c ".png" 2^>nul') do set /a "TotalNumErrPNG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('findstr /i /e ".jpg"  "%filelisterr%" ^| find /i /c ".jpg" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('findstr /i /e ".jpe"  "%filelisterr%" ^| find /i /c ".jpe" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('findstr /i /e ".jpeg" "%filelisterr%" ^| find /i /c ".jpeg" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
	if defined gif  for /f "tokens=3 delims=:" %%a in ('findstr /i /e ".gif"  "%filelisterr%" ^| find /i /c ".gif" 2^>nul') do set /a "TotalNumErrGIF+=%%a"
)

:endsetcounters
if %TotalNumPNG% equ 0 if %TotalNumJPG% equ 0 if %TotalNumGIF% equ 0 (
	cls
	1>&2 echo.-------------------------------------------------------------------------------
	1>&2 echo. Images not found. Please check images and try again.
	call:helpmsg
	exit /b
)
for /l %%a in (1,1,%thread%) do (
	>"%logfile%png.%%a" echo.
	>"%logfile%jpg.%%a" echo.
	>"%logfile%gif.%%a" echo.
)
cls
echo.------------------------------------------------------------------------------
echo. File Name                    ^| Original  ^| Optimized ^| Savings, ^| %% Savings
echo.                              ^| Size, KB  ^| Size, KB  ^| KB       ^|
echo.------------------------------------------------------------------------------
if /i "%updatecheck%" equ "true" start "" /b cmd.exe /c ""%fullname%" updateic"
call:setitle
call:setvtime stime
for /f "usebackq tokens=1,2 delims=	" %%a in ("%filelist%") do (
	call:initsource "%%~a"
	if defined ispng if "%png%" neq "0" call:filework "%%~fa" "%%~fb" png %thread% ImageNumPNG
	if defined isjpeg if "%jpeg%" neq "0" call:filework "%%~fa" "%%~fb" jpg %thread% ImageNumJPG
	if defined isgif if "%gif%" neq "0" call:filework "%%~fa" "%%~fb" gif %thread% ImageNumGIF
)

:waithread
call:waitflag "%tmppath%\thrt*.lck"
for /l %%z in (1,1,%thread%) do (
	call:typelog png %%z
	call:typelog jpg %%z
	call:typelog gif %%z
)
echo.------------------------------------------------------------------------------
call:setitle
call:end
call:dopause & exit /b

:paramcontrol
if "%~1" equ "" exit /b
set "tt=%~1"
if "!tt:~,1!" equ "/" (
	if /i "!tt:~1,4!" equ "JPG:" (
		set "jpeg=!tt:~5!"
		if "!jpeg!" neq "0" if "!jpeg!" neq "1" if "!jpeg!" neq "2" if "!jpeg!" neq "3" (
			set "jpeg=0" & set "perr=JPG"
		)
		if not defined png set "png=0"
		if not defined gif set "gif=0"
	) else if /i "!tt:~1,4!" equ "PNG:" (
		set "png=!tt:~5!"
		if "!png!" neq "0" if "!png!" neq "1" if "!png!" neq "2" (
			set "png=0" & set "perr=PNG"
		)
		if not defined jpeg set "jpeg=0"
		if not defined gif set "gif=0"
	) else if /i "!tt:~1,4!" equ "GIF:" (
		set "gif=!tt:~5!"
		if "!gif!" neq "0" if "!gif!" neq "1" (
			set "gif=0" & set "perr=GIF"
		)
		if not defined png set "png=0"
		if not defined jpeg set "jpeg=0"
	) else if /i "!tt:~1,7!" equ "Outdir:" (
		set "outdir=!tt:~8!"
	)
)
shift
goto:paramcontrol

:runningcheck
call:runic "%~1"
set "lastrunic=%runic%"
if defined runic (
	title [Waiting] %name% %version%
	echo.Another process is running %name%. Waiting for shuting down.
	call:runningcheck2 "%~1"
)
exit /b

:runningcheck2
2>nul (3>"%iclock%" 1>&3 call:runic2 "%~1" || (call:waitrandom 5000 & goto:runningcheck2))
exit /b

:runic
set "runic="
for /f "tokens=* delims=" %%a in ('tasklist /fo csv /v /nh ^| find /i /c "%~1" ') do (
	if %%a gtr 1 set "runic=%%a"
)
exit /b

:setvtime
set "%1=%date% %time:~0,2%:%time:~3,2%:%time:~6,2%"
exit /b

:icupdate
if not exist "%scripts%update.js" exit /b
>"%iculck%" echo.Update IC
cscript //nologo //E:JScript "%scripts%update.js" %updateurl% 2>nul 1>"%iculog%" || 1>nul 2>&1 del /f /q "%iculog%"
1>nul 2>&1 del /f /q "%iculck%"
exit /b

::%1 - png | jpg | gif
::%2 - %thread%
::%3 - input file
::%4 - output file
:createthread
if %2 equ 1 call:threadwork %1 1 %3 %4 & call:typelog %1 1 & exit /b
for /l %%z in (1,1,%2) do (
	if not exist "%tmppath%\thrt%%z.lck" (
		call:typelog %1 %%z
		>"%tmppath%\thrt%%z.lck" echo. Image processing: %3
		start /b /LOW /MIN cmd.exe /s /c ""%fullname%" thrd "%~3" "%~4" %1 %%z"
		exit /b
	)
)
call:waitrandom 500
goto:createthread

::%1 - png | jpg | gif
::%2 - thread number
:typelog
if %thread% equ 1 exit /b
if not defined typenum%1%2 set "typenum%1%2=1"
call:typelogfile "%logfile%%1.%2" "typenum%1%2" %1
::call:typelogfile "%logfile%%1.%2" "typenum%1%2" %%typenum%1%2%% %1
exit /b

::%1 - log file name (%logfile%)
::%2 - variable name - counter displayed files
::%3 - png | jpg | gif
:typelogfile
if not exist "%~1" exit /b
set "tmpnum=!%~2!"
for /f "usebackq skip=%tmpnum% tokens=1-5 delims=;" %%b in ("%~1") do (
	if /i "%%d" equ "error" (
		call:printfileerr "%%~b" "%%~c"
	) else (
		call:printfileinfo "%%~b" %%c %%d %%e %%f %3
	)
	set /a "%~2+=1"
)
exit /b

::%1 - file name
::%2 - original size in byte
::%3 - optimize size in byte
::%4 - change (%2 - %3)
::%5 - percent change (%4*100/%2)
::%6 - png | jpg | gif
:printfileinfo
if "%~4" equ "0" (
	>>"%filelisterr1%" echo.%~f1
	exit /b
)
setlocal  
set "fn="
call:cropfilename fn %1 %TFN%
set "origsize=%2"
call:division origsize 1024 100
set "origsize=          !origsize!"
set "optsize=%3"
call:division optsize 1024 100
set "optsize=          !optsize!"
set "change=%4"
call:division change 1024 100
set "change=          !change!"
set "percent=          %5%%"
echo. !fn:~,%TFN%!^|%origsize:~-11%^|%optsize:~-11%^|%change:~-10%^|%percent:~-10%
endlocal & call:calcstep %6 %2 %3
exit /b

::%1 - file name
::%2 - error message
:printfileerr
setlocal
set "fn=%~nx1                                        "
set "errmsg=%~2"
call:centerstring errmsg 45
1>&2 echo. %fn:~,30%^|%errmsg%
endlocal
exit /b

::%1 - variable containing file name
::%2 - file name in %1
::%3 - max length file name
:cropfilename
setlocal  
set "xfn=%~nx2"
set "xfnext=%~x2"
set "xfnlen=0"
set "xfnextlen=0"
call:strlen xfn xfnlen
call:strlen xfnext xfnextlen
set /a "xfnextlen=%3-%xfnextlen%-2"
if %xfnlen% gtr %3 (
	call set "xfn=%%xfn:~,%xfnextlen%%%..%xfnext%"
) else (
	set "xfn=%xfn%                                        "
	set "xfn=!xfn:~,%3!"
)
endlocal & set "%~1=%xfn%"
exit /b

:centerstring StrVar Length
if "%~1" equ "" exit /b
if not defined %~1 exit /b
setlocal
set "xstringlen=0"
set "xstr=!%~1!"
call:strlen xstr xstringlen
set "xstradd=                                                                                                    "
set /a "xstraddlen=(%~2-%xstringlen%)/2"
set "xstradd=!xstradd:~,%xstraddlen%!"
if %xstringlen% geq %~2 (
	set "xstr=!xstr:~,%~2!"
) else (
	set "xstr=!xstradd!%xstr%!xstradd!"
	set /a "xstraddlen=xstringlen+xstraddlen*2"
	if !xstraddlen! lss %~2 set "xstr= !xstr!"
)
endlocal & set "%~1=%xstr%"
exit /b

::original: http://forum.script-coding.com/viewtopic.php?pid=71000#p71000
:strlen  StrVar  RtnVar  --  be sure to check if the returned errorlevel is 0
setlocal
set /a "}=0"
if "%~1" neq "" if defined %~1 (
        for %%# in (4096 2048 1024 512 256 128 64 32 16) do (
            if "!%~1:~%%#,1!" neq "" set "%~1=!%~1:~%%#!" & set /a "}+=%%#"
        )
        set "%~1=!%~1!0FEDCBA9876543211" & set /a "}+=0x!%~1:~32,1!!%~1:~16,1!"
    )
)
endlocal & set /a "%~2=%}%"
exit /b

:echostd
echo.%~1
exit /b

:echoerr
1>&2 echo.%~1
exit /b

::%1 - png | jpg | gif
::%2 - thread number
::%3 - input file
::%4 - output file
:threadwork
1>nul 2>&1 md "%~dp4"
if /i "%1" equ "png" call:pngfilework %2 %3 %4 & if %thread% gtr 1 >>"%countPNG%.%2" echo.1
if /i "%1" equ "jpg" call:jpegfilework %2 %3 %4 & if %thread% gtr 1 >>"%countJPG%.%2" echo.1
if /i "%1" equ "gif" call:giffilework %2 %3 %4 & if %thread% gtr 1 >>"%countGIF%.%2" echo.1
if exist "%tmppath%\thrt%2.lck" >nul 2>&1 del /f /q "%tmppath%\thrt%2.lck"
exit /b

:waitflag
if not exist "%~1" exit /b
call:waitrandom 2000
goto:waitflag

:waitrandom
set /a "ww=%random%%%%1"
1>nul 2>&1 ping -n 1 -w %ww% 127.255.255.255
exit /b

:initsource
set "isjpeg="
set "ispng="
set "isgif="
if /i "%~x1" equ ".png" set "ispng=1"
if /i "%~x1" equ ".jpg" set "isjpeg=1"
if /i "%~x1" equ ".jpeg" set "isjpeg=1"
if /i "%~x1" equ ".jpe" set "isjpeg=1"
if /i "%~x1" equ ".gif" set "isgif=1"
exit /b

:sethread
set /a "thread=%~1+1-1"
if "%~1" neq "" if "%~1" neq "0" set "thread=%~1" & exit /b
if %thread% equ 0 set "thread=%NUMBER_OF_PROCESSORS%"
exit /b

:png
cls
set "png="
title [PNG] %name% %version%
echo. -------------------------
echo. Optimization setting PNG:
echo. -------------------------
echo.
echo. [1] Advanced
echo.
echo. [2] Xtreme
echo.
echo. [0] Skip
echo.
echo. ---------------------------------------
set /p png="#Select setting and press Enter [0-2]: "
echo. ---------------------------------------
echo.
if "%png%" neq "0" if "%png%" neq "1" if "%png%" neq "2" goto:png
exit /b

:jpeg
cls
set "jpeg="
title [JPEG] %name% %version%
echo. --------------------------
echo. Optimization setting JPEG:
echo. --------------------------
echo.
echo. [1] Baseline
echo.
echo. [2] Progressive
echo.
echo. [3] Default
echo.
echo. [0] Skip
echo.
echo. ---------------------------------------
set /p jpeg="#Select setting and press Enter [0-3]: "
echo. ---------------------------------------
echo.
if "%jpeg%" neq "0" if "%jpeg%" neq "1" if "%jpeg%" neq "2" if "%jpeg%" neq "3" goto:jpeg
exit /b

:gif
cls
set "gif="
title [GIF] %name% %version%
echo. -------------------------
echo. Optimization setting GIF:
echo. -------------------------
echo.
echo. [1] Default
echo.
echo. [0] Skip
echo.
echo. ---------------------------------------
set /p gif="#Select setting and press Enter [0-1]: "
echo. ---------------------------------------
echo.
if "%gif%" neq "0" if "%gif%" neq "1" goto:gif
exit /b

:setitle
if "%jpeg%" equ "0" if "%png%" equ "0" if "%gif%" equ "0" (title %~1%name% %version% & exit /b)
if %thread% gtr 1 (
	set "ImageNumPNG=0" & set "ImageNumJPG=0" & set "ImageNumGIF=0"
	for /l %%c in (1,1,%thread%) do  (
		for %%b in ("%countPNG%.%%c") do set /a "ImageNumPNG+=%%~zb/3" 2>nul
		for %%b in ("%countJPG%.%%c") do set /a "ImageNumJPG+=%%~zb/3" 2>nul
		for %%b in ("%countGIF%.%%c") do set /a "ImageNumGIF+=%%~zb/3" 2>nul
	)
)
if %png% equ 1  (set "pngtitle=Advanced")
if %png% equ 2  (set "pngtitle=Xtreme")
if %jpeg% equ 1 (set "jpegtitle=Baseline")
if %jpeg% equ 2 (set "jpegtitle=Progressive")
if %jpeg% equ 3 (set "jpegtitle=Default")
if %gif% equ 1  (set "giftitle=Default")
set "titlestr="
set "tmpn=0"
if %png% gtr 0  (
	set /a "perc=%ImageNumPNG%*100/%TotalNumPNG%"
	set "titlestr=PNG %pngtitle%: !perc!%%"
)
if %jpeg% gtr 0 (
	set /a "perc=%ImageNumJPG%*100/%TotalNumJPG%"
	if %png% gtr 0 set "titlestr=%titlestr% ^| "
	set "titlestr=!titlestr!JPEG %jpegtitle%: !perc!%%"
)
if %gif% gtr 0 (
	set /a "perc=%ImageNumGIF%*100/%TotalNumGIF%"
	set /a "tmpn=%jpeg%+%png%"
	if !tmpn! gtr 0 (set "titlestr=%titlestr% ^| ")
	set "titlestr=!titlestr!GIF %giftitle%: !perc!%%"
)
title [%titlestr%] %name% %version%
set "titlestr="
set "tmpn="
exit /b

::%1 - input file
::%2 - output file
::%3 - png | jpg | gif
::%4 - %thread%
::%5 - ImageNum(PNG|JPG|GIF)
:filework
call:createthread %3 %4 "%~f1" "%~f2"
set /a "%5+=1"
call:setitle
exit /b

::%1 - thread number
::%2 - input file
::%3 - output file
:pngfilework
set "zc="
set "zm="
set "zs="
set "psize=%~z2"
set "errbackup=0"
set "logfile2=%logfile%png.%1"
set "pnglog=%tmppath%\png%1.log"
set "filework=%tmppath%\%~n2-ic%1%~x2"
if not exist "%~2" (
	call:saverrorlog "%~f2" 3 %~1
	exit /b 1
)
if %png% equ 2 (
	>"%pnglog%" 2>nul truepng -y -i0 -zw7 -zc7 -zm5-9 -zs0-3 -f0,5 -fs:2 %xtreme% -force -out "%filework%" "%~2"
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
	for /f "tokens=2,4,6,8,10 delims=:	" %%a in ('findstr /r /i /b /c:"zc:..zm:..zs:" "%pnglog%"') do (
		set "zc=%%a"
		set "zm=%%b"
		set "zs=%%c"
	)
	pngwolfzopfli --zopfli-iter=10 --zopfli-maxsplit=0 --zlib-window=15 --zlib-level=!zc! --zlib-memlevel=!zm! --zlib-strategy=!zs! --max-stagnate-time=0 --max-evaluations=1 --in="%filework%" --out="%filework%" 1>nul 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
)
if %png% equ 1 (
	>"%pnglog%" 2>nul truepng -y -i0 -zw7 -zc7 -zm8-9 -zs0-1 -f0,1,5 -fs:2 %advanced% -force -out "%filework%" "%~2"
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
	for /f "tokens=2,4,6,8,10 delims=:	" %%a in ('findstr /r /i /b /c:"zc:..zm:..zs:" "%pnglog%"') do (
		set "zc=%%a"
		set "zm=%%b"
		set "zs=%%c"
	)
	truepng -y -i0 -zw7 -zc!zc! -zm!zm! -zs!zs! -f5 -fs:7 -na -nc -np "%filework%" 1>nul 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
	advdef -z3 "%filework%" 1>nul 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
)
deflopt -k "%filework%" 1>nul 2>&1
if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
call:backup2 "%~f2" "%filework%" "%~f3" || set "errbackup=1"
if %errbackup% neq 0 (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe)
if /i "%pngtags%" equ "true" (1>nul 2>&1 truepng -nz -md remove all "%~3" || (call:saverrorlog "%~f2" 2 %~1 & goto:pngfwe))
call:savelog "%~f3" %psize%
if %thread% equ 1 for %%a in ("%~f3") do (set /a "ImageSizePNG+=%%~za" & set /a "TotalSizePNG+=%psize%")
:pngfwe
1>nul 2>&1 del /f /q "%filework%" "%pnglog%"
exit /b

::%1 - thread number
::%2 - input file
::%3 - output file
:jpegfilework
set "ep="
set "jsize=%~z2"
set "errbackup=0"
set "logfile2=%logfile%jpg.%1"
set "jpglog=%tmppath%\jpg%1.log"
if /i "%~f2" equ "%~f3" (
	set "filework=%tmppath%\%~n2-ic%1%~x2"
) else (
	set "filework=%~f3"
)
if not exist "%~2" (
	call:saverrorlog "%~f2" 3 %~1
	exit /b 1
)
if %jpeg% equ 1 (
	jpegtran -verbose -revert -optimize -copy all -outfile "%filework%" "%~2" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe)
	for /f "tokens=4,10 delims=:,= " %%a in ('findstr /C:"Start Of Frame" "%jpglog%" 2^>nul') do (set "ep=%%a")
	if "!ep!" equ "0xc0" goto:jpegfwb
	if "!ep!" equ "0xc2" (
		if /i "%~f2" equ "%~f3" (1>nul 2>&1 move /y "%filework%" "%~f3" || set "errbackup=1")
		goto:jpegfwf
	) else (
		call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe
	)
)
if %jpeg% equ 2 (
	jpegtran -verbose -copy all -outfile "%filework%" "%~2" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe)
	for /f "tokens=4,10 delims=:,= " %%a in ('findstr /C:"Start Of Frame" "%jpglog%" 2^>nul') do (set "ep=%%a")
	if "!ep!" equ "0xc2" goto:jpegfwb
	if "!ep!" equ "0xc0" (
		if /i "%~f2" equ "%~f3" (1>nul 2>&1 move /y "%filework%" "%~f3" || set "errbackup=1")
		goto:jpegfwf
	) else (
		call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe
	)
)
if %jpeg% equ 3 (
	jpginfo "%~2" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe)
	for /f "usebackq tokens=5" %%a in ("%jpglog%") do set "ep=%%~a"
	if /i "!ep!" equ "Baseline" (
		jpegtran -verbose -revert -optimize -copy all -outfile "%filework%" "%~2" 1>nul 2>&1 &&	goto:jpegfwb
	)
	if /i "!ep!" equ "Progressive" (
		jpegtran -verbose -copy all -outfile "%filework%" "%~2" 1>nul 2>&1 && goto:jpegfwb
	)
	call:saverrorlog "%~f2" 2 %~1 & goto:jpegfwe
)
:jpegfwb
if /i "%~f2" neq "%~f3" (
	call:backup "%filework%" "%~f2" >nul || set "errbackup=1"
) else (
	call:backup "%~f2" "%filework%" true >nul || set "errbackup=1"
)
:jpegfwf
1>nul 2>&1 del /f /q "%jpglog%"
if %errbackup% neq 0 (call:saverrorlog "%~f2" 3 %~1 & goto:jpegfwe)
if /i "%jpegtags%" equ "true" (1>nul 2>&1 jpegstripper -y "%~f3" || (call:saverrorlog "%~f2" 2 %~1 & exit /b))
call:savelog "%~f3" %jsize%
if %thread% equ 1 for %%a in ("%~f3") do (set /a "ImageSizeJPG+=%%~za" & set /a "TotalSizeJPG+=%jsize%")
exit /b
:jpegfwe
if /i "%~f2" neq "%~f3" (1>nul 2>&1 del /f /q "%filework%")
1>nul 2>&1 del /f /q "%jpglog%"
exit /b 1

::%1 - thread number
::%2 - input file
::%3 - output file
:giffilework
set "gsize=%~z2"
set "errbackup=0"
set "logfile2=%logfile%gif.%1"
set "filework="
if /i "%~f2" equ "%~f3" (
	set "filework1=%tmppath%\%~n2%1%-gifsicle1~x1"
	set "filework=!filework1! "
) else (
	set "filework1=%~f3"
)
set "filework2=%tmppath%\%~n2%1%-gifsicle2~x1"
set "filework=%filework%%filework2%"
if not exist "%~2" (
	call:saverrorlog "%~f2" 3 %~1
	exit /b 1
)
gifsicle --batch %giftags% --optimize=3 --output "%filework1%" "%~2" 1>nul 2>&1
if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:giffwe)
gifsicle --batch %giftags% --output "%filework2%" "%~2" 1>nul 2>&1
if errorlevel 1 (call:saverrorlog "%~f2" 2 %~1 & goto:giffwe)
if /i "%~f2" neq "%~f3" (
	call:backup "%filework1%" "%~f2" >nul || set "errbackup=1"
	call:backup "%filework1%" "%filework2%" true >nul || set "errbackup=1"
) else (
	call:backup "%~f3" "%filework1%" true >nul || set "errbackup=1"
	call:backup "%~f3" "%filework2%" true >nul || set "errbackup=1"
)
if %errbackup% neq 0 (call:saverrorlog "%~f2" 3 %~1 & goto:giffwe)
call:savelog "%~f3" %gsize%
if %thread% equ 1 for %%a in ("%~f3") do (set /a "ImageSizeGIF+=%%~za" & set /a "TotalSizeGIF+=%jsize%")
exit /b
:giffwe
if /i "%~f2" neq "%~f3" if exist "%filework1%" del /f /q "%filework1%"
if exist "%filework2%" del /f /q "%filework2%"
exit /b 1

:backup
if not exist "%~1" exit /b 2
if not exist "%~2" exit /b 3
if %~z2 equ 0 (if "%3" neq "" (1>nul 2>&1 del /f /q "%~2") & exit /b 4)
if %~z1 leq %~z2 (
	if "%3" neq "" (1>nul 2>&1 del /f /q "%~2")
) else (
	1>nul 2>&1 copy /b /y "%~2" "%~1" || exit /b 1
	if "%3" neq "" 1>nul 2>&1 del /f /q "%~2"
)
exit /b

:backup2
if not exist "%~1" exit /b 2
if not exist "%~2" exit /b 3
set "cone="
if %~z2 equ 0 set "cone=yes"
if %~z1 leq %~z2 set "cone=yes"
if defined cone (
	if "%~1" neq "%~3" (1>nul 2>&1 copy /b /y "%~1" "%~3" || exit /b 1)
) else (
	1>nul 2>&1 copy /b /y "%~2" "%~3" || exit /b 1
)
exit /b 0

::%1 - optimize file path
::%2 - original file size
::%3 - thread number
:savelog
set /a "change=%~z1-%2"
if %change% equ 0 call:saverrorlog %1 1
set /a "perc=%change%*100/%2" 2>nul
set /a "fract=%change%*100%%%2*100/%2" 2>nul
set /a "perc=%perc%*100+%fract%"
call:division perc 100 100
>>"%logfile2%" echo.%~1;%2;%~z1;%change%;%perc%;ok
if %thread% equ 1 (
	call:printfileinfo "%~1" %2 %~z1 %change% %perc%
)
exit /b

::%1 - file name
::%2 - 	1 - Images are already optimized
::	2 - Images are not supported
::	3 - Images are not found
::%3 -	thread number
:saverrorlog
if exist "%filework%" 1>nul 2>&1 del /f /q "%filework%"
if "%~2" equ "" exit /b
>>"%filelisterr%%~2.%~3" echo.%~f1
if %thread% equ 1 (call:printfileerr "%~f1" %~2)
exit /b

::%1 - variable name for division (dividend)
::%2 - divider
::%3 - 10^(number of decimal places) - (100 - 2 decimal places, 1000 - 3 decimal places, 1 - no decimals places)
:division
set "sign="
1>nul 2>&1 set /a "int=!%1!/%2"
1>nul 2>&1 set /a "fractd=!%1!*%3/%2%%%3"
if "%fractd:~,1%" equ "-" (set "sign=-" & set "fractd=%fractd:~1%")
1>nul 2>&1 set /a "fractd=%3+%fractd%"
if "%int:~,1%" equ "-" set "sign="
set "%1=%sign%%int%.%fractd:~1%"
exit /b

:end
call:setvtime ftime
set "fract=0"
set "changePNG=0" & set "percPNG=0"
set "changeJPG=0" & set "percJPG=0"
set "changeGIF=0" & set "percGIF=0"
if %jpeg% equ 0 if %png% equ 0 if %gif% equ 0 1>nul 2>&1 ping -n 1 -w 500 127.255.255.255 & goto:finmessage
::set "TotalNumNOptJPG=0" & set "TotalNumNOptPNG=0" & set "TotalNumNOptGIF=0"
::set "stepJPG=0" & set "stepPNG=0" & set "stepGIF=0"
::if %thread% gtr 1 (
::	for /f "tokens=1-5 delims=;" %%a in ('findstr /e /i /r /c:";ok" "%logfile%png*" ') do call:calcstep PNG %%b %%c
::	for /f "tokens=1-5 delims=;" %%a in ('findstr /e /i /r /c:";ok" "%logfile%jpg*" ') do call:calcstep JPG %%b %%c
::	for /f "tokens=1-5 delims=;" %%a in ('findstr /e /i /r /c:";ok" "%logfile%gif*" ') do call:calcstep GIF %%b %%c
::)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";error" "%logfile%png*" 2^>nul ^| find /i /c ";error" 2^>nul') do (
	set /a "TotalNumErrPNG+=%%a" & set /a "TotalNumPNG-=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";error" "%logfile%jpg*" 2^>nul ^| find /i /c ";error" 2^>nul') do (
	set /a "TotalNumErrJPG+=%%a" & set /a "TotalNumJPG-=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";error" "%logfile%gif*" 2^>nul ^| find /i /c ";error" 2^>nul') do (
	set /a "TotalNumErrGIF+=%%a" & set /a "TotalNumGIF-=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";0;0.00;ok" "%logfile%png*" 2^>nul ^| find /i /c ";0;0.00;ok" 2^>nul') do (
	set /a "TotalNumNOptPNG+=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";0;0.00;ok" "%logfile%jpg*" 2^>nul ^| find /i /c ";0;0.00;ok" 2^>nul') do (
	set /a "TotalNumNOptJPG+=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";0;0.00;ok" "%logfile%gif*" 2^>nul ^| find /i /c ";0;0.00;ok" 2^>nul') do (
	set /a "TotalNumNOptGIF+=%%a"
)
call:fincalc PNG
call:fincalc JPG
call:fincalc GIF

::set /a "STotalSizePNG+=%TotalSizePNG%/1024"
::set /a "SImageSizePNG+=%ImageSizePNG%/1024"
::set /a "changePNG=(%ImageSizePNG%-%TotalSizePNG%)" 2>nul
::set /a "percPNG=%changePNG%*100/%TotalSizePNG%" 2>nul
::set /a "fract=%changePNG%*100%%%TotalSizePNG%*100/%TotalSizePNG%" 2>nul
::set /a "percPNG=%percPNG%*100+%fract%" 2>nul
::::call:division changePNG 1024 100
::call:division percPNG 100 100
::set /a "changeJPG=(%ImageSizeJPG%-%TotalSizeJPG%)" 2>nul
::set /a "percJPG=%changeJPG%*100/%TotalSizeJPG%" 2>nul
::set /a "fract=%changeJPG%*100%%%TotalSizeJPG%*100/%TotalSizeJPG%" 2>nul
::set /a "percJPG=%percJPG%*100+%fract%" 2>nul
::::call:division changeJPG 1024 100
::call:division percJPG 100 100
::set /a "changeGIF=(%ImageSizeGIF%-%TotalSizeGIF%)" 2>nul
::set /a "percGIF=%changeGIF%*100/%TotalSizeGIF%" 2>nul
::set /a "fract=%changeGIF%*100%%%TotalSizeGIF%*100/%TotalSizeGIF%" 2>nul
::set /a "percGIF=%percGIF%*100+%fract%" 2>nul
::::call:division changeGIF 1024 100
::call:division percGIF 100 100

:finmessage
call:totalmsg PNG %png%
call:totalmsg JPG %jpeg%
call:totalmsg GIF %gif%
echo. Started  at - %stime%
echo. Finished at - %ftime%
echo.
echo.-------------------------------------------------------------------------------
1>&2 call:listerrfiles
echo. Image optimization is completed.
echo.-------------------------------------------------------------------------------
if /i "%updatecheck%" equ "true" (
	call:waitflag "%iculck%"
	1>nul 2>&1 del /f /q "%iculck%"
	if exist "%iculog%" (
		call:readini "%iculog%"
		if "%version%" neq "!ver!" (
			echo. New version available %name% !ver!.
			echo.-------------------------------------------------------------------------------
			start "" !url!
		)
		1>nul 2>&1 del /f /q "%iculog%"
	)
)
1>nul 2>&1 del /f /q "%logfile%*" "%countJPG%" "%countPNG%*" "%filelist%*" "%filelisterr%*" "%iclock%"
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
exit /b

::%1 - JPG|PNG|GIF
:fincalc
set /a "STotalSize%~1+=!TotalSize%~1!/!step%~1!"
set /a "SImageSize%~1+=!ImageSize%~1!/!step%~1!"
set /a "change%~1=(!SImageSize%~1!-!STotalSize%~1!)" 2>nul
set /a "perc%~1=!change%~1!*100/!STotalSize%~1!" 2>nul
set /a "fract=!change%~1!*100%%!STotalSize%~1!*100/!STotalSize%~1!" 2>nul
set /a "perc%~1=!perc%~1!*100+%fract%" 2>nul
::call:division change%~1 1024 100
call:division perc%~1 100 100
exit /b

::%1 - JPG|PNG|GIF
::%2 - Total Size
::%3 - Image Size
:calcstep
set /a "TotalSize%~1+=%~2"
set /a "ImageSize%~1+=%~2"
if !TotalSize%~1! lss %BYTECONV% if !ImageSize%~1! lss %BYTECONV% exit /b
set /a "STotalSize%~1+=!TotalSize%~1!/!step%~1!"
set /a "SImageSize%~1+=!ImageSize%~1!/!step%~1!"
set "TotalSize%~1=0"
set "ImageSize%~1=0"
if !STotalSize%~1! lss %BYTECONV% if !SImageSize%~1! lss %BYTECONV% exit /b
set /a "step%~1*=10"
set /a "STotalSize%~1/=10"
set /a "SImageSize%~1/=10"
exit /b

:totalmsg
set /a "tt=!TotalNum%~1!+!TotalNumErr%~1!"
if "%tt%" equ "0" exit /b
if "%~2" equ "0" (
	set "opt=0"
	set "tterr=%tt%"
	set "nopt=0"
) else (
	set "nopt=!TotalNumNOpt%~1!"
	set /a "opt=!TotalNum%~1!-!nopt!"
	set "tterr=!TotalNumErr%~1!"
)
echo. Total Number of %1:	%tt%
echo. Optimized %1:		%opt%
if "%nopt%" neq "0" echo. Not optimized %1:	%nopt%
if "%tterr%" neq "0" echo. Skipped %1:		%tterr%
set "stepcur=!step%~1!"
set "stepm=1"
for %%a in (KB KB KB MB MB MB GB GB GB TB TB TB) do (
	set /a "stepcur/=10"
	set /a "stepm=stepm*10%%1000"
	if !stepm! equ 0 set "stepm=1"
	if !stepcur! equ 1 (
		call:division change%~1 1 !stepm!
		echo. Total %1:  		!change%~1! %%a, !perc%~1!%%
))
echo.
exit /b

:listerrfiles
set "iserr="
for %%a in ("%filelisterr%") do if %%~za gtr 0 (
	set "iserr=1"
	echo.
	echo. Image with characters:
	type "%%~a"
	echo.
)
set "iserr2="
for /f "tokens=2* delims=:" %%a in ('findstr /e /i /r /c:";error" "%logfile%*" 2^>nul') do (
	if not defined iserr (set "iserr=1" & echo.)
	if not defined iserr2 (echo. Images with errors:& set "iserr2=1")
	for /f "tokens=1-2 delims=;" %%c in ("%%~b") do echo. %%~c
)
if defined iserr2 echo.
if defined iserr (echo.-------------------------------------------------------------------------------)
set "iserr=" & set "iserr2="
exit /b

:readini
for /f "usebackq tokens=1,* delims== " %%a in ("%~1") do (
	set param=%%a
	if "!param:~,1!" neq ";" if "!param:~,1!" neq "[" set "%%~a=%%~b"
)
exit /b

:helpmsg
title [Manual] %name% %version%
1>&2 (
	echo.-------------------------------------------------------------------------------
	echo. Image Catalyst - optimization / compression images PNG, JPEG and GIF lossless
	echo.
	echo. Recommended to examine ReadMe
	echo.
	echo. call iCatalyst.bat [options] [add folders \ add files]
	echo.
	echo. Options:
	echo.
	echo. /png:#	Optimization settings PNG ^(Non-Interlaced^):
	echo.	1 - Compression level - Xtreme
	echo.	2 - Compression level - Advanced
	echo.	0 - Skip ^(default^)
	echo.
	echo. /jpg:#	Optimization settings JPEG:
	echo.	1 - Encoding Process - Baseline
	echo.	2 - Encoding Process - Progressive
	echo.	3 - uses settings of original images
	echo.	0 - Skip ^(default^)
	echo.
	echo. /gif:#	Optimization settings GIF:
	echo.	1 - uses settings of original images
	echo.	0 - Skip ^(default^)
	echo.
	echo. "/outdir:#" Settings save optimized images:
	echo.	true  - replace the original image on optimized
	echo.	false - open dialog box for saving images ^(default^)
	echo.	"full path to folder" - specify the folder to save images.
	echo.	for example: "/outdir:C:\temp", if the destination folder does not 
	echo.	exist, it will be created automatically.
	echo.
	echo. Add folders \ Add files:
	echo. - Specify the full path to the images and / or folders with images.
	echo.   For example: "C:\Images" "C:\logo.png"
	echo. - The full paths of images should not be special characters. 
	echo.   For example: "&", "%%", "(", ")" etc.
	echo. - The application optimizes images in nested subfolders.
	echo.
	echo. Examples:
	echo. call iCatalyst.bat /gif:1 "/outdir:C:\photos" "C:\images"
	echo. call iCatalyst.bat /png:2 /jpg:2 "/outdir:true" "C:\images"
	echo.-------------------------------------------------------------------------------
)
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
call:dopause & exit /b

:errormsg
title [Error] %name% %version%
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
if "%~1" neq "" 1>&2 echo.%~1
call:dopause
exit /b

:dopause
set "x=%~f0"
echo.%CMDCMDLINE% | 1>nul 2>&1 findstr /ilc:"%x%" && 1>nul 2>&1 pause
set "x="
exit /b
