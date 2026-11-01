# CurseForge gap analysis

Read this before scaffolding any new addon. The owner's rule: **don't rebuild what exists unless it has obvious gaps.**

## Procedure

1. **Name the idea in 3–6 keywords**: the feature nouns plus class or profession (for example "soul shard counter warlock").
2. **Search** (web search; no CurseForge API key is assumed):
   - `site:curseforge.com/wow/addons <keywords> forever`
   - `site:curseforge.com/wow/addons <keywords>` (Forever support may not be in the page text)
   - `site:addons.wago.io <keywords>`
3. **For each of the top 3–5 matches, open the project page** and record:
   - **Last updated** date.
   - **Forever listed:** whether the flavor list or game versions show "Forever" (CurseForge) or `forever` (Wago). CurseForge lists Forever as its own flavor, with game version 1.60.x (research.md:259-261).
   - **License** (from the page or the repo), which you need before forking.
   - **What it covers** and **what's missing** relative to the idea.
4. **Verdict**:
   - **use**: an existing addon covers the idea, is maintained, and supports Forever. Recommend it and stop.
   - **fork / extend**: it's close, but has clear gaps or no Forever support, and its license allows forking. Go to the QRSPI planning path (`qrspi-handoff.md`).
   - **build**: nothing covers it, or the matches are abandoned or incompatible.
5. **Record** the table and the verdict in the new addon's README "Gap analysis" line (and in `task.md` on the QRSPI path).

## Report template

```markdown
### Gap analysis: <idea> (<date>)

| # | Addon | Last update | Forever flavor listed? | License | Covers | Gaps |
|---|---|---|---|---|---|---|
| 1 | [Name](url) | YYYY-MM-DD | yes / no / unverified | MIT / ARR / … | … | … |

**Verdict:** use / fork / build. <one-sentence reason>
```

## Degrading gracefully

- If a page can't be fetched, or a field isn't shown, write **unverified** in that cell. Never guess.
- If search returns nothing relevant, say so and make the verdict **build**, noting "no matches found".
- Don't download addon zips. The listing page is enough for a verdict.
