class_name MemoryEchoData
extends Resource
## Data definition for a single memory echo.
##
## Echoes are .tres resources in resources/echoes/. Keeping them as data
## (like ItemData) means new echoes are authored, not coded. Mirrors the
## design bible's memory model: a category (§24 archive), a quality
## (§7.3), the recovered memory itself, and an optional keepsake granted.

## Unique id, used by the ArchiveSystem to de-duplicate.
@export var id: StringName

## Short name shown in prompts and the archive, e.g. "The Last Broadcast".
@export var title: String = ""

## Archive category: People / Places / Objects / Broadcasts / Factions /
## Personal Memories / Unresolved Echoes.
@export var category: String = "Places"

## Memory quality: Static / Fragment / Clear Echo / Restored Memory.
@export var quality: String = "Clear Echo"

## Teaser shown the moment the scanner reveals the echo.
@export_multiline var hint: String = "A memory stirs here."

## The memory itself, shown when the echo is recovered.
@export_multiline var memory_text: String = ""

## Optional item id (see resources/items/) granted on recovery. Empty for
## none. This is where the keepsake / "meaningful junk" tie-in lives.
@export var keepsake_item: StringName = &""
