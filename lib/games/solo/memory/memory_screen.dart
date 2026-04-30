import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';

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
  final List<String> emojis = ["🍎", "🍌", "🍇", "🍉", "🍒", "🍍"];
  late List<String> cards;
  List<bool> revealed = [];
  int? firstIndex;
  int? secondIndex;
  int pairsFound = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    cards = [...emojis, ...emojis]..shuffle(Random());
    revealed = List.generate(cards.length, (_) => false);
    pairsFound = 0;
    firstIndex = null;
    secondIndex = null;
  }

  void checkWin() {
    if (revealed.every((e) => e)) {
      Future.delayed(const Duration(milliseconds: 300), () => win(context));
    }
  }

  void onTap(int index) async {
    if (revealed[index]) return;
    if (firstIndex != null && secondIndex != null) return;

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
        setState(() => pairsFound++);
        checkWin();
      }

      firstIndex = null;
      secondIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = emojis.length;

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
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("MEM", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            const Text("Память", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFDB2777), Colors.transparent]),
          )),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 12),

            // ── Статус ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFFDB2777)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFFDB2777).withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Найди пары", "🧠"),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _statItem("$pairsFound / $total пар", "✅"),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _statItem("Награда 10🪙", "💰"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Прогресс-бар ─────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B35),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF6D28D9).withValues(alpha: 0.3)),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  widthFactor: total > 0 ? pairsFound / total : 0,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFFDB2777)]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: const Color(0xFFDB2777).withValues(alpha: 0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Поле карточек ────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                itemCount: cards.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final isRevealed = revealed[index];
                  return GestureDetector(
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: isRevealed
                            ? LinearGradient(colors: [
                          const Color(0xFF059669).withValues(alpha: 0.25),
                          const Color(0xFF0D1B35).withValues(alpha: 0.8),
                        ])
                            : const LinearGradient(
                          colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRevealed
                              ? const Color(0xFF34D399).withValues(alpha: 0.5)
                              : const Color(0xFF7C3AED).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isRevealed
                                ? const Color(0xFF34D399).withValues(alpha: 0.2)
                                : const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isRevealed
                            ? Text(cards[index], style: const TextStyle(fontSize: 28))
                            : Icon(Icons.question_mark_rounded,
                            color: Colors.white.withValues(alpha: 0.7), size: 26),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Подсказка ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                "Открывай карточки и находи пары",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String text, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}