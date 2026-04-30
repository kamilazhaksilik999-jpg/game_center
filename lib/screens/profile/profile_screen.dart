import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friend_service.dart';
import '../../core/services/notification_service.dart';
import '../friends/friends_screen.dart';
import '../friends/user_profile_screen.dart';
import '../chat/chat_screen.dart';

// ─── Цвета темы ───────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF0D0D1A);
const _kCard      = Color(0xFF16213E);
const _kCardDark  = Color(0xFF0F1829);
const _kAccent    = Color(0xFF00C896);
const _kAccentRed = Color(0xFFEF5B5B);
const _kTextMuted = Color(0xFF8888AA);
const _kBorder    = Color(0xFF2A2A4A);

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
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kAccent, width: 1)),
        title: const Text('Изменить имя',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          maxLength: 20,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Новое имя',
            hintStyle: const TextStyle(color: _kTextMuted),
            counterStyle: const TextStyle(color: _kTextMuted),
            filled: true,
            fillColor: _kCardDark,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kAccent, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kBorder, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kAccent, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена',
                  style: TextStyle(color: _kTextMuted))),
          _NeonButton(
            label: 'Сохранить',
            onTap: () async {
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
          ),
        ],
      ),
    );
  }

  Future<void> _changeAvatar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Выбери аватар',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _avatars.map((emoji) {
                final isSelected = _userData?['avatar'] == emoji;
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
                      color: isSelected
                          ? _kAccent.withOpacity(0.2)
                          : _kCardDark,
                      border: Border.all(
                          color: isSelected ? _kAccent : _kBorder,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 26))),
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
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kAccent, width: 1)),
        title: Text('Повысить до $nextRank?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Спишется $cost 🪙\nОстаток: ${coins - cost} 🪙',
            style: const TextStyle(color: _kTextMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена',
                  style: TextStyle(color: _kTextMuted))),
          _NeonButton(
            label: 'Купить',
            onTap: () => Navigator.pop(context, true),
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
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: _kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _kAccent, width: 1)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    }
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
            child: Text('Ошибка загрузки профиля',
                style: TextStyle(color: Colors.white))),
      );
    }
    return _buildProfileScreen();
  }

  Widget _buildProfileScreen() {
    final data = _userData!;
    final String name   = data['name']        ?? 'Player';
    final String id     = data['id']          ?? '#0000';
    final int coins     = data['coins']       ?? 0;
    final int wins      = data['wins']        ?? 0;
    final int games     = data['gamesPlayed'] ?? 0;
    final String rank   = data['rank']        ?? 'Новичок';
    final String avatar = data['avatar']      ?? '😊';

    final rankIdx = _rankOrder.indexOf(rank);
    final isMax   = rankIdx >= _rankOrder.length - 1;
    final nextRank = isMax ? null : _rankOrder[rankIdx + 1];
    final cost    = isMax ? null : _rankCost[rank];

    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Шапка ──────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 56, bottom: 24),
                  decoration: BoxDecoration(
                    color: _kCardDark,
                    border: const Border(
                        bottom: BorderSide(color: _kBorder, width: 1)),
                    boxShadow: [
                      BoxShadow(
                          color: _kAccent.withOpacity(0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Кнопка назад
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: _kTextMuted, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      // Аватар
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kCard,
                                border: Border.all(
                                    color: _kAccent, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: _kAccent.withOpacity(0.25),
                                      blurRadius: 20,
                                      spreadRadius: 2),
                                ],
                              ),
                              child: Center(
                                  child: Text(avatar,
                                      style: const TextStyle(fontSize: 44))),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kAccent,
                                    border: Border.all(
                                        color: _kBg, width: 2)),
                                child: const Icon(Icons.edit,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Имя
                      GestureDetector(
                        onTap: _editName,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit,
                                size: 14, color: _kTextMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: $id',
                          style: const TextStyle(
                              color: _kTextMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      _rankBadge(rank),
                    ],
                  ),
                ),

                // ── Статистика ─────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('$coins', 'монет', const Color(0xFFFFD700)),
                      _divider(),
                      _stat('$wins', 'побед', _kAccent),
                      _divider(),
                      _stat('$games', 'игр', const Color(0xFF5B8DEF)),
                    ],
                  ),
                ),

                // ── TabBar ─────────────────────────────────────────────────
                const SizedBox(height: 16),
                Container(
                  color: _kCard,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _kAccent,
                    indicatorWeight: 2,
                    labelColor: _kAccent,
                    unselectedLabelColor: _kTextMuted,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      const Tab(text: 'Профиль'),
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
                                  _badge(count, _kAccentRed),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
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
                                  _badge(count, _kAccentRed),
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
            _buildProfileTab(rank, coins, cost, isMax, nextRank),
            _buildFriendsTab(),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _kAccent.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: _kAccent.withOpacity(0.05),
                      blurRadius: 20),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kAccent.withOpacity(0.15),
                      border: Border.all(
                          color: _kAccent.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.star,
                        color: _kAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMax ? '👑 Максимальный ранг!' : 'Следующий: $nextRank',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        if (!isMax)
                          Text('Стоимость: $cost 🪙',
                              style: const TextStyle(
                                  color: _kTextMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!isMax)
                    GestureDetector(
                      onTap: coins >= (cost ?? 0) ? _upgradeRank : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: coins >= (cost ?? 0)
                              ? _kAccent
                              : _kCardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: coins >= (cost ?? 0)
                                  ? _kAccent
                                  : _kBorder),
                        ),
                        child: Text(
                          'Купить',
                          style: TextStyle(
                              color: coins >= (cost ?? 0)
                                  ? Colors.white
                                  : _kTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
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
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: _kCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                          color: _kAccentRed, width: 1)),
                  title: const Text('Выйти?',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  content: const Text('Данные сохранятся',
                      style: TextStyle(color: _kTextMuted)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена',
                            style: TextStyle(color: _kTextMuted))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Выйти',
                          style: TextStyle(
                              color: _kAccentRed,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _kCardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kAccentRed.withOpacity(0.4), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: _kAccentRed, size: 18),
                    SizedBox(width: 8),
                    Text('Выйти из профиля',
                        style: TextStyle(
                            color: _kAccentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ],
                ),
              ),
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
            color: _kCardDark,
            child: TabBar(
              indicatorColor: _kAccent,
              indicatorWeight: 2,
              labelColor: _kAccent,
              unselectedLabelColor: _kTextMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
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
                          child: CircularProgressIndicator(color: _kAccent));
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('😔', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('Пока нет друзей',
                                style: TextStyle(color: _kTextMuted)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
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
                            final name   = ud['name']   ?? 'Player';
                            final avatar = ud['avatar'] ?? '😊';
                            final status = ud['status'] ?? 'offline';
                            final isOnline = status == 'online';

                            return _FriendTile(
                              name: name,
                              avatar: avatar,
                              isOnline: isOnline,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfileScreen(uid: friendUid)),
                              ),
                              onMessage: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(otherUid: friendUid)),
                              ),
                              onRemove: () async {
                                await _friendService.removeFriend(friendUid);
                              },
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
                          child: CircularProgressIndicator(color: _kAccent));
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Нет входящих заявок',
                            style: TextStyle(color: _kTextMuted)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
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
                            final name   = ud['name']   ?? 'Player';
                            final avatar = ud['avatar'] ?? '😊';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kCard,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                Border.all(color: _kBorder, width: 1),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: _avatarWidget(avatar),
                                title: Text(name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                subtitle: const Text('Хочет добавить тебя',
                                    style: TextStyle(
                                        color: _kTextMuted, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _iconBtn(Icons.check_circle, _kAccent,
                                            () => _friendService
                                            .acceptRequest(fromUid)),
                                    _iconBtn(Icons.cancel, _kAccentRed,
                                            () => _friendService
                                            .declineRequest(fromUid)),
                                  ],
                                ),
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

          // Кнопка поиска
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _showSearchFriend,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAccent, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, color: _kAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Найти игрока по ID',
                        style: TextStyle(
                            color: _kAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
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
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kAccent, width: 1)),
        title: const Text('Найти игрока',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _friendIdController,
          style: const TextStyle(
              color: Colors.white, letterSpacing: 2),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введи ID игрока',
            hintStyle: const TextStyle(color: _kTextMuted),
            filled: true,
            fillColor: _kCardDark,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kAccent, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kBorder, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kAccent, width: 1.5)),
            prefixText: '#',
            prefixStyle: const TextStyle(
                color: _kAccent, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена',
                  style: TextStyle(color: _kTextMuted))),
          _NeonButton(
            label: 'Найти',
            onTap: () async {
              final input = _friendIdController.text.trim();
              if (input.isEmpty) return;
              Navigator.pop(context);
              final user =
              await _friendService.findUserById('#$input');
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
              GestureDetector(
                onTap: _notifService.markAllRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _kAccent.withOpacity(0.4)),
                  ),
                  child: const Text('Все прочитано',
                      style: TextStyle(
                          color: _kAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
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
                    child: CircularProgressIndicator(color: _kAccent));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Нет уведомлений',
                          style: TextStyle(color: _kTextMuted)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc  = snap.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final type    = data['type']     ?? '';
                  final fromUid = data['fromUid']  ?? '';
                  final text    = data['text']     ?? '';
                  final read    = data['read']     ?? false;
                  final time =
                  (data['createdAt'] as Timestamp?)?.toDate();

                  IconData icon;
                  Color color;
                  switch (type) {
                    case 'friend_request':
                      icon = Icons.person_add; color = const Color(0xFF5B8DEF);
                      break;
                    case 'friend_accepted':
                      icon = Icons.people; color = _kAccent;
                      break;
                    case 'game_invite':
                      icon = Icons.sports_esports; color = const Color(0xFFBB86FC);
                      break;
                    case 'message':
                      icon = Icons.message; color = const Color(0xFFFFD700);
                      break;
                    default:
                      icon = Icons.notifications; color = Colors.white;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: read ? _kCard : _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: read
                              ? _kBorder
                              : color.withOpacity(0.4),
                          width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      onTap: () async {
                        await _notifService.markRead(doc.id);
                        if (type == 'friend_request') {
                          await _friendService.acceptRequest(fromUid);
                          _showSnack('Заявка принята ✅');
                        }
                      },
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                              color: color.withOpacity(0.4)),
                        ),
                        child: Icon(icon, color: color, size: 20),
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
                              name =
                                  (ud as Map<String, dynamic>)['name'] ??
                                      'Player';
                            }
                          }
                          return Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14));
                        },
                      ),
                      subtitle: Text(text,
                          style: const TextStyle(
                              color: _kTextMuted, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!read)
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kAccent),
                            ),
                          if (time != null)
                            Text(
                              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: _kTextMuted, fontSize: 10),
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

  // ── Утилиты ────────────────────────────────────────────────────────────────

  Widget _rankBadge(String rank) {
    final colors = {
      'Новичок': _kAccent,
      'Медиум'  : const Color(0xFFFFD700),
      'Профи'   : const Color(0xFF5B8DEF),
      'Легенда' : const Color(0xFFBB86FC),
    };
    final icons = {
      'Новичок': '🥇',
      'Медиум'  : '🥈',
      'Профи'   : '🏆',
      'Легенда' : '👑',
    };
    final color = colors[rank] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icons[rank] ?? '🏅',
              style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(rank,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _stat(String v, String l, Color c) => Column(children: [
    Text(v,
        style: TextStyle(
            color: c, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(l, style: const TextStyle(color: _kTextMuted, fontSize: 12)),
  ]);

  Widget _divider() =>
      Container(width: 1, height: 36, color: _kBorder);

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _kTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _badges(String rank) {
    final list = [
      {'t': 'Новичок', 'i': '🥇', 'c': _kAccent},
      {'t': 'Медиум',  'i': '🥈', 'c': const Color(0xFFFFD700)},
      {'t': 'Профи',   'i': '🏆', 'c': const Color(0xFF5B8DEF)},
      {'t': 'Легенда', 'i': '👑', 'c': const Color(0xFFBB86FC)},
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
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: unlocked
                  ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                  : Border.all(color: _kBorder, width: 1),
              boxShadow: unlocked
                  ? [
                BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 12)
              ]
                  : null,
            ),
            child: Column(
              children: [
                Text(e.value['i'] as String,
                    style: TextStyle(
                        fontSize: 24,
                        color: unlocked ? null : const Color(0xFF2A2A4A))),
                const SizedBox(height: 4),
                Text(e.value['t'] as String,
                    style: TextStyle(
                        color: unlocked ? Colors.white : _kTextMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(unlocked ? '✓ Получен' : '🔒 Закрыт',
                    style: TextStyle(
                        color: unlocked ? _kAccent : _kTextMuted,
                        fontSize: 8)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(int count, Color color) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: Center(
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    ),
  );

  Widget _avatarWidget(String avatar, {bool isOnline = false}) {
    return Stack(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kCard,
            border: Border.all(color: _kBorder),
          ),
          child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 22))),
        ),
        if (isOnline)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent,
                border: Border.all(color: _kBg, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onTap,
      );
}

// ─── Переиспользуемые компоненты ──────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  final String name, avatar;
  final bool isOnline;
  final VoidCallback onTap, onMessage, onRemove;

  const _FriendTile({
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.onTap,
    required this.onMessage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: Stack(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCardDark,
                border: Border.all(
                    color: isOnline
                        ? _kAccent.withOpacity(0.5)
                        : _kBorder),
              ),
              child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 22))),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? _kAccent : const Color(0xFF444466),
                  border: Border.all(color: _kBg, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Text(
          isOnline ? 'онлайн' : 'оффлайн',
          style: TextStyle(
              color: isOnline ? _kAccent : _kTextMuted,
              fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.message_rounded,
                  color: Color(0xFF5B8DEF), size: 20),
              onPressed: onMessage,
            ),
            IconButton(
              icon: Icon(Icons.person_remove_rounded,
                  color: _kAccentRed.withOpacity(0.8), size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NeonButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _kAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: _kAccent.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }
}