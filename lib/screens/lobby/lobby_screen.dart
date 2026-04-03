import 'package:flutter/material.dart';
import 'online/online_games_screen.dart'; // <-- путь к онлайн играм

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // тёмный фон
      appBar: AppBar(
        title: const Text(
          "🌐 Лобби Онлайн-игр",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B), // красивый темно-синий
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Кнопки режимов
            _modeCard(context, "Против ИИ", Colors.teal),
            const SizedBox(height: 12),
            _modeCard(context, "Случайный соперник", Colors.green),
            const SizedBox(height: 12),
            _modeCard(context, "Создать комнату", Colors.orange),
            const SizedBox(height: 24),
            // Старый текст "Список онлайн-игр"
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2,2))
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Здесь будет список онлайн-игр!",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(BuildContext context, String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Переход в OnlineGamesScreen с выбранным режимом
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineGamesScreen(selectedMode: title),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2,2))
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}