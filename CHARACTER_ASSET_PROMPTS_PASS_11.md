# Character Asset Generation Prompts — Pass 11

Copy-paste prompts for generating the replacement top-down **player** and
**Hollow** sprites. Dimensions/layout are defined in `CHARACTER_SPRITE_SPEC.md`;
these prompts encode the same rules in generator-friendly language.

**How to use:** paste one prompt into the image generator. If the model supports
a transparent background, ask for PNG alpha. If it cannot, it will fall back to
the solid key colour named in the prompt (`#FF00FF` magenta), which
`tools/chroma_extract_assets.py` will remove. Generate large, then downscale at
import time.

Every prompt ends with the same **hard constraints** block. Do not delete it — it
is what prevents the eye-level-turnaround / green-mush / labelled-grid failures
we hit before.

---

## SHARED HARD CONSTRAINTS (already appended to each prompt below)

```
HARD CONSTRAINTS (must all be obeyed):
- Camera view: STRICT TOP-DOWN, looking straight down / slight three-quarter
  from above. This is a top-down game. Do NOT draw an eye-level or front-facing
  standing character. Do NOT draw a model-sheet turnaround.
- Background: fully TRANSPARENT if possible; otherwise a SOLID FLAT #FF00FF
  magenta fill, perfectly even, with clean crisp edges around the figure. No
  gradient, texture, ground, shadow, or scenery in the background.
- Layout: a clean uniform GRID. One pose per cell. Equal cell size. Even spacing.
  No cells overlapping. No frame borders drawn. The figure is centered in each
  cell with a little padding and is never cropped.
- Consistent scale: the character is the SAME height in every single cell.
- Absolutely NO text, letters, numbers, labels, captions, arrows, grid lines,
  colour swatches, or watermarks anywhere in the image.
- One character only per cell. No weapons props, no items, no tiles.
- Muted post-apocalyptic palette; flat even lighting; no baked drop shadow, no
  strong coloured rim light (the game tints the sprite at runtime).
- Pixel/painted sprite suitable for reading at ~40 pixels tall in-game.
```

---

## 1. Player — top-down sprite sheet (primary)

```
Top-down 2D game character sprite sheet of a lone post-apocalyptic survivor
scavenger, seen from directly above (top-down / slight three-quarter-from-above).
A small weary figure in a worn ash-grey and faded-rust long coat, a scarf, heavy
boots, and a bulky backpack whose top is visible from above. Desaturated cold
wasteland palette (grey-green, faded rust #6E5A3C, dark backpack) with one small
warm amber accent on the scarf for readability.

Arrange as a GRID: 4 rows = facing DOWN, UP, LEFT, RIGHT (top to bottom);
columns = WALK cycle frames (6 columns). Same figure, same size, seen from above,
just rotated to each facing and stepping through a walk cycle. 96x96 px per cell,
figure ~68 px tall, centered, feet near the bottom of each cell.

HARD CONSTRAINTS (must all be obeyed):
- Camera view: STRICT TOP-DOWN, looking straight down / slight three-quarter
  from above. This is a top-down game. Do NOT draw an eye-level or front-facing
  standing character. Do NOT draw a model-sheet turnaround.
- Background: fully TRANSPARENT if possible; otherwise a SOLID FLAT #FF00FF
  magenta fill, perfectly even, with clean crisp edges around the figure. No
  gradient, texture, ground, shadow, or scenery in the background.
- Layout: a clean uniform GRID. One pose per cell. Equal cell size. Even spacing.
  No cells overlapping. No frame borders drawn. The figure is centered in each
  cell with a little padding and is never cropped.
- Consistent scale: the character is the SAME height in every single cell.
- Absolutely NO text, letters, numbers, labels, captions, arrows, grid lines,
  colour swatches, or watermarks anywhere in the image.
- One character only per cell. No weapons props, no items, no tiles.
- Muted post-apocalyptic palette; flat even lighting; no baked drop shadow, no
  strong coloured rim light (the game tints the sprite at runtime).
- Pixel/painted sprite suitable for reading at ~40 pixels tall in-game.
```

*(Generate matching sheets for the other animations by swapping the "columns ="
line: `IDLE (2 columns, subtle sway)`, `ATTACK melee swing (3 columns: wind-up,
swing, recover)`, `HURT flinch (1 column)`. Keep every other line identical so
scale/style stay consistent across sheets.)*

## 2. Hollow — top-down sprite sheet (primary)

```
Top-down 2D game enemy sprite sheet of a "Hollow": a pale, forgotten humanoid,
a survivor-shaped figure drained of colour, gaunt and slightly hunched with long
limp arms that hang and reach. Seen from directly above (top-down / slight
three-quarter-from-above). Bone / cold off-white / pale grey-green skin
(#C2D6D0, #B0BEB9) with a darker hollow void at the chest and faint low-opacity
cyan-grey memory-corruption wisps (#5FA8B5). Ghostly and sad, not a monster.
Clearly different from a coated backpacked survivor: taller, thinner, no coat,
no pack, washed out.

Arrange as a GRID: 4 rows = facing DOWN, UP, LEFT, RIGHT (top to bottom);
columns = SHAMBLE walk frames (4 columns), an uneven dragging step. Same figure,
same size, seen from above, rotated to each facing. 96x96 px per cell, figure
~72 px tall, centered, feet near the bottom of each cell.

HARD CONSTRAINTS (must all be obeyed):
- Camera view: STRICT TOP-DOWN, looking straight down / slight three-quarter
  from above. This is a top-down game. Do NOT draw an eye-level or front-facing
  standing character. Do NOT draw a model-sheet turnaround.
- Background: fully TRANSPARENT if possible; otherwise a SOLID FLAT #FF00FF
  magenta fill, perfectly even, with clean crisp edges around the figure. No
  gradient, texture, ground, shadow, or scenery in the background.
- Layout: a clean uniform GRID. One pose per cell. Equal cell size. Even spacing.
  No cells overlapping. No frame borders drawn. The figure is centered in each
  cell with a little padding and is never cropped.
- Consistent scale: the character is the SAME height in every single cell.
- Absolutely NO text, letters, numbers, labels, captions, arrows, grid lines,
  colour swatches, or watermarks anywhere in the image.
- One character only per cell. No weapons props, no items, no tiles.
- NO red, no red aura, no glowing block. Muted; flat even lighting; no baked drop
  shadow, no strong coloured rim light (the game tints the sprite at runtime).
- Pixel/painted sprite suitable for reading at ~40 pixels tall in-game.
```

*(Swap the "columns =" line for the other sheets: `IDLE twitch (2 columns)`,
`ATTACK lunge/reach (3 columns)`, `HIT flinch (1 column)`. For DEATH, use the
dedicated dissolve prompt in section 7.)*

## 3. Player — single-frame fallback (if sheets fail)

```
A single top-down 2D game sprite of a lone post-apocalyptic survivor scavenger,
seen from directly above, FACING DOWN (toward the bottom of the image). Worn
ash-grey/faded-rust long coat, scarf, boots, and a bulky backpack visible from
above. One figure, centered, ~72 px tall on a 96x96 canvas. Desaturated cold
wasteland palette with a small warm amber accent.

HARD CONSTRAINTS (must all be obeyed):
- STRICT TOP-DOWN view, looking straight down. NOT eye-level, NOT a turnaround.
- Fully TRANSPARENT background, or a SOLID FLAT #FF00FF magenta with clean edges.
- Exactly ONE figure, centered, not cropped, with a little padding.
- NO text, labels, arrows, borders, swatches, or watermarks.
- Flat even lighting, no baked drop shadow, no strong coloured rim light.
```

## 4. Hollow — single-frame fallback (if sheets fail)

```
A single top-down 2D game sprite of a "Hollow": a pale, gaunt, forgotten
humanoid drained of colour, slightly hunched with long hanging arms, seen from
directly above, FACING DOWN (toward the bottom of the image). Bone / pale
grey-green skin, a dark hollow void at the chest, faint cyan-grey wisps. Ghostly
and sad, clearly not a coated survivor. One figure, centered, ~76 px tall on a
96x96 canvas.

HARD CONSTRAINTS (must all be obeyed):
- STRICT TOP-DOWN view, looking straight down. NOT eye-level, NOT a turnaround.
- Fully TRANSPARENT background, or a SOLID FLAT #FF00FF magenta with clean edges.
- Exactly ONE figure, centered, not cropped, with a little padding.
- NO red, no red aura, no glow block.
- NO text, labels, arrows, borders, swatches, or watermarks.
- Flat even lighting, no baked drop shadow, no strong coloured rim light.
```

## 5. Player + Hollow — palette reference (for your own use, NOT an in-game asset)

```
A simple flat colour palette swatch strip for two top-down game characters, on a
plain neutral grey card. Left group "survivor": ash grey-green coat, faded rust,
dark backpack brown, muted skin, small warm amber accent. Right group "hollow":
bone off-white, pale grey-green, dark hollow-core charcoal, faint cyan-grey
corruption. Just flat rectangular colour chips in two groups.
(This is a reference for the artist only — it is fine to include colours here.
Keep it to flat chips; do not draw characters.)
```

*(This one is intentionally allowed to be a plain swatch card; it is a reference,
not a shipped sprite. Do not import it into the game.)*

## 6. Optional — player attack slash effect (separate overlay)

```
A small top-down 2D melee slash / swipe arc effect for a game, as a short sheet:
1 row x 4 columns showing an arc sweep appearing and fading. Pale warm off-white
with a faint motion smear, semi-transparent. Seen from above, meant to overlay in
front of a character. 64x64 px per cell, arc centered.

HARD CONSTRAINTS:
- TRANSPARENT background, or SOLID FLAT #FF00FF magenta, clean edges.
- Uniform grid, one arc per cell, even spacing, not cropped.
- NO character, NO weapon, NO text/labels/borders/watermarks.
- Just the glowing arc effect.
```

## 7. Optional — Hollow death dissolve effect

```
A top-down 2D "dissolve into ash and cyan light" death sequence for a pale
humanoid enemy, as a single row: 1 row x 5 columns, left to right, going from an
intact pale figure (frame 1) breaking apart into drifting ash flecks and faint
cyan memory sparks and nearly gone (frame 5). Seen from directly above, figure
facing down. 96x96 px per cell, centered.

HARD CONSTRAINTS (must all be obeyed):
- STRICT TOP-DOWN view. NOT eye-level.
- TRANSPARENT background, or SOLID FLAT #FF00FF magenta, clean even fill.
- Uniform grid, one frame per cell, even spacing, figure not cropped.
- Cyan/ashy palette, NO red.
- NO text, labels, arrows, borders, swatches, or watermarks.
- Flat lighting; the break-apart is shape-based, colour is tinted in-engine.
```

---

## After generation

1. Save raw outputs to `assets/source/generated/characters/{player,hollow}/`.
2. If a magenta/green key was used, run `tools/chroma_extract_assets.py` to make
   real alpha; save keyed results to `assets/processed/{player_topdown,hollow_topdown}/`.
3. Sanity-check against the acceptance checklist in `CHARACTER_SPRITE_SPEC.md`.
4. Then follow `CHARACTER_ART_INTEGRATION_CHECKLIST.md` — **do not** wire art in
   until a sheet passes the checklist.
