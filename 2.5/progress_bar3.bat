@echo off
::Вращающаяся палка
SetLocal EnableDelayedExpansion

0<nul set /p "= "
for /L %%a In (1,1,1024) Do (
	set /a "n=%%a%%8"
	if !n! equ 0 0<Nul Set /p "=|"
	if !n! equ 1 0<Nul Set /p "=/"
	if !n! equ 2 0<Nul Set /p "=-"
	if !n! equ 3 0<Nul Set /p "=\"
	if !n! equ 4 0<Nul Set /p "=|"
	if !n! equ 5 0<Nul Set /p "=/"
	if !n! equ 6 0<Nul Set /p "=-"
	if !n! equ 7 0<Nul Set /p "=\"
	1>nul 2>&1 ping -n 1 -w 10 127.255.255.255
)
