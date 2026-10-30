"""Encode actual Godot frames into an animated preview; does not edit sprite art."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
paths = sorted((root / '.godot/crate_salvage_frames').glob('*.png'))
assert len(paths) == 84, 'Run capture_crate_salvage.gd first.'
frames = [Image.open(path).convert('RGB') for path in paths]
durations = [round((i + 1) * 100 / 24) * 10 - round(i * 100 / 24) * 10 for i in range(84)]
durations[63] += 500
durations[-1] += 350
destination = root / 'art/previews/crate_salvage.gif'
frames[0].save(destination, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=True, disposal=1)
with Image.open(destination) as preview:
    total = 0
    for index in range(preview.n_frames):
        preview.seek(index)
        total += preview.info['duration']
    assert preview.size == (640, 360) and total == sum(durations)
print(f'Saved {destination} ({total / 1000:.2f} seconds).')
