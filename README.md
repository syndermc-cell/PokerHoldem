# Poker Hold'em V5 — Flutter

Atualização completa multiplataforma.

Inclui:
- Mesa visual de cassino em feltro
- Assentos de 2 a 8 jogadores
- Dealer, Small Blind e Big Blind
- Pote e fichas visuais
- Mesa com 5 cartas e 2 cartas por jogador
- Baralho visual de 52 cartas
- Bloqueio de cartas repetidas
- Avaliador completo de Texas Hold'em
- Royal Flush, Straight Flush, Quadra, Full House, Flush, Sequência, Trinca, Dois Pares, Par e Carta Alta
- Desempate por kickers
- Resultado individual de todos os jogadores
- Histórico das últimas 12 mãos
- Botão Próxima Mão que move o Dealer
- Funcionamento offline e sem servidor

## Reta final

Android:
  flutter pub get
  flutter build apk --release

iPhone:
  flutter pub get
  flutter build ios --release
  ou abra ios/Runner.xcworkspace no Xcode para assinatura e distribuição.

Para criar o projeto iOS/Android completo a partir desta fonte, use `flutter create .` dentro desta pasta antes do build.
