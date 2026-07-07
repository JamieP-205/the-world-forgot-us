#!/usr/bin/env python
"""Chroma-key + slice the generated asset sheets for The World Forgot Us.

The generated pack ships as flat PNGs on a bright green screen, and most
files are multi-object sheets (3-10 separate props/icons/effects per image).
This tool:

  1. Removes the green background with a soft chroma key + green despill,
     so edges don't keep a green halo.
  2. Finds each distinct object on the sheet via connected-component
     labelling (with dilation so an object's detached parts -- straps,
     dangling handset, scrap chips -- stay grouped as one object).
  3. Sorts the objects into reading order (rows top->bottom, left->right)
     and writes each to its own trimmed, padded, transparent PNG using the
     names given per sheet.

Originals are never modified; outputs go to assets/processed/<sheet>/.

Run from the project root:  python tools/chroma_extract_assets.py
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "source" / "generated"
OUT = ROOT / "assets" / "processed"

# Chroma-key thresholds on "greenness" = G - max(R, B).
GREEN_HI = 120   # >= this is definitely background -> fully transparent
GREEN_LO = 40    # <= this is definitely foreground -> fully opaque
PAD = 8          # transparent padding around each trimmed crop


def chroma_key(im: Image.Image) -> np.ndarray:
    """Return an RGBA float array with the green screen removed + despilled."""
    rgb = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    max_rb = np.maximum(r, b)
    greenness = g - max_rb

    alpha = np.clip((GREEN_HI - greenness) / (GREEN_HI - GREEN_LO), 0.0, 1.0)

    # Despill: pull the green channel down to the other channels wherever
    # green dominates. Leaves legit cyans/browns (g <= max(r,b)) untouched.
    g_despilled = np.minimum(g, max_rb)

    out = np.dstack([r, g_despilled, b, alpha * 255.0])
    return out.astype(np.uint8)


def find_objects(alpha: np.ndarray, dilate: int, min_area: int):
    """Return component bounding-box slices in reading order."""
    content = alpha > 64
    if dilate > 0:
        content_d = ndimage.binary_dilation(content, iterations=dilate)
    else:
        content_d = content
    labels, n = ndimage.label(content_d)

    boxes = []
    for i in range(1, n + 1):
        ys, xs = np.where(labels == i)
        # Real (undilated) area, so faint dilation halos don't inflate size.
        area = int(np.count_nonzero(content[ys.min():ys.max() + 1,
                                            xs.min():xs.max() + 1] &
                                    (labels[ys.min():ys.max() + 1,
                                            xs.min():xs.max() + 1] == i)))
        if area < min_area:
            continue
        boxes.append((ys.min(), ys.max(), xs.min(), xs.max()))

    # Reading order: band into rows by vertical centre, then sort by x.
    boxes.sort(key=lambda bb: (bb[0] + bb[1]) / 2)
    rows, cur = [], []
    row_ref = None
    for bb in boxes:
        cy = (bb[0] + bb[1]) / 2
        h = bb[1] - bb[0]
        if row_ref is None or abs(cy - row_ref) < max(120, h * 0.6):
            cur.append(bb)
            row_ref = cy if row_ref is None else (row_ref + cy) / 2
        else:
            rows.append(cur)
            cur = [bb]
            row_ref = cy
    if cur:
        rows.append(cur)

    ordered = []
    for row in rows:
        ordered.extend(sorted(row, key=lambda bb: (bb[2] + bb[3]) / 2))
    return ordered


def trim_and_save(rgba: np.ndarray, box, path: Path):
    y0, y1, x0, x1 = box
    crop = rgba[y0:y1 + 1, x0:x1 + 1].copy()
    a = crop[..., 3]
    ys, xs = np.where(a > 24)
    if len(ys) == 0:
        return False
    ty0, ty1, tx0, tx1 = ys.min(), ys.max(), xs.min(), xs.max()
    crop = crop[ty0:ty1 + 1, tx0:tx1 + 1]
    padded = np.zeros((crop.shape[0] + PAD * 2, crop.shape[1] + PAD * 2, 4),
                      dtype=np.uint8)
    padded[PAD:PAD + crop.shape[0], PAD:PAD + crop.shape[1]] = crop
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(padded, "RGBA").save(path)
    return True


def slice_sheet(rel, names, dilate=16, min_area=2500):
    src = SRC / rel
    sheet_out = OUT / Path(rel).stem
    im = Image.open(src)
    rgba = chroma_key(im)
    boxes = find_objects(rgba[..., 3], dilate, min_area)
    print(f"\n{rel}: found {len(boxes)} objects (expected {len(names)})")
    for idx, box in enumerate(boxes):
        name = names[idx] if idx < len(names) else f"extra_{idx:02d}"
        ok = trim_and_save(rgba, box, sheet_out / f"{name}.png")
        h, w = box[1] - box[0], box[3] - box[2]
        print(f"  [{idx}] {name:24s} {w}x{h}  {'ok' if ok else 'EMPTY'}")
    return len(boxes) == len(names)


def slice_grid_dark(rel, rows, cols, names):
    """Grid-slice a sheet that sits on a dark (non-green) background."""
    src = SRC / rel
    sheet_out = OUT / Path(rel).stem
    im = Image.open(src).convert("RGBA")
    arr = np.asarray(im)
    H, W = arr.shape[:2]
    ch, cw = H // rows, W // cols
    print(f"\n{rel}: grid {rows}x{cols} cells of {cw}x{ch}")
    k = 0
    for ry in range(rows):
        for cx in range(cols):
            name = names[k] if k < len(names) else f"cell_{k:02d}"
            k += 1
            cell = arr[ry * ch:(ry + 1) * ch, cx * cw:(cx + 1) * cw]
            # Trim uniform dark margins around the cell content.
            lum = cell[..., :3].max(axis=2)
            ys, xs = np.where(lum > 70)
            if len(ys) == 0:
                continue
            crop = cell[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
            sheet_out.mkdir(parents=True, exist_ok=True)
            Image.fromarray(crop, "RGBA").save(sheet_out / f"{name}.png")
    print(f"  wrote {k} cells")


SHEETS = {
    "world/props/loot_containers.png": [
        "crate_wood_closed", "crate_wood_open", "toolbox_metal_closed",
        "toolbox_metal_open", "locker_metal", "scrap_pile",
    ],
    "items/item_icons_pack_01.png": [
        "icon_scrap", "icon_battery", "icon_canned_food", "icon_old_photo",
        "icon_childs_lunchbox",
        "icon_medicine", "icon_fuel", "icon_tools", "icon_electronics",
        "icon_compass",
    ],
    "base/railhome_props.png": [
        "bedroll", "storage_chest", "workbench_empty", "radio_desk",
        "lantern", "workbench_tools", "map_wall", "base_doorway",
    ],
    "world/props/petrol_station_props.png": [
        "petrol_pump", "station_sign_tall", "station_counter",
        "vending_machine", "phone_booth", "warning_barrier",
    ],
    "world/props/roadside_props.png": [
        "broken_car", "road_sign", "backpack", "portable_radio",
        "missing_person_poster", "debris_pile", "traffic_cone", "guardrail",
    ],
    "scanner_memory/scanner_memory_effects.png": [
        "mnemoscope_device", "scanner_pulse_ring", "cyan_sparkles",
        "memory_echo_core", "recovery_burst", "signal_sparks", "cyan_dust",
    ],
    "effects/effects_pack_01.png": [
        "hit_spark", "hollow_dissolve", "sparkle_star", "pulse_ring_small",
        "loot_glow_chest",
        "amber_pillar", "ash_dust", "radio_waves", "glow_cone_amber",
        "glow_cone_cyan",
    ],
}

# Concept-style character sheets: sliced for reference only (not top-down).
CHARACTER_SHEETS = {
    "characters/player/player_4dir_concept.png": [
        "player_front", "player_back", "player_side_r", "player_side_l",
    ],
    "characters/hollow/hollow_concept_sheet.png": [
        "hollow_idle", "hollow_shamble", "hollow_attack", "hollow_charged",
        "hollow_dissolve",
    ],
}


def main():
    ok = True
    for rel, names in SHEETS.items():
        ok &= slice_sheet(rel, names)
    for rel, names in CHARACTER_SHEETS.items():
        slice_sheet(rel, names, dilate=10, min_area=8000)
    # Ground tiles sit on a dark background: 3 rows of ground + 1 barrier row.
    slice_grid_dark("world/tiles/demo_ground_tiles.png", 4, 4, [
        "asphalt_cracked", "asphalt_lane", "dirt_gravel", "dirt_grass",
        "gravel_rubble", "dirt_debris", "cobble_broken", "concrete_broken",
        "rubble_planks", "rubble_metal", "metal_floor", "wood_floor",
        "barrier_concrete", "barrier_wood", "wall_broken", "barricade_sandbag",
    ])
    print("\nDONE." if ok else "\nDONE (some sheets had count mismatch -- review).")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
