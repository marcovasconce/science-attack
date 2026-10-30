"""Encode actual Godot captures; does not alter the source artwork."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
paths = sorted((root / '.godot/impact_frames').glob('*.png'))
assert len(paths) == 42, 'Run capture_impacts.gd first.'
frames = [Image.open(path).convert('RGB') for path in paths]
durations = [round((i + 1) * 100 / 30) * 10 - round(i * 100 / 30) * 10 for i in range(42)]
durations[17] += 450
durations[-1] += 650
destination = root / 'art/previews/combat_impacts.gif'
frames[0].save(destination, save_all=True, append_images=frames[1:],
               duration=durations, loop=0, optimize=True, disposal=1)
with Image.open(destination) as preview:
    total = 0
    for index in range(preview.n_frames):
        preview.seek(index)
        total += preview.info['duration']
    assert preview.size == (640, 360) and total == sum(durations)
print(f'Saved {destination} ({total / 1000:.1f} seconds).')
