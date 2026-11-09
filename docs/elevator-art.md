# Elevador cooperativo

Sprite criada com a ferramenta integrada ImageGen, com fundo transparente. Arquivo final: `assets/environment/cooperative_elevator.png` (1402 × 1122). O PNG original foi preservado, sem pintura ou remoção de fundo posterior. A cena usa um recorte AtlasTexture em `Rect2(96, 88, 1216, 960)` e escala 0,22, com filtragem nearest.

A cabine, os trilhos, as colisões e as duas plataformas são nós editáveis em `scenes/environment/cooperative_elevator.tscn`. As plataformas são desenhadas no Godot para alternar de vermelho para verde sem trocar a sprite da cabine. A ocupação considera os pés dos personagens; cada jogador só conta para uma plataforma. A cabine e os passageiros sobem juntos, e uma CanvasLayer cobre a tela inteira com preto.

Prévia real: `art/previews/elevator_both_ready.png`. O elevador agora carrega `scenes/gameplay/tabletop_stage.tscn`, com a dupla armada e seu inventário preservado. A cena de chegada reutiliza a cabine e acrescenta duas portas metálicas deslizantes desenhadas nativamente no Godot. O aviso “PRÓXIMA FASE EM BREVE” continua apenas como fallback para instâncias sem destino configurado.

## Prompt final — ImageGen integrado

```text
Use case: stylized-concept. Asset type: a single transparent pixel-art elevator cabin sprite for Science Attack, a 640x360 cooperative side-scrolling beat-em-up in a microscopic metal laboratory. Primary request: a broad open industrial freight elevator that comfortably carries two small characters side by side. Front view with a small amount of top-down view so the floor is visible, matching a 16-bit beat-em-up. Steel blue and dark teal chunky metal frame, vertical side columns, a crossbeam at the top, recessed dark blue rear wall with restrained cyan indicators, rivets, a wide empty grey steel floor deck across the bottom and a short thick front lip with a few yellow-black hazard stripes. OPEN FRONT with no doors, no railing across the entrance, ample empty interior for characters and two separately rendered pressure pads. Do NOT paint pressure pads or red/green circles into the art: the game draws those interactively. Silhouette approximately 5:4 width-to-height, deck visible over the bottom quarter. Crisp coarse square pixel clusters, stepped outlines, limited palette, readable at 240x192 in-game pixels, matching retro sprites at 2x nearest-neighbor display. Entire elevator centered, fully visible with generous transparent padding. Genuine transparent RGBA background, opaque sprite pixels. No scenery, no surrounding floor, no background, no characters, no text, no watermark, no grid, no glow beyond silhouette, no blur or photorealism.
```

