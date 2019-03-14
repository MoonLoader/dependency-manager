@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

SET "LUAROCKS_PATH=%~dp0"
IF "%LUA_PATH%"=="" (
	SET "LUA_PATH=%LUAROCKS_PATH%lua\?.lua;%LUAROCKS_PATH%lua\?\init.lua;.\?.lua;.\?\init.lua"
) ELSE (
	SET "LUA_PATH=%LUAROCKS_PATH%lua\?.lua;%LUAROCKS_PATH%lua\?\init.lua;%LUA_PATH%"
)
IF "%LUA_CPATH%"=="" (
	SET "LUA_CPATH=.\?.dll"
)
REM SET "PATH=%LUAROCKS_PATH%;%PATH%"
"%~dp0..\luajit\bin\luajit.exe" "%LUAROCKS_PATH%luarocks.lua" %*
SET EXITCODE=%ERRORLEVEL%
IF NOT "%EXITCODE%"=="2" GOTO EXITLR

REM Permission denied error, try and auto elevate...
REM already an admin? (checking to prevent loops)
NET SESSION >NUL 2>&1
IF "%ERRORLEVEL%"=="0" GOTO EXITLR

REM Do we have PowerShell available?
PowerShell /? >NUL 2>&1
IF NOT "%ERRORLEVEL%"=="0" GOTO EXITLR

:GETTEMPNAME
SET TMPFILE=%TEMP%\LuaRocks-Elevator-%RANDOM%.bat
IF EXIST "%TMPFILE%" GOTO :GETTEMPNAME

ECHO @ECHO OFF                                  >  "%TMPFILE%"
ECHO CHDIR /D %CD%                              >> "%TMPFILE%"
ECHO ECHO %0 %*                                 >> "%TMPFILE%"
ECHO ECHO.                                      >> "%TMPFILE%"
ECHO CALL %0 %*                                 >> "%TMPFILE%"
ECHO ECHO.                                      >> "%TMPFILE%"
ECHO ECHO Press any key to close this window... >> "%TMPFILE%"
ECHO PAUSE ^> NUL                               >> "%TMPFILE%"
ECHO DEL "%TMPFILE%"                            >> "%TMPFILE%"

ECHO Now retrying as a privileged user...
PowerShell -Command (New-Object -com 'Shell.Application').ShellExecute('%TMPFILE%', '', '', 'runas')

:EXITLR
exit /b %EXITCODE%
