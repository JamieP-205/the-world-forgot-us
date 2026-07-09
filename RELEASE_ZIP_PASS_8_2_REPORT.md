# Release Zip Verification Pass 8.2 Report

Goal: verify the existing zipped Windows tester build is complete, clean,
launchable, and ready to share without rebuilding or modifying release
artifacts.

## Verified state

- Verified project HEAD:
  `08e24efe7e593ff1a6e46e1a5f18ee4a6b7f07ab`
- Tracked working tree was clean before verification.
- The existing ZIP and tester package were present, so no export or
  recompression was performed.

## Release ZIP

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- Size: 67,286,845 bytes
- SHA-256:
  `00EE85989375C9211BFB794A916DB4FC1A36772B6EF356F12DB1AAC49B261150`

The ZIP contains exactly four root-level files:

- `TheWorldForgotUs_Demo.exe` - 109,062,144 bytes
- `TheWorldForgotUs_Demo.pck` - 29,779,284 bytes
- `README_TESTER.txt` - 3,345 bytes
- `BUILD_NOTES.md` - 2,266 bytes

No project source folders, `.git` data, cleanup quarantine, cloud-sync
duplicates, old exports, or temporary files were present.

## Extraction and smoke test

The ZIP was extracted to the temporary ignored folder `dist/_zip_verify/`.
The extracted folder contained exactly the same four intended files.

The extracted executable was launched from that folder with:

`TheWorldForgotUs_Demo.exe --headless --quit-after 120`

Result: exit code 0, no immediate crash, and the game booted from its adjacent
packed data. The extracted EXE and PCK SHA-256 hashes matched the build outputs.
Direct inspection also confirmed the sync-conflict script filename was absent
from the extracted PCK.

The temporary extraction folder was safely deleted after verification.

## Release hashes

- ZIP:
  `00EE85989375C9211BFB794A916DB4FC1A36772B6EF356F12DB1AAC49B261150`
- Windows executable:
  `DFFDB890DCB5575B2259E0D5B2E34BB1CC3793ABDB1B2B967B93026FF6B91AA3`
- Windows PCK:
  `EDAC7A96F3D864E2B389330A5E262C5DBB23D8D79BEB7222D6D90AF322EC96CB`

## Git and packaging validation

- `git diff --check`: passed with exit code 0.
- `git check-ignore` confirmed the ZIP, build EXE/PCK, tester package, and
  temporary extraction path are ignored by the existing `dist/` and `builds/`
  rules.
- No binaries, ZIP files, export preset, sync-conflict files, or temporary
  extraction files are included in the report commit.

## Files touched

- New tracked report: `RELEASE_ZIP_PASS_8_2_REPORT.md`
- Temporary ignored verification folder: `dist/_zip_verify/` (created and
  deleted during verification)

The existing ZIP, build outputs, tester package, gameplay, balance, scenes,
saves, systems, cleanup quarantine, archives, and sync-conflict files were not
modified.

## Remaining limitations

- The Windows executable is unsigned, so SmartScreen may warn.
- Player and Hollow visuals remain placeholder/blockout art, with no final
  audio pass.
- The next zone remains an ending hook rather than a playable area.
- Persisted IDs are tied to placed node names.
- Fresh export environments must recreate the exact machine-local export
  exclusion for the sync-conflict script.
