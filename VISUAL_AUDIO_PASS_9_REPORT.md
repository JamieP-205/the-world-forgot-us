# Visual + Audio Feel Pass 9 Report

Goal: make the existing demo slice feel less like a prototype — better character
readability and a first layer of sound — without adding a new zone, new gameplay
systems, or disturbing any validated build/menu/save/persistence behaviour.

## Entry state / safety

- Verified active root and confirmed HEAD was
  `7af161425da3c100f3b83088e3572df03434f72e` (Release Zip Verification Pass 8.2).
- Working tree was clean on entry.
- Godot 4.7 headless, 120 frames on entry: **0 errors / 0 warnings.**
- Did not touch the cleanup quarantine, the cloud-sync duplicate files, or the
  verified release ZIP.

## 1. Visual audit (what read as "prototype")

- **Player** — flat Polygon2D figure with no grounding; otherwise well composed
  (coat/head/backpack + amber facing arrow).
- **Hollow** — the worst offender: a pale humanoid wrapped in a dark-red
  `ThreatShadow` + red `DangerAura`, which read as an angry red *block* rather
  than a forgotten, ghostly survivor.
- Scanner pulse, memory echo, Railhome, Radio Desk, Route Beacon, exits/road
  guidance, loot containers, and the north-signal ending hook already use
  sprites and/or tuned effects and read acceptably — left as-is.
- No sound anywhere: every beat was text/visual only.

## 2. Player visual improvement

- Added a soft **contact shadow** (`Shadow` Polygon2D, drawn beneath the body)
  in `scenes/player/player.tscn` so the player sits on the ground in the
  top-down view.
- Facing arrow, collisions (`18×22`), camera, controls, combat, scanner, and the
  interaction area are all unchanged. No animations were added, so nothing can
  break. The concept turnaround sheet was intentionally *not* forced in (it is
  eye-level, not top-down — see `NEXT_ASSET_REQUESTS.md`).

## 3. Hollow visual improvement

- Replaced the red `ThreatShadow`/`DangerAura` with a cold **`ContactShadow`**
  (grounding) and a pale **`ForgottenHaze`** (cool grey-cyan, low alpha) in
  `scenes/enemies/enemy_hollow.tscn`, so the Hollow now reads as a pale,
  forgotten silhouette that stays visible against dark ground and is clearly
  distinct from the warm-toned player.
- Added a **cosmetic-only** slow shimmer on the haze (`enemy_hollow.gd` `_ready`,
  a looping alpha tween created only after the "already defeated" early-out).
  It touches no physics, AI, collision, damage, death persistence, or balance.
- Enemy stats, detection, contact damage, hit flash, death dissolve, and the
  defeated-persistence path are all unchanged. Combat is not harder.

## 4. Audio pass (small, safe, procedural)

No audio assets exist in the project, so a new **`AudioManager` autoload**
(`scripts/systems/audio_manager.gd`, registered last in `project.godot`)
synthesises ten short PCM tones in memory at startup (`AudioStreamWAV`, 22 050 Hz,
16-bit mono) and plays them through a small pool of `AudioStreamPlayer`s. **No
audio files are shipped or imported**, and with the headless dummy driver
`play()` is a harmless no-op, so validation is unaffected. Master trim is
`-13 dB` with low per-tone amplitude to keep it quiet.

Events covered (all eight requested):

| Event | Trigger | Hook |
| --- | --- | --- |
| Loot pickup | `loot_container.gd` | direct `play("pickup")` |
| Scanner pulse | `EventBus.scanner_pulsed` | signal |
| Echo revealed | `EventBus.echo_revealed` | signal |
| Echo recovered | `memory_echo.gd` | direct `play("echo_recover")` |
| Hollow hit | `enemy_hollow.gd` `_flash` | direct `play("hollow_hit")` |
| Hollow death | `enemy_hollow.gd` `_on_died` | direct `play("hollow_death")` |
| Radio Desk built | `BaseUpgradeSystem.upgrade_built` | signal → `build` |
| Route Beacon built | `BaseUpgradeSystem.upgrade_built` (id `route_beacon`) | signal → `beacon` |
| Bedroll rest/save | `EventBus.game_saved` | signal (only the bedroll saves) |
| Ending hook | `test_map.gd` | direct `play("ending")` |

No music was added (no suitable asset exists).

## 5. Atmosphere polish

- **Notice timing:** `hud.gd` now scales a notice's on-screen time to its length
  (`clampf(3.0 + len*0.045, 4.0, 11.0)` seconds) instead of a flat 5 s, so long
  multi-line beats (opening line, echo recovery, ending hook) stay up long enough
  to read while short toasts still clear quickly.
- Kept everything else deliberately restrained — no new particles or heavy
  screen effects.

## 6. Regression safety

Unchanged: save format/schema, `WorldState` flag names, persistent IDs, demo
objective order, menu/pause flow, and all build/packaging files. The verified
release ZIP was **not** touched.

## Files touched

- **new** `scripts/systems/audio_manager.gd`
- `project.godot` — registered `AudioManager` autoload (last).
- `scenes/player/player.tscn` — contact shadow.
- `scenes/enemies/enemy_hollow.tscn` — cold shadow + forgotten haze (replacing red aura).
- `scripts/enemies/enemy_hollow.gd` — hit/death SFX + cosmetic haze shimmer.
- `scripts/world/loot_container.gd` — pickup SFX.
- `scripts/world/memory_echo.gd` — echo-recover SFX.
- `scripts/maps/test_map.gd` — ending-hook SFX.
- `scripts/ui/hud.gd` — length-scaled notice duration.
- `README.md` — updated audio + visual feature descriptions.
- **new** `VISUAL_AUDIO_PASS_9_REPORT.md` (this file).

Temporary headless smoke harness (`_smoke_pass9.tscn/.gd`) was created, used, and
deleted before commit.

## Intentionally left placeholder

- Player and Hollow remain Polygon2D blockout (improved, not replaced) — real
  top-down character sheets are still the hard art blocker in
  `NEXT_ASSET_REQUESTS.md`.
- Audio is procedural placeholder tones only — no music, no final sound design.
- The fallen mast, kiosk, and shed remain blockout; no new zone was added.

## Validation

- Godot 4.7 headless, 120 frames: **0 errors / 0 warnings.**
- **Targeted smoke** (temporary main-scene driver, autoloads live, then removed):
  world map + player booted; `Shadow` and `ForgottenHaze` nodes confirmed
  present; `Hollow.take_damage` (hit SFX path) fired; all 10 synthesised sounds
  played; `scanner_pulsed` / `echo_revealed` / `game_saved` / `upgrade_built`
  handlers fired — **PASS9_SMOKE_RESULT: PASS**, no runtime errors.
  - Note: the smoke surfaced the pre-existing cloud-sync duplicate
    `memory_echo (# Name clash … #).gd` "hides a global script class" parse
    error. It predates this pass, affects only the inert duplicate (excluded from
    the release build), and was left untouched per the rules.
- `git diff --check`: clean (only CRLF normalisation warnings, as in prior passes).
- Only source/docs are modified; no `builds/`, `dist/`, exe, pck, zip, temp, or
  machine-local files are staged.

## Whether the release ZIP was left untouched

**Yes.** `dist/TheWorldForgotUs_Demo_Windows.zip` and all build/package artifacts
were not modified, rebuilt, or re-exported. This pass changes source only; a
future rebuild would pick up the improvements.

## Remaining limitations

- Unsigned Windows executable (SmartScreen warning).
- Player/Hollow still placeholder blockout art; no real character sheets.
- Procedural placeholder audio only; no music or final sound design.
- Next zone is still only an ending hook.
- Persisted IDs are tied to node names.
- Fresh export environments must recreate the local sync-duplicate exclusion.
