import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_provider.dart';
import 'leaderboard_tile.dart';

class LeaderboardScreen extends StatelessWidget {
  LeaderboardScreen({super.key});

  final LeaderboardProvider provider = LeaderboardProvider();

  @override
  Widget build(BuildContext context) {
    final currentUserId = provider.currentUserId;

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
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFFFFFFF)],
          ).createShader(b),
          child: const Text(
            "🌍 Мировой рейтинг",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки 😢\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Пока никого нет 😢',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          int? currentUserIndex;
          Map<String, dynamic>? currentUserData;
          if (currentUserId != null) {
            for (int i = 0; i < docs.length; i++) {
              if (docs[i].id == currentUserId) {
                currentUserIndex = i;
                currentUserData = docs[i].data();
                break;
              }
            }
          }

          int totalGamesAll = 0;
          for (final doc in docs) {
            totalGamesAll += (doc.data()['totalGames'] ?? 0) as int;
          }

          return Column(
            children: [
              _StatsHeader(
                totalPlayers: docs.length,
                totalGames: totalGamesAll,
                currentUserRank:
                currentUserIndex != null ? currentUserIndex + 1 : null,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final docId = docs[index].id;
                    final data = docs[index].data();
                    return LeaderboardTile(
                      player: data,
                      index: index,
                      isCurrentUser: docId == currentUserId,
                    );
                  },
                ),
              ),
              if (currentUserData != null &&
                  (currentUserIndex == null || currentUserIndex >= 10))
                _StickyCurrentUser(
                  data: currentUserData,
                  rank: currentUserIndex != null
                      ? currentUserIndex + 1
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int totalPlayers;
  final int totalGames;
  final int? currentUserRank;

  const _StatsHeader({
    required this.totalPlayers,
    required this.totalGames,
    this.currentUserRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Игроков', value: '$totalPlayers'),
          _VerticalDivider(),
          _StatChip(label: 'Игр сыграно', value: '$totalGames'),
          if (currentUserRank != null) ...[
            _VerticalDivider(),
            _StatChip(
              label: 'Ваш ранг',
              value: '#$currentUserRank',
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color:
            highlight ? const Color(0xFFF97316) : const Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: Colors.white12);
  }
}

class _StickyCurrentUser extends StatelessWidget {
  final Map<String, dynamic> data;
  final int? rank;

  const _StickyCurrentUser({required this.data, this.rank});

  @override
  Widget build(BuildContext context) {
    final name =
    (data['displayName'] ?? data['name'] ?? 'Вы').toString();
    final rating = data['rating'] ?? 0;
    final total = data['totalGames'] ?? 0;
    final wins = data['wins'] ?? 0;
    final winRate =
    total > 0 ? ((wins / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B35),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFFF97316).withOpacity(0.25),
            const Color(0xFF0F172A),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF97316).withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              rank != null ? '#$rank' : '—',
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFFF97316),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Игр: $total  •  Побед: $winRate%',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '$rating',
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}