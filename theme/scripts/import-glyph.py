#!/usr/bin/env python3
"""Normalise an SVG into a nordfra glyph: 16x16 viewBox, colours stripped so the template's fill applies.

Usage: import-glyph.py [--silhouette] SOURCE.svg DEST.svg

--silhouette  for a full-colour icon: drop gradients and filters, fill every shape and fit the
              drawn area to the glyph box (needs librsvg's Python bindings)
"""
import re
import sys
import xml.etree.ElementTree as ET

SKIP = {"metadata", "title", "desc", "namedview", "RDF", "style", "script"}
PAINT_SERVERS = {"linearGradient", "radialGradient", "filter"}
XLINK = "{http://www.w3.org/1999/xlink}"
PAINT = re.compile(r"(^|;)\s*(fill|stroke|color)\s*:\s*([^;]*)")


def clean_style(style):
    def keep(m):
        prop, value = m.group(2), m.group(3).strip()
        if prop == "color" or (prop == "fill" and value != "none" and not value.startswith("url")):
            return m.group(1)
        if prop == "stroke" and value != "none" and not value.startswith("url"):
            return f"{m.group(1)}stroke:currentColor"
        return m.group(0)
    return ";".join(p for p in PAINT.sub(keep, style).split(";") if p.strip())


def serialize(el, silhouette):
    tag = el.tag.split("}", 1)[-1]
    if tag in SKIP or (silhouette and tag in PAINT_SERVERS):
        return ""
    attrs = []
    for key, value in el.attrib.items():
        if key == f"{XLINK}href":
            key = "href"
        elif "}" in key or ":" in key or key in ("class", "color"):
            continue
        if silhouette and key == "filter":
            continue
        if silhouette and key in ("fill", "stroke") and value.startswith("url"):
            value = "currentColor"
        if key == "fill" and value != "none" and not value.startswith("url"):
            continue
        if key == "stroke" and value != "none" and not value.startswith("url"):
            value = "currentColor"
        if key == "style":
            value = clean_style(value)
            if not value:
                continue
        attrs.append(f'{key}="{value}"')
    children = "".join(serialize(child, silhouette) for child in el)
    text = (el.text or "").strip() if tag in ("text", "tspan") else ""
    head = " ".join([tag, *attrs])
    return f"<{head}>{text}{children}</{tag}>" if children or text else f"<{head}/>"


def ink_box(source, x, y, w, h):
    import gi
    gi.require_version("Rsvg", "2.0")
    from gi.repository import Rsvg
    viewport = Rsvg.Rectangle()
    viewport.x, viewport.y, viewport.width, viewport.height = 0, 0, w, h
    _, ink, _ = Rsvg.Handle.new_from_file(source).get_geometry_for_layer(None, viewport)
    return x + ink.x, y + ink.y, ink.width, ink.height


def main(source, dest, silhouette=False):
    root = ET.parse(source).getroot()
    view_box = root.get("viewBox")
    if view_box:
        x, y, w, h = (float(v) for v in view_box.replace(",", " ").split())
    else:
        x = y = 0.0
        w = float(re.sub(r"[^0-9.]", "", root.get("width", "16")))
        h = float(re.sub(r"[^0-9.]", "", root.get("height", "16")))
    box, margin = 16, 0
    if silhouette:
        x, y, w, h = ink_box(source, x, y, w, h)
        box, margin = 14, 1
    scale = box / max(w, h)
    dx = margin + (box - w * scale) / 2 - x * scale
    dy = margin + (box - h * scale) / 2 - y * scale
    body = [serialize(child, silhouette) for child in root]
    body = [line for line in body if line]
    if (scale, dx, dy) != (1, 0, 0):
        body = [f'<g transform="translate({dx:.4g} {dy:.4g}) scale({scale:.5g})">', *body, "</g>"]
    with open(dest, "w") as out:
        out.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">\n')
        out.write("\n".join(body) + "\n")
        out.write("</svg>\n")


if __name__ == "__main__":
    args = sys.argv[1:]
    silhouette = "--silhouette" in args
    paths = [a for a in args if a != "--silhouette"]
    if len(paths) != 2:
        sys.exit(__doc__.strip())
    main(*paths, silhouette=silhouette)
