import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isRegistered = false;
  Map<String, dynamic>? _userData;
  String? _userId;

  final List<String> _avatars = [
    '😊', '😎', '🦊', '🐱', '🎮', '🦁', '🐺', '🤖', '👾', '🎯'
  ];
  String _selectedAvatar = '😊';

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // 🔥 Загрузка пользователя — сначала кэш, потом сеть
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('user_id');

    if (savedId != null) {
      try {
        // ✅ Сначала из кэша — мгновенно
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(savedId)
            .get(const GetOptions(source: Source.cache));

        if (doc.exists) {
          setState(() {
            _userId = savedId;
            _userData = doc.data();
            _isRegistered = true;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {
        // Кэша нет — идём в сеть
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(savedId)
              .get();

          if (doc.exists) {
            setState(() {
              _userId = savedId;
              _userData = doc.data();
              _isRegistered = true;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          debugPrint('Firestore error: $e');
        }
      }
    }

    setState(() {
      _isLoading = false;
      _isRegistered = false;
    });
  }

  // 🔥 Регистрация — мгновенно показываем профиль, Firebase в фоне
  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    final id = (1000 + Random().nextInt(9000)).toString();
    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'name': name,
      'id': '#$id',
      'coins': 0,
      'wins': 0,
      'gamesPlayed': 0,
      'rank': 'Новичок',
      'avatar': _selectedAvatar,
      'friends': [],
    };

    // ✅ 1. Сохраняем локально — МГНОВЕННО
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);

    // ✅ 2. Сразу показываем профиль — БЕЗ ОЖИДАНИЯ FIREBASE
    setState(() {
      _userId = uid;
      _userData = data;
      _isRegistered = true;
      _isLoading = false;
    });

    // ✅ 3. Пишем в Firestore В ФОНЕ — не блокируем UI
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({...data, 'createdAt': FieldValue.serverTimestamp()})
        .catchError((e) => debugPrint('Firestore error: $e'));
  }

  // 🔥 Выйти из аккаунта
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    setState(() {
      _isRegistered = false;
      _userData = null;
      _userId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (!_isRegistered) {
      return _buildRegistrationScreen();
    }

    return _buildProfileScreen();
  }

  // ══════════════════════════════════════════
  // 📋 ЭКРАН РЕГИСТРАЦИИ
  // ══════════════════════════════════════════
  Widget _buildRegistrationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              const Text(
                'Создай профиль',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выбери аватар и введи имя',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // Выбранный аватар
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)],
                  ),
                ),
                child: Center(
                  child: Text(_selectedAvatar,
                      style: const TextStyle(fontSize: 44)),
                ),
              ),

              const SizedBox(height: 24),

              // Сетка аватаров
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _avatars.map((emoji) {
                  final isSelected = emoji == _selectedAvatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = emoji),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        border: isSelected
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Поле имени
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: 'Твой никнейм',
                  hintStyle: const TextStyle(color: Colors.white38),
                  counterStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white54),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка регистрации
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Создать профиль',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 👤 ЭКРАН ПРОФИЛЯ
  // ══════════════════════════════════════════
  Widget _buildProfileScreen() {
    final data = _userData!;
    final String name = data['name'] ?? 'Player';
    final String id = data['id'] ?? '#0000';
    final int coins = data['coins'] ?? 0;
    final int wins = data['wins'] ?? 0;
    final int games = data['gamesPlayed'] ?? 0;
    final String rank = data['rank'] ?? 'Новичок';
    final String avatar = data['avatar'] ?? '😊';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ══════════ ШАПКА ══════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFFD1D1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.shade300,
                    ),
                    child: Center(
                      child: Text(avatar,
                          style: const TextStyle(fontSize: 46)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('ID: $id',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 10),
                  _buildRankBadge(rank),
                ],
              ),
            ),

            // ══════════ СТАТИСТИКА ══════════
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('$coins', 'монет', Colors.yellow),
                  _buildDivider(),
                  _buildStat('$wins', 'побед', Colors.greenAccent),
                  _buildDivider(),
                  _buildStat('$games', 'игр сыграно', Colors.lightBlueAccent),
                ],
              ),
            ),

            // ══════════ ЖЕТОНЫ ══════════
            _buildSection('ЖЕТОНЫ', _buildBadges(rank)),

            // ══════════ ДРУЗЬЯ ══════════
            _buildSection('ДРУЗЬЯ', _buildFriends()),

            const SizedBox(height: 16),

            // ══════════ ВЫЙТИ ══════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF16213E),
                      title: const Text('Выйти?',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Данные профиля сохранятся',
                          style: TextStyle(color: Colors.white54)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          child: const Text('Выйти',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Выйти из профиля',
                    style: TextStyle(color: Colors.red.shade300)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🧩 ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
  // ══════════════════════════════════════════

  Widget _buildRankBadge(String rank) {
    final colors = {
      'Новичок': Colors.green,
      'Медиум': Colors.orange,
      'Профи': Colors.blue,
      'Легенда': Colors.purple,
    };
    final icons = {
      'Новичок': '🥇',
      'Медиум': '🥈',
      'Профи': '🏆',
      'Легенда': '👑',
    };
    final color = colors[rank] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icons[rank] ?? '🏅', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(rank,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: Colors.white12);
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildBadges(String currentRank) {
    final badges = [
      {'title': 'Новичок', 'icon': '🥇', 'color': Colors.green},
      {'title': 'Медиум', 'icon': '🥈', 'color': Colors.orange},
      {'title': 'Профи', 'icon': '🏆', 'color': Colors.blue},
      {'title': 'Легенда', 'icon': '👑', 'color': Colors.purple},
    ];

    final rankOrder = ['Новичок', 'Медиум', 'Профи', 'Легенда'];
    final currentIndex = rankOrder.indexOf(currentRank);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: badges.asMap().entries.map((entry) {
        final i = entry.key;
        final badge = entry.value;
        final unlocked = i <= currentIndex;
        final color = badge['color'] as Color;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: unlocked
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                Text(badge['icon'] as String,
                    style: TextStyle(
                        fontSize: 28,
                        color: unlocked ? null : Colors.black)),
                const SizedBox(height: 6),
                Text(badge['title'] as String,
                    style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  unlocked ? '✓ Получен' : '🔒 Закрыт',
                  style: TextStyle(
                      color: unlocked ? Colors.greenAccent : Colors.white24,
                      fontSize: 9),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFriends() {
    final friends = [
      {'name': 'Amir_M', 'initials': 'AM', 'online': true, 'color': Colors.teal},
      {'name': 'Dana_S', 'initials': 'ДС', 'online': false, 'color': Colors.purple},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: friends.map((f) {
          final isOnline = f['online'] as bool;
          final color = f['color'] as Color;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(f['initials'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            title: Text(f['name'] as String,
                style: const TextStyle(color: Colors.white)),
            subtitle: Row(
              children: [
                Icon(Icons.circle,
                    size: 8,
                    color: isOnline ? Colors.greenAccent : Colors.white38),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Онлайн' : 'Не в сети',
                  style: TextStyle(
                      color: isOnline ? Colors.greenAccent : Colors.white38,
                      fontSize: 12),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: isOnline ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline ? Colors.blue : Colors.transparent,
                foregroundColor: isOnline ? Colors.white : Colors.white38,
                side: isOnline
                    ? null
                    : const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isOnline ? 'Играть' : 'Оффлайн',
                  style: const TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}