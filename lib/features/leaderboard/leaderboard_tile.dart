import 'package:flutter/material.dart';

class LeaderboardTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final int index;
  final bool isCurrentUser;

  const LeaderboardTile({
    super.key,
    required this.player,
    required this.index,
    this.isCurrentUser = false,
  });

  Color get _medalColor {
    if (index == 0) return const Color(0xFFFBBF24);
    if (index == 1) return const Color(0xFF94A3B8);
    if (index == 2) return const Color(0xFFD97706);
    return const Color(0xFF334155);
  }

  String get _medal {
    if (index == 0) return '🥇';
    if (index == 1) return '🥈';
    if (index == 2) return '🥉';
    return '#${index + 1}';
  }

  String get _initials {
    final name =
    (player['displayName'] ?? player['name'] ?? 'P').toString().trim();
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name =
    (player['displayName'] ?? player['name'] ?? 'Игрок').toString();
    final rating = player['rating'] ?? 0;
    final wins = player['wins'] ?? 0;
    final total = player['totalGames'] ?? 0;
    final winStreak = player['winStreak'] ?? 0;
    final lastChange = player['lastRatingChange'] ?? 0;
    final winRate =
    total > 0 ? ((wins / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentUser
              ? [
            const Color(0xFFF97316).withOpacity(0.2),
            const Color(0xFF0F172A)
          ]
              : index == 0
              ? [
            const Color(0xFFFBBF24).withOpacity(0.18),
            const Color(0xFF0F172A)
          ]
              : index == 1
              ? [
            const Color(0xFF94A3B8).withOpacity(0.14),
            const Color(0xFF0F172A)
          ]
              : index == 2
              ? [
            const Color(0xFFD97706).withOpacity(0.14),
            const Color(0xFF0F172A)
          ]
              : [
            const Color(0xFF1E293B),
            const Color(0xFF020617)
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFF97316).withOpacity(0.8)
              : _medalColor.withOpacity(index < 3 ? 0.5 : 0.2),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? const Color(0xFFF97316).withOpacity(0.15)
                : _medalColor.withOpacity(index < 3 ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Медаль / номер
          SizedBox(
            width: 42,
            child: Center(
              child: index < 3
                  ? Text(_medal, style: const TextStyle(fontSize: 22))
                  : Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Аватар
          CircleAvatar(
            radius: 22,
            backgroundColor: isCurrentUser
                ? const Color(0xFFF97316).withOpacity(0.3)
                : _medalColor.withOpacity(0.2),
            child: Text(
              _initials,
              style: TextStyle(
                color:
                isCurrentUser ? const Color(0xFFF97316) : _medalColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Имя + статистика
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrentUser
                              ? const Color(0xFFF97316)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Вы',
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (winStreak >= 3) ...[
                      const SizedBox(width: 5),
                      Text(
                        '🔥$winStreak',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Игр: $total  •  Побед: $winRate%  •  W: $wins',
                  style:
                  const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),

          // Рейтинг + изменение
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$rating',
                style: TextStyle(
                  color: isCurrentUser
                      ? const Color(0xFFF97316)
                      : _medalColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lastChange != 0)
                Text(
                  lastChange > 0 ? '+$lastChange' : '$lastChange',
                  style: TextStyle(
                    color: lastChange > 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'rating',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}