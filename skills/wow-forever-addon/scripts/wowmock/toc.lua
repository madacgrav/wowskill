-- TOC + XML file-list parsing. Missing files under Libs/ are skipped (stubs stand in for embedded libs).
local M = {}

local function exists(p)
  local f = io.open(p, "r")
  if f then f:close(); return true end
  return false
end

local function dirname(p) return p:match("^(.*)/") or "." end

local function add(files, path)
  if not exists(path) then
    if path:find("/Libs/", 1, true) then return end
    error("wowmock: missing file " .. path, 0)
  end
  if path:match("%.xml$") then
    local fh = io.open(path)
    local s = fh:read("*a")
    fh:close()
    for tag, f in s:gmatch('<(%a+)%s+file="([^"]+)"') do
      if tag == "Script" or tag == "Include" then
        add(files, dirname(path) .. "/" .. (f:gsub("\\", "/")))
      end
    end
  else
    files[#files + 1] = path
  end
end

function M.parse(dir)
  dir = dir:gsub("/+$", "")
  local name = dir:match("([^/]+)$")
  local tocpath = dir .. "/" .. name .. ".toc"
  local fh = io.open(tocpath)
  if not fh then error("wowmock: no TOC at " .. tocpath, 0) end
  local toc = { name = name, fields = {}, files = {} }
  for raw in fh:lines() do
    local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local k, v = line:match("^##%s*([%w%-_]+)%s*:%s*(.-)$")
    if k then
      toc.fields[k] = v
    elseif line ~= "" and not line:match("^#") then
      add(toc.files, dir .. "/" .. (line:gsub("\\", "/")))
    end
  end
  fh:close()
  return toc
end

return M
