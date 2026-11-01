-- Minimal busted-style test runner: describe / it / before_each / assert.*
-- usage: luajit runner.lua <addon-dir> <spec.lua>...
ADDON_DIR = arg[1]
local pass, fail, stack, befores = 0, 0, {}, {}

local function deq(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local A = {
  equals = function(e, a, m)
    if e ~= a then error(("%sexpected %s, got %s"):format(m and m .. ": " or "", tostring(e), tostring(a)), 2) end
  end,
  same = function(e, a, m) if not deq(e, a) then error(m or "tables differ", 2) end end,
  truthy = function(v, m) if not v then error(m or "expected truthy", 2) end end,
  falsy = function(v, m) if v then error(m or "expected falsy", 2) end end,
  matches = function(p, s, m)
    if not tostring(s):match(p) then error((m or "no match for " .. p) .. ": " .. tostring(s), 2) end
  end,
  errors = function(fn, p)
    local ok, e = pcall(fn)
    if ok then error("expected an error", 2) end
    if p and not tostring(e):match(p) then error("error did not match: " .. tostring(e), 2) end
  end,
}
assert = setmetatable(A, { __call = function(_, v, m, ...)
  if not v then error(m or "assertion failed", 2) end
  return v, m, ...
end })

function describe(name, fn)
  stack[#stack + 1] = name
  befores[#stack] = {}
  fn()
  befores[#stack] = nil
  stack[#stack] = nil
end

function before_each(fn) table.insert(befores[#stack], fn) end

function it(name, fn)
  local full = table.concat(stack, " > ") .. " > " .. name
  local ok, err = xpcall(function()
    for lvl = 1, #stack do for _, b in ipairs(befores[lvl]) do b() end end
    fn()
  end, debug.traceback)
  if ok then
    pass = pass + 1
    print("ok   " .. full)
  else
    fail = fail + 1
    print("FAIL " .. full .. "\n     " .. tostring(err):gsub("\n", "\n     "))
  end
end

for i = 2, #arg do
  local ok, err = pcall(dofile, arg[i])
  if not ok then
    fail = fail + 1
    print("FAIL " .. arg[i] .. " (spec file error)\n     " .. tostring(err))
  end
end
print(("\n%d passed, %d failed"):format(pass, fail))
os.exit(fail > 0 and 1 or 0)
