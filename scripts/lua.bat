@ECHO OFF

SETLOCAL
CALL :NORMALIZEPATH "%~dp0..\luarocks"
SET "LUAROCKS_PATH=%RETVAL%"
CALL :NORMALIZEPATH "%~dp0..\lib"
SET "LIB_PATH=%RETVAL%"
SET "LUA_PATH=%LIB_PATH%\std\?.lua;%LIB_PATH%\std\?\init.lua;%LIB_PATH%\?.luac;%LIB_PATH%\?\init.luac;%LUAROCKS_PATH%\lua\?.lua;%LUAROCKS_PATH%\lua\?\init.lua"
SET "LUA_CPATH=%LIB_PATH%\std\?.dll"
ENDLOCAL & SET "LUA_PATH=%LUA_PATH%" & SET "LUA_CPATH=%LUA_CPATH%"

"%~dp0\bin\luajit.exe" -lluarocks.loader %*

GOTO :EOF

:NORMALIZEPATH
  SET RETVAL=%~dpfn1
  EXIT /B
