# Colmeia, trilhos e capítulos

O jogo inicia em `scenes/main_menu.tscn`, com Jogar, Capítulos, Opções, Sair e a opção Jogar em dupla. A composição usa camadas separadas e reaproveita a animação dos avatares, germes e tubos do jogo. Tibúrcio fica entre Max e Amanda no menu. Clicar nesses elementos aciona uma reação no laboratório. Opções salva tela cheia e animações reduzidas no perfil local. Capítulos aceita mouse, setas, Enter e Esc para voltar. Enter alterna o controle da Amanda em jogo, e F2 mantém a escolha ao reiniciar. F8 mostra ou esconde os atalhos nas compilações de debug.

O jogo renderiza o canvas na resolução da janela, mantém o layout lógico de 640×360 e preserva a proporção 16:9. A janela comum ajusta sua área de jogo para um tamanho 16:9. A opção Tela cheia usa 1920×1080 em monitores Full HD. O tremor da câmera respeita a área pintada das fases. O tema padrão usa Press Start 2P. Os sprites de personagem mantêm filtro nearest. As molduras do menu, HUD, diálogos e telas de equipamento e resultado usam o Pixel UI Pack da Kenney. O suporte dos tubos usa peças do laboratório de Ansimuz. Créditos e licenças estão em `assets/third_party/`.

O nó global `SceneFx` aplica íris no botão Jogar, pixelização no fim da abertura e cortinas direcionais nas viagens de elevador. Os efeitos de elevador acompanham o progresso das animações e do carregamento existentes. Com animações reduzidas, a transição usa um escurecimento suave. Os três shaders vieram do [Saltmire Transitions](https://github.com/saltmire/saltmire-transitions). A licença MIT está em `assets/third_party/saltmire/LICENSE.txt`.

O catálogo compartilhado em `scripts/chapter_catalog.gd` alimenta tanto o menu quanto ESCOLHER FASE: introdução, tutorial, bancada e seus seis setores, chegada ao setor inferior, enxame, quebra-cabeça, emboscada da porta, sabonete, Guardião do Rei, conserto, descida de 40 segundos, chegada à Colmeia e oficina da Colmeia. Atalhos restauram apenas os pré-requisitos e continuam no mesmo trecho ao reiniciar com F2; escolher outra fase limpa o atalho anterior. O atalho de conserto mantém as três caixas de peças disponíveis.

O elevador consertado fecha as portas por 0,9 s antes de mover a cabine, portas, placas de reparo e jogadores juntos. O poço e os trilhos ficam fixos, preenchidos até abaixo da cabine. A câmera acompanha parte da descida antes da transição para a batalha no elevador.

A Colmeia ocupa 4044 pixels, entre a metade e três quartos da extensão das fases anteriores. A cabine abre para a oficina com o puzzle de dois trampolins. Depois das primeiras ondas vêm a galeria dos drenos, a estação de pressão, o túnel de exaustão e o dique. Gêiseres usam o atlas original e sinalizam a erupção no piso. Na estação de pressão, a bomba aciona três ralos em sequência e alterna as faixas da arena. O sentido da sequência se inverte na segunda onda e a comporta abre quando os germes acabam. Os voadores de passagem podem ser atingidos ou esquivados. As bactérias amarelas mergulham depois de alguns segundos, abrindo oportunidade para golpes do chão.

O Rei Bactéria tem 10000 PV e prende Tibúrcio numa cápsula. Círculo laranja anuncia o salto, círculo azul marca o redemoinho e a bolha dourada cresce antes do disparo. A bolha pode ser rebatida para interromper o Rei. A partir de 5300 PV, o Rei muda de cor, chama reforços, anuncia dois pontos de impacto para o salto duplo e dispara três ralos em sequência. A dupla usa o frasco da Bancada para concluir a captura. F2 recomeça na arena com as armas conquistadas.

A câmera aproxima de formas diferentes no disparo da Bolha Nova e nas três batidas da Escova Solar. O zoom de impacto respeita a opção de movimento reduzido.

O som usa nove faixas diferentes, incluindo menu, capítulos, luta e final. Música e efeitos têm ajustes independentes em Opções. A água ambiente só toca no esgoto. O autoload GameAudio distribui os sons por prioridade e limita o pico da saída. Arte e áudio da Colmeia estão creditados em `assets/third_party/CREDITS.md`.

`tools/verify_hive_chapters.gd` verifica a cabine e os ciclos dos ralos. `tools/verify_hive_navigation.gd` cobre puzzle, ondas, fases do Rei e captura com o frasco.
