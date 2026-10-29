# Science Attack

Jogo Godot 4.7 com abertura e uma primeira fase jogável de beat 'em up cooperativo.

## Jogar
Abra `project.godot` e pressione F5. Enter ou clique avança as falas; Espaço pausa a abertura e R repete. Max e Amanda entram correndo juntos, seguem às cápsulas e dormem em tamanho normal. A câmera escurece e abre a fase dos microavatares, controlados remotamente pelos cientistas.

- P1: WASD para mover, Shift para correr, F para combo, G para saltar, H para esquivar, E para construir ou ajudar.
- P2: F2 alterna IA e controle local; setas para mover, K para combo, L para saltar, ponto e vírgula para esquivar, O para construir ou ajudar.
- R reinicia a fase durante o jogo.

O combate permite movimento lateral e em profundidade, combo de três golpes, ataques no salto, esquiva com invulnerabilidade, recuo e bônus de dano ao atacar em dupla. Um parceiro sem vida pode ser reanimado mantendo a ação cooperativa perto dele. O segundo avatar acompanha e combate por IA até a entrada do segundo jogador.

Quebre caixas e derrote germes para coletar peças. Reúna a dupla no terminal e segure E/O para montar a ponte com oito peças. Atravesse, vença a segunda onda e limpe o setor. A câmera acompanha a dupla. Esta entrega contém uma fase inicial, com cenário geométrico editável; ainda não contém campanha, multiplayer online ou suporte a controle.

## Cenas editáveis

- `scenes/laboratory_intro.tscn`: cenário, atores, câmera, cápsulas, efeitos, diálogo e camadas da abertura.
- `scenes/actors/micro_player.tscn`: CharacterBody2D, AnimatedSprite2D, colisão nos pés, sombra e área de golpe.
- `scenes/actors/germ.tscn`: inimigo, colisão, corpo, olhos e vida.
- `scenes/gameplay/micro_arena.tscn`: cenário, caixas, ponte, terminal, personagens, câmera e HUD. Todos são nós reais salvos no projeto.
- `assets/avatars/*.tres`: SpriteFrames com todas as regiões dos spritesheets de idle, corrida, ataques, salto, dano, morte e empurrar.

Scripts cuidam das regras, movimento, IA e eventos. Os inimigos são instâncias da cena Germ; o cenário e os jogadores ficam montados no editor. A montagem das texturas dos cientistas usa o atlas original. A animação Push está configurada no recurso para uso futuro.

## Assets
Os microavatares Owlet e Pink foram importados da pasta AVATAR fornecida. O pacote original e sua referência de licença estão em `assets/avatars`. O personagem Dude foi preservado para expansão. As artes do laboratório e cientistas e seus prompts estão em `assets`, `art` e `docs`.

## Verificação
`Godot --headless --path . --script res://tools/verify_micro_game.gd`

Verifica corrida simultânea, sono sem encolhimento, dano, um acerto por golpe, queda, reanimação e abertura cooperativa da ponte. A captura atual está em `art/previews/micro_gameplay.png`. Prévias anteriores mostram versões antigas da abertura.
