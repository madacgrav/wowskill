-- CreateFrame and a frame/region method subset. Unknown PascalCase methods raise
-- "wowmock: unimplemented Frame:X" so the stub grows from real test failures.
local M = {}

local NOOP = { "ClearAllPoints", "SetAllPoints", "SetSize", "SetWidth", "SetHeight", "SetAlpha", "SetScale",
  "SetFrameStrata", "SetFrameLevel", "EnableMouse", "SetMovable", "RegisterForDrag", "SetClampedToScreen",
  "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetTexture", "SetColorTexture", "SetVertexColor",
  "SetJustifyH", "SetJustifyV", "SetFontObject", "SetTextColor", "StartMoving", "StopMovingOrSizing", "SetOwner" }

function M.install(env, api)
  local Frame = {}
  for _, n in ipairs(NOOP) do Frame[n] = function() end end
  local mt = { __index = function(_, k)
    local m = Frame[k]
    if m ~= nil then return m end
    if type(k) == "string" and k:match("^%u") and not k:match("^[%u%d_]+$") then
      error("wowmock: unimplemented Frame:" .. k .. " (add it to wowmock/frames.lua)", 2)
    end
  end }

  -- frames go in env.frames (so tests can count them); regions (FontString/Texture) do not
  local function new(ftype, name, parent, isRegion)
    local o = setmetatable({ _type = ftype, _name = name, _parent = parent, _scripts = {}, _events = {},
      _shown = true, _point = {}, lines = {} }, mt)
    if not isRegion then env.frames[#env.frames + 1] = o end
    if name then rawset(env.G, name, o) end
    return o
  end
  env.frames = {}
  env.new_frame = new

  function Frame:GetName() return self._name end
  function Frame:GetParent() return self._parent end
  function Frame:GetObjectType() return self._type end
  function Frame:Show() self._shown = true end
  function Frame:Hide() self._shown = false end
  function Frame:IsShown() return self._shown end
  function Frame:IsVisible() return self._shown end
  function Frame:SetShown(v) self._shown = not not v end
  function Frame:SetScript(name, fn) self._scripts[name] = fn end
  function Frame:GetScript(name) return self._scripts[name] end
  function Frame:HookScript(name, fn)
    local old = self._scripts[name]
    self._scripts[name] = old and function(...) old(...); fn(...) end or fn
  end
  function Frame:RegisterEvent(e) env:_register(self, e) end
  function Frame:RegisterUnitEvent(e) env:_register(self, e) end
  function Frame:UnregisterEvent(e) env:_unregister(self, e) end
  function Frame:UnregisterAllEvents() for e in pairs(self._events) do env:_unregister(self, e) end end
  function Frame:IsEventRegistered(e) return self._events[e] == true end
  function Frame:SetPoint(...) self._point = { ... } end
  function Frame:GetPoint() return unpack(self._point) end
  function Frame:CreateFontString(name) return new("FontString", name, self, true) end
  function Frame:CreateTexture(name) return new("Texture", name, self, true) end
  function Frame:SetText(t) self._text = t end
  function Frame:GetText() return self._text end
  -- GameTooltip-style line capture
  function Frame:AddLine(text) self.lines[#self.lines + 1] = tostring(text) end
  function Frame:AddDoubleLine(l, r) self.lines[#self.lines + 1] = tostring(l) .. " " .. tostring(r) end
  function Frame:ClearLines() self.lines = {} end
  function Frame:NumLines() return #self.lines end

  api.CreateFrame = function(ftype, name, parent) return new(ftype or "Frame", name, parent) end
  new("Frame", "UIParent")
end

return M
