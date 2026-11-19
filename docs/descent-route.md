# Busca do sabonete e descida à Colmeia

A gosma antes do Guardião ocupa agora 296 × 230 pixels (antes 236 × 188). Ao chegar perto dela, depois da leva mista, Amanda diz: “Não podemos passar por aqui. Rápido, deve ter um sabonete por algum lugar!”. Um dos armários em x=2910, 3060 ou 3180 é sorteado ao iniciar a fase. Somente ele ganha o contorno amarelo após o aviso. O jogador precisa voltar de 130 a 400 pixels, pegar o sabonete com E/U e retornar à gosma. A limpeza conserva as bolhas, a espuma e a remoção gradual da colisão.

Após derrotar o Guardião, o corredor continua até x=5680. O elevador em x=5420 usa uma nova arte de cabine quebrada e contaminada. Ao se aproximar, Max diz: “Vamos consertar esse elevador e salvar o Tibúrcio!”.

Segurar E/U perto da lateral esquerda conserta o elevador em 3,2 segundos. O conserto reserva oito peças ao começar e retoma do mesmo ponto após uma interrupção. Equipamento, energia, poções, peças e vida dos sobreviventes são preservados nas trocas de fase. Quem caiu volta com a vida cheia. Três caixas no corredor final rendem três peças cada, garantindo uma fonte suficiente mesmo sem peças anteriores. O conserto exibe faíscas, progresso e chapas de reparo. Depois, as portas abrem e cada sobrevivente ocupa uma marca. Se alguém caiu, uma única marca basta para o embarque. As portas se fecham antes da transição. A IA utiliza a mesma entrada pela frente do elevador.

## Descida

`scenes/gameplay/shaft_descent.tscn` é uma arena jogável. A parede do poço e os trilhos contaminados sobem no fundo enquanto a plataforma permanece sob os personagens. O tempo de combate é de 40 segundos, além das breves transições de entrada e saída. F1 pausa o cronômetro e o combate; F2 recupera o estado de entrada e reinicia a descida.

Duplas de inimigos entram a cada 2,6 segundos, após 1,8 segundo inicial, até os últimos 2,5 segundos. A sequência contém quatro vermelhas, três voadoras amarelas e uma verde a cada oito spawns. O limite simultâneo é oito. Vermelhas e verdes caem na plataforma antes de atacar; amarelas conservam o combate aéreo, a derrubada e os dez segundos de voo baixo. As paredes físicas mantêm todos na plataforma, inclusive ao receber recuo.

Aos 40 segundos, o elevador chega, o combate encerra e uma transição leva a `scenes/gameplay/hive_stage.tscn`. A Colmeia agora continua por 3480 pixels, com bolsas animadas, pingos, quatro buracos e oito gêiseres, descritos em `docs/hive-chapters.md`. O menu principal e o seletor de depuração incluem todos os capítulos implementados.

## Verificação

- `tools/verify_descent_route.gd`: 34 verificações de busca, conserto, gasto único, estoque, embarque, falas, pausa, 40 segundos e trocas reais entre cenas.
- `tools/verify_shaft_combat.gd`: simulação de combate real de toda a descida, com IA eliminando inimigos, limite de oito, barreiras, encerramento, F2 e dupla derrotada.
- Regressões: final do laboratório, voadoras, barreiras, elevador/carregamento, navegação de fases e combate de bactérias.
- `tools/capture_descent_route.gd` captura os estados dentro do Godot; `tools/export_descent_preview.py` apenas codifica os quadros capturados em GIF.

Prévia: `art/previews/journey_descent.gif`. As artes e os prompts estão em `docs/descent-art-prompts.md`.
