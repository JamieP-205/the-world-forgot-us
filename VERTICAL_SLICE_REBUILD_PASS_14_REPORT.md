# Vertical Slice Rebuild Pass 14 Report

## Goal

Rework the existing demo source into a smaller, clearer, more intentional 5-8 minute vertical slice. This pass did not export, package, or zip a build.

## What was cut / simplified

- Rebuilt `scenes/maps/test_map.tscn` from a wide asset scatter into one compact route.
- Removed the visible Route Beacon from the current map loop; Scanner Coil and Signal Lantern are enough upgrade focus for this slice.
- Removed the two either/or choice clusters from the visible map; they added decision noise before the core loop was strong.
- Removed duplicate/random lore clutter such as extra notes and disconnected choice props.
- Removed generic extra crates such as office/toolbox/side-cache scatter. The remaining loot now supports the loop directly.
- Kept one optional guarded relay cache as the clear combat/reward side objective.

## Visual style unification

Temporary style chosen for this build:

- dark ash ground
- rust-brown structures
- muted amber safe-zone light
- cyan memory/scanner tech
- low saturation
- no bright debug red/blue/green blocks

Applied to:

- World ground, road, road shoulders, and station/kiosk/shed/mast polygons.
- Petrol station blockout surfaces, with panel lines, canopy stripe, struts, oil stain, and decal support so the polygons read as intentional placeholder structures.
- Railhome floor/walls/runner/safe glows/upgrade props, warmer and less cold.
- Player and Hollow animated placeholder sprites via tint/veil polygons while keeping the animations and collisions unchanged.
- Main menu footer updated so it no longer claims there is no audio.

## Map loop changes

The route is now:

1. Railhome/start.
2. Amber road guidance and first supply crate.
3. Broken car / petrol station / kiosk / shed material loop.
4. Fallen mast signal check.
5. Return to Railhome to build Scanner Coil.
6. Return to mast, scan again, recover The Last Broadcast.
7. Return to Railhome, build Radio Desk.
8. Use Memory Shelf if a keepsake was carried home.
9. Rest/save.
10. North signal ending hook.

Each remaining area has one job:

- road: guidance and first supplies
- petrol station: main salvage and first danger
- kiosk/shed: food, battery/scrap, lunchbox keepsake
- fallen mast: core memory moment
- relay cache: optional combat reward
- Railhome: build/save/keepsake payoff/end

## Compass

Fixed, not removed.

- `scripts/ui/compass.gd` now draws defensively using the actual control size and a stable radius.
- `scripts/ui/hud.gd` now targets the rebuilt loop state instead of broad old state.
- Early route targets first supplies/materials, then the Railhome Scanner Coil, then the mast echo, then base objectives, then north signal.
- The compass remains a simple objective arrow, not a minimap.

## Gameplay loop changes

The demo should now last longer naturally because the echo is gated by a purposeful step rather than padding distance.

- First supplies teach search and food.
- The mast can be found early, but scanning it before the Scanner Coil gives a clear "signal too weak" notice.
- Battery and scrap from the compact route are needed for Scanner Coil.
- Scanner Coil becomes the first meaningful use of materials and unlocks the echo reveal.
- The recovered echo then enables the Radio Desk path.
- Food healing remains obvious through opening/objective text and the vending-machine note.
- The guarded relay cache is now the main optional combat reward and can fund optional base upgrades.
- Keepsakes retain payoff through the Memory Shelf without the old noisy either/or choice clusters.

## Echo / effects

- `scripts/world/memory_echo.gd` now supports an optional required upgrade gate.
- The mast echo uses `required_upgrade_id = &"scanner_coil"`.
- Pre-coil scan gives a weak-signal cue, small blocked pulse, notice, and camera nudge.
- Post-coil reveal has stronger timing, clearer objective transition, and more focused cyan/warm recovery colors.

## Music / audio

- `scripts/systems/audio_manager.gd` now includes a quiet procedural drone/music bed in addition to wind.
- Mix changes by level: colder outside, quieter/warmer in the Railhome.
- Added `weak_signal` cue for the gated mast scan.
- Strengthened scan, echo reveal/recover, build, Hollow death, rest, ending, eat, and keepsake cues without adding audio assets.
- Continuous audio remains skipped under headless runs.

## Lighting / mood

- `scripts/main.gd` now applies level-aware `CanvasModulate` tint: cold ash outside, warm Railhome inside.
- World map uses amber safe glows and cyan mast/north signal glows more deliberately.
- Railhome safe lights and Signal Lantern/Memory Shelf visuals are warmer and more cohesive.

## Validation

- Godot 4.7 headless, 120 frames: exit code 0, no errors/warnings printed.
- Targeted temporary smoke harness: `PASS14_SMOKE_RESULT: PASS`, exit code 0, no leak warning after explicit cleanup.
- Smoke covered: main menu load, New Game clean state, player movement, attack area presence, compass visible/aimable, Scanner Coil echo gate, echo reveal/recovery, food heal/consume, Radio Desk build, Memory Shelf payoff, Hollow damage/death persistence, save path.
- `git diff --check`: exit code 0.
- Temporary smoke script removed after validation.

## ZIP / packaging

- ZIP was left untouched by instruction.
- No export was run.
- No files under `builds/` or `dist/` were modified by this pass.
- README now explicitly says the existing ZIP is still the outdated Pass 13.1 package and does not include Pass 14.

## Remaining limitations

- Player and Hollow are still placeholder animated sprites, only visually toned to fit better.
- Kiosk, shed, mast, road, and building pieces are still stylized blockout polygons where final art is missing.
- Music/audio is procedural placeholder only, not final composition or final sound design.
- Combat remains simple melee vs. basic Hollow chase/contact damage.
- Storage remains a manifest, not a stash-transfer UI.
- The north signal remains an ending hook; no new zone loads.
- Persisted IDs remain tied to node names, so future renames still need migration care.
