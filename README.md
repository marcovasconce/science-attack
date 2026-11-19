# Science Attack

Beat 'em up microscópico feito em Godot 4.7. Jogue sozinho com Amanda na IA ou em dupla local.

[Baixar o jogo para Windows](https://github.com/marcovasconce/science-attack/releases/latest)

## Elevador cooperativo e germes

Os germes verdes têm 130 de vida, os vermelhos 260 e o germe do tutorial 72 (o dobro dos valores anteriores). As expressões usam uma sequência de ida e volta a oito poses por segundo, com respiração/balanço a 30 Hz e alinhamento dos pés, mantendo a arte pixelada.

Depois do posto de apoio, equipe **os dois personagens** no robô. Ao fechar o painel, a seta existente indica a continuação à direita, depois do robô de treino. O elevador tem duas plataformas vermelhas: cada uma fica verde com um personagem vivo e apoiado no chão. Ambos precisam ocupar plataformas diferentes simultaneamente por 0,4 s. Sair, saltar ou cair cancela a confirmação. A Amanda controlada por IA contorna a coluna e ocupa a plataforma livre no modo solo.

A cabine sobe com os dois jogadores durante 2,6 s, com escurecimento gradual até uma tela preta de carregamento. Ajuda e troca de IA/P2 ficam bloqueadas durante a transição; F2 continua reiniciando. O destino `next_scene_path` aponta para a segunda fase sobre a bancada. O carregamento é assíncrono, e o novo estágio consome `party_state`, preservando equipamentos, vida, energia, frascos e modo IA/P2.

Cena editável: `scenes/environment/cooperative_elevator.tscn`. Sprite e prompt: `docs/elevator-art.md`. Capturas reais: `art/previews/elevator_one_ready.png`, `elevator_both_ready.png`, `elevator_ascending.png` e `elevator_loading.png`.

Verificação: `Godot --headless --path . --script res://tools/verify_elevator.gd`, `res://tools/verify_elevator_loading.gd` e `res://tools/verify_germs_dash.gd`. Capturas: `Godot --path . --script res://tools/capture_elevator.gd`.

## Segunda fase: bancada do laboratório

A dupla chega à mesa em tamanho microscópico. O fundo lembra a sala da abertura, com o monitor azul, cápsulas verdes, janelas e passarela; o laboratório distante se desloca mais lentamente que a câmera. Sobre a bancada há cinco tubos grandes com líquidos ciano/verde animados (superfície ondulante e bolhas), duas canetas e dois lápis.

Depois do carregamento, as portas do elevador deslizam e liberam a saída pela frente. Ao sair um jogador humano, Tibúrcio aparece no comunicador e diz: **“vamos, sigam em frente, detectei bastante germes a caminho”**. E/U revela e depois fecha a fala. A seta indica a continuação, com dois grupos de três germes verdes e um vermelho. Armas, vida, energia, frascos e modo solo/cooperativo vêm da fase anterior. F2 reinicia a bancada com os recursos da chegada.

Para abrir a fase diretamente no editor, use `scenes/gameplay/tabletop_stage.tscn` e F6; nesse caso, Max começa com escova e Amanda com bolhas. Arte, prompts e verificações: `docs/tabletop-stage-art.md`. Prévia animada: `art/previews/tabletop_stage.gif`.

## Jogar
Abra `project.godot` e pressione F5. Marque **Jogar em dupla** no menu para dois jogadores no mesmo teclado. Enter ou clique avança as falas, Espaço pausa a abertura e F2 repete. Max e Amanda entram correndo juntos, seguem às cápsulas e dormem em tamanho normal. A câmera escurece e abre a fase dos microavatares, controlados remotamente pelos cientistas.

- P1: WASD para mover, Espaço para saltar, F para combo, Shift para esquivar, E para construir/interagir, Q para especial e R para usar um frasco de cura.
- P2: Enter alterna IA e controle local; setas para mover, J para combo, K para saltar, L para esquivar, U para construir/interagir, I para especial e O para usar um frasco de cura.
- F1 abre a ajuda de teclado e pausa o combate enquanto a ajuda está aberta.
- F2 reinicia a fase durante o jogo.
- Controle no PC com layout reconhecido pelo Godot. Direcional ou analógico esquerdo move. **A/✕** pula, **X/□** bate, **B/○** desvia, **Y/△** usa o especial, **RB/R1** interage e **LB/L1** cura. O menu usa o botão de confirmar.
- O primeiro controle assume Max. O segundo entra com **Menu/Options**. Em uma dupla com teclado e controle, ative **Jogar em dupla** e inicie com o teclado, ou use **Menu/Options** no controle durante uma partida solo iniciada pelo teclado. O HUD segue o último dispositivo usado por cada jogador. O primeiro jogador abre a ajuda com **Menu/Options**. Com a ajuda aberta ou com os dois caídos, **View/Share/Create** reinicia.

O combate permite movimento lateral e em profundidade, combo de três golpes, ataques no salto, esquiva com invulnerabilidade, recuo e bônus de dano ao atacar em dupla. Um parceiro sem vida pode ser reanimado mantendo a ação cooperativa perto dele. O segundo avatar acompanha e combate por IA até a entrada do segundo jogador. A abertura aceita **Backspace**, **B** ou **○** para pular. **Esc** abre o menu de pausa durante a abertura e as fases, com opções para continuar ou voltar ao menu principal. No terminal e no painel de equipamentos, **Esc** fecha a interface em uso.

O primeiro estágio é um tutorial guiado. Os avatares despertam deitados numa cutscene de 3,6 segundos antes de o controle ser liberado. A IA orienta a dupla pelo comunicador no HUD, com retrato azul e uma dica por vez: andar, pular e aterrissar, desviar, quebrar caixas, combater um germe e construir em dupla. Durante as lições ele usa o comunicador; após limpar o primeiro setor, a dupla encontra Tibúrcio Ung pessoalmente no posto de apoio. As lições exigem ações de um jogador humano; o parceiro automático não as completa sozinho. Setas indicam os alvos. A ajuda completa só aparece com F1.

Quebre caixas e derrote germes para coletar parafusos pixelados. Reúna a dupla na margem do rombo, junto ao marcador de parafuso, e segure E/U para montar a ponte metálica com oito parafusos. Atravesse, vença a segunda onda e siga a seta para encontrar Tibúrcio Ung e o robô de apoio. Equipe a dupla e use o elevador para chegar à bancada do laboratório. Ao terminar a bancada, o próximo elevador desce para o setor inferior. A campanha passa pelo tutorial, pela bancada e pelo setor inferior até chegar à Colmeia. A dupla joga no mesmo PC.

## Fase 2: setor inferior

O cenário reaproveita o tutorial com tons verdes e gosma no elevador, atrás dos personagens. Rei Bactéria e Tibúrcio desacordado, com o olho fechado, formam uma única sprite de seis quadros: a boca mexe e a gosma estica, se solta e cai. Depois da fala e da fuga, um emblema sem fundo pisca por um segundo e começa uma onda de 48 voadoras. Ao terminar, o alerta se repete e chegam outras 80. Elas atravessam a tela, causam dano no contato e continuam voando; um ataque de qualquer arma as derrota. Vida, energia, frascos, equipamentos e modo cooperativo passam de uma fase para outra. F2 reinicia a abertura com os recursos da chegada.

A IA mantém o foco nas voadoras que chegam pela frente e não persegue as que já passaram. Após as ondas, o caminho continua entre armários danificados, placas de risco biológico e computadores em chamas, com fogo e fumaça animados. Poças tóxicas causam dano ao pisar; desvie ou salte. O companheiro contorna as poças automaticamente. O computador perto da porta bloqueada é ativado com E/U: a câmera aproxima, o sistema inicializa e aparece um puzzle 3×3 usando a sprite original de Tibúrcio. Clique em duas peças para trocá-las, ou use WASD/setas e E/U. Esc sai sem perder as trocas. Montar a imagem abre a porta e libera a passagem.

A porta é vista de perfil e o fogo usa doze quadros baseados na referência. Quando a porta acaba de abrir, chegam seis bactérias verdes, três vermelhas e três voadoras amarelas. As amarelas têm 195 de vida (verde: 130; vermelha: 260), voam alto e cospem bolas de gosma pixeladas. Pule e ataque para derrubá-las; depois da animação de queda, elas voam baixo por dez segundos e podem ser atingidas do chão. Se sobreviverem, voltam ao alto. A IA também pula para enfrentar esse inimigo. Prévia em `art/previews/yellow_flyer_knockdown.gif`; artes e prompts em `docs/lower-lab-combat-art.md`.

Há nove caixas em posições sorteadas pelo corredor; cada uma tem 50% de chance de soltar um frasco de cura. Os enxames bloqueiam o avanço até terminar, o puzzle começa com todas as nove peças fora do lugar e Amanda dá uma dica rápida sobre as voadoras. O poço do elevador agora tem estrutura e trilhos contínuos.

Depois da leva após o puzzle, pegue o sabão no armário de contorno amarelo com E/U e use E/U diante da gosma que bloqueia o caminho. A espuma limpa a passagem. Mais adiante, o Guardião do Rei surge com tremor e fala, fecha a arena e avança de escudo. Desvie da faixa marcada: cada impacto na parede faz cair três TNTs em posições aleatórias. Elas explodem após pousar ou ao serem atingidas; a explosão também fere o boss. A vida do guardião tem uma camada laranja e outra vermelha. Vencê-lo reabre a arena. Artes e prompts em `docs/lower-lab-finale-art.md`.

Para testar diretamente, use **Capítulos → Chegada ao laboratório** no menu principal. Cena: `scenes/gameplay/lower_lab_stage.tscn`. Detalhes, assets e verificações em `docs/lower-lab-stage.md`; prompts da ferramenta imagegen integrada em `docs/lower-lab-art-prompts.md`. Capturas em `art/previews/lower_lab_*.png`.

O objetivo permanece visível: **MONTE A PONTE**. As caixas metálicas cinzas fornecem parafusos, que saltam e pousam no chão. Com oito parafusos, aproxime-se da margem do rombo e segure E (ou U para P2). Os personagens executam uma animação de seis quadros enquanto os parafusos voam em arco até os encaixes. A ponte de aço aparece em três seções da esquerda para a direita; soltar a tecla pausa o trabalho, e é possível retomá-lo. O rombo bloqueia fisicamente toda a profundidade caminhável, inclusive durante salto e esquiva, até a ponte ficar pronta. A IA ajuda a montar e reanimar, mas não ataca a bactéria de treinamento; ela volta a combater após o tutorial.

Os destroços das caixas pousam e permanecem no chão durante a fase. Os novos sprites de montagem foram gerados usando os spritesheets originais como referência. Fonte, prompt e preparo dos arquivos: `docs/build-animation-prompts.md`. Prévia: `art/previews/construction.gif`.

O estágio microscópico usa um fundo original de painéis azul-petróleo e piso metálico inspirado na referência fornecida, sem prateleiras, computadores, servidores ou móveis. A parede e o piso são regiões nativas de textura na cena `scenes/environment/microscopic_stage.tscn`. O rombo é desenhado por `scripts/floor_rift.gd`; a ponte usa uma textura de aço dividida em três regiões. A abertura do laboratório não foi alterada. O tutorial usa a mesma fonte Press Start 2P, texto branco, caixa azul-escuro com borda pixelada e retrato lateral da abertura, com revelação gradual das falas.

As caixas são RigidBody2D: bloqueiam os pés, podem ser empurradas, recebem impulso, resistem a dois golpes leves e liberam fragmentos físicos ao quebrar. Há colisão no rombo e nos limites da fase. Fontes e licenças anteriores estão em `assets/third_party/CREDITS.md`. Os novos assets foram gerados pela ferramenta imagegen integrada; prompts e regiões estão em `docs/microscopic-stage-art-prompts.md`. Prévia atual: `art/previews/microscopic_bridge.gif`.

## HUD e cura

A HUD pixelada mostra os retratos dos microavatares, a vida em verde, o especial em azul e um frasco de laboratório verde com a quantidade disponível. No solo, Max usa o painel principal e Amanda aparece numa linha compacta identificada como IA. Enter alterna para dois painéis completos lado a lado, preservando vida, especial e inventário de cada personagem. A barra azul acompanha `energy`, tem um divisor exatamente em 50% e indica quando o especial de meia barra ou de barra cheia está pronto.

Cada personagem começa com 5 frascos. R (P1) ou O (P2) consome um frasco e recupera 25 pontos, limitado à vida máxima. Não há consumo com vida cheia, sem estoque, durante pausas/cutscenes ou quando caído; a reanimação cooperativa continua necessária. A IA usa seu próprio estoque quando a vida chega a 35% ou menos. `max_hp`, `healing_flasks` e `flask_heal_amount` podem ser ajustados no Inspector dos personagens.

Os painéis são cenas editáveis em `scenes/ui/character_hud.tscn` e `scenes/ui/team_hud.tscn`. O frasco é um SVG pixelado local em `assets/ui/healing_flask.svg`. As cores, barras, textos e posições estão nos nós dessas cenas e no script de layout. A HUD fica fixa na tela e não acompanha o movimento da câmera.

Verificação específica: `Godot --headless --path . --script res://tools/verify_hud.gd`.
Capturas reais: `Godot --path . --script res://tools/capture_hud.gd`, salvas em `art/previews/hud_solo.png` e `hud_coop.png`.

## Cenas editáveis

- `scenes/laboratory_intro.tscn`: cenário, atores, câmera, cápsulas, efeitos, diálogo e camadas da abertura.
- `scenes/actors/micro_player.tscn`: CharacterBody2D, AnimatedSprite2D, colisão nos pés, sombra e área de golpe.
- `scenes/actors/germ.tscn`: inimigo, colisão, corpo, olhos e vida.
- `scenes/actors/cartoon_crate.tscn`: caixa física, colisão, vida, material e fragmentos.
- `BuildSite` em `scenes/gameplay/micro_arena.tscn`: oito parafusos, desenho da passagem, contador e montagem progressiva, todos como nós salvos.
- `scenes/gameplay/micro_arena.tscn`: cenário, caixas, ponte, rombo, personagens, câmera e HUD. Todos são nós reais salvos no projeto.
- `assets/avatars/*.tres`: SpriteFrames com todas as regiões dos spritesheets de idle, corrida, ataques, salto, dano, morte e empurrar.

Scripts cuidam das regras, movimento, IA e eventos. Os inimigos são instâncias da cena Germ; o cenário e os jogadores ficam montados no editor. A montagem das texturas dos cientistas usa o atlas original. A animação Push está configurada no recurso para uso futuro.

## Assets
Os microavatares Owlet e Pink foram importados da pasta AVATAR fornecida. O pacote original e sua referência de licença estão em `assets/avatars`. O personagem Dude foi preservado para expansão. As artes do laboratório e cientistas e seus prompts estão em `assets`, `art` e `docs`.

## Verificação
`Godot --headless --path . --script res://tools/verify_micro_game.gd`

Verifica piso metálico e rombo, comunicador sem entidade, corpos físicos, impulso dos golpes, fragmentos, liberação da colisão, despertar, teclado, tutorial, combate, reanimação e construção cooperativa. Prévias anteriores registram versões antigas da fase.

## Combo e impactos

A HUD foi reduzida cerca de 7% na largura e 9% na altura, mantendo a fonte legível. O contador amarelo `xN` aparece abaixo e à direita da HUD. Cada personagem possui seu próprio combo: somente acertos em inimigos somam; iniciar um ataque renova a janela de 5 segundos, mesmo sem acertar. Dano recebido realmente zera o combo, mas golpes bloqueados pela invulnerabilidade não. O contador expira somente após mais de 5 segundos sem atacar e fica congelado com a ajuda/pausa aberta. Entrar ou sair do modo cooperativo preserva os contadores de cada personagem.

Cada golpe em caixa gera uma estrela azul/branca animada; cada golpe em inimigo gera uma estrela de impacto branca e amarela que se desfaz em faíscas. São duas animações de seis quadros, com transparência, fixas no ponto de contato e independentes do alvo (inclusive no golpe final). O anel de fogo foi substituído pela nova estrela. Origem e prompts atuais: `docs/crate-salvage-art-prompts.md`; o efeito azul está documentado em `docs/impact-art-prompts.md`.

Verificação: `Godot --headless --path . --script res://tools/verify_impacts_combo.gd`.
Prévias: `Godot --path . --script res://tools/capture_impacts.gd`.

## Caixas metálicas e sucata

A nova caixa cinza segue a referência: moldura de metal claro, painel rebaixado escuro e presilhas nos cantos. Ela fica amassada/rachada no primeiro golpe; no último, toca quatro quadros de desmonte durante 0,44 s. A colisão some imediatamente, os golpes seguintes não geram recompensas duplicadas e a animação pausa com a ajuda aberta. O impacto azul nas caixas foi preservado.

Cada caixa libera três parafusos pixelados para a construção e dois fragmentos físicos de carcaça. O atlas dos itens contém seis orientações do mesmo parafuso de aço. Os parafusos saltam por 0,6 s, pousam e depois voam até a ponte durante a montagem. Sobras além das oito usadas na ponte continuam visíveis no chão. O tutorial identifica a caixa metálica.

Teste específico: `Godot --headless --path . --script res://tools/verify_crate_salvage.gd`.
Prévia: `Godot --path . --script res://tools/capture_crate_salvage.gd`; `tools/export_crate_preview.py` gera o GIF a partir dessas capturas.

## Rombo e ponte de metal

`Godot --headless --path . --script res://tools/verify_micro_bridge.gd` verifica colisão em toda a largura caminhável, bloqueio com ponte parcial, passagem após montagem, consumo de oito parafusos, sobras, pausa/retomada e fonte/layout do tutorial em solo e cooperativo.

`Godot --path . --script res://tools/capture_micro_bridge.gd` captura o cenário, a montagem e a travessia reais. Imagens em `art/previews/microscopic_stage.png`, `microscopic_gap.png`, `metal_bridge_building.png`, `metal_bridge_complete.png`, `metal_bridge_crossing.png` e `microscopic_coop.png`.

## Posto de apoio e Tibúrcio Ung

Após concluir o tutorial, montar a ponte e derrotar os cinco germes do primeiro setor de combate, aparece uma seta para a direita no estilo da HUD. O caminho continua até uma segunda área de painéis metálicos, com caixas já danificadas, Tibúrcio Ung (o microavatar azul do comunicador) e um robô de apoio de quatro patas. A câmera e os limites da fase acompanham essa continuação.

Aproxime-se de Tibúrcio e pressione E (P1) ou U (P2) para conversar. A primeira pressão durante a fala revela o texto inteiro; a próxima encerra a conversa. A fala usa o texto solicitado, com nome, retrato e a caixa azul pixelada. Ao se aproximar do robô aparece o aviso de equipamentos; E/U abre o painel para equipar Max e Amanda com espada escova de dentes ou metralhadora de bolhas de sabão. E/U ou Esc fecha. A conversa e o painel pausam o controle; a IA não inicia interações.

Teste: `Godot --headless --path . --script res://tools/verify_supply_encounter.gd`. Capturas: `Godot --path . --script res://tools/capture_supply_encounter.gd`. O sprite do robô e o prompt estão documentados em `docs/supply-outpost-art.md`.


## Equipamentos e animações pixeladas

Os dois avatares mantêm a escala dos personagens originais de 32×32 pixels, ampliada exatamente 2× sem suavização. Os estados armados usam sprites completos novos de espera e caminhada; os golpes da escova combinam os corpos originais com braços e equipamento animados. A montagem tem 12 quadros de mãos vazias; os parafusos continuam voando para a ponte. Um canvas pequeno mantém até as armas girando na mesma grade de pixels dos personagens.

No robô, cada avatar escolhe uma única arma por vez. É permitido aos dois escolher a mesma arma. P1 usa W/S para selecionar e F para equipar; no solo, A/D alterna entre Max e Amanda controlada pela IA. P2 usa setas para selecionar e J para equipar. Também é possível clicar nas opções. E/U ou Esc fecha o painel. A escolha mantém vida, energia, frascos e o equipamento do outro personagem; alternar IA/P2 preserva o equipamento. Reiniciar a fase volta ao soco normal.

- Espada escova: alcance de 112 pixels, comparado aos 65 do soco. Causa 28 de dano nos golpes leves e 40 no terceiro golpe. Cada golpe atinge um alvo uma vez, respeitando direção e profundidade. Segure F/J para repetir continuamente corte lateral (12 quadros), corte ascendente (12) e escovada forte de cima para baixo (14). Há também uma animação de 10 quadros para atacar durante o salto. A janela para continuar a sequência é de 0,42 s após cada golpe; uma pausa maior reinicia o primeiro movimento. A escova está cerca de 20% menor; o corpo prepara, se inclina, dá uma pequena passada e se recupera, mantendo o rastro branco/ciano e a grade de pixels original. A passada respeita paredes e o rombo. Detalhes em `docs/brush-choreography.md`.
- Metralhadora de bolhas: segure F/J para disparar a cada 0,28 s. Cada bolha viaja a 300 pixels/s por até 780 pixels, causa 10 de dano e estoura ao atingir um inimigo, caixa ou bloqueio sólido. O movimento considera todo o trecho percorrido entre quadros para evitar atravessar alvos. Bolhas não ferem aliados nem Tibúrcio. A IA usa distância apropriada à arma equipada e continua sem atacar a bactéria de treinamento.

Cada arma acompanha espera (8 quadros), corrida (6), salto (8), direção e altura do avatar. Nas novas poses de espera, os personagens seguram a escova inclinada ou apoiam a arma de bolhas com as duas mãos, com respiração discreta. O novo lançador usa metal azul/escuro, reservatório verde, mangueira e cano segmentado, renderizados na grade de pixels dos personagens. A arma de bolhas tem recuo de 4 quadros. As escovadas têm rastros brancos/cianos curtos e partículas quadradas. Os quadros de ataque acompanham o relógio do combate, inclusive durante a pausa do painel. As novas poses armadas de espera e caminhada vêm dos sheets completos em `assets/animations/max_armed_walk.png` e `amanda_armed_walk.png`, mantendo a escala pixelada original. A escova é segurada com as duas mãos e arrastada pelo chão; a arma de bolhas fica apoiada pelas duas mãos. Os golpes da escova preservam a coreografia anterior, agora com as duas mãos no cabo. Ao soltar F/J depois de manter pressionado, termina o golpe atual e a repetição para.

Verificação: `Godot --headless --path . --script res://tools/verify_equipment_combat.gd`, `res://tools/verify_pixel_animations.gd` e `res://tools/verify_brush_choreography.gd`.
Prévia: `Godot --path . --script res://tools/capture_equipment_combat.gd`, seguida de `python tools/export_equipment_preview.py`. GIF: `art/previews/equipment_combat.gif`. Arte atual e prompts: `docs/pixel-equipment-art.md`.

## Especiais e robô de treino

Com uma arma equipada, Q (P1) ou I (P2) escolhe automaticamente o especial: de 50 até menos de 100 pontos, consome 50; com 100, consome a barra inteira. Abaixo de 50 nada é consumido. Os jogadores têm energia independente; ataques especiais não recarregam a própria barra. Menus pausam os efeitos. É possível se mover devagar durante os especiais da escova e o lançamento da bolha gigante. Durante o jato de água, o personagem firma os pés e mantém a direção do disparo. Ainda é possível receber dano e cair.

- Escova, 50%: giro contínuo de seis segundos, corpo girando e rastro branco/ciano, atingindo os dois lados.
- Escova, 100%: escovada forte com duas ondas de espuma em área, explosão de água pixelada, bolhinhas e tremor breve da câmera.
- Bolhas, 50%: uma bolha gigante que explode e causa 140 de dano em área.
- Bolhas, 100%: jato contínuo de água e sabão por três segundos após 0,25 s de preparação, com bolhas viajando no fluxo. Causa 30 de dano a cada 0,15 s (até 600 no alvo exposto ao jato inteiro), para nas paredes e não atinge aliados.

A IA não ativa especiais automaticamente. Pausas congelam efeitos, duração e dano. A HUD permanece fixa durante o tremor da escova.

O robô dourado à direita do posto de equipamentos é um alvo de treino permanente. Recebe socos, escovadas, bolhas e especiais, mostra o dano acumulado e não é destruído nem gera peças ou progresso do tutorial. Aproxime-se e pressione E/U para alternar a carga do personagem entre 100% e 50%, zerando o contador de dano. A interação fica indisponível durante um especial ativo.

Verificação: `Godot --headless --path . --script res://tools/verify_specials_training.gd`. Prévia: `Godot --path . --script res://tools/capture_specials_training.gd`, seguida de `python tools/export_specials_preview.py`. GIF: `art/previews/specials_training.gif`. Assets e prompts: `docs/specials-training-art.md`.


## Caminhada armada e ataque segurado

Novos sprites completos para cada microavatar segurando as duas armas. Idle de oito passos e caminhada com seis desenhos distintos, espelhados para a esquerda. A cadência normal da arma de bolhas foi reduzida pela metade (intervalo de 0,28 s). Segurar F/J repete a sequência de três escovadas.

Detalhes, arquivos e prompts: `docs/armed-movement-art.md`. Teste: `Godot --headless --path . --script res://tools/verify_armed_movement.gd`. Prévia: `Godot --path . --script res://tools/capture_armed_movement.gd` e `python tools/export_armed_preview.py`; GIF em `art/previews/armed_movement.gif`.


## Efeitos de água e sabão

A bolha gigante passou para meia barra. A barra cheia da arma agora produz um jato animado de água e sabão por três segundos. O impacto de barra cheia da escova ganhou seis quadros de água/espuma, bolhas e tremor curto. Os efeitos são renderizados numa grade de pixels ampliada 2×.

Verificação: `Godot --headless --path . --script res://tools/verify_water_specials.gd`. Prévia atual: `art/previews/water_specials.gif`. Assets, implementação e prompts: `docs/water-specials-art.md`.
