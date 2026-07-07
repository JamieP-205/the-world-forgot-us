# Art Spec

Working target for the first real asset pass. The current game uses readable Polygon2D placeholder art; these notes define what to replace first without changing the camera or mechanics.

## Current camera / view style

- 2D top-down survival view.
- Camera is centered on the player with smoothing enabled.
- Current zoom is `1.9`, giving a tight room-to-road view rather than a broad tactics view.
- Assets should read clearly at small on-screen sizes and from a top-down / slight three-quarter impression.
- Mood target: ashy, cold wasteland with small warm safety points and cyan memory technology.

## Recommended tile size

- Use `32x32 px` as the base environment tile/grid size.
- Larger props should be built in 32 px increments where practical:
  - Crate: `32x32`
  - Small kiosk props: `64x64`
  - Car: `96x64`
  - Petrol station chunks: `128x96` and `192x128`
  - Railhome interior modules: `128x96`

## Recommended player sprite size

- Player base sprite: `32x32 px`.
- Allow up to `40x40 px` including backpack, coat, and weapon swing silhouette.
- Keep the collision feel close to the current `18x22` body.

## Required first real asset pack list

- Survivor player sprite set.
- Hollow enemy sprite set.
- Loot crate / toolbox / locker variants.
- Railhome exit / doorway marker.
- Fallen radio mast landmark.
- Ruined petrol station pieces: canopy, pumps, office wall, warning board.
- Broken roadside kiosk.
- Maintenance shed / bus-stop style shelter.
- Broken car.
- Railhome base props: bedroll, storage crate, Radio Desk, workbench.
- Memory echo visual: idle hidden shimmer, revealed cyan echo, recovered warm echo.
- UI icons: scrap, battery, food, keepsake, echo, scanner, health, save/rest.

## Player animation list

- Idle down/up/left/right.
- Walk down/up/left/right.
- Melee swing down/up/left/right.
- Hurt flash or stagger.
- Scan pose or one-frame scanner raise.
- Rest / kneel optional for bedroll interaction.

## Hollow animation list

- Idle twitch.
- Slow shamble down/up/left/right.
- Contact attack swipe.
- Hit reaction.
- Death dissolve / fade.
- Optional scanner-react flinch for later.

## Environment asset list

- Asphalt road with cracks and faded lane paint.
- Ashy dirt / gravel ground.
- Rubble piles and broken concrete.
- Rusted petrol pumps.
- Petrol station office wall and roof pieces.
- Dead vending machine.
- Cracked public phone.
- Missing-person poster.
- Emergency warning board.
- Faded road sign.
- Abandoned backpack.
- Broken radio.
- Old family photo frame.
- Child's Lunchbox keepsake.
- Fallen mast with cold signal sparks and recovered warm glow.
- Railhome interior walls, runner rug, bunks, bedroll, storage, Radio Desk.

## UI icon list

- Health cross / heart.
- Scanner / Mnemoscope ring.
- Scrap.
- Battery.
- Canned food.
- Keepsake.
- Echo / memory shard.
- Radio signal.
- Save/rest bedroll.
- Interaction key prompt marker.
- Objective checkbox states.

## Notes for future image generation

- Generate assets as transparent-background sprites, not full scenes.
- Keep palette restrained: cold grey-green wasteland, rust red/brown structures, warm amber safety lights, cyan memory effects.
- Avoid polished sci-fi. The radio/scanner tech should look repaired, analog, and scavenged.
- Make silhouettes readable at `32x32` before adding detail.
- Produce neutral directional sheets first; animation polish can come later.
- Memory effects can stay semi-abstract: cyan shards/rings for unrecovered, amber/cyan blend after recovery.
