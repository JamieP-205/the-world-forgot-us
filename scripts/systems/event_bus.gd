extends Node
## Autoload: EventBus
##
## Central signal hub so systems never need direct references to each
## other (the HUD listens here instead of knowing about the player).
## Add signals as new systems arrive: scanner pulses fired, memory echoes
## recovered, base upgrades built, save/load events, radio messages...

## Emitted by the player when the "[E] ..." HUD prompt should change.
## An empty string means "hide the prompt".
signal interaction_prompt_changed(text: String)

## Emitted by GameManager when the game is paused / unpaused.
signal paused_changed(is_paused: bool)

## Requests a level swap. Main listens and performs the deferred change,
## keeping the persistent Player/HUD alive. `spawn` names a Marker2D (in
## the "spawn_points" group) in the destination level; &"" means "leave
## the player where the scene authored them".
signal travel_requested(scene: PackedScene, spawn: StringName)

## Emitted by Main after a destination level has been instanced and the
## player has been placed. SaveManager and the HUD use this to sync state.
signal level_loaded

## A short, transient status line for the HUD (e.g. "Storage checked").
## Reusable notice/toast channel for any system that needs to say something.
signal notice_posted(text: String)

## Player health changed; the HUD health bar listens.
signal player_health_changed(current: float, maximum: float)

## Player's health hit zero. GameManager sends them home to the base.
signal player_died

## The scanner fired a pulse from `origin` reaching `radius` pixels.
## Scannables listen and react if they're within range.
signal scanner_pulsed(origin: Vector2, radius: float)

## Scanner energy changed; the HUD scanner meter listens.
signal scanner_energy_changed(current: float, maximum: float)

## A hidden echo was revealed by a scanner pulse.
signal echo_revealed(data: MemoryEchoData)

## A save was written successfully.
signal game_saved

## Small camera feedback for scanner reveals, echo recovery, and Hollow death.
signal camera_shake_requested(strength: float, duration: float)

## Emitted by Scannable whenever a scanner pulse actually finds something.
signal scannable_pinged(position: Vector2)
