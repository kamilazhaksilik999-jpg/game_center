import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

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
  int a = 0;
  int b = 0;
  int correct = 0;

  List<int> options = [];

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
  }

  @override
  void initState() {
    super.initState();
    generate();
  }

  void answer(int value) {
    if (value == correct) {
      win(context); // ✅ теперь через твою функцию

      generate();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Неправильно"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        title: const Text("Математическая дуэль"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 ВОПРОС (КРАСИВАЯ КАРТОЧКА)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "$a + $b = ?",
                  style: const TextStyle(
                    fontSize: 38,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 🎯 ОТВЕТЫ
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.2,

                children: options.map((e) {
                  return GestureDetector(
                    onTap: () => answer(e),

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),

                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF334155)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),

                      child: Center(
                        child: Text(
                          "$e",
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            /// 💡 Небольшой текст снизу
            Text(
              "Выбери правильный ответ",
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