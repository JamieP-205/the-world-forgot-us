# Build / Repackage Pass 12.1 Report

Goal: rebuild the shareable Windows demo ZIP so it includes the Pass 12 animated
placeholder character sprites. No gameplay change; docs-only commit (binaries/ZIP
stay git-ignored).

## Source commit used for the build

`2b655f76cb45ff7d066f84fd6a56436a80b6a670` (Pass 12 — "art: integrate placeholder
character sprites"), branch `master`. Working tree was clean before edits.

## Entry checks

- HEAD confirmed at `2b655f7`; clean.
- Godot 4.7 headless, 120 frames: exit 0, no errors/warnings.
- Export templates `4.7.stable` present (`windows_release_x86_64.exe`).
- Existing `Windows Desktop` preset intact → `builds/windows-test/TheWorldForgotUs_Demo.exe`.
  (Preset unchanged; its now-moot `exclude_filter` for the removed cloud-sync
  duplicate is harmless.)

## Build output

Re-exported release (headless `--export-release "Windows Desktop"`):

- `builds/windows-test/TheWorldForgotUs_Demo.exe` — 109,062,144 bytes
- `builds/windows-test/TheWorldForgotUs_Demo.pck` — 30,197,804 bytes
  (up from 29,794,544 in Pass 9.1 — the added sprite sheets + SpriteFrames)

Binaries are **not committed** (git-ignored under `builds/`).

## Tester package

`dist/TheWorldForgotUs_Demo_Windows/` refreshed to exactly:

- `TheWorldForgotUs_Demo.exe` (rebuilt)
- `TheWorldForgotUs_Demo.pck` (rebuilt)
- `README_TESTER.txt` (art line updated: animated placeholder sprites)
- `BUILD_NOTES.md` (updated: Pass 12 content + commit `2b655f7`)

## Shareable ZIP

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- **Size: 67,641,306 bytes**
- Contains exactly four root-level files (exe, pck, README_TESTER.txt,
  BUILD_NOTES.md) — no source folders, `.git`, `scripts/`, `scenes/`,
  `resources/`, quarantine, cloud-sync duplicates, or temp files.

## ZIP verification (extract + smoke)

Extracted to `dist/_zip_verify/` (four intended files only); ran
`TheWorldForgotUs_Demo.exe --headless --quit-after 120` → **exit 0**, booted from
packed data, no crash. Temp extraction folder removed afterward.

## PCK content check (Pass 12 assets present)

Searched the rebuilt `.pck`:

- `player_placeholder_spriteframes` — present
- `hollow_placeholder_spriteframes` — present
- `player_topdown` sprite PNGs — present (incl. `player_idle.png`, `player_walk.png`)
- `hollow_topdown` sprite PNGs — present (incl. `hollow_idle.png`, `hollow_death.png`)
- Cloud-sync `memory_echo (# Name clash ... #)` duplicate — **absent** (0 matches).

## Hashes

- **ZIP  SHA-256:** `59F4F29AA23212AE047CF4098958A0E041DE48567D856D18B0CDF2417F603DF4`
- **EXE  SHA-256:** `DFFDB890DCB5575B2259E0D5B2E34BB1CC3793ABDB1B2B967B93026FF6B91AA3`
  (unchanged — the Godot runtime stub is identical build-to-build)
- **PCK  SHA-256:** `2E0FCBFDD4D850AF570148A47BF5291020F8FE367B7F2C2608B34E0E4A76925C`
  (new — carries the Pass 12 sprites)

Previous (Pass 9.1) ZIP was `8A40B90F…B261150` / 67,291,497 bytes — superseded.

## Validation

- Godot 4.7 headless, 120 frames (source project): **exit 0, no errors/warnings.**
- Extracted-ZIP smoke: **exit 0.**
- `git diff --check`: clean.
- `git check-ignore` confirms `builds/…exe`, `builds/…pck`,
  `dist/TheWorldForgotUs_Demo_Windows.zip`, and the dist package files are
  ignored; `export_presets.cfg` remains ignored. No binaries/ZIP committed.

## Files committed (docs only)

- `BUILD_NOTES.md` — Pass 12 content + commit `2b655f7`.
- `README.md` — updated current-ZIP size/SHA-256.
- `BUILD_REPACKAGE_PASS_12_1_REPORT.md` — this file.

(The `dist/…/README_TESTER.txt` art-line tweak lives only inside the git-ignored
package/ZIP and is not committed.)

## Remaining limitations

- Unsigned Windows executable (SmartScreen warning).
- Character sprites are still **placeholder blockout** stand-ins, not final art.
- Procedural placeholder audio only; no music/final sound.
- Next zone is only an ending hook.
- Persisted IDs tied to node names.
