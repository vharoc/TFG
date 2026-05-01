import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/ajustes_view_model.dart';
import '../widgets/common/back_title_app_bar.dart';
import '../widgets/ajustes/settings_sections.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AjustesViewModel(),
      child: const _AjustesScreenState(),
    );
  }
}

class _AjustesScreenState extends StatelessWidget {
  const _AjustesScreenState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: const BackTitleAppBar(title: 'Ajustes'),
      body: SettingsSections(
        onProfileTap: () => context.push('/perfil'),
        onPermissionsTap: () => _abrirPermisosDispositivo(context),
        onLogoutTap: () => _confirmarCerrarSesion(context),
      ),
    );
  }

  // ── Abre los ajustes de permisos del sistema ─────────────────────────────
  Future<void> _abrirPermisosDispositivo(BuildContext context) async {
    // Abre la pantalla de ajustes de la app en el sistema operativo.
    // Requiere el paquete `app_settings` (app_settings: ^5.x).
    // Si no lo tienes instalado, puedes usar el channel nativo o simplemente
    // redirigir al usuario con un diálogo informativo.
    try {
      // Intenta usar el paquete app_settings si está disponible.
      // ignore: avoid_dynamic_calls
      const MethodChannel('flutter/platform').invokeMethod('openAppSettings');
    } catch (_) {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permisos'),
            content: const Text(
              'Ve a Ajustes → Aplicaciones → [Esta app] para gestionar los permisos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ── Confirmar cierre de sesión ───────────────────────────────────────────
  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final vm = context.read<AjustesViewModel>();

    final ok = await vm.cerrarSesion();
    if (context.mounted) {
      if (ok) {
        context.go('/login');
      } else if (vm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
        );
      }
    }
  }
}
