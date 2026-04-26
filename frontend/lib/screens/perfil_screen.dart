import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/theme.dart';
import '../viewmodels/perfil_view_model.dart';
import '../widgets/perfil/delete_account_card.dart';
import '../widgets/perfil/password_card.dart';
import '../widgets/perfil/profile_header.dart';
import '../widgets/perfil/username_card.dart';

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

class _PerfilScreenState extends StatefulWidget {
  const _PerfilScreenState();

  @override
  State<_PerfilScreenState> createState() => _PerfilScreenStateState();
}

class _PerfilScreenStateState extends State<_PerfilScreenState> {
  final _nombreCtrl = TextEditingController();
  final _passwdActualCtrl = TextEditingController();
  final _passwdNuevaCtrl = TextEditingController();

  bool _nombreInicializado = false;
  bool _mostrarCambioPasswd = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nombreInicializado) return;
    final vm = context.read<PerfilViewModel>();
    _nombreCtrl.text = vm.displayName;
    _nombreInicializado = true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passwdActualCtrl.dispose();
    _passwdNuevaCtrl.dispose();
    super.dispose();
  }

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
          PerfilProfileHeader(
            inicial: vm.inicial,
            displayName: vm.displayName,
            email: vm.email,
          ),

          const SizedBox(height: 36),

          PerfilUsernameCard(
            controller: _nombreCtrl,
            loading: vm.cargando,
            onSave: () => _actualizarNombre(vm),
          ),

          const SizedBox(height: 16),

          PerfilPasswordCard(
            loading: vm.cargando,
            expanded: _mostrarCambioPasswd,
            obscureActual: _obscureActual,
            obscureNueva: _obscureNueva,
            actualController: _passwdActualCtrl,
            nuevaController: _passwdNuevaCtrl,
            onToggleExpanded: () {
              setState(() => _mostrarCambioPasswd = !_mostrarCambioPasswd);
            },
            onToggleObscureActual: () {
              setState(() => _obscureActual = !_obscureActual);
            },
            onToggleObscureNueva: () {
              setState(() => _obscureNueva = !_obscureNueva);
            },
            onSave: () => _cambiarContrasena(vm),
          ),

          const SizedBox(height: 16),

          PerfilDeleteAccountCard(
            onTap: () => _mostrarDialogoEliminarCuenta(context, vm),
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
            SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
          );
        }
      }
    }

    passwdCtrl.dispose();
  }

  Future<void> _actualizarNombre(PerfilViewModel vm) async {
    final ok = await vm.actualizarNombreUsuario(_nombreCtrl.text);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre de usuario actualizado.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cambiarContrasena(PerfilViewModel vm) async {
    final ok = await vm.cambiarContrasena(
      contrasenaActual: _passwdActualCtrl.text,
      nuevaContrasena: _passwdNuevaCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      _passwdActualCtrl.clear();
      _passwdNuevaCtrl.clear();
      setState(() => _mostrarCambioPasswd = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
      );
    }
  }
}
