# Forever API notes (curated)

Read this before using any API you remember from Classic Era or Retail, and when porting code between flavors. Every entry carries a source, a date and a confidence label: **verified** (checked in the `forever` branch or in-game), **reported** (secondary source) or **unverified**.

## What Forever is

- WoW Forever ("Classic+", codename **Camelot**, client **1.60.x**) is a **Mainline-family** game type, built from Retail **12.1.5** code (build 69952). (warcraft.wiki.gg Patch_1.60.1/API_changes and /notes, 2026-10-17, reported.)
- It is **not** the Classic Era or Anniversary branch. `_Classic.toc` files do not load. (warcraft.wiki.gg TOC_format, 2026-10-17, reported.)
- `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18). (warcraft.wiki.gg WOW_PROJECT_ID, 2026-10-17, reported.)
- Launch is 2026-11-04. Everything here dates from the beta (1.60.1). Rerun `<skill>/scripts/gen-api.sh` after launch and after each patch.

## Differs from Retail 12.1.5

Every name below was confirmed in `forever-api-index.md`, generated from `ca8368f 1.60.1 (70532)` (2026-10-22, **verified**).

**Classic systems restored as new namespaces:**
- `C_SwingTimer`: `EnableRangeCheck`, `IsTargetWithinSwingRange`.
- `C_PetInfo`: hunter pet happiness, loyalty, food and training points (`GetPetHappiness`, `GetPetLoyalty`, `GetPetFoodTypes`, `CanPetEatItem`, `GetPetTrainingPoints`, `GetPetTalentTree`, …).
- `C_StableInfo`: stable slots and lists (`GetNumStableSlots`, `GetStablePetInfo`, `BuyStableSlot`, `IsAtStableMaster`, …).
- `C_SkillInfo`: the classic skill-line UI (`GetNumSkillLines`, `GetSkillLineInfo`, `GetSkillLineInfoByID`, `AbandonSkill`, …).
- `C_Trainer`: `GetTrainerType`, `GetCategorizeTrainerUI`, `SetCategorizeTrainerUI`.

**Classic stat globals:** `UnitDefenseSkill`, `UnitResistance`, `UnitUsesAmmo`, `GetArmorPenetration`, `GetHealthRegenFromSpirit`, `ToggleSit`. Also `C_PaperDollInfo.AmmoNeeded`.

**Game-mode rules:** `C_GameRules.GetForeverExperiencePreset`, plus hardcore and self-found queries (see the `C_GameRules` section of the index).

**Other additions:** `C_Flyout`, `C_GamepadTargeting`.

**Language change:** Lua `require` is renamed `import` in the Forever client. (warcraft.wiki.gg Patch_1.60.1/API_changes/notes, Beta 4, reported.)

**Retail-style APIs present:** `C_Container`, `C_UnitAuras` (`GetAuraDataByIndex`, `GetBuffDataByIndex`, `GetDebuffDataByIndex`), `C_Spell`, `C_Item` (`GetDetailedItemLevelInfo`), `C_AddOns` and `C_Timer` (`After`, `NewTicker`, …) all exist. Use them, not the Classic Era globals.

## Secret values / Midnight restrictions

- Midnight's addon restrictions ("secret values") are reported to apply in Forever. **[unverified in Forever]** (gamewave.fr, Icy Veins, 2026; research.md:191.) Assume combat- and unit-data restrictions exist until confirmed in-game.

## Never-emit list

Names that must not appear in generated code. `scripts/lint.sh` fails on them, and `scripts/gen-api.sh` removes them from the lint std and reports each one as `DOCS`, `FrameXML shim` or `absent`.

The 2026-11-01 run against `ca8368f 1.60.1 (70532)` reported every entry below as **absent**: no documented API and no FrameXML shim (verified). Every listed replacement is present in the index.

<!-- never-emit:start -->
- `GetContainerItemInfo` — use `C_Container.GetContainerItemInfo` (returns a table)
- `GetContainerNumSlots` — use `C_Container.GetContainerNumSlots`
- `GetContainerNumFreeSlots` — use `C_Container.GetContainerNumFreeSlots`
- `PickupContainerItem` — use `C_Container.PickupContainerItem`
- `UseContainerItem` — use `C_Container.UseContainerItem`
- `UnitAura` — use `C_UnitAuras.GetAuraDataByIndex`
- `UnitBuff` — use `C_UnitAuras.GetBuffDataByIndex`
- `UnitDebuff` — use `C_UnitAuras.GetDebuffDataByIndex`
- `GetSpellInfo` — use `C_Spell.GetSpellInfo` (returns a table)
- `GetSpellCooldown` — use `C_Spell.GetSpellCooldown`
- `GetSpellTexture` — use `C_Spell.GetSpellTexture`
- `GetAddOnInfo` — use `C_AddOns.GetAddOnInfo`
- `IsAddOnLoaded` — use `C_AddOns.IsAddOnLoaded`
- `GetNumAddOns` — use `C_AddOns.GetNumAddOns`
- `LoadAddOn` — use `C_AddOns.LoadAddOn`
- `this` — vanilla 1.x implicit handler self; use the `self` parameter
<!-- never-emit:end -->

## How to verify a name

1. `grep -n 'Name' <skill>/references/forever-api-index.md`.
2. If it's not there, check the matching `*Documentation.lua` in Gethe/wow-ui-source branch `forever`, or FrameXML in the same branch.
3. In-game: `/dump Name` (or `/dump C_X.Name`). `nil` means absent.
4. If you find a new difference or a new never-emit name, add it here with source, date and confidence, then rerun `gen-api.sh`.
