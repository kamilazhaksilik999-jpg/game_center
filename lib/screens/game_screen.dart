import 'package:flutter/material.dart';
import '../core/models/level_model.dart';

class GameScreen extends StatefulWidget {

  final LevelModel level;

  const GameScreen({
    super.key,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();

}

class _GameScreenState extends State<GameScreen> {

  final Set<int> _foundIndices = {};

  Offset? debugTap;

  String debugText = "";

  void _onTap(
      TapDownDetails details,
      BoxConstraints constraints,
      ) {

    double x =
        details.localPosition.dx /
            constraints.maxWidth;

    double y =
        details.localPosition.dy /
            constraints.maxHeight;

    String rect =
        "Rect.fromLTWH(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, 0.15, 0.15)";

    setState(() {

      debugTap = Offset(x, y);

      debugText = rect;

    });

    for (int i = 0;
    i < widget.level.differences.length;
    i++) {

      if (widget.level
          .differences[i]
          .contains(Offset(x, y))) {

        if (!_foundIndices.contains(i)) {

          setState(() {

            _foundIndices.add(i);

          });

          if (_foundIndices.length ==
              widget.level.differences.length) {

            _showWinDialog();

          }

        }

        return;

      }

    }

  }

  void _showWinDialog() {

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text("🎉 Победа"),

          content: Text(
              "Найдено ${widget.level.differences.length}"
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text("OK"),

            ),

          ],

        );

      },

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(
            "Найдено ${_foundIndices.length}/${widget.level.differences.length}"
        ),

      ),

      body: Column(

        children: [

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _onTap(details, constraints),
                  child: Image.asset(
                    widget.level.image1,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),

          const Divider(
            height: 2,
            color: Colors.black,
          ),

          Expanded(

            child: LayoutBuilder(

              builder: (context, constraints) {

                return GestureDetector(

                  behavior: HitTestBehavior.opaque,

                  onTapDown: (details) =>
                      _onTap(details, constraints),

                  child: Stack(

                    children: [

                      Positioned.fill(

                        child: Image.asset(

                          widget.level.image2,

                          fit: BoxFit.contain,

                        ),

                      ),

                      // найденные зоны
                      ..._foundIndices.map((index) {

                        final rect =
                        widget.level
                            .differences[index];

                        return Positioned(

                          left:
                          rect.left *
                              constraints.maxWidth,

                          top:
                          rect.top *
                              constraints.maxHeight,

                          width:
                          rect.width *
                              constraints.maxWidth,

                          height:
                          rect.height *
                              constraints.maxHeight,

                          child: Container(

                            decoration:
                            BoxDecoration(

                              border: Border.all(
                                color: Colors.green,
                                width: 3,
                              ),

                              borderRadius:
                              BorderRadius.circular(20),

                            ),

                          ),

                        );

                      }),

                      // DEBUG точка
                      if (debugTap != null)

                        Positioned(

                          left:
                          debugTap!.dx *
                              constraints.maxWidth - 8,

                          top:
                          debugTap!.dy *
                              constraints.maxHeight - 8,

                          child: Container(

                            width: 16,

                            height: 16,

                            decoration:
                            const BoxDecoration(

                              color: Colors.red,

                              shape: BoxShape.circle,

                            ),

                          ),

                        ),

                      // DEBUG текст координат
                      Positioned(

                        top: 10,

                        left: 10,

                        child: Container(

                          color: Colors.black
                              .withOpacity(0.7),

                          padding:
                          const EdgeInsets.all(8),

                          child: Text(

                            debugText,

                            style:
                            const TextStyle(

                              color: Colors.white,

                              fontSize: 14,

                            ),

                          ),

                        ),

                      ),

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