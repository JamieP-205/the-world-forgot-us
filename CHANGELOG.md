# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
