import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_services.dart';
import '../theme/theme.dart';
import '../widgets/auth/auth_page_layout.dart';
import '../widgets/auth/auth_primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _sending = false;
  // Cooldown: el botón de reenvío se bloquea 60 s tras cada envío.
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _reenviar() async {
    setState(() => _sending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo enviado. Revisa tu bandeja de entrada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el correo. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verificar() async {
    setState(() => _checking = true);
    try {
      await AuthService.instance.reloadUser();
      if (!mounted) return;
      if (AuthService.instance.isEmailVerified) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún no hemos recibido la verificación. Revisa tu correo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _salir() async {
    await AuthService.instance.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';

    return AuthPageLayout(
      title: 'Verifica tu correo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.mark_email_unread_outlined,
              size: 72, color: AppTheme.usal),
          const SizedBox(height: 24),
          Text(
            'Hemos enviado un enlace de verificación a:',
            style: AppTheme.cuerpo,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: AppTheme.cuerpo.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ábrelo y pulsa el enlace; después vuelve aquí y toca el botón de abajo.',
            style: AppTheme.cuerpo.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            label: 'Ya lo he verificado',
            loading: _checking,
            onPressed: _checking ? null : _verificar,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: (_sending || _cooldown > 0) ? null : _reenviar,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.usal,
              side: const BorderSide(color: AppTheme.usal),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: AppTheme.cuerpo,
            ),
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.usal),
                  )
                : Text(_cooldown > 0
                    ? 'Reenviar correo (${_cooldown}s)'
                    : 'Reenviar correo'),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _salir,
            child: Text(
              'Cerrar sesión',
              style: AppTheme.cuerpo.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
