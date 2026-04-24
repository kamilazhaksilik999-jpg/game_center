import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginScreen({super.key, required this.onSwitch});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String e) {
    if (e.contains('user-not-found')) return 'Пользователь не найден';
    if (e.contains('wrong-password')) return 'Неверный пароль';
    if (e.contains('invalid-email')) return 'Неверный email';
    return 'Ошибка входа. Попробуй снова';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              const SizedBox(height: 60),
              const Text('👋 Добро пожаловать',
                  style: TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Войди в свой аккаунт',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),

              // Email
              _field(_emailController, 'Email', Icons.email,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Пароль
              _field(_passwordController, 'Пароль', Icons.lock,
                  obscure: true),
              const SizedBox(height: 16),

              // Ошибка
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),

              const SizedBox(height: 24),

              // Кнопка войти
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Войти',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // Переключение на регистрацию
              TextButton(
                onPressed: widget.onSwitch,
                child: const Text('Нет аккаунта? Зарегистрируйся',
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