# Asset credits and provenance

This project mixes generated source images, script-produced blockout art, processed derivatives, code-drawn visuals and procedural audio. This file records what the repository can prove about each category. It does not present generated work as hand-drawn art.

## Generated source images

The PNG sheets under [`assets/source/generated/`](assets/source/generated/) were made for this project with AI image-generation tools. They cover:

- the style-board reference
- player and enemy concept sheets
- road, petrol-station, loot-container and carriage props
- ground tiles and the seamless ash/asphalt texture
- item icons, effects, Trace Receiver effects and the UI reference sheet

The source sheets do not preserve reliable provider, model or generation-date metadata for every file. This record therefore stops at the information the repository can support rather than guessing missing details.

## Processed game images

Most PNGs under [`assets/processed/`](assets/processed/) are derivatives prepared for the Godot project rather than separate source artwork.

- [`tools/chroma_extract_assets.py`](tools/chroma_extract_assets.py) removes the green background from generated sheets, despills their edges, detects individual objects and writes transparent prop, icon and effect images.
- [`tools/make_ground_decals.py`](tools/make_ground_decals.py) turns opaque ground-tile slices into feathered decals.
- [`tools/generate_normal_maps.py`](tools/generate_normal_maps.py) derives deterministic tangent-space normal maps from processed art using alpha-weighted luminance. These are generated lighting data, not artist-authored height maps.
- [`tools/gen_player_placeholder_sheet.py`](tools/gen_player_placeholder_sheet.py) and [`tools/gen_hollow_placeholder_sheet.py`](tools/gen_hollow_placeholder_sheet.py) create fallback top-down blockout sheets with Pillow drawing commands. The live player and Hollow scenes now use the processed painted concept art through `resources/spriteframes/*_painted_spriteframes.tres`; the scripted sheets remain as documented fallbacks.

The character placeholder directories contain their own format notes:

- [`assets/processed/player_topdown/README_PLACEHOLDER.md`](assets/processed/player_topdown/README_PLACEHOLDER.md)
- [`assets/processed/hollow_topdown/README_PLACEHOLDER.md`](assets/processed/hollow_topdown/README_PLACEHOLDER.md)

Those fallback sheets are functional animation stand-ins and are not described as final character art. The painted concepts are also prototype generated assets rather than a claim of hand-drawn final art.

## Code-drawn visuals and icon

Several visuals are assembled directly in Godot from polygons, particles, gradients, shaders and runtime lights. This includes much of the world geometry, interaction markers, Trace Receiver sweeps, shadows and the full-screen colour treatment. They do not come from an external art pack.

[`icon.svg`](icon.svg) is a simple project-specific vector made from rectangles and circles. The interface itself is primarily Godot controls and authored theme resources; the generated UI sheet remains a reference/source asset rather than a claim of a hand-drawn interface.

## Audio

There are no imported music or sound-effect files in the current project tree. [`scripts/systems/audio_manager.gd`](scripts/systems/audio_manager.gd) synthesises the interaction cues, wind bed and drone in-engine at runtime.

## External software

- The game is built with [Godot Engine](https://godotengine.org/), distributed separately under its own MIT licence.
- The image-processing tools use Pillow and NumPy when run locally. Those packages are development dependencies and are not vendored as art assets here.

I did not find third-party stock-art or stock-audio packs in the current repository. If one is added later, its creator, source URL, licence and any required attribution should be recorded in this file before the asset is committed.

## Licence note

The repository [MIT License](LICENSE) covers the project software and accompanying documentation. Generated source images are included transparently as project assets, but I am not claiming they were drawn by hand or inventing copyright provenance that the repository does not contain. Anyone reusing those images separately should check the terms that applied to the generation tool and account used to create them.

For a new asset, record:

1. who made it or which tool generated it;
2. the original source file or URL;
3. the licence or generation terms;
4. what processing was applied;
5. where the game uses it.
