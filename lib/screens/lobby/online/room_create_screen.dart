import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RoomCreateScreen extends StatefulWidget {
  final String gameName;
  const RoomCreateScreen({super.key, required this.gameName});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  late String roomCode;
  bool isCreated = false;

  @override
  void initState() {
    super.initState();
    roomCode = generateCode();
  }

  String generateCode() {
    return String.fromCharCodes(
      Iterable.generate(
        6,
            (_) => '0123456789'.codeUnitAt(Random().nextInt(10)),
      ),
    );
  }

  Future<void> createRoom() async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .set({
      'game': widget.gameName,
      'player1': 'player1',
      'player2': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => isCreated = true);
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 8),
            const Text("Код скопирован!", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF0D1B35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF34D399), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      // ─── AppBar видимый ────────────────────────────────────────────
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_rounded, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 8),
            Text(
              widget.gameName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
                colors: [Colors.transparent, Color(0xFFD97706), Colors.transparent],
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 20),

              // ── Блок с кодом ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B35), Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "КОД КОМНАТЫ",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Сам код — красиво отображённые цифры
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: roomCode.split('').map((char) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 42,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            char,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Кнопка скопировать
                    GestureDetector(
                      onTap: _copyCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, color: Color(0xFF93C5FD), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Скопировать код",
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Кнопка создать / статус ───────────────────────────────
              if (!isCreated)
                _gradientButton(
                  label: "Создать комнату",
                  icon: Icons.add_rounded,
                  gradient: const [Color(0xFFD97706), Color(0xFFF97316)],
                  glow: const Color(0xFFD97706),
                  onTap: createRoom,
                ),

              if (isCreated)
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomCode)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final player2 = data?['player2'];

                      if (player2 != null) {
                        return _opponentJoined();
                      }
                      return _waitingForOpponent();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Противник подключился ─────────────────────────────────────────────────
  Widget _opponentJoined() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF34D399)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        const Text(
          "Противник подключился!",
          style: TextStyle(
            color: Color(0xFF34D399),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Готовы к началу",
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _gradientButton(
          label: "Начать игру",
          icon: Icons.play_arrow_rounded,
          gradient: const [Color(0xFF059669), Color(0xFF34D399)],
          glow: const Color(0xFF34D399),
          onTap: () {
            // TODO: переход к игре
          },
        ),
      ],
    );
  }

  // ── Ожидание ──────────────────────────────────────────────────────────────
  Widget _waitingForOpponent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Анимированный контейнер ожидания
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                const Color(0xFF06B6D4).withValues(alpha: 0.3),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: Color(0xFF06B6D4),
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Ожидание противника...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Поделитесь кодом с другом",
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 32),

        // Пульсирующий индикатор
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF06B6D4),
              shape: BoxShape.circle,
            ),
          )),
        ),

        const SizedBox(height: 32),

        // Кнопка отмена
        GestureDetector(
          onTap: () async {
            await FirebaseFirestore.instance
                .collection('rooms')
                .doc(roomCode)
                .delete();
            if (context.mounted) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded, color: Color(0xFFF43F5E), size: 18),
                SizedBox(width: 6),
                Text(
                  "Отменить",
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Градиентная кнопка ────────────────────────────────────────────────────
  Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required Color glow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}