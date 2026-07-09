# Solo Playtest Issues — Pass 13

Triage of the user's playtest feedback. P0/P1 are fixed this pass; P2 partially;
P3 noted for later. This is a working log, not the main deliverable.

## P0 — broken / confusing core experience
1. **Fog/dust moves with the player.** `AshDrift` is a child of `Camera2D`
   (screen-locked). → Move to world-space atmosphere on each map.
2. **Memory echo is far too big.** `memory_echo.gd` tweens the ~430px core to
   absolute `scale = 2.25` (~950px). → Rescale to small multiples of a small base.
3. **Interact from weird distances.** Player interaction reach radius is 52px.
   → Tighten so prompts feel fair.
4. **"Next mission then nothing."** After Radio Desk + rest the objective implies
   more. → Make the endpoint explicit and point at optional content.

## P1 — weak gameplay loop
5. **Collected items have no use.** → Canned Food becomes a field heal (new
   `consume` key); keepsakes get a Railhome **Keepsake Shelf** payoff.
6. **Only two build actions.** → Add **Scanner Coil** and **Railhome Lantern**
   upgrades (cost Scrap/Battery, visible payoff), persisted via BaseUpgradeSystem.
7. **No navigation help.** → Add a small HUD **compass** with an objective arrow.
8. **Areas feel purposeless.** → Every area already has loot/lore/choice; the new
   upgrades + keepsake shelf + compass give the map reasons to move.

## P2 — visual / audio polish
9. **Bright placeholder blocks clash with sprites.** → Mute the rust-red
   building roofs and restyle the flat "note/scrap" lore polygons to a unified
   parchment/ash palette.
10. **Audio too minimal.** → Add a low ambient wasteland wind drone; add
    eat/keepsake/upgrade feedback sounds; tune levels.
11. **Echo effect weak.** → Cleaner reveal/recover tween at the new scale.

## P3 — future content (not this pass)
- Real painterly character/building art (placeholder sprites remain).
- A real next zone (still an ending hook by design).
- Full inventory/stash UI, deeper combat, real audio design.
