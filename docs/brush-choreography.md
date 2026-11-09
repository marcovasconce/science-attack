# Coreografia da escova de dentes

A escova foi reduzida de 42×10 para 34×8 pixels lógicos, cerca de 20%. O rastro mantém as duas faixas branca/ciano e os pontos quadrados; acompanha dois quadros do arco para conservar a leitura durante o golpe. As texturas originais da arma e dos personagens não foram alteradas.

O corpo participa dos quatro movimentos, usando poses originais de corrida, caminhada com ataque, preparação, salto e recuperação:

- Lateral: 12 quadros em 0,56 s. Recua para preparar, inclina o tronco e avança com uma passada de 16 pixels de cenário.
- Ascendente: 12 quadros em 0,58 s. Abaixa, estende o corpo, faz um pequeno impulso visual e avança 10 pixels.
- Forte: 14 quadros em 0,74 s. Levanta a escova, ergue o corpo e termina inclinado para a frente, avançando 18 pixels.
- Aéreo: 10 quadros em 0,52 s. Prepara no alto, acompanha o corte com o corpo e avança 8 pixels durante o salto.

Todas as inclinações são renderizadas no canvas original e ampliadas exatamente 2× com filtro nearest. Os pés, corpo e mão têm posições coordenadas por quadro. A passada usa a colisão real do personagem; paredes e o rombo bloqueiam o avanço. O painel pausa os movimentos, e sofrer dano cancela a passada e a continuação enfileirada. A direção fica estável durante cada golpe da IA.

Controles e sequência continuam em F/J. Alcance de dano, cura, arma de bolhas e montagem foram preservados. Os valores da coreografia ficam em `scripts/brush_motion.gd`.

Verificação: `tools/verify_brush_choreography.gd`, `tools/verify_pixel_animations.gd` e `tools/verify_equipment_combat.gd`.

Prévia capturada do jogo: `art/previews/brush_choreography.gif`. Para gerar: `Godot --path . --script res://tools/capture_brush_choreography.gd`, seguido de `python tools/export_brush_choreography.py`.
