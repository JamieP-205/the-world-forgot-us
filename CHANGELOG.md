# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] — 2026-07-23

### Added
- **Roughly doubled the discoverable content** — 65 new documents, letters, forms, dispatch logs, radio recordings and physical discoveries scattered across every region, deepening the mystery and the people caught in it (Idris, Imogen, Leena, Owen, Gwen, Rafi, Tom, Mara, Katie). Plus 14 new environmental beats and 12 survivor graffiti.
- **A multi-beat finale.** The single ending screen is now a paged epilogue that reacts to your exact path: what becomes of the network (Restore / Mesh / Sever), of the ally you sided with, whether the copy conceded it isn't Maggie or insisted to the last, and Ellie's own reckoning — before the final card.
- **A weight beat at the Choir Core**, just before the operation, that names the specific path you carried north — so the choice lands.

### Fixed
- Removed a stale message that wrongly claimed the finale "isn't built in this slice."
- Clamped document, beat and graffiti coordinates into each scene's walkable interior — several records (legacy and new) had been authored at off-map coordinates and were unreachable.

## [1.3.0] — 2026-07-23

### Added
- Subtle procedural ambient **music** — a slow, evolving minor pad with sparse, distant cold-piano tones that plays beneath the rain and thunder and grows darker and more dissonant as dread rises.
- A dense layer of **world detail & animation**: rain-fed puddles with ripples, a wet sheen that tracks the nearest light, thin ground mist that curls with the wind, wind-blown leaves and litter, water dripping from edges, and moths spiralling in lamplight.
- **Sky & weather drama**: parallax fog banks, embers rising through the light, far-off sheet lightning and jagged forked bolts, rain-on-the-lens streaks, and a breathing vignette.
- **More tension & scares**: a pale face at a dark window that's gone when you look again, a figure revealed only in a lightning flash, shapes that dart across far alleys, the lantern dying for a long beat, and the sense of being watched the longer you linger.

### Fixed
- Shadows now read correctly on every item: added an always-on ambient contact shadow under all props and buildings, and stopped small clutter from casting hard directional wedges (which produced an ugly starburst around lamps). Large structures still cast clean directional shadows.

## [1.2.0] — 2026-07-23

### Changed
- Redesigned all six enemy types as uncanny "reconstructions" — people the network rebuilt wrong. The Hollow is a stooped figure with a static-filled void where a face should be; the Static Wraith a torn, chromatic-split smear of interference; the Mimic Stalker wears a stolen face over the void; the Signal Leech is a listening organ on splayed legs; the Relay Husk is armoured in a humming signal-shield; and the Choir Warden boss carries a slowly rotating drum of many stolen faces. Each animates unsettlingly and reacts to being exposed, telegraphing an attack, or having its shield stripped.

### Added
- Proximity dread: as a reconstruction closes in, colour drains, a vignette tightens, a heartbeat quickens and an arterial red bleeds at the screen's edge.
- A "the signal notices you" sting the moment an enemy locks on, and rare figures glimpsed at the edge of the fog.
- A lantern that gutters and recoils near wrongness, and a colour grade that deepens and cools after nightfall.
- Procedural dread audio — heartbeat, rising drone, alert sting and whisper textures.

### Story
- Rewrote the opening and every objective for clarity. The cold-open now plainly establishes who Ellie is, that her sister Maggie is dead, and that Maggie's voice is coming from equipment with no power — then Ellie explains, in plain terms, what Continuity is and what Blank Night was before she sets out.

## [1.0.1] — 2026-07-21

### Fixed
- Document reader panel could render see-through on some displays where the paper texture pattern failed to load; it now uses a solid rendered paper fill.
- Prop labels occasionally inherited a stray text alignment, nudging captions off-anchor.
- Object shadows are cast from a ground-contact strip so they read as soft directional shadows rather than a hard rectangle around each prop.

## [1.0.0] — 2026-07-21

First public release of the browser build.

### Added
- Complete four-region campaign: Cullbrook Services, Ashmere Estate, Wrenfield Broadcast Fields and Tollard Exchange.
- Trace-receiver investigation with an evidence archive (Unverified / Supported / Contradicted / Corroborated).
- Discoverable story layer: found documents, letters, radio transmissions, environmental beats and graffiti, with a Records archive.
- Alliance and network-strategy choices (Restore / Mesh / Sever) resolving into twelve endings.
- Small-scale survival combat with six enemy families, crafting, and a downed-and-revive system.
- Dynamic 2-D lighting with cast shadows, a day/night cycle, rain and a fully procedural Web Audio engine.
- Keyboard, mouse and touch controls; localStorage saves; accessibility options.

### Technical
- Single self-contained `index.html` — no dependencies, no build step.
- Deploys to GitHub Pages as static content.
