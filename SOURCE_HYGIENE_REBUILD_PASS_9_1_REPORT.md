# Source Hygiene + Rebuild Pass 9.1 Report

Goal: remove the inert cloud-sync duplicate script from the Godot project safely
(quarantine, not delete), then rebuild the Windows tester ZIP so it carries the
Pass 9 visual/audio improvements.

## 1. Entry state / safety

- Verified active root and confirmed HEAD was
  `b6e078c270ae42e73e7a26171becc7c2f0eb76a1` (Pass 9 visual/audio polish).
- Working tree clean on entry.

## 2. Duplicate inspection

Found the cloud-sync duplicate **tracked in git** (it predated the `*Name clash*`
`.gitignore` rule, which cannot untrack already-committed files):

- `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd`
- `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd.uid`  (uid `dga5h33ce4k05`)

Reference check — the duplicate is **not** referenced by anything that matters:

- `project.godot`: no reference.
- `.tscn` / `.tres`: none. `scenes/world/memory_echo.tscn` references the **real**
  `res://scripts/world/memory_echo.gd`.
- `.gd`: none.
- `export_presets.cfg`: only names it inside an `exclude_filter` (so it was being
  kept out of the build anyway).
- The duplicate's uid `dga5h33ce4k05` appears nowhere in the project.
- Only mentions are in documentation and the `.gitignore` rule.

Both `memory_echo.gd` and the duplicate declare `class_name MemoryEcho`, which is
exactly what produced the "hides a global script class" parse error in Pass 9
smoke testing.

## 3. Moved the duplicate out of the Godot project

- **From:** `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd` (+ `.gd.uid`)
- **To:** `C:\Users\Jamie Parr\Documents\Projects\the-world-forgot-us\_local_quarantine\cloud_sync_duplicates\`
  (outside the Godot project root — one level above the repo).

Method: copied both files to the quarantine (preserving timestamps), then
`git rm` on the tracked paths (stages the removal and clears them from the working
tree). **Not deleted** — the originals are preserved in the quarantine.

- The real `scripts/world/memory_echo.gd` (and its `.uid`) were **not touched**.
- The pre-existing cloud-sync README duplicate and the separate cleanup quarantine
  were **not touched**.

## 4. Confirmed the duplicate is no longer parsed

- The generated class cache (`.godot/global_script_class_cache.cfg`, git-ignored)
  initially still pointed `MemoryEcho` at the duplicate path. Forced a rescan with
  `--headless --import`; the cache now maps `MemoryEcho` →
  `res://scripts/world/memory_echo.gd` with **no** duplicate reference.
- World-load smoke (temporary main scene that instances `test_map.tscn` +
  `memory_echo.tscn`, then removed): loaded with **no** "hides a global script
  class" / duplicate-class error. `DUP_SMOKE_RESULT: PASS`.

## 5. Source validation

- Godot 4.7 headless, 120 frames: **exit 0, 0 errors / 0 warnings.**
- `git diff --check`: clean (exit 0).

## 6. Rebuild (Windows Desktop, existing preset)

Exported release with the existing `Windows Desktop` preset:

- `builds/windows-test/TheWorldForgotUs_Demo.exe` — 109,062,144 bytes
- `builds/windows-test/TheWorldForgotUs_Demo.pck` — 29,794,544 bytes

Confirmed the duplicate filename is **absent** from the packed `.pck`. Binaries
are **not committed** (git-ignored under `builds/`).

## 7. Tester package refreshed

`dist/TheWorldForgotUs_Demo_Windows/` now contains exactly:

- `TheWorldForgotUs_Demo.exe`  (rebuilt)
- `TheWorldForgotUs_Demo.pck`  (rebuilt)
- `README_TESTER.txt`  (updated: Pass 9 visuals/audio note, commit/date footer)
- `BUILD_NOTES.md`  (updated: commit/source state, Pass 9 improvements, date 2026-07-09)

## 8. ZIP rebuilt

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- Contains only the four root-level files above — **no** source folders, `.git`,
  `scripts/`, `scenes/`, resources, cleanup quarantine, cloud-sync duplicates, or
  temp files.

## 9. ZIP verification

Extracted to `dist/_zip_verify/` (git-ignored), which held exactly the four
intended files. Ran the extracted build headless:

`TheWorldForgotUs_Demo.exe --headless --quit-after 120` → **exit 0**, no crash,
booted from its packed data. Temp extraction files were removed after
verification (the now-empty `_zip_verify/` directory handle was briefly held by
cloud sync; it is empty and git-ignored, so it is inert and will clear on its own).

## Hashes / size

- **ZIP size:** 67,291,497 bytes
- **ZIP  SHA-256:** `8A40B90FFE4121CB4EAFEABF12D15D8C0601398FA593C07826343A405625FBE1`
- **EXE  SHA-256:** `DFFDB890DCB5575B2259E0D5B2E34BB1CC3793ABDB1B2B967B93026FF6B91AA3`
- **PCK  SHA-256:** `52D131A3E78B741E51629386ABFE2A85C90EEB7892CADD4F058980EFE57AC010`

(For reference, the previous verified ZIP was
`00EE85989375C9211BFB794A916DB4FC1A36772B6EF356F12DB1AAC49B261150`, 67,286,845
bytes; that build did not include Pass 9. The exe hash is unchanged because the
Godot runtime stub is identical; the pck changed to carry the Pass 9 source.)

## Ignore / commit hygiene

- `git check-ignore` confirms `builds/…exe`, `builds/…pck`,
  `dist/TheWorldForgotUs_Demo_Windows.zip`, the dist package files, and
  `dist/_zip_verify` are all ignored.
- `export_presets.cfg` remains machine-local / git-ignored and was not staged.
- The moved-duplicate quarantine folder lives outside the repo and is not staged.
- Committed tracked changes only: the two duplicate deletions, the new
  `audio_manager.gd.uid` sidecar (matches the repo convention of tracking `.uid`
  files), `BUILD_NOTES.md`, `README.md`, and this report.

## Files touched (tracked)

- **removed** `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd` (quarantined)
- **removed** `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd.uid` (quarantined)
- **new** `scripts/systems/audio_manager.gd.uid` (Godot-generated sidecar for the Pass 9 script)
- `BUILD_NOTES.md` — refreshed for this rebuild.
- `README.md` — corrected the now-accurate Export / build status section.
- **new** `SOURCE_HYGIENE_REBUILD_PASS_9_1_REPORT.md` (this file).

Untracked/ignored (not committed): `builds/`, `dist/` (package + ZIP),
`export_presets.cfg`, temporary smoke/verify artifacts.

## Remaining limitations

- Unsigned Windows executable (SmartScreen warning).
- Player/Hollow still placeholder blockout art (improved, not replaced).
- Audio is procedural placeholder tones only; no music or final sound design.
- Next zone is still only an ending hook.
- Persisted IDs are tied to node names.
- Fresh export environments must still recreate the machine-local preset; the
  duplicate-exclusion `exclude_filter` is now moot (the duplicate no longer
  exists in the project) but harmless if left in place.
