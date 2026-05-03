import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/ubicacion_service.dart';
import '../viewmodels/ajustes_view_model.dart';
import '../widgets/common/back_title_app_bar.dart';
import '../widgets/ajustes/settings_sections.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AjustesViewModel(),
      child: const _AjustesBody(),
    );
  }
}

class _AjustesBody extends StatefulWidget {
  const _AjustesBody();

  @override
  State<_AjustesBody> createState() => _AjustesBodyState();
}

class _AjustesBodyState extends State<_AjustesBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AjustesViewModel>().recargarUbicacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: const BackTitleAppBar(title: 'Ajustes'),
      body: SettingsSections(
        onProfileTap: () => context.push('/perfil'),
        onUbicacionToggle: (value) => _toggleUbicacion(context, value),
        onCamaraToggle: (value) => _toggleCamara(context, value),
        onAlbumToggle: (value) => _toggleAlbum(context, value),
        onLogoutTap: () => _confirmarCerrarSesion(context),
      ),
    );
  }

  Future<void> _toggleUbicacion(BuildContext context, bool activar) async {
    final vm = context.read<AjustesViewModel>();

    if (activar) {
      final estado = await vm.activarUbicacion();
      if (!context.mounted) return;
      if (estado == EstadoPermiso.permanentementeDenegado) {
        _mostrarDialogoAjustes(context, vm, 'ubicación');
      }
    } else {
      _mostrarDialogoAjustes(context, vm, 'ubicación');
    }
  }

  Future<void> _toggleCamara(BuildContext context, bool activar) async {
    final vm = context.read<AjustesViewModel>();

    if (activar) {
      final concedido = await vm.activarCamara();
      if (!context.mounted) return;
      if (!concedido) {
        _mostrarDialogoAjustes(context, vm, 'cámara');
      }
    } else {
      _mostrarDialogoAjustes(context, vm, 'cámara');
    }
  }

  Future<void> _toggleAlbum(BuildContext context, bool activar) async {
    final vm = context.read<AjustesViewModel>();

    if (activar) {
      final concedido = await vm.activarAlbum();
      if (!context.mounted) return;
      if (!concedido) {
        _mostrarDialogoAjustes(context, vm, 'álbum');
      }
    } else {
      _mostrarDialogoAjustes(context, vm, 'álbum');
    }
  }

  void _mostrarDialogoAjustes(BuildContext context, AjustesViewModel vm, String permiso) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permiso de $permiso'),
        content: Text(
          'Para cambiar el permiso de $permiso ve a los Ajustes del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.abrirAjustesApp();
            },
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
  }

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
