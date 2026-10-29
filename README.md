# Science Attack

Jogo Godot 4.7 com abertura e uma primeira fase jogável de beat 'em up cooperativo.

## Jogar
Abra `project.godot` e pressione F5. Enter ou clique avança as falas; Espaço pausa a abertura e R repete. Max e Amanda entram correndo juntos, seguem às cápsulas e dormem em tamanho normal. A câmera escurece e abre a fase dos microavatares, controlados remotamente pelos cientistas.

- P1: WASD para mover, Espaço para saltar, F para combo, Shift para esquivar e E para construir ou ajudar.
- P2: Enter alterna IA e controle local; setas para mover, J para combo, K para saltar, L para esquivar e U para construir ou ajudar.
- F1 abre a ajuda de teclado e pausa o combate enquanto a ajuda está aberta.
- R reinicia a fase durante o jogo.

O combate permite movimento lateral e em profundidade, combo de três golpes, ataques no salto, esquiva com invulnerabilidade, recuo e bônus de dano ao atacar em dupla. Um parceiro sem vida pode ser reanimado mantendo a ação cooperativa perto dele. O segundo avatar acompanha e combate por IA até a entrada do segundo jogador.

O primeiro estágio é um tutorial guiado. Os avatares despertam deitados numa cutscene de 3,6 segundos antes de o controle ser liberado. A IA orienta a dupla pelo comunicador no HUD, com retrato azul e uma dica por vez: andar, pular e aterrissar, desviar, quebrar caixas, combater um germe e construir em dupla. Ela não possui entidade no mundo. As lições exigem ações de um jogador humano; o parceiro automático não as completa sozinho. Setas indicam os alvos. A ajuda completa só aparece com F1.

Quebre caixas e derrote germes para coletar peças. Reúna a dupla no terminal e segure E/U para montar a ponte com oito peças. Atravesse, vença a segunda onda e limpe o setor. A câmera acompanha a dupla. Esta entrega contém uma fase inicial; ainda não contém campanha, multiplayer online ou suporte a controle.

O objetivo permanece visível: **Abra a passagem**. As caixas laranja fornecem blocos amarelos visíveis no chão. Com oito peças, aproxime-se do console e segure E (ou U para P2). Os personagens executam uma animação própria de seis quadros enquanto as peças voam em arco até os encaixes. A passagem se forma em três seções; soltar a tecla pausa o trabalho, e é possível retomá-lo. A IA ajuda a montar e reanimar, mas não ataca a bactéria de treinamento; ela volta a combater após o tutorial.

Os destroços das caixas pousam e permanecem no chão durante a fase. Os novos sprites de montagem foram gerados usando os spritesheets originais como referência. Fonte, prompt e preparo dos arquivos: `docs/build-animation-prompts.md`. Prévia: `art/previews/construction.gif`.

O estágio usa o pacote cartoon Industrial de Kenney para piso, paredes, janelas, caixas, terminal e barreiras, e germes prontos de ChiliGames. O piso é contínuo, incluindo as bordas da câmera e o trecho da ponte. As caixas são RigidBody2D: bloqueiam os pés, podem ser empurradas, recebem impulso, resistem a dois golpes leves e liberam fragmentos físicos ao quebrar. Há colisões reais no terminal, na barreira e nos limites da fase. Fontes e licenças estão em `assets/third_party/CREDITS.md`. A captura atual é `art/previews/cartoon_communicator.png`.

## Cenas editáveis

- `scenes/laboratory_intro.tscn`: cenário, atores, câmera, cápsulas, efeitos, diálogo e camadas da abertura.
- `scenes/actors/micro_player.tscn`: CharacterBody2D, AnimatedSprite2D, colisão nos pés, sombra e área de golpe.
- `scenes/actors/germ.tscn`: inimigo, colisão, corpo, olhos e vida.
- `scenes/actors/cartoon_crate.tscn`: caixa física, colisão, vida, material e fragmentos.
- `BuildSite` em `scenes/gameplay/micro_arena.tscn`: oito peças, desenho da passagem, contador e montagem progressiva, todos como nós salvos.
- `scenes/gameplay/micro_arena.tscn`: cenário, caixas, ponte, terminal, personagens, câmera e HUD. Todos são nós reais salvos no projeto.
- `assets/avatars/*.tres`: SpriteFrames com todas as regiões dos spritesheets de idle, corrida, ataques, salto, dano, morte e empurrar.

Scripts cuidam das regras, movimento, IA e eventos. Os inimigos são instâncias da cena Germ; o cenário e os jogadores ficam montados no editor. A montagem das texturas dos cientistas usa o atlas original. A animação Push está configurada no recurso para uso futuro.

## Assets
Os microavatares Owlet e Pink foram importados da pasta AVATAR fornecida. O pacote original e sua referência de licença estão em `assets/avatars`. O personagem Dude foi preservado para expansão. As artes do laboratório e cientistas e seus prompts estão em `assets`, `art` e `docs`.

## Verificação
`Godot --headless --path . --script res://tools/verify_micro_game.gd`

Verifica piso contínuo, comunicador sem entidade, corpos físicos, impulso dos golpes, fragmentos, liberação da colisão, despertar, teclado, tutorial, combate, reanimação e construção cooperativa. Prévias anteriores registram versões antigas da fase.
