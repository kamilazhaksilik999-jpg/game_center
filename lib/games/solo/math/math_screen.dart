import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';

void win(BuildContext context) {
  CoinService.addCoins(10);
  showWinDialog(context);
}

class MathScreen extends StatefulWidget {
  const MathScreen({super.key});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  int a = 0, b = 0, correct = 0;
  List<int> options = [];
  int? selectedAnswer;
  bool? isCorrect;

  void generate() {
    final rnd = Random();
    a = rnd.nextInt(20);
    b = rnd.nextInt(20);
    correct = a + b;
    options = [
      correct,
      correct + rnd.nextInt(5) + 1,
      correct - rnd.nextInt(5) - 1,
      correct + rnd.nextInt(10),
    ];
    options.shuffle();
    selectedAnswer = null;
    isCorrect = null;
  }

  @override
  void initState() {
    super.initState();
    generate();
  }

  void answer(int value) {
    if (selectedAnswer != null) return;

    setState(() {
      selectedAnswer = value;
      isCorrect = value == correct;
    });

    if (value == correct) {
      Future.delayed(const Duration(milliseconds: 400), () {
        win(context);
        setState(() => generate());
      });
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() { selectedAnswer = null; isCorrect = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.close_rounded, color: Color(0xFFF43F5E), size: 18),
              const SizedBox(width: 8),
              const Text("Неправильно! Попробуй снова", style: TextStyle(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFF0D1B35),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFF43F5E), width: 1),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      });
    }
  }

  // Цвет варианта ответа
  Color _optionBorderColor(int value) {
    if (selectedAnswer == null) return const Color(0xFF1E3A8A).withValues(alpha: 0.5);
    if (value == correct) return const Color(0xFF34D399);
    if (value == selectedAnswer) return const Color(0xFFF43F5E);
    return const Color(0xFF1E3A8A).withValues(alpha: 0.3);
  }

  List<Color> _optionGradient(int value) {
    if (selectedAnswer == null) {
      return [const Color(0xFF0D1B35).withValues(alpha: 0.9), const Color(0xFF111827).withValues(alpha: 0.8)];
    }
    if (value == correct) {
      return [const Color(0xFF059669).withValues(alpha: 0.3), const Color(0xFF065F46).withValues(alpha: 0.2)];
    }
    if (value == selectedAnswer) {
      return [const Color(0xFF7F1D1D).withValues(alpha: 0.3), const Color(0xFF450A0A).withValues(alpha: 0.2)];
    }
    return [const Color(0xFF0D1B35).withValues(alpha: 0.5), const Color(0xFF111827).withValues(alpha: 0.4)];
  }

  @override
  Widget build(BuildContext context) {
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
                gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("MATH", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            const Text("Математика", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, Color(0xFF06B6D4), Colors.transparent]),
          )),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 12),

            // ── Вопрос ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Text("РЕШИ ПРИМЕР", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3)),
                  const SizedBox(height: 12),
                  Text(
                    "$a + $b = ?",
                    style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Метка
            Row(
              children: [
                Container(width: 4, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF818CF8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("ВЫБЕРИ ОТВЕТ", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3)),
              ],
            ),

            const SizedBox(height: 14),

            // ── Варианты ──────────────────────────────────────────────
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                physics: const NeverScrollableScrollPhysics(),
                children: options.map((e) {
                  return GestureDetector(
                    onTap: () => answer(e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _optionGradient(e)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _optionBorderColor(e), width: 1.5),
                        boxShadow: selectedAnswer != null && e == correct
                            ? [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.3), blurRadius: 14)]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selectedAnswer != null && e == correct)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 22),
                          if (selectedAnswer != null && e == selectedAnswer && e != correct)
                            const Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 22),
                          if (selectedAnswer == null || (e != correct && e != selectedAnswer))
                            const SizedBox(height: 22),
                          Text(
                            "$e",
                            style: TextStyle(
                              fontSize: 34,
                              color: selectedAnswer != null && e == correct
                                  ? const Color(0xFF34D399)
                                  : selectedAnswer != null && e == selectedAnswer
                                  ? const Color(0xFFF43F5E)
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Подсказка ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                "Нажми на правильный ответ",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}