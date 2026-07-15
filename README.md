# The World Forgot Us

[![Build and deploy Godot Web](https://github.com/JamieP-205/the-world-forgot-us/actions/workflows/pages.yml/badge.svg)](https://github.com/JamieP-205/the-world-forgot-us/actions/workflows/pages.yml)

**[Play the browser build](https://jamiep-205.github.io/the-world-forgot-us/)** — keyboard and mouse recommended.

A top-down Godot game set around a failed British civil-warning network. You play Ellie Ward, following recordings left by her sister through Cullbrook Services, Ashmere Estate, Wrenfield Relay Station and Tollard Exchange.

I started this as a small vertical slice while learning Godot. It has grown into a playable four-area campaign with saving, combat, upgrades, NPC assignments, environmental puzzles, optional records and three endings. It is still a personal project in active development, and its pacing and balance need external playtesting.

## Why I built it

I wanted the exploration, combat and story to depend on the same tool. The Trace Receiver reveals recordings in the environment, interrupts enemy shielding and helps Ellie work out which messages can be trusted. Back at Carriage 317, recovered parts repair the shortwave desk and open the road north.

The setting also gave me a useful technical problem to work through: campaign state has to survive scene changes, saves and a browser export without turning every map into a separate set of one-off systems.

## What is in it

- Four connected areas, from the service road at Cullbrook to the controls under Tollard Exchange
- Directional melee, a dodge, healing supplies, Trace Receiver sweeps, an unlockable receiver discharge and a four-direction walk cycle
- Ten recoverable traces, NPC assignments, a road-record investigation, a signal defence, a circuit rerouting puzzle and three ending routes
- Hollows, Linesmen, a Custodian, ranged Signal Leeches and ambushing Mimic Stalkers with night and scanner reactions
- A small base with a shortwave desk, receiver upgrades, lighting and a keepsake shelf
- Local save/load, death recovery, objectives, dialogue, an in-game trace archive and a schematic field map
- A short opening cinematic, a seven-minute day/night cycle, region-aware lighting and adaptive procedural music
- Persistent display, audio and accessibility settings, including reduced effects and day/night controls
- Authored landmarks, clearer routes, real-time 2D lights, generated normal maps and shadow occluders
- A single-threaded Web export preset with an automated GitHub Actions build and check pipeline

## The thing that shaped the code

Cullbrook is an authored Godot scene. The other three areas use a shared runtime builder so campaign rules stay consistent without copying the same placement code into several scenes. The builder now combines region-specific route grammar, structures, prop clusters, landmarks, quest pockets and lighting rather than repeating one generic blockout.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD or arrow keys |
| Interact / advance dialogue | E |
| Melee attack | J or left-click |
| Trace Receiver sweep | Q or right-click |
| Dodge | Space |
| Receiver discharge | R, after the Ashmere workshop repair |
| Use healing supplies | F |
| Open trace archive | I |
| Open field map | M |
| Pause | Esc |

The Trace Receiver reveals nearby traces and exposed enemies. Its sweep also interrupts the Linesman and Custodian shields for a short damage window.

## Files

- `scenes/` maps, player, enemies, world objects and UI
- `scripts/` gameplay, campaign state, saving, procedural audio and rendering
- `resources/` items, upgrades, traces and animation data
- `assets/source/generated/` source image sheets and concept references
- `assets/processed/` sliced props, painted character concepts, fallback sheets and normal maps used by the game
- `tools/` asset-processing scripts and the deterministic campaign smoke test
- `web/` the browser shell and Web-template installer

Asset origins and processing steps are listed in [ASSET_CREDITS.md](ASSET_CREDITS.md).

## Running it

The project currently targets [Godot 4.7](https://godotengine.org/). Open [project.godot](project.godot) and press **F5**, or run it from PowerShell:

```powershell
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --path .
```

The configured main scene is the title screen. Desktop saves use Godot's per-user `user://savegame.json`; browser saves stay in that browser's site storage.

## Building the Web version

The committed Web preset uses Godot's single-threaded browser template, so it can run from a normal static host without cross-origin isolation headers.

Install the official Godot 4.7 Web templates once:

```powershell
python web/install_godot_web_template.py `
  --archive-url "https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz" `
  --output-dir "$env:APPDATA\Godot\export_templates\4.7.stable" `
  --template web_nothreads_debug.zip `
  --template web_nothreads_release.zip
```

Export and serve the build:

```powershell
New-Item -ItemType Directory -Force builds\web
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "Web" "builds/web/index.html"
python -m http.server 8060 --bind 127.0.0.1 --directory builds\web
```

Then open <http://127.0.0.1:8060/> in a current browser with WebGL 2 and hardware acceleration enabled.

## Checks

The main deterministic check loads the required scenes and resources, walks the four campaign areas, verifies the persistent HUD and endings, and checks live normal-map, light and shadow-occluder setup.

```powershell
$env:APPDATA = "$PWD\.godot\complete_smoke_appdata"
& "C:\path\to\Godot_v4.7-stable_win64_console.exe" --headless --path . --scene res://tools/complete_game_smoke.tscn
```

Expected result:

```text
COMPLETE_GAME_SMOKE: PASS
```

Normal maps are deterministic and can be checked separately after installing Pillow and NumPy:

```powershell
python tools/generate_normal_maps.py --check
```

GitHub Pages is configured to deploy through GitHub Actions. The workflow's default `GITHUB_TOKEN` builds and publishes the browser release on each push to `main`.

Pushes to `main` verify generated normal maps, import the project, run the smoke test, export the Web build, check the expected HTML/JavaScript/WebAssembly/PCK files and then publish them through GitHub Pages.

## Known limitations

- Keyboard and mouse are the tested controls. There is no finished controller or touch layout.
- The Web build requires WebGL 2. Browser or driver settings can still prevent it from starting.
- Several source sheets were generated with image tools. The live walk cycle, characters and landmarks are production-pass prototypes, and combat action frames still have less variation than locomotion.
- Ashmere, Wrenfield and Tollard share a runtime construction system. Their routes and landmarks are now region-specific, but content density and navigation still need observation in external playtests.
- Music and sound effects are synthesised in-engine. There is no recorded voice work or live-performed score.
- Browser progress is one local save and can be lost when site data is cleared or private browsing ends.
- The launcher has keyboard and reduced-motion considerations, but the canvas game has not had a manual screen-reader accessibility pass.
- Campaign pacing, balance and playtime need more external playtesting before I would call this a finished release.

## AI-assisted development

I used AI tooling while working on parts of the campaign implementation, runtime map builder, lighting and normal-map pipeline, Web export and automated smoke tests. I also used image-generation tools for prototype source sheets. I revised the generated material, kept its provenance documented and tested the project through Godot's import, smoke-test and Web-export paths.

## Next

- Run timed external playtests and tune encounter, quest and travel pacing from the results
- Expand combat reactions and action animation to the same coverage as locomotion
- Add further NPC branches and optional discoveries without obscuring the main route
- Finish controller support and broader accessibility testing
- Evaluate recorded voice work and a commissioned or live-performed score

## Licence and project notes

Built and maintained by Jamie Parr using Godot 4.7. The code and project documentation are available under the [MIT License](LICENSE); image provenance and processing notes are separate in [ASSET_CREDITS.md](ASSET_CREDITS.md).

Project history is in [CHANGELOG.md](CHANGELOG.md). Contributions are covered by [CONTRIBUTING.md](CONTRIBUTING.md), and bugs can be reported through [GitHub Issues](https://github.com/JamieP-205/the-world-forgot-us/issues).
