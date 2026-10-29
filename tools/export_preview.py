"""Encode Godot-rendered captures into a looping preview; never alters game art.

Requires Pillow only for this optional export, not to run the game.
Run capture_intro.gd with --sequence first, then run this script.
"""

from pathlib import Path

from PIL import Image


root = Path(__file__).resolve().parents[1]
paths = sorted((root / ".godot/shrinking_preview_frames").glob("*.png"))
if len(paths) != 456:
    raise SystemExit("Expected 456 rendered frames; run capture_intro.gd -- --sequence first.")

# Use one palette for every frame, avoiding color flicker as the red light pulses.
palette_samples = [Image.open(paths[i]).convert("RGB") for i in (0, 11, 145, 244, 365, 390)]
palette_strip = Image.new("RGB", (640, 360 * len(palette_samples)))
for i, sample in enumerate(palette_samples):
    palette_strip.paste(sample, (0, 360 * i))
palette = palette_strip.quantize(colors=256)
frames = []
for path in paths:
    with Image.open(path) as source:
        frames.append(source.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE))

def export(selected, name):
    destination = root / "art/previews" / name
    # GIF stores time in centiseconds; alternating durations preserves 12fps.
    durations = [round((i + 1) * 100 / 12) * 10 - round(i * 100 / 12) * 10 for i in range(len(selected))]
    selected[0].save(destination, save_all=True, append_images=selected[1:], duration=durations,
                     loop=0, optimize=True, disposal=1)
    with Image.open(destination) as preview:
        total_duration = 0
        for index in range(preview.n_frames):
            preview.seek(index)
            total_duration += preview.info.get("duration", 0)
        assert total_duration == sum(durations)
        assert preview.size == (640, 360)
    print(f"Saved {destination} ({destination.stat().st_size:,} bytes; {len(selected) / 12:g} seconds)")


export(frames, "laboratory_intro.gif")
export(frames[252:], "shrinking_sequence.gif")
