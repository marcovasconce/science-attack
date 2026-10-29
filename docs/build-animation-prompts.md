# Sprites de montagem

Gerados com a ferramenta integrada ImageGen em 29/10/2026, usando como referências os spritesheets `Owlet_Monster_Push_6.png` e `Pink_Monster_Push_6.png` fornecidos pelo usuário.

## Arquivos finais

- `assets/animations/Owlet_build_6.png`: seis quadros de 32×32 para Max.
- `assets/animations/Pink_build_6.png`: seis quadros de 32×32 para Amanda.
- `assets/animations/build_sheet_source.png`: imagem gerada original preservada.
- Os recursos SpriteFrames de Owlet e Pink contêm a animação `build`, a 10 quadros por segundo.

O script `tools/prepare_build_sprites.py` recorta a grade 6×2, elimina ruído de alfa quase transparente, normaliza a escala e alinha os pés. Não redesenha os personagens. Os quadros finais usam filtro nearest para a escala em jogo.

## Prompt final enviado

Use case: precise-object-edit. Asset type: production transparent pixel art sprite sheet for Godot. Both attached sprite sheets are STYLE AND IDENTITY REFERENCES, not edit targets. Create a NEW building/assembling animation sheet matching these exact two cute tiny creatures: top row white/gray one-eyed owlet with dark blue-gray face, little feet; bottom row pink rabbit-eared creature with purple belly. Keep original silhouettes, colors, pixel-art outline and side-view proportions. They face RIGHT. Layout exactly 6 equal-width columns and 2 equal-height rows, transparent background, generous equal empty margins in each cell. Each cell contains ONE full body on a consistent ground baseline at identical scale, no touching adjacent cells. Six sequential construction poses: 1 crouch reaching forward/down, 2 lift tiny golden block with both hands, 3 raise hands and block to chest, 4 reach forward placing block, 5 press both hands down fastening block, 6 return to low reach. Small continuous changes, loop intended at 10 fps. Character height approximately 60% of each cell. Chunky 32x32 game sprite appearance, crisp pixel clusters, no soft paint, no anti-aliasing, no grids, no separators, no captions, no numbers, no watermark, no scene, no tools. Make movements readable at small size and preserve reference identity exactly.

## Construção no jogo

Os blocos amarelos usam o asset pronto 092 do pacote Industrial de Kenney. As caixas laranja e seus fragmentos usam o asset 106. O desenho da passagem usa o asset 057. As peças têm destinos separados, trajetórias em arco e permanecem nos encaixes após a construção. Os personagens usam as novas poses e a montagem pausa quando o jogador solta a tecla.
