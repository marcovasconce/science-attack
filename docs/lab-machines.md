# Máquinas e puzzle dos tubos

- Gerador: carcaças turquesa, console com osciloscópio, engrenagens douradas vazadas e animação por quadros. Indicadores pequenos embutidos na frente da carcaça e alavanca com suporte e cabo da mesma família visual. Mantém montagem em nove peças e partida gradual.
- Vapor: um único sprite translúcido ancorado por saída, com quatro quadros, sem contorno escuro. O shader suaviza as bordas e limita a opacidade. Aparece durante a mesma janela de dano; a ajuda pausa a animação.
- Puzzle: tubo esquerdo começa com água; direito vazio. O jogador precisa se aproximar do botão sob o tubo direito e pressionar sua tecla de interação (E ou U) para iniciar três segundos de sucção. Apenas as três rodas que controlam os canos permanecem. A água só avança depois da coleta; com o circuito completo, lava o tubo por 3,2 segundos. Os checkpoints posteriores restauram o circuito limpo.
- Máquina de limpeza: um monitor animado, dois tubos com o cano inserido pelas bocas e engrenagens reunidas em uma carcaça ao lado. O líquido da entrada baixa e muda de cor, e a saída enche durante as três ondas (90% do processo); o enxágue final completa os 10% restantes. Sem legendas, placas de texto, lâmpadas soltas ou telas sobrepostas. A ajuda pausa também essa transferência.
- Cenário: a mesa foi retirada e substituída por tubos menores junto ao fundo, com contraste reduzido e sombras de contato discretas. As caixas de peças usam a mesma cena animada da fase inicial; as caixas médicas reutilizam sua textura, mantendo o conteúdo e a coleta.
- Câmera: acompanha os jogadores até o limite real do mapa, permitindo enxergar além dos portões ainda fechados. A colisão das barreiras e a progressão permanecem.

As carcaças, engrenagens, fumaça e monitores usam `assets/environment/machines/lab_atlas.png`, gerado com a ferramenta integrada ImageGen. O prompt exato e a origem estilística estão junto do atlas. Os tubos reutilizam o PNG original `assets/environment/tabletop_props.png`, com shader próprio para nível, cor, reflexos e bolhas, sem alterar o original.

Validação:

```text
godot --headless --path . --script res://tools/verify_tabletop_route.gd
godot --headless --path . --script res://tools/verify_tabletop_stage.gd
godot --headless --path . --script res://tools/verify_debug_phases.gd
godot --path . --script res://tools/capture_lab_machines.gd
```

As quatorze capturas ficam em `art/previews/lab_*.png`, incluindo estados intermediários da primeira e segunda ondas para verificar a transferência gradual. O botão de sucção usa o sprite elevado de `lab_controls.png`, com chevron discreto antes da ativação e posição pressionada após a interação.
