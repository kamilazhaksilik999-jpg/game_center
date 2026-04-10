import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

void win(BuildContext context) {
  CoinService.addCoins(10);
  showWinDialog(context);
}

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<String> emojis = ["🍎","🍌","🍇","🍉","🍒","🍍"];
  late List<String> cards;

  List<bool> revealed = [];
  int? firstIndex;
  int? secondIndex;

  @override
  void initState() {
    super.initState();
    cards = [...emojis, ...emojis];
    cards.shuffle(Random());
    revealed = List.generate(cards.length, (_) => false);
  }

  void checkWin() {
    if (revealed.every((e) => e)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        win(context); // ✅ теперь даёт монеты + диалог
      });
    }
  }

  void onTap(int index) async {
    if (revealed[index]) return;

    setState(() => revealed[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      secondIndex = index;

      await Future.delayed(const Duration(milliseconds: 500));

      if (cards[firstIndex!] != cards[secondIndex!]) {
        setState(() {
          revealed[firstIndex!] = false;
          revealed[secondIndex!] = false;
        });
      } else {
        checkWin();
      }

      firstIndex = null;
      secondIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        title: const Text("Игра на память"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 ЗАГОЛОВОК
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  "Найди пары",
                  style: TextStyle(
                    fontSize: 24,
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
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),

                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => onTap(index),

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      decoration: BoxDecoration(
                        gradient: revealed[index]
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF334155)
                          ],
                        )
                            : const LinearGradient(
                          colors: [
                            Color(0xFF0EA5E9),
                            Color(0xFF3B82F6)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),

                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),

                      child: Center(
                        child: revealed[index]
                            ? Text(
                          cards[index],
                          style: const TextStyle(fontSize: 30),
                        )
                            : const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 💡 ПОДСКАЗКА
            Text(
              "Открывай карточки и находи пары",
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