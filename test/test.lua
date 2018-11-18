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
