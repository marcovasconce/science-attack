"""Encode native Godot screenshots without modifying the game artwork."""
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[1]
frames = [Image.open(root / f".godot/descent_preview_frames/{i:03d}.png").convert("RGB") for i in range(120)]
frames[0].save(root / "art/previews/journey_descent.gif", save_all=True,
               append_images=frames[1:], duration=[33, 33, 34] * 40, loop=0, disposal=2)
print("Saved art/previews/journey_descent.gif")
