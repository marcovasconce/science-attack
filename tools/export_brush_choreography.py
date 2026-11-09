"""Encode actual Godot captures; no game sprites are changed."""
from pathlib import Path
from PIL import Image
project = Path(__file__).resolve().parents[1]
frames = [Image.open(p).convert('RGB') for p in sorted((project/'.godot/brush_choreography_frames').glob('*.png'))]
assert frames, 'Capture the Godot choreography first.'
output = project/'art/previews/brush_choreography.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=False)
print(output)
