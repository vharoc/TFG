import 'package:flutter/material.dart';

class PerfilDeleteAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const PerfilDeleteAccountCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}
