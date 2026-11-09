# Germes, dash e ajuste da água

- Folha de germes: `assets/animations/germs_laugh_breathe.png`, gerada com a ferramenta integrada ImageGen a partir da referência do usuário; transparência preservada.
- Prompt usado: abaixo. Metadados em `germ_poses.tres`; `tools/prepare_germ_poses.py` lê os recortes e alinhamentos sem alterar o PNG.
- Verde: 130 de vida. Vermelho: 260. O primeiro inimigo guiado tem 72 de vida. Cada onda contém um vermelho e três/quatro verdes. Os quatro desenhos de cada variante agora seguem a sequência 0–1–2–3–2–1, a oito poses por segundo, sem as antigas pausas de 0,4 s. Respiração e balanço da caminhada são amostrados a 30 Hz; os recortes mantêm altura e pés alinhados para evitar saltos de tamanho. O relógio congela junto com a pausa do jogo.
- Renderização em canvas de baixa resolução, com pixels ampliados 2x e filtragem nearest. Vida, colisões, golpes, drops e progressão continuam usando o mesmo inimigo base.
- Caminhada armada: o corte da última linha passa pelo espaço vazio em x=1200; o cano do quadro anterior deixa de aparecer solto no último quadro. Os PNGs originais dos avatares e das poses armadas não foram alterados.
- Dash: usa o mesmo deslocamento de 0,24 s; inclinação breve, dois rastros com duração de 0,11 s e pequenos traços nos pés. Funciona em ambos os jogadores, direções e equipamentos; congela com os menus e limpa ao finalizar.
- Especial completo da escova: escala do splash caiu de 0,22 para 0,14 (36% menor), bolhinhas menores e onda de água com espuma em pixels. Mantém alcance, dois pulsos de dano e tremor.
- Verificação: `verify_germs_dash.gd`, `verify_armed_movement.gd`, `verify_water_specials.gd`, `verify_equipment_combat.gd`, `verify_supply_encounter.gd`, `verify_micro_game.gd`, `verify_impacts_combo.gd`, `verify_specials_training.gd`.
- Prévia real do Godot: `art/previews/germs_dash_water.gif`, produzida por `capture_germs_dash.gd` e `export_germ_dash_preview.py`.

## Prompt final — ferramenta integrada ImageGen

```text
Use case: identity-preserve. Asset: transparent low-resolution pixel-art enemy animation sprite sheet for a 2D beat-em-up. The attached image contains the two enemy identities to preserve. Generate exactly EIGHT complete sprites in a strict 4-column by 2-row grid, ample padding with no overlap, equal cell dimensions, each row has a shared ground baseline.
TOP ROW: four sequential frames of the GREEN ROUND GERM on the LEFT of the reference. Preserve lime-green bumpy round body, short green stalks/spikes, enormous brown-rimmed open mouth and little yellow teeth, the goofy villain expression. Animate a short chuckle/laugh: frame 1 relaxed open grin, frame 2 mouth slightly closes and cheeks rise, frame 3 wide laughing mouth, frame 4 returns toward grin. Stalks jiggle slightly. No arms/legs added.
BOTTOM ROW: four frames of the TALL DARK RED GERM on the RIGHT of the reference. Preserve capsule-shaped red bumpy body, two long curved horn-like antennae at the top, side nubs and the wide brown-rimmed dark mouth with yellow teeth. Subtle heavy breathing/snarl animation, mouth opens/closes a little, antennae twitch. Stay tall and visibly more imposing than the green one.
Keep each creature's size constant throughout its row. Green roughly 30x28 logical pixels, red roughly 28x46 logical pixels. Coarse square pixels, stepped edges, dark outline, compact palette, nearest-neighbor enlarged; retain the reference designs rather than inventing new monsters. Flat pixel clusters, no smoothing, no blur, no shadows, no ground, no scenery, no gradients, no glow, no text/grid/labels. Fully transparent background alpha=0 and opaque sprite pixels. There must be exactly four green enemies on top and four red enemies below.
```

