#!/usr/bin/env python3
"""Generate deterministic tangent-space normal maps for the 2D art set.

The source art does not ship with authored height maps, so this tool treats
alpha-weighted luminance as a conservative height estimate. It intentionally
uses no random state and preserves the source alpha channel. Running it twice
with the same Pillow/numpy versions and settings produces byte-identical PNGs.

Default usage generates the environment, prop, player and enemy maps used by
LightingDirector::

    python tools/generate_normal_maps.py

Use ``--all`` to include every processed PNG (UI/effects included), or
``--check`` in CI to verify that generated pixels are current without writing.
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    import numpy as np
    from PIL import Image, ImageFilter
except ImportError as exc:  # pragma: no cover - actionable CLI failure
    raise SystemExit(
        "Normal-map generation requires Pillow and numpy. "
        "Install them with: python -m pip install pillow numpy"
    ) from exc


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_ROOT = PROJECT_ROOT / "assets" / "processed"
NORMAL_ROOT = PROCESSED_ROOT / "normals"

# These folders contain the surfaces that receive real-time light in gameplay.
# Sorting during discovery makes both output order and summary hashes stable.
DEFAULT_FOLDERS = (
    "decals",
    "demo_ground_tiles",
    "enemy_walk_rebuild",
    "environment",
    "environment_landmarks_v2",
    "environment_rebuild",
    "hollow_topdown",
    "interior_identity",
    "loot_containers",
    "petrol_station_props",
    "player_topdown",
    "player_walk_v2",
    "railhome_props",
    "roadside_props",
    "trace_anchors",
)
DEFAULT_EXTRA_FILES = (
    "scanner_memory_effects/memory_echo_core.png",
    "scanner_memory_effects/mnemoscope_device.png",
)
EXCLUDED_STEMS = {
    "hollow_topdown_preview",
    "player_topdown_preview",
}


@dataclass(frozen=True)
class Settings:
    strength: float = 5.5
    blur: float = 1.15
    alpha_height: float = 0.28


def discover_inputs(include_all: bool) -> list[Path]:
    if include_all:
        candidates = [
            path
            for path in PROCESSED_ROOT.rglob("*.png")
            if NORMAL_ROOT not in path.parents
        ]
    else:
        candidates: list[Path] = []
        for folder in DEFAULT_FOLDERS:
            candidates.extend((PROCESSED_ROOT / folder).glob("*.png"))
        candidates.extend(PROCESSED_ROOT / relative for relative in DEFAULT_EXTRA_FILES)

    return sorted(
        (
            path
            for path in candidates
            if path.is_file() and path.stem not in EXCLUDED_STEMS
        ),
        key=lambda path: path.relative_to(PROCESSED_ROOT).as_posix(),
    )


def output_path_for(source: Path) -> Path:
    relative = source.relative_to(PROCESSED_ROOT)
    return NORMAL_ROOT / relative.parent / f"{relative.stem}_normal.png"


def generate_pixels(source: Path, settings: Settings) -> np.ndarray:
    rgba = np.asarray(Image.open(source).convert("RGBA"), dtype=np.float32) / 255.0
    alpha = rgba[..., 3]

    # Rec. 709 luminance gives painted highlights slightly more influence than
    # saturated color. Alpha contributes a restrained silhouette bevel.
    luminance = (
        rgba[..., 0] * 0.2126
        + rgba[..., 1] * 0.7152
        + rgba[..., 2] * 0.0722
    )
    height = (
        luminance * (1.0 - settings.alpha_height)
        + alpha * settings.alpha_height
    ) * alpha

    if settings.blur > 0.0:
        height_image = Image.fromarray(
            np.clip(height * 255.0 + 0.5, 0, 255).astype(np.uint8), mode="L"
        )
        height = np.asarray(
            height_image.filter(ImageFilter.GaussianBlur(settings.blur)),
            dtype=np.float32,
        ) / 255.0

    # Godot CanvasTexture expects X+, Y+, Z+ tangent-space coordinates.
    gradient_y, gradient_x = np.gradient(height)
    normal_x = -gradient_x * settings.strength
    normal_y = -gradient_y * settings.strength
    normal_z = np.ones_like(height)

    length = np.sqrt(normal_x * normal_x + normal_y * normal_y + normal_z * normal_z)
    normal_x /= length
    normal_y /= length
    normal_z /= length

    out = np.empty(rgba.shape, dtype=np.uint8)
    out[..., 0] = np.clip((normal_x * 0.5 + 0.5) * 255.0 + 0.5, 0, 255).astype(np.uint8)
    out[..., 1] = np.clip((normal_y * 0.5 + 0.5) * 255.0 + 0.5, 0, 255).astype(np.uint8)
    out[..., 2] = np.clip((normal_z * 0.5 + 0.5) * 255.0 + 0.5, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(alpha * 255.0 + 0.5, 0, 255).astype(np.uint8)

    # Fully transparent texels use the exact flat normal to avoid edge color
    # bleeding under bilinear filtering.
    transparent = out[..., 3] == 0
    out[transparent, 0] = 128
    out[transparent, 1] = 128
    out[transparent, 2] = 255
    return out


def pixels_match(path: Path, expected: np.ndarray) -> bool:
    if not path.exists():
        return False
    actual = np.asarray(Image.open(path).convert("RGBA"), dtype=np.uint8)
    return actual.shape == expected.shape and bool(np.array_equal(actual, expected))


def write_png(path: Path, pixels: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pixels, mode="RGBA").save(
        path,
        format="PNG",
        compress_level=9,
        optimize=False,
    )


def digest_outputs(paths: Iterable[Path]) -> str:
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(PROJECT_ROOT).as_posix().encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest().upper()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="Generate every processed PNG.")
    parser.add_argument("--check", action="store_true", help="Verify outputs without writing.")
    parser.add_argument("--strength", type=float, default=Settings.strength)
    parser.add_argument("--blur", type=float, default=Settings.blur)
    parser.add_argument("--alpha-height", type=float, default=Settings.alpha_height)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    settings = Settings(args.strength, args.blur, args.alpha_height)
    if settings.strength <= 0.0 or settings.blur < 0.0:
        raise SystemExit("--strength must be positive and --blur cannot be negative.")
    if not 0.0 <= settings.alpha_height <= 1.0:
        raise SystemExit("--alpha-height must be between 0 and 1.")

    sources = discover_inputs(args.all)
    if not sources:
        raise SystemExit(f"No source PNGs found under {PROCESSED_ROOT}")

    stale: list[Path] = []
    outputs: list[Path] = []
    for source in sources:
        output = output_path_for(source)
        expected = generate_pixels(source, settings)
        outputs.append(output)
        if pixels_match(output, expected):
            print(f"OK       {output.relative_to(PROJECT_ROOT).as_posix()}")
            continue
        stale.append(output)
        if args.check:
            print(f"STALE    {output.relative_to(PROJECT_ROOT).as_posix()}")
        else:
            write_png(output, expected)
            print(f"WROTE    {output.relative_to(PROJECT_ROOT).as_posix()}")

    if args.check and stale:
        print(f"Normal maps are stale or missing: {len(stale)}/{len(outputs)}", file=sys.stderr)
        return 1

    print(
        f"Normal maps: {len(outputs)} files; "
        f"pixel set SHA-256 {digest_outputs(outputs)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
