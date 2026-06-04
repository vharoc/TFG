import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class RutaExitButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const RutaExitButton({
    super.key,
    required this.onTap,
    this.icon = Icons.close_rounded,
    this.label = 'Salir de ruta',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.usal.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppTheme.usal),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.usal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
