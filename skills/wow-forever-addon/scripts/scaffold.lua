-- Render a vanilla or Ace3 addon from templates/, substituting tokens and dropping unselected pattern blocks.
-- usage: luajit scaffold.lua <skill-dir> <Name> [--ace3] [--pattern p]... [--license MIT|none] [--dest DIR] [--author A] [--notes TXT]
local SK, NAME = arg[1], arg[2]
local function die(msg) io.stderr:write("scaffold: ", msg, "\n"); os.exit(2) end
if not NAME or not NAME:match("^[A-Za-z][A-Za-z0-9_]*$") then
  die("usage: scaffold.sh <Name> [--ace3] [--pattern p]... [--license MIT|none] [--dest DIR]; Name must match [A-Za-z][A-Za-z0-9_]*")
end

local opt = { patterns = {}, license = "MIT", dest = ".", ace3 = false }
local i = 3
while arg[i] do
  local a = arg[i]
  if a == "--ace3" then
    opt.ace3 = true; i = i + 1
  elseif a == "--pattern" then
    if not arg[i + 1] then die("--pattern needs a value") end
    opt.patterns[arg[i + 1]] = true; i = i + 2
  elseif a == "--license" or a == "--dest" or a == "--author" or a == "--notes" then
    if not arg[i + 1] then die(a .. " needs a value") end
    opt[a:sub(3)] = arg[i + 1]; i = i + 2
  else
    die("unknown arg " .. a)
  end
end
local VALID = { event = true, timer = true, ui = true, ldb = true, tooltip = true }
for p in pairs(opt.patterns) do if not VALID[p] then die("unknown pattern " .. p) end end
opt.patterns.ace3 = opt.ace3

local function read(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function write(p, s)
  os.execute('mkdir -p "' .. p:match("^(.*)/") .. '"')
  local f = assert(io.open(p, "wb")); f:write(s); f:close()
end
local function files(dir)
  local t, p = {}, io.popen('cd "' .. dir .. '" && find . -type f')
  for l in p:lines() do t[#t + 1] = l:sub(3) end
  p:close()
  return t
end

local tocref = read(SK .. "/references/toc-format.md")
local iface = tocref:match("^Interface: (%d+)") or tocref:match("\nInterface: (%d+)")
if not iface then die("Interface not found in references/toc-format.md") end
local gitname = io.popen("git config user.name 2>/dev/null"):read("*l")
local author = opt.author or (gitname ~= "" and gitname) or "Unknown"

local tokens = {
  __NAME__ = NAME,
  __KEY__ = (NAME:upper():gsub("[^%w]", "")),
  __SLASH__ = NAME:lower(),
  __INTERFACE__ = iface,
  __AUTHOR__ = author,
  __NOTES__ = opt.notes or "",
  __YEAR__ = os.date("%Y"),
  __LIBCHOICE__ = opt.ace3 and "Ace3" or "vanilla",
  __LIBREASON__ = opt.ace3 and "options UI / profiles / modules wanted (see ace3-vs-vanilla.md)"
    or "no options panel, <=3 settings, no cross-addon messaging (see ace3-vs-vanilla.md)",
}

local function render(s)
  local out, skip = {}, false
  for line in (s:sub(-1) == "\n" and s or s .. "\n"):gmatch("(.-)\n") do
    local p = line:match("@pattern:([%w_]+)@")
    if p then
      skip = not opt.patterns[p]
    elseif line:match("@end%-pattern@") then
      skip = false
    elseif not skip then
      out[#out + 1] = line
    end
  end
  s = table.concat(out, "\n") .. "\n"
  for k, v in pairs(tokens) do s = s:gsub(k, (v:gsub("%%", "%%%%"))) end
  return s
end

local root = opt.dest .. "/" .. NAME
local tpl = SK .. "/templates/" .. (opt.ace3 and "ace3" or "vanilla")
for _, rel in ipairs(files(tpl)) do
  write(root .. "/" .. rel:gsub("__NAME__", NAME), render(read(tpl .. "/" .. rel)))
end
local common = { ["README.addon.md"] = "README.md", ["CHANGELOG.md"] = "CHANGELOG.md" }
if opt.license ~= "none" then common["LICENSE.MIT"] = "LICENSE" end
for src, dst in pairs(common) do
  write(root .. "/" .. dst, render(read(SK .. "/templates/common/" .. src)))
end
print("created " .. root)
