import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const RegisterScreen({super.key, required this.onSwitch});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;
  String _selectedAvatar = '😊';

  final List<String> _avatars = [
    '😊','😎','🦊','🐱','🎮','🦁','🐺','🤖','👾','🎯',
    '🐸','🐼','🦄','🐲','👻','🤩','🦸','🧙','🥷','🎭',
  ];

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполни все поля');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Пароль минимум 6 символов');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.register(
        email: email,
        password: password,
        name: name,
        avatar: _selectedAvatar,
      );
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String e) {
    if (e.contains('email-already-in-use')) return 'Email уже используется';
    if (e.contains('invalid-email')) return 'Неверный email';
    if (e.contains('weak-password')) return 'Слабый пароль';
    return 'Ошибка регистрации. Попробуй снова';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('Создай аккаунт',
                  style: TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Выбери аватар и заполни данные',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),

              // Аватар
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)]),
                ),
                child: Center(child: Text(_selectedAvatar,
                    style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 16),

              // Выбор аватара
              Wrap(
                spacing: 8, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _avatars.map((e) {
                  final sel = e == _selectedAvatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = e),
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        border: sel
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                      ),
                      child: Center(child: Text(e,
                          style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Никнейм
              _field(_nameController, 'Никнейм', Icons.person),
              const SizedBox(height: 12),

              // Email
              _field(_emailController, 'Email', Icons.email,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),

              // Пароль
              _field(_passwordController, 'Пароль (мин. 6 символов)',
                  Icons.lock, obscure: true),
              const SizedBox(height: 12),

              // Ошибка
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),

              const SizedBox(height: 20),

              // Кнопка регистрации
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Зарегистрироваться',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: widget.onSwitch,
                child: const Text('Уже есть аккаунт? Войти',
                    style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false,
        TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }
}