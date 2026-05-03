import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme.dart';
import '../../viewmodels/ajustes_view_model.dart';
import 'action_tile.dart';
import 'section_card.dart';

class SettingsSections extends StatelessWidget {
  final VoidCallback onProfileTap;
  final void Function(bool) onUbicacionToggle;
  final void Function(bool) onCamaraToggle;
  final void Function(bool) onAlbumToggle;
  final VoidCallback onLogoutTap;

  const SettingsSections({
    super.key,
    required this.onProfileTap,
    required this.onUbicacionToggle,
    required this.onCamaraToggle,
    required this.onAlbumToggle,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AjustesViewModel>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          children: [
            ActionTile(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              onTap: onProfileTap,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Permisos de la aplicación',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SectionCard(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.location_on_outlined, size: 22),
              title: const Text('Ubicación', style: TextStyle(fontSize: 15)),
              value: vm.ubicacionActiva,
              onChanged: onUbicacionToggle,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              secondary: const Icon(Icons.camera_alt_outlined, size: 22),
              title: const Text('Cámara', style: TextStyle(fontSize: 15)),
              value: vm.camaraActiva,
              onChanged: onCamaraToggle,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              secondary: const Icon(Icons.photo_library_outlined, size: 22),
              title: const Text('Álbum', style: TextStyle(fontSize: 15)),
              value: vm.albumActivo,
              onChanged: onAlbumToggle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          children: [
            ActionTile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              onTap: onLogoutTap,
              color: AppTheme.usal,
            ),
          ],
        ),
      ],
    );
  }
}
