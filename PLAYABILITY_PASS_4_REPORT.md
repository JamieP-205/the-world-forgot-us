# Playability Pass 4 Report

## Safety Checkpoint

- Git was initialized at the active project root.
- Initial checkpoint commit created before edits:
  - `04d13f9 checkpoint: post content pass 3`
- No zip fallback was needed.

## Fresh-Start Route Checked

Expected Godot save paths were checked before validation and no local `savegame.json` was found, so the headless startup path represented a clean launch state.

Route reviewed against the current scenes/scripts:

1. Spawn in the wasteland near the Railhome exit.
2. Follow the road arrows to the first roadside crate.
3. Search crate/container loot and confirm pickup notices/inventory rows are driven by `LootContainer` and `InventorySystem`.
4. Follow the road to the fallen mast and scan/recover `The Last Broadcast`.
5. Explore the petrol station, kiosk, shed, lunchbox, lore props, and choice areas.
6. Fight or avoid Hollows; relay cache remains optional and guarded.
7. Return to the bright Railhome doorway.
8. Build the Radio Desk after recovering the echo and collecting materials.
9. Rest at the bedroll to heal/save.
10. Build/repair the Route Beacon when the player has spare materials, then return to the world.

No GUI/manual input playthrough was performed in this environment. The pass was validated through headless startup, scene/resource inspection, economy review, and script flow checks.

## Issues Found

- The opening objective mentioned the optional beacon too early, which could distract a fresh player before they searched the first crate.
- The scanner objective did not point strongly enough at the visible fallen mast/cyan static landmark.
- Build prompts did not show material costs until the player tried to build.
- Scene exits changed location without a short feedback notice.
- Save/load persistence is functional for global demo state, but some scene-local interactions are still not serialized.

## Fixes Made

- Tightened early HUD objective text:
  - first step now points to the cracked road and glinting roadside crate
  - scanner step now points to the fallen mast and cyan static
  - echo step now tells the player to interact with the revealed echo
  - return step now calls out the bright Railhome doorway
  - final state now says `Demo complete. Next signal detected north.`
- Opening notice now says:
  - `Follow the amber road arrows east. Search glinting crates with E.`
- Radio Desk prompt now includes its material cost.
- Route Beacon prompt now includes its material cost.
- Radio Desk success notice now uses the clearer wording `Radio Desk built.`
- Route Beacon success notice now uses the clearer wording `Roadside Beacon built.`
- Scene exits now post short travel notices:
  - `Railhome reached.`
  - `Back on the cracked road.`
- Added defensive null guards to the build prompt helpers for standalone upgrade/beacon scenes.

## Balance Findings

- Radio Desk cost remains `1 Battery, 3 Scrap`.
- Route Beacon cost remains `1 Battery, 2 Scrap`.
- Normal exploration gives enough resources for the Radio Desk without scraping every object.
- The Route Beacon can be built without blocking the Radio Desk if the player searches a normal spread of containers.
- Choice rewards are meaningful but not punishing:
  - salvage choices help build faster
  - keepsake choices add story/inventory flavor without blocking progression
- Relay cache reward (`1 Battery, 2 Scrap`) is worth the risk and remains optional.
- Hollow tuning already looked fair for this pass:
  - slow movement
  - low contact damage
  - two-hit player kill on standard Hollow health
  - visible hit flash and death fade

No resource costs or enemy numbers were changed.

## Save/Load Findings

Verified by script inspection:

- Bedroll calls `heal_full()` and `SaveManager.save_game("")`.
- Bedroll posts `Rested. Progress saved.` on success.
- `SaveManager` writes:
  - current level path
  - player position
  - player health
  - inventory
  - recovered echoes
  - built upgrades
- `SaveManager.load_game()` restores inventory, echoes, upgrades, level, player position, and health.
- Built Radio Desk and Route Beacon state persist through `BaseUpgradeSystem`.
- Inventory/resource counts persist.

Known persistence limitations:

- Loot container searched/opened state is still scene-local.
- Optional choice locks are still scene-local.
- Enemy defeated state is scene-local.
- These were documented rather than rewritten because Playability Pass 4 was scoped as polish, not a persistence-system expansion.

## Smoke Checks

Static/resource checks confirmed:

- `scenes/maps/test_map.tscn` exists.
- `scenes/base/railhome_base.tscn` exists.
- `scenes/world/route_beacon.tscn` exists.
- `resources/upgrades/route_beacon.tres` exists.
- `resources/upgrades/radio_desk.tres` exists.
- `resources/items/tin_locket.tres` exists.
- `scripts/world/choice_option.gd` exists.
- `scripts/systems/save_manager.gd` exists.
- `MemoryEcho` has `echo_data = ExtResource("5_echodata")`.
- `RouteBeacon` is placed and has `upgrade_data = ExtResource("27_beacondata")`.
- `ChoiceKiosk`, `ChoiceForecourt`, `RelayCache`, and `RelayHollow` are present.

Feature checks by inspection:

- Startup path is intact.
- Crate search path is intact.
- Inventory icon rows are still driven by `ItemData.icon`.
- Scanner/echo flow is intact.
- Combat flow is intact.
- Relay cache remains lootable and optional.
- Travel to/from Railhome is intact.
- Storage manifest still opens through `StorageBox`.
- Radio Desk build still uses `BaseUpgradeSystem`.
- Route Beacon build still uses `BaseUpgradeSystem`.
- Save/load scripts do not report errors under headless startup.

## Validation Result

- Godot 4.7 headless run for 120 frames: passed.
- `git diff --check`: no whitespace errors; Git reported CRLF normalization warnings for edited files.
- No Godot errors or warnings were printed during the final headless validation run.

## Known Limitations

- No full automated input playback exists yet, so hands-on feel still needs a human pass in the editor/player.
- Storage is still a manifest, not a transfer UI.
- Player and Hollow are still placeholder/blockout visuals.
- No real audio assets are present.
- Scene-local searched/choice/enemy state is not yet persisted.
