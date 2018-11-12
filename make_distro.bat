@echo off
rd /s /q distro

robocopy lua\ distro\ /E

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
