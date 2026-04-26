import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PerfilProfileHeader extends StatelessWidget {
  final String inicial;
  final String displayName;
  final String email;

  const PerfilProfileHeader({
    super.key,
    required this.inicial,
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.usal,
            child: Text(
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(displayName, style: AppTheme.titulo.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
