# Arte da continuação da fase 2

Criada com a ferramenta **imagegen integrada**, sem CLI/API externa. Uma geração por recurso (o guardião usa seis poses do mesmo personagem). As referências do usuário guiaram o sabão, o TNT e o escudo; a bactéria existente definiu a linguagem visual. Os originais RGBA estão em `art/source/lower_lab/`.

`tools/prepare_lower_lab_finale_art.gd` faz apenas recorte das margens, registro dos pés e redimensionamento nearest. O alpha gerado é preservado. Guardião: atlas 3×2 de células 112×112; sabão: 40×34; TNT: 36×42; contaminação: 180×92. Poço/trilhos, contorno interativo, barra de vida e partículas de espuma usam desenho nativo do Godot.

## shield_germ

- Recurso final: `assets/enemies/shield_germ.png`.
- Original preservado: `art/source/lower_lab/shield_germ.png`.

Prompt final:

```text
Use case: stylized-concept. Asset: one transparent pixel-art animation sprite sheet for an original slime-germ shield mini boss in a children's side-view beat-em-up. Reference images 1 and 2: only inspiration for the big shield, stance and shield-first charge; image 3: game's actual green bacteria style. Make an ORIGINAL chunky lime-green bacterial creature with a huge organic green slime shield, a round lumpy germ torso, tiny protrusions, dripping goo arms and stubby goo legs, mischievous red eyes and a bold cartoon grin. Remove all black armor, dark suit, metal helmet and human soldier anatomy from the knight inspiration; the creature and shield are entirely living slime. Olive dark outlines allowed, no black armor. Not scary, appropriate age 9. Six full-body frames in EXACT 3 columns by 2 rows on transparent background: row1 idle facing left, crouched shield windup facing left, charging shield-first left; row2 a second charging stride left, squashed wall-impact left, dazed recovery left with drooping slime. Same identity, scale and feet baseline in all equal cells, generous transparent gaps and margins, no clipped shield. Crisp low resolution 16-bit pixel clusters, no antialiasing or gradients, simple palette, readable when each cell is reduced to 112x112. No text, labels, ground shadows, border, checkerboard, scenery, weapons other than shield.
```

## Idle e efeitos do guardião

- `assets/enemies/shield_germ_idle.png`: atlas de idle da versão anterior, preservado como referência; a versão atual usa o atlas v2.
- `assets/effects/shield_block_impact.png`: animação de quatro quadros para golpes reduzidos pelo escudo.
- `assets/effects/tnt_explosion.png`: explosão de oito quadros em grade 4×2.
- Os rastros verdes da investida são efeitos nativos. A derrota atual usa quatro desenhos próprios do atlas v2; o script só controla a sequência, o piscar e o desaparecimento.

## soap_pickup

- Recurso final: `assets/environment/lower_lab/soap_pickup.png`.
- Original preservado: `art/source/lower_lab/soap_pickup.png`.

Prompt final:

```text
Use case: stylized-concept. Create a single game pickup sprite of a chunky pink bar of SOAP with a few tiny pearly cyan soap suds beneath it, inspired by the reference silhouette. Original crisp 16-bit pixel art for Science Attack, clear stepped dark purple outline, light pink top, saturated rose sides, small white highlights. Slight three-quarter view like reference. The only embossed text is 'SABÃO', if legible. Centered isolated on truly transparent background, generous margin. No scenery, ground shadow, photo texture, watermark, gradients or extra objects. It must read clearly reduced to 40 by 32 pixels.
```

## tnt_crate

- Recurso final: `assets/environment/lower_lab/tnt_crate.png`.
- Original preservado: `art/source/lower_lab/tnt_crate.png`.

Prompt final:

```text
Use case: stylized-concept. Create one isolated red wooden TNT crate game sprite inspired by reference. Crisp chunky 16-bit pixel art in a children's cartoon beat-em-up. Red planks, burgundy outlines, bright readable golden 'TNT' letters centered on front, small dark gray plunger at top, red wood top rim, same almost frontal view as reference. Single crate only, no background or scenery or shadow; truly transparent alpha, generous margin. Clear silhouette readable reduced to 36 by 42 pixels. No gradients, antialiasing, sparks, explosions, realistic detail, or additional objects.
```

## slime_block

- Recurso final: `assets/environment/lower_lab/slime_block.png`.
- Original preservado: `art/source/lower_lab/slime_block.png`.

Prompt final:

```text
Use case: stylized-concept. Single original pixel-art environment obstacle for a side-view laboratory game for age nine. A thick disgusting but cartoon-safe bright olive/lime green goo contamination mound pooling across a corridor, inspired by the texture and color of the reference elevator slime. This is a FLOOR SPILL blocking the path, not an arch or doorway: a large irregular oval footprint viewed slightly from above, several low lumpy translucent slime globules, dripping edges, small glossy yellow-green highlights and a few bubbles. Dense cohesive mound with wide footprint, no empty hole in middle. Proportions roughly 180 pixels wide by 130 tall, highest globules at back tapering toward foreground. Crisp chunky 16-bit pixels, dark green contour, limited palette, no antialias or soft gradients. Truly transparent background, no environment, shadow, machinery, text, eyes or face, generous clear margin. One sprite only.
```


