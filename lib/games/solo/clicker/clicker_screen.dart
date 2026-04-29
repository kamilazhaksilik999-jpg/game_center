import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/user_service.dart';
import '../../../features/leaderboard/leaderboard_provider.dart';

void win(BuildContext context) async {
  CoinService.addCoins(10);
  final userId = await UserService.getOrCreateUser();
  await LeaderboardProvider().updateAfterMatch(userId: userId, win: true);
  showWinDialog(context);
}

class ClickerScreen extends StatefulWidget {
  const ClickerScreen({super.key});

  @override
  State<ClickerScreen> createState() => _ClickerScreenState();
}

class _ClickerScreenState extends State<ClickerScreen> {
  int taps = 0;
  final int target = 20;
  double scale = 1.0;
  final List<_FloatingCoin> floatingCoins = [];

  void onTap() {
    if (taps >= target) return;

    setState(() {
      taps++;
      scale = 0.88;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => scale = 1.0);
    });

    spawnCoins();

    if (taps == target) {
      Future.delayed(const Duration(milliseconds: 300), () => win(context));
    }
  }

  void spawnCoins() {
    final random = Random();
    for (int i = 0; i < 6; i++) {
      floatingCoins.add(_FloatingCoin(
        offset: Offset(
          random.nextDouble() * 100 - 50,
          random.nextDouble() * -150,
        ),
      ));
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 800), () {
      floatingCoins.clear();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = taps / target;

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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF97316)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("TAP", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            const Text("Кликер", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF97316), Colors.transparent]),
          )),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height: 24),

          // ── Счётчик ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("ПРОГРЕСС", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3)),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                  ).createShader(b),
                  child: Text(
                    "$taps / $target",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Прогресс-бар ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.5)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 14,
                  width: (MediaQuery.of(context).size.width - 40) * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF97316), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: const Color(0xFFF97316).withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Инфо-карточки ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _infoCard("Осталось", "${target - taps}", const Color(0xFF3B82F6)),
                const SizedBox(width: 10),
                _infoCard("Цель", "$target", const Color(0xFFA855F7)),
                const SizedBox(width: 10),
                _infoCard("Награда", "10 🪙", const Color(0xFFFBBF24)),
              ],
            ),
          ),

          // ── Игровая область ────────────────────────────────────────
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // Свечение вокруг монеты
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 220 * scale + 40,
                    height: 220 * scale + 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: taps > 0 ? 0.3 : 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  // Монета
                  GestureDetector(
                    onTap: onTap,
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                            center: Alignment(-0.3, -0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6), width: 3),
                        ),
                        child: Image.asset("assets/coins.png", fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Center(
                              child: Text("🪙", style: TextStyle(fontSize: 70)),
                            )),
                      ),
                    ),
                  ),

                  // Плавающие монеты
                  ...floatingCoins.map((coin) => Positioned(
                    left: 90 + coin.offset.dx,
                    top: 90 + coin.offset.dy,
                    child: const Text("🪙", style: TextStyle(fontSize: 20)),
                  )),
                ],
              ),
            ),
          ),

          // ── Подсказка ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              taps >= target ? "🎉 Отлично!" : "Нажимай на монету!",
              style: TextStyle(
                color: taps >= target ? const Color(0xFF34D399) : Colors.white30,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _FloatingCoin {
  final Offset offset;
  _FloatingCoin({required this.offset});
}