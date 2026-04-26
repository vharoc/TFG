import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth/auth_error_text.dart';
import '../widgets/auth/auth_labeled_text_field.dart';
import '../widgets/auth/auth_labeled_password_field.dart';
import '../widgets/auth/auth_page_layout.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_switch_link.dart';
import '../widgets/common/separator.dart';
import '../viewmodels/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();

  bool _obscure = true;
  final _vm = LoginViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Iniciar sesión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthLabeledTextField(
            label: 'Email o usuario',
            hintText: 'Introduce tu email o usuario',
            icon: Icons.person_outline,
            controller: _email,
          ),
          const SizedBox(height: 16),
          AuthLabeledPasswordField(
            label: 'Contraseña',
            controller: _passwd,
            obscure: _obscure,
            hintText: 'Introduce tu contraseña',
            iconColor: Colors.black,
            onToggleVisibility: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 28),
          if (_vm.error != null) ...[
            AuthErrorText(message: _vm.error!),
            const SizedBox(height: 12),
          ],
          AuthPrimaryButton(
            label: 'Iniciar sesión',
            loading: _vm.loading,
            onPressed: _login,
          ),
          const SizedBox(height: 24),
          const Separator(),
          const SizedBox(height: 16),
          AuthSwitchLink(
            prefix: '¿No tienes cuenta?',
            action: 'Crear cuenta',
            onTap: () => context.go('/register'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final ok = await _vm.login(email: _email.text, passwd: _passwd.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    }
  }
}
