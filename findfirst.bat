@echo off
::Тестирование трех вариантов поиска первого файла по маске.
::Варианты:
::	1.Одновременный поиск первого вхождения всех трех типов файлов в одном цикле.
::	2.Последовательный поиск первого вхождения трех типов файлов, каждый тип файлов в своем цикле, последовательный поиск.
::	3.Параллельный поиск первого вхождения трех типов файлов, каждый тип файлов в своем процессе. Межпроцессный обмен с помощью временных файлов. Поиск последнего типа файлов запускается в основном процессе.
::Параметры: %1 - путь к каталогу, в котором будет производится поиск.
setlocal enabledelayedexpansion
if "%~2" equ "findfirst" goto:findfirst

set "alltypes=*.jpg *.png *.gif"
set "jpgtype=*.jpg *.jpe *.jpeg"
set "pngtype=*.png"
set "giftype=*.gif"
set "jpglock=jpg.lck"
set "pnglock=png.lck"
set "giflock=gif.lck"
set "jpgtmp=jpg.tmp"
set "pngtmp=png.tmp"
set "giftmp=gif.tmp"
set "timeout=3"

echo.1.Одновременный поиск (в одном цикле все типы файлов)
call:initvars
echo.%time%
for /r "%~1" %%a in (%alltypes%) do (
	if /i "%%~xa" equ ".jpg" if not defined jpg set "jpg=1"
	if /i "%%~xa" equ ".png" if not defined png set "png=1"
	if /i "%%~xa" equ ".gif" if not defined gif set "gif=1"
	if defined jpg if defined png if defined gif goto:fin1
)
:fin1
echo.%time%
echo.jpg=%jpg%	png=%png%	gif=%gif%
if defined jpg if defined png if defined gif (echo.Найдены все типы & goto:fin11)
echo.Найдены не все типы
:fin11

echo.2.Последовательный поиск (каждый тип файлов в своем цикле)
call:initvars
echo.%time%
for /r "%~1" %%a in (%jpgtype%) do set "jpg=1" & goto:fin2jpg
:fin2jpg
for /r "%~1" %%a in (%pngtype%) do set "png=1" & goto:fin2png
:fin2png
for /r "%~1" %%a in (%giftype%) do set "gif=1" & goto:fin2gif
:fin2gif
echo.%time%
echo.jpg=%jpg%	png=%png%	gif=%gif%
if defined jpg if defined png if defined gif (echo.Найдены все типы & goto:fin2)
echo.Найдены не все типы
:fin2

echo.3.Параллельный поиск (каждый тип файлов в своем процессе)
call:initvars
echo.%time%
::Старт процессов
start /b cmd /c "%~0 %~1 findfirst jpg"
start /b cmd /c "%~0 %~1 findfirst png"
::start /b cmd /c "%~0 %~1 findfirst gif"
call:findfirst "%~1" findfirst gif

::Проверка завершенности процессов
call:waitforfile "%jpglock%"
call:waitforfile "%pnglock%"
::call:waitforfile "%giflock%"

::Итоги
echo.%time%
<"%jpgtmp%" set /p "jpg="
<"%pngtmp%" set /p "png="
<"%giftmp%" set /p "gif="
echo.jpg=%jpg%	png=%png%	gif=%gif%
if defined jpg if defined png if defined gif (echo.Найдены все типы & goto:fin3)
echo.Найдены не все типы
:fin3
1>nul 2>&1 del /f/q "%jpgtmp%" "%pngtmp%" "%giftmp%"

exit /b

:waitforfile
if exist "%~1" (1>nul timeout /t %timeout% /nobreak & goto:waitforfile)
exit /b

:initvars
set "jpg="
set "png="
set "gif="
exit /b

:findfirst
call set "lck=%%%~3lock%%"
call set "ftmp=%%%~3tmp%%"
call set "type=%%%~3type%%"
>"%lck%" echo.
for /r "%~1" %%a in (%type%) do (>"%ftmp%" echo.1 & goto:endfindfirst)
>"%ftmp%" echo.0
:endfindfirst
1>nul del /f/q "%lck%"
exit /b
