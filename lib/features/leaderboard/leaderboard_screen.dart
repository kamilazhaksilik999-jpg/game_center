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
<<<<<<< HEAD
      backgroundColor: const Color(0xFF060B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,

        // ── Видимая кнопка назад ──────────────────────────────────────
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
              child: const Text(
                "🌍",
                style: TextStyle(fontSize: 20),
              ),
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFFBBF24),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
=======

      backgroundColor: const Color(0xff020617),

      appBar: AppBar(
        title: const Text("🌍 Global Ranking"),
        backgroundColor: Colors.transparent,
        elevation: 0,
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

        stream: provider.getLeaderboard(),
        builder: (context, snapshot) {

<<<<<<< HEAD
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        color: Color(0xFFFBBF24),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Загружаем рейтинг...",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
=======
          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Ошибка: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
              ),
            );
          }

<<<<<<< HEAD
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFF43F5E),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Ошибка загрузки\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("😢", style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 14),
                  const Text(
                    "Пока никого нет",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Сыграй первую игру!",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
=======
          /// 📭 Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Нет игроков 😢",
                style: TextStyle(color: Colors.white),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
              ),
            );
          }

          final players = snapshot.data!.docs;

          return ListView.builder(
<<<<<<< HEAD
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final data = players[index].data();
              final userId = players[index].id;
              final isMe = userId == currentUserId;

              return _LeaderboardRow(
                data: data,
                index: index,
                isCurrentUser: isMe,
=======

            padding: const EdgeInsets.all(12),

            itemCount: players.length,

            itemBuilder: (context, index) {

              final player = players[index].data();

              final name = player['name'] ?? 'Player';
              final rating = player['rating'] ?? 0;

              /// 🎨 Цвет топа
              Color color;
              if (index == 0) color = Colors.amber;
              else if (index == 1) color = Colors.grey;
              else if (index == 2) color = Colors.deepOrange;
              else color = Colors.blueGrey;

              /// 👤 инициалы
              String initials = "";
              final parts = name.toString().split(" ");
              for (var p in parts) {
                if (p.isNotEmpty) initials += p[0];
              }

              return Container(

                margin: const EdgeInsets.only(bottom: 12),

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),

                child: Row(
                  children: [

                    /// 🏆 МЕСТО
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// 👤 АВАТАР
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// 🧑 ИМЯ
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    /// 💰 ОЧКИ
                    Text(
                      "$rating",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
              );
            },
          );
        },
      ),
    );
  }
}

// ── Строка рейтинга ───────────────────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.data,
    required this.index,
    required this.isCurrentUser,
  });

  // Цвета и медали для топ-3
  Color get _rankColor {
    if (index == 0) return const Color(0xFFFBBF24); // золото
    if (index == 1) return const Color(0xFF94A3B8); // серебро
    if (index == 2) return const Color(0xFFD97706); // бронза
    return const Color(0xFF1E3A8A);
  }

  String get _medal {
    if (index == 0) return "🥇";
    if (index == 1) return "🥈";
    if (index == 2) return "🥉";
    return "#${index + 1}";
  }

  List<Color> get _rowGradient {
    if (isCurrentUser) {
      return [
        const Color(0xFF1D4ED8).withValues(alpha: 0.35),
        const Color(0xFF06B6D4).withValues(alpha: 0.15),
      ];
    }
    if (index == 0) {
      return [
        const Color(0xFFD97706).withValues(alpha: 0.25),
        const Color(0xFF78350F).withValues(alpha: 0.2),
      ];
    }
    if (index == 1) {
      return [
        const Color(0xFF475569).withValues(alpha: 0.3),
        const Color(0xFF1E293B).withValues(alpha: 0.2),
      ];
    }
    if (index == 2) {
      return [
        const Color(0xFF92400E).withValues(alpha: 0.25),
        const Color(0xFF78350F).withValues(alpha: 0.1),
      ];
    }
    return [
      const Color(0xFF0D1B35).withValues(alpha: 0.8),
      const Color(0xFF111827).withValues(alpha: 0.6),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['name'] ?? 'Игрок';
    final rating = data['rating'] ?? 0;
    final wins = data['wins'] ?? 0;
    final games = data['totalGames'] ?? 0;
    final winPct = games > 0 ? ((wins / games) * 100).toStringAsFixed(0) : '0';

    // Инициалы
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _rowGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF06B6D4).withValues(alpha: 0.6)
              : _rankColor.withValues(alpha: index < 3 ? 0.5 : 0.2),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: index < 3
            ? [
          BoxShadow(
            color: _rankColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [

          // ── Медаль / номер ──────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Center(
              child: index < 3
                  ? Text(_medal, style: const TextStyle(fontSize: 22))
                  : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    "#${index + 1}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Аватар ───────────────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _rankColor.withValues(alpha: 0.8),
                  _rankColor.withValues(alpha: 0.4),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Имя + статы ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrentUser
                              ? const Color(0xFF67E8F9)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          "ВЫ",
                          style: TextStyle(
                            color: Color(0xFF67E8F9),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Игр: $games  •  Побед: $winPct%",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Рейтинг ──────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: index == 0
                      ? [const Color(0xFFFBBF24), const Color(0xFFF97316)]
                      : index == 1
                      ? [const Color(0xFFE2E8F0), const Color(0xFF94A3B8)]
                      : index == 2
                      ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                      : [Colors.white, Colors.white70],
                ).createShader(b),
                child: Text(
                  "$rating",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Text(
                "rating",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}