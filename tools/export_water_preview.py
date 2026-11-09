"""Encode actual Godot captures with a shared GIF palette; leave game assets untouched."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
paths=sorted((root/".godot/water_frames").glob("*.png"))
assert paths, "Run capture_water_specials.gd first"
# Sharing the palette preserves consistent colours between frames and compresses
# the static arena efficiently instead of encoding a new palette every frame.
with Image.open(paths[92]) as sample:
    palette=sample.convert("RGB").quantize(colors=256,method=Image.Quantize.MEDIANCUT)
frames=[]
for path in paths:
    with Image.open(path) as frame:
        frames.append(frame.convert("RGB").quantize(palette=palette,dither=Image.Dither.NONE))
target=root/"art/previews/water_specials.gif"
frames[0].save(target,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True)
print(target, target.stat().st_size, "bytes")

