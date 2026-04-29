// football_multiplayer.dart
// Пенальти онлайн — 2 игрока через Firestore
//
// Архитектура:
//   • Authoritative Host — хост считает результат математически, пишет в Firestore
//   • Визуальная физика запускается локально на обоих клиентах одновременно
//   • StreamSubscription вместо StreamBuilder — нет rebuild всего дерева
//   • Ticker (vsync) вместо Timer.periodic — нет drift
//   • ValueNotifier — canvas и HUD обновляются изолированно
//   • Умный shouldRepaint — не перерисовывает без изменений
//   • Экран ожидания — единый стиль с остальными играми (код комнаты, копирование)
//   • Гость тоже проходит через WaitingScreen (симметрично хосту)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Константы ────────────────────────────────────────────────────────────────

const double kFieldW     = 400.0;
const double kFieldH     = 600.0;
const double kGoalW      = 200.0;
const double kGoalH      = 60.0;
const double kGoalY      = 40.0;
const double kBallR      = 16.0;
const double kBallStartX = kFieldW / 2;
const double kBallStartY = kFieldH - 100.0;
const double kKeeperW    = 60.0;
const double kKeeperH    = 60.0;
const double kKeeperY    = kGoalY + kGoalH / 2;
const double kArrowMaxLen = 90.0;
const double kBallMaxSpeed = 22.0;
const double kGravity    = 0.18;

// ─── Роль и фазы ─────────────────────────────────────────────────────────────

enum PlayerRole { host, guest }
enum MatchPhase { waiting, keeperPhase, aiming, shooting, calculating, scored, missed, saved, result }
enum TurnAction { shoot, keep }

// ─── Главный экран (меню) ─────────────────────────────────────────────────────

class MultiplayerMenuScreen extends StatefulWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  State<MultiplayerMenuScreen> createState() => _MultiplayerMenuScreenState();
}

class _MultiplayerMenuScreenState extends State<MultiplayerMenuScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController(text: 'Игрок');
  final _roomController = TextEditingController();
  final _rng = Random();
  bool _loading = false;
  String? _error;

  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите имя игрока');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final code = _generateRoomCode();

    await FirebaseFirestore.instance.collection('football_rooms').doc(code).set({
      'hostName'      : name,
      'guestName'     : null,
      'guestJoined'   : false,
      'hostScore'     : 0,
      'guestScore'    : 0,
      'round'         : 0,
      'maxRounds'     : 5,
      'shooterRole'   : 'host',
      'keeperTargetX' : null,
      'keeperReady'   : false,
      'shotVelX'      : null,
      'shotVelY'      : null,
      'shotSpin'      : null,
      'shotFired'     : false,
      'roundResult'   : null,
      'roundComplete' : false,
      'gameOver'      : false,
      'created_at'    : FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;

    // Хост идёт через экран ожидания
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FootballWaitingScreen(
          roomCode: code,
          playerName: name,
          isHost: true,
        ),
      ),
    );
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final code = _roomController.text.trim().toUpperCase();

    if (name.isEmpty) {
      setState(() => _error = 'Введите имя игрока');
      return;
    }
    if (code.length != 4) {
      setState(() => _error = 'Код комнаты — 4 символа');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance
        .collection('football_rooms')
        .doc(code)
        .get();

    if (!doc.exists) {
      setState(() { _error = 'Комната не найдена: $code'; _loading = false; });
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['guestJoined'] == true) {
      setState(() { _error = 'Комната уже заполнена'; _loading = false; });
      return;
    }

    await FirebaseFirestore.instance
        .collection('football_rooms')
        .doc(code)
        .update({'guestName': name, 'guestJoined': true});

    setState(() => _loading = false);
    if (!mounted) return;

    // Гость ТОЖЕ идёт через экран ожидания (симметрично хосту)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FootballWaitingScreen(
          roomCode: code,
          playerName: name,
          isHost: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0D0D1A), const Color(0xFF101020), _bgAnim.value)!,
                  Color.lerp(const Color(0xFF111128), const Color(0xFF0A1020), _bgAnim.value)!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Иконка
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF00C896).withOpacity(0.3), width: 2),
                    ),
                    child: const Center(
                        child: Text('⚽', style: TextStyle(fontSize: 44))),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'ПЕНАЛЬТИ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const Text(
                    '2 ИГРОКА',
                    style: TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 36),

                  _buildInput(_nameController, 'Ваше имя', Icons.person),
                  const SizedBox(height: 24),

                  // Кнопка создать
                  SizedBox(
                    width: double.infinity,
                    child: _MenuButton(
                      label: 'СОЗДАТЬ КОМНАТУ',
                      icon: Icons.add_circle_outline_rounded,
                      color: const Color(0xFF00C896),
                      onTap: _loading ? null : _createRoom,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('или',
                          style: TextStyle(
                              color: const Color(0xFF8888AA).withOpacity(0.5),
                              fontSize: 14)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
                  ]),
                  const SizedBox(height: 20),

                  _buildInput(
                    _roomController,
                    'Код комнаты (4 символа)',
                    Icons.meeting_room_outlined,
                    caps: true,
                    maxLen: 4,
                  ),
                  const SizedBox(height: 16),

                  // Кнопка войти
                  SizedBox(
                    width: double.infinity,
                    child: _MenuButton(
                      label: 'ВОЙТИ В КОМНАТУ',
                      icon: Icons.login_rounded,
                      color: const Color(0xFF16213E),
                      borderColor: const Color(0xFF00C896),
                      textColor: const Color(0xFF00C896),
                      onTap: _loading ? null : _joinRoom,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CircularProgressIndicator(color: Color(0xFF00C896)),
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    'Один игрок создаёт комнату,\nвторой вводит 4-значный код',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF444466), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon,
      {bool caps = false, int? maxLen}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00C896), width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        maxLength: maxLen,
        textCapitalization:
        caps ? TextCapitalization.characters : TextCapitalization.words,
        style: TextStyle(
            color: Colors.white,
            fontSize: caps ? 22 : 16,
            fontWeight: caps ? FontWeight.bold : FontWeight.normal,
            letterSpacing: caps ? 6 : 0),
        textAlign: caps ? TextAlign.center : TextAlign.start,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF444466)),
          prefixIcon: caps ? null : Icon(icon, color: const Color(0xFF8888AA), size: 20),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Экран ожидания — единый стиль для хоста и гостя
// ═══════════════════════════════════════════════════════════════════════════════

class FootballWaitingScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final bool isHost;

  const FootballWaitingScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<FootballWaitingScreen> createState() => _FootballWaitingScreenState();
}

class _FootballWaitingScreenState extends State<FootballWaitingScreen> {
  StreamSubscription? _sub;
  bool _opponentJoined = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('football_rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;

      // Хост ждёт гостя, гость ждёт подтверждения (guestJoined уже true для него)
      final joined = d['guestJoined'] as bool? ?? false;
      if (joined && !_opponentJoined) {
        setState(() => _opponentJoined = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FootballGameScreen(
                  roomCode: widget.roomCode,
                  playerName: widget.playerName,
                  role: widget.isHost ? PlayerRole.host : PlayerRole.guest,
                ),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (widget.isHost) {
      await FirebaseFirestore.instance
          .collection('football_rooms')
          .doc(widget.roomCode)
          .delete();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚽', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),

              Text(
                widget.isHost ? 'Твоя комната' : 'Подключение...',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Блок с кодом — только хосту
              if (widget.isHost) ...[
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Код скопирован!'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00C896), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.roomCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, color: Colors.white38, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Нажми, чтобы скопировать',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
                const SizedBox(height: 40),
              ] else
                const SizedBox(height: 20),

              if (!_opponentJoined) ...[
                const CircularProgressIndicator(color: Color(0xFF00C896)),
                const SizedBox(height: 20),
                Text(
                  widget.isHost ? 'Ожидаем друга...' : 'Подключаемся к комнате...',
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                if (widget.isHost) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Поделись кодом с другом',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ] else ...[
                const Icon(Icons.check_circle,
                    color: Color(0xFF00C896), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Игра начинается!',
                  style: TextStyle(color: Color(0xFF00C896), fontSize: 16),
                ),
              ],

              const SizedBox(height: 36),
              TextButton(
                onPressed: _cancel,
                child: const Text('Отмена',
                    style: TextStyle(color: Colors.redAccent, fontSize: 15)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Кнопка меню ─────────────────────────────────────────────────────────────

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    this.borderColor,
    this.textColor,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasBorder = widget.borderColor != null;
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) { setState(() => _pressed = false); widget.onTap!(); }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            border: hasBorder
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: hasBorder
                ? null
                : [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.textColor ?? Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Игровой экран
// ═══════════════════════════════════════════════════════════════════════════════

class FootballGameScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final PlayerRole role;

  const FootballGameScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.role,
  });

  @override
  State<FootballGameScreen> createState() => _FootballGameScreenState();
}

// ОПТИМИЗАЦИЯ: TickerProviderStateMixin даёт Ticker для vsync физики
class _FootballGameScreenState extends State<FootballGameScreen>
    with TickerProviderStateMixin {

  // ── Локальная физика (ТОЛЬКО ДЛЯ ОТРИСОВКИ) ─────────────────────────────
  Offset _ball     = const Offset(kBallStartX, kBallStartY);
  Offset _ballVel  = Offset.zero;
  double _ballSpin = 0;
  double _ballScale = 1.0;
  double _keeperX  = kFieldW / 2;

  // ── Прицел ──────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;

  // ── Фаза матча ──────────────────────────────────────────────────────────
  MatchPhase _phase   = MatchPhase.waiting;
  TurnAction _myAction = TurnAction.shoot;

  // ── Вратарь ─────────────────────────────────────────────────────────────
  double _myKeeperTarget = kFieldW / 2;
  bool   _keeperDecided  = false;
  bool   _physicsStarted = false;

  // ── Анимация попа (гол/мимо/сэйв) ───────────────────────────────────────
  late AnimationController _scorePopController;
  late Animation<double>   _scorePopAnim;
  bool   _showScorePop  = false;
  String _scorePopText  = '';
  Color  _scorePopColor = Colors.white;

  String? _statusMessage;

  // ── Firestore ────────────────────────────────────────────────────────────
  StreamSubscription? _sub;
  // Кэш последнего снапшота для header/result
  Map<String, dynamic> _lastData = {};

  // ОПТИМИЗАЦИЯ: Ticker для визуальной физики вместо Timer.periodic
  Ticker? _physicsTicker;
  bool    _physicsRunning = false;
  // Сохраняем параметры удара для ticker
  Offset  _shotVel        = Offset.zero;
  double  _shotSpin       = 0;
  double  _shotKeeperTarget = kFieldW / 2;

  // ОПТИМИЗАЦИЯ: ValueNotifier'ы — canvas и HUD обновляются отдельно
  final _repaint    = ValueNotifier<int>(0);
  final _hudRefresh = ValueNotifier<int>(0);

  DocumentReference get _roomRef =>
      FirebaseFirestore.instance.collection('football_rooms').doc(widget.roomCode);

  bool get _isHost => widget.role == PlayerRole.host;

  // ═══════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();

    _scorePopController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scorePopAnim =
        CurvedAnimation(parent: _scorePopController, curve: Curves.elasticOut);

    _listenRoom();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _physicsTicker?.dispose();
    _scorePopController.dispose();
    _repaint.dispose();
    _hudRefresh.dispose();
    super.dispose();
  }

  // ─── Подписка на Firestore ─────────────────────────────────────────────
  //
  // ОПТИМИЗАЦИЯ: StreamSubscription вместо StreamBuilder.
  // Данные обновляются без rebuild всего дерева виджетов.
  void _listenRoom() {
    _sub = _roomRef.snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = snap.data() as Map<String, dynamic>;
      _lastData = d;
      _syncFromData(d);
    });
  }

  // ── Синхронизация состояния из Firestore ──────────────────────────────

  void _syncFromData(Map<String, dynamic> d) {
    final guestJoined = d['guestJoined'] as bool? ?? false;

    if (!guestJoined) {
      if (_phase != MatchPhase.waiting) {
        _phase = MatchPhase.waiting;
        _statusMessage = 'Ожидание второго игрока...';
        _hudRefresh.value++;
        if (mounted) setState(() {});
      }
      return;
    }

    if (d['gameOver'] == true) {
      if (_phase != MatchPhase.result) {
        _phase = MatchPhase.result;
        if (mounted) setState(() {});
      }
      return;
    }

    final shooterRole  = d['shooterRole'] as String? ?? 'host';
    final shooterIsHost = shooterRole == 'host';
    final iAmShooter =
        (_isHost && shooterIsHost) || (!_isHost && !shooterIsHost);

    // Раунд завершён
    if (d['roundComplete'] == true) {
      if (_phase != MatchPhase.scored &&
          _phase != MatchPhase.missed &&
          _phase != MatchPhase.saved) {
        _handleRoundResult(d['roundResult'] as String?, iAmShooter);
      }
      return;
    }

    // Мяч летит
    final shotFired = d['shotFired'] as bool? ?? false;
    if (shotFired && !_physicsStarted) {
      final vx   = (d['shotVelX'] as num?)?.toDouble();
      final vy   = (d['shotVelY'] as num?)?.toDouble();
      final spin = (d['shotSpin'] as num?)?.toDouble() ?? 0.0;
      final kt   = (d['keeperTargetX'] as num?)?.toDouble() ?? kFieldW / 2;

      if (vx != null && vy != null) {
        _physicsStarted = true;
        _startLocalVisualPhysics(Offset(vx, vy), spin, kt);

        if (_isHost) {
          _calculateAndWriteResultAsHost(vx, vy, spin, kt, shooterIsHost, d);
        }
      }
      return;
    }

    // Фаза расстановки — обновляем только при реальной смене фазы
    if (!shotFired) {
      final keeperReady = d['keeperReady'] as bool? ?? false;

      if (!iAmShooter && !keeperReady && !_keeperDecided) {
        if (_phase != MatchPhase.keeperPhase) {
          _phase         = MatchPhase.keeperPhase;
          _statusMessage = 'Встань в ворота! Выбери позицию';
          _myAction      = TurnAction.keep;
          if (mounted) setState(() {});
        }
      } else if (iAmShooter && keeperReady) {
        if (_phase != MatchPhase.aiming) {
          _phase     = MatchPhase.aiming;
          _statusMessage = null;
          _myAction  = TurnAction.shoot;
          if (mounted) setState(() {});
        }
      } else if (iAmShooter && !keeperReady) {
        if (_phase != MatchPhase.waiting) {
          _phase         = MatchPhase.waiting;
          _statusMessage = 'Ожидание вратаря...';
          if (mounted) setState(() {});
        }
      }
    }
  }

  // ── Математический расчет результата (только хост) ────────────────────

  Future<void> _calculateAndWriteResultAsHost(
      double vx, double vy, double spin, double kt,
      bool shooterIsHost, Map<String, dynamic> currentData) async {

    Offset simBall = const Offset(kBallStartX, kBallStartY);
    Offset simVel  = Offset(vx, vy);
    String result  = 'missed';

    for (int i = 0; i < 300; i++) {
      simVel  = Offset(simVel.dx + spin * 0.05, simVel.dy);
      simBall += simVel;
      simVel  *= (1 - kGravity * 0.08);

      if ((simBall.dx - kt).abs() < kKeeperW / 2 + kBallR &&
          simBall.dy <= kKeeperY + kKeeperH / 2 + kBallR &&
          simBall.dy >= kGoalY) {
        result = 'saved';
        break;
      }

      if (simBall.dy <= kGoalY + kGoalH) {
        final inGoalX = simBall.dx >= kFieldW / 2 - kGoalW / 2 + kBallR &&
            simBall.dx <= kFieldW / 2 + kGoalW / 2 - kBallR;
        if (inGoalX) {
          result = 'scored';
          break;
        }
      }

      if (simBall.dy < -kBallR * 2 ||
          simBall.dx < -kBallR * 2 ||
          simBall.dx > kFieldW + kBallR * 2) {
        result = 'missed';
        break;
      }
    }

    int hostScore  = currentData['hostScore']  as int? ?? 0;
    int guestScore = currentData['guestScore'] as int? ?? 0;

    if (result == 'scored') {
      if (shooterIsHost) hostScore++; else guestScore++;
    } else {
      if (!shooterIsHost) hostScore++; else guestScore++;
    }

    await _roomRef.update({
      'hostScore'     : hostScore,
      'guestScore'    : guestScore,
      'roundResult'   : result,
      'round'         : FieldValue.increment(1),
      'roundComplete' : true,
    });
  }

  void _handleRoundResult(String? result, bool iWasShooter) {
    if (result == 'scored') {
      _showPop(iWasShooter ? '⚽ ГОЛ!' : '😱 ГОЛ!',
          iWasShooter ? const Color(0xFF00C896) : Colors.redAccent);
    } else if (result == 'saved') {
      _showPop(!iWasShooter ? '🧤 СЭЙВ!' : '🧤 Сэйв!',
          !iWasShooter ? const Color(0xFF00C896) : Colors.redAccent);
    } else {
      _showPop('❌ МИМО!', const Color(0xFFFFD740));
    }

    _phase = result == 'scored'
        ? MatchPhase.scored
        : result == 'saved'
        ? MatchPhase.saved
        : MatchPhase.missed;
    if (mounted) setState(() {});

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_isHost) _nextRound();
    });
  }

  Future<void> _nextRound() async {
    final snap = await _roomRef.get();
    if (!snap.exists) return;
    final d     = snap.data() as Map<String, dynamic>;
    final round = d['round'] as int? ?? 0;
    final maxRounds = d['maxRounds'] as int? ?? 5;

    if (round >= maxRounds) {
      await _roomRef.update({'gameOver': true});
    } else {
      final nextShooter =
      (d['shooterRole'] as String? ?? 'host') == 'host' ? 'guest' : 'host';
      await _roomRef.update({
        'shooterRole'   : nextShooter,
        'keeperTargetX' : null,
        'keeperReady'   : false,
        'shotVelX'      : null,
        'shotVelY'      : null,
        'shotSpin'      : null,
        'shotFired'     : false,
        'roundResult'   : null,
        'roundComplete' : false,
      });
    }

    _resetLocalState();
  }

  void _resetLocalState() {
    _physicsTicker?.stop();
    _physicsRunning = false;

    _ball          = const Offset(kBallStartX, kBallStartY);
    _ballVel       = Offset.zero;
    _ballSpin      = 0;
    _ballScale     = 1.0;
    _keeperX       = kFieldW / 2;
    _myKeeperTarget = kFieldW / 2;
    _keeperDecided  = false;
    _physicsStarted = false;
    _phase          = MatchPhase.waiting;
    _statusMessage  = null;

    if (mounted) setState(() {});
  }

  // ── Визуальная физика (только отрисовка) ─────────────────────────────
  //
  // ОПТИМИЗАЦИЯ: Ticker (vsync) вместо Timer.periodic(16ms).
  // Привязан к частоте экрана — нет drift и лишних кадров.
  void _startLocalVisualPhysics(Offset vel, double spin, double keeperTarget) {
    _ball        = const Offset(kBallStartX, kBallStartY);
    _ballVel     = vel;
    _ballSpin    = spin;
    _keeperX     = kFieldW / 2;
    _shotVel     = vel;
    _shotSpin    = spin;
    _shotKeeperTarget = keeperTarget;
    _phase       = MatchPhase.shooting;

    if (mounted) setState(() {});

    _physicsTicker ??= createTicker(_onPhysicsTick);
    _physicsRunning = true;
    _physicsTicker!.start();
  }

  void _onPhysicsTick(Duration elapsed) {
    if (!_physicsRunning || !mounted) return;

    _ballVel  = Offset(_ballVel.dx + _ballSpin * 0.05, _ballVel.dy);
    _ball    += _ballVel;
    _ballVel *= (1 - kGravity * 0.08);
    _ballScale = 1.0 - (_ball.dy - kBallStartY).abs() / (kFieldH * 4);

    final dx = _shotKeeperTarget - _keeperX;
    _keeperX += dx.sign * min(4.5, dx.abs());

    // Проверяем выход мяча за пределы
    final bx = _ball.dx;
    final by = _ball.dy;
    bool stop = false;

    if (bx < -kBallR || bx > kFieldW + kBallR ||
        by < -kBallR * 2 || by > kFieldH + kBallR) {
      stop = true;
    }

    if (!stop && by <= kGoalY + kGoalH + kBallR) {
      final caught = (bx - _keeperX).abs() < kKeeperW / 2 + kBallR &&
          by <= kKeeperY + kKeeperH / 2 + kBallR;
      if (caught || by < kGoalY - kBallR) stop = true;
    }

    if (stop) {
      _physicsTicker!.stop();
      _physicsRunning = false;
      // Ждём результата от сервера
      _phase         = MatchPhase.calculating;
      _statusMessage = 'Сверка результата...';
      if (mounted) setState(() {});
      return;
    }

    // ОПТИМИЗАЦИЯ: обновляем только canvas, не весь виджет
    _repaint.value++;
  }

  // ── Ввод вратаря ──────────────────────────────────────────────────────

  void _onKeeperDrag(DragUpdateDetails d) {
    if (_phase != MatchPhase.keeperPhase) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final screenW = box.size.width;
    final fieldOffX = (screenW - kFieldW) / 2;
    final x = (local.dx - fieldOffX).clamp(
      kFieldW / 2 - kGoalW / 2 + kKeeperW / 2,
      kFieldW / 2 + kGoalW / 2 - kKeeperW / 2,
    );
    // ОПТИМИЗАЦИЯ: только canvas, не весь rebuild
    _myKeeperTarget = x;
    _repaint.value++;
  }

  Future<void> _confirmKeeperPosition() async {
    if (_keeperDecided) return;
    _keeperDecided = true;
    await _roomRef.update({
      'keeperTargetX' : _myKeeperTarget,
      'keeperReady'   : true,
    });
    _phase         = MatchPhase.waiting;
    _statusMessage = 'Позиция зафиксирована! Ждём удара...';
    if (mounted) setState(() {});
  }

  // ── Ввод бьющего ──────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails d) {
    if (_phase != MatchPhase.aiming) return;
    final local = _toField(d.globalPosition);
    if (local == null) return;
    if ((local - _ball).distance < 50) {
      _dragStart  = local;
      _dragCurrent = local;
      _repaint.value++;
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_phase != MatchPhase.aiming || _dragStart == null) return;
    final local = _toField(d.globalPosition);
    if (local == null) return;
    _dragCurrent = local;
    _repaint.value++;
  }

  Future<void> _onDragEnd(DragEndDetails _) async {
    if (_phase != MatchPhase.aiming || _dragStart == null) return;
    final ds    = _dragStart!;
    final dc    = _dragCurrent!;
    final delta = ds - dc;

    _dragStart   = null;
    _dragCurrent = null;

    if (delta.distance < 10) {
      _repaint.value++;
      return;
    }

    final norm       = delta / delta.distance;
    final power      = (delta.distance / kArrowMaxLen).clamp(0.0, 1.0);
    final speed      = power * kBallMaxSpeed;
    final spinFactor = delta.dx / kArrowMaxLen;
    final vel        = norm * speed;

    await _roomRef.update({
      'shotVelX' : vel.dx,
      'shotVelY' : vel.dy,
      'shotSpin' : spinFactor * 2.5,
      'shotFired': true,
    });
  }

  Offset? _toField(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local    = box.globalToLocal(global);
    final screenW  = box.size.width;
    final screenH  = box.size.height;
    final fieldOffX = (screenW - kFieldW) / 2;
    final fieldOffY = (screenH - kFieldH) / 2 + 60;
    return local - Offset(fieldOffX, fieldOffY);
  }

  void _showPop(String text, Color color) {
    _scorePopText  = text;
    _scorePopColor = color;
    _showScorePop  = true;
    _scorePopController.forward(from: 0);
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showScorePop = false);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ОПТИМИЗАЦИЯ: HUD в ValueListenableBuilder — обновляется без rebuild поля
            ValueListenableBuilder<int>(
              valueListenable: _hudRefresh,
              builder: (_, __, ___) => _buildHeader(),
            ),
            Expanded(child: _buildField()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Шапка ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final d = _lastData;
    final myScore = _isHost
        ? (d['hostScore'] as int? ?? 0)
        : (d['guestScore'] as int? ?? 0);
    final opScore = _isHost
        ? (d['guestScore'] as int? ?? 0)
        : (d['hostScore'] as int? ?? 0);
    final round     = d['round'] as int? ?? 0;
    final maxRounds = d['maxRounds'] as int? ?? 5;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF8888AA), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          // Код комнаты (нажать — скопировать)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00C896).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.meeting_room_outlined,
                      color: Color(0xFF8888AA), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.roomCode,
                    style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Раунд $round/$maxRounds',
            style: const TextStyle(color: Color(0xFF8888AA), fontSize: 12),
          ),
          const Spacer(),
          // Счёт
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00C896).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$myScore',
                    style: const TextStyle(
                        color: Color(0xFF00C896),
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':',
                      style: TextStyle(color: Color(0xFF8888AA), fontSize: 18)),
                ),
                Text('$opScore',
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Игровое поле ────────────────────────────────────────────────────────

  Widget _buildField() {
    final effectiveKeeperX =
    _phase == MatchPhase.keeperPhase ? _myKeeperTarget : _keeperX;

    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _phase == MatchPhase.keeperPhase
          ? _onKeeperDrag
          : _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ОПТИМИЗАЦИЯ: RepaintBoundary + AnimatedBuilder — поле перерисовывается
            // изолированно по _repaint, не затрагивая остальной UI
            RepaintBoundary(
              child: SizedBox(
                width: kFieldW,
                height: kFieldH,
                child: AnimatedBuilder(
                  animation: _repaint,
                  builder: (_, __) => CustomPaint(
                    painter: _FieldPainter(
                      ball            : _ball,
                      ballScale       : _ballScale,
                      ballVel         : _ballVel,
                      ballSpin        : _ballSpin,
                      keeperX         : effectiveKeeperX,
                      keeperDive      : _phase == MatchPhase.shooting ||
                          _phase == MatchPhase.calculating,
                      keeperDiveAngle : effectiveKeeperX < kFieldW / 2 ? -0.4 : 0.4,
                      dragStart       : _dragStart,
                      dragCurrent     : _dragCurrent,
                      showArrow       : _phase == MatchPhase.aiming,
                      isKeeperPhase   : _phase == MatchPhase.keeperPhase,
                      myAction        : _myAction,
                    ),
                  ),
                ),
              ),
            ),

            // Статус-оверлей
            if (_phase == MatchPhase.waiting || _phase == MatchPhase.calculating)
              _buildStatusOverlay(),

            // Поп-анимация (ГОЛ / СЭЙВ / МИМО)
            if (_showScorePop)
              ScaleTransition(
                scale: _scorePopAnim,
                child: Text(
                  _scorePopText,
                  style: TextStyle(
                    color: _scorePopColor,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: _scorePopColor.withOpacity(0.7), blurRadius: 30),
                    ],
                  ),
                ),
              ),

            if (_phase == MatchPhase.result)
              _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    final d = _lastData;
    final guestJoined  = d['guestJoined'] as bool? ?? false;
    final isCalculating = _phase == MatchPhase.calculating;

    return Container(
      width: kFieldW,
      height: kFieldH,
      decoration: BoxDecoration(
        color: isCalculating
            ? Colors.black.withOpacity(0.5)
            : Colors.black.withOpacity(0.70),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!guestJoined) ...[
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Ожидание второго игрока',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            const Text('Код комнаты:',
                style: TextStyle(color: Color(0xFF8888AA), fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  Clipboard.setData(ClipboardData(text: widget.roomCode)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: const Color(0xFF00C896), width: 2),
                ),
                child: Text(
                  widget.roomCode,
                  style: const TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                  ),
                ),
              ),
            ),
          ] else if (isCalculating) ...[
            const CircularProgressIndicator(color: Color(0xFF00C896)),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ] else ...[
            Text(
              _statusMessage ?? '⏳',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final d       = _lastData;
    final myScore = _isHost
        ? (d['hostScore']  as int? ?? 0)
        : (d['guestScore'] as int? ?? 0);
    final opScore = _isHost
        ? (d['guestScore'] as int? ?? 0)
        : (d['hostScore']  as int? ?? 0);
    final opName  = _isHost
        ? (d['guestName'] as String? ?? 'Соперник')
        : (d['hostName']  as String? ?? 'Соперник');

    final win   = myScore > opScore;
    final draw  = myScore == opScore;
    final title = draw ? '🤝 НИЧЬЯ!' : win ? '🏆 ПОБЕДА!' : '😔 ПОРАЖЕНИЕ';
    final color = draw
        ? const Color(0xFFFFD740)
        : win
        ? const Color(0xFF00C896)
        : Colors.redAccent;

    return Container(
      width: kFieldW,
      height: kFieldH,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: color.withOpacity(0.6), blurRadius: 24)
                  ])),
          const SizedBox(height: 10),
          Text(
            '${widget.playerName}  $myScore : $opScore  $opName',
            style: const TextStyle(
                color: Colors.white70, fontSize: 16, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          _GlowButton(
            label: 'СЫГРАТЬ СНОВА',
            color: const Color(0xFF00C896),
            onTap: _isHost ? _restartGame : () {},
          ),
          const SizedBox(height: 12),
          _GlowButton(
            label: 'В МЕНЮ',
            color: const Color(0xFF16213E),
            onTap: () => Navigator.pop(context),
          ),
          if (!_isHost) ...[
            const SizedBox(height: 8),
            const Text(
              'Перезапустить может только хост',
              style: TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _restartGame() async {
    if (!_isHost) return;
    await _roomRef.update({
      'hostScore'     : 0,
      'guestScore'    : 0,
      'round'         : 0,
      'shooterRole'   : 'host',
      'keeperTargetX' : null,
      'keeperReady'   : false,
      'shotVelX'      : null,
      'shotVelY'      : null,
      'shotSpin'      : null,
      'shotFired'     : false,
      'roundResult'   : null,
      'roundComplete' : false,
      'gameOver'      : false,
    });
    _resetLocalState();
  }

  Widget _buildBottomBar() {
    if (_phase == MatchPhase.waiting   ||
        _phase == MatchPhase.result    ||
        _phase == MatchPhase.calculating ||
        _phase == MatchPhase.shooting) {
      return const SizedBox(height: 48);
    }

    if (_phase == MatchPhase.keeperPhase && !_keeperDecided) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🧤 Перетащи вратаря в нужную позицию',
              style: TextStyle(color: Color(0xFF8888AA), fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _GlowButton(
                label: 'ЗАФИКСИРОВАТЬ ПОЗИЦИЮ',
                color: const Color(0xFF00C896),
                onTap: _confirmKeeperPosition,
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == MatchPhase.aiming) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          '👆 Тяни стрелку от мяча, чтобы ударить',
          style: TextStyle(
              color: Color(0xFF8888AA), fontSize: 13, letterSpacing: 0.5),
        ),
      );
    }

    return const SizedBox(height: 48);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CustomPainter поля
// ═══════════════════════════════════════════════════════════════════════════════

class _FieldPainter extends CustomPainter {
  final Offset ball;
  final double ballScale;
  final Offset ballVel;
  final double ballSpin;
  final double keeperX;
  final bool   keeperDive;
  final double keeperDiveAngle;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final bool showArrow;
  final bool isKeeperPhase;
  final TurnAction myAction;

  _FieldPainter({
    required this.ball,
    required this.ballScale,
    required this.ballVel,
    required this.ballSpin,
    required this.keeperX,
    required this.keeperDive,
    required this.keeperDiveAngle,
    this.dragStart,
    this.dragCurrent,
    required this.showArrow,
    required this.isKeeperPhase,
    required this.myAction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);
    _drawGoal(canvas);
    _drawKeeper(canvas);
    _drawBall(canvas);
    if (showArrow) _drawArrow(canvas);
    if (isKeeperPhase && myAction == TurnAction.keep) _drawKeeperHint(canvas);
    _drawShadows(canvas);
  }

  void _drawField(Canvas canvas, Size size) {
    final fieldRect =
    RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(fieldRect, grassPaint);

    final stripePaint = Paint()
      ..color = const Color(0xFF1A5C1E)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.clipRRect(fieldRect);
    for (int i = 0; i < 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH(0, i * size.height / 8, size.width, size.height / 8),
            stripePaint);
      }
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.65), 60, linePaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), linePaint);

    final penaltyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 30),
      width: 200,
      height: 140,
    );
    canvas.drawRect(penaltyRect, linePaint);
    canvas.drawCircle(
        Offset(size.width / 2, kBallStartY), 4, Paint()..color = Colors.white30);
    canvas.restore();
  }

  void _drawGoal(Canvas canvas) {
    final goalLeft = kFieldW / 2 - kGoalW / 2;
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = goalLeft; x <= goalLeft + kGoalW; x += 15) {
      canvas.drawLine(Offset(x, kGoalY), Offset(x, kGoalY + kGoalH), netPaint);
    }
    for (double y = kGoalY; y <= kGoalY + kGoalH; y += 12) {
      canvas.drawLine(
          Offset(goalLeft, y), Offset(goalLeft + kGoalW, y), netPaint);
    }

    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(goalLeft, kGoalY), Offset(goalLeft, kGoalY + kGoalH), postPaint);
    canvas.drawLine(Offset(goalLeft + kGoalW, kGoalY),
        Offset(goalLeft + kGoalW, kGoalY + kGoalH), postPaint);
    canvas.drawLine(
        Offset(goalLeft, kGoalY), Offset(goalLeft + kGoalW, kGoalY), postPaint);
  }

  void _drawKeeper(Canvas canvas) {
    final kx = keeperX;
    const ky = kKeeperY;

    canvas.save();
    canvas.translate(kx, ky);
    if (keeperDive) canvas.rotate(keeperDiveAngle);

    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, kKeeperH / 2 + 4), width: 40, height: 10),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 8), width: 32, height: 34),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFFFFD600),
    );
    canvas.drawCircle(
        const Offset(-20, 6), 9, Paint()..color = const Color(0xFFFF6F00));
    canvas.drawCircle(
        const Offset(20, 6), 9, Paint()..color = const Color(0xFFFF6F00));
    canvas.drawCircle(
        const Offset(0, -16), 14, Paint()..color = const Color(0xFFFFCC80));

    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -18), width: 28, height: 20),
      pi, pi, false,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawCircle(
        const Offset(-5, -17), 2.5, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(
        const Offset(5, -17), 2.5, Paint()..color = const Color(0xFF212121));

    final legPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-14, 24, 12, 20), const Radius.circular(4)),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 24, 12, 20), const Radius.circular(4)),
      legPaint,
    );

    final bootPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-16, 40, 14, 8), const Radius.circular(3)),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 40, 14, 8), const Radius.circular(3)),
      bootPaint,
    );

    canvas.restore();
  }

  void _drawKeeperHint(Canvas canvas) {
    final goalLeft = kFieldW / 2 - kGoalW / 2;
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, kGoalY, kGoalW, kGoalH),
      Paint()
        ..color = const Color(0xFF00C896).withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    final arrowPaint = Paint()
      ..color = const Color(0xFF00C896).withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(kFieldW / 2 - 30, kKeeperY),
        const Offset(kFieldW / 2 - 50, kKeeperY), arrowPaint);
    canvas.drawLine(const Offset(kFieldW / 2 + 30, kKeeperY),
        const Offset(kFieldW / 2 + 50, kKeeperY), arrowPaint);
  }

  void _drawBall(Canvas canvas) {
    final bx    = ball.dx;
    final by    = ball.dy;
    final scale = ballScale.clamp(0.4, 1.2);
    final r     = kBallR * scale;

    canvas.save();
    canvas.translate(bx, by);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, r + 4), width: r * 2.2, height: r * 0.6),
      Paint()..color = Colors.black.withOpacity(0.22 * scale),
    );

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Colors.white, const Color(0xFFDDDDDD), const Color(0xFF888888)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );

    _drawBallPattern(canvas, r, Paint()..color = const Color(0xFF111111));

    canvas.drawCircle(
      Offset(-r * 0.3, -r * 0.35),
      r * 0.25,
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    canvas.restore();
  }

  void _drawBallPattern(Canvas canvas, double r, Paint paint) {
    final path = Path();
    void hex(double cx, double cy, double size) {
      for (int i = 0; i < 6; i++) {
        final a  = pi / 3 * i - pi / 6;
        final px = cx + cos(a) * size;
        final py = cy + sin(a) * size;
        i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      path.close();
    }
    hex(0, 0, r * 0.38);
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas) {
    if (dragStart == null || dragCurrent == null) return;
    final from     = ball;
    final rawDelta = dragStart! - dragCurrent!;
    if (rawDelta.distance < 8) return;

    final clampedLen = rawDelta.distance.clamp(0.0, kArrowMaxLen);
    final dir   = rawDelta / rawDelta.distance;
    final to    = from + dir * clampedLen;
    final power = clampedLen / kArrowMaxLen;

    final arrowColor =
    Color.lerp(const Color(0xFF00C896), Colors.redAccent, power)!;

    final arrowPaint = Paint()
      ..color       = arrowColor.withOpacity(0.9)
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    const dashLen = 10.0;
    const gapLen  = 5.0;
    double d      = 0;
    bool drawing  = true;
    final total   = (to - from).distance;
    Offset cur    = from;
    while (d < total) {
      if (drawing) {
        final end = from + dir * (d + dashLen).clamp(0.0, total);
        canvas.drawLine(cur, end, arrowPaint);
        cur = end;
        d += dashLen;
      } else {
        cur = from + dir * d;
        d += gapLen;
      }
      drawing = !drawing;
    }

    const headLen   = 18.0;
    const headAngle = pi / 5;
    final angle     = atan2(dir.dy, dir.dx);
    final tipPaint  = Paint()
      ..color       = arrowColor
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    canvas.drawLine(
        to,
        to - Offset(cos(angle - headAngle), sin(angle - headAngle)) * headLen,
        tipPaint);
    canvas.drawLine(
        to,
        to - Offset(cos(angle + headAngle), sin(angle + headAngle)) * headLen,
        tipPaint);
    canvas.drawCircle(to, 5, Paint()..color = arrowColor);

    canvas.drawArc(
      Rect.fromCircle(center: from, radius: kBallR + 8),
      -pi / 2, 2 * pi * power, false,
      Paint()
        ..color       = arrowColor.withOpacity(0.35)
        ..strokeWidth = 3
        ..style       = PaintingStyle.stroke,
    );
  }

  void _drawShadows(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, kFieldH - 60, kFieldW, 60),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.25)],
        ).createShader(Rect.fromLTWH(0, kFieldH - 60, kFieldW, 60)),
    );
  }

  // ОПТИМИЗАЦИЯ: умный shouldRepaint — не перерисовывает без реальных изменений
  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      ball      != old.ball      ||
          keeperX   != old.keeperX   ||
          ballScale != old.ballScale ||
          dragStart != old.dragStart ||
          dragCurrent != old.dragCurrent ||
          showArrow != old.showArrow ||
          isKeeperPhase != old.isKeeperPhase;
}

// ─── Кнопка с свечением ───────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── main ─────────────────────────────────────────────────────────────────────

void main() {
  runApp(const MaterialApp(
    title: 'Пенальти 2 игрока',
    debugShowCheckedModeBanner: false,
    home: MultiplayerMenuScreen(),
  ));
}