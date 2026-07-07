# Next Asset Requests

Exact art still needed to finish the demo's visual pass. Everything here is
blocked on **new generation** — the current pack can't cover it. The game
stays fully playable with placeholders until these arrive.

Delivery format for all of the below:
- **Transparent background** (real alpha, not green screen). If green screen
  is unavoidable, keep it pure `#00FF00` with a clean edge so
  `tools/chroma_extract_assets.py` can key it.
- **One object/frame per cell**, laid out on an even grid, generous spacing.
- **Consistent scale** across every frame of a sheet (same pixel height for
  the character in every pose).
- **Top-down / slight-3-quarter** framing to match the game camera — NOT
  eye-level concept turnarounds (that is why the current character sheets
  can't be used; see below).

---

## 1. Player — top-down character sheet (highest priority)

The current `player_4dir_concept.png` is a 4-view standing **turnaround** at
eye level. In a top-down game where the body rotates to face movement/aim, a
front-facing figure that never turns reads wrong, so the player is still the
placeholder capsule. Needed instead:

- **Directions:** 4-direction (down / up / left / right) minimum; 8-direction
  preferred. Right can be a mirror of left.
- **Animations per direction:**
  - idle (1–2 frames)
  - walk (4–6 frames)
  - melee swing (2–3 frames)
  - scan/raise-scanner pose (1–2 frames)
  - hurt/stagger (1 frame)
- **Scale:** character ≈ **32–40 px tall** in-game. Deliver larger (e.g. a
  128 px cell) and it will be down-scaled; keep the collision footprint near
  the current `18×22` body.
- **Read from above:** shoulders/backpack visible, head foreshortened. Keep
  the scavenger silhouette from the concept (coat, scarf, backpack).

## 2. Hollow enemy — top-down sheet (high priority)

`hollow_concept_sheet.png` is 5 eye-level side poses — same problem. Needed:

- **Directions:** 4-direction (down/up/left/right), or at least down + up +
  side (mirror for the 4th).
- **Animations per direction:**
  - idle twitch (2 frames)
  - shamble/walk (4 frames)
  - contact attack (2–3 frames)
  - hurt (1 frame)
  - death dissolve (3–4 frames) — cyan/ashy break-apart to match the existing
    memory-tech palette.
- **Scale:** match the player's height budget so the two read together.

## 3. Fallen radio-mast landmark

The mast is still authored polygons (`test_map.gd` animates its cold sparks →
warm recovered glow). Needed: a **fallen/leaning radio mast + dish** prop,
top-down, with:
- a neutral state,
- a cold-signal state (faint cyan sparks), and
- a recovered/warm state (amber glow),
OR one neutral prop plus separate spark/glow overlay sprites the script can
toggle. Transparent PNG(s).

## 4. Roadside kiosk & maintenance shed exteriors

Still polygons — the pack had no matching exterior. Needed as top-down props
with transparent backgrounds:
- **Roadside kiosk** (small shop hut, broken window).
- **Maintenance shed / bus-stop shelter** (open front, corrugated roof).

## 5. Radio Desk — built vs unbuilt pair (nice to have)

Pass 2 uses the single `radio_desk.png` and fakes the two states by dimming
the sprite (unbuilt = cold/dim, built = full + warm glow). A dedicated
**powered-down** desk sprite (dark screens, no glow) plus the existing lit one
would look cleaner than a modulate tint.

## 6. Ground tiles as a seamless atlas (optional)

`demo_ground_tiles` slices are single samples on a dark background. Pass 2
feathers a few into blend-able decals (`tools/make_ground_decals.py`), which
is enough for detail. If a fully **tiled** ground is ever wanted, deliver a
**seamless/tileable** 32 px atlas (asphalt, dirt, gravel, rubble, concrete,
metal floor, wood floor) with wang/edge variants.

---

## Reference: what already exists and is usable

Props, loot containers, item icons, base furniture, scanner/memory effects,
and UI-kit frames are all sliced under `assets/processed/` and mostly wired
in (see `ASSET_IMPORT_REPORT.md`). Only the **characters, mast, kiosk/shed**
are hard blockers on new art.
