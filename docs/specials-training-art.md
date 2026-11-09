# Armas, poses de espera e treino

Esta página registra a primeira versão dos especiais. A bolha gigante agora usa meia barra; a barra cheia produz um jato de água e sabão. Mecânicas, arte e prompts atuais: [water-specials-art.md](water-specials-art.md).

Assets raster criados/editados com a ferramenta imagegen integrada, em fundo transparente. Os corpos originais de Max (Owlet) e Amanda (Pink) não foram alterados. As poses, mãos, giros e rastros são compostos pelo Godot numa superfície pequena com filtro nearest, preservando a grade de pixels.

## Lançador de bolhas

- Imagem: `assets/animations/bubble_blaster_mechanical.png`.
- Região do AtlasTexture: `Rect2(206, 186, 1183, 719)`, em `bubble_blaster_mechanical.tres`.
- Referência: lançador anterior `bubble_blaster_pixel.png`.
- Renderizado com 28 × 17 pixels lógicos, paleta de metal azul/escuro e reservatório verde.

Prompt usado:

> Use case: precise-object-edit. Edit target: the attached cyan soap bubble gun. Redesign it as a more stylish mechanical laboratory cleaning blaster, still appealing cartoon and unmistakably low resolution pixel art. Preserve horizontal side view, barrel pointing RIGHT and transparent isolated composition. Replace the toy-like bright plastic silhouette with a compact chunky dark graphite and blue-steel body, silver segmented barrel, small cyan pressure indicator, a restrained transparent mint-green soap reservoir integrated above the rear half, dark textured grip, two visible bolts, one small curved hose beneath the body. Readable strong silhouette suitable for 28x16 pixel weapon held by a 32 pixel tall hero. Palette limited to 8 flat colors, hard stair-step edges, large square pixels, dark single-pixel outline. SNES/arcade sprite enlarged by nearest neighbor; avoid tiny realistic details, gradients, neon glow, halo, glossy rendering, toy trigger colors. No character, hands, projectiles, text, background, floor or shadow. The barrel's open mouth must be visible on the right.

## Robô de treino

- Imagem: `assets/animations/training_robot.png`.
- Região do AtlasTexture: `Rect2(356, 293, 633, 670)`, em `training_robot.tres`.
- Referência fornecida: `codex-clipboard-b3af5f93-ffb4-4f54-ab68-00aa2bcf990a.png`.
- Renderizado com 36 × 42 pixels lógicos, ampliados 2×. A ferramenta isolou o robô; a aparência final é uma interpretação da referência.
- Cena editável: `scenes/actors/training_dummy.tscn`, instanciada em `Actors/TrainingDummy` na arena, posição (2100, 266).

Prompt usado:

> Use case: background-extraction. Edit the attached pixel robot image. Remove ONLY the dark gray background, giving a genuinely transparent background. Preserve the EXACT golden yellow box-shaped robot: squared head/body with two thin vertical dark eye slits, top lid angled upward, tiny corner bolts, black articulated shoulder joints, chunky gold forearms, short segmented legs and square feet, three-quarter view facing slightly left as in the reference. Preserve the original low resolution pixel art and color palette; hard square pixels and dark outlines, no smoothing, no gradients, no new details, no redesign. Center a SINGLE complete robot with all feet visible and wide transparent padding. No text, no shadows, no platform, no additional poses. This is a 40x48-ish pixel game training dummy, enlarged with nearest-neighbor blocks.

## Animação e mecânicas

`tools/prepare_pixel_avatars.py` gera somente metadados SpriteFrames/AtlasTexture. Não altera os PNGs dos personagens. As duas armas têm idle de oito quadros a 5 fps, deslocamento de respiração de um pixel e apoio das mãos. O giro da escova usa 12 poses a 20 fps, alternando direção e perspectiva do corpo sobre os quadros originais de corrida.

`scripts/special_ability.gd` controla custos e tempos: 50 pontos para o primeiro ataque, 100 para o segundo. A barra tem separador central nos modos solo e cooperativo. P1 usa Q para especial/R para cura; P2 usa I/O. O giro dura seis segundos e pode atingir a cada 0,4 s. Sua energia não se recompõe pelos próprios acertos nem passivamente durante a execução.

Os outros três especiais são propostas iniciais: escovada com onda de espuma (barra cheia), rajada pressurizada em três linhas (meia barra) e bolha gigante explosiva (barra cheia). O dummy recebe dano sem morrer, não interfere na conclusão do tutorial e oferece E/U para preparar 50% ou 100% de energia.

## Verificação e prévia

- `tools/verify_specials_training.gd`: limiares e consumo, independência entre jogadores, duração em atualizações de 60 Hz, pausa, cancelamento, dano, projéteis, dummy e divisor da HUD.
- Regressões: equipamento, coreografia da escova, HUD, tutorial, ponte, posto, animações e combo.
- `tools/capture_specials_training.gd`: capturas reais do jogo, sem montagem de arte externa.
- `tools/export_specials_preview.py`: codifica as capturas em `art/previews/specials_training.gif`.

