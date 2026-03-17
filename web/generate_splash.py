#!/usr/bin/env python3
"""
Ibex Classroom — iOS Splash Screen Generator
=============================================
Generates all required Apple launch images for iOS PWA.
Each splash uses the app's dark background (#0A0E21) with the
centered logo placeholder.

Run this script from the flutter_app/web/ directory:
    python3 generate_splash.py

Requirements: Pillow
    pip install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

BG_COLOR = (10, 14, 33)        # #0A0E21
PRIMARY_COLOR = (41, 121, 255)  # #2979FF
TEXT_COLOR = (255, 255, 255)    # White

# iOS splash screen sizes (width x height in pixels)
SPLASH_SIZES = [
    (2048, 2732, "apple-splash-2048-2732.png"),   # iPad Pro 12.9"
    (1668, 2388, "apple-splash-1668-2388.png"),   # iPad Pro 11"
    (1640, 2360, "apple-splash-1640-2360.png"),   # iPad Air 10.9"
    (1290, 2796, "apple-splash-1290-2796.png"),   # iPhone 14 Pro Max
    (1179, 2556, "apple-splash-1179-2556.png"),   # iPhone 14 Pro
    (1170, 2532, "apple-splash-1170-2532.png"),   # iPhone 14 / 13 / 12
    (1242, 2688, "apple-splash-1242-2688.png"),   # iPhone 11 Pro Max / XS Max
    (828, 1792, "apple-splash-828-1792.png"),     # iPhone 11 / XR
    (1125, 2436, "apple-splash-1125-2436.png"),   # iPhone X / XS / 11 Pro
    (1242, 2208, "apple-splash-1242-2208.png"),   # iPhone 8 Plus
    (750, 1334, "apple-splash-750-1334.png"),     # iPhone 8 / SE
]

def create_splash(width, height, filename, output_dir):
    img = Image.new("RGB", (width, height), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Draw circular gradient-ish logo background
    logo_size = min(width, height) // 6
    logo_x = (width - logo_size) // 2
    logo_y = (height - logo_size) // 2 - logo_size // 3

    # Draw blue rounded rect (logo placeholder)
    draw.rounded_rectangle(
        [logo_x, logo_y, logo_x + logo_size, logo_y + logo_size],
        radius=logo_size // 5,
        fill=PRIMARY_COLOR
    )

    # Draw graduation cap emoji text (best effort — system font)
    try:
        font_size = logo_size // 2
        font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", font_size)
    except:
        font = ImageFont.load_default()

    emoji = "🎓"
    try:
        bbox = draw.textbbox((0, 0), emoji, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        draw.text(
            (logo_x + (logo_size - text_w) / 2,
             logo_y + (logo_size - text_h) / 2 - bbox[1]),
            emoji, font=font
        )
    except:
        pass

    # App name label below logo
    try:
        label_font_size = logo_size // 4
        label_font = ImageFont.truetype(
            "/System/Library/Fonts/Helvetica.ttc", label_font_size
        ) if os.path.exists("/System/Library/Fonts/Helvetica.ttc") else ImageFont.load_default()
    except:
        label_font = ImageFont.load_default()

    label = "Ibex Classroom"
    try:
        bbox = draw.textbbox((0, 0), label, font=label_font)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        draw.text(
            ((width - lw) / 2, logo_y + logo_size + logo_size // 6),
            label,
            fill=(*TEXT_COLOR, 179),  # Semi-transparent white
            font=label_font
        )
    except:
        pass

    out_path = os.path.join(output_dir, filename)
    img.save(out_path, "PNG", optimize=True)
    print(f"  ✅ {filename} ({width}x{height})")

def main():
    output_dir = os.path.join(os.path.dirname(__file__), "splash")
    os.makedirs(output_dir, exist_ok=True)

    print("\n🎨 Generating iOS splash screens...\n")
    for width, height, filename in SPLASH_SIZES:
        create_splash(width, height, filename, output_dir)

    print(f"\n✅ Done! {len(SPLASH_SIZES)} splash screens saved to: {output_dir}\n")
    print("Next: Copy the splash/ folder to flutter_app/web/splash/ and commit.")

if __name__ == "__main__":
    main()
