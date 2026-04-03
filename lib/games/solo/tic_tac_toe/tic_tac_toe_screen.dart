import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

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
      [0,1,2],[3,4,5],[6,7,8],
      [0,3,6],[1,4,7],[2,5,8],
      [0,4,8],[2,4,6]
    ];

    for (var w in wins) {
      if (board[w[0]] != "" &&
          board[w[0]] == board[w[1]] &&
          board[w[1]] == board[w[2]]) {

        win(context); // ✅ теперь с монетами

        setState(() {
          board = List.filled(9, "");
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        title: const Text("Крестики-нолики"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 ТЕКУЩИЙ ИГРОК
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "Ход: $current",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🎮 ПОЛЕ
            Expanded(
              child: GridView.builder(
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),

                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => tap(i),

                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF334155)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          )
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

                          child: board[i] == ""
                              ? const SizedBox()
                              : Text(
                            board[i],
                            key: ValueKey(board[i] + i.toString()),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: board[i] == "X"
                                  ? Colors.greenAccent
                                  : Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 💡 ПОДСКАЗКА
            Text(
              "Собери линию из 3 символов",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}