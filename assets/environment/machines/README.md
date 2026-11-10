# Laboratory sprites

`lab_atlas.png` is original artwork generated with the built-in image generation tool, using the user's three supplied references for style (cartoon laboratory machinery, mint industrial equipment and eight-tooth hollow gold gears). It has a transparent background and a 4 × 4 grid.

Rows: machine housings / console / clamp stand; four gear frames; four steam frames; four monitor frames. Runtime atlas regions preserve the source PNG. Animation clocks follow gameplay pause and machine state.

The exact generation prompt is preserved in [prompt.txt](prompt.txt). The returned image is 1254 × 1254; atlas coordinates derive from the actual texture width rather than the requested resolution.

## Integrated controls and translucent steam

[lab_controls.png](lab_controls.png) was generated with the built-in ImageGen tool, using the first atlas as a palette reference. Its 4 × 2 grid contains four vapor frames, a lever mounting plate, a lever handle, an inset indicator lens and a raised push button. The exact prompt is in [controls_prompt.txt](controls_prompt.txt). Runtime atlas coordinates use the actual image dimensions. The steam shader removes dark edging, feathers the cell edges and limits opacity; the source PNG is preserved.

Prompt: Create a transparent 4 × 4 pixel-art sprite atlas for a cartoon side-view laboratory game. Front orthographic view, crisp chunky pixels, dark navy outlines, mint/turquoise metal and amber highlights. Row 1: electrical housing with ventilation and lightning plate, recessed gear housing, science console, clamp support. Row 2: four frames of a gold eight-tooth open-center cog. Row 3: four thick pale steam frames with blue-gray edges. Row 4: four dark monitors with moving green oscilloscope waveforms. No labels, watermark, scenery or characters.
