# HANDOFF - Vibemode Overlay

Updated: 26-06-2026
Project id: vibemode
Format: Handoff v2 / short transfer sheet

## Current Snapshot

Current local version: `2.2` candidate.
Current branch: `codex/vibemode-2.0`.
GitHub: `https://github.com/RyandavisProject/vibemode`.
Latest pushed commit seen locally: `928d05d vibemode 25-06-2026 23-26 v2.1: restore reset timers`.
Current status: audit/hardening in progress; local changes are not committed or pushed.

Next safe step:

- Run local checks and ZIP privacy scan, then ask the owner before commit/push/release.

## Project Goal

Vibemode Overlay should let a regular Russian-speaking user see Vibemode API limits locally, with simple install/update paths, without sending credentials or private cabinet data anywhere.

The app is local-first:

- browser session stays on the user's machine;
- usage/state files stay under `%USERPROFILE%\.neurogate-usage-overlay`;
- public repo and ZIP contain only code, docs, scripts, sanitized screenshots, and tests.

## Read These First

- `PROJECT_STATE.md`
- `README.md`
- `CHANGELOG.md`
- `SECURITY.md`
- `docs/PRIVACY.md`
- `docs/ARCHITECTURE.md`
- `docs/PUBLISHING.md`
- `security_best_practices_report.md`

## Recent v2.x Context

`v2.0`:

- Project moved to the Vibemode cabinet at `https://portal.vibemod.pro/client`.
- Limits are read primarily from `https://api.vibemod.pro`.
- Public naming was corrected to Vibemode.
- Windows and macOS share the same reader/data model.

`v2.1`:

- Reset timers for 5-hour and 7-day rows were restored from the new cabinet text.

`v2.2` local candidate:

- Daily limit suggestion is capped correctly when less than one day remains before reset.
- 5-hour and 7-day rows show `remaining/total` again.
- Daily row formatting matches the upper rows.
- Windows version row is informational unless an update is available.
- Windows context menu is clamped on screen.
- macOS local popover actions require a session token.
- macOS ZIP updates require SHA256 by default.
- macOS `.app` shortcut stores the actual project root.
- macOS and Windows launch scripts avoid broad brand-name process killing.
- Body text polling uses shorter per-attempt timeout.
- macOS CI smoke/unit job was added.
- Release ZIP excludes internal handoff/state/audit report files.

## Verification

Canonical checks:

```powershell
cd C:\Codex\neurogate-usage-overlay
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
git diff --check
powershell -ExecutionPolicy Bypass -File .\scripts\package-release.ps1
```

ZIP privacy scan:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip='C:\Codex\neurogate-usage-overlay\dist\vibemode-v2.2.zip'
[IO.Compression.ZipFile]::OpenRead($zip).Entries.FullName |
  Select-String -Pattern '__pycache__|egg-info|browser-profile|\.venv|\.git/|overlay-debug|overlay-ui|usage-daily|overlay-state|\.env|\.har|\.trace|\.cookies|PROJECT_STATE|HANDOFF|security_best_practices'
```

## Owner Preferences

- Russian by default.
- Dates in docs: `dd-mm-yyyy`.
- Main public link: `https://github.com/RyandavisProject/vibemode`.
- Keep UI compact; do not redesign without asking.
- Version bumps are intentional: patch/minor only when there is a reason.
- Commit naming pattern:

```text
vibemode dd-mm-yyyy hh-mm vX.Y: short meaning
```

## Safety Boundaries

Never expose or commit:

- tokens, passwords, API keys, `.env`;
- local browser profiles;
- local session state;
- private Vibemode data;
- raw cabinet text;
- raw logs with account content;
- temporary update/install sandboxes.

Ask before:

- commit;
- push;
- force-push;
- changing repo visibility;
- creating GitHub Releases;
- publishing ZIP assets;
- changing auth/session/autologin behavior.

## Next Safe Commands

Check project:

```powershell
cd C:\Codex\neurogate-usage-overlay
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

Package release candidate only when needed:

```powershell
cd C:\Codex\neurogate-usage-overlay
powershell -ExecutionPolicy Bypass -File .\scripts\package-release.ps1
```

Verify GitHub state without changing it:

```powershell
git status --short --branch
git log --oneline -3 --decorate
gh repo view RyandavisProject/vibemode --json name,visibility,url,defaultBranchRef
```
