import 'dart:math';
import 'package:flutter/material.dart';

class CoinAnimation extends StatefulWidget {
  const CoinAnimation({super.key});

  @override
  State<CoinAnimation> createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with TickerProviderStateMixin {
  final List<AnimationController> controllers = [];
  final List<Animation<double>> animations = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 10; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + Random().nextInt(400)),
      );

      final animation = Tween<double>(begin: 0, end: -150.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );

      controllers.add(controller);
      animations.add(animation);

      controller.forward();
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(10, (i) {
        final randomX = Random().nextDouble() * 100 - 50;

        return AnimatedBuilder(
          animation: animations[i],
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(randomX, animations[i].value),
              child: Opacity(
                opacity: 1 - (animations[i].value.abs() / 150),
                child: child,
              ),
            );
          },
          child: Image.asset(
            "assets/coin.png",
            height: 40,
          ),
        );
      }),
    );
  }
}