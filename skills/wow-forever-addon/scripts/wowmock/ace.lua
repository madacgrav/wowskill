-- LibStub registry. Embedded libraries are not loaded offline; stubs register themselves in env.libs.
local M = {}

function M.install(env, api)
  env.libs = {}
  local LibStub = setmetatable({}, { __call = function(_, major, silent)
    local l = env.libs[major]
    if not l and not silent then error("Cannot find a library instance of " .. tostring(major), 2) end
    return l
  end })
  function LibStub:NewLibrary() return nil end -- real libs never load offline; stubs are pre-registered
  function LibStub:GetLibrary(major, silent) return self(major, silent) end
  function LibStub:IterateLibraries() return pairs(env.libs) end
  api.LibStub = LibStub
end

return M
