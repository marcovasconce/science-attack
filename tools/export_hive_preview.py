"""Encode native game frames for reviewing the implemented animation."""
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[1]
frames = [Image.open(root / f".godot/hive_frames/{i:03d}.png").convert("RGB") for i in range(110)]
frames[0].save(root / "art/previews/hive_animation.gif", save_all=True,
               append_images=frames[1:], duration=40, loop=0, disposal=2)
print("Saved art/previews/hive_animation.gif")
