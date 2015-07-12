@ECHO OFF
setlocal enabledelayedexpansion

rem Количество итераций
Set "cnt=120"
::Максимальный размер строки индикатора
set "ilen=20"
::Маркерный символ индикатора
set "imark=0"
::Длинна индикатора
set "imarklen=3"
::На сколько позиций сдвигать маркер каждую итерацию
set "imarkskip=2"
::Символ заполнитель (фон)
set "iblank=9"
::Текущая позиция маркера в индикаторе
set "imarkpos=0"
::Начальный и конечный символы границы области индикатора
set "boxb=["
set "boxe=]"

set /a "imu=%imarklen%"

::Инициализация области индикатора
set "istrbs="
for /l %%i in (1,1,%ilen%) do set "istrbs=!istrbs!"
set "istrblank="
for /l %%i in (1,1,%ilen%) do set "istrblank=!istrblank!%iblank%"
set "imarkbs="
for /l %%i in (1,1,%imarklen%) do set "imarkbs=!imarkbs!"
set "imarkstr="
for /l %%i in (1,1,%imarklen%) do set "imarkstr=!imarkstr!%imark%"

0<nul set /p "=%boxb%%istrblank%%boxe%%istrbs%"
::Основной цикл
for /l %%i in (1,1,%cnt%) do (
	Call:Bar %%i
	1>nul 2>&1 ping -n 1 -w 1 127.255.255.255
)


::Подтираем за собой
::set "istrblank="
::0>nul set /p "=!istrbs!"
::for /l %%i in (1,1,%ilen%) do set "istrblank=!istrblank! "
::0>nul set /p "=%boxb%%istrblank% "
::0>nul set /p "=%istrbs% "

>nul pause & goto:eof

:Bar
if %imu% gtr 0 (
	if %imarkpos% lss %imarklen% (
		0<nul set /p "=%imark%"
	) else if %imarkpos% gtr %ilen% (
		for /l %%j in (1,1,%imu%) do 0<nul set /p "="
		0<nul set /p "=%iblank%"
		for /l %%j in (2,1,%imu%) do 0<nul set /p "=%imark%"
		set /a "imu-=1"
		if !imu! equ 1 set "imu=-%imarklen%"
		set /a "imarkpos-=1"
	) else 0<nul set /p "=%imarkbs%%iblank%%imarkstr%"
	set /a "imarkpos+=1"
)
::if %imarkpos% gtr %imarklen%
::echo.%imarkpos%	

::0<nul set /p "=%imark%"

exit /b

if %imarkpos% equ 0 (
	set "imarkpos=1"
	0<nul set /p "=%iblank%%istrbs%%imark%"
) else (
	0<Nul Set /p "=%iblank%%imark%"
	set /a "imarkpos=(imarkpos+1)%%ilen"
)
exit /b
