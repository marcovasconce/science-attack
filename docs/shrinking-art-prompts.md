# Sequência da máquina de encolhimento

As novas poses foram geradas com a ferramenta integrada **image_gen**, usando os atlas de Max e Amanda como referência. Arquivo final: `assets/characters/tube_poses.png`, atlas transparente com duas colunas: Max à esquerda, Amanda à direita. O Godot extrai cada pose por AtlasTexture e a coloca atrás do vidro dos tubos existentes; a arte não inclui tubos ou efeitos fixos.

## Prompt utilizado

```text
Use case: identity-preserve.
Asset type: production transparent sprite atlas for the shrinking-machine sequence in the existing pixel-art game Science Attack.
Input 1 is the existing Dr. Max animation sheet. Input 2 is the existing Dr. Amanda animation sheet. Preserve those two exact character identities and clothing.
Create one regular TWO-COLUMN, ONE-ROW sprite atlas, square 1024x1024 canvas. Each column is a separate 512x1024 cell. Left cell: Dr. Max. Right cell: Dr. Amanda. Exactly TWO full-body characters total. Each character centered in their own cell, same standing height, soles on a shared baseline about y=950; all hair, hands, coat and shoes fully visible with clear padding. Real transparent alpha background.
Both scientists stand upright facing mostly FRONT, slightly three-quarter but nearly symmetrical, in a calm braced pose ready to be miniaturized inside narrow vertical glass chambers. Arms relaxed close to the torso, empty hands visible near the hips, feet close together, coat tails hanging straight. Compact narrow silhouette, no running, no wide gestures. Eyes open and focused. The image contains ONLY the two character sprites; the EXISTING game engine adds the laboratory's green glass cylinders around them. Do NOT draw tubes, machinery, shadows, floor, green glow or effects into this atlas.
Dr. Max: young adult man, warm medium skin, thick tousled dark navy hair, cobalt blue shirt under a long off-white lab coat with cool lavender-gray shadows, dark navy trousers, pale gray sneakers, no glasses, no flask.
Dr. Amanda: adult woman, light warm skin, dark blue-black hair tied in a loose high bun with side-swept fringe, long white lab coat with lavender shadows, dark top with purple detail, purple trousers, black shoes, no Pokeball or held equipment.
Polished chunky 16-bit pixel art matching the original gameplay sprites, clean dark outlines, deliberate square pixels, consistent anatomy and palette. More carefully defined front-facing idle poses, not painted illustrations. No blur, no soft gradients, no text, no labels, no border, no grid lines, no watermark. Neutral lighting: green tint and shrinking animation will be applied in Godot.
```

## Direção da cena

Todos os tempos abaixo são relativos à confirmação da última fala de Amanda:

- 0–2,75 s: Amanda passa pelo início da escada, sobe os dois trechos e espera ao lado do tubo da direita.
- 0–3 s: Max permanece diante do computador.
- 3–6,40 s: Max percorre a mesma escada e segue até o tubo central; Amanda espera.
- 6,75–7,55 s: os dois dão o último passo para dentro das câmaras; as poses laterais dão lugar às novas poses atrás do vidro.
- 7,80–9,60 s: os tubos central e direito carregam, com pulsos verdes suaves de 1,05 s, reflexos, partículas e faixa de energia.
- 9,60–12,60 s: os dois encolhem simultaneamente, com os pés ancorados, até deixarem de ser visíveis.
- 12,90–14,40 s: a tela escurece suavemente até ficar totalmente preta; então a cena emite `intro_finished`.

A câmera abre o enquadramento para mostrar as escadas e depois focaliza os tubos. A iluminação vermelha continua, mais discreta durante a ativação verde. O tubo da esquerda permanece vazio.

## Implementação e revisão

- `scripts/shrinking_sequence.gd`: trajetos, espera, profundidade, entrada nos tubos, vidro, luz e redução de escala.
- `scripts/laboratory_foreground.gd`: reaproveita regiões do cenário como corrimãos em primeiro plano, deixando as pernas visíveis entre as barras.
- `scripts/laboratory_intro.gd`: integra a nova sequência depois dos diálogos e coordena a câmera.
- `art/previews/07_amanda_stairs.png` até `13_empty_tubes.png`: capturas reais dos momentos principais.
- `art/previews/shrinking_sequence.gif`: trecho novo em loop, com 17 segundos.
- `art/previews/laboratory_intro.gif`: abertura completa, com 38 segundos; a prévia avança as falas automaticamente, enquanto o jogo espera Enter/clique.

Espaço pausa toda a sequência; R restaura câmera, trajetos, escala, vidro, efeitos e o escurecimento. O sinal `dialogue_finished` marca o fim da conversa, e `intro_finished` fica reservado ao fim do escurecimento completo da tela.

