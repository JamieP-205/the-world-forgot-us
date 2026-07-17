# The World Forgot Us — art direction and asset manifest

Status: current release manifest and future production brief
Scope: art, animation, environment, Trace Anchors, cinematic and UI assets
Rule: sections 1-3 define the visual and scale contract used by the current build. Section 4 is an optional handoff contract for future stand-alone art batches. Section 5 separates the shipped runtime catalogue from later art targets. Asset origin and processing records remain in [ASSET_CREDITS.md](../ASSET_CREDITS.md).

## 1. Visual target

The game should feel like rain-soaked British roadside survival built from analogue civil-defence equipment. It is not clean science fiction. Horror comes from familiar things being copied slightly wrong.

### Visual pillars

1. Human evidence
   - Paper lists, cassettes, grease pencil, council signs, clinic labels, biscuit tins and worn personal effects.
   - Every important location needs evidence that a real person worked, waited or made a choice there.
   - Handwritten marks and repairs should be specific. Avoid random clutter.

2. Dead infrastructure
   - Wet asphalt, oxidised galvanised steel, soot, old concrete, painted timber, Bakelite, CRT glass and fabric cable.
   - Buildings need believable structure, thresholds and circulation. They must not read as props pasted onto blocks.
   - Working light is scarce. Sodium amber means human shelter or practical power.

3. Uncanny intrusion
   - Copied voices appear as misregistered silhouettes, delayed gestures, tape flutter, waveform errors and signs that almost agree.
   - Signal horror should alter a familiar object before adding glow.
   - Cyan is a system state, not general decoration.

### Palette

| Use | Colour | Hex | Rule |
|---|---|---:|---|
| Soot / deepest shadow | near-black green | #111715 | Main background and unlit recesses |
| Wet asphalt | blue-black grey | #202725 | Large ground fields |
| Old concrete | cold khaki grey | #77776A | Walls and road furniture |
| Galvanised metal | dull green-grey | #68726A | Cabinets, doors and relay hardware |
| Oxidised steel | brown rust | #754834 | Damage, fasteners and exposed structure |
| Paper / cloth | dirty warm ivory | #D2C6A5 | Notebook, labels and domestic relief |
| Human practical light | sodium amber | #D38A36 | Safe work, shelter and confirmed human action |
| Verified signal | restrained cyan | #58B8B8 | Scanner lock, verified evidence and active analogue line |
| Contradiction / threat | warning red | #B94D43 | False record, danger and irreversible loss |
| Clinic / living systems | muted green | #718A72 | Medicine, water and recoverable life |

Use roughly 70% neutral infrastructure, 20% warm human material and no more than 10% signal colour in a normal scene. Never light a whole room cyan. Red and cyan should not compete unless the scene is about a contradiction.

### Material rules

- Wear belongs on contact points, water lines, hinges, tyres and exposed edges.
- Do not apply equal dirt to every surface.
- Keep metal matte. Avoid glossy futuristic panels.
- Paper should curl, stain, tear and carry pin or tape marks.
- Generated signs and screens must be blank. All readable text is added in-engine.
- Cast shadows, wet reflections and light cones are separate layers. Do not bake them into reusable props.

## 2. Scale bible

P means Ellie's visible standing height from head to grounded foot.

- P = 68 world pixels.
- Canonical character authoring cell = 320 × 320 source pixels.
- Canonical character display scale = 0.235, giving a 75.2-world-pixel cell.
- Character artwork should occupy about 285–292 source pixels vertically, giving 67–69 world pixels in play.
- Ellie's current 18 × 22 world-pixel body collision remains the gameplay baseline. Visual scale must follow P, not the collision capsule.
- Camera validation baseline is the current 1.9 zoom at 1280 × 720. Also validate 16:9 mobile, 20:9 mobile and portrait fallback.

| Asset | Target relative to P | Approximate world size |
|---|---:|---:|
| Clear doorway | 0.55–0.70 P wide, 1.10–1.20 P high | 37–48 wide, 75–82 high |
| Interior corridor clear width | 1.5–2.0 P | 102–136 |
| Small usable room | at least 4 P × 5 P | 272 × 340 |
| Kiosk or service shed | 3–5 P wide, 2–3 P deep | 204–340 × 136–204 |
| Home, shop or relay hut | 6–9 P wide, 4–6 P deep | 408–612 × 272–408 |
| Clinic, school or major landmark | 10–18 P wide, 6–12 P deep | 680–1224 × 408–816 |
| Car | 2.4–3.0 P long | 163–204 |
| Bus | 5.5–7.0 P long | 374–476 |
| Workbench | 1.8–2.4 P wide | 122–163 |
| Bed or trolley | 1.8–2.2 P long | 122–150 |
| Waist-high cabinet | 0.75–1.0 P high | 51–68 |
| Small pickup | 0.20–0.35 P | 14–24 |

Scale rules:

- A normal intact door always implies an enterable building.
- A non-enterable structure must visibly be collapsed, flooded, burned out or sealed by physical damage.
- The collision footprint describes the ground contact only. Roofs, signs, awnings and upper walls do not enlarge it.
- At a hero-building approach, the camera must show the entrance, one route landmark and enough ground to turn away.
- Test every exterior with Ellie standing at its door. Test every room with two NPCs and one enemy-sized body in the same circulation path.

## 3. Character sprite-sheet contract

### Universal contract

- One PNG per character and action.
- Four direction rows in this exact order: down, up, left, right.
- Columns are chronological frames. No unused columns inside an action sheet.
- Cell size: 320 × 320 RGBA.
- Foot pivot: source pixel (160, 288) in every cell.
- Safe opaque area: x 40–280, y 16–294.
- The grounded foot may move no more than 3 source pixels from the pivot. Motion above the ankle can move freely.
- No root motion. Gameplay movement owns world position.
- No baked cast shadow, glow, weapon trail, dust or background.
- Do not mirror a direction after export. Left and right equipment details must remain correct.
- Keep costume, proportions, carried gear and palette identical across every action.
- Filename: char_character_action_4dir_fNN.png.
- Import animation: character/action/direction. Example: ellie/walk/left.
- Loop idle, walk, phase loop, drain loop and field loop. Other actions play once.
- Standard rates: idle 5 fps, walk 9 fps, deliberate NPC work 6 fps, combat 11 fps, death 8 fps.
- Player walk contacts are frames 2 and 6 of an eight-frame cycle. Enemy contacts are authored per species.

Each future replacement-art delivery also needs:

- one neutral turnaround sheet;
- one 1:1 pivot-overlay proof image;
- one contact-sheet GIF or video at final in-game scale;
- one metadata sidecar when that batch adopts the external handoff contract in section 4.

### Player — Ellie Ward

| Action | Frames per direction | Notes |
|---|---:|---|
| idle | 4 | Breathing and coat movement only; feet fixed |
| walk | 8 | Clear weight transfer; contacts at 2 and 6 |
| attack | 6 | Readable wind-up, contact and recovery |
| hurt | 4 | Directional recoil; no displacement |
| dodge | 6 | Low practical sidestep/roll; no teleport smear |
| scan_start | 5 | Receiver raised and coil engaged |
| scan_loop | 4 | Stable aiming pose with small needle/hand motion |
| scan_end | 4 | Receiver lowered without costume jump |
| interact | 4 | Reach/use pose for doors, switches and containers |
| consume | 4 | Bandage or ration action; readable at game scale |
| death | 8 | Grounded collapse, no graphic gore |

All player actions must use the same model and scale. The current split between player_painted_spriteframes and player_walk_v2 is not a production pattern.

### Enemy species

Each enemy gets its own silhouette, movement rhythm and signal reaction. None may reuse the Hollow sheet with a tint.

| Species | Required four-direction actions and frame counts | Visual read |
|---|---|---|
| Hollow | idle 4; shamble 8; attack 6; hit 3; death 8; scan_react 4 | Human work clothes pulled by a repeated instruction; uneven but grounded gait |
| Static Wraith | idle 6; drift 8; phase_in 6; phase_out 6; attack 8; hit 4; death 10; scan_exposed 6 | Thin duplicated silhouette with delayed coat/limb registration; no generic ghost robe |
| Mimic Stalker | idle 4; stalk 8; lunge 8; disguise_shift 6; hit 4; death 8; scan_reveal 6 | Almost-human roadside survivor whose proportions become wrong during motion |
| Signal Leech | idle 6; crawl 8; latch 6; drain_loop 6; detach 4; hit 3; death 8; scan_recoil 4 | Low cable-and-flesh parasite built around a receiver or speaker carcass |
| Linesman / Relay Husk | idle 4; stride 8; cable_swing 8; overload 8; hit 4; death 10; shield_loop 4; scan_break 6 | Heavy former utility worker; insulated coat, line hook and energised cable field |
| Custodian / Choir Warden | idle 6; stride 8; archive_slam 8; voice_cast 8; hit 4; death 12; field_loop 6; scan_break 8 | Tall exchange custodian fused with printer, headset and manual-control hardware |

Enemy size bands:

- Hollow, Wraith and Mimic: 0.95–1.15 P.
- Leech: 0.35–0.55 P high and 0.9–1.3 P long.
- Linesman: 1.35–1.55 P.
- Custodian: 1.7–2.0 P.

Larger enemies use larger authoring cells only when their art cannot fit the universal safe area. If enlarged, use 480 × 480 with foot pivot (240, 432) and keep the same world-P target.

### NPCs

The current recurring cast uses one square 4 × 4 runtime atlas per person: down, up, left and right rows, with four grounded locomotion phases in each row. Character identity must live in the painted atlas. Runtime palette swaps, generic body-family reuse and polygon costume overlays are not accepted for named characters.

Silhouettes must still separate at low saturation: Imogen's hood and medical satchel; Rafi's heavy radio coat; Leena's long registrar coat and ledger case; Owen's hard cap and cable coil; Gwen's broad driver coat and route roll; Idris's cross-back carpenter harness; Mara's asymmetric key wrap; Tom's hat and oilskin; Nia's high locs and climbing harness; Continuity's broken engineer-coat edges.

Core set for every recurring NPC:

| Action | Frames per direction | Notes |
|---|---:|---|
| idle | 4 | Quiet, grounded breathing |
| walk | 8 | Same foot-pivot contract as Ellie |
| talk | 4 | One restrained hand/face gesture loop |
| work | 6 | Character-specific practical job |
| startled | 4 | Used by horror and combat entrances |
| hurt | 4 | Non-combatant response |
| sit_down | 6 | Transition into base furniture |
| sit_idle | 4 | Persistent base routine |
| stand_up | 6 | Reverse transition authored cleanly |

Named signature work actions:

- Imogen: check pulse, write patient label, tend oxygen trolley.
- Rafi: tune receiver, key microphone, repair pump/fuse.
- Leena: pin list, compare papers, mark an entry uncertain.
- Owen: test relay, pull breaker, inspect service panel.
- Doyle survivor: load crate, check vehicle, unfold route sheet.
- Nia: set tripwire, tune carrier lure, inspect Hollow tracks.
- Idris: brace bunk, square timber, repair ventilation.
- Mara: cut key, file bypass, tag a sealed cache.
- Tom: string dark wool, dull a bell, read a track.
- Continuity/Maggie-copy: checksum pause, signal break, borrowed-memory recoil.

Portraits are separate 768 × 768 busts: neutral, guarded, alarmed, angry, relieved and exhausted. Keep the same costume and age as the world sprite.

### Animation acceptance

- Overlay all frames at 50% opacity. Feet and centre mass must not drift between cells.
- Test every direction at final scale against a stationary grid and collision capsule.
- No frame may touch a cell edge.
- Alpha fringe must be neutral, not green.
- A direction must be recognisable from silhouette alone.
- Hit and attack animations cannot be interrupted visually by an idle frame unless the state machine intentionally cancels them.

## 4. Future external-asset metadata contract

The current build does not load `.asset.json` sidecars. Its scale, entrances, interaction areas and foot-plane collision are authored in Godot scenes and the runtime catalogues, then checked by deterministic contracts. Use this sidecar schema for a future commissioned or stand-alone replacement batch when source-pixel geometry must travel independently of a scene. It is a handoff target, not a missing release dependency.

For a batch that adopts this contract, each solid prop, exterior, interior shell, door, container or large set piece gets a sidecar named `asset_id.asset.json` beside its source texture.

Required schema:

    {
      "asset_id": "ashmere_clinic_exterior",
      "texture": "ashmere_clinic_exterior.png",
      "category": "building_exterior",
      "source_master": "source/generated/environment/ashmere_clinic_master.png",
      "display_scale": [0.235, 0.235],
      "pivot_px": [1024, 1790],
      "depth_sort_origin_px": [1024, 1790],
      "collision_polygons_px": [
        [[410, 1640], [1630, 1640], [1710, 1840], [330, 1840]]
      ],
      "occluder_polygons_px": [
        [[280, 280], [1760, 280], [1760, 1650], [280, 1650]]
      ],
      "interaction_zones_px": [
        {"id": "front_door", "shape": "rect", "rect": [900, 1720, 240, 180]}
      ],
      "entrances": [
        {"id": "front_door", "anchor_px": [1020, 1800], "facing": "down"}
      ],
      "alpha_padding_px": 8,
      "variant_ids": ["intact", "storm_damaged", "entered"],
      "provenance_id": "gen_2026_ashmere_clinic_01"
    }

Rules:

- Coordinates are source-texture pixels before display scale.
- Pivot and depth-sort origin normally sit at the centre of the visible ground-contact edge.
- Collision covers solid material at foot height only. Never trace roof alpha.
- Occluders cover walls, roof and tall foreground material that should fade or mask actors.
- Interaction zones are not collision. Keep door, loot and story triggers separate.
- An open doorway removes collision across its clear width.
- Trim to 8 transparent pixels only after recording the untrimmed pivot. The processing tool must offset metadata during trim.
- Collision may sit no more than 3 displayed pixels outside visible grounded material.
- Acceptance review should include a debug capture showing texture, pivot, collision, occluder and interaction zones in different colours. The capture is QA evidence, not a shipped runtime file.
- Provenance ID must resolve to tool, prompt, references, generation date and processing steps in the asset log.

## 5. Current runtime catalogue and future targets

### Implemented in the current build

| Runtime path | Current use |
|---|---|
| `assets/processed/player_walk_v2/` | Registered four-direction Ellie locomotion used by the live SpriteFrames resource |
| `assets/processed/enemy_walk_rebuild/` | Six distinct four-direction enemy locomotion atlases |
| `assets/generated/npcs/*.png` | Ten world-profile identities plus Maggie's flooded-cutting discovery art, each with its own source image and silhouette |
| `assets/processed/environment_rebuild/` | Carriage 317 / Railhome exterior art |
| `assets/processed/interior_identity/` | Identity atlas used to distinguish all nineteen enterable locations and their one-to-three-room layouts |
| `assets/processed/trace_anchors/`, `scanner_memory_effects/` and `effects_pack_01/` | Physical evidence and layered detect, focus, reveal and verification treatment |
| `assets/processed/cinematic_rebuild/` | Eight full-screen illustrated opening frames |
| `assets/processed/item_icons_rebuild/` | Twelve crafted-output icons used by the notebook workbench |
| `assets/processed/roadside_props/`, `petrol_station_props/`, `railhome_props/` and `loot_containers/` | Runtime environment dressing and readable interaction props |
| `assets/processed/normals/` | Deterministic normal maps paired with the rebuilt characters, shelter, interiors, evidence and environment art |

Runtime composition is deliberately data-driven. `scripts/world/building_catalog.gd`, `scripts/world/world_layout_contract.gd`, the interior scenes and `scripts/maps/campaign_level_builder.gd` own building identity, room count, placement, entrances, interaction zones and collision. Character profiles and their visual paths live in `resources/npcs/` and `scripts/npcs/world_npc_catalog.gd`. Those are the release contracts; the optional sidecar design above is for art that needs to move outside them.

### Future art targets beyond this release

These are expansion or commissioning targets, not unimplemented requirements for the current playable build.

1. Broader bespoke attack, hurt, dodge, interaction and death coverage to match the finished locomotion standard.
2. Named-character portraits and service/work animation sets beyond the current unique four-direction identities.
3. Hand-authored refinements for remaining modular exterior and prop combinations without changing their working doors or collision.
4. Separate foreground, rain and interference layers for the eight opening frames; the current release uses complete stills.
5. A licensed bespoke type family, evidence thumbnails and a larger native 9-slice component library beyond the current document-and-instrument interface.
6. A commissioned mobile icon/state set, including a dedicated left-handed visual pass, beyond the current responsive control surfaces.
7. The optional sidecar and automated overlay-capture pipeline in section 4 for future independent asset deliveries.
8. Recorded voice and performed or commissioned music if the project later moves beyond its current in-engine audio direction.

## 6. Exterior, interior and hero-prop batches

### Exterior batches

| Batch | Deliverables | Entry rule |
|---|---|---|
| E00 — modular shell | Brick, concrete, timber and corrugated wall runs; corners; roof edges; gutters; windows; 4 door families; boarded, collapsed, burned and flooded blockers | Base kit for all locations |
| E01 — Carriage 317 | Full rail-maintenance depot shell, carriage exterior, track bed, service platform, workshop lean-to, perimeter gate, rail trolley travel exit | Carriage and depot both read as one home |
| E02 — Cullbrook | Petrol office/café, roadside kiosk, north and south service bays, maintenance shed, public-phone shelter | All intact doors enter |
| E03 — Ashmere | Clinic and annex, Bellwether school and hall, Maggie's workshop/cellar, 3 terrace-home variants, bus-depot office | Major buildings get 3 rooms; homes 1–2 |
| E04 — Wrenfield | West cable house, repeater shelter, east antenna bunker, south generator hall, control shed, 2 transformer-house variants | Each relay arm has a unique silhouette |
| E05 — Tollard | Exchange exterior, loading entrance, archive wing, operations wing, battery/service entrance, gantry approach | Exterior must communicate at least 3 final approaches |

Do not reuse one landmark texture as two named buildings. Reuse modular materials and construction language, not the full silhouette.

### Interior kit

Build rooms in Godot from modular assets. Do not generate a finished room as one flattened image.

Required kit:

- 64-world-pixel floor modules with asphalt, linoleum, tile, timber, concrete and steel plate.
- 64, 128 and 256-world-pixel wall runs with matching corners and end caps.
- Door states: closed, opening, open, blocked and broken.
- Window states: intact dirty, cracked, boarded and missing.
- Roof/foreground overlays with occluder masks and fade variants.
- Stairs, ramps, thresholds, drains, cable channels and skirting.
- Lighting fixtures as separate unlit art: bulb cage, fluorescent strip, sodium lamp, emergency beacon and desk lamp.
- Furniture families: domestic, clinic, school, workshop, relay, archive and depot.
- Wet, soot, dust, paper and signal-distortion decals.

### Room plans

| Building | Rooms |
|---|---|
| Carriage 317 | Living/sleeping bay; receiver/workbench bay; stores/infirmary bay. Depot apron and vestibule remain explorable |
| Cullbrook café/office | Public counter; staff office/store |
| Kiosk or shed | One strong room |
| Service bays | Workshop floor; parts cage |
| Clinic | Reception/triage; treatment/oxygen; records/pharmacy |
| School | Assembly/classroom; caretaker/radio room; shelter/store |
| Maggie's workshop | Main bench; parts room; cellar |
| Terrace home | Front room; bedroom/kitchen variant |
| Bus depot | Ticket office; lost property |
| Cable house | Cable floor; verification desk |
| Repeater shelter | Transmitter room; Rafi's living/work corner |
| Antenna bunker | Entry/defence room; carrier room |
| Generator hall | Machine floor; switch room; service store |
| Tollard Exchange | Reception; archives; operations; battery/service tunnels; incident control. These may be connected as multiple 1–3-room scene units |

### Hero-prop batch

| Location | Hero props |
|---|---|
| Carriage 317 | Trace Receiver, Maggie cassette case, Ward photo, kettle, keepsake shelf, hand-repaired radio desk |
| Cullbrook | Dead payphone, service receipt spike, unplugged café radio, mast service handset |
| Clinic | Oxygen trolley, handwritten patient ledger, stripped label printer, medicine fridge |
| School | Nine-ray lunch tin, attendance board, caretaker radio, improvised aerial controls |
| Maggie's workshop | Red-lead modification, grease-marked service ledger, fuse drawer, Wrenfield key case |
| Bus depot | Gwen Doyle logbook, ticket punch, route-board mechanism, lost-property cage |
| Wrenfield cable house | Contradictory road cards, line-seven headset, cable verification desk |
| Rafi's repeater | Analogue weather cards, microphone, thermos/mug, local fuse carrier |
| Generator hall | FEED/GROUND/CARRIER switch bank, route card, oil cabinet |
| Tollard | Incident 44 printer, blank identity forms, manual battery breakers, voice-generator drum, Maggie's isolated transmitter |

Hero props need closed/used/broken or before/after states where player action changes them. Text surfaces remain blank in generated art and receive authored overlays.

## 7. Trace Anchor asset set

The crystal and generic hex halo are retired. The original object remains in the world after filing a trace.

| Trace ID | Physical anchor | Spatial reveal | Practical meaning |
|---|---|---|---|
| echo_last_signal | Cracked mast handset with folded Ward photo inside | Maggie and child-hand silhouettes split from a false safe-record waveform | Establishes the impossible record |
| echo_sun_lid | Dented lunch tin with a hand-painted nine-ray sun | Child hand, inhaler and Maggie's ordinary kitchen gesture | Verifies a private test phrase |
| echo_mara_repair | Grease-marked service ledger, clinic fuse and tin locket | Maggie borrowing the fuse and marking job 6142 | Opens a technical route/check |
| echo_clinic_triage | Torn labels, wristbands and handwritten patient ledger | Leena rejecting printer names and writing UNKNOWN | Teaches human witness verification |
| echo_bus_ledger | Driver logbook, ticket punch and bus key | Gwen crossing out Tollard while children move toward the school | Proves physical route contradiction |
| echo_driver_call | Line-seven headset and damaged call reel | Two wife-voice silhouettes point to different junctions | Teaches copied voice conflict |
| echo_relay_warning | Weather card, microphone and fuse carrier | Rafi repeats a plain forecast while personalised routing falls away | Proves safe analogue use |
| echo_names_wall | Pinned paper list, pencil and drawing pins | Several witnesses refuse/correct names; Ellie's line remains unconfirmed | Builds the witness-chain route |
| echo_first_tone | Incident 44 printout in a dot-matrix tray | 02:03 and 02:17 waveforms overlap; a Maggie-shaped copy appears early | Reveals Continuity pre-activation |
| echo_maggie_final | Isolated transmitter handset, red lead and manual key | Maggie at the breaker door; copied Maggie remains at the console | Separates the real final call from the copy |

Shared Trace effect stack:

1. Detect
   - Directional receiver needle animation.
   - Local dust, paper or hanging cable aligns toward the anchor.
   - Low-opacity scanner pulse using the existing ring as a base.

2. Focus
   - Two or three offset signal contours.
   - Object-specific highlight only at contact edges.
   - Confidence/noise state shown on the Receiver UI.

3. Reveal
   - One foreground silhouette layer.
   - One midground action layer.
   - One environmental-change mask aligned to the room.
   - Optional contradictory silhouette in warning red.

4. File
   - Reveal collapses into a monochrome trace-print thumbnail.
   - Warm paper flecks and short amber confirmation, not a loot explosion.
   - Physical object remains, visibly spent or labelled.

5. Corrupt
   - Misregistration, frame delay, wrong-direction eye/head turn and brief copied gesture.
   - Do not use every time. Escalate across the campaign.

Required effect files:

- trace_detect_pulse.png
- trace_focus_contours.png
- trace_verified_collapse.png
- trace_contradiction_split.png
- trace_paper_flecks.png
- trace_signal_dust.png
- trace_afterimage_mask_[trace_id].png
- trace_thumbnail_[trace_id].png

## 8. Opening cinematic stills

Format:

- 2560 × 1440, 16:9, full bleed.
- No text, logos, interface, subtitles or watermark.
- Keep the bottom 28% clear enough for optional subtitles.
- Deliver background, midground and foreground layers when parallax is listed.
- Deliver a clean still and one separate interference mask.
- Match the in-game top-down painterly texture and palette, but use a cinematic camera.

| ID | Still | Composition and motion |
|---|---|---|
| CIN01 | Receiver and family photo | Macro: rain-streaked Ward photo beside dormant Receiver; waveform glow crosses Maggie's face. Slow push in |
| CIN02 | Same switch, two times | Match composition: young Ellie's hand at a warning switch and adult Ellie's hand repairing the Receiver. Two-layer dissolve |
| CIN03 | Carriage 317 depot | Wide dawn exterior: real carriage inside derelict maintenance depot; Ellie small; fallen mast distant. Rain foreground parallax |
| CIN04 | Blank Night fragments | Evacuation queue and contradictory road lights; Maggie grips Ellie's red sleeve. Red sleeve is the only stable warm element |
| CIN05 | Dead café phone | Empty service café seen through wet glass; payphone rings under one amber lamp. Slow lateral move |
| CIN06 | The other Ellie | A silhouette inside raises the receiver while Ellie is visible outside. Lights fail from back to front |
| CIN07 | False safe print | Receiver ejects a blank paper strip while Ellie watches. Add the authored safe-record text in-engine, never in the image |
| CIN08 | Playable three-way choice | Depot threshold at first light: phone east, mast sparks west, human movement north. Camera settles into the gameplay angle |

The first playable frame must match CIN08 closely enough that control handoff feels continuous.

## 9. Receiver and field-notebook UI

### Core metaphor

- Receiver hardware shows live system state: gain, channel, heat, confidence and direction.
- Field notebook holds human interpretation: objectives, map, witnesses, recipes and deductions.
- Archive pages combine object photo, time, source class and player conclusion.
- Avoid generic holograms, floating neon rectangles and uniform all-caps copy.

### Typography

Use two licence-recorded font families plus one small accent:

- Condensed grotesk for headings and route labels.
- Legible typewriter/monospace for records, times and technical values.
- Handwritten accent only for Maggie, Ellie and witness marks.

Normal body copy uses sentence case. All-caps is reserved for stamped status, danger and hardware labels. Fonts must be included with licence and source records. Do not generate text as image.

### Native UI asset kit

Build screens from native Godot controls with 9-slice textures.

Required assets:

- ui_receiver_bezel_9slice.png
- ui_notebook_page_9slice.png
- ui_taped_note_9slice.png
- ui_metal_tab_9slice.png
- ui_choice_strip_9slice.png
- ui_tooltip_9slice.png
- ui_inventory_slot_9slice.png
- ui_recipe_card_9slice.png
- ui_signal_meter_fill.png
- ui_signal_noise_mask.png
- ui_divider_torn_paper.png
- ui_cursor_receiver_needle.png
- ui_checkbox_pencil_[empty,marked,uncertain].png
- ui_source_[physical,witness,system,contradiction].png

Every component needs idle, hover/focus, pressed/selected and disabled states. Focus state must work without colour alone.

### Screen treatment

- HUD: health, Receiver charge and one current objective only. Keep most of the world visible.
- Dialogue: portrait/evidence thumbnail, speaker line, body copy and choice strips. The selected choice gets a short response beat before the card closes.
- Map: folded local route page with stable landmarks, surface/material cues and player annotations. Do not show exact GPS position.
- Archive: trace thumbnail, physical/witness/system sources, confidence, contradictions and deductions.
- Crafting: bench photo, recipe card, required tools, ingredients, output and one clear craft action. Show unavailable reason in plain language.
- Ending/aftermath: use the same notebook system and explorable world changes before prose.

### Mobile controls

Icon masters are 128 × 128 RGBA. Runtime export is 64 × 64. Keep critical shape inside 104 × 104. Buttons must have at least a 56-physical-pixel touch target and 8 pixels of visual separation.

| Action | Icon |
|---|---|
| Use | Open hand approaching a brass switch/handle |
| Attack | Short pry-bar swing with one strong diagonal |
| Scan | Receiver coil with two directional wave arcs |
| Dodge | Boot and bent route arrow |
| Heal | Folded bandage with one clinic-green stripe |
| Burst | Split signal ring breaking outward |
| Help | Folded field-guide page with tab |
| Menu / Kit | Field-kit latch |
| Map | Folded road sheet with one route line |
| Log / Archive | Cassette over a clipped paper page |

Required states per action:

- idle;
- pressed, with 8% inward scale and brighter edge;
- disabled, lower contrast plus a slash/notch;
- cooldown, radial mask supplied by code;
- charged/ready, one restrained amber or cyan rim;
- contextual, small secondary marker;
- tutorial pulse, two cycles only.

Mobile layout rules:

- Four primary actions remain under the right thumb.
- Utility actions sit in one receiver/field-kit tray, not six loose text circles.
- Joystick uses a worn rubber/metal base and clear thumb knob. It remains low contrast until touched.
- Reserve safe areas for notches and browser bars.
- Use icon plus short label only during the tutorial or accessibility mode.
- Pressed state, cooldown and haptic response must agree.
- Validate left-handed mirroring.

## 10. Image-generation specifications

Generated work is source material. It still needs extraction, frame registration, metadata, import and visual QA.

### Reference pack

Attach only relevant current art. State what each reference controls.

- Character identity: assets/processed/player_4dir_concept/player_front.png, player_back.png, player_side_l.png and player_side_r.png.
- Player motion/proportions: assets/processed/player_walk_v2/player_walk_cycle.png. Use as motion reference, not as a frame-layout reference.
- Enemy mood only: assets/processed/hollow_concept_sheet/. Do not copy its front-facing pose structure.
- Environment camera/material: assets/processed/environment_landmarks_v2/bellwether_civic_ruin.png, long_acre_relay_station.png and tollard_exchange_ruin.png.
- Prop language: assets/processed/roadside_props/, petrol_station_props/ and railhome_props/.
- Broad palette/texture: assets/source/generated/style/style_board.png.

Do not use assets/source/generated/ui/ui_kit_01.png as the UI target. Its generic metal-panel treatment is not the new direction.

### Common style block

Use this in every prompt:

    Grounded British analogue civil-defence survival horror. Rain-dark roadside infrastructure, worn 1980s–2000s public-service equipment, oxidised galvanised metal, dirty concrete, painted timber, paper records and repaired domestic objects. Painterly pixel-art texture with readable silhouettes, restrained detail and a top-down three-quarter game camera where requested. Human warmth is sodium amber. Verified signal is restrained cyan. Contradiction is warning red. Practical, specific and lived-in. No futuristic clean sci-fi.

### Common negative block

    No text, letters, numbers, logos, watermark, signature, interface, captions or speech bubbles. No generic neon holograms. No glossy spaceship panels. No fantasy runes. No random cables without function. No multiple objects touching. No cropped silhouette. No cast shadow unless requested as a separate layer. No green spill on the subject.

### Character action prompt

    Use the supplied turnaround as a strict identity, costume, colour and proportion reference. Create one four-direction animation sheet for [CHARACTER], action [ACTION], [FRAME COUNT] frames per direction. Exact grid: four rows ordered down, up, left, right; [FRAME COUNT] columns; every cell 320 by 320 pixels. Fixed grounded foot pivot at x160 y288 in every cell. No root motion. Clear chronological poses with stable scale and lighting. Isolated full body. Flat pure chroma-key green #00FF00 background, no shadow, no text or watermark.

Generation notes:

- Generate one action at a time.
- Use a neutral turnaround as the first reference and the most recently approved action as continuity reference.
- Do not accept a sheet until pivots and costume continuity pass.
- If the tool cannot honour the exact grid, generate frame strips, then register and assemble them locally. Never import an approximate grid.

### Enemy identity prompts

- Hollow: former road/service worker trapped in a repeated task; recognisably human clothing; asymmetrical carried weight; no skull-face cliché.
- Static Wraith: duplicated human silhouette with delayed clothing edges and missing signal bands; no robe or magic smoke.
- Mimic Stalker: plausible stranded survivor at rest; subtly wrong limb length and copied expression during motion.
- Signal Leech: low parasite assembled around speaker cone, wet cable and organic grip tissue; readable head/attack end.
- Linesman: heavy insulated utility coat, line hook, cable reel and damaged face shield; field effect separate.
- Custodian: exchange maintenance uniform fused with headset, printer feed and manual control hardware; imposing but physically built.

### Exterior prompt

    Create one isolated [BUILDING] exterior in top-down three-quarter game view. Match the supplied environment camera, material wear and palette references. The building is [WORLD WIDTH IN P] player-heights wide and [WORLD DEPTH IN P] deep. Show a clear grounded footprint, readable roofline, front step and one blank enterable door. Include only structurally attached details. Leave signs blank. Full silhouette with generous margins. Flat pure chroma-key green #00FF00 background. No people, loose props, text, logo, watermark, cast shadow or atmospheric fog.

Generate one building per image. Generate roof/foreground overlay separately when the player can pass behind it.

### Modular interior prompt

    Create an isolated modular asset sheet for [MATERIAL/FURNITURE FAMILY] in the same top-down three-quarter camera and scale as the supplied environment references. Equal 64-pixel logical increments, straight edges that tile, separate corners and end caps, consistent light from upper left, no baked room shadow. Place components in a clean non-overlapping grid with wide gutters on flat pure chroma-key green #00FF00. Blank signs and screens. No text, watermark or people.

### Hero-prop prompt

    Create one isolated [PROP] for [LOCATION/FUNCTION], top-down three-quarter game view, grounded British public-service design, visibly used and repaired. It must tell this specific story: [BEFORE / INTERRUPTION / HUMAN RESPONSE]. Match supplied prop palette and scale. Leave labels and paper blank for authored overlays. Flat pure chroma-key green #00FF00 background, no cast shadow, text, watermark or extra objects.

### Trace Anchor prompt

    Create the physical Trace Anchor [OBJECT] as a real, worn object first. It belongs in [LOCATION] and carries [SPECIFIC HUMAN EVIDENCE]. Add no crystal, magic stone or generic glowing orb. Deliver the object isolated on flat pure chroma-key green #00FF00, then deliver separate monochrome afterimage layers showing [PAST ACTION] aligned to the same camera. No text, watermark or baked cyan halo.

Soft signal effects should be generated on black with no text, then converted to alpha/additive layers. Hard-edged artifacts and thumbnails use green or transparent isolation.

### Cinematic prompt

    Cinematic still [ID], 2560 by 1440, grounded British analogue survival horror, [SHOT DESCRIPTION]. Match the supplied character, prop and environment references. Painterly pixel-art texture with cinematic composition, rain depth and restrained practical light. Keep bottom 28 percent quiet for subtitles. Full bleed scene, no chroma key. No text, letters, numbers, logo, interface, watermark or signature.

Request background, midground, foreground rain/glass and signal-interference layers separately after the clean still is approved.

### UI component prompt

    Create isolated physical UI components inspired by a repaired field receiver and used paper notebook: [COMPONENT LIST]. Dirty ivory paper, graphite, masking tape, dull galvanised metal, Bakelite knobs and restrained amber/cyan status edges. Straight 9-slice-safe borders, blank centres, consistent corner radii and no baked labels. Place pieces in a non-overlapping grid on flat pure chroma-key green #00FF00. No text, icons, logo, interface screenshot or watermark.

### Mobile icon prompt

    Create one bold game-control icon for [ACTION]: [ICON DESCRIPTION]. 128 by 128 master, one-colour dirty-ivory silhouette with a restrained [AMBER/CYAN/GREEN] accent, thick readable shape, transparent or flat green background, no circle button background. No text, letters, logo, watermark, gradients or tiny detail.

## 11. Future replacement-art order and gates

The current runtime catalogue is covered by release contracts. Use this sequence when replacing a complete asset family or commissioning the future targets in section 5; it is not a list of work still required for the current build. Do not mass-generate a replacement list before its pilot passes.

1. Contract pilot
   - Ellie idle/walk/attack.
   - One Hollow idle/walk/attack/hit/death.
   - Carriage 317 exterior and one two-room Cullbrook interior.
   - One physical Trace Anchor.
   - Receiver HUD strip and four primary mobile icons.

2. Validate
   - Scale at current camera.
   - Frame registration and action readability.
   - Collision/occluder metadata.
   - Green extraction and edge quality.
   - Desktop and mobile legibility.

3. Character batch
   - Complete Ellie.
   - Complete six enemy species.
   - Complete Imogen and Rafi before the remaining NPC roster.

4. World batch
   - E00 modular kit.
   - E01–E05 in story order.
   - Interiors and hero props immediately after each exterior, not at the end.

5. Narrative visual batch
   - Ten Trace Anchors.
   - Eight cinematic stills.
   - Portraits, evidence thumbnails and archive pages.

6. UI batch
   - Desktop HUD/dialogue/map/archive/crafting.
   - Mobile states and left-handed layout.
   - Accessibility variants.

7. Final audit
   - Every visible intact door enters somewhere.
   - Every solid-looking prop has correct foot-plane collision or is clearly non-solid.
   - No named building reuses another named building's full silhouette.
   - No enemy reuses another species' animation sheet.
   - No generated image contains text, logos or watermark.
   - Every shipped asset has provenance in [ASSET_CREDITS.md](../ASSET_CREDITS.md); a future batch using section 4 also has its handoff metadata.
   - Every screen and scene is checked at final camera scale, not only in the source image.
