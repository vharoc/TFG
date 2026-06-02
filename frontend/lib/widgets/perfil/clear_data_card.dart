import 'package:flutter/material.dart';

class PerfilClearDataCard extends StatelessWidget {
  final VoidCallback onTap;

  const PerfilClearDataCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: ListTile(
        leading: Icon(Icons.cleaning_services_outlined, color: Colors.orange.shade700),
        title: Text(
          'Borrar datos',
          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Elimina chats y progreso de ciudades',
          style: TextStyle(fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
}
