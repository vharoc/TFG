import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/auth/auth_error_text.dart';
import '../widgets/auth/auth_labeled_password_field.dart';
import '../widgets/auth/auth_labeled_text_field.dart';
import '../widgets/auth/auth_page_layout.dart';
import '../widgets/auth/auth_primary_button.dart';
import '../widgets/auth/auth_switch_link.dart';
import '../widgets/common/separator.dart';
import '../viewmodels/register_view_model.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: const _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  const _RegisterBody();

  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();
  final _user = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return AuthPageLayout(
      title: 'Crear cuenta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthLabeledTextField(
            label: 'Usuario',
            hintText: 'Elige un nombre de usuario',
            icon: Icons.person_outline,
            controller: _user,
          ),
          const SizedBox(height: 16),
          AuthLabeledTextField(
            label: 'Email',
            hintText: 'correo@ejemplo.com',
            icon: Icons.mail_outline,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthLabeledPasswordField(
            label: 'Contraseña',
            controller: _passwd,
            obscure: _obscure,
            hintText: 'Mínimo 8 caracteres',
            onToggleVisibility: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 28),
          if (vm.error != null) ...[
            AuthErrorText(message: vm.error!),
            const SizedBox(height: 12),
          ],
          AuthPrimaryButton(
            label: 'Crear cuenta',
            loading: vm.loading,
            onPressed: _register,
          ),
          const SizedBox(height: 24),
          const Separator(),
          const SizedBox(height: 16),
          AuthSwitchLink(
            prefix: '¿Ya tienes cuenta?',
            action: 'Iniciar sesión',
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final vm = context.read<RegisterViewModel>();
    final ok = await vm.register(
      email: _email.text.trim(),
      passwd: _passwd.text.trim(),
      nombre: _user.text.trim(),
    );
    if (!mounted) return;
    if (ok) context.go('/home');
  }
}
