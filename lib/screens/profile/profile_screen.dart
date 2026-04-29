import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friend_service.dart';
import '../../core/services/notification_service.dart';
import '../friends/friends_screen.dart';
import '../friends/user_profile_screen.dart';
import '../chat/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _userId;

  final _authService = AuthService();
  final _friendService = FriendService();
  final _notifService = NotificationService();

  late TabController _tabController;

  final List<String> _avatars = [
    '😊','😎','🦊','🐱','🎮','🦁','🐺','🤖','👾','🎯',
    '🐸','🐼','🦄','🐲','👻','🤩','🦸','🧙','🥷','🎭',
  ];

  final _nameController = TextEditingController();
  final _friendIdController = TextEditingController();

  final List<String> _rankOrder = ['Новичок', 'Медиум', 'Профи', 'Легенда'];
  final Map<String, int> _rankCost = {
    'Новичок': 500,
    'Медиум': 1500,
    'Профи': 3000,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _friendIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _userId = user.uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = Map<String, dynamic>.from(doc.data()!);
        if (!data.containsKey('coins')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'coins': 100});
          data['coins'] = 100;
        }
        if (!data.containsKey('leaderboardEligible')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'leaderboardEligible': false});
          data['leaderboardEligible'] = false;
        }
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Firestore error: $e');
      setState(() => _isLoading = false);
    }
  }

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
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Новое имя',
            hintStyle: const TextStyle(color: Colors.white38),
            counterStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isEmpty) return;
              setState(() => _userData!['name'] = newName);
              Navigator.pop(context);
              if (_userId != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_userId)
                    .update({'name': newName});
              }
              _showSnack('Имя сохранено ✅');
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeAvatar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _avatars.map((emoji) {
                return GestureDetector(
                  onTap: () async {
                    setState(() => _userData!['avatar'] = emoji);
                    Navigator.pop(context);
                    if (_userId != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_userId)
                          .update({'avatar': emoji});
                    }
                    _showSnack('Аватар изменён ✅');
                  },
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 28))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _upgradeRank() async {
    final rank = _userData?['rank'] ?? 'Новичок';
    final idx = _rankOrder.indexOf(rank);
    if (idx >= _rankOrder.length - 1) {
      _showSnack('Ты уже на максимальном ранге! 👑');
      return;
    }
    final nextRank = _rankOrder[idx + 1];
    final cost = _rankCost[rank] ?? 9999;
    final coins = _userData?['coins'] ?? 0;
    if (coins < cost) {
      _showSnack('Нужно $cost 🪙, у тебя только $coins 🪙');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text('Повысить до $nextRank?',
            style: const TextStyle(color: Colors.white)),
        content: Text('Спишется $cost 🪙\nОстаток: ${coins - cost} 🪙',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Купить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final newCoins = coins - cost;
    setState(() {
      _userData!['rank'] = nextRank;
      _userData!['coins'] = newCoins;
    });
    if (_userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'rank': nextRank, 'coins': newCoins});
    }
    _showSnack('Ранг повышен до $nextRank! 🎉');
  }

  Future<void> _logout() async {
    await _authService.logout();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF16213E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
            child: Text('Ошибка загрузки профиля',
                style: TextStyle(color: Colors.white))),
      );
    }
    return _buildProfileScreen();
  }

  Widget _buildProfileScreen() {
    final data = _userData!;
    final String name = data['name'] ?? 'Player';
    final String id = data['id'] ?? '#0000';
    final int coins = data['coins'] ?? 0;
    final int wins = data['wins'] ?? 0;
    final int games = data['gamesPlayed'] ?? 0;
    final String rank = data['rank'] ?? 'Новичок';
    final String avatar = data['avatar'] ?? '😊';

    final rankIdx = _rankOrder.indexOf(rank);
    final isMax = rankIdx >= _rankOrder.length - 1;
    final nextRank = isMax ? null : _rankOrder[rankIdx + 1];
    final cost = isMax ? null : _rankCost[rank];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Шапка ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFFD1D1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange.shade300,
                              ),
                              child: Center(
                                  child: Text(avatar,
                                      style: const TextStyle(fontSize: 46))),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange),
                                child: const Icon(Icons.edit,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      _rankBadge(rank),
                    ],
                  ),
                ),

                // ── Статистика ──
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
                      _stat('$coins', 'монет', Colors.yellow),
                      _divider(),
                      _stat('$wins', 'побед', Colors.greenAccent),
                      _divider(),
                      _stat('$games', 'игр', Colors.lightBlueAccent),
                    ],
                  ),
                ),

                // ── TabBar ──
                Container(
                  color: const Color(0xFF16213E),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.orange,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      const Tab(text: 'Профиль'),
                      // Друзья с счётчиком заявок
                      StreamBuilder<QuerySnapshot>(
                        stream: _friendService.incomingRequestsStream(),
                        builder: (context, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Друзья'),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 18, height: 18,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red),
                                    child: Center(
                                      child: Text('$count',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      // Уведомления с счётчиком
                      StreamBuilder<int>(
                        stream: _notifService.unreadCountStream(),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Уведомления'),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 18, height: 18,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Вкладка 1: Профиль ──
            _buildProfileTab(rank, coins, cost, isMax, nextRank),
            // ── Вкладка 2: Друзья ──
            _buildFriendsTab(),
            // ── Вкладка 3: Уведомления ──
            _buildNotificationsTab(),
          ],
        ),
      ),
    );
  }

  // ══════ ВКЛАДКА ПРОФИЛЬ ══════
  Widget _buildProfileTab(String rank, int coins, int? cost,
      bool isMax, String? nextRank) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          // Повышение ранга
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(14),
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
                          isMax ? '👑 Максимальный ранг!' : 'Следующий: $nextRank',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        if (!isMax)
                          Text('Стоимость: $cost 🪙',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!isMax)
                    ElevatedButton(
                      onPressed: coins >= (cost ?? 0) ? _upgradeRank : null,
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

          // Жетоны
          _section('ЖЕТОНЫ', _badges(rank)),

          const SizedBox(height: 24),

          // Выйти
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF16213E),
                  title: const Text('Выйти?',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Данные сохранятся',
                      style: TextStyle(color: Colors.white54)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена')),
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
              ),
              child: Text('Выйти из профиля',
                  style: TextStyle(color: Colors.red.shade300)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════ ВКЛАДКА ДРУЗЬЯ ══════
  Widget _buildFriendsTab() {
    final myUid = _userId ?? '';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1A1A2E),
            child: const TabBar(
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'Друзья'),
                Tab(text: 'Заявки'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Список друзей
                StreamBuilder<QuerySnapshot>(
                  stream: _friendService.friendsStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.orange));
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Пока нет друзей 😔',
                            style: TextStyle(color: Colors.white54)),
                      );
                    }
                    return ListView.builder(
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, i) {
                        final doc = snap.data!.docs[i];
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final users =
                        List<String>.from(data['users'] ?? []);
                        final friendUid = users.firstWhere(
                                (u) => u != myUid,
                            orElse: () => '');
                        if (friendUid.isEmpty) return const SizedBox();

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(friendUid)
                              .snapshots(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) return const SizedBox();
                            final ud = userSnap.data!.data()
                            as Map<String, dynamic>? ?? {};
                            final name = ud['name'] ?? 'Player';
                            final avatar = ud['avatar'] ?? '😊';
                            final status = ud['status'] ?? 'offline';
                            final isOnline = status == 'online';

                            return ListTile(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(
                                        uid: friendUid)),
                              ),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                    Colors.deepPurple.shade300,
                                    child: Text(avatar,
                                        style: const TextStyle(
                                            fontSize: 22)),
                                  ),
                                  Positioned(
                                    right: 0, bottom: 0,
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        border: Border.all(
                                            color: const Color(0xFF1A1A2E),
                                            width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                isOnline ? 'онлайн' : 'оффлайн',
                                style: TextStyle(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.white38,
                                    fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Написать
                                  IconButton(
                                    icon: const Icon(Icons.message,
                                        color: Colors.blue, size: 20),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                              otherUid: friendUid)),
                                    ),
                                  ),
                                  // Удалить
                                  IconButton(
                                    icon: const Icon(Icons.person_remove,
                                        color: Colors.red, size: 20),
                                    onPressed: () async {
                                      await _friendService
                                          .removeFriend(friendUid);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // Входящие заявки
                StreamBuilder<QuerySnapshot>(
                  stream: _friendService.incomingRequestsStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.orange));
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Нет входящих заявок',
                            style: TextStyle(color: Colors.white54)),
                      );
                    }
                    return ListView.builder(
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, i) {
                        final doc = snap.data!.docs[i];
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final fromUid = data['fromUid'] as String;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(fromUid)
                              .get(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) return const SizedBox();
                            final ud = userSnap.data!.exists
                                ? userSnap.data!.data()
                            as Map<String, dynamic>
                                : <String, dynamic>{};
                            final name = ud['name'] ?? 'Player';
                            final avatar = ud['avatar'] ?? '😊';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                Colors.deepPurple.shade300,
                                child: Text(avatar,
                                    style:
                                    const TextStyle(fontSize: 22)),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      color: Colors.white)),
                              subtitle: const Text('Хочет добавить тебя',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () => _friendService
                                        .acceptRequest(fromUid),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                    onPressed: () => _friendService
                                        .declineRequest(fromUid),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Кнопка поиска друга
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showSearchFriend,
                icon: const Icon(Icons.person_search),
                label: const Text('Найти игрока по ID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchFriend() async {
    _friendIdController.clear();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Найти игрока',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _friendIdController,
          style: const TextStyle(color: Colors.white, letterSpacing: 2),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введи ID игрока',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            prefixText: '#',
            prefixStyle: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              final input = _friendIdController.text.trim();
              if (input.isEmpty) return;
              Navigator.pop(context);
              final user = await _friendService
                  .findUserById('#$input');
              if (!mounted) return;
              if (user == null) {
                _showSnack('Игрок не найден 😔');
                return;
              }
              if (user['uid'] == _userId) {
                _showSnack('Это ты 😅');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        UserProfileScreen(uid: user['uid'])),
              );
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  // ══════ ВКЛАДКА УВЕДОМЛЕНИЯ ══════
  Widget _buildNotificationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _notifService.markAllRead,
                child: const Text('Все прочитано',
                    style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _notifService.notificationsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.orange));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Нет уведомлений',
                      style: TextStyle(color: Colors.white54)),
                );
              }

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snap.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] ?? '';
                  final fromUid = data['fromUid'] ?? '';
                  final text = data['text'] ?? '';
                  final read = data['read'] ?? false;
                  final time =
                  (data['createdAt'] as Timestamp?)?.toDate();

                  IconData icon;
                  Color color;
                  switch (type) {
                    case 'friend_request':
                      icon = Icons.person_add;
                      color = Colors.blue;
                      break;
                    case 'friend_accepted':
                      icon = Icons.people;
                      color = Colors.green;
                      break;
                    case 'game_invite':
                      icon = Icons.sports_esports;
                      color = Colors.purple;
                      break;
                    case 'message':
                      icon = Icons.message;
                      color = Colors.orange;
                      break;
                    default:
                      icon = Icons.notifications;
                      color = Colors.white;
                  }

                  return Container(
                    color: read
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.05),
                    child: ListTile(
                      onTap: () async {
                        await _notifService.markRead(doc.id);
                        if (type == 'friend_request') {
                          await _friendService.acceptRequest(fromUid);
                          _showSnack('Заявка принята ✅');
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(fromUid)
                            .get(),
                        builder: (context, userSnap) {
                          String name = '...';
                          if (userSnap.hasData &&
                              userSnap.data!.exists) {
                            final ud = userSnap.data!.data();
                            if (ud != null) {
                              name = (ud as Map<String, dynamic>)[
                              'name'] ??
                                  'Player';
                            }
                          }
                          return Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold));
                        },
                      ),
                      subtitle: Text(text,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!read)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange),
                            ),
                          if (time != null)
                            Text(
                              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rankBadge(String rank) {
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
      'Легенда': '👑'
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

  Widget _stat(String v, String l, Color c) => Column(children: [
    Text(v,
        style: TextStyle(
            color: c, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(l,
        style:
        const TextStyle(color: Colors.white38, fontSize: 12)),
  ]);

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white12);

  Widget _section(String title, Widget content, {Widget? action}) {
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

  Widget _badges(String rank) {
    final list = [
      {'t': 'Новичок', 'i': '🥇', 'c': Colors.green},
      {'t': 'Медиум', 'i': '🥈', 'c': Colors.orange},
      {'t': 'Профи', 'i': '🏆', 'c': Colors.blue},
      {'t': 'Легенда', 'i': '👑', 'c': Colors.purple},
    ];
    final idx = _rankOrder.indexOf(rank);
    return Row(
      children: list.asMap().entries.map((e) {
        final unlocked = e.key <= idx;
        final color = e.value['c'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                Text(e.value['i'] as String,
                    style: TextStyle(
                        fontSize: 26,
                        color: unlocked ? null : Colors.black45)),
                const SizedBox(height: 4),
                Text(e.value['t'] as String,
                    style: TextStyle(
                        color:
                        unlocked ? Colors.white : Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(unlocked ? '✓ Получен' : '🔒 Закрыт',
                    style: TextStyle(
                        color: unlocked
                            ? Colors.greenAccent
                            : Colors.white24,
                        fontSize: 8)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}