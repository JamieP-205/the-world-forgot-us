# Changelog

This project has not reached a stable 1.0 release. These entries describe playable development milestones, not promises of save-format or content stability.

## Unreleased — 2026-07-16

### Story and campaign

- Rewrote the central mystery around the Common Warning Network, its 34,112 invented records and the uncertain Maggie-copy at Tollard.
- Expanded the campaign to twelve route combinations: four relationship anchors crossed with three shared Tollard operations — restore, mesh and sever — with anchor-specific assignments, modifiers and consequences rather than twelve separate finale spaces.
- Added twenty-four route-exclusive missions, fourteen corroborated revelations, persistent evidence confidence and an explorable aftermath.
- Added meaningful rescue, trace-sharing, Hollow-treatment and witness decisions that alter missions, access, allies, world state and ending details.
- Added ten in-world profiles — Imogen, Rafi, Leena, Owen, Gwen, Idris, Mara, Tom, Nia and Continuity — with distinct jobs, schedules, authored four-direction silhouettes and services that produce persistent gameplay effects.
- Expanded the narrative registry to twelve figures by including Ellie and the real Maggie, and tied Nia to the recoverable-Hollow decision.
- Moved Maggie's fate into play: her body and analogue recorder can be inspected in Wrenfield's flooded cutting before the Tollard operation.
- Rewrote the opening as eight illustrated shots and tightened objectives, dialogue and archive copy around one clear question at a time.
- Moved saves to schema version 4 with migration for older campaign files.

### World and exploration

- Rebuilt all four regional layouts around readable loops, landmark sightlines, surface changes, quiet approach spaces, side pockets and unlockable shortcuts.
- Added nineteen enterable locations with one to three authored rooms, real exterior doors, return points, evidence, caches, unique layouts, address-specific hero props and one restrained practical light per room.
- Replaced door props in empty ground with properly scaled building exteriors and separated usable entrances from visibly blocked ruins.
- Rebuilt Carriage 317 as a three-zone shelter with recovery, operations, workbench, radio, storage, living space and physical upgrade changes.
- Added a shared collision contract for building footprints, door gaps and prop feet, correcting invisible walls and walk-through scenery.
- Added broad navigation bearings by default, keeping exact waypoint behaviour behind a precise-bearing accessibility option.

### Player, enemies and crafting

- Replaced the player walk with a painted sixteen-frame, four-direction cycle and shared its turning, registration, phase and foot-placement rules across enemy controllers.
- Added unique sixteen-frame directional walk atlases for the Hollow, Mimic Stalker, Signal Leech, Relay Husk, Static Wraith and Choir Warden.
- Corrected player, enemy and building scale against one 68-pixel world unit.
- Added eighteen material/item definitions, twelve recipes, twelve painted crafted-item icons and a full workbench/notebook interface.
- Added crafted healing, stealth, trap, receiver, light, defence and traversal effects with route-aware unlocks and consequences.

### Trace Receiver

- Replaced the coloured crystal/shape sequence with ten physical Trace Anchors tied to phones, photographs, ledgers, route boards, cabinets and other ordinary evidence.
- Added detect, focus, reveal and verify stages, with distance, bearing, noise, practical edge light and aligned spatial afterimages.
- Added the decision to file a trace locally or feed it to the network; that choice now affects copy exposure, guidance and later story checks.
- Added structured evidence, contradiction and confidence records to the archive and save file.

### Interface, mobile and presentation

- Rebuilt the HUD, dialogue, crafting, Trace Receiver, title, map, archive, ending and controls surfaces around worn field documents and repaired equipment.
- Replaced generic headings and button copy with concise in-world language and added responsive narrow-screen stacking and scrolling.
- Rebuilt touch controls as worn, safe-edge pads for use, strike, sweep and step, with a compact field-kit tray for crafting, healing, map, traces and pause.
- Added portrait guidance, larger minimum hit areas, idle fading and overlap-safe desktop/portrait/landscape layouts.
- Added twelve-item crafting art, six enemy animation atlases, a Railhome exterior, Trace Anchor art, a nineteen-building interior atlas and eight full-screen opening frames.
- Expanded generated normal-map coverage to the rebuilt characters, shelter, interiors, Trace Anchors and environment assets.

### Audio and lighting

- Reworked procedural audio into five regional ambience profiles, a fourteen-channel priority pool and forty-one gameplay/interface cues.
- Added browser audio-context recovery for keyboard, pointer and touch input, clearer music/ambience levels, cue cooldowns and a safe master limiter.
- Kept each regional score and room tone through shared building interiors, with clean crossfade cancellation during fast travel.
- Added footsteps, doors, crafting, danger, dialogue, menu and Trace Anchor feedback.
- Preserved animation metadata while pairing animated atlases with normal maps and tightened practical-light/shadow limits.

### Verification and repository

- Added focused Godot contracts for crafting, recipe effects, narrative routes, NPC population, Trace Anchors, directional animation, touch controls, Carriage 317, world flow/collision, all nineteen interior identities and secondary interface layouts.
- Expanded the complete campaign smoke and normal-map checks, including raw Godot error gates.
- Updated the GitHub Pages workflow to import, run every contract, export and verify the browser artifact before deployment.
- Preserved the full-resolution cinematic masters while reducing their shipped texture payload by 63%, and added 64 MiB PCK / 100 MiB artifact budgets to catch Web-build regressions.
- Rewrote the README around the current campaign and updated generated/processed asset provenance.

## Production overhaul — 2026-07-14

- Added the first four-direction player walk cycle, footsteps and regional day/night presentation.
- Rebuilt major routes and landmarks across Ashmere, Wrenfield and Tollard.
- Added Imogen and Rafi, investigation/defence/escort/circuit activities, Signal Leeches and Mimic Stalkers.
- Added the first cinematic opening, persistent interface/settings and expanded procedural sound.
- Removed remaining coloured building cards and placeholder structures from the public campaign.

## First Web build — 2026-07-11

- Expanded the original road-and-carriage slice into a four-area campaign.
- Added directional combat, dodge, Trace Receiver sweeps, receiver discharge, shielded encounters and three early ending routes.
- Added the trace archive, objectives, dialogue, local saves and ending screen.
- Added real-time 2D lights, normal maps, shadow occluders and procedural audio.
- Added a single-threaded Godot Web export, deterministic campaign smoke and GitHub Pages deployment.
