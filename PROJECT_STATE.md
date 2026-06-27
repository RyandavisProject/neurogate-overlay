# PROJECT_STATE - Vibemode Overlay

Updated: 26-06-2026
Project: Vibemode Overlay
Project id: vibemode
Local path: `C:\Codex\neurogate-usage-overlay`
GitHub: `https://github.com/RyandavisProject/vibemode`
Current local version: `2.2` candidate, not pushed in this audit turn.
Current branch: `codex/vibemode-2.0`
Latest pushed commit seen locally: `928d05d vibemode 25-06-2026 23-26 v2.1: restore reset timers`
Current mode: audit/hardening; no commit, push, GitHub Release, or public version change without owner confirmation.

## State Summary

Vibemode Overlay is a local-first Python desktop project for Vibemode API usage limits.

- Windows: compact always-on-top Tkinter overlay.
- macOS: menu bar status item with NSPopover/WKWebView popover.
- Data source: `https://portal.vibemod.pro/client` and `https://api.vibemod.pro` through the user's own local Playwright/Chrome session.
- Public install paths: Git/Codex install and ZIP installer.
- Updates: GitHub Releases with ZIP plus SHA256.

The project is public and intended mainly for Russian-speaking users. The app must not collect, publish, or transmit passwords, cookies, browser profiles, raw cabinet text, tokens, local logs, or private account data.

## Current Product Surface

- Compact limit UI with tariff name, tariff time left, 5-hour and 7-day rows.
- `remaining/total` display for limit rows when total limits are known.
- Reset time on the right side of 5-hour and 7-day rows.
- Progress bars for limit consumption.
- Optional manually set `limit/day` row for the current calendar day only.
- Daily-limit suggestion formula: `7d remaining / remaining 7d reset time`, with hours converted to decimal days and divisor never below one day.
- Daily-limit row is hidden the next calendar day until the user manually sets a new value.
- Right-click menu on Windows; popover actions on macOS.
- Saved refresh interval, saved 2x scale, saved Windows overlay position.
- Safe account switching via `Сменить аккаунт`.
- Safe auto-login only for stable prefilled forms, disabled during account switching.
- Hidden browser by default after successful login, with optional `Не закрывать ЛК`.

## Local Data Boundary

Local-only files live under:

```text
%USERPROFILE%\.neurogate-usage-overlay\
```

Important files:

- `browser-profile/` - local browser session, private.
- `overlay-state.json` - UI preferences and daily limit for the current day.
- `usage-daily.json` - current-day baseline for today's spending, rewritten instead of appended.
- `overlay.lock` / `overlay.pid` - local single-instance/runtime helpers.
- local logs - private diagnostic logs, never release artifacts.

## Current Audit Candidate - 26-06-2026

Uncommitted v2.2 hardening work currently includes:

- macOS ZIP updater requires SHA256 by default, matching Windows.
- macOS popover local action endpoints require a per-session token; GET action calls are blocked.
- macOS `.app` launcher embeds the actual project root instead of guessing it later.
- macOS `run-overlay.sh` no longer kills broad brand-name process matches.
- Windows `run-overlay.ps1` no longer kills broad brand-name Python process matches.
- Windows context menu is clamped inside the visible screen.
- Browser body-text polling uses a short timeout per polling attempt instead of repeatedly waiting the long global timeout.
- macOS popover can render `remaining/total` values like Windows.
- CI now includes a macOS smoke/unit job with macOS optional dependencies.
- Release ZIP packaging skips internal handoff/state/audit files.
- README, CHANGELOG, privacy, architecture, publishing, and security audit docs are updated for the audit candidate.

## Verification Commands

Canonical local checks:

```powershell
cd C:\Codex\neurogate-usage-overlay
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
git diff --check
powershell -ExecutionPolicy Bypass -File .\scripts\package-release.ps1
```

When packaging is run, verify the ZIP does not contain local or private files:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip='C:\Codex\neurogate-usage-overlay\dist\vibemode-v2.2.zip'
[IO.Compression.ZipFile]::OpenRead($zip).Entries.FullName |
  Select-String -Pattern '__pycache__|egg-info|browser-profile|\.venv|\.git/|overlay-debug|overlay-ui|usage-daily|overlay-state|\.env|\.har|\.trace|\.cookies|PROJECT_STATE|HANDOFF|security_best_practices'
```

## Owner Rules

- Speak Russian by default.
- Dates in docs: `dd-mm-yyyy`.
- Keep the overlay compact; avoid visual drift unless the owner explicitly asks.
- Do not commit/push/release without separate confirmation.
- Do not create GitHub Releases unless explicitly asked.
- Public user links normally point to the main repo: `https://github.com/RyandavisProject/vibemode`.
- Commit naming pattern: `vibemode dd-mm-yyyy hh-mm vX.Y: short meaning`.
- Do not touch private browser profiles, cookies, tokens, passwords, or local session files.

## Current Risks

| Risk | Level | Mitigation |
| --- | --- | --- |
| Live Vibemode cabinet can change markup/API | WARN | Keep API adapter first, parser fallback second, add anonymized fixtures when layouts change |
| macOS UI cannot be fully visually verified from Windows | WARN | Use macOS CI smoke plus manual macOS run before public release |
| GitHub Releases are required for in-app update notifications | WARN | After commit/push, create release only with explicit owner approval and attach ZIP + SHA256 |
| Compact UI is pixel-sensitive | WARN | Keep small measured changes and test 1x/2x states |
| Public repo/ZIP can accidentally include local data | BLOCKER | Keep `.gitignore`, packaging skip list, and ZIP privacy scan before release |

## Next Safe Step

1. Finish the current audit hardening pass.
2. Run `scripts/check.ps1`, `git diff --check`, and package/ZIP privacy verification.
3. Show the owner the audit result and changed files.
4. Wait for explicit confirmation before commit, push, or GitHub Release.
