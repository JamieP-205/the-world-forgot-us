# Known Issues — For Testers

Please read this before reporting a bug — a lot of the rough edges below are
**known and expected** for this early demo. If you hit something *not* on this
list, that's the good stuff: please tell me!

## Expected / not bugs (please don't report these)

- **"Windows protected your PC" / SmartScreen warning on launch.** The build is
  not code-signed (it's a solo hobby project). Click **More info → Run anyway**.
  Antivirus may flag it for the same reason — it's a false positive.
- **Placeholder characters.** The player and the "Hollow" enemies are simple
  blockout shapes (with shadows), not final art. The fallen mast, roadside kiosk,
  and shed are also still rough.
- **No music, only simple sounds.** Audio is lightweight placeholder tones
  generated in-engine — no soundtrack or final sound design yet.
- **The "next zone" doesn't load.** At the end, a signal calls you north and a
  glow appears — that's just a teaser hook. There's no new area to travel to yet.
- **Storage is just a list.** The storage crate shows a text manifest of your
  supplies; it isn't a drag-and-drop stash.
- **Basic combat.** Melee is a simple swing; Hollows just shamble toward you and
  hurt you on contact. It's intentionally minimal for now.
- **Plain UI.** No final menu/HUD styling — it's functional, not pretty.

## Things to keep an eye on (possible real bugs — worth reporting)

- Getting **stuck on geometry** or unable to reach the mast / the Railhome door.
- **Save/Continue** not restoring your progress after you close and reopen.
- Loot, choices, defeated enemies, or objectives **resetting or repeating** when
  they shouldn't (e.g. a crate you already searched giving loot again).
- The **echo** not appearing after you scan the mast, or not being recoverable.
- The **Radio Desk** not building even though you have the materials.
- Audio that's **way too loud**, crackly, or annoying.
- Any **crash, freeze, or hard error message**, or the window failing to open.
- Big **lag/stutter** or very low frame rate.

When reporting, a one-line "I was doing X when Y happened" (plus a screenshot if
easy) helps a ton.

## How to reset your save

- Easiest: pick **New Game** on the main menu (it wipes the save and starts
  fresh; it asks to confirm first if a save already exists).
- Manual: delete this file, then relaunch —
  `%APPDATA%\Godot\app_userdata\The World Forgot Us\savegame.json`

## What this demo is (quick reminder)

A ~5–10 minute top-down survival slice: explore east, recover a memory echo at
the fallen mast, return to the Railhome, build the Radio Desk, and rest/save.
It's a first playable test, not the finished game.
