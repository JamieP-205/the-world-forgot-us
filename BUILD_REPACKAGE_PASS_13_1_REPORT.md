# Build/Repackage Pass 13.1 Report

## Source

- Source commit used for build: `787fe114d2e75b9e582643ef8b96d68e6fd08219`
- Commit message: `fix: improve demo playability and visual cohesion`
- Branch: `master`
- Build pass: Pass 13.1 - Windows demo ZIP rebuilt to include Pass 13 Quality Rescue fixes.

## Outputs

- Build output: `builds/windows-test/TheWorldForgotUs_Demo.exe`
- Packed data: `builds/windows-test/TheWorldForgotUs_Demo.pck`
- Tester package: `dist/TheWorldForgotUs_Demo_Windows/`
- ZIP: `dist/TheWorldForgotUs_Demo_Windows.zip`
- ZIP size: 67,652,404 bytes

## SHA256

- `dist/TheWorldForgotUs_Demo_Windows.zip`: `9FCA718E42EDD91A3372A644463D8ED4755E8B0D674A28EC45E58CF8AAD47A99`
- `builds/windows-test/TheWorldForgotUs_Demo.exe`: `DFFDB890DCB5575B2259E0D5B2E34BB1CC3793ABDB1B2B967B93026FF6B91AA3`
- `builds/windows-test/TheWorldForgotUs_Demo.pck`: `CC1AC9F40A1DFCFD1CF0F33BE66C8D07CE88BDCC2430444A0471F32CED515B04`

## Export Setup

- Godot version: 4.7 stable (`4.7.stable.official.5b4e0cb0f`).
- Export preset: existing `Windows Desktop` preset used without recreation.
- Export path: `builds/windows-test/TheWorldForgotUs_Demo.exe`.
- Export templates: confirmed installed/usable by successful `--export-release "Windows Desktop"` export.

## Package Contents

`dist/TheWorldForgotUs_Demo_Windows/` and the ZIP contain exactly these root-level files:

- `TheWorldForgotUs_Demo.exe`
- `TheWorldForgotUs_Demo.pck`
- `README_TESTER.txt`
- `BUILD_NOTES.md`

The ZIP does not include source folders, `.git`, `scripts/`, `scenes/`, `resources/`, quarantine folders, cloud-sync duplicates, or temp extraction folders.

## Smoke / Validation

- Godot project validation before export: Godot 4.7 headless, 120 frames, exit code 0.
- Exported ZIP smoke: extracted to `dist/_zip_verify/`, ran `TheWorldForgotUs_Demo.exe --headless --quit-after 120`, exit code 0.
- Verification folder cleanup: `dist/_zip_verify/` removed after the successful smoke test.
- Final Godot project validation: Godot 4.7 headless, 120 frames, exit code 0.
- `git diff --check`: clean.

## PCK Content Check

The rebuilt `TheWorldForgotUs_Demo.pck` was byte-scanned for Pass 13 content. Confirmed present:

- `scripts/ui/compass.gd` / `scripts/ui/compass.gdc`
- `resources/upgrades/scanner_coil.tres`, `scanner_coil`, `Scanner Coil`
- `resources/upgrades/base_lantern.tres`, `base_lantern`, `Signal Lantern`
- `scripts/base/keepsake_shelf.gd`, `keepsake_shelf`, `Memory Shelf`
- `scripts/world/memory_echo.gd` / `memory_echo.gdc`
- `scripts/systems/audio_manager.gd` / `audio_manager.gdc`
- `eat` and `keepsake` audio cue strings

The compiled PCK did not expose the word `ambient` as plain text, but the packed `audio_manager` entries are present and source verification confirms the Pass 13 ambient wind loop is in `scripts/systems/audio_manager.gd`.

Cloud-sync duplicate check: no `Name clash`, `2xs3wlC`, or `memory_echo (#` strings were found in the rebuilt PCK. The export preset still excludes the old duplicate `scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd` and `.uid` paths.

## Ignored Artifacts

Confirmed ignored by `git check-ignore`:

- `builds/windows-test/TheWorldForgotUs_Demo.exe`
- `builds/windows-test/TheWorldForgotUs_Demo.pck`
- `dist/TheWorldForgotUs_Demo_Windows.zip`
- `dist/TheWorldForgotUs_Demo_Windows/BUILD_NOTES.md`

No build binaries, PCK, ZIP, temp extraction folder, `export_presets.cfg`, or quarantine folders were staged.

## Remaining Limitations

- The executable is unsigned. Windows SmartScreen may warn.
- Player/Hollow sprites and several buildings remain placeholder blockout assets, not final art.
- Audio is procedural placeholder sound only; there is no final sound design or music yet.
- The next zone is only an ending hook; no new area loads yet.
- Persisted scene IDs are tied to node names, so future content renames need migration care.