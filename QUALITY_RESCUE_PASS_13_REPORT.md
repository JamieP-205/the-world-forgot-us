# Quality Rescue Pass 13 Report — Visual Cohesion + Real Usefulness

The last build did not meet the bar: it felt empty, placeholder, and technically
working rather than playable. This pass fixes the player-facing demo — the fog
bug, the giant echo, item uselessness, missing navigation, and the "next mission
then nothing" ending — without new zones, new architecture, or a rebuilt ZIP.

Full triage in `SOLO_PLAYTEST_ISSUES_PASS_13.md`.

## User complaints addressed

| Complaint | Fix |
| --- | --- |
| Fog/dust moves with the player | `AshDrift` was a child of `Camera2D`. Removed; added world-space **Atmosphere** nodes to the map and base so the ash drifts in the world and the camera pans over it. |
| Echo far too big, bad effect | `memory_echo.gd` tweened a ~430px sprite to absolute `scale 2.25` (~950px). Now scales in small multiples of a `0.13` base (revealed ~55px) with a cleaner reveal pop + gentle idle glow. |
| Interact from weird distances | Player interaction reach tightened `52 → 44` px. |
| Items collected but nothing to do with them | Canned Food now **heals in the field** (F); keepsakes get a Railhome **Memory Shelf** payoff; Scrap/Battery feed two new upgrades. |
| After Radio Desk, nothing else | Endpoint objective text now says the demo endpoint is reached, the north signal is a **hook only (not playable)**, and lists optional things to do. |
| No navigation help / wanted a compass | Added a **HUD compass** (N/E/S/W ring + amber arrow to the current objective). |
| Bright placeholder blocks clash with sprites | Muted the rust-red petrol-station / kiosk roofs and canopy to darker, integrated tones. |
| Audio too minimal | Added a low continuous **ambient wasteland wind**, `eat`/`keepsake` feedback sounds, and raised the master level (`-13 → -9 dB`). |
| Player/Hollow visibility | Confirmed the Pass 12 `AnimatedSprite2D` player and Hollow render, animate, and are distinct; old polygons stay hidden as `PlaceholderVisual`. No change needed. |

## Item uses / upgrades added

- **Canned Food → field heal.** New `consume` input (F); `player.gd` eats one tin
  to heal `+45` with a notice + sound. A real reason to hoard food before a Hollow.
- **Scanner Coil** (1 Battery + 2 Scrap) — `scanner_coil.tres` + a Railhome bench.
  `scanner_component.gd` applies it immediately: pulse radius ×1.35, recharge ×1.5.
- **Signal Lantern** (1 Battery + 2 Scrap) — `base_lantern.tres` + a Railhome
  bench. Reveals a warm overlay so the base visibly brightens.
- **Memory Shelf** — `keepsake_shelf.gd`: recognises the child's lunchbox / tin
  locket / folded photo you carry home, warms the base the first time (persisted
  via `WorldState`), never consumes them.
- Existing Radio Desk and Route Beacon still consume Scrap/Battery as before.
- All new upgrades show their cost in the prompt and persist via `BaseUpgradeSystem`.

## Compass

- `scripts/ui/compass.gd` (Control) draws a fixed N/E/S/W ring plus an amber arrow.
- `hud.gd` feeds it `(target - player)` each frame; target is chosen by objective
  stage and found by name in the live level (`MemoryEcho` → `BaseDoor` /
  `RadioDeskStation` → `Bedroll` → `NorthSignal`, with base-side equivalents).
  `main.gd` gained a `get_current_level()` accessor for this. No minimap, no clutter.

## Visual cohesion fixes

- Removed the screen-locked fog; ash is now genuine world atmosphere (subtler in
  the base).
- Echo rescaled to read as a small cyan shard.
- Muted `OfficeRoof`, `Canopy`, and `KioskRoof` reds so buildings look styled, not
  like debug blocks, against the ashy ground.
- New Railhome props (coil bench, lantern, shelf, warm overlay) use the
  ash/rust/cyan/amber palette.

## Collision / interaction fixes

- Player interaction reach `52 → 44` px for fairer prompts (no acting from far
  away). Building/prop collisions already match their visuals and were left intact;
  no oversized invisible boxes were found blocking the player.

## Audio / effect fixes

- Continuous low ambient wind (procedural, `-25 dB`) so the world isn't silent.
- New `eat` and `keepsake` cues; master trim raised to `-9 dB` so feedback reads.
- Cleaner echo reveal (pop → settle) and a gentle looping halo pulse.
- Ambient is skipped under `--headless` (no audio device), keeping validation
  deterministic; the windowed game plays it normally.

## Files changed

- **Scenes:** `scenes/player/player.tscn` (fog node removed, reach 44),
  `scenes/maps/test_map.tscn` (world Atmosphere, muted roofs),
  `scenes/base/railhome_base.tscn` (Atmosphere, Scanner Coil bench, Signal
  Lantern, Memory Shelf, warm overlay), `scenes/ui/hud.tscn` (compass).
- **Scripts:** `scripts/world/memory_echo.gd`, `scripts/ui/hud.gd`,
  `scripts/ui/compass.gd` (new), `scripts/main.gd`, `scripts/player/player.gd`,
  `scripts/scanner/scanner_component.gd`, `scripts/systems/audio_manager.gd`,
  `scripts/base/base_upgrade_bench.gd` (new), `scripts/base/keepsake_shelf.gd` (new).
- **Resources:** `resources/upgrades/scanner_coil.tres`,
  `resources/upgrades/base_lantern.tres` (new).
- **Config:** `project.godot` (new `consume` input = F).
- **Docs:** `README.md`, `SOLO_PLAYTEST_ISSUES_PASS_13.md`, this report.

## Validation

- Godot 4.7 headless, 120 frames: **exit 0, no errors/warnings** (5/5 runs clean).
- **Gameplay smoke** (temp harness, removed): world Atmosphere present + no
  AshDrift under the camera; echo scale `0.130`; food heals and is consumed;
  Scanner Coil + Signal Lantern build; warm overlay reveals; Memory Shelf records
  its visit; HUD compass present — **SMOKE13_RESULT: PASS**.
- **In-engine screenshot** (temp, removed): small cyan echo, compass rendered,
  muted building tones, subtle ash — reads as a coherent scene.
- `git diff --check`: clean.
- Core flow preserved: menu, New Game, movement, sprite animation, scanner/echo,
  combat, Hollow chase/hit/death, Radio Desk build, rest/save, persistence — all
  unchanged in behaviour.

## Release ZIP

**Left untouched** — no export/rebuild this pass (per instructions). The current
`dist/TheWorldForgotUs_Demo_Windows.zip` predates these fixes; a later build pass
must re-export and re-verify to ship them.

## Remaining limitations

- Character/building art is still placeholder blockout/sprites, not final painterly
  art (P3).
- The "next zone" remains an ending hook by design; no new area loads.
- Combat and storage are still intentionally minimal.
- Some scattered flat "note/scrap" lore polygons remain (subdued, readable) since
  there's no matching art.
- Teardown-only note: the procedural ambient is intentionally not started under
  `--headless`; the windowed game is unaffected.
