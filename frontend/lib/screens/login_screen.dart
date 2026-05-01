import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/auth/auth_error_text.dart';
import '../widgets/auth/auth_labeled_text_field.dart';
import '../widgets/auth/auth_page_layout.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_switch_link.dart';
import '../widgets/common/separator.dart';
import '../viewmodels/login_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

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
          AuthLabeledTextField(
            label: 'Contraseña',
            hintText: 'Introduce tu contraseña',
            icon: Icons.lock_outline,
            controller: _passwd,
            isPassword: true,
            obscure: _obscure,
            iconColor: Colors.black,
            onToggleVisibility: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 28),
          if (vm.error != null) ...[
            AuthErrorText(message: vm.error!),
            const SizedBox(height: 12),
          ],
          AuthPrimaryButton(
            label: 'Iniciar sesión',
            loading: vm.loading,
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
    final vm = context.read<LoginViewModel>();
    final ok = await vm.login(email: _email.text, passwd: _passwd.text);
    if (!mounted) return;
    if (ok) context.go('/home');
  }
}
