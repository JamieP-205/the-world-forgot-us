#!/usr/bin/env python
"""Turn opaque ground-tile slices into soft-edged decals.

The `demo_ground_tiles` slices are opaque rectangles (they came off a dark
background). Dropped straight onto the map they'd show hard rectangular
seams. This applies a smooth elliptical alpha falloff so each becomes a
blendable decal (cracked asphalt, dirt, rubble, floor grime) with feathered
edges, written to `assets/processed/decals/`.

Run from the project root:  python tools/make_ground_decals.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TILES = ROOT / "assets" / "processed" / "demo_ground_tiles"
OUT = ROOT / "assets" / "processed" / "decals"

# Which tiles to turn into decals.
TILES_TO_FEATHER = [
    "asphalt_cracked", "concrete_broken", "dirt_gravel", "dirt_debris",
    "gravel_rubble", "rubble_planks", "metal_floor", "wood_floor",
]

# Fraction of the half-width/height that stays fully opaque before the
# feather starts (0.0 = feather from centre, 0.9 = only a thin edge fades).
CORE = 0.30


def feather(name: str) -> bool:
    src = TILES / f"{name}.png"
    if not src.exists():
        print(f"  missing {name}, skip")
        return False
    im = Image.open(src).convert("RGBA")
    arr = np.asarray(im).astype(np.float32)
    h, w = arr.shape[:2]

    yy, xx = np.mgrid[0:h, 0:w]
    nx = (xx - (w - 1) / 2.0) / ((w - 1) / 2.0)
    ny = (yy - (h - 1) / 2.0) / ((h - 1) / 2.0)
    r = np.sqrt(nx * nx + ny * ny)              # 0 centre -> ~1.41 corners

    # Smooth falloff: 1 inside CORE, 0 by r=1.0.
    a = np.clip((1.0 - r) / (1.0 - CORE), 0.0, 1.0)
    a = a * a * (3 - 2 * a)                      # smoothstep

    arr[..., 3] = arr[..., 3] * a
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(OUT / f"{name}.png")
    return True


def main() -> None:
    print("Feathering ground decals ->", OUT)
    n = sum(feather(t) for t in TILES_TO_FEATHER)
    print(f"wrote {n} decals")


if __name__ == "__main__":
    main()
