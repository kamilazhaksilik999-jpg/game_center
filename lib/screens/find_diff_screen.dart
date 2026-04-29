import 'package:flutter/material.dart';
import '../../core/models/level_model.dart';
import '../../data/levels.dart';

class FindDiffScreen extends StatefulWidget {
  final LevelModel level;
  const FindDiffScreen({super.key, required this.level});

  @override
  State<FindDiffScreen> createState() => _FindDiffScreenState();
}

class _FindDiffScreenState extends State<FindDiffScreen> {
  List<bool> found = [];
  late LevelModel currentLevel;
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    found = List.generate(currentLevel.differences.length, (_) => false);
  }

  void tap(Offset pos, Size size) {
    for (int i = 0; i < currentLevel.differences.length; i++) {
      final r = currentLevel.differences[i];
      final scaledRect = Rect.fromLTWH(
        r.left * size.width,
        r.top * size.height,
        r.width * size.width,
        r.height * size.height,
      );
      if (scaledRect.contains(pos) && !found[i]) {
        setState(() => found[i] = true);
        if (found.every((e) => e)) win();
        break;
      }
    }
  }

  void nextLevel() {
    final index = levels.indexWhere((l) => l.id == currentLevel.id);
    if (index + 1 < levels.length) {
      setState(() {
        currentLevel = levels[index + 1];
        found = List.generate(currentLevel.differences.length, (_) => false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🎉 Ты прошла все уровни!"),
          backgroundColor: const Color(0xFF0D1B35),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  void win() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка победы с glow
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF97316)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("🎉", style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                ).createShader(b),
                child: const Text(
                  "Победа!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Все отличия найдены",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  nextLevel();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Дальше →",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int foundCount = found.where((e) => e).length;
    final int total = found.length;
    final double progress = total > 0 ? foundCount / total : 0;

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
                    colors: [Color(0xFFD97706), Color(0xFFF97316)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("DIFF",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            Text(
              "Уровень ${currentLevel.id}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700),
            ),
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
                Color(0xFFF97316),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // ── Счётчик ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("НАЙДЕНО",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3)),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                  ).createShader(b),
                  child: Text(
                    "$foundCount / $total",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Прогресс-бар ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.5)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  width: (MediaQuery.of(context).size.width - 40) * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF97316), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.5),
                          blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Инфо-карточки ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _infoCard("Найдено", "$foundCount", const Color(0xFF34D399)),
                const SizedBox(width: 10),
                _infoCard("Осталось", "${total - foundCount}", const Color(0xFF3B82F6)),
                const SizedBox(width: 10),
                _infoCard("Уровень", "${currentLevel.id}", const Color(0xFFFBBF24)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Картинки ────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Левая — кликабельная
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (d) {
                        final box = imageKey.currentContext!
                            .findRenderObject() as RenderBox;
                        tap(d.localPosition, box.size);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            key: imageKey,
                            fit: StackFit.expand,
                            children: [
                              Image.asset(currentLevel.image1, fit: BoxFit.cover),
                              ...drawCircles(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Правая — референс
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(currentLevel.image2, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Подсказка ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Text(
              foundCount >= total
                  ? "🎉 Все отличия найдены!"
                  : "Нажми на отличие на левой картинке",
              style: TextStyle(
                color: foundCount >= total
                    ? const Color(0xFF34D399)
                    : Colors.white30,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> drawCircles() {
    final box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return [];

    final size = box.size;
    return [
      for (int i = 0; i < currentLevel.differences.length; i++)
        if (found[i])
          Positioned(
            left: currentLevel.differences[i].left * size.width,
            top: currentLevel.differences[i].top * size.height,
            child: Container(
              width: currentLevel.differences[i].width * size.width,
              height: currentLevel.differences[i].height * size.height,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF34D399), width: 2.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}