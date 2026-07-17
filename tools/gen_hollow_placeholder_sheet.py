#!/usr/bin/env python3
"""Generate the legacy functional TOP-DOWN Hollow fixture sheet.

Blockout stand-in (clean shapes, not painterly art) so the Hollow can be wired
into an AnimatedSprite2D later, replacing its Polygon2D blockout. It matches the
player placeholder's grid conventions but a distinct silhouette: a pale, gaunt,
forgotten humanoid with cold cyan/grey corruption -- no coat, no backpack, no red.

Output: assets/processed/hollow_topdown/
  hollow_idle.png    (4 rows x 4 cols)
  hollow_walk.png    (4 rows x 6 cols)
  hollow_attack.png  (4 rows x 4 cols)
  hollow_hit.png     (4 rows x 2 cols)
  hollow_death.png   (4 rows x 6 cols)
  hollow_topdown_preview.png  (all stacked, for eyeballing)

Grid: 96x96 cells. Rows (top->bottom) = facing DOWN, UP, LEFT, RIGHT (canonical
order, matches CHARACTER_SPRITE_SPEC.md). Columns = animation frames.
Transparent background, no baked shadow, centred, consistent baseline.
"""
from __future__ import annotations
import math
import os
import random
from PIL import Image, ImageDraw

CELL = 96
SS = 4
DIRS = ["down", "up", "left", "right"]
FV = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0)}
DEATH_FRAMES = 6

# --- palette (pale bone / grey-green, cold cyan corruption, dark hollow core) --
PALE       = (196, 214, 208, 255)
PALE_DARK  = (150, 172, 166, 255)
LIMB       = (170, 190, 184, 255)
CORE       = (40, 50, 52, 255)     # hollow void at the chest
EYE        = (150, 224, 232, 255)  # faint cyan eyes
CYAN       = (120, 210, 224, 255)  # memory-corruption wisps
FLASH      = (220, 245, 248, 255)

OUT_DIR = os.path.join("assets", "processed", "hollow_topdown")


def ell(d, cx, cy, rx, ry, color):
    d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=color)


def pose(anim: str, frame: int):
    p = {"body_dy": 0.0, "sway": 0.0, "arm": 0.0, "leg": 0.0,
         "reach": None, "lean": 0.0, "back": 0.0, "flash": 0.0}
    if anim == "idle":
        p["sway"] = [0.0, 1.2, 0.0, -1.2][frame]
        p["body_dy"] = [0, -1, 0, 0][frame]
    elif anim == "walk":
        t = frame / 6.0
        s = math.sin(2 * math.pi * t)
        p["body_dy"] = -abs(math.sin(2 * math.pi * t)) * 1.4
        p["arm"] = s * 3.0
        p["leg"] = s * 3.5
        p["sway"] = math.cos(2 * math.pi * t) * 1.2  # uneven shamble drift
    elif anim == "attack":
        p["reach"] = [-3.0, 8.0, 12.0, 2.0][frame]
        p["lean"] = [0.0, 2.0, 3.0, 0.5][frame]
    elif anim == "hit":
        p["back"] = [3.0, 1.0][frame]
        p["flash"] = [1.0, 0.35][frame]
    elif anim == "death":
        p["body_dy"] = 0.0
    return p


def draw_hollow(d, direction: str, anim: str, frame: int):
    """Draw the pale figure onto a (possibly-scaled) layer's ImageDraw `d`."""
    fx, fy = FV[direction]
    px, py = -fy, fx
    p = pose(anim, frame)

    ox = -fx * p["back"] + px * p["sway"] + fx * p["lean"]
    oy = -fy * p["back"] + py * p["sway"] + fy * p["lean"]
    cx, cy = 48 + ox, 50 + oy
    hx, hy = cx + fx * 2, cy - 11 + fy * 2

    # Legs: thin, uneven shamble.
    legA = p["leg"]
    ell(d, cx + px * 3.5 + fx * legA, cy + 15 + fy * legA, 2.6, 5.2, PALE_DARK)
    ell(d, cx - px * 3.5 - fx * (legA * 0.6), cy + 16 - fy * (legA * 0.6), 2.6, 5.6, PALE_DARK)

    # Long limp arms (hang/reach). Attack extends the forward reach.
    aA = p["arm"]
    ell(d, cx + px * 9 + fx * aA, cy + 4 + fy * aA, 3.0, 6.0, LIMB)
    ell(d, cx - px * 9 - fx * aA, cy + 4 - fy * aA, 3.0, 6.0, LIMB)
    if p["reach"] is not None:
        r = p["reach"]
        ell(d, cx + px * 5 + fx * (8 + r), cy + fy * (8 + r), 3.0, 5.5, LIMB)
        ell(d, cx - px * 5 + fx * (8 + r), cy + fy * (8 + r), 3.0, 5.5, LIMB)

    # Gaunt torso (taller/narrower than the player) + hollow void.
    ell(d, cx, cy, 10, 14, PALE)
    ell(d, cx, cy + 1, 6.5, 10, PALE_DARK)
    ell(d, cx, cy + 1, 3.6, 5.2, CORE)

    # Faint cyan corruption wisps (static-ish, seeded per direction).
    wr = random.Random(hash(direction) & 0xFFFF)
    for _ in range(3):
        wx = cx + wr.uniform(-8, 8)
        wy = cy + wr.uniform(-10, 10)
        ell(d, wx, wy, 1.3, 1.3, (CYAN[0], CYAN[1], CYAN[2], 120))

    # Head + hollow eyes (eyes only when not facing away).
    ell(d, hx, hy, 7, 7, PALE)
    ell(d, hx, hy, 4.6, 4.6, PALE_DARK)
    if direction != "up":
        ell(d, hx + fx * 1.5 + px * 2.2, hy + fy * 1.5 + py * 2.2, 1.4, 1.4, EYE)
        ell(d, hx + fx * 1.5 - px * 2.2, hy + fy * 1.5 - py * 2.2, 1.4, 1.4, EYE)

    if p["flash"] > 0:
        a = int(150 * p["flash"])
        ell(d, cx, cy, 12, 15, (FLASH[0], FLASH[1], FLASH[2], a))


def scale_alpha(layer: Image.Image, factor: float) -> Image.Image:
    r, g, b, a = layer.split()
    a = a.point(lambda v: int(v * factor))
    return Image.merge("RGBA", (r, g, b, a))


def add_flecks(big: Image.Image, direction: str, frame: int, t: float):
    """Ash + cyan sparks drifting outward as the Hollow disperses."""
    d = ImageDraw.Draw(big)
    rng = random.Random(1000 + frame * 17 + (hash(direction) & 0xFF))
    n = int(4 + frame * 5)
    for _ in range(n):
        ang = rng.uniform(0, 2 * math.pi)
        dist = rng.uniform(2, 6) + t * 16
        fxp = 48 + math.cos(ang) * dist
        fyp = 50 + math.sin(ang) * dist
        col = CYAN if rng.random() < 0.4 else PALE
        rad = rng.uniform(0.8, 1.8) * SS
        a = int(200 * (1 - t) + 40)
        d.ellipse([fxp * SS - rad, fyp * SS - rad, fxp * SS + rad, fyp * SS + rad],
                  fill=(col[0], col[1], col[2], a))


def render_cell(direction: str, anim: str, frame: int) -> Image.Image:
    big = Image.new("RGBA", (CELL * SS, CELL * SS), (0, 0, 0, 0))
    layer = Image.new("RGBA", (CELL * SS, CELL * SS), (0, 0, 0, 0))
    draw_hollow(ImageDraw.Draw(layer), direction, anim, frame)

    if anim == "death":
        t = frame / (DEATH_FRAMES - 1)
        layer = scale_alpha(layer, max(0.04, 1.0 - t))
        big.alpha_composite(layer)
        add_flecks(big, direction, frame, t)
    else:
        big.alpha_composite(layer)
    return big.resize((CELL, CELL), Image.LANCZOS)


def render_sheet(anim: str, cols: int) -> Image.Image:
    sheet = Image.new("RGBA", (cols * CELL, len(DIRS) * CELL), (0, 0, 0, 0))
    for row, direction in enumerate(DIRS):
        for col in range(cols):
            cell = render_cell(direction, anim, col)
            sheet.paste(cell, (col * CELL, row * CELL), cell)
    return sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    anims = {"idle": 4, "walk": 6, "attack": 4, "hit": 2, "death": 6}
    sheets = {}
    for anim, cols in anims.items():
        sh = render_sheet(anim, cols)
        path = os.path.join(OUT_DIR, f"hollow_{anim}.png")
        sh.save(path)
        sheets[anim] = sh
        print(f"wrote {path}  ({sh.width}x{sh.height}, {cols} frames/dir)")

    maxw = max(s.width for s in sheets.values())
    toth = sum(s.height for s in sheets.values())
    preview = Image.new("RGBA", (maxw, toth), (0, 0, 0, 0))
    y = 0
    for anim in anims:
        preview.paste(sheets[anim], (0, y), sheets[anim])
        y += sheets[anim].height
    ppath = os.path.join(OUT_DIR, "hollow_topdown_preview.png")
    preview.save(ppath)
    print(f"wrote {ppath}  ({preview.width}x{preview.height})")


if __name__ == "__main__":
    main()
