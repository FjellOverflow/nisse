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
UNUSED_COLOURS = {"color", "solid-color", "text-decoration-color"}
TEXT_LAYOUT = {"letter-spacing", "word-spacing", "writing-mode", "direction", "baseline-shift",
               "block-progression", "line-height", "shape-padding", "dominant-baseline"}
DEFAULTS = {("display", "inline"), ("visibility", "visible"), ("overflow", "visible"), ("marker", "none"),
            ("vector-effect", "none"), ("isolation", "auto"), ("mix-blend-mode", "normal")}


def is_inert(prop, value):
    return (prop in TEXT_LAYOUT or prop.startswith(("font", "text-", "-inkscape"))
            or (prop, value) in DEFAULTS)


def repaint(prop, value, silhouette):
    value = value.strip()
    is_paint = value != "none" and (silhouette or not value.startswith("url"))
    if prop in UNUSED_COLOURS or is_inert(prop, value) or (prop == "fill" and is_paint):
        return None
    if prop == "stroke" and is_paint or prop == "stop-color":
        return "currentColor"
    return value


def clean_style(style, silhouette):
    declarations = []
    for declaration in style.split(";"):
        prop, _, value = declaration.partition(":")
        prop = prop.strip()
        if not prop:
            continue
        value = repaint(prop, value, silhouette)
        if value is not None:
            declarations.append(f"{prop}:{value}")
    return ";".join(declarations)


def serialize(el, silhouette):
    tag = el.tag.split("}", 1)[-1]
    if tag in SKIP or (silhouette and tag in PAINT_SERVERS):
        return ""
    attrs = []
    for key, value in el.attrib.items():
        if key == f"{XLINK}href":
            key = "href"
        elif "}" in key or ":" in key or key == "class":
            continue
        if silhouette and key == "filter":
            continue
        if key == "style":
            value = clean_style(value, silhouette)
        else:
            value = repaint(key, value, silhouette)
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
