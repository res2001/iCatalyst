@echo off
::Тестирование трех вариантов поиска первого файла по маске.
::Варианты:
::	1.Одновременный поиск первого вхождения всех трех типов файлов в одном цикле.
::	2.Последовательный поиск первого вхождения трех типов файлов, каждый тип файлов в своем цикле, последовательный поиск.
::	3.Параллельный поиск первого вхождения трех типов файлов, каждый тип файлов в своем процессе. Межпроцессный обмен с помощью временных файлов. Поиск последнего типа файлов запускается в основном процессе.
::Параметры: %1 - путь к каталогу, в котором будет производится поиск.
::Вариант 1
setlocal enabledelayedexpansion

set "alltypes=*.jpg *.png *.gif"
set "jpgtype=*.jpg *.jpe *.jpeg"
set "pngtype=*.png"
set "giftype=*.gif"

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

exit /b

:initvars
set "jpg="
set "png="
set "gif="
exit /b
