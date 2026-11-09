"""Encode actual Godot viewport captures as a GIF, without changing game art."""
from pathlib import Path
from PIL import Image
project=Path(__file__).resolve().parents[1]
frames=[Image.open(p).convert('RGB') for p in sorted((project/'.godot/equipment_frames').glob('*.png'))]
assert frames, 'Run capture_equipment_combat.gd first.'
output=project/'art/previews/equipment_combat.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=[90]*len(frames),loop=0,optimize=False)
print(output)
