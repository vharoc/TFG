import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/theme.dart';
import '../viewmodels/perfil_view_model.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerfilViewModel(),
      child: const _PerfilScreenState(),
    );
  }
}

class _PerfilScreenState extends StatelessWidget {
  const _PerfilScreenState();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();

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
          'Perfil',
          style: AppTheme.titulo.copyWith(fontSize: 20, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar + datos ─────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.usal,
                  child: Text(
                    vm.inicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  vm.displayName,
                  style: AppTheme.titulo.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.email,
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Zona de peligro ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Eliminar cuenta',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () => _mostrarDialogoEliminarCuenta(context, vm),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diálogo eliminar cuenta ──────────────────────────────────────────────
  Future<void> _mostrarDialogoEliminarCuenta(
    BuildContext context,
    PerfilViewModel vm,
  ) async {
    final passwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es irreversible. Se eliminarán tu cuenta y '
                'todo tu historial de conversaciones.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Introduce tu contraseña' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!context.mounted) {
      passwdCtrl.dispose();
      return;
    }

    if (confirm == true) {
      final ok = await vm.eliminarCuenta(passwdCtrl.text.trim());
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

    passwdCtrl.dispose();
  }
}