# The World Forgot Us

A 2D top-down open-world post-apocalyptic survival game built in **Godot 4.7**.

> Loot the wasteland. Rebuild your base. Recover what the world forgot.

This repository currently contains the **first playable prototype foundation** — not the full game. It proves out the core moment-to-moment feel (move, approach, interact, loot, see inventory update), the **return-to-base loop** (travel between the world map and the Railhome base with your inventory intact), **simple melee combat** (fight a Hollow, take damage, die and wake back at the base), and the game's signature **scan → recover** loop (the Mnemoscope reveals a hidden memory echo, which you recover to restore it into the Archive and gain a keepsake), on a clean, modular architecture designed to grow into base building and save/load.

The full **scan → recover → archive** chain is the mechanic the game is named for: *recover what the world forgot.*

See `master-design-bible.md` for the full game vision.

---

## How to run

You need **Godot 4.7** (the executable is already in `Downloads/Godot_v4.7-stable_win64.exe/`).

### From the editor (recommended)
1. Launch Godot 4.7.
2. Click **Import**, browse to this folder, and select `project.godot`.
3. Once the project opens, press **F5** (Run Project) or the ▶ play button, top-right.

The game boots into `scenes/main.tscn` (the persistent root), which loads the world map as the starting level.

### From the command line
```
Godot_v4.7-stable_win64.exe --path "path/to/the-world-forgot-us"
```

### Controls
| Input | Action |
|-------|--------|
| **W A S D** | Move |
| **E** | Interact (search containers, use doors, base props) |
| **J** or **Left-click** | Melee attack (swing in the facing direction) |
| **Q** or **Right-click** | Scanner pulse (Mnemoscope) |
| **Esc** | Pause / resume |

**Try the loop:**
1. Walk the tan square up to the orange crate. When `[E] Search crate` appears at the bottom, press **E** — the crate dims and the inventory readout (below the meters) updates.
2. Head south-east to the pale Hollow. Face it and press **J** (or left-click) to swing — two hits kill it. Get too close and it shambles after you and chips your health bar (top-left). If your health hits zero you wake back at the base, healed.
3. Walk north until you're near the top of the map, then press **Q** (or right-click) to fire a scanner pulse. A cyan ring expands, and a hidden memory echo flickers into view with a whispered hint. Watch the cyan **scanner meter** drain per pulse and slowly recharge.
4. Walk onto the revealed echo — now `[E] Recover memory: The Last Broadcast` appears. Press **E** to recover it: the memory plays as a notice, the echo settles to a warm restored glow, the **Echoes recovered** counter (bottom-left) ticks up, and you gain an **Old Photo** keepsake.
5. Head to the teal doorway on the left (`[E] Return to the Railhome`) and press **E** to travel to the base.
6. Inside the train carriage, interact with the bedroll, storage crate, or radio desk (placeholders that post a status notice), then use the doorway on the right to step back into the wasteland. Your inventory carries across every trip.

---

## Folder structure

```
the-world-forgot-us/
├── project.godot            # Godot project config: autoloads, input map, physics layers
├── icon.svg                 # Project/window icon (Mnemoscope motif)
├── master-design-bible.md   # Full design document
│
├── scenes/                  # All .tscn scene files (visual/node composition)
│   ├── main.tscn            # Persistent root: Player + HUD + swappable level. MAIN SCENE
│   ├── maps/
│   │   └── test_map.tscn     # World map level (environment only)
│   ├── base/
│   │   └── railhome_base.tscn # The Railhome train-carriage base level
│   ├── player/
│   │   └── player.tscn       # Player body, camera, interaction area, melee hitbox, health
│   ├── enemies/
│   │   └── enemy_hollow.tscn  # The Hollow enemy
│   ├── scanner/
│   │   └── scanner_pulse.tscn  # Expanding-ring pulse effect (cosmetic)
│   ├── world/
│   │   ├── loot_container.tscn  # Reusable lootable crate
│   │   ├── scene_exit.tscn      # Reusable doorway that travels to another level
│   │   └── echo_source.tscn     # Hidden memory echo, revealed by the scanner
│   └── ui/
│       └── hud.tscn          # Health + scanner meters, inventory, prompt, pause, notice
│
├── scripts/                 # All GDScript logic, split by domain
│   ├── main.gd              # Main – owns Player/HUD, swaps the current level
│   ├── systems/             # Autoloaded singletons (global systems)
│   │   ├── event_bus.gd      # EventBus  – decoupled signal hub
│   │   ├── item_database.gd  # ItemDatabase – loads item definitions
│   │   ├── inventory_system.gd # InventorySystem – id→count inventory
│   │   └── game_manager.gd   # GameManager – global state (pause, travel, respawn)
│   ├── components/          # Reusable behaviour nodes
│   │   └── health_component.gd # HealthComponent – shared health pool + signals
│   ├── scanner/             # The Mnemoscope
│   │   ├── scanner_component.gd # Fires pulses, manages energy (child of Player)
│   │   ├── scanner_pulse.gd     # Cosmetic expanding ring
│   │   └── scannable.gd         # Base for anything a pulse reveals/affects
│   ├── player/
│   │   └── player.gd         # Movement, facing, interaction, melee, health
│   ├── enemies/
│   │   └── enemy_hollow.gd    # Hollow AI (idle / chase / attack)
│   ├── world/
│   │   ├── interactable.gd    # Base class for anything E can act on
│   │   ├── loot_container.gd  # Interactable that grants items once
│   │   ├── scene_exit.gd      # Interactable that travels to another level
│   │   ├── placeholder_interactable.gd # Interactable that posts a "coming later" notice
│   │   └── echo_source.gd     # Scannable – a hidden memory echo
│   ├── items/
│   │   └── item_data.gd       # ItemData resource definition
│   └── ui/
│       └── hud.gd            # Listens to system signals, draws the HUD
│
└── resources/
    └── items/               # Item definitions as .tres (data, not code)
        ├── scrap.tres
        ├── canned_food.tres
        ├── battery.tres
        └── old_photo.tres
```

---

## Architecture: how the pieces fit

The prototype is built around **autoloaded singletons** and a **signal-driven event bus** so that systems don't hold hard references to each other. That decoupling is what makes the later features (combat, scanner, echoes, base building, save/load) drop-in rather than rewrites.

### The four global systems (autoloads)
Registered in `project.godot` under `[autoload]`, so they exist from launch and are reachable by name anywhere:

- **`EventBus`** — a hub of global signals. The player emits `interaction_prompt_changed`; the HUD listens. Neither knows the other exists. Add a signal here whenever two systems need to talk without coupling.
- **`ItemDatabase`** — scans `resources/items/*.tres` at startup into an `id → ItemData` lookup. Adding an item is a data change (new `.tres`), never a code change.
- **`InventorySystem`** — a minimal `id → count` store with `add_item` / `remove_item` / `get_count` and an `inventory_changed` signal. No UI knowledge; the HUD just reacts to the signal.
- **`GameManager`** — owns global game state: pausing (via `get_tree().paused`) and `travel_to(scene_path, spawn)`, which loads a level and hands the swap to `Main`. Natural home for the day/storm cycle and save-on-travel later.

### The persistent root and the return-to-base loop
- **`Main`** (`scenes/main.tscn`) is the persistent root. It holds the things that must survive travel — the **Player**, its **camera**, and the **HUD** — plus a single `LevelHolder` slot for the current level.
- **Levels are pure environment scenes.** `test_map.tscn` (the world) and `railhome_base.tscn` (the base) contain only floors, walls, props, exits, and spawn markers — no player or UI. That keeps them small and reusable.
- **Traveling** goes: a `SceneExit` calls `GameManager.travel_to()` → `EventBus.travel_requested` → `Main` frees the old level, instances the new one, and moves the player onto the named spawn marker (a `Marker2D` in the `spawn_points` group whose node name matches the exit's `target_spawn`). Because the Player and `InventorySystem` (an autoload) persist, **your inventory and gear carry across the loop for free**. The swap is deferred one frame so the exit that triggered it isn't freed mid-call.

### The interaction pattern
- `Interactable` (extends `Area2D`) is the **base class for everything E can touch**. It exposes `get_prompt()` and `interact(player)`. Three concrete kinds exist today:
  - `LootContainer` — hands its `loot` dictionary to `InventorySystem` once, then reports itself empty.
  - `SceneExit` — travels to another level at a named spawn point.
  - `PlaceholderInteractable` — posts a transient HUD notice (used for the base bedroll/storage/radio desk until those systems are built).
- The player carries an `InteractionArea` that detects nearby `Interactable`s, picks the closest each frame (pruning any freed by a level swap), and pushes its prompt to the HUD via `EventBus`. Pressing **E** calls `interact()` on that target.

### Combat
- **`HealthComponent`** is a reusable child node (a health pool with `take_damage` / `heal` / `reset` and `health_changed` / `died` signals). Both the player and the Hollow carry one, so the damage rules live in exactly one place.
- **Damage flows through a thin `take_damage(amount)`** on each combatant, which forwards to its `HealthComponent`. Attackers never touch the target's health directly — that's how the player's melee and the enemy's contact attack stay decoupled from each other.
- **Player melee**: pressing attack enables an `AttackArea` (a hitbox pinned in front of the player by the `facing` vector) for a brief swing, and damages every overlapping body that has a `take_damage` method. On a cooldown.
- **Hollow AI** (`enemy_hollow.gd`) is a minimal idle → chase → attack state machine driven by distance to the player (found via the `player` group). On death it frees itself — the hook where loot/echo drops go later.
- **Death → respawn**: when the player's health hits zero it emits `EventBus.player_died`; `GameManager` sends them home to the base and the player heals to full — reusing the same travel system as the return-to-base loop ("wake at the base").

### The scanner (Mnemoscope)
- **`ScannerComponent`** is a child of the Player, so its position is the pulse origin. It reads its own `scan` input, runs a rechargeable **energy meter** (drains per pulse, recharges over time; the natural place to later gate on Batteries in the inventory), spawns the cosmetic ring, and announces the pulse with `EventBus.scanner_pulsed(origin, radius)`.
- **`Scannable`** is the base for anything a pulse reveals or affects. It listens for `scanner_pulsed` and, if it's within range, fires `scanned` and calls an overridable `_on_scanned()`. Distance-based, so no collision shape is needed.
- **`EchoSource`** (a `Scannable`) is a memory echo hidden in the world — nearly invisible until a pulse reveals it, then it glows pale cyan and posts a hint. This is the seed the next build step grows into full echo *recovery*.
- Because everything talks through `EventBus`, adding new scannables (hidden enemies, weak points, corrupted machines) is drop-in — they just listen for the pulse.

### Physics layers (defined in project.godot)
| Layer | Name | Used by |
|-------|------|---------|
| 1 | `world` | Walls, rubble, container solid bodies (block movement) |
| 2 | `player` | The player body |
| 3 | `interactable` | Interactable trigger areas (detected by the player's reach) |
| 4 | `enemy` | Enemy bodies (detected by the player's melee hitbox) |

*(The scanner is distance-based and needs no physics layer.)*

---

## Designed to extend

Each planned system has a clear seam already in place:

| Future feature | Where it plugs in |
|----------------|-------------------|
| **More enemies / weapons** | Copy `enemy_hollow.tscn` for new enemy types; give them a `HealthComponent` and a `take_damage`. Ranged/throwable weapons follow the same hitbox pattern as the melee `AttackArea`. |
| **Memory-echo recovery** | Make `EchoSource` also an `Interactable` (or give the revealed echo an interaction zone) so a scanned echo can be walked up to and recovered — restoring a name, granting a keepsake, or unlocking a clue. Recovered echoes recorded in a future `ArchiveSystem`. |
| **Scanner in combat** | Have enemies subclass/compose `Scannable` so a pulse can reveal hidden foes (Static Wraith), expose weak points, or stun signal-corrupted enemies (design bible §14.3). The `scanner_pulsed` signal is already the hook. |
| **Base building** | The base scene (`railhome_base.tscn`) exists with placeholder props. Replace each `PlaceholderInteractable` with a real station backed by a `BaseUpgradeSystem` that spends `InventorySystem` resources. |
| **Save/load** | `SaveManager` serialises `InventorySystem.get_items()`, the current level path, and player position; `GameManager.travel_to` is the seam to save on transition. Systems already expose read-only snapshots. |
| **More levels/districts** | Add an environment `.tscn` with spawn markers and point a `SceneExit` at it. No code change. |
| **New items** | Drop a new `.tres` into `resources/items/`. No code change. |

Everything follows the design bible's rule: keep systems modular and add one at a time.
