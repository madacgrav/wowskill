-- Addon-specific luacheck settings. Run via <skill>/scripts/lint.sh, which prepends stds.forever
-- and the base config (std, ignores, SlashCmdList), so extend `globals` rather than replacing it.
globals = globals or {}
globals[#globals + 1] = "TooltipItemLevelDB"
globals[#globals + 1] = "TooltipItemLevelCharDB"
