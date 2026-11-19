"""Encode native Godot screenshots; this does not author or modify sprite art."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
for folder, count, output in [
    ("finale_frames", 180, "lower_lab_shield_boss.gif"),
    ("cleaning_frames", 90, "lower_lab_soap_cleaning.gif"),
]:
    paths = sorted((ROOT / ".godot" / folder).glob("*.png"))
    assert len(paths) == count, f"Capture {folder} with Godot first"
    frames = [Image.open(path).convert("RGB") for path in paths]
    frames[0].save(
        ROOT / "art/previews" / output,
        save_all=True, append_images=frames[1:],
        duration=[33, 33, 34] * (count // 3), loop=0, disposal=2,
    )
    print(f"Saved art/previews/{output}")
