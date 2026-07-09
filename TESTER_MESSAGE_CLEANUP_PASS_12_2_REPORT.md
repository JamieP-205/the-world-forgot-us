# Tester Message Cleanup Pass 12.2 Report

Goal: make the tester send-message safe to paste alongside the final ZIP, with no
references to files that aren't inside that ZIP.

## Issue fixed

`TESTER_SEND_MESSAGE.md`'s copy-paste block pointed testers at
`TESTER_FEEDBACK_TEMPLATE.md` ("there's a short list of questions in
`TESTER_FEEDBACK_TEMPLATE.md`"), but that file is **not** inside the shareable
ZIP. The ZIP contains only:

- `TheWorldForgotUs_Demo.exe`
- `TheWorldForgotUs_Demo.pck`
- `README_TESTER.txt`
- `BUILD_NOTES.md`

The message now **embeds the feedback questions directly** (Did it launch OK? Did
you understand what to do? Did anything break? etc.), so a tester needs nothing
beyond what's in the ZIP.

## Files updated

- `TESTER_SEND_MESSAGE.md` — rewrote the copy-paste block with the agreed wording;
  removed the `TESTER_FEEDBACK_TEMPLATE.md` reference; put the feedback questions
  inline. Also adjusted the intro note to say the questions are built into the
  message.
- `TESTER_MESSAGE_CLEANUP_PASS_12_2_REPORT.md` — this report.

## Checked, not changed (no wrong implication)

- `KNOWN_ISSUES_FOR_TESTERS.md` — does not mention the feedback template at all.
- `README.md` — its "Sharing with testers" note lists the repo handoff docs (for
  the developer) and explicitly states the ZIP itself carries only
  `README_TESTER.txt` + `BUILD_NOTES.md`. It does not imply the feedback template
  is in the ZIP, so it was left as-is (no over-editing).
- `BUILD_NOTES.md` — unchanged; already accurate.

## ZIP left untouched

Confirmed the shareable ZIP was **not** rebuilt or modified this pass:

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- Size: **67,641,306 bytes**
- SHA-256: `59F4F29AA23212AE047CF4098958A0E041DE48567D856D18B0CDF2417F603DF4`

(Identical to the Pass 12.1 release hash/size.) No export/rebuild; no touch to
`builds/`, `dist/`, exe, pck, zip, temp folders, quarantine, or
`export_presets.cfg`.

## Validation

- `TESTER_SEND_MESSAGE.md` contains **0** references to `TESTER_FEEDBACK_TEMPLATE.md`.
- `git diff --check`: clean.
- `git status -sb`: only docs changed (`TESTER_SEND_MESSAGE.md` + this report).
- Godot 4.7 headless, 120 frames: exit 0, no errors/warnings (docs-only change,
  run as a sanity check).
