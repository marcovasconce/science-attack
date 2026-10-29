# Artes da abertura

Geradas com a ferramenta integrada **image_gen**, usando as três referências fornecidas pelo usuário. Os PNGs finais foram copiados para o projeto; não há dependência dos arquivos temporários ou da pasta de geração.

## Laboratório — `assets/backgrounds/laboratory.png`

```text
Use case: precise-object-edit.
Asset type: Production pixel-art laboratory background for the initial cutscene of a Godot side-view beat-em-up game. Landscape 16:9, 1536x864 if possible, intended logical resolution 640x360.
Input image: the attached laboratory is the layout and architecture reference/edit target. Redraw it crisply and richly as professional 16-bit pixel art, keeping its recognizable three-level side-view composition: top observation corridor with dark rectangular windows, middle laboratory with a large blue computer display on the left and three vertical mint-green specimen cylinders in the center, lower laboratory with a chalkboard on the far left, computer workstation in the lower center-left, and stairs ascending to the right. Steel walls, piping, railings, small vials on shelves, right-hand fire extinguisher. Cooler steel blue-gray palette, dark navy shadows, cyan monitors and mint vats, restrained amber accent lamps, coherent hard pixel edges, no blur.
REQUIRED EDIT: Remove absolutely ALL people, creatures, flying objects, projectiles, fireballs and characters from ALL levels; reconstruct clean architecture where they stood. All experiment tanks empty of living subjects.
Composition for engine use: show entire room front-on, flat 2D side-on game camera, no isometric perspective. Lower floor must be open from the left image boundary to the workstation so two actors can run in. Main walking baseline at 92 percent image height. Lower floor workstation at 40 percent image width with unobstructed empty standing area to its right. Wide dark rectangular computer screens with subtle static cyan data are fine; they will be animated by code. Keep the large blue monitor on middle-left flat rectangular and easy to overlay. Upper walkway occupies top quarter, middle floor middle third, lower floor bottom third. Fine pixel machinery detail, bold readable shapes, gently worn industrial surfaces.
No characters, no written labels, no text overlays, no border, no HUD, no red lighting baked in: the game adds a pulsing red alarm. Full bleed image.
```

## Doutor Max — `assets/characters/dr_max.png`

```text
Use case: identity-preserve.
Asset type: production 2D game sprite sheet, transparent PNG.
Input: reference image is Dr. Max, preserve his recognizable appearance: young adult male scientist, thick dark navy tousled hair, medium warm skin, long off-white lab coat with lavender-gray shadows, cobalt-blue shirt, very dark navy trousers, light gray sneakers, no glasses.
Create one perfectly regular sprite sheet with EXACTLY 4 columns and 2 rows, 8 equal square cells in a 1024x1024 canvas (each cell 256x512? NO: canvas should be 1024x512, each cell 256x256). Final aspect ratio 2:1. Use a truly transparent background everywhere outside character silhouettes. Uniform grid, no margins between cells, no drawn grid, no labels.
Characters must be equal height about 208 px inside each 256px cell, centered horizontally with soles aligned at y=232 within each cell. Keep EVERY body, hand, foot and hair fully inside its own cell, with at least 16px clear padding. No frame may touch another.
All frames face RIGHT, 3/4 side view matching a side-scrolling beat-em-up. Pixel-art sprite with a real limited palette, dark outlines, clearly separated chunky pixels, consistent character design, careful hands, crisp hard edges.
Frames in reading order:
1 top-left: run right, right leg fully extended forward and left leg back, opposite arms pumping.
2: run right, legs compress in passing pose, arms change, slight body lowering.
3: run right, left knee rises forward, right foot pushes back, coat tails swing.
4 top-right: run right, left leg fully extended forward and right leg back, opposite arms pumping.
5 bottom-left: run right, passing pose opposite frame2.
6 bottom row second: run right, right knee rises and left foot pushes, cycles to frame1.
7 bottom row third: normal relaxed standing facing right, feet grounded, EMPTY hands lowered by sides, head attentive, no running lean.
8 bottom-right: same normal standing right with a very subtle breathing change.
Critical: The flask from the reference is removed completely in ALL frames; both hands are EMPTY. No bottle, no potion, no weapon, no object in hands, no effects, no background, no ground shadows, no text. Preserve his face/hair/coat/blue shirt identity. This is animation source art, not a presentation or mockup.
```

## Segunda cientista — `assets/characters/scientist.png`

```text
Use case: identity-preserve.
Asset type: production 2D pixel-art game animation sprite sheet, transparent PNG.
Input reference: the female scientist. Preserve her dark blue-black hair tied in a high loose bun/ponytail with side swept fringe, light warm skin, long white lab coat with cool lavender shadows, dark inner top, purple trousers and dark shoes. Adult woman, confident and alert.
Create exactly EIGHT full-body frames laid out in a perfectly regular 4-column by 2-row grid on a 1024x512 landscape canvas. Each cell 256x256. GENUINE alpha transparency. No background, no shadows, no text, no visible grid or labels. All sprites equal size about 208px tall and centered in each cell, soles around y=232 relative to their own cell. At least 16px empty padding in EVERY cell; no overlapping cells or cropped body parts.
Polished chunky 16-bit pixel art with strong dark outlines and restrained shading, like a hand-animated side-view arcade beat-em-up. Every frame faces RIGHT. Maintain exactly the same character identity, proportions, hairstyle and outfit throughout.
Frames in reading order:
Top row four consecutive running-right frames: 1 right leg extended forward, left leg behind, arms pumping opposite legs; 2 passing compressed pose; 3 left knee rises forward, right foot pushes back; 4 left leg extended forward and right leg back. Bottom row first two complete the cycle: 5 opposite passing pose; 6 right knee rising, left foot pushes back. Lab coat tails and hair bounce naturally through running cycle. Clear leg and arm changes, no static sliding pose.
Bottom row frames3 and4 (frames7 and8 overall): two normal relaxed standing-right frames, tiny breathing variation, head upright, arms lowered naturally and EMPTY hands, feet grounded. Ready to face and speak to another scientist.
Remove the Pokeball COMPLETELY. No sphere, no ball, no flask, no item or instrument in either hand in ANY frame. Also remove her reference's raised hand to her face: neutral hands when standing and normal arm-pumping while running. Do not copy the original pose. Keep clothing and face based on the reference.
```

## Integração

O Godot usa regiões AtlasTexture para consumir os oito frames de cada sprite sem alterar os PNGs. Max tem suas poses de repouso espelhadas em tempo de execução. O alerta vermelho, os dados dos monitores e as bolhas são animados por código sobre o cenário.

