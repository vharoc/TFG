import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/theme.dart';
import '../viewmodels/ajustes_view_model.dart';
import '../widgets/ajustes/action_tile.dart';
import '../widgets/ajustes/section_card.dart';

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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.usal,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ajustes',
          style: AppTheme.titulo.copyWith(fontSize: 20, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Cuenta ────────────────────────────────────────────────────────
          SectionCard(
            children: [
              ActionTile(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                onTap: () => context.push('/perfil'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Dispositivo ───────────────────────────────────────────────────
          SectionCard(
            children: [
              ActionTile(
                icon: Icons.tune_rounded,
                label: 'Permisos de la aplicación',
                onTap: () => _abrirPermisosDispositivo(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Sesión ────────────────────────────────────────────────────────
          SectionCard(
            children: [
              ActionTile(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                onTap: () => _confirmarCerrarSesion(context),
                color: AppTheme.usal,
              ),
            ],
          ),
        ],
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
          SnackBar(
            content: Text(vm.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
  }
}