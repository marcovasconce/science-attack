# Bancada — revisão para crianças de 8 a 10 anos

Orientação do projeto: linguagem simples, menos desafios de lógica em sequência, dicas visuais e ação contínua durante as falas de Tibúrcio. A montagem e os canos são os dois momentos principais de lógica. O percurso de 7200 pixels, os combates e a exploração foram mantidos.

## Percurso atual

1. **Chegada:** sair do elevador, pular os materiais de escrita e vencer os dois grupos iniciais.
2. **Montagem:** quebrar as caixas para liberar as nove peças da máquina, manter a interação no ponto de montagem e puxar a alavanca após o último encaixe. A montagem separa as peças ao começar e retoma do mesmo ponto se o jogador soltar. A energia abre o caminho até os canos.
3. **Água:** girar três peças independentes. A água preenche cada trecho conectado, para onde a ligação está errada e enche o tanque quando chega ao fim. Só então a poça some e a passagem abre.
4. **Vapor e combate:** observar a luz de aviso, esperar ou pular os jatos e enfrentar duas emboscadas. Vencer o último grupo abre a porta automaticamente.
5. **Depósito:** trecho livre para andar e encontrar ajuda. As prateleiras não pedem códigos; as baterias são bônus opcionais, sem busca obrigatória ou retorno pelo caminho.
6. **Máquina de limpeza:** apertar o botão uma vez. A máquina trabalha sozinha, enquanto a dupla fica livre para combater três grupos de germes. Cada grupo corresponde a um trecho da barra de progresso.
7. **Frasco e descida:** aproximar-se do frasco azul para guardá-lo libera o elevador da bancada. Tibúrcio pede que a dupla desça para encontrá-lo. Cada sobrevivente ocupa uma marca para iniciar a descida. Amanda embarca automaticamente quando controlada pela IA. Depois do carregamento, `lower_lab_stage.tscn` recebe a dupla e seus recursos. O elevador do tutorial continua subindo para a bancada.

Saíram da progressão obrigatória o puzzle das placas de pressão, a combinação dos frascos, os fusíveis e os medidores de pressão acoplados. Seus antigos espaços viraram cenário ou exploração. As marcas do elevador servem apenas para embarcar, como no tutorial. Não há instruções escondidas para as mecânicas removidas.

## Rádio e interface

- Seis falas automáticas no percurso: chegada, montagem, canos, vapor, defesa e saída. A caixa mede 308 × 78, mantendo a fonte de corpo em 15 e a frase inteira visível.
- Cada fala dura entre 9 e 15 segundos, com pelo menos 12 segundos de silêncio entre elas. Movimento, ataques, saltos, montagem, interação, água e inimigos continuam funcionando.
- O rádio não consome E/U nem pede confirmação. A ajuda aberta com F1 pausa também o tempo de leitura.
- Dicas que ficaram na fila e já perderam o contexto são descartadas antes de aparecer. A frase em exibição conserva seu tempo de leitura.
- As falas tratam da história e de ações simples: água, rodas, poça, luz, germes, frasco e reencontro com Tibúrcio no setor inferior. Não explicam modo solo, teclas ou regras numéricas.
- Os painéis de vida ficam à esquerda do rádio, também quando Amanda é controlada pelo P2.
- Só há uma dica de interação próxima: `E Girar`, `U Ligar`, `E Abrir`, `E Puxar` ou `Segure E para montar`, conforme quem está perto e o que pode fazer. Nada de etiquetas `E / U` espalhadas pela bancada.
- Baterias, frascos de energia e frasco limpo são recolhidos ao aproximar-se. Os antigos monitores de pistas viraram frascos reconhecíveis, somem ao coletar e mostram “+ Energia”, sem fala extra. Caixas com cruz são quebradas pelos ataques: o item fica oculto na caixa intacta, salta na quebra e só pode ser coletado depois de cair. A caixa se divide em quatro fragmentos com a textura existente; a recompensa continua única. O depósito não mantém a antiga sequência de cores, miniaturas de padrão ou terminal falso.

## Água que realmente percorre os canos

As duas curvas de cima são fixas. Cada uma das três rodas gira apenas a peça imediatamente acima dela. O primeiro e o terceiro controles giram curvas; o controle central gira um cano reto. A água serve como pista da conexão atual, sem números, letras ou sequência de cores para decorar.

`tabletop_route.gd` usa as mesmas coordenadas para portas, conexões, desenho do cano e percurso da água. Há onze trechos alternando conexões e interiores de peças. Um trecho recebe água depois que o anterior enche e a rotação termina de alinhar. Uma peça que recebe água mas aponta para o lado errado pode encher, porém não alimenta a seguinte.

Desconectar uma peça esvazia os trechos seguintes. A água avança com frente visível e bolhas dentro da textura dos canos. O shader `tabletop_water_tank.gdshader` enche o tanque receptor de baixo para cima. A solução só é aceita quando a água realmente chega e enche esse tanque. As peças ficam travadas depois da conclusão para evitar desfazer o objetivo sem querer.

## Retomada e testes

F2 retorna ao último checkpoint da sessão. A chegada, as armas, os recursos e os objetivos concluídos são restaurados. Checkpoints antigos das placas ou dos filtros são convertidos para a progressão atual, sem deixar a dupla presa num objetivo removido. A ajuda continua em F1 e a entrada/saída do segundo jogador em Enter.

O menu de debug oferece seis atalhos: **Canos e água**, **Passagem do vapor**, **Depósito**, **Máquina de limpeza**, **Frasco limpo** e **Descida ao laboratório**. F6 percorre introdução, tutorial, fase 1 (bancada) e fase 2 (setor inferior).

Verificações realizadas:

- `verify_tabletop_route.gd`: 128 verificações, incluindo entrada real durante o rádio, legibilidade/tempo, preenchimento progressivo, conexão física entre trechos, desconexão, pausa de ajuda, interface com P2, progressão sem puzzles removidos, máquina automática, migração de checkpoints, F2 real, embarque da IA, marcas distintas, bloqueio durante salto/ajuda, descida dos passageiros e carregamento real do setor inferior.
- `verify_elevator.gd`: regressão do elevador do tutorial, incluindo liberação, colisões, embarque, ajuda, IA, subida e transição.
- `verify_tabletop_stage.gd`: chegada, inventário, montagem, reserva de peças, alavanca, luzes, engrenagens, colisões e reinício.
- `verify_debug_phases.gd`: seis setores, troca direta e limpeza de checkpoints antigos.
- `verify_elevator_loading.gd`: carregamento e transferência de inventário aprovados; permanece o aviso de quatro instâncias RefCounted no ObjectDB ao encerrar esse teste.
- `capture_tabletop_route.gd`: capturas reais dos tubos secos, preenchimento parcial, bloqueio, tanque cheio, exploração, defesa, dois jogadores e elevador de saída, incluindo embarque, descida, carregamento e chegada ao setor inferior. O vídeo `art/previews/kids_water_flow.mp4` registra o preenchimento em movimento antes dos ajustes mais recentes dos suportes.

A meta anterior de 15–20 minutos precisa ser medida novamente com esta versão e com jogadores. Não compensar os puzzles retirados com esperas, texto extra ou carga segurada sem ação.

Os equipamentos reutilizam as texturas cartoon do projeto. A cena `scenes/environment/tabletop_route.tscn` é gerada por `tools/author_tabletop_route.py`; incorporar ajustes no gerador antes de regenerá-la, para preservar mudanças manuais.

A barra da máquina fica em um nó próprio, acima dos tanques e com z_index 8, independente da camada dos canos. As capturas atuais mostram a barra desobstruída, o rádio compacto e as caixas abertas.

Os tanques da bomba têm pedestais metálicos e conexões laterais que entram no vidro. Os tanques da máquina de limpeza apoiam a base na plataforma, com pés. As barreiras descem verticalmente dentro de um recorte fixo, sem movimento lateral ou fade, e mantêm a colisão até recolherem quase totalmente. A validação inclui quebra por golpe real, lançamento/coleta do item e movimento vertical da barreira.
