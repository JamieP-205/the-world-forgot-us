# The World Forgot Us

A small Godot 4 top-down survival prototype. This is not the full game. The current source is a focused 5-8 minute vertical slice: scavenge a compact road/station loop, strengthen the Mnemoscope, recover one memory echo, return to the Railhome, build the Radio Desk, and rest/save.

## What works now

- Player movement, facing, melee attack, health, death, and wake-at-base respawn.
- A compact hand-built wasteland route: Railhome start, road supplies, petrol station/kiosk/shed material loop, fallen mast memory moment, one guarded relay cache, and return to Railhome.
- Searchable supplies grant real inventory items and show pickup notices. Canned Food heals in the field with **F**.
- Scrap and batteries now serve a clearer loop: build the Scanner Coil first, then recover the mast echo, then build the Radio Desk.
- The Mnemoscope scanner sends a visible pulse, spends/recharges energy, and reveals the hidden echo only after the Scanner Coil is built.
- The Last Broadcast has a stronger reveal/recovery beat, a multi-line recovery notice, and changes the fallen mast area after recovery.
- The HUD shows health, scanner energy, item icons, recovered echo count, interaction prompts, notices, objective progress, and a fixed objective compass.
- The compact map uses one temporary style: dark ash ground, rust-brown structures, muted amber safe-zone light, cyan memory tech, and low-saturation placeholder shapes where sprites are missing.
- Returning to the Railhome works through scene exits.
- The Radio Desk can be built if you have recovered The Last Broadcast and have the required materials. When built, it lights up and plays a short placeholder signal message.
- The Memory Shelf recognizes keepsakes carried home, including the Child's Lunchbox and the echo photograph.
- The Signal Lantern remains an optional Railhome upgrade for extra salvage.
- The bedroll heals the player and saves progress with: `Rested. Progress saved.`
- Progress is stable across travel and save/load: inventory, recovered echoes, built upgrades, current level, player position/health, searched containers, resolved world flags, and defeated hand-placed Hollows persist. See `PERSISTENCE_PASS_6_REPORT.md`.
- Atmosphere now includes world-space ash, colder wasteland tint, warmer Railhome tint, cyan echo glow, amber safe lights, procedural wind, and a low procedural drone/music bed.
- Imported art remains in use for loot crates, base furniture, the lit Radio Desk, the memory-echo core, world props, inventory item icons, decals, and station signage. See `ASSET_IMPORT_REPORT.md`.

## Still placeholder

- The player and Hollow still use animated top-down placeholder sprite sheets, now tinted/veiled to sit closer to the world palette. They are not final painterly art.
- The fallen mast, roadside kiosk, maintenance shed, and some structure details are still stylized Polygon2D blockout, though no longer bright debug colors.
- Combat is a basic melee hitbox and simple Hollow chase/contact damage.
- Storage is a manifest, not a full stash-transfer UI.
- The Radio Desk build is a payoff milestone only. It hints at the next signal but does not unlock a new quest yet.
- Audio is procedural placeholder sound and drone only; there is no final music composition or final sound design.
- There are no NPCs, factions, procedural generation, advanced crafting, or final UI styling.

## Controls

| Input | Action |
| --- | --- |
| W A S D | Move |
| E | Interact |
| J or Left-click | Melee attack |
| Q or Right-click | Scanner pulse |
| F | Eat a ration (heal, uses Canned Food) |
| Esc | Pause / resume |

## Demo walkthrough

0. On launch you land on the **main menu**: **Continue** (loads your save, if any), **New Game** (clears the save and starts fresh, confirmed first if a save exists), **Controls**, **Quit**. Press Esc in-game for the pause menu.
1. Start in the wasteland at the Railhome door. Follow the amber road and search the first supply crate.
2. Scavenge the compact road/station loop: car boot, kiosk drawer, pump locker, and shed locker. Food heals with **F** if a Hollow hurts you.
3. Visit the fallen mast and scan with **Q**. The signal is present, but too weak until the Scanner Coil is built.
4. Return west to the Railhome once you have enough battery/scrap and build the Scanner Coil.
5. Go back to the mast, scan again, step into the cyan echo, and press **E** to recover The Last Broadcast.
6. Optional: take the Child's Lunchbox near the kiosk and/or clear the guarded relay cache for extra salvage.
7. Return to the Railhome and build the Radio Desk.
8. Use the Memory Shelf if you carried a keepsake home.
9. Optional: wire the Signal Lantern if you have surplus salvage.
10. Rest at the bedroll to heal/save. Step outside afterward to see the north signal ending hook. The next zone is not playable yet.

## Run

Open `project.godot` in Godot 4.7 and press F5. The game boots to the **main menu** (`res://scenes/ui/main_menu.tscn`).

From PowerShell on this machine:

```powershell
& "C:\Users\Jamie Parr\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\Jamie Parr\Documents\Projects\the-world-forgot-us\the-world-forgot-us"
```

During development you can still run the game scene directly (`res://scenes/main.tscn`, F6) to skip the menu. It auto-continues from a save or starts the world.

### Starting / resetting your save

- **Continue** loads the current save (also auto-continued if you run the game scene directly).
- **New Game** wipes the save and all run state (inventory, world flags, echoes, upgrades) and starts fresh; it asks to confirm if a save already exists.
- The save lives at `user://savegame.json`.

### Export / build status

A Windows test build exists, but **Pass 14 was not exported or zipped**. The shareable ZIP below is still the prior Pass 13.1 package and does not include this vertical-slice rebuild.

With the Godot 4.7 export templates installed and the `Windows Desktop` preset (machine-local `export_presets.cfg`), export headless with:

```powershell
& "...\Godot_v4.7-stable_win64_console.exe" --headless --path "<project>" --export-release "Windows Desktop"
```

This writes `builds/windows-test/TheWorldForgotUs_Demo.exe` + `.pck`. The tester package lives in `dist/TheWorldForgotUs_Demo_Windows/` and is zipped to `dist/TheWorldForgotUs_Demo_Windows.zip`. All exported binaries and the ZIP under `builds/` and `dist/` are git-ignored.

**Current shareable ZIP** (outdated Pass 13.1 rebuild, source commit `787fe114d2e75b9e582643ef8b96d68e6fd08219`; does not include Pass 14):

- Path: `dist/TheWorldForgotUs_Demo_Windows.zip`
- Size: 67,652,404 bytes
- SHA-256: `9FCA718E42EDD91A3372A644463D8ED4755E8B0D674A28EC45E58CF8AAD47A99`

**To run the packaged build**: unzip it, keep `TheWorldForgotUs_Demo.exe` and `TheWorldForgotUs_Demo.pck` together in the same folder, and double-click the `.exe`. Windows SmartScreen may warn because the build is unsigned; choose *More info -> Run anyway* if you trust it.

### Sharing with testers

Handoff docs for sending the demo to real testers: `TESTER_SEND_MESSAGE.md`, `TESTER_FEEDBACK_TEMPLATE.md`, and `KNOWN_ISSUES_FOR_TESTERS.md`. The ZIP itself also carries `README_TESTER.txt` + `BUILD_NOTES.md`, but those packaged copies are from the previous build until a future export pass.
