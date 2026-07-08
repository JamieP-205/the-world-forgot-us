# The World Forgot Us

A small Godot 4 top-down survival prototype. This is not the full game. It is a 3-5 minute playable demo loop meant to make the core idea readable: search the wasteland, recover a memory echo, return to the Railhome, build the Radio Desk, and rest/save.

## What works now

- Player movement, facing, melee attack, health, death, and wake-at-base respawn.
- A hand-built wasteland test map with an abandoned road, ruined petrol station forecourt, broken roadside kiosk, half-collapsed maintenance shed, broken car, two Hollow enemies, a memory echo landmark, and a clear exit back to base.
- Nine searchable/pickup objects, including normal supplies and the optional `Child's Lunchbox` keepsake.
- Eight short lore props: road sign, backpack, broken radio, missing-person poster, family photo, warning board, vending machine, and public phone.
- Content Pass 3 adds a buildable Roadside Beacon, extra lore notes, two small either/or salvage-vs-keepsake choices, a guarded relay cache, the `Tin Locket` keepsake, and optional HUD objectives.
- Loot containers grant real inventory items and show pickup notices.
- The Mnemoscope scanner sends a visible pulse, spends/recharges scanner energy, and reveals the hidden echo.
- The Last Broadcast has a stronger reveal pulse, a multi-line recovery notice, and changes the fallen mast area after recovery.
- Returning to the Railhome works through scene exits.
- The Radio Desk can be built if you have recovered The Last Broadcast and have the required materials. When built, it lights up and plays a short placeholder signal message.
- The bedroll heals the player and saves progress with: `Rested. Progress saved.`
- The storage crate shows a working storage manifest based on your current supplies.
- The HUD shows health, scanner energy, an inventory list **with item icons**, recovered echo count, interaction prompts, notices, and objective progress.
- Interactables highlight when you are close enough to use them.
- Atmosphere pass: global ashy tint, drifting ash/dust, warmer Railhome safety glow, cyan scanner/echo glow, flickering mast signal, loot glints, Hollow hit sparks/death fade, and subtle camera shake on scanner reveal, echo recovery, and Hollow death.
- Imported art (Asset Passes 1 & 2): real sprites for loot crates, base furniture (bedroll, storage, lantern, wall map, workbench), the lit Radio Desk, the memory-echo core, world props (car, pumps, vending, phone, signs, backpack, radio, poster), inventory item icons, plus feathered ground decals and a station-sign landmark. See `ASSET_IMPORT_REPORT.md`.
- `ART_SPEC.md` documents the art requirements; `NEXT_ASSET_REQUESTS.md` lists the exact sprites still needed (top-down player/Hollow sheets, fallen mast, kiosk/shed).

## Still placeholder

- The **player and Hollow** are still Polygon2D blockout art — the generated character sheets are eye-level concept turnarounds, not top-down frames (see `NEXT_ASSET_REQUESTS.md`). The **fallen mast, roadside kiosk, and maintenance shed** are also still blockout (no matching art yet). Most other props/items now use imported sprites.
- Combat is a basic melee hitbox and simple Hollow chase/contact damage.
- Storage is a manifest, not a full stash-transfer UI.
- The Radio Desk build is a payoff milestone only. It hints at the next signal but does not unlock a new quest yet.
- Optional choice locks are lightweight scene interactions. They prevent taking both options during the current map visit, but the choice state is not yet serialized as a dedicated save record.
- Audio is still represented by text/visual feedback and TODO-style placeholder comments. There are no real sound assets yet.
- There are no NPCs, factions, procedural generation, advanced crafting, or final UI styling.

## Controls

| Input | Action |
| --- | --- |
| W A S D | Move |
| E | Interact |
| J or Left-click | Melee attack |
| Q or Right-click | Scanner pulse |
| Esc | Pause / resume |

## Demo walkthrough

1. Start in the wasteland at the Railhome door. An opening line sets the tone (you are alone; the road east matters) and amber arrows point the way. Search supplies and follow the signal.
2. Follow the road east. Search the roadside crate, car boot, pump locker, office crate, kiosk drawer, shed locker, repair toolbox, and optional side cache as you explore.
3. Read a few lore props if you want more atmosphere: the missing-person poster, warning board, dead vending machine, cracked phone, and broken radio are all interactable.
4. Pick up the optional Child's Lunchbox near the petrol station forecourt. It is keepsake loot, not crafting material.
5. Optional: power the Roadside Beacon near the broken car if you have spare battery/scrap. It lights the route home.
6. Optional: inspect the extra lore props (`ChildDrawing`, `EvacNotice`, `RouteTag`, `HollowChalk`, `MastNote`) and the `CarvedInitials` in the Railhome.
7. Optional: resolve the two small choices: kiosk salvage or `Tin Locket`, and forecourt wiring or a folded photo.
8. Optional: clear or avoid the Hollow guarding the relay cache in the northwest and loot it.
9. Fight or avoid the pale Hollow enemies on the main route.
10. Go to the fallen radio mast north of the petrol station and press Q to scan.
11. When the echo appears, walk to it and press E to recover The Last Broadcast. The echo pulses, the camera nudges, and the mast area warms after recovery.
12. Return west to the Railhome exit and press E.
13. In the Railhome, use the Radio Desk station to build the Radio Desk. The desk glows and plays a weak signal message.
14. Check storage to see your current supply manifest.
15. Use the bedroll to heal and save progress. Once the Radio Desk is built, resting notes that the base is a little more awake.
16. Step back out to the world. With the Radio Desk built and a save made, a new signal claws in from the north and a cyan glow appears at the north edge — the demo's ending hook and the promise of the next zone. (The optional Route Beacon, if lit, is acknowledged but never required.)

## Run

Open `project.godot` in Godot 4.7 and press F5.

From PowerShell on this machine:

```powershell
& "C:\Users\Jamie Parr\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\Jamie Parr\Documents\Projects\the-world-forgot-us\the-world-forgot-us"
```

The main scene is `res://scenes/main.tscn`.
