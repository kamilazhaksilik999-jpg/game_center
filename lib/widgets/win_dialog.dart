import 'package:flutter/material.dart';

void showWinDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => const WinDialog(),
  );
}

class WinDialog extends StatefulWidget {
  const WinDialog({super.key});

  @override
  State<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    scale = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF6EC6FF), Color(0xFF2196F3)],
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🖼️ ТВОЯ КАРТИНКА
              Image.asset(
                "assets/win.png",
                height: 120,
              ),

              const SizedBox(height: 16),

              /// 🎉 ТЕКСТ
              const Text(
                "Поздравляем с победой!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto', // можно поменять
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Вам начислено 10 монет 🪙",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 20),

              /// 🔘 КНОПКА
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // закрыть диалог

                  /// 👉 переход на главный экран
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    "/",
                        (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}