@echo off
setlocal

REM Thu muc chua file BAT
set CURDIR=%~dp0

REM Bo dau \ cuoi
set CURDIR=%CURDIR:~0,-1%

REM Ten thu muc cuoi cung
for %%F in ("%CURDIR%") do set FOLDERNAME=%%~nxF

REM O dia chua file BAT
set DRIVE=%~d0

REM Thu muc dich
set DEST=%DRIVE%\%FOLDERNAME%_NB

echo Tao thu muc:
echo %DEST%

if not exist "%DEST%" mkdir "%DEST%"

for /r "%CURDIR%" %%F in (*.cpp) do copy "%%F" "%DEST%\" >nul

echo.
echo Da copy xong cac file CPP.
echo Thu muc dich:
echo %DEST%

pause