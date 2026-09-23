
import 'package:flutter/material.dart';

void main() => runApp(const PokerHoldemApp());

class PlayingCard {
  final String rank, suit, id;
  final int value;
  const PlayingCard(this.rank, this.suit, this.id, this.value);
  bool get red => suit == '♥' || suit == '♦';
}

class HandScore {
  final int category;
  final List<int> tie;
  final String name, detail;
  const HandScore(this.category, this.tie, this.name, this.detail);
}

class PokerHoldemApp extends StatelessWidget {
  const PokerHoldemApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Poker Holdem',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff050807),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const PokerTable(),
  );
}

class PokerTable extends StatefulWidget {
  const PokerTable({super.key});
  @override
  State<PokerTable> createState() => _PokerTableState();
}

class _PokerTableState extends State<PokerTable> {
  late final List<PlayingCard> deck;
  int playersCount = 4;
  int dealer = 0;
  int handNumber = 1;
  int pot = 0;
  late List<PlayingCard?> board;
  late List<List<PlayingCard?>> hole;
  List<HandScore?> scores = [];
  String result = 'Pronto para a próxima mão.';
  final List<String> history = [];
  int? pickerPlayer, pickerCard, pickerBoard;

  @override
  void initState() {
    super.initState();
    deck = makeDeck();
    resetHand();
  }

  List<PlayingCard> makeDeck() {
    const suits = ['♠','♥','♦','♣'];
    const ranks = ['2','3','4','5','6','7','8','9','10','J','Q','K','A'];
    return [
      for (final s in suits)
        for (var i = 0; i < ranks.length; i++)
          PlayingCard(ranks[i], s, '$s${ranks[i]}', i + 2)
    ];
  }

  Set<String> get used => {
    ...board.whereType<PlayingCard>().map((c) => c.id),
    ...hole.expand((p) => p).whereType<PlayingCard>().map((c) => c.id),
  };

  void resetHand({bool advance = false}) {
    if (advance) {
      dealer = (dealer + 1) % playersCount;
      handNumber++;
    }
    setState(() {
      board = List.filled(5, null);
      hole = List.generate(playersCount, (_) => List.filled(2, null));
      scores = [];
      pot = playersCount * 10;
      result = 'Mão #$handNumber — coloque as cartas e calcule o vencedor.';
    });
  }

  void changePlayers(int n) {
    playersCount = n;
    dealer %= n;
    resetHand();
  }

  Future<void> pickBoard(int index) async {
    final c = await showModalBottomSheet<PlayingCard>(
      context: context, backgroundColor: const Color(0xff101713), isScrollControlled: true,
      builder: (_) => CardPicker(deck: deck, used: used),
    );
    if (c != null) setState(() => board[index] = c);
  }

  Future<void> pickPlayer(int p, int cindex) async {
    final c = await showModalBottomSheet<PlayingCard>(
      context: context, backgroundColor: const Color(0xff101713), isScrollControlled: true,
      builder: (_) => CardPicker(deck: deck, used: used),
    );
    if (c != null) setState(() => hole[p][cindex] = c);
  }

  void calculate() {
    if (board.any((c) => c == null) || hole.any((p) => p.any((c) => c == null))) {
      setState(() => result = '⚠️ Complete as 5 cartas da mesa e as 2 cartas de todos os jogadores.');
      return;
    }
    final computed = hole.map((p) => Evaluator.score([
      ...board.whereType<PlayingCard>(), ...p.whereType<PlayingCard>()
    ])).toList();
    var best = computed.first;
    for (final s in computed.skip(1)) {
      if (Evaluator.compare(s, best) > 0) best = s;
    }
    final winners = <int>[];
    for (var i = 0; i < computed.length; i++) {
      if (Evaluator.compare(computed[i], best) == 0) winners.add(i + 1);
    }
    final text = winners.length == 1
        ? '🏆 JOGADOR ${winners.first} VENCEU'
        : '🤝 EMPATE — ${winners.map((n) => 'JOGADOR $n').join(' e ')}';
    setState(() {
      scores = computed;
      result = '$text\n${best.name} — ${best.detail}';
      history.insert(0, 'Mão #$handNumber • $text • ${best.name}');
      if (history.length > 12) history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff020403), Color(0xff071c13), Color(0xff020403)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
            child: Column(children: [
              header(),
              const SizedBox(height: 8),
              casinoTable(),
              const SizedBox(height: 10),
              actions(),
              const SizedBox(height: 10),
              resultPanel(),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 10),
                historyPanel(),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget header() => Row(children: [
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('♛ POKER HOLD’EM', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.amber)),
      Text('CASINO TABLE • OFFLINE', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: Colors.white54)),
    ])),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<int>(
        value: playersCount, dropdownColor: const Color(0xff14221b),
        items: [for (var n = 2; n <= 8; n++) DropdownMenuItem(value: n, child: Text('$n jogadores')),
        onChanged: (n) { if (n != null) setState(() => changePlayers(n)); },
      )),
    ),
  ]);

  Widget casinoTable() {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const RadialGradient(
          center: Alignment.center, radius: 1.05,
          colors: [Color(0xff197044), Color(0xff0a482d), Color(0xff042519)],
          stops: [0, .62, 1],
        ),
        border: Border.all(color: const Color(0xff7d5427), width: 7),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 22, spreadRadius: 2)],
      ),
      child: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: TableMarkingsPainter()))),
        Positioned(top: 16, left: 0, right: 0, child: seat(0)),
        Positioned(top: 150, left: 3, child: seat(playersCount > 1 ? 1 : 0)),
        Positioned(top: 150, right: 3, child: seat(playersCount > 2 ? 2 : 0)),
        Positioned(bottom: 24, left: 0, right: 0, child: seat(playersCount > 3 ? 3 : 0)),
        if (playersCount > 4) Positioned(top: 315, left: 2, child: seat(4)),
        if (playersCount > 5) Positioned(top: 315, right: 2, child: seat(5)),
        if (playersCount > 6) Positioned(bottom: 145, left: 2, child: seat(6)),
        if (playersCount > 7) Positioned(bottom: 145, right: 2, child: seat(7)),
        Positioned(top: 190, left: 0, right: 0, child: centerPot()),
      ]),
    );
  }

  Widget seat(int p) {
    final active = p < playersCount;
    if (!active) return const SizedBox();
    final isDealer = p == dealer;
    final sb = p == (dealer + 1) % playersCount;
    final bb = p == (dealer + 2) % playersCount;
    return Center(
      child: Container(
        width: 148, padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDealer ? Colors.amber : Colors.white12, width: isDealer ? 1.5 : 1),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 15, backgroundColor: Colors.black54, child: Text('${p + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(width: 5),
            Flexible(child: Text('JOGADOR ${p + 1}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            miniCard(hole[p][0], () => pickPlayer(p, 0)),
            const SizedBox(width: 3),
            miniCard(hole[p][1], () => pickPlayer(p, 1)),
          ]),
          const SizedBox(height: 3),
          Wrap(spacing: 3, children: [
            if (isDealer) badge('D'),
            if (sb) badge('SB'),
            if (bb) badge('BB'),
          ]),
        ]),
      ),
    );
  }

  Widget badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(5)),
    child: Text(t, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
  );

  Widget centerPot() => Column(children: [
    const Text('POTE', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white70)),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ...List.generate(3, (_) => const Padding(padding: EdgeInsets.symmetric(horizontal: 1), child: ChipIcon())),
      const SizedBox(width: 5),
      Text('$pot', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.amber)),
    ]),
    const SizedBox(height: 8),
    Wrap(alignment: WrapAlignment.center, spacing: 5, children: [
      for (var i = 0; i < 5; i++) card(board[i], () => pickBoard(i)),
    ]),
  ]);

  Widget miniCard(PlayingCard? c, VoidCallback tap) => GestureDetector(onTap: tap, child: playingCard(c, 34, 46));
  Widget card(PlayingCard? c, VoidCallback tap) => GestureDetector(onTap: tap, child: playingCard(c, 43, 59));

  Widget playingCard(PlayingCard? c, double w, double h) => Container(
    width: w, height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: c == null ? Colors.white.withOpacity(.12) : Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)],
    ),
    child: Text(c == null ? '+' : '${c.rank}${c.suit}',
      style: TextStyle(fontSize: w > 40 ? 16 : 12, fontWeight: FontWeight.w900,
      color: c == null ? Colors.white54 : (c.red ? Colors.red.shade700 : Colors.black))),
  );

  Widget actions() => Row(children: [
    Expanded(child: ElevatedButton.icon(
      onPressed: calculate, icon: const Icon(Icons.emoji_events_rounded),
      label: const Text('CALCULAR'), style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    )),
    const SizedBox(width: 7),
    OutlinedButton.icon(
      onPressed: () => resetHand(advance: true), icon: const Icon(Icons.skip_next_rounded),
      label: const Text('PRÓXIMA MÃO'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10)),
    ),
  ]);

  Widget resultPanel() => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(.18))),
    child: Column(children: [
      const Text('RESULTADO', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white54)),
      const SizedBox(height: 5),
      Text(result, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.amber)),
      if (scores.isNotEmpty) ...[
        const Divider(color: Colors.white12),
        for (var i = 0; i < scores.length; i++)
          Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
            Text('Jogador ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const Spacer(),
            Text(scores[i]!.name, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(scores[i]!.detail, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ])),
      ],
    ]),
  );

  Widget historyPanel() => Container(
    width: double.infinity, padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📜 HISTÓRICO DA SESSÃO', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      ...history.map((h) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(h, style: const TextStyle(fontSize: 11, color: Colors.white70)))),
    ]),
  );
}

class ChipIcon extends StatelessWidget {
  const ChipIcon({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade800, border: Border.all(color: Colors.white70, width: 2)),
    child: const Center(child: Text('◆', style: TextStyle(fontSize: 8, color: Colors.white))),
  );
}

class TableMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withOpacity(.08);
    final r = Rect.fromLTWH(size.width*.10, size.height*.12, size.width*.80, size.height*.76);
    canvas.drawOval(r, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardPicker extends StatelessWidget {
  final List<PlayingCard> deck;
  final Set<String> used;
  const CardPicker({super.key, required this.deck, required this.used});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        const Text('ESCOLHA UMA CARTA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 10),
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisExtent: 52, crossAxisSpacing: 7, mainAxisSpacing: 7),
          itemCount: deck.length,
          itemBuilder: (_, i) {
            final c = deck[i], disabled = used.contains(c.id);
            return ElevatedButton(
              onPressed: disabled ? null : () => Navigator.pop(context, c),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: c.red ? Colors.red : Colors.black, disabledBackgroundColor: Colors.white24),
              child: Text('${c.rank}${c.suit}', style: const TextStyle(fontWeight: FontWeight.w900)),
            );
          },
        )),
      ]),
    ),
  );
}

class Evaluator {
  static const names = ['Carta alta','Par','Dois pares','Trinca','Sequência','Flush','Full House','Quadra','Straight Flush','Royal Flush'];

  static int compare(HandScore a, HandScore b) {
    if (a.category != b.category) return a.category.compareTo(b.category);
    final n = a.tie.length < b.tie.length ? a.tie.length : b.tie.length;
    for (var i = 0; i < n; i++) {
      if (a.tie[i] != b.tie[i]) return a.tie[i].compareTo(b.tie[i]);
    }
    return 0;
  }

  static HandScore score(List<PlayingCard> seven) {
    HandScore? best;
    for (var a=0;a<7;a++) for (var b=a+1;b<7;b++) for (var c=b+1;c<7;c++)
      for (var d=c+1;d<7;d++) for (var e=d+1;e<7;e++) {
        final s = score5([seven[a],seven[b],seven[c],seven[d],seven[e]]);
        if (best == null || compare(s,best!) > 0) best=s;
      }
    return best!;
  }

  static HandScore score5(List<PlayingCard> cards) {
    final vals = cards.map((c)=>c.value).toList()..sort((a,b)=>b.compareTo(a));
    final counts=<int,int>{};
    for(final v in vals){counts[v]=(counts[v]??0)+1;}
    final flush=cards.map((c)=>c.suit).toSet().length==1;
    final u=counts.keys.toList()..sort((a,b)=>b.compareTo(a));
    if(u.contains(14))u.add(1);
    var straight=0;
    for(var i=0;i+4<u.length;i++){if(u[i]-u[i+4]==4){straight=u[i];break;}}
    final groups=counts.entries.toList()..sort((a,b)=>a.value!=b.value?b.value.compareTo(a.value):b.key.compareTo(a.key));
    if(flush&&straight==14)return const HandScore(9,[14],'Royal Flush','A-K-Q-J-10');
    if(flush&&straight>0)return HandScore(8,[straight],'Straight Flush','${rank(straight)} high');
    if(groups[0].value==4){final k=groups[0].key;return HandScore(7,[k,...vals.where((v)=>v!=k)],names[7],rank(k));}
    if(groups[0].value==3){
      final pair=groups.skip(1).firstWhere((g)=>g.value>=2,orElse:()=>const MapEntry(-1,0));
      if(pair.key!=-1)return HandScore(6,[groups[0].key,pair.key],names[6],'${rank(groups[0].key)} full de ${rank(pair.key)}');
    }
    if(flush)return HandScore(5,vals,names[5],vals.map(rank).join('-'));
    if(straight>0)return HandScore(4,[straight],names[4],'${rank(straight)} high');
    if(groups[0].value==3){final k=groups[0].key;return HandScore(3,[k,...vals.where((v)=>v!=k)],names[3],rank(k));}
    final pairs=groups.where((g)=>g.value==2).map((g)=>g.key).toList();
    if(pairs.length>=2)return HandScore(2,[pairs[0],pairs[1],...vals.where((v)=>!pairs.contains(v))],names[2],'${rank(pairs[0])} e ${rank(pairs[1])}');
    if(pairs.length==1){final k=pairs[0];return HandScore(1,[k,...vals.where((v)=>v!=k)],names[1],rank(k));}
    return HandScore(0,vals,names[0],rank(vals[0]));
  }

  static String rank(int v)=>switch(v){14=>'A',13=>'K',12=>'Q',11=>'J',_=>'$v'};
}
