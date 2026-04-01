import 'package:flutter/material.dart';
import '../../core/models/level_model.dart';
class FindDiffScreen extends StatefulWidget {




  final LevelModel level;

  const FindDiffScreen({super.key, required this.level});

  @override
  State<FindDiffScreen> createState() => _FindDiffScreenState();
}

class _FindDiffScreenState extends State<FindDiffScreen> {

  List<bool> found = [];

  @override
  void initState() {
    super.initState();
    found = List.generate(widget.level.differences.length, (_) => false);
  }

  void tap(Offset pos, Size size) {

    for (int i = 0; i < widget.level.differences.length; i++) {

      final r = widget.level.differences[i];

      /// 💯 адаптация под экран
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

  void win() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Победа"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Найди отличия")),

      body: Column(
        children: [

          Expanded(
            child: Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTapDown: (d) {
                      final box = context.findRenderObject() as RenderBox;
                      final size = box.size;

                      tap(d.localPosition, size);
                    },                    child: Stack(
                      children: [
                        Image.asset(widget.level.leftImage, fit: BoxFit.cover),
                        ...drawCircles(),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Image.asset(widget.level.rightImage, fit: BoxFit.cover),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "${found.where((e) => e).length} / ${found.length}",
              style: const TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> drawCircles() {
    List<Widget> list = [];

    for (int i = 0; i < widget.level.differences.length; i++) {

      if (found[i]) {
        final r = widget.level.differences[i];

        list.add(Positioned(
          left: r.left,
          top: r.top,
          child: Container(
            width: r.width,
            height: r.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
            ),
          ),
        ));
      }
    }

    return list;
  }
}