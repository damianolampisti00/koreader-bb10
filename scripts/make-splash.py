#!/usr/bin/env python3
"""Make the BB10 splash images: the KOReader logo with its name below, on white (light) and black
(dark, for night mode). Only the logo's area: ffi/framebuffer_bb10.lua centers it on a screen
filled with the background color.

Usage: make-splash.py <koreader.svg> <NotoSans-Bold.ttf> <outdir>
       → <outdir>/splash-light.png, <outdir>/splash-dark.png
Needs rsvg-convert and Pillow (host side).
"""
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

LOGO = 240         # logo size, px (the Q10's screen is 720x720)
TEXT = 46          # name font size, px
GAP = 28           # between the logo and the name
PAD = 8


def main():
    svg, font_file, outdir = sys.argv[1:]
    os.makedirs(outdir, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        png = os.path.join(tmp, "logo.png")
        subprocess.run(["rsvg-convert", "-w", str(LOGO), "-h", str(LOGO), "-o", png, svg], check=True)
        logo = Image.open(png).convert("RGBA")
    font = ImageFont.truetype(font_file, TEXT)
    name = "KOReader"
    left, top, right, bottom = font.getbbox(name)
    text_w, text_h = right - left, bottom - top
    width = max(LOGO, text_w) + 2 * PAD
    height = LOGO + GAP + text_h + 2 * PAD
    for variant, bg, fg in (("light", (255, 255, 255), (34, 34, 34)), ("dark", (0, 0, 0), (221, 221, 221))):
        img = Image.new("RGB", (width, height), bg)
        img.paste(logo, ((width - LOGO) // 2, PAD), logo)
        ImageDraw.Draw(img).text(((width - text_w) // 2 - left, PAD + LOGO + GAP - top), name, font=font, fill=fg)
        img.save(os.path.join(outdir, "splash-%s.png" % variant), optimize=True)
    print("splash %dx%d" % (width, height))


if __name__ == "__main__":
    main()
