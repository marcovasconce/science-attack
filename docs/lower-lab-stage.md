# Fase 2 — setor inferior

A saída da bancada desce e carrega `scenes/gameplay/lower_lab_stage.tscn`. A fala final de Tibúrcio é “Frasco guardado! Desçam pelo elevador e me encontrem lá embaixo!”. A transição conserva equipamento, vida máxima e atual, energia, frascos e modo solo/cooperativo. F2 restaura os recursos que a dupla tinha ao entrar no setor inferior.

O ambiente reutiliza os painéis e o piso do tutorial, com um shader verde aplicado somente ao cenário. A gosma do elevador fica acima da arte da cabine e abaixo dos personagens (z efetivo -1). As placas de setor, o aviso de saída e os textos de objetivo desse trecho foram removidos. Depois de caminhar até x=510, a câmera apresenta o Rei Bactéria com Tibúrcio de olho fechado, caído no antebraço. Os dois são uma única sprite de seis quadros, a 7,5 quadros por segundo. Os desenhos animam a boca, a gosma alongando, a gota se soltando e caindo. Não há mais um avatar independente sobreposto ao rei.

Fala: “Tarde demais! Logo, logo esse laboratório já era! Ninguém poderá me deter!”. E/U revela ou avança a fala; sem interação, ela avança após 7,5 segundos. O rei acelera para a direita com Tibúrcio. Só depois de sair da câmera, o emblema vermelho sem caixa de fundo, no canto inferior direito, pisca cinco vezes durante um segundo de jogo. F1 pausa também esse intervalo.

A primeira onda contém 48 voadoras, em intervalos de 0,12 segundo. Quando todas forem derrotadas ou saírem da tela, o alerta pisca por mais um segundo; a segunda onda traz 80 voadoras, em intervalos de 0,08 segundo. Elas entram pela direita e atravessam os jogadores sem parar ou voltar. Algumas faixas de voo miram a profundidade atual da dupla ao nascer; a trajetória depois permanece fixa. Cada contato causa 6 pontos, no máximo uma vez por voadora para cada jogador, respeitando a invulnerabilidade e o salto existentes. A verificação usa o segmento inteiro do movimento para não perder colisões em alta velocidade. Cada inimiga tem 1 ponto de vida. As que passam saem da cena sem contar como derrotadas, mas liberam a progressão da onda. A sequência termina após as duas ondas, totalizando 128 voadoras.

A IA escolhe apenas voadoras à frente que ainda não passaram por ela. Cada voadora registra os jogadores ultrapassados para não voltar a ser alvo caso o companheiro recue. A IA mantém sua posição perto do jogador humano e intercepta as faixas de voo, sem perseguir o enxame para trás.

## Corredor e terminal

Depois das duas ondas, o limite de avanço passa de x=1040 para x=3140. O corredor tem armários danificados, placas de risco biológico e computadores desligados com chamas e fumaça pixeladas animadas. Cinco poças de líquido amarelo-esverdeado, com frascos quebrados, bolhas e vapor animados, causam 8 pontos de dano por segundo de contato. Saltar, desviar e andar pelas faixas livres evitam o dano. A IA contorna as poças nos dois sentidos. As poças e efeitos param durante telas modais.

A porta em x=2640 bloqueia toda a profundidade caminhável. Aproxime-se do computador em x=2440 e pressione E (P1) ou U (P2 humano). A câmera aproxima em 0,6 segundo, a inicialização do terminal dura 1,4 segundo e então aparece o quebra-cabeça 3×3 com a **sprite original** `Dude_Monster_Idle_4.png`, primeiro quadro. Não é uma imagem gerada do Tibúrcio: as nove peças recortam a textura original em tempo de desenho.

A porta agora é vista **de perfil**: uma faixa mecânica estreita de 32 pixels de largura, com colisão de 18 pixels, e a parte central recolhe para cima. O fogo dos computadores foi substituído por uma sprite de doze quadros, animada a 12 FPS, baseada na referência de chamas enviada pelo usuário. O vapor das poças e a fumaça dos equipamentos permanecem separados.

Clique em duas peças para trocar suas posições, ou navegue com WASD/setas e confirme com E/U, Enter ou Espaço. O retrato de referência fica ao lado. Esc ou X fecha o terminal, preservando as trocas; a câmera e os controles voltam ao normal. A IA não ativa o computador sozinha. A solução mostra “ACESSO LIBERADO!”, retorna a câmera e recolhe a porta para cima; a colisão é removida somente quando a porta termina de abrir. A passagem permanece liberada. F2 reinicia a fase inteira com o inventário da chegada, incluindo ondas, poças, puzzle e porta. Após a leva mista, o caminho continua pela limpeza com sabão e pela batalha do guardião, descritas abaixo.

## Combate após a porta

Quando a abertura física termina, começa uma leva de **6 bactérias verdes, 3 vermelhas e 3 voadoras amarelas**, em intervalos de 0,6 segundo. O gatilho ocorre uma única vez. As verdes têm 130 de vida, as amarelas **195** e as vermelhas 260. As voadoras verdes dos dois enxames iniciais continuam com um ponto de vida e seguem atravessando a tela.

As amarelas flutuam alto, cospem bolas de gosma turquesa pixeladas após uma preparação de 0,48 segundo e procuram manter distância. Os projéteis miram a posição do jogador no disparo, descem da altura da boca, causam 10 de dano, estouram no primeiro contato e respeitam paredes, profundidade, invulnerabilidade e pausa. É possível evitar o disparo saindo da faixa de voo.

Para atingir uma amarela no alto, é preciso **pular e atacar**. A verificação considera a altura real do golpe ou da bolha; disparos feitos no chão passam por baixo mesmo que o jogador pule depois, enquanto bolhas disparadas no salto mantêm a altura se o jogador aterrissar. Golpes, especiais de área e jatos também respeitam essa regra. A IA pula para atacar esse tipo de alvo.

Um acerto válido no alto provoca uma queda com giro, impacto achatado e pequenas partículas no piso. Após 0,35 segundo no chão, ela volta a voar baixo por **dez segundos completos**, recebendo ataques normais sem salto. Novos acertos não renovam o temporizador. Se sobreviver, sobe novamente em 0,65 segundo; outro acerto no alto pode derrubá-la de novo. A pausa congela todos esses tempos. Derrotar o grupo libera a continuação e elimina os projéteis hostis remanescentes. A IA persegue normalmente os inimigos desse combate, mantendo a restrição de ignorar inimigas ultrapassadas apenas para o enxame inicial.

## Caixas, dicas e bloqueios

Nove caixas ocupam posições sorteadas entre doze pontos seguros, com variação pequena de posição. Cada caixa faz uma única rolagem independente: valores abaixo de 0,5 soltam um frasco de cura; valores maiores ou iguais não soltam nada. Caminhar sobre o frasco adiciona uma unidade ao inventário do personagem. As caixas desta fase não fornecem peças de construção. O sprite e a animação de quebra já existentes foram reaproveitados.

O poço tem painéis, travessas, cabos e trilhos fixos que continuam aparecendo quando a cabine desce. A chegada da fase 2 também mantém os trilhos aparentes. A gosma continua atrás dos personagens. Durante os enxames, uma parede física invisível em x=1056 impede avanço por salto ou esquiva; ela some somente após as duas ondas. Uma segunda barreira em x=3155 segura o trecho seguinte enquanto a leva mista estiver viva.

O puzzle ainda é 3×3, agora com uma permutação aleatória em ciclo único: nenhuma peça começa correta e são necessárias pelo menos oito trocas. Fechar e reabrir conserva o progresso. A primeira voadora amarela aciona a mensagem não bloqueante da Dra. Amanda no alto à direita por 4,5 segundos: “Voadores! Vamos derrubá-los!”.

## Sabão e contaminação

Após a leva mista, chegar à contaminação aciona a fala da Amanda e destaca um armário sorteado entre x=2910, 3060 e 3180. É preciso voltar para buscar o sabonete com E/U. O sabão é compartilhado pela dupla. A gosma em x=3440 tem 296 × 230 pixels e bloqueia toda a profundidade, inclusive saltos. Com sabão, E/U inicia três segundos de esfregação, bolhas e espuma; a colisão só desaparece ao terminar. O armário não repõe o item. O corredor agora continua até x=5680 para acomodar o elevador após o chefe. Veja `docs/descent-route.md` para a busca, o conserto e a descida à Colmeia.

## Guardião do Rei

Passar de x=4040 depois da limpeza inicia um tremor curto. A dupla entra na arena x=3940–4740, a câmera se fixa no centro e duas paredes sólidas invisíveis fecham o combate. Pilares e faixas no piso indicam exatamente esses limites. O parceiro atrasado ou caído também entra, preservando a possibilidade de reanimação.

O mini boss é um germe verde escuro com escudo orgânico, uma animação de idle com quatro quadros e a fala “eu irei proteger o REI!!!”. Após a fala (2,6 segundos ou E/U), ele já prepara a primeira investida. A preparação marca uma faixa no chão, fixa o rumo e depois atravessa até a parede oposta a 520 pixels/s. Durante o movimento, rastros de tons verdes acompanham o corpo. O impacto causa tremor de 0,28 segundo, animação de choque e recuperação. A IA sai da faixa da investida e evita TNT próxima. O golpe curto de escudo só acontece depois que um jogador permanece por 1,5 segundo contínuo junto à frente do chefe (80 pixels horizontais e 32 na profundidade). Sair de perto zera o tempo; golpes à distância não o acionam. Há 0,36 segundo de preparação antes do contato: ele causa apenas 6 de dano e empurra cerca de 100 pixels, parando nas paredes. O intervalo mínimo é de 3,5 segundos. Saltar ou sair do alcance evita o golpe. Quatro poses próprias mostram preparação, avanço do escudo, arco de impacto e retorno, sem quadrado verde.

Somente 25% das investidas que batem na parede chamam uma chuva de três TNTs, em regiões aleatórias separadas da arena. As marcas de pouso aparecem antes da queda. Depois de pousar, uma TNT só explode se um jogador acertá-la ou se o próprio chefe a atingir durante a investida; caminhar sobre ela não a detona. Cada explosão causa 14 de dano ao jogador próximo e 320 ao chefe próximo, mesmo contra o escudo. Não há novas quedas depois da vitória.

A barra no alto central mostra o retrato e duas camadas de 650 de vida: a laranja cobre a vermelha e a vazia aparece conforme ambas se esgotam. O HUD da dupla desce durante a luta para não cobrir a barra. O golpe da investida causa 23 de dano. Ao ser derrotado, o chefe passa por quatro desenhos de queda, fica deitado com os olhos fechados, pisca e desaparece em 3 segundos; as paredes abrem, TNTs restantes desaparecem e o HUD volta ao lugar. F1 pausa o combate e as quedas; F2 reinicia toda a sequência com o inventário da chegada.

As barreiras invisíveis bloqueiam jogadores e voadores. As amarelas respeitam a camada 5 tanto no voo normal e baixo quanto no recuo da queda, usando movimento com colisão. As verdes do enxame também respeitam as barreiras e nascem dentro da área acessível, sem precisar atravessá-las. Tiros e raios continuam usando a camada do cenário.

Código principal da extensão: `scripts/lower_lab_finale.gd`, `shield_germ.gd`, `falling_tnt.gd`, `shield_boss_hud.gd`, `lower_lab_supply.gd` e `lower_lab_healing_pickup.gd`. Capturas verificadas: `art/previews/shield_wide_arena.png`, `shield_charge_trail.png`, `shield_block_impact.png`, `shield_explosion.png`, `shield_death_prone.png`, `shield_death_blink.png`, `shield_orange_over_red.png` e `shield_red_over_empty.png`; limpeza: `art/previews/lower_lab_soap_cleaning.gif`.

## Arte

Gerada com a ferramenta imagegen integrada, usando as referências fornecidas e a bactéria verde existente. Não foi usada API/CLI externa. Originais com transparência preservados em `art/source/lower_lab/`; recursos usados pelo jogo:

- `assets/enemies/king_captive_animated_v3.png`: atlas 3 × 2, com seis desenhos integrados do rei com o prisioneiro. Tibúrcio preserva a pálpebra clara do olho único, o contorno azul, a pequena franja e o lenço vermelho. Fonte em `art/source/lower_lab/king_captive_animated_v3.png`.
- `assets/enemies/flying_bacteria.png`: quatro poses de asas, mesma bactéria verde com língua de fora.
- `assets/environment/elevator_slime.png`: gosma grudada à cabine.
- `scripts/wave_warning.gd`: emblema de perigo desenhado na grade de pixels, como a interface existente.
- `assets/environment/lower_lab/`: seis recursos do atlas de decoração, porta e terminal. Fonte e prompts em `docs/lower-lab-corridor-art.md`; extração de células em `tools/prepare_corridor_art.gd`.
- Revisão de combate: `assets/environment/lower_lab/door_side.png` e `fire_animated.png`; `assets/enemies/yellow_flying_bacteria.png` e `slime_ball.png`. Fontes e prompts em `docs/lower-lab-combat-art.md`, importador `tools/prepare_lower_lab_combat_art.gd`. A porta frontal anterior fica preservada como referência, mas não é usada pela fase.

`tools/prepare_king_captive.gd` normaliza as seis células para 112 × 112, usando nearest-neighbor e alinhando a coroa para evitar saltos laterais entre quadros. O alpha gerado é preservado. O rei aparece em 2×; as voadoras em 1,5× com filtro nearest. `tools/prepare_lower_lab_art.gd` continua importando as voadoras, a gosma e a versão antiga do rei, preservada como referência. Prompts da revisão em `docs/king-captive-v2-prompts.md`; prompts anteriores em `docs/lower-lab-art-prompts.md`.

## Validação

Na extensão do guardião passaram `tools/verify_lower_lab_finale.gd` (60 verificações), as 80 verificações da fase, as 38 das voadoras amarelas e as 128 da bancada, além dos testes de elevador, carregamento e caixas existentes. Os testes novos exercitam a fronteira exata dos 50%, coleta única, posições aleatórias, puzzle mais difícil, colisões reais durante saltos, sequência de sabão, pausa, ataque inicial, colisão varrida da investida, três quedas por impacto, explosão única, duas camadas de vida, IA desviando e limpeza da arena após vitória. `tools/capture_lower_lab_finale.gd` renderiza as novas telas e sequências; `tools/export_lower_lab_finale_preview.py` apenas codifica os quadros em GIF.

Godot 4.7.2: nesta revisão passaram `tools/verify_lower_lab.gd` (80 verificações), `tools/verify_yellow_flyers.gd` (38 verificações), `tools/verify_equipment_combat.gd` e `tools/verify_water_specials.gd`. Cobrem inventário, sprite integrada, boca/gosma animadas, alpha, ordenação da gosma, dois alertas, 48 + 80 inimigos, contato por passagem, armas, IA focando à frente, desvio das poças nos dois sentidos, dano e cooldown, porta bloqueando três profundidades, E/U, inicialização, mouse/teclado, puzzle, abertura física e F2 real. As 38 novas verificações incluem a composição da leva, disparo único após abertura, vida intermediária, ataques e projéteis em alturas diferentes, queda, impacto, dez segundos de voo baixo, recuperação, dano de gosma, pausa, IA pulando, encerramento e doze quadros do fogo. O ambiente emite um aviso de certificados do sistema. Na revisão anterior também passaram as 128 verificações da bancada e a navegação de debug.

`tools/capture_lower_lab.gd` gera capturas renderizadas da chegada, sobreposição corrigida, rapto, fala, dois alertas e duas ondas em `art/previews/lower_lab_*.png`. Com `-- --sequence`, também salva 72 quadros renderizados, codificados por `tools/export_lower_lab_preview.py` em `art/previews/king_captive_animated.gif`. Para entrar diretamente, use **ESCOLHER FASE → Fase 2: setor inferior** no debug, ou abra a cena no Godot.

`tools/capture_lower_lab_corridor.gd` captura decoração, poças, porta, zoom, boot, puzzle e solução. Com `-- --sequence`, salva os quadros das chamas e do vapor; o mesmo exportador cria `art/previews/lower_lab_corridor_animated.gif`. As prévias foram verificadas visualmente em renderização real do Godot.

`tools/capture_yellow_flyers.gd` captura a porta de perfil fechada/abrindo/aberta, a leva mista, disparos de gosma, golpe aéreo, queda, impacto e voo baixo. Execute com `--fixed-fps 60` para manter as capturas de física sincronizadas. O exportador gera `art/previews/yellow_flyer_knockdown.gif` a partir dos 120 quadros renderizados.

Revisão de colisão e poses: `tools/verify_flyer_barriers.gd` cobre as duas direções, voo alto/baixo, queda, liberação e spawn do enxame; `tools/verify_shield_proximity.gd` cobre proximidade contínua, afastamento, dano baixo, salto, recuo nas paredes e derrota. A captura atual é `art/previews/shield_polish.gif`, gerada pelo Godot.
