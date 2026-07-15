# Changelog

This project has not reached a stable 1.0 release. The entries below describe public development milestones rather than promises of API, save-format or content stability.

## Unreleased

### Production overhaul

- Added a four-direction, sixteen-frame player walk cycle with timed footstep sounds.
- Rebuilt the later areas around readable roads, thresholds, sign clusters, gameplay pockets and region-specific landmark art for Bellwether, Long Acre and Tollard.
- Replaced visible blockout cards and coloured building shapes with processed environment art, matching generated normal maps and cleaner occlusion.
- Added a persistent seven-minute day/night cycle with region-aware colour grading, practical-light changes and enemy night behaviours.
- Added Imogen and Rafi as physical NPCs, branching field assignments, a road-record investigation, an east-line defence and a persistent south-line rerouting puzzle.
- Added Signal Leech ranged-denial enemies and Mimic Stalker ambushers with distinct scanner and night responses.
- Strengthened the opening mystery, campaign objectives and ending consequences around the impossible 02:03 transmission.
- Added a six-beat opening cinematic, compact HUD, schematic field map and persistent audio, display and accessibility settings.
- Replaced the single ambient bed with region-, threat- and night-aware procedural scores, footsteps and an expanded sound-effect set.
- Expanded deterministic smoke coverage for NPCs, quests, puzzles, defence waves, enemies, settings and presentation resources.

### Story and content

- Reworked the campaign around Ellie Ward, Maggie Ward, Rafi Sayeed and the failed Common Warning Network.
- Renamed the four areas to Cullbrook Services, Ashmere Estate, Wrenfield Relay Station and Tollard Exchange.
- Expanded the archive from five broad memory summaries to ten shorter traces with concrete witnesses and records.
- Added the optional Rafi radio link and analogue public repeater to the requirements for The Long Repair ending.
- Rewrote objectives, interaction copy, item descriptions and endings in a more direct, grounded voice.

### World and presentation

- Expanded the later maps with additional routes, optional trace locations and less symmetrical encounter layouts.
- Refined the HUD, menus, dialogue and archive presentation so the game view carries more of the screen.
- Rebalanced the normal-mapped lighting, shadow occluders and post-process treatment.
- Added a shared ash/asphalt environment texture and matching generated normal map.

### Verification and documentation

- Extended the deterministic smoke test to cover the ten-trace archive and runtime lighting paths.
- Rewrote the README around the current prototype rather than presenting it as a finished release.
- Added explicit generated/processed asset provenance and a repository line-ending policy.
- Removed internal pass reports, prompt packs, tester handoffs and cloud-conflict snapshots from the public source tree.
- Updated the Pages workflow to verify exact Web artifacts and documented the required one-time Pages source selection.

## First Web build - 2026-07-11

- Expanded the original road-and-carriage vertical slice into a four-area playable campaign.
- Added directional melee, dodge, Trace Receiver sweeps, receiver discharge, two shielded boss encounters and three ending routes.
- Added the trace archive, campaign objectives, dialogue, local saving and the ending screen.
- Added real-time 2D lights, generated normal maps, shadow occluders and procedural audio.
- Added a single-threaded Godot Web export, deterministic campaign smoke test and GitHub Pages deployment workflow.
