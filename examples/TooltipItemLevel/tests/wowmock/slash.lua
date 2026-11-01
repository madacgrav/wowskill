-- SlashCmdList and env:slash("/cmd args"), resolved through SLASH_<KEY>N globals.
local M = {}

function M.install(env, api)
  api.SlashCmdList = {}

  function env:slash(line)
    local cmd, rest = line:match("^(%S+)%s*(.-)%s*$")
    for k, v in pairs(self.G) do
      if type(k) == "string" and type(v) == "string" then
        local key = k:match("^SLASH_(.-)%d+$")
        if key and v:lower() == cmd:lower() then
          local h = api.SlashCmdList[key]
          if h then return h(rest, nil) end
        end
      end
    end
    error("wowmock: no slash command " .. tostring(cmd), 2)
  end
end

return M
