"""Record the new ending sprite and promoted runtime copies without modifying masters."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / "assets/generated/production_prompts.json"
records = json.loads(path.read_text(encoding="utf-8"))
names = {entry["name"] for entry in records}
if "demon_king_v1" not in names:
    records.append({
        "name": "demon_king_v1", "category": "npc", "file": "assets/generated/demon_king_v1.png",
        "prompt": "Use case: illustration-story. One standalone sprite for WINDOW HERO, a peaceful medieval window-cleaning logic puzzle. A small tired but gentle Demon King in three-quarter side view looking left, seated upright on a modest wooden chair. Round compact adult creature, two small blunt ivory horns, tousled dark violet hair, sleepy expressive eyes, warm pale lavender skin, dark plum royal robe with simple gold collar and tiny crooked crown. One hand rests on the chair arm; calm wistful expression. Storybook 2D game illustration, bold navy contours, restrained two-tone cel shading, rounded readable forms, cozy ochre/teal hero palette. Full-body seated character and chair, centered, generous transparent margins, readable at 100 pixels. Soft amber side light from the left. Transparent alpha PNG. No scenery, window, floor, shadow, lettering, dialog, weapons, armor, battle pose, glow background, checkerboard, or watermark.",
        "reference_images": [], "tool": "built-in image_gen", "model": "not exposed by tool", "date": "2026-09-30",
    })
for name, source, target in [
    ("legendary_ladder_v1", "item_legendary_ladder_v01", "assets/generated/legendary_ladder_v1.png"),
    ("heart_window_v1", "window_heart_clean_hint_v01", "assets/generated/heart_window_v1.png"),
]:
    if name not in names:
        source_record = next(entry for entry in records if entry["name"] == source)
        records.append({**source_record, "name": name, "file": target, "category": "runtime_copy", "source_file": source_record["file"]})
path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{len(records)} generated PNG records; runtime masters preserved")
