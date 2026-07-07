class_name ItemData
extends Resource
## Data definition for a single item type.
##
## Items are .tres resources in resources/items/, loaded by ItemDatabase at
## startup. The inventory only stores ids + counts; all display data lives
## here. Extend later with: icon, weight, effects, trade value, and the
## keepsake/memory-echo hooks from the design bible (scrap / archive /
## give / trade / return choices).

## Unique id used by the inventory and loot tables (e.g. "scrap").
@export var id: StringName

## Name shown in UI.
@export var display_name: String = ""

## Icon shown in the inventory/HUD (sliced sprite from assets/processed/).
@export var icon: Texture2D

## Short flavour / usage text.
@export_multiline var description: String = ""

## Maximum stack size (not enforced yet; matters once the real inventory
## UI and encumbrance rules arrive).
@export var stack_size: int = 99

## Loose category tag: "material", "food", "tech", "keepsake", ...
@export var category: String = "material"
