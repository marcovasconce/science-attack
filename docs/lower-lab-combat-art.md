# Porta de perfil, fogo e voadoras amarelas

Ferramenta usada: imagegen integrada. Referências: três imagens fornecidas pelo usuário e atlas da voadora verde existente. Arquivos gerados copiados para o projeto; canal alpha preservado. O importador `tools/prepare_lower_lab_combat_art.gd` apenas recorta/alinha células e reduz por vizinho mais próximo. A queda, impacto no chão, voo baixo e subida são animações de posição/rotação/escala na engine sobre os quatro desenhos de asas.

## Porta de perfil

Fonte: `art/source/lower_lab/door_side.png`. Recurso utilizado: `assets/environment/lower_lab/door_side.png`.

Prompt:

Create one game-ready pixel sprite, reference image shows required SIDE PROFILE orientation of an industrial laboratory security door. A very narrow tall closed vertical sliding barrier seen precisely EDGE-ON in a side scrolling beat-em-up: just a thin dark blue steel column/track with pale slate edge panels, several silver horizontal mechanical teeth, turquoise indicator in the middle and compact thicker square caps at the very top and bottom. Ratio width to height approximately 1:8. NO front-facing doorway, no door opening rectangle, no pair of pillars, no big broad shutter. A single slender vertical strip as in reference. Flat orthographic side elevation, crisp 16-bit pixel grid, dark navy outline and blue gray steel palette, a few bolts, no text, no perspective scene. Sprite occupies centered 100px width and 800px height on 1024x1024 transparent canvas. Only isolated door-profile sprite, remove ALL blue surrounding wall from reference, background truly fully transparent alpha with no glow or shadow. Top and bottom caps 10 percent height each, mechanical central sliding spine middle80percent.

## Fogo animado

Fonte: `art/source/lower_lab/fire_animated.png`. Recurso utilizado: `assets/environment/lower_lab/fire_animated.png`.

Prompt:

Edit target is the provided flame-animation reference. Produce a clean game-ready pixel-art SPRITESHEET of the SAME low wide flame band: bright yellow pointed tongues rising from a continuous orange/red hot base. Exactly TWELVE distinct consecutive animation frames arranged SIX equal columns by TWO equal rows, 1536x1024 total, 256x512 cells. Each flame band centered horizontally in its cell, same width 210px and fixed base at local y=380, maximum height about160px. Follow reference flicker silhouettes and warm colors closely; changing flame tips curl, stretch, split and recombine through a looping cycle. Chunky crisp 16-bit pixel edges, flat yellow/orange shades, no soft painted fire. Extract flames only, remove every rounded box, all captions, all gray/black background; genuine transparent alpha everywhere outside flames. NO glow halo, no floor, no smoke, no extra objects, no text, no panels. Leave clear margins in every cell. This sprite is to replace bad geometric fire in a children's pixel game.

## Voadora amarela

Fonte: `art/source/lower_lab/yellow_flying_bacteria.png`. Recurso utilizado: `assets/enemies/yellow_flying_bacteria.png`.

Prompt:

Edit the supplied FOUR-FRAME green flying bacteria animation sheet into a YELLOW variant for the same pixel game. Preserve character identity exactly: round bacteria body, little round nodules, two bat wings, big cheeky open mouth with two small fangs and pink tongue sticking out, not scary. Replace all body and wing green colors with saturated GOLDEN YELLOW and amber/ochre shadows, lemon highlights. Keep mouth pink-brown, pink tongue and cream teeth. Keep exactly 4 consecutive wing-flap frames aligned in one row, equal cells: wings raised, horizontal, down, horizontal. SAME body size and fixed center in all frames. NO crown, no extra appendages, no new character. Authentic chunky 16-bit pixel art, sharp grid and limited palette, thick dark brown outline. Entire bodies and wings inside own cells with margins; wide 1536x512 canvas, four384x512 cells. Fully transparent alpha background, no black background, no glow, no shadows, no text, no frames or UI.

## Bola de gosma

Fonte: `art/source/lower_lab/slime_ball.png`. Recurso utilizado: `assets/enemies/slime_ball.png`.

Prompt:

Edit provided slime-ball animation reference into a MUCH MORE PIXELATED game-ready 16-bit sprite sheet. Four sequential poses of the same turquoise/green gelatinous projectile with darker blue-green blobs inside and a tiny mint highlight, arranged in one horizontal row of four equal square cells. First pose tall droplet, second soft oval, third squash rounded ball, fourth flatter squish, with consistent perceived volume. Big clearly visible square pixels, stepped dark teal outline, 5-6 flat colors, NO gradients or blur or soft edges. Each projectile about 20x24 virtual pixels, enlarged with nearest-neighbor only on output. 1536x384 canvas, four384x384 cells, each ball centered with generous clear margins. Keep the reference's teal blue green palette, this is goo spat by a playful yellow bacteria. All background genuinely transparent alpha; remove gray from reference, no glow halo, no text, no boxes, no ground or cast shadows.


