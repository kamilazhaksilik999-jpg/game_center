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
        setState(() {
          found[i] = true;
        });

        if (found.every((e) => e)) {
          win();
        }

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
        const SnackBar(content: Text("🎉 Ты прошла все уровни!")),
      );

      Navigator.pop(context);
    }
  }

  void win() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("🎉 Победа", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nextLevel();
            },
            child: const Text("Дальше"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        title: Text("Уровень ${currentLevel.id}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          /// 🔥 ПРОГРЕСС БАР
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                "${found.where((e) => e).length} / ${found.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🖼️ КАРТИНКИ
          Expanded(
            child: Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTapDown: (d) {

                      final box = imageKey.currentContext!.findRenderObject() as RenderBox;
                      final size = box.size;

                      tap(d.localPosition, size);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          key: imageKey,
                          children: [
                            Image.asset(currentLevel.image1, fit: BoxFit.cover),
                            ...drawCircles(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(currentLevel.image2, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> drawCircles() {

    List<Widget> list = [];

    final box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return list;

    final size = box.size;

    for (int i = 0; i < currentLevel.differences.length; i++) {

      if (found[i]) {

        final r = currentLevel.differences[i];

        list.add(Positioned(
          left: r.left * size.width,
          top: r.top * size.height,
          child: Container(
            width: r.width * size.width,
            height: r.height * size.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ));
      }
    }

    return list;
  }
}