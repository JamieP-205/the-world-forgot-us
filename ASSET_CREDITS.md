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

The July 2026 production pass used the built-in OpenAI image-generation tool for these project-specific additions:

- [`assets/source/generated/player_walk_v2/`](assets/source/generated/player_walk_v2/) contains the green-screen source for Ellie's sixteen-frame, four-direction walk cycle. Existing player views were supplied as identity and style references.
- [`assets/source/generated/environment_landmarks_v2/`](assets/source/generated/environment_landmarks_v2/) contains green-screen source art for the Bellwether civic ruin, Long Acre relay station and Tollard Exchange ruin. Existing environment props were supplied as style and camera references.
- [`assets/source/generated/characters/npc_identity/`](assets/source/generated/characters/npc_identity/) contains flat-magenta masters for Leena, Owen, Gwen, Idris, Mara, Tom, Nia and the Maggie/Continuity presence, plus the static Maggie cutting discovery. Imogen and Rafi's existing sheets were supplied as style and atlas-layout references only.
- [`assets/generated/npcs/`](assets/generated/npcs/) contains the transparent runtime derivatives and the earlier distinct Imogen and Rafi atlases. The eight new character sheets each contain sixteen authored views: down, up, left and right with four locomotion phases per direction.
- [`assets/source/generated/characters/enemy_walk_rebuild/`](assets/source/generated/characters/enemy_walk_rebuild/) contains six green-screen, sixteen-frame directional locomotion atlases: Hollow, Mimic Stalker, Signal Leech, Relay Husk, Static Wraith and Choir Warden.
- [`assets/source/generated/item_icons/`](assets/source/generated/item_icons/) contains the green-screen twelve-item crafting atlas.
- [`assets/source/generated/environment/`](assets/source/generated/environment/) contains the Railhome depot/carriage exterior used at Cullbrook.
- [`assets/source/generated/trace_anchors/`](assets/source/generated/trace_anchors/) contains the handset/photograph Trace Anchor and its separate aligned afterimage source.
- [`assets/source/generated/interiors/`](assets/source/generated/interiors/) contains the flat-magenta source atlas for nineteen building-specific interior hero props and one spare emergency-store cluster.
- [`assets/processed/cinematic_rebuild/`](assets/processed/cinematic_rebuild/) contains eight generated full-frame opening illustrations. These are recorded here as generated outputs even though they do not need a chroma-key processing stage.

The prompts requested top-down three-quarter painterly art, continuity with the supplied project references, isolated assets, no interface elements, and either a flat chroma-key background or transparency. No external stock art was introduced in this pass.

## Processed game images

Most PNGs under [`assets/processed/`](assets/processed/) are derivatives prepared for the Godot project rather than separate source artwork.

- [`tools/chroma_extract_assets.py`](tools/chroma_extract_assets.py) removes the green background from generated sheets, despills their edges, detects individual objects and writes transparent prop, icon and effect images.
- [`tools/make_ground_decals.py`](tools/make_ground_decals.py) turns opaque ground-tile slices into feathered decals.
- [`tools/generate_normal_maps.py`](tools/generate_normal_maps.py) derives deterministic tangent-space normal maps from processed art using alpha-weighted luminance. These are generated lighting data, not artist-authored height maps.
- [`assets/processed/player_walk_v2/`](assets/processed/player_walk_v2/) and [`assets/processed/environment_landmarks_v2/`](assets/processed/environment_landmarks_v2/) are transparent derivatives extracted from the July 2026 green-screen sources with the local chroma-key helper, soft matte and edge despill. Landmark normals live under [`assets/processed/normals/environment_landmarks_v2/`](assets/processed/normals/environment_landmarks_v2/).
- [`assets/processed/enemy_walk_rebuild/`](assets/processed/enemy_walk_rebuild/), [`assets/processed/item_icons_rebuild/`](assets/processed/item_icons_rebuild/), [`assets/processed/environment_rebuild/`](assets/processed/environment_rebuild/), [`assets/processed/trace_anchors/`](assets/processed/trace_anchors/) and [`assets/processed/interior_identity/`](assets/processed/interior_identity/) are transparent derivatives from the new chroma-screen sources. The Trace Anchor afterimage was separately keyed from black.
- [`assets/generated/npcs/*_walk.png`](assets/generated/npcs/) and [`assets/generated/npcs/maggie_cutting_body.png`](assets/generated/npcs/maggie_cutting_body.png) were keyed from the NPC identity masters with a soft alpha matte and edge despill. Each named profile binds its own atlas directly; no runtime palette swap or procedural costume overlay creates character identity.
- [`tools/install_enemy_walk_atlases.gd`](tools/install_enemy_walk_atlases.gd) slices the six enemy atlases into four rows and four locomotion frames while retaining each scene's existing combat actions.
- [`assets/processed/normals/`](assets/processed/normals/) contains deterministic normal derivatives for the current character, building, prop, Trace Anchor and cinematic-adjacent game art covered by the lighting pipeline.
- [`tools/gen_player_placeholder_sheet.py`](tools/gen_player_placeholder_sheet.py) and [`tools/gen_hollow_placeholder_sheet.py`](tools/gen_hollow_placeholder_sheet.py) create fallback top-down blockout sheets with Pillow drawing commands. The live player and Hollow scenes now use the processed painted concept art through `resources/spriteframes/*_painted_spriteframes.tres`; the scripted sheets remain as documented fallbacks.

The character placeholder directories contain their own format notes:

- [`assets/processed/player_topdown/README_PLACEHOLDER.md`](assets/processed/player_topdown/README_PLACEHOLDER.md)
- [`assets/processed/hollow_topdown/README_PLACEHOLDER.md`](assets/processed/hollow_topdown/README_PLACEHOLDER.md)

Those fallback sheets are functional animation stand-ins and are not described as final character art. The painted concepts are also prototype generated assets rather than a claim of hand-drawn final art.

## Code-drawn visuals and icon

Several visuals are assembled directly in Godot from polygons, particles, gradients, shaders and runtime lights. This includes much of the world geometry, interaction markers, Trace Receiver sweeps, shadows and the full-screen colour treatment. They do not come from an external art pack.

[`icon.svg`](icon.svg) is a simple project-specific vector made from rectangles and circles. The interface itself is primarily Godot controls and authored theme resources; the generated UI sheet remains a reference/source asset rather than a claim of a hand-drawn interface.

## Audio

There are no imported music or sound-effect files in the current project tree. [`scripts/systems/audio_manager.gd`](scripts/systems/audio_manager.gd) synthesises region-specific music, threat and night layers, ambience, footsteps, combat feedback and interaction cues in-engine at runtime.

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
