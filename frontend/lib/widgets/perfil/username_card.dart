import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PerfilUsernameCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSave;

  const PerfilUsernameCard({
    super.key,
    required this.controller,
    required this.loading,
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
          Text(
            'Nombre de usuario',
            style: AppTheme.cuerpo.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Introduce tu nombre de usuario',
              prefixIcon: Icon(Icons.person_outline_rounded),
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
                : const Text('Guardar nombre'),
          ),
        ],
      ),
    );
  }
}
