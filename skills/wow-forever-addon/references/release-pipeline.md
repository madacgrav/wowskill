# Release pipeline

Read this before packaging, tagging or setting up uploads. Every scaffold ships `.pkgmeta` and `.github/workflows/release.yml`. Pushing a `vX.Y.Z` tag packages the addon with the **BigWigs packager** and uploads it to CurseForge, Wago and GitHub Releases.

## How Forever is detected

- The packager reads `## Interface: 16001`. The **`16xxx` prefix maps to game type `forever`** (aliases `-g forever`, `-g camelot`), so no `-g` flag is needed. (BigWigs `release.sh` master, verified 2026-11-01; latest release v2.6.1, 2026-09-18.)
- **CurseForge:** Forever is its own game-version type, id **88568**, hard-coded in the packager. CurseForge addon pages show the flavor as "Forever", with game version 1.60.x. The exact versions list needs an API token to read, so it is unverified.
- **Wago:** `addons.wago.io/api/data/game` lists `forever` patches (`1.60.1`) (verified 2026-11-01).
- **WoWInterface** uploads are not set up in this skill.

## `.pkgmeta` (template)

| Key | Value | Why |
|---|---|---|
| `package-as` | addon folder name | Zip root folder |
| `manual-changelog` | `CHANGELOG.md`, markdown | Used for the upload's changelog text |
| `enable-nolib-creation` | `no` | Nolib zips only go to GitHub. Not needed. |
| `ignore` | `tests`, `thoughts`, `.github`, `.luacheckrc`, `.pkgmeta`, `.gitignore` | Dev files never ship. `thoughts/` (QRSPI history) stays in the repo only. |
| `externals` (Ace3 only) | One per library, from `https://repos.wowace.com/wow/<lib>/trunk/...` | Soft-embedded `Libs/`, fetched at package time. URLs probed with HTTP 200 on 2026-11-01. Needs `svn` locally for dry runs. |

**Substitution tokens** in Lua, TOC and XML:
- `@project-version@`: the TOC `## Version`, taken from the tag.
- `@project-date-iso@` and `@project-abbreviated-hash@`.
- Comment blocks such as `--@debug@ … --@end-debug@`, which are stripped from release builds, and `--@alpha@`, which is kept only in untagged builds.

## TOC fields for uploads

Uncomment and fill these in once the projects exist:

```
## X-Curse-Project-ID: 123456
## X-Wago-ID: abcd1234
```

## Secrets

Set these in the GitHub repo under Settings → Secrets → Actions:

| Secret / env | Used for | Notes |
|---|---|---|
| `CF_API_TOKEN` | CurseForge upload | From the CurseForge "API tokens" page. `CF_API_KEY` is the **deprecated** name. |
| `WAGO_API_TOKEN` | Wago upload | From the Wago account "API keys" page. |
| `GH_API_TOKEN` | GitHub Release | The workflow passes `secrets.GITHUB_TOKEN`. `GITHUB_OAUTH` is the **deprecated** name. |

The packager skips any upload whose token is unset, so the workflow is safe to commit before the projects exist.

## Local dry run (no upload)

The packager needs bash ≥ 4.3 (macOS ships 3.2), plus `jq`, and `svn` for Ace3 externals:

```bash
brew install bash jq subversion
curl -fsSLo /tmp/release.sh https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh
cd <addon-repo-root>                                   # must be the git repo root (the packager refuses subfolders)
"$(brew --prefix)/bin/bash" /tmp/release.sh -d         # -d = skip uploads
unzip -l .release/*.zip                                # no tests/, thoughts/, .github/
```

The zip is named `<Name>-<version>-forever.zip`, which confirms Forever detection. Without a tag, the version is the commit hash. Verified on `examples/TooltipItemLevel` (copied into its own repo, tagged `v0.1.0`) on 2026-11-01: `## Version: v0.1.0` was substituted and no dev files were packaged.

## `/release` checklist

- [ ] Move `## [Unreleased]` entries in `CHANGELOG.md` under `## [X.Y.Z] - YYYY-MM-DD`, grouped from conventional commits (feat, fix, perf, …).
- [ ] `<skill>/scripts/lint.sh <addon>` is clean.
- [ ] `<skill>/scripts/test.sh <addon>` is green.
- [ ] Commit: `chore(release): vX.Y.Z`.
- [ ] Tag and push: `git tag vX.Y.Z && git push && git push --tags`.
- [ ] The GitHub Actions "Package and release" run is green.
- [ ] The CurseForge and Wago project pages show the new file with the **Forever** flavor, and the GitHub Release has the zip.
- [ ] After launch: install the released zip in-game, `/reload`, no errors.
