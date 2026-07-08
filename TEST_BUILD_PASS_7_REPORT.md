# Test Build Prep Pass 7 Report

Goal: turn the demo into a clean, shareable first test build — a real start
flow, a proper pause menu, a controls/help screen, reliable save/reset, and
export readiness — without adding new gameplay.

## Safety

- Verified active root and that the tip commit was `1c72ffa` (Persistence Pass 6).
- Working tree was clean apart from the untracked cloud-sync "Name clash" README
  duplicate. No checkpoint needed; the duplicate is now covered by a `.gitignore`
  pattern (left on disk, never staged, never moved/deleted).
- Headless 120 frames on entry: 0 errors.

## 1. Main menu / start flow  (new)

- `scenes/ui/main_menu.tscn` + `scripts/ui/main_menu.gd`, set as the project's
  `run/main_scene`.
- Buttons:
  - **Continue** — loads the existing save (disabled/greyed when there is no save).
  - **New Game** — clears the save *and all run state* and starts fresh. If a save
    exists it first asks for confirmation (`ConfirmationDialog`, "Erase your saved
    progress and start a new run?").
  - **Controls** — opens the shared controls/help panel.
  - **Quit** — exits.
- Running `scenes/main.tscn` directly during development still works (Main
  auto-continues from a save or starts the world), so the dev workflow is intact.

## 2. Pause menu polish

- The old pause overlay was just dimmed text. It now shows a centered menu:
  **Resume**, **Controls**, **Main Menu**, **Quit** (in `scenes/ui/hud.tscn`,
  wired in `scripts/ui/hud.gd`). "Main Menu" unpauses and returns to the menu.
- `GameManager` now only toggles pause while the `Main` game root is in the tree,
  so Esc can't freeze the main menu.

## 3. Controls / help screen  (new, shared)

- `scenes/ui/controls_panel.tscn` + `scripts/ui/controls_panel.gd` — one reusable
  panel instanced by both the main menu and the pause menu. Lists:
  Move (WASD / arrows), Interact (E), Scan (Q), Attack (Left click / J),
  Pause (Esc), plus the objective hint:
  "Search supplies, follow the road, scan the fallen mast, return to the Railhome."

## 4. Save / reset reliability  (verified by smoke test)

- **Continue** loads the current save.
- **New Game** calls `SaveManager.clear_run_state()` which deletes the save and
  clears inventory, WorldState flags, recovered echoes, and built upgrades; the
  fresh world then loads at the authored spawn with a full-health player.
- **Reset leaves no stale WorldState** — a seeded junk flag + save were fully wiped.
- **Old saves don't crash** — a legacy save with no `version`/`world` keys loads
  fine (every field read uses `.get(default)`; world flags default empty).

## 5. Export / build status  (BLOCKED: templates not installed)

- `%APPDATA%/Godot/export_templates/4.7.stable/` is **empty (0 files)**, so no
  Windows build can be produced right now. Per the pass rules, nothing was
  downloaded.
- `.gitignore` now ignores `builds/` and `dist/` so exported binaries won't be
  committed. `export_presets.cfg` remains ignored (machine-specific).
- **To export later (Windows Desktop):**
  1. Godot editor -> *Editor > Manage Export Templates > Download and Install*
     for `4.7.stable` (~700 MB), or drop the templates into
     `%APPDATA%/Godot/export_templates/4.7.stable/`.
  2. *Project > Export > Add > Windows Desktop*; set export path to
     `builds/TheWorldForgotUs.exe`.
  3. Export, or headless:
     `Godot_v4.7-stable_win64_console.exe --headless --export-release "Windows Desktop" builds/TheWorldForgotUs.exe`

## 6. Git hygiene

- The cloud-sync "Name clash" README duplicate is now matched by a specific
  `*Name clash*` `.gitignore` rule (it stopped appearing in `git status`). The file
  was **not** deleted or moved. The rule is narrow and hides no real project files.
- Added `builds/` and `dist/` to `.gitignore`.

## 7. Test route  (scripted smoke, headless)

Full route through the new start flow — **ALL PASS**:
- boot at main menu (Continue disabled, no save)
- New Game -> fresh world (junk state + save wiped, 0 items)
- search crate, scan + recover echo, build Route Beacon (world)
- travel to Railhome, build Radio Desk, rest/save
- return to world -> ending hook (north signal visible)
- change to main menu, wipe volatile autoloads (simulating relaunch), Continue
  (now enabled) -> everything restored: echo, Radio Desk, Route Beacon, searched
  crate, inventory count identical (no duplication)

## Files touched

- **new** `scenes/ui/main_menu.tscn`, `scripts/ui/main_menu.gd`
- **new** `scenes/ui/controls_panel.tscn`, `scripts/ui/controls_panel.gd`
- `project.godot` — `run/main_scene` -> main menu
- `scenes/ui/hud.tscn`, `scripts/ui/hud.gd` — pause menu + controls panel
- `scripts/systems/save_manager.gd` — `clear_run_state()`
- `scripts/systems/game_manager.gd` — pause only during gameplay
- `.gitignore` — builds/dist + Name-clash pattern

No gameplay content, costs, collisions, or save format fields were changed
(the save schema already carried `version`/`world` from Pass 6).

## Validation

- Godot 4.7 headless, 120 frames (main scene = main menu): **0 errors / 0 warnings.**
- `git diff --check`: clean (CRLF normalisation warnings only).
- Menu-flow + full-route + Continue-persistence smoke: **ALL PASS.**
- Legacy-save robustness smoke: **PASS** (no crash, fields defaulted).
- Menu and pause screens confirmed visually via screenshots.
- Export: **not attempted** — templates absent (documented above).

## Remaining limitations

- Player and Hollow are still placeholder/blockout art; no real audio.
- The "next zone" is still only a hook.
- No Windows build produced this pass (export templates not installed).
- Persisted ids are tied to placed node names.
