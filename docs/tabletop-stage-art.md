# Segunda fase — bancada do laboratório

## Assets finais

Criados com a ferramenta **ImageGen integrada**. Os dois PNGs originais foram copiados para o projeto e preservados sem repintura, redimensionamento ou edição de fundo.

- `assets/environment/tabletop_laboratory.png`: panorama opaco de 2172 × 724. Sala distante inspirada no laboratório da abertura, tampo de bancada e borda frontal.
- `assets/environment/tabletop_props.png`: folha RGBA transparente de 1312 × 1199, com dois tubos de ensaio, uma caneta e um lápis. Recortes AtlasTexture permitem reutilizar os objetos.
- `assets/environment/test_tube_liquid.gdshader`: anima somente o interior do líquido: ondulação da superfície e seis bolhas quadradas que sobem. Cada tubo tem material e relógio próprios; o vidro acima do líquido permanece estável. A ajuda pausa a animação; as falas de rádio da segunda fase não pausam.

A sala distante usa deslocamento mais lento que a câmera. O tampo tem área de caminhada até y=326, com borda visual em y=334; não é um piso de azulejos. A bancada tem 7200 pixels; os cinco tubos, duas canetas e dois lápis ocupam o trecho inicial. Os tubos têm colisões na base, e os materiais de escrita bloqueiam os pés no chão e podem ser ultrapassados com salto. Posições e rotações são definidas na cena, com escala uniforme e sem sobreposição entre tubos e materiais de escrita. A continuação usa os assets cartoon existentes; consulte `docs/tabletop-phase-flow.md` para objetivos, ritmo e checkpoints.

## Chegada e jogo

Cena editável: `scenes/gameplay/tabletop_stage.tscn`. O elevador da primeira fase aponta para ela. A cabine reaparece com portas fechadas, a tela clareia e as portas deslizam durante 1,4 s. Ao terminar, a colisão da porta é removida e os jogadores podem sair pela frente. Ao sair um personagem humano, Tibúrcio aparece no comunicador:

> Vamos limpar a bancada! A estufa fica logo ali.

O rádio mostra uma frase curta, inteira e com fonte maior, por 9–15 segundos. Não pede confirmação nem bloqueia movimento, combate ou interação. Os dois painéis de vida ficam ao lado do rádio, inclusive com dois jogadores humanos. Há dois grupos iniciais de germes. Depois da montagem e dos canos, a fase alterna vapor, combate, exploração e a defesa da máquina de limpeza. Placas cooperativas, códigos de frascos, busca obrigatória de fusíveis e regulagem dos filtros foram removidos. As peças de cenário continuam aproveitando o pacote cartoon existente. F2 retoma o último checkpoint da bancada; antes do primeiro, restaura a chegada.

## Verificação e prévias

- `tools/verify_tabletop_stage.gd`: entrada/portas/colisão, inventário, rádio sem bloqueio, montagem, alavanca, líquidos, combate, ondas e reinício real.
- `tools/verify_tabletop_route.gd`: água preenchendo conexões físicas, interrupção do fluxo, rádio legível durante ações, progressão simplificada, checkpoints antigos/atuais e saída com a dupla.
- `tools/capture_tabletop_route.gd`: capturas atuais em `art/previews/kids_*.png`; com `-- --sequence`, registra os quadros da animação da água. Prévia em `art/previews/kids_water_flow.mp4` e `.gif`.
- `tools/verify_elevator_loading.gd`: transição real da primeira fase para a segunda e consumo do estado da dupla.
- `tools/verify_elevator.gd` e `tools/verify_equipment_combat.gd`: regressões do embarque e equipamentos.
- `tools/capture_tabletop.gd`: capturas reais em `art/previews/tabletop_*.png`; `tools/export_tabletop_preview.py` codifica os quadros em `art/previews/tabletop_stage.gif`.
- Comparação dos quadros `tabletop_liquid_0.png` e `tabletop_liquid_1.png`: ambos os líquidos mudam; o vidro acima da superfície permanece igual.

## Prompt final — cenário / ImageGen integrado

```text
Use case: stylized-concept. Asset type: wide panoramic 16-bit pixel-art level background for the 640x360 side-scrolling cooperative game Science Attack. Scene: the camera is on top of a scientist's enormous laboratory workbench at microscopic character scale. The bottom 48 percent is a continuous flat pale blue-gray epoxy worktop, visibly a tabletop not a tiled room floor; very sparse tiny scratches and a few faint wiped circular stains. A thick dark navy beveled front edge runs horizontally along the very bottom, with the room dropping away beneath it. Keep this playable tabletop EMPTY: no objects, people, creatures, elevator, pens, tubes or props, they will be separate game sprites. Horizon/back edge of the workbench at 52 percent image height, perfectly horizontal. Above and far behind the table, a large futuristic laboratory resembling an established opening scene: blue-gray steel wall panels with rivets, a huge cobalt-blue monitor with abstract cyan graphs toward the left, three green illuminated cylindrical stasis capsules toward the center/right, high dark windows, metal mezzanine railings, cabinets and distant stairs. The rear laboratory must be lower contrast and desaturated than the foreground workbench to leave actors readable. Front/slightly elevated 2D beat-em-up view, fixed horizon, no dramatic vanishing point. Wide landscape panorama approximately 3:1 ratio. Crisp chunky square pixels and stepped edges, restrained blue-gray/cyan/green palette, consistent retro game art, no painterly rendering, no blur, no photographic detail, no text, no watermarks. Full opaque background.
```

## Prompt final — objetos / ImageGen integrado

```text
Use case: stylized-concept. Asset type: transparent retro pixel-art environmental prop sprite sheet for a microscopic beat-em-up set on top of a laboratory desk. Exactly FOUR isolated complete objects in a strict 2-column by 2-row sheet with ample transparent padding and no touching. TOP LEFT: a single giant upright glass test tube, rounded U-shaped bottom, thick rolled open rim, clear pale-blue glass outline with a few narrow white reflections, filled halfway with vivid CYAN liquid. TOP RIGHT: a second matching upright glass test tube with slightly different height, filled halfway with bright LIME GREEN liquid. Each tube must be a simple vertical cylinder, with a clearly visible liquid surface and straight sides: no holder/rack, no stopper, no markings or text, no bubbles painted into the liquid because the engine adds animated bubbles. BOTTOM LEFT: one ordinary large dark-blue ballpoint pen lying flat, slight diagonal from upper left to lower right, full pen visible, recognizable cap, clip and barrel. BOTTOM RIGHT: one large yellow wooden pencil lying flat at a slight opposite diagonal, full pencil visible with sharpened wooden tip, graphite point, silver ferrule and pink eraser. Microscopic heroes will be much smaller than these ordinary desk items. 16-bit game pixel art, crisp coarse square pixel clusters, dark stepped outlines, restrained colors, no smoothing. Tubes intended to display about 70 pixels wide and 200 pixels tall; pen and pencil about 220 pixels long. Truly transparent RGBA background; no ground, shadows, scenery, people, labels, gridlines, extra objects or watermarks. Keep all four objects well inside their separate quadrants.
```

