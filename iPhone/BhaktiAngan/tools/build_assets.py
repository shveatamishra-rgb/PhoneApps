#!/usr/bin/env python3
"""Build the app icon and optimized devotional image asset catalog."""

from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image, ImageOps


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = PROJECT_ROOT / "BhaktiAngan" / "Resources" / "Assets.xcassets"
DEFAULT_SOURCE = Path(
    "/Users/shveatamishra/Projects/DivineStillnessOm/"
    "60 day Divine Stillness Om Content"
)
DEFAULT_MARK = Path(
    "/Users/shveatamishra/Projects/DivineStillnessOm/youtube_assets/"
    "divine-stillness-om-video-watermark-transparent-source.png"
)


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def imageset(name: str, filename: str) -> None:
    folder = ASSET_ROOT / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    write_json(
        folder / "Contents.json",
        {
            "images": [
                {"filename": filename, "idiom": "universal", "scale": "1x"},
                {"idiom": "universal", "scale": "2x"},
                {"idiom": "universal", "scale": "3x"},
            ],
            "info": {"author": "xcode", "version": 1},
        },
    )


def build_devotional_images(source: Path) -> None:
    files = sorted(
        source.glob("day*.png"),
        key=lambda item: int(item.stem.split("_")[0].replace("day", "")),
    )
    if len(files) != 60:
        raise RuntimeError(f"Expected 60 devotional PNGs, found {len(files)} in {source}")

    for source_path in files:
        folder = ASSET_ROOT / f"{source_path.stem}.imageset"
        output_name = f"{source_path.stem}.jpg"
        output_path = folder / output_name
        folder.mkdir(parents=True, exist_ok=True)

        with Image.open(source_path) as image:
            image = image.convert("RGB")
            image.save(
                output_path,
                "JPEG",
                quality=84,
                optimize=True,
                progressive=True,
                subsampling="4:2:0",
            )
        imageset(source_path.stem, output_name)


def build_brand_assets(mark_path: Path) -> None:
    with Image.open(mark_path) as mark:
        mark = mark.convert("RGBA")

        brand = Image.new("RGBA", (640, 640), (0, 0, 0, 0))
        fitted = ImageOps.contain(mark, (600, 600), Image.Resampling.LANCZOS)
        brand.alpha_composite(fitted, ((640 - fitted.width) // 2, (640 - fitted.height) // 2))
        brand_folder = ASSET_ROOT / "BrandMark.imageset"
        brand_folder.mkdir(parents=True, exist_ok=True)
        brand.save(brand_folder / "BrandMark.png", optimize=True)
        imageset("BrandMark", "BrandMark.png")

        icon = Image.new("RGB", (1024, 1024), (54, 14, 33))
        fitted_icon = ImageOps.contain(mark, (880, 880), Image.Resampling.LANCZOS)
        icon.paste(
            fitted_icon,
            ((1024 - fitted_icon.width) // 2, (1024 - fitted_icon.height) // 2),
            fitted_icon,
        )
        icon_folder = ASSET_ROOT / "AppIcon.appiconset"
        icon_folder.mkdir(parents=True, exist_ok=True)
        icon.save(icon_folder / "AppIcon-1024.png", "PNG", optimize=True)
        write_json(
            icon_folder / "Contents.json",
            {
                "images": [
                    {
                        "filename": "AppIcon-1024.png",
                        "idiom": "universal",
                        "platform": "ios",
                        "size": "1024x1024",
                    }
                ],
                "info": {"author": "xcode", "version": 1},
            },
        )


def build_colors() -> None:
    write_json(
        ASSET_ROOT / "AccentColor.colorset" / "Contents.json",
        {
            "colors": [
                {
                    "color": {
                        "color-space": "srgb",
                        "components": {
                            "alpha": "1.000",
                            "blue": "0.080",
                            "green": "0.180",
                            "red": "0.720",
                        },
                    },
                    "idiom": "universal",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        },
    )
    write_json(
        ASSET_ROOT / "LaunchBackground.colorset" / "Contents.json",
        {
            "colors": [
                {
                    "color": {
                        "color-space": "srgb",
                        "components": {
                            "alpha": "1.000",
                            "blue": "0.910",
                            "green": "0.960",
                            "red": "0.980",
                        },
                    },
                    "idiom": "universal",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        },
    )


def main() -> None:
    source = Path(os.environ.get("DIVINE_STILLNESS_SOURCE_IMAGES", DEFAULT_SOURCE))
    mark = Path(os.environ.get("DIVINE_STILLNESS_BRAND_MARK", DEFAULT_MARK))

    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    write_json(ASSET_ROOT / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    build_colors()
    build_brand_assets(mark)
    build_devotional_images(source)


if __name__ == "__main__":
    main()
