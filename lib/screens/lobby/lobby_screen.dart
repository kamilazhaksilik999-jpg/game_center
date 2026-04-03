import 'package:flutter/material.dart';

// файлы из подпапки online
import 'online/online_games_screen.dart';
import 'online/room_create_screen.dart';
import 'online/room_join_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("🌐 Лобби Онлайн-игр"),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Старый текст
            const Text(
              "Здесь будет список онлайн-игр!",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Новый блок "Выбери режим"
            const Text(
              "ВЫБЕРИ РЕЖИМ",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),

            _modeButton(
              context,
              icon: Icons.smart_toy,
              title: "Против ИИ",
              subtitle: "Тренируйся в любое время",
              color: Colors.greenAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlineGamesScreen(selectedMode: "ИИ"),
                  ),
                );
              },
            ),

            _modeButton(
              context,
              icon: Icons.casino,
              title: "Случайный соперник",
              subtitle: "Онлайн матч с рандомом",
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlineGamesScreen(selectedMode: "Случайный соперник"),
                  ),
                );
              },
            ),

            _modeButton(
              context,
              icon: Icons.vpn_key,
              title: "Создать комнату",
              subtitle: "Позови друга по коду",
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomCreateScreen(gameName: "Любая игра"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
}