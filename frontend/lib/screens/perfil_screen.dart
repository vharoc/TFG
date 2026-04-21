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

class _PerfilScreenState extends StatefulWidget {
  const _PerfilScreenState({super.key});

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

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0DAD4)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nombre de usuario',
                  style: AppTheme.cuerpo.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Introduce tu nombre de usuario',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: vm.cargando ? null : () => _actualizarNombre(vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.usal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: vm.cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar nombre'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0DAD4)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Contraseña',
                        style: AppTheme.cuerpo.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _mostrarCambioPasswd = !_mostrarCambioPasswd),
                      child: Text(
                        _mostrarCambioPasswd
                            ? 'Cancelar'
                            : 'Cambiar contraseña',
                        style: const TextStyle(color: AppTheme.usal),
                      ),
                    ),
                  ],
                ),
                if (_mostrarCambioPasswd) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwdActualCtrl,
                    obscureText: _obscureActual,
                    decoration: InputDecoration(
                      hintText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureActual = !_obscureActual),
                        icon: Icon(
                          _obscureActual
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwdNuevaCtrl,
                    obscureText: _obscureNueva,
                    decoration: InputDecoration(
                      hintText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureNueva = !_obscureNueva),
                        icon: Icon(
                          _obscureNueva
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: vm.cargando
                        ? null
                        : () => _cambiarContrasena(vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.usal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: vm.cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar nueva contraseña'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

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
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
