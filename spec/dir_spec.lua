local test_env = require("spec.util.test_env")
local testing_paths = test_env.testing_paths

test_env.unload_luarocks()
test_env.setup_specs()
local dir = require("luarocks.dir")

describe("Luarocks dir test #unit", function()
   local runner
   
   setup(function()
      runner = require("luacov.runner")
      runner.init(testing_paths.testrun_dir .. "/luacov.config")
      runner.tick = true
   end)
   
   teardown(function()
      runner.shutdown()
   end)
   
   describe("dir.is_basic_protocol", function()
      it("checks whether the arguments represent a valid protocol and returns the result of the check", function()
         assert.truthy(dir.is_basic_protocol("http"))
         assert.truthy(dir.is_basic_protocol("https"))
         assert.truthy(dir.is_basic_protocol("ftp"))
         assert.truthy(dir.is_basic_protocol("file"))
         assert.falsy(dir.is_basic_protocol("git"))
         assert.falsy(dir.is_basic_protocol("git+https"))
         assert.falsy(dir.is_basic_protocol("invalid"))
      end)
   end)

   describe("dir.deduce_base_dir", function()
      assert.are.same("v0.3", dir.deduce_base_dir("https://example.com/hishamhm/lua-compat-5.2/archive/v0.3.zip"))
      assert.are.same("lua-compat-5.2", dir.deduce_base_dir("https://example.com/hishamhm/lua-compat-5.2.zip"))
      assert.are.same("lua-compat-5.2", dir.deduce_base_dir("https://example.com/hishamhm/lua-compat-5.2.tar.gz"))
      assert.are.same("lua-compat-5.2", dir.deduce_base_dir("https://example.com/hishamhm/lua-compat-5.2.tar.bz2"))
      assert.are.same("parser.moon", dir.deduce_base_dir("git://example.com/Cirru/parser.moon"))
      assert.are.same("v0.3", dir.deduce_base_dir("https://example.com/hishamhm/lua-compat-5.2/archive/v0.3"))
   end)

end)
