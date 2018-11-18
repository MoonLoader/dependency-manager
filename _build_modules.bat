@echo off
:: used only to build binary rocks
set LUAROCKS=..\luarocks\luarocks
md distro\binary_rocks
pushd distro\binary_rocks
set "CFLAGS=CFLAGS=/nologo /MD /O2 /D_USING_V110_SDK71_ /D_WIN32_WINNT=0x0501"
set "LRFLAGS=--pack-binary-rock --deps-mode=none"
set ZLIB_LIBDIR=D:\Dev\SDK\zlib-1.2.11\build\install\lib
set ZLIB_INCDIR=D:\Dev\SDK\zlib-1.2.11\build\install\include
set OPENSSL_DIR=D:\Dev\SDK\openssl\build\install
set OPENSSL_LIBDIR=D:\Dev\SDK\openssl\build\install\lib
set "USE_SPECIAL_ROCKS_SERVER=--only-server=http://luarocks.org/manifests/fyp"

call %LUAROCKS% download luafilesystem 1.7.0-2 --rockspec
call %LUAROCKS% build luafilesystem 1.7.0-2 "%CFLAGS%" %LRFLAGS%
call %LUAROCKS% download luasocket 3.0rc1-2 --rockspec
call %LUAROCKS% build luasocket 3.0rc1-2 "%CFLAGS% /DLUASOCKET_INET_PTON" %LRFLAGS%
call %LUAROCKS% download md5 1.2-1 --rockspec
call %LUAROCKS% build md5 1.2-1 "%CFLAGS%" %LRFLAGS%
call %LUAROCKS% build lzlib 0.4.1.53-1 "ZLIB_LIBDIR=%ZLIB_LIBDIR%" "ZLIB_INCDIR=%ZLIB_INCDIR%" "%CFLAGS%" %USE_SPECIAL_ROCKS_SERVER% %LRFLAGS%
call %LUAROCKS% build luasec 0.7-1 OPENSSL_DIR=%OPENSSL_DIR% OPENSSL_LIBDIR=%OPENSSL_LIBDIR% "%CFLAGS%" %USE_SPECIAL_ROCKS_SERVER% %LRFLAGS%
popd
