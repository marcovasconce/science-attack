"""Encode real Godot captures; the original background/prop PNGs are unchanged."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
paths = sorted((root / ".godot/tabletop_frames").glob("*.png"))
assert len(paths) == 75, "Run capture_tabletop.gd first"
frames = []
for path in paths:
    with Image.open(path) as frame:
        frames.append(frame.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT))
target = root / "art/previews/tabletop_stage.gif"
frames[0].save(target, save_all=True, append_images=frames[1:], duration=60, loop=0, optimize=True)
print(target, target.stat().st_size, "bytes")
