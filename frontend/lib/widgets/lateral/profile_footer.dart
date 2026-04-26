import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class LateralProfileFooter extends StatelessWidget {
  final String inicial;
  final String nombre;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  const LateralProfileFooter({
    super.key,
    required this.inicial,
    required this.nombre,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppTheme.usal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nombre,
              style: AppTheme.cuerpo.copyWith(
                fontSize: 13,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black54,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
