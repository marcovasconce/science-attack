# Colmeia e menu — arte integrada

Todas as quatro imagens foram geradas com a ferramenta integrada ImageGen. Os originais estão preservados em `art/source/hive/`. O registro de sprites usa recorte, alinhamento de atlas e nearest-neighbor em `tools/prepare_hive_art.gd`.

## Menu original

Arquivos: `assets/menu/laboratory.png`

Use case: precise-object-edit. Game-ready wide pixel-art background for Science Attack, 2D side scrolling beat em up, output 1536x864 landscape. Edit the supplied menu artwork: preserve its blue and purple laboratory, glassware, microscope, bright SCIENCE ATTACK logo, Max and Amanda characters and their nameplates, pencil, bacteria, overall framing and crisp playful pixel style. Remove ALL THREE buttons on the left (JOGAR, OPÇÕES, SAIR) completely, replacing them with unobtrusive blue/purple laboratory wall and floor matching the surrounding scene. This is a background layer: leave the left region from x5% to31%, y46% to80% empty and calm for two real interactive buttons to be added in game. Keep characters and logo exactly recognizable and retain the text SCIENCE ATTACK, MAX, AMANDA. No additional text, no buttons, no menu icons.

## Menu em camadas

O ImageGen integrado usou `assets/menu/laboratory.png` como referência visual. A cena `scenes/main_menu.tscn` sobrepõe fundo, marca, órbitas, avatares do jogo, bactérias, tubos com líquido animado e controles do Godot.

### Fundo — `assets/menu/laboratory_stage.png`

Create a brand-new background plate for a 2D pixel art game main menu, wide 16:9 1920x1080 composition. The attached Science Attack screenshot is STYLE REFERENCE ONLY, not a plate to edit; match the vivid deep ultramarine and violet laboratory tiles, crunchy retro 16-bit hand-pixelled outlines and cyan reflections, cartoony confident science adventure color accents. Draw only the environment: an interior lab with a gridded blue wall, subtle recessed panels, purple shelves, dark tiled glossy metallic floor beginning about 70 percent down the image. Keep the entire left 48 percent quiet, mostly dark indigo wall with low contrast to leave empty space for separately composited logo and a vertical menu. Keep the lower right open with a strong cyan pool of light on the floor for two separately composited characters, no stage or podium. In the upper right, put a horizontal purple lab shelf at 36 percent down; park any microscope on its far right end, keep the left half of that shelf clear for independently animated science bottles. A few background conduits and low soft light sources just at far corners, subtle color banding, restrained detail across the center. Pixel clusters, crisp hard edges, no painted gloss blur, even pixels around 3 pixels in the final image. Flat 2D frontal wall and lightly receding floor. No letters, logo, signage, text, UI, buttons, people, characters, eyes, monsters, bacteria, flasks, bubbles, pencils, borders or labels. Full bleed.

### Marca — `assets/menu/title_mark.png`

Isolate a single logo asset from the reference image, for the exact same pixel art game. Retain ONLY the original two-line text SCIENCE ATTACK and the little cyan Erlenmeyer flask perched on top of SCIENCE. Match the original letter shapes, chunky arcade pixel lettering, exact spelling, orange-to-yellow SCIENCE, cyan-to-blue ATTACK, dark navy shadow and very thick white pixel sticker outline. Preserve the tiny cog-shaped counter in the A of ATTACK if visible. Preserve the original proportions exactly. Remove the white atom orbital lines and tiny stars outside the sticker edge: those will be separate dynamic layers. Remove the entire laboratory, all figures, characters, containers besides the logo's top flask, floor, furniture, labels and backdrop. One isolated mark centered, with small safe padding and genuine RGBA transparency everywhere around it, no gradients or glows outside its white outline, no other text. Game asset cutout, crisp blocky pixel edges, exact original game style.

## Parede orgânica

Arquivos: `assets/environment/hive/wall.png; assets/environment/hive/floor.png`

Use case: precise-object-edit. Asset: wide horizontally repeating pixel-art background for a side scrolling beat em up, 1536x864. Reference is the previous hive scene. Replace ALL man-made structures, steel, pipes, rails, regular honeycomb hexagons and especially the right hand tunnel/arch/doorway with continuous wet organic slime membranes. There must be NO tunnel, passage opening, doorway, architecture or hexagonal pattern anywhere. Keep the glowing lime green spherical/oval slime sacs nested in thick emerald goo, their luminous spotted interiors and darker teal palette. Composition: upper TWO THIRDS is a dense organic wall of irregular green slime folds, huge embedded round translucent sacs, viscous sagging drips hanging from the ceiling. Lower ONE THIRD is relatively plain horizontal dark desaturated green organic floor, traversable in a beat em up, no pits yet, no obstacles, not a perspective corridor. Wide lateral view. Left and right edges must meet smoothly when tiled. Consistent crisp SNES pixel clusters, dark outlines, restrained limited palette, hard edges, no blur, no text, no actors. Whole image completely organic; preserve the reference's green glowy sacs and slimy aesthetic.

## Gêiser

Arquivos: `assets/environment/hive/geyser.png`

Use case: stylized-concept. Asset type: transparent pixel art game sprite sheet for an animated toxic slime geyser. Reference 1 is a low cracked rocky crater; reference 2 is a green rising slime geyser. Draw precisely 8 equally sized cells in 4 columns by 2 rows, all with the SAME crater at SAME bottom baseline and center in every cell. Cell logical size96x160. Row1: dormant empty low dark cracked crater; crater interior glows bright green (warning); small slime column starts erupting; column reaches half height. Row2: full tall lime green slime geyser with rounded bubbling mushroom crown; full height second animation pose with different wavy liquid streaks and splashes; column collapsing to half height; final low slime splash returning to dormant crater. Each cell entire sprite visible, no overlaps, generous transparent margin above and on sides. Crater width60, columnwidth30, peakheight140 logical pixels. Muted dark olive cracked organic rim, emerald shadows, vivid yellow-green liquid, white-green highlights. Thick hard pixel clusters, SNES sprite aesthetic, no blur, NO text, labels, grid lines, watermark, scenery or characters. Transparent alpha background.

## Buraco

Arquivos: `assets/environment/hive/pit.png`

Use case: stylized-concept. Transparent pixel-art ground obstacle sprite for a green organic hive beat em up, inspired by the attached slime chasm. Draw ONE narrow jagged fissure in the floor, viewed at the slight overhead angle of a side scrolling beat em up. Vertical orientation in the image, long from top to bottom, width about one third its height, so characters moving LEFT to RIGHT must jump the narrow gap. Dark black-green deep pit, broken muted olive stone/slime lips on both sides, glowing lime toxic liquid far below, some small green drips on the inner walls. NO character, objects, labels, background ground rectangle or scenery. Isolated transparent alpha outside the irregular rim. Crisp chunky 16-bit pixel art, logical size80x160, bold hard edges, limited palette. Entire fissure contained in frame with padding. Hazard should read as a deep hole rather than a flat puddle. No blur or shadows outside the rim.
