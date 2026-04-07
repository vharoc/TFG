import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
 
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.usal, size: 20),
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
          // ── Datos del usuario ──────────────────────────────────────────────
          _SectionCard(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.usal,
                  child: Text(
                    _inicial(user),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                    user?.displayName ?? user?.email ?? 'Usuario',
                    style: AppTheme.cuerpo),
                subtitle: Text(
                  user?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 20),
 
          // ── Sesión ─────────────────────────────────────────────────────────
          _SectionCard(
            children: [
              _ActionTile(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                onTap: () => _cerrarSesion(context),
              ),
            ],
          ),
 
          const SizedBox(height: 20),
 
          // ── Zona de peligro ────────────────────────────────────────────────
          _SectionCard(
            children: [
              _ActionTile(
                icon: Icons.delete_forever_outlined,
                label: 'Eliminar cuenta',
                color: Colors.red,
                onTap: () => _mostrarDialogoEliminarCuenta(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  // ── Cerrar sesión ──────────────────────────────────────────────────────────
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar la sesión actual?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) context.go('/login'); // ajusta la ruta a tu router
    }
  }
 
  // ── Diálogo eliminar cuenta ────────────────────────────────────────────────
  Future<void> _mostrarDialogoEliminarCuenta(BuildContext context) async {
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
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
 
    if (confirm == true) {
      await _eliminarCuenta(context, passwdCtrl.text.trim());
    }
    passwdCtrl.dispose();
  }
 
  // ── Eliminar cuenta: borra chats en Firestore → borra usuario en Auth ──────
  Future<void> _eliminarCuenta(BuildContext context, String passwd) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      // 1) Verifica credenciales primero
      await AuthService().reauthenticate(email: email, passwd: passwd);

      // 2) Intenta limpiar chats; si falla por permisos, no bloquea borrar cuenta
      try {
        await ChatService.instance.eliminarTodosLosChats();
      } on FirebaseException {
        // Ignorado intencionalmente: priorizamos borrar la cuenta en Auth.
      }

      // 3) Borra cuenta en Auth y cierra sesion
      await AuthService().deleteCurrentUser();

      // 4) Navega al login
      if (context.mounted) context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError(e.code)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        final msg = e.code == 'permission-denied'
            ? 'Firestore no permite esta operacion. Revisa las reglas.'
            : 'Error de Firestore al eliminar datos de usuario.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }
 
  String _inicial(User? user) {
    if (user?.displayName?.isNotEmpty == true) {
      return user!.displayName![0].toUpperCase();
    }
    if (user?.email?.isNotEmpty == true) {
      return user!.email![0].toUpperCase();
    }
    return '?';
  }
 
  String _mensajeError(String code) {
    return switch (code) {
      'wrong-password' => 'Contraseña incorrecta.',
      'too-many-requests' => 'Demasiados intentos. Prueba más tarde.',
      _ => 'Error al eliminar la cuenta. Inténtalo de nuevo.',
    };
  }
}
 
// ── Widgets auxiliares ─────────────────────────────────────────────────────────
 
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0DAD4)),
      ),
      child: Column(children: children),
    );
  }
}
 
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
 
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });
 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      trailing:
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
      onTap: onTap,
    );
  }
}