import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PerfilPasswordCard extends StatelessWidget {
  final bool loading;
  final bool expanded;
  final bool obscureActual;
  final bool obscureNueva;
  final TextEditingController actualController;
  final TextEditingController nuevaController;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleObscureActual;
  final VoidCallback onToggleObscureNueva;
  final VoidCallback onSave;

  const PerfilPasswordCard({
    super.key,
    required this.loading,
    required this.expanded,
    required this.obscureActual,
    required this.obscureNueva,
    required this.actualController,
    required this.nuevaController,
    required this.onToggleExpanded,
    required this.onToggleObscureActual,
    required this.onToggleObscureNueva,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                onPressed: onToggleExpanded,
                child: Text(
                  expanded ? 'Cancelar' : 'Cambiar contraseña',
                  style: const TextStyle(color: AppTheme.usal),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: actualController,
              obscureText: obscureActual,
              decoration: InputDecoration(
                hintText: 'Contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscureActual,
                  icon: Icon(
                    obscureActual
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nuevaController,
              obscureText: obscureNueva,
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscureNueva,
                  icon: Icon(
                    obscureNueva
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.usal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: loading
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
    );
  }
}
