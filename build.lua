-- build.lua -- typecheck the rule bundle and record the build stamp.
--
--   luajit build.lua            (or: bin/unii build)
--
-- 1. Checks the toolchain (LuaJIT 2.1) and that the shen-lua runtime
--    (vendor/shen-lua, or UNII_SHEN_LUA in the Nix shell) is the pinned
--    commit, unmodified (host/shen_lua.lua).
-- 2. Loads every core file under (tc +) with the fasl cache disabled, so the
--    kernel typechecker really runs, and confirms that a deliberately
--    ill-typed rules module is rejected (the check is live, not vacuous).
-- 3. Writes build/bundle.stamp with the bundle hash. Boot refuses any
--    bundle whose hash differs from the stamp.
local ffi = require("ffi")
ffi.cdef [[ int setenv(const char *name, const char *value, int overwrite); ]]
ffi.C.setenv("SHEN_FASL", "off", 1)

local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)/build%.lua$") or "."
package.path = here .. "/?.lua;" .. here .. "/?/init.lua;" .. package.path

local manifest = require("manifest")

local function step(msg) io.stdout:write("[build] ", msg, "\n") end
local function die(msg) io.stderr:write("[build] FAILED: ", msg, "\n"); os.exit(1) end

-- 1. toolchain and pinned runtime
if not jit or not jit.version:match("^LuaJIT 2%.1") then
  die("LuaJIT 2.1 required, running " .. (jit and jit.version or _VERSION))
end
step("toolchain " .. jit.version .. " " .. jit.os .. "/" .. jit.arch)

local pin = manifest.shen_lua.commit
local shen_lua = require("host.shen_lua")
local pinned, how = shen_lua.verify()
if pinned == false then die(how) end
step((pinned and "shen-lua runtime: " or "WARNING: ") .. how)
shen_lua.install()
local core = require("host.core")

-- 2. typecheck
local t0 = os.clock()
local ok, err = pcall(core.load_bundle, here)
if not ok then die(err) end
step(("typechecked %d core files under (tc +) in %.2fs CPU"):format(#manifest.core_files, os.clock() - t0))

local shen = core.shen()
shen.eval("(tc +)")
local bad = here .. "/test/fixtures/ill_typed_rules.shen"
local rejected, why = pcall(shen.prims.F["load"], bad)
shen.eval("(tc -)")
if rejected then die("typechecker accepted " .. bad .. "; type checking is not live") end
step("ill-typed fixture rejected: " .. core.error_message(why):gsub("\n.*", ""))

-- 3. stamp
local hash = core.bundle_hash(here)
os.execute(("mkdir -p %q"):format(here .. "/build"))
local f = assert(io.open(core.stamp_path(here), "wb"))
f:write("bundle ", hash, "\n",
        "bundle_format ", manifest.bundle_format, "\n",
        "files ", table.concat(manifest.core_files, " "), "\n",
        "shen_lua ", pin, "\n",
        "shen_lua_verified ", pinned and "yes" or "no", "\n",
        "luajit ", jit.version, "\n")
f:close()
step("bundle " .. hash .. " -> " .. core.stamp_path(here))
