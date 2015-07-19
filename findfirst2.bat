@echo off
::Тестирование трех вариантов поиска первого файла по маске.
::Варианты:
::	1.Одновременный поиск первого вхождения всех трех типов файлов в одном цикле.
::	2.Последовательный поиск первого вхождения трех типов файлов, каждый тип файлов в своем цикле, последовательный поиск.
::	3.Параллельный поиск первого вхождения трех типов файлов, каждый тип файлов в своем процессе. Межпроцессный обмен с помощью временных файлов. Поиск последнего типа файлов запускается в основном процессе.
::Параметры: %1 - путь к каталогу, в котором будет производится поиск.
::Вариант 2
setlocal enabledelayedexpansion

set "alltypes=*.jpg *.png *.gif"
set "jpgtype=*.jpg *.jpe *.jpeg"
set "pngtype=*.png"
set "giftype=*.gif"

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

exit /b

:initvars
set "jpg="
set "png="
set "gif="
exit /b
