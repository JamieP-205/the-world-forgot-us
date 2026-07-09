# Tester Handoff + Feedback Prep Pass 10 Report

Goal: get the already-verified demo ZIP ready to send to real testers by adding
the tester-facing paperwork (send message, feedback form, known issues) and
tightening the README. No gameplay change; no rebuild unless tester docs
required it (they did not).

## Entry state / safety

- Verified active root and confirmed HEAD was
  `93047856cd684b3524f3f44f91f08ccddad1a565` (Pass 9.1 rebuild).
- Working tree clean on entry.
- Godot 4.7 headless, 120 frames on entry: **exit 0, 0 errors / 0 warnings.**

## 1. Tester handoff audit

Reviewed `README.md`, `BUILD_NOTES.md`, the in-ZIP
`dist/TheWorldForgotUs_Demo_Windows/README_TESTER.txt`, and
`SOURCE_HYGIENE_REBUILD_PASS_9_1_REPORT.md`.

A brand-new tester **can** already learn: what the game is, how to run it (unzip,
keep `.exe`+`.pck` together, double-click, expect a SmartScreen warning),
controls, the ~5–10 min test route, how to reset the save, and what's known
placeholder — mostly via the in-ZIP `README_TESTER.txt` + `BUILD_NOTES.md`, which
are current and accurate. Gaps for a real send: no ready-to-paste message, no
concise feedback form, and no single "what's expected vs. a real bug" sheet.
This pass adds those.

## 2–4. New tester-facing docs (created, tracked)

- **`TESTER_FEEDBACK_TEMPLATE.md`** — short, copy-pasteable feedback form:
  launch/SmartScreen, first-minute clarity, controls, the echo moment, Railhome
  progress, save/Continue, weird resets, audio, boring/confusing/ugly, "want the
  next zone?", bugs/crashes, and optional PC specs. Kept short so people actually
  fill it in.
- **`TESTER_SEND_MESSAGE.md`** — casual, non-corporate copy-paste message to send
  with the ZIP: what it is, how to run it, the unsigned/SmartScreen heads-up,
  controls, ~5–10 min playtime, the kind of feedback wanted, and an explicit
  "it's early — placeholder art, no final audio, next zone is just a hook."
- **`KNOWN_ISSUES_FOR_TESTERS.md`** — expected-and-not-a-bug list (SmartScreen,
  placeholder art, placeholder audio, teaser-only next zone, manifest storage,
  basic combat, plain UI), a "possible real bugs to watch for" list, save-reset
  steps, and a one-paragraph reminder of what the demo is.

## 5. README check

The README's **Export / build status** section was **already corrected in Pass
9.1** (it no longer claims "no build / templates missing"), so it was not stale.
It was, however, missing tester-handoff specifics, so I **added** (did not
rewrite): the current ZIP path/size/SHA-256, a "to run the packaged build" note
(unzip, keep exe+pck together, double-click, SmartScreen → Run anyway), and a
short "Sharing with testers" pointer to the three new docs. The dev "Run from
Godot" instructions were already present and correct. Nothing was overstated.

## 6. Package-doc refresh / ZIP

The in-ZIP tester docs (`README_TESTER.txt`, `BUILD_NOTES.md`) are already current
and accurate (updated during Pass 9.1), so **no dist docs were changed and the
ZIP was NOT rebuilt or re-zipped.** The verified ZIP is left exactly as-is.

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- Size: **67,291,497 bytes** (unchanged)
- SHA-256: **`8A40B90FFE4121CB4EAFEABF12D15D8C0601398FA593C07826343A405625FBE1`**
  (re-verified this pass — matches Pass 9.1).

## 7. Files created / updated

- **new** `TESTER_FEEDBACK_TEMPLATE.md`
- **new** `TESTER_SEND_MESSAGE.md`
- **new** `KNOWN_ISSUES_FOR_TESTERS.md`
- **new** `TESTER_HANDOFF_PASS_10_REPORT.md` (this file)
- `README.md` — added current-ZIP hash/size, packaged-run steps, and a tester-docs
  pointer (additive, not a rewrite).

No gameplay, scenes, systems, save format, build, or dist artifacts were changed.

## 8. Validation

- Godot 4.7 headless, 120 frames: **exit 0, 0 errors / 0 warnings.**
- `git diff --check`: clean.
- ZIP: **not changed** this pass; SHA-256 re-verified equal to the recorded value,
  so no re-extraction/re-hash of a new artifact was required.
- Only tracked docs are staged; `builds/`, `dist/`, exe, pck, zip, temp folders,
  the cleanup quarantine, the local quarantine, and `export_presets.cfg` are all
  ignored / not staged.

## Whether the ZIP was changed

**Left untouched.** This is a docs-only pass.

## Remaining limitations

- Unsigned Windows executable (SmartScreen warning).
- Player/Hollow still placeholder blockout art (improved, not final).
- Procedural placeholder audio only; no music or final sound design.
- Next zone is still only an ending hook.
- Persisted IDs are tied to node names.
- The machine-local `export_presets.cfg` still carries the now-moot
  duplicate-exclusion `exclude_filter` (harmless after the Pass 9.1 cleanup).
