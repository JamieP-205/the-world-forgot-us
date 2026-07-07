# Asset Import Pass 1 — Report

Imported the first generated asset pack into the demo: chroma-keyed the green
screen, sliced the multi-object sheets into individual transparent sprites,
and replaced the highest-confidence placeholder visuals. No mechanics, scripts
(beyond visual type-annotations), collision shapes, or navigation were changed.

Validation: Godot 4.7 headless, 120 frames, **no errors**. A functional smoke
test confirmed loot search and echo scan/recover still work with the new
sprites (`items 0 -> 3`, `echo recovered archive=1`).

---

## 1. Folders

- **Originals preserved (untouched):** `assets/source/generated/` — all 13 sheets.
- **Processed output:** `assets/processed/<sheet>/*.png` — 81 sliced transparent sprites.
- **Repeatable tool:** `tools/chroma_extract_assets.py`
  - Soft chroma key on "greenness = G − max(R,B)" (fully transparent ≥120, opaque ≤40, soft edge between) + green **despill** so edges keep no halo.
  - Connected-component slicing (with dilation so an object's detached parts — straps, dangling handset, scrap chips — stay grouped), sorted into reading order and named per sheet.
  - Dark-background sheets (ground tiles) use a separate grid slicer.
  - Re-run any time with `python tools/chroma_extract_assets.py`.

---

## 2. Source sheets found (13) & background handling

| Sheet | Grid | Green removed | Sliced parts |
|---|---|---|---|
| `world/props/loot_containers.png` | 2×3 | yes | 6 |
| `items/item_icons_pack_01.png` | 2×5 | yes | 10 |
| `base/railhome_props.png` | 2×4 | yes | 8 |
| `world/props/petrol_station_props.png` | 2×3 | yes | 6 |
| `world/props/roadside_props.png` | 2×4 | yes | 8 |
| `scanner_memory/scanner_memory_effects.png` | ~2 rows | yes | 7 (+1 stray fragment) |
| `effects/effects_pack_01.png` | 2×5 | yes | 10 |
| `world/tiles/demo_ground_tiles.png` | 4×4 | n/a (dark bg) | 16 (grid) |
| `characters/player/player_4dir_concept.png` | 4 views | yes | 4 (reference only) |
| `characters/hollow/hollow_concept_sheet.png` | 5 poses | yes | 5 (reference only) |
| `characters/player/player_animation_plan.png` | — | not processed | planning doc, not sliceable |
| `style/style_board.png` | — | not processed | mood board, reference only |
| `ui/ui_kit_01.png` | — | not sliced this pass | UI skinning deferred (see §6) |

---

## 3. Sliced assets USED in scenes

**Loot containers** (`scenes/world/loot_container.tscn` → every crate instance:
Roadside/CarBoot/PumpLocker/Office crates):
- `loot_containers/crate_wood_closed.png` — replaces the polygon crate. Script
  still dims it on search via `modulate` (annotation retyped `Polygon2D → Node2D`,
  which also keeps the map-local polygon crates working).

**Railhome base** (`scenes/base/railhome_base.tscn`):
- `railhome_props/bedroll.png` — the rest/save bedroll (SavePoint).
- `railhome_props/storage_chest.png` — the storage crate (StorageBox).
- `railhome_props/lantern.png` — new ambient warmth decoration (+ soft glow).

**Memory echo** (`scenes/world/memory_echo.tscn`):
- `scanner_memory_effects/memory_echo_core.png` — the cyan echo core. The
  reveal/recover tweens were rescaled proportionally (via a `BASE_SCALE`
  constant) so the exact same pop/settle animation drives the larger sprite.

**World map** (`scenes/maps/test_map.tscn`) — placeholder polygons swapped for
sprites, all collision + LoreProp scripts untouched:
- `roadside_props/broken_car.png` (BrokenCar)
- `roadside_props/road_sign.png` (FadedRoadSign)
- `roadside_props/backpack.png` (AbandonedBackpack)
- `roadside_props/portable_radio.png` (BrokenRadioProp)
- `roadside_props/missing_person_poster.png` (MissingPoster)
- `petrol_station_props/warning_barrier.png` (EmergencyBoard)
- `petrol_station_props/petrol_pump.png` (PumpA, PumpB ×2)
- `petrol_station_props/vending_machine.png` (DeadVendingMachine)
- `petrol_station_props/phone_booth.png` (CrackedPublicPhone)
- `item_icons_pack_01/icon_old_photo.png` (FamilyPhotoWall)

Verified in-game via screenshots: crates, base props, car, backpack, road sign,
pumps, vending, phone all render at correct scale and read clearly against the
ashy ground.

---

## 4. Sliced & ready, NOT yet integrated (safe, deliberate)

- **`railhome_props/radio_desk.png`** — beautiful, but the Radio Desk **upgrade
  station** drives a built/unbuilt state through named polygon children
  (`PowerLight`, `SignalGlow`, `RadioBody`, `Dial`) in `base_upgrade_station.gd`.
  Swapping it would break that state animation, so it was left as-is this pass.
  *Next:* give the station an unbuilt (dim) vs built (lit) desk sprite pair, or a
  desk sprite + overlay light the script toggles.
- **Effects** (`scanner_pulse_ring`, `recovery_burst`, `signal_sparks`,
  `cyan_sparkles`, `hit_spark`, `hollow_dissolve`, `radio_waves`, glow cones,
  `amber_pillar`, etc.) — the scanner pulse, echo halo, mast sparks and Hollow
  death are currently procedural/polygon and already look good, so effects were
  left procedural to avoid regressions. Sprites are ready to drop in.
- **Item icons** (`scrap`, `battery`, `canned_food`, `childs_lunchbox`,
  `medicine`, `fuel`, `tools`, `electronics`, `compass`) — sliced and ready, but
  the HUD inventory is a **text list**; showing icons needs a small inventory-UI
  grid (TextureRects). Deferred to a UI pass. (`old_photo` is used as a world prop.)
- **Ground tiles** (16 cells) — sliced to `processed/demo_ground_tiles/`. Not
  integrated: the map ground is authored polygons with a hand-shaped road, and
  dropping a tiled ground risks the road/exit readability and navigation. Left
  for a dedicated tile pass.
- **`railhome_props/workbench_empty` / `workbench_tools` / `map_wall` /
  `base_doorway`**, `petrol_station_props/station_sign_tall` / `station_counter`,
  `roadside_props/debris_pile` / `traffic_cone` / `guardrail`,
  `loot_containers/toolbox_metal_*` / `locker_metal` / `scrap_pile` — ready for
  future base build-outs and prop variety.

---

## 5. Player & Hollow — animation limitation (documented)

The player and Hollow sheets are **eye-level concept turnarounds** (player: 4
standing views; Hollow: 5 side poses), not top-down animation atlases. Dropping a
front-facing standing figure into a top-down game that rotates a facing indicator
would *reduce* clarity (the sprite wouldn't turn with movement/aim). Per the pass
rules, the current working player/Hollow visuals were **left in place**. The
individual figures were still sliced to `processed/player_4dir_concept/` and
`processed/hollow_concept_sheet/` for reference.

*Needs regeneration:* dedicated **top-down** directional sheets — player
idle/walk/attack/scan per direction; Hollow idle/shamble/attack/hit/death.

---

## 6. Skipped this pass & why

- **UI kit (`ui_kit_01.png`)** — not sliced/integrated. The current HUD (bars +
  labels + objective tracker) is readable and functional; skinning it now risks
  the "don't let pretty art reduce clarity" rule. Deferred to a UI pass.
- **Style board / player animation plan** — reference/planning images, not game assets.
- **RadioMast, RoadsideKiosk, MaintenanceShed** — kept as polygons: the mast is
  script-driven (`test_map.gd` animates its glow/sparks) *and* the pack has no
  matching fallen-mast / kiosk-exterior / shed-exterior asset.
- **Route arrows, exit beacons, safe-zone glows** — intentional gameplay-guidance
  polygons from the earlier passes; kept.

---

## 7. Assets that need regeneration

1. Top-down player animation atlas (per-direction idle/walk/attack/scan/hurt).
2. Top-down Hollow animation atlas (idle/shamble/attack/hit/death).
3. Fallen radio-mast landmark (cold sparks + recovered warm glow states).
4. Roadside kiosk exterior and maintenance shed exterior.
5. Radio Desk in **unbuilt vs built** states (for the upgrade station).
6. Ground tiles as a genuinely seamless/tileable atlas if tiling is wanted.

---

## 8. Remaining art problems / notes

- **scanner_memory sheet:** the scattered cyan dust cluster split into two
  components during slicing (`cyan_dust` + `extra_07`). Cosmetic only; those
  effect sprites aren't used yet.
- The pack's style is a hand-painted 3/4 look, not pixel-art. It reads well at the
  current zoom (1.9) as slightly-3/4 top-down props, but the player/enemy staying
  as placeholders is the main visual gap until top-down character sheets exist.
- Chroma key is clean on all prop/icon/effect sheets (verified on a checkerboard
  contact sheet — no green halos). The bright-green electronics vial in the item
  sheet is the only element the key slightly eats; that icon isn't used yet.

---
---

# Asset Integration Pass 2 — Report

Goal was integration/readability, not new mechanics. Pass 1 state was verified
first (all folders present, tool + report present, Godot 4.7 headless 120
frames = 0 errors) before changing anything.

Validation: Godot 4.7 headless, 120 frames, **0 errors/warnings**. Smoke test
covered inventory build, crate search, echo scan/recover, Radio Desk build, and
world↔base travel — all pass.

## What was added in Pass 2

**1. Item icons in the inventory HUD.**
- Added an `icon: Texture2D` field to `ItemData` and set it on all 5 items
  (`scrap`, `battery`, `canned_food`, `child_lunchbox`, `old_photo`) from
  `assets/processed/item_icons_pack_01/`.
- Replaced the plain `InventoryLabel` with an `InventoryPanel` (header +
  `VBoxContainer`); `hud.gd` now builds one 26 px icon + "Name xN" row per item.
  `TextureRect.EXPAND_IGNORE_SIZE` keeps rows small (the source icons are ~300 px).
- Readable and compact; no inventory redesign.

**2. Radio Desk visual pass (state preserved).**
- Added `radio_desk.png` as a `DeskSprite` background layer *inside* `Visual`,
  and hid the now-redundant body polygons (`TableTop/RadioBody/Dial/Antenna` →
  `visible=false`, base `Visual` polygon alpha 0). **All script-referenced nodes
  still exist**, so `base_upgrade_station.gd`'s built/unbuilt logic is intact.
- Two small additive script hooks: dim the desk sprite when unbuilt
  (`modulate 0.5,0.55,0.62`), restore to full on build. The `SignalGlow` pulse
  was re-tinted warm amber (was teal) to match the lit desk, and the flat green
  `PowerLight` square was hidden (the sprite's own screens read as "on"). Build
  interaction, gating, and payoff notice are unchanged.

**3. Ground/detail decals.**
- New reusable tool `tools/make_ground_decals.py` feathers the opaque
  ground-tile slices into soft-edged, blend-able decals →
  `assets/processed/decals/` (8 of them).
- World (`test_map.tscn`): a `GroundDecals` node (global alpha 0.72) with 7
  decals — cracked asphalt on the road, broken concrete on the forecourt, dirt
  by the kiosk/shed, rubble by the mast/kiosk. Rendered above ground, below all
  props; no collision, navigation untouched.
- Base (`railhome_base.tscn`): a `FloorDecals` node (alpha 0.5) with floor grime
  + dirt near the entrance.

**4. Base readability.**
- Added two non-interactive props: `map_wall` mounted on the top wall, and a
  `workbench_tools` clutter table in the workshop corner. Placed clear of the
  bedroll / storage / Radio Desk / exit so those interactions stay obvious.

**5. World readability.**
- Added one landmark: the tall `station_sign_tall` on the station→mast approach
  (first relocated after it was found hidden behind the station's office/canopy
  polygons — draw order). Kept sparse to avoid clutter; the bright yellow
  keepsake-lunchbox pickup was deliberately left as-is so interactables stay
  visually distinct from background props.

## Intentionally skipped in Pass 2

- **Player / Hollow sprites** — the sliced statics are eye-level concept art;
  forcing them into a top-down game that rotates a facing indicator would reduce
  clarity. Left as placeholders. See `NEXT_ASSET_REQUESTS.md`.
- **Storage popup** — it's a transient text notice (not a panel), so icons don't
  apply cleanly; left as the readable text manifest. The always-on inventory
  panel now carries the icons.
- **Fallen mast / kiosk / shed** — still polygons (no matching art, and the mast
  is script-driven). Listed in `NEXT_ASSET_REQUESTS.md`.
- **Full ground tiling** — used feathered decals instead of retiling the map, to
  protect the hand-shaped road/exits and navigation.

## Needs regenerated art

Tracked in **`NEXT_ASSET_REQUESTS.md`**: top-down player sheet, top-down Hollow
sheet, fallen radio-mast, roadside kiosk + maintenance shed exteriors, an
optional powered-down Radio Desk sprite, and (optional) a seamless ground atlas.
