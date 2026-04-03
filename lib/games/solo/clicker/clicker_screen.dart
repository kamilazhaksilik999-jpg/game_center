import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

// 🔥 ДОБАВИЛ
import '../../../core/services/user_service.dart';
import '../../../features/leaderboard/leaderboard_provider.dart';

void win(BuildContext context) async { // 🔥 async
  CoinService.addCoins(10);

  // 👤 создаём / получаем пользователя
  final userId = await UserService.getOrCreateUser();

  // 🏆 обновляем рейтинг
  await LeaderboardProvider().updateAfterMatch(
    userId: userId,
    win: true,
  );

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
      scale = 0.9;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => scale = 1.0);
    });

    spawnCoins();

    if (taps == target) {
      Future.delayed(const Duration(milliseconds: 300), () {
        win(context);
      });
    }
  }

  void spawnCoins() {
    final random = Random();

    for (int i = 0; i < 6; i++) {
      floatingCoins.add(
        _FloatingCoin(
          offset: Offset(
            random.nextDouble() * 100 - 50,
            random.nextDouble() * -150,
          ),
        ),
      );
    }

    setState(() {});

    Future.delayed(const Duration(milliseconds: 800), () {
      floatingCoins.clear();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Кликер"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// 🔢 СЧЁТЧИК
          const SizedBox(height: 20),

          Text(
            "$taps / $target",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// 📊 ПРОГРЕСС
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(
              value: taps / target,
              minHeight: 10,
            ),
          ),

          /// 🎮 ИГРОВАЯ ОБЛАСТЬ
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [

                  /// 🔘 КНОПКА
                  GestureDetector(
                    onTap: onTap,
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 100),
                      child: Image.asset(
                        "assets/coins.png",
                        width: 200,
                      ),
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
}

/// 🪙 модель
class _FloatingCoin {
  final Offset offset;

  _FloatingCoin({required this.offset});
}