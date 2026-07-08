# Persistence + Demo Stability Pass 6 Report

Goal: make the demo stable across scene travel and save/load without adding
major systems. Levels are re-instanced on every trip, so scene-local state
(searched crates, resolved choices, defeated enemies) previously reset on any
travel. This pass adds a small persistent flag store so those stick.

## Safety

- Verified active root: `Documents\Projects\the-world-forgot-us\the-world-forgot-us`.
- On entry the tracked tree held a stale cloud-sync revert of `README.md` (it had
  dropped the committed Pass 5 walkthrough and spawned a "Name clash" duplicate).
  Restored `README.md` from `a4c2573`; left the untracked sync-conflict copy alone
  (no reorganising, no quarantine touched).
- Latest commits: `a4c2573` (Demo Arc Pass 5), `7996dc6` (Playability Pass 4).

## Approach

One small autoload, **`WorldState`** (`scripts/systems/world_state.gd`), mirroring
`BaseUpgradeSystem`: a plain flag store of "consumed" ids that survives level
re-instancing (autoloads persist) and is serialised by `SaveManager`. No new
gameplay system, no new UI, no scene edits.

Placed nodes derive a **stable id from their node name** (unique across the demo),
so no per-instance authoring was needed. Each also exposes an `@export`
(`persistent_id` / `choice_group` + `option_id`) for future overrides.

## What now persists (across travel AND save/load)

- **Searched loot containers** — every crate/toolbox/locker, plus the `ChildLunchbox`
  keepsake pickup. On revisit they appear dim/emptied and give no loot again.
- **Resolved either/or choices** — `ChoiceKiosk` (salvage | Tin Locket) and
  `ChoiceForecourt` (wiring/scrap | Old Photo). After a pick, both options stay
  locked and the reward is never re-granted.
- **Defeated hand-placed Hollows** — `RoadHollow`, `AvoidableHollow`, `RelayHollow`.
  A defeated Hollow does not respawn on return (it frees itself in `_ready` if its
  id is marked defeated).
- **Ending hook** — the Pass 5 "north signal" one-time flag moved from a
  session-only `root` meta to `WorldState.ending_hook_shown`, so it no longer
  re-fires after reload. The north-signal glow still shows whenever the Radio Desk
  is built (that state already persisted via `BaseUpgradeSystem`).
- (Already persisted before this pass: inventory, recovered echoes, built upgrades,
  current level, player position, player health.)

## What is still scene-local (by design)

- Living-enemy exact positions, in-flight tweens/particles, camera state — transient
  visuals, not worth serialising.
- Nothing in the three targeted categories (containers / choices / enemies) is
  scene-local anymore.

## Save format notes

- Added `"version": 1` and a `"world"` block:
  `{ "opened": [ids], "choices": {group: option}, "defeated": [ids], "ending_hook_shown": bool }`.
- **Backward compatible:** older saves without `version`/`world` still load — every
  read uses `.get(..., default)`, so world flags default to empty and inventory /
  upgrades / echoes / level / player restore exactly as before. No crash.
- **Robustness:** `SaveManager` keeps its null guards for missing main/player; ids
  are plain strings, so a saved id whose node no longer exists is simply never
  matched (no lookup, no crash). Ids follow node names — renaming a placed node
  would orphan its saved flag (documented, acceptable for a hand-authored demo).

## Files touched

- **new** `scripts/systems/world_state.gd` — the flag store.
- `project.godot` — registered `WorldState` autoload (before `GameManager`).
- `scripts/systems/save_manager.gd` — `SAVE_VERSION`, `world` block in save/load.
- `scripts/world/loot_container.gd` — `persistent_id`; restore searched state; mark on open.
- `scripts/world/choice_option.gd` — `choice_group`/`option_id`; lock on load; mark on pick.
- `scripts/enemies/enemy_hollow.gd` — `persistent_id`; skip-spawn if defeated; mark on death.
- `scripts/maps/test_map.gd` — ending hook flag now reads/writes `WorldState`.

No costs, enemy tuning, collisions, interaction areas, loot notices, or inventory
icons were changed.

## Validation

- Godot 4.7 headless, 120 frames: **0 errors / 0 warnings.**
- `git diff --check`: clean (CRLF normalisation warnings only).
- **Persistence smoke test** (temporary autoload, removed): **ALL PASS**
  - searched crate, resolved choice, defeated Hollow set up (6 items)
  - travel base↔world → crate still searched, choice still locked, Hollow gone,
    items unchanged (no duplication)
  - save → wipe volatile autoload state → load → all flags restored, nodes reflect
    them, items restored exactly (no dup, no loss), ending-hook flag restored
- **Full-arc regression smoke** (temporary autoload, removed): **ALL PASS**
  - fresh start → crate → scanner reveal + echo recovery → Radio Desk build →
    rest/save → return → ending hook (north signal + flag) → Route Beacon build

## Remaining limitations (unchanged)

- Player and Hollow are still placeholder/blockout visuals (`NEXT_ASSET_REQUESTS.md`).
- No real audio yet.
- The "next zone" is still only a hook — no new area loads.
- Persisted ids are tied to node names; renaming a placed crate/choice/enemy would
  reset that one flag.
