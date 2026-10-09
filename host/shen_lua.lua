-- host/shen_lua.lua -- locate the pinned shen-lua runtime and put it on
-- package.path. The runtime is the git submodule vendor/shen-lua, or the
-- directory named by UNII_SHEN_LUA (the Nix dev shell points it at the
-- flake input). Both are pinned to manifest.shen_lua.commit.
local manifest = require("manifest")

local M = {}

function M.root()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("^(.*)/host/shen_lua%.lua$") or "."
end

function M.dir()
  local env = os.getenv("UNII_SHEN_LUA")
  if env and env ~= "" then return env end
  return M.root() .. "/vendor/shen-lua"
end

local function missing(dir)
  local f = io.open(dir .. "/shen.lua", "rb")
  if f then f:close(); return nil end
  return ("shen-lua runtime not found at %s: run `git submodule update --init` "
    .. "(or enter `nix develop`, or set UNII_SHEN_LUA)"):format(dir)
end

local installed

-- Unii's own root stays ahead of the runtime so its module names win; the
-- runtime stays ahead of the default path so an installed shen rock cannot
-- shadow the pinned one.
function M.install()
  if installed then return installed end
  local dir = M.dir()
  local why = missing(dir)
  if why then error(why, 0) end
  local root = M.root()
  package.path = table.concat({
    root .. "/?.lua", root .. "/?/init.lua", dir .. "/?.lua", dir .. "/?/init.lua",
  }, ";") .. ";" .. package.path
  installed = dir
  return dir
end

local function sh(cmd)
  local p = io.popen("( " .. cmd .. " ) 2>/dev/null; echo \"__EXIT=$?\"")
  local out = p:read("*a")
  p:close()
  local code = tonumber(out:match("__EXIT=(%d+)\n?$"))
  return (out:gsub("__EXIT=%d+\n?$", "")), code == 0
end

local function realpath(p)
  if p == "" then return nil end
  local out, ok = sh(("cd %q && pwd -P"):format(p))
  return ok and (out:gsub("%s+$", "")) or nil
end

-- Check the runtime against the pin. Returns ok, description. A git
-- checkout (the submodule) must be at the pinned commit with no tracked
-- changes and no untracked, non-ignored files. A non-git tree is accepted
-- only when UNII_SHEN_LUA_REV names the pin: the Nix shell sets it from the
-- flake input, whose content flake.lock fixes by narHash. Anything else is
-- reported as unverifiable (ok == nil).
function M.verify()
  local pin = manifest.shen_lua.commit
  local dir = M.dir()
  local why = missing(dir)
  if why then return false, why end
  local real = realpath(dir)
  local toplevel, in_git = sh(("git -C %q rev-parse --show-toplevel"):format(dir))
  if in_git and realpath((toplevel:gsub("%s+$", ""))) == real then
    local head = (sh(("git -C %q rev-parse HEAD"):format(dir))):gsub("%s+$", "")
    if head ~= pin then
      return false, ("%s is at %s, pinned commit is %s"):format(dir, head, pin)
    end
    local dirty = sh(("git -C %q status --porcelain --untracked-files=normal"):format(dir))
    if dirty ~= "" then
      return false, ("%s has local changes against pinned commit %s:\n%s"):format(dir, pin, dirty)
    end
    return true, "git checkout " .. dir .. " at pinned commit " .. pin:sub(1, 12) .. ", clean"
  end
  local rev = os.getenv("UNII_SHEN_LUA_REV")
  if rev and rev ~= "" then
    if rev ~= pin then
      return false, ("UNII_SHEN_LUA_REV is %s, pinned commit is %s"):format(rev, pin)
    end
    return true, "flake input " .. dir .. " at pinned commit " .. pin:sub(1, 12) .. " (narHash in flake.lock)"
  end
  return nil, dir .. " is neither a git checkout nor a pinned flake input; runtime pin not verified"
end

return M
