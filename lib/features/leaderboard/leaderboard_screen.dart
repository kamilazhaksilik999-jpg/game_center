import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_provider.dart';
import 'leaderboard_tile.dart';

//ст
class LeaderboardScreen extends StatelessWidget {
  LeaderboardScreen({super.key});

  final LeaderboardProvider provider = LeaderboardProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,

        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
              ).createShader(b),
              child: const Text("🌍", style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFFFFFFF)],
              ).createShader(b),
              child: const Text(
                "Мировой рейтинг",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.getLeaderboard(),
        builder: (context, snapshot) {

          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFBBF24),
              ),
            );
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Ошибка: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          /// 📭 Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Пока никого нет 😢",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final players = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final data = players[index].data();

              return _LeaderboardRow(
                data: data,
                index: index,
                isCurrentUser: false, // если нужно — подключишь userId
              );
            },
          );
        },
      ),
    );
  }
}

// ── Строка рейтинга ───────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.data,
    required this.index,
    required this.isCurrentUser,
  });

  Color get _rankColor {
    if (index == 0) return const Color(0xFFFBBF24);
    if (index == 1) return const Color(0xFF94A3B8);
    if (index == 2) return const Color(0xFFD97706);
    return const Color(0xFF1E3A8A);
  }

  String get _medal {
    if (index == 0) return "🥇";
    if (index == 1) return "🥈";
    if (index == 2) return "🥉";
    return "#${index + 1}";
  }

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['name'] ?? 'Игрок';
    final rating = data['rating'] ?? 0;

    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rankColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: index < 3
                  ? Text(_medal, style: const TextStyle(fontSize: 20))
                  : Text(
                "#${index + 1}",
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),

          const SizedBox(width: 10),

          CircleAvatar(
            backgroundColor: _rankColor,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          ),

          Text(
            "$rating",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}