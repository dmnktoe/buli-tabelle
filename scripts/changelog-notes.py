#!/usr/bin/env python3
"""Wandelt den CHANGELOG.md-Abschnitt einer Version in schlichtes HTML um.

Ausgabe (stdout) ist als Sparkle-`<description>` gedacht: Überschriften,
Aufzählungen, **fett** und `code`. Ohne passenden Abschnitt bleibt die
Ausgabe leer (Exit 0), sodass der Aufrufer die Notes einfach weglassen kann.
"""
from __future__ import annotations

import re
import sys


def _inline(text: str) -> str:
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return text


def section(changelog: str, version: str) -> str:
    pattern = re.compile(
        r"^##\s*\[" + re.escape(version) + r"\][^\n]*\n(.*?)(?=^##\s|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    m = pattern.search(changelog)
    return m.group(1).strip() if m else ""


def to_html(markdown: str) -> str:
    html: list[str] = []
    in_list = False
    current: str | None = None

    def flush_item() -> None:
        nonlocal current
        if current is not None:
            html.append(f"<li>{_inline(current.strip())}</li>")
            current = None

    def close_list() -> None:
        nonlocal in_list
        flush_item()
        if in_list:
            html.append("</ul>")
            in_list = False

    for raw in markdown.splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith("### "):
            close_list()
            html.append(f"<h4>{_inline(stripped[4:].strip())}</h4>")
        elif stripped.startswith("- "):
            flush_item()
            if not in_list:
                html.append("<ul>")
                in_list = True
            current = stripped[2:]
        elif in_list and current is not None and raw[:1] in " \t":
            current += " " + stripped
        else:
            close_list()
            html.append(f"<p>{_inline(stripped)}</p>")

    close_list()
    return "\n".join(html)


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: changelog-notes.py <version> [changelog-pfad]", file=sys.stderr)
        return 2
    version = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 else "CHANGELOG.md"
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return 0
    body = section(text, version)
    if body:
        sys.stdout.write(to_html(body))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
