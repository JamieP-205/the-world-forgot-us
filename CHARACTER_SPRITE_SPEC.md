# Character Sprite Specification (Player + Hollow)

Strict target for replacing the placeholder `Polygon2D` player and Hollow with
real top-down sprite sheets. This is the single source of truth for
dimensions/layout; the generation prompts (`CHARACTER_ASSET_PROMPTS_PASS_11.md`)
and the integration steps (`CHARACTER_ART_INTEGRATION_CHECKLIST.md`) both defer
to the numbers here.

> Nothing here is integrated yet. This pass only specifies. Gameplay, scenes,
> the build, and the verified ZIP are unchanged.

---

## 0. Current in-engine character setup (measured from the scenes/scripts)

**Camera:** top-down, centered on player, `zoom = 1.9`, smoothing on. A 32 px
source sprite therefore appears ~61 px on screen; a 40 px sprite ~76 px. Design
silhouettes to read at **32–40 px tall**.

**Palette / mood:** cold ashy grey-green wasteland, rust/brown structures, warm
amber safety lights, cyan memory tech (see `ART_SPEC.md`).

### Player (`scenes/player/player.tscn` + `scripts/player/player.gd`)
- Root `CharacterBody2D`, origin at the **body centre (0,0)**.
- Body collision: `RectangleShape2D` **18 × 22 px**, centred on origin. **Must not
  change.**
- Current drawn figure spans roughly y −16 (head top) → +17 (feet/shadow),
  ~33 px tall. Coat/backpack/head are the recognisable silhouette.
- **Facing:** `facing` is a continuous `Vector2` from `Input.get_vector(...)`. A
  child `FacingIndicator` (amber arrow) is rotated every frame via
  `_facing_indicator.rotation = facing.angle()`.
- **Attack:** `SwingVisual` polygon + `AttackArea` are offset `facing * 24 px`
  and shown for 0.12 s (`SwingTimer`).
- **Hurt:** `_visual.modulate` flashes red then tweens back over 0.3 s — applied
  to the node named **`Visual`**.
- **Script-referenced nodes that must keep their names/types-compat:**
  `Visual` (any CanvasItem — modulate target), `FacingIndicator` (rotated),
  `Shadow`, `SwingVisual`, `SwingTimer`, `AttackArea`, `InteractionArea`,
  `ScannerComponent`, `Camera2D`, `HealthComponent`.

### Hollow (`scenes/enemies/enemy_hollow.tscn` + `scripts/enemies/enemy_hollow.gd`)
- Root `CharacterBody2D`, origin at the **body centre (0,0)**.
- Body collision: `RectangleShape2D` **22 × 30 px**, centred on origin. **Must not
  change.**
- Current drawn figure spans roughly y −18 (head) → +16 (feet); pale humanoid.
- Decor nodes owned by the scene/script: `ContactShadow` (grounding),
  `ForgottenHaze` (cool halo, script runs a slow shimmer tween on it), `HitSpark`
  (flash burst).
- **Hurt:** whole-node `modulate` flashes reddish + `HitSpark` for ~0.25 s.
- **Death:** whole-node `modulate` tweens to cyan **alpha 0** over 0.45 s, then
  `queue_free()`; `HitSpark` scales/fades. Persistence marks it defeated so it
  never respawns.
- **Script-referenced nodes that must keep their names:** `HealthComponent`,
  `HitSpark`, `CollisionShape2D`, `ForgottenHaze`. (The `Visual` block and its
  children are *not* script-referenced and can be replaced wholesale.)

### What the future sheets must support
- 4 facing directions (down/up/left/right) resolvable from a continuous vector.
- Idle + walk at minimum; attack and hurt strongly wanted; Hollow also needs a
  death/disperse sequence.
- Whole-sprite `modulate` tints (red hurt flash, cyan death fade) must still look
  right — so **do not bake heavy coloured lighting** into the frames; keep them
  fairly neutral so a modulate multiply reads cleanly.
- **No baked drop shadow** in the frames — the scenes already draw their own
  `Shadow` / `ContactShadow`. (A faint soft contact oval is tolerable but the
  separate node is preferred; see prompts.)
- Consistent scale across every frame and every animation of a character.

---

## 1. Shared delivery rules (both characters)

- **Transparent background** (real alpha PNG) strongly preferred. If the
  generator cannot output alpha, use a **flat pure key colour** — magenta
  `#FF00FF` **or** pure green `#00FF00` — as a solid, even fill with a clean edge,
  and it will be keyed by `tools/chroma_extract_assets.py`. Never a textured or
  gradient background.
- **View:** true **top-down or slight three-quarter top-down** (camera looking
  down at the character). Shoulders/backpack visible, head foreshortened. **NOT**
  an eye-level standing turnaround (that is exactly why
  `player_4dir_concept` / `hollow_concept_sheet` are unusable).
- **Grid:** one frame per cell, uniform cell size, even spacing, no overlap, no
  bleed between cells. Figure centred in each cell.
- **Consistent scale:** the character occupies the **same pixel height in every
  cell** of every sheet for that character.
- **No text, labels, numbers, arrows, frame borders, or watermarks** anywhere on
  the image.
- **No cropping:** the whole figure (including raised arm on attack) fits inside
  its cell with a few px of padding.
- One character per cell; no props, no ground, no scenery.

**Layout convention (both):** one PNG **per animation**, laid out as a grid where
**rows = directions** in this fixed order top→bottom — **down, up, left, right** —
and **columns = frames** left→right. `right` may be a horizontal mirror of `left`
(you can omit the right row and mirror at import time; state which you did).
Death is direction-agnostic (single row).

---

## 2. Player sprite specification

- **Subject:** a small survivor/scavenger seen from above — worn ash/rust **long
  coat**, **scarf**, **backpack** hump visible from the top, boots. Muted, weary,
  not heroic. Keep the silhouette readable at 32–40 px.
- **Palette:** desaturated coat (grey-green / faded rust `#6E5A3C`, `#3B4A44`),
  warm skin/scarf accent, dark backpack. One small warm accent (amber patch or
  scarf) helps facing readability. Avoid bright saturated colours.
- **Cell size:** **96 × 96 px** source (figure ~64–72 px tall inside the cell,
  centred, feet ~70% down). Delivered large for clean downscaling to ~40 px
  in-game.
- **Directions:** down, up, left, right (right may be mirrored from left).
- **Animations & frame counts (one PNG each):**

  | File (animation) | Rows × Cols | Frames/dir | Notes |
  | --- | --- | --- | --- |
  | `player_idle`  | 4 × 2 | 2 | subtle breathing/sway |
  | `player_walk`  | 4 × 6 | 6 | full step cycle, contact + passing frames |
  | `player_attack`| 4 × 3 | 3 | wind-up → swing → recover; melee arc reads in the swing frame |
  | `player_hurt`  | 4 × 1 | 1 | optional; recoil/flinch pose |

- **Pivot/origin:** the cell **centre** maps to the Godot node origin (body
  centre). Draw the figure so its **ground-contact point (feet)** sits near the
  bottom of the central 18 × 22 footprint — i.e. feet roughly at cell-y ≈ 62/96.
  Keep horizontal centre of mass on the cell centre-line.
- **Neutral lighting:** even, slightly cool top light. No baked coloured rim, no
  baked shadow (engine draws `Shadow`).

## 3. Hollow sprite specification

- **Subject:** a **pale, forgotten humanoid** — a survivor-shaped figure drained
  of colour, gaunt, slightly hunched, arms hanging/reaching. Reads as a ghostly
  "the world forgot this person," **not** a monster, **not** a block. Clearly
  distinct from the player: taller/thinner, no coat/backpack, washed-out.
- **Palette:** cold off-white / bone / pale grey-green (`#C2D6D0`, `#B0BEB9`),
  darker hollow core at the chest, faint **cyan/grey memory-corruption** wisps
  allowed (`#5FA8B5` low-opacity). **No red, no red aura, no glowing block.**
  Must stay readable against dark ash ground.
- **Cell size:** **96 × 96 px** source (figure ~68–76 px tall — a touch taller
  than the player so the two read together at their collision sizes 18×22 vs
  22×30).
- **Directions:** down, up, left, right (right may be mirrored from left).
- **Animations & frame counts (one PNG each):**

  | File (animation) | Rows × Cols | Frames/dir | Notes |
  | --- | --- | --- | --- |
  | `hollow_idle`   | 4 × 2 | 2 | slow twitch/waver |
  | `hollow_walk`   | 4 × 4 | 4 | uneven shamble, dragging step |
  | `hollow_attack` | 4 × 3 | 3 | lunge/reach-and-grab |
  | `hollow_hit`    | 4 × 1 | 1 | flinch (whole-node red modulate is added in-engine) |
  | `hollow_death`  | 1 × 5 | 5 | **direction-agnostic** cyan/ashy break-apart dissolve, front-facing; frame 1 intact → frame 5 nearly gone |

- **Pivot/origin:** cell centre = node origin (body centre, 22 × 30 footprint).
  Feet near cell-y ≈ 60/96. Centre of mass on the centre-line.
- **Neutral-ish lighting:** keep frames pale and even so the in-engine cyan death
  `modulate` and the separate `ForgottenHaze`/`HitSpark` still read. Do **not**
  bake the haze or the death dissolve glow as coloured lighting that would fight
  a multiply tint — the dissolve *shapes* (breaking silhouette) are fine, the
  colour will be tinted by the engine.

---

## 4. Naming convention (files)

- **Raw generated sheets:** `assets/source/generated/characters/player/player_<anim>_sheet.png`
  and `assets/source/generated/characters/hollow/hollow_<anim>_sheet.png`.
- **Processed / keyed / ready-to-slice:** `assets/processed/player_topdown/player_<anim>.png`
  and `assets/processed/hollow_topdown/hollow_<anim>.png`.
- **Godot SpriteFrames animation names:** `<anim>_<dir>` — e.g. `idle_down`,
  `walk_left`, `attack_up`, `hurt_right`, and `death` (no direction) for the
  Hollow. Use these exact names so an integration script can wire them
  predictably.

## 5. Acceptance checklist (reject a sheet if any fail)

- [ ] Top-down / 3-quarter-top view (NOT eye-level turnaround).
- [ ] Transparent alpha, or a clean solid `#FF00FF`/`#00FF00` key.
- [ ] Uniform cell size; one frame per cell; even grid; no bleed.
- [ ] Same figure height in every cell of every sheet for that character.
- [ ] Rows = down/up/left/right (or documented mirror); columns = frames.
- [ ] No text/labels/arrows/borders/watermarks.
- [ ] Whole figure inside each cell (attack arm not cropped).
- [ ] Player reads as coated scavenger w/ backpack; Hollow reads as pale forgotten
      humanoid, no red.
- [ ] No baked drop shadow; neutral enough lighting to survive a modulate tint.
