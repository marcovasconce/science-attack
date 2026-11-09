"""Encode actual Godot viewport captures as a GIF; does not edit game art."""
from pathlib import Path
from PIL import Image

project = Path(__file__).resolve().parents[1]
frames = [Image.open(p).convert('RGB') for p in sorted((project / '.godot/micro_bridge_frames').glob('*.png'))]
if not frames:
    raise SystemExit('Run capture_micro_bridge.gd with the Godot renderer first.')
output = project / 'art/previews/microscopic_bridge.gif'
frames[0].save(output, save_all=True, append_images=frames[1:], duration=[600] + [80] * (len(frames) - 2) + [900], loop=0, optimize=False)
print(output)
