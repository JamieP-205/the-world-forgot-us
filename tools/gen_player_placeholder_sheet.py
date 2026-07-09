#!/usr/bin/env python3
"""Generate a functional TOP-DOWN placeholder sprite sheet for the survivor.

This is a *blockout* stand-in (clean shapes, not painterly art) so the player can
be wired into an AnimatedSprite2D today, replacing the single Polygon2D. Real
illustrated art (see CHARACTER_ASSET_PROMPTS_PASS_11.md) can drop in later.

Output: assets/processed/player_topdown/
  player_idle.png    (4 rows x 4 cols)
  player_walk.png    (4 rows x 6 cols)
  player_attack.png  (4 rows x 4 cols)
  player_hurt.png    (4 rows x 2 cols)
  player_topdown_preview.png  (all four stacked, for eyeballing)

Grid: 96x96 cells. Rows (top->bottom) = facing DOWN, UP, LEFT, RIGHT
(canonical order, matches CHARACTER_SPRITE_SPEC.md). Columns = animation frames.
Transparent background, no baked shadow, figure centred, feet near a common
baseline, consistent scale.
"""
from __future__ import annotations
import math
import os
from PIL import Image, ImageDraw

CELL = 96
SS = 4  # supersample factor for smooth edges
# Canonical row order (matches CHARACTER_SPRITE_SPEC.md): down / up / left / right.
DIRS = ["down", "up", "left", "right"]
FV = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0)}

# --- palette (rust-brown coat, amber accent, cyan memory-tech) ---------------
COAT       = (122, 74, 48, 255)
COAT_DARK  = (92, 55, 36, 255)
PACK       = (42, 38, 34, 255)
PACK_LINE  = (60, 52, 42, 255)
SKIN       = (201, 168, 124, 255)
HOOD       = (74, 53, 36, 255)
AMBER      = (230, 165, 61, 255)
CYAN       = (95, 208, 222, 255)
BOOT       = (46, 39, 31, 255)
ARM        = (104, 63, 41, 255)

OUT_DIR = os.path.join("assets", "processed", "player_topdown")


def ellipse(d, cx, cy, rx, ry, color):
    d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=color)


def line(d, x0, y0, x1, y1, color, w=2):
    d.line([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=color, width=int(w * SS))


def pose(anim: str, frame: int):
    """Return per-frame motion params."""
    p = {"body_dy": 0.0, "arm": 0.0, "leg": 0.0, "reach": None, "arc": 0.0, "back": 0.0}
    if anim == "idle":
        p["body_dy"] = [0, -1, -1, 0][frame]
    elif anim == "walk":
        t = frame / 6.0
        s = math.sin(2 * math.pi * t)
        p["body_dy"] = -abs(math.sin(2 * math.pi * t)) * 2.0
        p["arm"] = s * 4.0
        p["leg"] = s * 4.0
    elif anim == "attack":
        p["reach"] = [-4.0, 10.0, 13.0, 3.0][frame]
        p["arc"] = [0.0, 1.0, 0.55, 0.0][frame]
        p["body_dy"] = [0, -1, 0, 0][frame]
    elif anim == "hurt":
        p["back"] = [4.0, 2.0][frame]
        p["body_dy"] = [-1, 0][frame]
    return p


def draw_character(img: Image.Image, direction: str, anim: str, frame: int):
    d = ImageDraw.Draw(img)
    fx, fy = FV[direction]
    px, py = -fy, fx  # perpendicular (character's left-right axis)
    pp = pose(anim, frame)

    # Whole-body shove for hurt / bob.
    ox = -fx * pp["back"]
    oy = -fy * pp["back"] + pp["body_dy"]
    cx, cy = 48 + ox, 52 + oy          # body centre
    hx, hy = cx + fx * 2, cy - 8 + fy * 2  # head centre (toward top of cell)

    # 1. Legs (below body along the facing axis, alternate for walk).
    legA = pp["leg"]
    lx1, ly1 = cx + px * 5 + fx * legA, cy + 14 + fy * legA
    lx2, ly2 = cx - px * 5 - fx * legA, cy + 14 - fy * legA
    ellipse(d, lx1, ly1, 3.2, 4.6, BOOT)
    ellipse(d, lx2, ly2, 3.2, 4.6, BOOT)

    # 2. Backpack (behind = opposite facing).
    bx, by = cx - fx * 11, cy - fy * 11
    ellipse(d, bx, by, 9, 7.5, PACK)
    ellipse(d, bx, by, 5.5, 4.5, PACK_LINE)
    ellipse(d, bx + px * 3, by + py * 3, 1.6, 1.6, CYAN)  # memory-tech detail

    # 3. Coat body.
    ellipse(d, cx, cy, 14, 12, COAT)
    ellipse(d, cx, cy + 1, 9.5, 8, COAT_DARK)

    # 4. Arms (perpendicular, swing along facing for walk).
    aL = pp["arm"]
    ellipse(d, cx + px * 12 + fx * aL, cy + py * 0 + fy * aL, 4, 4.4, ARM)
    ellipse(d, cx - px * 12 - fx * aL, cy - fy * aL, 4, 4.4, ARM)

    # 5. Attack: forward hand + pale swing arc ahead.
    if pp["reach"] is not None:
        r = pp["reach"]
        ellipse(d, cx + fx * (11 + r), cy + fy * (11 + r), 4.2, 4.2, ARM)
        if pp["arc"] > 0:
            a = int(150 * pp["arc"])
            ax, ay = cx + fx * (16 + r), cy + fy * (16 + r)
            ImageDraw.Draw(img).ellipse(
                [(ax - 10) * SS, (ay - 10) * SS, (ax + 10) * SS, (ay + 10) * SS],
                fill=(240, 226, 180, a))

    # 6. Head + hood.
    ellipse(d, hx, hy, 8, 8, HOOD)
    # Face / scarf only visible when not facing away (up).
    if direction != "up":
        ellipse(d, hx + fx * 3, hy + fy * 3, 4.6, 4.6, SKIN)
        ellipse(d, hx + fx * 5, hy + fy * 5, 3.2, 2.2, AMBER)  # scarf accent
    else:
        ellipse(d, hx, hy, 4.5, 4.5, HOOD)  # back of hood


def render_cell(direction: str, anim: str, frame: int) -> Image.Image:
    big = Image.new("RGBA", (CELL * SS, CELL * SS), (0, 0, 0, 0))
    draw_character(big, direction, anim, frame)
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
    anims = {"idle": 4, "walk": 6, "attack": 4, "hurt": 2}
    sheets = {}
    for anim, cols in anims.items():
        sh = render_sheet(anim, cols)
        path = os.path.join(OUT_DIR, f"player_{anim}.png")
        sh.save(path)
        sheets[anim] = sh
        print(f"wrote {path}  ({sh.width}x{sh.height}, {cols} frames/dir)")

    # Combined preview: animations stacked vertically, left-aligned.
    maxw = max(s.width for s in sheets.values())
    toth = sum(s.height for s in sheets.values())
    preview = Image.new("RGBA", (maxw, toth), (0, 0, 0, 0))
    y = 0
    for anim in anims:
        preview.paste(sheets[anim], (0, y), sheets[anim])
        y += sheets[anim].height
    ppath = os.path.join(OUT_DIR, "player_topdown_preview.png")
    preview.save(ppath)
    print(f"wrote {ppath}  ({preview.width}x{preview.height})")


if __name__ == "__main__":
    main()
