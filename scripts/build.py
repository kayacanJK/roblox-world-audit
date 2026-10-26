#!/usr/bin/env python3
"""Bundle Luau modules into one plugin script for Roblox Studio local installation."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
OUTPUT = ROOT / "dist" / "WorldAudit.plugin.lua"
RULE_IMPORT = "local Rules = require(script.Parent.Rules)"
SCANNER_IMPORT = "local Scanner = require(script.Parent.Scanner)"


def build() -> str:
    plugin = (SOURCE / "Plugin.lua").read_text(encoding="utf-8")
    rules = (SOURCE / "Rules.lua").read_text(encoding="utf-8")
    scanner = (SOURCE / "Scanner.lua").read_text(encoding="utf-8")
    if plugin.count(RULE_IMPORT) != 1 or plugin.count(SCANNER_IMPORT) != 1:
        raise ValueError("Plugin imports changed; update the bundler instead of emitting a broken build")
    # Roblox Script files loaded as local plugins have no sibling ModuleScripts.
    # Keep development modules separate and inline them only in the distributable.
    plugin = plugin.replace(RULE_IMPORT, "local Rules = (function()\n" + rules + "\nend)()")
    plugin = plugin.replace(SCANNER_IMPORT, "local Scanner = (function()\n" + scanner + "\nend)()")
    return plugin


def main() -> int:
    OUTPUT.parent.mkdir(exist_ok=True)
    content = build()
    OUTPUT.write_text(content, encoding="utf-8", newline="\n")
    print(f"Built {OUTPUT.relative_to(ROOT)} ({len(content):,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
