"""Encode the real Godot frames as a GIF without changing any game sprites."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
paths = sorted((root/'.godot/germ_dash_frames').glob('*.png'))
assert paths, 'Run capture_germs_dash.gd first'
with Image.open(paths[93]) as sample:
    palette = sample.convert('RGB').quantize(colors=256,method=Image.Quantize.MEDIANCUT)
frames = []
for path in paths:
    with Image.open(path) as frame:
        frames.append(frame.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE))
target = root/'art/previews/germs_dash_water.gif'
frames[0].save(target,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True)
print(target, target.stat().st_size, 'bytes')
