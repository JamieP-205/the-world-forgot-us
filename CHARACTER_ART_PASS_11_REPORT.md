# Character Art Request Pack Pass 11 Report

Goal: produce exact art-generation and integration specifications for replacing
the placeholder player and Hollow visuals **later**. No art was integrated, no
gameplay changed, no build/ZIP touched.

## Entry state / safety

- Verified active root and confirmed HEAD was
  `7ed598057683c94015683b296d846931552e214b` (Pass 10 tester handoff).
- Working tree clean on entry.
- Godot 4.7 headless, 120 frames on entry: **exit 0, 0 errors / 0 warnings.**

## Files read

- `README.md`, `ART_SPEC.md`, `NEXT_ASSET_REQUESTS.md`
- `VISUAL_AUDIO_PASS_9_REPORT.md`, `TESTER_HANDOFF_PASS_10_REPORT.md`
- `scenes/player/player.tscn`, `scenes/enemies/enemy_hollow.tscn`
- (plus the character scripts and the `assets/` tree for exact node names, collision
  sizes, facing/attack/death logic, asset paths, tools, and import settings.)

## 1. Current character setup (audited)

- **Player** `CharacterBody2D`, origin = body centre; collision `18×22`; drawn
  figure ~33 px; continuous `facing` vector drives a rotated `FacingIndicator`;
  attack = `SwingVisual`/`AttackArea` offset `facing*24` for 0.12 s; hurt =
  `$Visual.modulate` red flash. Script-referenced nodes: `Visual`,
  `FacingIndicator`, `Shadow`, `SwingVisual`, `SwingTimer`, `AttackArea`,
  `InteractionArea`, `ScannerComponent`, `Camera2D`, `HealthComponent`.
- **Hollow** `CharacterBody2D`, origin = body centre; collision `22×30`; pale
  humanoid; hurt = whole-node red `modulate` + `HitSpark`; death = whole-node
  cyan `modulate` alpha→0 over 0.45 s then `queue_free`, with defeated
  persistence; `ForgottenHaze` runs a shimmer. Script-referenced nodes:
  `HealthComponent`, `HitSpark`, `CollisionShape2D`, `ForgottenHaze`.
- **Camera** zoom `1.9` → design for ~32–40 px on-screen character height.

## What the current art blocker is

The **only** hard character blocker is that the existing generated sheets
(`player_4dir_concept`, `hollow_concept_sheet`) are **eye-level standing
turnarounds / side poses**, which read wrong in a top-down game where the body
rotates to face movement. So the player/Hollow are still `Polygon2D` blockouts.
The fix is new **top-down** sheets — not a code problem.

## Files created

- **`CHARACTER_SPRITE_SPEC.md`** — authoritative spec: measured current setup;
  shared delivery rules; strict player spec (§2) and Hollow spec (§3) with
  directions (down/up/left/right), animations, frame counts, `96×96` cells,
  pivots, palettes; naming convention; acceptance checklist.
- **`CHARACTER_ASSET_PROMPTS_PASS_11.md`** — copy-paste image-gen prompts: player
  sheet, Hollow sheet, player single-frame fallback, Hollow single-frame
  fallback, palette reference, optional attack-slash effect, optional Hollow
  death dissolve. Each carries a hard-constraints block that forbids eye-level
  turnarounds, textured/green mush backgrounds (uses transparent or a clean
  `#FF00FF` key for `chroma_extract_assets.py`), text/labels, inconsistent scale,
  off-grid poses, cropping, and perspective mismatch.
- **`CHARACTER_ART_INTEGRATION_CHECKLIST.md`** — placement paths
  (`assets/processed/{player_topdown,hollow_topdown}/`), how to keep the
  placeholder as a hidden `PlaceholderVisual` while a new `Visual`
  `AnimatedSprite2D` takes over (zero-script-change first step), `SpriteFrames`
  slicing + `<anim>_<dir>` naming, Godot import settings (lossless, mipmaps off,
  fix-alpha-border, filter choice), scale/feet/readability test at zoom 1.9,
  later animation-hook plan, an explicit "what NOT to touch" list, and a
  post-integration validation checklist.
- **`CHARACTER_ART_PASS_11_REPORT.md`** — this file.

## Files updated

- **`NEXT_ASSET_REQUESTS.md`** — the two character sections now point to the new
  spec/prompt/checklist files instead of vaguely asking for "better character
  art" (kept the existing summaries as a quick index; not a rewrite).

## Specs produced (summary)

- Player: `96×96` cells, rows = down/up/left/right, sheets for idle(×2),
  walk(×6), attack(×3), hurt(×1); coated scavenger w/ backpack; ~40 px in-game.
- Hollow: `96×96` cells, same directions, sheets for idle(×2), walk/shamble(×4),
  attack(×3), hit(×1), and a direction-agnostic death dissolve(×5); pale forgotten
  humanoid, no red; slightly taller/thinner than the player.
- Both: transparent-or-`#FF00FF` key, uniform grid, consistent scale, neutral
  lighting (so in-engine red/cyan `modulate` still reads), no baked shadow.

## Intentionally NOT changed

- No sprites generated or imported; no scene/script/gameplay edits.
- Collision sizes, layers, health, attack/scan/interaction, camera, save format,
  `WorldState`, persistent IDs — untouched.
- The verified release ZIP and export preset — untouched; **no rebuild**.

## Validation

- Godot 4.7 headless, 120 frames: **exit 0, 0 errors / 0 warnings.**
- `git diff --check`: clean.
- `git status -sb`: only the new/updated docs (no build/dist/artifacts).

## Remaining limitations (unchanged)

- Unsigned Windows executable.
- Player/Hollow still placeholder blockout art — this pass specs the replacement
  but does not perform it.
- Procedural placeholder audio only; no music/final sound.
- Next zone is only an ending hook.
- Persisted IDs tied to node names.
