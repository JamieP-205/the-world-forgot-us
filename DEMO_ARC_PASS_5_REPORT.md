# Demo Arc Pass 5 Report

Goal: shape the existing playable demo into a satisfying ~10-minute slice with
a clear beginning, middle, payoff, and ending hook — using only existing
mechanics, scenes, and systems. No new architecture, no quest system.

## Safety

- Verified the active project root: `Documents\Projects\the-world-forgot-us\the-world-forgot-us`.
- Working tree was dirty (uncommitted Playability Pass 4 work). Checkpointed it
  before any edits: `7996dc6 checkpoint: post playability pass 4`
  (on top of `04d13f9 checkpoint: post content pass 3`).
- No file reorganisation; quarantine and archives untouched.

## Fresh-run audit (what the arc was)

Reviewed against the current scenes/scripts and a clean (no-save) launch:
spawn at the Railhome door → amber arrows east → first crate → fallen mast
scan/recover → petrol/kiosk/shed + optional choices + guarded relay cache →
return to Railhome → build Radio Desk → rest/save → build Route Beacon →
return to world.

Weak beats identified:
- **Opening** was a functional hint but not atmospheric — it didn't establish
  that you're alone in a forgetting world.
- **Mast echo** reveal/recovery worked but the reveal didn't clearly say "press
  E," and recovery didn't push the player home.
- **Rest** was a flat "Rested. Progress saved." — no sense of a safe pause or a
  base coming alive.
- **Ending** existed only as objective text ("next signal north"); returning to
  the world showed no visible change or payoff.

## Changes made (small, existing systems only)

### 1. Opening beat — `scripts/ui/hud.gd`
Opening notice now reads:
> "You wake alone on the dead road. The Railhome is at your back; everything the
> world forgot lies east. Follow the amber arrows and search the glinting crates (E)."

The player already spawns beside the "Return to the Railhome" door with amber
arrows pointing east, so this makes "alone / road matters / first goal" land in
the first seconds. (One notice change only — no tutorial walls.)

### 2. Mast echo — `scripts/world/memory_echo.gd`
- **Reveal** (on scan) now: "A cyan echo tears free above the fallen mast — a
  voice from the night everyone left. Step into the light and press E to recover it."
  (clearer action + kept the mystery).
- **Recovery** now: "Echo recovered — The Last Broadcast. <memory> The mast glows
  warm behind you. Carry this home, west, to the Railhome." (stronger, short,
  and pushes the objective transition home). Existing cyan→warm tween and camera
  shake are unchanged.

### 3. Railhome payoff — `scripts/base/save_point.gd`
Resting now reads as a real safe pause, and the base feels more awake once the
Radio Desk is built:
> "You sleep. For a while, nothing out there is trying to forget you. The Radio
> Desk hums warm through the carriage walls. Rested. Progress saved."
(The "hums warm" line only appears after the Radio Desk is built.) The Radio Desk
build message and its lit sprite/glow from earlier passes already provide the
build payoff and were left intact.

### 4. Ending hook — `scripts/maps/test_map.gd` + `scenes/maps/test_map.tscn`
- New **`NorthSignal`** node (a pulsing cyan/amber glow) at the north edge of the
  map, hidden by default. `test_map.gd` shows and pulses it once the Radio Desk
  is built — a visible world change after the payoff.
- After the player has built the Radio Desk **and** rested/saved, the next time
  they step into the world an ominous hook fires once per session (guarded by a
  `root` meta flag, no new autoload):
  > "A NEW SIGNAL claws in from the north — louder than the last, and wrong
  > somewhere underneath. '...come north... it isn't finished forgetting...' The
  > next road is out there, and it is already changing."
  If the optional Route Beacon is lit, one bonus line is appended. A small camera
  shake accompanies it.

### 6. Optional content stays optional
The ending hook requires only the **main** arc (Radio Desk + rest). The Route
Beacon, lunchbox thread, and choice keepsakes remain optional flavour and only
add a bonus line / objective ticks — they never gate the ending.

## Files touched
- `scripts/ui/hud.gd` — opening notice.
- `scripts/world/memory_echo.gd` — reveal + recovery messages.
- `scripts/base/save_point.gd` — rest message.
- `scripts/maps/test_map.gd` — north-signal reveal + ending hook.
- `scenes/maps/test_map.tscn` — `NorthSignal` node.
- `README.md` — walkthrough/ending note.
- `DEMO_ARC_PASS_5_REPORT.md` — this file.

No systems, costs, collisions, interaction areas, or save format were changed.

## Validation
- Godot 4.7 headless, 120 frames: **0 errors / 0 warnings.**
- Full-arc headless smoke test (temporary autoload, removed after): **ALL PASS**
  - fresh start (no save, world loaded)
  - crate search → 3 items
  - scanner reveal + echo recovery → The Last Broadcast archived
  - travel to base → Radio Desk builds
  - rest at bedroll → save written
  - return to world → **NorthSignal visible + ending hook fires**
  - Route Beacon builds
- Visual confirmation via screenshots: opening notice + spawn/arrows read clearly;
  ending notice + north-signal glow + all-main-objectives-complete tracker read clearly.

## Known limitations (unchanged from Pass 4)
- Searched-crate / choice-lock / defeated-enemy state is still scene-local (not
  saved). Global demo state (inventory, echoes, upgrades, level, position,
  health) persists.
- Player and Hollow are still placeholder/blockout visuals (see
  `NEXT_ASSET_REQUESTS.md`).
- No real audio yet; radio/signal beats are text + visual feedback.
- The "next zone" is a hook only — no new area is loaded yet.
