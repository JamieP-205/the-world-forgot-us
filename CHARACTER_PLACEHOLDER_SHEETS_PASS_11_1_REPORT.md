# Character Placeholder Sheet Pass 11.1 Report

Goal: create and commit a consistent placeholder character sprite-sheet pack for
**both** the Player and the Hollow, ready for a later integration pass — and fix
the player sheets' row order to the canonical order from
`CHARACTER_SPRITE_SPEC.md`.

## Why placeholders were generated

The player/Hollow are still `Polygon2D` blockouts; real top-down art is a hard
blocker on new generation (`CHARACTER_ASSET_PROMPTS_PASS_11.md`). Painterly art
can't be produced in this environment, so these are **functional blockout
stand-ins** (clean shapes, not final art) drawn programmatically so a later pass
can wire them into `AnimatedSprite2D` and prove the animation/facing plumbing
before real art arrives. Both generators are deterministic and re-runnable.

## Entry state / safety

- Verified HEAD was `3144eb705e4434ccf05442c302dc40817542f3a2` (Pass 11) — the
  player_topdown assets from that turn were present but uncommitted.
- Godot 4.7 headless, 120 frames on entry: exit 0, no errors/warnings.

## Row order fix

- Player sheets were regenerated from `down / left / right / up` to the
  **canonical `down / up / left / right`** (top → bottom), matching
  `CHARACTER_SPRITE_SPEC.md`. The Hollow sheets use the same order. Verified
  visually (player row 0 = face/scarf down; row 1 = back-of-hood up; rows 2/3 =
  left/right).

## Files created / updated

### Generators (tools)
- `tools/gen_player_placeholder_sheet.py` — **updated**: canonical row order.
- `tools/gen_hollow_placeholder_sheet.py` — **new**: matching Hollow generator.

### Player pack — `assets/processed/player_topdown/`
- `player_idle.png` — 384 × 384 (4 dir × 4 frames)
- `player_walk.png` — 576 × 384 (4 dir × 6 frames)
- `player_attack.png` — 384 × 384 (4 dir × 4 frames)
- `player_hurt.png` — 192 × 384 (4 dir × 2 frames)
- `player_topdown_preview.png` — stacked reference (not for in-game use)
- `README_PLACEHOLDER.md` — slicing guide (updated to canonical order)

### Hollow pack — `assets/processed/hollow_topdown/`
- `hollow_idle.png` — 384 × 384 (4 dir × 4 frames)
- `hollow_walk.png` — 576 × 384 (4 dir × 6 frames)
- `hollow_attack.png` — 384 × 384 (4 dir × 4 frames)
- `hollow_hit.png` — 192 × 384 (4 dir × 2 frames)
- `hollow_death.png` — 576 × 384 (4 dir × 6 frames)
- `hollow_topdown_preview.png` — stacked reference (not for in-game use)
- `README_PLACEHOLDER.md` — slicing guide

### Docs
- `CHARACTER_ART_INTEGRATION_CHECKLIST.md` — clarified canonical row order and
  noted the placeholder sheets now exist at the two paths.
- `CHARACTER_PLACEHOLDER_SHEETS_PASS_11_1_REPORT.md` — this file.

## Sheet conventions

- **Row order:** `down / up / left / right` (both characters).
- **Cell size:** 96 × 96 px.
- **Columns:** animation frames — idle 4, walk 6, attack 4, player hurt 2 /
  Hollow hit 2, Hollow death 6.
- Transparent background (real alpha), **no baked shadow**, figure centred,
  consistent feet baseline, one file per animation.
- **Player:** rust-brown coat, small backpack, amber scarf facing-cue, cyan
  memory-tech dot. **Hollow:** pale gaunt forgotten humanoid, dark hollow core,
  faint cyan eyes/corruption, **no red**, visually distinct from the player
  (taller/thinner, no coat/pack).

## Known limitations

- Blockout geometry, **not** painterly/illustrated art — a functional stand-in.
- Facing "up" hides the face by design (back of head/hood); side views are simple
  offsets, not true profiles.
- Player `hurt` and Hollow `hit` frames are minimal (recoil/flash); the engine
  also applies its own modulate flash.
- Hollow `death` is per-direction (6 frames) rather than the spec's earlier
  direction-agnostic sketch — documented in the Hollow README; extra rows are
  harmless.
- Not yet imported/sliced into `SpriteFrames` and not referenced by any scene.

## No integration happened

Confirmed: **no** scene, script, or gameplay changes. `player.gd`,
`enemy_hollow.gd`, `player.tscn`, `enemy_hollow.tscn` are untouched. No
build/export, and the verified release ZIP is untouched. This pass only adds
generators, PNG assets, and docs.

## Validation

- Godot 4.7 headless, 120 frames (new PNGs present, unreferenced): **exit 0, no
  errors/warnings.**
- File sanity: all 11 PNGs exist with the expected dimensions; RGBA/alpha present;
  no green/magenta backgrounds; previews present; no temp/source-duplicate files.
- `git diff --check`: clean.

## Next recommended step

A dedicated **Character Art Integration** pass following
`CHARACTER_ART_INTEGRATION_CHECKLIST.md`: start with the player — hide the
polygon as `PlaceholderVisual`, add a `Visual` `AnimatedSprite2D` with a
`SpriteFrames` sliced from these sheets, add facing→animation logic in
`player.gd`, verify in-engine — then the Hollow. Keep it source-only until a
separate build pass re-cuts and re-verifies the ZIP.
