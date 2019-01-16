@echo off
rd /s /q distro

robocopy lua\ distro\ /E
md distro\lib

robocopy luajit\src\ distro\luajit\lib\ lua51.lib luajit.lib
robocopy luajit\src\ distro\luajit\inc\ lauxlib.h lua.h lua.hpp luaconf.h luajit.h lualib.h
robocopy luajit\src\ distro\luajit\bin\ lua51.dll luajit.exe
robocopy luajit\src\jit\ distro\luajit\bin\jit\ *.lua
robocopy scripts\ distro\luajit\ lua.bat

robocopy config\ distro\luarocks\ config-*.lua
robocopy scripts\ distro\luarocks\ luarocks.bat luarocks-admin.bat
robocopy luarocks\src\luarocks distro\luarocks\lua\luarocks\ /E
robocopy luarocks\win32\ distro\luarocks\tools\ COPYING*
robocopy luarocks\win32\ distro\luarocks\ luarocksw.bat
robocopy luarocks\win32\tools distro\luarocks\tools\ /E
xcopy luarocks\src\bin\* distro\luarocks\*.lua
md distro\luarocks\systree

if /I "%1"=="without-modules" goto :EOF

:: init deps manager and install modules for luarocks
pushd distro
call luajit\lua -e "require'deps'"
cd luarocks

SET "LRFLAGS=--tree=libstd --only-server=http://luarocks.org/manifests/fyp"
call luarocks install luafilesystem 1.7.0-2 %LRFLAGS%
call luarocks install mimetypes 1.0.0-2 --tree=libstd
call luarocks install luasocket 3.0rc1-2 %LRFLAGS%
call luarocks install md5 1.2-1 %LRFLAGS%
call luarocks install lzlib 0.4.1.53-1 %LRFLAGS%
call luarocks install luasec 0.7-1 %LRFLAGS%

del path.txt
del lua\luarocks\core\hardcoded.lua

:: enable using modules
echo fs_use_modules = true>> config-5.1.lua
:: executables aren't needed anymore
rd /s /q tools
popd
