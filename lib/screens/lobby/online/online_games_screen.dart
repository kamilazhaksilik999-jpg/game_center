import 'package:flutter/material.dart';
import 'room_create_screen.dart';
import 'room_join_screen.dart';

class OnlineGamesScreen extends StatelessWidget {
  final String? selectedMode; // <- добавили параметр

  const OnlineGamesScreen({super.key, this.selectedMode}); // <- конструктор с параметром

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedMode != null
              ? "Онлайн: $selectedMode"
              : "Онлайн игры",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3,
          children: [
            _gameCard(context, "Морской бой", Colors.teal),
            _gameCard(context, "Мини-футбол", Colors.green),
            _gameCard(context, "Танк", Colors.orange),
            _gameCard(context, "Перетяни канат", Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, String title, Color color) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 🔵 СОЗДАТЬ КОМНАТУ
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomCreateScreen(gameName: title),
                      ),
                    );
                  },
                  child: const Text("Создать комнату"),
                ),

                const SizedBox(height: 10),

                // 🟢 ПРИСОЕДИНИТЬСЯ
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomJoinScreen(gameName: title),
                      ),
                    );
                  },
                  child: const Text("Присоединиться"),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}