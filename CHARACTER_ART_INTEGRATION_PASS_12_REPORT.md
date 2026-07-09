# Character Art Integration Pass 12 Report

Goal: wire the existing placeholder top-down sprite sheets into the Player and
Hollow via `AnimatedSprite2D`, preserving all gameplay behaviour. No new art, no
sheet changes, no export/ZIP change.

## Entry state / safety

- Verified HEAD was `d32fab0f56c0c2de2546a4306a16da8d055ae2eb` (Pass 11.1); clean.
- Godot 4.7 headless, 120 frames on entry: exit 0, no errors/warnings.

## 1. SpriteFrames resources (new)

Built programmatically by a new tool `tools/build_spriteframes.gd` (headless
`-s`), slicing the sheets on the canonical grid (cell 96×96; rows 0=down, 1=up,
2=left, 3=right):

- `resources/spriteframes/player_placeholder_spriteframes.tres` — **16
  animations / 64 frames**: `idle_*`(4) `walk_*`(6) `attack_*`(4) `hurt_*`(2) ×
  {down,up,left,right}. Loop on idle/walk; one-shot on attack/hurt.
- `resources/spriteframes/hollow_placeholder_spriteframes.tres` — **20
  animations / 88 frames**: `idle_*`(4) `walk_*`(6) `attack_*`(4) `hit_*`(2)
  `death_*`(6) × 4 dirs. Loop on idle/walk; one-shot on attack/hit/death.

Each frame is an `AtlasTexture` over the sheet PNG at `Rect2(col*96, row*96, 96,
96)`. The builder is re-runnable if the sheets change.

## 2. Player integration

**`scenes/player/player.tscn`**
- Old polygon `Visual` (+ `Coat`/`Head`/`Backpack`) renamed to **`PlaceholderVisual`,
  `visible = false`** (kept as a hidden fallback).
- New **`Visual` = `AnimatedSprite2D`** with the player SpriteFrames,
  `animation = idle_down`, `offset = (0,-5)` so the figure's feet land on the old
  footprint. Scale 1.0 → the 96-cell figure reads at ~the old size.
- `FacingIndicator` set `visible = false` (the sprite now conveys facing); node
  kept so the existing script reference still resolves.
- Collision (18×22), `Shadow`, `InteractionArea`, `AttackArea`, `SwingVisual`,
  `ScannerComponent`, `Camera2D`, `HealthComponent` all unchanged.

**`scripts/player/player.gd`** (minimal, additive)
- `_visual` retyped `Polygon2D → AnimatedSprite2D` (still the `$Visual` node;
  hurt-flash `modulate` still works).
- Added `_facing_dir()` (continuous facing → down/up/left/right), `_play_action()`
  (one-shot with a short `_anim_lock`), and `_update_locomotion()` (idle vs walk),
  called from the existing `_handle_movement()`.
- Attack plays `attack_<dir>`; taking damage plays `hurt_<dir>`; `_ready` starts
  `idle_down`. **Movement, combat hitbox, cooldowns, scanner, and interaction are
  untouched.**

## 3. Hollow integration

**`scenes/enemies/enemy_hollow.tscn`**
- Old polygon `Visual` (+ children) renamed to **`PlaceholderVisual`,
  `visible = false`**.
- New **`Visual` = `AnimatedSprite2D`** with the Hollow SpriteFrames,
  `animation = idle_down`, `offset = (0,-8)` to match the old footprint.
- **`ContactShadow` and `ForgottenHaze` kept** (grounding + cyan shimmer); no red
  aura reintroduced. `HitSpark`, collision (22×30), `HealthComponent` unchanged.

**`scripts/enemies/enemy_hollow.gd`** (minimal, additive)
- Added `@onready _visual`, a tracked `_face`, and `_anim_lock`.
- `_update_anim()` (called after `move_and_slide`) plays `walk_<dir>` while
  chasing / `idle_<dir>` while still, facing derived from velocity.
- `_flash()` also plays `hit_<dir>`; `_on_died()` plays `death_<dir>` before the
  existing fade. **AI, detection, contact damage, stats, the cyan death fade,
  `AudioManager` hits, camera shake, `WorldState` defeat persistence, and
  `queue_free` timing are all unchanged.** The whole-node `modulate` red/cyan
  flashes now also tint the sprite (intended).

## 4. Fallback safety

Both old polygon visuals are preserved as hidden `PlaceholderVisual` nodes.
Reverting is as simple as hiding the `AnimatedSprite2D` and re-showing
`PlaceholderVisual` (plus retyping `_visual`), with no data loss.

## 5. Visual / behaviour sanity (verified)

- Headless boot: scripts parse, scenes load — exit 0.
- **World-load smoke** (temp driver, removed): player + Hollow spawn; both
  `Visual` nodes are `AnimatedSprite2D` playing `idle_down`; every referenced
  animation (`idle/walk/attack/hurt|hit/death` × dirs) exists; both
  `PlaceholderVisual` nodes present and hidden; driving `take_damage`,
  `_try_attack`, and a lethal hit ran hurt/attack/hit/death with **no errors** →
  `SMOKE12_RESULT: PASS`.
- **In-engine screenshot** (temp, removed): player (coated survivor, facing left,
  walk frame) and Hollow (pale, cyan core/eyes, haze + contact shadow) render at
  correct relative scale, clearly distinct, placeholders hidden, shadows/haze not
  obscuring the sprites, no wrong-row facing.

## Intentionally untouched

Balance/stats, collision sizes, `collision_layer/mask`, save format, persistence
IDs, `WorldState` flags, menu/objective flow, scanner/echo, interaction, camera,
and the release ZIP/export. No new gameplay content.

## Files changed

- **new** `tools/build_spriteframes.gd`
- **new** `resources/spriteframes/player_placeholder_spriteframes.tres`
- **new** `resources/spriteframes/hollow_placeholder_spriteframes.tres`
- `scenes/player/player.tscn`, `scripts/player/player.gd`
- `scenes/enemies/enemy_hollow.tscn`, `scripts/enemies/enemy_hollow.gd`
- `README.md` — corrected the character-visuals description.
- **new** `CHARACTER_ART_INTEGRATION_PASS_12_REPORT.md`

## Validation

- Godot 4.7 headless, 120 frames (post-edit): **exit 0, no errors/warnings.**
- World-load smoke: **PASS** (see §5).
- `git diff --check`: clean.
- Only source/resource/docs staged — no `builds/`, `dist/`, exe, pck, zip, temp,
  quarantine, or `export_presets.cfg`.

## Release ZIP

**Left untouched.** No export/rebuild this pass; the verified ZIP is unchanged.

## Remaining limitations

- Character sprites are **blockout placeholders**, not final painterly art.
- Facing is 4-direction (nearest axis); no diagonal frames.
- Attack/hurt/hit use short time-locks rather than `animation_finished` handoff —
  simple and safe, but not frame-perfect.
- Unsigned Windows exe; procedural placeholder audio; next zone is a hook only;
  persisted IDs tied to node names.
- A future build pass must re-export and re-verify the ZIP to ship these visuals.
