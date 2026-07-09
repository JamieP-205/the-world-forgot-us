# Build Notes - The World Forgot Us Demo

- **Build name:** The World Forgot Us Demo
- **Build type:** First playable test demo (vertical-slice prototype, not the full game)
- **Build pass:** Build/Repackage Pass 13.1 - Windows demo ZIP rebuilt with Pass 13 Quality Rescue fixes
- **Source commit:** `787fe114d2e75b9e582643ef8b96d68e6fd08219` (`fix: improve demo playability and visual cohesion`), branch `master`
- **Date:** 2026-07-09
- **Engine:** Godot 4.7 stable, GL Compatibility renderer
- **Platform:** Windows desktop, x86_64
- **Output:** `builds/windows-test/TheWorldForgotUs_Demo.exe` + `TheWorldForgotUs_Demo.pck`
- **Tester ZIP:** `dist/TheWorldForgotUs_Demo_Windows.zip`

## What's new in this build

This package includes the Pass 13 Quality Rescue fixes. It replaces the older
Pass 12.1 shareable ZIP, which did not include these changes.

- HUD compass added: N/E/S/W ring plus an amber pointer toward the current objective.
- Canned Food can now heal the player in the field with **F**.
- Scanner Coil upgrade added at the Railhome: wider scanner pulse and faster recharge.
- Signal Lantern upgrade added at the Railhome: warms and visibly brightens the base.
- Memory Shelf payoff added for carried keepsakes: recognizes lunchbox/locket/photo without consuming them.
- Memory echo scale/effect fixed so the echo reads as a small cyan shard rather than a giant blob.
- Ash/fog is now world-space atmosphere instead of moving with the camera.
- Demo endpoint objective text now clearly marks the north signal as an ending hook, not a playable next zone.
- Audio pass improved with low ambient wasteland wind, eat/keepsake cues, and clearer levels.
- Pass 12 animated top-down placeholder sprites for the player and Hollow remain integrated.

## Controls

| Input | Action |
| --- | --- |
| W A S D / Arrows | Move |
| E | Interact / search / build |
| J or Left-click | Melee attack |
| Q or Right-click | Scanner pulse |
| F | Eat a ration (heals, consumes Canned Food) |
| Esc | Pause / resume |

Main menu: **Continue** (loads save), **New Game** (wipes save, confirms first),
**Controls**, **Quit**. In-game Esc opens the pause menu (Resume / Controls /
Main Menu / Quit).

## What the tester should try (~5-10 min)

1. Main menu opens; pick **New Game**.
2. Move east along the road. Search glinting crates with **E**.
3. Read a lore prop or two (poster, warning board, phone, vending machine).
4. Check that the HUD compass points toward the current objective as you move.
5. If you find Canned Food and take damage, press **F** to heal in the field.
6. Reach the fallen radio mast, press **Q** to scan, then walk into the cyan echo and press **E** to recover The Last Broadcast.
7. Return west and use the door (**E**) to enter the Railhome.
8. Build the Radio Desk, check storage, then optionally build the Scanner Coil or Signal Lantern if you have enough Scrap/Battery.
9. Inspect the Memory Shelf if you returned with a keepsake.
10. Rest on the bedroll (heals + saves), then step back outside to see the north signal ending hook.
11. Press **Esc** to test the pause menu; quit from the menu.
12. Relaunch and press **Continue** to confirm your progress persisted.

## Known limitations

- The executable is unsigned. Windows SmartScreen may show a warning.
- Player/Hollow sprites and several buildings remain placeholder blockout assets, not final art.
- Audio is procedural placeholder sound only; there is no final sound design or music yet.
- Combat is a simple melee hitbox vs. basic Hollow chase/contact damage.
- Storage is a manifest view, not a stash-transfer UI.
- The next zone is only an ending hook; no new area loads yet.
- Persisted scene IDs are still tied to node names, so future content renames need migration care.
- No final UI styling; this is a functional test slice.

## How to reset your save

- Choose **New Game** from the main menu (it wipes the save and all run state; it confirms first if a save exists), **or**
- Delete the save file manually:
  `%APPDATA%\Godot\app_userdata\The World Forgot Us\savegame.json`
  (Godot's `user://savegame.json`).
