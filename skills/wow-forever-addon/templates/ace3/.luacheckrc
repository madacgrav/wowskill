-- Addon-specific luacheck settings. Run via <skill>/scripts/lint.sh, which prepends stds.forever
-- and the base config (std, ignores, SlashCmdList, LibStub), so extend `globals` rather than replacing it.
globals = globals or {}
globals[#globals + 1] = "__NAME__DB"
