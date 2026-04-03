import 'package:flutter/material.dart';
import '../core/models/level_model.dart';

class GameScreen extends StatefulWidget {
  final LevelModel level;
  const GameScreen({Key? key, required this.level}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Set<int> _foundIndices = {};

  void _onTap(TapDownDetails details, BoxConstraints constraints) {
    // Получаем точные координаты клика в процентах (0.0 - 1.0)
    double x = details.localPosition.dx / constraints.maxWidth;
    double y = details.localPosition.dy / constraints.maxHeight;

    for (int i = 0; i < widget.level.differences.length; i++) {
      if (widget.level.differences[i].contains(Offset(x, y))) {
        if (!_foundIndices.contains(i)) {
          setState(() => _foundIndices.add(i));
          _checkWin();
        }
        return;
      }
    }
  }

  void _checkWin() {
    if (_foundIndices.length == widget.level.differences.length) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Уровень пройден!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Далее"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Найдено: ${_foundIndices.length}/${widget.level.differences.length}")),
      body: Column(
        children: [
          // Верхняя картинка (эталон)
          Expanded(
            child: Image.asset(widget.level.image1, fit: BoxFit.fill),
          ),
          const Divider(height: 2, color: Colors.black),
          // Нижняя картинка (интерактивная)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTap(details, constraints),
                  child: Stack(
                    children: [
                      Image.asset(widget.level.image2, fit: BoxFit.fill, width: double.infinity),
                      // Рисуем кружки найденных отличий
                      ..._foundIndices.map((index) {
                        final rect = widget.level.differences[index];
                        return Positioned(
                          left: rect.left * constraints.maxWidth - 5, // Небольшой запас для центровки
                          top: rect.top * constraints.maxHeight - 5,
                          width: rect.width * constraints.maxWidth + 10,
                          height: rect.height * constraints.maxHeight + 10,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.greenAccent, width: 3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}