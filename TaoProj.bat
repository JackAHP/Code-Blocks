@echo off
setlocal EnableDelayedExpansion

set /p "START=Start project name: "
if not defined START (
    echo Error: name cannot be empty.
    pause
    exit /b 1
)

call :AnalyzeName "%START%" MODE1 CLEAN1 PREFIX1 NUMSTR1

if "%MODE1%"=="SINGLE" (
    if not defined CLEAN1 (
        echo Error: name cannot be empty.
        pause
        exit /b 1
    )
    call :SetupCB
    if errorlevel 1 exit /b 1

    call :CreateProject "%CLEAN1%" ""

    if exist "!CLEAN1!\!CLEAN1!.cbp" (
        echo Opening !CLEAN1!...
        start "" "!CB!" "%CD%\!CLEAN1!\!CLEAN1!.cbp"
    )
    goto :End
)

call :StripZeros "%NUMSTR1%" N1STR
set /a N1=!N1STR!

set /p "END=End (name or number): "
if not defined END (
    echo Error: name cannot be empty.
    pause
    exit /b 1
)

echo(%END%| findstr /r "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    call :StripZeros "%END%" N2STR
    set /a N2=!N2STR!
) else (
    call :StrLen "%PREFIX1%" PLEN
    set "ENDHEAD=!END:~0,%PLEN%!"
    if /I not "!ENDHEAD!"=="%PREFIX1%" (
        echo Error: Start/End must share prefix.
        pause
        exit /b 1
    )
    set "ENDTAIL=!END:~%PLEN%!"
    echo(!ENDTAIL!| findstr /r "^[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo Error: invalid End name.
        pause
        exit /b 1
    )
    call :StripZeros "!ENDTAIL!" N2STR
    set /a N2=!N2STR!
)

if !N1! GTR !N2! (
    echo Error: Start ^> End.
    pause
    exit /b 1
)

call :FormatNum !N1! 2 NUMFIRST
set "FIRSTNAME=%PREFIX1%!NUMFIRST!"
call :FormatNum !N2! 2 NUMLAST
set "LASTNAME=%PREFIX1%!NUMLAST!"
set "WORKSPACE=!FIRSTNAME!-!LASTNAME!.workspace"
set "CREATE_WS=1"

if exist "!WORKSPACE!" (
    echo !WORKSPACE! exists.
    choice /C YN /M "Overwrite"
    if errorlevel 2 (
        set "CREATE_WS=0"
    ) else (
        del /f /q "!WORKSPACE!"
    )
)

if "!CREATE_WS!"=="1" (
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<CodeBlocks_workspace_file^>
echo     ^<Workspace title="!FIRSTNAME!-!LASTNAME!"^>
) > "!WORKSPACE!"
)

call :SetupCB
if errorlevel 1 exit /b 1

set "CLONE=0"
if !N2! GTR !N1! (
    echo ENTER=create all, other key=Clone Mode
    for /f %%K in ('powershell -NoProfile -Command "$k=[Console]::ReadKey($true).Key; if($k -eq 'Enter'){'0'}else{'1'}"') do set "CLONE=%%K"
    if "!CLONE!"=="1" echo Clone Mode.
)

call :CreateProject "!FIRSTNAME!" ""

set "CLONESRC="

if "!CLONE!"=="1" (
    if exist "!FIRSTNAME!\!FIRSTNAME!.cbp" (
        echo Opening !FIRSTNAME!...
        start "" "!CB!" "%CD%\!FIRSTNAME!\!FIRSTNAME!.cbp"
    )
    set /p "=Edit !FIRSTNAME!.cpp, save, then press Enter..."
    echo.

    findstr /c:"!FIRSTNAME!.INP" "!FIRSTNAME!\!FIRSTNAME!.cpp" >nul 2>&1
    if errorlevel 1 (
        echo Error: freopen ^(!FIRSTNAME!.INP^) not found.
        pause
        exit /b 1
    )
    findstr /c:"!FIRSTNAME!.OUT" "!FIRSTNAME!\!FIRSTNAME!.cpp" >nul 2>&1
    if errorlevel 1 (
        echo Error: freopen ^(!FIRSTNAME!.OUT^) not found.
        pause
        exit /b 1
    )

    set "CLONESRC=!FIRSTNAME!"
)

set /a NEXTN=N1+1
for /l %%i in (!NEXTN!,1,!N2!) do (
    call :FormatNum %%i 2 NUMI
    call :CreateProject "!PREFIX1!!NUMI!" "!CLONESRC!"
)

if "!CREATE_WS!"=="1" (
(
echo     ^</Workspace^>
echo ^</CodeBlocks_workspace_file^>
) >> "!WORKSPACE!"
)

echo Workspace: !WORKSPACE!

if exist "!WORKSPACE!" (
    start "" "!CB!" "%CD%\!WORKSPACE!"
)

:End
exit /b 0

:: ==================================================================
:: Subroutines
:: ==================================================================

:AnalyzeName
:: %1=raw name -> %2=MODE(SINGLE/MULTI) %3=clean name %4=prefix %5=2-digit numstr
setlocal EnableDelayedExpansion
set "n=%~1"

if "!n:~-1!"=="/" (
    set "n=!n:~0,-1!"
    set "mode=SINGLE"
    set "prefix="
    set "numstr="
) else (
    set "last2=!n:~-2!"
    echo(!last2!| findstr /r "^[0-9][0-9]$" >nul
    if not errorlevel 1 (
        set "mode=MULTI"
        set "numstr=!last2!"
        set "prefix=!n:~0,-2!"
    ) else (
        set "mode=SINGLE"
        set "prefix="
        set "numstr="
    )
)

endlocal & set "%~2=%mode%" & set "%~3=%n%" & set "%~4=%prefix%" & set "%~5=%numstr%"
exit /b

:StrLen
setlocal
set "s=%~1"
set "len=0"
:StrLen_loop
if defined s (
    set "s=%s:~1%"
    set /a len+=1
    goto :StrLen_loop
)
endlocal & set "%~2=%len%"
exit /b

:StripZeros
setlocal
set "s=%~1"
if not defined s set "s=0"
:StripZeros_loop
if "%s:~0,1%"=="0" if not "%s%"=="0" (
    set "s=%s:~1%"
    goto :StripZeros_loop
)
endlocal & set "%~2=%s%"
exit /b

:FormatNum
:: %1=number %2=min width %3=result var
setlocal EnableDelayedExpansion
set "n=%~1"
set "w=%~2"
call :StrLen "!n!" nlen
if !nlen! GEQ !w! (
    set "pad=!n!"
) else (
    set "pad=0000000000!n!"
    set "pad=!pad:~-%w%!"
)
endlocal & set "%~3=%pad%"
exit /b

:SetupCB
set "CB="
if exist "C:\Program Files\CodeBlocks\codeblocks.exe" set "CB=C:\Program Files\CodeBlocks\codeblocks.exe"
if not defined CB if exist "C:\Program Files (x86)\CodeBlocks\codeblocks.exe" set "CB=C:\Program Files (x86)\CodeBlocks\codeblocks.exe"
if not defined CB (
    for /f "delims=" %%F in ('where codeblocks.exe 2^>nul') do (
        set "CB=%%F"
        goto :SetupCB_found
    )
)
:SetupCB_found
if not defined CB (
    echo Code::Blocks not found.
    set /p "CB=Path to codeblocks.exe: "
    if not exist "!CB!" (
        echo Invalid path.
        exit /b 1
    )
)
exit /b 0

:CreateProject
setlocal EnableDelayedExpansion
set "NAME=%~1"
set "CLONE_SRC=%~2"
set "SKIP=0"

if exist "!NAME!" (
    echo !NAME! exists.
    choice /C YN /M "Overwrite"
    if errorlevel 2 (
        set "SKIP=1"
    ) else (
        rd /s /q "!NAME!"
    )
)

if "!SKIP!"=="0" (
    mkdir "!NAME!"
    type nul > "!NAME!\!NAME!.INP"
    type nul > "!NAME!\!NAME!.OUT"

    if defined CLONE_SRC (
        powershell -NoProfile -Command "(Get-Content -Raw '!CLONE_SRC!\!CLONE_SRC!.cpp') -replace [regex]::Escape('!CLONE_SRC!.INP'), '!NAME!.INP' -replace [regex]::Escape('!CLONE_SRC!.OUT'), '!NAME!.OUT' | Set-Content -NoNewline '!NAME!\!NAME!.cpp'"
    ) else (
        (
        echo #include ^<bits/stdc++.h^>
        echo using namespace std;
        echo using ll = long long;
        echo using ull = unsigned long long;
        echo.
        echo int main^(^){
        echo     freopen^("!NAME!.INP", "r", stdin^);
        echo     freopen^("!NAME!.OUT", "w", stdout^);
        echo.
        echo     long long n;
        echo     cin ^>^> n;
        echo.
        echo     return 0;
        echo ^}
        ) > "!NAME!\!NAME!.cpp"
    )

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
)

if "!CREATE_WS!"=="1" if exist "!NAME!\!NAME!.cbp" (
    echo         ^<Project filename="!NAME!\!NAME!.cbp" /^> >> "!WORKSPACE!"
)

endlocal & set "SKIP=%SKIP%"
exit /b
