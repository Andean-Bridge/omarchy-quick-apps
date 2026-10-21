#!/usr/bin/env python3
"""Offline checks for the distributable plugin. Runtime smoke tests are separate."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "manifest.json").read_text())
assert manifest["schemaVersion"] == 1
assert manifest["id"] == "andean-bridge.quick-apps"
assert manifest["kinds"] == ["menu"] and manifest["keepLoaded"] is True
assert manifest["version"] == json.loads((root / "package.json").read_text())["version"]
assert re.fullmatch(r"\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?", manifest["version"])
for entry in manifest["entryPoints"].values():
    path = Path(entry)
    assert not path.is_absolute() and ".." not in path.parts and (root / path).is_file()
for required in ["README.md", "LICENSE", "CHANGELOG.md", "preview.png", "docs/PUBLISHING.md"]:
    assert (root / required).is_file(), f"Missing release file: {required}"
catalogs = [json.loads(p.read_text()) for p in sorted((root / "i18n").glob("*.json"))]
assert catalogs and all(set(c) == set(catalogs[0]) for c in catalogs)
assert all(isinstance(value, str) and value for c in catalogs for value in c.values())
for path in root.glob("*.qml"):
    source = path.read_text()
    assert len(re.findall(r"\bText\s*\{", source)) == source.count("textFormat: Text.PlainText"), f"Text must render as plain text: {path.name}"
    assert "/home/sbosell" not in source and "local.quick-apps" not in source
    assert "execDetached([\"bash\"" not in source, "Use argv instead of interpolating a shell command"
for path in root.rglob("*"):
    if ".git" in path.parts:
        continue
    assert not path.is_symlink(), f"Plugin distribution cannot contain symlinks: {path}"
    assert path.name != ".env", "Do not distribute credentials"
assert (root / "preview.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
print("Plugin package checks passed.")
