# Build Notes — The World Forgot Us Demo

- **Build name:** The World Forgot Us Demo
- **Build type:** First playable test demo (vertical-slice prototype, not the full game)
- **Commit:** `92371f2` (branch `master`)
- **Date:** 2026-07-08
- **Engine:** Godot 4.7 stable, GL Compatibility renderer
- **Platform:** Windows desktop, x86_64
- **Output:** `builds/windows-test/TheWorldForgotUs_Demo.exe` + `TheWorldForgotUs_Demo.pck`

## Controls

| Input | Action |
| --- | --- |
| W A S D / Arrows | Move |
| E | Interact / search / build |
| J or Left-click | Melee attack |
| Q or Right-click | Scanner pulse |
| Esc | Pause / resume |

Main menu: **Continue** (loads save), **New Game** (wipes save, confirms first),
**Controls**, **Quit**. In-game Esc opens the pause menu (Resume / Controls /
Main Menu / Quit).

## What the tester should try (~5–10 min)

1. Main menu opens; pick **New Game**.
2. Move east along the road. Search glinting crates with **E**.
3. Read a lore prop or two (poster, warning board, phone, vending machine).
4. Reach the fallen radio mast, press **Q** to scan, then walk into the cyan
   echo and press **E** to recover The Last Broadcast.
5. Return west and use the door (**E**) to enter the Railhome.
6. Build the Radio Desk, check storage, then rest on the bedroll (heals + saves).
7. Step back outside — a new signal/glow should appear at the north edge.
8. Press **Esc** to test the pause menu; quit from the menu.
9. Relaunch and press **Continue** to confirm your progress persisted.

## Known limitations

- Player and Hollow enemies are still placeholder/blockout art; most props/items
  use imported sprites.
- No real audio yet — radio/signal beats are text + visual feedback.
- Combat is a simple melee hitbox vs. basic Hollow chase/contact damage.
- Storage is a manifest view, not a stash-transfer UI.
- The "next zone" is only an ending hook — no new area loads yet.
- No final UI styling; this is a functional test slice.

## How to reset your save

- Choose **New Game** from the main menu (it wipes the save and all run state;
  it confirms first if a save exists), **or**
- Delete the save file manually:
  `%APPDATA%\Godot\app_userdata\The World Forgot Us\savegame.json`
  (Godot's `user://savegame.json`).
