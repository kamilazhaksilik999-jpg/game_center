import 'package:flutter/material.dart';

class OnlineGamesScreen extends StatelessWidget {
  const OnlineGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1ED5A9), Color(0xFF0FBC8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Онлайн игры",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                const Text(
                  "ВЫБЕРИ РЕЖИМ",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),

                Column(
                  children: [
                    _modeButton(
                      context,
                      icon: Icons.smart_toy,
                      title: "Против ИИ",
                      subtitle: "Тренируйся в любое время",
                      color: Colors.greenAccent,
                    ),
                    _modeButton(
                      context,
                      icon: Icons.casino,
                      title: "Случайный соперник",
                      subtitle: "Онлайн матч с рандомом",
                      color: Colors.blueAccent,
                    ),
                    _modeButton(
                      context,
                      icon: Icons.vpn_key,
                      title: "Создать комнату",
                      subtitle: "Позови друга по коду",
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "ВЫБЕРИ ИГРУ",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3,
                    children: [
                      _gameCard("Морской бой", 34, Colors.teal),
                      _gameCard("Мини-футбол", 21, Colors.green),
                      _gameCard("Танк", 12, Colors.orange),
                      _gameCard("Перетяни канат", 18, Colors.redAccent),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Color color}) {
    return GestureDetector(
      onTap: () {
        // TODO: добавить переход на режим
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(color: Colors.white, fontSize: 16)),
                Text(subtitle,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _gameCard(String title, int onlineCount, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: добавить переход на онлайн игру
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            Text("$onlineCount онлайн",
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}