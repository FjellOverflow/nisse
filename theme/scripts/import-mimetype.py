#!/usr/bin/env python3
"""Recolour a full-colour mimetype icon into the Nord palette from tokens.json.

Usage: import-mimetype.py SOURCE.svg DEST.svg

Greys map onto a polar night to snow storm ramp, every other hue onto a frost ramp, both by lightness.
"""
import colorsys
import json
import os
import re
import sys

HASH = re.compile(r"(url\(|href=\")?#([0-9A-Za-z_-]+)")
PAINT = re.compile(r"(?:fill|stroke|stop-color|flood-color|lighting-color|color)\s*[:=]\s*\"?\s*([a-zA-Z]+)\b")
PAINT_KEYWORDS = {"none", "currentcolor", "url", "inherit", "transparent"}


def rgb(value):
    value = value.lstrip("#")
    if len(value) == 3:
        value = "".join(c * 2 for c in value)
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def to_hex(colour):
    return "#" + "".join(f"{round(max(0.0, min(1.0, v)) * 255):02x}" for v in colour)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def ramp(stops, t):
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t <= t1:
            return mix(c0, c1, (t - t0) / (t1 - t0))
    return stops[-1][1]


def ramps():
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tokens.json")) as f:
        tokens = json.load(f)
    c = {k: rgb(v) for k, v in tokens["colors"].items() if v.startswith("#")}
    grey = [(0, c["bg0"]), (0.2, c["bg1"]), (0.4, c["bg3"]), (1, c["fg"])]
    frost = [(0, c["bg1"]), (0.25, c["accent_bg"]), (0.5, rgb(tokens["icons"]["bg"])), (0.75, c["accent"]),
             (1, mix(c["accent"], c["fg_bright"], 0.5))]
    return grey, frost


def recolour(svg, grey, frost):
    unsupported = {m.group(1) for m in PAINT.finditer(svg) if m.group(1).lower() not in PAINT_KEYWORDS}
    if unsupported:
        raise ValueError(f"unsupported colours: {', '.join(sorted(unsupported))}")

    def replace(match):
        reference, value = match.groups()
        if reference:
            return match.group(0)
        if len(value) not in (3, 6) or not all(c in "0123456789abcdefABCDEF" for c in value):
            raise ValueError(f"unsupported colour: #{value}")
        r, g, b = rgb(value)
        _, lightness, saturation = colorsys.rgb_to_hls(r, g, b)
        neutral = saturation < 0.18 or max(r, g, b) - min(r, g, b) < 0.08
        return to_hex(ramp(grey if neutral else frost, lightness))
    return HASH.sub(replace, svg)


def main(source, dest):
    with open(source) as f:
        svg = f.read()
    try:
        svg = recolour(svg, *ramps())
    except ValueError as error:
        sys.exit(f"{source}: {error}")
    with open(dest, "w") as f:
        f.write(svg)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip())
    main(*sys.argv[1:])
