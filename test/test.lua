-- debug
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
if not logdebug then
	function logdebug(...)
		return print('(debug)', ...)
	end
end
-- /debug

local maincor = coroutine.create(function()
	require 'deps' {
		'inspect',
		'dkjson@2.4-1',
		'steved/penlight@1.5.4-1',
		'iZarif:flvk',
	}

	local deps = require 'deps'
	local results = deps.test('inspect', 'nonexistent_3481234', 'dkjson@2.1', 'penlight@9.9')
	for k, v in pairs(results) do
		print(k .. ':', v)
	end

	pcall(deps.install, 'lustache@13.37')
end)
coroutine.resume(maincor)
while coroutine.status(maincor) == 'suspended' do
	coroutine.resume(maincor)
end
