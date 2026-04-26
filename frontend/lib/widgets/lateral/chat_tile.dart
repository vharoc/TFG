import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../theme/theme.dart';

class LateralChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LateralChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: const Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: AppTheme.usal,
        ),
        title: Text(
          chat.titulo,
          style: AppTheme.cuerpo.copyWith(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFecha(chat.fechaCreacion),
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.black38,
          ),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
