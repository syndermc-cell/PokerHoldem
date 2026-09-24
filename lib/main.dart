import 'package:flutter/material.dart';

void main() => runApp(const PokerApp());

class CardData {
  final String rank;
  final String suit;
  const CardData(this.rank, this.suit);

  String get label => '$rank$suit';
  bool get red => suit == '♥' || suit == '♦';
}

const ranks = ['2','3','4','5','6','7','8','9','10','J','Q','K','A'];
const suits = ['♠','♥','♦','♣'];

class PlayerHand {
  String? c1;
  String? c2;
  PlayerHand({this.c1, this.c2});
  List<String> get cards => [if (c1 != null) c1!, if (c2 != null) c2!];
}

class HandResult {
  final int player;
  final String name;
  final String hand;
  final List<String> cards;
  HandResult(this.player, this.name, this.hand, this.cards);
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Poker Hold'em Calculator",
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050708),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC229),
          brightness: Brightness.dark,
        ),
      ),
      home: const PokerHome(),
    );
  }
}

class PokerHome extends StatefulWidget {
  const PokerHome({super.key});

  @override
  State<PokerHome> createState() => _PokerHomeState();
}

class _PokerHomeState extends State<PokerHome> {
  int players = 2;
  final List<String?> board = List<String?>.filled(5, null);
  late List<PlayerHand> hands;
  List<HandResult> results = [];
  List<HandResult> history = [];
  bool calculated = false;

  @override
  void initState() {
    super.initState();
    hands = List.generate(8, (_) => PlayerHand());
  }

  List<String> usedCards({String? ignore}) {
    final all = <String>[];
    for (final c in board) {
      if (c != null && c != ignore) all.add(c);
    }
    for (int i = 0; i < players; i++) {
      for (final c in hands[i].cards) {
        if (c != ignore) all.add(c);
      }
    }
    return all;
  }

  Future<void> pickCard({
    required String title,
    required String? current,
    required ValueChanged<String> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF101417),
      isScrollControlled: true,
      builder: (_) => CardPicker(
        title: title,
        current: current,
        used: usedCards(ignore: current),
      ),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
        calculated = false;
      });
    }
  }

  void calculate() {
    if (board.any((c) => c == null)) {
      _message('Selecione as 5 cartas da mesa.');
      return;
    }
    for (int i = 0; i < players; i++) {
      if (hands[i].c1 == null || hands[i].c2 == null) {
        _message('Selecione as 2 cartas do Jogador ${i + 1}.');
        return;
      }
    }

    final seen = <String>{};
    final all = <String>[...board.whereType<String>()];
    for (int i = 0; i < players; i++) {
      all.addAll(hands[i].cards);
    }
    for (final c in all) {
      if (!seen.add(c)) {
        _message('Existe uma carta repetida: $c');
        return;
      }
    }

    final temp = <HandResult>[];
    for (int i = 0; i < players; i++) {
      final seven = [...board.whereType<String>(), ...hands[i].cards];
      final ev = evaluate7(seven);
      temp.add(HandResult(i + 1, 'Jogador ${i + 1}', ev.name, ev.bestCards));
    }

    temp.sort((a, b) {
      final ea = evaluate7([
        ...board.whereType<String>(),
        ...hands[a.player - 1].cards
      ]);
      final eb = evaluate7([
        ...board.whereType<String>(),
        ...hands[b.player - 1].cards
      ]);
      return compareScore(eb.score, ea.score);
    });

    setState(() {
      results = temp;
      calculated = true;
      history.insertAll(0, temp);
      if (history.length > 32) history = history.take(32).toList();
    });
  }

  void nextHand() {
    setState(() {
      for (final h in hands) {
        h.c1 = null;
        h.c2 = null;
      }
      for (int i = 0; i < 5; i++) {
        board[i] = null;
      }
      results = [];
      calculated = false;
    });
  }

  void clearAll() {
    nextHand();
    setState(() {
      history = [];
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF9B1C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030506),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _topBar(),
              _table(),
              _controls(),
              if (calculated) _resultsPanel(),
              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF050708),
            Color(0xFF15110A),
            Color(0xFF050708),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF7B5712)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: Color(0xFFFFC229),
            size: 42,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "POKER HOLD'EM",
                  style: TextStyle(
                    color: Color(0xFFFFD66B),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "CALCULATOR",
                  style: TextStyle(
                    color: Color(0xFFD8A83A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.wifi_off,
            color: Color(0xFFBDBDBD),
            size: 25,
          ),
          const SizedBox(width: 5),
          const Text(
            "OFFLINE",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 42,
            width: 1,
            color: const Color(0xFF5E471A),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.settings,
            color: Colors.white,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const RadialGradient(
          colors: [
            Color(0xFF08743E),
            Color(0xFF034C2B),
            Color(0xFF021D12),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8D641D),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _boardTitle(),
          const SizedBox(height: 12),
          _boardCards(),
          const SizedBox(height: 18),
          _playersGrid(),
        ],
      ),
    );
  }

  Widget _boardTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF031A10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF6E521B),
        ),
      ),
      child: const Column(
        children: [
          Text(
            "—  MESA  —",
            style: TextStyle(
              color: Color(0xFFFFD66B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            "5 CARTAS COMUNITÁRIAS",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardCards() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      children: List.generate(
        5,
        (i) => _cardButton(
          board[i],
          () => pickCard(
            title: "Carta da mesa ${i + 1}",
            current: board[i],
            onPicked: (c) => board[i] = c,
          ),
        ),
      ),
    );
  } Widget _playersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 700 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, i) {
            return _playerBox(i);
          },
        );
      },
    );
  }

  Widget _playerBox(int i) {
    final hand = hands[i];
    final result = results.where((r) => r.player == i + 1).firstOrNull;
    final winner = calculated && results.isNotEmpty && results.first.player == i + 1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: winner
            ? const Color(0xFF30230A)
            : const Color(0xDD06100D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner
              ? const Color(0xFFFFC229)
              : const Color(0xFF80601E),
          width: winner ? 2 : 1,
        ),
        boxShadow: winner
            ? const [
                BoxShadow(
                  color: Color(0x88FFC229),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF111820),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFFC229),
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Jogador ${i + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (winner)
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFC229),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniCard(
                  hand.c1,
                  () => pickCard(
                    title: "Jogador ${i + 1} — Carta 1",
                    current: hand.c1,
                    onPicked: (c) => hand.c1 = c,
                  ),
                ),
                const SizedBox(width: 5),
                _miniCard(
                  hand.c2,
                  () => pickCard(
                    title: "Jogador ${i + 1} — Carta 2",
                    current: hand.c2,
                    onPicked: (c) => hand.c2 = c,
                  ),
                ),
              ],
            ),
          ),
          if (result != null)
            Text(
              result.hand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: winner
                    ? const Color(0xFFFFD35C)
                    : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardButton(String? card, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 78,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: card == null
              ? const Color(0xFF10201A)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: card == null
                ? const Color(0xFFB38A35)
                : const Color(0xFFE5C77A),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: card == null
              ? const Icon(
                  Icons.add,
                  color: Color(0xFFFFC229),
                  size: 25,
                )
              : _cardText(card, 25),
        ),
      ),
    );
  }

  Widget _miniCard(String? card, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 55,
        decoration: BoxDecoration(
          color: card == null
              ? const Color(0xFF16252C)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: card == null
                ? const Color(0xFF6B7D82)
                : const Color(0xFFE2C77E),
          ),
        ),
        child: Center(
          child: card == null
              ? const Icon(
                  Icons.add,
                  color: Color(0xFFFFC229),
                  size: 20,
                )
              : _cardText(card, 19),
        ),
      ),
    );
  }

  Widget _cardText(String card, double size) {
    final red = card.endsWith('♥') || card.endsWith('♦');

    return Text(
      card,
      style: TextStyle(
        color: red ? Colors.red.shade700 : Colors.black87,
        fontSize: size,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _controls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF644A18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups,
                color: Color(0xFFFFC229),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "NÚMERO DE JOGADORES",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF171D20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8A651C),
                  ),
                ),
                child: DropdownButton<int>(
                  value: players,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF171D20),
                  iconEnabledColor: const Color(0xFFFFC229),
                  items: [
                    for (int n = 2; n <= 8; n++)
                      DropdownMenuItem(
                        value: n,
                        child: Text(
                          "$n jogadores",
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (n) {
                    if (n == null) return;
                    setState(() {
                      players = n;
                      results = [];
                      calculated = false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: calculate,
              icon: const Icon(
                Icons.calculate,
                size: 28,
              ),
              label: const Text(
                "CALCULAR VENCEDOR",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB916),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsPanel() {
    if (results.isEmpty) return const SizedBox();

    final winner = results.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF090C0D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFC229),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFC229),
                size: 34,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${winner.name.toUpperCase()} VENCEU!",
                  style: const TextStyle(
                    color: Color(0xFFFFD66B),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            winner.hand,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(
            color: Color(0xFF4E3C18),
            height: 22,
          ),
          const Text(
            "OUTROS RESULTADOS",
            style: TextStyle(
              color: Color(0xFFFFD66B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          ...results.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF111719),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Text(
                    r.player == winner.player ? "🏆" : "●",
                    style: TextStyle(
                      color: r.player == winner.player
                          ? const Color(0xFFFFC229)
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    r.hand,
                    style: TextStyle(
                      color: r.player == winner.player
                          ? const Color(0xFFFFD66B)
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: history.isEmpty
                  ? null
                  : () => _showHistory(),
              icon: const Icon(Icons.history),
              label: const Text("HISTÓRICO"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD66B),
                side: const BorderSide(
                  color: Color(0xFF76551B),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: clearAll,
              icon: const Icon(Icons.delete_outline),
              label: const Text("LIMPAR"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(
                  color: Color(0xFF555555),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: nextHand,
              icon: const Icon(Icons.refresh),
              label: const Text("PRÓXIMA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB916),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1012),
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "HISTÓRICO",
                style: TextStyle(
                  color: Color(0xFFFFC229),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...history.asMap().entries.map(
                (entry) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF252015),
                    child: Text(
                      "${entry.value.player}",
                      style: const TextStyle(
                        color: Color(0xFFFFC229),
                      ),
                    ),
                  ),
                  title: Text(entry.value.name),
                  subtitle: Text(entry.value.hand),
                  trailing: Text(
                    entry.value.cards.join(' '),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    
  }class CardPicker extends StatelessWidget {
  final String title;
  final String? current;
  final List<String> used;

  const CardPicker({
    super.key,
    required this.title,
    required this.current,
    required this.used,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.style,
                  color: Color(0xFFFFC229),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(color: Color(0xFF3E3E3E)),
            const SizedBox(height: 5),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 52,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final rank = ranks[index % 13];
                  final suit = suits[index ~/ 13];
                  final card = '$rank$suit';
                  final blocked =
                      used.contains(card) && card != current;
                  final red = suit == '♥' || suit == '♦';

                  return GestureDetector(
                    onTap: blocked
                        ? null
                        : () => Navigator.pop(context, card),
                    child: Container(
                      decoration: BoxDecoration(
                        color: blocked
                            ? const Color(0xFF25282A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: current == card
                              ? const Color(0xFFFFC229)
                              : const Color(0xFF777777),
                          width: current == card ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          blocked ? '×' : card,
                          style: TextStyle(
                            color: blocked
                                ? Colors.white24
                                : red
                                    ? Colors.red.shade700
                                    : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Evaluation {
  final int category;
  final List<int> score;
  final String name;
  final List<String> bestCards;

  Evaluation(
    this.category,
    this.score,
    this.name,
    this.bestCards,
  );
}

Evaluation evaluate7(List<String> cards) {
  final combinations = <List<String>>[];

  for (int a = 0; a < cards.length - 4; a++) {
    for (int b = a + 1; b < cards.length - 3; b++) {
      for (int c = b + 1; c < cards.length - 2; c++) {
        for (int d = c + 1; d < cards.length - 1; d++) {
          for (int e = d + 1; e < cards.length; e++) {
            combinations.add([
              cards[a],
              cards[b],
              cards[c],
              cards[d],
              cards[e],
            ]);
          }
        }
      }
    }
  }

  Evaluation? best;

  for (final combo in combinations) {
    final current = evaluate5(combo);

    if (best == null ||
        compareScore(current.score, best.score) > 0) {
      best = current;
    }
  }

  return best!;
}

Evaluation evaluate5(List<String> cards) {
  final values = cards.map(cardValue).toList();
  values.sort((a, b) => b.compareTo(a));

  final counts = <int, int>{};

  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }

  final groups = counts.entries.toList()
    ..sort((a, b) {
      if (a.value != b.value) {
        return b.value.compareTo(a.value);
      }
      return b.key.compareTo(a.key);
    });

  final flush = cards
      .map(cardSuit)
      .toSet()
      .length == 1;

  final unique = values.toSet().toList()
    ..sort((a, b) => b.compareTo(a));

  int? straightHigh;

  if (unique.length == 5) {
    if (unique.first - unique.last == 4) {
      straightHigh = unique.first;
    } else if (unique.join(',') == '14,5,4,3,2') {
      straightHigh = 5;
    }
  }

  // Straight Flush / Royal Flush
  if (flush && straightHigh != null) {
    if (straightHigh == 14) {
      return Evaluation(
        8,
        [14],
        'Royal Flush',
        cards,
      );
    }

    return Evaluation(
      8,
      [straightHigh],
      'Straight Flush',
      cards,
    );
  }

  // Quadra
  final four = groups.where((g) => g.value == 4).toList();

  if (four.isNotEmpty) {
    final quad = four.first.key;
    final kicker = values.where((v) => v != quad).first;

    return Evaluation(
      7,
      [quad, kicker],
      'Quadra de ${valueName(quad)}',
      cards,
    );
  }

  // Full House
  final trips = groups.where((g) => g.value == 3).toList();
  final pairs = groups.where((g) => g.value == 2).toList();

  if (trips.isNotEmpty &&
      (pairs.isNotEmpty || trips.length >= 2)) {
    final trip = trips.first.key;

    final second =
        pairs.isNotEmpty ? pairs.first.key : trips[1].key;

    return Evaluation(
      6,
      [trip, second],
      'Full House',
      cards,
    );
  }

  // Flush
  if (flush) {
    return Evaluation(
      5,
      values,
      'Flush',
      cards,
    );
  }

  // Straight
  if (straightHigh != null) {
    return Evaluation(
      4,
      [straightHigh],
      'Sequência',
      cards,
    );
  }

  // Trinca
  if (trips.isNotEmpty) {
    final trip = trips.first.key;
    final kickers =
        values.where((v) => v != trip).toList();

    return Evaluation(
      3,
      [trip, ...kickers],
      'Trinca de ${valueName(trip)}',
      cards,
    );
  }

  // Dois Pares
  if (pairs.length >= 2) {
    final highPair = pairs[0].key;
    final lowPair = pairs[1].key;
    final kicker =
        values.where((v) => v != highPair && v != lowPair).first;

    return Evaluation(
      2,
      [highPair, lowPair, kicker],
      'Dois Pares',
      cards,
    );
  }

  // Um Par
  if (pairs.length == 1) {
    final pair = pairs.first.key;
    final kickers =
        values.where((v) => v != pair).toList();

    return Evaluation(
      1,
      [pair, ...kickers],
      'Par de ${valueName(pair)}',
      cards,
    );
  }

  // Carta Alta
  return Evaluation(
    0,
    values,
    'Carta Alta',
    cards,
  );
}

int compareScore(List<int> a, List<int> b) {
  final length = a.length > b.length ? a.length : b.length;

  for (int i = 0; i < length; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;

    if (av != bv) {
      return av.compareTo(bv);
    }
  }

  return 0;
}

int cardValue(String card) {
  final rank = card.substring(0, card.length - 1);

  switch (rank) {
    case '2':
      return 2;
    case '3':
      return 3;
    case '4':
      return 4;
    case '5':
      return 5;
    case '6':
      return 6;
    case '7':
      return 7;
    case '8':
      return 8;
    case '9':
      return 9;
    case '10':
      return 10;
    case 'J':
      return 11;
    case 'Q':
      return 12;
    case 'K':
      return 13;
    case 'A':
      return 14;
  }

  return 0;
}

String cardSuit(String card) {
  return card.substring(card.length - 1);
}

String valueName(int value) {
  switch (value) {
    case 14:
      return 'Ás';
    case 13:
      return 'Reis';
    case 12:
      return 'Damas';
    case 11:
      return 'Valetes';
    default:
      return '$value';
      }
}
  }
}
