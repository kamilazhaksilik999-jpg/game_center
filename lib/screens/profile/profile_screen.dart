import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:convert';

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
    '😊','😎','🦊','🐱','🎮','🦁','🐺','🤖','👾','🎯',
    '🐸','🐼','🦄','🐲','👻','🤡','🦅','🐯','🦸','🧙',
  ];
  String _selectedAvatar = '😊';
  final _nameController = TextEditingController();
  final _friendIdController = TextEditingController();

  // Стоимость повышения ранга
  final Map<String, int> _rankUpgradeCost = {
    'Новичок': 500,
    'Медиум': 1500,
    'Профи': 3000,
  };
  final List<String> _rankOrder = ['Новичок', 'Медиум', 'Профи', 'Легенда'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _friendIdController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 🔥 ЗАГРУЗКА
  // ══════════════════════════════════════════
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('user_id');

    if (savedId != null) {
      try {
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

  // ══════════════════════════════════════════
  // 🔥 РЕГИСТРАЦИЯ
  // ══════════════════════════════════════════
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
      'avatarImage': null,
      'friends': [],
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);

    setState(() {
      _userId = uid;
      _userData = data;
      _isRegistered = true;
      _isLoading = false;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({...data, 'createdAt': FieldValue.serverTimestamp()})
        .catchError((e) => debugPrint('Firestore error: $e'));
  }

  // ══════════════════════════════════════════
  // ✏️ ИЗМЕНЕНИЕ ИМЕНИ
  // ══════════════════════════════════════════
  Future<void> _editName() async {
    _nameController.text = _userData?['name'] ?? '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Изменить имя',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Новое имя',
            hintStyle: const TextStyle(color: Colors.white38),
            counterStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isEmpty) return;

              setState(() {
                _userData!['name'] = newName;
              });

              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .update({'name': newName});

              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🖼️ ИЗМЕНЕНИЕ АВАТАРА
  // ══════════════════════════════════════════
  Future<void> _changeAvatar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выбери аватар',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Кнопка загрузки фото
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Загрузить фото из галереи'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _pickImageFromGallery();
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Text('или выбери эмодзи',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),

              // Сетка эмодзи
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _avatars.map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _userData!['avatar'] = emoji;
                        _userData!['avatarImage'] = null;
                      });
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_userId)
                          .update({'avatar': emoji, 'avatarImage': null});
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _userData!['avatarImage'] = base64Image;
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'avatarImage': base64Image});
    } catch (e) {
      debugPrint('Image error: $e');
    }
  }

  // ══════════════════════════════════════════
  // 🏆 ПОВЫШЕНИЕ РАНГА ЗА МОНЕТЫ
  // ══════════════════════════════════════════
  Future<void> _upgradeRank() async {
    final currentRank = _userData?['rank'] ?? 'Новичок';
    final currentIndex = _rankOrder.indexOf(currentRank);

    if (currentIndex >= _rankOrder.length - 1) {
      _showSnack('Ты и так на максимальном ранге! 👑');
      return;
    }

    final nextRank = _rankOrder[currentIndex + 1];
    final cost = _rankUpgradeCost[currentRank] ?? 999999;
    final coins = _userData?['coins'] ?? 0;

    if (coins < cost) {
      _showSnack('Недостаточно монет! Нужно $cost 🪙');
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text('Повысить ранг до $nextRank?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'Стоимость: $cost 🪙\nТвои монеты: $coins 🪙',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final newCoins = coins - cost;
              setState(() {
                _userData!['rank'] = nextRank;
                _userData!['coins'] = newCoins;
              });

              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .update({'rank': nextRank, 'coins': newCoins});

              Navigator.pop(context);
              _showSnack('Ранг повышен до $nextRank! 🎉');
            },
            child: const Text('Купить'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 👥 ДОБАВЛЕНИЕ ДРУГА
  // ══════════════════════════════════════════
  Future<void> _addFriend() async {
    _friendIdController.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Добавить друга',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _friendIdController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введи ID друга (например: 4821)',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixText: '#',
            prefixStyle: const TextStyle(color: Colors.orange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(context);
              await _searchAndAddFriend('#${_friendIdController.text.trim()}');
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndAddFriend(String friendId) async {
    if (friendId == _userData?['id']) {
      _showSnack('Нельзя добавить себя 😅');
      return;
    }

    final List friends = List.from(_userData?['friends'] ?? []);
    if (friends.any((f) => f['id'] == friendId)) {
      _showSnack('Этот игрок уже в друзьях!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: friendId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _isLoading = false);
        _showSnack('Игрок не найден 😔');
        return;
      }

      final foundUser = query.docs.first.data();
      final newFriend = {
        'id': foundUser['id'],
        'name': foundUser['name'],
        'avatar': foundUser['avatar'] ?? '😊',
        'online': false,
      };

      friends.add(newFriend);

      setState(() {
        _userData!['friends'] = friends;
        _isLoading = false;
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'friends': friends});

      _showSnack('${foundUser['name']} добавлен в друзья! 🎉');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Ошибка поиска');
    }
  }

  // ══════════════════════════════════════════
  // ❌ УДАЛЕНИЕ ДРУГА
  // ══════════════════════════════════════════
  Future<void> _removeFriend(String friendId, String friendName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Удалить друга?',
            style: TextStyle(color: Colors.white)),
        content: Text('$friendName будет удалён из друзей',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final List friends = List.from(_userData?['friends'] ?? []);
    friends.removeWhere((f) => f['id'] == friendId);

    setState(() {
      _userData!['friends'] = friends;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .update({'friends': friends});

    _showSnack('$friendName удалён из друзей');
  }

  // ══════════════════════════════════════════
  // 🔴 ВЫХОД
  // ══════════════════════════════════════════
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    setState(() {
      _isRegistered = false;
      _userData = null;
      _userId = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF16213E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🏗️ BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
            child: CircularProgressIndicator(color: Colors.orange)),
      );
    }
    if (!_isRegistered) return _buildRegistrationScreen();
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
              const Text('Создай профиль',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Выбери аватар и введи имя',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
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
                spacing: 10,
                runSpacing: 10,
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
                  prefixIcon:
                  const Icon(Icons.person, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Создать профиль',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
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
    final String? avatarImage = data['avatarImage'];
    final List friends = data['friends'] ?? [];

    final currentRankIndex = _rankOrder.indexOf(rank);
    final isMaxRank = currentRankIndex >= _rankOrder.length - 1;
    final nextRank = isMaxRank ? null : _rankOrder[currentRankIndex + 1];
    final upgradeCost = isMaxRank ? null : _rankUpgradeCost[rank];

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
                  colors: [
                    Color(0xFF833AB4),
                    Color(0xFFE1306C),
                    Color(0xFFFD1D1D)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [

                  // Кликабельный аватар
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.shade300,
                          ),
                          child: ClipOval(
                            child: avatarImage != null
                                ? Image.memory(
                              base64Decode(avatarImage),
                              fit: BoxFit.cover,
                            )
                                : Center(
                                child: Text(avatar,
                                    style:
                                    const TextStyle(fontSize: 46))),
                          ),
                        ),
                        // Иконка редактирования
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Кликабельное имя
                  GestureDetector(
                    onTap: _editName,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit,
                            size: 14, color: Colors.white60),
                      ],
                    ),
                  ),

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

            // ══════════ ПОВЫШЕНИЕ РАНГА ══════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMaxRank
                                ? '👑 Максимальный ранг!'
                                : 'Следующий ранг: $nextRank',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          if (!isMaxRank)
                            Text(
                              'Стоимость: $upgradeCost 🪙 (у тебя: $coins 🪙)',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (!isMaxRank)
                      ElevatedButton(
                        onPressed: coins >= (upgradeCost ?? 0)
                            ? _upgradeRank
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          disabledBackgroundColor:
                          Colors.grey.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Купить',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),

            // ══════════ ЖЕТОНЫ ══════════
            _buildSection('ЖЕТОНЫ', _buildBadges(rank)),

            // ══════════ ДРУЗЬЯ ══════════
            _buildSection(
              'ДРУЗЬЯ',
              _buildFriends(friends),
              action: TextButton.icon(
                onPressed: _addFriend,
                icon: const Icon(Icons.person_add,
                    size: 16, color: Colors.blue),
                label: const Text('Добавить',
                    style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
            ),

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
          Text(icons[rank] ?? '🏅',
              style: const TextStyle(fontSize: 16)),
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
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style:
            const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 36, color: Colors.white12);

  Widget _buildSection(String title, Widget content, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      letterSpacing: 1.2)),
              if (action != null) action,
            ],
          ),
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
    final currentIndex = _rankOrder.indexOf(currentRank);

    return Row(
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
                  ? Border.all(
                  color: color.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                Text(badge['icon'] as String,
                    style: TextStyle(
                        fontSize: 28,
                        color: unlocked ? null : Colors.black45)),
                const SizedBox(height: 6),
                Text(badge['title'] as String,
                    style: TextStyle(
                        color:
                        unlocked ? Colors.white : Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  unlocked ? '✓ Получен' : '🔒 Закрыт',
                  style: TextStyle(
                      color: unlocked
                          ? Colors.greenAccent
                          : Colors.white24,
                      fontSize: 9),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFriends(List friends) {
    if (friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('Пока нет друзей 😔\nДобавь первого!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: friends.map<Widget>((f) {
          final name = f['name'] ?? 'Player';
          final fId = f['id'] ?? '';
          final fAvatar = f['avatar'] ?? '😊';
          final isOnline = f['online'] ?? false;

          // Инициалы для аватара
          final initials = name.length >= 2
              ? name.substring(0, 2).toUpperCase()
              : name.toUpperCase();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[
              name.hashCode % Colors.primaries.length],
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            title: Text(name,
                style: const TextStyle(color: Colors.white)),
            subtitle: Row(
              children: [
                Icon(Icons.circle,
                    size: 8,
                    color: isOnline
                        ? Colors.greenAccent
                        : Colors.white38),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Онлайн' : 'Не в сети',
                  style: TextStyle(
                      color: isOnline
                          ? Colors.greenAccent
                          : Colors.white38,
                      fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOnline)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Играть',
                        style: TextStyle(fontSize: 11)),
                  ),
                const SizedBox(width: 6),
                // Кнопка удаления
                GestureDetector(
                  onTap: () => _removeFriend(fId, name),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}