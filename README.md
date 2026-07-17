# The World Forgot Us

[![Build and deploy Godot Web](https://github.com/JamieP-205/the-world-forgot-us/actions/workflows/pages.yml/badge.svg)](https://github.com/JamieP-205/the-world-forgot-us/actions/workflows/pages.yml)

**[Play the browser build](https://jamiep-205.github.io/the-world-forgot-us/)** — keyboard and mouse or the on-screen phone controls. Landscape is best on a small screen.

The World Forgot Us is a top-down mystery and survival game set around a failed British civil-warning network. Ellie Ward follows the repair trail left by her sister through Cullbrook Services, Ashmere Estate, Wrenfield Relay Station and Tollard Exchange. The messages know too much about Ellie, but knowing a fact and remembering a life are not the same thing.

I started the project as a small Godot exercise. It is now a complete four-region campaign with exploration, investigation, combat, crafting, enterable buildings, a working shelter, persistent choices and twelve route outcomes. It is still a personal project in active development, so balance and pacing will keep changing as I get more playtest results.

## What is in the current build

- Four connected regions with loops, shortcuts, side routes, sightline landmarks and optional scavenging away from the main job
- Nineteen enterable locations, each with one to three rooms, its own purpose, evidence, loot and a real exterior return point
- Carriage 317 rebuilt as a proper three-zone survival shelter with recovery, operations, workbench, radio, storage and living areas
- Four-direction locomotion for Ellie and all six enemy families, with shared turning, foot placement and animation timing
- Directional melee, dodge, healing, receiver sweeps, an unlockable discharge and enemies that react differently to light, noise, range and scanning
- A twelve-recipe crafting notebook with unique item art, unlock conditions, resource costs and effects that matter in exploration or combat
- Ten physical Trace Anchors built around ordinary objects rather than magic stones: detect, focus, reveal, compare, then file the evidence or feed it to the network
- Ten in-world profiles — nine survivors plus Continuity — with distinct silhouettes, schedules, services with gameplay effects, personal assignments, relationships and route consequences; Ellie and the real Maggie bring the narrative registry to twelve figures
- Twelve route combinations built from four relationship anchors and three shared Tollard operations — restore, mesh and sever — with anchor-specific assignments, modifiers and consequences
- Twenty-four route-exclusive assignments, fourteen corroborated revelations and an explorable aftermath
- A playable flooded-cutting discovery for Maggie's body and analogue recorder before the Tollard operation
- An eight-shot illustrated opening, rewritten dialogue surfaces, a field notebook archive, a folded route map and a quieter instrument-panel HUD
- A seven-minute day/night cycle, region-aware lighting, normal-mapped art, adaptive procedural music and a prioritised sound-effect mix
- Local saves, save migration, display/audio/accessibility options and responsive touch controls with safe-edge and portrait handling
- A single-threaded Web build checked and deployed by GitHub Actions

## How the campaign works

The Trace Receiver ties the main systems together. It locates physical evidence, exposes or interrupts some enemies and can share what Ellie finds with the voice on the line. Sharing makes the voice more capable and more convincing. Keeping a trace isolated protects the witness chain, but gives up useful guidance.

The campaign does not choose an ending from one final menu. Work done for Imogen, Rafi, Leena, Owen, Gwen, Idris, Mara, Tom and Nia changes who reaches Carriage 317 and which approaches to Tollard remain possible. Ellie commits to a clinic, radio, witness or copy anchor, completes that anchor's two assignments, then carries out one of three physical switch operations at Tollard: restore the warning network, break it into a local mesh or sever it. Those choices make twelve stateful route combinations, not twelve separate finale maps. Earlier evidence, rescues, service work, trace sharing, the recoverable-Hollow decision and Maggie's flooded-cutting recorder alter the operation and its aftermath.

The full story and clue structure are documented in [docs/NARRATIVE_WORLD_REWRITE.md](docs/NARRATIVE_WORLD_REWRITE.md). Art scale, collision, animation and interface rules live in [docs/ART_DIRECTION_AND_ASSET_MANIFEST.md](docs/ART_DIRECTION_AND_ASSET_MANIFEST.md).

## Controls

| Action | Keyboard / mouse | Phone or tablet |
| --- | --- | --- |
| Move | WASD or arrow keys | Lower-left movement field |
| Use / advance dialogue | E | `use` pad or dialogue button |
| Strike | J or left-click | `strike` pad |
| Receiver sweep | Q or right-click | `sweep` pad |
| Dodge | Space | `step` pad |
| Open field kit | — | `kit` tab |
| Craft | C | `kit` → `make` |
| Heal | F | `kit` → `dress` |
| Receiver discharge | R, after its repair | `kit` → `burst` |
| Trace archive | I | `kit` → `traces` |
| Field map | M | `kit` → `map` |
| Pause | Esc | `kit` → `pause` |
| Touch help | Field Guide menu | `kit` → `guide` |

The first touch session opens a short field guide after the opening. The kit closes after an action so it does not sit over the road. The default navigation bearing points broadly rather than acting as GPS; the precise-bearing accessibility option restores an exact pointer.

## Project layout

- `scenes/` maps, interiors, player, enemies, world objects and interface scenes
- `scripts/` gameplay, campaign state, dialogue, audio, rendering and world systems
- `resources/` items, recipes, traces, upgrades and animation data
- `assets/source/generated/` source sheets and visual references excluded from the Web export
- `assets/processed/` transparent game art, cinematic frames and deterministic normal maps
- `docs/` narrative, world, asset, scale and implementation rules
- `tools/` asset-processing utilities and deterministic contract tests
- `web/` browser shell and Web-template installer

Asset origins and processing steps are recorded in [ASSET_CREDITS.md](ASSET_CREDITS.md).

## Running it

The project targets [Godot 4.7](https://godotengine.org/). Open [project.godot](project.godot) and press **F5**, or run it from PowerShell:

```powershell
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --path .
```

The title screen is the configured main scene. Desktop saves use Godot's `user://savegame.json`; browser saves remain in that browser's site storage.

## Building the Web version

The committed preset uses Godot's single-threaded Web template, so a normal static host can serve it without cross-origin isolation headers. Install the official Godot 4.7 templates once:

```powershell
python web/install_godot_web_template.py `
  --archive-url "https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz" `
  --output-dir "$env:APPDATA\Godot\export_templates\4.7.stable" `
  --template web_nothreads_debug.zip `
  --template web_nothreads_release.zip
```

Export and serve it locally:

```powershell
New-Item -ItemType Directory -Force builds\web
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "Web" "builds/web/index.html"
python -m http.server 8060 --bind 127.0.0.1 --directory builds\web
```

Then open <http://127.0.0.1:8060/> in a current browser with WebGL 2 and hardware acceleration enabled.

## Checks

The main smoke walks the campaign, loads every required scene and checks live lighting, audio, saves, routes and presentation resources:

```powershell
$env:APPDATA = "$PWD\.godot\complete_smoke_appdata"
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --headless --path . --scene res://tools/complete_game_smoke.tscn
```

Expected result:

```text
COMPLETE_GAME_SMOKE: PASS
```

Focused contracts cover crafting, crafted effects, route combinations, NPC population, Trace Anchors, animation, touch controls, the Railhome shelter, world layout/collision, all nineteen building identities and the main interface surfaces. Normal maps are deterministic and can be checked separately after installing Pillow and NumPy:

```powershell
python tools/generate_normal_maps.py --check
```

Pull requests run the import, contract and Web-export checks. The eight cinematic masters stay at full resolution, while Godot applies a visually conservative Web texture import that keeps the current package at roughly 59 MiB. CI rejects a PCK over 64 MiB or a complete browser artifact over 100 MiB. Pushes to `main` also publish the verified artifact through GitHub Pages.

## Known limitations

- Keyboard and mouse remain the most extensively tested controls. The touch layout has deterministic size and overlap checks, but still needs hands-on testing across more Android and iOS browsers.
- Finished controller support is not included yet.
- The Web build requires WebGL 2; browser or driver settings can still stop it from starting.
- Locomotion now has complete directional coverage, but some combat actions have fewer unique frames.
- Music and effects are synthesised in-engine. There is no recorded voice work or live-performed score.
- Browser saves and touch preferences can be lost when site data is cleared or private browsing ends.
- The canvas game has keyboard and reduced-effects work, but has not had a manual screen-reader audit.
- Route balance, combat difficulty and total playtime still need wider external playtesting.

## Development notes

I used AI-assisted coding and image-generation tools during development, including for prototype source sheets, parts of the runtime world system and some automated checks. I revised the output in the project, kept source/processed asset provenance documented and validated the finished paths in Godot and the exported browser build. The repository does not present generated images as hand-drawn work.

## Next

- Run timed external playtests and tune route, encounter and resource pacing from the results
- Test the responsive touch layout on a broader set of real phones and tablets
- Expand combat reactions and action frames to match the locomotion coverage
- Finish controller support and a broader accessibility pass
- Evaluate recorded voice work and a live-performed or commissioned score

## Licence

Built and maintained by Jamie Parr using Godot 4.7. Code and project documentation are available under the [MIT License](LICENSE); image provenance and processing notes are separate in [ASSET_CREDITS.md](ASSET_CREDITS.md).

Project history is in [CHANGELOG.md](CHANGELOG.md). Contributions are covered by [CONTRIBUTING.md](CONTRIBUTING.md), and bugs can be reported through [GitHub Issues](https://github.com/JamieP-205/the-world-forgot-us/issues).
