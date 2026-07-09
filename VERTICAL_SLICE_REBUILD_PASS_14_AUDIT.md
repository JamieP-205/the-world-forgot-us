# Vertical Slice Rebuild Pass 14 Audit

This audit is based on the actual source files, not prior reports.

## Files inspected

- `scenes/maps/test_map.tscn`
- `scenes/base/railhome_base.tscn`
- `scenes/player/player.tscn`
- `scenes/enemies/enemy_hollow.tscn`
- `scripts/ui/hud.gd`
- `scripts/ui/compass.gd`
- `scripts/world/memory_echo.gd`
- `scripts/systems/audio_manager.gd`
- `assets/processed/`

## Visual Inventory

Sprites currently used:

- Player and Hollow animated placeholder sprite sheets from `assets/processed/player_topdown/` and `assets/processed/hollow_topdown/`.
- Loot crates/toolbox base visuals through `scenes/world/loot_container.tscn` using `assets/processed/loot_containers/`.
- Roadside props: broken car, road sign, backpack, portable radio, missing poster.
- Petrol station props: petrol pump, warning barrier, vending machine, phone booth, station sign.
- Railhome props: bedroll, storage chest, lantern, wall map, workbench, radio desk.
- Scanner/memory sprites: memory echo core, pulse/effect sheets exist in `assets/processed/scanner_memory_effects/`.
- Ground decals: asphalt, concrete, dirt, gravel, metal, wood, rubble textures.

Polygons currently used:

- Whole map base ground, road, road lines, dunes, Railhome exit glow, north signal, petrol station floor/office/roof/canopy, kiosk, shed, rubble, mast, several lore props, lunchbox, choice items, scanner pulse, echo halo, player fallback, Hollow fallback/haze/spark, base floor/walls/overlays/upgrade benches/shelf.

## Biggest Visual Clashes

- `test_map.tscn` still relies on large flat Polygon2D blocks for the road, station, kiosk, shed, dunes, mast, and many small props. These sit next to painted/generated sprites and make the scene read like a debug map.
- Old choice/lore polygons use brighter paper/yellow/metal colors that pull attention away from the actual route.
- Player/Hollow animated sprites are cleaner and brighter than the ash/rust/cyan world, so they read as imported placeholders rather than inhabitants.
- Lighting is mostly translucent polygons, but it is not organized by mood: the world is not cold enough, the base is not clearly safe enough, and the echo moment does not dominate the scene.

## Map Purpose Audit

Areas with gameplay purpose:

- Railhome/start: return/save/build hub.
- Road approach: currently guides east and has first supplies.
- Petrol station: loot, lore, first Hollow risk.
- Kiosk/shed: loot and optional keepsake/material decisions.
- Fallen mast: main memory echo.
- Relay cache: optional combat/cache reward.

Areas mostly decorative or confusing:

- Wide north/south empty dunes and far edges.
- Multiple lore props around the same station cluster that do not change choices or route decisions.
- Two separate either/or choice nodes plus extra notes; they create noise before the core loop is strong.
- Side cache and relay cache both act like generic extra loot, so neither feels like a clear reward.
- Route beacon adds another optional build but competes with the more useful Scanner Coil / Signal Lantern.

## Item Use Audit

Useful items:

- `canned_food`: heals with F, but the HUD/objective flow does not make this obvious enough.
- `scrap` and `battery`: build Radio Desk, Scanner Coil, Signal Lantern, Route Beacon.
- `child_lunchbox`, `tin_locket`, `old_photo`: recognized by Memory Shelf, but the payoff is easy to miss and too many keepsake choices dilute it.

Confusing items/systems:

- Loot is too generous and scattered, so the player can finish without understanding why anything mattered.
- Scanner Coil is useful but optional; the main echo can be recovered without it, so it reads as extra clutter.
- Route Beacon is another optional material sink but is weaker than the required demo path.
- Choice caches are interesting on paper but currently add another system before the core loop has enough clarity.

## Compass Audit

The compass is visible, but it feels broken for three reasons:

- It points at named scene nodes selected by broad state, not a tight route. Early it can point straight to `MemoryEcho`, skipping the clearer road/supply path.
- Its target logic does not account for whether the player has enough material for the Scanner Coil or Radio Desk. The arrow can therefore point to the wrong next action.
- `compass.gd` draws from `size.x` only and has no minimum/defensive radius handling, so any layout mismatch can produce a bad or unclear arrow.

Decision: fix the compass, but simplify it into a stable arrow to the current objective node and make HUD objective text match the same state machine.

## Cuts / Simplifications Needed

- Cut or hide duplicate lore props that do not support the route.
- Cut the two either/or choice clusters for this slice; keep keepsake payoff through the lunchbox and echo photograph.
- Remove the weak Route Beacon from the visible loop for now; Scanner Coil and Signal Lantern are enough.
- Collapse the map into a compact road/station/mast/cache loop.
- Gate the echo behind Scanner Coil so scavenged materials have a clear first purpose.
- Make optional relay cache the clear combat reward, not just another random crate.
- Restyle all remaining polygons into one ash/rust/cyan/amber palette with small detail shapes/decals so placeholders look intentional.
