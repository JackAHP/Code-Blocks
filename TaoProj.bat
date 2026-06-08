@echo off
setlocal EnableDelayedExpansion

set /p START=Project dau:
set /p END=Project cuoi:

set PREFIX1=%START:~0,1%
set PREFIX2=%END:~0,1%

if /I not "%PREFIX1%"=="%PREFIX2%" (
    echo.
    echo Loi: Hai project phai cung chu cai dau.
    pause
    exit /b
)

set /a N1=1%START:~1,2%-100
set /a N2=1%END:~1,2%-100

set WORKSPACE=%START%-%END%.workspace

rem ======================================
rem Xu ly workspace
rem ======================================

set CREATE_WS=1

if exist "%WORKSPACE%" (
    echo.
    echo File "%WORKSPACE%" da ton tai.
    choice /C YN /M "Overwrite"

    if errorlevel 2 (
        set CREATE_WS=0
        echo Giu nguyen workspace cu.
    ) else (
        del /f /q "%WORKSPACE%"
    )
)

if !CREATE_WS!==1 (
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<CodeBlocks_workspace_file^>
echo     ^<Workspace title="%START%-%END%"^>
) > "%WORKSPACE%"
)

for /L %%i in (%N1%,1,%N2%) do (

    if %%i LSS 10 (
        set NUM=0%%i
    ) else (
        set NUM=%%i
    )

    set NAME=%PREFIX1%!NUM!

    set SKIP=0

    if exist "!NAME!" (
        echo.
        echo Folder "!NAME!" da ton tai.
        choice /C YN /M "Overwrite"

        if errorlevel 2 (
            set SKIP=1
        ) else (
            rd /s /q "!NAME!"
        )
    )

    if !SKIP!==0 (

        echo Tao !NAME!...

        mkdir "!NAME!"

        type nul > "!NAME!\!NAME!.INP"
        type nul > "!NAME!\!NAME!.OUT"

        (
        echo #include ^<bits/stdc++.h^>
        echo using namespace std;
        echo.
        echo int main^(^){
        echo     freopen^("!NAME!.INP", "r", stdin^);
        echo     freopen^("!NAME!.OUT", "w", stdout^);
        echo.
        echo     long long n;
        echo     cin ^>^> n;
        echo.
        echo     long long a[n];
        echo     for^(int i=0;i^<n;i++^) cin ^>^> a[i];
        echo.
        echo     return 0;
        echo ^}
        ) > "!NAME!\!NAME!.cpp"

        (
        echo ^<?xml version="1.0" encoding="UTF-8"?^>
        echo ^<CodeBlocks_project_file^>
        echo     ^<FileVersion major="1" minor="6" /^>
        echo     ^<Project^>
        echo         ^<Option title="!NAME!" /^>
        echo         ^<Build /^>
        echo.
        echo         ^<Unit filename="!NAME!.cpp" /^>
        echo         ^<Unit filename="!NAME!.INP" /^>
        echo         ^<Unit filename="!NAME!.OUT" /^>
        echo.
        echo     ^</Project^>
        echo ^</CodeBlocks_project_file^>
        ) > "!NAME!\!NAME!.cbp"

        if !CREATE_WS!==1 (
            echo         ^<Project filename="!NAME!\!NAME!.cbp" /^> >> "%WORKSPACE%"
        )
    )
)

if !CREATE_WS!==1 (
(
echo     ^</Workspace^>
echo ^</CodeBlocks_workspace_file^>
) >> "%WORKSPACE%"
)

echo.
if !CREATE_WS!==1 (
    echo Da tao workspace: %WORKSPACE%
) else (
    echo Khong tao lai workspace.
)

rem ======================================
rem Tim Code::Blocks
rem ======================================

set CB=

if exist "C:\Program Files\CodeBlocks\codeblocks.exe" (
    set "CB=C:\Program Files\CodeBlocks\codeblocks.exe"
)

if not defined CB if exist "C:\Program Files (x86)\CodeBlocks\codeblocks.exe" (
    set "CB=C:\Program Files (x86)\CodeBlocks\codeblocks.exe"
)

if not defined CB (
    for /f "delims=" %%F in ('where codeblocks.exe 2^>nul') do (
        set "CB=%%F"
        goto FoundCB
    )
)

:FoundCB

if not defined CB (
    echo.
    echo Khong tim thay Code::Blocks.
    echo.
    set /p CB=Nhap duong dan day du den codeblocks.exe:

    if not exist "!CB!" (
        echo.
        echo Duong dan khong hop le:
        echo !CB!
        pause
        exit /b
    )
)

echo.
echo Code::Blocks:
echo !CB!

if exist "%WORKSPACE%" (
    echo.
    echo Dang mo workspace...
    start "" "!CB!" "%CD%\%WORKSPACE%"
)

exit