# Especiais de água e sabão

## Comportamento atual

- Arma, meia barra: uma bolha gigante, custo de 50 pontos, 140 de dano em área ao estourar.
- Arma, barra cheia: preparação de 0,25 s e jato contínuo de água e sabão durante 3 s. Custo de 100 pontos. São 20 pulsos de 30 de dano (até 600 num alvo que permanecer no feixe inteiro). O personagem se firma no lugar e mantém a direção escolhida; o jato termina nas paredes e respeita a profundidade dos alvos. Bolhas pequenas viajam com a água. Os especiais não recarregam a própria barra.
- Escova, barra cheia: conserva os dois golpes de área (100 + 65 de dano) e a duração de 1,4 s. Agora o impacto tem uma sequência de seis quadros de água/espuma, bolhas pequenas subindo e tremores curtos de 0,22 s e 0,12 s. A câmera volta ao centro; a HUD não treme.
- O giro de meia barra da escova, os tiros normais mais lentos e o combo segurado em F/J foram preservados. Q/I continuam sendo as teclas dos especiais.

Pausa congela duração, animações, dano e tremor. Trocar de arma ou cair cancela o jato. O feixe não atinge aliados nem Tibúrcio. O robô de treino continua recebendo dano sem morrer.

## Arte e implementação

Sprites criados com a ferramenta imagegen integrada, usando as duas referências fornecidas pelo usuário:

- `assets/animations/soap_water_beam.png`: seis fases do jato, duas colunas por três linhas.
- `assets/animations/soap_water_splash.png`: seis fases da explosão de água, três colunas por duas linhas.
- Os recursos `soap_water_beam.tres` e `soap_water_splash.tres` descrevem os recortes. `tools/prepare_water_effects.py` gera esses metadados sem editar os PNGs.
- `scripts/pixel_water_effect.gd` anima os sprites e as bolhas num viewport pequeno ampliado 2×, filtro nearest e corte de alfa, para manter os pixels bem definidos.
- `scripts/special_ability.gd` controla custo, preparação, canalização, pulsos, direção e cancelamento.
- `scripts/micro_arena.gd` limita alcance por colisão, aplica o dano e controla o tremor somente da câmera do mundo.

## Verificação

`Godot --headless --path . --script res://tools/verify_water_specials.gd` cobre a troca dos especiais, custo, duração a 60 Hz, 20 pulsos, paredes, profundidade, direção esquerda, postura fixa, ausência de dano em aliados, pausa, cancelamento, efeito da escova e retorno da câmera ao centro. Também passaram as regressões de especiais, equipamentos, movimento armado e coreografia.

Captura real: `Godot --path . --script res://tools/capture_water_specials.gd`. GIF: `python tools/export_water_preview.py`, em `art/previews/water_specials.gif`. Imagens estáticas: `giant_bubble_half.png`, `soap_water_beam.png` e `brush_water_impact.png` na mesma pasta.

## Prompt do jato

Use case: style-transfer. Asset: a 6-frame animation sprite sheet for a low resolution pixel-art beat-em-up. Reference image is a guide to the general charged beam silhouette ONLY. Make an original WATER AND SOAP PRESSURE BEAM, horizontal, flowing from LEFT to RIGHT. At the left a round bright aqua pressure bulb, then a long continuous turbulent water stream to the right; several visible small round soap bubbles carried along inside the flow, creamy white foam streaks and choppy turquoise watery ribbons. It must look like liquid water rather than fire or electricity. Exactly SIX frames arranged in a regular 2-column by 3-row grid. Each frame is a complete long beam fully isolated with generous transparent padding, same size and same left anchor. Every frame is a distinct flowing-water phase: foam ribbons and little bubbles travel right, jagged edges alternate. Intended loop 12 fps. Use only coarse square pixels and stair-step edges, a 6-color aqua/cyan/deep-blue/white palette, no soft glow, no blur, no smooth vector lines, no gradients. Each effect equivalent to roughly 128x32 logical pixels enlarged by nearest neighbor. Completely transparent background alpha=0, solid art alpha=255; no black background, no checkerboard, no gridlines, no labels, no text, no characters, no gun.

## Prompt do impacto

Use case: style-transfer. Asset: a six-frame water-and-soap impact sprite sheet for a low resolution pixel-art beat-em-up. Use attached image only as a reference for the progression of a ground water splash. Make it MUCH MORE PIXELATED: large crisp square pixel clusters, stepped edges, flat cyan/turquoise/deep blue and white foam, only 6 colors. Exactly SIX distinct isolated frames in a regular 3-column by 2-row grid. Sequence read left to right: 1 compact water column hitting the floor; 2 explosive tall foamy crown; 3 widest dramatic splash with curling side waves and white crests; 4 spreading lower wave and droplets; 5 low foam ripple; 6 dissolving ripple with tiny droplets. Constant shared ground baseline and consistent scale within each cell, enough padding for the wide third frame. Add a few small round soap bubbles above each crest, pixel circles, not realistic. Each frame equivalent to around 96x48 logical pixels enlarged nearest-neighbor. Transparent background alpha=0, solid sprite pixels alpha=255. No smooth curves, no gradients, no glow, no shadows, no labels, no gridlines, no text, no characters.

