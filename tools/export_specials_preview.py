"""Encode actual viewport captures as an animated preview."""
from pathlib import Path
from PIL import Image
project = Path(__file__).resolve().parents[1]
frames = [Image.open(p).convert('RGB') for p in sorted((project/'.godot/specials_frames').glob('*.png'))]
assert frames, 'Capture the Godot preview first.'
target = project/'art/previews/specials_training.gif'
frames[0].save(target,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True)
print(target)
