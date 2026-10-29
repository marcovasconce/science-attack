# Retratos e interface dos primeiros diálogos

Os retratos foram criados com a ferramenta integrada **image_gen**, usando as sprites existentes como referência de identidade. Os arquivos finais são `assets/portraits/dr_max_dialogue.png` e `assets/portraits/amanda_dialogue.png`.

## Doutor Max — prompt utilizado

```text
Use case: identity-preserve.
Asset type: detailed pixel-art dialogue portrait for the existing 2D game Science Attack.
Input image is the existing Dr. Max animation sheet, use it ONLY as identity/outfit reference. Create ONE large, beautifully detailed bust portrait of this exact young adult male scientist. Preserve tousled thick dark-navy hair, warm medium skin, cobalt blue collared shirt, off-white lab coat, no glasses. More detailed facial anatomy, layered pixel shading and individual locks of hair than the tiny in-game sprite, but clearly the same person and the same 16-bit arcade art world.
Composition: single head-and-shoulders bust from mid chest up, three-quarter face looking toward the RIGHT so it can sit on the LEFT side of a dialogue box. All hair and both shoulders within canvas, no cut-off head. His expression is worried and urgently explaining a dangerous lab emergency, brows concerned, mouth slightly OPEN as if speaking, no exaggerated shouting. Hands outside the crop. No flask or held object.
Style: polished hand-crafted pixel art with intentional clean square pixels and dark outlines, rich navy/blue/cool lavender palette for clothing, warm nuanced facial highlights, crisp and refined anime/arcade character portrait, no soft painting, no blur, no 3D render, no smooth gradients. Readable at about 100x110 logical pixels but high quality source.
Transparent background with real alpha. One portrait only, centered, with 5 percent clear padding. No frame, UI box, writing, watermark, scenery or shadows outside the silhouette.
```

## Doutora Amanda — prompt utilizado

```text
Use case: identity-preserve.
Asset type: detailed pixel-art dialogue portrait for the existing 2D game Science Attack.
Input image is the existing female scientist's animation sheet, use it ONLY as identity/outfit reference. Her name is Doutora Amanda. Create ONE beautifully detailed head-and-shoulders bust portrait of this exact adult woman. Preserve dark blue-black hair with side swept fringe and loose high bun/ponytail, light warm skin, white lab coat with cool lavender-gray shadows and dark inner top with a purple detail. She must look recognizable as this exact game sprite.
Composition: from mid chest up, three-quarter face looking toward the LEFT so it can sit on the RIGHT side of the dialogue box. All of her bun and both shoulders stay inside the canvas, clear padding, no cut-off head. She looks focused, resourceful, determined, urgently responding to Max and telling him to prepare the shrinking machine. Mouth slightly OPEN in the middle of speaking, not smiling, not exaggerated shouting. Hands outside the crop. No Pokeball, sphere, flask, weapon or held equipment.
Style: high-quality deliberate pixel art, rich detailed facial anatomy, crisp clean square pixels, dark outlines, layered restrained pixel shading, expressive eyes, carefully shaded hair strands. 16-bit arcade/anime dialogue portrait, more defined and detailed than the small gameplay sprite. No soft painting, no blur, no 3D, no smooth gradients. Readable when displayed at approximately 100x110 logical pixels.
Genuine transparent alpha background. One character only. No scenery, framing, UI, letters, labels, logo, watermark or shadow outside the silhouette.
```

## Fonte

A fonte pixelada Press Start 2P é distribuída com o projeto em `assets/fonts/PressStart2P-Regular.ttf`, acompanhada de `assets/fonts/OFL-PressStart2P.txt`. Fonte e licença obtidas do [repositório oficial Google Fonts](https://github.com/google/fonts/tree/main/ofl/pressstart2p). O diálogo usa tamanho 8 na resolução lógica de 640 × 360, sem antialiasing; a janela inicial duplica essa resolução.

## Roteiro e apresentação

As duas falas do usuário foram preservadas literalmente em `scripts/intro_dialogue.gd`, incluindo capitalização, acentos e pontuação. Retratos estáticos em expressão de fala acompanham o texto progressivo. Max fala primeiro, com retrato à esquerda e caixa azul-escura; Amanda responde com retrato à direita e caixa roxa. Enter ou clique completa a frase em exibição; o próximo avanço passa à frase seguinte. A última confirmação conclui o diálogo.

A aproximação da câmera dura 1,35 s e termina em zoom de 1,28×. A caixa aparece durante a aproximação, 0,48 s após a chegada de Amanda. A respiração usa uma pose estável com ciclo de 3,8 s e variação vertical de apenas ±0,3%, mantendo os pés no chão.

