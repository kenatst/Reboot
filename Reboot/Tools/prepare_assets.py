#!/usr/bin/env python3
"""Build-time asset preparation for REBOOT.

Preprocesses the supplied onboarding artwork (RGB line work on near-black
backgrounds) into RGBA PNGs that blend naturally onto VOID, and generates
the application icon with native geometric shapes.

Run from the repository root:
    python3 Reboot/Tools/prepare_assets.py
"""

from __future__ import annotations

import json
import math
import os
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS = os.path.join(ROOT, "Reboot", "Resources", "Assets.xcassets")
TOOL_DIR = os.path.join(ROOT, "Reboot", "Tools")

# (source filename, semantic asset name)
ART_MAP = [
    ("page1.png", "OnboardingOverload"),
    ("page2.png", "OnboardingDiagnostic"),
    ("page3.png", "OnboardingRecovery"),
    ("page4.png", "OnboardingProtocol"),
    ("page5.png", "OnboardingActivation"),
    ("page6.png", "OnboardingSignal"),
]

VOID = (8, 10, 9)
SIGNAL_RED = (255, 68, 56)
SIGNAL_CYAN = (87, 230, 255)


def luminance(px):
    r, g, b = px
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def prepare_artwork(src_dir: str) -> None:
    for src, name in ART_MAP:
        path = os.path.join(src_dir, src)
        im = Image.open(path).convert("RGB")
        w, h = im.size
        rgba = Image.new("RGBA", (w, h), VOID + (0,))
        src_px = im.load()
        out_px = rgba.load()
        for y in range(h):
            for x in range(w):
                p = src_px[x, y]
                lum = luminance(p)
                # Soft threshold: pure black becomes fully transparent,
                # bright line work becomes fully opaque.
                t = max(0.0, min(1.0, (lum - 12.0) / 62.0))
                alpha = int(round(255.0 * (t ** 1.15)))
                out_px[x, y] = (p[0], p[1], p[2], alpha)
        # Slight vertical feather so a hard rectangle never appears.
        alpha_channel = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(0.5))
        rgba.putalpha(alpha_channel)
        out = os.path.join(ASSETS, f"{name}.imageset", f"{name}.png")
        rgba.save(out)
        print(f"wrote {out} ({w}x{h})")


def prepare_icon() -> None:
    appicon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    size = 1024
    im = Image.new("RGBA", (size, size), VOID + (255,))
    d = ImageDraw.Draw(im)

    cx, cy = 512, 496
    radius = 300
    stroke = 74
    gap_angle_deg = 44.0

    # Main ring: SIGNAL_RED arc with a gap at ~55 degrees (top-right).
    start = -90 - gap_angle_deg / 2
    end = -90 + gap_angle_deg / 2
    d.arc(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        start=start + 360 - gap_angle_deg,
        end=360 + start,
        fill=SIGNAL_RED + (255,),
        width=stroke,
    )

    # Cyan closing segment inside the gap (the recovered signal).
    inner = radius - stroke / 2
    d.arc(
        [cx - inner, cy - inner, cx + inner, cy + inner],
        start=start - 3,
        end=end + 3,
        fill=SIGNAL_CYAN + (255,),
        width=stroke,
    )

    # Short power stem descending from the gap.
    stem_w = 52
    stem_top = cy + radius * 0.12
    stem_bot = cy + radius * 0.52
    stem_cx = cx + math.sin(math.radians(-90)) * 0
    d.rounded_rectangle(
        [stem_cx - stem_w / 2, stem_top, stem_cx + stem_w / 2, stem_bot],
        radius=stem_w / 2,
        fill=SIGNAL_CYAN + (255,),
    )

    # Anti-aliased downscale from 4x for crisp edges.
    im = im.resize((1024, 1024), Image.LANCZOS)
    out = os.path.join(appicon_dir, "AppIcon1024.png")
    im.save(out)
    print(f"wrote {out}")


def write_contents() -> None:
    for _, name in ART_MAP:
        imageset_dir = os.path.join(ASSETS, f"{name}.imageset")
        with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
            json.dump(
                {
                    "images": [
                        {
                            "filename": f"{name}.png",
                            "idiom": "universal",
                            "scale": "1x",
                        }
                    ],
                    "info": {"author": "xcode", "version": 1},
                },
                f,
                indent=2,
            )

    icon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
        json.dump(
            {
                "images": [
                    {
                        "filename": "AppIcon1024.png",
                        "idiom": "universal",
                        "platform": "ios",
                        "size": "1024x1024",
                    }
                ],
                "info": {"author": "xcode", "version": 1},
            },
            f,
            indent=2,
        )
    print("wrote asset catalog Contents.json files")


def main() -> None:
    src = os.environ.get("REBOOT_ART_SRC", "/tmp/reboot-art/onb no wr")
    os.makedirs(os.path.join(ASSETS, "AppIcon.appiconset"), exist_ok=True)
    for _, name in ART_MAP:
        os.makedirs(os.path.join(ASSETS, f"{name}.imageset"), exist_ok=True)
    prepare_artwork(src)
    prepare_icon()
    write_contents()


if __name__ == "__main__":
    main()
