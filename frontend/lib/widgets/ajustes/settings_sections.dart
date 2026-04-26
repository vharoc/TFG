import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'action_tile.dart';
import 'section_card.dart';

class SettingsSections extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onPermissionsTap;
  final VoidCallback onLogoutTap;

  const SettingsSections({
    super.key,
    required this.onProfileTap,
    required this.onPermissionsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
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
        SectionCard(
          children: [
            ActionTile(
              icon: Icons.tune_rounded,
              label: 'Permisos de la aplicación',
              onTap: onPermissionsTap,
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
