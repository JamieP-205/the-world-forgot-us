# Contributing

Thanks for helping improve **The World Forgot Us**.

## Workflow

1. Create a focused branch from the default branch.
2. Keep each change tied to the game's core loop: memory, survival, exploration, or rebuilding the Railhome.
3. Run Godot's headless parser and the complete campaign smoke test.
4. Include before/after screenshots for visual changes and describe save compatibility for progression changes.
5. Open a pull request using the repository template.

## Project rules

- Use Godot 4.7 and GDScript.
- Keep Web compatibility: the project uses the Compatibility renderer and a single-threaded Web export.
- Preserve stable persistence IDs on placed loot, echoes, enemies, and story interactions.
- Do not commit `.godot/`, exported binaries, local saves, credentials, or downloaded templates.
- Add authored data as resources where possible; avoid hard-coding item and echo data into UI code.
- New visual systems must remain readable under the cold/cyan/amber lighting palette.

## Validation

```powershell
godot --headless --editor --path . --quit
$env:APPDATA = "$PWD\.godot\complete_smoke_appdata"
godot --headless --path . --scene res://tools/complete_game_smoke.tscn
```

The smoke test must print `COMPLETE_GAME_SMOKE: PASS`.
