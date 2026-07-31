#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import sys
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


def load_items(path: str) -> list[ET.Element]:
    if not path or not os.path.exists(path) or os.path.getsize(path) == 0:
        return []
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        print(f"⚠️  {path}: {exc} — ignoriere vorhandene Items", file=sys.stderr)
        return []
    return root.findall("./channel/item")


def item_version(item: ET.Element) -> str:
    el = item.find(f"{{{SPARKLE_NS}}}version")
    if el is not None and (el.text or "").strip():
        return el.text.strip()
    enc = item.find("enclosure")
    if enc is not None:
        val = enc.get(f"{{{SPARKLE_NS}}}version")
        if val:
            return val.strip()
    return ""


def sort_key(version: str):
    try:
        return (1, int(version))
    except ValueError:
        return (0, version)


def main() -> int:
    ap = argparse.ArgumentParser(description="Neue Sparkle-Version in den bestehenden Appcast einfügen.")
    ap.add_argument("--current", default="")
    ap.add_argument("--new", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--title", default="BuLi Tabelle")
    ap.add_argument("--notes-html", default="",
                    help="Optionale HTML-Datei; wird als <description> (Release-Notes) an die neuen Items gehängt.")
    args = ap.parse_args()

    new_items = load_items(args.new)
    if not new_items:
        print(f"✗ {args.new} enthält keine <item> — Abbruch", file=sys.stderr)
        return 1

    # Release-Notes als <description> an die neu hinzukommenden Items hängen.
    # ElementTree escaped das HTML; Sparkles XML-Parser macht daraus wieder HTML.
    notes = args.notes_html
    if notes and os.path.exists(notes) and os.path.getsize(notes) > 0:
        html = open(notes, encoding="utf-8").read().strip()
        if html:
            for item in new_items:
                desc = item.find("description")
                if desc is None:
                    desc = ET.SubElement(item, "description")
                desc.text = html
            print(f"▸ Release-Notes als <description> eingebettet ({len(html)} Zeichen).")

    by_version: dict[str, ET.Element] = {}
    order: list[str] = []
    for item in load_items(args.current) + new_items:
        ver = item_version(item)
        key = ver or f"__novers_{len(order)}"
        if key not in by_version:
            order.append(key)
        by_version[key] = item

    items = sorted(
        by_version.values(),
        key=lambda it: sort_key(item_version(it)),
        reverse=True,
    )

    rss = ET.Element("rss", {"version": "2.0"})
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = args.title
    for item in items:
        channel.append(item)

    ET.indent(rss, space="    ")
    ET.ElementTree(rss).write(args.out, encoding="utf-8", xml_declaration=True)
    with open(args.out, "a", encoding="utf-8") as fh:
        fh.write("\n")

    versions = ", ".join(item_version(i) or "?" for i in items)
    print(f"✓ {args.out}: {len(items)} Version(en) [{versions}]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
