@ECHO OFF
setlocal enabledelayedexpansion

rem Количество итераций
Set "cnt=100"
::Максимальный размер строки индикатора
set "ilen=20"
::Маркер индикатора
set "imark=+"
::Символ заполнитель
set "iblank= "
::Текущая позиция маркера в индикаторе
set "imarkpos=1"
::Начальный и конечный символы границы области индикатора
set "boxb=["
set "boxe=]"

::Инициализация области индикатора
set "istrbs="
for /l %%i in (1,1,%ilen%) do set "istrbs=!istrbs!"
set "istrblank="
for /l %%i in (1,1,%ilen%) do set "istrblank=!istrblank!%iblank%"
0<nul set /p "=%boxb%%istrblank%%boxe%%istrbs%%iblank%"
::Основной цикл
for /l %%i in (1,1,%cnt%) do (
	Call:Bar %%i
	1>nul 2>&1 ping -n 1 -w 1 127.255.255.255
)
::Подтираем за собой
set "istrblank="
0>nul set /p "=!istrbs!"
for /l %%i in (1,1,%ilen%) do set "istrblank=!istrblank! "
0>nul set /p "=%boxb%%istrblank% "
0>nul set /p "=%istrbs% "

>nul pause & goto:eof

:Bar
if %imarkpos% equ 0 (
	set "imarkpos=1"
	0<nul set /p "=%iblank%%istrbs%%imark%"
) else (
	0<Nul Set /p "=%iblank%%imark%"
	set /a "imarkpos=(imarkpos+1)%%ilen"
)
exit /b
