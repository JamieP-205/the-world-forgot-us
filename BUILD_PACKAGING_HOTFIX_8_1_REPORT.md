# Build Packaging Hotfix 8.1 Report

Goal: remove the inert cloud-sync conflict script from the Windows tester
package without deleting or modifying the source conflict file.

## Duplicate identified

The previous PCK contained:

`scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd`

Its source sidecar is:

`scripts/world/memory_echo (# Name clash 2026-07-07 2xs3wlC #).gd.uid`

The sidecar UID is `uid://dga5h33ce4k05`. Exact path and UID searches found no
references in `project.godot`, `.tscn`, `.tres`, `.gd`, or
`export_presets.cfg` files.

## Safe exclusion

The machine-local, git-ignored `export_presets.cfg` now uses an exact
`exclude_filter` for the duplicate `.gd` path and its `.gd.uid` sidecar. No
project directory was broadly ignored.

The source duplicate and sidecar remain in place and are byte-identical to
HEAD. No sync-conflict file, cleanup quarantine, or user archive was deleted,
moved, staged, or modified.

## Re-export and package

Godot `4.7.stable.official.5b4e0cb0f` completed the Windows Desktop release
export with exit code 0.

- Build: `builds/windows-test/TheWorldForgotUs_Demo.exe`
- Build PCK: `builds/windows-test/TheWorldForgotUs_Demo.pck`
- Tester package: `dist/TheWorldForgotUs_Demo_Windows/`
- Rebuilt PCK size: 29,779,284 bytes
- Rebuilt PCK SHA-256:
  `EDAC7A96F3D864E2B389330A5E262C5DBB23D8D79BEB7222D6D90AF322EC96CB`

The tester package executable, PCK, and build notes match their build-source
files by SHA-256.

## Verification

- Before the hotfix, direct PCK inspection found the conflict `.gd` filename.
- After the hotfix, direct inspection found no conflict `.gd`, `.gd.uid`, or
  `.gdc` filename in either the build PCK or tester-package PCK.
- README sync-conflict filenames were also absent from the rebuilt PCK.
- Exported build headless smoke for 120 frames: exit code 0.
- Godot project headless validation for 120 frames: exit code 0, with no errors
  or warnings.
- `git diff --check`: passed with exit code 0.
- `git check-ignore` confirmed `builds/`, `dist/`, and `export_presets.cfg`
  remain ignored.

## Files touched

- New tracked report: `BUILD_PACKAGING_HOTFIX_8_1_REPORT.md`
- Updated ignored machine-local preset: `export_presets.cfg`
- Rebuilt ignored output: `builds/windows-test/TheWorldForgotUs_Demo.exe`
- Rebuilt ignored output: `builds/windows-test/TheWorldForgotUs_Demo.pck`
- Refreshed ignored tester package under
  `dist/TheWorldForgotUs_Demo_Windows/`

No gameplay, balance, scene, save, or system files changed.

## Remaining limitations

- The Windows executable is not code-signed, so SmartScreen may warn.
- Player and Hollow visuals remain placeholder/blockout art, with no final
  audio pass.
- The next zone remains an ending hook rather than a playable area.
- Persisted IDs are tied to placed node names.
- The exclusion lives in the ignored machine-local export preset. Any fresh
  export environment must reproduce the same exact exclusion.
