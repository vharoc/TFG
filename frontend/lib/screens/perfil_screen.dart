import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/perfil_view_model.dart';
import '../widgets/perfil/delete_account_card.dart';
import '../widgets/perfil/delete_account_dialog.dart';
import '../widgets/common/back_title_app_bar.dart';
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
      appBar: const BackTitleAppBar(title: 'Perfil'),
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
            onTap: () => _mostrarDialogoEliminarCuenta(vm),
          ),
        ],
      ),
    );
  }

  // ── Diálogo eliminar cuenta ──────────────────────────────────────────────
  Future<void> _mostrarDialogoEliminarCuenta(PerfilViewModel vm) async {
    final passwd = await showDeleteAccountDialog(context);
    if (!mounted || passwd == null) return;

    final ok = await vm.eliminarCuenta(passwd);
    if (!mounted) return;

    if (ok) {
      context.go('/login');
      return;
    }

    if (vm.error != null) {
      _showErrorSnackBar(vm.error!);
    }
  }

  Future<void> _actualizarNombre(PerfilViewModel vm) async {
    final ok = await vm.actualizarNombreUsuario(_nombreCtrl.text);
    if (!mounted) return;

    if (ok) {
      _showSuccessSnackBar('Nombre de usuario actualizado.');
    } else if (vm.error != null) {
      _showErrorSnackBar(vm.error!);
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
      _showSuccessSnackBar('Contraseña actualizada correctamente.');
    } else if (vm.error != null) {
      _showErrorSnackBar(vm.error!);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
