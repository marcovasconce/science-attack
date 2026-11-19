# Corredor danificado e Tibúrcio — revisão 3

Arte raster criada/editada pela ferramenta imagegen. Recortes, alinhamento de quadros e redução por vizinho mais próximo feitos pelos importadores Godot, preservando alpha. Referências do usuário serviram apenas como inspiração visual; textos e marcas d'água não foram copiados.

## Tibúrcio integrado ao Rei

Fonte: `art/source/lower_lab/king_captive_animated_v3.png`. Sprite: `assets/enemies/king_captive_animated_v3.png`. Importador: `tools/prepare_king_captive.gd`. Mantém seis quadros, boca e gosma animadas, olho único fechado, lenço vermelho e membros azuis. Referências: versão 2 do rei e `Dude_Monster_Idle_4.png` original.

Prompt:

Edit the first image, an existing 3 by 2 pixel-art animation spritesheet. Keep the green crowned bacteria king, his red eyes, all 6 distinct talking-mouth and dripping-slime animation poses and their grid layout. Improve ONLY the tiny captive carried limp across the king's one hand: he is Tiburcio, the exact cyan blue ONE-EYED cyclops character shown in the second image (original 32px sprite animation). Match the ORIGINAL identity: rounded irregular turquoise head/body, ONE enormous circular pale-white eye socket covering most of the face, now CLOSED with one horizontal curved navy eyelid line across the pale eyelid. A tiny black fringe/spike on crown of his head, red neck scarf with two tails, little dark blue limbs dangling limply. He has no nose and no human face, no pair of eyes, no grin. His closed pale eyelid must read as the original cyclops eye closed, not a black smile on a featureless blue ball. Head tipped sideways, unconscious but unharmed and appropriate for kids. His torso rests horizontally across the king's palm and forearm with his head supported on the right and legs dangling on the left. Make captive consistent identical identity and pose in all six cells, integrated naturally into the arm grip as ONE combined character sprite. Preserve king as closely as possible. Pixel art crisp grid, thick dark pixel outlines. TRUE TRANSPARENT RGBA background in every empty area, absolutely no background color, no haze, no glow, no halo, no shadow behind characters. 1536x1024 sheet with 512x512 cells 3 columns 2 rows, crown aligned within cells. Maintain room around all sprites. This is a game asset, no labels or text.

## Atlas de cenário

Fonte: `art/source/lower_lab/damaged_corridor_atlas.png`. Saídas: `assets/environment/lower_lab/{locker,machines,puddle,sign,door,terminal}.png`. Importador: `tools/prepare_corridor_art.gd`. Referências: armários, computadores, poças, porta e terminal anexados pelo usuário. Chamas, vapor, bolhas, movimento da porta e tela de inicialização são efeitos nativos do jogo.

Prompt:

Create ONE cohesive 2D videogame environment prop atlas in crunchy hand-crafted 16-bit pixel art. Six separate sprites, absolutely isolated on TRUE TRANSPARENT RGBA background, arranged in exactly 3 columns by 2 rows of equal 512x512 square cells (1536x1024 sheet). Keep every sprite entirely inside its own cell with 36px empty margins. Dark navy thick pixel outlines, desaturated teal steel, green corrosion, limited colors, stepped pixels, no antialiasing, no labels, no text or watermark. Front view with a tiny amount of top surfaces, for a side-scrolling laboratory adventure suitable for 9-year-olds. References are inspiration for objects only; draw new original pixel interpretations.
TOP LEFT: a tall double metal locker unit, one door shut with vents and one torn door hanging crooked open exposing shelves, teal dented steel, black claw-like cracks and some green slime.
TOP MIDDLE: two connected deactivated retro laboratory computer machines, one tall cracked black oscilloscope monitor over dials and one lower twin-reel computer box, dark OFF screens, scorched upper edge, a few broken wires. NO fire or smoke yet, these will be animated by the game.
TOP RIGHT: a shallow irregular bright yellow-green toxic puddle on the floor with turquoise broken flask and glass shards, flat wide elliptical perspective, no steam yet, no ground plane. Wide sprite centered in its cell.
BOTTOM LEFT: one isolated square yellow metal biohazard warning sign with strong black recognizable biohazard symbol, bolts, chipped corners; no other objects.
BOTTOM MIDDLE: industrial steel doorway frame with a CLOSED purple/slate horizontal roll-up shutter inside, dark blue side posts, top lintel and black-yellow hazard stripe across top. Entire rectangular unit centered and front-facing. No room or wall behind, only doorway sprite.
BOTTOM RIGHT: a functional retro CRT terminal on a squat teal metal cabinet with little feet. Small dark green screen with tiny bright green abstract pixel dashes (not legible letters), physical keyboard and 3 amber indicator lamps, red switch. Distinct from destroyed machine. Sprite coherent with all others.

