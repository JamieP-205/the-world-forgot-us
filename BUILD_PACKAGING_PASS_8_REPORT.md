# Build Packaging Pass 8 Report

Goal: produce a clean, shareable Windows test build of the current demo and
wrap it in a lightweight tester package. No gameplay or content was added.

## Entry state and safety

- Verified the active project root and confirmed HEAD was `92371f2`, the
  expected checkpoint after Test Build Prep Pass 7.
- All existing export artifacts were present and non-empty, so the project was
  not re-exported.
- The Git index was missing on entry. It was rebuilt from HEAD with
  `git read-tree HEAD`, which did not alter any working-tree files. The recovered
  status showed only the two new packaging documents.
- The cleanup quarantine and cloud-sync duplicate files were not changed or
  deleted.

## Windows export

The existing Godot 4.7 release export is valid and remains at:

- `builds/windows-test/TheWorldForgotUs_Demo.exe` - 109,062,144 bytes
- `builds/windows-test/TheWorldForgotUs_Demo.pck` - 29,787,024 bytes

The export uses the machine-local `Windows Desktop` preset in
`export_presets.cfg`. The preset is git-ignored. The PCK is kept separate from
the executable, and GDScript is exported as binary tokens.

## Tester package

The completed tester package is:

`dist/TheWorldForgotUs_Demo_Windows/`

It contains exactly:

- `TheWorldForgotUs_Demo.exe`
- `TheWorldForgotUs_Demo.pck`
- `BUILD_NOTES.md`
- `README_TESTER.txt`

The executable and PCK were copied from `builds/windows-test/`. No source files
are included.

## Smoke test and validation

- Exported build smoke:
  `builds/windows-test/TheWorldForgotUs_Demo.exe --headless --quit-after 120`
  completed successfully. A hidden, waited process run confirmed exit code 0.
- Project validation:
  Godot `4.7.stable.official.5b4e0cb0f` ran the project headlessly for
  120 frames and returned exit code 0 with no errors or warnings.
- `git diff --check`: passed with exit code 0.
- `git check-ignore` confirmed both the build executable and tester-package
  executable are ignored by the `builds/` and `dist/` rules.
- `git check-ignore` also confirmed `export_presets.cfg` remains ignored.
- Exported binaries and machine-local preset files are not committed.

## Files added by this pass

- `BUILD_NOTES.md`
- `BUILD_PACKAGING_PASS_8_REPORT.md`
- Git-ignored files under `builds/windows-test/`
- Git-ignored files under `dist/TheWorldForgotUs_Demo_Windows/`
- Git-ignored machine-local `export_presets.cfg`

No gameplay content, scenes, systems, costs, collisions, or save format were
changed.

## Remaining limitations

- The Windows executable is not code-signed, so SmartScreen may warn and require
  testers to choose "Run anyway".
- Player and Hollow visuals remain placeholder/blockout art, and there is no
  final audio pass.
- The next zone remains an ending hook rather than a playable area.
- Persisted IDs are tied to placed node names.
- The PCK contains the inert cloud-sync duplicate memory-echo script. It is not
  referenced by a scene and was intentionally left in place.
