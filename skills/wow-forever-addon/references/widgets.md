# Widgets and frames

Read this before creating frames, fonts, textures or layout. For widget method signatures, see the `*APIDocumentation.lua` files (ScriptObject systems) in Gethe/wow-ui-source `forever`, under `Blizzard_APIDocumentationGenerated/`.

## Creating frames

```lua
local f = CreateFrame("Frame", "MyAddonFrame", UIParent, "BackdropTemplate")
```

- **Types:** `Frame`, `Button`, `CheckButton`, `EditBox`, `ScrollFrame`, `Slider`, `StatusBar`, `Cooldown`, `GameTooltip`, `Model`.
- **Name:** a global name makes the frame reachable as `_G[name]` and shows it in `/fstack`. Use `nil` for internal frames.
- **Templates:** `BackdropTemplate` (required before `SetBackdrop`), `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `SecureActionButtonTemplate` (see `taint-and-secure.md`).
- Create each frame **once**. Frames are never freed.

## Layout

- `f:SetSize(w, h)`, `f:SetPoint(point, relativeTo, relativePoint, x, y)`, `f:ClearAllPoints()`, `f:SetAllPoints(parent)`.
- Anchor points: `TOPLEFT`, `TOP`, `TOPRIGHT`, `LEFT`, `CENTER`, `RIGHT`, `BOTTOMLEFT`, `BOTTOM`, `BOTTOMRIGHT`.
- **Strata** (`SetFrameStrata`): `BACKGROUND` < `LOW` < `MEDIUM` < `HIGH` < `DIALOG` < `FULLSCREEN` < `FULLSCREEN_DIALOG` < `TOOLTIP`. Within a strata, `SetFrameLevel`.
- **Movable windows:** `SetMovable(true)`, `EnableMouse(true)`, `RegisterForDrag("LeftButton")`, `OnDragStart` → `StartMoving`, `OnDragStop` → `StopMovingOrSizing`, then save `GetPoint()` to per-character SavedVariables (the scaffold's `ui` pattern does this).

## Regions

- **Text:** `local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")`, then `t:SetText(...)` and `t:SetPoint(...)`. Font objects: `GameFontNormal`, `GameFontHighlight`, `GameFontNormalLarge`, `GameFontDisable`.
- **Texture:** `local tex = f:CreateTexture(nil, "ARTWORK")`, then `tex:SetTexture(fileID or path)` or `tex:SetColorTexture(r, g, b, a)`. Draw layers: `BACKGROUND` < `BORDER` < `ARTWORK` < `OVERLAY` < `HIGHLIGHT`.

## Scripts

`SetScript("OnShow" | "OnHide" | "OnEvent" | "OnUpdate" | "OnClick" | "OnEnter" | "OnLeave" | "OnDragStart" | "OnDragStop", fn)`. Use `HookScript` to add to an existing handler without replacing it, which is required on Blizzard frames.

## Tooltips

- Item, spell and unit tooltips: `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data) ... end)`, then `tooltip:AddLine(text, r, g, b)`. The `examples/TooltipItemLevel` addon shows this.
- Your own tooltip on hover: `OnEnter` → `GameTooltip:SetOwner(self, "ANCHOR_RIGHT")`, `GameTooltip:AddLine(...)`, `GameTooltip:Show()`. Then `OnLeave` → `GameTooltip:Hide()`.

## Inspecting in-game

- `/fstack` shows frame names, strata and templates under the cursor.
- `/tinspect <frame>` shows a table inspector.

Global names here (`CreateFrame`, `UIParent`, `GameTooltip`, `TooltipDataProcessor`, `BackdropTemplate`, `GameFontNormal`) are verified in the generated lint std (2026-11-01). Widget methods are not globals, so check them against the ScriptObject docs.
