import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class LateralNewChatButton extends StatelessWidget {
  final bool isCompact;
  final VoidCallback onTap;

  const LateralNewChatButton({
    super.key,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 10 : 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.usal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Nueva conversación',
                style: AppTheme.cuerpo.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
