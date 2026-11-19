# Artes da descida e entrada da Colmeia

Geradas em 17/11/2026 com a ferramenta integrada `image_gen`. Sem uso de API/CLI externo. Os originais estão em `art/source/lower_lab/`. O preparo técnico em `tools/prepare_descent_art.gd` somente recorta e dimensiona com nearest-neighbor, preservando o alpha do elevador.

Recursos finais:

- `assets/environment/lower_lab/broken_exit_elevator.png` — cabine quebrada e contaminada, 280 × 230.
- `assets/environment/lower_lab/shaft_wall.png` — trecho do poço, 640 × 320, usado na rolagem vertical.
- `assets/environment/lower_lab/shaft_deck.png` — plataforma fixa, 640 × 176.
- `assets/environment/lower_lab/hive_entrance.png` — entrada da Colmeia, 1280 × 360.

## Elevador quebrado

Referência/edit target: `assets/environment/cooperative_elevator.png`. Saída transparente, original `art/source/lower_lab/broken_exit_elevator.png`.

Edit this game elevator into a BROKEN AND CONTAMINATED version for a child-friendly pixel-art beat-em-up. Keep exactly the same frontal viewpoint, chunky blue steel structure and central open doorway, same proportions and silhouette so game characters can enter. Obvious damage: torn upper-right motor casing, exposed copper wires, bent upper beam, cracks and dents, one broken cyan lamp, loose panel dangling on the right column. Thick vivid green bacterial slime growing over top beam and side pillars, hanging slimy drips; keep the central entrance and boarding floor clear. Doors open with interior visible. Full object on true transparent background; no background, shadow, floor outside the cabin, text, labels, humans or monsters. Coarse crisp pixel clusters suitable for reducing to 280x230, old-school 16-bit game style. This is one single elevator sprite, not a sprite sheet. No flame, repair tools, UI or colored rectangular background.

## Poço e plataforma

Referência: imagem de cenário anexada pelo usuário, usada para ambiente e perspectiva. Original `art/source/lower_lab/shaft_environment.png`.

Original environment asset atlas for a pixel-art side-view beat-em-up elevator battle. Reference is ONLY for the industrial elevator setting and perspective. NO characters, enemies, text, numbers, UI, logos or copied game graphics. Exactly TWO WIDE PANELS stacked vertically, equal height, no gaps or borders, square overall canvas. TOP HALF is ONLY the shaft wall: seamless vertically repeating dark navy and violet steel panels, strong vertical rails at x about 15% and 85%, bolts, layered metal braces, little cyan/green lights. Some small vivid green bacterial slime patches adhering to rails, sparse hanging slime strands, visible mechanical depth. No platform or floor in top half; rails extend straight to upper and lower panel edges so this part can scroll upward forever. BOTTOM HALF is ONLY the stationary elevator combat deck in the same perspective as reference: wide empty gray-blue steel platform filling most of the panel, shallow perspective sloping side rails with dull golden yellow rims, hazard strip corners, rear control pillar at far right, huge uncluttered central walkable floor with seams and scratches. Minor green slime at corners, none across middle floor. Top of bottom panel is rear edge of platform; bottom of bottom panel is near front edge. Cohesive coarse crisp SNES arcade pixel art, large readable pixel clusters, limited palette, no smooth gradients, dramatic but child-friendly. Each panel will be cropped separately and downscaled for a 640x360 game.

## Colmeia

Original `art/source/lower_lab/hive_entrance.png`, sem imagem de referência.

Original wide 16-bit pixel art background for the entrance of the final level called the bacterial hive in a children's laboratory beat-em-up. Wide landscape 16:9 composition. Side-view with a little floor depth, matching an old arcade beat-em-up. Abandoned industrial laboratory completely overtaken by thick dark emerald green living slime, rounded bacterial colony lobes, translucent glowing green sacs and organic hexagonal cavities grown over steel walls. Thick hanging slime strands, remnants of blue metal rails at left suggesting the elevator just arrived. Far right an ominous but child-friendly organic arch deeper into the hive, warm lime light glowing inside, NO actual bees or insects. Clear continuous gray-green floor band across the entire bottom third for walking and fighting; keep this walking band mostly empty except small stains at its rear edge. Dark teal and forest-green shadows, brighter lime highlights, crisp large square pixel clusters, limited palette, no smooth rendering. No characters, no UI, no typography, no text, no logos, no gore, not horror. This is a finished game environment, no mockup frame.
