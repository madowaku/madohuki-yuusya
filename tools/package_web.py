"""Create the exact itch.io upload ZIP, including asset notices and checksums."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "web"
required = ["index.html", "index.js", "index.wasm", "index.pck"]
required_notices = [
    "CREDITS.md", "asset-manifest.json",
    "licenses/Godot-MIT.txt", "licenses/Kenney-Medieval.txt",
    "licenses/Kenney-Particle-Pack.txt", "licenses/Kenney-UI-Adventure.txt",
    "licenses/Kenney-UI-Audio.txt", "licenses/MPLUS-OFL.txt",
]
for item in required:
    if not (BUILD / item).is_file():
        raise SystemExit(f"Missing export: {item}. Export the Web preset first.")

shutil.copy2(ROOT / "CREDITS.md", BUILD / "CREDITS.md")
shutil.copytree(ROOT / "assets" / "licenses", BUILD / "licenses", dirs_exist_ok=True)

manifest = []
for path in sorted((ROOT / "assets").rglob("*")):
    if not path.is_file() or path.suffix == ".import" or path.name == "manifest.json":
        continue
    relative = path.relative_to(ROOT).as_posix()
    source = "Original project work"
    license_id = "Original work; no third-party samples"
    if path.name in ["place.ogg", "retrieve.ogg"]:
        source = "https://kenney.nl/assets/ui-audio"
        license_id = "CC0-1.0"
    elif path.name == "sparkle.png":
        source = "https://kenney.nl/assets/particle-pack"
        license_id = "CC0-1.0"
    elif path.suffix == ".ttf":
        source = "https://github.com/google/fonts/tree/main/ofl/mplusrounded1c"
        license_id = "OFL-1.1"
    elif "kenney_medieval" in path.parts:
        source = "https://kenney.nl/assets/platformer-pack-medieval"
        license_id = "CC0-1.0"
    elif "kenney_ui_adventure" in path.parts:
        source = "https://kenney.nl/assets/ui-pack-adventure"
        license_id = "CC0-1.0"
    elif path.suffix == ".png" and ("generated" in path.parts or "reference" in path.parts):
        source = "OpenAI built-in image generation; see assets/generated/production_prompts.json"
        license_id = "AI-generated project asset; not a third-party CC0 grant"
    elif path.parent.name == "licenses":
        source = "License notice, see CREDITS.md"
        license_id = "License text"
    reference_only = ("reference" in path.parts or "processed" in path.parts
                      or path.name.startswith(("hero_master", "window_heart", "item_legendary", "production_")))
    manifest.append({"file": relative, "source": source, "license": license_id,
                     "included_in_web": not reference_only,
                     "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
(ROOT / "assets" / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
shutil.copy2(ROOT / "assets" / "manifest.json", BUILD / "asset-manifest.json")

archive = ROOT / "build" / "window-hero-itch.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as out:
    for path in sorted(BUILD.rglob("*")):
        if path.is_file() and path.suffix != ".import":
            out.write(path, path.relative_to(BUILD).as_posix())
with zipfile.ZipFile(archive) as check:
    assert check.testzip() is None
    assert all(item in check.namelist() for item in required)
    assert all(item in check.namelist() for item in required_notices)
print(f"Created {archive} ({archive.stat().st_size / 1024 / 1024:.2f} MiB)")
print("SHA256 " + hashlib.sha256(archive.read_bytes()).hexdigest())
