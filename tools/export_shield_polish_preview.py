"""Encode unmodified native Godot frames; no sprite art is authored here."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
frames = [Image.open(root / f".godot/shield_polish_frames/{i:03d}.png").convert("RGB") for i in range(204)]
frames[0].save(root / "art/previews/shield_polish.gif", save_all=True,
               append_images=frames[1:], duration=[33, 33, 34] * 68, loop=0, disposal=2)
print("Saved art/previews/shield_polish.gif: 204 native gameplay frames")
