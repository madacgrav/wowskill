# Task

Build a Claude Code skill (`SKILL.md` + `references/` + `templates/` + `scripts/`) that makes Claude a reliable collaborator for World of Warcraft: Forever (Classic+) addon development: correct Forever-only API usage, scaffolding (vanilla or Ace3), offline validation via luacheck and a mock WoW API harness, CurseForge gap analysis, and a BigWigs-packager release pipeline to CurseForge/Wago. For non-trivial addon work the skill hands off to the installed `qrspi-plan-toolkit` plugin and supplies WoW-specific inputs at each phase.

Source spec: `wow-addon-skill-prd.md` (Draft v0.2) at the repo root. Work is delivered as milestones M1–M7 (see `backlog.md`); open questions in PRD §9 are to be resolved in `3-design`.
