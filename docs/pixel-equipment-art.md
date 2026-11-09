# Revisão pixelada dos equipamentos — 31/10/2026

Os sprites corporais são os PNGs originais de 32×32 em assets/avatars/Owlet_Monster e assets/avatars/Pink_Monster. Não houve alteração de pixels nesses arquivos. A revisão substitui o uso dos personagens redesenhados nos cinco spritesheets da versão anterior.

## Arquivos usados

- assets/avatars/Owlet_Monster.tres e Pink_Monster.tres: quadros originais, montagem de 12 quadros, espera, corrida, salto e movimentos das armas.
- assets/animations/toothbrush_pixel.png e .tres: escova de dentes com cerdas claras e cabo ciano.
- assets/animations/bubble_blaster_pixel.png e .tres: arma de bolhas com tanque verde.
- scripts/pixel_equipment_pose.gd: encaixe das armas nas luvas originais; poses distintas e rastros de escovada.
- scripts/pixel_avatar_visual.gd: composição em canvas de pixels, exibido em escala inteira 2× sem filtro. Alpha recortado na renderização para evitar halos.
- tools/prepare_pixel_avatars.py: regenera somente os recursos Godot e as regiões AtlasTexture. Não redesenha nem reamostra PNGs.
- art/previews/equipment_combat.gif: captura da montagem, três golpes, ataque no ar e metralhadora no jogo.

## Animações de escova

F/J em sequência: lateral (12 quadros / 0,56 s), ascendente (12 / 0,58 s), golpe forte de cima para baixo (14 / 0,74 s). Ataque no ar: 10 quadros / 0,52 s. A sequência reinicia após 0,42 s sem continuar, contados a partir do fim do golpe. O mesmo relógio dirige contato, passada e animação; a pausa do jogo congela todos. Corrida e salto usam os seis e oito quadros originais. A revisão de coreografia e a redução da escova estão descritas em `docs/brush-choreography.md`.

## Geração das duas texturas de equipamento

Ferramenta: image_gen integrada, com transparent_background=true. Os PNGs gerados foram copiados para o projeto sem edição. Os corpos dos personagens não passaram pela ferramenta de imagem.

### Prompt final — escova

Use case: stylized-concept. Asset type: transparent pixel-art game equipment sprite, a toothbrush used as a tiny sword. One single isolated toothbrush pointing horizontally right, with handle at left, long turquoise handle, small rectangular head at right with clearly visible upright white and pale cyan bristle tufts along its TOP edge. Exact old-school 32x12 pixel-art design, enlarged with nearest-neighbor square blocks to fill this image. Dark navy one-logical-pixel outline, 5 flat colors, no gradients, no antialiasing, no soft glow, no diagonal orientation, no perspective, no character or hands, no text, no scene, no shadow. Every pixel is a huge hard square as in a 32 pixel wide SNES equipment icon. Straight horizontal shaft with an ergonomic thicker grip at the LEFT end. Head occupies the right quarter of the object's length. Entire object centered with transparent padding on all sides. True transparent background.

### Prompt final — metralhadora

Use case: stylized-concept. One isolated SOAP BUBBLE BLASTER weapon sprite on genuine transparent background, pointing horizontally RIGHT. Classic 1990s 16-bit equipment icon, only 24 by 16 logical pixels, enlarged into very big crisp square blocks. Dark navy one pixel outline. Compact cyan gun with a small lime-green soap tank on top, short dark grip underneath on left, white highlights, silver square barrel at far right with two tiny round barrel openings. Friendly laboratory cleaning equipment. 6 flat solid colors maximum. HARD-EDGED OPAQUE PIXELS ONLY. No glow, no bloom, no halo, no shadows, no soft edges, no antialias, no smooth surfaces, no gradients, no text, no characters or hands, no bubbles outside the gun. Whole gun inside image with wide transparent margins. Flat side view, not diagonal or perspective. Usable low-resolution game inventory sprite.

