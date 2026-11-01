-- Base luacheck config for WoW Forever addons. lint.sh prepends the generated stds.forever
-- (forever-std.lua) and appends the addon's own .luacheckrc.
std = "lua51+forever"
max_line_length = false
codes = true
exclude_files = { "**/Libs/**", "**/tests/wowmock/**", ".release/**" }
ignore = { "211", "212", "213", "212/self", "11./SLASH_.*", "11./BINDING_.*" }
globals = { "SlashCmdList" } -- writable WoW globals addons legitimately assign into
read_globals = { "LibStub" } -- embedded-library loader (not part of Blizzard's UI code)
files["**/tests/**"] = { std = "+busted", read_globals = { "ADDON_DIR" } }
