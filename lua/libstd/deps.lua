-- This file is part of SA MoonLoader package.
-- Licensed under the MIT License.
-- Copyright (c) 2018, BlastHack Team <blast.hk>

-- DEBUG
if not getWorkingDirectory then
	local ffi = require 'ffi'
	ffi.cdef [[unsigned long GetCurrentDirectoryA(unsigned long nBufferLength, char* lpBuffer);]]
	function getWorkingDirectory()
		local buf = ffi.new('char[260]')
		local written = ffi.C.GetCurrentDirectoryA(ffi.sizeof(buf), buf)
		if written > 0 then
			return ffi.string(buf, written)
		end
		return '.'
	end
end
if not script then
	script = {this = {filename = 'debug.lua'}}
end

local workdir = getWorkingDirectory()

local config = {
	PREFIX          = workdir .. [[\luarocks]],
	WIN_TOOLS       = workdir .. [[\luarocks\tools]],
	SYSCONFDIR      = workdir .. [[\luarocks]],
	LUA_DIR         = workdir .. [[\luajit]],
	LUA_INCDIR      = workdir .. [[\luajit\inc]],
	LUA_LIBDIR      = workdir .. [[\luajit\lib]],
	LUA_BINDIR      = workdir .. [[\luajit\bin]],
	LUA_INTERPRETER = [[luajit.exe]],
	SYSTEM          = [[windows]],
	PROCESSOR       = [[x86]],
	FORCE_CONFIG    = true,
}

local function rewrite_hardcoded_config()
	local hc = assert(io.open(config.PREFIX .. [[\lua\luarocks\core\hardcoded.lua]], 'w'))
	hc:write('return {\n')
	for k, v in pairs(config) do
		if type(v) == 'string' then
			hc:write(('\t%s = [[%s]],\n'):format(k, v))
		else
			hc:write(('\t%s = %s,\n'):format(k, v))
		end
	end
	hc:write('}\n')
	hc:close()
end

local function configure()
	local f = io.open(workdir .. [[\luarocks\path.txt]], 'r')
	local path
	if f then
		path = f:read('*all')
		f:close()
	end
	if workdir ~= path then
		rewrite_hardcoded_config()
		f = assert(io.open(workdir .. [[\luarocks\path.txt]], 'w'))
		f:write(workdir)
		f:close()
	end
end

local luarocks_luapath = config.PREFIX .. [[\lua\?.lua;]] .. config.PREFIX .. [[\lua\?\init.lua]]
local function run_luarocks(cmd)
	local interpreter = config.LUA_BINDIR .. '\\' .. config.LUA_INTERPRETER
	local luarocks_cmd = ('"%s" "-e package.path=[[%s]]" "%s\\luarocks.lua" --tree=system %s 2>&1'):format(interpreter, luarocks_luapath, config.PREFIX, cmd)
	local proc = io.popen(luarocks_cmd)
	local output = proc:read('*all')
	local result = proc:close()
	return result, output
end

local function parse_package_string(dep)
	local verpos = dep:find('@[^@]*$')
	local version, server
	if verpos then
		version = dep:sub(verpos + 1)
		dep = dep:sub(1, verpos - 1)
	end
	local srvpos = dep:find(':[^:]*$')
	if srvpos then
		server = dep:sub(1, srvpos - 1)
		dep = dep:sub(srvpos + 1)
	end
	local name = dep
	return name, version, server
end

local luarocks
local function init_luarocks()
	if luarocks then
		return luarocks
	end
	local luapath = package.path
	package.path = luarocks_luapath .. ';' .. package.path
	luarocks = {
		queries = require('luarocks.queries'),
		search = require('luarocks.search'),
		cfg = require('luarocks.core.cfg'),
		fs = require('luarocks.fs'),
	}
	local ok, err = luarocks.cfg.init()
	if not ok then
		package.path = luapath
		return nil, err
	end
	luarocks.fs.init()
	if doesFileExist and doesDirectoryExist then
		-- replace a couple of FS functions to avoid popping up console windows
		luarocks.fs.current_dir = function()
			return workdir
		end
		luarocks.fs.exists = function(path)
			return doesFileExist(path) or doesDirectoryExist(path)
		end
	end
	package.path = luapath
	return luarocks
end

local function test_installed_package(name, version)
	local luarocks, err = init_luarocks()
	if not luarocks then
		return nil, err
	end
	local query = luarocks.queries.new(name:lower(), version, nil, nil, '>=')
	local rock_name, rock_version = luarocks.search.pick_installed_rock(query)
	if rock_name then
		return true
	end
	-- 'rock_version' is error message
	if rock_version:find('cannot find package') then
		return false
	end
	return nil, rock_version
end

local function install_package(name, version, server)
	local fetch_from = ''
	if server then
		if server:match('[%w]+://') then
			fetch_from = '--server=' .. server
		else
			fetch_from = '--server=http://luarocks.org/manifests/' .. server
		end
	end
	local res, out = run_luarocks(('--timeout=10 %s install %s %s'):format(fetch_from, name, version or ''))
	if not res then
		return false, out
	end
	return true
end

local ffi
local function msgbox(text, title, style)
	if not ffi then
		ffi = require 'ffi'
		ffi.cdef [[int MessageBoxA(void* hWnd, const char* lpText, const char* lpCaption, unsigned int uType);]]
	end
	local hwnd = ffi.cast('void*', readMemory(0x00C8CF88, 4, false))
	return ffi.C.MessageBoxA(hwnd, text, '[MoonLoader] ' .. script.this.filename .. ': ' .. title, style and (style + 0x50000) or 0x50000)
end

local function failure(msg)
	msgbox(msg, 'Failed to install dependencies', 0x10)
	error(msg)
end

local function batch_install(packages)
	local to_install = {}
	local time_test, time_install = os.clock(), nil
	for i, dep in ipairs(packages) do
		local name, version, server = parse_package_string(dep)
		local installed, err = test_installed_package(name, version)
		if not installed then
			if err then
				failure(dep .. '\n' .. err)
			end
			table.insert(to_install, {name = name, ver = version, svr = server, full = dep})
		end
	end
	time_test = os.clock() - time_test
	if #to_install > 0 then
		local list = ''
		for i, pkg in ipairs(to_install) do
			list = list .. pkg.full .. '\n'
		end
		if 7 --[[IDNO]] == msgbox('Script "' .. script.this.filename .. '" asks to install the following packages:\n\n' ..
			list .. '\nInstallation process will take some time.\nProceed?', 'Package installation', 0x04 + 0x20 --[[MB_YESNO+MB_ICONQUESTION]])
		then
			error('dependency installation was interrupted by user')
		end
		time_install = os.clock()
		for i, pkg in ipairs(to_install) do
			local ok, err = install_package(pkg.name, pkg.ver, pkg.svr)
			if not ok then
				failure(pkg.full .. '\n' .. err)
			end
			print('Package "' .. pkg.full .. '" has been installed')
		end
		time_install = os.clock() - time_install
	end
	-- DEBUG
	local dbgmsg = ('[DEBUG] Installed check took %.3fs.'):format(time_test)
	if #to_install > 0 then
		dbgmsg = dbgmsg .. (' Installation of %d packages took %.2fs. Total %.2fs.'):format(#to_install, time_install, time_test + time_install)
	end
	print(dbgmsg)
end

-- API

local mod = {
	_VERSION = '0.1.0'
}

function mod.install(...)
	return batch_install({...})
end

function mod.test(...)
	local results = {}
	for i, dep in ipairs({...}) do
		local name, version, server = parse_package_string(dep)
		local installed, err = test_installed_package(name, version)
		if not installed and err then
			return nil, err
		end
		results[dep] = installed
	end
	return results
end

setmetatable(mod, {
	__call = function(t, a1, ...)
		if type(a1) == 'table' then
			return batch_install(a1)
		end
		return batch_install({a1, ...})
	end
})

configure()

return mod
