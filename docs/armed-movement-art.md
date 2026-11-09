# Sprites com armas e ataque contínuo

A atualização usa sprites completos novos de Max e Amanda carregando as armas com as duas mãos. A escova é puxada para trás, com as cerdas no chão. A arma de bolhas tem postura própria de apoio e recuo. Cada personagem recebeu 16 quadros: dois de espera e seis de caminhada para cada arma. Os dois quadros de espera são repetidos numa sequência de oito passos para respiração discreta. A caminhada tem seis desenhos distintos e espelha corretamente para a esquerda.

As escovadas mantêm a coreografia existente, com ajuste dos braços e das duas mãos no cabo. A arma de bolhas usa os novos sprites também ao disparar. Os sprites são exibidos na escala dos microavatares originais (26 e 28 pixels de altura lógica), com filtro nearest e ampliação 2×. Os PNGs originais foram preservados.

## Arquivos

- `assets/animations/max_armed_walk.png`: sheet completo de Max.
- `assets/animations/amanda_armed_walk.png`: sheet completo de Amanda.
- `assets/animations/max_armed_poses.tres` e `amanda_armed_poses.tres`: recortes e pontos de apoio dos pés.
- `tools/prepare_armed_poses.py`: lê alfa e gera apenas metadados; não altera os PNGs.
- `scripts/pixel_equipment_pose.gd`: renderização dos quadros, braços dos golpes e recuo.

Arte produzida com a ferramenta imagegen integrada. As imagens de referência são os sprites originais e a captura do jogo com as armas. O sheet de Max também serviu como referência de layout e poses para Amanda.

## Controles e cadência

- Segurar F (P1) ou J (P2) repete corte lateral, ascendente e escovada forte enquanto a tecla permanecer pressionada.
- Ao soltar uma tecla mantida, termina o golpe atual. Toques adicionais durante um golpe continuam podendo preparar a próxima escovada, como antes.
- Golpes e tiros respeitam a pausa e os controles individuais. Os especiais continuam com Q/I.
- O tiro normal passou de um disparo a cada 0,14 s para um a cada 0,28 s, aproximadamente metade da cadência. Os especiais de bolhas conservam a própria cadência.

## Verificação

`Godot --headless --path . --script res://tools/verify_armed_movement.gd` verifica os novos quadros e âncoras, repetição 1-2-3-1-2 para cada jogador, interrupção ao soltar, pausa e a nova cadência. Também passaram as regressões de equipamento, coreografia da escova e especiais.

`tools/capture_armed_movement.gd` grava capturas reais de espera, caminhada nos dois sentidos e ataque segurado. `tools/export_armed_preview.py` gera `art/previews/armed_movement.gif` sem modificar os sprites do jogo.

## Prompt de Max

Use case: identity-preserve. Asset type: actual low-resolution pixel art game animation sprite sheet. Reference 1 is the EXACT original character identity and pixel style to preserve; reference 2 shows the game and the existing two weapons. Redraw the character with new poses holding the weapons with TWO HANDS. Keep the same face, silhouette, palette, small body, big head and simple large square pixels; this is NOT a human scientist. Transparent background, no text, no grids, no shadows, no effects.
Make EXACTLY 16 isolated full-body sprites in a strict 4-column by 4-row regular grid, equally spaced cells, no overlap. Each cell has identical scale and ground baseline, ample transparent padding. ALL face RIGHT.
Top eight cells (rows 1-2, read left to right): holding a cyan toothbrush sword in both hands near the waist, with its shaft angled DOWN AND BACK TO THE LEFT so the white bristle head drags on the ground BEHIND the character. Cells 1-2 are two subtle idle breathing poses; cells 3-8 are six different sequential walking poses, legs stepping through a complete cycle, body leaning slightly forward with effort, both arms visibly attached to the same handle, brush head always touches baseline.
Bottom eight cells (rows 3-4): holding the compact dark blue-steel soap blaster from reference 2, green tank and silver barrel pointing RIGHT. Two hands visibly grip rear handle and support the front. Cells 9-10 are two idle breathing poses; cells 11-16 six sequential marching/walking poses, legs moving while both arms keep supporting the gun, no one-handed aim.
Brush should be about 1.2 times body height, gun about 0.9 times body height. Coarse pixel art, character only about 24-28 logical pixels tall, nearest-neighbor enlarged. Hard square pixel clusters, 1-pixel dark outlines, flat colors. Do not add armor, hair, clothing, goggles or realistic anatomy. Do not enlarge into high-detail illustrations. No antialiasing or smooth gradients. No detached arms, no extra hands or legs, no inconsistent character sizes.
Character to draw in ALL sixteen cells: ONLY MAX, the small white-gray round one-eyed microavatar in reference 1. His single large dark blue circular eye, pale head, small gray arms and dark gray feet must remain recognizable. Do not include the pink character.

## Refinamento do fundo de Max

Use case: background-extraction. This is an EDIT of the attached sprite sheet, not a redesign. Remove ALL the dark background and all gray/cyan glows completely, setting these regions to transparent alpha=0. Keep ONLY the sixteen solid pixel-art character-and-weapon silhouettes, opaque alpha=255. Preserve their pixel colors, exact positions, 4x4 layout, poses and proportions, canvas 1536x1024. Do not add any background, checkerboard, shadow, haze, aura or halo. No smoothing at edges. The gaps between legs and around the toothbrush handle must also be fully transparent. The output is a transparent PNG sprite sheet for a game.

## Prompt de Amanda

Use case: identity-preserve. Asset type: actual low-resolution pixel art game animation sprite sheet. Reference 1 is the EXACT original character identity and pixel style to preserve; reference 2 shows the game and the existing two weapons. Redraw the character with new poses holding the weapons with TWO HANDS. Keep the same face, silhouette, palette, small body, big head and simple large square pixels; this is NOT a human scientist. Transparent background, no text, no grids, no shadows, no effects.
Make EXACTLY 16 isolated full-body sprites in a strict 4-column by 4-row regular grid, equally spaced cells, no overlap. Each cell has identical scale and ground baseline, ample transparent padding. ALL face RIGHT.
Top eight cells (rows 1-2, read left to right): holding a cyan toothbrush sword in both hands near the waist, with its shaft angled DOWN AND BACK TO THE LEFT so the white bristle head drags on the ground BEHIND the character. Cells 1-2 are two subtle idle breathing poses; cells 3-8 are six different sequential walking poses, legs stepping through a complete cycle, body leaning slightly forward with effort, both arms visibly attached to the same handle, brush head always touches baseline.
Bottom eight cells (rows 3-4): holding the compact dark blue-steel soap blaster from reference 2, green tank and silver barrel pointing RIGHT. Two hands visibly grip rear handle and support the front. Cells 9-10 are two idle breathing poses; cells 11-16 six sequential marching/walking poses, legs moving while both arms keep supporting the gun, no one-handed aim.
Brush should be about 1.2 times body height, gun about 0.9 times body height. Coarse pixel art, character only about 24-28 logical pixels tall, nearest-neighbor enlarged. Hard square pixel clusters, 1-pixel dark outlines, flat colors. Do not add armor, hair, clothing, goggles or realistic anatomy. Do not enlarge into high-detail illustrations. No antialiasing or smooth gradients. No detached arms, no extra hands or legs, no inconsistent character sizes.
Character to draw in ALL sixteen cells: ONLY AMANDA, the vivid pink/purple small monster microavatar in reference 1, with two little pointed ears, white face and belly, dark navy outlines, magenta hands and feet. Preserve her original face. Reference 3 is the completed MAX sheet: copy ONLY its exact 4x4 arrangement, weapon poses and pixel density, but replace the gray creature with the original pink Amanda in every cell. Preserve Amanda's anatomy; do not recolor Max into pink. Avoid realistic details. Fully transparent background alpha=0 around sprites, opaque solid character pixels.

