"""Encode the frames rendered by capture_lower_lab.gd; no sprite edits."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
paths = sorted((ROOT / ".godot/king_captive_frames").glob("*.png"))
assert len(paths) == 72, "Capture the sequence with Godot first"
frames = [Image.open(path).convert("RGB") for path in paths]
frames[0].save(
    ROOT / "art/previews/king_captive_animated.gif",
    save_all=True,
    append_images=frames[1:],
    duration=[42, 42, 41] * 24,
    loop=0,
    disposal=2,
)
print("Saved art/previews/king_captive_animated.gif")

corridor_paths = sorted((ROOT / ".godot/corridor_frames").glob("*.png"))
if len(corridor_paths) == 48:
    corridor_frames = [Image.open(path).convert("RGB") for path in corridor_paths]
    corridor_frames[0].save(
        ROOT / "art/previews/lower_lab_corridor_animated.gif",
        save_all=True,
        append_images=corridor_frames[1:],
        duration=[42, 42, 41] * 16,
        loop=0,
        disposal=2,
    )
    print("Saved art/previews/lower_lab_corridor_animated.gif")

yellow_paths = sorted((ROOT / ".godot/yellow_flyer_frames").glob("*.png"))
if len(yellow_paths) == 120:
    yellow_frames = [Image.open(path).convert("RGB") for path in yellow_paths]
    yellow_frames[0].save(
        ROOT / "art/previews/yellow_flyer_knockdown.gif",
        save_all=True,
        append_images=yellow_frames[1:],
        duration=[42, 42, 41] * 40,
        loop=0,
        disposal=2,
    )
    print("Saved art/previews/yellow_flyer_knockdown.gif")
