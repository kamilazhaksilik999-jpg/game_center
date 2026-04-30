import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';

void win(BuildContext context) {
  CoinService.addCoins(10);
  showWinDialog(context);
}

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> board = List.filled(9, "");
  String current = "X";

  void tap(int i) {
    if (board[i] != "") return;

    setState(() {
      board[i] = current;
      current = current == "X" ? "O" : "X";
    });

    checkWin();
  }

  void checkWin() {
    List<List<int>> wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var w in wins) {
      if (board[w[0]] != "" &&
          board[w[0]] == board[w[1]] &&
          board[w[1]] == board[w[2]]) {

        win(context);

        setState(() {
          board = List.filled(9, "");
          current = "X";
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isX = current == "X";

    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("XO",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            const Text("Крестики-Нолики",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                Color(0xFFA855F7),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Текущий ход ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isX
                            ? [const Color(0xFF34D399), const Color(0xFF059669)]
                            : [const Color(0xFFF472B6), const Color(0xFFDB2777)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("ХОД ИГРОКА",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3)),
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: isX
                          ? [const Color(0xFF34D399), const Color(0xFF6EE7B7)]
                          : [const Color(0xFFF472B6), const Color(0xFFFBCFE8)],
                    ).createShader(b),
                    child: Text(
                      current,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Игровое поле ──────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final symbol = board[i];
                  final isSymbolX = symbol == "X";

                  return GestureDetector(
                    onTap: () => tap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: symbol.isEmpty
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                              : isSymbolX
                              ? const Color(0xFF34D399).withValues(alpha: 0.5)
                              : const Color(0xFFF472B6).withValues(alpha: 0.5),
                          width: symbol.isEmpty ? 1 : 2,
                        ),
                        boxShadow: symbol.isEmpty
                            ? []
                            : [
                          BoxShadow(
                            color: isSymbolX
                                ? const Color(0xFF34D399).withValues(alpha: 0.25)
                                : const Color(0xFFF472B6).withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: symbol.isEmpty
                              ? const SizedBox(key: ValueKey("empty"))
                              : ShaderMask(
                            key: ValueKey(symbol + i.toString()),
                            shaderCallback: (b) => LinearGradient(
                              colors: isSymbolX
                                  ? [const Color(0xFF34D399), const Color(0xFF6EE7B7)]
                                  : [const Color(0xFFF472B6), const Color(0xFFFBCFE8)],
                            ).createShader(b),
                            child: Text(
                              symbol,
                              style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Подсказка ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFA855F7),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Собери линию из 3 символов",
                  style: TextStyle(
                      color: Colors.white30,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}