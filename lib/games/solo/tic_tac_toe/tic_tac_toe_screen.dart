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

        showWinDialog(context);

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
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("КРЕСТИКИ-НОЛИКИ"),
        backgroundColor: Colors.deepOrange,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.builder(
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.5, // 👈 уменьшает квадраты
          ),

          itemBuilder: (context, i) {
            return GestureDetector(
              onTap: () => tap(i),

              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),

                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut, // 🔥 эффект "прыжка"
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
                      key: ValueKey(board[i] + i.toString()), // важно!
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: board[i] == "X"
                            ? Colors.white
                            : Colors.yellow,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}